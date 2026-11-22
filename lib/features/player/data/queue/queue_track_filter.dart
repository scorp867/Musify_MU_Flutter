// ============================================================================
// 1:1 Replica of Spotify Queue Delimiter & Track Visibility Filter
// Sources:
// - Decompiled Java:
//   - `p199p/erl.java:16,19-69` (`f64907a = {"spotify:meta"}`, `m42236a`, `m42237b`)
//   - `p199p/bh10.java:339-361` (partitions `playerQueue.nextTracks()` by `ock1.m68146V`
//     into `userQueue` / `contextTracks` and applies `erl.m42237b` to both lists)
//   - `p199p/fi31.java:42-88` (stops at first `isDelimiter()` when resolving next track)
//   - `com/spotify/player/model/ContextTrack.java:16,206-208`
//     (`delimiters = ["spotify:meta:delimiter", "spotify:delimiter"]`)
// - Native binary (`liborbit-jni-spotify.so` arm64):
//   - `0x13bd38c..0x13bd404` (`spotify:meta:delimiter`, `spotify:delimiter`, `spotify:meta:`)
//   - `0xe61124..0xe61158` (delimiter boundary break during queue traversal)
// ============================================================================

import '../../domain/models/context_track.dart';
import 'context_track_extensions.dart';
import 'queue_key_resolver.dart';

/// Partitioned visible queue result matching `p199p/bh10.java:339-361` (`wcx0`).
typedef FilteredQueuePartition = ({
  List<ContextTrack> userQueue,
  List<ContextTrack> contextTracks,
});

abstract class QueueTrackFilter {
  /// Blacklisted URI prefixes (`p199p/erl.java:16` `f64907a`).
  static const Set<String> blacklistedPrefixes = {'spotify:meta'};

  /// Partitions raw `PlayerQueue.nextTracks` into user-queued ("Next in Queue")
  /// and context ("Next from ...") tracks and filters both partitions via
  /// [filterTracks], matching `p199p/bh10.java:344-361` -> `p199p/erl.java:40-69`.
  ///
  /// Both `spotify:delimiter` / `spotify:meta:delimiter` AND every subsequent
  /// track after the delimiter are excluded from the visible UI lists while
  /// keeping the authoritative raw `PlayerQueue.nextTracks` untouched.
  static FilteredQueuePartition partitionAndFilter(
    List<ContextTrack> nextTracks, {
    bool filter19Plus = false,
  }) {
    final rawUserQueue = <ContextTrack>[];
    final rawContextTracks = <ContextTrack>[];

    for (final track in nextTracks) {
      if (QueueKeyResolver.isQueued(track)) {
        rawUserQueue.add(track);
      } else {
        rawContextTracks.add(track);
      }
    }

    return (
      userQueue: filterTracks(rawUserQueue, filter19Plus: filter19Plus),
      contextTracks: filterTracks(rawContextTracks, filter19Plus: filter19Plus),
    );
  }

  /// Filters out tracks at and beyond the first delimiter, blacklisted URI
  /// prefixes (`spotify:meta*`), collection-banned, hidden, and optionally 19+
  /// tracks (`p199p/erl.java:40-69` `m42237b`).
  static List<ContextTrack> filterTracks(
    List<ContextTrack> tracks, {
    bool filter19Plus = false,
  }) {
    // 1:1 with `p199p/erl.java:43-49`: slice strictly up to the first delimiter.
    final sliced = <ContextTrack>[];
    for (final track in tracks) {
      if (track.isDelimiter()) {
        break;
      }
      sliced.add(track);
    }

    final filtered = <ContextTrack>[];
    for (final track in sliced) {
      // 1:1 with `p199p/erl.java:55-63`: drop blacklisted URI prefixes.
      bool isBlacklisted = false;
      for (final prefix in blacklistedPrefixes) {
        if (track.uri.startsWith(prefix)) {
          isBlacklisted = true;
          break;
        }
      }
      if (isBlacklisted) continue;

      if (!track.isCollectionBanned &&
          !track.isHidden &&
          (!filter19Plus || !track.is19Plus)) {
        filtered.add(track);
      }
    }
    return filtered;
  }

  /// Filters out unavailable explicit tracks if [filterUnavailable] is enabled
  /// (`p199p/erl.java:19-37` `m42236a`).
  static List<ContextTrack> filterAvailability(
    List<ContextTrack> tracks,
    Map<String, bool> availabilityMap, {
    bool filterUnavailable = false,
  }) {
    if (!filterUnavailable) {
      return List<ContextTrack>.from(tracks);
    }

    final result = <ContextTrack>[];
    for (final track in tracks) {
      final isAvailable = track.isExplicit
          ? (availabilityMap[track.uri] == true)
          : true;
      if (isAvailable) {
        result.add(track);
      }
    }
    return result;
  }
}
