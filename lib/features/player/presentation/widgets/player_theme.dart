import 'package:flutter/material.dart';

/// Dark-minimal design tokens — near-black backgrounds, amber/gold accent.
abstract final class PlayerColors {
  // Backgrounds
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const surfaceHigh = Color(0xFF1C1C1C);

  // Accent
  static const accent = Color(0xFFFFB300);
  static const accentDim = Color(0xFFCC8F00);

  // Text
  static const textPrimary = Color(0xFFE8E8E8);
  static const textSecondary = Color(0xFF8A8A8A);
  static const muted = Color(0xFF5C5C5C);

  // Misc
  static const divider = Color(0xFF1E1E1E);
  static const shimmer = Color(0xFF252525);
  static final BoxDecoration panelDecoration = BoxDecoration(
    color: surfaceHigh,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: divider),
  );
}
