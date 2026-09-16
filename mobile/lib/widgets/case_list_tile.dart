import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/database.dart';

class CaseListTile extends StatelessWidget {
  final Case caseRecord;
  final VoidCallback onTap;

  const CaseListTile({super.key, required this.caseRecord, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final synced = caseRecord.syncedAt != null;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: caseRecord.referralFlag
            ? Colors.orange.shade100
            : Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          caseRecord.referralFlag ? Icons.flag : Icons.gavel,
          color: caseRecord.referralFlag ? Colors.orange.shade800 : null,
        ),
      ),
      title: Text(caseRecord.caseType, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${caseRecord.location} · ${DateFormat.yMMMd().format(caseRecord.createdAt)}',
      ),
      trailing: Chip(
        label: Text(synced ? 'Synced' : 'Pending'),
        avatar: Icon(synced ? Icons.cloud_done : Icons.cloud_off, size: 16),
        visualDensity: VisualDensity.compact,
        backgroundColor: synced ? Colors.green.shade50 : Colors.grey.shade200,
      ),
    );
  }
}
