/// Result of cover resolution for a playlist.
class CoverResolution {
  final String? coverUrl;
  final bool isCustomCover;
  final List<String> mosaicImageUrls;

  const CoverResolution({
    this.coverUrl,
    this.isCustomCover = false,
    this.mosaicImageUrls = const [],
  });
}

/// What the diff did to the cover (if anything).
sealed class DiffCoverChange {
  const DiffCoverChange();
}

/// Diff explicitly set a new custom cover URL.
class CoverSet extends DiffCoverChange {
  final String url;
  const CoverSet(this.url);
}

/// Diff explicitly removed the custom cover (no_value contained LIST_PICTURE).
class CoverRemoved extends DiffCoverChange {
  const CoverRemoved();
}

/// Determines playlist cover from diff changes and cached state.
/// Pure logic, zero external dependencies.
class CoverResolver {
  const CoverResolver._();

  /// Given the previous cover state and diff changes, determines
  /// whether to keep the custom cover or resolve from tracks.
  ///
  /// Matching Spotify Android:
  /// - If the playlist has >= 4 unique album artworks, builds a 2x2 mosaic.
  /// - If the playlist has 1..3 unique artworks, takes the first track's
  ///   album art as a single cover (mosaic is not generated).
  /// - If the playlist has 0 tracks, cover is null (shows placeholder).
  static CoverResolution resolve({
    required bool wasCustomCover,
    required String? cachedCoverUrl,
    required DiffCoverChange? coverChange,
    required List<String> mosaicUrls,
  }) {
    if (coverChange is CoverSet) {
      return CoverResolution(
        coverUrl: coverChange.url,
        isCustomCover: true,
      );
    }

    if (coverChange is CoverRemoved) {
      return _buildCover(mosaicUrls);
    }

    if (wasCustomCover) {
      return CoverResolution(
        coverUrl: cachedCoverUrl,
        isCustomCover: true,
      );
    }

    return _buildCover(mosaicUrls);
  }

  /// Full-fetch cover resolution: checks if the response has a custom
  /// cover, otherwise builds mosaic (>= 4) or single cover (< 4) from tracks.
  static CoverResolution resolveFromFull({
    required String? customCoverUrl,
    required List<String> mosaicUrls,
  }) {
    if (customCoverUrl != null && customCoverUrl.isNotEmpty) {
      return CoverResolution(
        coverUrl: customCoverUrl,
        isCustomCover: true,
      );
    }

    return _buildCover(mosaicUrls);
  }

  static CoverResolution _buildCover(List<String> urls) {
    if (urls.length >= 4) {
      return CoverResolution(
        coverUrl: urls.first,
        isCustomCover: false,
        mosaicImageUrls: urls.take(4).toList(),
      );
    }

    // When fewer than 4 unique artworks are present, Spotify uses the
    // first track's album art as a single cover rather than a mosaic.
    return CoverResolution(
      coverUrl: urls.isNotEmpty ? urls.first : null,
      isCustomCover: false,
      mosaicImageUrls: const [],
    );
  }
}
