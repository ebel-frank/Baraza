import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_services.dart';
import '../db/database.dart';
import '../services/advisory_api_client.dart';
import '../services/audio_player_service.dart';
import '../widgets/referral_banner.dart';

class CaseDetailScreen extends StatefulWidget {
  final AppServices services;
  final String caseId;

  const CaseDetailScreen({
    super.key,
    required this.services,
    required this.caseId,
  });

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  bool _loadingAdvisory = false;
  String? _advisoryError;

  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  String? _currentlyPlayingPath;
  PlayerState _playerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    _audioPlayerService.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playerState = state);
    });
  }

  @override
  void dispose() {
    _audioPlayerService.dispose();
    super.dispose();
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

  Future<void> _askForGuidance(Case caseRecord) async {
    setState(() {
      _loadingAdvisory = true;
      _advisoryError = null;
    });
    try {
      // Sends both the description text and any actual voice recordings —
      // the backend has Gemini consider all of it when producing the summary.
      final voiceNotePaths = caseRecord.voiceNoteRefsJson == null
          ? <String>[]
          : (jsonDecode(caseRecord.voiceNoteRefsJson!) as List).cast<String>();
      final result = await widget.services.advisoryApiClient.query(
        caseRecord.description,
        caseId: caseRecord.id,
        audioFilePaths: voiceNotePaths,
      );

      await widget.services.db.updateAdvisoryResponse(
        caseRecord.id,
        advisoryResponseJson: jsonEncode(result.toJson()),
        referralFlag: caseRecord.referralFlag || result.suggestsReferral,
        referralReason: caseRecord.referralReason ?? result.referralNote,
      );
    } on AdvisoryApiException catch (e) {
      setState(() => _advisoryError = e.message);
    } catch (e) {
      setState(() => _advisoryError = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loadingAdvisory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Case detail')),
      body: SafeArea(
        top: false,
        child: StreamBuilder<Case?>(
          stream: widget.services.db.watchCaseById(widget.caseId),
          builder: (context, snapshot) {
            final caseRecord = snapshot.data;
            if (caseRecord == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final parties = (jsonDecode(caseRecord.partiesJson) as List)
                .map((p) => (p as Map<String, dynamic>)['role'] as String)
                .toList();
            // Only offer playback for paths that still actually exist on this device —
            // a case pulled from another device carries the reference, not the file
            // itself (see README "Known simplifications").
            final voiceNotePaths = caseRecord.voiceNoteRefsJson == null
                ? <String>[]
                : (jsonDecode(caseRecord.voiceNoteRefsJson!) as List)
                      .cast<String>()
                      .where((path) => File(path).existsSync())
                      .toList();

            AdvisoryResult? advisory;
            if (caseRecord.advisoryResponseJson != null) {
              advisory = AdvisoryResult.fromJson(
                jsonDecode(caseRecord.advisoryResponseJson!)
                    as Map<String, dynamic>,
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (caseRecord.referralFlag)
                  ReferralBanner(
                    reason: caseRecord.referralReason,
                    suggestedNextStep: advisory?.referralNote,
                  ),
                Text(
                  caseRecord.caseType,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${caseRecord.location} · ${DateFormat.yMMMd().format(caseRecord.createdAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Chip(
                  label: Text(
                    caseRecord.syncedAt != null ? 'Synced' : 'Pending sync',
                  ),
                  avatar: Icon(
                    caseRecord.syncedAt != null
                        ? Icons.cloud_done
                        : Icons.cloud_off,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 16),
                if (parties.isNotEmpty) ...[
                  Text(
                    'Parties',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Wrap(
                    spacing: 8,
                    children: parties.map((r) => Chip(label: Text(r))).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(caseRecord.description),
                if (voiceNotePaths.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...voiceNotePaths.asMap().entries.map((entry) {
                    final playing = _isPlaying(entry.value);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: OutlinedButton.icon(
                        onPressed: () => _togglePlayVoiceNote(entry.value),
                        icon: Icon(
                          playing ? Icons.pause_circle : Icons.play_circle,
                        ),
                        label: Text(
                          playing
                              ? 'Playing voice note ${entry.key + 1}…'
                              : 'Play voice note ${entry.key + 1}',
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loadingAdvisory
                      ? null
                      : () => _askForGuidance(caseRecord),
                  icon: _loadingAdvisory
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.menu_book),
                  label: const Text('Ask for guidance'),
                ),
                if (_advisoryError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _advisoryError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (advisory != null) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  Text(
                    'Guidance',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(advisory.summary),
                  const SizedBox(height: 12),
                  if (advisory.citations.isEmpty)
                    const Text(
                      'No sourced excerpt was confident enough to cite.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    )
                  else
                    ...advisory.citations.map(
                      (c) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${c.documentTitle}${c.section != null ? ' (${c.section})' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                c.jurisdiction,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                c.excerpt,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Text(
                    'Generated ${DateFormat.yMMMd().add_jm().format(DateTime.parse(advisory.generatedAt))}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
