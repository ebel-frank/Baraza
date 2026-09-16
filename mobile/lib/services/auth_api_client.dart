import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_config.dart';
import 'mediator_profile_service.dart';

class AuthResult {
  final String token;
  final MediatorProfile profile;

  AuthResult({required this.token, required this.profile});
}

class AuthApiException implements Exception {
  final String message;
  AuthApiException(this.message);
  @override
  String toString() => message;
}

/// Register/sign-in call the backend and need connectivity; case logging stays
/// offline afterward (AuthSessionService caches the resulting session on-device).
class AuthApiClient {
  final BackendConfig _config;

  AuthApiClient({BackendConfig? config}) : _config = config ?? BackendConfig();

  Future<AuthResult> register({
    required String username,
    required String password,
    required String fullName,
    required String country,
    required String region,
    required String locality,
  }) =>
      _post('/auth/register', {
        'username': username,
        'password': password,
        'fullName': fullName,
        'country': country,
        'region': region,
        'locality': locality,
      });

  Future<AuthResult> login({required String username, required String password}) =>
      _post('/auth/login', {'username': username, 'password': password});

  Future<AuthResult> _post(String path, Map<String, dynamic> body) async {
    final baseUrl = await _config.getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    http.Response response;
    try {
      response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      throw AuthApiException(
          'Could not reach the backend at $baseUrl. Registering and signing in need an internet connection. ($e)');
    }

    if (response.statusCode == 401) {
      throw AuthApiException('Incorrect username or password.');
    }
    if (response.statusCode == 409) {
      throw AuthApiException('That username is already taken.');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthApiException('Backend returned ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthResult(
      token: json['token'] as String,
      profile: MediatorProfile.fromJson(json['mediator'] as Map<String, dynamic>),
    );
  }
}
