import 'dart:convert';
import 'package:musify_mu/features/home_feed/data/eagerload/section_trait_provider.dart';

/// Dynamically builds Spotify's Casita `?eagerload=...` query parameter.
/// Direct equivalent to Spotify Android's `p.ozo` (case 27).
class EagerloadPayloadBuilder {
  /// Default suite of all active section providers in Spotify.
  static const List<SectionTraitProvider> defaultProviders = [
    ShortcutsTraitProvider(),
    PreviewTraitProvider(),
    ImmersivePreviewTraitProvider(),
    AnchorsTraitProvider(),
    ContentEvaluationListTraitProvider(),
    PromotionV1TraitProvider(),
    PromotionV3TraitProvider(),
    ActionCardCarouselTraitProvider(),
    LiveEventTraitProvider(),
    ShowcaseTraitProvider(),
    VideoPromoTraitProvider(),
    CampaignLinkCarouselTraitProvider(),
    VerticalSingleEntryTraitProvider(),
    VideoCarouselTraitProvider(),
    AssociatedPreviewTraitProvider(),
    BannerWithAnimationsTraitProvider(),
    AudioPromoTraitProvider(),
    PlayLinkPromoTraitProvider(),
    AudioSpotlightTraitProvider(),
    PreviewCarouselTraitProvider(),
    PreviewPromotionCarouselTraitProvider(),
    ReflectionTraitProvider(),
  ];

  /// Compiles a list of SectionTraitProviders into Spotify's Base64 JSON payload.
  static String build([List<SectionTraitProvider> providers = defaultProviders]) {
    final Map<String, Map<String, List<int>>> mapping = {};

    for (final provider in providers) {
      final sectionId = provider.sectionId;
      if (sectionId == null) continue;

      final reqs = provider.getTraitRequirements();
      if (reqs.isEmpty) continue;

      final sectionMap = <String, List<int>>{};
      for (final entry in reqs.entries) {
        if (entry.value.isNotEmpty) {
          sectionMap[entry.key.toString()] = List<int>.from(entry.value);
        }
      }

      if (sectionMap.isNotEmpty) {
        mapping[sectionId.toString()] = sectionMap;
      }
    }

    // Sort keys alphabetically/numerically like Spotify's TreeMap in p.ozo
    final sortedKeys = mapping.keys.toList()..sort();
    final sortedMapping = <String, dynamic>{};
    for (final k in sortedKeys) {
      sortedMapping[k] = mapping[k];
    }

    final payload = {'mapping': sortedMapping};
    final jsonStr = jsonEncode(payload);
    return base64Encode(utf8.encode(jsonStr));
  }
}
