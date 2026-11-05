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

  /// Determines whether a ContextTrack represents a user-queued track (from Spotify ock1.m68146V).
  static bool isQueued(ContextTrack track) {
    if (track.provider == 'queue') {
      return true;
    }
    final raw = track.metadata[ContextTrackMetadata.keyIsQueued];
    return raw == 'true' || raw == 'True';
  }
}
