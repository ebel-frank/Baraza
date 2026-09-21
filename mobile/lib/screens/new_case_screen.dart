import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../app_services.dart';
import '../db/database.dart';
import '../services/audio_player_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/mediator_profile_service.dart';
import '../services/speech_service.dart';

const _caseTypes = [
  'Land boundary',
  'Family / inheritance',
  'Neighbor dispute',
  'Domestic / marital',
  'Debt / property',
  'Other',
];

class NewCaseScreen extends StatefulWidget {
  final AppServices services;
  final MediatorProfile mediator;

  const NewCaseScreen({
    super.key,
    required this.services,
    required this.mediator,
  });

  @override
  State<NewCaseScreen> createState() => _NewCaseScreenState();
}

class _NewCaseScreenState extends State<NewCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _partyRoleController = TextEditingController();

  String _caseType = _caseTypes.first;
  DateTime _date = DateTime.now();
  final List<String> _partyRoles = [];

  final SpeechService _speechService = SpeechService();
  SpeechLanguage _speechLanguage = SpeechLanguage.english;
  bool _listening = false;
  String _voiceBaseText = '';
  bool _saving = false;

  // Voice notes: real audio recordings, independent of the speech-to-text
  // dictation above — kept as their own artifacts rather than just transcribed
  // text. A case can have several separate recordings, not just one.
  final AudioRecorderService _audioRecorderService = AudioRecorderService();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  bool _recordingVoiceNote = false;
  final List<String> _voiceNoteFilePaths = [];
  String? _currentlyPlayingPath;
  PlayerState _playerState = PlayerState.stopped;
  Duration _recordingElapsed = Duration.zero;
  Timer? _recordingTimer;
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _locationController.text =
        '${widget.mediator.locality}, ${widget.mediator.region}';
    _playerStateSub = _audioPlayerService.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playerState = state);
    });
  }

  @override
  void dispose() {
    _speechService.stop();
    _recordingTimer?.cancel();
    _playerStateSub?.cancel();
    _audioRecorderService.dispose();
    _audioPlayerService.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _partyRoleController.dispose();
    super.dispose();
  }

  void _addPartyRole() {
    final role = _partyRoleController.text.trim();
    if (role.isEmpty) return;
    setState(() {
      _partyRoles.add(role);
      _partyRoleController.clear();
    });
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speechService.stop();
      setState(() => _listening = false);
      return;
    }
    final ready = await _speechService.ensureReady();
    if (!ready) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is needed for voice intake.'),
        ),
      );
      return;
    }
    _voiceBaseText = _descriptionController.text;
    setState(() => _listening = true);
    await _speechService.startListening(
      language: _speechLanguage,
      onResult: (text, isFinal) {
        final combined = _voiceBaseText.isEmpty
            ? text
            : '$_voiceBaseText $text';
        _descriptionController.text = combined;
        _descriptionController.selection = TextSelection.collapsed(
          offset: combined.length,
        );
        if (isFinal) {
          _voiceBaseText = combined;
          setState(() => _listening = false);
        }
      },
    );
  }

  Future<void> _toggleVoiceNoteRecording() async {
    if (_recordingVoiceNote) {
      final path = await _audioRecorderService.stop();
      _recordingTimer?.cancel();
      setState(() {
        _recordingVoiceNote = false;
        if (path != null) _voiceNoteFilePaths.add(path);
      });
      return;
    }

    final ready = await _audioRecorderService.ensureReady();
    if (!ready) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Microphone permission is needed to record a voice note.',
          ),
        ),
      );
      return;
    }

    // Each recording is kept as its own separate voice note.
    await _audioRecorderService.start();
    setState(() {
      _recordingVoiceNote = true;
      _recordingElapsed = Duration.zero;
    });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordingElapsed += const Duration(seconds: 1));
    });
  }

  bool _isPlaying(String path) =>
      _currentlyPlayingPath == path && _playerState == PlayerState.playing;

  Future<void> _togglePlayVoiceNote(String path) async {
    if (_isPlaying(path)) {
      await _audioPlayerService.pause();
      return;
    }
    _currentlyPlayingPath = path;
    await _audioPlayerService.play(path);
  }

  Future<void> _deleteVoiceNote(String path) async {
    if (_currentlyPlayingPath == path) {
      await _audioPlayerService.stop();
      _currentlyPlayingPath = null;
    }
    final file = File(path);
    if (await file.exists()) await file.delete();
    setState(() => _voiceNoteFilePaths.remove(path));
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final description = _descriptionController.text.trim();
    final referralCheck = await widget.services.referralService.check(
      description,
    );

    await widget.services.db
        .into(widget.services.db.cases)
        .insert(
          CasesCompanion.insert(
            id: const Uuid().v4(),
            caseType: _caseType,
            partiesJson: jsonEncode(
              _partyRoles.map((r) => {'role': r}).toList(),
            ),
            description: description,
            voiceNoteRefsJson: Value(
              _voiceNoteFilePaths.isEmpty
                  ? null
                  : jsonEncode(_voiceNoteFilePaths),
            ),
            location: _locationController.text.trim(),
            createdAt: _date,
            referralFlag: Value(referralCheck.flagged),
            referralReason: Value(referralCheck.reason),
          ),
        );

    // Best-effort: try to push immediately if we happen to be online already.
    widget.services.syncService.pushPending();

    if (!mounted) return;
    if (referralCheck.flagged) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Possible referral needed'),
          content: Text(
            '${referralCheck.reason}\n\nSuggested next step: ${referralCheck.suggestedNextStep}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Noted'),
            ),
          ],
        ),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New case')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _caseType,
                decoration: const InputDecoration(
                  labelText: 'Case type',
                  border: OutlineInputBorder(),
                ),
                items: _caseTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _caseType = v ?? _caseType),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _partyRoleController,
                      decoration: const InputDecoration(
                        labelText: 'Party role (e.g. Complainant, Neighbor)',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addPartyRole(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addPartyRole,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              if (_partyRoles.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    children: _partyRoles
                        .map(
                          (r) => Chip(
                            label: Text(r),
                            onDeleted: () =>
                                setState(() => _partyRoles.remove(r)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location / area',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Short description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v == null || v.trim().length < 5)
                          ? 'Please describe the case'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SegmentedButton<SpeechLanguage>(
                    segments: SpeechLanguage.values
                        .map(
                          (l) => ButtonSegment(value: l, label: Text(l.label)),
                        )
                        .toList(),
                    selected: {_speechLanguage},
                    onSelectionChanged: (s) =>
                        setState(() => _speechLanguage = s.first),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _toggleListening,
                    icon: Icon(_listening ? Icons.stop : Icons.mic),
                    label: Text(_listening ? 'Stop' : 'Dictate'),
                    style: _listening
                        ? FilledButton.styleFrom(backgroundColor: Colors.red)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Voice notes (optional)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Text(
                'Real recordings, kept alongside the description, not just text. Record as many as you need.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              if (_voiceNoteFilePaths.isNotEmpty)
                ..._voiceNoteFilePaths.asMap().entries.map((entry) {
                  final index = entry.key;
                  final path = entry.value;
                  final playing = _isPlaying(path);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => _togglePlayVoiceNote(path),
                          icon: Icon(
                            playing ? Icons.pause_circle : Icons.play_circle,
                          ),
                        ),
                        Expanded(child: Text('Voice note ${index + 1}')),
                        IconButton(
                          onPressed: () => _deleteVoiceNote(path),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  );
                }),
              FilledButton.icon(
                onPressed: _toggleVoiceNoteRecording,
                icon: Icon(
                  _recordingVoiceNote ? Icons.stop : Icons.fiber_manual_record,
                ),
                label: Text(
                  _recordingVoiceNote
                      ? 'Stop (${_formatDuration(_recordingElapsed)})'
                      : (_voiceNoteFilePaths.isEmpty
                            ? 'Record'
                            : 'Record another'),
                ),
                style: _recordingVoiceNote
                    ? FilledButton.styleFrom(backgroundColor: Colors.red)
                    : null,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save case'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
