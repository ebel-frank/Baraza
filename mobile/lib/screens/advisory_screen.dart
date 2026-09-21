import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/advisory_api_client.dart';
import '../theme.dart';

/// Shows a single "Ask for guidance" result: the mediator's next-step
/// recommendations plus the exact source excerpts they're grounded in. Kept
/// as its own screen (rather than inline on the case) since a mediator reads
/// this closely and it can get long once citations are included.
class AdvisoryScreen extends StatelessWidget {
  final String caseType;
  final AdvisoryResult advisory;

  const AdvisoryScreen({
    super.key,
    required this.caseType,
    required this.advisory,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Guidance')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(caseType, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              'Suggested next steps',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (advisory.suggestsReferral) ...[
              _ReferralCallout(note: advisory.referralNote),
              const SizedBox(height: 16),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                advisory.summary,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 24),
            Text('Sources', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Every claim above is grounded in one of these excerpts, never general knowledge.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            if (advisory.citations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'No sourced excerpt was confident enough to cite.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              )
            else
              for (final c in advisory.citations) ...[
                _CitationCard(citation: c),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 8),
            Text(
              'Generated ${DateFormat.yMMMd().add_jm().format(DateTime.parse(advisory.generatedAt))}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralCallout extends StatelessWidget {
  final String? note;
  const _ReferralCallout({required this.note});

  @override
  Widget build(BuildContext context) {
    final risk = RiskColors.of(context, 'high');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: risk.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.flag_rounded, color: risk.fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This case may need referral',
                  style: TextStyle(color: risk.fg, fontWeight: FontWeight.w700),
                ),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(note!, style: TextStyle(color: risk.fg)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CitationCard extends StatelessWidget {
  final AdvisoryCitation citation;
  const _CitationCard({required this.citation});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${citation.documentTitle}${citation.section != null ? ' (${citation.section})' : ''}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              citation.jurisdiction,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              citation.excerpt,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
