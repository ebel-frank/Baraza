import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_services.dart';
import '../services/admin_api_client.dart';
import 'sign_in_screen.dart';

/// Overseeing-institution dashboard — full, unanonymized case data grouped by
/// region, only reachable by an admin-role account (see AdminGuard on the
/// backend). Deliberately not anonymized: the government partner asked to see
/// exactly what cases are arising and where, now that the project is scoped
/// to Nigeria alone.
class AdminDashboardScreen extends StatefulWidget {
  final AppServices services;

  const AdminDashboardScreen({super.key, required this.services});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminCaseOverview? _overview;
  bool _loading = true;
  String? _error;
  String? _regionFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overview = await widget.services.adminApiClient.fetchCaseOverview();
      setState(() => _overview = overview);
    } on AdminApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed != true) return;

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
      appBar: AppBar(
        title: const Text('Case Overview — Nigeria'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final overview = _overview;
    if (overview == null) return const SizedBox.shrink();
    if (overview.cases.isEmpty) {
      return const Center(child: Text('No cases logged yet.'));
    }

    final visibleCases = _regionFilter == null
        ? overview.cases
        : overview.cases.where((c) => c.region == _regionFilter).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('By region', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RegionChip(
                label: 'All regions (${overview.cases.length})',
                selected: _regionFilter == null,
                onTap: () => setState(() => _regionFilter = null),
              ),
              for (final r in overview.regions)
                _RegionChip(
                  label: '${r.region} (${r.count})',
                  referralCount: r.referralFlagCount,
                  selected: _regionFilter == r.region,
                  onTap: () => setState(() => _regionFilter = r.region),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Cases (${visibleCases.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final c in visibleCases) _AdminCaseCard(caseData: c),
        ],
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  final String label;
  final int? referralCount;
  final bool selected;
  final VoidCallback onTap;

  const _RegionChip({required this.label, this.referralCount, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasEscalation = (referralCount ?? 0) > 0;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: hasEscalation ? const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange) : null,
    );
  }
}

class _AdminCaseCard extends StatelessWidget {
  final AdminCase caseData;

  const _AdminCaseCard({required this.caseData});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(caseData.createdAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(caseData.caseType, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (caseData.referralFlag)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text('Referred', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(caseData.description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _MetaItem(icon: Icons.place_outlined, text: '${caseData.locality}, ${caseData.region}'),
                _MetaItem(icon: Icons.person_outline, text: caseData.mediatorName),
                if (date != null) _MetaItem(icon: Icons.event_outlined, text: DateFormat.yMMMd().format(date)),
              ],
            ),
            if (caseData.referralFlag && caseData.referralReason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Referral reason: ${caseData.referralReason}',
                style: TextStyle(color: Colors.red.shade700, fontStyle: FontStyle.italic, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
      ],
    );
  }
}
