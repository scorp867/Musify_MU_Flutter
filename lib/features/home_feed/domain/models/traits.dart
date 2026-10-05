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
    return switch (type) {
      'SimpleCardTrait' => SimpleCardTrait.fromJson(json),
      'PreviewCardTrait' => PreviewCardTrait.fromJson(json),
      'IdentityTrait' => IdentityTrait.fromJson(json),
      'ShortcutsCardTrait' => ShortcutsCardTrait.fromJson(json),
      'FallbackMetadataTrait' => FallbackMetadataTrait.fromJson(json),
      'RecentsMetadataTrait' => RecentsMetadataTrait.fromJson(json),
      'AudioPreviewPlaybackTrait' => AudioPreviewPlaybackTrait.fromJson(json),
      'PreviewPlaybackTrait' => PreviewPlaybackTrait.fromJson(json),
      'VideoCardTrait' => VideoCardTrait.fromJson(json),
      'VisualIdentityTrait' => VisualIdentityTrait.fromJson(json),
      _ => null,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════
// Visual traits (rendered as cards)
// ═══════════════════════════════════════════════════════════════════

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

class IdentityTrait extends Trait {
  final String title;
  const IdentityTrait({required this.title});

  @override
  Map<String, dynamic> toJson() => {'title': title};

  factory IdentityTrait.fromJson(Map<String, dynamic> json) => IdentityTrait(
    title: json['title'] ?? '',
  );
}

class PreviewCardTrait extends Trait {
  final String title;
  final String contentTypeName;
  final String description;
  final String? imageUrl;
  final String? backgroundColor;
  final String? waveformColor;
  final int trackCount;
  final String? entityUri;
  final String? navigateUri;
  final List<String> tags;
  final String previewLabel;
  final String playingLabel;
  final String creatorName;
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

class ShortcutsCardTrait extends Trait {
  final String title;
  final String? imageUrl;

  const ShortcutsCardTrait({required this.title, this.imageUrl});

  @override
  Map<String, dynamic> toJson() => {'title': title, 'imageUrl': imageUrl};

  factory ShortcutsCardTrait.fromJson(Map<String, dynamic> json) => ShortcutsCardTrait(
    title: json['title'] ?? '',
    imageUrl: json['imageUrl'],
  );
}

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
    'title': title, 'subtitle': subtitle, 'imageUrl': imageUrl,
    'extractedColor': extractedColor, 'badge': badge,
  };

  factory FallbackMetadataTrait.fromJson(Map<String, dynamic> json) => FallbackMetadataTrait(
    title: json['title'] ?? '',
    subtitle: json['subtitle'] ?? '',
    imageUrl: json['imageUrl'],
    extractedColor: json['extractedColor'],
    badge: json['badge'],
  );
}

// ═══════════════════════════════════════════════════════════════════
// Context-specific metadata traits
// ═══════════════════════════════════════════════════════════════════

class RecentsMetadataTrait extends Trait {
  final int songsCount;
  final String recentType;
  final String contentCategory;
  final String groupName;
  final int timestamp;

  const RecentsMetadataTrait({
    this.songsCount = 0,
    this.recentType = 'played',
    this.contentCategory = '',
    this.groupName = '',
    this.timestamp = 0,
  });

  @override
  Map<String, dynamic> toJson() => {
    'songsCount': songsCount, 'recentType': recentType,
    'contentCategory': contentCategory, 'groupName': groupName,
    'timestamp': timestamp,
  };

  factory RecentsMetadataTrait.fromJson(Map<String, dynamic> json) => RecentsMetadataTrait(
    songsCount: json['songsCount'] ?? 0,
    recentType: json['recentType'] ?? 'played',
    contentCategory: json['contentCategory'] ?? '',
    groupName: json['groupName'] ?? '',
    timestamp: json['timestamp'] ?? 0,
  );
}

// ═══════════════════════════════════════════════════════════════════
// Playback traits (for inline preview playback)
// ═══════════════════════════════════════════════════════════════════

/// Audio preview playback data (ExtensionKind 116).
/// Provides audio file URL, duration, and preview metadata for
/// sections like AudioSpotlight, AudioPromo, and ImmersivePreview.
class AudioPreviewPlaybackTrait extends Trait {
  final String audioFileUrl;
  final String transcriptUrl;
  final String videoFileId;
  final String videoPlaceholderImageUrl;
  final int previewDurationMs;
  final int durationFromOriginalMs;
  final String previewStreamReportingUri;
  final int previewRestriction;

  const AudioPreviewPlaybackTrait({
    this.audioFileUrl = '',
    this.transcriptUrl = '',
    this.videoFileId = '',
    this.videoPlaceholderImageUrl = '',
    this.previewDurationMs = 0,
    this.durationFromOriginalMs = 0,
    this.previewStreamReportingUri = '',
    this.previewRestriction = 0,
  });

  @override
  Map<String, dynamic> toJson() => {
    'audioFileUrl': audioFileUrl,
    'transcriptUrl': transcriptUrl,
    'videoFileId': videoFileId,
    'videoPlaceholderImageUrl': videoPlaceholderImageUrl,
    'previewDurationMs': previewDurationMs,
    'durationFromOriginalMs': durationFromOriginalMs,
    'previewStreamReportingUri': previewStreamReportingUri,
    'previewRestriction': previewRestriction,
  };

  factory AudioPreviewPlaybackTrait.fromJson(Map<String, dynamic> json) =>
      AudioPreviewPlaybackTrait(
        audioFileUrl: json['audioFileUrl'] ?? '',
        transcriptUrl: json['transcriptUrl'] ?? '',
        videoFileId: json['videoFileId'] ?? '',
        videoPlaceholderImageUrl: json['videoPlaceholderImageUrl'] ?? '',
        previewDurationMs: json['previewDurationMs'] ?? 0,
        durationFromOriginalMs: json['durationFromOriginalMs'] ?? 0,
        previewStreamReportingUri: json['previewStreamReportingUri'] ?? '',
        previewRestriction: json['previewRestriction'] ?? 0,
      );
}

/// Content-agnostic preview playback (ExtensionKind 181).
/// Can hold either an audio or video preview.
class PreviewPlaybackTrait extends Trait {
  final String uri;
  final String reportingUri;
  final String audioUrl;
  final String videoUrl;
  final String videoImageUrl;
  final int durationMs;

  const PreviewPlaybackTrait({
    this.uri = '',
    this.reportingUri = '',
    this.audioUrl = '',
    this.videoUrl = '',
    this.videoImageUrl = '',
    this.durationMs = 0,
  });

  bool get hasAudio => audioUrl.isNotEmpty;
  bool get hasVideo => videoUrl.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
    'uri': uri, 'reportingUri': reportingUri,
    'audioUrl': audioUrl, 'videoUrl': videoUrl,
    'videoImageUrl': videoImageUrl, 'durationMs': durationMs,
  };

  factory PreviewPlaybackTrait.fromJson(Map<String, dynamic> json) =>
      PreviewPlaybackTrait(
        uri: json['uri'] ?? '',
        reportingUri: json['reportingUri'] ?? '',
        audioUrl: json['audioUrl'] ?? '',
        videoUrl: json['videoUrl'] ?? '',
        videoImageUrl: json['videoImageUrl'] ?? '',
        durationMs: json['durationMs'] ?? 0,
      );
}

/// Video card metadata for video podcasts and watch feed items.
/// Carries the 16:9 video thumbnail, square show artwork, and duration badge.
class VideoCardTrait extends Trait {
  final String title;
  final String subtitle;
  final String? videoThumbnailUrl;
  final String? showArtworkUrl;
  final String durationString;
  final String overline;
  final bool isPlaying;

  const VideoCardTrait({
    required this.title,
    this.subtitle = '',
    this.videoThumbnailUrl,
    this.showArtworkUrl,
    this.durationString = '',
    this.overline = '',
    this.isPlaying = false,
  });

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'videoThumbnailUrl': videoThumbnailUrl,
    'showArtworkUrl': showArtworkUrl,
    'durationString': durationString,
    'overline': overline,
    'isPlaying': isPlaying,
  };

  factory VideoCardTrait.fromJson(Map<String, dynamic> json) => VideoCardTrait(
    title: json['title'] ?? '',
    subtitle: json['subtitle'] ?? '',
    videoThumbnailUrl: json['videoThumbnailUrl'],
    showArtworkUrl: json['showArtworkUrl'],
    durationString: json['durationString'] ?? '',
    overline: json['overline'] ?? '',
    isPlaying: json['isPlaying'] ?? false,
  );
}

/// Visual identity metadata (ExtensionKind 179).
/// Carries square cover art, 16:9 video cover art, full-bleed images,
/// and Spotify curated color palette (background and text colors).
class VisualIdentityTrait extends Trait {
  final String? squareCoverUrl;
  final String? sixteenByNineCoverUrl;
  final String? wideFullBleedUrl;
  final String? squareFullBleedUrl;
  final String? videoNineBySixteenUrl;
  final bool hasVideo;
  final String? backgroundColorHex;
  final String? textColorHex;
  final String? textSubduedColorHex;

  const VisualIdentityTrait({
    this.squareCoverUrl,
    this.sixteenByNineCoverUrl,
    this.wideFullBleedUrl,
    this.squareFullBleedUrl,
    this.videoNineBySixteenUrl,
    this.hasVideo = false,
    this.backgroundColorHex,
    this.textColorHex,
    this.textSubduedColorHex,
  });

  @override
  Map<String, dynamic> toJson() => {
    'squareCoverUrl': squareCoverUrl,
    'sixteenByNineCoverUrl': sixteenByNineCoverUrl,
    'wideFullBleedUrl': wideFullBleedUrl,
    'squareFullBleedUrl': squareFullBleedUrl,
    'videoNineBySixteenUrl': videoNineBySixteenUrl,
    'hasVideo': hasVideo,
    'backgroundColorHex': backgroundColorHex,
    'textColorHex': textColorHex,
    'textSubduedColorHex': textSubduedColorHex,
  };

  factory VisualIdentityTrait.fromJson(Map<String, dynamic> json) => VisualIdentityTrait(
    squareCoverUrl: json['squareCoverUrl'],
    sixteenByNineCoverUrl: json['sixteenByNineCoverUrl'],
    wideFullBleedUrl: json['wideFullBleedUrl'],
    squareFullBleedUrl: json['squareFullBleedUrl'],
    videoNineBySixteenUrl: json['videoNineBySixteenUrl'],
    hasVideo: json['hasVideo'] ?? false,
    backgroundColorHex: json['backgroundColorHex'],
    textColorHex: json['textColorHex'],
    textSubduedColorHex: json['textSubduedColorHex'],
  );
}
