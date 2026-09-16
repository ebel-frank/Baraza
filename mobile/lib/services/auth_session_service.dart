import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'mediator_profile_service.dart';

class AuthSession {
  final String token;
  final MediatorProfile profile;

  AuthSession({required this.token, required this.profile});
}

/// Persists the signed-in mediator's session (JWT + profile) on-device so the
/// app doesn't need connectivity just to reopen — only register/login/sign-out
/// touch the network.
///
/// NEXT STEP (not done here): the token is stored in plain shared_preferences;
/// a real deployment should use secure/encrypted storage instead.
class AuthSessionService {
  static const _keyToken = 'session_token';
  static const _keyProfile = 'session_profile';

  Future<AuthSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final profileJson = prefs.getString(_keyProfile);
    if (token == null || profileJson == null) return null;
    return AuthSession(
      token: token,
      profile: MediatorProfile.fromJson(jsonDecode(profileJson) as Map<String, dynamic>),
    );
  }

  Future<void> saveSession(String token, MediatorProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyProfile);
  }
}
