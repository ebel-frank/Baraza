import 'package:flutter/material.dart';

import '../theme.dart';

/// Compact "may need referral" pill. Kept deliberately short — the reason and
/// suggested next step already appear in full on the Guidance screen.
class ReferralBanner extends StatelessWidget {
  final String? reason;
  final String? suggestedNextStep;

  const ReferralBanner({super.key, this.reason, this.suggestedNextStep});

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
            'May need referral',
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
