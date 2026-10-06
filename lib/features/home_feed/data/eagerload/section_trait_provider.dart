/// Contract for section trait requirement providers in Spotify.
/// Direct equivalent to Spotify Android's `p.qqv`.
abstract class SectionTraitProvider {
  /// The Protobuf Section discriminator case / section ID (e.g. 2, 4, 6, 12...).
  int? get sectionId;

  /// Returns a map of priority level (1 = Required, 2 = Optional)
  /// to the list of ExtensionKind integer IDs.
  Map<int, List<int>> getTraitRequirements();
}

/// Case 2: Shortcuts (p.u10 case 10 / p.arn0)
class ShortcutsTraitProvider implements SectionTraitProvider {
  const ShortcutsTraitProvider();
  @override
  int get sectionId => 2;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [119], // SHORTCUTS_CARD_TRAIT
    2: [119],
  };
}

/// Case 4: Preview (p.u10 case 7 / p.kkn0)
class PreviewTraitProvider implements SectionTraitProvider {
  const PreviewTraitProvider();
  @override
  int get sectionId => 4;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    2: [118, 116], // PREVIEW_CARD_TRAIT, AUDIO_PREVIEW_PLAYBACK_TRAIT
  };
}

/// Case 6: ImmersivePreview (p.u10 case 6 / p.hif0)
class ImmersivePreviewTraitProvider implements SectionTraitProvider {
  const ImmersivePreviewTraitProvider();
  @override
  int get sectionId => 6;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [118], // PREVIEW_CARD_TRAIT
    2: [116, 178], // AUDIO_PREVIEW_PLAYBACK_TRAIT, IDENTITY_TRAIT
  };
}

/// Case 7: Anchors (p.dk3 case 0 / p.vj3)
class AnchorsTraitProvider implements SectionTraitProvider {
  const AnchorsTraitProvider();
  @override
  int get sectionId => 7;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [119], // SHORTCUTS_CARD_TRAIT
  };
}

/// Case 8: ContentEvaluationList (p.dk3 case 3 / p.dei)
class ContentEvaluationListTraitProvider implements SectionTraitProvider {
  const ContentEvaluationListTraitProvider();
  @override
  int get sectionId => 8;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [119],
  };
}

/// Case 12: PromotionV1 (p.dk3 case 5 / p.zno0)
class PromotionV1TraitProvider implements SectionTraitProvider {
  const PromotionV1TraitProvider();
  @override
  int get sectionId => 12;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [167], // PROMO_V1_TRAIT
  };
}

/// Case 13: PromotionV3 (p.dk3 case 6 / p.ke21)
class PromotionV3TraitProvider implements SectionTraitProvider {
  const PromotionV3TraitProvider();
  @override
  int get sectionId => 13;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [171], // PROMO_V3_TRAIT
  };
}

/// Case 15: ActionCardCarousel (p.u10 case 0 / p.d20)
class ActionCardCarouselTraitProvider implements SectionTraitProvider {
  const ActionCardCarouselTraitProvider();
  @override
  int get sectionId => 15;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [97], // SIMPLE_TRAIT
    2: [97],
  };
}

/// Case 16: LiveEvent (p.dk3 case 2 / p.e270)
class LiveEventTraitProvider implements SectionTraitProvider {
  const LiveEventTraitProvider();
  @override
  int get sectionId => 16;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [122, 123, 124], // CONCERT, CONCERT_LOCATION, CONCERT_MARKETING
  };
}

/// Case 17: Showcase (p.dk3 case 8 / p.ppx0)
class ShowcaseTraitProvider implements SectionTraitProvider {
  const ShowcaseTraitProvider();
  @override
  int get sectionId => 17;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [178, 167, 179], // IDENTITY_TRAIT, PROMO_V1_TRAIT, VISUAL_IDENTITY_TRAIT
  };
}

/// Case 18: VideoPromo (p.u10 case 5 / p.vbb0)
class VideoPromoTraitProvider implements SectionTraitProvider {
  const VideoPromoTraitProvider();
  @override
  int get sectionId => 18;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [118], // PREVIEW_CARD_TRAIT
    2: [181, 249, 118, 178], // PREVIEW_PLAYBACK_TRAIT, 249, 118, IDENTITY_TRAIT
  };
}

/// Case 23: CampaignLinkCarousel (p.dk3 case 1 / p.cua)
class CampaignLinkCarouselTraitProvider implements SectionTraitProvider {
  const CampaignLinkCarouselTraitProvider();
  @override
  int get sectionId => 23;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [97], // SIMPLE_TRAIT
  };
}

/// Case 24: VerticalSingleEntry (p.vbq case 5 / p.ur61)
class VerticalSingleEntryTraitProvider implements SectionTraitProvider {
  const VerticalSingleEntryTraitProvider();
  @override
  int get sectionId => 24;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [171], // PROMO_V3_TRAIT
    2: [116], // AUDIO_PREVIEW_PLAYBACK_TRAIT
  };
}

/// Case 25: VideoCarousel (p.u10 case 4 / p.lg81)
class VideoCarouselTraitProvider implements SectionTraitProvider {
  const VideoCarouselTraitProvider();
  @override
  int get sectionId => 25;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [118], // PREVIEW_CARD_TRAIT
    2: [118, 178, 116], // 118, IDENTITY_TRAIT, AUDIO_PREVIEW_PLAYBACK_TRAIT
  };
}

/// Case 27: AssociatedPreview (p.u10 case 2 / p.t36)
class AssociatedPreviewTraitProvider implements SectionTraitProvider {
  const AssociatedPreviewTraitProvider();
  @override
  int get sectionId => 27;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [118, 116], // PREVIEW_CARD_TRAIT, AUDIO_PREVIEW_PLAYBACK_TRAIT
    2: [178], // IDENTITY_TRAIT
  };
}

/// Case 28: BannerWithAnimations (p.dk3 case 10 / p.ke21)
class BannerWithAnimationsTraitProvider implements SectionTraitProvider {
  const BannerWithAnimationsTraitProvider();
  @override
  int get sectionId => 28;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [229], // BANNER_WITH_ANIMATIONS
  };
}

/// Case 33: AudioPromo (p.u10 case 3 / p.m7b0)
class AudioPromoTraitProvider implements SectionTraitProvider {
  const AudioPromoTraitProvider();
  @override
  int get sectionId => 33;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [118], // PREVIEW_CARD_TRAIT
  };
}

/// Case 35: PlayLinkPromo (p.dk3 case 4 / p.oal0)
class PlayLinkPromoTraitProvider implements SectionTraitProvider {
  const PlayLinkPromoTraitProvider();
  @override
  int get sectionId => 35;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [248], // PLAY_LINK_PROMO_TRAIT
  };
}

/// Case 36: AudioSpotlight (p.u10 case 1 / p.m7b0)
class AudioSpotlightTraitProvider implements SectionTraitProvider {
  const AudioSpotlightTraitProvider();
  @override
  int get sectionId => 36;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [118], // PREVIEW_CARD_TRAIT
  };
}

/// Case 37: PreviewCarousel (p.u10 case 8 / p.qcb0)
class PreviewCarouselTraitProvider implements SectionTraitProvider {
  const PreviewCarouselTraitProvider();
  @override
  int get sectionId => 37;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [118], // PREVIEW_CARD_TRAIT
    2: [118, 178, 116], // 118, IDENTITY_TRAIT, AUDIO_PREVIEW_PLAYBACK_TRAIT
  };
}

/// Case 39: PreviewPromotionCarousel (p.u10 case 9 / p.arn0)
class PreviewPromotionCarouselTraitProvider implements SectionTraitProvider {
  const PreviewPromotionCarouselTraitProvider();
  @override
  int get sectionId => 39;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [118], // PREVIEW_CARD_TRAIT
    2: [181, 249, 118, 178], // PREVIEW_PLAYBACK_TRAIT, 249, 118, IDENTITY_TRAIT
  };
}

/// Case 41: Reflection (p.dk3 case 7 / p.rxr0)
class ReflectionTraitProvider implements SectionTraitProvider {
  const ReflectionTraitProvider();
  @override
  int get sectionId => 41;
  @override
  Map<int, List<int>> getTraitRequirements() => {
    1: [179, 178], // VISUAL_IDENTITY_TRAIT, IDENTITY_TRAIT
  };
}
