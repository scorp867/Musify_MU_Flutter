library;

/// Enum representing Spotify's ProvidedSortOrder for playlists.
/// Matches 1:1 with Spotify's `spotify.playlist.esperanto.proto.ProvidedSortOrder`.
enum ProvidedSortOrder {
  custom(id: 'CUSTOM', displayName: 'Custom order'),
  title(id: 'TITLE', displayName: 'Title'),
  artist(id: 'ARTIST', displayName: 'Artist'),
  album(id: 'ALBUM', displayName: 'Album'),
  dateAdded(id: 'ADDED', displayName: 'Recently added');

  final String id;
  final String displayName;

  const ProvidedSortOrder({
    required this.id,
    required this.displayName,
  });

  static ProvidedSortOrder fromId(String id) {
    for (final order in ProvidedSortOrder.values) {
      if (order.id == id) {
        return order;
      }
    }
    return ProvidedSortOrder.custom;
  }
}
