// 1:1 replica of com.spotify.player.model.command.options.PreparePlayOptions

import '../../models/audio_stream.dart';
import '../../models/suppressions.dart';
import 'player_option_overrides.dart';
import 'prefetch_level.dart';
import 'skip_to_track.dart';

class PreparePlayOptions {
  static final PreparePlayOptions empty = builder().build();

  final String? playbackId;
  final bool? alwaysPlaySomething;
  final SkipToTrack? skipTo;
  final int? seekTo;
  final bool? initiallyPaused;
  final bool? systemInitiated;
  final PlayerOptionOverrides? playerOptionsOverride;
  final Suppressions? suppressions;
  final PrefetchLevel? prefetchLevel;
  final AudioStream? audioStream;
  final String? sessionId;
  final String? license;
  final Map<String, String> configurationOverride;
  final String? seekToCreatorTimestamp;

  const PreparePlayOptions({
    this.playbackId,
    this.alwaysPlaySomething,
    this.skipTo,
    this.seekTo,
    this.initiallyPaused,
    this.systemInitiated,
    this.playerOptionsOverride,
    this.suppressions,
    this.prefetchLevel,
    this.audioStream,
    this.sessionId,
    this.license,
    this.configurationOverride = const <String, String>{},
    this.seekToCreatorTimestamp,
  });

  static PreparePlayOptionsBuilder builder() =>
      PreparePlayOptionsBuilder().configurationOverride(const <String, String>{});

  PreparePlayOptionsBuilder toBuilder() => PreparePlayOptionsBuilder(
        playbackId: playbackId,
        alwaysPlaySomething: alwaysPlaySomething,
        skipTo: skipTo,
        seekTo: seekTo,
        initiallyPaused: initiallyPaused,
        systemInitiated: systemInitiated,
        playerOptionsOverride: playerOptionsOverride,
        suppressions: suppressions,
        prefetchLevel: prefetchLevel,
        audioStream: audioStream,
        sessionId: sessionId,
        license: license,
        configurationOverride: configurationOverride,
        seekToCreatorTimestamp: seekToCreatorTimestamp,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreparePlayOptions &&
          other.playbackId == playbackId &&
          other.alwaysPlaySomething == alwaysPlaySomething &&
          other.skipTo == skipTo &&
          other.seekTo == seekTo &&
          other.initiallyPaused == initiallyPaused &&
          other.systemInitiated == systemInitiated &&
          other.playerOptionsOverride == playerOptionsOverride &&
          other.suppressions == suppressions &&
          other.prefetchLevel == prefetchLevel &&
          other.audioStream == audioStream &&
          other.sessionId == sessionId &&
          other.license == license &&
          _mapEquals(other.configurationOverride, configurationOverride) &&
          other.seekToCreatorTimestamp == seekToCreatorTimestamp);

  @override
  int get hashCode => Object.hashAll([
        playbackId,
        alwaysPlaySomething,
        skipTo,
        seekTo,
        initiallyPaused,
        systemInitiated,
        playerOptionsOverride,
        suppressions,
        prefetchLevel,
        audioStream,
        sessionId,
        license,
        Object.hashAll(
            configurationOverride.entries.map((e) => Object.hash(e.key, e.value))),
        seekToCreatorTimestamp,
      ]);

  @override
  String toString() =>
      'PreparePlayOptions{playbackId=$playbackId, alwaysPlaySomething=$alwaysPlaySomething, skipTo=$skipTo, seekTo=$seekTo, initiallyPaused=$initiallyPaused, systemInitiated=$systemInitiated, playerOptionsOverride=$playerOptionsOverride, suppressions=$suppressions, prefetchLevel=$prefetchLevel, audioStream=$audioStream, sessionId=$sessionId, license=$license, configurationOverride=$configurationOverride, seekToCreatorTimestamp=$seekToCreatorTimestamp}';

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
  String? _playbackId;
  bool? _alwaysPlaySomething;
  SkipToTrack? _skipTo;
  int? _seekTo;
  bool? _initiallyPaused;
  bool? _systemInitiated;
  PlayerOptionOverrides? _playerOptionsOverride;
  Suppressions? _suppressions;
  PrefetchLevel? _prefetchLevel;
  AudioStream? _audioStream;
  String? _sessionId;
  String? _license;
  Map<String, String> _configurationOverride;
  String? _seekToCreatorTimestamp;

  PreparePlayOptionsBuilder({
    String? playbackId,
    bool? alwaysPlaySomething,
    SkipToTrack? skipTo,
    int? seekTo,
    bool? initiallyPaused,
    bool? systemInitiated,
    PlayerOptionOverrides? playerOptionsOverride,
    Suppressions? suppressions,
    PrefetchLevel? prefetchLevel,
    AudioStream? audioStream,
    String? sessionId,
    String? license,
    Map<String, String> configurationOverride = const <String, String>{},
    String? seekToCreatorTimestamp,
  })  : _playbackId = playbackId,
        _alwaysPlaySomething = alwaysPlaySomething,
        _skipTo = skipTo,
        _seekTo = seekTo,
        _initiallyPaused = initiallyPaused,
        _systemInitiated = systemInitiated,
        _playerOptionsOverride = playerOptionsOverride,
        _suppressions = suppressions,
        _prefetchLevel = prefetchLevel,
        _audioStream = audioStream,
        _sessionId = sessionId,
        _license = license,
        _configurationOverride = Map<String, String>.from(configurationOverride),
        _seekToCreatorTimestamp = seekToCreatorTimestamp;

  static PreparePlayOptionsBuilder builder() => PreparePlayOptions.builder();

  PreparePlayOptionsBuilder playbackId(String val) {
    _playbackId = val;
    return this;
  }

  PreparePlayOptionsBuilder alwaysPlaySomething(bool val) {
    _alwaysPlaySomething = val;
    return this;
  }

  PreparePlayOptionsBuilder skipTo(SkipToTrack val) {
    _skipTo = val;
    return this;
  }

  PreparePlayOptionsBuilder seekTo(int val) {
    _seekTo = val;
    return this;
  }

  PreparePlayOptionsBuilder initiallyPaused(bool val) {
    _initiallyPaused = val;
    return this;
  }

  PreparePlayOptionsBuilder systemInitiated(bool val) {
    _systemInitiated = val;
    return this;
  }

  PreparePlayOptionsBuilder playerOptionsOverride(PlayerOptionOverrides val) {
    _playerOptionsOverride = val;
    return this;
  }

  PreparePlayOptionsBuilder suppressions(Suppressions val) {
    _suppressions = val;
    return this;
  }

  PreparePlayOptionsBuilder suppressionsFromSet(Set<String> set) {
    _suppressions = Suppressions.create(set);
    return this;
  }

  PreparePlayOptionsBuilder prefetchLevel(PrefetchLevel val) {
    _prefetchLevel = val;
    return this;
  }

  PreparePlayOptionsBuilder audioStream(AudioStream val) {
    _audioStream = val;
    return this;
  }

  PreparePlayOptionsBuilder sessionId(String val) {
    _sessionId = val;
    return this;
  }

  PreparePlayOptionsBuilder license(String val) {
    _license = val;
    return this;
  }

  PreparePlayOptionsBuilder configurationOverride(Map<String, String> val) {
    _configurationOverride = Map<String, String>.from(val);
    return this;
  }

  PreparePlayOptionsBuilder seekToCreatorTimestamp(String val) {
    _seekToCreatorTimestamp = val;
    return this;
  }

  PreparePlayOptions build() => PreparePlayOptions(
        playbackId: _playbackId,
        alwaysPlaySomething: _alwaysPlaySomething,
        skipTo: _skipTo,
        seekTo: _seekTo,
        initiallyPaused: _initiallyPaused,
        systemInitiated: _systemInitiated,
        playerOptionsOverride: _playerOptionsOverride,
        suppressions: _suppressions,
        prefetchLevel: _prefetchLevel,
        audioStream: _audioStream,
        sessionId: _sessionId,
        license: _license,
        configurationOverride:
            Map<String, String>.unmodifiable(_configurationOverride),
        seekToCreatorTimestamp: _seekToCreatorTimestamp,
      );
}
