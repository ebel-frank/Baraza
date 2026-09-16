import 'db/database.dart';
import 'services/advisory_api_client.dart';
import 'services/auth_api_client.dart';
import 'services/auth_session_service.dart';
import 'services/backend_config.dart';
import 'services/demo_seed_service.dart';
import 'services/referral_service.dart';
import 'services/sync_service.dart';

/// Simple hand-rolled service locator — deliberately not pulling in a state
/// management package for a hackathon-scope app with this few screens.
class AppServices {
  final AppDatabase db;
  final AuthSessionService authSessionService;
  final AuthApiClient authApiClient;
  final ReferralService referralService;
  final BackendConfig backendConfig;
  final AdvisoryApiClient advisoryApiClient;
  final SyncService syncService;
  final DemoSeedService demoSeedService;

  AppServices._(
    this.db,
    this.authSessionService,
    this.authApiClient,
    this.referralService,
    this.backendConfig,
    this.advisoryApiClient,
    this.syncService,
    this.demoSeedService,
  );

  static AppServices create() {
    final db = AppDatabase();
    final backendConfig = BackendConfig();
    final authSessionService = AuthSessionService();
    return AppServices._(
      db,
      authSessionService,
      AuthApiClient(config: backendConfig),
      ReferralService(),
      backendConfig,
      AdvisoryApiClient(config: backendConfig, authSessionService: authSessionService),
      SyncService(db: db, backendConfig: backendConfig, authSessionService: authSessionService),
      DemoSeedService(),
    );
  }
}
