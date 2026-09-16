import 'package:flutter/material.dart';

/// Decorative curved header shared by the sign-in and register screens —
/// a colored panel with soft circle accents and a centered icon, echoing a
/// typical auth-screen illustration without needing an actual image asset.
class AuthHeader extends StatelessWidget {
  final IconData icon;
  final bool showBack;

  const AuthHeader({super.key, required this.icon, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(48),
                bottomRight: Radius.circular(48),
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -30,
            child: CircleAvatar(radius: 70, backgroundColor: scheme.onPrimary.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: -24,
            left: -24,
            child: CircleAvatar(radius: 56, backgroundColor: scheme.onPrimary.withValues(alpha: 0.08)),
          ),
          Center(child: Icon(icon, size: 72, color: scheme.onPrimary)),
          if (showBack)
            Positioned(
              top: 4,
              left: 4,
              child: SafeArea(
                bottom: false,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: scheme.onPrimary),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
