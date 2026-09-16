/// Fixed at the hosted Render backend — not user-configurable. To point at a
/// different backend (e.g. for local dev via `docker compose up` in
/// backend/), change this constant and rebuild.
const kBackendBaseUrl = 'https://baraza.onrender.com';

class BackendConfig {
  Future<String> getBaseUrl() async => kBackendBaseUrl;
}
