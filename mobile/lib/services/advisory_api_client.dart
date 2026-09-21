import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'auth_session_service.dart';
import 'backend_config.dart';

class AdvisoryCitation {
  final String documentTitle;
  final String jurisdiction;
  final String? section;
  final String excerpt;
  final double similarity;

  AdvisoryCitation({
    required this.documentTitle,
    required this.jurisdiction,
    required this.section,
    required this.excerpt,
    required this.similarity,
  });

  factory AdvisoryCitation.fromJson(Map<String, dynamic> json) => AdvisoryCitation(
        documentTitle: json['documentTitle'] as String,
        jurisdiction: json['jurisdiction'] as String,
        section: json['section'] as String?,
        excerpt: json['excerpt'] as String,
        similarity: (json['similarity'] as num).toDouble(),
      );
}

class AdvisoryResult {
  final String summary;
  final List<AdvisoryCitation> citations;
  final bool suggestsReferral;
  final String? referralNote;
  final String generatedAt;

  AdvisoryResult({
    required this.summary,
    required this.citations,
    required this.suggestsReferral,
    required this.referralNote,
    required this.generatedAt,
  });

  factory AdvisoryResult.fromJson(Map<String, dynamic> json) => AdvisoryResult(
        summary: json['summary'] as String,
        citations: (json['citations'] as List)
            .map((e) => AdvisoryCitation.fromJson(e as Map<String, dynamic>))
            .toList(),
        suggestsReferral: json['suggestsReferral'] as bool,
        referralNote: json['referralNote'] as String?,
        generatedAt: json['generatedAt'] as String,
      );

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'citations': citations
            .map((c) => {
                  'documentTitle': c.documentTitle,
                  'jurisdiction': c.jurisdiction,
                  'section': c.section,
                  'excerpt': c.excerpt,
                  'similarity': c.similarity,
                })
            .toList(),
        'suggestsReferral': suggestsReferral,
        'referralNote': referralNote,
        'generatedAt': generatedAt,
      };
}

class AdvisoryApiException implements Exception {
  final String message;
  AdvisoryApiException(this.message);
  @override
  String toString() => message;
}

class AdvisoryApiClient {
  final BackendConfig _config;
  final AuthSessionService _authSessionService;

  AdvisoryApiClient({BackendConfig? config, AuthSessionService? authSessionService})
      : _config = config ?? BackendConfig(),
        _authSessionService = authSessionService ?? AuthSessionService();

  /// [audioFilePaths] are the case's real voice-note recordings (if any) — sent
  /// alongside the description so the backend can have Gemini consider all of
  /// it when producing the summary, not just the transcribed text.
  Future<AdvisoryResult> query(
    String description, {
    String? caseId,
    List<String> audioFilePaths = const [],
  }) async {
    final session = await _authSessionService.getSession();
    if (session == null) {
      throw AdvisoryApiException('Not signed in.');
    }
    final baseUrl = await _config.getBaseUrl();
    final uri = Uri.parse('$baseUrl/advisory/query');
    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer ${session.token}'
        ..fields['description'] = description;
      if (caseId != null) request.fields['caseId'] = caseId;
      for (final path in audioFilePaths) {
        if (!await File(path).exists()) continue;
        // Voice notes are always recorded as WAV (see AudioRecorderService) —
        // set the content type explicitly since MultipartFile.fromPath
        // otherwise defaults to application/octet-stream.
        request.files.add(await http.MultipartFile.fromPath(
          'audio',
          path,
          contentType: MediaType('audio', 'wav'),
        ));
      }

      // Generous timeout: the backend retries Gemini up to 3 times with
      // exponential backoff on transient 503s (see GeminiClient), which can
      // add up to ~40s worst case even before a successful attempt's own
      // call time — 45s was cutting it too close.
      final streamedResponse = await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw AdvisoryApiException('Backend returned ${response.statusCode}: ${response.body}');
      }
      return AdvisoryResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on AdvisoryApiException {
      rethrow;
    } catch (e) {
      throw AdvisoryApiException(
          'Could not reach the advisory backend at $baseUrl. Check connectivity and the backend URL in Sync Status. ($e)');
    }
  }
}
