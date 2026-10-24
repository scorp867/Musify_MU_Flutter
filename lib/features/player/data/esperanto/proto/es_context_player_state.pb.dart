// This is a generated file - do not edit.
//
// Generated from es_context_player_state.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'es_context_player_options.pb.dart' as $4;
import 'es_context_player_state.pbenum.dart';
import 'es_optional.pb.dart' as $3;
import 'es_play_origin.pb.dart' as $1;
import 'es_prepare_play_options.pbenum.dart' as $5;
import 'es_provided_track.pb.dart' as $2;
import 'es_restrictions.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'es_context_player_state.pbenum.dart';

class ContextIndex extends $pb.GeneratedMessage {
  factory ContextIndex({
    $fixnum.Int64? page,
    $fixnum.Int64? track,
  }) {
    final result = ContextIndex._();
    if (page != null) result.page = page;
    if (track != null) result.track = track;
    return result;
  }

  ContextIndex._();

  factory ContextIndex.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContextIndex()..mergeFromBuffer(data, registry);
  factory ContextIndex.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContextIndex()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextIndex',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: ContextIndex.$_createMessage)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'page', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'track', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextIndex clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextIndex copyWith(void Function(ContextIndex) updates) =>
      super.copyWith((message) => updates(message as ContextIndex))
          as ContextIndex;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ContextIndex() / ContextIndex.new instead')
  static ContextIndex create() => ContextIndex._();
  static $pb.GeneratedMessage $_createMessage() => ContextIndex._();
  @$core.override
  ContextIndex createEmptyInstance() => ContextIndex._();
  @$core.pragma('dart2js:noInline')
  static ContextIndex getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ContextIndex>(
          ContextIndex.$_createMessage);
  static ContextIndex? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get page => $_getI64(0);
  @$pb.TagNumber(1)
  set page($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPage() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get track => $_getI64(1);
  @$pb.TagNumber(2)
  set track($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTrack() => $_has(1);
  @$pb.TagNumber(2)
  void clearTrack() => $_clearField(2);
}

class PlaybackQuality extends $pb.GeneratedMessage {
  factory PlaybackQuality({
    PlaybackQuality_BitrateLevel? bitrateLevel,
    PlaybackQuality_BitrateStrategy? strategy,
    PlaybackQuality_BitrateLevel? targetBitrateLevel,
    $core.bool? targetBitrateAvailable,
    PlaybackQuality_HiFiStatus? hifiStatus,
  }) {
    final result = PlaybackQuality._();
    if (bitrateLevel != null) result.bitrateLevel = bitrateLevel;
    if (strategy != null) result.strategy = strategy;
    if (targetBitrateLevel != null)
      result.targetBitrateLevel = targetBitrateLevel;
    if (targetBitrateAvailable != null)
      result.targetBitrateAvailable = targetBitrateAvailable;
    if (hifiStatus != null) result.hifiStatus = hifiStatus;
    return result;
  }

  PlaybackQuality._();

  factory PlaybackQuality.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaybackQuality()..mergeFromBuffer(data, registry);
  factory PlaybackQuality.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaybackQuality()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlaybackQuality',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: PlaybackQuality.$_createMessage)
    ..aE<PlaybackQuality_BitrateLevel>(1, _omitFieldNames ? '' : 'bitrateLevel',
        enumValues: PlaybackQuality_BitrateLevel.values)
    ..aE<PlaybackQuality_BitrateStrategy>(2, _omitFieldNames ? '' : 'strategy',
        enumValues: PlaybackQuality_BitrateStrategy.values)
    ..aE<PlaybackQuality_BitrateLevel>(
        3, _omitFieldNames ? '' : 'targetBitrateLevel',
        enumValues: PlaybackQuality_BitrateLevel.values)
    ..aOB(4, _omitFieldNames ? '' : 'targetBitrateAvailable')
    ..aE<PlaybackQuality_HiFiStatus>(5, _omitFieldNames ? '' : 'hifiStatus',
        enumValues: PlaybackQuality_HiFiStatus.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlaybackQuality clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlaybackQuality copyWith(void Function(PlaybackQuality) updates) =>
      super.copyWith((message) => updates(message as PlaybackQuality))
          as PlaybackQuality;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PlaybackQuality() / PlaybackQuality.new instead')
  static PlaybackQuality create() => PlaybackQuality._();
  static $pb.GeneratedMessage $_createMessage() => PlaybackQuality._();
  @$core.override
  PlaybackQuality createEmptyInstance() => PlaybackQuality._();
  @$core.pragma('dart2js:noInline')
  static PlaybackQuality getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PlaybackQuality>(
          PlaybackQuality.$_createMessage);
  static PlaybackQuality? _defaultInstance;

  @$pb.TagNumber(1)
  PlaybackQuality_BitrateLevel get bitrateLevel => $_getN(0);
  @$pb.TagNumber(1)
  set bitrateLevel(PlaybackQuality_BitrateLevel value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBitrateLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearBitrateLevel() => $_clearField(1);

  @$pb.TagNumber(2)
  PlaybackQuality_BitrateStrategy get strategy => $_getN(1);
  @$pb.TagNumber(2)
  set strategy(PlaybackQuality_BitrateStrategy value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStrategy() => $_has(1);
  @$pb.TagNumber(2)
  void clearStrategy() => $_clearField(2);

  @$pb.TagNumber(3)
  PlaybackQuality_BitrateLevel get targetBitrateLevel => $_getN(2);
  @$pb.TagNumber(3)
  set targetBitrateLevel(PlaybackQuality_BitrateLevel value) =>
      $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTargetBitrateLevel() => $_has(2);
  @$pb.TagNumber(3)
  void clearTargetBitrateLevel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get targetBitrateAvailable => $_getBF(3);
  @$pb.TagNumber(4)
  set targetBitrateAvailable($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTargetBitrateAvailable() => $_has(3);
  @$pb.TagNumber(4)
  void clearTargetBitrateAvailable() => $_clearField(4);

  @$pb.TagNumber(5)
  PlaybackQuality_HiFiStatus get hifiStatus => $_getN(4);
  @$pb.TagNumber(5)
  set hifiStatus(PlaybackQuality_HiFiStatus value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasHifiStatus() => $_has(4);
  @$pb.TagNumber(5)
  void clearHifiStatus() => $_clearField(5);
}

class ContextPlayerState extends $pb.GeneratedMessage {
  factory ContextPlayerState({
    $fixnum.Int64? timestamp,
    $core.String? contextUri,
    $core.String? contextUrl,
    $0.Restrictions? contextRestrictions,
    $1.PlayOrigin? playOrigin,
    ContextIndex? index,
    $2.ProvidedTrack? track,
    $core.List<$core.int>? playbackId,
    PlaybackQuality? playbackQuality,
    $3.OptionalDouble? playbackSpeed,
    $3.OptionalInt64? positionAsOfTimestamp,
    $3.OptionalInt64? duration,
    $core.bool? isPlaying,
    $core.bool? isPaused,
    $core.bool? isBuffering,
    $core.bool? isSystemInitiated,
    $4.ContextPlayerOptions? options,
    $0.Restrictions? restrictions,
    $core.Iterable<$core.String>? suppressions,
    $core.Iterable<$2.ProvidedTrack>? prevTracks,
    $core.Iterable<$2.ProvidedTrack>? nextTracks,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? contextMetadata,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? pageMetadata,
    $core.String? sessionId,
    $fixnum.Int64? queueRevision,
    $5.PreparePlayOptions_AudioStream? audioStream,
    $core.Iterable<$core.String>? signals,
    $core.String? sessionCommandId,
  }) {
    final result = ContextPlayerState._();
    if (timestamp != null) result.timestamp = timestamp;
    if (contextUri != null) result.contextUri = contextUri;
    if (contextUrl != null) result.contextUrl = contextUrl;
    if (contextRestrictions != null)
      result.contextRestrictions = contextRestrictions;
    if (playOrigin != null) result.playOrigin = playOrigin;
    if (index != null) result.index = index;
    if (track != null) result.track = track;
    if (playbackId != null) result.playbackId = playbackId;
    if (playbackQuality != null) result.playbackQuality = playbackQuality;
    if (playbackSpeed != null) result.playbackSpeed = playbackSpeed;
    if (positionAsOfTimestamp != null)
      result.positionAsOfTimestamp = positionAsOfTimestamp;
    if (duration != null) result.duration = duration;
    if (isPlaying != null) result.isPlaying = isPlaying;
    if (isPaused != null) result.isPaused = isPaused;
    if (isBuffering != null) result.isBuffering = isBuffering;
    if (isSystemInitiated != null) result.isSystemInitiated = isSystemInitiated;
    if (options != null) result.options = options;
    if (restrictions != null) result.restrictions = restrictions;
    if (suppressions != null) result.suppressions.addAll(suppressions);
    if (prevTracks != null) result.prevTracks.addAll(prevTracks);
    if (nextTracks != null) result.nextTracks.addAll(nextTracks);
    if (contextMetadata != null)
      result.contextMetadata.addEntries(contextMetadata);
    if (pageMetadata != null) result.pageMetadata.addEntries(pageMetadata);
    if (sessionId != null) result.sessionId = sessionId;
    if (queueRevision != null) result.queueRevision = queueRevision;
    if (audioStream != null) result.audioStream = audioStream;
    if (signals != null) result.signals.addAll(signals);
    if (sessionCommandId != null) result.sessionCommandId = sessionCommandId;
    return result;
  }

  ContextPlayerState._();

  factory ContextPlayerState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContextPlayerState()..mergeFromBuffer(data, registry);
  factory ContextPlayerState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContextPlayerState()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextPlayerState',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: ContextPlayerState.$_createMessage)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'timestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'contextUri')
    ..aOS(3, _omitFieldNames ? '' : 'contextUrl')
    ..aOM<$0.Restrictions>(4, _omitFieldNames ? '' : 'contextRestrictions',
        subBuilder: $0.Restrictions.$_createMessage)
    ..aOM<$1.PlayOrigin>(5, _omitFieldNames ? '' : 'playOrigin',
        subBuilder: $1.PlayOrigin.$_createMessage)
    ..aOM<ContextIndex>(6, _omitFieldNames ? '' : 'index',
        subBuilder: ContextIndex.$_createMessage)
    ..aOM<$2.ProvidedTrack>(7, _omitFieldNames ? '' : 'track',
        subBuilder: $2.ProvidedTrack.$_createMessage)
    ..a<$core.List<$core.int>>(
        8, _omitFieldNames ? '' : 'playbackId', $pb.PbFieldType.OY)
    ..aOM<PlaybackQuality>(9, _omitFieldNames ? '' : 'playbackQuality',
        subBuilder: PlaybackQuality.$_createMessage)
    ..aOM<$3.OptionalDouble>(10, _omitFieldNames ? '' : 'playbackSpeed',
        subBuilder: $3.OptionalDouble.$_createMessage)
    ..aOM<$3.OptionalInt64>(11, _omitFieldNames ? '' : 'positionAsOfTimestamp',
        subBuilder: $3.OptionalInt64.$_createMessage)
    ..aOM<$3.OptionalInt64>(12, _omitFieldNames ? '' : 'duration',
        subBuilder: $3.OptionalInt64.$_createMessage)
    ..aOB(13, _omitFieldNames ? '' : 'isPlaying')
    ..aOB(14, _omitFieldNames ? '' : 'isPaused')
    ..aOB(15, _omitFieldNames ? '' : 'isBuffering')
    ..aOB(16, _omitFieldNames ? '' : 'isSystemInitiated')
    ..aOM<$4.ContextPlayerOptions>(17, _omitFieldNames ? '' : 'options',
        subBuilder: $4.ContextPlayerOptions.$_createMessage)
    ..aOM<$0.Restrictions>(18, _omitFieldNames ? '' : 'restrictions',
        subBuilder: $0.Restrictions.$_createMessage)
    ..pPS(19, _omitFieldNames ? '' : 'suppressions')
    ..pPM<$2.ProvidedTrack>(20, _omitFieldNames ? '' : 'prevTracks',
        subBuilder: $2.ProvidedTrack.$_createMessage)
    ..pPM<$2.ProvidedTrack>(21, _omitFieldNames ? '' : 'nextTracks',
        subBuilder: $2.ProvidedTrack.$_createMessage)
    ..m<$core.String, $core.String>(
        22, _omitFieldNames ? '' : 'contextMetadata',
        entryClassName: 'ContextPlayerState.ContextMetadataEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('spotify.player.esperanto.proto'))
    ..m<$core.String, $core.String>(23, _omitFieldNames ? '' : 'pageMetadata',
        entryClassName: 'ContextPlayerState.PageMetadataEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('spotify.player.esperanto.proto'))
    ..aOS(24, _omitFieldNames ? '' : 'sessionId')
    ..a<$fixnum.Int64>(
        25, _omitFieldNames ? '' : 'queueRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<$5.PreparePlayOptions_AudioStream>(
        26, _omitFieldNames ? '' : 'audioStream',
        enumValues: $5.PreparePlayOptions_AudioStream.values)
    ..pPS(27, _omitFieldNames ? '' : 'signals')
    ..aOS(28, _omitFieldNames ? '' : 'sessionCommandId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextPlayerState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextPlayerState copyWith(void Function(ContextPlayerState) updates) =>
      super.copyWith((message) => updates(message as ContextPlayerState))
          as ContextPlayerState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ContextPlayerState() / ContextPlayerState.new instead')
  static ContextPlayerState create() => ContextPlayerState._();
  static $pb.GeneratedMessage $_createMessage() => ContextPlayerState._();
  @$core.override
  ContextPlayerState createEmptyInstance() => ContextPlayerState._();
  @$core.pragma('dart2js:noInline')
  static ContextPlayerState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContextPlayerState>(
          ContextPlayerState.$_createMessage);
  static ContextPlayerState? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestamp => $_getI64(0);
  @$pb.TagNumber(1)
  set timestamp($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestamp() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get contextUri => $_getSZ(1);
  @$pb.TagNumber(2)
  set contextUri($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContextUri() => $_has(1);
  @$pb.TagNumber(2)
  void clearContextUri() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get contextUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set contextUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContextUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearContextUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.Restrictions get contextRestrictions => $_getN(3);
  @$pb.TagNumber(4)
  set contextRestrictions($0.Restrictions value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasContextRestrictions() => $_has(3);
  @$pb.TagNumber(4)
  void clearContextRestrictions() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Restrictions ensureContextRestrictions() => $_ensure(3);

  @$pb.TagNumber(5)
  $1.PlayOrigin get playOrigin => $_getN(4);
  @$pb.TagNumber(5)
  set playOrigin($1.PlayOrigin value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPlayOrigin() => $_has(4);
  @$pb.TagNumber(5)
  void clearPlayOrigin() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.PlayOrigin ensurePlayOrigin() => $_ensure(4);

  @$pb.TagNumber(6)
  ContextIndex get index => $_getN(5);
  @$pb.TagNumber(6)
  set index(ContextIndex value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasIndex() => $_has(5);
  @$pb.TagNumber(6)
  void clearIndex() => $_clearField(6);
  @$pb.TagNumber(6)
  ContextIndex ensureIndex() => $_ensure(5);

  @$pb.TagNumber(7)
  $2.ProvidedTrack get track => $_getN(6);
  @$pb.TagNumber(7)
  set track($2.ProvidedTrack value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasTrack() => $_has(6);
  @$pb.TagNumber(7)
  void clearTrack() => $_clearField(7);
  @$pb.TagNumber(7)
  $2.ProvidedTrack ensureTrack() => $_ensure(6);

  @$pb.TagNumber(8)
  $core.List<$core.int> get playbackId => $_getN(7);
  @$pb.TagNumber(8)
  set playbackId($core.List<$core.int> value) => $_setBytes(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPlaybackId() => $_has(7);
  @$pb.TagNumber(8)
  void clearPlaybackId() => $_clearField(8);

  @$pb.TagNumber(9)
  PlaybackQuality get playbackQuality => $_getN(8);
  @$pb.TagNumber(9)
  set playbackQuality(PlaybackQuality value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasPlaybackQuality() => $_has(8);
  @$pb.TagNumber(9)
  void clearPlaybackQuality() => $_clearField(9);
  @$pb.TagNumber(9)
  PlaybackQuality ensurePlaybackQuality() => $_ensure(8);

  @$pb.TagNumber(10)
  $3.OptionalDouble get playbackSpeed => $_getN(9);
  @$pb.TagNumber(10)
  set playbackSpeed($3.OptionalDouble value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasPlaybackSpeed() => $_has(9);
  @$pb.TagNumber(10)
  void clearPlaybackSpeed() => $_clearField(10);
  @$pb.TagNumber(10)
  $3.OptionalDouble ensurePlaybackSpeed() => $_ensure(9);

  @$pb.TagNumber(11)
  $3.OptionalInt64 get positionAsOfTimestamp => $_getN(10);
  @$pb.TagNumber(11)
  set positionAsOfTimestamp($3.OptionalInt64 value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasPositionAsOfTimestamp() => $_has(10);
  @$pb.TagNumber(11)
  void clearPositionAsOfTimestamp() => $_clearField(11);
  @$pb.TagNumber(11)
  $3.OptionalInt64 ensurePositionAsOfTimestamp() => $_ensure(10);

  @$pb.TagNumber(12)
  $3.OptionalInt64 get duration => $_getN(11);
  @$pb.TagNumber(12)
  set duration($3.OptionalInt64 value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasDuration() => $_has(11);
  @$pb.TagNumber(12)
  void clearDuration() => $_clearField(12);
  @$pb.TagNumber(12)
  $3.OptionalInt64 ensureDuration() => $_ensure(11);

  @$pb.TagNumber(13)
  $core.bool get isPlaying => $_getBF(12);
  @$pb.TagNumber(13)
  set isPlaying($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasIsPlaying() => $_has(12);
  @$pb.TagNumber(13)
  void clearIsPlaying() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.bool get isPaused => $_getBF(13);
  @$pb.TagNumber(14)
  set isPaused($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasIsPaused() => $_has(13);
  @$pb.TagNumber(14)
  void clearIsPaused() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.bool get isBuffering => $_getBF(14);
  @$pb.TagNumber(15)
  set isBuffering($core.bool value) => $_setBool(14, value);
  @$pb.TagNumber(15)
  $core.bool hasIsBuffering() => $_has(14);
  @$pb.TagNumber(15)
  void clearIsBuffering() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.bool get isSystemInitiated => $_getBF(15);
  @$pb.TagNumber(16)
  set isSystemInitiated($core.bool value) => $_setBool(15, value);
  @$pb.TagNumber(16)
  $core.bool hasIsSystemInitiated() => $_has(15);
  @$pb.TagNumber(16)
  void clearIsSystemInitiated() => $_clearField(16);

  @$pb.TagNumber(17)
  $4.ContextPlayerOptions get options => $_getN(16);
  @$pb.TagNumber(17)
  set options($4.ContextPlayerOptions value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasOptions() => $_has(16);
  @$pb.TagNumber(17)
  void clearOptions() => $_clearField(17);
  @$pb.TagNumber(17)
  $4.ContextPlayerOptions ensureOptions() => $_ensure(16);

  @$pb.TagNumber(18)
  $0.Restrictions get restrictions => $_getN(17);
  @$pb.TagNumber(18)
  set restrictions($0.Restrictions value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasRestrictions() => $_has(17);
  @$pb.TagNumber(18)
  void clearRestrictions() => $_clearField(18);
  @$pb.TagNumber(18)
  $0.Restrictions ensureRestrictions() => $_ensure(17);

  @$pb.TagNumber(19)
  $pb.PbList<$core.String> get suppressions => $_getList(18);

  @$pb.TagNumber(20)
  $pb.PbList<$2.ProvidedTrack> get prevTracks => $_getList(19);

  @$pb.TagNumber(21)
  $pb.PbList<$2.ProvidedTrack> get nextTracks => $_getList(20);

  @$pb.TagNumber(22)
  $pb.PbMap<$core.String, $core.String> get contextMetadata => $_getMap(21);

  @$pb.TagNumber(23)
  $pb.PbMap<$core.String, $core.String> get pageMetadata => $_getMap(22);

  @$pb.TagNumber(24)
  $core.String get sessionId => $_getSZ(23);
  @$pb.TagNumber(24)
  set sessionId($core.String value) => $_setString(23, value);
  @$pb.TagNumber(24)
  $core.bool hasSessionId() => $_has(23);
  @$pb.TagNumber(24)
  void clearSessionId() => $_clearField(24);

  @$pb.TagNumber(25)
  $fixnum.Int64 get queueRevision => $_getI64(24);
  @$pb.TagNumber(25)
  set queueRevision($fixnum.Int64 value) => $_setInt64(24, value);
  @$pb.TagNumber(25)
  $core.bool hasQueueRevision() => $_has(24);
  @$pb.TagNumber(25)
  void clearQueueRevision() => $_clearField(25);

  @$pb.TagNumber(26)
  $5.PreparePlayOptions_AudioStream get audioStream => $_getN(25);
  @$pb.TagNumber(26)
  set audioStream($5.PreparePlayOptions_AudioStream value) =>
      $_setField(26, value);
  @$pb.TagNumber(26)
  $core.bool hasAudioStream() => $_has(25);
  @$pb.TagNumber(26)
  void clearAudioStream() => $_clearField(26);

  @$pb.TagNumber(27)
  $pb.PbList<$core.String> get signals => $_getList(26);

  @$pb.TagNumber(28)
  $core.String get sessionCommandId => $_getSZ(27);
  @$pb.TagNumber(28)
  set sessionCommandId($core.String value) => $_setString(27, value);
  @$pb.TagNumber(28)
  $core.bool hasSessionCommandId() => $_has(27);
  @$pb.TagNumber(28)
  void clearSessionCommandId() => $_clearField(28);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
