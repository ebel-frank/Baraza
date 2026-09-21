import 'package:flutter/material.dart';

/// Baraza's app-wide look. A deep, unfussy green (civic, trustworthy, not the
/// default Material teal) carries the brand; semantic colors for referral/
/// risk states are kept separate from it so they still read clearly against
/// either theme.
class BarazaTheme {
  static const _seed = Color(0xFF0B6E4F);

  static const success = Color(0xFF2F8F5B);
  static const warning = Color(0xFFB9821F);
  static const danger = Color(0xFFC1432B);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: _textTheme(scheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
        secondaryLabelStyle: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.6), space: 1),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    return TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.4, color: scheme.onSurface),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2, color: scheme.onSurface),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
      titleSmall: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
      bodyLarge: TextStyle(color: scheme.onSurface, height: 1.4),
      bodyMedium: TextStyle(color: scheme.onSurface, height: 1.4),
      bodySmall: TextStyle(color: scheme.onSurfaceVariant, height: 1.3),
      labelLarge: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
    );
  }
}

/// Semantic colors for a risk/severity level, distinct from the brand color
/// so escalation state always reads clearly regardless of theme.
class RiskColors {
  final Color fg;
  final Color bg;
  const RiskColors(this.fg, this.bg);

  static RiskColors of(BuildContext context, String level) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    switch (level) {
      case 'high':
        return dark ? const RiskColors(Color(0xFFE8735A), Color(0xFF3A1C16)) : const RiskColors(Color(0xFFC1432B), Color(0xFFFBE7E2));
      case 'medium':
        return dark ? const RiskColors(Color(0xFFE0B84E), Color(0xFF332B14)) : const RiskColors(Color(0xFFB9821F), Color(0xFFFBF1DC));
      default:
        return dark ? const RiskColors(Color(0xFF5CC191), Color(0xFF163024)) : const RiskColors(Color(0xFF2F8F5B), Color(0xFFE7F3EB));
    }
  }
}
