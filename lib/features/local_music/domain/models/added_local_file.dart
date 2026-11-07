import 'package:flutter/foundation.dart';

/// 1:1 Spotify `com.spotify.localfiles.localfilesmonorepo.AddedLocalFile`.
@immutable
final class AddedLocalFile {
  final int duration;
  final String albumName;
  final String artistName;
  final String trackTitle;
  final String localTrackUri;

  const AddedLocalFile({
    required this.duration,
    required this.albumName,
    required this.artistName,
    required this.trackTitle,
    required this.localTrackUri,
  });

  AddedLocalFile copy({
    int? duration,
    String? albumName,
    String? artistName,
    String? trackTitle,
    String? localTrackUri,
  }) {
    return AddedLocalFile(
      duration: switch (duration) {
        final d? => d,
        null => this.duration,
      },
      albumName: switch (albumName) {
        final a? => a,
        null => this.albumName,
      },
      artistName: switch (artistName) {
        final a? => a,
        null => this.artistName,
      },
      trackTitle: switch (trackTitle) {
        final t? => t,
        null => this.trackTitle,
      },
      localTrackUri: switch (localTrackUri) {
        final u? => u,
        null => this.localTrackUri,
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AddedLocalFile &&
          other.duration == duration &&
          other.albumName == albumName &&
          other.artistName == artistName &&
          other.trackTitle == trackTitle &&
          other.localTrackUri == localTrackUri);

  @override
  int get hashCode => Object.hash(
    duration,
    albumName,
    artistName,
    trackTitle,
    localTrackUri,
  );
}
