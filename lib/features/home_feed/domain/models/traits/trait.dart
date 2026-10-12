import 'simple_card_trait.dart';
import 'preview_card_trait.dart';
import 'identity_trait.dart';
import 'shortcuts_card_trait.dart';
import 'fallback_metadata_trait.dart';
import 'recents_metadata_trait.dart';
import 'audio_preview_playback_trait.dart';
import 'preview_playback_trait.dart';
import 'video_card_trait.dart';
import 'visual_identity_trait.dart';
import 'show_access_trait.dart';
import 'audiobook_specifics_trait.dart';
import 'audiobook_price_trait.dart';
import 'promo_v1_trait.dart';
import 'promo_v3_trait.dart';
import 'concert_trait.dart';
import 'concert_location_trait.dart';
import 'concert_marketing_trait.dart';
import 'consumption_experience_trait.dart';
import 'track_meta_trait.dart';
import 'on_platform_reputation_trait.dart';
import 'credits_trait.dart';

enum ContentType {
  album,
  playlist,
  artist,
  track,
  episode,
  podcast,
  unknown;

  static ContentType fromUri(String uri) {
    if (uri.contains(':album:')) return album;
    if (uri.contains(':playlist:')) return playlist;
    if (uri.contains(':artist:')) return artist;
    if (uri.contains(':track:')) return track;
    if (uri.contains(':episode:')) return episode;
    if (uri.contains(':show:')) return podcast;
    if (uri.contains(':collection:')) return playlist;
    return unknown;
  }
}

/// Base class for all Spotify SDUI Traits.
/// Direct 1:1 equivalent to Spotify Android's `p.l5w`.
abstract class Trait {
  const Trait();
  Map<String, dynamic> toJson();

  static Trait? fromJson(String type, Map<String, dynamic> json) {
    return switch (type) {
      'SimpleCardTrait' => SimpleCardTrait.fromJson(json),
      'PreviewCardTrait' => PreviewCardTrait.fromJson(json),
      'IdentityTrait' => IdentityTrait.fromJson(json),
      'ShortcutsCardTrait' => ShortcutsCardTrait.fromJson(json),
      'FallbackMetadataTrait' => FallbackMetadataTrait.fromJson(json),
      'RecentsMetadataTrait' => RecentsMetadataTrait.fromJson(json),
      'AudioPreviewPlaybackTrait' => AudioPreviewPlaybackTrait.fromJson(json),
      'PreviewPlaybackTrait' => PreviewPlaybackTrait.fromJson(json),
      'VideoCardTrait' => VideoCardTrait.fromJson(json),
      'VisualIdentityTrait' => VisualIdentityTrait.fromJson(json),
      'ShowAccessTrait' => ShowAccessTrait.fromJson(json),
      'AudiobookSpecificsTrait' => AudiobookSpecificsTrait.fromJson(json),
      'AudiobookPriceTrait' => AudiobookPriceTrait.fromJson(json),
      'PromoV1Trait' => PromoV1Trait.fromJson(json),
      'PromoV3Trait' => PromoV3Trait.fromJson(json),
      'ConcertTrait' => ConcertTrait.fromJson(json),
      'ConcertLocationTrait' => ConcertLocationTrait.fromJson(json),
      'ConcertMarketingTrait' => ConcertMarketingTrait.fromJson(json),
      'ConsumptionExperienceTrait' => ConsumptionExperienceTrait.fromJson(json),
      'TrackMetaTrait' => TrackMetaTrait.fromJson(json),
      'OnPlatformReputationTrait' => OnPlatformReputationTrait.fromJson(json),
      'CreditsTrait' => CreditsTrait.fromJson(json),
      _ => null,
    };
  }
}
