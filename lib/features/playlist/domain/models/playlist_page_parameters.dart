library;

import 'package:flutter/foundation.dart';

/// 1:1 replica of Spotify's `bts0.java` and `un3.java` page parameters.
@immutable
class PlaylistPageParameters {
  final String playlistUri;
  final bool canEdit;
  final bool isCurated;
  final bool overrideSort;

  const PlaylistPageParameters({
    required this.playlistUri,
    this.canEdit = false,
    this.isCurated = false,
    this.overrideSort = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistPageParameters &&
          runtimeType == other.runtimeType &&
          playlistUri == other.playlistUri &&
          canEdit == other.canEdit &&
          isCurated == other.isCurated &&
          overrideSort == other.overrideSort);

  @override
  int get hashCode => Object.hash(
        playlistUri,
        canEdit,
        isCurated,
        overrideSort,
      );

  @override
  String toString() =>
      'PlaylistPageParameters(uri: $playlistUri, canEdit: $canEdit, isCurated: $isCurated)';
}
