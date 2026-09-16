import 'package:flutter/material.dart';

import '../app_services.dart';
import '../constants/african_countries.dart';
import '../constants/dev_flags.dart';
import '../services/auth_api_client.dart';
import '../services/mediator_profile_service.dart';
import '../widgets/auth_header.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final AppServices services;

  const RegisterScreen({super.key, required this.services});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _otherCountryController = TextEditingController();
  final _regionController = TextEditingController();
  final _localityController = TextEditingController();

  String _country = 'Kenya';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _saving = false;
  String? _error;

  bool get _isOtherCountry => _country == countryOptionOther;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _otherCountryController.dispose();
    _regionController.dispose();
    _localityController.dispose();
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
      // with a local placeholder session built from what was typed. Flip
      // kSkipAuthApiCalls off once a backend is reachable to restore the real
      // register call.
      final username = _usernameController.text.trim();
      final profile = MediatorProfile(
        id: 'local-$username',
        username: username,
        fullName: _fullNameController.text.trim(),
        country: _isOtherCountry ? _otherCountryController.text.trim() : _country,
        region: _regionController.text.trim(),
        locality: _localityController.text.trim(),
      );
      await widget.services.authSessionService.saveSession('dev-bypass-token', profile);
      await widget.services.demoSeedService.seedIfNeeded(widget.services.db);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(services: widget.services, mediator: profile),
        ),
        (route) => false,
      );
      return;
    }

    try {
      final AuthResult result = await widget.services.authApiClient.register(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        country: _isOtherCountry ? _otherCountryController.text.trim() : _country,
        region: _regionController.text.trim(),
        locality: _localityController.text.trim(),
      );
      await widget.services.authSessionService.saveSession(result.token, result.profile);
      await widget.services.demoSeedService.seedIfNeeded(widget.services.db);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(services: widget.services, mediator: result.profile),
        ),
        (route) => false,
      );
    } on AuthApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const AuthHeader(icon: Icons.person_add_alt, showBack: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Register', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Please register to login.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Needs an internet connection once — logging cases afterward works fully offline.',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 3) ? 'At least 3 characters' : null,
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
                        validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (v != _passwordController.text) ? 'Passwords do not match' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _country,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          prefixIcon: Icon(Icons.public),
                          border: OutlineInputBorder(),
                        ),
                        items: countryDropdownOptions
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _country = v ?? _country),
                      ),
                      if (_isOtherCountry) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _otherCountryController,
                          decoration: const InputDecoration(labelText: 'Country name', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _regionController,
                        decoration: const InputDecoration(
                          labelText: 'Region / county / state',
                          prefixIcon: Icon(Icons.map_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _localityController,
                        decoration: const InputDecoration(
                          labelText: 'Locality / town / ward',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                            : const Text('Sign Up'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? '),
                          GestureDetector(
                            onTap: _saving ? null : () => Navigator.of(context).maybePop(),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
