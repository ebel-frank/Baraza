import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_services.dart';
import '../services/admin_api_client.dart';
import '../theme.dart';
import '../widgets/nigeria_heatmap.dart';
import 'admin_case_detail_screen.dart';
import 'sign_in_screen.dart';

/// Overseeing-institution dashboard: full, unanonymized case data grouped by
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
  String? _caseTypeFilter;

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
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await widget.services.authSessionService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SignInScreen(services: widget.services),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case overview'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(top: false, child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No cases logged yet.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final visibleCases = overview.cases
        .where((c) => _regionFilter == null || c.region == _regionFilter)
        .where((c) => _caseTypeFilter == null || c.caseType == _caseTypeFilter)
        .toList();
    final referredTotal = overview.cases.where((c) => c.referralFlag).length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SubtitleBanner(regionCount: overview.regions.length),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Total cases',
                  value: '${overview.cases.length}',
                  icon: Icons.folder_open_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Referred',
                  value: '$referredTotal',
                  icon: Icons.priority_high_rounded,
                  emphasize: referredTotal > 0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Regions',
                  value: '${overview.regions.length}',
                  icon: Icons.map_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('By region', style: Theme.of(context).textTheme.titleMedium),
              if (_regionFilter != null)
                TextButton(
                  onPressed: () => setState(() => _regionFilter = null),
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _regionFilter == null
                ? 'Tap a state to see its cases.'
                : '$_regionFilter selected: ${visibleCases.length} case${visibleCases.length == 1 ? '' : 's'}.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: NigeriaHeatmap(
                regions: overview.regions,
                selectedRegion: _regionFilter,
                onSelectRegion: (region) =>
                    setState(() => _regionFilter = region),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'By case type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_caseTypeFilter != null)
                TextButton(
                  onPressed: () => setState(() => _caseTypeFilter = null),
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'What kinds of disputes are arising, most common first.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  for (final t in overview.caseTypes)
                    _CaseTypeBar(
                      caseType: t.caseType,
                      count: t.count,
                      referralFlagCount: t.referralFlagCount,
                      maxCount: overview.caseTypes.first.count,
                      selected: _caseTypeFilter == t.caseType,
                      onTap: () => setState(
                        () => _caseTypeFilter = _caseTypeFilter == t.caseType
                            ? null
                            : t.caseType,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cases (${visibleCases.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          for (final c in visibleCases) ...[
            _AdminCaseCard(caseData: c),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SubtitleBanner extends StatelessWidget {
  final int regionCount;
  const _SubtitleBanner({required this.regionCount});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: scheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Full case detail across $regionCount Nigerian states, for the overseeing institution.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
        ],
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

class _CaseTypeBar extends StatelessWidget {
  final String caseType;
  final int count;
  final int referralFlagCount;
  final int maxCount;
  final bool selected;
  final VoidCallback onTap;

  const _CaseTypeBar({
    required this.caseType,
    required this.count,
    required this.referralFlagCount,
    required this.maxCount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final barColor = referralFlagCount > 0
        ? BarazaTheme.danger
        : scheme.primary;
    final fraction = maxCount == 0 ? 0.0 : count / maxCount;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    caseType,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13.5,
                      color: selected ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                ),
                if (referralFlagCount > 0) ...[
                  Icon(
                    Icons.priority_high_rounded,
                    size: 13,
                    color: BarazaTheme.danger,
                  ),
                  const SizedBox(width: 2),
                ],
                Text(
                  '$count',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Container(height: 7, color: scheme.surfaceContainerHigh),
                    Container(
                      height: 7,
                      width: constraints.maxWidth * fraction,
                      color: barColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdminCaseDetailScreen(caseData: caseData),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: caseData.referralFlag
                    ? BarazaTheme.danger
                    : Colors.transparent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              caseData.caseType,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          if (caseData.referralFlag) _ReferredBadge(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        caseData.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _MetaItem(
                            icon: Icons.place_outlined,
                            text: '${caseData.locality}, ${caseData.region}',
                          ),
                          _MetaItem(
                            icon: Icons.person_outline,
                            text: caseData.mediatorName,
                          ),
                          if (date != null)
                            _MetaItem(
                              icon: Icons.event_outlined,
                              text: DateFormat.yMMMd().format(date),
                            ),
                          if (caseData.closedAt != null) _ClosedBadge(),
                        ],
                      ),
                      if (caseData.referralFlag &&
                          caseData.referralReason != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: RiskColors.of(context, 'high').bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            caseData.referralReason!,
                            style: TextStyle(
                              color: RiskColors.of(context, 'high').fg,
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClosedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final risk = RiskColors.of(context, 'low');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: risk.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        'Closed',
        style: TextStyle(
          color: risk.fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReferredBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final risk = RiskColors.of(context, 'high');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: risk.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        'Referred',
        style: TextStyle(
          color: risk.fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
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
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }
}
