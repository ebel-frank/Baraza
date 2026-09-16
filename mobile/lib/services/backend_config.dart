import 'package:shared_preferences/shared_preferences.dart';

/// 10.0.2.2 is the Android emulator's alias for the host machine's localhost,
/// which is where `docker-compose up` publishes the backend in the README flow.
/// For a physical device on the same Wi-Fi, change this to the host's LAN IP
/// from the Sync Status screen.
const kDefaultBackendBaseUrl = 'http://10.0.2.2:3000';

class BackendConfig {
  static const _key = 'backend_base_url';

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? kDefaultBackendBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url.trim());
  }
}
