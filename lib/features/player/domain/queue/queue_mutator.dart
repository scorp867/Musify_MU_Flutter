import 'package:musify_mu/features/player/domain/models/context_page.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';
import 'queue_filter_helper.dart';

/// 1:1 with Spotify's p.zfy (case 25), p.lwp0, and p.pml0 queue algebra
abstract class QueueMutator {
  static String _nextRevision(String currentRevision) {
    final parsed = int.tryParse(currentRevision) ?? 0;
    return (parsed + 1).toString();
  }

  /// 1:1 with zfy.java:681-715 (case y == 0): Add to Queue (Append to User Queue)
  ///
  /// 1. Marks incoming tracks as is_queued = true
  /// 2. Deduplicates against incoming tracks by URI/UID
  /// 3. Reassembles nextTracks: (existing userQueue) + (incoming tracks) + (upcoming contextTracks)
  /// 4. Increments monotonic revision
  static PlayerQueue addToQueue(
    PlayerQueue playerQueue,
    List<ContextTrack> tracksToAdd,
  ) {
    if (tracksToAdd.isEmpty) return playerQueue;

    // Stamp incoming tracks with is_queued = true
    final stampedNewTracks = tracksToAdd
        .map((t) => QueueFilterHelper.setIsQueued(t, true))
        .toList();

    // Deduplicate within existing user queue by UID
    final newTrackUids = stampedNewTracks
        .map((t) => t.uid)
        .where((u) => u.isNotEmpty)
        .toSet();

    final existingUserQueue = QueueFilterHelper.getUserQueue(playerQueue)
        .where((t) => !newTrackUids.contains(t.uid))
        .toList();

    // 1:1 with uvn.java:58: context tracks (subList) and delimiters remain intact
    final contextTracksAndDelimiters =
        playerQueue.nextTracks.where((t) => !t.isQueued).toList();

    // Single linear concatenation: [userQueue] + [newTracks] + [contextTracks]
    final updatedNextTracks = [
      ...existingUserQueue,
      ...stampedNewTracks,
      ...contextTracksAndDelimiters,
    ];

    return playerQueue.copyWith(
      revision: _nextRevision(playerQueue.revision),
      nextTracks: updatedNextTracks,
    );
  }

  /// 1:1 with zfy.java:670-676 (case y == 1): Play Next (Insert at front of User Queue)
  ///
  /// 1. Marks incoming tracks as is_queued = true
  /// 2. Prepends to front of queue: (incoming tracks) + (existing userQueue) + (contextTracks)
  /// 3. Increments monotonic revision
  static PlayerQueue playAsNext(
    PlayerQueue playerQueue,
    List<ContextTrack> tracksToPrepend,
  ) {
    if (tracksToPrepend.isEmpty) return playerQueue;

    final stampedNewTracks = tracksToPrepend
        .map((t) => QueueFilterHelper.setIsQueued(t, true))
        .toList();

    final newTrackUids = stampedNewTracks
        .map((t) => t.uid)
        .where((u) => u.isNotEmpty)
        .toSet();

    final existingUserQueue = QueueFilterHelper.getUserQueue(playerQueue)
        .where((t) => !newTrackUids.contains(t.uid))
        .toList();

    final contextTracksAndDelimiters =
        playerQueue.nextTracks.where((t) => !t.isQueued).toList();

    final updatedNextTracks = [
      ...stampedNewTracks,
      ...existingUserQueue,
      ...contextTracksAndDelimiters,
    ];

    return playerQueue.copyWith(
      revision: _nextRevision(playerQueue.revision),
      nextTracks: updatedNextTracks,
    );
  }

  /// 1:1 with Spotify's p/gxl0.java lines 29-75 (Drag & Drop Reorder Event zxp0 -> qvp0 -> gxl0)
  ///
  /// [draggedTrack]: ContextTrack being moved (gxl0.b)
  /// [targetVisibleIndex]: Target drop index in visible list (gxl0.c)
  /// [isTargetInUserQueue]: Whether the target drop slot is in user queue (qvp0.f)
  static PlayerQueue reorderTrack(
    PlayerQueue playerQueue, {
    required ContextTrack draggedTrack,
    required int targetVisibleIndex,
    required bool isTargetInUserQueue,
  }) {
    final nextTracks = List<ContextTrack>.from(playerQueue.nextTracks);
    final visibleTracks = QueueFilterHelper.getVisibleUpcomingTracks(playerQueue);

    if (targetVisibleIndex < 0 || targetVisibleIndex >= visibleTracks.length) {
      return playerQueue;
    }

    // 1:1 with gxl0.java line 33: get UID of track sitting at targetVisibleIndex
    final targetUid = visibleTracks[targetVisibleIndex].uid;

    // 1:1 with hxl0.e(contextTrack, isQueued): stamp new is_queued metadata on dragged track
    final updatedTrack =
        QueueFilterHelper.setIsQueued(draggedTrack, isTargetInUserQueue);

    // 1:1 with gxl0.java lines 36-49: find index i2 of dragged track in full nextTracks
    final i2 = nextTracks.indexWhere((t) => t.uid == draggedTrack.uid);

    // 1:1 with gxl0.java lines 50-61: find index i of target track in full nextTracks
    final i = nextTracks.indexWhere((t) => t.uid == targetUid);

    if (i2 != -1 && i != -1) {
      // 1:1 with gxl0.java line 63: arrayList.remove(i2)
      nextTracks.removeAt(i2);

      // 1:1 with gxl0.java lines 64-68: arrayList.add(i, contextTrack)
      if (i <= nextTracks.length) {
        nextTracks.insert(i, updatedTrack);
      } else {
        nextTracks.add(updatedTrack);
      }

      return playerQueue.copyWith(
        revision: _nextRevision(playerQueue.revision),
        nextTracks: nextTracks,
      );
    }

    return playerQueue;
  }

  /// 1:1 with lwp0.java:23-40: Undo/Restore Queue Snapshot Reorder Commit (fyp0 -> jvp0 -> lwp0)
  ///
  /// Takes userQueue partition and contextTracks partition after undoing a batch action.
  /// Any track in userQueuePartition gets is_queued = true.
  /// Any track in contextPartition gets is_queued = false.
  /// Concatenates: [userQueuePartition] + [contextPartition]
  static PlayerQueue reorder(
    PlayerQueue playerQueue, {
    required List<ContextTrack> userQueuePartition,
    required List<ContextTrack> contextQueuePartition,
  }) {
    final stampedUserQueue = userQueuePartition
        .map((t) => QueueFilterHelper.setIsQueued(t, true))
        .toList();

    final stampedContextQueue = contextQueuePartition
        .map((t) => QueueFilterHelper.setIsQueued(t, false))
        .toList();

    return playerQueue.copyWith(
      revision: _nextRevision(playerQueue.revision),
      nextTracks: [...stampedUserQueue, ...stampedContextQueue],
    );
  }


  /// 1:1 with sxp0 / l6h0.java:1056-1060: Remove Track by UID
  static PlayerQueue removeTrack(
    PlayerQueue playerQueue,
    String uid,
  ) {
    final updatedNextTracks =
        playerQueue.nextTracks.where((t) => t.uid != uid).toList();

    return playerQueue.copyWith(
      revision: _nextRevision(playerQueue.revision),
      nextTracks: updatedNextTracks,
    );
  }

  /// 1:1 with pml0.java:161-163 (case 2) & tup0.java: Clear User Queue
  ///
  /// Purges all tracks where is_queued == true.
  /// Retains all context tracks, preserving the active album/playlist playback.
  static PlayerQueue clearUserQueue(PlayerQueue playerQueue) {
    final contextTracks =
        playerQueue.nextTracks.where((t) => !t.isQueued).toList();

    return playerQueue.copyWith(
      revision: _nextRevision(playerQueue.revision),
      nextTracks: contextTracks,
    );
  }

  /// Advance queue playhead on natural track completion or skip
  static PlayerQueue advancePlayhead(
    PlayerQueue playerQueue, {
    ContextTrack? targetTrack,
  }) {
    if (playerQueue.nextTracks.isEmpty && targetTrack == null) {
      return playerQueue;
    }

    final current = playerQueue.track;
    final updatedHistory = [
      ?current,
      ...playerQueue.prevTracks,
    ];

    if (targetTrack != null) {
      // Find target track in nextTracks by UID or URI
      final targetIndex = playerQueue.nextTracks.indexWhere(
        (t) => (t.uid.isNotEmpty && t.uid == targetTrack.uid) || t.uri == targetTrack.uri,
      );

      if (targetIndex != -1) {
        final newNextTracks = List<ContextTrack>.from(playerQueue.nextTracks);
        final nextActiveTrack = newNextTracks.removeAt(targetIndex);
        return playerQueue.copyWith(
          revision: _nextRevision(playerQueue.revision),
          track: nextActiveTrack,
          nextTracks: newNextTracks,
          prevTracks: updatedHistory,
        );
      }
    }

    // Default: advance to first upcoming track in linear nextTracks
    final newNextTracks = List<ContextTrack>.from(playerQueue.nextTracks);
    final nextActiveTrack = newNextTracks.isNotEmpty ? newNextTracks.removeAt(0) : null;

    return playerQueue.copyWith(
      revision: _nextRevision(playerQueue.revision),
      track: nextActiveTrack,
      nextTracks: newNextTracks,
      prevTracks: updatedHistory,
    );
  }

  /// 1:1 with Spotify's UpdatePageCommand and context pagination expansion.
  ///
  /// Appends incoming ContextPage tracks to the linear nextTracks sequence.
  static PlayerQueue updatePage(
    PlayerQueue playerQueue,
    ContextPage page,
  ) {
    final pageTracks = page.tracks ?? const [];
    if (pageTracks.isEmpty) return playerQueue;

    return playerQueue.copyWith(
      revision: _nextRevision(playerQueue.revision),
      nextTracks: [...playerQueue.nextTracks, ...pageTracks],
    );
  }
}
