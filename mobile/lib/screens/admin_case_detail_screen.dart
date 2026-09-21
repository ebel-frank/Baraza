import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/admin_api_client.dart';
import '../theme.dart';

/// Full-screen view of a single case from the admin overview. The list card
/// already shows most of this, but a dedicated screen gives room to read the
/// full description and parties without competing with the rest of the list.
class AdminCaseDetailScreen extends StatelessWidget {
  final AdminCase caseData;

  const AdminCaseDetailScreen({super.key, required this.caseData});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(caseData.createdAt);
    final parties = (caseData.parties as List)
        .map((p) => (p as Map)['role'] as String? ?? 'Party')
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Case detail')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (caseData.referralFlag)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ReferralPill(),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    caseData.caseType,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                _StatusPill(closed: caseData.closedAt != null),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _MetaItem(
                  icon: Icons.place_outlined,
                  text: '${caseData.locality}, ${caseData.region}',
                ),
                if (date != null)
                  _MetaItem(
                    icon: Icons.event_outlined,
                    text: DateFormat.yMMMd().format(date),
                  ),
                _MetaItem(
                  icon: Icons.person_outline,
                  text: caseData.mediatorName,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (parties.isNotEmpty) ...[
              Text('Parties', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: parties.map((r) => Chip(label: Text(r))).toList(),
              ),
              const SizedBox(height: 20),
            ],
            Text('Description', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              caseData.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (caseData.referralFlag && caseData.referralReason != null) ...[
              const SizedBox(height: 20),
              Text(
                'Referral reason',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: RiskColors.of(context, 'high').bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  caseData.referralReason!,
                  style: TextStyle(
                    color: RiskColors.of(context, 'high').fg,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            if (caseData.closedAt != null) ...[
              const SizedBox(height: 20),
              Text('Resolved', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: RiskColors.of(context, 'low').bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.yMMMd().format(
                        DateTime.parse(caseData.closedAt!),
                      ),
                      style: TextStyle(
                        color: RiskColors.of(context, 'low').fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    if (caseData.resolutionNote != null &&
                        caseData.resolutionNote!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        caseData.resolutionNote!,
                        style: TextStyle(
                          color: RiskColors.of(context, 'low').fg,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool closed;
  const _StatusPill({required this.closed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = closed
        ? RiskColors.of(context, 'low').fg
        : scheme.onSurfaceVariant;
    final bg = closed
        ? RiskColors.of(context, 'low').bg
        : scheme.surfaceContainerHighest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        closed ? 'Closed' : 'Open',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReferralPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final risk = RiskColors.of(context, 'high');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: risk.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, color: risk.fg, size: 15),
          const SizedBox(width: 6),
          Text(
            'Referred',
            style: TextStyle(
              color: risk.fg,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
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
        Icon(icon, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
