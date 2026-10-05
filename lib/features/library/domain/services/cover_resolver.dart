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
  /// whether to keep the custom cover, regenerate the mosaic, or
  /// apply a new custom cover from the diff.
  ///
  /// [mosaicUrlsBuilder] is called lazily only when mosaic regeneration
  /// is needed (avoids unnecessary metadata lookups).
  static CoverResolution resolve({
    required bool wasCustomCover,
    required String? cachedCoverUrl,
    required DiffCoverChange? coverChange,
    required List<String> Function() mosaicUrlsBuilder,
  }) {
    if (coverChange is CoverSet) {
      return CoverResolution(
        coverUrl: coverChange.url,
        isCustomCover: true,
      );
    }

    if (coverChange is CoverRemoved) {
      return _buildMosaic(mosaicUrlsBuilder);
    }

    if (wasCustomCover) {
      return CoverResolution(
        coverUrl: cachedCoverUrl,
        isCustomCover: true,
      );
    }

    return _buildMosaic(mosaicUrlsBuilder);
  }

  /// Full-fetch cover resolution: checks if the response has a custom
  /// cover, otherwise builds mosaic from tracks.
  static CoverResolution resolveFromFull({
    required String? customCoverUrl,
    required List<String> Function() mosaicUrlsBuilder,
  }) {
    if (customCoverUrl != null && customCoverUrl.isNotEmpty) {
      return CoverResolution(
        coverUrl: customCoverUrl,
        isCustomCover: true,
      );
    }

    return _buildMosaic(mosaicUrlsBuilder);
  }

  static CoverResolution _buildMosaic(List<String> Function() builder) {
    final mosaicUrls = builder();
    final mosaicList = mosaicUrls.length >= 4 ? mosaicUrls : const <String>[];

    return CoverResolution(
      coverUrl: mosaicUrls.isNotEmpty ? mosaicUrls.first : null,
      isCustomCover: false,
      mosaicImageUrls: mosaicList,
    );
  }
}
