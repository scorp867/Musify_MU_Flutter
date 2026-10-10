import 'package:flutter/material.dart';

/// Dark-minimal Spotify design tokens — #121212 background, #1ED760 green accent.
abstract final class PlayerColors {
  // Backgrounds
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF181818);
  static const surfaceHigh = Color(0xFF242424);

  // Accent (Authentic Spotify Green)
  static const accent = Color(0xFF1ED760);
  static const accentDim = Color(0xFF169C46);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB3B3B3);
  static const muted = Color(0xFF727272);

  // Misc
  static const divider = Color(0xFF282828);
  static const shimmer = Color(0xFF252525);
  static final BoxDecoration panelDecoration = BoxDecoration(
    color: surfaceHigh,
    borderRadius: BorderRadius.circular(16),
  );
}
