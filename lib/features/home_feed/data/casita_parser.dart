import 'dart:developer' as dev;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:musify_mu/core/protocol/generated/spotify/casita/resolved.pb.dart' as casita;
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/visual_identity_trait.pb.dart' as vit;
import 'package:musify_mu/core/protocol/generated/spotify/traits/preview_card_trait.pb.dart' as pct;
import 'package:musify_mu/core/protocol/generated/spotify/traits/shortcuts_card_trait.pb.dart' as sct;
import 'package:musify_mu/core/protocol/generated/spotify/traits/simple_card_trait.pb.dart' as sct2;
import 'package:musify_mu/features/home_feed/data/section_mapper.dart';
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

      const mapper = SectionMapper();
      final sections = <HomeSection>[];
      for (final section in home.structure.sections) {
        try {
          final mapped = mapper.mapSection(
            section,
            extractSource: _extractItemsFromSource,
            extractList: _extractItemsFromList,
            extractSingle: _extractItemsFromItem,
            extractTitle: _extractTitleWithFallback,
            storeTrait: _storeTrait,
            cleanImageUrl: _cleanImageUrl,
          );
          if (mapped != null) {
            final parsed = mapped.toHomeSection();
            if (parsed.items.isNotEmpty ||
                parsed.sectionType == 'recentsShelf' ||
                parsed.sectionType == 'recents' ||
                parsed.sectionType == 'interactiveEntrypoint' ||
                parsed.sectionType == 'inlineCard') {
              sections.add(parsed);
            }
          }
        } catch (e) {
          dev.log('CasitaParser: Failed mapping section: $e');
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

      final chips = <HomeChip>[];
      for (final sec in hydratedSections) {
        if (sec.sectionType == 'anchors') {
          for (final item in sec.items) {
            final simple = item.getTrait<SimpleCardTrait>();
            final label = simple?.title.isNotEmpty == true
                ? simple!.title
                : (item.uri.split(':').isNotEmpty ? item.uri.split(':').last : item.uri);
            chips.add(HomeChip(id: item.uri, label: label));
          }
        }
      }

      final filteredSections = hydratedSections.where((s) => s.sectionType != 'anchors').toList();

      dev.log('CasitaParser: ${filteredSections.length} sections, $hydrated items hydrated, ${chips.length} chips');
      return CasitaResult(
        homeData: HomeViewData(
          sections: filteredSections,
          chips: chips.isNotEmpty ? chips : HomeViewData.defaultChips,
        ),
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

  String _extractTitleWithFallback(casita.Heading heading, [String sectionId = '']) {
    final title = _extractTitle(heading);
    if (title.isNotEmpty) return title;
    return _inferTitle(sectionId);
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

