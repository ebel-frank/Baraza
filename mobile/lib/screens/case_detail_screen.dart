import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_services.dart';
import '../db/database.dart';
import '../services/advisory_api_client.dart';
import '../services/audio_player_service.dart';
import '../theme.dart';
import '../widgets/referral_banner.dart';
import 'advisory_screen.dart';

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

  void _openGuidance(Case caseRecord, AdvisoryResult advisory) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AdvisoryScreen(caseType: caseRecord.caseType, advisory: advisory),
      ),
    );
  }

  Future<void> _askForGuidance(Case caseRecord) async {
    setState(() {
      _loadingAdvisory = true;
      _advisoryError = null;
    });
    try {
      // Sends both the description text and any actual voice recordings —
      // the backend has Gemini consider all of it when producing the guidance.
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
      if (mounted) _openGuidance(caseRecord, result);
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
    final scheme = Theme.of(context).colorScheme;
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
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MetaItem(
                      icon: Icons.place_outlined,
                      text: caseRecord.location,
                    ),
                    _MetaItem(
                      icon: Icons.event_outlined,
                      text: DateFormat.yMMMd().format(caseRecord.createdAt),
                    ),
                    _SyncBadge(synced: caseRecord.syncedAt != null),
                  ],
                ),
                const SizedBox(height: 20),
                if (parties.isNotEmpty) ...[
                  Text(
                    'Parties',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: parties.map((r) => Chip(label: Text(r))).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  caseRecord.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (voiceNotePaths.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final entry in voiceNotePaths.asMap().entries) ...[
                    OutlinedButton.icon(
                      onPressed: () => _togglePlayVoiceNote(entry.value),
                      icon: Icon(
                        _isPlaying(entry.value)
                            ? Icons.pause_circle
                            : Icons.play_circle,
                      ),
                      label: Text(
                        _isPlaying(entry.value)
                            ? 'Playing voice note ${entry.key + 1}…'
                            : 'Play voice note ${entry.key + 1}',
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _loadingAdvisory
                      ? null
                      : () => advisory != null
                            ? _openGuidance(caseRecord, advisory)
                            : _askForGuidance(caseRecord),
                  icon: _loadingAdvisory
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : Icon(
                          advisory != null
                              ? Icons.menu_book_rounded
                              : Icons.auto_awesome_rounded,
                        ),
                  label: Text(
                    _loadingAdvisory
                        ? 'Getting guidance…'
                        : advisory != null
                        ? 'View guidance'
                        : 'Ask for guidance',
                  ),
                ),
                if (advisory != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: TextButton(
                        onPressed: _loadingAdvisory
                            ? null
                            : () => _askForGuidance(caseRecord),
                        child: const Text('Ask again'),
                      ),
                    ),
                  ),
                if (_advisoryError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _advisoryError!,
                      style: TextStyle(color: BarazaTheme.danger),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SyncBadge extends StatelessWidget {
  final bool synced;
  const _SyncBadge({required this.synced});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = synced ? BarazaTheme.success : scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          synced ? 'Synced' : 'Pending sync',
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
