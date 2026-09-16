class DomainTrack {
  final String
  id; // Use string to support both integer Local DB IDs and String Online API IDs
  final String title;
  final String artist;
  final String? album;
  final int? duration;
  final String? dataPath; // The local file path or the online stream URL
  final int? songId; // Original Android MediaStore ID (for artwork)
  final String? artUri; // Online image URL if available
  final DateTime? dateModified;
  final bool isLocal; // Flag to identify the source

  DomainTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.dataPath,
    this.songId,
    this.artUri,
    this.dateModified,
    this.isLocal = true,
  });

  // Optional: equality override for Bloc diffing
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DomainTrack &&
        other.id == id &&
        other.title == title &&
        other.artist == artist &&
        other.album == album &&
        other.duration == duration &&
        other.dateModified == dateModified;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        artist.hashCode ^
        album.hashCode ^
        duration.hashCode ^
        dateModified.hashCode;
  }
}
