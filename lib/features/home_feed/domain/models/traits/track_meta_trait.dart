import 'trait.dart';

/// Metadata for tracks and episodes (ExtensionKind 10 TRACK_V4, ExtensionKind 12 EPISODE_V4).
class TrackMetaTrait extends Trait {
  final String uri;
  final String title;
  final String subtitle;
  final String albumName;
  final Map<String, String> imageUrls;
  final String? largeImageHex;
  final int durationMs;
  final String fileId;
  final String aacFileId;
  final String headUrl;
  final String canonicalUri;

  String get imageXlargeUrl {
    if (imageUrls['xlarge'] case final url? when url.isNotEmpty) {
      return url;
    }
    if (imageUrls['large'] case final url? when url.isNotEmpty) {
      return url;
    }
    return imageUrl;
  }

  String get imageLargeUrl {
    if (imageUrls['large'] case final url? when url.isNotEmpty) {
      return url;
    }
    if (imageUrls['xlarge'] case final url? when url.isNotEmpty) {
      return url;
    }
    return imageUrl;
  }

  String get imageSmallUrl {
    if (imageUrls['small'] case final url? when url.isNotEmpty) {
      return url;
    }
    if (imageUrls['default'] case final url? when url.isNotEmpty) {
      return url;
    }
    if (imageUrls['medium'] case final url? when url.isNotEmpty) {
      return url;
    }
    return imageLargeUrl;
  }

  String get thumbnailImageUrl => imageSmallUrl;

  String get imageUrl {
    if (imageUrls['default'] case final url? when url.isNotEmpty) {
      return url;
    }
    if (imageUrls['medium'] case final url? when url.isNotEmpty) {
      return url;
    }
    if (imageUrls['large'] case final url? when url.isNotEmpty) {
      return url;
    }
    if (imageUrls['xlarge'] case final url? when url.isNotEmpty) {
      return url;
    }
    if (imageUrls['small'] case final url? when url.isNotEmpty) {
      return url;
    }
    return '';
  }

  const TrackMetaTrait({
    required this.uri,
    this.title = '',
    this.subtitle = '',
    this.albumName = '',
    this.imageUrls = const {},
    this.largeImageHex,
    this.durationMs = 0,
    this.fileId = '',
    this.aacFileId = '',
    this.headUrl = '',
    this.canonicalUri = '',
  });

  @override
  Map<String, dynamic> toJson() => {
    'uri': uri,
    'title': title,
    'subtitle': subtitle,
    'albumName': albumName,
    'imageUrls': imageUrls,
    if (largeImageHex != null) 'largeImageHex': largeImageHex,
    'durationMs': durationMs,
    if (fileId.isNotEmpty) 'fileId': fileId,
    if (aacFileId.isNotEmpty) 'aacFileId': aacFileId,
    if (headUrl.isNotEmpty) 'headUrl': headUrl,
    if (canonicalUri.isNotEmpty) 'canonicalUri': canonicalUri,
  };

  factory TrackMetaTrait.fromJson(Map<String, dynamic> json) => TrackMetaTrait(
    uri: switch (json['uri']) {
      final String u => u,
      _ => '',
    },
    title: switch (json['title']) {
      final String t => t,
      _ => '',
    },
    subtitle: switch (json['subtitle']) {
      final String s => s,
      _ => '',
    },
    albumName: switch (json['albumName']) {
      final String a => a,
      _ => '',
    },
    imageUrls: switch (json['imageUrls']) {
      final Map<dynamic, dynamic> m => Map<String, String>.from(m),
      _ => const {},
    },
    largeImageHex: switch (json['largeImageHex']) {
      final String hex => hex,
      _ => null,
    },
    durationMs: switch (json['durationMs']) {
      final int d => d,
      _ => 0,
    },
    fileId: switch (json['fileId']) {
      final String fid => fid,
      _ => '',
    },
    aacFileId: switch (json['aacFileId']) {
      final String aac => aac,
      _ => '',
    },
    headUrl: switch (json['headUrl']) {
      final String h => h,
      _ => '',
    },
    canonicalUri: switch (json['canonicalUri']) {
      final String c => c,
      _ => '',
    },
  );
}
