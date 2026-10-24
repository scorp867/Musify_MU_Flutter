// This is a generated file - do not edit.
//
// Generated from es_stop.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'es_command_options.pb.dart' as $0;
import 'es_logging_params.pb.dart' as $1;
import 'es_stop.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'es_stop.pbenum.dart';

class StopRequest extends $pb.GeneratedMessage {
  factory StopRequest({
    $0.CommandOptions? options,
    StopRequest_Reason? reason,
    $1.LoggingParams? loggingParams,
  }) {
    final result = StopRequest._();
    if (options != null) result.options = options;
    if (reason != null) result.reason = reason;
    if (loggingParams != null) result.loggingParams = loggingParams;
    return result;
  }

  StopRequest._();

  factory StopRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StopRequest()..mergeFromBuffer(data, registry);
  factory StopRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StopRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StopRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: StopRequest.$_createMessage)
    ..aOM<$0.CommandOptions>(1, _omitFieldNames ? '' : 'options',
        subBuilder: $0.CommandOptions.$_createMessage)
    ..aE<StopRequest_Reason>(2, _omitFieldNames ? '' : 'reason',
        enumValues: StopRequest_Reason.values)
    ..aOM<$1.LoggingParams>(3, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopRequest copyWith(void Function(StopRequest) updates) =>
      super.copyWith((message) => updates(message as StopRequest))
          as StopRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StopRequest() / StopRequest.new instead')
  static StopRequest create() => StopRequest._();
  static $pb.GeneratedMessage $_createMessage() => StopRequest._();
  @$core.override
  StopRequest createEmptyInstance() => StopRequest._();
  @$core.pragma('dart2js:noInline')
  static StopRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StopRequest>(
          StopRequest.$_createMessage);
  static StopRequest? _defaultInstance;

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
  StopRequest_Reason get reason => $_getN(1);
  @$pb.TagNumber(2)
  set reason(StopRequest_Reason value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasReason() => $_has(1);
  @$pb.TagNumber(2)
  void clearReason() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.LoggingParams get loggingParams => $_getN(2);
  @$pb.TagNumber(3)
  set loggingParams($1.LoggingParams value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasLoggingParams() => $_has(2);
  @$pb.TagNumber(3)
  void clearLoggingParams() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.LoggingParams ensureLoggingParams() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
