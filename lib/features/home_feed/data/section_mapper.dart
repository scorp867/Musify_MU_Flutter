import 'package:musify_mu/core/protocol/generated/spotify/casita/resolved.pb.dart' as casita;
import 'package:musify_mu/features/home_feed/domain/models/home_feature_type.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Direct equivalent to Spotify Android's `p.kw1` (`SectionMapper`).
/// Evaluates `section.whichFeatureType()` (featureTypeCase_) and instantiates
/// the corresponding `HomeFeatureType` (p.f410).
class SectionMapper {
  const SectionMapper();

  /// Maps a Casita Protobuf Section to its strongly typed HomeFeatureType (matches kw1.F).
  HomeFeatureType? mapSection(
    casita.Section section, {
    required List<SpotifyEntity> Function(casita.ItemSource) extractSource,
    required List<SpotifyEntity> Function(List<casita.Item>) extractList,
    required List<SpotifyEntity> Function(casita.Item) extractSingle,
    required String Function(casita.Heading heading, [String sectionId]) extractTitle,
    required void Function(String uri, Trait trait) storeTrait,
    required String? Function(String url) cleanImageUrl,
  }) {
    final sectionId = section.hasSectionInfo() ? section.sectionInfo.sectionId : '';
    final featureType = section.whichFeatureType();

    switch (featureType) {
      case casita.Section_FeatureType.shortcuts:
        final items = extractSource(section.shortcuts.itemSource);
        return ShortcutsFeatureType(id: sectionId, title: '', items: items);

      case casita.Section_FeatureType.imageLink:
        final title = extractTitle(section.imageLink.heading, sectionId);
        final items = extractSource(section.imageLink.itemSource);
        return ImageLinkFeatureType(
          id: sectionId,
          title: title,
          items: items,
          density: section.imageLink.density,
        );

      case casita.Section_FeatureType.preview:
        final title = extractTitle(section.preview.heading, sectionId);
        final items = extractSingle(section.preview.item);
        return PreviewFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.immersivePreview:
        final title = extractTitle(section.immersivePreview.heading, sectionId);
        final items = extractSingle(section.immersivePreview.item);
        return ImmersivePreviewFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.anchors:
        final items = extractSource(section.anchors.itemSource);
        return AnchorsFeatureType(id: sectionId, title: '', items: items);

      case casita.Section_FeatureType.contentEvaluationList:
        final title = extractTitle(section.contentEvaluationList.heading, sectionId);
        final items = extractList(section.contentEvaluationList.items);
        return ContentEvaluationListFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.recentsShelf:
        final title = extractTitle(section.recentsShelf.heading, sectionId);
        final items = extractSource(section.recentsShelf.itemSource);
        return RecentsShelfFeatureType(
          id: sectionId,
          title: title.isNotEmpty ? title : 'Recents',
          items: items,
        );

      case casita.Section_FeatureType.watchFeed:
        final title = extractTitle(section.watchFeed.heading, sectionId);
        final items = <SpotifyEntity>[];
        for (final wfItem in section.watchFeed.items) {
          final uri = wfItem.hasItem() ? wfItem.item.identifier : '';
          if (uri.isEmpty) continue;

          if (wfItem.hasEntrypoint()) {
            final ep = wfItem.entrypoint;
            final thumbUrl = cleanImageUrl(ep.thumbnailImage.url);
            final coverUrl = cleanImageUrl(ep.coverImage.url);

            int durationSec = 0;
            if (ep.hasVideoFile() && ep.videoFile.endTime > ep.videoFile.startTime) {
              durationSec = ((ep.videoFile.endTime - ep.videoFile.startTime) ~/ 1000).toInt();
            }
            final durationStr = durationSec > 0
                ? '${(durationSec ~/ 60).toString().padLeft(2, '0')}:${(durationSec % 60).toString().padLeft(2, '0')}'
                : (ep.overline.isNotEmpty ? ep.overline : '');

            storeTrait(uri, VideoCardTrait(
              title: ep.title,
              subtitle: ep.subtitle,
              videoThumbnailUrl: thumbUrl,
              showArtworkUrl: coverUrl,
              durationString: durationStr,
              overline: ep.overline,
            ));

            storeTrait(uri, SimpleCardTrait(
              title: ep.title,
              subtitle: ep.subtitle,
              imageUrl: thumbUrl ?? coverUrl,
            ));
          }

          items.add(SpotifyEntity(
            uri: uri,
            type: ContentType.fromUri(uri),
            traits: {},
          ));
        }
        return WatchFeedFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.promotionV1:
        final title = extractTitle(section.promotionV1.heading, sectionId);
        final items = extractSingle(section.promotionV1.item);
        return PromotionV1FeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.promotionV3:
        final items = extractSingle(section.promotionV3.item);
        return PromotionV3FeatureType(id: sectionId, title: '', items: items);

      case casita.Section_FeatureType.actionCardCarousel:
        final title = extractTitle(section.actionCardCarousel.heading, sectionId);
        final items = extractList(section.actionCardCarousel.items);
        return ActionCardCarouselFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.liveEvent:
        final title = extractTitle(section.liveEvent.heading, sectionId);
        final items = extractSource(section.liveEvent.itemSource);
        return LiveEventFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.showcase:
        final title = extractTitle(section.showcase.heading, sectionId);
        final items = extractSingle(section.showcase.item);
        return ShowcaseFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.videoPromo:
        final title = extractTitle(section.videoPromo.heading, sectionId);
        final items = extractSingle(section.videoPromo.item);
        return VideoPromoFeatureType(
          id: sectionId,
          title: title,
          items: items,
          targetUri: section.videoPromo.targetUri,
        );

      case casita.Section_FeatureType.campaignLinkCarousel:
        final title = extractTitle(section.campaignLinkCarousel.heading, sectionId);
        final items = extractSource(section.campaignLinkCarousel.itemSource);
        return CampaignLinkCarouselFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.verticalSingleEntry:
        final title = extractTitle(section.verticalSingleEntry.heading, sectionId);
        final items = extractSingle(section.verticalSingleEntry.item);
        return VerticalSingleEntryFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.videoCarousel:
        final title = extractTitle(section.videoCarousel.heading, sectionId);
        final items = extractList(section.videoCarousel.items);
        return VideoCarouselFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.associatedPreview:
        final title = extractTitle(section.associatedPreview.heading, sectionId);
        final items = extractSingle(section.associatedPreview.item);
        return AssociatedPreviewFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.bannerWithAnimations:
        final items = extractSingle(section.bannerWithAnimations.item);
        return BannerWithAnimationsFeatureType(id: sectionId, title: '', items: items);

      case casita.Section_FeatureType.interactiveEntrypoint:
        final prompt = section.interactiveEntrypoint.prompt;
        return InteractiveEntrypointFeatureType(id: sectionId, prompt: prompt);

      case casita.Section_FeatureType.topStoryCarousel:
        final items = <SpotifyEntity>[];
        for (final story in section.topStoryCarousel.stories) {
          items.addAll(extractList(story.items));
        }
        return TopStoryCarouselFeatureType(id: sectionId, title: '', items: items);

      case casita.Section_FeatureType.audioPromo:
        final title = extractTitle(section.audioPromo.heading, sectionId);
        final items = extractSingle(section.audioPromo.item);
        return AudioPromoFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.inlineCard:
        return InlineCardFeatureType(id: sectionId);

      case casita.Section_FeatureType.playLinkPromo:
        final title = extractTitle(section.playLinkPromo.heading, sectionId);
        final items = extractSingle(section.playLinkPromo.item);
        return PlayLinkPromoFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.audioSpotlight:
        final title = extractTitle(section.audioSpotlight.heading, sectionId);
        final items = extractSingle(section.audioSpotlight.item);
        return AudioSpotlightFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.previewCarousel:
        final title = extractTitle(section.previewCarousel.heading, sectionId);
        final items = extractList(section.previewCarousel.items);
        return PreviewCarouselFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.previewPromotionCarousel:
        final title = extractTitle(section.previewPromotionCarousel.heading, sectionId);
        final items = <SpotifyEntity>[];
        for (final wrapped in section.previewPromotionCarousel.items) {
          if (wrapped.hasVideoPromo() && wrapped.videoPromo.hasItem()) {
            items.addAll(extractSingle(wrapped.videoPromo.item));
          }
        }
        return PreviewPromotionCarouselFeatureType(id: sectionId, title: title, items: items);

      case casita.Section_FeatureType.reflection:
        final title = extractTitle(section.reflection.heading, sectionId);
        final items = extractSingle(section.reflection.item);
        return ReflectionFeatureType(id: sectionId, title: title, items: items);

      // Commercial ads and non-visual content cleanly ignored
      case casita.Section_FeatureType.videoBrandAd:
      case casita.Section_FeatureType.imageBrandAd:
      case casita.Section_FeatureType.banner:
      case casita.Section_FeatureType.fullBleedBanner:
      case casita.Section_FeatureType.promptableSection:
      case casita.Section_FeatureType.concertCampaign:
      case casita.Section_FeatureType.promptedWorldsShelf:
      case casita.Section_FeatureType.userPromptedWorldEntrypoint:
      case casita.Section_FeatureType.callToAction:
      case casita.Section_FeatureType.narrative:
      case casita.Section_FeatureType.notSet:
        return null;
    }
  }
}
