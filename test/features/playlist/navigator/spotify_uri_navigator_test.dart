import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/navigation/spotify_uri_navigator.dart';

void main() {
  group('SpotifyUriNavigator URI Filtering Tests', () {
    test('isPlaylistUri correctly identifies playlist URI schemes and rejects non-playlists', () {
      // Valid playlist URIs
      expect(SpotifyUriNavigator.isPlaylistUri('spotify:playlist:37i9dQZF1DXcBWIGoYBM5M'), isTrue);
      expect(SpotifyUriNavigator.isPlaylistUri('spotify:user:spotify:playlist:37i9dQZF1DXcBWIGoYBM5M'), isTrue);
      expect(SpotifyUriNavigator.isPlaylistUri('https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M'), isTrue);

      // Liked songs / Collection playlist URIs (1:1 replica of Spotify d8l1.m37036x and veb0.java)
      expect(SpotifyUriNavigator.isPlaylistUri('spotify:playlist:37i9dQZF1F5p3rmiWPIYgZ'), isTrue);
      expect(SpotifyUriNavigator.isPlaylistUri('spotify:collection:tracks'), isTrue);
      expect(SpotifyUriNavigator.isPlaylistUri('spotify:internal:collection:tracks'), isTrue);
      expect(SpotifyUriNavigator.isPlaylistUri('spotify:user:user123:collection'), isTrue);

      // Non-playlist URIs reserved for future screens
      expect(SpotifyUriNavigator.isPlaylistUri('spotify:track:4cOdK2wGLETKBW3PvgPWqT'), isFalse);
      expect(SpotifyUriNavigator.isPlaylistUri('spotify:album:1DFixLWuPkv3KT3TnV35m3'), isFalse);
      expect(SpotifyUriNavigator.isPlaylistUri('spotify:artist:06HL4z0CvFAxyc27GXpf02'), isFalse);
      expect(SpotifyUriNavigator.isPlaylistUri('spotify:show:5CfCWKI5pZ28v0uOzXgTe8'), isFalse);
      expect(SpotifyUriNavigator.isPlaylistUri(''), isFalse);
    });

    test('isLikedSongsUri matches Spotify d8l1.m37036x canonical collection formats', () {
      // Canonical Liked Songs URIs
      expect(SpotifyUriNavigator.isLikedSongsUri('spotify:playlist:37i9dQZF1F5p3rmiWPIYgZ'), isTrue);
      expect(SpotifyUriNavigator.isLikedSongsUri('spotify:collection:tracks'), isTrue);
      expect(SpotifyUriNavigator.isLikedSongsUri('spotify:internal:collection:tracks'), isTrue);
      expect(SpotifyUriNavigator.isLikedSongsUri('spotify:user:spotify_user:collection'), isTrue);

      // Non-collection URIs
      expect(SpotifyUriNavigator.isLikedSongsUri('spotify:playlist:37i9dQZF1DXcBWIGoYBM5M'), isFalse);
      expect(SpotifyUriNavigator.isLikedSongsUri('spotify:user:spotify:playlist:37i9dQZF1DXcBWIGoYBM5M'), isFalse);
      expect(SpotifyUriNavigator.isLikedSongsUri('spotify:album:1DFixLWuPkv3KT3TnV35m3'), isFalse);
      expect(SpotifyUriNavigator.isLikedSongsUri('spotify:track:4cOdK2wGLETKBW3PvgPWqT'), isFalse);
      expect(SpotifyUriNavigator.isLikedSongsUri('spotify:user:spotify_user'), isFalse);
      expect(SpotifyUriNavigator.isLikedSongsUri(''), isFalse);
    });
  });
}
