import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'spotify_audio_format.dart';

/// 1:1 replica of Spotify's internal audio file domain model (`p199p/eey.java` / `p/bou.java`).
///
/// Holds the 40-character lowercase hexadecimal file identifier and its associated audio format.
@immutable
final class SpotifyAudioFile extends Equatable {
  /// The 40-character lowercase hexadecimal SHA-1 file identifier.
  final String fileIdHex;

  /// The audio format and bitrate category.
  final SpotifyAudioFormat format;

  const SpotifyAudioFile({
    required this.fileIdHex,
    required this.format,
  });

  /// The official Spotify CDN endpoint for fetching the 128 KiB chunk 0 head file.
  String get headUrl => 'https://heads-fa-tls13.spotifycdn.com/head/$fileIdHex';

  @override
  List<Object?> get props => <Object?>[fileIdHex, format];

  @override
  String toString() => 'SpotifyAudioFile(fileIdHex: $fileIdHex, format: ${format.name})';
}
