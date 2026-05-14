import 'package:flutter/material.dart';

class AppTheme {
  static const _seedColor = Color(0xFF00C8FF); // Electric cyan accent

  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF111820),
      onSurface: Colors.white,
      primary: _seedColor,
      secondary: const Color(0xFF7B8CDE),
      tertiary: const Color(0xFF00E5A0),
      error: const Color(0xFFFF5370),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: const Color(0xFF0A0E14),
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        color: base.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: base.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          elevation: 0,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: base.primary,
        inactiveTrackColor: const Color(0xFF1A2332),
        thumbColor: base.primary,
        overlayColor: base.primary.withOpacity(0.15),
        trackHeight: 5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
      ),
      dividerColor: Colors.white.withOpacity(0.07),
      iconTheme: const IconThemeData(color: Colors.white70),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28),
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
        bodyLarge: TextStyle(color: Colors.white70, fontSize: 15),
        bodyMedium: TextStyle(color: Colors.white54, fontSize: 13),
        labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      fontFamily: 'Roboto',
    );
  }
}