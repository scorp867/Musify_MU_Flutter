import 'dart:developer' as dev;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:musify_mu/core/protocol/generated/spotify/casita/resolved.pb.dart' as casita;
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/visual_identity_trait.pb.dart' as vit;
import 'package:musify_mu/core/protocol/generated/spotify/traits/preview_card_trait.pb.dart' as pct;
import 'package:musify_mu/core/protocol/generated/spotify/traits/shortcuts_card_trait.pb.dart' as sct;
import 'package:musify_mu/core/protocol/generated/spotify/traits/simple_card_trait.pb.dart' as sct2;
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';

/// Parses the Casita (SDUI) response from Spotify's home feed endpoint.
///
/// Uses generated protobuf classes from the official Spotify proto schemas
/// (extracted from the decompiled APK) instead of manual binary parsing.
class CasitaParser {
  final Uint8List data;

  /// URI -> { traitTypeName -> Trait } lookup
  final Map<String, Map<String, Trait>> _traits = {};

  CasitaParser(this.data);
  CasitaParser._(this.data);

  /// Result of parsing a Casita response.
  Future<CasitaResult> parse() async {
    // Run entire parse in background isolate to avoid UI jank.
    return Isolate.run(() => _parseSync(data));
  }

  /// Synchronous parsing -- runs in background isolate.
  static CasitaResult _parseSync(Uint8List data) {
    final parser = CasitaParser._(data);
    return parser._doParse();
  }

  CasitaResult _doParse() {
    try {
      _traits.clear();

      final home = casita.ResolvedHome.fromBuffer(data);

      try {
        _parseEagerlyLoadedTraits(home.eagerlyLoadedTraits);
        dev.log('CasitaParser: ${_traits.length} URIs loaded from repository');
      } catch (e) {
        dev.log('CasitaParser: Eager traits failed (non-critical): $e');
      }

      final ondemandUris = home.ondemandSet.uris.toList();
      dev.log('CasitaParser: ${ondemandUris.length} URIs in ondemandSet');

      final sections = <HomeSection>[];
      for (final section in home.structure.sections) {
        try {
          final parsed = _parseSection(section);
          if (parsed != null &&
              (parsed.items.isNotEmpty ||
                  parsed.sectionType == 'recentsShelf' ||
                  parsed.sectionType == 'recents')) {
            sections.add(parsed);
          }
        } catch (e) {
          dev.log('CasitaParser: Failed parsing section: $e');
        }
      }

      int hydrated = 0;
      final hydratedSections = sections.map((section) {
        final hydratedItems = section.items.map((item) {
          final uriTraits = _traits[item.uri] ?? {};
          if (uriTraits.isNotEmpty) hydrated++;

          return SpotifyEntity(
            uri: item.uri,
            type: item.type,
            traits: Map.of(uriTraits),
          );
        }).toList();

        return HomeSection(
          title: section.title,
          subtitle: section.subtitle,
          items: hydratedItems,
          layout: section.layout,
          sectionUri: section.sectionUri,
          sectionType: section.sectionType,
        );
      }).toList();

      dev.log('CasitaParser: ${hydratedSections.length} sections, $hydrated items hydrated');
      return CasitaResult(
        homeData: HomeViewData(sections: hydratedSections),
        ondemandUris: ondemandUris,
        traits: Map.of(_traits),
      );
    } catch (e, stack) {
      dev.log('CasitaParser: $e\n$stack');
      return CasitaResult(
        homeData: const HomeViewData(),
        ondemandUris: const [],
      );
    }
  }

  Map<String, Trait>? traitsForUri(String uri) => _traits[uri] ?? _traits[uri.toLowerCase()];

  // ═══════════════════════════════════════════════════════════════════
  // Repository / EagerlyLoadedTraits parsing
  // ═══════════════════════════════════════════════════════════════════

  void _parseEagerlyLoadedTraits(casita.EagerlyLoadedTraits eagerTraits) {
    final batchedResponse = eagerTraits.traits;

    for (final dataArray in batchedResponse.extendedMetadata) {
      for (final extData in dataArray.extensionData) {
        final uri = extData.entityUri;
        if (uri.isEmpty) continue;

        final anyData = extData.extensionData;
        if (!anyData.hasValue() || anyData.value.isEmpty) continue;
        final payload = anyData.value;

        _decodeTraitByTypeUrl(uri, anyData.typeUrl, payload);
      }
    }
  }

  void _decodeTraitByTypeUrl(String uri, String typeUrl, List<int> payload) {
    if (typeUrl.contains('SimpleCardTrait')) {
      _decodeSimpleCardTrait(uri, payload);
    } else if (typeUrl.contains('ShortcutsCardTrait')) {
      _decodeShortcutsCardTrait(uri, payload);
    } else if (typeUrl.contains('PreviewCardTrait')) {
      _decodePreviewCardTrait(uri, payload);
    } else if (typeUrl.contains('VisualIdentityTrait')) {
      _decodeVisualIdentityTrait(uri, payload);
    } else if (typeUrl.contains('IdentityTrait')) {
      _decodeIdentityTrait(uri, payload);
    }
  }

  void _decodeSimpleCardTrait(String uri, List<int> payload) {
    try {
      final trait = sct2.SimpleCardTrait.fromBuffer(payload);

      _storeTrait(uri, SimpleCardTrait(
        title: trait.title,
        subtitle: trait.subtitle,
        imageUrl: _cleanImageUrl(trait.imageUri),
        navigationUri: trait.navigationUri,
        accessibility: trait.accessibility,
      ));
    } catch (e) {
      dev.log('CasitaParser: malformed SimpleCardTrait for $uri (skipped): $e');
    }
  }

  void _decodeShortcutsCardTrait(String uri, List<int> payload) {
    try {
      final trait = sct.ShortcutsCardTrait.fromBuffer(payload);

      _storeTrait(uri, ShortcutsCardTrait(
        title: trait.title,
        imageUrl: _cleanImageUrl(trait.imageUrl),
      ));
    } catch (e) {
      dev.log('CasitaParser: malformed ShortcutsCardTrait for $uri (skipped): $e');
    }
  }

  void _decodePreviewCardTrait(String uri, List<int> payload) {
    try {
      final trait = pct.PreviewCardTrait.fromBuffer(payload);

      _storeTrait(uri, PreviewCardTrait(
        title: trait.title,
        contentTypeName: trait.contentTypeName,
        description: trait.description,
        imageUrl: _cleanImageUrl(trait.entityImageUrl),
        backgroundColor: trait.backgroundColorHex,
        waveformColor: trait.waveformColorHex,
        trackCount: trait.numberOfItems,
        entityUri: trait.entityUri,
        navigateUri: trait.navigateUri,
        tags: trait.descriptorTags.map((t) => t.name).toList(),
        previewLabel: trait.hasLabels() ? trait.labels.previewLabel : '',
        playingLabel: trait.hasLabels() ? trait.labels.playingLabel : '',
        creatorName: trait.hasContentParent() ? trait.contentParent.name : '',
        creatorUri: trait.hasContentParent() ? trait.contentParent.uri : '',
        creatorImageUrl: trait.hasContentParent() ? trait.contentParent.imageUrl : '',
      ));
    } catch (e) {
      dev.log('CasitaParser: malformed PreviewCardTrait for $uri (skipped): $e');
    }
  }

  void _decodeIdentityTrait(String uri, List<int> payload) {
    // IdentityTrait has title at field 2 -- but since we don't have a generated
    // proto for it yet, we'll use the SimpleCardTrait parser as a fallback
    // for now, just storing basic identity info.
    // TODO: Add identity_trait.proto when needed beyond homescreen
    try {
      final trait = sct2.SimpleCardTrait.fromBuffer(payload);
      if (trait.title.isNotEmpty) {
        _storeTrait(uri, IdentityTrait(title: trait.title));
      }
    } catch (e) {
      dev.log('Silently skip malformed identity traits: $e');
    }
  }

  void _decodeVisualIdentityTrait(String uri, List<int> payload) {
    try {
      final trait = vit.VisualIdentityTrait.fromBuffer(payload);

      String? squareUrl;
      if (trait.hasSquareCoverImage() && trait.squareCoverImage.instances.isNotEmpty) {
        squareUrl = _cleanImageUrl(trait.squareCoverImage.instances.first.flatFile.cdnUrl);
      }

      String? sixteenByNineUrl;
      if (trait.hasSixteenByNineCoverImage() && trait.sixteenByNineCoverImage.instances.isNotEmpty) {
        sixteenByNineUrl = _cleanImageUrl(trait.sixteenByNineCoverImage.instances.first.flatFile.cdnUrl);
      }

      String? wideFullBleedUrl;
      if (trait.hasWideFullBleedImage() && trait.wideFullBleedImage.instances.isNotEmpty) {
        wideFullBleedUrl = _cleanImageUrl(trait.wideFullBleedImage.instances.first.flatFile.cdnUrl);
      }

      String? squareFullBleedUrl;
      if (trait.hasSquareFullBleedImage() && trait.squareFullBleedImage.instances.isNotEmpty) {
        squareFullBleedUrl = _cleanImageUrl(trait.squareFullBleedImage.instances.first.flatFile.cdnUrl);
      }

      String? videoUrl;
      if (trait.hasNineBySixteenCoverVideo() && trait.nineBySixteenCoverVideo.hasAsset()) {
        final asset = trait.nineBySixteenCoverVideo.asset;
        if (asset.hasFlatFile()) {
          videoUrl = asset.flatFile.cdnUrl;
        }
      }

      String? bgHex;
      String? textHex;
      String? textSubduedHex;

      if (trait.hasCuratedColor() && trait.curatedColor.hasMinContrast()) {
        final colorSet = trait.curatedColor.minContrast;
        if (colorSet.hasBackgroundBase()) {
          final c = colorSet.backgroundBase;
          bgHex = _rgbaToHex(c.r, c.g, c.b);
        }
        if (colorSet.hasTextBase()) {
          final c = colorSet.textBase;
          textHex = _rgbaToHex(c.r, c.g, c.b);
        }
        if (colorSet.hasTextSubdued()) {
          final c = colorSet.textSubdued;
          textSubduedHex = _rgbaToHex(c.r, c.g, c.b);
        }
      } else if (trait.hasSquareCoverImage() && trait.squareCoverImage.hasExtractedColorSet()) {
        final colorSet = trait.squareCoverImage.extractedColorSet.minContrast;
        if (colorSet.hasBackgroundBase()) {
          final c = colorSet.backgroundBase;
          bgHex = _rgbaToHex(c.r, c.g, c.b);
        }
      }

      final visualTrait = VisualIdentityTrait(
        squareCoverUrl: squareUrl,
        sixteenByNineCoverUrl: sixteenByNineUrl,
        wideFullBleedUrl: wideFullBleedUrl,
        squareFullBleedUrl: squareFullBleedUrl,
        videoNineBySixteenUrl: videoUrl,
        hasVideo: sixteenByNineUrl != null || videoUrl != null,
        backgroundColorHex: bgHex,
        textColorHex: textHex,
        textSubduedColorHex: textSubduedHex,
      );

      _storeTrait(uri, visualTrait);

      // Also ensure SimpleCardTrait has an image for standard card consumers
      final existingSimple = _traits[uri]?['SimpleCardTrait'] as SimpleCardTrait?;
      if (existingSimple == null && (squareUrl != null || sixteenByNineUrl != null)) {
        _storeTrait(uri, SimpleCardTrait(
          title: '',
          imageUrl: squareUrl ?? sixteenByNineUrl,
        ));
      }
    } catch (e) {
      dev.log('CasitaParser: malformed VisualIdentityTrait for $uri: $e');
    }
  }

  static String _rgbaToHex(int r, int g, int b) {
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }

  void _storeTrait(String uri, Trait trait) {
    _traits.putIfAbsent(uri, () => {})[trait.runtimeType.toString()] = trait;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Section parsing using generated Section proto
  // ═══════════════════════════════════════════════════════════════════

  HomeSection? _parseSection(casita.Section section) {
    final sectionId = section.hasSectionInfo() ? section.sectionInfo.sectionId : '';
    final featureType = section.whichFeatureType();

    dev.log('Section: featureType=${featureType.name} sectionId=$sectionId');

    // The featureType.name IS the rendering instruction from Spotify's Casita.
    // Pass it through directly — no manual mapping.
    final ft = featureType.name;

    switch (featureType) {
      case casita.Section_FeatureType.shortcuts:
        final items = _extractItemsFromSource(section.shortcuts.itemSource);
        return HomeSection(
          title: '',
          items: items,
          layout: SectionLayout.quickGrid,
          sectionType: ft,
        );

      case casita.Section_FeatureType.imageLink:
        final title = _extractTitle(section.imageLink.heading);
        final items = _extractItemsFromSource(section.imageLink.itemSource);
        return _buildSection(title, items, sectionId, SectionLayout.carousel, sectionType: ft);

      case casita.Section_FeatureType.preview:
        final title = _extractTitle(section.preview.heading);
        final items = _extractItemsFromItem(section.preview.item);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.immersivePreview:
        final title = _extractTitle(section.immersivePreview.heading);
        final items = _extractItemsFromItem(section.immersivePreview.item);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.recentsShelf:
        final title = _extractTitle(section.recentsShelf.heading);
        return HomeSection(
          title: title.isNotEmpty ? title : 'Recents',
          items: const [],
          layout: SectionLayout.carousel,
          sectionType: ft,
        );

      case casita.Section_FeatureType.previewCarousel:
        final title = _extractTitle(section.previewCarousel.heading);
        final items = _extractItemsFromList(section.previewCarousel.items);
        return _buildSection(title, items, sectionId, SectionLayout.carousel, sectionType: ft);

      case casita.Section_FeatureType.showcase:
        final title = _extractTitle(section.showcase.heading);
        final items = _extractItemsFromItem(section.showcase.item);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.associatedPreview:
        final title = _extractTitle(section.associatedPreview.heading);
        final items = _extractItemsFromItem(section.associatedPreview.item);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.audioSpotlight:
        final title = _extractTitle(section.audioSpotlight.heading);
        final items = _extractItemsFromItem(section.audioSpotlight.item);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.verticalSingleEntry:
        final title = _extractTitle(section.verticalSingleEntry.heading);
        final items = _extractItemsFromItem(section.verticalSingleEntry.item);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.narrative:
        return null;

      case casita.Section_FeatureType.topStoryCarousel:
        final items = <SpotifyEntity>[];
        for (final story in section.topStoryCarousel.stories) {
          items.addAll(_extractItemsFromList(story.items));
        }
        return _buildSection('', items, sectionId, SectionLayout.carousel, sectionType: ft);

      case casita.Section_FeatureType.videoCarousel:
        final title = _extractTitle(section.videoCarousel.heading);
        final items = _extractItemsFromList(section.videoCarousel.items);
        return _buildSection(title, items, sectionId, SectionLayout.carousel, sectionType: ft);

      case casita.Section_FeatureType.audioPromo:
        final title = _extractTitle(section.audioPromo.heading);
        final items = _extractItemsFromItem(section.audioPromo.item);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.inlineCard:
        return null;

      case casita.Section_FeatureType.watchFeed:
        final title = _extractTitle(section.watchFeed.heading);
        final items = <SpotifyEntity>[];
        for (final wfItem in section.watchFeed.items) {
          final uri = wfItem.hasItem() ? wfItem.item.identifier : '';
          if (uri.isEmpty) continue;

          if (wfItem.hasEntrypoint()) {
            final ep = wfItem.entrypoint;
            final thumbUrl = _cleanImageUrl(ep.thumbnailImage.url);
            final coverUrl = _cleanImageUrl(ep.coverImage.url);

            int durationSec = 0;
            if (ep.hasVideoFile() && ep.videoFile.endTime > ep.videoFile.startTime) {
              durationSec = ((ep.videoFile.endTime - ep.videoFile.startTime) ~/ 1000).toInt();
            }
            final durationStr = durationSec > 0
                ? '${(durationSec ~/ 60).toString().padLeft(2, '0')}:${(durationSec % 60).toString().padLeft(2, '0')}'
                : (ep.overline.isNotEmpty ? ep.overline : '');

            _storeTrait(uri, VideoCardTrait(
              title: ep.title,
              subtitle: ep.subtitle,
              videoThumbnailUrl: thumbUrl,
              showArtworkUrl: coverUrl,
              durationString: durationStr,
              overline: ep.overline,
            ));

            _storeTrait(uri, SimpleCardTrait(
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
        return _buildSection(title, items, sectionId, SectionLayout.carousel, sectionType: ft);

      case casita.Section_FeatureType.liveEvent:
        final title = _extractTitle(section.liveEvent.heading);
        final items = _extractItemsFromSource(section.liveEvent.itemSource);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.contentEvaluationList:
        final title = _extractTitle(section.contentEvaluationList.heading);
        final items = _extractItemsFromList(section.contentEvaluationList.items);
        return _buildSection(title, items, sectionId, SectionLayout.carousel, sectionType: ft);

      case casita.Section_FeatureType.reflection:
        final title = _extractTitle(section.reflection.heading);
        final items = _extractItemsFromItem(section.reflection.item);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.previewPromotionCarousel:
        final title = _extractTitle(section.previewPromotionCarousel.heading);
        final items = <SpotifyEntity>[];
        for (final wrapped in section.previewPromotionCarousel.items) {
          if (wrapped.hasVideoPromo() && wrapped.videoPromo.hasItem()) {
            items.addAll(_extractItemsFromItem(wrapped.videoPromo.item));
          }
        }
        return _buildSection(title, items, sectionId, SectionLayout.carousel, sectionType: ft);

      case casita.Section_FeatureType.interactiveEntrypoint:
        return null;

      case casita.Section_FeatureType.actionCardCarousel:
        final title = _extractTitle(section.actionCardCarousel.heading);
        final items = _extractItemsFromList(section.actionCardCarousel.items);
        return _buildSection(title, items, sectionId, SectionLayout.carousel, sectionType: ft);

      case casita.Section_FeatureType.campaignLinkCarousel:
        final title = _extractTitle(section.campaignLinkCarousel.heading);
        final items = _extractItemsFromSource(section.campaignLinkCarousel.itemSource);
        return _buildSection(title, items, sectionId, SectionLayout.carousel, sectionType: ft);

      case casita.Section_FeatureType.promotionV1:
        final title = _extractTitle(section.promotionV1.heading);
        final items = _extractItemsFromItem(section.promotionV1.item);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.promotionV3:
        final items = _extractItemsFromItem(section.promotionV3.item);
        return _buildSection('', items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.videoPromo:
        final title = _extractTitle(section.videoPromo.heading);
        final items = _extractItemsFromItem(section.videoPromo.item);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.playLinkPromo:
        final title = _extractTitle(section.playLinkPromo.heading);
        final items = _extractItemsFromItem(section.playLinkPromo.item);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.bannerWithAnimations:
        final items = _extractItemsFromItem(section.bannerWithAnimations.item);
        return _buildSection('', items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.anchors:
        final items = _extractItemsFromSource(section.anchors.itemSource);
        return _buildSection('', items, sectionId, SectionLayout.carousel, sectionType: ft);

      // ── Commercial brand ads & non-content (skip cleanly) ──────────
      case casita.Section_FeatureType.videoBrandAd:
      case casita.Section_FeatureType.imageBrandAd:
      case casita.Section_FeatureType.banner:
      case casita.Section_FeatureType.fullBleedBanner:
      case casita.Section_FeatureType.promptableSection:
      case casita.Section_FeatureType.concertCampaign:
      case casita.Section_FeatureType.promptedWorldsShelf:
      case casita.Section_FeatureType.userPromptedWorldEntrypoint:
      case casita.Section_FeatureType.callToAction:
        return null;

      case casita.Section_FeatureType.notSet:
        // Option B: Preserved in unknownFields, gracefully skip without crashing
        final unknownTags = section.unknownFields.asMap().keys.toList();
        dev.log('CasitaParser: Unrecognized section tag(s) $unknownTags (sectionId=$sectionId), skipped gracefully.');
        return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Item extraction helpers
  // ═══════════════════════════════════════════════════════════════════

  /// Extract items from an ItemSource (Provided, LocalRecentlyPlayed, ListPlatform)
  List<SpotifyEntity> _extractItemsFromSource(casita.ItemSource source) {
    switch (source.whichSource()) {
      case casita.ItemSource_Source.provided:
        return _extractItemsFromList(source.provided.items);
      case casita.ItemSource_Source.listPlatform:
        final uri = source.listPlatform.listUri;
        if (uri.isNotEmpty) {
          return [SpotifyEntity(uri: uri, type: ContentType.fromUri(uri), traits: {})];
        }
        return [];
      case casita.ItemSource_Source.localRecentlyPlayed:
        return [];
      case casita.ItemSource_Source.notSet:
        return [];
    }
  }

  /// Extract items from a repeated Item list (PreviewCarousel, TopStoryCarousel)
  List<SpotifyEntity> _extractItemsFromList(List<casita.Item> items) {
    final result = <SpotifyEntity>[];
    for (final item in items) {
      final uri = item.identifier;
      if (uri.isNotEmpty && uri.contains('spotify:')) {
        result.add(SpotifyEntity(uri: uri, type: ContentType.fromUri(uri), traits: {}));
      }
    }
    return result;
  }

  /// Extract items from a single Item field (Preview, ImmersivePreview, etc.)
  List<SpotifyEntity> _extractItemsFromItem(casita.Item item) {
    final uri = item.identifier;
    if (uri.isNotEmpty && uri.contains('spotify:')) {
      return [SpotifyEntity(uri: uri, type: ContentType.fromUri(uri), traits: {})];
    }
    return [];
  }

  // ═══════════════════════════════════════════════════════════════════
  // Heading / title extraction
  // ═══════════════════════════════════════════════════════════════════

  String _extractTitle(casita.Heading heading) {
    switch (heading.whichHeading()) {
      case casita.Heading_Heading.textHeading:
        return heading.textHeading.text;

      case casita.Heading_Heading.enrichedHeading:
        final format = heading.enrichedHeading.format;
        final assoc = heading.enrichedHeading.associatedItem;
        if (format.contains('{0}') && assoc.title.isNotEmpty) {
          return format.replaceAll('{0}', assoc.title);
        }
        return format;

      case casita.Heading_Heading.headingWithDescription:
        return heading.headingWithDescription.title;

      case casita.Heading_Heading.staticEnrichedHeading:
        return heading.staticEnrichedHeading.text;

      case casita.Heading_Heading.sponsoredHeading:
        return heading.sponsoredHeading.text;

      case casita.Heading_Heading.emptyHeading:
      case casita.Heading_Heading.notSet:
        return '';
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════

  HomeSection? _buildSection(
    String title,
    List<SpotifyEntity> items,
    String sectionId,
    SectionLayout layout, {
    String? sectionType,
  }) {
    if (title.isEmpty) title = _inferTitle(sectionId);
    if (items.isEmpty) return null;

    return HomeSection(
      title: title,
      items: items,
      layout: layout,
      sectionType: sectionType ?? _sectionType(sectionId),
    );
  }

  String _sectionType(String sectionId) {
    final pipeIdx = sectionId.indexOf('|');
    if (pipeIdx < 0) return 'music';
    final suffix = sectionId.substring(pipeIdx + 1).toLowerCase();
    if (suffix.startsWith('shortcuts')) return 'shortcuts';
    if (suffix.startsWith('podcast')) return 'podcast';
    if (suffix.startsWith('musicfeed')) return 'musicfeed';
    if (suffix.contains('nft-home') || suffix.contains('recently-played')) {
      return 'recents';
    }
    return 'music';
  }

  String _inferTitle(String id) {
    final pipeIdx = id.indexOf('|');
    if (pipeIdx < 0) return '';
    final suffix = id.substring(pipeIdx + 1);

    var clean = suffix
        .replaceAll(RegExp(r'\[.*\]'), '')
        .replaceAll(RegExp(r'-extended$'), '')
        .replaceAll('editorial-', '')
        .replaceAll('home-', '')
        .replaceAll('more-like-', 'More like ')
        .replaceAll('for-fans-of', 'For fans of')
        .replaceAll('inspired-by-', 'Inspired by ')
        .replaceAll('dig-deeper-into', 'Discover more from');

    if (clean.startsWith('More like ') ||
        clean.startsWith('For fans of') ||
        clean.startsWith('Inspired by ') ||
        clean.startsWith('Discover more from')) {
      return clean;
    }

    final parts = clean.split('-');
    return parts.map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join(' ').trim();
  }

  String? _cleanImageUrl(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('spotify:image:')) {
      return 'https://i.scdn.co/image/${url.split(':').last}';
    }
    if (url.startsWith('http')) return url;
    return null;
  }
}

/// Result of parsing a Casita response.
/// Contains the parsed HomeViewData and the on-demand URI set from field 999.
class CasitaResult {
  final HomeViewData homeData;
  final List<String> ondemandUris;
  final Map<String, Map<String, Trait>> traits;

  const CasitaResult({
    required this.homeData,
    required this.ondemandUris,
    this.traits = const {},
  });
}

