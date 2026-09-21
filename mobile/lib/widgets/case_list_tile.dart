import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/database.dart';
import '../theme.dart';

class CaseListTile extends StatelessWidget {
  final Case caseRecord;
  final VoidCallback onTap;

  const CaseListTile({
    super.key,
    required this.caseRecord,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final synced = caseRecord.syncedAt != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: caseRecord.referralFlag
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
                              caseRecord.caseType,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          if (caseRecord.referralFlag) ...[
                            Icon(
                              Icons.priority_high_rounded,
                              size: 16,
                              color: BarazaTheme.danger,
                            ),
                            const SizedBox(width: 2),
                          ],
                          _SyncBadge(synced: synced),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          _MetaItem(
                            icon: Icons.place_outlined,
                            text: caseRecord.location,
                          ),
                          _MetaItem(
                            icon: Icons.event_outlined,
                            text: DateFormat.yMMMd().format(
                              caseRecord.createdAt,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.outline,
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

class _SyncBadge extends StatelessWidget {
  final bool synced;
  const _SyncBadge({required this.synced});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = synced ? BarazaTheme.success : scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          synced ? 'Synced' : 'Pending',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
        ),
      ],
    );
  }
}
