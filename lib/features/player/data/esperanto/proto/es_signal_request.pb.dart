// This is a generated file - do not edit.
//
// Generated from es_signal_request.proto.

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

class SignalRequest extends $pb.GeneratedMessage {
  factory SignalRequest({
    $core.String? signalId,
    $core.String? parameters,
    $0.CommandOptions? options,
    $1.LoggingParams? loggingParams,
  }) {
    final result = SignalRequest._();
    if (signalId != null) result.signalId = signalId;
    if (parameters != null) result.parameters = parameters;
    if (options != null) result.options = options;
    if (loggingParams != null) result.loggingParams = loggingParams;
    return result;
  }

  SignalRequest._();

  factory SignalRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SignalRequest()..mergeFromBuffer(data, registry);
  factory SignalRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SignalRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SignalRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: SignalRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'signalId')
    ..aOS(2, _omitFieldNames ? '' : 'parameters')
    ..aOM<$0.CommandOptions>(3, _omitFieldNames ? '' : 'options',
        subBuilder: $0.CommandOptions.$_createMessage)
    ..aOM<$1.LoggingParams>(4, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignalRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignalRequest copyWith(void Function(SignalRequest) updates) =>
      super.copyWith((message) => updates(message as SignalRequest))
          as SignalRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SignalRequest() / SignalRequest.new instead')
  static SignalRequest create() => SignalRequest._();
  static $pb.GeneratedMessage $_createMessage() => SignalRequest._();
  @$core.override
  SignalRequest createEmptyInstance() => SignalRequest._();
  @$core.pragma('dart2js:noInline')
  static SignalRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SignalRequest>(
          SignalRequest.$_createMessage);
  static SignalRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get signalId => $_getSZ(0);
  @$pb.TagNumber(1)
  set signalId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSignalId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSignalId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get parameters => $_getSZ(1);
  @$pb.TagNumber(2)
  set parameters($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasParameters() => $_has(1);
  @$pb.TagNumber(2)
  void clearParameters() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.CommandOptions get options => $_getN(2);
  @$pb.TagNumber(3)
  set options($0.CommandOptions value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOptions() => $_has(2);
  @$pb.TagNumber(3)
  void clearOptions() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.CommandOptions ensureOptions() => $_ensure(2);

  @$pb.TagNumber(4)
  $1.LoggingParams get loggingParams => $_getN(3);
  @$pb.TagNumber(4)
  set loggingParams($1.LoggingParams value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasLoggingParams() => $_has(3);
  @$pb.TagNumber(4)
  void clearLoggingParams() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.LoggingParams ensureLoggingParams() => $_ensure(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
