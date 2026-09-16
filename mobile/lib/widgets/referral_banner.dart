import 'package:flutter/material.dart';

class ReferralBanner extends StatelessWidget {
  final String? reason;
  final String? suggestedNextStep;

  const ReferralBanner({super.key, this.reason, this.suggestedNextStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.flag, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This case may be outside mediation’s normal scope',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                ),
              ),
            ],
          ),
          if (reason != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(reason!)),
          if (suggestedNextStep != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Suggested next step: $suggestedNextStep',
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'This is a prompt to consider referral, not a diagnosis — use your judgement.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
