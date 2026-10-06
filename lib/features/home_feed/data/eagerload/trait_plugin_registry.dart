import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Equivalent to Spotify Android's `p.b2w` (`ExtendedMetadataPlugin`).
class TraitPlugin {
  final Type traitType;
  final int extensionKindValue;
  final ExtensionKind? extensionKind;

  const TraitPlugin({
    required this.traitType,
    required this.extensionKindValue,
    this.extensionKind,
  });
}

/// Registry mapping Trait models to integer ExtensionKind IDs.
/// Direct equivalent to Spotify Android's `p.c2w` (`PluginRegistry`).
class TraitPluginRegistry {
  static final Map<Type, int> _typeToKind = {};
  static final Map<int, Type> _kindToType = {};
  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;

    _register<SimpleCardTrait>(97, ExtensionKind.SIMPLE_TRAIT);
    _register<ShortcutsCardTrait>(119, ExtensionKind.SHORTCUTS_CARD_TRAIT);
    _register<PreviewCardTrait>(118, ExtensionKind.PREVIEW_CARD_TRAIT);
    _register<IdentityTrait>(178, ExtensionKind.IDENTITY_TRAIT);
    _register<VisualIdentityTrait>(179, ExtensionKind.VISUAL_IDENTITY_TRAIT);
    _register<AudioPreviewPlaybackTrait>(116, ExtensionKind.AUDIO_PREVIEW_PLAYBACK_TRAIT);
    _register<PreviewPlaybackTrait>(181, ExtensionKind.PREVIEW_PLAYBACK_TRAIT);
    _register<ShowAccessTrait>(31, ExtensionKind.SHOW_ACCESS);
    _register<AudiobookSpecificsTrait>(52, ExtensionKind.AUDIOBOOK_SPECIFICS);
    _register<AudiobookPriceTrait>(64, ExtensionKind.AUDIOBOOK_PRICE);
    _register<PromoV1Trait>(167, ExtensionKind.PROMO_V1_TRAIT);
    _register<PromoV3Trait>(171, ExtensionKind.PROMO_V3_TRAIT);
    _register<ConcertTrait>(122, ExtensionKind.CONCERT);
    _register<ConcertLocationTrait>(123, ExtensionKind.CONCERT_LOCATION);
    _register<ConcertMarketingTrait>(124, ExtensionKind.CONCERT_MARKETING);
    _register<ConsumptionExperienceTrait>(182, ExtensionKind.CONSUMPTION_EXPERIENCE_TRAIT);

    _initialized = true;
  }

  static void _register<T extends Trait>(int kind, ExtensionKind? protoKind) {
    _typeToKind[T] = kind;
    _kindToType[kind] = T;
  }

  /// Maps a Trait type to its ExtensionKind integer ID.
  static int? kindForType(Type type) {
    ensureInitialized();
    return _typeToKind[type];
  }

  /// Maps an ExtensionKind integer ID to its Trait type.
  static Type? typeForKind(int kind) {
    ensureInitialized();
    return _kindToType[kind];
  }
}
