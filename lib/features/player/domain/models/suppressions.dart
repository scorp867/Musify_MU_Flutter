// 1:1 replica of com.spotify.player.model.Suppressions

class Suppressions {
  static const Suppressions empty = Suppressions(<String>{});

  final Set<String> providers;

  const Suppressions(this.providers);

  static Suppressions create([Set<String>? providers]) {
    return Suppressions(providers != null ? Set<String>.unmodifiable(providers) : const <String>{});
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Suppressions &&
          other.providers.length == providers.length &&
          other.providers.containsAll(providers));

  @override
  int get hashCode => providers.fold(0, (prev, element) => prev ^ element.hashCode);

  @override
  String toString() => 'Suppressions{providers=$providers}';
}

abstract class SuppressionsProviders {
  static const String ads = 'ad';
  static const String mft = 'mft';
  static const String mftDisallowRestartPlay = 'mft/disallow_restart_play';
  static const String mftInjectFillerTracks = 'mft/inject_filler_tracks';
  static const String mftInjectRandomTracks = 'mft/inject_random_tracks';
  static const String mftInjectTrackOnStartPlay = 'mft/inject_track_on_start_play';
  static const String podcastAd = 'podcast_ad';
  static const String resumePoint = 'played_state/resume_point';
}
