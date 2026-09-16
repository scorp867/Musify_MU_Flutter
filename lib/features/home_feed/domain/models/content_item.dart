/// Universal content item — used for cards in lists everywhere.
///
/// Whether it's a playlist, album, artist, or podcast episode,
/// the card shows: image + title + subtitle. The [type] field
/// tells the UI how to render it (circle for artists, square for albums, etc).
class ContentItem {
  final String uri;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final ContentType type;
  final String? extractedColor;
  /// Status badge — e.g. "2 songs added", "Finished".
  final String? badge;

  const ContentItem({
    required this.uri,
    required this.title,
    this.subtitle = '',
    this.imageUrl,
    this.type = ContentType.unknown,
    this.extractedColor,
    this.badge,
  });

  ContentItem copyWith({
    String? uri,
    String? title,
    String? subtitle,
    String? imageUrl,
    ContentType? type,
    String? extractedColor,
    String? badge,
  }) {
    return ContentItem(
      uri: uri ?? this.uri,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      extractedColor: extractedColor ?? this.extractedColor,
      badge: badge ?? this.badge,
    );
  }

  @override
  String toString() => 'ContentItem($type: $title)';
}

enum ContentType {
  album,
  playlist,
  artist,
  track,
  episode,
  podcast,
  unknown;

  /// Infer type from a Spotify URI like "spotify:album:xxxxx".
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
