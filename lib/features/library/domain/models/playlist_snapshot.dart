/// Parsed playlist data from a full fetch or diff application.
///
/// This is an intermediate domain model used during sync.
/// The library UI reads from [PlaylistDetailCache], not this type directly.
class PlaylistSnapshot {
  final String playlistId;
  final String revision;
  final String name;
  final String? description;
  final String ownerUsername;
  final int trackCount;
  final List<String> trackUris;
  final String? coverUrl;

  const PlaylistSnapshot({
    required this.playlistId,
    required this.revision,
    required this.name,
    this.description,
    required this.ownerUsername,
    required this.trackCount,
    required this.trackUris,
    this.coverUrl,
  });
}
