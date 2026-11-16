// 1:1 Replicated Spotify Esperanto Cast Messages Wire Descriptors
// Sources:
// - Decompiled Java: `com/spotify/connect/discovery/cast/esperanto/proto/CastMessages.java`
// - Decompiled Java: `p199p/khd.java`, `p199p/ygd.java`
// - `liborbit-jni-spotify_memdump.so` offset `0x36d3b8` (`cast_messages.proto`)

// This is a generated file - do not edit.
//
// Generated from protos/esperanto/cast_messages.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/wrappers.pb.dart'
    as $0;

import 'es_cast_messages.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'es_cast_messages.pbenum.dart';

class DeviceId extends $pb.GeneratedMessage {
  factory DeviceId({
    $core.String? deviceId,
  }) {
    final result = DeviceId._();
    if (deviceId != null) result.deviceId = deviceId;
    return result;
  }

  DeviceId._();

  factory DeviceId.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeviceId()..mergeFromBuffer(data, registry);
  factory DeviceId.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeviceId()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceId',
      package: const $pb.PackageName(_omitMessageNames
          ? ''
          : 'spotify.connect.discovery.cast.esperanto.proto'),
      createEmptyInstance: DeviceId.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceId clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceId copyWith(void Function(DeviceId) updates) =>
      super.copyWith((message) => updates(message as DeviceId)) as DeviceId;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeviceId() / DeviceId.new instead')
  static DeviceId create() => DeviceId._();
  static $pb.GeneratedMessage $_createMessage() => DeviceId._();
  @$core.override
  DeviceId createEmptyInstance() => DeviceId._();
  @$core.pragma('dart2js:noInline')
  static DeviceId getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<DeviceId>(
      DeviceId.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static DeviceId? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);
}

class PutDeviceRequest extends $pb.GeneratedMessage {
  factory PutDeviceRequest({
    $core.String? deviceId,
    $core.List<$core.int>? json,
  }) {
    final result = PutDeviceRequest._();
    if (deviceId != null) result.deviceId = deviceId;
    if (json != null) result.json = json;
    return result;
  }

  PutDeviceRequest._();

  factory PutDeviceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutDeviceRequest()..mergeFromBuffer(data, registry);
  factory PutDeviceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutDeviceRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PutDeviceRequest',
      package: const $pb.PackageName(_omitMessageNames
          ? ''
          : 'spotify.connect.discovery.cast.esperanto.proto'),
      createEmptyInstance: PutDeviceRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'json', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutDeviceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutDeviceRequest copyWith(void Function(PutDeviceRequest) updates) =>
      super.copyWith((message) => updates(message as PutDeviceRequest))
          as PutDeviceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PutDeviceRequest() / PutDeviceRequest.new instead')
  static PutDeviceRequest create() => PutDeviceRequest._();
  static $pb.GeneratedMessage $_createMessage() => PutDeviceRequest._();
  @$core.override
  PutDeviceRequest createEmptyInstance() => PutDeviceRequest._();
  @$core.pragma('dart2js:noInline')
  static PutDeviceRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<PutDeviceRequest>(
      PutDeviceRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static PutDeviceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get json => $_getN(1);
  @$pb.TagNumber(2)
  set json($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearJson() => $_clearField(2);
}

class ConnectionErrorRequest extends $pb.GeneratedMessage {
  factory ConnectionErrorRequest({
    $core.String? deviceId,
    $core.int? error,
    $core.int? platformErrorCode,
  }) {
    final result = ConnectionErrorRequest._();
    if (deviceId != null) result.deviceId = deviceId;
    if (error != null) result.error = error;
    if (platformErrorCode != null) result.platformErrorCode = platformErrorCode;
    return result;
  }

  ConnectionErrorRequest._();

  factory ConnectionErrorRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectionErrorRequest()..mergeFromBuffer(data, registry);
  factory ConnectionErrorRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectionErrorRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectionErrorRequest',
      package: const $pb.PackageName(_omitMessageNames
          ? ''
          : 'spotify.connect.discovery.cast.esperanto.proto'),
      createEmptyInstance: ConnectionErrorRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..aI(2, _omitFieldNames ? '' : 'error')
    ..aI(3, _omitFieldNames ? '' : 'platformErrorCode')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionErrorRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionErrorRequest copyWith(
          void Function(ConnectionErrorRequest) updates) =>
      super.copyWith((message) => updates(message as ConnectionErrorRequest))
          as ConnectionErrorRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ConnectionErrorRequest() / ConnectionErrorRequest.new instead')
  static ConnectionErrorRequest create() => ConnectionErrorRequest._();
  static $pb.GeneratedMessage $_createMessage() => ConnectionErrorRequest._();
  @$core.override
  ConnectionErrorRequest createEmptyInstance() => ConnectionErrorRequest._();
  @$core.pragma('dart2js:noInline')
  static ConnectionErrorRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<ConnectionErrorRequest>(
      ConnectionErrorRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static ConnectionErrorRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get error => $_getIZ(1);
  @$pb.TagNumber(2)
  set error($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get platformErrorCode => $_getIZ(2);
  @$pb.TagNumber(3)
  set platformErrorCode($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPlatformErrorCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlatformErrorCode() => $_clearField(3);
}

class ConnectRequest extends $pb.GeneratedMessage {
  factory ConnectRequest({
    $core.String? deviceId,
    $core.Iterable<$core.String>? interactionIds,
  }) {
    final result = ConnectRequest._();
    if (deviceId != null) result.deviceId = deviceId;
    if (interactionIds != null) result.interactionIds.addAll(interactionIds);
    return result;
  }

  ConnectRequest._();

  factory ConnectRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectRequest()..mergeFromBuffer(data, registry);
  factory ConnectRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectRequest',
      package: const $pb.PackageName(_omitMessageNames
          ? ''
          : 'spotify.connect.discovery.cast.esperanto.proto'),
      createEmptyInstance: ConnectRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..pPS(2, _omitFieldNames ? '' : 'interactionIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectRequest copyWith(void Function(ConnectRequest) updates) =>
      super.copyWith((message) => updates(message as ConnectRequest))
          as ConnectRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConnectRequest() / ConnectRequest.new instead')
  static ConnectRequest create() => ConnectRequest._();
  static $pb.GeneratedMessage $_createMessage() => ConnectRequest._();
  @$core.override
  ConnectRequest createEmptyInstance() => ConnectRequest._();
  @$core.pragma('dart2js:noInline')
  static ConnectRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<ConnectRequest>(
      ConnectRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static ConnectRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get interactionIds => $_getList(1);
}

class Response extends $pb.GeneratedMessage {
  factory Response({
    CastResult? result,
  }) {
    final result$ = Response._();
    if (result != null) result$.result = result;
    return result$;
  }

  Response._();

  factory Response.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Response()..mergeFromBuffer(data, registry);
  factory Response.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Response()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response',
      package: const $pb.PackageName(_omitMessageNames
          ? ''
          : 'spotify.connect.discovery.cast.esperanto.proto'),
      createEmptyInstance: Response.$_createMessage)
    ..aE<CastResult>(1, _omitFieldNames ? '' : 'result',
        enumValues: CastResult.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response copyWith(void Function(Response) updates) =>
      super.copyWith((message) => updates(message as Response)) as Response;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Response() / Response.new instead')
  static Response create() => Response._();
  static $pb.GeneratedMessage $_createMessage() => Response._();
  @$core.override
  Response createEmptyInstance() => Response._();
  @$core.pragma('dart2js:noInline')
  static Response getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<Response>(
      Response.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static Response? _defaultInstance;

  @$pb.TagNumber(1)
  CastResult get result => $_getN(0);
  @$pb.TagNumber(1)
  set result(CastResult value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResult() => $_has(0);
  @$pb.TagNumber(1)
  void clearResult() => $_clearField(1);
}

class CastServiceApi {
  final $pb.RpcClient _client;

  CastServiceApi(this._client);

  $async.Future<Response> connect($pb.ClientContext? ctx, DeviceId request) =>
      _client.invoke<Response>(
          ctx, 'CastService', 'Connect', request, Response());
  $async.Future<Response> connectionError(
          $pb.ClientContext? ctx, ConnectionErrorRequest request) =>
      _client.invoke<Response>(
          ctx, 'CastService', 'ConnectionError', request, Response());
  $async.Future<Response> deleteDevice(
          $pb.ClientContext? ctx, DeviceId request) =>
      _client.invoke<Response>(
          ctx, 'CastService', 'DeleteDevice', request, Response());
  $async.Future<Response> putDevice(
          $pb.ClientContext? ctx, PutDeviceRequest request) =>
      _client.invoke<Response>(
          ctx, 'CastService', 'PutDevice', request, Response());
  $async.Future<Response> putMessage(
          $pb.ClientContext? ctx, $0.BytesValue request) =>
      _client.invoke<Response>(
          ctx, 'CastService', 'PutMessage', request, Response());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
