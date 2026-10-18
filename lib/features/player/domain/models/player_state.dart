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
  final Map<String, String> contextMetadata;
  final Restrictions contextRestrictions;
  final PlayOrigin playOrigin;
  final ContextIndex? index;
  final ContextTrack? track;
  final String? playbackId;
  final PlaybackQuality? playbackQuality;
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
  final Map<String, String> pageMetadata;
  final String sessionId;
  final String? sessionCommandId;
  final String queueRevision;
  final List<String> signals;
  final AudioStream audioStream;
  final Format? format;
  final AdBreakContext? adBreakContext;
  final SleepTimer? sleepTimer;

  const PlayerState({
    this.timestamp = 0,
    this.contextUri = '',
    this.contextUrl = '',
    this.contextMetadata = const <String, String>{},
    this.contextRestrictions = const Restrictions(),
    this.playOrigin = const PlayOrigin(),
    this.index,
    this.track,
    this.playbackId,
    this.playbackQuality,
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
    this.pageMetadata = const <String, String>{},
    this.sessionId = '',
    this.sessionCommandId,
    this.queueRevision = '0',
    this.signals = const <String>[],
    this.audioStream = AudioStream.defaultStream,
    this.format,
    this.adBreakContext,
    this.sleepTimer,
  });

  static PlayerStateBuilder builder() => PlayerStateBuilder();

  PlayerStateBuilder toBuilder() => PlayerStateBuilder(
        timestamp: timestamp,
        contextUri: contextUri,
        contextUrl: contextUrl,
        contextMetadata: contextMetadata,
        contextRestrictions: contextRestrictions,
        playOrigin: playOrigin,
        index: index,
        track: track,
        playbackId: playbackId,
        playbackQuality: playbackQuality,
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
        pageMetadata: pageMetadata,
        sessionId: sessionId,
        sessionCommandId: sessionCommandId,
        queueRevision: queueRevision,
        signals: signals,
        audioStream: audioStream,
        format: format,
        adBreakContext: adBreakContext,
        sleepTimer: sleepTimer,
      );

  int? position(int currentTimestamp) {
    if (positionAsOfTimestamp == null) {
      return null;
    }
    final speed = playbackSpeed ?? 0.0;
    final diff = currentTimestamp - timestamp;
    return positionAsOfTimestamp! + (speed * diff).round();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerState &&
          other.timestamp == timestamp &&
          other.contextUri == contextUri &&
          other.contextUrl == contextUrl &&
          other.isPlaying == isPlaying &&
          other.isPaused == isPaused &&
          other.isBuffering == isBuffering &&
          other.isSystemInitiated == isSystemInitiated &&
          other.playbackId == playbackId &&
          other.playbackSpeed == playbackSpeed &&
          other.positionAsOfTimestamp == positionAsOfTimestamp &&
          other.duration == duration &&
          other.sessionId == sessionId &&
          other.sessionCommandId == sessionCommandId &&
          other.queueRevision == queueRevision &&
          other.audioStream == audioStream &&
          other.format == format &&
          other.index == index &&
          other.track == track &&
          other.options == options &&
          other.restrictions == restrictions &&
          other.contextRestrictions == contextRestrictions &&
          other.playOrigin == playOrigin &&
          other.playbackQuality == playbackQuality &&
          other.suppressions == suppressions &&
          other.adBreakContext == adBreakContext &&
          other.sleepTimer == sleepTimer &&
          _listEquals(other.nextTracks, nextTracks) &&
          _listEquals(other.prevTracks, prevTracks) &&
          _listEquals(other.signals, signals) &&
          _mapEquals(other.contextMetadata, contextMetadata) &&
          _mapEquals(other.pageMetadata, pageMetadata));

  @override
  int get hashCode => Object.hashAll([
        timestamp,
        contextUri,
        contextUrl,
        isPlaying,
        isPaused,
        isBuffering,
        isSystemInitiated,
        playbackId,
        playbackSpeed,
        positionAsOfTimestamp,
        duration,
        sessionId,
        sessionCommandId,
        queueRevision,
        audioStream,
        format,
        index,
        track,
        options,
        restrictions,
      ]);

  @override
  String toString() =>
      'PlayerState{timestamp=$timestamp, contextUri=$contextUri, track=$track, isPlaying=$isPlaying, isPaused=$isPaused, isBuffering=$isBuffering, positionAsOfTimestamp=$positionAsOfTimestamp, duration=$duration, queueRevision=$queueRevision}';

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
  Map<String, String> _contextMetadata;
  Restrictions _contextRestrictions;
  PlayOrigin _playOrigin;
  ContextIndex? _index;
  ContextTrack? _track;
  String? _playbackId;
  PlaybackQuality? _playbackQuality;
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
  Map<String, String> _pageMetadata;
  String _sessionId;
  String? _sessionCommandId;
  String _queueRevision;
  List<String> _signals;
  AudioStream _audioStream;
  Format? _format;
  AdBreakContext? _adBreakContext;
  SleepTimer? _sleepTimer;

  PlayerStateBuilder({
    int timestamp = 0,
    String contextUri = '',
    String contextUrl = '',
    Map<String, String> contextMetadata = const <String, String>{},
    Restrictions contextRestrictions = const Restrictions(),
    PlayOrigin playOrigin = const PlayOrigin(),
    ContextIndex? index,
    ContextTrack? track,
    String? playbackId,
    PlaybackQuality? playbackQuality,
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
    Map<String, String> pageMetadata = const <String, String>{},
    String sessionId = '',
    String? sessionCommandId,
    String queueRevision = '0',
    List<String> signals = const <String>[],
    AudioStream audioStream = AudioStream.defaultStream,
    Format? format,
    AdBreakContext? adBreakContext,
    SleepTimer? sleepTimer,
  })  : _timestamp = timestamp,
        _contextUri = contextUri,
        _contextUrl = contextUrl,
        _contextMetadata = Map<String, String>.from(contextMetadata),
        _contextRestrictions = contextRestrictions,
        _playOrigin = playOrigin,
        _index = index,
        _track = track,
        _playbackId = playbackId,
        _playbackQuality = playbackQuality,
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
        _pageMetadata = Map<String, String>.from(pageMetadata),
        _sessionId = sessionId,
        _sessionCommandId = sessionCommandId,
        _queueRevision = queueRevision,
        _signals = List<String>.from(signals),
        _audioStream = audioStream,
        _format = format,
        _adBreakContext = adBreakContext,
        _sleepTimer = sleepTimer;

  PlayerStateBuilder timestamp(int val) { _timestamp = val; return this; }
  PlayerStateBuilder contextUri(String val) { _contextUri = val; return this; }
  PlayerStateBuilder contextUrl(String val) { _contextUrl = val; return this; }
  PlayerStateBuilder contextMetadata(Map<String, String> val) { _contextMetadata = Map.from(val); return this; }
  PlayerStateBuilder contextRestrictions(Restrictions val) { _contextRestrictions = val; return this; }
  PlayerStateBuilder playOrigin(PlayOrigin val) { _playOrigin = val; return this; }
  PlayerStateBuilder index(ContextIndex? val) { _index = val; return this; }
  PlayerStateBuilder track(ContextTrack? val) { _track = val; return this; }
  PlayerStateBuilder playbackId(String? val) { _playbackId = val; return this; }
  PlayerStateBuilder playbackQuality(PlaybackQuality? val) { _playbackQuality = val; return this; }
  PlayerStateBuilder playbackSpeed(double? val) { _playbackSpeed = val; return this; }
  PlayerStateBuilder positionAsOfTimestamp(int? val) { _positionAsOfTimestamp = val; return this; }
  PlayerStateBuilder duration(int? val) { _duration = val; return this; }
  PlayerStateBuilder isPlaying(bool val) { _isPlaying = val; return this; }
  PlayerStateBuilder isPaused(bool val) { _isPaused = val; return this; }
  PlayerStateBuilder isBuffering(bool val) { _isBuffering = val; return this; }
  PlayerStateBuilder isSystemInitiated(bool val) { _isSystemInitiated = val; return this; }
  PlayerStateBuilder options(PlayerOptions val) { _options = val; return this; }
  PlayerStateBuilder restrictions(Restrictions val) { _restrictions = val; return this; }
  PlayerStateBuilder suppressions(Suppressions val) { _suppressions = val; return this; }
  PlayerStateBuilder prevTracks(List<ContextTrack> val) { _prevTracks = List.from(val); return this; }
  PlayerStateBuilder nextTracks(List<ContextTrack> val) { _nextTracks = List.from(val); return this; }
  PlayerStateBuilder pageMetadata(Map<String, String> val) { _pageMetadata = Map.from(val); return this; }
  PlayerStateBuilder sessionId(String val) { _sessionId = val; return this; }
  PlayerStateBuilder sessionCommandId(String? val) { _sessionCommandId = val; return this; }
  PlayerStateBuilder queueRevision(String val) { _queueRevision = val; return this; }
  PlayerStateBuilder signals(List<String> val) { _signals = List.from(val); return this; }
  PlayerStateBuilder audioStream(AudioStream val) { _audioStream = val; return this; }
  PlayerStateBuilder format(Format? val) { _format = val; return this; }
  PlayerStateBuilder adBreakContext(AdBreakContext? val) { _adBreakContext = val; return this; }
  PlayerStateBuilder sleepTimer(SleepTimer? val) { _sleepTimer = val; return this; }

  PlayerState build() => PlayerState(
        timestamp: _timestamp,
        contextUri: _contextUri,
        contextUrl: _contextUrl,
        contextMetadata: Map.unmodifiable(_contextMetadata),
        contextRestrictions: _contextRestrictions,
        playOrigin: _playOrigin,
        index: _index,
        track: _track,
        playbackId: _playbackId,
        playbackQuality: _playbackQuality,
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
        prevTracks: List.unmodifiable(_prevTracks),
        nextTracks: List.unmodifiable(_nextTracks),
        pageMetadata: Map.unmodifiable(_pageMetadata),
        sessionId: _sessionId,
        sessionCommandId: _sessionCommandId,
        queueRevision: _queueRevision,
        signals: List.unmodifiable(_signals),
        audioStream: _audioStream,
        format: _format,
        adBreakContext: _adBreakContext,
        sleepTimer: _sleepTimer,
      );
}
