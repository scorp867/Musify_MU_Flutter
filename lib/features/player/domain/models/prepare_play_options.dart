import 'package:equatable/equatable.dart';
import 'prefetch_level.dart';

/// 1:1 with Spotify's com.spotify.player.model.command.options.PreparePlayOptions
class PreparePlayOptions extends Equatable {
  final PrefetchLevel prefetchLevel;
  final bool initiallyPaused;
  final bool alwaysPlaySomething;
  final Duration? seekTo;
  final String? skipToTrackUri;
  final String? skipToTrackUid;
  final Map<String, String> configurationOverride;

  const PreparePlayOptions({
    this.prefetchLevel = PrefetchLevel.media,
    this.initiallyPaused = false,
    this.alwaysPlaySomething = false,
    this.seekTo,
    this.skipToTrackUri,
    this.skipToTrackUid,
    this.configurationOverride = const {},
  });

  static const PreparePlayOptions empty = PreparePlayOptions();

  PreparePlayOptions copyWith({
    PrefetchLevel? prefetchLevel,
    bool? initiallyPaused,
    bool? alwaysPlaySomething,
    Duration? seekTo,
    String? skipToTrackUri,
    String? skipToTrackUid,
    Map<String, String>? configurationOverride,
  }) {
    return PreparePlayOptions(
      prefetchLevel: prefetchLevel ?? this.prefetchLevel,
      initiallyPaused: initiallyPaused ?? this.initiallyPaused,
      alwaysPlaySomething: alwaysPlaySomething ?? this.alwaysPlaySomething,
      seekTo: seekTo ?? this.seekTo,
      skipToTrackUri: skipToTrackUri ?? this.skipToTrackUri,
      skipToTrackUid: skipToTrackUid ?? this.skipToTrackUid,
      configurationOverride: configurationOverride ?? this.configurationOverride,
    );
  }

  @override
  List<Object?> get props => [
        prefetchLevel,
        initiallyPaused,
        alwaysPlaySomething,
        seekTo,
        skipToTrackUri,
        skipToTrackUid,
        configurationOverride,
      ];
}
