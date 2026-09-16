import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';
import 'package:musify_mu/features/local_music/domain/entities/domain_track.dart';

/// Keeps the active media item in sync with local-library metadata changes.
///
/// Library updates can arrive in bursts while a media scanner is writing
/// metadata. Updates are serialized so artwork queries never overlap.
class LocalMusicPlaybackSynchronizer {
  final PlaybackController _playbackController;
  Future<void> _pendingUpdate = Future<void>.value();

  LocalMusicPlaybackSynchronizer(this._playbackController);

  Future<void> synchronize(List<DomainTrack> tracks) {
    _pendingUpdate = _pendingUpdate.then((_) async {
      try {
        await _synchronizeCurrentTrack(tracks);
      } catch (error) {
        debugPrint('Unable to synchronize active media metadata: $error');
      }
    });
    return _pendingUpdate;
  }

  Future<void> _synchronizeCurrentTrack(List<DomainTrack> tracks) async {
    final currentItem = _playbackController.currentMediaItem;
    if (currentItem == null) return;

    final track = tracks.where((candidate) => candidate.id == currentItem.id);
    if (track.isEmpty) return;

    final updatedItem = MediaItemMapper.fromTrack(
      id: track.first.id,
      title: track.first.title,
      artist: track.first.artist,
      album: track.first.album,
      durationMilliseconds: track.first.duration,
      songId: track.first.songId,
      dataPath: track.first.dataPath,
      dateModified: track.first.dateModified,
    );

    if (!_hasMetadataChanged(currentItem, updatedItem)) return;

    await _playbackController.updateCurrentMediaItem(updatedItem);
  }

  bool _hasMetadataChanged(MediaItem current, MediaItem updated) {
    return current.title != updated.title ||
        current.artist != updated.artist ||
        current.album != updated.album ||
        current.duration != updated.duration ||
        current.extras?[MediaItemMapper.songIdKey] !=
            updated.extras?[MediaItemMapper.songIdKey] ||
        current.extras?[MediaItemMapper.dataPathKey] !=
            updated.extras?[MediaItemMapper.dataPathKey] ||
        current.extras?[MediaItemMapper.dateModifiedKey] !=
            updated.extras?[MediaItemMapper.dateModifiedKey];
  }
}
