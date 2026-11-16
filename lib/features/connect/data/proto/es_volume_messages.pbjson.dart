// 1:1 Replicated Spotify Esperanto Volume Messages Json Descriptors
// Sources:
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
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

import 'package:protobuf/well_known_types/google/protobuf/empty.pbjson.dart'
    as $1;

import 'es_common_messages.pbjson.dart' as $0;

@$core.Deprecated('Use volumeResponseDescriptor instead')
const VolumeResponse$json = {
  '1': 'VolumeResponse',
  '2': [
    {'1': 'volume', '3': 1, '4': 1, '5': 5, '9': 0, '10': 'volume', '17': true},
    {
      '1': 'status',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.spotify.connect.esperanto.proto.Status',
      '10': 'status'
    },
    {
      '1': 'active_device_connect_state_identifier',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'activeDeviceConnectStateIdentifier',
      '17': true
    },
    {
      '1': 'group_device_volumes',
      '3': 4,
      '4': 3,
      '5': 11,
      '6':
          '.spotify.connect.esperanto.proto.VolumeResponse.GroupDeviceVolumesEntry',
      '10': 'groupDeviceVolumes'
    },
  ],
  '3': [VolumeResponse_GroupDeviceVolumesEntry$json],
  '8': [
    {'1': '_volume'},
    {'1': '_active_device_connect_state_identifier'},
  ],
};

@$core.Deprecated('Use volumeResponseDescriptor instead')
const VolumeResponse_GroupDeviceVolumesEntry$json = {
  '1': 'GroupDeviceVolumesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 13, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `VolumeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List volumeResponseDescriptor = $convert.base64Decode(
    'Cg5Wb2x1bWVSZXNwb25zZRIbCgZ2b2x1bWUYASABKAVIAFIGdm9sdW1liAEBEj8KBnN0YXR1cx'
    'gCIAEoDjInLnNwb3RpZnkuY29ubmVjdC5lc3BlcmFudG8ucHJvdG8uU3RhdHVzUgZzdGF0dXMS'
    'VwomYWN0aXZlX2RldmljZV9jb25uZWN0X3N0YXRlX2lkZW50aWZpZXIYAyABKAlIAVIiYWN0aX'
    'ZlRGV2aWNlQ29ubmVjdFN0YXRlSWRlbnRpZmllcogBARJ5ChRncm91cF9kZXZpY2Vfdm9sdW1l'
    'cxgEIAMoCzJHLnNwb3RpZnkuY29ubmVjdC5lc3BlcmFudG8ucHJvdG8uVm9sdW1lUmVzcG9uc2'
    'UuR3JvdXBEZXZpY2VWb2x1bWVzRW50cnlSEmdyb3VwRGV2aWNlVm9sdW1lcxpFChdHcm91cERl'
    'dmljZVZvbHVtZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoDVIFdmFsdW'
    'U6AjgBQgkKB192b2x1bWVCKQonX2FjdGl2ZV9kZXZpY2VfY29ubmVjdF9zdGF0ZV9pZGVudGlm'
    'aWVy');

@$core.Deprecated('Use volumeSetRequestDescriptor instead')
const VolumeSetRequest$json = {
  '1': 'VolumeSetRequest',
  '2': [
    {'1': 'volume', '3': 1, '4': 1, '5': 5, '10': 'volume'},
    {
      '1': 'logging_params',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.connect.esperanto.proto.LoggingParams',
      '10': 'loggingParams'
    },
    {
      '1': 'group_device_identifier',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'groupDeviceIdentifier',
      '17': true
    },
  ],
  '8': [
    {'1': '_group_device_identifier'},
  ],
};

/// Descriptor for `VolumeSetRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List volumeSetRequestDescriptor = $convert.base64Decode(
    'ChBWb2x1bWVTZXRSZXF1ZXN0EhYKBnZvbHVtZRgBIAEoBVIGdm9sdW1lElUKDmxvZ2dpbmdfcG'
    'FyYW1zGAIgASgLMi4uc3BvdGlmeS5jb25uZWN0LmVzcGVyYW50by5wcm90by5Mb2dnaW5nUGFy'
    'YW1zUg1sb2dnaW5nUGFyYW1zEjsKF2dyb3VwX2RldmljZV9pZGVudGlmaWVyGAMgASgJSABSFW'
    'dyb3VwRGV2aWNlSWRlbnRpZmllcogBAUIaChhfZ3JvdXBfZGV2aWNlX2lkZW50aWZpZXI=');

@$core.Deprecated('Use volumeUpRequestDescriptor instead')
const VolumeUpRequest$json = {
  '1': 'VolumeUpRequest',
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
      '1': 'group_device_identifier',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'groupDeviceIdentifier',
      '17': true
    },
  ],
  '8': [
    {'1': '_group_device_identifier'},
  ],
};

/// Descriptor for `VolumeUpRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List volumeUpRequestDescriptor = $convert.base64Decode(
    'Cg9Wb2x1bWVVcFJlcXVlc3QSVQoObG9nZ2luZ19wYXJhbXMYASABKAsyLi5zcG90aWZ5LmNvbm'
    '5lY3QuZXNwZXJhbnRvLnByb3RvLkxvZ2dpbmdQYXJhbXNSDWxvZ2dpbmdQYXJhbXMSOwoXZ3Jv'
    'dXBfZGV2aWNlX2lkZW50aWZpZXIYAiABKAlIAFIVZ3JvdXBEZXZpY2VJZGVudGlmaWVyiAEBQh'
    'oKGF9ncm91cF9kZXZpY2VfaWRlbnRpZmllcg==');

@$core.Deprecated('Use volumeDownRequestDescriptor instead')
const VolumeDownRequest$json = {
  '1': 'VolumeDownRequest',
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
      '1': 'group_device_identifier',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'groupDeviceIdentifier',
      '17': true
    },
  ],
  '8': [
    {'1': '_group_device_identifier'},
  ],
};

/// Descriptor for `VolumeDownRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List volumeDownRequestDescriptor = $convert.base64Decode(
    'ChFWb2x1bWVEb3duUmVxdWVzdBJVCg5sb2dnaW5nX3BhcmFtcxgBIAEoCzIuLnNwb3RpZnkuY2'
    '9ubmVjdC5lc3BlcmFudG8ucHJvdG8uTG9nZ2luZ1BhcmFtc1INbG9nZ2luZ1BhcmFtcxI7Chdn'
    'cm91cF9kZXZpY2VfaWRlbnRpZmllchgCIAEoCUgAUhVncm91cERldmljZUlkZW50aWZpZXKIAQ'
    'FCGgoYX2dyb3VwX2RldmljZV9pZGVudGlmaWVy');

@$core.Deprecated('Use localVolumeResponseDescriptor instead')
const LocalVolumeResponse$json = {
  '1': 'LocalVolumeResponse',
  '2': [
    {'1': 'volume', '3': 1, '4': 1, '5': 5, '10': 'volume'},
    {
      '1': 'reason',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.spotify.connect.esperanto.proto.LocalVolumeResponse.Reason',
      '10': 'reason'
    },
  ],
  '4': [LocalVolumeResponse_Reason$json],
};

@$core.Deprecated('Use localVolumeResponseDescriptor instead')
const LocalVolumeResponse_Reason$json = {
  '1': 'Reason',
  '2': [
    {'1': 'USER', '2': 0},
    {'1': 'SYSTEM', '2': 1},
  ],
};

/// Descriptor for `LocalVolumeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List localVolumeResponseDescriptor = $convert.base64Decode(
    'ChNMb2NhbFZvbHVtZVJlc3BvbnNlEhYKBnZvbHVtZRgBIAEoBVIGdm9sdW1lElMKBnJlYXNvbh'
    'gCIAEoDjI7LnNwb3RpZnkuY29ubmVjdC5lc3BlcmFudG8ucHJvdG8uTG9jYWxWb2x1bWVSZXNw'
    'b25zZS5SZWFzb25SBnJlYXNvbiIeCgZSZWFzb24SCAoEVVNFUhAAEgoKBlNZU1RFTRAB');

const $core.Map<$core.String, $core.dynamic> ConnectVolumeServiceBase$json = {
  '1': 'ConnectVolumeService',
  '2': [
    {
      '1': 'Volume',
      '2': '.google.protobuf.Empty',
      '3': '.spotify.connect.esperanto.proto.VolumeResponse',
      '6': true
    },
    {
      '1': 'LocalVolume',
      '2': '.google.protobuf.Empty',
      '3': '.spotify.connect.esperanto.proto.LocalVolumeResponse',
      '6': true
    },
    {
      '1': 'VolumeSet',
      '2': '.spotify.connect.esperanto.proto.VolumeSetRequest',
      '3': '.spotify.connect.esperanto.proto.StatusResponse'
    },
    {
      '1': 'VolumeUp',
      '2': '.spotify.connect.esperanto.proto.VolumeUpRequest',
      '3': '.spotify.connect.esperanto.proto.StatusResponse'
    },
    {
      '1': 'VolumeDown',
      '2': '.spotify.connect.esperanto.proto.VolumeDownRequest',
      '3': '.spotify.connect.esperanto.proto.StatusResponse'
    },
  ],
};

@$core.Deprecated('Use connectVolumeServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    ConnectVolumeServiceBase$messageJson = {
  '.google.protobuf.Empty': $1.Empty$json,
  '.spotify.connect.esperanto.proto.VolumeResponse': VolumeResponse$json,
  '.spotify.connect.esperanto.proto.VolumeResponse.GroupDeviceVolumesEntry':
      VolumeResponse_GroupDeviceVolumesEntry$json,
  '.spotify.connect.esperanto.proto.LocalVolumeResponse':
      LocalVolumeResponse$json,
  '.spotify.connect.esperanto.proto.VolumeSetRequest': VolumeSetRequest$json,
  '.spotify.connect.esperanto.proto.LoggingParams': $0.LoggingParams$json,
  '.spotify.connect.esperanto.proto.StatusResponse': $0.StatusResponse$json,
  '.spotify.connect.esperanto.proto.VolumeUpRequest': VolumeUpRequest$json,
  '.spotify.connect.esperanto.proto.VolumeDownRequest': VolumeDownRequest$json,
};

/// Descriptor for `ConnectVolumeService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List connectVolumeServiceDescriptor = $convert.base64Decode(
    'ChRDb25uZWN0Vm9sdW1lU2VydmljZRJTCgZWb2x1bWUSFi5nb29nbGUucHJvdG9idWYuRW1wdH'
    'kaLy5zcG90aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLlZvbHVtZVJlc3BvbnNlMAESXQoL'
    'TG9jYWxWb2x1bWUSFi5nb29nbGUucHJvdG9idWYuRW1wdHkaNC5zcG90aWZ5LmNvbm5lY3QuZX'
    'NwZXJhbnRvLnByb3RvLkxvY2FsVm9sdW1lUmVzcG9uc2UwARJvCglWb2x1bWVTZXQSMS5zcG90'
    'aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLlZvbHVtZVNldFJlcXVlc3QaLy5zcG90aWZ5Lm'
    'Nvbm5lY3QuZXNwZXJhbnRvLnByb3RvLlN0YXR1c1Jlc3BvbnNlEm0KCFZvbHVtZVVwEjAuc3Bv'
    'dGlmeS5jb25uZWN0LmVzcGVyYW50by5wcm90by5Wb2x1bWVVcFJlcXVlc3QaLy5zcG90aWZ5Lm'
    'Nvbm5lY3QuZXNwZXJhbnRvLnByb3RvLlN0YXR1c1Jlc3BvbnNlEnEKClZvbHVtZURvd24SMi5z'
    'cG90aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLlZvbHVtZURvd25SZXF1ZXN0Gi8uc3BvdG'
    'lmeS5jb25uZWN0LmVzcGVyYW50by5wcm90by5TdGF0dXNSZXNwb25zZQ==');
