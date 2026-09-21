import 'package:flutter/material.dart';

import '../app_services.dart';
import '../services/mediator_profile_service.dart';
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
            icon: const Icon(Icons.sync),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SyncStatusScreen(services: widget.services)),
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: widget.services.db.watchAllCases(),
        builder: (context, snapshot) {
          final cases = snapshot.data ?? const [];
          if (cases.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No cases logged yet. Tap + to log your first case. It works fully offline.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: cases.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = cases[index];
              return CaseListTile(
                caseRecord: c,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CaseDetailScreen(services: widget.services, caseId: c.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New case'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NewCaseScreen(services: widget.services, mediator: widget.mediator),
          ),
        ),
      ),
    );
  }
}
