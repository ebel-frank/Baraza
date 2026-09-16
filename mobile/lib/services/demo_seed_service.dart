import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';

/// Inserts 2-3 example cases into the local database on first launch, purely so
/// a demo has something to look at immediately without needing to type a case in
/// first. Runs once, gated by a shared_preferences flag.
class DemoSeedService {
  static const _keySeeded = 'demo_cases_seeded';

  Future<void> seedIfNeeded(AppDatabase db) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keySeeded) == true) return;

    final now = DateTime.now();
    await db.into(db.cases).insert(CasesCompanion.insert(
          id: 'local-demo-case-1',
          caseType: 'Land boundary',
          partiesJson: jsonEncode([{'role': 'Complainant'}, {'role': 'Neighbor'}]),
          description:
              'Two neighboring farmers disagree on where the boundary between their unregistered plots lies after a fence was moved during the last planting season.',
          location: 'Kajiado, Kenya',
          createdAt: now.subtract(const Duration(days: 2)),
        ));

    await db.into(db.cases).insert(CasesCompanion.insert(
          id: 'local-demo-case-2',
          caseType: 'Family / inheritance',
          partiesJson:
              jsonEncode([{'role': 'Widow'}, {'role': "Deceased's brother"}]),
          description:
              "A widow says her late husband's brother is claiming the family land and threatened her when she refused to leave the homestead.",
          location: 'Kisumu, Kenya',
          createdAt: now.subtract(const Duration(days: 1)),
          referralFlag: const Value(true),
          referralReason: const Value(
              'Threat mentioned alongside a land/inheritance dispute — escalating conflict, refer before continuing mediation.'),
        ));

    await db.into(db.cases).insert(CasesCompanion.insert(
          id: 'local-demo-case-3',
          caseType: 'Neighbor dispute',
          partiesJson: jsonEncode([{'role': 'Complainant'}, {'role': 'Neighbor'}]),
          description:
              'This is the third time these two neighbors have brought the same water-access disagreement to mediation this year.',
          location: 'Enugu, Nigeria',
          createdAt: now,
          referralFlag: const Value(true),
          referralReason: const Value(
              'Repeat dispute between the same parties — mediation is not resolving the underlying issue.'),
        ));

    await prefs.setBool(_keySeeded, true);
  }
}
