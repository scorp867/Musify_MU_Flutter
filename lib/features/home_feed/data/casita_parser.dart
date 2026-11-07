import 'dart:collection';
import 'dart:developer' as dev;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:musify_mu/core/kodiak/extendedmetadataimpl/batched_extension_response_parser.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/kodiak_cell_mapper.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/plugins/builtin_plugins.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/protocol/generated/spotify/casita/resolved.pb.dart'
    as casita;
import 'package:musify_mu/features/home_feed/data/casita_result.dart';
import 'package:musify_mu/features/home_feed/data/section_mapper.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

export 'casita_result.dart';

/// Parses the Casita (SDUI) response from Spotify's home feed endpoint.
class CasitaParser {
  final Uint8List data;
  final ExtendedMetadataPluginRegistry _registry;

  final Map<String, Map<String, Trait>> _traits = {};

  CasitaParser(this.data, [ExtendedMetadataPluginRegistry? registry])
    : _registry =
          registry ??
          ExtendedMetadataPluginRegistry(
            createDefaultExtendedMetadataPlugins(),
          );
  CasitaParser._(this.data, this._registry);

  Future<CasitaResult> parse() async {
    return Isolate.run(() => _parseSync(data));
  }

  static CasitaResult _parseSync(Uint8List data) {
    final registry = ExtendedMetadataPluginRegistry(
      createDefaultExtendedMetadataPlugins(),
    );
    final parser = CasitaParser._(data, registry);
    return parser._doParse();
  }

  CasitaResult _doParse() {
    if (data.isEmpty) {
      throw const FormatException('CasitaParser: empty ResolvedHome payload');
    }

    _traits.clear();

    final casita.ResolvedHome home;
    try {
      home = casita.ResolvedHome.fromBuffer(data);
    } on Object catch (e) {
      throw FormatException('CasitaParser: invalid ResolvedHome protobuf: $e');
    }

    Map<CellKey, Trait> eagerCells = const {};
    Map<(int, String), Uint8List> eagerRawPayloads = const {};

    try {
      if (home.hasEagerlyLoadedTraits() &&
          home.eagerlyLoadedTraits.hasTraits()) {
        final decoded = BatchedExtensionResponseParser.parseProtobufWithRaw(
          home.eagerlyLoadedTraits.traits,
          _registry,
        );
        eagerCells = KodiakCellMapper.map(decoded.parsed);
        eagerRawPayloads = decoded.rawPayloads;
        for (final entry in decoded.parsed.entries) {
          final uri = entry.key;
          final map = _traits.putIfAbsent(uri, () => {});
          for (final traitEntry in entry.value.entries) {
            map[traitEntry.key.toString()] = traitEntry.value;
          }
        }
      }
      dev.log(
        'CasitaParser: ${eagerCells.length} eager cells loaded via plugin registry',
      );
    } catch (e) {
      dev.log('CasitaParser: Eager traits failed: $e');
    }

    final ondemandUris = List<String>.unmodifiable(home.ondemandSet.uris);

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
              parsed.sectionType == 'inlineCard' ||
              parsed.sectionType == 'fullBleedBanner' ||
              parsed.sectionType == 'banner') {
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
        final uriTraits = _traits[item.uri];
        if (uriTraits != null && uriTraits.isNotEmpty) hydrated++;

        return SpotifyEntity(
          uri: item.uri,
          type: item.type,
          traits: uriTraits != null ? Map.of(uriTraits) : const {},
        );
      }).toList(growable: false);

      String? colorCode = section.colorCode;
      String? imageUrl = section.imageUrl;
      final metadata = Map<String, Object?>.of(section.metadata);

      if (hydratedItems.isNotEmpty) {
        final firstItem = hydratedItems.first;
        final previewTrait = firstItem.getTrait<PreviewCardTrait>();
        if (previewTrait != null) {
          if (colorCode == null) {
            if (previewTrait.backgroundColor case final bg?
                when bg.isNotEmpty) {
              final rawBg = bg.replaceAll('#', '').trim();
              if (rawBg.length >= 6) {
                colorCode = '#${rawBg.substring(0, 6).toUpperCase()}';
              } else {
                colorCode = bg;
              }
            }
          }
          imageUrl ??= previewTrait.imageUrl;
          if (previewTrait.title.isNotEmpty) {
            metadata['itemTitle'] = previewTrait.title;
          }
        }
      }

      return HomeSection(
        title: section.title,
        subtitle: section.subtitle,
        items: hydratedItems,
        layout: section.layout,
        sectionUri: section.sectionUri,
        sectionType: section.sectionType,
        colorCode: colorCode,
        imageUrl: imageUrl,
        metadata: UnmodifiableMapView<String, Object?>(metadata),
      );
    }).toList();

    final filteredSections = List<HomeSection>.unmodifiable(
      hydratedSections.where((s) => s.sectionType != 'anchors'),
    );

    dev.log(
      'CasitaParser: ${filteredSections.length} sections, $hydrated items hydrated',
    );
    return CasitaResult(
      homeData: HomeViewData(
        sections: filteredSections,
        chips: HomeViewData.defaultChips,
      ),
      ondemandUris: ondemandUris,
      traits: Map.of(_traits),
      eagerCells: eagerCells,
      eagerRawPayloads: eagerRawPayloads,
    );
  }

  Map<String, Trait>? traitsForUri(String uri) =>
      _traits[uri] ?? _traits[uri.toLowerCase()];

  void _storeTrait(String uri, Trait trait) {
    _traits.putIfAbsent(uri, () => {})[trait.runtimeType.toString()] = trait;
  }

  String _extractTitleWithFallback(
    casita.Heading heading, [
    String sectionId = '',
  ]) {
    final title = _extractTitle(heading);
    if (title.isNotEmpty) return title;
    return _inferTitle(sectionId);
  }

  List<SpotifyEntity> _extractItemsFromSource(casita.ItemSource source) {
    switch (source.whichSource()) {
      case casita.ItemSource_Source.provided:
        return _extractItemsFromList(source.provided.items);
      case casita.ItemSource_Source.listPlatform:
        final uri = source.listPlatform.listUri;
        if (uri.isNotEmpty) {
          return [SpotifyEntity(uri: uri, type: ContentType.fromUri(uri), traits: const {})];
        }
        return [];
      case casita.ItemSource_Source.localRecentlyPlayed:
        return [];
      case casita.ItemSource_Source.notSet:
        return [];
    }
  }

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
            : (item.highlightedSubItems.isNotEmpty
                  ? item.highlightedSubItems.first
                  : '');
      }
      if (uri.isNotEmpty && uri.contains('spotify:')) {
        result.add(SpotifyEntity(uri: uri, type: ContentType.fromUri(uri), traits: const {}));
        if (item.identifier.isNotEmpty &&
            item.identifier.contains(':show:') &&
            uri != item.identifier) {
          _storeTrait(
            uri,
            PreviewCardTrait(title: '', creatorUri: item.identifier),
          );
        }
      }
    }
    return result;
  }

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
          : (item.highlightedSubItems.isNotEmpty
                ? item.highlightedSubItems.first
                : '');
    }
    if (uri.isNotEmpty && uri.contains('spotify:')) {
      final entity = SpotifyEntity(uri: uri, type: ContentType.fromUri(uri), traits: const {});
      if (item.identifier.isNotEmpty &&
          item.identifier.contains(':show:') &&
          uri != item.identifier) {
        _storeTrait(
          uri,
          PreviewCardTrait(title: '', creatorUri: item.identifier),
        );
      }
      return [entity];
    }
    return [];
  }

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
    return parts
        .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
        .join(' ')
        .trim();
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
