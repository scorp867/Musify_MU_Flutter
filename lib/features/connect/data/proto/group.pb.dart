// 1:1 Replicated Spotify Connect Group Protobuf Wire Descriptors
// Sources:
// - Decompiled Java: `com/spotify/connect/esperanto/proto/ConnectMessages$GroupData.java`
// - Decompiled Java: `ConnectMessages$GroupDevice.java`
// - Decompiled Java: `p199p/z9k.java`
// - `liborbit-jni-spotify_memdump.so` offset `0x36de24` (`connect_group.proto`)

// This is a generated file - do not edit.
//
// Generated from protos/spotify/connect/group.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'group.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'group.pbenum.dart';

class GroupCapabilities extends $pb.GeneratedMessage {
  factory GroupCapabilities({
    $core.int? maxDevices,
  }) {
    final result = GroupCapabilities._();
    if (maxDevices != null) result.maxDevices = maxDevices;
    return result;
  }

  GroupCapabilities._();

  factory GroupCapabilities.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupCapabilities()..mergeFromBuffer(data, registry);
  factory GroupCapabilities.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupCapabilities()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GroupCapabilities',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.connect'),
      createEmptyInstance: GroupCapabilities.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'maxDevices', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupCapabilities clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupCapabilities copyWith(void Function(GroupCapabilities) updates) =>
      super.copyWith((message) => updates(message as GroupCapabilities))
          as GroupCapabilities;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GroupCapabilities() / GroupCapabilities.new instead')
  static GroupCapabilities create() => GroupCapabilities._();
  static $pb.GeneratedMessage $_createMessage() => GroupCapabilities._();
  @$core.override
  GroupCapabilities createEmptyInstance() => GroupCapabilities._();
  @$core.pragma('dart2js:noInline')
  static GroupCapabilities getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<GroupCapabilities>(
      GroupCapabilities.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static GroupCapabilities? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get maxDevices => $_getIZ(0);
  @$pb.TagNumber(1)
  set maxDevices($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMaxDevices() => $_has(0);
  @$pb.TagNumber(1)
  void clearMaxDevices() => $_clearField(1);
}

class GroupDeviceCapabilities extends $pb.GeneratedMessage {
  factory GroupDeviceCapabilities({
    $core.bool? removable,
    $core.bool? removalDissolvesGroup,
  }) {
    final result = GroupDeviceCapabilities._();
    if (removable != null) result.removable = removable;
    if (removalDissolvesGroup != null)
      result.removalDissolvesGroup = removalDissolvesGroup;
    return result;
  }

  GroupDeviceCapabilities._();

  factory GroupDeviceCapabilities.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupDeviceCapabilities()..mergeFromBuffer(data, registry);
  factory GroupDeviceCapabilities.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupDeviceCapabilities()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GroupDeviceCapabilities',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.connect'),
      createEmptyInstance: GroupDeviceCapabilities.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'removable')
    ..aOB(2, _omitFieldNames ? '' : 'removalDissolvesGroup')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupDeviceCapabilities clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupDeviceCapabilities copyWith(
          void Function(GroupDeviceCapabilities) updates) =>
      super.copyWith((message) => updates(message as GroupDeviceCapabilities))
          as GroupDeviceCapabilities;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GroupDeviceCapabilities() / GroupDeviceCapabilities.new instead')
  static GroupDeviceCapabilities create() => GroupDeviceCapabilities._();
  static $pb.GeneratedMessage $_createMessage() => GroupDeviceCapabilities._();
  @$core.override
  GroupDeviceCapabilities createEmptyInstance() => GroupDeviceCapabilities._();
  @$core.pragma('dart2js:noInline')
  static GroupDeviceCapabilities getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<GroupDeviceCapabilities>(
      GroupDeviceCapabilities.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static GroupDeviceCapabilities? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get removable => $_getBF(0);
  @$pb.TagNumber(1)
  set removable($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRemovable() => $_has(0);
  @$pb.TagNumber(1)
  void clearRemovable() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get removalDissolvesGroup => $_getBF(1);
  @$pb.TagNumber(2)
  set removalDissolvesGroup($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRemovalDissolvesGroup() => $_has(1);
  @$pb.TagNumber(2)
  void clearRemovalDissolvesGroup() => $_clearField(2);
}

class GroupDeviceIdentifiers extends $pb.GeneratedMessage {
  factory GroupDeviceIdentifiers({
    $core.String? groupDeviceIdentifier,
    $core.String? localIdentifier,
    $core.String? deduplicationId,
    $core.String? connectStateIdentifier,
  }) {
    final result = GroupDeviceIdentifiers._();
    if (groupDeviceIdentifier != null)
      result.groupDeviceIdentifier = groupDeviceIdentifier;
    if (localIdentifier != null) result.localIdentifier = localIdentifier;
    if (deduplicationId != null) result.deduplicationId = deduplicationId;
    if (connectStateIdentifier != null)
      result.connectStateIdentifier = connectStateIdentifier;
    return result;
  }

  GroupDeviceIdentifiers._();

  factory GroupDeviceIdentifiers.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupDeviceIdentifiers()..mergeFromBuffer(data, registry);
  factory GroupDeviceIdentifiers.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupDeviceIdentifiers()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GroupDeviceIdentifiers',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.connect'),
      createEmptyInstance: GroupDeviceIdentifiers.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'groupDeviceIdentifier')
    ..aOS(2, _omitFieldNames ? '' : 'localIdentifier')
    ..aOS(3, _omitFieldNames ? '' : 'deduplicationId')
    ..aOS(4, _omitFieldNames ? '' : 'connectStateIdentifier')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupDeviceIdentifiers clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupDeviceIdentifiers copyWith(
          void Function(GroupDeviceIdentifiers) updates) =>
      super.copyWith((message) => updates(message as GroupDeviceIdentifiers))
          as GroupDeviceIdentifiers;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GroupDeviceIdentifiers() / GroupDeviceIdentifiers.new instead')
  static GroupDeviceIdentifiers create() => GroupDeviceIdentifiers._();
  static $pb.GeneratedMessage $_createMessage() => GroupDeviceIdentifiers._();
  @$core.override
  GroupDeviceIdentifiers createEmptyInstance() => GroupDeviceIdentifiers._();
  @$core.pragma('dart2js:noInline')
  static GroupDeviceIdentifiers getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<GroupDeviceIdentifiers>(
      GroupDeviceIdentifiers.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static GroupDeviceIdentifiers? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get groupDeviceIdentifier => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupDeviceIdentifier($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGroupDeviceIdentifier() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupDeviceIdentifier() => $_clearField(1);

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
}

class GroupDeviceVolume extends $pb.GeneratedMessage {
  factory GroupDeviceVolume({
    $core.int? volume,
    $core.int? volumeSteps,
  }) {
    final result = GroupDeviceVolume._();
    if (volume != null) result.volume = volume;
    if (volumeSteps != null) result.volumeSteps = volumeSteps;
    return result;
  }

  GroupDeviceVolume._();

  factory GroupDeviceVolume.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupDeviceVolume()..mergeFromBuffer(data, registry);
  factory GroupDeviceVolume.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupDeviceVolume()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GroupDeviceVolume',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.connect'),
      createEmptyInstance: GroupDeviceVolume.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'volume', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'volumeSteps')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupDeviceVolume clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupDeviceVolume copyWith(void Function(GroupDeviceVolume) updates) =>
      super.copyWith((message) => updates(message as GroupDeviceVolume))
          as GroupDeviceVolume;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GroupDeviceVolume() / GroupDeviceVolume.new instead')
  static GroupDeviceVolume create() => GroupDeviceVolume._();
  static $pb.GeneratedMessage $_createMessage() => GroupDeviceVolume._();
  @$core.override
  GroupDeviceVolume createEmptyInstance() => GroupDeviceVolume._();
  @$core.pragma('dart2js:noInline')
  static GroupDeviceVolume getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<GroupDeviceVolume>(
      GroupDeviceVolume.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static GroupDeviceVolume? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get volume => $_getIZ(0);
  @$pb.TagNumber(1)
  set volume($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVolume() => $_has(0);
  @$pb.TagNumber(1)
  void clearVolume() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get volumeSteps => $_getIZ(1);
  @$pb.TagNumber(2)
  set volumeSteps($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVolumeSteps() => $_has(1);
  @$pb.TagNumber(2)
  void clearVolumeSteps() => $_clearField(2);
}

class GroupDevice extends $pb.GeneratedMessage {
  factory GroupDevice({
    GroupDeviceIdentifiers? identifiers,
    $core.String? name,
    $core.String? type,
    $core.String? modelDisplayName,
    GroupDeviceCapabilities? capabilities,
    GroupingStatus? groupingStatus,
    GroupDeviceVolume? volume,
  }) {
    final result = GroupDevice._();
    if (identifiers != null) result.identifiers = identifiers;
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    if (modelDisplayName != null) result.modelDisplayName = modelDisplayName;
    if (capabilities != null) result.capabilities = capabilities;
    if (groupingStatus != null) result.groupingStatus = groupingStatus;
    if (volume != null) result.volume = volume;
    return result;
  }

  GroupDevice._();

  factory GroupDevice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupDevice()..mergeFromBuffer(data, registry);
  factory GroupDevice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupDevice()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GroupDevice',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.connect'),
      createEmptyInstance: GroupDevice.$_createMessage)
    ..aOM<GroupDeviceIdentifiers>(1, _omitFieldNames ? '' : 'identifiers',
        subBuilder: GroupDeviceIdentifiers.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'type')
    ..aOS(4, _omitFieldNames ? '' : 'modelDisplayName')
    ..aOM<GroupDeviceCapabilities>(5, _omitFieldNames ? '' : 'capabilities',
        subBuilder: GroupDeviceCapabilities.$_createMessage)
    ..aE<GroupingStatus>(6, _omitFieldNames ? '' : 'groupingStatus',
        enumValues: GroupingStatus.values)
    ..aOM<GroupDeviceVolume>(7, _omitFieldNames ? '' : 'volume',
        subBuilder: GroupDeviceVolume.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupDevice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupDevice copyWith(void Function(GroupDevice) updates) =>
      super.copyWith((message) => updates(message as GroupDevice))
          as GroupDevice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GroupDevice() / GroupDevice.new instead')
  static GroupDevice create() => GroupDevice._();
  static $pb.GeneratedMessage $_createMessage() => GroupDevice._();
  @$core.override
  GroupDevice createEmptyInstance() => GroupDevice._();
  @$core.pragma('dart2js:noInline')
  static GroupDevice getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<GroupDevice>(
      GroupDevice.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static GroupDevice? _defaultInstance;

  @$pb.TagNumber(1)
  GroupDeviceIdentifiers get identifiers => $_getN(0);
  @$pb.TagNumber(1)
  set identifiers(GroupDeviceIdentifiers value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasIdentifiers() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdentifiers() => $_clearField(1);
  @$pb.TagNumber(1)
  GroupDeviceIdentifiers ensureIdentifiers() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get type => $_getSZ(2);
  @$pb.TagNumber(3)
  set type($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get modelDisplayName => $_getSZ(3);
  @$pb.TagNumber(4)
  set modelDisplayName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModelDisplayName() => $_has(3);
  @$pb.TagNumber(4)
  void clearModelDisplayName() => $_clearField(4);

  @$pb.TagNumber(5)
  GroupDeviceCapabilities get capabilities => $_getN(4);
  @$pb.TagNumber(5)
  set capabilities(GroupDeviceCapabilities value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasCapabilities() => $_has(4);
  @$pb.TagNumber(5)
  void clearCapabilities() => $_clearField(5);
  @$pb.TagNumber(5)
  GroupDeviceCapabilities ensureCapabilities() => $_ensure(4);

  @$pb.TagNumber(6)
  GroupingStatus get groupingStatus => $_getN(5);
  @$pb.TagNumber(6)
  set groupingStatus(GroupingStatus value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasGroupingStatus() => $_has(5);
  @$pb.TagNumber(6)
  void clearGroupingStatus() => $_clearField(6);

  @$pb.TagNumber(7)
  GroupDeviceVolume get volume => $_getN(6);
  @$pb.TagNumber(7)
  set volume(GroupDeviceVolume value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasVolume() => $_has(6);
  @$pb.TagNumber(7)
  void clearVolume() => $_clearField(7);
  @$pb.TagNumber(7)
  GroupDeviceVolume ensureVolume() => $_ensure(6);
}

class GroupData extends $pb.GeneratedMessage {
  factory GroupData({
    $core.Iterable<GroupDevice>? devices,
    GroupCapabilities? capabilities,
  }) {
    final result = GroupData._();
    if (devices != null) result.devices.addAll(devices);
    if (capabilities != null) result.capabilities = capabilities;
    return result;
  }

  GroupData._();

  factory GroupData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupData()..mergeFromBuffer(data, registry);
  factory GroupData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupData()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GroupData',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.connect'),
      createEmptyInstance: GroupData.$_createMessage)
    ..pPM<GroupDevice>(1, _omitFieldNames ? '' : 'devices',
        subBuilder: GroupDevice.$_createMessage)
    ..aOM<GroupCapabilities>(2, _omitFieldNames ? '' : 'capabilities',
        subBuilder: GroupCapabilities.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupData copyWith(void Function(GroupData) updates) =>
      super.copyWith((message) => updates(message as GroupData)) as GroupData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GroupData() / GroupData.new instead')
  static GroupData create() => GroupData._();
  static $pb.GeneratedMessage $_createMessage() => GroupData._();
  @$core.override
  GroupData createEmptyInstance() => GroupData._();
  @$core.pragma('dart2js:noInline')
  static GroupData getDefault() {
    final instance = _defaultInstance;
    if (instance != null) {
      return instance;
    }
    final created = $pb.GeneratedMessage.$_defaultFor<GroupData>(
      GroupData.$_createMessage,
    );
    _defaultInstance = created;
    return created;
  }

  static GroupData? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<GroupDevice> get devices => $_getList(0);

  @$pb.TagNumber(2)
  GroupCapabilities get capabilities => $_getN(1);
  @$pb.TagNumber(2)
  set capabilities(GroupCapabilities value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCapabilities() => $_has(1);
  @$pb.TagNumber(2)
  void clearCapabilities() => $_clearField(2);
  @$pb.TagNumber(2)
  GroupCapabilities ensureCapabilities() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
