import 'dart:typed_data';

import 'package:musify_mu/core/protocol/generated/spotify/casita/resolved.pb.dart' as casita;
import 'package:musify_mu/core/protocol/generated/spotify/traits/preview_card_trait.pb.dart' as pct;
import 'package:musify_mu/core/protocol/generated/spotify/traits/shortcuts_card_trait.pb.dart' as sct;
import 'package:musify_mu/core/protocol/generated/spotify/traits/simple_card_trait.pb.dart' as sct2;
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/entity_extension_data.pb.dart';
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

  /// Result of parsing a Casita response.
  CasitaResult parse() {
    try {
      _traits.clear();

      final home = casita.ResolvedHome.fromBuffer(data);

      // Parse the eagerly loaded traits (repository) from field 2
      _parseEagerlyLoadedTraits(home.eagerlyLoadedTraits);
      print('📦 CasitaParser: ${_traits.length} URIs loaded from repository');

      // Extract the on-demand set (field 999) -- URIs needing trait resolution
      final ondemandUris = home.ondemandSet.uris.toList();
      print('📦 CasitaParser: ${ondemandUris.length} URIs in ondemandSet');

      // Parse all sections from field 1
      final sections = <HomeSection>[];
      for (final section in home.structure.sections) {
        final parsed = _parseSection(section);
        if (parsed != null && (parsed.items.isNotEmpty || parsed.sectionType == 'recents')) {
          sections.add(parsed);
        }
      }

      // Hydrate section items with traits from the repository
      int hydrated = 0;
      final hydratedSections = sections.map((section) {
        final hydratedItems = section.items.map((item) {
          final uriTraits = _traits[item.uri] ?? {};
          if (uriTraits.isNotEmpty) hydrated++;

          return SpotifyEntity(
            uri: item.uri,
            type: item.type,
            traits: uriTraits,
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

      print('📦 CasitaParser: ${hydratedSections.length} sections, $hydrated items hydrated');
      return CasitaResult(
        homeData: HomeViewData(sections: hydratedSections),
        ondemandUris: ondemandUris,
      );
    } catch (e, stack) {
      print('❌ CasitaParser: $e\n$stack');
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
    } else if (typeUrl.contains('IdentityTrait')) {
      _decodeIdentityTrait(uri, payload);
    }
  }

  void _decodeSimpleCardTrait(String uri, List<int> payload) {
    final trait = sct2.SimpleCardTrait.fromBuffer(payload);

    _storeTrait(uri, SimpleCardTrait(
      title: trait.title,
      subtitle: trait.subtitle,
      imageUrl: _cleanImageUrl(trait.imageUri),
      navigationUri: trait.navigationUri,
      accessibility: trait.accessibility,
    ));
  }

  void _decodeShortcutsCardTrait(String uri, List<int> payload) {
    final trait = sct.ShortcutsCardTrait.fromBuffer(payload);

    _storeTrait(uri, ShortcutsCardTrait(
      title: trait.title,
      imageUrl: _cleanImageUrl(trait.imageUrl),
    ));
  }

  void _decodePreviewCardTrait(String uri, List<int> payload) {
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
    } catch (_) {
      // Silently skip malformed identity traits
    }
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

    print('📋 Section: featureType=${featureType.name} sectionId=$sectionId');

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
        final title = _extractTitle(section.topStoryCarousel.heading);
        final items = _extractItemsFromList(section.topStoryCarousel.items);
        return _buildSection(title, items, sectionId, SectionLayout.carousel, sectionType: ft);

      case casita.Section_FeatureType.videoCarousel:
        final title = _extractTitle(section.videoCarousel.heading);
        final items = _extractItemsFromSource(section.videoCarousel.itemSource);
        return _buildSection(title, items, sectionId, SectionLayout.carousel, sectionType: ft);

      case casita.Section_FeatureType.audioPromo:
        final title = _extractTitle(section.audioPromo.heading);
        final items = _extractItemsFromItem(section.audioPromo.item);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.inlineCard:
        final title = _extractTitle(section.inlineCard.heading);
        final items = _extractItemsFromItem(section.inlineCard.item);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.watchFeed:
        final title = _extractTitle(section.watchFeed.heading);
        final items = _extractItemsFromSource(section.watchFeed.itemSource);
        return _buildSection(title, items, sectionId, SectionLayout.carousel, sectionType: ft);

      case casita.Section_FeatureType.liveEvent:
        final title = _extractTitle(section.liveEvent.heading);
        final items = _extractItemsFromItem(section.liveEvent.item);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.contentEvaluationList:
        final title = _extractTitle(section.contentEvaluationList.heading);
        final items = _extractItemsFromSource(section.contentEvaluationList.itemSource);
        return _buildSection(title, items, sectionId, SectionLayout.carousel, sectionType: ft);

      case casita.Section_FeatureType.reflection:
        final title = _extractTitle(section.reflection.heading);
        final items = _extractItemsFromItem(section.reflection.item);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.previewPromotionCarousel:
        final title = _extractTitle(section.previewPromotionCarousel.heading);
        final items = <SpotifyEntity>[];
        for (final wrapped in section.previewPromotionCarousel.items) {
          final uri = wrapped.item.identifier;
          if (uri.isNotEmpty && uri.contains('spotify:')) {
            items.add(SpotifyEntity(uri: uri, type: ContentType.fromUri(uri), traits: {}));
          }
        }
        return _buildSection(title, items, sectionId, SectionLayout.carousel, sectionType: ft);

      case casita.Section_FeatureType.interactiveEntrypoint:
        final title = _extractTitle(section.interactiveEntrypoint.heading);
        final items = _extractItemsFromItem(section.interactiveEntrypoint.item);
        return _buildSection(title, items, sectionId, SectionLayout.feed, sectionType: ft);

      case casita.Section_FeatureType.callToAction:
        return null; // CTA ads, skip

      case casita.Section_FeatureType.notSet:
      default:
        print('⚠️ CasitaParser: Unknown section type ${featureType.name} (sectionId=$sectionId)');
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
        final uri = source.listPlatform.uri;
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

  const CasitaResult({
    required this.homeData,
    required this.ondemandUris,
  });
}

