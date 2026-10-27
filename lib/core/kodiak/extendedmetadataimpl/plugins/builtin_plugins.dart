import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';

import 'simple_card_trait_plugin.dart';
import 'shortcuts_card_trait_plugin.dart';
import 'preview_card_trait_plugin.dart';
import 'identity_trait_plugin.dart';
import 'visual_identity_trait_plugin.dart';
import 'show_access_trait_plugin.dart';
import 'audiobook_specifics_plugin.dart';
import 'audiobook_price_plugin.dart';
import 'audio_preview_playback_trait_plugin.dart';
import 'preview_playback_trait_plugin.dart';
import 'promo_v1_trait_plugin.dart';
import 'promo_v3_trait_plugin.dart';
import 'concert_trait_plugin.dart';
import 'concert_location_trait_plugin.dart';
import 'concert_marketing_trait_plugin.dart';
import 'consumption_experience_trait_plugin.dart';
import 'track_v4_plugin.dart';
import 'episode_v4_plugin.dart';
import 'on_platform_reputation_trait_plugin.dart';
import 'credits_trait_plugin.dart';
import 'playback_trait_plugin.dart';

export 'plugin_utils.dart';
export 'simple_card_trait_plugin.dart';
export 'shortcuts_card_trait_plugin.dart';
export 'preview_card_trait_plugin.dart';
export 'identity_trait_plugin.dart';
export 'visual_identity_trait_plugin.dart';
export 'show_access_trait_plugin.dart';
export 'audiobook_specifics_plugin.dart';
export 'audiobook_price_plugin.dart';
export 'audio_preview_playback_trait_plugin.dart';
export 'preview_playback_trait_plugin.dart';
export 'promo_v1_trait_plugin.dart';
export 'promo_v3_trait_plugin.dart';
export 'concert_trait_plugin.dart';
export 'concert_location_trait_plugin.dart';
export 'concert_marketing_trait_plugin.dart';
export 'consumption_experience_trait_plugin.dart';
export 'track_v4_plugin.dart';
export 'episode_v4_plugin.dart';
export 'on_platform_reputation_trait_plugin.dart';
export 'credits_trait_plugin.dart';
export 'playback_trait_plugin.dart';

/// Instantiates the standard suite of ExtendedMetadata plugins.
List<ExtendedMetadataPlugin> createDefaultExtendedMetadataPlugins() {
  return const [
    SimpleCardTraitPlugin(),
    ShortcutsCardTraitPlugin(),
    PreviewCardTraitPlugin(),
    IdentityTraitPlugin(),
    VisualIdentityTraitPlugin(),
    ShowAccessTraitPlugin(),
    AudiobookSpecificsPlugin(),
    AudiobookPricePlugin(),
    AudioPreviewPlaybackTraitPlugin(),
    PreviewPlaybackTraitPlugin(),
    PromoV1TraitPlugin(),
    PromoV3TraitPlugin(),
    ConcertTraitPlugin(),
    ConcertLocationTraitPlugin(),
    ConcertMarketingTraitPlugin(),
    ConsumptionExperienceTraitPlugin(),
    TrackV4Plugin(),
    EpisodeV4Plugin(),
    OnPlatformReputationTraitPlugin(),
    CreditsTraitPlugin(),
    PlaybackTraitPlugin(),
  ];
}
