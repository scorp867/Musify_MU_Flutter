import '../../domain/models/context_track.dart';
import 'context_track_extensions.dart';

abstract class QueueTrackFilter {
  /// Blacklisted URI prefixes (from Spotify s5j.a)
  static const Set<String> blacklistedPrefixes = {'spotify:meta'};

  /// Filters out tracks beyond delimiter, blacklisted prefixes, banned, hidden, and optionally 19+ (from Spotify s5j.b).
  static List<ContextTrack> filterTracks(
    List<ContextTrack> tracks, {
    bool filter19Plus = false,
  }) {
    // Slicing up to the first delimiter track
    final sliced = <ContextTrack>[];
    for (final track in tracks) {
      if (track.isDelimiter()) {
        break;
      }
      sliced.add(track);
    }

    final filtered = <ContextTrack>[];
    for (final track in sliced) {
      // Check blacklisted URI prefix
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

  /// Filters out unavailable explicit tracks if filterUnavailable is enabled (from Spotify s5j.a).
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
