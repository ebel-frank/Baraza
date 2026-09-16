import 'dart:convert';

import 'package:flutter/services.dart';

class ReferralCategory {
  final String id;
  final String label;
  final String reason;
  final String suggestedNextStep;
  final List<String> keywords;

  ReferralCategory({
    required this.id,
    required this.label,
    required this.reason,
    required this.suggestedNextStep,
    required this.keywords,
  });

  factory ReferralCategory.fromJson(Map<String, dynamic> json) => ReferralCategory(
        id: json['id'] as String,
        label: json['label'] as String,
        reason: json['reason'] as String,
        suggestedNextStep: json['suggestedNextStep'] as String,
        keywords: (json['keywords'] as List).map((e) => e.toString()).toList(),
      );
}

class ReferralCheckResult {
  final bool flagged;
  final String? categoryLabel;
  final String? reason;
  final String? suggestedNextStep;

  const ReferralCheckResult({
    required this.flagged,
    this.categoryLabel,
    this.reason,
    this.suggestedNextStep,
  });

  static const none = ReferralCheckResult(flagged: false);
}

/// On-device keyword rule engine, driven entirely by the editable config asset
/// (assets/config/referral_categories.json — mirrored in backend/src/referral for
/// the server's LLM-assisted second check). This is what lets the app flag a case
/// for referral even with zero connectivity.
class ReferralService {
  List<ReferralCategory>? _categories;

  Future<List<ReferralCategory>> _load() async {
    if (_categories != null) return _categories!;
    final raw = await rootBundle.loadString('assets/config/referral_categories.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _categories = (json['categories'] as List)
        .map((e) => ReferralCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    return _categories!;
  }

  Future<ReferralCheckResult> check(String description) async {
    final categories = await _load();
    final text = description.toLowerCase();
    for (final category in categories) {
      final hit = category.keywords.any((kw) => text.contains(kw.toLowerCase()));
      if (hit) {
        return ReferralCheckResult(
          flagged: true,
          categoryLabel: category.label,
          reason: category.reason,
          suggestedNextStep: category.suggestedNextStep,
        );
      }
    }
    return ReferralCheckResult.none;
  }
}
