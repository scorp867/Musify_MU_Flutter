

enum ContentType {
  album,
  playlist,
  artist,
  track,
  episode,
  podcast,
  unknown;

  static ContentType fromUri(String uri) {
    if (uri.contains(':album:')) return album;
    if (uri.contains(':playlist:')) return playlist;
    if (uri.contains(':artist:')) return artist;
    if (uri.contains(':track:')) return track;
    if (uri.contains(':episode:')) return episode;
    if (uri.contains(':show:')) return podcast;
    if (uri.contains(':collection:')) return playlist;
    return unknown;
  }
}

/// Base class for all Spotify SDUI Traits.
abstract class Trait {
  const Trait();
  Map<String, dynamic> toJson();
  
  static Trait? fromJson(String type, Map<String, dynamic> json) {
    switch (type) {
      case 'SimpleCardTrait': return SimpleCardTrait.fromJson(json);
      case 'PreviewCardTrait': return PreviewCardTrait.fromJson(json);
      case 'IdentityTrait': return IdentityTrait.fromJson(json);
      case 'ShortcutsCardTrait': return ShortcutsCardTrait.fromJson(json);
      case 'FallbackMetadataTrait': return FallbackMetadataTrait.fromJson(json);
      default: return null;
    }
  }
}

/// Defines a standard square or circular card.
class SimpleCardTrait extends Trait {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? navigationUri;
  final String? accessibility;

  const SimpleCardTrait({
    required this.title,
    this.subtitle = '',
    this.imageUrl,
    this.navigationUri,
    this.accessibility,
  });

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'navigationUri': navigationUri,
    'accessibility': accessibility,
  };

  factory SimpleCardTrait.fromJson(Map<String, dynamic> json) {
    final image = json['imageUrl'] as String?;

    return SimpleCardTrait(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: image?.isEmpty == true ? null : image,
      navigationUri: json['navigationUri'],
      accessibility: json['accessibility'],
    );
  }
}

/// Defines an IdentityTrait (used for tracks).
class IdentityTrait extends Trait {
  final String title;
  
  const IdentityTrait({required this.title});

  @override
  Map<String, dynamic> toJson() => {'title': title};

  factory IdentityTrait.fromJson(Map<String, dynamic> json) => IdentityTrait(
    title: json['title'] ?? '',
  );
}

/// Defines a preview card with background color, tags, and play preview.
/// Field mapping matches the official PreviewCardTrait proto schema.
class PreviewCardTrait extends Trait {
  final String title;
  final String contentTypeName;  // "Playlist", "Album", "Episode"
  final String description;      // Artist list or episode description
  final String? imageUrl;
  final String? backgroundColor; // hex e.g. "3a7f97ff"
  final String? waveformColor;   // hex e.g. "3a7f9755"
  final int trackCount;
  final String? entityUri;
  final String? navigateUri;
  final List<String> tags;       // e.g. ["Bollywood", "Driving", "Road Trip"]
  final String previewLabel;     // e.g. "Preview playlist"
  final String playingLabel;     // e.g. "Playing playlist"
  final String creatorName;      // e.g. "Spotify"
  final String creatorUri;
  final String creatorImageUrl;

  const PreviewCardTrait({
    required this.title,
    this.contentTypeName = '',
    this.description = '',
    this.imageUrl,
    this.backgroundColor,
    this.waveformColor,
    this.trackCount = 0,
    this.entityUri,
    this.navigateUri,
    this.tags = const [],
    this.previewLabel = '',
    this.playingLabel = '',
    this.creatorName = '',
    this.creatorUri = '',
    this.creatorImageUrl = '',
  });

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'contentTypeName': contentTypeName,
    'description': description,
    'imageUrl': imageUrl,
    'backgroundColor': backgroundColor,
    'waveformColor': waveformColor,
    'trackCount': trackCount,
    'entityUri': entityUri,
    'navigateUri': navigateUri,
    'tags': tags,
    'previewLabel': previewLabel,
    'playingLabel': playingLabel,
    'creatorName': creatorName,
    'creatorUri': creatorUri,
    'creatorImageUrl': creatorImageUrl,
  };

  factory PreviewCardTrait.fromJson(Map<String, dynamic> json) {
    final image = json['imageUrl'] as String?;
    final bg = json['backgroundColor'] as String?;

    return PreviewCardTrait(
      title: json['title'] ?? '',
      contentTypeName: json['contentTypeName'] ?? '',
      description: json['description'] ?? '',
      imageUrl: image?.isEmpty == true ? null : image,
      backgroundColor: bg?.isEmpty == true ? null : bg,
      waveformColor: json['waveformColor'],
      trackCount: json['trackCount'] ?? 0,
      entityUri: json['entityUri'],
      navigateUri: json['navigateUri'],
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      previewLabel: json['previewLabel'] ?? '',
      playingLabel: json['playingLabel'] ?? '',
      creatorName: json['creatorName'] ?? '',
      creatorUri: json['creatorUri'] ?? '',
      creatorImageUrl: json['creatorImageUrl'] ?? '',
    );
  }
}

/// Defines a small pill-shaped shortcuts card.
class ShortcutsCardTrait extends Trait {
  final String title;
  final String? imageUrl;

  const ShortcutsCardTrait({
    required this.title,
    this.imageUrl,
  });

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'imageUrl': imageUrl,
  };

  factory ShortcutsCardTrait.fromJson(Map<String, dynamic> json) => ShortcutsCardTrait(
    title: json['title'] ?? '',
    imageUrl: json['imageUrl'],
  );
}

/// Metadata fetched via /extended-metadata fallback.
class FallbackMetadataTrait extends Trait {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? extractedColor;
  final String? badge;

  const FallbackMetadataTrait({
    required this.title,
    this.subtitle = '',
    this.imageUrl,
    this.extractedColor,
    this.badge,
  });

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'extractedColor': extractedColor,
    'badge': badge,
  };

  factory FallbackMetadataTrait.fromJson(Map<String, dynamic> json) => FallbackMetadataTrait(
    title: json['title'] ?? '',
    subtitle: json['subtitle'] ?? '',
    imageUrl: json['imageUrl'],
    extractedColor: json['extractedColor'],
    badge: json['badge'],
  );
}

/// The core SDUI container.
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
  
  /// Helper to get ANY available title
  String get fallbackTitle {
    return getTrait<SimpleCardTrait>()?.title 
        ?? getTrait<IdentityTrait>()?.title
        ?? getTrait<PreviewCardTrait>()?.title 
        ?? getTrait<ShortcutsCardTrait>()?.title 
        ?? '';
  }

  /// Helper to get ANY available image
  String? get fallbackImageUrl {
    return getTrait<SimpleCardTrait>()?.imageUrl 
        ?? getTrait<PreviewCardTrait>()?.imageUrl 
        ?? getTrait<ShortcutsCardTrait>()?.imageUrl;
  }

  /// Serialization for cache
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
