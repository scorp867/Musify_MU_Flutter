// 1:1 Replicated Spotify Esperanto Connect Messages Json Descriptors
// Sources:
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
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

import 'package:protobuf/well_known_types/google/protobuf/empty.pbjson.dart'
    as $2;

import 'group.pbjson.dart' as $0;
import 'es_common_messages.pbjson.dart' as $1;

@$core.Deprecated('Use loginTypeDescriptor instead')
const LoginType$json = {
  '1': 'LoginType',
  '2': [
    {'1': 'CONNECT', '2': 0},
    {'1': 'CAST', '2': 1},
  ],
};

/// Descriptor for `LoginType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List loginTypeDescriptor =
    $convert.base64Decode('CglMb2dpblR5cGUSCwoHQ09OTkVDVBAAEggKBENBU1QQAQ==');

@$core.Deprecated('Use protocolChoiceReasonDescriptor instead')
const ProtocolChoiceReason$json = {
  '1': 'ProtocolChoiceReason',
  '2': [
    {'1': 'PROTOCOL_CHOICE_REASON_DEFAULT', '2': 0},
    {'1': 'PROTOCOL_CHOICE_REASON_USER_SELECTED', '2': 1},
    {'1': 'PROTOCOL_CHOICE_REASON_STREAM_EXPANSION', '2': 2},
    {'1': 'PROTOCOL_CHOICE_REASON_ANDROID_TV', '2': 3},
    {'1': 'PROTOCOL_CHOICE_REASON_TAP_DEVICE', '2': 4},
  ],
};

/// Descriptor for `ProtocolChoiceReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List protocolChoiceReasonDescriptor = $convert.base64Decode(
    'ChRQcm90b2NvbENob2ljZVJlYXNvbhIiCh5QUk9UT0NPTF9DSE9JQ0VfUkVBU09OX0RFRkFVTF'
    'QQABIoCiRQUk9UT0NPTF9DSE9JQ0VfUkVBU09OX1VTRVJfU0VMRUNURUQQARIrCidQUk9UT0NP'
    'TF9DSE9JQ0VfUkVBU09OX1NUUkVBTV9FWFBBTlNJT04QAhIlCiFQUk9UT0NPTF9DSE9JQ0VfUk'
    'VBU09OX0FORFJPSURfVFYQAxIlCiFQUk9UT0NPTF9DSE9JQ0VfUkVBU09OX1RBUF9ERVZJQ0UQ'
    'BA==');

@$core.Deprecated('Use outputPeripheralCategoryDescriptor instead')
const OutputPeripheralCategory$json = {
  '1': 'OutputPeripheralCategory',
  '2': [
    {'1': 'OUTPUT_PERIPHERAL_CATEGORY_UNKNOWN', '2': 0},
    {'1': 'OUTPUT_PERIPHERAL_CATEGORY_CAR', '2': 1},
    {'1': 'OUTPUT_PERIPHERAL_CATEGORY_HEADPHONES', '2': 2},
    {'1': 'OUTPUT_PERIPHERAL_CATEGORY_SPEAKER', '2': 3},
    {'1': 'OUTPUT_PERIPHERAL_CATEGORY_WEARABLE', '2': 4},
    {'1': 'OUTPUT_PERIPHERAL_CATEGORY_GLASSES', '2': 5},
    {'1': 'OUTPUT_PERIPHERAL_CATEGORY_APP', '2': 6},
  ],
};

/// Descriptor for `OutputPeripheralCategory`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List outputPeripheralCategoryDescriptor = $convert.base64Decode(
    'ChhPdXRwdXRQZXJpcGhlcmFsQ2F0ZWdvcnkSJgoiT1VUUFVUX1BFUklQSEVSQUxfQ0FURUdPUl'
    'lfVU5LTk9XThAAEiIKHk9VVFBVVF9QRVJJUEhFUkFMX0NBVEVHT1JZX0NBUhABEikKJU9VVFBV'
    'VF9QRVJJUEhFUkFMX0NBVEVHT1JZX0hFQURQSE9ORVMQAhImCiJPVVRQVVRfUEVSSVBIRVJBTF'
    '9DQVRFR09SWV9TUEVBS0VSEAMSJwojT1VUUFVUX1BFUklQSEVSQUxfQ0FURUdPUllfV0VBUkFC'
    'TEUQBBImCiJPVVRQVVRfUEVSSVBIRVJBTF9DQVRFR09SWV9HTEFTU0VTEAUSIgoeT1VUUFVUX1'
    'BFUklQSEVSQUxfQ0FURUdPUllfQVBQEAY=');

@$core.Deprecated('Use outputPeripheralConnectionTypeDescriptor instead')
const OutputPeripheralConnectionType$json = {
  '1': 'OutputPeripheralConnectionType',
  '2': [
    {'1': 'OUTPUT_PERIPHERAL_CONNECTION_TYPE_UNKNOWN', '2': 0},
    {'1': 'OUTPUT_PERIPHERAL_CONNECTION_TYPE_WIRED', '2': 1},
    {'1': 'OUTPUT_PERIPHERAL_CONNECTION_TYPE_CAR_PROJECTED', '2': 2},
    {'1': 'OUTPUT_PERIPHERAL_CONNECTION_TYPE_BLUETOOTH', '2': 3},
    {'1': 'OUTPUT_PERIPHERAL_CONNECTION_TYPE_AIRPLAY', '2': 4},
    {'1': 'OUTPUT_PERIPHERAL_CONNECTION_TYPE_BUILT_IN_SPEAKER', '2': 5},
  ],
};

/// Descriptor for `OutputPeripheralConnectionType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List outputPeripheralConnectionTypeDescriptor = $convert.base64Decode(
    'Ch5PdXRwdXRQZXJpcGhlcmFsQ29ubmVjdGlvblR5cGUSLQopT1VUUFVUX1BFUklQSEVSQUxfQ0'
    '9OTkVDVElPTl9UWVBFX1VOS05PV04QABIrCidPVVRQVVRfUEVSSVBIRVJBTF9DT05ORUNUSU9O'
    'X1RZUEVfV0lSRUQQARIzCi9PVVRQVVRfUEVSSVBIRVJBTF9DT05ORUNUSU9OX1RZUEVfQ0FSX1'
    'BST0pFQ1RFRBACEi8KK09VVFBVVF9QRVJJUEhFUkFMX0NPTk5FQ1RJT05fVFlQRV9CTFVFVE9P'
    'VEgQAxItCilPVVRQVVRfUEVSSVBIRVJBTF9DT05ORUNUSU9OX1RZUEVfQUlSUExBWRAEEjYKMk'
    '9VVFBVVF9QRVJJUEhFUkFMX0NPTk5FQ1RJT05fVFlQRV9CVUlMVF9JTl9TUEVBS0VSEAU=');

@$core.Deprecated('Use groupErrorDescriptor instead')
const GroupError$json = {
  '1': 'GroupError',
  '2': [
    {'1': 'UNKNOWN_GROUP_ERROR', '2': 0},
    {'1': 'TIMEOUT_GROUP_ERROR', '2': 1},
    {'1': 'INTERNAL_GROUP_ERROR', '2': 2},
    {'1': 'GROUP_DEVICE_NOT_FOUND', '2': 3},
    {'1': 'MAX_NUMBER_OF_DEVICES_REACHED', '2': 4},
    {'1': 'TARGET_NOT_FOUND', '2': 5},
    {'1': 'NOT_IMPLEMENTED', '2': 6},
    {'1': 'BUSY', '2': 13},
  ],
};

/// Descriptor for `GroupError`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List groupErrorDescriptor = $convert.base64Decode(
    'CgpHcm91cEVycm9yEhcKE1VOS05PV05fR1JPVVBfRVJST1IQABIXChNUSU1FT1VUX0dST1VQX0'
    'VSUk9SEAESGAoUSU5URVJOQUxfR1JPVVBfRVJST1IQAhIaChZHUk9VUF9ERVZJQ0VfTk9UX0ZP'
    'VU5EEAMSIQodTUFYX05VTUJFUl9PRl9ERVZJQ0VTX1JFQUNIRUQQBBIUChBUQVJHRVRfTk9UX0'
    'ZPVU5EEAUSEwoPTk9UX0lNUExFTUVOVEVEEAYSCAoEQlVTWRAN');

@$core.Deprecated('Use removeGroupErrorDescriptor instead')
const RemoveGroupError$json = {
  '1': 'RemoveGroupError',
  '2': [
    {'1': 'UNKNOWN_REMOVE_ERROR', '2': 0},
    {'1': 'TIMEOUT_REMOVE_ERROR', '2': 1},
    {'1': 'INTERNAL_REMOVE_ERROR', '2': 2},
    {'1': 'REMOVE_GROUP_DEVICE_NOT_FOUND', '2': 3},
    {'1': 'REMOVE_TARGET_NOT_FOUND', '2': 4},
    {'1': 'REMOVE_NOT_IMPLEMENTED', '2': 5},
    {'1': 'REMOVE_BUSY', '2': 12},
  ],
};

/// Descriptor for `RemoveGroupError`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List removeGroupErrorDescriptor = $convert.base64Decode(
    'ChBSZW1vdmVHcm91cEVycm9yEhgKFFVOS05PV05fUkVNT1ZFX0VSUk9SEAASGAoUVElNRU9VVF'
    '9SRU1PVkVfRVJST1IQARIZChVJTlRFUk5BTF9SRU1PVkVfRVJST1IQAhIhCh1SRU1PVkVfR1JP'
    'VVBfREVWSUNFX05PVF9GT1VORBADEhsKF1JFTU9WRV9UQVJHRVRfTk9UX0ZPVU5EEAQSGgoWUk'
    'VNT1ZFX05PVF9JTVBMRU1FTlRFRBAFEg8KC1JFTU9WRV9CVVNZEAw=');

@$core.Deprecated('Use deleteGroupErrorDescriptor instead')
const DeleteGroupError$json = {
  '1': 'DeleteGroupError',
  '2': [
    {'1': 'UNKNOWN_DELETE_ERROR', '2': 0},
    {'1': 'TIMEOUT_DELETE_ERROR', '2': 1},
    {'1': 'INTERNAL_DELETE_ERROR', '2': 2},
    {'1': 'DELETE_TARGET_NOT_FOUND', '2': 3},
    {'1': 'DELETE_NOT_IMPLEMENTED', '2': 4},
    {'1': 'DELETE_BUSY', '2': 11},
  ],
};

/// Descriptor for `DeleteGroupError`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List deleteGroupErrorDescriptor = $convert.base64Decode(
    'ChBEZWxldGVHcm91cEVycm9yEhgKFFVOS05PV05fREVMRVRFX0VSUk9SEAASGAoUVElNRU9VVF'
    '9ERUxFVEVfRVJST1IQARIZChVJTlRFUk5BTF9ERUxFVEVfRVJST1IQAhIbChdERUxFVEVfVEFS'
    'R0VUX05PVF9GT1VORBADEhoKFkRFTEVURV9OT1RfSU1QTEVNRU5URUQQBBIPCgtERUxFVEVfQl'
    'VTWRAL');

@$core.Deprecated('Use installSpotifyStateDescriptor instead')
const InstallSpotifyState$json = {
  '1': 'InstallSpotifyState',
  '2': [
    {'1': 'CONNECTING', '2': 0},
    {'1': 'PAIRING', '2': 1},
    {'1': 'SUBSCRIBING', '2': 2},
    {'1': 'LAUNCHING_APP_STORE', '2': 3},
    {'1': 'WAITING_FOR_APP_TO_BE_INSTALLED', '2': 4},
    {'1': 'LAUNCHING_THE_APP', '2': 5},
    {'1': 'SUCCESS', '2': 6},
    {'1': 'UNKNOWN_ERROR', '2': 100},
    {'1': 'DEVICE_NOT_FOUND', '2': 101},
    {'1': 'DEVICE_NOT_SUPPORTED', '2': 102},
    {'1': 'TIMEOUT', '2': 103},
    {'1': 'CANCELLED', '2': 104},
  ],
};

/// Descriptor for `InstallSpotifyState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List installSpotifyStateDescriptor = $convert.base64Decode(
    'ChNJbnN0YWxsU3BvdGlmeVN0YXRlEg4KCkNPTk5FQ1RJTkcQABILCgdQQUlSSU5HEAESDwoLU1'
    'VCU0NSSUJJTkcQAhIXChNMQVVOQ0hJTkdfQVBQX1NUT1JFEAMSIwofV0FJVElOR19GT1JfQVBQ'
    'X1RPX0JFX0lOU1RBTExFRBAEEhUKEUxBVU5DSElOR19USEVfQVBQEAUSCwoHU1VDQ0VTUxAGEh'
    'EKDVVOS05PV05fRVJST1IQZBIUChBERVZJQ0VfTk9UX0ZPVU5EEGUSGAoUREVWSUNFX05PVF9T'
    'VVBQT1JURUQQZhILCgdUSU1FT1VUEGcSDQoJQ0FOQ0VMTEVEEGg=');

@$core.Deprecated('Use outputPeripheralDescriptor instead')
const OutputPeripheral$json = {
  '1': 'OutputPeripheral',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    {'1': 'brand', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'brand', '17': true},
    {'1': 'model', '3': 3, '4': 1, '5': 9, '9': 2, '10': 'model', '17': true},
    {
      '1': 'category',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.spotify.connect.esperanto.proto.OutputPeripheralCategory',
      '9': 3,
      '10': 'category',
      '17': true
    },
    {
      '1': 'connection_type',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.spotify.connect.esperanto.proto.OutputPeripheralConnectionType',
      '9': 4,
      '10': 'connectionType',
      '17': true
    },
  ],
  '8': [
    {'1': '_name'},
    {'1': '_brand'},
    {'1': '_model'},
    {'1': '_category'},
    {'1': '_connection_type'},
  ],
};

/// Descriptor for `OutputPeripheral`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputPeripheralDescriptor = $convert.base64Decode(
    'ChBPdXRwdXRQZXJpcGhlcmFsEhcKBG5hbWUYASABKAlIAFIEbmFtZYgBARIZCgVicmFuZBgCIA'
    'EoCUgBUgVicmFuZIgBARIZCgVtb2RlbBgDIAEoCUgCUgVtb2RlbIgBARJaCghjYXRlZ29yeRgE'
    'IAEoDjI5LnNwb3RpZnkuY29ubmVjdC5lc3BlcmFudG8ucHJvdG8uT3V0cHV0UGVyaXBoZXJhbE'
    'NhdGVnb3J5SANSCGNhdGVnb3J5iAEBEm0KD2Nvbm5lY3Rpb25fdHlwZRgFIAEoDjI/LnNwb3Rp'
    'ZnkuY29ubmVjdC5lc3BlcmFudG8ucHJvdG8uT3V0cHV0UGVyaXBoZXJhbENvbm5lY3Rpb25UeX'
    'BlSARSDmNvbm5lY3Rpb25UeXBliAEBQgcKBV9uYW1lQggKBl9icmFuZEIICgZfbW9kZWxCCwoJ'
    'X2NhdGVnb3J5QhIKEF9jb25uZWN0aW9uX3R5cGU=');

@$core.Deprecated('Use stateRequestDescriptor instead')
const StateRequest$json = {
  '1': 'StateRequest',
  '2': [
    {
      '1': 'show_offline_devices_in_core',
      '3': 1,
      '4': 1,
      '5': 8,
      '10': 'showOfflineDevicesInCore'
    },
    {
      '1': 'show_offline_amazon_devices_as_online',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'showOfflineAmazonDevicesAsOnline'
    },
    {
      '1': 'include_local_device',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'includeLocalDevice'
    },
    {
      '1': 'exclude_non_local_devices',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'excludeNonLocalDevices'
    },
    {
      '1': 'include_user_match_unauthenticated_devices',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'includeUserMatchUnauthenticatedDevices'
    },
  ],
};

/// Descriptor for `StateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stateRequestDescriptor = $convert.base64Decode(
    'CgxTdGF0ZVJlcXVlc3QSPgocc2hvd19vZmZsaW5lX2RldmljZXNfaW5fY29yZRgBIAEoCFIYc2'
    'hvd09mZmxpbmVEZXZpY2VzSW5Db3JlEk8KJXNob3dfb2ZmbGluZV9hbWF6b25fZGV2aWNlc19h'
    'c19vbmxpbmUYAiABKAhSIHNob3dPZmZsaW5lQW1hem9uRGV2aWNlc0FzT25saW5lEjAKFGluY2'
    'x1ZGVfbG9jYWxfZGV2aWNlGAMgASgIUhJpbmNsdWRlTG9jYWxEZXZpY2USOQoZZXhjbHVkZV9u'
    'b25fbG9jYWxfZGV2aWNlcxgEIAEoCFIWZXhjbHVkZU5vbkxvY2FsRGV2aWNlcxJaCippbmNsdW'
    'RlX3VzZXJfbWF0Y2hfdW5hdXRoZW50aWNhdGVkX2RldmljZXMYBSABKAhSJmluY2x1ZGVVc2Vy'
    'TWF0Y2hVbmF1dGhlbnRpY2F0ZWREZXZpY2Vz');

@$core.Deprecated('Use stateResponseDescriptor instead')
const StateResponse$json = {
  '1': 'StateResponse',
  '2': [
    {'1': 'is_running', '3': 1, '4': 1, '5': 8, '10': 'isRunning'},
    {'1': 'is_connected', '3': 2, '4': 1, '5': 8, '10': 'isConnected'},
    {'1': 'local_name', '3': 3, '4': 1, '5': 9, '10': 'localName'},
    {
      '1': 'should_use_local_playback',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'shouldUseLocalPlayback'
    },
    {
      '1': 'devices',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.spotify.connect.esperanto.proto.StateResponse.Device',
      '10': 'devices'
    },
    {'1': 'is_active', '3': 6, '4': 1, '5': 8, '10': 'isActive'},
    {
      '1': 'is_active_on_same_device',
      '3': 7,
      '4': 1,
      '5': 8,
      '10': 'isActiveOnSameDevice'
    },
    {
      '1': 'is_synced_with_backend',
      '3': 8,
      '4': 1,
      '5': 8,
      '10': 'isSyncedWithBackend'
    },
  ],
  '3': [
    StateResponse_Hifi$json,
    StateResponse_Incarnation$json,
    StateResponse_Device$json
  ],
};

@$core.Deprecated('Use stateResponseDescriptor instead')
const StateResponse_Hifi$json = {
  '1': 'Hifi',
  '2': [
    {'1': 'fully_supported', '3': 1, '4': 1, '5': 8, '10': 'fullySupported'},
    {'1': 'user_eligible', '3': 2, '4': 1, '5': 8, '10': 'userEligible'},
    {'1': 'device_supported', '3': 3, '4': 1, '5': 8, '10': 'deviceSupported'},
  ],
};

@$core.Deprecated('Use stateResponseDescriptor instead')
const StateResponse_Incarnation$json = {
  '1': 'Incarnation',
  '2': [
    {
      '1': 'login_type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.spotify.connect.esperanto.proto.LoginType',
      '10': 'loginType'
    },
    {'1': 'identifier', '3': 2, '4': 1, '5': 9, '10': 'identifier'},
    {'1': 'preferred', '3': 3, '4': 1, '5': 8, '10': 'preferred'},
    {
      '1': 'preferred_reason',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.spotify.connect.esperanto.proto.ProtocolChoiceReason',
      '10': 'preferredReason'
    },
    {
      '1': 'connect_state_identifier',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'connectStateIdentifier'
    },
  ],
};

@$core.Deprecated('Use stateResponseDescriptor instead')
const StateResponse_Device$json = {
  '1': 'Device',
  '2': [
    {'1': 'is_self', '3': 1, '4': 1, '5': 8, '10': 'isSelf'},
    {'1': 'local_identifier', '3': 2, '4': 1, '5': 9, '10': 'localIdentifier'},
    {'1': 'deduplication_id', '3': 3, '4': 1, '5': 9, '10': 'deduplicationId'},
    {
      '1': 'connect_state_identifier',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'connectStateIdentifier'
    },
    {'1': 'name', '3': 5, '4': 1, '5': 9, '10': 'name'},
    {'1': 'type', '3': 6, '4': 1, '5': 9, '10': 'type'},
    {'1': 'state', '3': 7, '4': 1, '5': 9, '10': 'state'},
    {'1': 'is_disabled', '3': 8, '4': 1, '5': 8, '10': 'isDisabled'},
    {'1': 'is_active', '3': 9, '4': 1, '5': 8, '10': 'isActive'},
    {
      '1': 'is_being_activated',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'isBeingActivated'
    },
    {'1': 'is_zeroconf', '3': 11, '4': 1, '5': 8, '10': 'isZeroconf'},
    {'1': 'is_webapp', '3': 12, '4': 1, '5': 8, '10': 'isWebapp'},
    {'1': 'is_local', '3': 14, '4': 1, '5': 8, '10': 'isLocal'},
    {'1': 'is_group', '3': 15, '4': 1, '5': 8, '10': 'isGroup'},
    {'1': 'is_offline', '3': 16, '4': 1, '5': 8, '10': 'isOffline'},
    {
      '1': 'is_social_connect',
      '3': 17,
      '4': 1,
      '5': 8,
      '10': 'isSocialConnect'
    },
    {'1': 'creation_time_ms', '3': 18, '4': 1, '5': 4, '10': 'creationTimeMs'},
    {'1': 'volume', '3': 19, '4': 1, '5': 13, '10': 'volume'},
    {
      '1': 'hifi',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.spotify.connect.esperanto.proto.StateResponse.Hifi',
      '10': 'hifi'
    },
    {'1': 'license', '3': 21, '4': 1, '5': 9, '10': 'license'},
    {
      '1': 'supports_on_demand',
      '3': 22,
      '4': 1,
      '5': 8,
      '10': 'supportsOnDemand'
    },
    {'1': 'supports_volume', '3': 23, '4': 1, '5': 8, '10': 'supportsVolume'},
    {'1': 'supports_logout', '3': 24, '4': 1, '5': 8, '10': 'supportsLogout'},
    {'1': 'supports_rename', '3': 25, '4': 1, '5': 8, '10': 'supportsRename'},
    {'1': 'supports_alarm', '3': 26, '4': 1, '5': 8, '10': 'supportsAlarm'},
    {'1': 'is_voice_enabled', '3': 27, '4': 1, '5': 8, '10': 'isVoiceEnabled'},
    {
      '1': 'is_newly_discovered',
      '3': 28,
      '4': 1,
      '5': 8,
      '10': 'isNewlyDiscovered'
    },
    {
      '1': 'supported_media_types',
      '3': 29,
      '4': 3,
      '5': 9,
      '10': 'supportedMediaTypes'
    },
    {
      '1': 'brand_display_name',
      '3': 30,
      '4': 1,
      '5': 9,
      '10': 'brandDisplayName'
    },
    {
      '1': 'model_display_name',
      '3': 31,
      '4': 1,
      '5': 9,
      '10': 'modelDisplayName'
    },
    {
      '1': 'volume_steps',
      '3': 32,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'volumeSteps',
      '17': true
    },
    {
      '1': 'capabilities',
      '3': 33,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'capabilities',
      '17': true
    },
    {
      '1': 'incarnations',
      '3': 34,
      '4': 3,
      '5': 11,
      '6': '.spotify.connect.esperanto.proto.StateResponse.Incarnation',
      '10': 'incarnations'
    },
    {
      '1': 'alias_id',
      '3': 35,
      '4': 1,
      '5': 13,
      '9': 2,
      '10': 'aliasId',
      '17': true
    },
    {
      '1': 'supports_dj',
      '3': 36,
      '4': 1,
      '5': 8,
      '9': 3,
      '10': 'supportsDj',
      '17': true
    },
    {'1': 'library_version', '3': 37, '4': 1, '5': 9, '10': 'libraryVersion'},
    {
      '1': 'output_peripheral',
      '3': 38,
      '4': 1,
      '5': 11,
      '6': '.spotify.connect.esperanto.proto.OutputPeripheral',
      '9': 4,
      '10': 'outputPeripheral',
      '17': true
    },
    {'1': 'local_ip', '3': 39, '4': 1, '5': 9, '10': 'localIp'},
    {
      '1': 'discovery_method',
      '3': 40,
      '4': 1,
      '5': 13,
      '10': 'discoveryMethod'
    },
    {
      '1': 'supports_remote_sleep_timer',
      '3': 41,
      '4': 1,
      '5': 8,
      '10': 'supportsRemoteSleepTimer'
    },
    {
      '1': 'supports_playlist_mixing',
      '3': 42,
      '4': 1,
      '5': 8,
      '10': 'supportsPlaylistMixing'
    },
    {
      '1': 'group_data',
      '3': 43,
      '4': 1,
      '5': 11,
      '6': '.spotify.connect.GroupData',
      '9': 5,
      '10': 'groupData',
      '17': true
    },
    {'1': 'is_public', '3': 44, '4': 1, '5': 8, '10': 'isPublic'},
    {
      '1': 'supports_remote_audio_quality_control',
      '3': 45,
      '4': 1,
      '5': 8,
      '10': 'supportsRemoteAudioQualityControl'
    },
    {
      '1': 'is_authenticated_with_current_user',
      '3': 46,
      '4': 1,
      '5': 8,
      '9': 6,
      '10': 'isAuthenticatedWithCurrentUser',
      '17': true
    },
    {'1': 'supports_zephyr', '3': 47, '4': 1, '5': 8, '10': 'supportsZephyr'},
    {'1': 'supports_gapless', '3': 48, '4': 1, '5': 8, '10': 'supportsGapless'},
    {
      '1': 'supports_crossfade',
      '3': 49,
      '4': 1,
      '5': 8,
      '10': 'supportsCrossfade'
    },
  ],
  '8': [
    {'1': '_volume_steps'},
    {'1': '_capabilities'},
    {'1': '_alias_id'},
    {'1': '_supports_dj'},
    {'1': '_output_peripheral'},
    {'1': '_group_data'},
    {'1': '_is_authenticated_with_current_user'},
  ],
};

/// Descriptor for `StateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stateResponseDescriptor = $convert.base64Decode(
    'Cg1TdGF0ZVJlc3BvbnNlEh0KCmlzX3J1bm5pbmcYASABKAhSCWlzUnVubmluZxIhCgxpc19jb2'
    '5uZWN0ZWQYAiABKAhSC2lzQ29ubmVjdGVkEh0KCmxvY2FsX25hbWUYAyABKAlSCWxvY2FsTmFt'
    'ZRI5ChlzaG91bGRfdXNlX2xvY2FsX3BsYXliYWNrGAQgASgIUhZzaG91bGRVc2VMb2NhbFBsYX'
    'liYWNrEk8KB2RldmljZXMYBSADKAsyNS5zcG90aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3Rv'
    'LlN0YXRlUmVzcG9uc2UuRGV2aWNlUgdkZXZpY2VzEhsKCWlzX2FjdGl2ZRgGIAEoCFIIaXNBY3'
    'RpdmUSNgoYaXNfYWN0aXZlX29uX3NhbWVfZGV2aWNlGAcgASgIUhRpc0FjdGl2ZU9uU2FtZURl'
    'dmljZRIzChZpc19zeW5jZWRfd2l0aF9iYWNrZW5kGAggASgIUhNpc1N5bmNlZFdpdGhCYWNrZW'
    '5kGn8KBEhpZmkSJwoPZnVsbHlfc3VwcG9ydGVkGAEgASgIUg5mdWxseVN1cHBvcnRlZBIjCg11'
    'c2VyX2VsaWdpYmxlGAIgASgIUgx1c2VyRWxpZ2libGUSKQoQZGV2aWNlX3N1cHBvcnRlZBgDIA'
    'EoCFIPZGV2aWNlU3VwcG9ydGVkGrICCgtJbmNhcm5hdGlvbhJJCgpsb2dpbl90eXBlGAEgASgO'
    'Miouc3BvdGlmeS5jb25uZWN0LmVzcGVyYW50by5wcm90by5Mb2dpblR5cGVSCWxvZ2luVHlwZR'
    'IeCgppZGVudGlmaWVyGAIgASgJUgppZGVudGlmaWVyEhwKCXByZWZlcnJlZBgDIAEoCFIJcHJl'
    'ZmVycmVkEmAKEHByZWZlcnJlZF9yZWFzb24YBCABKA4yNS5zcG90aWZ5LmNvbm5lY3QuZXNwZX'
    'JhbnRvLnByb3RvLlByb3RvY29sQ2hvaWNlUmVhc29uUg9wcmVmZXJyZWRSZWFzb24SOAoYY29u'
    'bmVjdF9zdGF0ZV9pZGVudGlmaWVyGAUgASgJUhZjb25uZWN0U3RhdGVJZGVudGlmaWVyGssRCg'
    'ZEZXZpY2USFwoHaXNfc2VsZhgBIAEoCFIGaXNTZWxmEikKEGxvY2FsX2lkZW50aWZpZXIYAiAB'
    'KAlSD2xvY2FsSWRlbnRpZmllchIpChBkZWR1cGxpY2F0aW9uX2lkGAMgASgJUg9kZWR1cGxpY2'
    'F0aW9uSWQSOAoYY29ubmVjdF9zdGF0ZV9pZGVudGlmaWVyGAQgASgJUhZjb25uZWN0U3RhdGVJ'
    'ZGVudGlmaWVyEhIKBG5hbWUYBSABKAlSBG5hbWUSEgoEdHlwZRgGIAEoCVIEdHlwZRIUCgVzdG'
    'F0ZRgHIAEoCVIFc3RhdGUSHwoLaXNfZGlzYWJsZWQYCCABKAhSCmlzRGlzYWJsZWQSGwoJaXNf'
    'YWN0aXZlGAkgASgIUghpc0FjdGl2ZRIsChJpc19iZWluZ19hY3RpdmF0ZWQYCiABKAhSEGlzQm'
    'VpbmdBY3RpdmF0ZWQSHwoLaXNfemVyb2NvbmYYCyABKAhSCmlzWmVyb2NvbmYSGwoJaXNfd2Vi'
    'YXBwGAwgASgIUghpc1dlYmFwcBIZCghpc19sb2NhbBgOIAEoCFIHaXNMb2NhbBIZCghpc19ncm'
    '91cBgPIAEoCFIHaXNHcm91cBIdCgppc19vZmZsaW5lGBAgASgIUglpc09mZmxpbmUSKgoRaXNf'
    'c29jaWFsX2Nvbm5lY3QYESABKAhSD2lzU29jaWFsQ29ubmVjdBIoChBjcmVhdGlvbl90aW1lX2'
    '1zGBIgASgEUg5jcmVhdGlvblRpbWVNcxIWCgZ2b2x1bWUYEyABKA1SBnZvbHVtZRJHCgRoaWZp'
    'GBQgASgLMjMuc3BvdGlmeS5jb25uZWN0LmVzcGVyYW50by5wcm90by5TdGF0ZVJlc3BvbnNlLk'
    'hpZmlSBGhpZmkSGAoHbGljZW5zZRgVIAEoCVIHbGljZW5zZRIsChJzdXBwb3J0c19vbl9kZW1h'
    'bmQYFiABKAhSEHN1cHBvcnRzT25EZW1hbmQSJwoPc3VwcG9ydHNfdm9sdW1lGBcgASgIUg5zdX'
    'Bwb3J0c1ZvbHVtZRInCg9zdXBwb3J0c19sb2dvdXQYGCABKAhSDnN1cHBvcnRzTG9nb3V0EicK'
    'D3N1cHBvcnRzX3JlbmFtZRgZIAEoCFIOc3VwcG9ydHNSZW5hbWUSJQoOc3VwcG9ydHNfYWxhcm'
    '0YGiABKAhSDXN1cHBvcnRzQWxhcm0SKAoQaXNfdm9pY2VfZW5hYmxlZBgbIAEoCFIOaXNWb2lj'
    'ZUVuYWJsZWQSLgoTaXNfbmV3bHlfZGlzY292ZXJlZBgcIAEoCFIRaXNOZXdseURpc2NvdmVyZW'
    'QSMgoVc3VwcG9ydGVkX21lZGlhX3R5cGVzGB0gAygJUhNzdXBwb3J0ZWRNZWRpYVR5cGVzEiwK'
    'EmJyYW5kX2Rpc3BsYXlfbmFtZRgeIAEoCVIQYnJhbmREaXNwbGF5TmFtZRIsChJtb2RlbF9kaX'
    'NwbGF5X25hbWUYHyABKAlSEG1vZGVsRGlzcGxheU5hbWUSJgoMdm9sdW1lX3N0ZXBzGCAgASgN'
    'SABSC3ZvbHVtZVN0ZXBziAEBEicKDGNhcGFiaWxpdGllcxghIAEoCUgBUgxjYXBhYmlsaXRpZX'
    'OIAQESXgoMaW5jYXJuYXRpb25zGCIgAygLMjouc3BvdGlmeS5jb25uZWN0LmVzcGVyYW50by5w'
    'cm90by5TdGF0ZVJlc3BvbnNlLkluY2FybmF0aW9uUgxpbmNhcm5hdGlvbnMSHgoIYWxpYXNfaW'
    'QYIyABKA1IAlIHYWxpYXNJZIgBARIkCgtzdXBwb3J0c19kahgkIAEoCEgDUgpzdXBwb3J0c0Rq'
    'iAEBEicKD2xpYnJhcnlfdmVyc2lvbhglIAEoCVIObGlicmFyeVZlcnNpb24SYwoRb3V0cHV0X3'
    'BlcmlwaGVyYWwYJiABKAsyMS5zcG90aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLk91dHB1'
    'dFBlcmlwaGVyYWxIBFIQb3V0cHV0UGVyaXBoZXJhbIgBARIZCghsb2NhbF9pcBgnIAEoCVIHbG'
    '9jYWxJcBIpChBkaXNjb3ZlcnlfbWV0aG9kGCggASgNUg9kaXNjb3ZlcnlNZXRob2QSPQobc3Vw'
    'cG9ydHNfcmVtb3RlX3NsZWVwX3RpbWVyGCkgASgIUhhzdXBwb3J0c1JlbW90ZVNsZWVwVGltZX'
    'ISOAoYc3VwcG9ydHNfcGxheWxpc3RfbWl4aW5nGCogASgIUhZzdXBwb3J0c1BsYXlsaXN0TWl4'
    'aW5nEj4KCmdyb3VwX2RhdGEYKyABKAsyGi5zcG90aWZ5LmNvbm5lY3QuR3JvdXBEYXRhSAVSCW'
    'dyb3VwRGF0YYgBARIbCglpc19wdWJsaWMYLCABKAhSCGlzUHVibGljElAKJXN1cHBvcnRzX3Jl'
    'bW90ZV9hdWRpb19xdWFsaXR5X2NvbnRyb2wYLSABKAhSIXN1cHBvcnRzUmVtb3RlQXVkaW9RdW'
    'FsaXR5Q29udHJvbBJPCiJpc19hdXRoZW50aWNhdGVkX3dpdGhfY3VycmVudF91c2VyGC4gASgI'
    'SAZSHmlzQXV0aGVudGljYXRlZFdpdGhDdXJyZW50VXNlcogBARInCg9zdXBwb3J0c196ZXBoeX'
    'IYLyABKAhSDnN1cHBvcnRzWmVwaHlyEikKEHN1cHBvcnRzX2dhcGxlc3MYMCABKAhSD3N1cHBv'
    'cnRzR2FwbGVzcxItChJzdXBwb3J0c19jcm9zc2ZhZGUYMSABKAhSEXN1cHBvcnRzQ3Jvc3NmYW'
    'RlQg8KDV92b2x1bWVfc3RlcHNCDwoNX2NhcGFiaWxpdGllc0ILCglfYWxpYXNfaWRCDgoMX3N1'
    'cHBvcnRzX2RqQhQKEl9vdXRwdXRfcGVyaXBoZXJhbEINCgtfZ3JvdXBfZGF0YUIlCiNfaXNfYX'
    'V0aGVudGljYXRlZF93aXRoX2N1cnJlbnRfdXNlcg==');

@$core.Deprecated('Use transferRequestDescriptor instead')
const TransferRequest$json = {
  '1': 'TransferRequest',
  '2': [
    {
      '1': 'logging_params',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.connect.esperanto.proto.LoggingParams',
      '10': 'loggingParams'
    },
    {
      '1': 'connect_device_identifier',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'connectDeviceIdentifier'
    },
    {'1': 'dodo', '3': 3, '4': 1, '5': 8, '9': 0, '10': 'dodo', '17': true},
  ],
  '8': [
    {'1': '_dodo'},
  ],
};

/// Descriptor for `TransferRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transferRequestDescriptor = $convert.base64Decode(
    'Cg9UcmFuc2ZlclJlcXVlc3QSVQoObG9nZ2luZ19wYXJhbXMYASABKAsyLi5zcG90aWZ5LmNvbm'
    '5lY3QuZXNwZXJhbnRvLnByb3RvLkxvZ2dpbmdQYXJhbXNSDWxvZ2dpbmdQYXJhbXMSOgoZY29u'
    'bmVjdF9kZXZpY2VfaWRlbnRpZmllchgCIAEoCVIXY29ubmVjdERldmljZUlkZW50aWZpZXISFw'
    'oEZG9kbxgDIAEoCEgAUgRkb2RviAEBQgcKBV9kb2Rv');

@$core.Deprecated('Use pullRequestDescriptor instead')
const PullRequest$json = {
  '1': 'PullRequest',
  '2': [
    {
      '1': 'logging_params',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.connect.esperanto.proto.LoggingParams',
      '10': 'loggingParams'
    },
  ],
};

/// Descriptor for `PullRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pullRequestDescriptor = $convert.base64Decode(
    'CgtQdWxsUmVxdWVzdBJVCg5sb2dnaW5nX3BhcmFtcxgBIAEoCzIuLnNwb3RpZnkuY29ubmVjdC'
    '5lc3BlcmFudG8ucHJvdG8uTG9nZ2luZ1BhcmFtc1INbG9nZ2luZ1BhcmFtcw==');

@$core.Deprecated('Use logoutRequestDescriptor instead')
const LogoutRequest$json = {
  '1': 'LogoutRequest',
  '2': [
    {
      '1': 'connect_device_identifier',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'connectDeviceIdentifier'
    },
  ],
};

/// Descriptor for `LogoutRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logoutRequestDescriptor = $convert.base64Decode(
    'Cg1Mb2dvdXRSZXF1ZXN0EjoKGWNvbm5lY3RfZGV2aWNlX2lkZW50aWZpZXIYASABKAlSF2Nvbm'
    '5lY3REZXZpY2VJZGVudGlmaWVy');

@$core.Deprecated('Use notifyAudioRouteChangedRequestDescriptor instead')
const NotifyAudioRouteChangedRequest$json = {
  '1': 'NotifyAudioRouteChangedRequest',
  '2': [
    {
      '1': 'audio_output_device_name',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'audioOutputDeviceName',
      '17': true
    },
    {
      '1': 'audio_output_device_connection_type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.spotify.connect.esperanto.proto.OutputPeripheralConnectionType',
      '9': 1,
      '10': 'audioOutputDeviceConnectionType',
      '17': true
    },
    {
      '1': 'audio_output_device_brand',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'audioOutputDeviceBrand',
      '17': true
    },
    {
      '1': 'audio_output_device_model',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'audioOutputDeviceModel',
      '17': true
    },
    {
      '1': 'audio_output_device_category',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.spotify.connect.esperanto.proto.OutputPeripheralCategory',
      '9': 4,
      '10': 'audioOutputDeviceCategory',
      '17': true
    },
  ],
  '8': [
    {'1': '_audio_output_device_name'},
    {'1': '_audio_output_device_connection_type'},
    {'1': '_audio_output_device_brand'},
    {'1': '_audio_output_device_model'},
    {'1': '_audio_output_device_category'},
  ],
};

/// Descriptor for `NotifyAudioRouteChangedRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List notifyAudioRouteChangedRequestDescriptor = $convert.base64Decode(
    'Ch5Ob3RpZnlBdWRpb1JvdXRlQ2hhbmdlZFJlcXVlc3QSPAoYYXVkaW9fb3V0cHV0X2RldmljZV'
    '9uYW1lGAEgASgJSABSFWF1ZGlvT3V0cHV0RGV2aWNlTmFtZYgBARKSAQojYXVkaW9fb3V0cHV0'
    'X2RldmljZV9jb25uZWN0aW9uX3R5cGUYAiABKA4yPy5zcG90aWZ5LmNvbm5lY3QuZXNwZXJhbn'
    'RvLnByb3RvLk91dHB1dFBlcmlwaGVyYWxDb25uZWN0aW9uVHlwZUgBUh9hdWRpb091dHB1dERl'
    'dmljZUNvbm5lY3Rpb25UeXBliAEBEj4KGWF1ZGlvX291dHB1dF9kZXZpY2VfYnJhbmQYAyABKA'
    'lIAlIWYXVkaW9PdXRwdXREZXZpY2VCcmFuZIgBARI+ChlhdWRpb19vdXRwdXRfZGV2aWNlX21v'
    'ZGVsGAQgASgJSANSFmF1ZGlvT3V0cHV0RGV2aWNlTW9kZWyIAQESfwocYXVkaW9fb3V0cHV0X2'
    'RldmljZV9jYXRlZ29yeRgFIAEoDjI5LnNwb3RpZnkuY29ubmVjdC5lc3BlcmFudG8ucHJvdG8u'
    'T3V0cHV0UGVyaXBoZXJhbENhdGVnb3J5SARSGWF1ZGlvT3V0cHV0RGV2aWNlQ2F0ZWdvcnmIAQ'
    'FCGwoZX2F1ZGlvX291dHB1dF9kZXZpY2VfbmFtZUImCiRfYXVkaW9fb3V0cHV0X2RldmljZV9j'
    'b25uZWN0aW9uX3R5cGVCHAoaX2F1ZGlvX291dHB1dF9kZXZpY2VfYnJhbmRCHAoaX2F1ZGlvX2'
    '91dHB1dF9kZXZpY2VfbW9kZWxCHwodX2F1ZGlvX291dHB1dF9kZXZpY2VfY2F0ZWdvcnk=');

@$core.Deprecated('Use setPreferredIncarnationRequestDescriptor instead')
const SetPreferredIncarnationRequest$json = {
  '1': 'SetPreferredIncarnationRequest',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 9, '10': 'deviceId'},
    {
      '1': 'preferred_login_type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.spotify.connect.esperanto.proto.LoginType',
      '9': 0,
      '10': 'preferredLoginType',
      '17': true
    },
    {
      '1': 'logging_params',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.connect.esperanto.proto.LoggingParams',
      '10': 'loggingParams'
    },
  ],
  '8': [
    {'1': '_preferred_login_type'},
  ],
};

/// Descriptor for `SetPreferredIncarnationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setPreferredIncarnationRequestDescriptor = $convert.base64Decode(
    'Ch5TZXRQcmVmZXJyZWRJbmNhcm5hdGlvblJlcXVlc3QSGwoJZGV2aWNlX2lkGAEgASgJUghkZX'
    'ZpY2VJZBJhChRwcmVmZXJyZWRfbG9naW5fdHlwZRgCIAEoDjIqLnNwb3RpZnkuY29ubmVjdC5l'
    'c3BlcmFudG8ucHJvdG8uTG9naW5UeXBlSABSEnByZWZlcnJlZExvZ2luVHlwZYgBARJVCg5sb2'
    'dnaW5nX3BhcmFtcxgDIAEoCzIuLnNwb3RpZnkuY29ubmVjdC5lc3BlcmFudG8ucHJvdG8uTG9n'
    'Z2luZ1BhcmFtc1INbG9nZ2luZ1BhcmFtc0IXChVfcHJlZmVycmVkX2xvZ2luX3R5cGU=');

@$core.Deprecated('Use sendCommandRequestDescriptor instead')
const SendCommandRequest$json = {
  '1': 'SendCommandRequest',
  '2': [
    {
      '1': 'logging_params',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.connect.esperanto.proto.LoggingParams',
      '10': 'loggingParams'
    },
    {
      '1': 'connect_device_identifier',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'connectDeviceIdentifier'
    },
    {'1': 'command_json', '3': 3, '4': 1, '5': 9, '10': 'commandJson'},
  ],
};

/// Descriptor for `SendCommandRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendCommandRequestDescriptor = $convert.base64Decode(
    'ChJTZW5kQ29tbWFuZFJlcXVlc3QSVQoObG9nZ2luZ19wYXJhbXMYASABKAsyLi5zcG90aWZ5Lm'
    'Nvbm5lY3QuZXNwZXJhbnRvLnByb3RvLkxvZ2dpbmdQYXJhbXNSDWxvZ2dpbmdQYXJhbXMSOgoZ'
    'Y29ubmVjdF9kZXZpY2VfaWRlbnRpZmllchgCIAEoCVIXY29ubmVjdERldmljZUlkZW50aWZpZX'
    'ISIQoMY29tbWFuZF9qc29uGAMgASgJUgtjb21tYW5kSnNvbg==');

@$core.Deprecated('Use sendCommandResponseDescriptor instead')
const SendCommandResponse$json = {
  '1': 'SendCommandResponse',
  '2': [
    {
      '1': 'context_player_error',
      '3': 1,
      '4': 1,
      '5': 5,
      '10': 'contextPlayerError'
    },
  ],
};

/// Descriptor for `SendCommandResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendCommandResponseDescriptor = $convert.base64Decode(
    'ChNTZW5kQ29tbWFuZFJlc3BvbnNlEjAKFGNvbnRleHRfcGxheWVyX2Vycm9yGAEgASgFUhJjb2'
    '50ZXh0UGxheWVyRXJyb3I=');

@$core.Deprecated('Use renameRequestDescriptor instead')
const RenameRequest$json = {
  '1': 'RenameRequest',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'new_name', '3': 2, '4': 1, '5': 9, '10': 'newName'},
  ],
};

/// Descriptor for `RenameRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameRequestDescriptor = $convert.base64Decode(
    'Cg1SZW5hbWVSZXF1ZXN0EhsKCWRldmljZV9pZBgBIAEoCVIIZGV2aWNlSWQSGQoIbmV3X25hbW'
    'UYAiABKAlSB25ld05hbWU=');

@$core.Deprecated('Use createStaticGroupRequestDescriptor instead')
const CreateStaticGroupRequest$json = {
  '1': 'CreateStaticGroupRequest',
};

/// Descriptor for `CreateStaticGroupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createStaticGroupRequestDescriptor =
    $convert.base64Decode('ChhDcmVhdGVTdGF0aWNHcm91cFJlcXVlc3Q=');

@$core.Deprecated('Use createStaticGroupResponseDescriptor instead')
const CreateStaticGroupResponse$json = {
  '1': 'CreateStaticGroupResponse',
};

/// Descriptor for `CreateStaticGroupResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createStaticGroupResponseDescriptor =
    $convert.base64Decode('ChlDcmVhdGVTdGF0aWNHcm91cFJlc3BvbnNl');

@$core.Deprecated('Use renameGroupRequestDescriptor instead')
const RenameGroupRequest$json = {
  '1': 'RenameGroupRequest',
};

/// Descriptor for `RenameGroupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameGroupRequestDescriptor =
    $convert.base64Decode('ChJSZW5hbWVHcm91cFJlcXVlc3Q=');

@$core.Deprecated('Use renameGroupResponseDescriptor instead')
const RenameGroupResponse$json = {
  '1': 'RenameGroupResponse',
};

/// Descriptor for `RenameGroupResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameGroupResponseDescriptor =
    $convert.base64Decode('ChNSZW5hbWVHcm91cFJlc3BvbnNl');

@$core.Deprecated('Use addDeviceToGroupRequestDescriptor instead')
const AddDeviceToGroupRequest$json = {
  '1': 'AddDeviceToGroupRequest',
  '2': [
    {
      '1': 'connect_device_identifier',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'connectDeviceIdentifier'
    },
    {
      '1': 'group_device_identifier',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'groupDeviceIdentifier'
    },
    {
      '1': 'logging_params',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.connect.esperanto.proto.LoggingParams',
      '10': 'loggingParams'
    },
  ],
};

/// Descriptor for `AddDeviceToGroupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addDeviceToGroupRequestDescriptor = $convert.base64Decode(
    'ChdBZGREZXZpY2VUb0dyb3VwUmVxdWVzdBI6Chljb25uZWN0X2RldmljZV9pZGVudGlmaWVyGA'
    'EgASgJUhdjb25uZWN0RGV2aWNlSWRlbnRpZmllchI2Chdncm91cF9kZXZpY2VfaWRlbnRpZmll'
    'chgCIAEoCVIVZ3JvdXBEZXZpY2VJZGVudGlmaWVyElUKDmxvZ2dpbmdfcGFyYW1zGAMgASgLMi'
    '4uc3BvdGlmeS5jb25uZWN0LmVzcGVyYW50by5wcm90by5Mb2dnaW5nUGFyYW1zUg1sb2dnaW5n'
    'UGFyYW1z');

@$core.Deprecated('Use addDeviceToGroupResponseDescriptor instead')
const AddDeviceToGroupResponse$json = {
  '1': 'AddDeviceToGroupResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.spotify.connect.esperanto.proto.GroupError',
      '9': 0,
      '10': 'error',
      '17': true
    },
  ],
  '8': [
    {'1': '_error'},
  ],
};

/// Descriptor for `AddDeviceToGroupResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addDeviceToGroupResponseDescriptor = $convert.base64Decode(
    'ChhBZGREZXZpY2VUb0dyb3VwUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxJGCg'
    'VlcnJvchgCIAEoDjIrLnNwb3RpZnkuY29ubmVjdC5lc3BlcmFudG8ucHJvdG8uR3JvdXBFcnJv'
    'ckgAUgVlcnJvcogBAUIICgZfZXJyb3I=');

@$core.Deprecated('Use removeDeviceFromGroupRequestDescriptor instead')
const RemoveDeviceFromGroupRequest$json = {
  '1': 'RemoveDeviceFromGroupRequest',
  '2': [
    {
      '1': 'connect_device_identifier',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'connectDeviceIdentifier'
    },
    {
      '1': 'group_device_identifier',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'groupDeviceIdentifier'
    },
    {
      '1': 'logging_params',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.connect.esperanto.proto.LoggingParams',
      '10': 'loggingParams'
    },
  ],
};

/// Descriptor for `RemoveDeviceFromGroupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeDeviceFromGroupRequestDescriptor = $convert.base64Decode(
    'ChxSZW1vdmVEZXZpY2VGcm9tR3JvdXBSZXF1ZXN0EjoKGWNvbm5lY3RfZGV2aWNlX2lkZW50aW'
    'ZpZXIYASABKAlSF2Nvbm5lY3REZXZpY2VJZGVudGlmaWVyEjYKF2dyb3VwX2RldmljZV9pZGVu'
    'dGlmaWVyGAIgASgJUhVncm91cERldmljZUlkZW50aWZpZXISVQoObG9nZ2luZ19wYXJhbXMYAy'
    'ABKAsyLi5zcG90aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLkxvZ2dpbmdQYXJhbXNSDWxv'
    'Z2dpbmdQYXJhbXM=');

@$core.Deprecated('Use removeDeviceFromGroupResponseDescriptor instead')
const RemoveDeviceFromGroupResponse$json = {
  '1': 'RemoveDeviceFromGroupResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.spotify.connect.esperanto.proto.RemoveGroupError',
      '9': 0,
      '10': 'error',
      '17': true
    },
  ],
  '8': [
    {'1': '_error'},
  ],
};

/// Descriptor for `RemoveDeviceFromGroupResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeDeviceFromGroupResponseDescriptor =
    $convert.base64Decode(
        'Ch1SZW1vdmVEZXZpY2VGcm9tR3JvdXBSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZX'
        'NzEkwKBWVycm9yGAIgASgOMjEuc3BvdGlmeS5jb25uZWN0LmVzcGVyYW50by5wcm90by5SZW1v'
        'dmVHcm91cEVycm9ySABSBWVycm9yiAEBQggKBl9lcnJvcg==');

@$core.Deprecated('Use deleteGroupRequestDescriptor instead')
const DeleteGroupRequest$json = {
  '1': 'DeleteGroupRequest',
  '2': [
    {
      '1': 'connect_device_identifier',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'connectDeviceIdentifier'
    },
    {
      '1': 'logging_params',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.connect.esperanto.proto.LoggingParams',
      '10': 'loggingParams'
    },
  ],
};

/// Descriptor for `DeleteGroupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteGroupRequestDescriptor = $convert.base64Decode(
    'ChJEZWxldGVHcm91cFJlcXVlc3QSOgoZY29ubmVjdF9kZXZpY2VfaWRlbnRpZmllchgBIAEoCV'
    'IXY29ubmVjdERldmljZUlkZW50aWZpZXISVQoObG9nZ2luZ19wYXJhbXMYAiABKAsyLi5zcG90'
    'aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLkxvZ2dpbmdQYXJhbXNSDWxvZ2dpbmdQYXJhbX'
    'M=');

@$core.Deprecated('Use deleteGroupResponseDescriptor instead')
const DeleteGroupResponse$json = {
  '1': 'DeleteGroupResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.spotify.connect.esperanto.proto.DeleteGroupError',
      '9': 0,
      '10': 'error',
      '17': true
    },
  ],
  '8': [
    {'1': '_error'},
  ],
};

/// Descriptor for `DeleteGroupResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteGroupResponseDescriptor = $convert.base64Decode(
    'ChNEZWxldGVHcm91cFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSTAoFZXJyb3'
    'IYAiABKA4yMS5zcG90aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLkRlbGV0ZUdyb3VwRXJy'
    'b3JIAFIFZXJyb3KIAQFCCAoGX2Vycm9y');

@$core.Deprecated(
    'Use clusterUpdateAfterBackendConnectionResponseDescriptor instead')
const ClusterUpdateAfterBackendConnectionResponse$json = {
  '1': 'ClusterUpdateAfterBackendConnectionResponse',
  '2': [
    {
      '1': 'has_received_cluster_update_after_backend_connection',
      '3': 1,
      '4': 1,
      '5': 8,
      '10': 'hasReceivedClusterUpdateAfterBackendConnection'
    },
  ],
};

/// Descriptor for `ClusterUpdateAfterBackendConnectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List
    clusterUpdateAfterBackendConnectionResponseDescriptor =
    $convert.base64Decode(
        'CitDbHVzdGVyVXBkYXRlQWZ0ZXJCYWNrZW5kQ29ubmVjdGlvblJlc3BvbnNlEmwKNGhhc19yZW'
        'NlaXZlZF9jbHVzdGVyX3VwZGF0ZV9hZnRlcl9iYWNrZW5kX2Nvbm5lY3Rpb24YASABKAhSLmhh'
        'c1JlY2VpdmVkQ2x1c3RlclVwZGF0ZUFmdGVyQmFja2VuZENvbm5lY3Rpb24=');

@$core.Deprecated('Use installSpotifyRequestDescriptor instead')
const InstallSpotifyRequest$json = {
  '1': 'InstallSpotifyRequest',
  '2': [
    {
      '1': 'connect_device_identifier',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'connectDeviceIdentifier'
    },
    {'1': 'port', '3': 2, '4': 1, '5': 13, '9': 0, '10': 'port', '17': true},
    {
      '1': 'logging_params',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.connect.esperanto.proto.LoggingParams',
      '10': 'loggingParams'
    },
  ],
  '8': [
    {'1': '_port'},
  ],
};

/// Descriptor for `InstallSpotifyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installSpotifyRequestDescriptor = $convert.base64Decode(
    'ChVJbnN0YWxsU3BvdGlmeVJlcXVlc3QSOgoZY29ubmVjdF9kZXZpY2VfaWRlbnRpZmllchgBIA'
    'EoCVIXY29ubmVjdERldmljZUlkZW50aWZpZXISFwoEcG9ydBgCIAEoDUgAUgRwb3J0iAEBElUK'
    'DmxvZ2dpbmdfcGFyYW1zGAMgASgLMi4uc3BvdGlmeS5jb25uZWN0LmVzcGVyYW50by5wcm90by'
    '5Mb2dnaW5nUGFyYW1zUg1sb2dnaW5nUGFyYW1zQgcKBV9wb3J0');

@$core.Deprecated('Use installSpotifyStatusUpdateDescriptor instead')
const InstallSpotifyStatusUpdate$json = {
  '1': 'InstallSpotifyStatusUpdate',
  '2': [
    {
      '1': 'current_state',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.spotify.connect.esperanto.proto.InstallSpotifyState',
      '10': 'currentState'
    },
  ],
};

/// Descriptor for `InstallSpotifyStatusUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installSpotifyStatusUpdateDescriptor =
    $convert.base64Decode(
        'ChpJbnN0YWxsU3BvdGlmeVN0YXR1c1VwZGF0ZRJZCg1jdXJyZW50X3N0YXRlGAEgASgOMjQuc3'
        'BvdGlmeS5jb25uZWN0LmVzcGVyYW50by5wcm90by5JbnN0YWxsU3BvdGlmeVN0YXRlUgxjdXJy'
        'ZW50U3RhdGU=');

const $core.Map<$core.String, $core.dynamic> ConnectServiceBase$json = {
  '1': 'ConnectService',
  '2': [
    {
      '1': 'State',
      '2': '.spotify.connect.esperanto.proto.StateRequest',
      '3': '.spotify.connect.esperanto.proto.StateResponse',
      '6': true
    },
    {
      '1': 'Transfer',
      '2': '.spotify.connect.esperanto.proto.TransferRequest',
      '3': '.spotify.connect.esperanto.proto.StatusResponse'
    },
    {
      '1': 'SendCommand',
      '2': '.spotify.connect.esperanto.proto.SendCommandRequest',
      '3': '.spotify.connect.esperanto.proto.SendCommandResponse'
    },
    {
      '1': 'Pull',
      '2': '.spotify.connect.esperanto.proto.PullRequest',
      '3': '.spotify.connect.esperanto.proto.StatusResponse'
    },
    {
      '1': 'Rename',
      '2': '.spotify.connect.esperanto.proto.RenameRequest',
      '3': '.spotify.connect.esperanto.proto.StatusResponse'
    },
    {
      '1': 'Logout',
      '2': '.spotify.connect.esperanto.proto.LogoutRequest',
      '3': '.spotify.connect.esperanto.proto.StatusResponse'
    },
    {
      '1': 'NotifyAudioRouteChanged',
      '2': '.spotify.connect.esperanto.proto.NotifyAudioRouteChangedRequest',
      '3': '.google.protobuf.Empty'
    },
    {
      '1': 'SetPreferredIncarnation',
      '2': '.spotify.connect.esperanto.proto.SetPreferredIncarnationRequest',
      '3': '.spotify.connect.esperanto.proto.StatusResponse'
    },
    {
      '1': 'CreateStaticGroup',
      '2': '.spotify.connect.esperanto.proto.CreateStaticGroupRequest',
      '3': '.spotify.connect.esperanto.proto.CreateStaticGroupResponse'
    },
    {
      '1': 'RenameGroup',
      '2': '.spotify.connect.esperanto.proto.RenameGroupRequest',
      '3': '.spotify.connect.esperanto.proto.RenameGroupResponse'
    },
    {
      '1': 'AddDeviceToGroup',
      '2': '.spotify.connect.esperanto.proto.AddDeviceToGroupRequest',
      '3': '.spotify.connect.esperanto.proto.AddDeviceToGroupResponse'
    },
    {
      '1': 'RemoveDeviceFromGroup',
      '2': '.spotify.connect.esperanto.proto.RemoveDeviceFromGroupRequest',
      '3': '.spotify.connect.esperanto.proto.RemoveDeviceFromGroupResponse'
    },
    {
      '1': 'DeleteGroup',
      '2': '.spotify.connect.esperanto.proto.DeleteGroupRequest',
      '3': '.spotify.connect.esperanto.proto.DeleteGroupResponse'
    },
    {
      '1': 'ClusterUpdateAfterBackendConnection',
      '2': '.google.protobuf.Empty',
      '3':
          '.spotify.connect.esperanto.proto.ClusterUpdateAfterBackendConnectionResponse'
    },
    {
      '1': 'InstallSpotify',
      '2': '.spotify.connect.esperanto.proto.InstallSpotifyRequest',
      '3': '.spotify.connect.esperanto.proto.InstallSpotifyStatusUpdate',
      '6': true
    },
    {
      '1': 'PerformDiscovery',
      '2': '.google.protobuf.Empty',
      '3': '.google.protobuf.Empty'
    },
    {
      '1': 'RefreshCluster',
      '2': '.google.protobuf.Empty',
      '3': '.google.protobuf.Empty'
    },
    {
      '1': 'WakeSleepingClusterDevices',
      '2': '.google.protobuf.Empty',
      '3': '.google.protobuf.Empty'
    },
  ],
};

@$core.Deprecated('Use connectServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    ConnectServiceBase$messageJson = {
  '.spotify.connect.esperanto.proto.StateRequest': StateRequest$json,
  '.spotify.connect.esperanto.proto.StateResponse': StateResponse$json,
  '.spotify.connect.esperanto.proto.StateResponse.Device':
      StateResponse_Device$json,
  '.spotify.connect.esperanto.proto.StateResponse.Hifi':
      StateResponse_Hifi$json,
  '.spotify.connect.esperanto.proto.StateResponse.Incarnation':
      StateResponse_Incarnation$json,
  '.spotify.connect.esperanto.proto.OutputPeripheral': OutputPeripheral$json,
  '.spotify.connect.GroupData': $0.GroupData$json,
  '.spotify.connect.GroupDevice': $0.GroupDevice$json,
  '.spotify.connect.GroupDeviceIdentifiers': $0.GroupDeviceIdentifiers$json,
  '.spotify.connect.GroupDeviceCapabilities': $0.GroupDeviceCapabilities$json,
  '.spotify.connect.GroupDeviceVolume': $0.GroupDeviceVolume$json,
  '.spotify.connect.GroupCapabilities': $0.GroupCapabilities$json,
  '.spotify.connect.esperanto.proto.TransferRequest': TransferRequest$json,
  '.spotify.connect.esperanto.proto.LoggingParams': $1.LoggingParams$json,
  '.spotify.connect.esperanto.proto.StatusResponse': $1.StatusResponse$json,
  '.spotify.connect.esperanto.proto.SendCommandRequest':
      SendCommandRequest$json,
  '.spotify.connect.esperanto.proto.SendCommandResponse':
      SendCommandResponse$json,
  '.spotify.connect.esperanto.proto.PullRequest': PullRequest$json,
  '.spotify.connect.esperanto.proto.RenameRequest': RenameRequest$json,
  '.spotify.connect.esperanto.proto.LogoutRequest': LogoutRequest$json,
  '.spotify.connect.esperanto.proto.NotifyAudioRouteChangedRequest':
      NotifyAudioRouteChangedRequest$json,
  '.google.protobuf.Empty': $2.Empty$json,
  '.spotify.connect.esperanto.proto.SetPreferredIncarnationRequest':
      SetPreferredIncarnationRequest$json,
  '.spotify.connect.esperanto.proto.CreateStaticGroupRequest':
      CreateStaticGroupRequest$json,
  '.spotify.connect.esperanto.proto.CreateStaticGroupResponse':
      CreateStaticGroupResponse$json,
  '.spotify.connect.esperanto.proto.RenameGroupRequest':
      RenameGroupRequest$json,
  '.spotify.connect.esperanto.proto.RenameGroupResponse':
      RenameGroupResponse$json,
  '.spotify.connect.esperanto.proto.AddDeviceToGroupRequest':
      AddDeviceToGroupRequest$json,
  '.spotify.connect.esperanto.proto.AddDeviceToGroupResponse':
      AddDeviceToGroupResponse$json,
  '.spotify.connect.esperanto.proto.RemoveDeviceFromGroupRequest':
      RemoveDeviceFromGroupRequest$json,
  '.spotify.connect.esperanto.proto.RemoveDeviceFromGroupResponse':
      RemoveDeviceFromGroupResponse$json,
  '.spotify.connect.esperanto.proto.DeleteGroupRequest':
      DeleteGroupRequest$json,
  '.spotify.connect.esperanto.proto.DeleteGroupResponse':
      DeleteGroupResponse$json,
  '.spotify.connect.esperanto.proto.ClusterUpdateAfterBackendConnectionResponse':
      ClusterUpdateAfterBackendConnectionResponse$json,
  '.spotify.connect.esperanto.proto.InstallSpotifyRequest':
      InstallSpotifyRequest$json,
  '.spotify.connect.esperanto.proto.InstallSpotifyStatusUpdate':
      InstallSpotifyStatusUpdate$json,
};

/// Descriptor for `ConnectService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List connectServiceDescriptor = $convert.base64Decode(
    'Cg5Db25uZWN0U2VydmljZRJoCgVTdGF0ZRItLnNwb3RpZnkuY29ubmVjdC5lc3BlcmFudG8ucH'
    'JvdG8uU3RhdGVSZXF1ZXN0Gi4uc3BvdGlmeS5jb25uZWN0LmVzcGVyYW50by5wcm90by5TdGF0'
    'ZVJlc3BvbnNlMAESbQoIVHJhbnNmZXISMC5zcG90aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3'
    'RvLlRyYW5zZmVyUmVxdWVzdBovLnNwb3RpZnkuY29ubmVjdC5lc3BlcmFudG8ucHJvdG8uU3Rh'
    'dHVzUmVzcG9uc2USeAoLU2VuZENvbW1hbmQSMy5zcG90aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLn'
    'Byb3RvLlNlbmRDb21tYW5kUmVxdWVzdBo0LnNwb3RpZnkuY29ubmVjdC5lc3BlcmFudG8ucHJv'
    'dG8uU2VuZENvbW1hbmRSZXNwb25zZRJlCgRQdWxsEiwuc3BvdGlmeS5jb25uZWN0LmVzcGVyYW'
    '50by5wcm90by5QdWxsUmVxdWVzdBovLnNwb3RpZnkuY29ubmVjdC5lc3BlcmFudG8ucHJvdG8u'
    'U3RhdHVzUmVzcG9uc2USaQoGUmVuYW1lEi4uc3BvdGlmeS5jb25uZWN0LmVzcGVyYW50by5wcm'
    '90by5SZW5hbWVSZXF1ZXN0Gi8uc3BvdGlmeS5jb25uZWN0LmVzcGVyYW50by5wcm90by5TdGF0'
    'dXNSZXNwb25zZRJpCgZMb2dvdXQSLi5zcG90aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLk'
    'xvZ291dFJlcXVlc3QaLy5zcG90aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLlN0YXR1c1Jl'
    'c3BvbnNlEnIKF05vdGlmeUF1ZGlvUm91dGVDaGFuZ2VkEj8uc3BvdGlmeS5jb25uZWN0LmVzcG'
    'VyYW50by5wcm90by5Ob3RpZnlBdWRpb1JvdXRlQ2hhbmdlZFJlcXVlc3QaFi5nb29nbGUucHJv'
    'dG9idWYuRW1wdHkSiwEKF1NldFByZWZlcnJlZEluY2FybmF0aW9uEj8uc3BvdGlmeS5jb25uZW'
    'N0LmVzcGVyYW50by5wcm90by5TZXRQcmVmZXJyZWRJbmNhcm5hdGlvblJlcXVlc3QaLy5zcG90'
    'aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLlN0YXR1c1Jlc3BvbnNlEooBChFDcmVhdGVTdG'
    'F0aWNHcm91cBI5LnNwb3RpZnkuY29ubmVjdC5lc3BlcmFudG8ucHJvdG8uQ3JlYXRlU3RhdGlj'
    'R3JvdXBSZXF1ZXN0Gjouc3BvdGlmeS5jb25uZWN0LmVzcGVyYW50by5wcm90by5DcmVhdGVTdG'
    'F0aWNHcm91cFJlc3BvbnNlEngKC1JlbmFtZUdyb3VwEjMuc3BvdGlmeS5jb25uZWN0LmVzcGVy'
    'YW50by5wcm90by5SZW5hbWVHcm91cFJlcXVlc3QaNC5zcG90aWZ5LmNvbm5lY3QuZXNwZXJhbn'
    'RvLnByb3RvLlJlbmFtZUdyb3VwUmVzcG9uc2UShwEKEEFkZERldmljZVRvR3JvdXASOC5zcG90'
    'aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLkFkZERldmljZVRvR3JvdXBSZXF1ZXN0Gjkuc3'
    'BvdGlmeS5jb25uZWN0LmVzcGVyYW50by5wcm90by5BZGREZXZpY2VUb0dyb3VwUmVzcG9uc2US'
    'lgEKFVJlbW92ZURldmljZUZyb21Hcm91cBI9LnNwb3RpZnkuY29ubmVjdC5lc3BlcmFudG8ucH'
    'JvdG8uUmVtb3ZlRGV2aWNlRnJvbUdyb3VwUmVxdWVzdBo+LnNwb3RpZnkuY29ubmVjdC5lc3Bl'
    'cmFudG8ucHJvdG8uUmVtb3ZlRGV2aWNlRnJvbUdyb3VwUmVzcG9uc2USeAoLRGVsZXRlR3JvdX'
    'ASMy5zcG90aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLkRlbGV0ZUdyb3VwUmVxdWVzdBo0'
    'LnNwb3RpZnkuY29ubmVjdC5lc3BlcmFudG8ucHJvdG8uRGVsZXRlR3JvdXBSZXNwb25zZRKLAQ'
    'ojQ2x1c3RlclVwZGF0ZUFmdGVyQmFja2VuZENvbm5lY3Rpb24SFi5nb29nbGUucHJvdG9idWYu'
    'RW1wdHkaTC5zcG90aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLkNsdXN0ZXJVcGRhdGVBZn'
    'RlckJhY2tlbmRDb25uZWN0aW9uUmVzcG9uc2UShwEKDkluc3RhbGxTcG90aWZ5EjYuc3BvdGlm'
    'eS5jb25uZWN0LmVzcGVyYW50by5wcm90by5JbnN0YWxsU3BvdGlmeVJlcXVlc3QaOy5zcG90aW'
    'Z5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLkluc3RhbGxTcG90aWZ5U3RhdHVzVXBkYXRlMAES'
    'QgoQUGVyZm9ybURpc2NvdmVyeRIWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eRoWLmdvb2dsZS5wcm'
    '90b2J1Zi5FbXB0eRJACg5SZWZyZXNoQ2x1c3RlchIWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eRoW'
    'Lmdvb2dsZS5wcm90b2J1Zi5FbXB0eRJMChpXYWtlU2xlZXBpbmdDbHVzdGVyRGV2aWNlcxIWLm'
    'dvb2dsZS5wcm90b2J1Zi5FbXB0eRoWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eQ==');
