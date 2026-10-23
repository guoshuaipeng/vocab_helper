import 'package:flutter/material.dart';

class AppTheme {
  static const seed = Color(0xFF4F8CFF);

  /// Disabled label: blend onSurface onto surface for an opaque color.
  /// Dark cards need higher alpha than Material's 0.38 to stay ~≥3:1 vs button face.
  static Color disabledForeground(ColorScheme scheme) {
    final alpha = scheme.brightness == Brightness.dark ? 0.70 : 0.45;
    return Color.alphaBlend(scheme.onSurface.withValues(alpha: alpha), scheme.surface);
  }

  static Color disabledBackground(ColorScheme scheme) {
    final alpha = scheme.brightness == Brightness.dark ? 0.18 : 0.12;
    return Color.alphaBlend(
      scheme.onSurface.withValues(alpha: alpha),
      scheme.surfaceContainerHighest,
    );
  }

  /// Approximate contrast ratio of two opaque colors (WCAG).
  static double contrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final bright = l1 > l2 ? l1 : l2;
    final dark = l1 > l2 ? l2 : l1;
    return (bright + 0.05) / (dark + 0.05);
  }

  static ThemeData _withButtons(ThemeData base) {
    final scheme = base.colorScheme;
    final fg = disabledForeground(scheme);
    final bg = disabledBackground(scheme);
    final filled = FilledButton.styleFrom(
      disabledForegroundColor: fg,
      disabledBackgroundColor: bg,
    );
    return base.copyWith(
      filledButtonTheme: FilledButtonThemeData(style: filled),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(disabledForegroundColor: fg),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(disabledForegroundColor: fg),
      ),
    );
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    return _withButtons(ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ));
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    return _withButtons(ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ));
  }
}
