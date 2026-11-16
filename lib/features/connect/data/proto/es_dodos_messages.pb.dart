// 1:1 Replicated Spotify Esperanto Dodos Messages Wire Descriptors
// Sources:
// - `liborbit-jni-spotify.so` `.rodata` FileDescriptorProto offset `5714450` / `0x5a1dd0`
// - `liborbit-jni-spotify_memdump.so` offset `0x36a536` (`dodos_messages.proto`)

// This is a generated file - do not edit.
//
// Generated from protos/esperanto/dodos_messages.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart' as $0;

import 'es_common_messages.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SingleDodo extends $pb.GeneratedMessage {
  factory SingleDodo({
    $core.String? dodoId,
    $core.String? csId,
    $core.bool? isPrimary,
    $core.bool? isBeingObserved,
  }) {
    final result = SingleDodo._();
    if (dodoId != null) result.dodoId = dodoId;
    if (csId != null) result.csId = csId;
    if (isPrimary != null) result.isPrimary = isPrimary;
    if (isBeingObserved != null) result.isBeingObserved = isBeingObserved;
    return result;
  }

  SingleDodo._();

  factory SingleDodo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SingleDodo()..mergeFromBuffer(data, registry);
  factory SingleDodo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SingleDodo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SingleDodo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: SingleDodo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'dodoId')
    ..aOS(2, _omitFieldNames ? '' : 'csId')
    ..aOB(3, _omitFieldNames ? '' : 'isPrimary')
    ..aOB(4, _omitFieldNames ? '' : 'isBeingObserved')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SingleDodo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SingleDodo copyWith(void Function(SingleDodo) updates) =>
      super.copyWith((message) => updates(message as SingleDodo)) as SingleDodo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SingleDodo() / SingleDodo.new instead')
  static SingleDodo create() => SingleDodo._();
  static $pb.GeneratedMessage $_createMessage() => SingleDodo._();
  @$core.override
  SingleDodo createEmptyInstance() => SingleDodo._();
  @$core.pragma('dart2js:noInline')
  static SingleDodo getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<SingleDodo>(
      SingleDodo.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static SingleDodo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get dodoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set dodoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDodoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDodoId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get csId => $_getSZ(1);
  @$pb.TagNumber(2)
  set csId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCsId() => $_has(1);
  @$pb.TagNumber(2)
  void clearCsId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isPrimary => $_getBF(2);
  @$pb.TagNumber(3)
  set isPrimary($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsPrimary() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsPrimary() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isBeingObserved => $_getBF(3);
  @$pb.TagNumber(4)
  set isBeingObserved($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsBeingObserved() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsBeingObserved() => $_clearField(4);
}

class SwitchToDodoRequest extends $pb.GeneratedMessage {
  factory SwitchToDodoRequest({
    $core.String? csId,
  }) {
    final result = SwitchToDodoRequest._();
    if (csId != null) result.csId = csId;
    return result;
  }

  SwitchToDodoRequest._();

  factory SwitchToDodoRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SwitchToDodoRequest()..mergeFromBuffer(data, registry);
  factory SwitchToDodoRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SwitchToDodoRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SwitchToDodoRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: SwitchToDodoRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'csId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SwitchToDodoRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SwitchToDodoRequest copyWith(void Function(SwitchToDodoRequest) updates) =>
      super.copyWith((message) => updates(message as SwitchToDodoRequest))
          as SwitchToDodoRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SwitchToDodoRequest() / SwitchToDodoRequest.new instead')
  static SwitchToDodoRequest create() => SwitchToDodoRequest._();
  static $pb.GeneratedMessage $_createMessage() => SwitchToDodoRequest._();
  @$core.override
  SwitchToDodoRequest createEmptyInstance() => SwitchToDodoRequest._();
  @$core.pragma('dart2js:noInline')
  static SwitchToDodoRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<SwitchToDodoRequest>(
      SwitchToDodoRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static SwitchToDodoRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get csId => $_getSZ(0);
  @$pb.TagNumber(1)
  set csId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCsId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCsId() => $_clearField(1);
}

class CreateNewDodoRequest extends $pb.GeneratedMessage {
  factory CreateNewDodoRequest() => CreateNewDodoRequest._();

  CreateNewDodoRequest._();

  factory CreateNewDodoRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateNewDodoRequest()..mergeFromBuffer(data, registry);
  factory CreateNewDodoRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateNewDodoRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateNewDodoRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: CreateNewDodoRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateNewDodoRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateNewDodoRequest copyWith(void Function(CreateNewDodoRequest) updates) =>
      super.copyWith((message) => updates(message as CreateNewDodoRequest))
          as CreateNewDodoRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateNewDodoRequest() / CreateNewDodoRequest.new instead')
  static CreateNewDodoRequest create() => CreateNewDodoRequest._();
  static $pb.GeneratedMessage $_createMessage() => CreateNewDodoRequest._();
  @$core.override
  CreateNewDodoRequest createEmptyInstance() => CreateNewDodoRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateNewDodoRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<CreateNewDodoRequest>(
      CreateNewDodoRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static CreateNewDodoRequest? _defaultInstance;
}

class EndDodoRequest extends $pb.GeneratedMessage {
  factory EndDodoRequest() => EndDodoRequest._();

  EndDodoRequest._();

  factory EndDodoRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EndDodoRequest()..mergeFromBuffer(data, registry);
  factory EndDodoRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EndDodoRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EndDodoRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: EndDodoRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EndDodoRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EndDodoRequest copyWith(void Function(EndDodoRequest) updates) =>
      super.copyWith((message) => updates(message as EndDodoRequest))
          as EndDodoRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EndDodoRequest() / EndDodoRequest.new instead')
  static EndDodoRequest create() => EndDodoRequest._();
  static $pb.GeneratedMessage $_createMessage() => EndDodoRequest._();
  @$core.override
  EndDodoRequest createEmptyInstance() => EndDodoRequest._();
  @$core.pragma('dart2js:noInline')
  static EndDodoRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<EndDodoRequest>(
      EndDodoRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static EndDodoRequest? _defaultInstance;
}

class DodoSubResponse extends $pb.GeneratedMessage {
  factory DodoSubResponse({
    $core.Iterable<SingleDodo>? dodos,
  }) {
    final result = DodoSubResponse._();
    if (dodos != null) result.dodos.addAll(dodos);
    return result;
  }

  DodoSubResponse._();

  factory DodoSubResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DodoSubResponse()..mergeFromBuffer(data, registry);
  factory DodoSubResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DodoSubResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DodoSubResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: DodoSubResponse.$_createMessage)
    ..pPM<SingleDodo>(1, _omitFieldNames ? '' : 'dodos',
        subBuilder: SingleDodo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DodoSubResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DodoSubResponse copyWith(void Function(DodoSubResponse) updates) =>
      super.copyWith((message) => updates(message as DodoSubResponse))
          as DodoSubResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DodoSubResponse() / DodoSubResponse.new instead')
  static DodoSubResponse create() => DodoSubResponse._();
  static $pb.GeneratedMessage $_createMessage() => DodoSubResponse._();
  @$core.override
  DodoSubResponse createEmptyInstance() => DodoSubResponse._();
  @$core.pragma('dart2js:noInline')
  static DodoSubResponse getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<DodoSubResponse>(
      DodoSubResponse.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static DodoSubResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SingleDodo> get dodos => $_getList(0);
}

class DodoServiceApi {
  final $pb.RpcClient _client;

  DodoServiceApi(this._client);

  $async.Future<DodoSubResponse> dodoSub(
          $pb.ClientContext? ctx, $0.Empty request) =>
      _client.invoke<DodoSubResponse>(
          ctx, 'DodoService', 'DodoSub', request, DodoSubResponse());
  $async.Future<$1.StatusResponse> switchToDodo(
          $pb.ClientContext? ctx, SwitchToDodoRequest request) =>
      _client.invoke<$1.StatusResponse>(
          ctx, 'DodoService', 'SwitchToDodo', request, $1.StatusResponse());
  $async.Future<$1.StatusResponse> createNewDodo(
          $pb.ClientContext? ctx, CreateNewDodoRequest request) =>
      _client.invoke<$1.StatusResponse>(
          ctx, 'DodoService', 'CreateNewDodo', request, $1.StatusResponse());
  $async.Future<$1.StatusResponse> endDodo(
          $pb.ClientContext? ctx, EndDodoRequest request) =>
      _client.invoke<$1.StatusResponse>(
          ctx, 'DodoService', 'EndDodo', request, $1.StatusResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
