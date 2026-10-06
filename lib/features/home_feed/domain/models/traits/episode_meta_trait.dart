import 'track_meta_trait.dart';

/// ExtensionKind 12 (EPISODE_V4).
class EpisodeMetaTrait extends TrackMetaTrait {
  const EpisodeMetaTrait({
    required super.uri,
    super.title,
    super.subtitle,
    super.albumName,
    super.imageUrls,
    super.largeImageHex,
    super.durationMs,
  });

  factory EpisodeMetaTrait.fromJson(Map<String, dynamic> json) {
    final meta = TrackMetaTrait.fromJson(json);
    return EpisodeMetaTrait(
      uri: meta.uri,
      title: meta.title,
      subtitle: meta.subtitle,
      albumName: meta.albumName,
      imageUrls: meta.imageUrls,
      largeImageHex: meta.largeImageHex,
      durationMs: meta.durationMs,
    );
  }
}
