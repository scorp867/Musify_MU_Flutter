import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E293B);
  static const primary = Color(0xFF3B82F6);
  static const secondary = Color(0xFF60A5FA);
  static const localAccent = Color(0xFF10B981);

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
    ),
    fontFamily: 'Poppins',
  );
}
