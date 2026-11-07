import 'package:flutter/material.dart';
import 'package:musify_mu/features/private_vault/domain/models/vault_theme.dart';

/// Semantic color palette for the Private Vault interfaces.
@immutable
final class VaultThemePalette {
  final Color scaffoldBackground;
  final Color cardBackground;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color mutedSurface;
  final Color danger;

  const VaultThemePalette({
    required this.scaffoldBackground,
    required this.cardBackground,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.mutedSurface,
    required this.danger,
  });

  /// Set 1: Deep Moss theme.
  /// #0f1f17, #1e3a2e, #3e5a3f, #6b7f67, #c7cbb8, #3d4337
  static const VaultThemePalette deepMoss = VaultThemePalette(
    scaffoldBackground: Color(0xFF0F1F17),
    cardBackground: Color(0xFF1E3A2E),
    cardBorder: Color(0xFF3E5A3F),
    textPrimary: Color(0xFFC7CBB8),
    textSecondary: Color(0xFF6B7F67),
    accent: Color(0xFF3E5A3F),
    mutedSurface: Color(0xFF3D4337),
    danger: Color(0xFFE57373),
  );

  /// Set 2: Obsidian Cream theme.
  /// #fffed0, #807e83, #403d3e, #262323, #121212
  static const VaultThemePalette obsidianCream = VaultThemePalette(
    scaffoldBackground: Color(0xFF121212),
    cardBackground: Color(0xFF262323),
    cardBorder: Color(0xFF403D3E),
    textPrimary: Color(0xFFFFFED0),
    textSecondary: Color(0xFF807E83),
    accent: Color(0xFF403D3E),
    mutedSurface: Color(0xFF1E1E1E),
    danger: Color(0xFFE57373),
  );

  /// Resolves the palette matching the specified [VaultTheme].
  static VaultThemePalette of(VaultTheme theme) {
    return switch (theme) {
      VaultTheme.deepMoss => deepMoss,
      VaultTheme.obsidianCream => obsidianCream,
    };
  }
}
