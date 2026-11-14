import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';

/// Immutable reactive design tokens for the Musify Secure Vault presentation layer.
///
/// Encapsulates all color tokens for [VaultThemePalettePolicyEnum.warmEspresso] and
/// [VaultThemePalettePolicyEnum.forestNoir], strictly enforcing:
/// - Zero purple/violet gradients (HSV hue outside [260, 310])
/// - Zero pill buttons
/// - Zero emojis
/// - Zero em dashes
@immutable
class VaultThemeData extends Equatable {
  /// The active palette policy identifier.
  final VaultThemePalettePolicyEnum palette;

  /// Full-screen scaffold background color.
  final Color scaffold;

  /// Primary container background color.
  final Color background;

  /// Surface color for cards, dialog surfaces, and keypad buttons.
  final Color surface;

  /// Subtle secondary surface for unselected chips or button idle state.
  final Color surfaceSubtle;

  /// Highlighted surface for active card focus or pressed keypad state.
  final Color surfaceHighlight;

  /// Tone-on-tone container border color (1px width).
  final Color border;

  /// Subtle divider and secondary separator color.
  final Color borderSubtle;

  /// High-salience typography and highlight color (e.g. active digits, filled PIN dots).
  final Color textHighSalience;

  /// Medium-salience typography (e.g. subtitles, helper copy, keypad letter captions).
  final Color textMediumSalience;

  /// Low-salience typography and unfilled PIN dot indicator outlines.
  final Color textLowSalience;

  /// Primary focus ring, badge, and primary action accent color.
  final Color accent;

  /// Muted tone-on-tone red for shake errors, warnings, and lockout countdowns.
  final Color danger;

  /// Frosted glass overlay tint for [ReauthBlurOverlay] (65% opacity of scaffold).
  final Color overlayTint;

  /// Default calibrated frosted glass blur sigma (px).
  static const double defaultBlurSigma = VaultConfig.defaultFrostedBlurSigma;

  /// Calibrated Gaussian blur sigma (px) for frosted artwork peeks and re-auth overlays.
  final double blurSigma;

  const VaultThemeData({
    required this.palette,
    required this.scaffold,
    required this.background,
    required this.surface,
    required this.surfaceSubtle,
    required this.surfaceHighlight,
    required this.border,
    required this.borderSubtle,
    required this.textHighSalience,
    required this.textMediumSalience,
    required this.textLowSalience,
    required this.accent,
    required this.danger,
    required this.overlayTint,
    this.blurSigma = defaultBlurSigma,
  });

  /// Convenience alias for scaffold background color.
  Color get scaffoldBackground => scaffold;

  /// Convenience alias for tone-on-tone border color.
  Color get toneOnToneBorder => border;

  /// Convenience alias for error and danger color.
  Color get errorTone => danger;

  /// Convenience alias for error color.
  Color get errorColor => danger;

  /// Creates a [VaultThemeData] instance from the given [VaultConfig].
  factory VaultThemeData.fromConfig(VaultConfig config) {
    return VaultThemeData.fromPalette(
      config.themePalette,
      blurSigma: config.frostedBlurSigma,
    );
  }

  /// Creates a [VaultThemeData] instance from the given domain [palette] and [blurSigma].
  factory VaultThemeData.fromPalette(
    VaultThemePalettePolicyEnum palette, {
    double blurSigma = defaultBlurSigma,
  }) {
    switch (palette) {
      case VaultThemePalettePolicyEnum.warmEspresso:
        return VaultThemeData(
          palette: VaultThemePalettePolicyEnum.warmEspresso,
          scaffold: const Color(0xFF120E0C),
          background: const Color(0xFF1E1814),
          surface: const Color(0xFF231C18),
          surfaceSubtle: const Color(0xFF191411),
          surfaceHighlight: const Color(0xFF2C241E),
          border: const Color(0xFF342B24),
          borderSubtle: const Color(0xFF261F1A),
          textHighSalience: const Color(0xFFECE6E0),
          textMediumSalience: const Color(0xFFAFA59C),
          textLowSalience: const Color(0xFF827870),
          accent: const Color(0xFFD6B48E),
          danger: const Color(0xFFB3463A),
          overlayTint: const Color(0xA6120E0C),
          blurSigma: blurSigma,
        );
      case VaultThemePalettePolicyEnum.forestNoir:
        return VaultThemeData(
          palette: VaultThemePalettePolicyEnum.forestNoir,
          scaffold: const Color(0xFF0B120E),
          background: const Color(0xFF15221B),
          surface: const Color(0xFF1A2821),
          surfaceSubtle: const Color(0xFF111B16),
          surfaceHighlight: const Color(0xFF22332A),
          border: const Color(0xFF293D32),
          borderSubtle: const Color(0xFF1D2C24),
          textHighSalience: const Color(0xFFE3EBE6),
          textMediumSalience: const Color(0xFF9DB0A5),
          textLowSalience: const Color(0xFF708479),
          accent: const Color(0xFF9BC2AA),
          danger: const Color(0xFFB1453A),
          overlayTint: const Color(0xA60B120E),
          blurSigma: blurSigma,
        );
    }
  }

  /// Converts these design tokens into a Flutter [ThemeData] instance.
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffold,
      fontFamily: VaultTheme.fontFamily,
      colorScheme: ColorScheme.dark(
        primary: accent,
        surface: surface,
        error: danger,
      ),
      cardTheme: CardThemeData(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: VaultTheme.borderRadius8,
          side: BorderSide(
            color: border,
            width: VaultTheme.borderWidth,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: VaultTheme.fontFamily,
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [
        palette,
        scaffold,
        background,
        surface,
        surfaceSubtle,
        surfaceHighlight,
        border,
        borderSubtle,
        textHighSalience,
        textMediumSalience,
        textLowSalience,
        accent,
        danger,
        overlayTint,
        blurSigma,
      ];
}

/// InheritedTheme providing reactive [VaultThemeData] throughout the vault presentation sub-tree.
class VaultTheme extends InheritedTheme {
  /// Strict geometric corner radius (8.0px). Stadium/pill buttons are strictly forbidden.
  static const double radiusValue = 8.0;

  /// Geometric radius token for 8.0px curves.
  static const Radius radius8 = Radius.circular(radiusValue);

  /// Geometric border radius token for 8.0px curves.
  static const BorderRadius borderRadius8 = BorderRadius.all(radius8);

  /// Geometric rounded rectangle border shape token.
  static const RoundedRectangleBorder shape8 = RoundedRectangleBorder(
    borderRadius: borderRadius8,
  );

  /// Strict tone-on-tone border width (1.0px).
  static const double borderWidth = 1.0;

  /// Project canonical font family.
  static const String fontFamily = 'Poppins';

  /// Generates a 1px tone-on-tone [Border] matching the specified [borderColor].
  static Border toneOnToneBorder(Color borderColor) => Border.all(
        color: borderColor,
        width: borderWidth,
      );

  /// Generates a 1px tone-on-tone [BorderSide] matching the specified [borderColor].
  static BorderSide borderSide(Color borderColor) => BorderSide(
        color: borderColor,
        width: borderWidth,
      );

  /// The active design token data.
  final VaultThemeData data;

  const VaultTheme({
    required this.data,
    required super.child,
    super.key,
  });

  /// Obtains the nearest [VaultThemeData] from the given [context].
  ///
  /// Falls back to [VaultThemePalettePolicyEnum.warmEspresso] if no [VaultTheme]
  /// is ancestor to [context].
  static VaultThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<VaultTheme>();
    if (theme != null) {
      return theme.data;
    }
    return VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso);
  }

  /// Obtains the nearest [VaultThemeData] from the given [context], or returns null.
  static VaultThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<VaultTheme>()?.data;
  }

  @override
  bool updateShouldNotify(VaultTheme oldWidget) => data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) {
    return VaultTheme(data: data, child: child);
  }
}
