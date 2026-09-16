import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_services.dart';
import 'sign_in_screen.dart';

class SyncStatusScreen extends StatefulWidget {
  final AppServices services;

  const SyncStatusScreen({super.key, required this.services});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  DateTime? _lastSyncedAt;
  int _pendingCount = 0;
  bool _syncing = false;
  String? _lastMessage;
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final lastSyncedAt = await widget.services.syncService.getLastSyncedAt();
    final pending = await widget.services.syncService.pendingCount();
    final url = await widget.services.backendConfig.getBaseUrl();
    setState(() {
      _lastSyncedAt = lastSyncedAt;
      _pendingCount = pending;
      _urlController.text = url;
    });
  }

  Future<void> _syncNow() async {
    setState(() {
      _syncing = true;
      _lastMessage = null;
    });
    final result = await widget.services.syncService.pushPending();
    setState(() {
      _syncing = false;
      _lastMessage = result.success
          ? 'Synced ${result.pushedCount} case(s).'
          : 'Sync failed: ${result.error}';
    });
    await _load();
  }

  Future<void> _saveUrl() async {
    await widget.services.backendConfig.setBaseUrl(_urlController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backend URL saved.')));
  }

  Future<void> _signOut() async {
    final pending = await widget.services.syncService.pendingCount();
    if (pending > 0) {
      if (!mounted) return;
      final shouldSyncNow = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Unsynced cases'),
          content: Text(
            'You have $pending case(s) not yet synced to the backend. Signing out '
            'clears this device’s local cache, so sync first or you’ll lose access '
            'to them here until you sign back in and they’re re-pulled — pending, '
            'never-synced cases cannot be recovered.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sync now')),
          ],
        ),
      );
      if (shouldSyncNow == true) {
        await _syncNow();
      }
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'This clears cases cached on this device. They’re safely synced and '
          'will come back the next time you sign in, on this or another device.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed != true) return;

    await widget.services.db.clearAllCases();
    await widget.services.authSessionService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => SignInScreen(services: widget.services)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync status')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lastSyncedAt == null
                          ? 'Never synced'
                          : 'Last synced: ${DateFormat.yMMMd().add_jm().format(_lastSyncedAt!)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('$_pendingCount case(s) pending sync'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _syncing ? null : _syncNow,
              icon: _syncing
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync),
              label: const Text('Sync now'),
            ),
            if (_lastMessage != null)
              Padding(padding: const EdgeInsets.only(top: 12), child: Text(_lastMessage!)),
            const SizedBox(height: 32),
            Text('Backend URL', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Android emulator: keep 10.0.2.2 (alias for your computer). '
              'Physical device on the same Wi-Fi: use your computer’s LAN IP instead.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _saveUrl, child: const Text('Save URL')),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
