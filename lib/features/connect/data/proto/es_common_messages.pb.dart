// 1:1 Replicated Spotify Esperanto Common Messages Wire Descriptors
// Sources:
// - Decompiled Java: `com/spotify/connect/esperanto/proto/CommonMessages.java`
// - Decompiled Java: `p199p/r1h.java`
// - `liborbit-jni-spotify_memdump.so` offset `0x3a79bc` (`common_messages.proto`)

// This is a generated file - do not edit.
//
// Generated from protos/esperanto/common_messages.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'es_common_messages.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'es_common_messages.pbenum.dart';

class LoggingParams extends $pb.GeneratedMessage {
  factory LoggingParams({
    $fixnum.Int64? commandInitiatedTime,
    $fixnum.Int64? commandReceivedTime,
    $core.Iterable<$core.String>? pageInstanceIds,
    $core.Iterable<$core.String>? interactionIds,
    $core.String? commandId,
    $core.String? featureIdentifier,
  }) {
    final result = LoggingParams._();
    if (commandInitiatedTime != null)
      result.commandInitiatedTime = commandInitiatedTime;
    if (commandReceivedTime != null)
      result.commandReceivedTime = commandReceivedTime;
    if (pageInstanceIds != null) result.pageInstanceIds.addAll(pageInstanceIds);
    if (interactionIds != null) result.interactionIds.addAll(interactionIds);
    if (commandId != null) result.commandId = commandId;
    if (featureIdentifier != null) result.featureIdentifier = featureIdentifier;
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
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: LoggingParams.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'commandInitiatedTime')
    ..aInt64(2, _omitFieldNames ? '' : 'commandReceivedTime')
    ..pPS(3, _omitFieldNames ? '' : 'pageInstanceIds')
    ..pPS(4, _omitFieldNames ? '' : 'interactionIds')
    ..aOS(5, _omitFieldNames ? '' : 'commandId')
    ..aOS(6, _omitFieldNames ? '' : 'featureIdentifier')
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
  static LoggingParams getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<LoggingParams>(
      LoggingParams.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static LoggingParams? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get commandInitiatedTime => $_getI64(0);
  @$pb.TagNumber(1)
  set commandInitiatedTime($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCommandInitiatedTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearCommandInitiatedTime() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get commandReceivedTime => $_getI64(1);
  @$pb.TagNumber(2)
  set commandReceivedTime($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCommandReceivedTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommandReceivedTime() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get pageInstanceIds => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get interactionIds => $_getList(3);

  @$pb.TagNumber(5)
  $core.String get commandId => $_getSZ(4);
  @$pb.TagNumber(5)
  set commandId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCommandId() => $_has(4);
  @$pb.TagNumber(5)
  void clearCommandId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get featureIdentifier => $_getSZ(5);
  @$pb.TagNumber(6)
  set featureIdentifier($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFeatureIdentifier() => $_has(5);
  @$pb.TagNumber(6)
  void clearFeatureIdentifier() => $_clearField(6);
}

class StatusResponse extends $pb.GeneratedMessage {
  factory StatusResponse({
    Status? status,
  }) {
    final result = StatusResponse._();
    if (status != null) result.status = status;
    return result;
  }

  StatusResponse._();

  factory StatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatusResponse()..mergeFromBuffer(data, registry);
  factory StatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatusResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatusResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: StatusResponse.$_createMessage)
    ..aE<Status>(1, _omitFieldNames ? '' : 'status', enumValues: Status.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusResponse copyWith(void Function(StatusResponse) updates) =>
      super.copyWith((message) => updates(message as StatusResponse))
          as StatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StatusResponse() / StatusResponse.new instead')
  static StatusResponse create() => StatusResponse._();
  static $pb.GeneratedMessage $_createMessage() => StatusResponse._();
  @$core.override
  StatusResponse createEmptyInstance() => StatusResponse._();
  @$core.pragma('dart2js:noInline')
  static StatusResponse getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<StatusResponse>(
      StatusResponse.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static StatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Status get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(Status value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
