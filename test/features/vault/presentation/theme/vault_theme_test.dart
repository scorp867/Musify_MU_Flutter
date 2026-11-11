import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

void main() {
  group('VaultTheme & Token Architecture Tests', () {
    test('warmEspresso palette matches exact hex and ARGB specifications', () {
      final theme = VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso);
      expect(theme.scaffold, const Color(0xFF1A120E));
      expect(theme.scaffoldBackground, const Color(0xFF1A120E));
      expect(theme.background, const Color(0xFF3A2418));
      expect(theme.surface, const Color(0xFF6B4A2E));
      expect(theme.surfaceSubtle, const Color(0xFF2A1B14));
      expect(theme.surfaceHighlight, const Color(0xFF4A3022));
      expect(theme.border, const Color(0xFF4A3320));
      expect(theme.toneOnToneBorder, const Color(0xFF4A3320));
      expect(theme.borderSubtle, const Color(0xFF332215));
      expect(theme.textHighSalience, const Color(0xFFA88462));
      expect(theme.textMediumSalience, const Color(0xFF8D6C4F));
      expect(theme.textLowSalience, const Color(0xFF4A3322));
      expect(theme.accent, const Color(0xFFD4B08C));
      expect(theme.danger, const Color(0xFFA84438));
      expect(theme.errorTone, const Color(0xFFA84438));
      expect(theme.errorColor, const Color(0xFFA84438));
      expect(theme.overlayTint, const Color(0xA61A120E));
    });

    test('forestNoir palette matches exact hex and ARGB specifications', () {
      final theme = VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.forestNoir);
      expect(theme.scaffold, const Color(0xFF0F1F17));
      expect(theme.scaffoldBackground, const Color(0xFF0F1F17));
      expect(theme.background, const Color(0xFF1E3A2E));
      expect(theme.surface, const Color(0xFF3E5A3F));
      expect(theme.surfaceSubtle, const Color(0xFF152A1F));
      expect(theme.surfaceHighlight, const Color(0xFF284A39));
      expect(theme.border, const Color(0xFF234233));
      expect(theme.toneOnToneBorder, const Color(0xFF234233));
      expect(theme.borderSubtle, const Color(0xFF193024));
      expect(theme.textHighSalience, const Color(0xFF6B7F67));
      expect(theme.textMediumSalience, const Color(0xFF52664F));
      expect(theme.textLowSalience, const Color(0xFF284235));
      expect(theme.accent, const Color(0xFF9EB29A));
      expect(theme.danger, const Color(0xFF9C423B));
      expect(theme.errorTone, const Color(0xFF9C423B));
      expect(theme.errorColor, const Color(0xFF9C423B));
      expect(theme.overlayTint, const Color(0xA60F1F17));
    });

    test('Geometric border radius is strictly 8px across all shapes', () {
      expect(VaultTheme.radiusValue, 8.0);
      expect(VaultTheme.radius8, const Radius.circular(8.0));
      expect(VaultTheme.borderRadius8, const BorderRadius.all(Radius.circular(8.0)));
      expect(VaultTheme.shape8.borderRadius, const BorderRadius.all(Radius.circular(8.0)));
    });

    test('Tone-on-tone border width is strictly 1.0px', () {
      expect(VaultTheme.borderWidth, 1.0);
      final border = VaultTheme.toneOnToneBorder(const Color(0xFF4A3320));
      expect(border.top.width, 1.0);
      expect(border.top.color, const Color(0xFF4A3320));

      final borderSide = VaultTheme.borderSide(const Color(0xFF4A3320));
      expect(borderSide.width, 1.0);
      expect(borderSide.color, const Color(0xFF4A3320));
    });

    test('Poppins typography is enforced on all text themes', () {
      expect(VaultTheme.fontFamily, 'Poppins');
      final theme = VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso);
      final materialTheme = theme.toThemeData();
      expect(materialTheme.textTheme.bodyMedium?.fontFamily, 'Poppins');
      expect(materialTheme.appBarTheme.titleTextStyle?.fontFamily, 'Poppins');
    });

    test('Zero Purple Gradients Invariant: No color has HSV hue in [260, 310]', () {
      for (final palette in VaultThemePalettePolicyEnum.values) {
        final data = VaultThemeData.fromPalette(palette);
        final colors = [
          data.scaffold,
          data.background,
          data.surface,
          data.surfaceSubtle,
          data.surfaceHighlight,
          data.border,
          data.borderSubtle,
          data.textHighSalience,
          data.textMediumSalience,
          data.textLowSalience,
          data.accent,
          data.danger,
        ];
        for (final color in colors) {
          final hsv = HSVColor.fromColor(color);
          final isPurple = hsv.hue >= 260.0 && hsv.hue <= 310.0;
          expect(
            isPurple,
            isFalse,
            reason: 'Color $color in $palette has forbidden violet/purple hue ${hsv.hue}',
          );
        }
      }
    });

    test('VaultThemeData equality and props', () {
      final theme1 = VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso);
      final theme2 = VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso);
      final themeForest = VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.forestNoir);

      expect(theme1, equals(theme2));
      expect(theme1.hashCode, equals(theme2.hashCode));
      expect(theme1, isNot(equals(themeForest)));
    });

    testWidgets('VaultTheme.of(context) dynamically provides active palette', (tester) async {
      await tester.pumpWidget(
        VaultTheme(
          data: VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.forestNoir),
          child: Builder(
            builder: (context) {
              final activeTheme = VaultTheme.of(context);
              return Container(color: activeTheme.scaffold);
            },
          ),
        ),
      );
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.color, const Color(0xFF0F1F17));
    });

    testWidgets('VaultTheme.maybeOf(context) returns null when not provided', (tester) async {
      VaultThemeData? observed;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            observed = VaultTheme.maybeOf(context);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(observed, isNull);
    });

    testWidgets('VaultTheme.of(context) falls back to warmEspresso when not provided', (tester) async {
      VaultThemeData? observed;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            observed = VaultTheme.of(context);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(observed?.palette, VaultThemePalettePolicyEnum.warmEspresso);
      expect(observed?.scaffold, const Color(0xFF1A120E));
    });
  });
}
