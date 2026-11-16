// 1:1 Replicated Spotify Connect Group Json Descriptors
// Sources:
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
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use groupingStatusDescriptor instead')
const GroupingStatus$json = {
  '1': 'GroupingStatus',
  '2': [
    {'1': 'UNKNOWN_GROUPING_STATUS', '2': 0},
    {'1': 'GROUPED', '2': 1},
    {'1': 'GROUPABLE', '2': 2},
    {'1': 'GROUPING', '2': 3},
  ],
};

/// Descriptor for `GroupingStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List groupingStatusDescriptor = $convert.base64Decode(
    'Cg5Hcm91cGluZ1N0YXR1cxIbChdVTktOT1dOX0dST1VQSU5HX1NUQVRVUxAAEgsKB0dST1VQRU'
    'QQARINCglHUk9VUEFCTEUQAhIMCghHUk9VUElORxAD');

@$core.Deprecated('Use groupCapabilitiesDescriptor instead')
const GroupCapabilities$json = {
  '1': 'GroupCapabilities',
  '2': [
    {'1': 'max_devices', '3': 1, '4': 1, '5': 13, '10': 'maxDevices'},
  ],
};

/// Descriptor for `GroupCapabilities`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupCapabilitiesDescriptor = $convert.base64Decode(
    'ChFHcm91cENhcGFiaWxpdGllcxIfCgttYXhfZGV2aWNlcxgBIAEoDVIKbWF4RGV2aWNlcw==');

@$core.Deprecated('Use groupDeviceCapabilitiesDescriptor instead')
const GroupDeviceCapabilities$json = {
  '1': 'GroupDeviceCapabilities',
  '2': [
    {'1': 'removable', '3': 1, '4': 1, '5': 8, '10': 'removable'},
    {
      '1': 'removal_dissolves_group',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'removalDissolvesGroup'
    },
  ],
};

/// Descriptor for `GroupDeviceCapabilities`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupDeviceCapabilitiesDescriptor = $convert.base64Decode(
    'ChdHcm91cERldmljZUNhcGFiaWxpdGllcxIcCglyZW1vdmFibGUYASABKAhSCXJlbW92YWJsZR'
    'I2ChdyZW1vdmFsX2Rpc3NvbHZlc19ncm91cBgCIAEoCFIVcmVtb3ZhbERpc3NvbHZlc0dyb3Vw');

@$core.Deprecated('Use groupDeviceIdentifiersDescriptor instead')
const GroupDeviceIdentifiers$json = {
  '1': 'GroupDeviceIdentifiers',
  '2': [
    {
      '1': 'group_device_identifier',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'groupDeviceIdentifier'
    },
    {
      '1': 'local_identifier',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'localIdentifier',
      '17': true
    },
    {
      '1': 'deduplication_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'deduplicationId',
      '17': true
    },
    {
      '1': 'connect_state_identifier',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'connectStateIdentifier',
      '17': true
    },
  ],
  '8': [
    {'1': '_local_identifier'},
    {'1': '_deduplication_id'},
    {'1': '_connect_state_identifier'},
  ],
};

/// Descriptor for `GroupDeviceIdentifiers`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupDeviceIdentifiersDescriptor = $convert.base64Decode(
    'ChZHcm91cERldmljZUlkZW50aWZpZXJzEjYKF2dyb3VwX2RldmljZV9pZGVudGlmaWVyGAEgAS'
    'gJUhVncm91cERldmljZUlkZW50aWZpZXISLgoQbG9jYWxfaWRlbnRpZmllchgCIAEoCUgAUg9s'
    'b2NhbElkZW50aWZpZXKIAQESLgoQZGVkdXBsaWNhdGlvbl9pZBgDIAEoCUgBUg9kZWR1cGxpY2'
    'F0aW9uSWSIAQESPQoYY29ubmVjdF9zdGF0ZV9pZGVudGlmaWVyGAQgASgJSAJSFmNvbm5lY3RT'
    'dGF0ZUlkZW50aWZpZXKIAQFCEwoRX2xvY2FsX2lkZW50aWZpZXJCEwoRX2RlZHVwbGljYXRpb2'
    '5faWRCGwoZX2Nvbm5lY3Rfc3RhdGVfaWRlbnRpZmllcg==');

@$core.Deprecated('Use groupDeviceVolumeDescriptor instead')
const GroupDeviceVolume$json = {
  '1': 'GroupDeviceVolume',
  '2': [
    {'1': 'volume', '3': 1, '4': 1, '5': 13, '10': 'volume'},
    {'1': 'volume_steps', '3': 2, '4': 1, '5': 5, '10': 'volumeSteps'},
  ],
};

/// Descriptor for `GroupDeviceVolume`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupDeviceVolumeDescriptor = $convert.base64Decode(
    'ChFHcm91cERldmljZVZvbHVtZRIWCgZ2b2x1bWUYASABKA1SBnZvbHVtZRIhCgx2b2x1bWVfc3'
    'RlcHMYAiABKAVSC3ZvbHVtZVN0ZXBz');

@$core.Deprecated('Use groupDeviceDescriptor instead')
const GroupDevice$json = {
  '1': 'GroupDevice',
  '2': [
    {
      '1': 'identifiers',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.connect.GroupDeviceIdentifiers',
      '10': 'identifiers'
    },
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'type', '3': 3, '4': 1, '5': 9, '10': 'type'},
    {
      '1': 'model_display_name',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'modelDisplayName'
    },
    {
      '1': 'capabilities',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.spotify.connect.GroupDeviceCapabilities',
      '10': 'capabilities'
    },
    {
      '1': 'grouping_status',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.spotify.connect.GroupingStatus',
      '10': 'groupingStatus'
    },
    {
      '1': 'volume',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.spotify.connect.GroupDeviceVolume',
      '10': 'volume'
    },
  ],
};

/// Descriptor for `GroupDevice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupDeviceDescriptor = $convert.base64Decode(
    'CgtHcm91cERldmljZRJJCgtpZGVudGlmaWVycxgBIAEoCzInLnNwb3RpZnkuY29ubmVjdC5Hcm'
    '91cERldmljZUlkZW50aWZpZXJzUgtpZGVudGlmaWVycxISCgRuYW1lGAIgASgJUgRuYW1lEhIK'
    'BHR5cGUYAyABKAlSBHR5cGUSLAoSbW9kZWxfZGlzcGxheV9uYW1lGAQgASgJUhBtb2RlbERpc3'
    'BsYXlOYW1lEkwKDGNhcGFiaWxpdGllcxgFIAEoCzIoLnNwb3RpZnkuY29ubmVjdC5Hcm91cERl'
    'dmljZUNhcGFiaWxpdGllc1IMY2FwYWJpbGl0aWVzEkgKD2dyb3VwaW5nX3N0YXR1cxgGIAEoDj'
    'IfLnNwb3RpZnkuY29ubmVjdC5Hcm91cGluZ1N0YXR1c1IOZ3JvdXBpbmdTdGF0dXMSOgoGdm9s'
    'dW1lGAcgASgLMiIuc3BvdGlmeS5jb25uZWN0Lkdyb3VwRGV2aWNlVm9sdW1lUgZ2b2x1bWU=');

@$core.Deprecated('Use groupDataDescriptor instead')
const GroupData$json = {
  '1': 'GroupData',
  '2': [
    {
      '1': 'devices',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.connect.GroupDevice',
      '10': 'devices'
    },
    {
      '1': 'capabilities',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.connect.GroupCapabilities',
      '10': 'capabilities'
    },
  ],
};

/// Descriptor for `GroupData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupDataDescriptor = $convert.base64Decode(
    'CglHcm91cERhdGESNgoHZGV2aWNlcxgBIAMoCzIcLnNwb3RpZnkuY29ubmVjdC5Hcm91cERldm'
    'ljZVIHZGV2aWNlcxJGCgxjYXBhYmlsaXRpZXMYAiABKAsyIi5zcG90aWZ5LmNvbm5lY3QuR3Jv'
    'dXBDYXBhYmlsaXRpZXNSDGNhcGFiaWxpdGllcw==');
