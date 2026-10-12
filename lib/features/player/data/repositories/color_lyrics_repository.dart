import 'dart:ui';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/features/player/data/datasources/color_lyrics_client.dart';
import 'package:musify_mu/features/player/domain/repositories/lyrics_repository.dart';

/// Concrete repository implementation for Spotify Color Lyrics.
///
/// Fetches, caches, and parses lyrics responses from Spotify's
/// `color-lyrics/v2/track/{trackId}` endpoint.
class ColorLyricsRepositoryImpl implements LyricsRepository {
  final ColorLyricsClient _client;
  final Map<String, ColorLyricsResponse> _cache = {};

  ColorLyricsRepositoryImpl({required ColorLyricsClient client}) : _client = client;

  @override

  /// Fetches lyrics with colors for the given Spotify track ID.
  Future<ColorLyricsResponse?> getLyrics(String trackId) async {
    final cleanId = _sanitizeTrackId(trackId);
    if (cleanId.isEmpty) return null;

    if (_cache.containsKey(cleanId)) {
      return _cache[cleanId];
    }

    final response = await _client.getColorLyrics(trackId: cleanId);
    if (response != null) {
      _cache[cleanId] = response;
    }
    return response;
  }

  /// Converts signed 32-bit protobuf color integer into a Flutter [Color].
  static Color parseProtoColor(int rawValue, {Color defaultColor = const Color(0xFF242424)}) {
    if (rawValue == 0) return defaultColor;
    // Protobuf stores as signed 32-bit (e.g. -8686235 for 0xFF7B7565)
    final argb = rawValue & 0xFFFFFFFF;
    // If alpha channel is 0, default to opaque 0xFF
    final fullArgb = (argb & 0xFF000000) == 0 ? (0xFF000000 | argb) : argb;
    return Color(fullArgb);
  }

  String _sanitizeTrackId(String input) {
    if (input.startsWith('spotify:track:')) {
      return input.replaceFirst('spotify:track:', '');
    }
    return input;
  }

  void clearCache() {
    _cache.clear();
  }
}
