import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';

/// Domain repository contract for Spotify Color Lyrics.
abstract interface class LyricsRepository {
  /// Fetches lyrics and color metadata for the given track identifier.
  Future<ColorLyricsResponse?> getLyrics(String trackId);
}
