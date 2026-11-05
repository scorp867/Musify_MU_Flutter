// 1:1 replica of com.spotify.player.model.PlayerState

import 'ad_break_context.dart';
import 'audio_stream.dart';
import 'context_index.dart';
import 'context_track.dart';
import 'format.dart';
import 'play_origin.dart';
import 'playback_quality.dart';
import 'player_options.dart';
import 'restrictions.dart';
import 'sleep_timer.dart';
import 'suppressions.dart';

class PlayerState {
  static final PlayerState empty = builder().build();

  final int timestamp;
  final String contextUri;
  final String contextUrl;
  final Restrictions contextRestrictions;
  final PlayOrigin playOrigin;
  final ContextIndex? index;
  final ContextTrack? track;
  final String? playbackId;
  final String? sessionCommandId;
  final Format? format;
  final PlaybackQuality? playbackQuality;
  final SleepTimer? sleepTimer;
  final double? playbackSpeed;
  final int? positionAsOfTimestamp;
  final int? duration;
  final bool isPlaying;
  final bool isPaused;
  final bool isBuffering;
  final bool isSystemInitiated;
  final PlayerOptions options;
  final Restrictions restrictions;
  final Suppressions suppressions;
  final List<ContextTrack> prevTracks;
  final List<ContextTrack> nextTracks;
  final Map<String, String> contextMetadata;
  final Map<String, String> pageMetadata;
  final String sessionId;
  final String queueRevision;
  final AudioStream audioStream;
  final List<String> signals;
  final AdBreakContext? adBreakContext;

  const PlayerState({
    this.timestamp = 0,
    this.contextUri = '',
    this.contextUrl = '',
    this.contextRestrictions = const Restrictions(),
    this.playOrigin = const PlayOrigin(),
    this.index,
    this.track,
    this.playbackId,
    this.sessionCommandId,
    this.format,
    this.playbackQuality,
    this.sleepTimer,
    this.playbackSpeed,
    this.positionAsOfTimestamp,
    this.duration,
    this.isPlaying = false,
    this.isPaused = false,
    this.isBuffering = false,
    this.isSystemInitiated = false,
    this.options = const PlayerOptions(),
    this.restrictions = const Restrictions(),
    this.suppressions = Suppressions.empty,
    this.prevTracks = const <ContextTrack>[],
    this.nextTracks = const <ContextTrack>[],
    this.contextMetadata = const <String, String>{},
    this.pageMetadata = const <String, String>{},
    this.sessionId = '',
    this.queueRevision = '0',
    this.audioStream = AudioStream.defaultStream,
    this.signals = const <String>[],
    this.adBreakContext,
  });

  static PlayerStateBuilder builder() => PlayerStateBuilder()
      .timestamp(0)
      .contextUri('')
      .contextUrl('')
      .contextRestrictions(const Restrictions())
      .options(const PlayerOptions())
      .restrictions(const Restrictions())
      .playOrigin(const PlayOrigin())
      .isPlaying(false)
      .isPaused(false)
      .isBuffering(false)
      .isSystemInitiated(false)
      .suppressions(Suppressions.empty)
      .prevTracks(const <ContextTrack>[])
      .nextTracks(const <ContextTrack>[])
      .contextMetadata(const <String, String>{})
      .pageMetadata(const <String, String>{})
      .sessionId('')
      .queueRevision('0')
      .signals(const <String>[])
      .audioStream(AudioStream.defaultStream);

  PlayerStateBuilder toBuilder() => PlayerStateBuilder(
        timestamp: timestamp,
        contextUri: contextUri,
        contextUrl: contextUrl,
        contextRestrictions: contextRestrictions,
        playOrigin: playOrigin,
        index: index,
        track: track,
        playbackId: playbackId,
        sessionCommandId: sessionCommandId,
        format: format,
        playbackQuality: playbackQuality,
        sleepTimer: sleepTimer,
        playbackSpeed: playbackSpeed,
        positionAsOfTimestamp: positionAsOfTimestamp,
        duration: duration,
        isPlaying: isPlaying,
        isPaused: isPaused,
        isBuffering: isBuffering,
        isSystemInitiated: isSystemInitiated,
        options: options,
        restrictions: restrictions,
        suppressions: suppressions,
        prevTracks: prevTracks,
        nextTracks: nextTracks,
        contextMetadata: contextMetadata,
        pageMetadata: pageMetadata,
        sessionId: sessionId,
        queueRevision: queueRevision,
        audioStream: audioStream,
        signals: signals,
        adBreakContext: adBreakContext,
      );

  int? position(int currentTimestamp) {
    if (positionAsOfTimestamp case final pos?) {
      final speed = switch (playbackSpeed) {
        final s? => s,
        null => (isPlaying && !isPaused) ? 1.0 : 0.0,
      };
      final diff = currentTimestamp - timestamp;
      return (pos + (speed * diff)).round();
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerState &&
          other.timestamp == timestamp &&
          other.contextUri == contextUri &&
          other.contextUrl == contextUrl &&
          other.contextRestrictions == contextRestrictions &&
          other.playOrigin == playOrigin &&
          other.index == index &&
          other.track == track &&
          other.playbackId == playbackId &&
          other.sessionCommandId == sessionCommandId &&
          other.format == format &&
          other.playbackQuality == playbackQuality &&
          other.sleepTimer == sleepTimer &&
          other.playbackSpeed == playbackSpeed &&
          other.positionAsOfTimestamp == positionAsOfTimestamp &&
          other.duration == duration &&
          other.isPlaying == isPlaying &&
          other.isPaused == isPaused &&
          other.isBuffering == isBuffering &&
          other.isSystemInitiated == isSystemInitiated &&
          other.options == options &&
          other.restrictions == restrictions &&
          other.suppressions == suppressions &&
          _listEquals(other.prevTracks, prevTracks) &&
          _listEquals(other.nextTracks, nextTracks) &&
          _mapEquals(other.contextMetadata, contextMetadata) &&
          _mapEquals(other.pageMetadata, pageMetadata) &&
          other.sessionId == sessionId &&
          other.queueRevision == queueRevision &&
          other.audioStream == audioStream &&
          _listEquals(other.signals, signals) &&
          other.adBreakContext == adBreakContext);

  @override
  int get hashCode => Object.hashAll([
        timestamp,
        contextUri,
        contextUrl,
        contextRestrictions,
        playOrigin,
        index,
        track,
        playbackId,
        sessionCommandId,
        format,
        playbackQuality,
        sleepTimer,
        playbackSpeed,
        positionAsOfTimestamp,
        duration,
        isPlaying,
        isPaused,
        isBuffering,
        isSystemInitiated,
        options,
      ]);

  @override
  String toString() =>
      'PlayerState{timestamp=$timestamp, contextUri=$contextUri, contextUrl=$contextUrl, contextRestrictions=$contextRestrictions, playOrigin=$playOrigin, index=$index, track=$track, playbackId=$playbackId, sessionCommandId=$sessionCommandId, format=$format, playbackQuality=$playbackQuality, sleepTimer=$sleepTimer, playbackSpeed=$playbackSpeed, positionAsOfTimestamp=$positionAsOfTimestamp, duration=$duration, isPlaying=$isPlaying, isPaused=$isPaused, isBuffering=$isBuffering, isSystemInitiated=$isSystemInitiated, options=$options, restrictions=$restrictions, suppressions=$suppressions, prevTracks=$prevTracks, nextTracks=$nextTracks, contextMetadata=$contextMetadata, pageMetadata=$pageMetadata, sessionId=$sessionId, queueRevision=$queueRevision, audioStream=$audioStream, signals=$signals, adBreakContext=$adBreakContext}';

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class PlayerStateBuilder {
  int _timestamp;
  String _contextUri;
  String _contextUrl;
  Restrictions _contextRestrictions;
  PlayOrigin _playOrigin;
  ContextIndex? _index;
  ContextTrack? _track;
  String? _playbackId;
  String? _sessionCommandId;
  Format? _format;
  PlaybackQuality? _playbackQuality;
  SleepTimer? _sleepTimer;
  double? _playbackSpeed;
  int? _positionAsOfTimestamp;
  int? _duration;
  bool _isPlaying;
  bool _isPaused;
  bool _isBuffering;
  bool _isSystemInitiated;
  PlayerOptions _options;
  Restrictions _restrictions;
  Suppressions _suppressions;
  List<ContextTrack> _prevTracks;
  List<ContextTrack> _nextTracks;
  Map<String, String> _contextMetadata;
  Map<String, String> _pageMetadata;
  String _sessionId;
  String _queueRevision;
  AudioStream _audioStream;
  List<String> _signals;
  AdBreakContext? _adBreakContext;

  PlayerStateBuilder({
    int timestamp = 0,
    String contextUri = '',
    String contextUrl = '',
    Restrictions contextRestrictions = const Restrictions(),
    PlayOrigin playOrigin = const PlayOrigin(),
    ContextIndex? index,
    ContextTrack? track,
    String? playbackId,
    String? sessionCommandId,
    Format? format,
    PlaybackQuality? playbackQuality,
    SleepTimer? sleepTimer,
    double? playbackSpeed,
    int? positionAsOfTimestamp,
    int? duration,
    bool isPlaying = false,
    bool isPaused = false,
    bool isBuffering = false,
    bool isSystemInitiated = false,
    PlayerOptions options = const PlayerOptions(),
    Restrictions restrictions = const Restrictions(),
    Suppressions suppressions = Suppressions.empty,
    List<ContextTrack> prevTracks = const <ContextTrack>[],
    List<ContextTrack> nextTracks = const <ContextTrack>[],
    Map<String, String> contextMetadata = const <String, String>{},
    Map<String, String> pageMetadata = const <String, String>{},
    String sessionId = '',
    String queueRevision = '0',
    AudioStream audioStream = AudioStream.defaultStream,
    List<String> signals = const <String>[],
    AdBreakContext? adBreakContext,
  })  : _timestamp = timestamp,
        _contextUri = contextUri,
        _contextUrl = contextUrl,
        _contextRestrictions = contextRestrictions,
        _playOrigin = playOrigin,
        _index = index,
        _track = track,
        _playbackId = playbackId,
        _sessionCommandId = sessionCommandId,
        _format = format,
        _playbackQuality = playbackQuality,
        _sleepTimer = sleepTimer,
        _playbackSpeed = playbackSpeed,
        _positionAsOfTimestamp = positionAsOfTimestamp,
        _duration = duration,
        _isPlaying = isPlaying,
        _isPaused = isPaused,
        _isBuffering = isBuffering,
        _isSystemInitiated = isSystemInitiated,
        _options = options,
        _restrictions = restrictions,
        _suppressions = suppressions,
        _prevTracks = List<ContextTrack>.from(prevTracks),
        _nextTracks = List<ContextTrack>.from(nextTracks),
        _contextMetadata = Map<String, String>.from(contextMetadata),
        _pageMetadata = Map<String, String>.from(pageMetadata),
        _sessionId = sessionId,
        _queueRevision = queueRevision,
        _audioStream = audioStream,
        _signals = List<String>.from(signals),
        _adBreakContext = adBreakContext;

  static PlayerStateBuilder builder() => PlayerState.builder();

  PlayerStateBuilder timestamp(int val) {
    _timestamp = val;
    return this;
  }

  PlayerStateBuilder contextUri(String val) {
    _contextUri = val;
    return this;
  }

  PlayerStateBuilder contextUrl(String val) {
    _contextUrl = val;
    return this;
  }

  PlayerStateBuilder contextRestrictions(Restrictions val) {
    _contextRestrictions = val;
    return this;
  }

  PlayerStateBuilder playOrigin(PlayOrigin val) {
    _playOrigin = val;
    return this;
  }

  PlayerStateBuilder index(ContextIndex? val) {
    _index = val;
    return this;
  }

  PlayerStateBuilder track(ContextTrack? val) {
    _track = val;
    return this;
  }

  PlayerStateBuilder playbackId(String? val) {
    _playbackId = val;
    return this;
  }

  PlayerStateBuilder sessionCommandId(String? val) {
    _sessionCommandId = val;
    return this;
  }

  PlayerStateBuilder format(Format? val) {
    _format = val;
    return this;
  }

  PlayerStateBuilder playbackQuality(PlaybackQuality? val) {
    _playbackQuality = val;
    return this;
  }

  PlayerStateBuilder sleepTimer(SleepTimer? val) {
    _sleepTimer = val;
    return this;
  }

  PlayerStateBuilder playbackSpeed(double? val) {
    _playbackSpeed = val;
    return this;
  }

  PlayerStateBuilder positionAsOfTimestamp(int? val) {
    _positionAsOfTimestamp = val;
    return this;
  }

  PlayerStateBuilder duration(int? val) {
    _duration = val;
    return this;
  }

  PlayerStateBuilder isPlaying(bool val) {
    _isPlaying = val;
    return this;
  }

  PlayerStateBuilder isPaused(bool val) {
    _isPaused = val;
    return this;
  }

  PlayerStateBuilder isBuffering(bool val) {
    _isBuffering = val;
    return this;
  }

  PlayerStateBuilder isSystemInitiated(bool val) {
    _isSystemInitiated = val;
    return this;
  }

  PlayerStateBuilder options(PlayerOptions val) {
    _options = val;
    return this;
  }

  PlayerStateBuilder restrictions(Restrictions val) {
    _restrictions = val;
    return this;
  }

  PlayerStateBuilder suppressions(Suppressions val) {
    _suppressions = val;
    return this;
  }

  PlayerStateBuilder prevTracks(List<ContextTrack> val) {
    _prevTracks = List<ContextTrack>.from(val);
    return this;
  }

  PlayerStateBuilder nextTracks(List<ContextTrack> val) {
    _nextTracks = List<ContextTrack>.from(val);
    return this;
  }

  PlayerStateBuilder contextMetadata(Map<String, String> val) {
    _contextMetadata = Map<String, String>.from(val);
    return this;
  }

  PlayerStateBuilder pageMetadata(Map<String, String> val) {
    _pageMetadata = Map<String, String>.from(val);
    return this;
  }

  PlayerStateBuilder sessionId(String val) {
    _sessionId = val;
    return this;
  }

  PlayerStateBuilder queueRevision(String val) {
    _queueRevision = val;
    return this;
  }

  PlayerStateBuilder audioStream(AudioStream val) {
    _audioStream = val;
    return this;
  }

  PlayerStateBuilder signals(List<String> val) {
    _signals = List<String>.from(val);
    return this;
  }

  PlayerStateBuilder adBreakContext(AdBreakContext? val) {
    _adBreakContext = val;
    return this;
  }

  PlayerState build() => PlayerState(
        timestamp: _timestamp,
        contextUri: _contextUri,
        contextUrl: _contextUrl,
        contextRestrictions: _contextRestrictions,
        playOrigin: _playOrigin,
        index: _index,
        track: _track,
        playbackId: _playbackId,
        sessionCommandId: _sessionCommandId,
        format: _format,
        playbackQuality: _playbackQuality,
        sleepTimer: _sleepTimer,
        playbackSpeed: _playbackSpeed,
        positionAsOfTimestamp: _positionAsOfTimestamp,
        duration: _duration,
        isPlaying: _isPlaying,
        isPaused: _isPaused,
        isBuffering: _isBuffering,
        isSystemInitiated: _isSystemInitiated,
        options: _options,
        restrictions: _restrictions,
        suppressions: _suppressions,
        prevTracks: List<ContextTrack>.unmodifiable(_prevTracks),
        nextTracks: List<ContextTrack>.unmodifiable(_nextTracks),
        contextMetadata: Map<String, String>.unmodifiable(_contextMetadata),
        pageMetadata: Map<String, String>.unmodifiable(_pageMetadata),
        sessionId: _sessionId,
        queueRevision: _queueRevision,
        audioStream: _audioStream,
        signals: List<String>.unmodifiable(_signals),
        adBreakContext: _adBreakContext,
      );
}
