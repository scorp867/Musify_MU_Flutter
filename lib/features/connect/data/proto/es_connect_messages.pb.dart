// 1:1 Replicated Spotify Esperanto Connect Messages Wire Descriptors
// Sources:
// - Decompiled Java: `com/spotify/connect/esperanto/proto/ConnectMessages.java`
// - Decompiled Java: `p199p/s77.java`, `p199p/C2086nd.java`, `p199p/n8d.java`
// - `liborbit-jni-spotify_memdump.so` offset `0x3a5024` (`connect_messages.proto`)

// This is a generated file - do not edit.
//
// Generated from protos/esperanto/connect_messages.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart' as $2;

import 'group.pb.dart' as $0;
import 'es_common_messages.pb.dart' as $1;
import 'es_connect_messages.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'es_connect_messages.pbenum.dart';

class OutputPeripheral extends $pb.GeneratedMessage {
  factory OutputPeripheral({
    $core.String? name,
    $core.String? brand,
    $core.String? model,
    OutputPeripheralCategory? category,
    OutputPeripheralConnectionType? connectionType,
  }) {
    final result = OutputPeripheral._();
    if (name != null) result.name = name;
    if (brand != null) result.brand = brand;
    if (model != null) result.model = model;
    if (category != null) result.category = category;
    if (connectionType != null) result.connectionType = connectionType;
    return result;
  }

  OutputPeripheral._();

  factory OutputPeripheral.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OutputPeripheral()..mergeFromBuffer(data, registry);
  factory OutputPeripheral.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OutputPeripheral()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputPeripheral',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: OutputPeripheral.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'brand')
    ..aOS(3, _omitFieldNames ? '' : 'model')
    ..aE<OutputPeripheralCategory>(4, _omitFieldNames ? '' : 'category',
        enumValues: OutputPeripheralCategory.values)
    ..aE<OutputPeripheralConnectionType>(
        5, _omitFieldNames ? '' : 'connectionType',
        enumValues: OutputPeripheralConnectionType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputPeripheral clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputPeripheral copyWith(void Function(OutputPeripheral) updates) =>
      super.copyWith((message) => updates(message as OutputPeripheral))
          as OutputPeripheral;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use OutputPeripheral() / OutputPeripheral.new instead')
  static OutputPeripheral create() => OutputPeripheral._();
  static $pb.GeneratedMessage $_createMessage() => OutputPeripheral._();
  @$core.override
  OutputPeripheral createEmptyInstance() => OutputPeripheral._();
  @$core.pragma('dart2js:noInline')
  static OutputPeripheral getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<OutputPeripheral>(
      OutputPeripheral.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static OutputPeripheral? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get brand => $_getSZ(1);
  @$pb.TagNumber(2)
  set brand($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBrand() => $_has(1);
  @$pb.TagNumber(2)
  void clearBrand() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get model => $_getSZ(2);
  @$pb.TagNumber(3)
  set model($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasModel() => $_has(2);
  @$pb.TagNumber(3)
  void clearModel() => $_clearField(3);

  @$pb.TagNumber(4)
  OutputPeripheralCategory get category => $_getN(3);
  @$pb.TagNumber(4)
  set category(OutputPeripheralCategory value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCategory() => $_has(3);
  @$pb.TagNumber(4)
  void clearCategory() => $_clearField(4);

  @$pb.TagNumber(5)
  OutputPeripheralConnectionType get connectionType => $_getN(4);
  @$pb.TagNumber(5)
  set connectionType(OutputPeripheralConnectionType value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasConnectionType() => $_has(4);
  @$pb.TagNumber(5)
  void clearConnectionType() => $_clearField(5);
}

class StateRequest extends $pb.GeneratedMessage {
  factory StateRequest({
    $core.bool? showOfflineDevicesInCore,
    $core.bool? showOfflineAmazonDevicesAsOnline,
    $core.bool? includeLocalDevice,
    $core.bool? excludeNonLocalDevices,
    $core.bool? includeUserMatchUnauthenticatedDevices,
  }) {
    final result = StateRequest._();
    if (showOfflineDevicesInCore != null)
      result.showOfflineDevicesInCore = showOfflineDevicesInCore;
    if (showOfflineAmazonDevicesAsOnline != null)
      result.showOfflineAmazonDevicesAsOnline =
          showOfflineAmazonDevicesAsOnline;
    if (includeLocalDevice != null)
      result.includeLocalDevice = includeLocalDevice;
    if (excludeNonLocalDevices != null)
      result.excludeNonLocalDevices = excludeNonLocalDevices;
    if (includeUserMatchUnauthenticatedDevices != null)
      result.includeUserMatchUnauthenticatedDevices =
          includeUserMatchUnauthenticatedDevices;
    return result;
  }

  StateRequest._();

  factory StateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StateRequest()..mergeFromBuffer(data, registry);
  factory StateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StateRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StateRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: StateRequest.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'showOfflineDevicesInCore')
    ..aOB(2, _omitFieldNames ? '' : 'showOfflineAmazonDevicesAsOnline')
    ..aOB(3, _omitFieldNames ? '' : 'includeLocalDevice')
    ..aOB(4, _omitFieldNames ? '' : 'excludeNonLocalDevices')
    ..aOB(5, _omitFieldNames ? '' : 'includeUserMatchUnauthenticatedDevices')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StateRequest copyWith(void Function(StateRequest) updates) =>
      super.copyWith((message) => updates(message as StateRequest))
          as StateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StateRequest() / StateRequest.new instead')
  static StateRequest create() => StateRequest._();
  static $pb.GeneratedMessage $_createMessage() => StateRequest._();
  @$core.override
  StateRequest createEmptyInstance() => StateRequest._();
  @$core.pragma('dart2js:noInline')
  static StateRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<StateRequest>(
      StateRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static StateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get showOfflineDevicesInCore => $_getBF(0);
  @$pb.TagNumber(1)
  set showOfflineDevicesInCore($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasShowOfflineDevicesInCore() => $_has(0);
  @$pb.TagNumber(1)
  void clearShowOfflineDevicesInCore() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get showOfflineAmazonDevicesAsOnline => $_getBF(1);
  @$pb.TagNumber(2)
  set showOfflineAmazonDevicesAsOnline($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasShowOfflineAmazonDevicesAsOnline() => $_has(1);
  @$pb.TagNumber(2)
  void clearShowOfflineAmazonDevicesAsOnline() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get includeLocalDevice => $_getBF(2);
  @$pb.TagNumber(3)
  set includeLocalDevice($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIncludeLocalDevice() => $_has(2);
  @$pb.TagNumber(3)
  void clearIncludeLocalDevice() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get excludeNonLocalDevices => $_getBF(3);
  @$pb.TagNumber(4)
  set excludeNonLocalDevices($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasExcludeNonLocalDevices() => $_has(3);
  @$pb.TagNumber(4)
  void clearExcludeNonLocalDevices() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get includeUserMatchUnauthenticatedDevices => $_getBF(4);
  @$pb.TagNumber(5)
  set includeUserMatchUnauthenticatedDevices($core.bool value) =>
      $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIncludeUserMatchUnauthenticatedDevices() => $_has(4);
  @$pb.TagNumber(5)
  void clearIncludeUserMatchUnauthenticatedDevices() => $_clearField(5);
}

class StateResponse_Hifi extends $pb.GeneratedMessage {
  factory StateResponse_Hifi({
    $core.bool? fullySupported,
    $core.bool? userEligible,
    $core.bool? deviceSupported,
  }) {
    final result = StateResponse_Hifi._();
    if (fullySupported != null) result.fullySupported = fullySupported;
    if (userEligible != null) result.userEligible = userEligible;
    if (deviceSupported != null) result.deviceSupported = deviceSupported;
    return result;
  }

  StateResponse_Hifi._();

  factory StateResponse_Hifi.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StateResponse_Hifi()..mergeFromBuffer(data, registry);
  factory StateResponse_Hifi.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StateResponse_Hifi()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StateResponse.Hifi',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: StateResponse_Hifi.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'fullySupported')
    ..aOB(2, _omitFieldNames ? '' : 'userEligible')
    ..aOB(3, _omitFieldNames ? '' : 'deviceSupported')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StateResponse_Hifi clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StateResponse_Hifi copyWith(void Function(StateResponse_Hifi) updates) =>
      super.copyWith((message) => updates(message as StateResponse_Hifi))
          as StateResponse_Hifi;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StateResponse_Hifi() / StateResponse_Hifi.new instead')
  static StateResponse_Hifi create() => StateResponse_Hifi._();
  static $pb.GeneratedMessage $_createMessage() => StateResponse_Hifi._();
  @$core.override
  StateResponse_Hifi createEmptyInstance() => StateResponse_Hifi._();
  @$core.pragma('dart2js:noInline')
  static StateResponse_Hifi getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<StateResponse_Hifi>(
      StateResponse_Hifi.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static StateResponse_Hifi? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get fullySupported => $_getBF(0);
  @$pb.TagNumber(1)
  set fullySupported($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFullySupported() => $_has(0);
  @$pb.TagNumber(1)
  void clearFullySupported() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get userEligible => $_getBF(1);
  @$pb.TagNumber(2)
  set userEligible($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserEligible() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserEligible() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get deviceSupported => $_getBF(2);
  @$pb.TagNumber(3)
  set deviceSupported($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeviceSupported() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeviceSupported() => $_clearField(3);
}

class StateResponse_Incarnation extends $pb.GeneratedMessage {
  factory StateResponse_Incarnation({
    LoginType? loginType,
    $core.String? identifier,
    $core.bool? preferred,
    ProtocolChoiceReason? preferredReason,
    $core.String? connectStateIdentifier,
  }) {
    final result = StateResponse_Incarnation._();
    if (loginType != null) result.loginType = loginType;
    if (identifier != null) result.identifier = identifier;
    if (preferred != null) result.preferred = preferred;
    if (preferredReason != null) result.preferredReason = preferredReason;
    if (connectStateIdentifier != null)
      result.connectStateIdentifier = connectStateIdentifier;
    return result;
  }

  StateResponse_Incarnation._();

  factory StateResponse_Incarnation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StateResponse_Incarnation()..mergeFromBuffer(data, registry);
  factory StateResponse_Incarnation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StateResponse_Incarnation()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StateResponse.Incarnation',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: StateResponse_Incarnation.$_createMessage)
    ..aE<LoginType>(1, _omitFieldNames ? '' : 'loginType',
        enumValues: LoginType.values)
    ..aOS(2, _omitFieldNames ? '' : 'identifier')
    ..aOB(3, _omitFieldNames ? '' : 'preferred')
    ..aE<ProtocolChoiceReason>(4, _omitFieldNames ? '' : 'preferredReason',
        enumValues: ProtocolChoiceReason.values)
    ..aOS(5, _omitFieldNames ? '' : 'connectStateIdentifier')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StateResponse_Incarnation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StateResponse_Incarnation copyWith(
          void Function(StateResponse_Incarnation) updates) =>
      super.copyWith((message) => updates(message as StateResponse_Incarnation))
          as StateResponse_Incarnation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use StateResponse_Incarnation() / StateResponse_Incarnation.new instead')
  static StateResponse_Incarnation create() => StateResponse_Incarnation._();
  static $pb.GeneratedMessage $_createMessage() =>
      StateResponse_Incarnation._();
  @$core.override
  StateResponse_Incarnation createEmptyInstance() =>
      StateResponse_Incarnation._();
  @$core.pragma('dart2js:noInline')
  static StateResponse_Incarnation getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created =
        $pb.GeneratedMessage.$_defaultFor<StateResponse_Incarnation>(
      StateResponse_Incarnation.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static StateResponse_Incarnation? _defaultInstance;

  @$pb.TagNumber(1)
  LoginType get loginType => $_getN(0);
  @$pb.TagNumber(1)
  set loginType(LoginType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLoginType() => $_has(0);
  @$pb.TagNumber(1)
  void clearLoginType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get identifier => $_getSZ(1);
  @$pb.TagNumber(2)
  set identifier($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIdentifier() => $_has(1);
  @$pb.TagNumber(2)
  void clearIdentifier() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get preferred => $_getBF(2);
  @$pb.TagNumber(3)
  set preferred($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPreferred() => $_has(2);
  @$pb.TagNumber(3)
  void clearPreferred() => $_clearField(3);

  @$pb.TagNumber(4)
  ProtocolChoiceReason get preferredReason => $_getN(3);
  @$pb.TagNumber(4)
  set preferredReason(ProtocolChoiceReason value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPreferredReason() => $_has(3);
  @$pb.TagNumber(4)
  void clearPreferredReason() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get connectStateIdentifier => $_getSZ(4);
  @$pb.TagNumber(5)
  set connectStateIdentifier($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasConnectStateIdentifier() => $_has(4);
  @$pb.TagNumber(5)
  void clearConnectStateIdentifier() => $_clearField(5);
}

class StateResponse_Device extends $pb.GeneratedMessage {
  factory StateResponse_Device({
    $core.bool? isSelf,
    $core.String? localIdentifier,
    $core.String? deduplicationId,
    $core.String? connectStateIdentifier,
    $core.String? name,
    $core.String? type,
    $core.String? state,
    $core.bool? isDisabled,
    $core.bool? isActive,
    $core.bool? isBeingActivated,
    $core.bool? isZeroconf,
    $core.bool? isWebapp,
    $core.bool? isLocal,
    $core.bool? isGroup,
    $core.bool? isOffline,
    $core.bool? isSocialConnect,
    $fixnum.Int64? creationTimeMs,
    $core.int? volume,
    StateResponse_Hifi? hifi,
    $core.String? license,
    $core.bool? supportsOnDemand,
    $core.bool? supportsVolume,
    $core.bool? supportsLogout,
    $core.bool? supportsRename,
    $core.bool? supportsAlarm,
    $core.bool? isVoiceEnabled,
    $core.bool? isNewlyDiscovered,
    $core.Iterable<$core.String>? supportedMediaTypes,
    $core.String? brandDisplayName,
    $core.String? modelDisplayName,
    $core.int? volumeSteps,
    $core.String? capabilities,
    $core.Iterable<StateResponse_Incarnation>? incarnations,
    $core.int? aliasId,
    $core.bool? supportsDj,
    $core.String? libraryVersion,
    OutputPeripheral? outputPeripheral,
    $core.String? localIp,
    $core.int? discoveryMethod,
    $core.bool? supportsRemoteSleepTimer,
    $core.bool? supportsPlaylistMixing,
    $0.GroupData? groupData,
    $core.bool? isPublic,
    $core.bool? supportsRemoteAudioQualityControl,
    $core.bool? isAuthenticatedWithCurrentUser,
    $core.bool? supportsZephyr,
    $core.bool? supportsGapless,
    $core.bool? supportsCrossfade,
  }) {
    final result = StateResponse_Device._();
    if (isSelf != null) result.isSelf = isSelf;
    if (localIdentifier != null) result.localIdentifier = localIdentifier;
    if (deduplicationId != null) result.deduplicationId = deduplicationId;
    if (connectStateIdentifier != null)
      result.connectStateIdentifier = connectStateIdentifier;
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    if (state != null) result.state = state;
    if (isDisabled != null) result.isDisabled = isDisabled;
    if (isActive != null) result.isActive = isActive;
    if (isBeingActivated != null) result.isBeingActivated = isBeingActivated;
    if (isZeroconf != null) result.isZeroconf = isZeroconf;
    if (isWebapp != null) result.isWebapp = isWebapp;
    if (isLocal != null) result.isLocal = isLocal;
    if (isGroup != null) result.isGroup = isGroup;
    if (isOffline != null) result.isOffline = isOffline;
    if (isSocialConnect != null) result.isSocialConnect = isSocialConnect;
    if (creationTimeMs != null) result.creationTimeMs = creationTimeMs;
    if (volume != null) result.volume = volume;
    if (hifi != null) result.hifi = hifi;
    if (license != null) result.license = license;
    if (supportsOnDemand != null) result.supportsOnDemand = supportsOnDemand;
    if (supportsVolume != null) result.supportsVolume = supportsVolume;
    if (supportsLogout != null) result.supportsLogout = supportsLogout;
    if (supportsRename != null) result.supportsRename = supportsRename;
    if (supportsAlarm != null) result.supportsAlarm = supportsAlarm;
    if (isVoiceEnabled != null) result.isVoiceEnabled = isVoiceEnabled;
    if (isNewlyDiscovered != null) result.isNewlyDiscovered = isNewlyDiscovered;
    if (supportedMediaTypes != null)
      result.supportedMediaTypes.addAll(supportedMediaTypes);
    if (brandDisplayName != null) result.brandDisplayName = brandDisplayName;
    if (modelDisplayName != null) result.modelDisplayName = modelDisplayName;
    if (volumeSteps != null) result.volumeSteps = volumeSteps;
    if (capabilities != null) result.capabilities = capabilities;
    if (incarnations != null) result.incarnations.addAll(incarnations);
    if (aliasId != null) result.aliasId = aliasId;
    if (supportsDj != null) result.supportsDj = supportsDj;
    if (libraryVersion != null) result.libraryVersion = libraryVersion;
    if (outputPeripheral != null) result.outputPeripheral = outputPeripheral;
    if (localIp != null) result.localIp = localIp;
    if (discoveryMethod != null) result.discoveryMethod = discoveryMethod;
    if (supportsRemoteSleepTimer != null)
      result.supportsRemoteSleepTimer = supportsRemoteSleepTimer;
    if (supportsPlaylistMixing != null)
      result.supportsPlaylistMixing = supportsPlaylistMixing;
    if (groupData != null) result.groupData = groupData;
    if (isPublic != null) result.isPublic = isPublic;
    if (supportsRemoteAudioQualityControl != null)
      result.supportsRemoteAudioQualityControl =
          supportsRemoteAudioQualityControl;
    if (isAuthenticatedWithCurrentUser != null)
      result.isAuthenticatedWithCurrentUser = isAuthenticatedWithCurrentUser;
    if (supportsZephyr != null) result.supportsZephyr = supportsZephyr;
    if (supportsGapless != null) result.supportsGapless = supportsGapless;
    if (supportsCrossfade != null) result.supportsCrossfade = supportsCrossfade;
    return result;
  }

  StateResponse_Device._();

  factory StateResponse_Device.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StateResponse_Device()..mergeFromBuffer(data, registry);
  factory StateResponse_Device.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StateResponse_Device()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StateResponse.Device',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: StateResponse_Device.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'isSelf')
    ..aOS(2, _omitFieldNames ? '' : 'localIdentifier')
    ..aOS(3, _omitFieldNames ? '' : 'deduplicationId')
    ..aOS(4, _omitFieldNames ? '' : 'connectStateIdentifier')
    ..aOS(5, _omitFieldNames ? '' : 'name')
    ..aOS(6, _omitFieldNames ? '' : 'type')
    ..aOS(7, _omitFieldNames ? '' : 'state')
    ..aOB(8, _omitFieldNames ? '' : 'isDisabled')
    ..aOB(9, _omitFieldNames ? '' : 'isActive')
    ..aOB(10, _omitFieldNames ? '' : 'isBeingActivated')
    ..aOB(11, _omitFieldNames ? '' : 'isZeroconf')
    ..aOB(12, _omitFieldNames ? '' : 'isWebapp')
    ..aOB(14, _omitFieldNames ? '' : 'isLocal')
    ..aOB(15, _omitFieldNames ? '' : 'isGroup')
    ..aOB(16, _omitFieldNames ? '' : 'isOffline')
    ..aOB(17, _omitFieldNames ? '' : 'isSocialConnect')
    ..a<$fixnum.Int64>(
        18, _omitFieldNames ? '' : 'creationTimeMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(19, _omitFieldNames ? '' : 'volume', fieldType: $pb.PbFieldType.OU3)
    ..aOM<StateResponse_Hifi>(20, _omitFieldNames ? '' : 'hifi',
        subBuilder: StateResponse_Hifi.$_createMessage)
    ..aOS(21, _omitFieldNames ? '' : 'license')
    ..aOB(22, _omitFieldNames ? '' : 'supportsOnDemand')
    ..aOB(23, _omitFieldNames ? '' : 'supportsVolume')
    ..aOB(24, _omitFieldNames ? '' : 'supportsLogout')
    ..aOB(25, _omitFieldNames ? '' : 'supportsRename')
    ..aOB(26, _omitFieldNames ? '' : 'supportsAlarm')
    ..aOB(27, _omitFieldNames ? '' : 'isVoiceEnabled')
    ..aOB(28, _omitFieldNames ? '' : 'isNewlyDiscovered')
    ..pPS(29, _omitFieldNames ? '' : 'supportedMediaTypes')
    ..aOS(30, _omitFieldNames ? '' : 'brandDisplayName')
    ..aOS(31, _omitFieldNames ? '' : 'modelDisplayName')
    ..aI(32, _omitFieldNames ? '' : 'volumeSteps',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(33, _omitFieldNames ? '' : 'capabilities')
    ..pPM<StateResponse_Incarnation>(34, _omitFieldNames ? '' : 'incarnations',
        subBuilder: StateResponse_Incarnation.$_createMessage)
    ..aI(35, _omitFieldNames ? '' : 'aliasId', fieldType: $pb.PbFieldType.OU3)
    ..aOB(36, _omitFieldNames ? '' : 'supportsDj')
    ..aOS(37, _omitFieldNames ? '' : 'libraryVersion')
    ..aOM<OutputPeripheral>(38, _omitFieldNames ? '' : 'outputPeripheral',
        subBuilder: OutputPeripheral.$_createMessage)
    ..aOS(39, _omitFieldNames ? '' : 'localIp')
    ..aI(40, _omitFieldNames ? '' : 'discoveryMethod',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(41, _omitFieldNames ? '' : 'supportsRemoteSleepTimer')
    ..aOB(42, _omitFieldNames ? '' : 'supportsPlaylistMixing')
    ..aOM<$0.GroupData>(43, _omitFieldNames ? '' : 'groupData',
        subBuilder: $0.GroupData.$_createMessage)
    ..aOB(44, _omitFieldNames ? '' : 'isPublic')
    ..aOB(45, _omitFieldNames ? '' : 'supportsRemoteAudioQualityControl')
    ..aOB(46, _omitFieldNames ? '' : 'isAuthenticatedWithCurrentUser')
    ..aOB(47, _omitFieldNames ? '' : 'supportsZephyr')
    ..aOB(48, _omitFieldNames ? '' : 'supportsGapless')
    ..aOB(49, _omitFieldNames ? '' : 'supportsCrossfade')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StateResponse_Device clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StateResponse_Device copyWith(void Function(StateResponse_Device) updates) =>
      super.copyWith((message) => updates(message as StateResponse_Device))
          as StateResponse_Device;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use StateResponse_Device() / StateResponse_Device.new instead')
  static StateResponse_Device create() => StateResponse_Device._();
  static $pb.GeneratedMessage $_createMessage() => StateResponse_Device._();
  @$core.override
  StateResponse_Device createEmptyInstance() => StateResponse_Device._();
  @$core.pragma('dart2js:noInline')
  static StateResponse_Device getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<StateResponse_Device>(
      StateResponse_Device.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static StateResponse_Device? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isSelf => $_getBF(0);
  @$pb.TagNumber(1)
  set isSelf($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIsSelf() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsSelf() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get localIdentifier => $_getSZ(1);
  @$pb.TagNumber(2)
  set localIdentifier($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLocalIdentifier() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocalIdentifier() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get deduplicationId => $_getSZ(2);
  @$pb.TagNumber(3)
  set deduplicationId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeduplicationId() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeduplicationId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get connectStateIdentifier => $_getSZ(3);
  @$pb.TagNumber(4)
  set connectStateIdentifier($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasConnectStateIdentifier() => $_has(3);
  @$pb.TagNumber(4)
  void clearConnectStateIdentifier() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get name => $_getSZ(4);
  @$pb.TagNumber(5)
  set name($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasName() => $_has(4);
  @$pb.TagNumber(5)
  void clearName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get type => $_getSZ(5);
  @$pb.TagNumber(6)
  set type($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasType() => $_has(5);
  @$pb.TagNumber(6)
  void clearType() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get state => $_getSZ(6);
  @$pb.TagNumber(7)
  set state($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasState() => $_has(6);
  @$pb.TagNumber(7)
  void clearState() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get isDisabled => $_getBF(7);
  @$pb.TagNumber(8)
  set isDisabled($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIsDisabled() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsDisabled() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get isActive => $_getBF(8);
  @$pb.TagNumber(9)
  set isActive($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasIsActive() => $_has(8);
  @$pb.TagNumber(9)
  void clearIsActive() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get isBeingActivated => $_getBF(9);
  @$pb.TagNumber(10)
  set isBeingActivated($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasIsBeingActivated() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsBeingActivated() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get isZeroconf => $_getBF(10);
  @$pb.TagNumber(11)
  set isZeroconf($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasIsZeroconf() => $_has(10);
  @$pb.TagNumber(11)
  void clearIsZeroconf() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get isWebapp => $_getBF(11);
  @$pb.TagNumber(12)
  set isWebapp($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasIsWebapp() => $_has(11);
  @$pb.TagNumber(12)
  void clearIsWebapp() => $_clearField(12);

  /// Tag 13 is unused
  @$pb.TagNumber(14)
  $core.bool get isLocal => $_getBF(12);
  @$pb.TagNumber(14)
  set isLocal($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(14)
  $core.bool hasIsLocal() => $_has(12);
  @$pb.TagNumber(14)
  void clearIsLocal() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.bool get isGroup => $_getBF(13);
  @$pb.TagNumber(15)
  set isGroup($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(15)
  $core.bool hasIsGroup() => $_has(13);
  @$pb.TagNumber(15)
  void clearIsGroup() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.bool get isOffline => $_getBF(14);
  @$pb.TagNumber(16)
  set isOffline($core.bool value) => $_setBool(14, value);
  @$pb.TagNumber(16)
  $core.bool hasIsOffline() => $_has(14);
  @$pb.TagNumber(16)
  void clearIsOffline() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.bool get isSocialConnect => $_getBF(15);
  @$pb.TagNumber(17)
  set isSocialConnect($core.bool value) => $_setBool(15, value);
  @$pb.TagNumber(17)
  $core.bool hasIsSocialConnect() => $_has(15);
  @$pb.TagNumber(17)
  void clearIsSocialConnect() => $_clearField(17);

  @$pb.TagNumber(18)
  $fixnum.Int64 get creationTimeMs => $_getI64(16);
  @$pb.TagNumber(18)
  set creationTimeMs($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(18)
  $core.bool hasCreationTimeMs() => $_has(16);
  @$pb.TagNumber(18)
  void clearCreationTimeMs() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.int get volume => $_getIZ(17);
  @$pb.TagNumber(19)
  set volume($core.int value) => $_setUnsignedInt32(17, value);
  @$pb.TagNumber(19)
  $core.bool hasVolume() => $_has(17);
  @$pb.TagNumber(19)
  void clearVolume() => $_clearField(19);

  @$pb.TagNumber(20)
  StateResponse_Hifi get hifi => $_getN(18);
  @$pb.TagNumber(20)
  set hifi(StateResponse_Hifi value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasHifi() => $_has(18);
  @$pb.TagNumber(20)
  void clearHifi() => $_clearField(20);
  @$pb.TagNumber(20)
  StateResponse_Hifi ensureHifi() => $_ensure(18);

  @$pb.TagNumber(21)
  $core.String get license => $_getSZ(19);
  @$pb.TagNumber(21)
  set license($core.String value) => $_setString(19, value);
  @$pb.TagNumber(21)
  $core.bool hasLicense() => $_has(19);
  @$pb.TagNumber(21)
  void clearLicense() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.bool get supportsOnDemand => $_getBF(20);
  @$pb.TagNumber(22)
  set supportsOnDemand($core.bool value) => $_setBool(20, value);
  @$pb.TagNumber(22)
  $core.bool hasSupportsOnDemand() => $_has(20);
  @$pb.TagNumber(22)
  void clearSupportsOnDemand() => $_clearField(22);

  @$pb.TagNumber(23)
  $core.bool get supportsVolume => $_getBF(21);
  @$pb.TagNumber(23)
  set supportsVolume($core.bool value) => $_setBool(21, value);
  @$pb.TagNumber(23)
  $core.bool hasSupportsVolume() => $_has(21);
  @$pb.TagNumber(23)
  void clearSupportsVolume() => $_clearField(23);

  @$pb.TagNumber(24)
  $core.bool get supportsLogout => $_getBF(22);
  @$pb.TagNumber(24)
  set supportsLogout($core.bool value) => $_setBool(22, value);
  @$pb.TagNumber(24)
  $core.bool hasSupportsLogout() => $_has(22);
  @$pb.TagNumber(24)
  void clearSupportsLogout() => $_clearField(24);

  @$pb.TagNumber(25)
  $core.bool get supportsRename => $_getBF(23);
  @$pb.TagNumber(25)
  set supportsRename($core.bool value) => $_setBool(23, value);
  @$pb.TagNumber(25)
  $core.bool hasSupportsRename() => $_has(23);
  @$pb.TagNumber(25)
  void clearSupportsRename() => $_clearField(25);

  @$pb.TagNumber(26)
  $core.bool get supportsAlarm => $_getBF(24);
  @$pb.TagNumber(26)
  set supportsAlarm($core.bool value) => $_setBool(24, value);
  @$pb.TagNumber(26)
  $core.bool hasSupportsAlarm() => $_has(24);
  @$pb.TagNumber(26)
  void clearSupportsAlarm() => $_clearField(26);

  @$pb.TagNumber(27)
  $core.bool get isVoiceEnabled => $_getBF(25);
  @$pb.TagNumber(27)
  set isVoiceEnabled($core.bool value) => $_setBool(25, value);
  @$pb.TagNumber(27)
  $core.bool hasIsVoiceEnabled() => $_has(25);
  @$pb.TagNumber(27)
  void clearIsVoiceEnabled() => $_clearField(27);

  @$pb.TagNumber(28)
  $core.bool get isNewlyDiscovered => $_getBF(26);
  @$pb.TagNumber(28)
  set isNewlyDiscovered($core.bool value) => $_setBool(26, value);
  @$pb.TagNumber(28)
  $core.bool hasIsNewlyDiscovered() => $_has(26);
  @$pb.TagNumber(28)
  void clearIsNewlyDiscovered() => $_clearField(28);

  @$pb.TagNumber(29)
  $pb.PbList<$core.String> get supportedMediaTypes => $_getList(27);

  @$pb.TagNumber(30)
  $core.String get brandDisplayName => $_getSZ(28);
  @$pb.TagNumber(30)
  set brandDisplayName($core.String value) => $_setString(28, value);
  @$pb.TagNumber(30)
  $core.bool hasBrandDisplayName() => $_has(28);
  @$pb.TagNumber(30)
  void clearBrandDisplayName() => $_clearField(30);

  @$pb.TagNumber(31)
  $core.String get modelDisplayName => $_getSZ(29);
  @$pb.TagNumber(31)
  set modelDisplayName($core.String value) => $_setString(29, value);
  @$pb.TagNumber(31)
  $core.bool hasModelDisplayName() => $_has(29);
  @$pb.TagNumber(31)
  void clearModelDisplayName() => $_clearField(31);

  @$pb.TagNumber(32)
  $core.int get volumeSteps => $_getIZ(30);
  @$pb.TagNumber(32)
  set volumeSteps($core.int value) => $_setUnsignedInt32(30, value);
  @$pb.TagNumber(32)
  $core.bool hasVolumeSteps() => $_has(30);
  @$pb.TagNumber(32)
  void clearVolumeSteps() => $_clearField(32);

  @$pb.TagNumber(33)
  $core.String get capabilities => $_getSZ(31);
  @$pb.TagNumber(33)
  set capabilities($core.String value) => $_setString(31, value);
  @$pb.TagNumber(33)
  $core.bool hasCapabilities() => $_has(31);
  @$pb.TagNumber(33)
  void clearCapabilities() => $_clearField(33);

  @$pb.TagNumber(34)
  $pb.PbList<StateResponse_Incarnation> get incarnations => $_getList(32);

  @$pb.TagNumber(35)
  $core.int get aliasId => $_getIZ(33);
  @$pb.TagNumber(35)
  set aliasId($core.int value) => $_setUnsignedInt32(33, value);
  @$pb.TagNumber(35)
  $core.bool hasAliasId() => $_has(33);
  @$pb.TagNumber(35)
  void clearAliasId() => $_clearField(35);

  @$pb.TagNumber(36)
  $core.bool get supportsDj => $_getBF(34);
  @$pb.TagNumber(36)
  set supportsDj($core.bool value) => $_setBool(34, value);
  @$pb.TagNumber(36)
  $core.bool hasSupportsDj() => $_has(34);
  @$pb.TagNumber(36)
  void clearSupportsDj() => $_clearField(36);

  @$pb.TagNumber(37)
  $core.String get libraryVersion => $_getSZ(35);
  @$pb.TagNumber(37)
  set libraryVersion($core.String value) => $_setString(35, value);
  @$pb.TagNumber(37)
  $core.bool hasLibraryVersion() => $_has(35);
  @$pb.TagNumber(37)
  void clearLibraryVersion() => $_clearField(37);

  @$pb.TagNumber(38)
  OutputPeripheral get outputPeripheral => $_getN(36);
  @$pb.TagNumber(38)
  set outputPeripheral(OutputPeripheral value) => $_setField(38, value);
  @$pb.TagNumber(38)
  $core.bool hasOutputPeripheral() => $_has(36);
  @$pb.TagNumber(38)
  void clearOutputPeripheral() => $_clearField(38);
  @$pb.TagNumber(38)
  OutputPeripheral ensureOutputPeripheral() => $_ensure(36);

  @$pb.TagNumber(39)
  $core.String get localIp => $_getSZ(37);
  @$pb.TagNumber(39)
  set localIp($core.String value) => $_setString(37, value);
  @$pb.TagNumber(39)
  $core.bool hasLocalIp() => $_has(37);
  @$pb.TagNumber(39)
  void clearLocalIp() => $_clearField(39);

  @$pb.TagNumber(40)
  $core.int get discoveryMethod => $_getIZ(38);
  @$pb.TagNumber(40)
  set discoveryMethod($core.int value) => $_setUnsignedInt32(38, value);
  @$pb.TagNumber(40)
  $core.bool hasDiscoveryMethod() => $_has(38);
  @$pb.TagNumber(40)
  void clearDiscoveryMethod() => $_clearField(40);

  @$pb.TagNumber(41)
  $core.bool get supportsRemoteSleepTimer => $_getBF(39);
  @$pb.TagNumber(41)
  set supportsRemoteSleepTimer($core.bool value) => $_setBool(39, value);
  @$pb.TagNumber(41)
  $core.bool hasSupportsRemoteSleepTimer() => $_has(39);
  @$pb.TagNumber(41)
  void clearSupportsRemoteSleepTimer() => $_clearField(41);

  @$pb.TagNumber(42)
  $core.bool get supportsPlaylistMixing => $_getBF(40);
  @$pb.TagNumber(42)
  set supportsPlaylistMixing($core.bool value) => $_setBool(40, value);
  @$pb.TagNumber(42)
  $core.bool hasSupportsPlaylistMixing() => $_has(40);
  @$pb.TagNumber(42)
  void clearSupportsPlaylistMixing() => $_clearField(42);

  @$pb.TagNumber(43)
  $0.GroupData get groupData => $_getN(41);
  @$pb.TagNumber(43)
  set groupData($0.GroupData value) => $_setField(43, value);
  @$pb.TagNumber(43)
  $core.bool hasGroupData() => $_has(41);
  @$pb.TagNumber(43)
  void clearGroupData() => $_clearField(43);
  @$pb.TagNumber(43)
  $0.GroupData ensureGroupData() => $_ensure(41);

  @$pb.TagNumber(44)
  $core.bool get isPublic => $_getBF(42);
  @$pb.TagNumber(44)
  set isPublic($core.bool value) => $_setBool(42, value);
  @$pb.TagNumber(44)
  $core.bool hasIsPublic() => $_has(42);
  @$pb.TagNumber(44)
  void clearIsPublic() => $_clearField(44);

  @$pb.TagNumber(45)
  $core.bool get supportsRemoteAudioQualityControl => $_getBF(43);
  @$pb.TagNumber(45)
  set supportsRemoteAudioQualityControl($core.bool value) =>
      $_setBool(43, value);
  @$pb.TagNumber(45)
  $core.bool hasSupportsRemoteAudioQualityControl() => $_has(43);
  @$pb.TagNumber(45)
  void clearSupportsRemoteAudioQualityControl() => $_clearField(45);

  @$pb.TagNumber(46)
  $core.bool get isAuthenticatedWithCurrentUser => $_getBF(44);
  @$pb.TagNumber(46)
  set isAuthenticatedWithCurrentUser($core.bool value) => $_setBool(44, value);
  @$pb.TagNumber(46)
  $core.bool hasIsAuthenticatedWithCurrentUser() => $_has(44);
  @$pb.TagNumber(46)
  void clearIsAuthenticatedWithCurrentUser() => $_clearField(46);

  @$pb.TagNumber(47)
  $core.bool get supportsZephyr => $_getBF(45);
  @$pb.TagNumber(47)
  set supportsZephyr($core.bool value) => $_setBool(45, value);
  @$pb.TagNumber(47)
  $core.bool hasSupportsZephyr() => $_has(45);
  @$pb.TagNumber(47)
  void clearSupportsZephyr() => $_clearField(47);

  @$pb.TagNumber(48)
  $core.bool get supportsGapless => $_getBF(46);
  @$pb.TagNumber(48)
  set supportsGapless($core.bool value) => $_setBool(46, value);
  @$pb.TagNumber(48)
  $core.bool hasSupportsGapless() => $_has(46);
  @$pb.TagNumber(48)
  void clearSupportsGapless() => $_clearField(48);

  @$pb.TagNumber(49)
  $core.bool get supportsCrossfade => $_getBF(47);
  @$pb.TagNumber(49)
  set supportsCrossfade($core.bool value) => $_setBool(47, value);
  @$pb.TagNumber(49)
  $core.bool hasSupportsCrossfade() => $_has(47);
  @$pb.TagNumber(49)
  void clearSupportsCrossfade() => $_clearField(49);
}

class StateResponse extends $pb.GeneratedMessage {
  factory StateResponse({
    $core.bool? isRunning,
    $core.bool? isConnected,
    $core.String? localName,
    $core.bool? shouldUseLocalPlayback,
    $core.Iterable<StateResponse_Device>? devices,
    $core.bool? isActive,
    $core.bool? isActiveOnSameDevice,
    $core.bool? isSyncedWithBackend,
  }) {
    final result = StateResponse._();
    if (isRunning != null) result.isRunning = isRunning;
    if (isConnected != null) result.isConnected = isConnected;
    if (localName != null) result.localName = localName;
    if (shouldUseLocalPlayback != null)
      result.shouldUseLocalPlayback = shouldUseLocalPlayback;
    if (devices != null) result.devices.addAll(devices);
    if (isActive != null) result.isActive = isActive;
    if (isActiveOnSameDevice != null)
      result.isActiveOnSameDevice = isActiveOnSameDevice;
    if (isSyncedWithBackend != null)
      result.isSyncedWithBackend = isSyncedWithBackend;
    return result;
  }

  StateResponse._();

  factory StateResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StateResponse()..mergeFromBuffer(data, registry);
  factory StateResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StateResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StateResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: StateResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'isRunning')
    ..aOB(2, _omitFieldNames ? '' : 'isConnected')
    ..aOS(3, _omitFieldNames ? '' : 'localName')
    ..aOB(4, _omitFieldNames ? '' : 'shouldUseLocalPlayback')
    ..pPM<StateResponse_Device>(5, _omitFieldNames ? '' : 'devices',
        subBuilder: StateResponse_Device.$_createMessage)
    ..aOB(6, _omitFieldNames ? '' : 'isActive')
    ..aOB(7, _omitFieldNames ? '' : 'isActiveOnSameDevice')
    ..aOB(8, _omitFieldNames ? '' : 'isSyncedWithBackend')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StateResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StateResponse copyWith(void Function(StateResponse) updates) =>
      super.copyWith((message) => updates(message as StateResponse))
          as StateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StateResponse() / StateResponse.new instead')
  static StateResponse create() => StateResponse._();
  static $pb.GeneratedMessage $_createMessage() => StateResponse._();
  @$core.override
  StateResponse createEmptyInstance() => StateResponse._();
  @$core.pragma('dart2js:noInline')
  static StateResponse getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<StateResponse>(
      StateResponse.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static StateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isRunning => $_getBF(0);
  @$pb.TagNumber(1)
  set isRunning($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIsRunning() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsRunning() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isConnected => $_getBF(1);
  @$pb.TagNumber(2)
  set isConnected($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsConnected() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsConnected() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get localName => $_getSZ(2);
  @$pb.TagNumber(3)
  set localName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLocalName() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocalName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get shouldUseLocalPlayback => $_getBF(3);
  @$pb.TagNumber(4)
  set shouldUseLocalPlayback($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasShouldUseLocalPlayback() => $_has(3);
  @$pb.TagNumber(4)
  void clearShouldUseLocalPlayback() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<StateResponse_Device> get devices => $_getList(4);

  @$pb.TagNumber(6)
  $core.bool get isActive => $_getBF(5);
  @$pb.TagNumber(6)
  set isActive($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsActive() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsActive() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get isActiveOnSameDevice => $_getBF(6);
  @$pb.TagNumber(7)
  set isActiveOnSameDevice($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasIsActiveOnSameDevice() => $_has(6);
  @$pb.TagNumber(7)
  void clearIsActiveOnSameDevice() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get isSyncedWithBackend => $_getBF(7);
  @$pb.TagNumber(8)
  set isSyncedWithBackend($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIsSyncedWithBackend() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsSyncedWithBackend() => $_clearField(8);
}

class TransferRequest extends $pb.GeneratedMessage {
  factory TransferRequest({
    $1.LoggingParams? loggingParams,
    $core.String? connectDeviceIdentifier,
    $core.bool? dodo,
  }) {
    final result = TransferRequest._();
    if (loggingParams != null) result.loggingParams = loggingParams;
    if (connectDeviceIdentifier != null)
      result.connectDeviceIdentifier = connectDeviceIdentifier;
    if (dodo != null) result.dodo = dodo;
    return result;
  }

  TransferRequest._();

  factory TransferRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TransferRequest()..mergeFromBuffer(data, registry);
  factory TransferRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TransferRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TransferRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: TransferRequest.$_createMessage)
    ..aOM<$1.LoggingParams>(1, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'connectDeviceIdentifier')
    ..aOB(3, _omitFieldNames ? '' : 'dodo')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferRequest copyWith(void Function(TransferRequest) updates) =>
      super.copyWith((message) => updates(message as TransferRequest))
          as TransferRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TransferRequest() / TransferRequest.new instead')
  static TransferRequest create() => TransferRequest._();
  static $pb.GeneratedMessage $_createMessage() => TransferRequest._();
  @$core.override
  TransferRequest createEmptyInstance() => TransferRequest._();
  @$core.pragma('dart2js:noInline')
  static TransferRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<TransferRequest>(
      TransferRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static TransferRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $1.LoggingParams get loggingParams => $_getN(0);
  @$pb.TagNumber(1)
  set loggingParams($1.LoggingParams value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLoggingParams() => $_has(0);
  @$pb.TagNumber(1)
  void clearLoggingParams() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.LoggingParams ensureLoggingParams() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get connectDeviceIdentifier => $_getSZ(1);
  @$pb.TagNumber(2)
  set connectDeviceIdentifier($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConnectDeviceIdentifier() => $_has(1);
  @$pb.TagNumber(2)
  void clearConnectDeviceIdentifier() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get dodo => $_getBF(2);
  @$pb.TagNumber(3)
  set dodo($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDodo() => $_has(2);
  @$pb.TagNumber(3)
  void clearDodo() => $_clearField(3);
}

class PullRequest extends $pb.GeneratedMessage {
  factory PullRequest({
    $1.LoggingParams? loggingParams,
  }) {
    final result = PullRequest._();
    if (loggingParams != null) result.loggingParams = loggingParams;
    return result;
  }

  PullRequest._();

  factory PullRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PullRequest()..mergeFromBuffer(data, registry);
  factory PullRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PullRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PullRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: PullRequest.$_createMessage)
    ..aOM<$1.LoggingParams>(1, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PullRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PullRequest copyWith(void Function(PullRequest) updates) =>
      super.copyWith((message) => updates(message as PullRequest))
          as PullRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PullRequest() / PullRequest.new instead')
  static PullRequest create() => PullRequest._();
  static $pb.GeneratedMessage $_createMessage() => PullRequest._();
  @$core.override
  PullRequest createEmptyInstance() => PullRequest._();
  @$core.pragma('dart2js:noInline')
  static PullRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<PullRequest>(
      PullRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static PullRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $1.LoggingParams get loggingParams => $_getN(0);
  @$pb.TagNumber(1)
  set loggingParams($1.LoggingParams value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLoggingParams() => $_has(0);
  @$pb.TagNumber(1)
  void clearLoggingParams() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.LoggingParams ensureLoggingParams() => $_ensure(0);
}

class LogoutRequest extends $pb.GeneratedMessage {
  factory LogoutRequest({
    $core.String? connectDeviceIdentifier,
  }) {
    final result = LogoutRequest._();
    if (connectDeviceIdentifier != null)
      result.connectDeviceIdentifier = connectDeviceIdentifier;
    return result;
  }

  LogoutRequest._();

  factory LogoutRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogoutRequest()..mergeFromBuffer(data, registry);
  factory LogoutRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogoutRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogoutRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: LogoutRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'connectDeviceIdentifier')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutRequest copyWith(void Function(LogoutRequest) updates) =>
      super.copyWith((message) => updates(message as LogoutRequest))
          as LogoutRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogoutRequest() / LogoutRequest.new instead')
  static LogoutRequest create() => LogoutRequest._();
  static $pb.GeneratedMessage $_createMessage() => LogoutRequest._();
  @$core.override
  LogoutRequest createEmptyInstance() => LogoutRequest._();
  @$core.pragma('dart2js:noInline')
  static LogoutRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<LogoutRequest>(
      LogoutRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static LogoutRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get connectDeviceIdentifier => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectDeviceIdentifier($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnectDeviceIdentifier() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectDeviceIdentifier() => $_clearField(1);
}

class NotifyAudioRouteChangedRequest extends $pb.GeneratedMessage {
  factory NotifyAudioRouteChangedRequest({
    $core.String? audioOutputDeviceName,
    OutputPeripheralConnectionType? audioOutputDeviceConnectionType,
    $core.String? audioOutputDeviceBrand,
    $core.String? audioOutputDeviceModel,
    OutputPeripheralCategory? audioOutputDeviceCategory,
  }) {
    final result = NotifyAudioRouteChangedRequest._();
    if (audioOutputDeviceName != null)
      result.audioOutputDeviceName = audioOutputDeviceName;
    if (audioOutputDeviceConnectionType != null)
      result.audioOutputDeviceConnectionType = audioOutputDeviceConnectionType;
    if (audioOutputDeviceBrand != null)
      result.audioOutputDeviceBrand = audioOutputDeviceBrand;
    if (audioOutputDeviceModel != null)
      result.audioOutputDeviceModel = audioOutputDeviceModel;
    if (audioOutputDeviceCategory != null)
      result.audioOutputDeviceCategory = audioOutputDeviceCategory;
    return result;
  }

  NotifyAudioRouteChangedRequest._();

  factory NotifyAudioRouteChangedRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NotifyAudioRouteChangedRequest()..mergeFromBuffer(data, registry);
  factory NotifyAudioRouteChangedRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NotifyAudioRouteChangedRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NotifyAudioRouteChangedRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: NotifyAudioRouteChangedRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'audioOutputDeviceName')
    ..aE<OutputPeripheralConnectionType>(
        2, _omitFieldNames ? '' : 'audioOutputDeviceConnectionType',
        enumValues: OutputPeripheralConnectionType.values)
    ..aOS(3, _omitFieldNames ? '' : 'audioOutputDeviceBrand')
    ..aOS(4, _omitFieldNames ? '' : 'audioOutputDeviceModel')
    ..aE<OutputPeripheralCategory>(
        5, _omitFieldNames ? '' : 'audioOutputDeviceCategory',
        enumValues: OutputPeripheralCategory.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotifyAudioRouteChangedRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotifyAudioRouteChangedRequest copyWith(
          void Function(NotifyAudioRouteChangedRequest) updates) =>
      super.copyWith(
              (message) => updates(message as NotifyAudioRouteChangedRequest))
          as NotifyAudioRouteChangedRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use NotifyAudioRouteChangedRequest() / NotifyAudioRouteChangedRequest.new instead')
  static NotifyAudioRouteChangedRequest create() =>
      NotifyAudioRouteChangedRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      NotifyAudioRouteChangedRequest._();
  @$core.override
  NotifyAudioRouteChangedRequest createEmptyInstance() =>
      NotifyAudioRouteChangedRequest._();
  @$core.pragma('dart2js:noInline')
  static NotifyAudioRouteChangedRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created =
        $pb.GeneratedMessage.$_defaultFor<NotifyAudioRouteChangedRequest>(
      NotifyAudioRouteChangedRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static NotifyAudioRouteChangedRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get audioOutputDeviceName => $_getSZ(0);
  @$pb.TagNumber(1)
  set audioOutputDeviceName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAudioOutputDeviceName() => $_has(0);
  @$pb.TagNumber(1)
  void clearAudioOutputDeviceName() => $_clearField(1);

  @$pb.TagNumber(2)
  OutputPeripheralConnectionType get audioOutputDeviceConnectionType =>
      $_getN(1);
  @$pb.TagNumber(2)
  set audioOutputDeviceConnectionType(OutputPeripheralConnectionType value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAudioOutputDeviceConnectionType() => $_has(1);
  @$pb.TagNumber(2)
  void clearAudioOutputDeviceConnectionType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get audioOutputDeviceBrand => $_getSZ(2);
  @$pb.TagNumber(3)
  set audioOutputDeviceBrand($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAudioOutputDeviceBrand() => $_has(2);
  @$pb.TagNumber(3)
  void clearAudioOutputDeviceBrand() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get audioOutputDeviceModel => $_getSZ(3);
  @$pb.TagNumber(4)
  set audioOutputDeviceModel($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAudioOutputDeviceModel() => $_has(3);
  @$pb.TagNumber(4)
  void clearAudioOutputDeviceModel() => $_clearField(4);

  @$pb.TagNumber(5)
  OutputPeripheralCategory get audioOutputDeviceCategory => $_getN(4);
  @$pb.TagNumber(5)
  set audioOutputDeviceCategory(OutputPeripheralCategory value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasAudioOutputDeviceCategory() => $_has(4);
  @$pb.TagNumber(5)
  void clearAudioOutputDeviceCategory() => $_clearField(5);
}

class SetPreferredIncarnationRequest extends $pb.GeneratedMessage {
  factory SetPreferredIncarnationRequest({
    $core.String? deviceId,
    LoginType? preferredLoginType,
    $1.LoggingParams? loggingParams,
  }) {
    final result = SetPreferredIncarnationRequest._();
    if (deviceId != null) result.deviceId = deviceId;
    if (preferredLoginType != null)
      result.preferredLoginType = preferredLoginType;
    if (loggingParams != null) result.loggingParams = loggingParams;
    return result;
  }

  SetPreferredIncarnationRequest._();

  factory SetPreferredIncarnationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetPreferredIncarnationRequest()..mergeFromBuffer(data, registry);
  factory SetPreferredIncarnationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetPreferredIncarnationRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetPreferredIncarnationRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: SetPreferredIncarnationRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..aE<LoginType>(2, _omitFieldNames ? '' : 'preferredLoginType',
        enumValues: LoginType.values)
    ..aOM<$1.LoggingParams>(3, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetPreferredIncarnationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetPreferredIncarnationRequest copyWith(
          void Function(SetPreferredIncarnationRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SetPreferredIncarnationRequest))
          as SetPreferredIncarnationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetPreferredIncarnationRequest() / SetPreferredIncarnationRequest.new instead')
  static SetPreferredIncarnationRequest create() =>
      SetPreferredIncarnationRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      SetPreferredIncarnationRequest._();
  @$core.override
  SetPreferredIncarnationRequest createEmptyInstance() =>
      SetPreferredIncarnationRequest._();
  @$core.pragma('dart2js:noInline')
  static SetPreferredIncarnationRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created =
        $pb.GeneratedMessage.$_defaultFor<SetPreferredIncarnationRequest>(
      SetPreferredIncarnationRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static SetPreferredIncarnationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  LoginType get preferredLoginType => $_getN(1);
  @$pb.TagNumber(2)
  set preferredLoginType(LoginType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPreferredLoginType() => $_has(1);
  @$pb.TagNumber(2)
  void clearPreferredLoginType() => $_clearField(2);

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

class SendCommandRequest extends $pb.GeneratedMessage {
  factory SendCommandRequest({
    $1.LoggingParams? loggingParams,
    $core.String? connectDeviceIdentifier,
    $core.String? commandJson,
  }) {
    final result = SendCommandRequest._();
    if (loggingParams != null) result.loggingParams = loggingParams;
    if (connectDeviceIdentifier != null)
      result.connectDeviceIdentifier = connectDeviceIdentifier;
    if (commandJson != null) result.commandJson = commandJson;
    return result;
  }

  SendCommandRequest._();

  factory SendCommandRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendCommandRequest()..mergeFromBuffer(data, registry);
  factory SendCommandRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendCommandRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendCommandRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: SendCommandRequest.$_createMessage)
    ..aOM<$1.LoggingParams>(1, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'connectDeviceIdentifier')
    ..aOS(3, _omitFieldNames ? '' : 'commandJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendCommandRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendCommandRequest copyWith(void Function(SendCommandRequest) updates) =>
      super.copyWith((message) => updates(message as SendCommandRequest))
          as SendCommandRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SendCommandRequest() / SendCommandRequest.new instead')
  static SendCommandRequest create() => SendCommandRequest._();
  static $pb.GeneratedMessage $_createMessage() => SendCommandRequest._();
  @$core.override
  SendCommandRequest createEmptyInstance() => SendCommandRequest._();
  @$core.pragma('dart2js:noInline')
  static SendCommandRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<SendCommandRequest>(
      SendCommandRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static SendCommandRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $1.LoggingParams get loggingParams => $_getN(0);
  @$pb.TagNumber(1)
  set loggingParams($1.LoggingParams value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLoggingParams() => $_has(0);
  @$pb.TagNumber(1)
  void clearLoggingParams() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.LoggingParams ensureLoggingParams() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get connectDeviceIdentifier => $_getSZ(1);
  @$pb.TagNumber(2)
  set connectDeviceIdentifier($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConnectDeviceIdentifier() => $_has(1);
  @$pb.TagNumber(2)
  void clearConnectDeviceIdentifier() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get commandJson => $_getSZ(2);
  @$pb.TagNumber(3)
  set commandJson($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCommandJson() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommandJson() => $_clearField(3);
}

class SendCommandResponse extends $pb.GeneratedMessage {
  factory SendCommandResponse({
    $core.int? contextPlayerError,
  }) {
    final result = SendCommandResponse._();
    if (contextPlayerError != null)
      result.contextPlayerError = contextPlayerError;
    return result;
  }

  SendCommandResponse._();

  factory SendCommandResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendCommandResponse()..mergeFromBuffer(data, registry);
  factory SendCommandResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendCommandResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendCommandResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: SendCommandResponse.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'contextPlayerError')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendCommandResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendCommandResponse copyWith(void Function(SendCommandResponse) updates) =>
      super.copyWith((message) => updates(message as SendCommandResponse))
          as SendCommandResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SendCommandResponse() / SendCommandResponse.new instead')
  static SendCommandResponse create() => SendCommandResponse._();
  static $pb.GeneratedMessage $_createMessage() => SendCommandResponse._();
  @$core.override
  SendCommandResponse createEmptyInstance() => SendCommandResponse._();
  @$core.pragma('dart2js:noInline')
  static SendCommandResponse getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<SendCommandResponse>(
      SendCommandResponse.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static SendCommandResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get contextPlayerError => $_getIZ(0);
  @$pb.TagNumber(1)
  set contextPlayerError($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasContextPlayerError() => $_has(0);
  @$pb.TagNumber(1)
  void clearContextPlayerError() => $_clearField(1);
}

class RenameRequest extends $pb.GeneratedMessage {
  factory RenameRequest({
    $core.String? deviceId,
    $core.String? newName,
  }) {
    final result = RenameRequest._();
    if (deviceId != null) result.deviceId = deviceId;
    if (newName != null) result.newName = newName;
    return result;
  }

  RenameRequest._();

  factory RenameRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RenameRequest()..mergeFromBuffer(data, registry);
  factory RenameRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RenameRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: RenameRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..aOS(2, _omitFieldNames ? '' : 'newName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameRequest copyWith(void Function(RenameRequest) updates) =>
      super.copyWith((message) => updates(message as RenameRequest))
          as RenameRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RenameRequest() / RenameRequest.new instead')
  static RenameRequest create() => RenameRequest._();
  static $pb.GeneratedMessage $_createMessage() => RenameRequest._();
  @$core.override
  RenameRequest createEmptyInstance() => RenameRequest._();
  @$core.pragma('dart2js:noInline')
  static RenameRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<RenameRequest>(
      RenameRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static RenameRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get newName => $_getSZ(1);
  @$pb.TagNumber(2)
  set newName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNewName() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewName() => $_clearField(2);
}

class CreateStaticGroupRequest extends $pb.GeneratedMessage {
  factory CreateStaticGroupRequest() => CreateStaticGroupRequest._();

  CreateStaticGroupRequest._();

  factory CreateStaticGroupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateStaticGroupRequest()..mergeFromBuffer(data, registry);
  factory CreateStaticGroupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateStaticGroupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateStaticGroupRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: CreateStaticGroupRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateStaticGroupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateStaticGroupRequest copyWith(
          void Function(CreateStaticGroupRequest) updates) =>
      super.copyWith((message) => updates(message as CreateStaticGroupRequest))
          as CreateStaticGroupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateStaticGroupRequest() / CreateStaticGroupRequest.new instead')
  static CreateStaticGroupRequest create() => CreateStaticGroupRequest._();
  static $pb.GeneratedMessage $_createMessage() => CreateStaticGroupRequest._();
  @$core.override
  CreateStaticGroupRequest createEmptyInstance() =>
      CreateStaticGroupRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateStaticGroupRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<CreateStaticGroupRequest>(
      CreateStaticGroupRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static CreateStaticGroupRequest? _defaultInstance;
}

class CreateStaticGroupResponse extends $pb.GeneratedMessage {
  factory CreateStaticGroupResponse() => CreateStaticGroupResponse._();

  CreateStaticGroupResponse._();

  factory CreateStaticGroupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateStaticGroupResponse()..mergeFromBuffer(data, registry);
  factory CreateStaticGroupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateStaticGroupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateStaticGroupResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: CreateStaticGroupResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateStaticGroupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateStaticGroupResponse copyWith(
          void Function(CreateStaticGroupResponse) updates) =>
      super.copyWith((message) => updates(message as CreateStaticGroupResponse))
          as CreateStaticGroupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateStaticGroupResponse() / CreateStaticGroupResponse.new instead')
  static CreateStaticGroupResponse create() => CreateStaticGroupResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      CreateStaticGroupResponse._();
  @$core.override
  CreateStaticGroupResponse createEmptyInstance() =>
      CreateStaticGroupResponse._();
  @$core.pragma('dart2js:noInline')
  static CreateStaticGroupResponse getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created =
        $pb.GeneratedMessage.$_defaultFor<CreateStaticGroupResponse>(
      CreateStaticGroupResponse.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static CreateStaticGroupResponse? _defaultInstance;
}

class RenameGroupRequest extends $pb.GeneratedMessage {
  factory RenameGroupRequest() => RenameGroupRequest._();

  RenameGroupRequest._();

  factory RenameGroupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RenameGroupRequest()..mergeFromBuffer(data, registry);
  factory RenameGroupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RenameGroupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameGroupRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: RenameGroupRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameGroupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameGroupRequest copyWith(void Function(RenameGroupRequest) updates) =>
      super.copyWith((message) => updates(message as RenameGroupRequest))
          as RenameGroupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RenameGroupRequest() / RenameGroupRequest.new instead')
  static RenameGroupRequest create() => RenameGroupRequest._();
  static $pb.GeneratedMessage $_createMessage() => RenameGroupRequest._();
  @$core.override
  RenameGroupRequest createEmptyInstance() => RenameGroupRequest._();
  @$core.pragma('dart2js:noInline')
  static RenameGroupRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<RenameGroupRequest>(
      RenameGroupRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static RenameGroupRequest? _defaultInstance;
}

class RenameGroupResponse extends $pb.GeneratedMessage {
  factory RenameGroupResponse() => RenameGroupResponse._();

  RenameGroupResponse._();

  factory RenameGroupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RenameGroupResponse()..mergeFromBuffer(data, registry);
  factory RenameGroupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RenameGroupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameGroupResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: RenameGroupResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameGroupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameGroupResponse copyWith(void Function(RenameGroupResponse) updates) =>
      super.copyWith((message) => updates(message as RenameGroupResponse))
          as RenameGroupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use RenameGroupResponse() / RenameGroupResponse.new instead')
  static RenameGroupResponse create() => RenameGroupResponse._();
  static $pb.GeneratedMessage $_createMessage() => RenameGroupResponse._();
  @$core.override
  RenameGroupResponse createEmptyInstance() => RenameGroupResponse._();
  @$core.pragma('dart2js:noInline')
  static RenameGroupResponse getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<RenameGroupResponse>(
      RenameGroupResponse.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static RenameGroupResponse? _defaultInstance;
}

class AddDeviceToGroupRequest extends $pb.GeneratedMessage {
  factory AddDeviceToGroupRequest({
    $core.String? connectDeviceIdentifier,
    $core.String? groupDeviceIdentifier,
    $1.LoggingParams? loggingParams,
  }) {
    final result = AddDeviceToGroupRequest._();
    if (connectDeviceIdentifier != null)
      result.connectDeviceIdentifier = connectDeviceIdentifier;
    if (groupDeviceIdentifier != null)
      result.groupDeviceIdentifier = groupDeviceIdentifier;
    if (loggingParams != null) result.loggingParams = loggingParams;
    return result;
  }

  AddDeviceToGroupRequest._();

  factory AddDeviceToGroupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddDeviceToGroupRequest()..mergeFromBuffer(data, registry);
  factory AddDeviceToGroupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddDeviceToGroupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddDeviceToGroupRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: AddDeviceToGroupRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'connectDeviceIdentifier')
    ..aOS(2, _omitFieldNames ? '' : 'groupDeviceIdentifier')
    ..aOM<$1.LoggingParams>(3, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddDeviceToGroupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddDeviceToGroupRequest copyWith(
          void Function(AddDeviceToGroupRequest) updates) =>
      super.copyWith((message) => updates(message as AddDeviceToGroupRequest))
          as AddDeviceToGroupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use AddDeviceToGroupRequest() / AddDeviceToGroupRequest.new instead')
  static AddDeviceToGroupRequest create() => AddDeviceToGroupRequest._();
  static $pb.GeneratedMessage $_createMessage() => AddDeviceToGroupRequest._();
  @$core.override
  AddDeviceToGroupRequest createEmptyInstance() => AddDeviceToGroupRequest._();
  @$core.pragma('dart2js:noInline')
  static AddDeviceToGroupRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<AddDeviceToGroupRequest>(
      AddDeviceToGroupRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static AddDeviceToGroupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get connectDeviceIdentifier => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectDeviceIdentifier($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnectDeviceIdentifier() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectDeviceIdentifier() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get groupDeviceIdentifier => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupDeviceIdentifier($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGroupDeviceIdentifier() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupDeviceIdentifier() => $_clearField(2);

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

class AddDeviceToGroupResponse extends $pb.GeneratedMessage {
  factory AddDeviceToGroupResponse({
    $core.bool? success,
    GroupError? error,
  }) {
    final result = AddDeviceToGroupResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  AddDeviceToGroupResponse._();

  factory AddDeviceToGroupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddDeviceToGroupResponse()..mergeFromBuffer(data, registry);
  factory AddDeviceToGroupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddDeviceToGroupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddDeviceToGroupResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: AddDeviceToGroupResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aE<GroupError>(2, _omitFieldNames ? '' : 'error',
        enumValues: GroupError.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddDeviceToGroupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddDeviceToGroupResponse copyWith(
          void Function(AddDeviceToGroupResponse) updates) =>
      super.copyWith((message) => updates(message as AddDeviceToGroupResponse))
          as AddDeviceToGroupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use AddDeviceToGroupResponse() / AddDeviceToGroupResponse.new instead')
  static AddDeviceToGroupResponse create() => AddDeviceToGroupResponse._();
  static $pb.GeneratedMessage $_createMessage() => AddDeviceToGroupResponse._();
  @$core.override
  AddDeviceToGroupResponse createEmptyInstance() =>
      AddDeviceToGroupResponse._();
  @$core.pragma('dart2js:noInline')
  static AddDeviceToGroupResponse getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<AddDeviceToGroupResponse>(
      AddDeviceToGroupResponse.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static AddDeviceToGroupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  GroupError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(GroupError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
}

class RemoveDeviceFromGroupRequest extends $pb.GeneratedMessage {
  factory RemoveDeviceFromGroupRequest({
    $core.String? connectDeviceIdentifier,
    $core.String? groupDeviceIdentifier,
    $1.LoggingParams? loggingParams,
  }) {
    final result = RemoveDeviceFromGroupRequest._();
    if (connectDeviceIdentifier != null)
      result.connectDeviceIdentifier = connectDeviceIdentifier;
    if (groupDeviceIdentifier != null)
      result.groupDeviceIdentifier = groupDeviceIdentifier;
    if (loggingParams != null) result.loggingParams = loggingParams;
    return result;
  }

  RemoveDeviceFromGroupRequest._();

  factory RemoveDeviceFromGroupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveDeviceFromGroupRequest()..mergeFromBuffer(data, registry);
  factory RemoveDeviceFromGroupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveDeviceFromGroupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveDeviceFromGroupRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: RemoveDeviceFromGroupRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'connectDeviceIdentifier')
    ..aOS(2, _omitFieldNames ? '' : 'groupDeviceIdentifier')
    ..aOM<$1.LoggingParams>(3, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveDeviceFromGroupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveDeviceFromGroupRequest copyWith(
          void Function(RemoveDeviceFromGroupRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RemoveDeviceFromGroupRequest))
          as RemoveDeviceFromGroupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RemoveDeviceFromGroupRequest() / RemoveDeviceFromGroupRequest.new instead')
  static RemoveDeviceFromGroupRequest create() =>
      RemoveDeviceFromGroupRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      RemoveDeviceFromGroupRequest._();
  @$core.override
  RemoveDeviceFromGroupRequest createEmptyInstance() =>
      RemoveDeviceFromGroupRequest._();
  @$core.pragma('dart2js:noInline')
  static RemoveDeviceFromGroupRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created =
        $pb.GeneratedMessage.$_defaultFor<RemoveDeviceFromGroupRequest>(
      RemoveDeviceFromGroupRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static RemoveDeviceFromGroupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get connectDeviceIdentifier => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectDeviceIdentifier($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnectDeviceIdentifier() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectDeviceIdentifier() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get groupDeviceIdentifier => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupDeviceIdentifier($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGroupDeviceIdentifier() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupDeviceIdentifier() => $_clearField(2);

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

class RemoveDeviceFromGroupResponse extends $pb.GeneratedMessage {
  factory RemoveDeviceFromGroupResponse({
    $core.bool? success,
    RemoveGroupError? error,
  }) {
    final result = RemoveDeviceFromGroupResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  RemoveDeviceFromGroupResponse._();

  factory RemoveDeviceFromGroupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveDeviceFromGroupResponse()..mergeFromBuffer(data, registry);
  factory RemoveDeviceFromGroupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveDeviceFromGroupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveDeviceFromGroupResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: RemoveDeviceFromGroupResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aE<RemoveGroupError>(2, _omitFieldNames ? '' : 'error',
        enumValues: RemoveGroupError.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveDeviceFromGroupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveDeviceFromGroupResponse copyWith(
          void Function(RemoveDeviceFromGroupResponse) updates) =>
      super.copyWith(
              (message) => updates(message as RemoveDeviceFromGroupResponse))
          as RemoveDeviceFromGroupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RemoveDeviceFromGroupResponse() / RemoveDeviceFromGroupResponse.new instead')
  static RemoveDeviceFromGroupResponse create() =>
      RemoveDeviceFromGroupResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      RemoveDeviceFromGroupResponse._();
  @$core.override
  RemoveDeviceFromGroupResponse createEmptyInstance() =>
      RemoveDeviceFromGroupResponse._();
  @$core.pragma('dart2js:noInline')
  static RemoveDeviceFromGroupResponse getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created =
        $pb.GeneratedMessage.$_defaultFor<RemoveDeviceFromGroupResponse>(
      RemoveDeviceFromGroupResponse.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static RemoveDeviceFromGroupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  RemoveGroupError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(RemoveGroupError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
}

class DeleteGroupRequest extends $pb.GeneratedMessage {
  factory DeleteGroupRequest({
    $core.String? connectDeviceIdentifier,
    $1.LoggingParams? loggingParams,
  }) {
    final result = DeleteGroupRequest._();
    if (connectDeviceIdentifier != null)
      result.connectDeviceIdentifier = connectDeviceIdentifier;
    if (loggingParams != null) result.loggingParams = loggingParams;
    return result;
  }

  DeleteGroupRequest._();

  factory DeleteGroupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteGroupRequest()..mergeFromBuffer(data, registry);
  factory DeleteGroupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteGroupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteGroupRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: DeleteGroupRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'connectDeviceIdentifier')
    ..aOM<$1.LoggingParams>(2, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteGroupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteGroupRequest copyWith(void Function(DeleteGroupRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteGroupRequest))
          as DeleteGroupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeleteGroupRequest() / DeleteGroupRequest.new instead')
  static DeleteGroupRequest create() => DeleteGroupRequest._();
  static $pb.GeneratedMessage $_createMessage() => DeleteGroupRequest._();
  @$core.override
  DeleteGroupRequest createEmptyInstance() => DeleteGroupRequest._();
  @$core.pragma('dart2js:noInline')
  static DeleteGroupRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<DeleteGroupRequest>(
      DeleteGroupRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static DeleteGroupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get connectDeviceIdentifier => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectDeviceIdentifier($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnectDeviceIdentifier() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectDeviceIdentifier() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.LoggingParams get loggingParams => $_getN(1);
  @$pb.TagNumber(2)
  set loggingParams($1.LoggingParams value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLoggingParams() => $_has(1);
  @$pb.TagNumber(2)
  void clearLoggingParams() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.LoggingParams ensureLoggingParams() => $_ensure(1);
}

class DeleteGroupResponse extends $pb.GeneratedMessage {
  factory DeleteGroupResponse({
    $core.bool? success,
    DeleteGroupError? error,
  }) {
    final result = DeleteGroupResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  DeleteGroupResponse._();

  factory DeleteGroupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteGroupResponse()..mergeFromBuffer(data, registry);
  factory DeleteGroupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteGroupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteGroupResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: DeleteGroupResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aE<DeleteGroupError>(2, _omitFieldNames ? '' : 'error',
        enumValues: DeleteGroupError.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteGroupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteGroupResponse copyWith(void Function(DeleteGroupResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteGroupResponse))
          as DeleteGroupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use DeleteGroupResponse() / DeleteGroupResponse.new instead')
  static DeleteGroupResponse create() => DeleteGroupResponse._();
  static $pb.GeneratedMessage $_createMessage() => DeleteGroupResponse._();
  @$core.override
  DeleteGroupResponse createEmptyInstance() => DeleteGroupResponse._();
  @$core.pragma('dart2js:noInline')
  static DeleteGroupResponse getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<DeleteGroupResponse>(
      DeleteGroupResponse.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static DeleteGroupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  DeleteGroupError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(DeleteGroupError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
}

class ClusterUpdateAfterBackendConnectionResponse extends $pb.GeneratedMessage {
  factory ClusterUpdateAfterBackendConnectionResponse({
    $core.bool? hasReceivedClusterUpdateAfterBackendConnection,
  }) {
    final result = ClusterUpdateAfterBackendConnectionResponse._();
    if (hasReceivedClusterUpdateAfterBackendConnection != null)
      result.hasReceivedClusterUpdateAfterBackendConnection =
          hasReceivedClusterUpdateAfterBackendConnection;
    return result;
  }

  ClusterUpdateAfterBackendConnectionResponse._();

  factory ClusterUpdateAfterBackendConnectionResponse.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClusterUpdateAfterBackendConnectionResponse()
        ..mergeFromBuffer(data, registry);
  factory ClusterUpdateAfterBackendConnectionResponse.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClusterUpdateAfterBackendConnectionResponse()
        ..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClusterUpdateAfterBackendConnectionResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance:
          ClusterUpdateAfterBackendConnectionResponse.$_createMessage)
    ..aOB(1,
        _omitFieldNames ? '' : 'hasReceivedClusterUpdateAfterBackendConnection')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClusterUpdateAfterBackendConnectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClusterUpdateAfterBackendConnectionResponse copyWith(
          void Function(ClusterUpdateAfterBackendConnectionResponse) updates) =>
      super.copyWith((message) =>
              updates(message as ClusterUpdateAfterBackendConnectionResponse))
          as ClusterUpdateAfterBackendConnectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ClusterUpdateAfterBackendConnectionResponse() / ClusterUpdateAfterBackendConnectionResponse.new instead')
  static ClusterUpdateAfterBackendConnectionResponse create() =>
      ClusterUpdateAfterBackendConnectionResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      ClusterUpdateAfterBackendConnectionResponse._();
  @$core.override
  ClusterUpdateAfterBackendConnectionResponse createEmptyInstance() =>
      ClusterUpdateAfterBackendConnectionResponse._();
  @$core.pragma('dart2js:noInline')
  static ClusterUpdateAfterBackendConnectionResponse getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<
        ClusterUpdateAfterBackendConnectionResponse>(
      ClusterUpdateAfterBackendConnectionResponse.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static ClusterUpdateAfterBackendConnectionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get hasReceivedClusterUpdateAfterBackendConnection => $_getBF(0);
  @$pb.TagNumber(1)
  set hasReceivedClusterUpdateAfterBackendConnection($core.bool value) =>
      $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHasReceivedClusterUpdateAfterBackendConnection() => $_has(0);
  @$pb.TagNumber(1)
  void clearHasReceivedClusterUpdateAfterBackendConnection() => $_clearField(1);
}

class InstallSpotifyRequest extends $pb.GeneratedMessage {
  factory InstallSpotifyRequest({
    $core.String? connectDeviceIdentifier,
    $core.int? port,
    $1.LoggingParams? loggingParams,
  }) {
    final result = InstallSpotifyRequest._();
    if (connectDeviceIdentifier != null)
      result.connectDeviceIdentifier = connectDeviceIdentifier;
    if (port != null) result.port = port;
    if (loggingParams != null) result.loggingParams = loggingParams;
    return result;
  }

  InstallSpotifyRequest._();

  factory InstallSpotifyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InstallSpotifyRequest()..mergeFromBuffer(data, registry);
  factory InstallSpotifyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InstallSpotifyRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallSpotifyRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: InstallSpotifyRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'connectDeviceIdentifier')
    ..aI(2, _omitFieldNames ? '' : 'port', fieldType: $pb.PbFieldType.OU3)
    ..aOM<$1.LoggingParams>(3, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallSpotifyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallSpotifyRequest copyWith(
          void Function(InstallSpotifyRequest) updates) =>
      super.copyWith((message) => updates(message as InstallSpotifyRequest))
          as InstallSpotifyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use InstallSpotifyRequest() / InstallSpotifyRequest.new instead')
  static InstallSpotifyRequest create() => InstallSpotifyRequest._();
  static $pb.GeneratedMessage $_createMessage() => InstallSpotifyRequest._();
  @$core.override
  InstallSpotifyRequest createEmptyInstance() => InstallSpotifyRequest._();
  @$core.pragma('dart2js:noInline')
  static InstallSpotifyRequest getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<InstallSpotifyRequest>(
      InstallSpotifyRequest.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static InstallSpotifyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get connectDeviceIdentifier => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectDeviceIdentifier($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnectDeviceIdentifier() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectDeviceIdentifier() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get port => $_getIZ(1);
  @$pb.TagNumber(2)
  set port($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPort() => $_has(1);
  @$pb.TagNumber(2)
  void clearPort() => $_clearField(2);

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

class InstallSpotifyStatusUpdate extends $pb.GeneratedMessage {
  factory InstallSpotifyStatusUpdate({
    InstallSpotifyState? currentState,
  }) {
    final result = InstallSpotifyStatusUpdate._();
    if (currentState != null) result.currentState = currentState;
    return result;
  }

  InstallSpotifyStatusUpdate._();

  factory InstallSpotifyStatusUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InstallSpotifyStatusUpdate()..mergeFromBuffer(data, registry);
  factory InstallSpotifyStatusUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InstallSpotifyStatusUpdate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallSpotifyStatusUpdate',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.connect.esperanto.proto'),
      createEmptyInstance: InstallSpotifyStatusUpdate.$_createMessage)
    ..aE<InstallSpotifyState>(1, _omitFieldNames ? '' : 'currentState',
        enumValues: InstallSpotifyState.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallSpotifyStatusUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallSpotifyStatusUpdate copyWith(
          void Function(InstallSpotifyStatusUpdate) updates) =>
      super.copyWith(
              (message) => updates(message as InstallSpotifyStatusUpdate))
          as InstallSpotifyStatusUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use InstallSpotifyStatusUpdate() / InstallSpotifyStatusUpdate.new instead')
  static InstallSpotifyStatusUpdate create() => InstallSpotifyStatusUpdate._();
  static $pb.GeneratedMessage $_createMessage() =>
      InstallSpotifyStatusUpdate._();
  @$core.override
  InstallSpotifyStatusUpdate createEmptyInstance() =>
      InstallSpotifyStatusUpdate._();
  @$core.pragma('dart2js:noInline')
  static InstallSpotifyStatusUpdate getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created =
        $pb.GeneratedMessage.$_defaultFor<InstallSpotifyStatusUpdate>(
      InstallSpotifyStatusUpdate.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static InstallSpotifyStatusUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  InstallSpotifyState get currentState => $_getN(0);
  @$pb.TagNumber(1)
  set currentState(InstallSpotifyState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCurrentState() => $_has(0);
  @$pb.TagNumber(1)
  void clearCurrentState() => $_clearField(1);
}

class ConnectServiceApi {
  final $pb.RpcClient _client;

  ConnectServiceApi(this._client);

  $async.Future<StateResponse> state(
          $pb.ClientContext? ctx, StateRequest request) =>
      _client.invoke<StateResponse>(
          ctx, 'ConnectService', 'State', request, StateResponse());
  $async.Future<$1.StatusResponse> transfer(
          $pb.ClientContext? ctx, TransferRequest request) =>
      _client.invoke<$1.StatusResponse>(
          ctx, 'ConnectService', 'Transfer', request, $1.StatusResponse());
  $async.Future<SendCommandResponse> sendCommand(
          $pb.ClientContext? ctx, SendCommandRequest request) =>
      _client.invoke<SendCommandResponse>(
          ctx, 'ConnectService', 'SendCommand', request, SendCommandResponse());
  $async.Future<$1.StatusResponse> pull(
          $pb.ClientContext? ctx, PullRequest request) =>
      _client.invoke<$1.StatusResponse>(
          ctx, 'ConnectService', 'Pull', request, $1.StatusResponse());
  $async.Future<$1.StatusResponse> rename(
          $pb.ClientContext? ctx, RenameRequest request) =>
      _client.invoke<$1.StatusResponse>(
          ctx, 'ConnectService', 'Rename', request, $1.StatusResponse());
  $async.Future<$1.StatusResponse> logout(
          $pb.ClientContext? ctx, LogoutRequest request) =>
      _client.invoke<$1.StatusResponse>(
          ctx, 'ConnectService', 'Logout', request, $1.StatusResponse());
  $async.Future<$2.Empty> notifyAudioRouteChanged(
          $pb.ClientContext? ctx, NotifyAudioRouteChangedRequest request) =>
      _client.invoke<$2.Empty>(ctx, 'ConnectService', 'NotifyAudioRouteChanged',
          request, $2.Empty());
  $async.Future<$1.StatusResponse> setPreferredIncarnation(
          $pb.ClientContext? ctx, SetPreferredIncarnationRequest request) =>
      _client.invoke<$1.StatusResponse>(ctx, 'ConnectService',
          'SetPreferredIncarnation', request, $1.StatusResponse());
  $async.Future<CreateStaticGroupResponse> createStaticGroup(
          $pb.ClientContext? ctx, CreateStaticGroupRequest request) =>
      _client.invoke<CreateStaticGroupResponse>(ctx, 'ConnectService',
          'CreateStaticGroup', request, CreateStaticGroupResponse());
  $async.Future<RenameGroupResponse> renameGroup(
          $pb.ClientContext? ctx, RenameGroupRequest request) =>
      _client.invoke<RenameGroupResponse>(
          ctx, 'ConnectService', 'RenameGroup', request, RenameGroupResponse());
  $async.Future<AddDeviceToGroupResponse> addDeviceToGroup(
          $pb.ClientContext? ctx, AddDeviceToGroupRequest request) =>
      _client.invoke<AddDeviceToGroupResponse>(ctx, 'ConnectService',
          'AddDeviceToGroup', request, AddDeviceToGroupResponse());
  $async.Future<RemoveDeviceFromGroupResponse> removeDeviceFromGroup(
          $pb.ClientContext? ctx, RemoveDeviceFromGroupRequest request) =>
      _client.invoke<RemoveDeviceFromGroupResponse>(ctx, 'ConnectService',
          'RemoveDeviceFromGroup', request, RemoveDeviceFromGroupResponse());
  $async.Future<DeleteGroupResponse> deleteGroup(
          $pb.ClientContext? ctx, DeleteGroupRequest request) =>
      _client.invoke<DeleteGroupResponse>(
          ctx, 'ConnectService', 'DeleteGroup', request, DeleteGroupResponse());
  $async.Future<ClusterUpdateAfterBackendConnectionResponse>
      clusterUpdateAfterBackendConnection(
              $pb.ClientContext? ctx, $2.Empty request) =>
          _client.invoke<ClusterUpdateAfterBackendConnectionResponse>(
              ctx,
              'ConnectService',
              'ClusterUpdateAfterBackendConnection',
              request,
              ClusterUpdateAfterBackendConnectionResponse());
  $async.Future<InstallSpotifyStatusUpdate> installSpotify(
          $pb.ClientContext? ctx, InstallSpotifyRequest request) =>
      _client.invoke<InstallSpotifyStatusUpdate>(ctx, 'ConnectService',
          'InstallSpotify', request, InstallSpotifyStatusUpdate());
  $async.Future<$2.Empty> performDiscovery(
          $pb.ClientContext? ctx, $2.Empty request) =>
      _client.invoke<$2.Empty>(
          ctx, 'ConnectService', 'PerformDiscovery', request, $2.Empty());
  $async.Future<$2.Empty> refreshCluster(
          $pb.ClientContext? ctx, $2.Empty request) =>
      _client.invoke<$2.Empty>(
          ctx, 'ConnectService', 'RefreshCluster', request, $2.Empty());
  $async.Future<$2.Empty> wakeSleepingClusterDevices(
          $pb.ClientContext? ctx, $2.Empty request) =>
      _client.invoke<$2.Empty>(ctx, 'ConnectService',
          'WakeSleepingClusterDevices', request, $2.Empty());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
