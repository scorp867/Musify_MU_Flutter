// This is a generated file - do not edit.
//
// Generated from es_set_queue_request.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'es_command_options.pb.dart' as $1;
import 'es_logging_params.pb.dart' as $2;
import 'es_provided_track.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SetQueueRequest extends $pb.GeneratedMessage {
  factory SetQueueRequest({
    $core.Iterable<$0.ProvidedTrack>? nextTracks,
    $core.Iterable<$0.ProvidedTrack>? prevTracks,
    $fixnum.Int64? queueRevision,
    $1.CommandOptions? options,
    $2.LoggingParams? loggingParams,
  }) {
    final result = SetQueueRequest._();
    if (nextTracks != null) result.nextTracks.addAll(nextTracks);
    if (prevTracks != null) result.prevTracks.addAll(prevTracks);
    if (queueRevision != null) result.queueRevision = queueRevision;
    if (options != null) result.options = options;
    if (loggingParams != null) result.loggingParams = loggingParams;
    return result;
  }

  SetQueueRequest._();

  factory SetQueueRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetQueueRequest()..mergeFromBuffer(data, registry);
  factory SetQueueRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetQueueRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetQueueRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: SetQueueRequest.$_createMessage)
    ..pPM<$0.ProvidedTrack>(1, _omitFieldNames ? '' : 'nextTracks',
        subBuilder: $0.ProvidedTrack.$_createMessage)
    ..pPM<$0.ProvidedTrack>(2, _omitFieldNames ? '' : 'prevTracks',
        subBuilder: $0.ProvidedTrack.$_createMessage)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'queueRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$1.CommandOptions>(4, _omitFieldNames ? '' : 'options',
        subBuilder: $1.CommandOptions.$_createMessage)
    ..aOM<$2.LoggingParams>(5, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $2.LoggingParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetQueueRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetQueueRequest copyWith(void Function(SetQueueRequest) updates) =>
      super.copyWith((message) => updates(message as SetQueueRequest))
          as SetQueueRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetQueueRequest() / SetQueueRequest.new instead')
  static SetQueueRequest create() => SetQueueRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetQueueRequest._();
  @$core.override
  SetQueueRequest createEmptyInstance() => SetQueueRequest._();
  @$core.pragma('dart2js:noInline')
  static SetQueueRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetQueueRequest>(
          SetQueueRequest.$_createMessage);
  static SetQueueRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.ProvidedTrack> get nextTracks => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<$0.ProvidedTrack> get prevTracks => $_getList(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get queueRevision => $_getI64(2);
  @$pb.TagNumber(3)
  set queueRevision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasQueueRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearQueueRevision() => $_clearField(3);

  @$pb.TagNumber(4)
  $1.CommandOptions get options => $_getN(3);
  @$pb.TagNumber(4)
  set options($1.CommandOptions value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasOptions() => $_has(3);
  @$pb.TagNumber(4)
  void clearOptions() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.CommandOptions ensureOptions() => $_ensure(3);

  @$pb.TagNumber(5)
  $2.LoggingParams get loggingParams => $_getN(4);
  @$pb.TagNumber(5)
  set loggingParams($2.LoggingParams value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasLoggingParams() => $_has(4);
  @$pb.TagNumber(5)
  void clearLoggingParams() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.LoggingParams ensureLoggingParams() => $_ensure(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
