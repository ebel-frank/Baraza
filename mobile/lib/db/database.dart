import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// One row per logged case. `parties` and `advisoryResponse` are stored as
/// JSON text since Drift/sqlite3 has no native JSON column type.
class Cases extends Table {
  TextColumn get id => text()();
  TextColumn get caseType => text()();
  TextColumn get partiesJson => text()();
  TextColumn get description => text()();
  // JSON-encoded list of local file paths — a case can have several separate
  // voice-note recordings, not just one (mirrors `partiesJson`'s pattern).
  TextColumn get voiceNoteRefsJson => text().nullable()();
  TextColumn get location => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get referralFlag => boolean().withDefault(const Constant(false))();
  TextColumn get referralReason => text().nullable()();
  TextColumn get advisoryResponseJson => text().nullable()();
  // A case is open while closedAt is null. resolutionNote is a short record
  // of what actually worked, entered when the mediator closes the case.
  DateTimeColumn get closedAt => dateTime().nullable()();
  TextColumn get resolutionNote => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'baraza.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(tables: [Cases])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // voiceNoteRef (single path) -> voiceNoteRefsJson (JSON list) is a
        // shape change, not just a rename — recreate rather than migrate
        // in place. Pre-launch/demo app, and all synced cases are safely
        // recoverable from the backend via sign-in's pull anyway.
        await m.deleteTable('cases');
        await m.createTable(cases);
      }
      if (from < 3) {
        await m.addColumn(cases, cases.closedAt);
        await m.addColumn(cases, cases.resolutionNote);
      }
    },
  );

  Future<List<Case>> watchAllOnce() => select(cases).get();

  Stream<Case?> watchCaseById(String id) =>
      (select(cases)..where((c) => c.id.equals(id))).watchSingleOrNull();

  Stream<List<Case>> watchAllCases() =>
      (select(cases)..orderBy([(c) => OrderingTerm.desc(c.createdAt)])).watch();

  Future<List<Case>> pendingCases() =>
      (select(cases)..where((c) => c.syncedAt.isNull())).get();

  Future<void> markSynced(String id, DateTime syncedAt) =>
      (update(cases)..where((c) => c.id.equals(id))).write(
        CasesCompanion(syncedAt: Value(syncedAt)),
      );

  Future<void> updateAdvisoryResponse(
    String id, {
    required String advisoryResponseJson,
    required bool referralFlag,
    String? referralReason,
  }) => (update(cases)..where((c) => c.id.equals(id))).write(
    CasesCompanion(
      advisoryResponseJson: Value(advisoryResponseJson),
      referralFlag: Value(referralFlag),
      referralReason: Value(referralReason),
    ),
  );

  /// Marks a case resolved. Clears syncedAt so the change gets pushed up on
  /// the next sync, same as any other local edit.
  Future<void> closeCase(String id, {String? resolutionNote}) =>
      (update(cases)..where((c) => c.id.equals(id))).write(
        CasesCompanion(
          closedAt: Value(DateTime.now()),
          resolutionNote: Value(resolutionNote),
          syncedAt: const Value(null),
        ),
      );

  /// Reopens a previously-closed case (e.g. closed by mistake).
  Future<void> reopenCase(String id) =>
      (update(cases)..where((c) => c.id.equals(id))).write(
        const CasesCompanion(
          closedAt: Value(null),
          resolutionNote: Value(null),
          syncedAt: Value(null),
        ),
      );

  /// Used after a successful sign-out: safe to wipe because sign-out only
  /// proceeds once every local case is confirmed synced to the account.
  Future<void> clearAllCases() => delete(cases).go();

  /// Hydrates the local DB from a server `/sync/pull` after sign-in, so a
  /// mediator gets their previously-synced cases back on a new/reinstalled app.
  Future<void> upsertFromServer(CasesCompanion entry) =>
      into(cases).insertOnConflictUpdate(entry);
}
