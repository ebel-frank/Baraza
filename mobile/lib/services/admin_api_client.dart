import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_session_service.dart';
import 'backend_config.dart';

class AdminCase {
  final String id;
  final String caseType;
  final dynamic parties;
  final String description;
  final String location;
  final String createdAt;
  final bool referralFlag;
  final String? referralReason;
  final String mediatorName;
  final String region;
  final String locality;

  AdminCase({
    required this.id,
    required this.caseType,
    required this.parties,
    required this.description,
    required this.location,
    required this.createdAt,
    required this.referralFlag,
    required this.referralReason,
    required this.mediatorName,
    required this.region,
    required this.locality,
  });

  factory AdminCase.fromJson(Map<String, dynamic> json) => AdminCase(
        id: json['id'] as String,
        caseType: json['caseType'] as String,
        parties: json['parties'],
        description: json['description'] as String,
        location: json['location'] as String,
        createdAt: json['createdAt'] as String,
        referralFlag: json['referralFlag'] as bool,
        referralReason: json['referralReason'] as String?,
        mediatorName: json['mediatorName'] as String,
        region: json['region'] as String,
        locality: json['locality'] as String,
      );
}

class AdminRegionTotal {
  final String region;
  final int count;
  final int referralFlagCount;

  AdminRegionTotal({required this.region, required this.count, required this.referralFlagCount});

  factory AdminRegionTotal.fromJson(Map<String, dynamic> json) => AdminRegionTotal(
        region: json['region'] as String,
        count: json['count'] as int,
        referralFlagCount: json['referralFlagCount'] as int,
      );
}

class AdminCaseOverview {
  final List<AdminRegionTotal> regions;
  final List<AdminCase> cases;

  AdminCaseOverview({required this.regions, required this.cases});

  factory AdminCaseOverview.fromJson(Map<String, dynamic> json) => AdminCaseOverview(
        regions: (json['regions'] as List)
            .map((e) => AdminRegionTotal.fromJson(e as Map<String, dynamic>))
            .toList(),
        cases: (json['cases'] as List).map((e) => AdminCase.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class AdminApiException implements Exception {
  final String message;
  AdminApiException(this.message);
  @override
  String toString() => message;
}

/// Unanonymized case overview for the overseeing-institution admin dashboard —
/// only reachable with an admin-role token (see AdminGuard on the backend).
class AdminApiClient {
  final BackendConfig _config;
  final AuthSessionService _authSessionService;

  AdminApiClient({BackendConfig? config, AuthSessionService? authSessionService})
      : _config = config ?? BackendConfig(),
        _authSessionService = authSessionService ?? AuthSessionService();

  Future<AdminCaseOverview> fetchCaseOverview() async {
    final session = await _authSessionService.getSession();
    if (session == null) {
      throw AdminApiException('Not signed in.');
    }
    final baseUrl = await _config.getBaseUrl();
    final uri = Uri.parse('$baseUrl/admin/cases');
    http.Response response;
    try {
      response = await http.get(uri, headers: {'Authorization': 'Bearer ${session.token}'}).timeout(
        const Duration(seconds: 20),
      );
    } catch (e) {
      throw AdminApiException('Could not reach the backend at $baseUrl. ($e)');
    }

    if (response.statusCode == 403) {
      throw AdminApiException('This account does not have admin access.');
    }
    if (response.statusCode != 200) {
      throw AdminApiException('Backend returned ${response.statusCode}: ${response.body}');
    }
    return AdminCaseOverview.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
