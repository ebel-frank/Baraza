import 'package:flutter/material.dart';

import '../theme.dart';

class ReferralBanner extends StatelessWidget {
  final String? reason;
  final String? suggestedNextStep;

  const ReferralBanner({super.key, this.reason, this.suggestedNextStep});

  @override
  Widget build(BuildContext context) {
    final risk = RiskColors.of(context, 'high');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: risk.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.flag_rounded, color: risk.fg, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This case may be outside mediation’s normal scope',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: risk.fg,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          if (reason != null) ...[
            const SizedBox(height: 8),
            Text(reason!, style: TextStyle(color: risk.fg, height: 1.4)),
          ],
          if (suggestedNextStep != null) ...[
            const SizedBox(height: 8),
            Text(
              'Suggested next step: $suggestedNextStep',
              style: TextStyle(
                color: risk.fg,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'This is a prompt to consider referral, not a diagnosis. Use your judgement.',
            style: TextStyle(
              fontSize: 12,
              color: risk.fg.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
