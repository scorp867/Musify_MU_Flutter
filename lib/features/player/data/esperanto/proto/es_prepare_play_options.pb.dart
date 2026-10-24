// This is a generated file - do not edit.
//
// Generated from es_prepare_play_options.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'es_context_player_options.pb.dart' as $2;
import 'es_optional.pb.dart' as $1;
import 'es_prepare_play_options.pbenum.dart';
import 'es_skip_to_track.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'es_prepare_play_options.pbenum.dart';

class PreparePlayOptions extends $pb.GeneratedMessage {
  factory PreparePlayOptions({
    $core.List<$core.int>? playbackId,
    $core.bool? alwaysPlaySomething,
    $0.SkipToTrack? skipTo,
    $1.OptionalInt64? seekTo,
    $core.bool? initiallyPaused,
    $core.bool? systemInitiated,
    $2.ContextPlayerOptionOverrides? playerOptionsOverride,
    $core.Iterable<$core.String>? suppressions,
    PreparePlayOptions_PrefetchLevel? prefetchLevel,
    PreparePlayOptions_AudioStream? audioStream,
    $core.String? sessionId,
    $core.String? license,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>?
        configurationOverride,
  }) {
    final result = PreparePlayOptions._();
    if (playbackId != null) result.playbackId = playbackId;
    if (alwaysPlaySomething != null)
      result.alwaysPlaySomething = alwaysPlaySomething;
    if (skipTo != null) result.skipTo = skipTo;
    if (seekTo != null) result.seekTo = seekTo;
    if (initiallyPaused != null) result.initiallyPaused = initiallyPaused;
    if (systemInitiated != null) result.systemInitiated = systemInitiated;
    if (playerOptionsOverride != null)
      result.playerOptionsOverride = playerOptionsOverride;
    if (suppressions != null) result.suppressions.addAll(suppressions);
    if (prefetchLevel != null) result.prefetchLevel = prefetchLevel;
    if (audioStream != null) result.audioStream = audioStream;
    if (sessionId != null) result.sessionId = sessionId;
    if (license != null) result.license = license;
    if (configurationOverride != null)
      result.configurationOverride.addEntries(configurationOverride);
    return result;
  }

  PreparePlayOptions._();

  factory PreparePlayOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreparePlayOptions()..mergeFromBuffer(data, registry);
  factory PreparePlayOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreparePlayOptions()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreparePlayOptions',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: PreparePlayOptions.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'playbackId', $pb.PbFieldType.OY)
    ..aOB(2, _omitFieldNames ? '' : 'alwaysPlaySomething')
    ..aOM<$0.SkipToTrack>(3, _omitFieldNames ? '' : 'skipTo',
        subBuilder: $0.SkipToTrack.$_createMessage)
    ..aOM<$1.OptionalInt64>(4, _omitFieldNames ? '' : 'seekTo',
        subBuilder: $1.OptionalInt64.$_createMessage)
    ..aOB(5, _omitFieldNames ? '' : 'initiallyPaused')
    ..aOB(6, _omitFieldNames ? '' : 'systemInitiated')
    ..aOM<$2.ContextPlayerOptionOverrides>(
        7, _omitFieldNames ? '' : 'playerOptionsOverride',
        subBuilder: $2.ContextPlayerOptionOverrides.$_createMessage)
    ..pPS(8, _omitFieldNames ? '' : 'suppressions')
    ..aE<PreparePlayOptions_PrefetchLevel>(
        9, _omitFieldNames ? '' : 'prefetchLevel',
        enumValues: PreparePlayOptions_PrefetchLevel.values)
    ..aE<PreparePlayOptions_AudioStream>(
        10, _omitFieldNames ? '' : 'audioStream',
        enumValues: PreparePlayOptions_AudioStream.values)
    ..aOS(11, _omitFieldNames ? '' : 'sessionId')
    ..aOS(12, _omitFieldNames ? '' : 'license')
    ..m<$core.String, $core.String>(
        13, _omitFieldNames ? '' : 'configurationOverride',
        entryClassName: 'PreparePlayOptions.ConfigurationOverrideEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('spotify.player.esperanto.proto'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreparePlayOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreparePlayOptions copyWith(void Function(PreparePlayOptions) updates) =>
      super.copyWith((message) => updates(message as PreparePlayOptions))
          as PreparePlayOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PreparePlayOptions() / PreparePlayOptions.new instead')
  static PreparePlayOptions create() => PreparePlayOptions._();
  static $pb.GeneratedMessage $_createMessage() => PreparePlayOptions._();
  @$core.override
  PreparePlayOptions createEmptyInstance() => PreparePlayOptions._();
  @$core.pragma('dart2js:noInline')
  static PreparePlayOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreparePlayOptions>(
          PreparePlayOptions.$_createMessage);
  static PreparePlayOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get playbackId => $_getN(0);
  @$pb.TagNumber(1)
  set playbackId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlaybackId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlaybackId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get alwaysPlaySomething => $_getBF(1);
  @$pb.TagNumber(2)
  set alwaysPlaySomething($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAlwaysPlaySomething() => $_has(1);
  @$pb.TagNumber(2)
  void clearAlwaysPlaySomething() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.SkipToTrack get skipTo => $_getN(2);
  @$pb.TagNumber(3)
  set skipTo($0.SkipToTrack value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSkipTo() => $_has(2);
  @$pb.TagNumber(3)
  void clearSkipTo() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.SkipToTrack ensureSkipTo() => $_ensure(2);

  @$pb.TagNumber(4)
  $1.OptionalInt64 get seekTo => $_getN(3);
  @$pb.TagNumber(4)
  set seekTo($1.OptionalInt64 value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSeekTo() => $_has(3);
  @$pb.TagNumber(4)
  void clearSeekTo() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.OptionalInt64 ensureSeekTo() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.bool get initiallyPaused => $_getBF(4);
  @$pb.TagNumber(5)
  set initiallyPaused($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasInitiallyPaused() => $_has(4);
  @$pb.TagNumber(5)
  void clearInitiallyPaused() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get systemInitiated => $_getBF(5);
  @$pb.TagNumber(6)
  set systemInitiated($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSystemInitiated() => $_has(5);
  @$pb.TagNumber(6)
  void clearSystemInitiated() => $_clearField(6);

  @$pb.TagNumber(7)
  $2.ContextPlayerOptionOverrides get playerOptionsOverride => $_getN(6);
  @$pb.TagNumber(7)
  set playerOptionsOverride($2.ContextPlayerOptionOverrides value) =>
      $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasPlayerOptionsOverride() => $_has(6);
  @$pb.TagNumber(7)
  void clearPlayerOptionsOverride() => $_clearField(7);
  @$pb.TagNumber(7)
  $2.ContextPlayerOptionOverrides ensurePlayerOptionsOverride() => $_ensure(6);

  @$pb.TagNumber(8)
  $pb.PbList<$core.String> get suppressions => $_getList(7);

  @$pb.TagNumber(9)
  PreparePlayOptions_PrefetchLevel get prefetchLevel => $_getN(8);
  @$pb.TagNumber(9)
  set prefetchLevel(PreparePlayOptions_PrefetchLevel value) =>
      $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasPrefetchLevel() => $_has(8);
  @$pb.TagNumber(9)
  void clearPrefetchLevel() => $_clearField(9);

  @$pb.TagNumber(10)
  PreparePlayOptions_AudioStream get audioStream => $_getN(9);
  @$pb.TagNumber(10)
  set audioStream(PreparePlayOptions_AudioStream value) =>
      $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasAudioStream() => $_has(9);
  @$pb.TagNumber(10)
  void clearAudioStream() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get sessionId => $_getSZ(10);
  @$pb.TagNumber(11)
  set sessionId($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasSessionId() => $_has(10);
  @$pb.TagNumber(11)
  void clearSessionId() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get license => $_getSZ(11);
  @$pb.TagNumber(12)
  set license($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasLicense() => $_has(11);
  @$pb.TagNumber(12)
  void clearLicense() => $_clearField(12);

  @$pb.TagNumber(13)
  $pb.PbMap<$core.String, $core.String> get configurationOverride =>
      $_getMap(12);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
