import 'dart:developer' as dev;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:musify_mu/core/protocol/generated/spotify/casita/resolved.pb.dart' as casita;
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/batched_extension_response_parser.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/kodiak_cell_mapper.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/plugins/builtin_plugins.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/features/home_feed/data/section_mapper.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';

/// Parses the Casita (SDUI) response from Spotify's home feed endpoint.
///
/// Uses generated protobuf classes from the official Spotify proto schemas
/// (extracted from the decompiled APK) instead of manual binary parsing.
class CasitaParser {
  final Uint8List data;
  final ExtendedMetadataPluginRegistry _registry;

  /// URI -> { traitTypeName -> Trait } lookup
  final Map<String, Map<String, Trait>> _traits = {};

  CasitaParser(this.data, [ExtendedMetadataPluginRegistry? registry])
      : _registry = registry ??
            ExtendedMetadataPluginRegistry(createDefaultExtendedMetadataPlugins());
  CasitaParser._(this.data, this._registry);

  /// Result of parsing a Casita response.
  Future<CasitaResult> parse() async {
    // Run entire parse in background isolate to avoid UI jank.
    return Isolate.run(() => _parseSync(data));
  }

  /// Synchronous parsing -- runs in background isolate.
  static CasitaResult _parseSync(Uint8List data) {
    final registry =
        ExtendedMetadataPluginRegistry(createDefaultExtendedMetadataPlugins());
    final parser = CasitaParser._(data, registry);
    return parser._doParse();
  }

  CasitaResult _doParse() {
    try {
      _traits.clear();

      final home = casita.ResolvedHome.fromBuffer(data);
      Map<CellKey, Trait> eagerCells = const {};

      try {
        if (home.hasEagerlyLoadedTraits() && home.eagerlyLoadedTraits.hasTraits()) {
          final parsed = BatchedExtensionResponseParser.parseProtobuf(
            home.eagerlyLoadedTraits.traits,
            _registry,
          );
          eagerCells = KodiakCellMapper.map(parsed);
          for (final entry in parsed.entries) {
            final uri = entry.key;
            final map = _traits.putIfAbsent(uri, () => {});
            for (final traitEntry in entry.value.entries) {
              map[traitEntry.key.toString()] = traitEntry.value;
            }
          }
        }
        dev.log('CasitaParser: ${eagerCells.length} eager cells loaded via plugin registry');
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

      final filteredSections = hydratedSections.where((s) => s.sectionType != 'anchors').toList();

      dev.log('CasitaParser: ${filteredSections.length} sections, $hydrated items hydrated');
      return CasitaResult(
        homeData: HomeViewData(
          sections: filteredSections,
          chips: HomeViewData.defaultChips,
        ),
        ondemandUris: ondemandUris,
        traits: Map.of(_traits),
        eagerCells: eagerCells,
      );
    } catch (e, stack) {
      dev.log('CasitaParser: $e\n$stack');
      return CasitaResult(
        homeData: const HomeViewData(),
        ondemandUris: const [],
        eagerCells: const {},
      );
    }
  }

  Map<String, Trait>? traitsForUri(String uri) => _traits[uri] ?? _traits[uri.toLowerCase()];



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
      String uri = '';
      if (item.highlightedSubItems.isNotEmpty) {
        final episode = item.highlightedSubItems.firstWhere(
          (u) => u.contains(':episode:'),
          orElse: () => '',
        );
        if (episode.isNotEmpty) uri = episode;
      }
      if (uri.isEmpty) {
        uri = item.identifier.isNotEmpty
            ? item.identifier
            : (item.highlightedSubItems.isNotEmpty ? item.highlightedSubItems.first : '');
      }
      if (uri.isNotEmpty && uri.contains('spotify:')) {
        result.add(SpotifyEntity(uri: uri, type: ContentType.fromUri(uri), traits: {}));
        if (item.identifier.isNotEmpty && item.identifier.contains(':show:') && uri != item.identifier) {
          _storeTrait(uri, PreviewCardTrait(
            title: '',
            creatorUri: item.identifier,
          ));
        }
      }
    }
    return result;
  }

  /// Extract items from a single Item field (Preview, ImmersivePreview, etc.)
  List<SpotifyEntity> _extractItemsFromItem(casita.Item item) {
    String uri = '';
    if (item.highlightedSubItems.isNotEmpty) {
      final episode = item.highlightedSubItems.firstWhere(
        (u) => u.contains(':episode:'),
        orElse: () => '',
      );
      if (episode.isNotEmpty) uri = episode;
    }
    if (uri.isEmpty) {
      uri = item.identifier.isNotEmpty
          ? item.identifier
          : (item.highlightedSubItems.isNotEmpty ? item.highlightedSubItems.first : '');
    }
    if (uri.isNotEmpty && uri.contains('spotify:')) {
      final entity = SpotifyEntity(uri: uri, type: ContentType.fromUri(uri), traits: {});
      if (item.identifier.isNotEmpty && item.identifier.contains(':show:') && uri != item.identifier) {
        _storeTrait(uri, PreviewCardTrait(
          title: '',
          creatorUri: item.identifier,
        ));
      }
      return [entity];
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
  final Map<CellKey, Trait> eagerCells;

  const CasitaResult({
    required this.homeData,
    required this.ondemandUris,
    this.traits = const {},
    this.eagerCells = const {},
  });
}

