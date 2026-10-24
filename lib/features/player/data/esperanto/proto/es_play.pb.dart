// This is a generated file - do not edit.
//
// Generated from es_play.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'es_command_options.pb.dart' as $2;
import 'es_logging_params.pb.dart' as $3;
import 'es_play_options.pb.dart' as $1;
import 'es_prepare_play.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class PlayRequest extends $pb.GeneratedMessage {
  factory PlayRequest({
    $0.PreparePlayRequest? preparePlayRequest,
    $1.PlayOptions? playOptions,
    $2.CommandOptions? options,
    $3.LoggingParams? loggingParams,
  }) {
    final result = PlayRequest._();
    if (preparePlayRequest != null)
      result.preparePlayRequest = preparePlayRequest;
    if (playOptions != null) result.playOptions = playOptions;
    if (options != null) result.options = options;
    if (loggingParams != null) result.loggingParams = loggingParams;
    return result;
  }

  PlayRequest._();

  factory PlayRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayRequest()..mergeFromBuffer(data, registry);
  factory PlayRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: PlayRequest.$_createMessage)
    ..aOM<$0.PreparePlayRequest>(1, _omitFieldNames ? '' : 'preparePlayRequest',
        subBuilder: $0.PreparePlayRequest.$_createMessage)
    ..aOM<$1.PlayOptions>(2, _omitFieldNames ? '' : 'playOptions',
        subBuilder: $1.PlayOptions.$_createMessage)
    ..aOM<$2.CommandOptions>(3, _omitFieldNames ? '' : 'options',
        subBuilder: $2.CommandOptions.$_createMessage)
    ..aOM<$3.LoggingParams>(4, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $3.LoggingParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayRequest copyWith(void Function(PlayRequest) updates) =>
      super.copyWith((message) => updates(message as PlayRequest))
          as PlayRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PlayRequest() / PlayRequest.new instead')
  static PlayRequest create() => PlayRequest._();
  static $pb.GeneratedMessage $_createMessage() => PlayRequest._();
  @$core.override
  PlayRequest createEmptyInstance() => PlayRequest._();
  @$core.pragma('dart2js:noInline')
  static PlayRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PlayRequest>(
          PlayRequest.$_createMessage);
  static PlayRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $0.PreparePlayRequest get preparePlayRequest => $_getN(0);
  @$pb.TagNumber(1)
  set preparePlayRequest($0.PreparePlayRequest value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPreparePlayRequest() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreparePlayRequest() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.PreparePlayRequest ensurePreparePlayRequest() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.PlayOptions get playOptions => $_getN(1);
  @$pb.TagNumber(2)
  set playOptions($1.PlayOptions value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPlayOptions() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlayOptions() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.PlayOptions ensurePlayOptions() => $_ensure(1);

  @$pb.TagNumber(3)
  $2.CommandOptions get options => $_getN(2);
  @$pb.TagNumber(3)
  set options($2.CommandOptions value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOptions() => $_has(2);
  @$pb.TagNumber(3)
  void clearOptions() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.CommandOptions ensureOptions() => $_ensure(2);

  @$pb.TagNumber(4)
  $3.LoggingParams get loggingParams => $_getN(3);
  @$pb.TagNumber(4)
  set loggingParams($3.LoggingParams value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasLoggingParams() => $_has(3);
  @$pb.TagNumber(4)
  void clearLoggingParams() => $_clearField(4);
  @$pb.TagNumber(4)
  $3.LoggingParams ensureLoggingParams() => $_ensure(3);
}

class PlayPreparedRequest extends $pb.GeneratedMessage {
  factory PlayPreparedRequest({
    $core.String? sessionId,
    $1.PlayOptions? playOptions,
    $2.CommandOptions? options,
    $3.LoggingParams? loggingParams,
  }) {
    final result = PlayPreparedRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (playOptions != null) result.playOptions = playOptions;
    if (options != null) result.options = options;
    if (loggingParams != null) result.loggingParams = loggingParams;
    return result;
  }

  PlayPreparedRequest._();

  factory PlayPreparedRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayPreparedRequest()..mergeFromBuffer(data, registry);
  factory PlayPreparedRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayPreparedRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayPreparedRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: PlayPreparedRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$1.PlayOptions>(2, _omitFieldNames ? '' : 'playOptions',
        subBuilder: $1.PlayOptions.$_createMessage)
    ..aOM<$2.CommandOptions>(3, _omitFieldNames ? '' : 'options',
        subBuilder: $2.CommandOptions.$_createMessage)
    ..aOM<$3.LoggingParams>(4, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $3.LoggingParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayPreparedRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayPreparedRequest copyWith(void Function(PlayPreparedRequest) updates) =>
      super.copyWith((message) => updates(message as PlayPreparedRequest))
          as PlayPreparedRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use PlayPreparedRequest() / PlayPreparedRequest.new instead')
  static PlayPreparedRequest create() => PlayPreparedRequest._();
  static $pb.GeneratedMessage $_createMessage() => PlayPreparedRequest._();
  @$core.override
  PlayPreparedRequest createEmptyInstance() => PlayPreparedRequest._();
  @$core.pragma('dart2js:noInline')
  static PlayPreparedRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlayPreparedRequest>(
          PlayPreparedRequest.$_createMessage);
  static PlayPreparedRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.PlayOptions get playOptions => $_getN(1);
  @$pb.TagNumber(2)
  set playOptions($1.PlayOptions value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPlayOptions() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlayOptions() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.PlayOptions ensurePlayOptions() => $_ensure(1);

  @$pb.TagNumber(3)
  $2.CommandOptions get options => $_getN(2);
  @$pb.TagNumber(3)
  set options($2.CommandOptions value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOptions() => $_has(2);
  @$pb.TagNumber(3)
  void clearOptions() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.CommandOptions ensureOptions() => $_ensure(2);

  @$pb.TagNumber(4)
  $3.LoggingParams get loggingParams => $_getN(3);
  @$pb.TagNumber(4)
  set loggingParams($3.LoggingParams value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasLoggingParams() => $_has(3);
  @$pb.TagNumber(4)
  void clearLoggingParams() => $_clearField(4);
  @$pb.TagNumber(4)
  $3.LoggingParams ensureLoggingParams() => $_ensure(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
