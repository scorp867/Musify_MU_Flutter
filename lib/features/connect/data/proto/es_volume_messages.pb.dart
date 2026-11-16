// 1:1 Replicated Spotify Esperanto Volume Messages Wire Descriptors
// Sources:
// - Decompiled Java: `com/spotify/connect/esperanto/proto/VolumeMessages.java`
// - Decompiled Java: `p199p/a0f1.java`, `p199p/lw51.java`, `p199p/ush1.java`
// - `liborbit-jni-spotify_memdump.so` offset `0x36a7bc` (`volume_messages.proto`)

// This is a generated file - do not edit.
//
// Generated from protos/esperanto/volume_messages.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart' as $1;

import 'es_common_messages.pb.dart' as $0;
import 'es_volume_messages.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'es_volume_messages.pbenum.dart';

class VolumeResponse extends $pb.GeneratedMessage {
  factory VolumeResponse({
    $core.int? volume,
    $0.Status? status,
    $core.String? activeDeviceConnectStateIdentifier,
    $core.Iterable<$core.MapEntry<$core.String, $core.int>>? groupDeviceVolumes,
  }) {
    final result = VolumeResponse._();
    if (volume != null) result.volume = volume;
    if (status != null) result.status = status;
    if (activeDeviceConnectStateIdentifier != null)
      result.activeDeviceConnectStateIdentifier =
          activeDeviceConnectStateIdentifier;
    if (groupDeviceVolumes != null)
      result.groupDeviceVolumes.addEntries(groupDeviceVolumes);
    return result;
  }

  VolumeResponse._();

  factory VolumeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VolumeResponse()..mergeFromBuffer(data, registry);
  factory VolumeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VolumeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VolumeResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: VolumeResponse.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'volume')
    ..aE<$0.Status>(2, _omitFieldNames ? '' : 'status',
        enumValues: $0.Status.values)
    ..aOS(3, _omitFieldNames ? '' : 'activeDeviceConnectStateIdentifier')
    ..m<$core.String, $core.int>(4, _omitFieldNames ? '' : 'groupDeviceVolumes',
        entryClassName: 'VolumeResponse.GroupDeviceVolumesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OU3,
        packageName: const $pb.PackageName('spotify.connect.esperanto.proto'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VolumeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VolumeResponse copyWith(void Function(VolumeResponse) updates) =>
      super.copyWith((message) => updates(message as VolumeResponse))
          as VolumeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use VolumeResponse() / VolumeResponse.new instead')
  static VolumeResponse create() => VolumeResponse._();
  static $pb.GeneratedMessage $_createMessage() => VolumeResponse._();
  @$core.override
  VolumeResponse createEmptyInstance() => VolumeResponse._();
  @$core.pragma('dart2js:noInline')
  static VolumeResponse getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<VolumeResponse>(
      VolumeResponse.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static VolumeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get volume => $_getIZ(0);
  @$pb.TagNumber(1)
  set volume($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVolume() => $_has(0);
  @$pb.TagNumber(1)
  void clearVolume() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Status get status => $_getN(1);
  @$pb.TagNumber(2)
  set status($0.Status value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get activeDeviceConnectStateIdentifier => $_getSZ(2);
  @$pb.TagNumber(3)
  set activeDeviceConnectStateIdentifier($core.String value) =>
      $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasActiveDeviceConnectStateIdentifier() => $_has(2);
  @$pb.TagNumber(3)
  void clearActiveDeviceConnectStateIdentifier() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbMap<$core.String, $core.int> get groupDeviceVolumes => $_getMap(3);
}

class VolumeSetRequest extends $pb.GeneratedMessage {
  factory VolumeSetRequest({
    $core.int? volume,
    $0.LoggingParams? loggingParams,
    $core.String? groupDeviceIdentifier,
  }) {
    final result = VolumeSetRequest._();
    if (volume != null) result.volume = volume;
    if (loggingParams != null) result.loggingParams = loggingParams;
    if (groupDeviceIdentifier != null)
      result.groupDeviceIdentifier = groupDeviceIdentifier;
    return result;
  }

  VolumeSetRequest._();

  factory VolumeSetRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VolumeSetRequest()..mergeFromBuffer(data, registry);
  factory VolumeSetRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VolumeSetRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VolumeSetRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: VolumeSetRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'volume')
    ..aOM<$0.LoggingParams>(2, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $0.LoggingParams.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'groupDeviceIdentifier')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VolumeSetRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VolumeSetRequest copyWith(void Function(VolumeSetRequest) updates) =>
      super.copyWith((message) => updates(message as VolumeSetRequest))
          as VolumeSetRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use VolumeSetRequest() / VolumeSetRequest.new instead')
  static VolumeSetRequest create() => VolumeSetRequest._();
  static $pb.GeneratedMessage $_createMessage() => VolumeSetRequest._();
  @$core.override
  VolumeSetRequest createEmptyInstance() => VolumeSetRequest._();
  @$core.pragma('dart2js:noInline')
  static VolumeSetRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<VolumeSetRequest>(
      VolumeSetRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static VolumeSetRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get volume => $_getIZ(0);
  @$pb.TagNumber(1)
  set volume($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVolume() => $_has(0);
  @$pb.TagNumber(1)
  void clearVolume() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.LoggingParams get loggingParams => $_getN(1);
  @$pb.TagNumber(2)
  set loggingParams($0.LoggingParams value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLoggingParams() => $_has(1);
  @$pb.TagNumber(2)
  void clearLoggingParams() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.LoggingParams ensureLoggingParams() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get groupDeviceIdentifier => $_getSZ(2);
  @$pb.TagNumber(3)
  set groupDeviceIdentifier($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGroupDeviceIdentifier() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroupDeviceIdentifier() => $_clearField(3);
}

class VolumeUpRequest extends $pb.GeneratedMessage {
  factory VolumeUpRequest({
    $0.LoggingParams? loggingParams,
    $core.String? groupDeviceIdentifier,
  }) {
    final result = VolumeUpRequest._();
    if (loggingParams != null) result.loggingParams = loggingParams;
    if (groupDeviceIdentifier != null)
      result.groupDeviceIdentifier = groupDeviceIdentifier;
    return result;
  }

  VolumeUpRequest._();

  factory VolumeUpRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VolumeUpRequest()..mergeFromBuffer(data, registry);
  factory VolumeUpRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VolumeUpRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VolumeUpRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: VolumeUpRequest.$_createMessage)
    ..aOM<$0.LoggingParams>(1, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $0.LoggingParams.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'groupDeviceIdentifier')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VolumeUpRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VolumeUpRequest copyWith(void Function(VolumeUpRequest) updates) =>
      super.copyWith((message) => updates(message as VolumeUpRequest))
          as VolumeUpRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use VolumeUpRequest() / VolumeUpRequest.new instead')
  static VolumeUpRequest create() => VolumeUpRequest._();
  static $pb.GeneratedMessage $_createMessage() => VolumeUpRequest._();
  @$core.override
  VolumeUpRequest createEmptyInstance() => VolumeUpRequest._();
  @$core.pragma('dart2js:noInline')
  static VolumeUpRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<VolumeUpRequest>(
      VolumeUpRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static VolumeUpRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $0.LoggingParams get loggingParams => $_getN(0);
  @$pb.TagNumber(1)
  set loggingParams($0.LoggingParams value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLoggingParams() => $_has(0);
  @$pb.TagNumber(1)
  void clearLoggingParams() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.LoggingParams ensureLoggingParams() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get groupDeviceIdentifier => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupDeviceIdentifier($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGroupDeviceIdentifier() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupDeviceIdentifier() => $_clearField(2);
}

class VolumeDownRequest extends $pb.GeneratedMessage {
  factory VolumeDownRequest({
    $0.LoggingParams? loggingParams,
    $core.String? groupDeviceIdentifier,
  }) {
    final result = VolumeDownRequest._();
    if (loggingParams != null) result.loggingParams = loggingParams;
    if (groupDeviceIdentifier != null)
      result.groupDeviceIdentifier = groupDeviceIdentifier;
    return result;
  }

  VolumeDownRequest._();

  factory VolumeDownRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VolumeDownRequest()..mergeFromBuffer(data, registry);
  factory VolumeDownRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VolumeDownRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VolumeDownRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: VolumeDownRequest.$_createMessage)
    ..aOM<$0.LoggingParams>(1, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $0.LoggingParams.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'groupDeviceIdentifier')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VolumeDownRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VolumeDownRequest copyWith(void Function(VolumeDownRequest) updates) =>
      super.copyWith((message) => updates(message as VolumeDownRequest))
          as VolumeDownRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use VolumeDownRequest() / VolumeDownRequest.new instead')
  static VolumeDownRequest create() => VolumeDownRequest._();
  static $pb.GeneratedMessage $_createMessage() => VolumeDownRequest._();
  @$core.override
  VolumeDownRequest createEmptyInstance() => VolumeDownRequest._();
  @$core.pragma('dart2js:noInline')
  static VolumeDownRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<VolumeDownRequest>(
      VolumeDownRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static VolumeDownRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $0.LoggingParams get loggingParams => $_getN(0);
  @$pb.TagNumber(1)
  set loggingParams($0.LoggingParams value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLoggingParams() => $_has(0);
  @$pb.TagNumber(1)
  void clearLoggingParams() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.LoggingParams ensureLoggingParams() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get groupDeviceIdentifier => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupDeviceIdentifier($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGroupDeviceIdentifier() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupDeviceIdentifier() => $_clearField(2);
}

class LocalVolumeResponse extends $pb.GeneratedMessage {
  factory LocalVolumeResponse({
    $core.int? volume,
    LocalVolumeResponse_Reason? reason,
  }) {
    final result = LocalVolumeResponse._();
    if (volume != null) result.volume = volume;
    if (reason != null) result.reason = reason;
    return result;
  }

  LocalVolumeResponse._();

  factory LocalVolumeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LocalVolumeResponse()..mergeFromBuffer(data, registry);
  factory LocalVolumeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LocalVolumeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LocalVolumeResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: LocalVolumeResponse.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'volume')
    ..aE<LocalVolumeResponse_Reason>(2, _omitFieldNames ? '' : 'reason',
        enumValues: LocalVolumeResponse_Reason.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalVolumeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalVolumeResponse copyWith(void Function(LocalVolumeResponse) updates) =>
      super.copyWith((message) => updates(message as LocalVolumeResponse))
          as LocalVolumeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use LocalVolumeResponse() / LocalVolumeResponse.new instead')
  static LocalVolumeResponse create() => LocalVolumeResponse._();
  static $pb.GeneratedMessage $_createMessage() => LocalVolumeResponse._();
  @$core.override
  LocalVolumeResponse createEmptyInstance() => LocalVolumeResponse._();
  @$core.pragma('dart2js:noInline')
  static LocalVolumeResponse getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<LocalVolumeResponse>(
      LocalVolumeResponse.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static LocalVolumeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get volume => $_getIZ(0);
  @$pb.TagNumber(1)
  set volume($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVolume() => $_has(0);
  @$pb.TagNumber(1)
  void clearVolume() => $_clearField(1);

  @$pb.TagNumber(2)
  LocalVolumeResponse_Reason get reason => $_getN(1);
  @$pb.TagNumber(2)
  set reason(LocalVolumeResponse_Reason value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasReason() => $_has(1);
  @$pb.TagNumber(2)
  void clearReason() => $_clearField(2);
}

class ConnectVolumeServiceApi {
  final $pb.RpcClient _client;

  ConnectVolumeServiceApi(this._client);

  $async.Future<VolumeResponse> volume(
          $pb.ClientContext? ctx, $1.Empty request) =>
      _client.invoke<VolumeResponse>(
          ctx, 'ConnectVolumeService', 'Volume', request, VolumeResponse());
  $async.Future<LocalVolumeResponse> localVolume(
          $pb.ClientContext? ctx, $1.Empty request) =>
      _client.invoke<LocalVolumeResponse>(ctx, 'ConnectVolumeService',
          'LocalVolume', request, LocalVolumeResponse());
  $async.Future<$0.StatusResponse> volumeSet(
          $pb.ClientContext? ctx, VolumeSetRequest request) =>
      _client.invoke<$0.StatusResponse>(ctx, 'ConnectVolumeService',
          'VolumeSet', request, $0.StatusResponse());
  $async.Future<$0.StatusResponse> volumeUp(
          $pb.ClientContext? ctx, VolumeUpRequest request) =>
      _client.invoke<$0.StatusResponse>(ctx, 'ConnectVolumeService', 'VolumeUp',
          request, $0.StatusResponse());
  $async.Future<$0.StatusResponse> volumeDown(
          $pb.ClientContext? ctx, VolumeDownRequest request) =>
      _client.invoke<$0.StatusResponse>(ctx, 'ConnectVolumeService',
          'VolumeDown', request, $0.StatusResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
