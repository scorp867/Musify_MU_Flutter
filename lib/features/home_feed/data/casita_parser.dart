import 'dart:convert';
import 'dart:typed_data';

import 'package:musify_mu/core/protocol/protobuf_utils.dart';
import 'package:musify_mu/features/home_feed/domain/models/content_item.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';

/// Parses the raw protobuf response from Casita `/casita/v1/home/default`.
///
/// Binary format (from forensic analysis):
///   Top: F1=Sections(~14KB) F2=Repository(~81KB) F3=PageMeta F999=MixURIs
///   Repository: F1 → F2 blocks → F3 entries → traits {uri → title, image}
///   Sections: repeated F1 → each has F1=ID wrapper + body on dynamic field
///
/// Two-pass approach:
///   1. Parse Repository → build traits map {uri → metadata}
///   2. Parse Sections → extract URIs → hydrate with traits
class CasitaParser {
  final Uint8List data;
  final Map<String, ContentItem> _traits = {};

  CasitaParser(this.data);

  /// Parses the full Casita response into [HomeViewData].
  HomeViewData parse() {
    try {
      _traits.clear();

      // Pass 1: Parse repository to build the traits lookup table.
      final repoBytes = protoNavTo(data, 2);
      if (repoBytes != null) _parseRepository(repoBytes);
      print('📦 CasitaParser: ${_traits.length} traits loaded from repository');

      // Pass 2: Parse sections.
      final sectionsBytes = protoNavTo(data, 1);
      if (sectionsBytes == null) {
        print('❌ CasitaParser: No sections blob (F1) found');
        return const HomeViewData();
      }
      final sectionBlobs = protoCollectField(sectionsBytes, 1);
      print('📦 CasitaParser: ${sectionBlobs.length} raw section blobs found');

      final sections = <HomeSection>[];
      for (final blob in sectionBlobs) {
        final section = _parseSection(blob);
        if (section != null &&
            (section.items.isNotEmpty || section.sectionType == 'recents')) {
          sections.add(section);
        }
      }

      // Pass 3: Hydrate section items with trait metadata.
      int hydrated = 0;
      final hydratedSections = sections.map((section) {
        final hydratedItems = section.items.map((item) {
          final trait = _findTrait(item.uri);
          if (trait == null) return item;
          hydrated++;
          return item.copyWith(
            title: trait.title.isNotEmpty ? trait.title : null,
            subtitle: trait.subtitle.isNotEmpty ? trait.subtitle : null,
            imageUrl: trait.imageUrl?.isNotEmpty == true ? trait.imageUrl : null,
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

      print('📦 CasitaParser: ${hydratedSections.length} sections, '
          '$hydrated items hydrated');
      return HomeViewData(sections: hydratedSections);
    } catch (e, stack) {
      print('❌ CasitaParser: $e\n$stack');
      return const HomeViewData();
    }
  }

  /// Lookup a trait by URI.
  ContentItem? traitForUri(String uri) => _findTrait(uri);

  // ═══════════════════════════════════════════════════════════════════
  // Repository parsing — builds {uri → ContentItem} traits map
  // ═══════════════════════════════════════════════════════════════════

  void _parseRepository(Uint8List bytes) {
    final inner = protoNavTo(bytes, 1);
    if (inner == null) return;

    final blocks = protoCollectField(inner, 2);
    for (final block in blocks) {
      final entries = protoCollectField(block, 3);
      for (final entry in entries) {
        _parseRepoEntry(entry);
      }
    }
  }

  void _parseRepoEntry(Uint8List entryBytes) {
    String uri = '';
    Uint8List? traitBytes;

    final reader = SpotifyProtoReader(entryBytes);
    while (reader.hasMore()) {
      final tag = reader.readTag();
      final field = tag >> 3;
      final wt = tag & 0x7;

      if (field == 2 && wt == 2) {
        uri = reader.readString();
      } else if (field == 3 && wt == 2) {
        traitBytes = reader.readBytes();
      } else {
        reader.skipField(wt);
      }
    }

    if (uri.isEmpty || traitBytes == null) return;

    // Parse google.protobuf.Any wrapper: F1=type_url, F2=payload
    String typeUrl = '';
    Uint8List? payload;
    final traitReader = SpotifyProtoReader(traitBytes);
    while (traitReader.hasMore()) {
      final tag = traitReader.readTag();
      final field = tag >> 3;
      final wt = tag & 0x7;

      if (field == 1 && wt == 2) {
        typeUrl = traitReader.readString();
      } else if (field == 2 && wt == 2) {
        payload = traitReader.readBytes();
      } else {
        traitReader.skipField(wt);
      }
    }

    if (payload == null) return;

    // Dispatch to correct decoder based on type_url
    if (typeUrl.contains('SimpleCardTrait')) {
      _decodeSimpleCardTrait(uri, payload);
    } else if (typeUrl.contains('ShortcutsCardTrait')) {
      _decodeShortcutsCardTrait(uri, payload);
    } else if (typeUrl.contains('PreviewCardTrait')) {
      _decodePreviewCardTrait(uri, payload);
    }
    // PreviewPlaybackTrait → no visual metadata, skip
  }

  /// SimpleCardTrait: F1=imageUrl F2=title F3=subtitle F6=titleRendered
  void _decodeSimpleCardTrait(String uri, Uint8List payload) {
    String image = '', title = '', subtitle = '', titleRendered = '';

    final reader = SpotifyProtoReader(payload);
    while (reader.hasMore()) {
      final tag = reader.readTag();
      if (tag == 0) break;
      final field = tag >> 3;
      final wt = tag & 0x7;

      if (wt == 2) {
        final bytes = reader.readBytes();
        final str = _safeDecodeString(bytes);
        switch (field) {
          case 1: image = str;
          case 2: title = str;
          case 3: subtitle = str;
          case 6: titleRendered = str;
        }
      } else {
        reader.skipField(wt);
      }
    }

    // titleRendered often has format "Title. Subtitle info"
    final displayTitle = title.isNotEmpty
        ? title
        : (titleRendered.contains('.')
            ? titleRendered.split('.').first.trim()
            : titleRendered);

    _storeTrait(uri, displayTitle, subtitle, image);
  }

  /// ShortcutsCardTrait: F1=imageUrl F2=title(str|msg) F3=contextUri
  void _decodeShortcutsCardTrait(String uri, Uint8List payload) {
    String image = '', title = '';

    final reader = SpotifyProtoReader(payload);
    while (reader.hasMore()) {
      final tag = reader.readTag();
      if (tag == 0) break;
      final field = tag >> 3;
      final wt = tag & 0x7;

      if (wt == 2) {
        final bytes = reader.readBytes();
        if (field == 1) {
          image = _safeDecodeString(bytes);
        } else if (field == 2) {
          // F2 can be a string (title) OR a submessage — try as string
          final s = _safeDecodeString(bytes);
          if (s.isNotEmpty && _isPrintableTitle(s)) {
            title = s;
          }
        } else {
          // skip
        }
      } else {
        reader.skipField(wt);
      }
    }

    _storeTrait(uri, title, '', image);
  }

  /// PreviewCardTrait (podcasts): F1=title F3=author F8=imageUrl
  void _decodePreviewCardTrait(String uri, Uint8List payload) {
    String title = '', author = '', image = '';

    final reader = SpotifyProtoReader(payload);
    while (reader.hasMore()) {
      final tag = reader.readTag();
      if (tag == 0) break;
      final field = tag >> 3;
      final wt = tag & 0x7;

      if (wt == 2) {
        final bytes = reader.readBytes();
        final str = _safeDecodeString(bytes);
        switch (field) {
          case 1: title = str;
          case 3: author = str;
          case 8: image = str;
        }
      } else {
        reader.skipField(wt);
      }
    }

    _storeTrait(uri, title, author, image);
  }

  /// Stores a trait in the lookup map after cleaning the image URL.
  void _storeTrait(String uri, String title, String subtitle, String image) {
    final cleanImage = _cleanImageUrl(image);
    if (title.isEmpty && cleanImage.isEmpty) return;

    _traits[uri] = ContentItem(
      uri: uri,
      title: title,
      subtitle: subtitle,
      imageUrl: cleanImage.isNotEmpty ? cleanImage : null,
      type: ContentType.fromUri(uri),
    );
  }


  // ═══════════════════════════════════════════════════════════════════
  // Section parsing — matches Meliora_MU CasitaParser V8
  // ═══════════════════════════════════════════════════════════════════

  HomeSection? _parseSection(Uint8List sectionBytes) {
    // Section structure:
    //   F1 = ID wrapper (contains F1 = actual ID string)
    //   First field > 1 = body (field number determines body type)
    String sectionId = '';
    int bodyField = 0;
    Uint8List? bodyBytes;

    final reader = SpotifyProtoReader(sectionBytes);
    while (reader.hasMore()) {
      final tag = reader.readTag();
      final field = tag >> 3;
      final wt = tag & 0x7;

      if (field == 1 && wt == 2 && sectionId.isEmpty) {
        // F1 = section ID wrapper containing F1 = actual ID string
        final idWrapper = reader.readBytes();
        sectionId = protoReadStringField(idWrapper, 1) ?? '';
      } else if (field > 1 && wt == 2 && bodyBytes == null) {
        // First field > 1 is the body — remember which field number
        bodyField = field;
        bodyBytes = reader.readBytes();
      } else {
        reader.skipField(wt);
      }
    }

    if (bodyBytes == null) return null;

    final sectionType = _sectionType(sectionId);

    // Extract title and items based on body field number.
    String title = '';
    List<ContentItem> items = [];

    switch (bodyField) {
      case 2: // Shortcuts (quick access grid — no title like Spotify)
        items = _parseShortcutsBody(bodyBytes);
        return HomeSection(
          title: '',
          items: items,
          layout: SectionLayout.quickGrid,
          sectionType: 'shortcuts',
        );

      case 3: // Standard music shelves (most sections)
        title = _extractTitleFromHeader(bodyBytes);
        items = _extractWrappedItems(bodyBytes);

      case 4: // Podcast sections
        title = _extractTitleFromHeader(bodyBytes);
        items = _extractPodcastItems(bodyBytes);

      case 6: // Musicfeed sections (with track previews)
        title = _extractTitleFromHeader(bodyBytes);
        items = _extractMusicfeedItems(bodyBytes);

      case 10: // NFT/Recents section (internal list reference)
        title = _extractTitleFromHeader(bodyBytes);
        if (title.isEmpty) title = 'Recents';
        return HomeSection(
          title: title,
          items: [],
          layout: SectionLayout.carousel,
          sectionType: 'recents',
        );

      default: // Unknown body field — try generic extraction
        title = _extractTitleFromHeader(bodyBytes);
        items = _extractWrappedItems(bodyBytes);
    }

    if (title.isEmpty) title = _inferTitle(sectionId);
    if (items.isEmpty) return null;

    final layout = switch (sectionType) {
      'shortcuts' => SectionLayout.quickGrid,
      'musicfeed' => SectionLayout.feed,
      _ => SectionLayout.carousel,
    };

    return HomeSection(
      title: title,
      items: items,
      layout: layout,
      sectionType: sectionType,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Body-specific item extractors
  // ═══════════════════════════════════════════════════════════════════

  /// Extracts title from a section body's F1 header.
  /// Handles both plain title (F1.F2.F1) and template title (F1.F3).
  String _extractTitleFromHeader(Uint8List bodyBytes) {
    final headerBytes = protoNavTo(bodyBytes, 1);
    if (headerBytes == null) return '';

    // Try path 1: F2.F1 = direct title (e.g., "Charts", "Popular radio")
    final titleWrapper = protoNavTo(headerBytes, 2);
    if (titleWrapper != null) {
      final directTitle = protoReadStringField(titleWrapper, 1);
      if (directTitle != null &&
          directTitle.isNotEmpty &&
          !directTitle.contains('{0}')) {
        return directTitle;
      }
    }

    // Try path 2: F3 = template title (e.g., "More like {0}")
    final templateWrapper = protoNavTo(headerBytes, 3);
    if (templateWrapper != null) {
      final template = protoReadStringField(templateWrapper, 1) ?? '';
      final paramsBytes = protoNavTo(templateWrapper, 2);
      if (paramsBytes != null && template.contains('{0}')) {
        final artistName = protoReadStringField(paramsBytes, 1) ?? '';
        if (artistName.isNotEmpty) {
          return template.replaceAll('{0}', artistName);
        }
      }
    }

    return '';
  }

  /// Shortcuts body: F2.F1 → repeated F1 items → {F1=primaryUri}
  List<ContentItem> _parseShortcutsBody(Uint8List bodyBytes) {
    final itemsContainer = protoNavTo(bodyBytes, 2);
    if (itemsContainer == null) return [];
    final itemsList = protoNavTo(itemsContainer, 1);
    if (itemsList == null) return [];

    final items = <ContentItem>[];
    final itemBlobs = protoCollectField(itemsList, 1);

    for (final blob in itemBlobs) {
      final uri = protoReadStringField(blob, 1);
      if (uri != null && uri.contains('spotify:')) {
        items.add(ContentItem(
          uri: uri,
          title: '',
          type: ContentType.fromUri(uri),
        ));
      }
    }
    return items;
  }

  /// Standard sections: body.F2.F1 → repeated F1(wrapper) → F1=URI
  List<ContentItem> _extractWrappedItems(Uint8List bodyBytes) {
    final itemsContainer = protoNavTo(bodyBytes, 2);
    if (itemsContainer == null) return [];
    final itemsListBytes = protoNavTo(itemsContainer, 1);
    if (itemsListBytes == null) return [];

    return _extractUrisFromItemsList(itemsListBytes);
  }

  /// Podcast sections: body.F2 → {F1=showUri, F2=episodeUri}
  List<ContentItem> _extractPodcastItems(Uint8List bodyBytes) {
    final itemsContainer = protoNavTo(bodyBytes, 2);
    if (itemsContainer == null) return [];

    final showUri = protoReadStringField(itemsContainer, 1);
    final episodeUri = protoReadStringField(itemsContainer, 2);
    if (showUri == null || showUri.isEmpty) return [];

    return [
      ContentItem(
        uri: episodeUri ?? showUri,
        title: '',
        subtitle: showUri,
        type: ContentType.fromUri(episodeUri ?? showUri),
      ),
    ];
  }

  /// Musicfeed sections: body.F2 → F1=playlistUri
  List<ContentItem> _extractMusicfeedItems(Uint8List bodyBytes) {
    final itemsContainer = protoNavTo(bodyBytes, 2);
    if (itemsContainer == null) return [];

    final playlistUri = protoReadStringField(itemsContainer, 1);
    if (playlistUri != null && playlistUri.isNotEmpty) {
      return [
        ContentItem(
          uri: playlistUri,
          title: '',
          type: ContentType.fromUri(playlistUri),
        ),
      ];
    }
    return [];
  }

  /// Parses repeated F1 items from an items list blob.
  /// Each F1 item contains F1=URI.
  List<ContentItem> _extractUrisFromItemsList(Uint8List listBytes) {
    final items = <ContentItem>[];
    final itemBlobs = protoCollectField(listBytes, 1);

    for (final blob in itemBlobs) {
      final uri = protoReadStringField(blob, 1);
      if (uri != null && uri.contains('spotify:')) {
        items.add(ContentItem(
          uri: uri,
          title: '',
          type: ContentType.fromUri(uri),
        ));
      }
    }
    return items;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════

  ContentItem? _findTrait(String uri) {
    return _traits[uri] ?? _traits[uri.toLowerCase()];
  }

  /// Safely decode bytes as UTF-8 string. Returns empty string on failure.
  String _safeDecodeString(Uint8List bytes) {
    if (bytes.isEmpty) return '';
    try {
      final s = utf8.decode(bytes, allowMalformed: false);
      return s.trim();
    } catch (_) {
      return '';
    }
  }

  bool _isPrintableTitle(String s) {
    if (s.length < 2 || s.length > 200) return false;
    for (final c in s.codeUnits) {
      if (c < 32 && c != 10 && c != 13 && c != 9) return false;
    }
    return true;
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
    return parts
        .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
        .join(' ')
        .trim();
  }

  String _cleanImageUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('spotify:image:')) {
      return 'https://i.scdn.co/image/${url.split(':').last}';
    }
    if (url.startsWith('http')) return url;
    return '';
  }
}
