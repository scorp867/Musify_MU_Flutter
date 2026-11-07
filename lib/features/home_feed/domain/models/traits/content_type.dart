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
