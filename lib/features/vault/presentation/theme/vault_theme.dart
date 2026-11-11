import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
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
  });

  /// Convenience alias for scaffold background color.
  Color get scaffoldBackground => scaffold;

  /// Convenience alias for tone-on-tone border color.
  Color get toneOnToneBorder => border;

  /// Convenience alias for error and danger color.
  Color get errorTone => danger;

  /// Convenience alias for error color.
  Color get errorColor => danger;

  /// Creates a [VaultThemeData] instance from the given domain [palette].
  factory VaultThemeData.fromPalette(VaultThemePalettePolicyEnum palette) {
    switch (palette) {
      case VaultThemePalettePolicyEnum.warmEspresso:
        return const VaultThemeData(
          palette: VaultThemePalettePolicyEnum.warmEspresso,
          scaffold: Color(0xFF1A120E),
          background: Color(0xFF3A2418),
          surface: Color(0xFF6B4A2E),
          surfaceSubtle: Color(0xFF2A1B14),
          surfaceHighlight: Color(0xFF4A3022),
          border: Color(0xFF4A3320),
          borderSubtle: Color(0xFF332215),
          textHighSalience: Color(0xFFA88462),
          textMediumSalience: Color(0xFF8D6C4F),
          textLowSalience: Color(0xFF4A3322),
          accent: Color(0xFFD4B08C),
          danger: Color(0xFFA84438),
          overlayTint: Color(0xA61A120E),
        );
      case VaultThemePalettePolicyEnum.forestNoir:
        return const VaultThemeData(
          palette: VaultThemePalettePolicyEnum.forestNoir,
          scaffold: Color(0xFF0F1F17),
          background: Color(0xFF1E3A2E),
          surface: Color(0xFF3E5A3F),
          surfaceSubtle: Color(0xFF152A1F),
          surfaceHighlight: Color(0xFF284A39),
          border: Color(0xFF234233),
          borderSubtle: Color(0xFF193024),
          textHighSalience: Color(0xFF6B7F67),
          textMediumSalience: Color(0xFF52664F),
          textLowSalience: Color(0xFF284235),
          accent: Color(0xFF9EB29A),
          danger: Color(0xFF9C423B),
          overlayTint: Color(0xA60F1F17),
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
