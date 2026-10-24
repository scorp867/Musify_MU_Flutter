// This is a generated file - do not edit.
//
// Generated from es_set_shuffling_context.proto.

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

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SetShufflingContextRequest extends $pb.GeneratedMessage {
  factory SetShufflingContextRequest({
    $core.bool? shufflingContext,
    $0.CommandOptions? options,
    $1.LoggingParams? loggingParams,
  }) {
    final result = SetShufflingContextRequest._();
    if (shufflingContext != null) result.shufflingContext = shufflingContext;
    if (options != null) result.options = options;
    if (loggingParams != null) result.loggingParams = loggingParams;
    return result;
  }

  SetShufflingContextRequest._();

  factory SetShufflingContextRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetShufflingContextRequest()..mergeFromBuffer(data, registry);
  factory SetShufflingContextRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetShufflingContextRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetShufflingContextRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: SetShufflingContextRequest.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'shufflingContext')
    ..aOM<$0.CommandOptions>(2, _omitFieldNames ? '' : 'options',
        subBuilder: $0.CommandOptions.$_createMessage)
    ..aOM<$1.LoggingParams>(3, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetShufflingContextRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetShufflingContextRequest copyWith(
          void Function(SetShufflingContextRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SetShufflingContextRequest))
          as SetShufflingContextRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetShufflingContextRequest() / SetShufflingContextRequest.new instead')
  static SetShufflingContextRequest create() => SetShufflingContextRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      SetShufflingContextRequest._();
  @$core.override
  SetShufflingContextRequest createEmptyInstance() =>
      SetShufflingContextRequest._();
  @$core.pragma('dart2js:noInline')
  static SetShufflingContextRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetShufflingContextRequest>(
          SetShufflingContextRequest.$_createMessage);
  static SetShufflingContextRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get shufflingContext => $_getBF(0);
  @$pb.TagNumber(1)
  set shufflingContext($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasShufflingContext() => $_has(0);
  @$pb.TagNumber(1)
  void clearShufflingContext() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.CommandOptions get options => $_getN(1);
  @$pb.TagNumber(2)
  set options($0.CommandOptions value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOptions() => $_has(1);
  @$pb.TagNumber(2)
  void clearOptions() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.CommandOptions ensureOptions() => $_ensure(1);

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
