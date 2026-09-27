/// A single item in the user's library (playlist, artist, show, album).
class LibraryItem {
  final String uri;
  final String type;
  final String name;
  final String? imageUrl;
  final String? ownerName;
  final DateTime? addedAt;
  final bool isPinned;
  final int? trackCount;

  /// First 4 unique album art URLs for client-side mosaic rendering.
  /// Non-empty only for playlists without a custom cover.
  final List<String> mosaicImageUrls;

  const LibraryItem({
    required this.uri,
    required this.type,
    required this.name,
    this.imageUrl,
    this.ownerName,
    this.addedAt,
    this.isPinned = false,
    this.trackCount,
    this.mosaicImageUrls = const [],
  });

  /// Creates a copy with updated fields.
  LibraryItem copyWith({
    String? name,
    String? imageUrl,
    String? ownerName,
    bool? isPinned,
    int? trackCount,
    List<String>? mosaicImageUrls,
  }) {
    return LibraryItem(
      uri: uri,
      type: type,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerName: ownerName ?? this.ownerName,
      addedAt: addedAt,
      isPinned: isPinned ?? this.isPinned,
      trackCount: trackCount ?? this.trackCount,
      mosaicImageUrls: mosaicImageUrls ?? this.mosaicImageUrls,
    );
  }
}

/// Aggregated library data ready for the UI.
class LibraryViewData {
  final List<LibraryItem> items;
  final Set<String> pinnedUris;

  const LibraryViewData({
    required this.items,
    this.pinnedUris = const {},
  });

  /// Items filtered by type.
  List<LibraryItem> filterByType(String type) {
    return items.where((item) => item.type == type).toList();
  }

  /// Items sorted by recency (added_at descending), with pinned items first.
  List<LibraryItem> sortedByRecents() {
    final sorted = List<LibraryItem>.from(items);
    sorted.sort((a, b) {
      // Pinned items first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      // Then by added_at descending
      final aTime = a.addedAt ?? DateTime(1970);
      final bTime = b.addedAt ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
    return sorted;
  }
}
