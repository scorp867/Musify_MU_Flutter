// 1:1 replica of com.spotify.player.model.command.options.PreparePlayOptions

import '../../models/audio_stream.dart';
import '../../models/suppressions.dart';
import 'player_option_overrides.dart';
import 'prefetch_level.dart';
import 'skip_to_track.dart';

class PreparePlayOptions {
  static final PreparePlayOptions empty = builder().build();

  final bool? alwaysPlaySomething;
  final AudioStream? audioStream;
  final Map<String, String> configurationOverride;
  final bool? initiallyPaused;
  final String? license;
  final String? playbackId;
  final PlayerOptionOverrides? playerOptionsOverride;
  final PrefetchLevel? prefetchLevel;
  final int? seekTo;
  final String? seekToCreatorTimestamp;
  final String? sessionId;
  final SkipToTrack? skipTo;
  final Suppressions? suppressions;
  final bool? systemInitiated;

  const PreparePlayOptions({
    this.alwaysPlaySomething,
    this.audioStream,
    this.configurationOverride = const <String, String>{},
    this.initiallyPaused,
    this.license,
    this.playbackId,
    this.playerOptionsOverride,
    this.prefetchLevel,
    this.seekTo,
    this.seekToCreatorTimestamp,
    this.sessionId,
    this.skipTo,
    this.suppressions,
    this.systemInitiated,
  });

  static PreparePlayOptionsBuilder builder() => PreparePlayOptionsBuilder();

  PreparePlayOptionsBuilder toBuilder() => PreparePlayOptionsBuilder(
        alwaysPlaySomething: alwaysPlaySomething,
        audioStream: audioStream,
        configurationOverride: configurationOverride,
        initiallyPaused: initiallyPaused,
        license: license,
        playbackId: playbackId,
        playerOptionsOverride: playerOptionsOverride,
        prefetchLevel: prefetchLevel,
        seekTo: seekTo,
        seekToCreatorTimestamp: seekToCreatorTimestamp,
        sessionId: sessionId,
        skipTo: skipTo,
        suppressions: suppressions,
        systemInitiated: systemInitiated,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreparePlayOptions &&
          other.alwaysPlaySomething == alwaysPlaySomething &&
          other.audioStream == audioStream &&
          other.initiallyPaused == initiallyPaused &&
          other.license == license &&
          other.playbackId == playbackId &&
          other.playerOptionsOverride == playerOptionsOverride &&
          other.prefetchLevel == prefetchLevel &&
          other.seekTo == seekTo &&
          other.seekToCreatorTimestamp == seekToCreatorTimestamp &&
          other.sessionId == sessionId &&
          other.skipTo == skipTo &&
          other.suppressions == suppressions &&
          other.systemInitiated == systemInitiated &&
          _mapEquals(other.configurationOverride, configurationOverride));

  @override
  int get hashCode => Object.hashAll([
        alwaysPlaySomething,
        audioStream,
        initiallyPaused,
        license,
        playbackId,
        playerOptionsOverride,
        prefetchLevel,
        seekTo,
        seekToCreatorTimestamp,
        sessionId,
        skipTo,
        suppressions,
        systemInitiated,
      ]);

  @override
  String toString() =>
      'PreparePlayOptions{alwaysPlaySomething=$alwaysPlaySomething, audioStream=$audioStream, initiallyPaused=$initiallyPaused, license=$license, playbackId=$playbackId, prefetchLevel=$prefetchLevel, seekTo=$seekTo, sessionId=$sessionId, skipTo=$skipTo, systemInitiated=$systemInitiated}';

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }
}

class PreparePlayOptionsBuilder {
  bool? _alwaysPlaySomething;
  AudioStream? _audioStream;
  Map<String, String> _configurationOverride;
  bool? _initiallyPaused;
  String? _license;
  String? _playbackId;
  PlayerOptionOverrides? _playerOptionsOverride;
  PrefetchLevel? _prefetchLevel;
  int? _seekTo;
  String? _seekToCreatorTimestamp;
  String? _sessionId;
  SkipToTrack? _skipTo;
  Suppressions? _suppressions;
  bool? _systemInitiated;

  PreparePlayOptionsBuilder({
    bool? alwaysPlaySomething,
    AudioStream? audioStream,
    Map<String, String> configurationOverride = const <String, String>{},
    bool? initiallyPaused,
    String? license,
    String? playbackId,
    PlayerOptionOverrides? playerOptionsOverride,
    PrefetchLevel? prefetchLevel,
    int? seekTo,
    String? seekToCreatorTimestamp,
    String? sessionId,
    SkipToTrack? skipTo,
    Suppressions? suppressions,
    bool? systemInitiated,
  })  : _alwaysPlaySomething = alwaysPlaySomething,
        _audioStream = audioStream,
        _configurationOverride = Map<String, String>.from(configurationOverride),
        _initiallyPaused = initiallyPaused,
        _license = license,
        _playbackId = playbackId,
        _playerOptionsOverride = playerOptionsOverride,
        _prefetchLevel = prefetchLevel,
        _seekTo = seekTo,
        _seekToCreatorTimestamp = seekToCreatorTimestamp,
        _sessionId = sessionId,
        _skipTo = skipTo,
        _suppressions = suppressions,
        _systemInitiated = systemInitiated;

  PreparePlayOptionsBuilder alwaysPlaySomething(bool val) { _alwaysPlaySomething = val; return this; }
  PreparePlayOptionsBuilder audioStream(AudioStream val) { _audioStream = val; return this; }
  PreparePlayOptionsBuilder configurationOverride(Map<String, String> val) { _configurationOverride = Map.from(val); return this; }
  PreparePlayOptionsBuilder initiallyPaused(bool val) { _initiallyPaused = val; return this; }
  PreparePlayOptionsBuilder license(String val) { _license = val; return this; }
  PreparePlayOptionsBuilder playbackId(String val) { _playbackId = val; return this; }
  PreparePlayOptionsBuilder playerOptionsOverride(PlayerOptionOverrides val) { _playerOptionsOverride = val; return this; }
  PreparePlayOptionsBuilder prefetchLevel(PrefetchLevel val) { _prefetchLevel = val; return this; }
  PreparePlayOptionsBuilder seekTo(int val) { _seekTo = val; return this; }
  PreparePlayOptionsBuilder seekToCreatorTimestamp(String val) { _seekToCreatorTimestamp = val; return this; }
  PreparePlayOptionsBuilder sessionId(String val) { _sessionId = val; return this; }
  PreparePlayOptionsBuilder skipTo(SkipToTrack val) { _skipTo = val; return this; }
  PreparePlayOptionsBuilder suppressions(Suppressions val) { _suppressions = val; return this; }
  PreparePlayOptionsBuilder systemInitiated(bool val) { _systemInitiated = val; return this; }

  PreparePlayOptions build() => PreparePlayOptions(
        alwaysPlaySomething: _alwaysPlaySomething,
        audioStream: _audioStream,
        configurationOverride: Map<String, String>.unmodifiable(_configurationOverride),
        initiallyPaused: _initiallyPaused,
        license: _license,
        playbackId: _playbackId,
        playerOptionsOverride: _playerOptionsOverride,
        prefetchLevel: _prefetchLevel,
        seekTo: _seekTo,
        seekToCreatorTimestamp: _seekToCreatorTimestamp,
        sessionId: _sessionId,
        skipTo: _skipTo,
        suppressions: _suppressions,
        systemInitiated: _systemInitiated,
      );
}
