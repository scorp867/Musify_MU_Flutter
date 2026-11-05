// This is a generated file - do not edit.
//
// Generated from es_play_as_next_in_queue_request.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'es_command_options.pb.dart' as $1;
import 'es_context_track.pb.dart' as $0;
import 'es_logging_params.pb.dart' as $2;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class PlayAsNextInQueueRequest extends $pb.GeneratedMessage {
  factory PlayAsNextInQueueRequest({
    $core.Iterable<$0.ContextTrack>? tracks,
    $1.CommandOptions? options,
    $2.LoggingParams? loggingParams,
  }) {
    final result = PlayAsNextInQueueRequest._();
    if (tracks != null) result.tracks.addAll(tracks);
    if (options != null) result.options = options;
    if (loggingParams != null) result.loggingParams = loggingParams;
    return result;
  }

  PlayAsNextInQueueRequest._();

  factory PlayAsNextInQueueRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayAsNextInQueueRequest()..mergeFromBuffer(data, registry);
  factory PlayAsNextInQueueRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayAsNextInQueueRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayAsNextInQueueRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: PlayAsNextInQueueRequest.$_createMessage)
    ..pPM<$0.ContextTrack>(1, _omitFieldNames ? '' : 'tracks',
        subBuilder: $0.ContextTrack.$_createMessage)
    ..aOM<$1.CommandOptions>(2, _omitFieldNames ? '' : 'options',
        subBuilder: $1.CommandOptions.$_createMessage)
    ..aOM<$2.LoggingParams>(3, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $2.LoggingParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayAsNextInQueueRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayAsNextInQueueRequest copyWith(
          void Function(PlayAsNextInQueueRequest) updates) =>
      super.copyWith((message) => updates(message as PlayAsNextInQueueRequest))
          as PlayAsNextInQueueRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PlayAsNextInQueueRequest() / PlayAsNextInQueueRequest.new instead')
  static PlayAsNextInQueueRequest create() => PlayAsNextInQueueRequest._();
  static $pb.GeneratedMessage $_createMessage() => PlayAsNextInQueueRequest._();
  @$core.override
  PlayAsNextInQueueRequest createEmptyInstance() =>
      PlayAsNextInQueueRequest._();
  @$core.pragma('dart2js:noInline')
  static PlayAsNextInQueueRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlayAsNextInQueueRequest>(
          PlayAsNextInQueueRequest.$_createMessage);
  static PlayAsNextInQueueRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.ContextTrack> get tracks => $_getList(0);

  @$pb.TagNumber(2)
  $1.CommandOptions get options => $_getN(1);
  @$pb.TagNumber(2)
  set options($1.CommandOptions value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOptions() => $_has(1);
  @$pb.TagNumber(2)
  void clearOptions() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.CommandOptions ensureOptions() => $_ensure(1);

  @$pb.TagNumber(3)
  $2.LoggingParams get loggingParams => $_getN(2);
  @$pb.TagNumber(3)
  set loggingParams($2.LoggingParams value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasLoggingParams() => $_has(2);
  @$pb.TagNumber(3)
  void clearLoggingParams() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.LoggingParams ensureLoggingParams() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
