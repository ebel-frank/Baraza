import 'package:flutter/material.dart';

import '../app_services.dart';
import '../services/mediator_profile_service.dart';
import '../theme.dart';
import '../widgets/case_list_tile.dart';
import 'case_detail_screen.dart';
import 'new_case_screen.dart';
import 'sync_status_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppServices services;
  final MediatorProfile mediator;

  const HomeScreen({super.key, required this.services, required this.mediator});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.services.syncService.startAutoSync();
    // Best-effort push on open in case connectivity is already there.
    widget.services.syncService.pushPending();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baraza'),
        actions: [
          IconButton(
            tooltip: 'Sync status',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SyncStatusScreen(services: widget.services),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder(
        stream: widget.services.db.watchAllCases(),
        builder: (context, snapshot) {
          final cases = snapshot.data ?? const [];
          if (cases.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 40,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No cases logged yet.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap + to log your first case. It works fully offline.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final referredCount = cases.where((c) => c.referralFlag).length;
          final pendingCount = cases.where((c) => c.syncedAt == null).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Cases',
                      value: '${cases.length}',
                      icon: Icons.folder_open_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'Referred',
                      value: '$referredCount',
                      icon: Icons.priority_high_rounded,
                      emphasize: referredCount > 0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'Pending sync',
                      value: '$pendingCount',
                      icon: Icons.cloud_off_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              for (final c in cases) ...[
                CaseListTile(
                  caseRecord: c,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CaseDetailScreen(
                        services: widget.services,
                        caseId: c.id,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New case'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NewCaseScreen(
              services: widget.services,
              mediator: widget.mediator,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool emphasize;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valueColor = emphasize ? BarazaTheme.danger : scheme.onSurface;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
