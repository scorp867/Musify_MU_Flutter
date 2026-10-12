import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/plugins/visual_identity_trait_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/visual_identity_trait.pb.dart'
    as vit;
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/visual_types.pb.dart'
    as vt;

void main() {
  test('VisualIdentityTraitPlugin correctly parses higherContrast palette', () {
    final traitProto = vit.VisualIdentityTrait(
      squareCoverImage: vt.Image(
        extractedColorSet: vt.ColorSetContrastOptions(
          higherContrast: vt.ColorSet(
            backgroundBase: vt.RgbaColor(r: 78, g: 71, b: 45, a: 255),
            backgroundTintedBase: vt.RgbaColor(r: 90, g: 82, b: 59, a: 255),
            textBase: vt.RgbaColor(r: 255, g: 255, b: 255, a: 255),
            textSubdued: vt.RgbaColor(r: 180, g: 175, b: 155, a: 255),
            textBrightAccent: vt.RgbaColor(r: 30, g: 215, b: 96, a: 255),
          ),
        ),
      ),
    );

    final bytes = traitProto.writeToBuffer();
    const plugin = VisualIdentityTraitPlugin();
    final decoded = plugin.parse(bytes);

    expect(decoded.higherContrast, isNotNull);
    final palette = decoded.preferredCardPalette!;

    // 0xFF4E472D (A=255, R=78, G=71, B=45)
    expect(palette.backgroundBase, equals(0xFF4E472D));
    expect((palette.backgroundBaseColor.r * 255.0).round(), equals(78));
    expect((palette.backgroundBaseColor.g * 255.0).round(), equals(71));
    expect((palette.backgroundBaseColor.b * 255.0).round(), equals(45));

    // 0xFF5A523B (A=255, R=90, G=82, B=59)
    expect(palette.backgroundTintedBase, equals(0xFF5A523B));
    expect((palette.backgroundTintedBaseColor.r * 255.0).round(), equals(90));
    expect((palette.backgroundTintedBaseColor.g * 255.0).round(), equals(82));
    expect((palette.backgroundTintedBaseColor.b * 255.0).round(), equals(59));

    // textBase: 0xFFFFFFFF
    expect(palette.textBase, equals(0xFFFFFFFF));
    // textSubdued: 0xFFB4AF9B
    expect(palette.textSubdued, equals(0xFFB4AF9B));
  });
}
