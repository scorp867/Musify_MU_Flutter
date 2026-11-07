import 'package:musify_mu/features/home_feed/domain/models/traits/image_size.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_item.dart';
import 'package:musify_mu/features/playlist/domain/models/track_item_metadata.dart';

/// Presentation formatting helpers extracted from `TrackItemMetadata`.
extension TrackItemMetadataPresentation on TrackItemMetadata {
  String get artistNamesString => artists.isNotEmpty
      ? artists.join(', ')
      : (showName.isNotEmpty ? showName : albumName);

  String get primaryCoverUrl => coverUrlForSize(ImageSize.large);

  String get highResCoverUrl => coverUrlForSize(ImageSize.xlarge);

  String get thumbnailCoverUrl => coverUrlForSize(ImageSize.small);
}

/// Presentation convenience getters extracted from `PlaylistItem`.
extension PlaylistItemPresentation on PlaylistItem {
  String get title => trackMetadata?.title ?? '';

  String get subtitle => trackMetadata?.artistNamesString ?? '';

  String get albumName => trackMetadata?.albumName ?? '';

  String get showName {
    if (trackMetadata case final meta? when meta.showName.isNotEmpty) {
      return meta.showName;
    }
    return albumName;
  }

  String get coverUrl => coverUrlForSize(ImageSize.xlarge);

  String get imageXlargeUrl => coverUrlForSize(ImageSize.xlarge);

  String get imageLargeUrl => coverUrlForSize(ImageSize.large);

  String get imageUrl => coverUrlForSize(ImageSize.normal);

  String get imageSmallUrl => coverUrlForSize(ImageSize.small);

  String get thumbnailUrl => coverUrlForSize(ImageSize.small);

  int get durationMs => trackMetadata?.durationMs ?? 0;

  bool get isExplicit => trackMetadata?.isExplicit ?? false;

  String get description => trackMetadata?.description ?? '';

  String get publishDate => trackMetadata?.publishDate ?? '';

  int get playbackPositionMs => trackMetadata?.playbackPositionMs ?? 0;
}
