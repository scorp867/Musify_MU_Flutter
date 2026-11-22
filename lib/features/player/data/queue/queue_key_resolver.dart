// ============================================================================
// 1:1 Replica of Spotify Queue Key & Queued Predicate Resolver
// Sources:
// - Decompiled Java:
//   - `p199p/ock1.java:204-206` (`m68146V`: `Boolean.parseBoolean(metadata["is_queued"])`)
//   - `p199p/ock1.java:1477-1479` (`m68168i0`: `uid + uri + provider + iteration`)
//   - `com/spotify/player/model/ContextTrack.java:16,206-208` (`isDelimiter()`)
// - Native binary (`liborbit-jni-spotify.so` arm64):
//   - `0x13bd38c..0x13bd3bc` (`spotify:meta:delimiter`, `spotify:delimiter`)
// ============================================================================

import '../../domain/models/context_track.dart';

/// Resolves unique compound queue keys matching Spotify's 1:1 implementation in `ock1.java` line 1478 (`m68168i0`).
///
/// Compound Key format:
/// `uid + uri + provider + iteration`
abstract final class QueueKeyResolver {
  /// Computes the unique compound key identifying a track instance in the queue.
  static String resolveKey(ContextTrack track) {
    final uid = track.uid;
    final uri = track.uri;
    final provider = track.provider;
    final iteration = switch (track.metadata[ContextTrackMetadata.keyIteration]) {
      final iter? => iter,
      null => '',
    };
    return '$uid$uri$provider$iteration';
  }

  /// Determines whether a ContextTrack represents a user-queued track
  /// (`p199p/ock1.java:204-206` `m68146V`), while explicitly excluding
  /// Spotify queue delimiters (`ContextTrack.java:206-208`).
  static bool isQueued(ContextTrack track) {
    if (track.isDelimiter()) {
      return false;
    }
    if (track.metadata[ContextTrackMetadata.keyIsQueued] case final raw?) {
      final normalized = raw.toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return track.provider == 'queue';
  }
}
