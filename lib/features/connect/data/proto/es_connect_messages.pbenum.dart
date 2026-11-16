// 1:1 Replicated Spotify Esperanto Connect Messages Enums
// Sources:
// - Decompiled Java: `com/spotify/connect/esperanto/proto/ConnectMessages.java`
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

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class LoginType extends $pb.ProtobufEnum {
  static const LoginType CONNECT =
      LoginType._(0, _omitEnumNames ? '' : 'CONNECT');
  static const LoginType CAST = LoginType._(1, _omitEnumNames ? '' : 'CAST');

  static const $core.List<LoginType> values = <LoginType>[
    CONNECT,
    CAST,
  ];

  static final $core.List<LoginType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static LoginType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LoginType._(super.value, super.name);
}

class ProtocolChoiceReason extends $pb.ProtobufEnum {
  static const ProtocolChoiceReason PROTOCOL_CHOICE_REASON_DEFAULT =
      ProtocolChoiceReason._(
          0, _omitEnumNames ? '' : 'PROTOCOL_CHOICE_REASON_DEFAULT');
  static const ProtocolChoiceReason PROTOCOL_CHOICE_REASON_USER_SELECTED =
      ProtocolChoiceReason._(
          1, _omitEnumNames ? '' : 'PROTOCOL_CHOICE_REASON_USER_SELECTED');
  static const ProtocolChoiceReason PROTOCOL_CHOICE_REASON_STREAM_EXPANSION =
      ProtocolChoiceReason._(
          2, _omitEnumNames ? '' : 'PROTOCOL_CHOICE_REASON_STREAM_EXPANSION');
  static const ProtocolChoiceReason PROTOCOL_CHOICE_REASON_ANDROID_TV =
      ProtocolChoiceReason._(
          3, _omitEnumNames ? '' : 'PROTOCOL_CHOICE_REASON_ANDROID_TV');
  static const ProtocolChoiceReason PROTOCOL_CHOICE_REASON_TAP_DEVICE =
      ProtocolChoiceReason._(
          4, _omitEnumNames ? '' : 'PROTOCOL_CHOICE_REASON_TAP_DEVICE');

  static const $core.List<ProtocolChoiceReason> values = <ProtocolChoiceReason>[
    PROTOCOL_CHOICE_REASON_DEFAULT,
    PROTOCOL_CHOICE_REASON_USER_SELECTED,
    PROTOCOL_CHOICE_REASON_STREAM_EXPANSION,
    PROTOCOL_CHOICE_REASON_ANDROID_TV,
    PROTOCOL_CHOICE_REASON_TAP_DEVICE,
  ];

  static final $core.List<ProtocolChoiceReason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static ProtocolChoiceReason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ProtocolChoiceReason._(super.value, super.name);
}

class OutputPeripheralCategory extends $pb.ProtobufEnum {
  static const OutputPeripheralCategory OUTPUT_PERIPHERAL_CATEGORY_UNKNOWN =
      OutputPeripheralCategory._(
          0, _omitEnumNames ? '' : 'OUTPUT_PERIPHERAL_CATEGORY_UNKNOWN');
  static const OutputPeripheralCategory OUTPUT_PERIPHERAL_CATEGORY_CAR =
      OutputPeripheralCategory._(
          1, _omitEnumNames ? '' : 'OUTPUT_PERIPHERAL_CATEGORY_CAR');
  static const OutputPeripheralCategory OUTPUT_PERIPHERAL_CATEGORY_HEADPHONES =
      OutputPeripheralCategory._(
          2, _omitEnumNames ? '' : 'OUTPUT_PERIPHERAL_CATEGORY_HEADPHONES');
  static const OutputPeripheralCategory OUTPUT_PERIPHERAL_CATEGORY_SPEAKER =
      OutputPeripheralCategory._(
          3, _omitEnumNames ? '' : 'OUTPUT_PERIPHERAL_CATEGORY_SPEAKER');
  static const OutputPeripheralCategory OUTPUT_PERIPHERAL_CATEGORY_WEARABLE =
      OutputPeripheralCategory._(
          4, _omitEnumNames ? '' : 'OUTPUT_PERIPHERAL_CATEGORY_WEARABLE');
  static const OutputPeripheralCategory OUTPUT_PERIPHERAL_CATEGORY_GLASSES =
      OutputPeripheralCategory._(
          5, _omitEnumNames ? '' : 'OUTPUT_PERIPHERAL_CATEGORY_GLASSES');
  static const OutputPeripheralCategory OUTPUT_PERIPHERAL_CATEGORY_APP =
      OutputPeripheralCategory._(
          6, _omitEnumNames ? '' : 'OUTPUT_PERIPHERAL_CATEGORY_APP');

  static const $core.List<OutputPeripheralCategory> values =
      <OutputPeripheralCategory>[
    OUTPUT_PERIPHERAL_CATEGORY_UNKNOWN,
    OUTPUT_PERIPHERAL_CATEGORY_CAR,
    OUTPUT_PERIPHERAL_CATEGORY_HEADPHONES,
    OUTPUT_PERIPHERAL_CATEGORY_SPEAKER,
    OUTPUT_PERIPHERAL_CATEGORY_WEARABLE,
    OUTPUT_PERIPHERAL_CATEGORY_GLASSES,
    OUTPUT_PERIPHERAL_CATEGORY_APP,
  ];

  static final $core.List<OutputPeripheralCategory?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static OutputPeripheralCategory? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OutputPeripheralCategory._(super.value, super.name);
}

class OutputPeripheralConnectionType extends $pb.ProtobufEnum {
  static const OutputPeripheralConnectionType
      OUTPUT_PERIPHERAL_CONNECTION_TYPE_UNKNOWN =
      OutputPeripheralConnectionType._(
          0, _omitEnumNames ? '' : 'OUTPUT_PERIPHERAL_CONNECTION_TYPE_UNKNOWN');
  static const OutputPeripheralConnectionType
      OUTPUT_PERIPHERAL_CONNECTION_TYPE_WIRED =
      OutputPeripheralConnectionType._(
          1, _omitEnumNames ? '' : 'OUTPUT_PERIPHERAL_CONNECTION_TYPE_WIRED');
  static const OutputPeripheralConnectionType
      OUTPUT_PERIPHERAL_CONNECTION_TYPE_CAR_PROJECTED =
      OutputPeripheralConnectionType._(
          2,
          _omitEnumNames
              ? ''
              : 'OUTPUT_PERIPHERAL_CONNECTION_TYPE_CAR_PROJECTED');
  static const OutputPeripheralConnectionType
      OUTPUT_PERIPHERAL_CONNECTION_TYPE_BLUETOOTH =
      OutputPeripheralConnectionType._(3,
          _omitEnumNames ? '' : 'OUTPUT_PERIPHERAL_CONNECTION_TYPE_BLUETOOTH');
  static const OutputPeripheralConnectionType
      OUTPUT_PERIPHERAL_CONNECTION_TYPE_AIRPLAY =
      OutputPeripheralConnectionType._(
          4, _omitEnumNames ? '' : 'OUTPUT_PERIPHERAL_CONNECTION_TYPE_AIRPLAY');
  static const OutputPeripheralConnectionType
      OUTPUT_PERIPHERAL_CONNECTION_TYPE_BUILT_IN_SPEAKER =
      OutputPeripheralConnectionType._(
          5,
          _omitEnumNames
              ? ''
              : 'OUTPUT_PERIPHERAL_CONNECTION_TYPE_BUILT_IN_SPEAKER');

  static const $core.List<OutputPeripheralConnectionType> values =
      <OutputPeripheralConnectionType>[
    OUTPUT_PERIPHERAL_CONNECTION_TYPE_UNKNOWN,
    OUTPUT_PERIPHERAL_CONNECTION_TYPE_WIRED,
    OUTPUT_PERIPHERAL_CONNECTION_TYPE_CAR_PROJECTED,
    OUTPUT_PERIPHERAL_CONNECTION_TYPE_BLUETOOTH,
    OUTPUT_PERIPHERAL_CONNECTION_TYPE_AIRPLAY,
    OUTPUT_PERIPHERAL_CONNECTION_TYPE_BUILT_IN_SPEAKER,
  ];

  static final $core.List<OutputPeripheralConnectionType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static OutputPeripheralConnectionType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OutputPeripheralConnectionType._(super.value, super.name);
}

class GroupError extends $pb.ProtobufEnum {
  static const GroupError UNKNOWN_GROUP_ERROR =
      GroupError._(0, _omitEnumNames ? '' : 'UNKNOWN_GROUP_ERROR');
  static const GroupError TIMEOUT_GROUP_ERROR =
      GroupError._(1, _omitEnumNames ? '' : 'TIMEOUT_GROUP_ERROR');
  static const GroupError INTERNAL_GROUP_ERROR =
      GroupError._(2, _omitEnumNames ? '' : 'INTERNAL_GROUP_ERROR');
  static const GroupError GROUP_DEVICE_NOT_FOUND =
      GroupError._(3, _omitEnumNames ? '' : 'GROUP_DEVICE_NOT_FOUND');
  static const GroupError MAX_NUMBER_OF_DEVICES_REACHED =
      GroupError._(4, _omitEnumNames ? '' : 'MAX_NUMBER_OF_DEVICES_REACHED');
  static const GroupError TARGET_NOT_FOUND =
      GroupError._(5, _omitEnumNames ? '' : 'TARGET_NOT_FOUND');
  static const GroupError NOT_IMPLEMENTED =
      GroupError._(6, _omitEnumNames ? '' : 'NOT_IMPLEMENTED');
  static const GroupError BUSY = GroupError._(13, _omitEnumNames ? '' : 'BUSY');

  static const $core.List<GroupError> values = <GroupError>[
    UNKNOWN_GROUP_ERROR,
    TIMEOUT_GROUP_ERROR,
    INTERNAL_GROUP_ERROR,
    GROUP_DEVICE_NOT_FOUND,
    MAX_NUMBER_OF_DEVICES_REACHED,
    TARGET_NOT_FOUND,
    NOT_IMPLEMENTED,
    BUSY,
  ];

  static final $core.Map<$core.int, GroupError> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static GroupError? valueOf($core.int value) => _byValue[value];

  const GroupError._(super.value, super.name);
}

class RemoveGroupError extends $pb.ProtobufEnum {
  static const RemoveGroupError UNKNOWN_REMOVE_ERROR =
      RemoveGroupError._(0, _omitEnumNames ? '' : 'UNKNOWN_REMOVE_ERROR');
  static const RemoveGroupError TIMEOUT_REMOVE_ERROR =
      RemoveGroupError._(1, _omitEnumNames ? '' : 'TIMEOUT_REMOVE_ERROR');
  static const RemoveGroupError INTERNAL_REMOVE_ERROR =
      RemoveGroupError._(2, _omitEnumNames ? '' : 'INTERNAL_REMOVE_ERROR');
  static const RemoveGroupError REMOVE_GROUP_DEVICE_NOT_FOUND =
      RemoveGroupError._(
          3, _omitEnumNames ? '' : 'REMOVE_GROUP_DEVICE_NOT_FOUND');
  static const RemoveGroupError REMOVE_TARGET_NOT_FOUND =
      RemoveGroupError._(4, _omitEnumNames ? '' : 'REMOVE_TARGET_NOT_FOUND');
  static const RemoveGroupError REMOVE_NOT_IMPLEMENTED =
      RemoveGroupError._(5, _omitEnumNames ? '' : 'REMOVE_NOT_IMPLEMENTED');
  static const RemoveGroupError REMOVE_BUSY =
      RemoveGroupError._(12, _omitEnumNames ? '' : 'REMOVE_BUSY');

  static const $core.List<RemoveGroupError> values = <RemoveGroupError>[
    UNKNOWN_REMOVE_ERROR,
    TIMEOUT_REMOVE_ERROR,
    INTERNAL_REMOVE_ERROR,
    REMOVE_GROUP_DEVICE_NOT_FOUND,
    REMOVE_TARGET_NOT_FOUND,
    REMOVE_NOT_IMPLEMENTED,
    REMOVE_BUSY,
  ];

  static final $core.Map<$core.int, RemoveGroupError> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static RemoveGroupError? valueOf($core.int value) => _byValue[value];

  const RemoveGroupError._(super.value, super.name);
}

class DeleteGroupError extends $pb.ProtobufEnum {
  static const DeleteGroupError UNKNOWN_DELETE_ERROR =
      DeleteGroupError._(0, _omitEnumNames ? '' : 'UNKNOWN_DELETE_ERROR');
  static const DeleteGroupError TIMEOUT_DELETE_ERROR =
      DeleteGroupError._(1, _omitEnumNames ? '' : 'TIMEOUT_DELETE_ERROR');
  static const DeleteGroupError INTERNAL_DELETE_ERROR =
      DeleteGroupError._(2, _omitEnumNames ? '' : 'INTERNAL_DELETE_ERROR');
  static const DeleteGroupError DELETE_TARGET_NOT_FOUND =
      DeleteGroupError._(3, _omitEnumNames ? '' : 'DELETE_TARGET_NOT_FOUND');
  static const DeleteGroupError DELETE_NOT_IMPLEMENTED =
      DeleteGroupError._(4, _omitEnumNames ? '' : 'DELETE_NOT_IMPLEMENTED');
  static const DeleteGroupError DELETE_BUSY =
      DeleteGroupError._(11, _omitEnumNames ? '' : 'DELETE_BUSY');

  static const $core.List<DeleteGroupError> values = <DeleteGroupError>[
    UNKNOWN_DELETE_ERROR,
    TIMEOUT_DELETE_ERROR,
    INTERNAL_DELETE_ERROR,
    DELETE_TARGET_NOT_FOUND,
    DELETE_NOT_IMPLEMENTED,
    DELETE_BUSY,
  ];

  static final $core.Map<$core.int, DeleteGroupError> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static DeleteGroupError? valueOf($core.int value) => _byValue[value];

  const DeleteGroupError._(super.value, super.name);
}

class InstallSpotifyState extends $pb.ProtobufEnum {
  static const InstallSpotifyState CONNECTING =
      InstallSpotifyState._(0, _omitEnumNames ? '' : 'CONNECTING');
  static const InstallSpotifyState PAIRING =
      InstallSpotifyState._(1, _omitEnumNames ? '' : 'PAIRING');
  static const InstallSpotifyState SUBSCRIBING =
      InstallSpotifyState._(2, _omitEnumNames ? '' : 'SUBSCRIBING');
  static const InstallSpotifyState LAUNCHING_APP_STORE =
      InstallSpotifyState._(3, _omitEnumNames ? '' : 'LAUNCHING_APP_STORE');
  static const InstallSpotifyState WAITING_FOR_APP_TO_BE_INSTALLED =
      InstallSpotifyState._(
          4, _omitEnumNames ? '' : 'WAITING_FOR_APP_TO_BE_INSTALLED');
  static const InstallSpotifyState LAUNCHING_THE_APP =
      InstallSpotifyState._(5, _omitEnumNames ? '' : 'LAUNCHING_THE_APP');
  static const InstallSpotifyState SUCCESS =
      InstallSpotifyState._(6, _omitEnumNames ? '' : 'SUCCESS');
  static const InstallSpotifyState UNKNOWN_ERROR =
      InstallSpotifyState._(100, _omitEnumNames ? '' : 'UNKNOWN_ERROR');
  static const InstallSpotifyState DEVICE_NOT_FOUND =
      InstallSpotifyState._(101, _omitEnumNames ? '' : 'DEVICE_NOT_FOUND');
  static const InstallSpotifyState DEVICE_NOT_SUPPORTED =
      InstallSpotifyState._(102, _omitEnumNames ? '' : 'DEVICE_NOT_SUPPORTED');
  static const InstallSpotifyState TIMEOUT =
      InstallSpotifyState._(103, _omitEnumNames ? '' : 'TIMEOUT');
  static const InstallSpotifyState CANCELLED =
      InstallSpotifyState._(104, _omitEnumNames ? '' : 'CANCELLED');

  static const $core.List<InstallSpotifyState> values = <InstallSpotifyState>[
    CONNECTING,
    PAIRING,
    SUBSCRIBING,
    LAUNCHING_APP_STORE,
    WAITING_FOR_APP_TO_BE_INSTALLED,
    LAUNCHING_THE_APP,
    SUCCESS,
    UNKNOWN_ERROR,
    DEVICE_NOT_FOUND,
    DEVICE_NOT_SUPPORTED,
    TIMEOUT,
    CANCELLED,
  ];

  static final $core.Map<$core.int, InstallSpotifyState> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static InstallSpotifyState? valueOf($core.int value) => _byValue[value];

  const InstallSpotifyState._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
