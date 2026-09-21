import 'package:flutter/material.dart';

import 'app_services.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sign_in_screen.dart';
import 'services/auth_session_service.dart';

void main() {
  runApp(const BarazaApp());
}

class BarazaApp extends StatefulWidget {
  const BarazaApp({super.key});

  @override
  State<BarazaApp> createState() => _BarazaAppState();
}

class _BarazaAppState extends State<BarazaApp> {
  late final AppServices _services;
  late final Future<AuthSession?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _services = AppServices.create();
    _sessionFuture = _services.authSessionService.getSession();
  }

  @override
  void dispose() {
    _services.syncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baraza',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: FutureBuilder<AuthSession?>(
        future: _sessionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final session = snapshot.data;
          if (session == null) {
            return SignInScreen(services: _services);
          }
          if (session.profile.isAdmin) {
            return AdminDashboardScreen(services: _services);
          }
          return HomeScreen(services: _services, mediator: session.profile);
        },
      ),
    );
  }
}
