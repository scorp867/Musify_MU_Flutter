// This is a generated file - do not edit.
//
// Generated from es_set_sleep_timer_request.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'es_command_options.pb.dart' as $0;
import 'es_logging_params.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SetSleepTimerRequest_Clear extends $pb.GeneratedMessage {
  factory SetSleepTimerRequest_Clear() => SetSleepTimerRequest_Clear._();

  SetSleepTimerRequest_Clear._();

  factory SetSleepTimerRequest_Clear.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSleepTimerRequest_Clear()..mergeFromBuffer(data, registry);
  factory SetSleepTimerRequest_Clear.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSleepTimerRequest_Clear()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSleepTimerRequest.Clear',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: SetSleepTimerRequest_Clear.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSleepTimerRequest_Clear clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSleepTimerRequest_Clear copyWith(
          void Function(SetSleepTimerRequest_Clear) updates) =>
      super.copyWith(
              (message) => updates(message as SetSleepTimerRequest_Clear))
          as SetSleepTimerRequest_Clear;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetSleepTimerRequest_Clear() / SetSleepTimerRequest_Clear.new instead')
  static SetSleepTimerRequest_Clear create() => SetSleepTimerRequest_Clear._();
  static $pb.GeneratedMessage $_createMessage() =>
      SetSleepTimerRequest_Clear._();
  @$core.override
  SetSleepTimerRequest_Clear createEmptyInstance() =>
      SetSleepTimerRequest_Clear._();
  @$core.pragma('dart2js:noInline')
  static SetSleepTimerRequest_Clear getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetSleepTimerRequest_Clear>(
          SetSleepTimerRequest_Clear.$_createMessage);
  static SetSleepTimerRequest_Clear? _defaultInstance;
}

class SetSleepTimerRequest_Duration extends $pb.GeneratedMessage {
  factory SetSleepTimerRequest_Duration({
    $fixnum.Int64? seconds,
  }) {
    final result = SetSleepTimerRequest_Duration._();
    if (seconds != null) result.seconds = seconds;
    return result;
  }

  SetSleepTimerRequest_Duration._();

  factory SetSleepTimerRequest_Duration.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSleepTimerRequest_Duration()..mergeFromBuffer(data, registry);
  factory SetSleepTimerRequest_Duration.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSleepTimerRequest_Duration()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSleepTimerRequest.Duration',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: SetSleepTimerRequest_Duration.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'seconds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSleepTimerRequest_Duration clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSleepTimerRequest_Duration copyWith(
          void Function(SetSleepTimerRequest_Duration) updates) =>
      super.copyWith(
              (message) => updates(message as SetSleepTimerRequest_Duration))
          as SetSleepTimerRequest_Duration;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetSleepTimerRequest_Duration() / SetSleepTimerRequest_Duration.new instead')
  static SetSleepTimerRequest_Duration create() =>
      SetSleepTimerRequest_Duration._();
  static $pb.GeneratedMessage $_createMessage() =>
      SetSleepTimerRequest_Duration._();
  @$core.override
  SetSleepTimerRequest_Duration createEmptyInstance() =>
      SetSleepTimerRequest_Duration._();
  @$core.pragma('dart2js:noInline')
  static SetSleepTimerRequest_Duration getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetSleepTimerRequest_Duration>(
          SetSleepTimerRequest_Duration.$_createMessage);
  static SetSleepTimerRequest_Duration? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get seconds => $_getI64(0);
  @$pb.TagNumber(1)
  set seconds($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSeconds() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeconds() => $_clearField(1);
}

class SetSleepTimerRequest_EndOfTrack extends $pb.GeneratedMessage {
  factory SetSleepTimerRequest_EndOfTrack() =>
      SetSleepTimerRequest_EndOfTrack._();

  SetSleepTimerRequest_EndOfTrack._();

  factory SetSleepTimerRequest_EndOfTrack.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSleepTimerRequest_EndOfTrack()..mergeFromBuffer(data, registry);
  factory SetSleepTimerRequest_EndOfTrack.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSleepTimerRequest_EndOfTrack()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSleepTimerRequest.EndOfTrack',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: SetSleepTimerRequest_EndOfTrack.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSleepTimerRequest_EndOfTrack clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSleepTimerRequest_EndOfTrack copyWith(
          void Function(SetSleepTimerRequest_EndOfTrack) updates) =>
      super.copyWith(
              (message) => updates(message as SetSleepTimerRequest_EndOfTrack))
          as SetSleepTimerRequest_EndOfTrack;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetSleepTimerRequest_EndOfTrack() / SetSleepTimerRequest_EndOfTrack.new instead')
  static SetSleepTimerRequest_EndOfTrack create() =>
      SetSleepTimerRequest_EndOfTrack._();
  static $pb.GeneratedMessage $_createMessage() =>
      SetSleepTimerRequest_EndOfTrack._();
  @$core.override
  SetSleepTimerRequest_EndOfTrack createEmptyInstance() =>
      SetSleepTimerRequest_EndOfTrack._();
  @$core.pragma('dart2js:noInline')
  static SetSleepTimerRequest_EndOfTrack getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetSleepTimerRequest_EndOfTrack>(
          SetSleepTimerRequest_EndOfTrack.$_createMessage);
  static SetSleepTimerRequest_EndOfTrack? _defaultInstance;
}

enum SetSleepTimerRequest_TimerType { clear_3, duration, endOfTrack, notSet }

class SetSleepTimerRequest extends $pb.GeneratedMessage {
  factory SetSleepTimerRequest({
    $0.CommandOptions? options,
    $1.LoggingParams? loggingParams,
    SetSleepTimerRequest_Clear? clear_3,
    SetSleepTimerRequest_Duration? duration,
    SetSleepTimerRequest_EndOfTrack? endOfTrack,
  }) {
    final result = SetSleepTimerRequest._();
    if (options != null) result.options = options;
    if (loggingParams != null) result.loggingParams = loggingParams;
    if (clear_3 != null) result.clear_3 = clear_3;
    if (duration != null) result.duration = duration;
    if (endOfTrack != null) result.endOfTrack = endOfTrack;
    return result;
  }

  SetSleepTimerRequest._();

  factory SetSleepTimerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSleepTimerRequest()..mergeFromBuffer(data, registry);
  factory SetSleepTimerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSleepTimerRequest()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SetSleepTimerRequest_TimerType>
      _SetSleepTimerRequest_TimerTypeByTag = {
    3: SetSleepTimerRequest_TimerType.clear_3,
    4: SetSleepTimerRequest_TimerType.duration,
    5: SetSleepTimerRequest_TimerType.endOfTrack,
    0: SetSleepTimerRequest_TimerType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSleepTimerRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: SetSleepTimerRequest.$_createMessage)
    ..oo(0, [3, 4, 5])
    ..aOM<$0.CommandOptions>(1, _omitFieldNames ? '' : 'options',
        subBuilder: $0.CommandOptions.$_createMessage)
    ..aOM<$1.LoggingParams>(2, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..aOM<SetSleepTimerRequest_Clear>(3, _omitFieldNames ? '' : 'clear',
        subBuilder: SetSleepTimerRequest_Clear.$_createMessage)
    ..aOM<SetSleepTimerRequest_Duration>(4, _omitFieldNames ? '' : 'duration',
        subBuilder: SetSleepTimerRequest_Duration.$_createMessage)
    ..aOM<SetSleepTimerRequest_EndOfTrack>(
        5, _omitFieldNames ? '' : 'endOfTrack',
        subBuilder: SetSleepTimerRequest_EndOfTrack.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSleepTimerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSleepTimerRequest copyWith(void Function(SetSleepTimerRequest) updates) =>
      super.copyWith((message) => updates(message as SetSleepTimerRequest))
          as SetSleepTimerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetSleepTimerRequest() / SetSleepTimerRequest.new instead')
  static SetSleepTimerRequest create() => SetSleepTimerRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetSleepTimerRequest._();
  @$core.override
  SetSleepTimerRequest createEmptyInstance() => SetSleepTimerRequest._();
  @$core.pragma('dart2js:noInline')
  static SetSleepTimerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetSleepTimerRequest>(
          SetSleepTimerRequest.$_createMessage);
  static SetSleepTimerRequest? _defaultInstance;

  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  SetSleepTimerRequest_TimerType whichTimerType() =>
      _SetSleepTimerRequest_TimerTypeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  void clearTimerType() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.CommandOptions get options => $_getN(0);
  @$pb.TagNumber(1)
  set options($0.CommandOptions value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOptions() => $_has(0);
  @$pb.TagNumber(1)
  void clearOptions() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.CommandOptions ensureOptions() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.LoggingParams get loggingParams => $_getN(1);
  @$pb.TagNumber(2)
  set loggingParams($1.LoggingParams value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLoggingParams() => $_has(1);
  @$pb.TagNumber(2)
  void clearLoggingParams() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.LoggingParams ensureLoggingParams() => $_ensure(1);

  @$pb.TagNumber(3)
  SetSleepTimerRequest_Clear get clear_3 => $_getN(2);
  @$pb.TagNumber(3)
  set clear_3(SetSleepTimerRequest_Clear value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasClear_3() => $_has(2);
  @$pb.TagNumber(3)
  void clearClear_3() => $_clearField(3);
  @$pb.TagNumber(3)
  SetSleepTimerRequest_Clear ensureClear_3() => $_ensure(2);

  @$pb.TagNumber(4)
  SetSleepTimerRequest_Duration get duration => $_getN(3);
  @$pb.TagNumber(4)
  set duration(SetSleepTimerRequest_Duration value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasDuration() => $_has(3);
  @$pb.TagNumber(4)
  void clearDuration() => $_clearField(4);
  @$pb.TagNumber(4)
  SetSleepTimerRequest_Duration ensureDuration() => $_ensure(3);

  @$pb.TagNumber(5)
  SetSleepTimerRequest_EndOfTrack get endOfTrack => $_getN(4);
  @$pb.TagNumber(5)
  set endOfTrack(SetSleepTimerRequest_EndOfTrack value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasEndOfTrack() => $_has(4);
  @$pb.TagNumber(5)
  void clearEndOfTrack() => $_clearField(5);
  @$pb.TagNumber(5)
  SetSleepTimerRequest_EndOfTrack ensureEndOfTrack() => $_ensure(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
