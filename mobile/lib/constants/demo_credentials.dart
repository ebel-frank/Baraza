/// Matches DEMO_USERNAME in backend/src/seed/seed.ts — the account `npm run
/// seed` creates on the backend. Pre-filled on the Sign In screen so there's
/// nothing to type but the password once you've hosted + seeded a backend.
const kDemoUsername = 'demo';

/// The seeded demo password isn't committed to source. Build with
/// `flutter run --dart-define=DEMO_PASSWORD=...` (matching whatever
/// DEMO_PASSWORD you set in the backend's .env) to have it pre-filled too;
/// otherwise the Sign In screen just leaves the password field blank.
const kDemoPassword = String.fromEnvironment('DEMO_PASSWORD');
