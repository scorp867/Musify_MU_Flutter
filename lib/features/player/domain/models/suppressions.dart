// 1:1 replica of com.spotify.player.model.Suppressions

import 'dart:collection';

class Suppressions {
  static const Suppressions empty = Suppressions._(<String>{});

  final Set<String> providers;

  const Suppressions._(this.providers);

  static Suppressions create([Set<String>? providers]) {
    if (providers == null || providers.isEmpty) {
      return empty;
    }
    return Suppressions._(UnmodifiableSetView<String>(Set<String>.from(providers)));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Suppressions &&
          other.providers.length == providers.length &&
          other.providers.containsAll(providers));

  @override
  int get hashCode => Object.hashAll(providers) ^ 1000003;

  @override
  String toString() => 'Suppressions{providers=$providers}';
}

abstract final class SuppressionsProviders {
  static const String ads = 'ad';
  static const String mft = 'mft';
  static const String mftDisallowRestartPlay = 'mft/disallow_restart_play';
  static const String mftInjectFillerTracks = 'mft/inject_filler_tracks';
  static const String mftInjectRandomTracks = 'mft/inject_random_tracks';
  static const String mftInjectTrackOnStartPlay = 'mft/inject_track_on_start_play';
  static const String podcastAd = 'podcast_ad';
  static const String resumePoint = 'played_state/resume_point';
}
