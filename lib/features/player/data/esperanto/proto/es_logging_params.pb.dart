// This is a generated file - do not edit.
//
// Generated from es_logging_params.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'es_optional.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class LoggingParams extends $pb.GeneratedMessage {
  factory LoggingParams({
    $0.OptionalInt64? commandInitiatedTime,
    $0.OptionalInt64? commandReceivedTime,
    $core.Iterable<$core.String>? pageInstanceIds,
    $core.Iterable<$core.String>? interactionIds,
    $core.String? deviceIdentifier,
    $core.String? commandId,
  }) {
    final result = LoggingParams._();
    if (commandInitiatedTime != null)
      result.commandInitiatedTime = commandInitiatedTime;
    if (commandReceivedTime != null)
      result.commandReceivedTime = commandReceivedTime;
    if (pageInstanceIds != null) result.pageInstanceIds.addAll(pageInstanceIds);
    if (interactionIds != null) result.interactionIds.addAll(interactionIds);
    if (deviceIdentifier != null) result.deviceIdentifier = deviceIdentifier;
    if (commandId != null) result.commandId = commandId;
    return result;
  }

  LoggingParams._();

  factory LoggingParams.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoggingParams()..mergeFromBuffer(data, registry);
  factory LoggingParams.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoggingParams()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoggingParams',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: LoggingParams.$_createMessage)
    ..aOM<$0.OptionalInt64>(1, _omitFieldNames ? '' : 'commandInitiatedTime',
        subBuilder: $0.OptionalInt64.$_createMessage)
    ..aOM<$0.OptionalInt64>(2, _omitFieldNames ? '' : 'commandReceivedTime',
        subBuilder: $0.OptionalInt64.$_createMessage)
    ..pPS(3, _omitFieldNames ? '' : 'pageInstanceIds')
    ..pPS(4, _omitFieldNames ? '' : 'interactionIds')
    ..aOS(5, _omitFieldNames ? '' : 'deviceIdentifier')
    ..aOS(6, _omitFieldNames ? '' : 'commandId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoggingParams clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoggingParams copyWith(void Function(LoggingParams) updates) =>
      super.copyWith((message) => updates(message as LoggingParams))
          as LoggingParams;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LoggingParams() / LoggingParams.new instead')
  static LoggingParams create() => LoggingParams._();
  static $pb.GeneratedMessage $_createMessage() => LoggingParams._();
  @$core.override
  LoggingParams createEmptyInstance() => LoggingParams._();
  @$core.pragma('dart2js:noInline')
  static LoggingParams getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LoggingParams>(
          LoggingParams.$_createMessage);
  static LoggingParams? _defaultInstance;

  @$pb.TagNumber(1)
  $0.OptionalInt64 get commandInitiatedTime => $_getN(0);
  @$pb.TagNumber(1)
  set commandInitiatedTime($0.OptionalInt64 value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCommandInitiatedTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearCommandInitiatedTime() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.OptionalInt64 ensureCommandInitiatedTime() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.OptionalInt64 get commandReceivedTime => $_getN(1);
  @$pb.TagNumber(2)
  set commandReceivedTime($0.OptionalInt64 value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCommandReceivedTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommandReceivedTime() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.OptionalInt64 ensureCommandReceivedTime() => $_ensure(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get pageInstanceIds => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get interactionIds => $_getList(3);

  @$pb.TagNumber(5)
  $core.String get deviceIdentifier => $_getSZ(4);
  @$pb.TagNumber(5)
  set deviceIdentifier($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDeviceIdentifier() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeviceIdentifier() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get commandId => $_getSZ(5);
  @$pb.TagNumber(6)
  set commandId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCommandId() => $_has(5);
  @$pb.TagNumber(6)
  void clearCommandId() => $_clearField(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
