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

  String get imageUrl =>
      imageUrls['large'] ??
      imageUrls['medium'] ??
      imageUrls['small'] ??
      '';

  const TrackMetaTrait({
    required this.uri,
    this.title = '',
    this.subtitle = '',
    this.albumName = '',
    this.imageUrls = const {},
    this.largeImageHex,
    this.durationMs = 0,
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
  };

  factory TrackMetaTrait.fromJson(Map<String, dynamic> json) => TrackMetaTrait(
    uri: json['uri'] ?? '',
    title: json['title'] ?? '',
    subtitle: json['subtitle'] ?? '',
    albumName: json['albumName'] ?? '',
    imageUrls: Map<String, String>.from(json['imageUrls'] ?? const {}),
    largeImageHex: json['largeImageHex'],
    durationMs: json['durationMs'] ?? 0,
  );
}
