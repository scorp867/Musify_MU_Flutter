import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';

/// 1:1 with Spotify's p.hxl0 and p.s5j queue filtering and metadata management
abstract class QueueFilterHelper {
  /// 1:1 with hxl0.d(playerQueue): Filters tracks where is_queued == true
  static List<ContextTrack> getUserQueue(PlayerQueue playerQueue) {
    return playerQueue.nextTracks
        .where((track) => track.isQueued)
        .toList();
  }

  /// 1:1 with hxl0.b(playerQueue): Filters tracks where is_queued != true
  static List<ContextTrack> getContextQueue(PlayerQueue playerQueue) {
    return playerQueue.nextTracks
        .where((track) => !track.isQueued)
        .toList();
  }

  /// 1:1 with s5j.a: Returns the visible upcoming list (skipping hidden/banned).
  static List<ContextTrack> getVisibleUpcomingTracks(PlayerQueue playerQueue) {
    final visible = <ContextTrack>[];
    for (final track in playerQueue.nextTracks) {
      final isBanned = track.metadata['collection.is_banned'] == 'true';
      final isHidden = track.metadata['hidden'] == 'true';
      if (!isBanned && !isHidden) {
        visible.add(track);
      }
    }
    return visible;
  }

  /// 1:1 with hxl0.e(contextTrack, isQueued):
  /// Returns a new ContextTrack with ContextTrack.Metadata.KEY_IS_QUEUED stamped in metadata
  static ContextTrack setIsQueued(ContextTrack contextTrack, bool isQueued) {
    return contextTrack.copyWith(
      isQueued: isQueued,
      provider: isQueued ? 'queue' : 'context',
    );
  }
}

