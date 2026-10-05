import 'package:equatable/equatable.dart';

/// A single item in the user's library (playlist, artist, show, album).
class LibraryItem extends Equatable {
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

  @override
  List<Object?> get props => [
        uri,
        type,
        name,
        imageUrl,
        ownerName,
        addedAt,
        isPinned,
        trackCount,
        mosaicImageUrls,
      ];

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
