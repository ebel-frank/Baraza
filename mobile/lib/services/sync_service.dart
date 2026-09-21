import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import 'auth_session_service.dart';
import 'backend_config.dart';
import 'connectivity_service.dart';

class SyncResult {
  final bool success;
  final int pushedCount;
  final String? error;

  SyncResult({required this.success, required this.pushedCount, this.error});
}

/// Pushes locally-queued cases to the backend when connectivity is available.
/// Never blocks the UI thread for long and never deletes/loses local rows —
/// a case only ever gets a `syncedAt` timestamp added once the backend confirms it.
class SyncService {
  static const _keyLastSyncedAt = 'last_synced_at';

  final AppDatabase db;
  final BackendConfig backendConfig;
  final ConnectivityService connectivityService;
  final AuthSessionService authSessionService;

  StreamSubscription<bool>? _connectivitySub;

  SyncService({
    required this.db,
    BackendConfig? backendConfig,
    ConnectivityService? connectivityService,
    AuthSessionService? authSessionService,
  }) : backendConfig = backendConfig ?? BackendConfig(),
       connectivityService = connectivityService ?? ConnectivityService(),
       authSessionService = authSessionService ?? AuthSessionService();

  void startAutoSync() {
    _connectivitySub ??= connectivityService.onConnectivityChanged().listen((
      online,
    ) {
      if (online) {
        // Fire-and-forget: a failed background attempt just leaves cases pending
        // for the next connectivity change or manual "Sync now".
        pushPending();
      }
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  Future<DateTime?> getLastSyncedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_keyLastSyncedAt);
    return iso == null ? null : DateTime.tryParse(iso);
  }

  Future<int> pendingCount() async => (await db.pendingCases()).length;

  Future<SyncResult> pushPending() async {
    final session = await authSessionService.getSession();
    if (session == null) {
      return SyncResult(
        success: false,
        pushedCount: 0,
        error: 'Not signed in.',
      );
    }

    final online = await connectivityService.isOnline();
    if (!online) {
      return SyncResult(
        success: false,
        pushedCount: 0,
        error: 'Device is offline.',
      );
    }

    final pending = await db.pendingCases();
    if (pending.isEmpty) {
      await _touchLastSynced();
      return SyncResult(success: true, pushedCount: 0);
    }

    final baseUrl = await backendConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/sync/push');

    final payload = {
      'cases': pending
          .map(
            (c) => {
              'id': c.id,
              'caseType': c.caseType,
              'parties': jsonDecode(c.partiesJson),
              'description': c.description,
              'voiceNoteRefs': c.voiceNoteRefsJson == null
                  ? []
                  : jsonDecode(c.voiceNoteRefsJson!),
              'location': c.location,
              'createdAt': c.createdAt.toIso8601String(),
              'referralFlag': c.referralFlag,
              'referralReason': c.referralReason,
              'advisoryResponse': c.advisoryResponseJson == null
                  ? null
                  : jsonDecode(c.advisoryResponseJson!),
              'closedAt': c.closedAt?.toIso8601String(),
              'resolutionNote': c.resolutionNote,
            },
          )
          .toList(),
    };

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${session.token}',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200 && response.statusCode != 201) {
        return SyncResult(
          success: false,
          pushedCount: 0,
          error: 'Backend returned ${response.statusCode}',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final syncedAt = DateTime.parse(body['syncedAt'] as String);
      final syncedIds = (body['syncedIds'] as List).cast<String>();

      for (final id in syncedIds) {
        await db.markSynced(id, syncedAt);
      }

      await _touchLastSynced();
      return SyncResult(success: true, pushedCount: syncedIds.length);
    } catch (e) {
      return SyncResult(success: false, pushedCount: 0, error: e.toString());
    }
  }

  /// Hydrates the local DB from the backend after sign-in, so a mediator gets
  /// their previously-synced cases back on a new or reinstalled app.
  Future<SyncResult> pullFromServer() async {
    final session = await authSessionService.getSession();
    if (session == null) {
      return SyncResult(
        success: false,
        pushedCount: 0,
        error: 'Not signed in.',
      );
    }

    final online = await connectivityService.isOnline();
    if (!online) {
      return SyncResult(
        success: false,
        pushedCount: 0,
        error: 'Device is offline.',
      );
    }

    final baseUrl = await backendConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/sync/pull');

    try {
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer ${session.token}'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return SyncResult(
          success: false,
          pushedCount: 0,
          error: 'Backend returned ${response.statusCode}',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final serverCases = (body['cases'] as List).cast<Map<String, dynamic>>();

      for (final c in serverCases) {
        await db.upsertFromServer(
          CasesCompanion(
            id: Value(c['id'] as String),
            caseType: Value(c['caseType'] as String),
            partiesJson: Value(jsonEncode(c['parties'])),
            description: Value(c['description'] as String),
            // Note: these paths were only ever valid on the device that recorded
            // them — pulling case data to a different/reinstalled device brings
            // back the file references, but not the audio bytes themselves (see
            // README "Known simplifications"). CaseDetailScreen only offers
            // playback for paths that still actually exist on this device.
            voiceNoteRefsJson: Value(
              (c['voiceNoteRefs'] as List?)?.isNotEmpty == true
                  ? jsonEncode(c['voiceNoteRefs'])
                  : null,
            ),
            location: Value(c['location'] as String),
            createdAt: Value(DateTime.parse(c['createdAt'] as String)),
            syncedAt: Value(
              c['syncedAt'] == null
                  ? null
                  : DateTime.parse(c['syncedAt'] as String),
            ),
            referralFlag: Value(c['referralFlag'] as bool),
            referralReason: Value(c['referralReason'] as String?),
            advisoryResponseJson: Value(
              c['advisoryResponse'] == null
                  ? null
                  : jsonEncode(c['advisoryResponse']),
            ),
            closedAt: Value(
              c['closedAt'] == null
                  ? null
                  : DateTime.parse(c['closedAt'] as String),
            ),
            resolutionNote: Value(c['resolutionNote'] as String?),
          ),
        );
      }

      await _touchLastSynced();
      return SyncResult(success: true, pushedCount: serverCases.length);
    } catch (e) {
      return SyncResult(success: false, pushedCount: 0, error: e.toString());
    }
  }

  Future<void> _touchLastSynced() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSyncedAt, DateTime.now().toIso8601String());
  }
}
