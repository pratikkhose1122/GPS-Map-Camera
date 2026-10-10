import 'package:flutter/material.dart';

/// Professional dark camera theme for GPS Map Camera.
///
/// Design direction: dark camera interface, practical, professional.
/// No decorative gradients or glowing effects.
class AppTheme {
  AppTheme._();

  // ── Color palette ──────────────────────────────────────────────────────

  static const Color _surface = Color(0xFF121212);
  static const Color _background = Color(0xFF0A0A0A);
  static const Color _card = Color(0xFF1E1E1E);
  static const Color _brandAccentDark = Color(
    0xFFFFB300,
  ); // Yellow/Orange for dark mode
  static const Color _onPrimary = Color(0xFFFFFFFF);
  static const Color _onSurface = Color(0xFFE0E0E0);
  static const Color _onSurfaceVariant = Color(0xFF9E9E9E);
  static const Color _error = Color(0xFFCF6679);
  static const Color _outline = Color(0xFF2C2C2C);

  // ── Light Palette ──────────────────────────────────────────────────────
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _backgroundLight = Color(0xFFF5F7FA); // Very light grey
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _brandAccentLight = Color(0xFFF59E0B); // Amber/Orange 500
  static const Color _onPrimaryLight = Color(0xFFFFFFFF);
  static const Color _onSurfaceLight = Color(0xFF1F2937); // Dark slate
  static const Color _onSurfaceVariantLight = Color(0xFF6B7280); // Muted slate
  static const Color _errorLight = Color(0xFFDC2626);
  static const Color _outlineLight = Color(0xFFE5E7EB);

  // ── Theme ──────────────────────────────────────────────────────────────

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      surface: _surface,
      primary: _brandAccentDark,
      onPrimary: _onPrimary,
      onSurface: _onSurface,
      onSurfaceVariant: _onSurfaceVariant,
      error: _error,
      outline: _outline,
      surfaceContainerHighest: _card,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _background,
      cardColor: _card,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _brandAccentDark,
        foregroundColor: _onPrimary,
        elevation: 2,
        highlightElevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _card,
        contentTextStyle: const TextStyle(color: _onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      iconTheme: const IconThemeData(color: _onSurface),
      dividerTheme: const DividerThemeData(
        color: _outline,
        space: 1,
        thickness: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get light {
    final colorScheme = const ColorScheme.light(
      surface: _surfaceLight,
      primary: _brandAccentLight,
      onPrimary: _onPrimaryLight,
      onSurface: _onSurfaceLight,
      onSurfaceVariant: _onSurfaceVariantLight,
      error: _errorLight,
      outline: _outlineLight,
      surfaceContainerHighest: _cardLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _backgroundLight,
      cardColor: _cardLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: _surfaceLight,
        foregroundColor: _onSurfaceLight,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _brandAccentLight,
        foregroundColor: _onPrimaryLight,
        elevation: 2,
        highlightElevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _onSurfaceLight,
        contentTextStyle: const TextStyle(color: _surfaceLight),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      iconTheme: const IconThemeData(color: _onSurfaceLight),
      dividerTheme: const DividerThemeData(
        color: _outlineLight,
        space: 1,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(iconColor: _onSurfaceVariantLight),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
