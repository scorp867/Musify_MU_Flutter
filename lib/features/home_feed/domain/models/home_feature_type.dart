import 'package:equatable/equatable.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Direct equivalent to Spotify Android's `p.f410` (`HomeFeatureType`).
/// Base contract for all server-driven Casita home sections.
abstract class HomeFeatureType extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final List<SpotifyEntity> items;
  final String sectionType;
  final String? colorCode;
  final String? imageUrl;
  final Map<String, dynamic> metadata;

  const HomeFeatureType({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.items = const [],
    required this.sectionType,
    this.colorCode,
    this.imageUrl,
    this.metadata = const {},
  });

  /// Converts to HomeSection for backward compatibility with view layer.
  HomeSection toHomeSection({SectionLayout? layout}) {
    return HomeSection(
      title: title,
      subtitle: subtitle,
      items: items,
      layout: layout ?? defaultLayout,
      sectionUri: id,
      sectionType: sectionType,
      colorCode: colorCode,
      imageUrl: imageUrl,
      metadata: metadata,
    );
  }

  SectionLayout get defaultLayout {
    switch (sectionType) {
      case 'shortcuts':
        return SectionLayout.quickGrid;
      case 'preview':
      case 'immersivePreview':
      case 'showcase':
      case 'associatedPreview':
      case 'verticalSingleEntry':
      case 'promotionV1':
      case 'promotionV3':
      case 'videoPromo':
      case 'playLinkPromo':
      case 'audioPromo':
      case 'audioSpotlight':
      case 'interactiveEntrypoint':
      case 'inlineCard':
      case 'reflection':
      case 'fullBleedBanner':
      case 'banner':
        return SectionLayout.feed;
      default:
        return SectionLayout.carousel;
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        items,
        sectionType,
        colorCode,
        imageUrl,
        metadata,
      ];
}

/// Case 2: Shortcuts (p.arn0 / p.yex0)
class ShortcutsFeatureType extends HomeFeatureType {
  const ShortcutsFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'shortcuts');
}

/// Case 3: ImageLink (p.h620)
class ImageLinkFeatureType extends HomeFeatureType {
  final int density;
  const ImageLinkFeatureType({
    required super.id,
    required super.title,
    super.subtitle = '',
    super.items = const [],
    this.density = 0,
  }) : super(sectionType: 'imageLink');
}

/// Case 4: Preview (p.kkn0)
class PreviewFeatureType extends HomeFeatureType {
  const PreviewFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'preview');
}

/// Case 6: ImmersivePreview (p.hif0)
class ImmersivePreviewFeatureType extends HomeFeatureType {
  const ImmersivePreviewFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'immersivePreview');
}

/// Case 7: Anchors (p.vj3)
class AnchorsFeatureType extends HomeFeatureType {
  const AnchorsFeatureType({
    required super.id,
    super.title = '',
    super.items = const [],
  }) : super(sectionType: 'anchors');
}

/// Case 8: ContentEvaluationList (p.dei)
class ContentEvaluationListFeatureType extends HomeFeatureType {
  const ContentEvaluationListFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'contentEvaluationList');
}

/// Case 10: RecentsShelf (p.hdr0 / p.ony0)
class RecentsShelfFeatureType extends HomeFeatureType {
  const RecentsShelfFeatureType({
    required super.id,
    super.title = 'Recents',
    super.items = const [],
  }) : super(sectionType: 'recentsShelf');
}

/// Case 11: WatchFeed (p.lg81)
class WatchFeedFeatureType extends HomeFeatureType {
  const WatchFeedFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'watchFeed');
}

/// Case 12: PromotionV1 (p.zno0)
class PromotionV1FeatureType extends HomeFeatureType {
  const PromotionV1FeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'promotionV1');
}

/// Case 13: PromotionV3 (p.ke21)
class PromotionV3FeatureType extends HomeFeatureType {
  const PromotionV3FeatureType({
    required super.id,
    super.title = '',
    super.items = const [],
  }) : super(sectionType: 'promotionV3');
}

/// Case 15: ActionCardCarousel (p.d20)
class ActionCardCarouselFeatureType extends HomeFeatureType {
  const ActionCardCarouselFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'actionCardCarousel');
}

/// Case 16: LiveEvent (p.e270 / p.xoo0)
class LiveEventFeatureType extends HomeFeatureType {
  const LiveEventFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'liveEvent');
}

/// Case 17: Showcase (p.ppx0)
class ShowcaseFeatureType extends HomeFeatureType {
  const ShowcaseFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'showcase');
}

/// Case 18: VideoPromo (p.vbb0)
class VideoPromoFeatureType extends HomeFeatureType {
  final String targetUri;
  const VideoPromoFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
    this.targetUri = '',
  }) : super(sectionType: 'videoPromo');
}

/// Case 23: CampaignLinkCarousel (p.cua)
class CampaignLinkCarouselFeatureType extends HomeFeatureType {
  const CampaignLinkCarouselFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'campaignLinkCarousel');
}

/// Case 24: VerticalSingleEntry (p.ur61)
class VerticalSingleEntryFeatureType extends HomeFeatureType {
  const VerticalSingleEntryFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'verticalSingleEntry');
}

/// Case 25: VideoCarousel (p.lg81 / p.qcb0)
class VideoCarouselFeatureType extends HomeFeatureType {
  const VideoCarouselFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'videoCarousel');
}

/// Case 27: AssociatedPreview (p.t36)
class AssociatedPreviewFeatureType extends HomeFeatureType {
  const AssociatedPreviewFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'associatedPreview');
}

/// Case 28: BannerWithAnimations (p.ke21)
class BannerWithAnimationsFeatureType extends HomeFeatureType {
  const BannerWithAnimationsFeatureType({
    required super.id,
    super.title = '',
    super.items = const [],
  }) : super(sectionType: 'bannerWithAnimations');
}

/// Case 30: InteractiveEntrypoint (p.jtf0)
class InteractiveEntrypointFeatureType extends HomeFeatureType {
  final String prompt;
  const InteractiveEntrypointFeatureType({
    required super.id,
    required this.prompt,
  }) : super(title: prompt, items: const [], sectionType: 'interactiveEntrypoint');
}

/// Case 31: TopStoryCarousel (p.rp31)
class TopStoryCarouselFeatureType extends HomeFeatureType {
  const TopStoryCarouselFeatureType({
    required super.id,
    super.title = '',
    super.items = const [],
  }) : super(sectionType: 'topStoryCarousel');
}

/// Case 33: AudioPromo (p.m7b0)
class AudioPromoFeatureType extends HomeFeatureType {
  const AudioPromoFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'audioPromo');
}

/// Case 34: InlineCard (p.fn20)
class InlineCardFeatureType extends HomeFeatureType {
  const InlineCardFeatureType({
    required super.id,
    super.title = '',
    super.items = const [],
  }) : super(sectionType: 'inlineCard');
}

/// Case 35: PlayLinkPromo (p.oal0)
class PlayLinkPromoFeatureType extends HomeFeatureType {
  const PlayLinkPromoFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'playLinkPromo');
}

/// Case 36: AudioSpotlight (p.m7b0)
class AudioSpotlightFeatureType extends HomeFeatureType {
  const AudioSpotlightFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'audioSpotlight');
}

/// Case 37: PreviewCarousel (p.qcb0)
class PreviewCarouselFeatureType extends HomeFeatureType {
  const PreviewCarouselFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'previewCarousel');
}

/// Case 39: PreviewPromotionCarousel (p.arn0)
class PreviewPromotionCarouselFeatureType extends HomeFeatureType {
  const PreviewPromotionCarouselFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'previewPromotionCarousel');
}

/// Case 41: Reflection (p.rxr0)
class ReflectionFeatureType extends HomeFeatureType {
  const ReflectionFeatureType({
    required super.id,
    required super.title,
    super.items = const [],
  }) : super(sectionType: 'reflection');
}

/// Case 26: FullBleedBanner (p.FullBleedBanner)
/// Edge-to-edge promotional hero banner (e.g. New Music Friday).
class FullBleedBannerFeatureType extends HomeFeatureType {
  final String accessibility;

  const FullBleedBannerFeatureType({
    required super.id,
    required super.colorCode,
    required super.imageUrl,
    required super.subtitle,
    required this.accessibility,
  }) : super(
          title: accessibility,
          items: const [],
          sectionType: 'fullBleedBanner',
        );

  @override
  List<Object?> get props => [
        ...super.props,
        accessibility,
      ];
}

/// Case 19: Banner (p.zno0 / p.en4 / Caught up celebration banner)
class BannerFeatureType extends HomeFeatureType {
  final int bannerType;

  const BannerFeatureType({
    required super.id,
    required this.bannerType,
    required super.colorCode,
    super.title = "You’re all caught up",
    super.subtitle = "Come back next Friday",
  }) : super(
          items: const [],
          sectionType: 'banner',
        );

  @override
  List<Object?> get props => [
        ...super.props,
        bannerType,
      ];
}
