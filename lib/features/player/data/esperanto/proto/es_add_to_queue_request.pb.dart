// This is a generated file - do not edit.
//
// Generated from es_add_to_queue_request.proto.

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

class AddToQueueRequest extends $pb.GeneratedMessage {
  factory AddToQueueRequest({
    $0.ContextTrack? track,
    $1.CommandOptions? options,
    $2.LoggingParams? loggingParams,
  }) {
    final result = AddToQueueRequest._();
    if (track != null) result.track = track;
    if (options != null) result.options = options;
    if (loggingParams != null) result.loggingParams = loggingParams;
    return result;
  }

  AddToQueueRequest._();

  factory AddToQueueRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddToQueueRequest()..mergeFromBuffer(data, registry);
  factory AddToQueueRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddToQueueRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddToQueueRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: AddToQueueRequest.$_createMessage)
    ..aOM<$0.ContextTrack>(1, _omitFieldNames ? '' : 'track',
        subBuilder: $0.ContextTrack.$_createMessage)
    ..aOM<$1.CommandOptions>(2, _omitFieldNames ? '' : 'options',
        subBuilder: $1.CommandOptions.$_createMessage)
    ..aOM<$2.LoggingParams>(3, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $2.LoggingParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddToQueueRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddToQueueRequest copyWith(void Function(AddToQueueRequest) updates) =>
      super.copyWith((message) => updates(message as AddToQueueRequest))
          as AddToQueueRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AddToQueueRequest() / AddToQueueRequest.new instead')
  static AddToQueueRequest create() => AddToQueueRequest._();
  static $pb.GeneratedMessage $_createMessage() => AddToQueueRequest._();
  @$core.override
  AddToQueueRequest createEmptyInstance() => AddToQueueRequest._();
  @$core.pragma('dart2js:noInline')
  static AddToQueueRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddToQueueRequest>(
          AddToQueueRequest.$_createMessage);
  static AddToQueueRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $0.ContextTrack get track => $_getN(0);
  @$pb.TagNumber(1)
  set track($0.ContextTrack value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTrack() => $_has(0);
  @$pb.TagNumber(1)
  void clearTrack() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.ContextTrack ensureTrack() => $_ensure(0);

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
