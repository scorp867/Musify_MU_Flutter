import 'package:musify_mu/core/navigation/spotify_uri_navigator.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_header_type.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_metadata.dart';

/// Curation and header-resolution policies extracted from `PlaylistMetadata`
/// (`ItemCurationStatePolicy.java` / `q2n.java` / `pu40.java`).
extension PlaylistCurationPolicy on PlaylistMetadata {
  bool get isEditorial {
    if (SpotifyUriNavigator.isLikedSongsUri(uri)) {
      return false;
    }
    final owner = ownerUsername.toLowerCase();
    final nameLower = ownerName.toLowerCase();
    return owner == 'spotify' ||
        nameLower == 'spotify' ||
        uri.contains(':spotify:playlist:') ||
        customAttributes['is_curated'] == 'true' ||
        customAttributes['format'] == 'editorial';
  }

  bool get isUserOwned => canEdit || canDelete;

  PlaylistHeaderType get headerType {
    if (isEditorial) return PlaylistHeaderType.editorial;
    if (isUserOwned) return PlaylistHeaderType.userOwned;
    return PlaylistHeaderType.followed;
  }
}
