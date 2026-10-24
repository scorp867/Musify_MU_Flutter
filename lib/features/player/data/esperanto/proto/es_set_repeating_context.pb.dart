// This is a generated file - do not edit.
//
// Generated from es_set_repeating_context.proto.

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

class SetRepeatingContextRequest extends $pb.GeneratedMessage {
  factory SetRepeatingContextRequest({
    $core.bool? repeatingContext,
    $0.CommandOptions? options,
    $1.LoggingParams? loggingParams,
  }) {
    final result = SetRepeatingContextRequest._();
    if (repeatingContext != null) result.repeatingContext = repeatingContext;
    if (options != null) result.options = options;
    if (loggingParams != null) result.loggingParams = loggingParams;
    return result;
  }

  SetRepeatingContextRequest._();

  factory SetRepeatingContextRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetRepeatingContextRequest()..mergeFromBuffer(data, registry);
  factory SetRepeatingContextRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetRepeatingContextRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetRepeatingContextRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: SetRepeatingContextRequest.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'repeatingContext')
    ..aOM<$0.CommandOptions>(2, _omitFieldNames ? '' : 'options',
        subBuilder: $0.CommandOptions.$_createMessage)
    ..aOM<$1.LoggingParams>(3, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRepeatingContextRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRepeatingContextRequest copyWith(
          void Function(SetRepeatingContextRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SetRepeatingContextRequest))
          as SetRepeatingContextRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetRepeatingContextRequest() / SetRepeatingContextRequest.new instead')
  static SetRepeatingContextRequest create() => SetRepeatingContextRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      SetRepeatingContextRequest._();
  @$core.override
  SetRepeatingContextRequest createEmptyInstance() =>
      SetRepeatingContextRequest._();
  @$core.pragma('dart2js:noInline')
  static SetRepeatingContextRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetRepeatingContextRequest>(
          SetRepeatingContextRequest.$_createMessage);
  static SetRepeatingContextRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get repeatingContext => $_getBF(0);
  @$pb.TagNumber(1)
  set repeatingContext($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepeatingContext() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepeatingContext() => $_clearField(1);

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
