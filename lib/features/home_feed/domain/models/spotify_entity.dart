export 'traits.dart';
import 'traits.dart';

/// The core SDUI container.
/// Each entity has a URI, content type, and a bag of traits
/// that different UI widgets read from based on their context.
class SpotifyEntity {
  final String uri;
  final ContentType type;
  final Map<String, Trait> traits;

  const SpotifyEntity({
    required this.uri,
    required this.type,
    required this.traits,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpotifyEntity && other.uri == uri;
  }

  @override
  int get hashCode => uri.hashCode;

  /// Convenience fetcher for specific traits
  T? getTrait<T extends Trait>() {
    final typeName = T.toString();
    return traits[typeName] as T?;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Context-specific title/image getters
  // Each widget context has a different trait priority chain.
  // ═══════════════════════════════════════════════════════════════════

  /// Shortcuts grid: prioritizes ShortcutsCardTrait from eagerload.
  String get shortcutTitle {
    final sct = getTrait<ShortcutsCardTrait>();
    if (sct != null && sct.title.isNotEmpty) return sct.title;
    final simple = getTrait<SimpleCardTrait>();
    if (simple != null && simple.title.isNotEmpty) return simple.title;
    final identity = getTrait<IdentityTrait>();
    if (identity != null && identity.title.isNotEmpty) return identity.title;
    return '';
  }

  String? get shortcutImageUrl {
    return getTrait<ShortcutsCardTrait>()?.imageUrl
        ?? getTrait<SimpleCardTrait>()?.imageUrl;
  }

  /// Standard cards (carousels, grids): prioritizes SimpleCardTrait.
  String get cardTitle {
    final simple = getTrait<SimpleCardTrait>();
    if (simple != null && simple.title.isNotEmpty) return simple.title;
    final identity = getTrait<IdentityTrait>();
    if (identity != null && identity.title.isNotEmpty) return identity.title;
    final preview = getTrait<PreviewCardTrait>();
    if (preview != null && preview.title.isNotEmpty) return preview.title;
    final sct = getTrait<ShortcutsCardTrait>();
    if (sct != null && sct.title.isNotEmpty) return sct.title;
    return '';
  }

  String? get cardImageUrl {
    return getTrait<VisualIdentityTrait>()?.squareCoverUrl
        ?? getTrait<SimpleCardTrait>()?.imageUrl
        ?? getTrait<PreviewCardTrait>()?.imageUrl
        ?? getTrait<ShortcutsCardTrait>()?.imageUrl;
  }

  /// Preview/showcase: prioritizes PreviewCardTrait -> VisualIdentityTrait.
  String get previewTitle {
    final preview = getTrait<PreviewCardTrait>();
    if (preview != null && preview.title.isNotEmpty) return preview.title;
    final simple = getTrait<SimpleCardTrait>();
    if (simple != null && simple.title.isNotEmpty) return simple.title;
    final identity = getTrait<IdentityTrait>();
    if (identity != null && identity.title.isNotEmpty) return identity.title;
    return '';
  }

  String? get previewImageUrl {
    return getTrait<VisualIdentityTrait>()?.wideFullBleedUrl
        ?? getTrait<VisualIdentityTrait>()?.sixteenByNineCoverUrl
        ?? getTrait<VisualIdentityTrait>()?.squareCoverUrl
        ?? getTrait<PreviewCardTrait>()?.imageUrl
        ?? getTrait<SimpleCardTrait>()?.imageUrl;
  }

  /// Video thumbnail: prioritizes VideoCardTrait -> VisualIdentityTrait (16:9) -> PreviewPlaybackTrait -> AudioPreviewPlaybackTrait.
  String? get videoThumbnailUrl {
    final vt = getTrait<VideoCardTrait>();
    if (vt?.videoThumbnailUrl != null && vt!.videoThumbnailUrl!.isNotEmpty) {
      return vt.videoThumbnailUrl;
    }
    final vit = getTrait<VisualIdentityTrait>();
    if (vit?.sixteenByNineCoverUrl != null && vit!.sixteenByNineCoverUrl!.isNotEmpty) {
      return vit.sixteenByNineCoverUrl;
    }
    final pt = getTrait<PreviewPlaybackTrait>();
    if (pt?.videoImageUrl != null && pt!.videoImageUrl.isNotEmpty) {
      return pt.videoImageUrl;
    }
    final at = getTrait<AudioPreviewPlaybackTrait>();
    if (at?.videoPlaceholderImageUrl != null && at!.videoPlaceholderImageUrl.isNotEmpty) {
      return at.videoPlaceholderImageUrl;
    }
    return null;
  }

  /// Show/podcast artwork (square): prioritizes VisualIdentityTrait (square) -> VideoCardTrait -> cardImageUrl.
  String? get showArtworkUrl {
    final vit = getTrait<VisualIdentityTrait>();
    if (vit?.squareCoverUrl != null && vit!.squareCoverUrl!.isNotEmpty) {
      return vit.squareCoverUrl;
    }
    final vt = getTrait<VideoCardTrait>();
    if (vt?.showArtworkUrl != null && vt!.showArtworkUrl!.isNotEmpty) {
      return vt.showArtworkUrl;
    }
    return cardImageUrl;
  }

  /// Video duration badge text (e.g. "25:31" or "09:22").
  String get durationString {
    final vt = getTrait<VideoCardTrait>();
    if (vt != null && vt.durationString.isNotEmpty) return vt.durationString;
    return '';
  }

  /// Deterministically checks whether this entity has playable video metadata.
  bool get hasVideo {
    final vit = getTrait<VisualIdentityTrait>();
    if (vit?.hasVideo == true || (vit?.sixteenByNineCoverUrl != null && vit!.sixteenByNineCoverUrl!.isNotEmpty)) {
      return true;
    }
    final vt = getTrait<VideoCardTrait>();
    if (vt?.videoThumbnailUrl != null && vt!.videoThumbnailUrl!.isNotEmpty) {
      return true;
    }
    final pt = getTrait<PreviewPlaybackTrait>();
    if (pt?.hasVideo == true) {
      return true;
    }
    return false;
  }

  /// Card background color hex provided by Spotify (PreviewCardTrait or VisualIdentityTrait).
  String? get backgroundColorHex {
    return getTrait<PreviewCardTrait>()?.backgroundColor
        ?? getTrait<VisualIdentityTrait>()?.backgroundColorHex;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Serialization for cache
  // ═══════════════════════════════════════════════════════════════════

  Map<String, dynamic> toJson() {
    return {
      'uri': uri,
      'type': type.name,
      'traits': traits.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  factory SpotifyEntity.fromJson(Map<String, dynamic> json) {
    final rawTraits = json['traits'] as Map<String, dynamic>? ?? {};
    final mappedTraits = <String, Trait>{};

    for (final entry in rawTraits.entries) {
      final trait = Trait.fromJson(entry.key, entry.value as Map<String, dynamic>);
      if (trait != null) {
        mappedTraits[entry.key] = trait;
      }
    }

    return SpotifyEntity(
      uri: json['uri'] ?? '',
      type: ContentType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ContentType.unknown,
      ),
      traits: mappedTraits,
    );
  }
}
