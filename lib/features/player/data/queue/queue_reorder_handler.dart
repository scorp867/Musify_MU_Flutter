import '../../domain/commands/set_queue_command.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/player_queue.dart';
import 'context_track_extensions.dart';
import 'queue_helpers.dart';
import 'queue_track_filter.dart';

abstract class QueueReorderHandler {
  /// Reorders a track within playerQueue.nextTracks relative to the visible track list (from Spotify gxl0).
  ///
  /// [trackToMove]: The track being dragged/reordered.
  /// [destinationVisibleIndex]: The target index in the user's visible queue view.
  /// [filter19Plus]: Whether 19+ tracks are currently filtered out in the view.
  /// [filterUnavailable]: Whether unavailable tracks are filtered out.
  /// [availabilityMap]: Availability status per track URI.
  static PlayerQueue reorderTrack({
    required PlayerQueue playerQueue,
    required ContextTrack trackToMove,
    required int destinationVisibleIndex,
    bool filter19Plus = false,
    bool filterUnavailable = false,
    Map<String, bool> availabilityMap = const {},
  }) {
    final nextTracks = List<ContextTrack>.from(playerQueue.nextTracks);

    // 1. Resolve visible tracks corresponding to the UI display
    final slicedAndFiltered = QueueTrackFilter.filterTracks(
      nextTracks,
      filter19Plus: filter19Plus,
    );
    final visibleTracks = QueueTrackFilter.filterAvailability(
      slicedAndFiltered,
      availabilityMap,
      filterUnavailable: filterUnavailable,
    );

    if (visibleTracks.isEmpty) {
      return playerQueue;
    }

    if (destinationVisibleIndex < 0 ||
        destinationVisibleIndex >= visibleTracks.length) {
      throw RangeError.range(
        destinationVisibleIndex,
        0,
        visibleTracks.length - 1,
        'destinationVisibleIndex',
        'Destination index is outside the visible track list bounds',
      );
    }

    // 2. Determine boundary between user-queued tracks and context tracks (Spotify lr5.java lines 580-596)
    int lastQueuedVisibleIndex = -1;
    for (int i = visibleTracks.length - 1; i >= 0; i--) {
      if (visibleTracks[i].uid != trackToMove.uid && visibleTracks[i].isQueued) {
        lastQueuedVisibleIndex = i;
        break;
      }
    }

    final bool targetIsQueued;
    if (lastQueuedVisibleIndex == -1) {
      targetIsQueued = destinationVisibleIndex == 0 && trackToMove.isQueued;
    } else {
      targetIsQueued = destinationVisibleIndex <= (lastQueuedVisibleIndex + 1);
    }

    // 3. Mutate track metadata via Spotify hxl0.e (ich0.java line 72)
    final mutatedTrack =
        QueueHelpers.setQueuedMetadata(trackToMove, targetIsQueued);

    // 4. Identify target track uid at the visible destination position
    final targetUid = visibleTracks[destinationVisibleIndex].uid;

    // 5. Find source index in absolute nextTracks
    int sourceIndex = -1;
    for (int i = 0; i < nextTracks.length; i++) {
      if (nextTracks[i].uid == trackToMove.uid) {
        sourceIndex = i;
        break;
      }
    }

    // 6. Find target index in absolute nextTracks
    int targetIndex = -1;
    for (int i = 0; i < nextTracks.length; i++) {
      if (nextTracks[i].uid == targetUid) {
        targetIndex = i;
        break;
      }
    }

    // 7. Shift track position (Spotify gxl0.java lines 63-71)
    if (sourceIndex != -1 && targetIndex != -1) {
      nextTracks.removeAt(sourceIndex);
      if (targetIndex <= nextTracks.length) {
        nextTracks.insert(targetIndex, mutatedTrack);
      } else {
        nextTracks.add(mutatedTrack);
      }

      return playerQueue.toBuilder().nextTracks(nextTracks).build();
    }

    return playerQueue;
  }

  /// Creates the SetQueueCommand after executing reordering.
  static SetQueueCommand createReorderCommand({
    required PlayerQueue playerQueue,
    required ContextTrack trackToMove,
    required int destinationVisibleIndex,
    bool filter19Plus = false,
    bool filterUnavailable = false,
    Map<String, bool> availabilityMap = const {},
  }) {
    final reorderedQueue = reorderTrack(
      playerQueue: playerQueue,
      trackToMove: trackToMove,
      destinationVisibleIndex: destinationVisibleIndex,
      filter19Plus: filter19Plus,
      filterUnavailable: filterUnavailable,
      availabilityMap: availabilityMap,
    );
    return QueueHelpers.createSetQueueCommand(reorderedQueue);
  }
}
