import 'package:flutter/material.dart';

class AppTheme {
  static const seed = Color(0xFF4F8CFF);

  /// Opaque-enough disabled label: onSurface@38% blended onto surface (readable on dark cards).
  static Color disabledForeground(ColorScheme scheme) {
    return Color.alphaBlend(scheme.onSurface.withValues(alpha: 0.38), scheme.surface);
  }

  static Color disabledBackground(ColorScheme scheme) {
    return Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.12),
      scheme.surfaceContainerHighest,
    );
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
