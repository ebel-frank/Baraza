import 'package:flutter/material.dart';

import '../app_services.dart';
import '../constants/demo_credentials.dart';
import '../constants/dev_flags.dart';
import '../services/auth_api_client.dart';
import '../services/mediator_profile_service.dart';
import '../widgets/auth_header.dart';
import 'admin_dashboard_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class SignInScreen extends StatefulWidget {
  final AppServices services;

  const SignInScreen({super.key, required this.services});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  // Pre-filled with the seeded demo account so there's nothing to type once
  // a backend has been hosted + seeded (`docker compose exec backend npm run seed`).
  final _usernameController = TextEditingController(text: kDemoUsername);
  final _passwordController = TextEditingController(text: kDemoPassword);
  bool _obscurePassword = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    if (kSkipAuthApiCalls) {
      // No backend hosted yet — skip the network call and go straight to Home
      // with a local placeholder session. Flip kSkipAuthApiCalls off once a
      // backend is reachable to restore the real sign-in call.
      final username = _usernameController.text.trim();
      final profile = MediatorProfile(
        id: 'local-$username',
        username: username,
        fullName: username,
        country: 'Nigeria',
        region: 'N/A',
        locality: 'N/A',
      );
      await widget.services.authSessionService.saveSession('dev-bypass-token', profile);
      if (!mounted) return;
      _navigateAfterLogin(profile);
      return;
    }

    try {
      final AuthResult result = await widget.services.authApiClient.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      await widget.services.authSessionService.saveSession(result.token, result.profile);
      if (!result.profile.isAdmin) {
        // Recover any cases already synced under this account (e.g. a new/reinstalled app).
        await widget.services.syncService.pullFromServer();
      }
      if (!mounted) return;
      _navigateAfterLogin(result.profile);
    } on AuthApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _navigateAfterLogin(MediatorProfile profile) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => profile.isAdmin
            ? AdminDashboardScreen(services: widget.services)
            : HomeScreen(services: widget.services, mediator: profile),
      ),
      (route) => false,
    );
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RegisterScreen(services: widget.services)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const AuthHeader(icon: Icons.balance),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Login', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Please sign in to continue.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_error!, style: const TextStyle(color: Colors.red)),
                        ),
                      FilledButton(
                        onPressed: _saving ? null : _submit,
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _saving
                            ? const SizedBox(
                                height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Sign In'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          GestureDetector(
                            onTap: _saving ? null : _goToRegister,
                            child: Text(
                              'Register',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  _usernameController.text = kAdminUsername;
                                  _passwordController.text = kAdminPassword;
                                },
                          child: const Text('Signing in as the overseeing institution? Use the admin demo account'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
