// 1:1 Replicated Spotify Esperanto Cast Messages Json Descriptors
// Sources:
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
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

import 'package:protobuf/well_known_types/google/protobuf/wrappers.pbjson.dart'
    as $0;

@$core.Deprecated('Use castResultDescriptor instead')
const CastResult$json = {
  '1': 'CastResult',
  '2': [
    {'1': 'CAST_RESULT_OK', '2': 0},
    {'1': 'CAST_RESULT_NOT_FOUND', '2': 1},
    {'1': 'CAST_RESULT_FAILED_TO_PARSE_JSON', '2': 2},
    {'1': 'CAST_RESULT_INVALID_STATE', '2': 3},
  ],
};

/// Descriptor for `CastResult`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List castResultDescriptor = $convert.base64Decode(
    'CgpDYXN0UmVzdWx0EhIKDkNBU1RfUkVTVUxUX09LEAASGQoVQ0FTVF9SRVNVTFRfTk9UX0ZPVU'
    '5EEAESJAogQ0FTVF9SRVNVTFRfRkFJTEVEX1RPX1BBUlNFX0pTT04QAhIdChlDQVNUX1JFU1VM'
    'VF9JTlZBTElEX1NUQVRFEAM=');

@$core.Deprecated('Use deviceIdDescriptor instead')
const DeviceId$json = {
  '1': 'DeviceId',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 9, '10': 'deviceId'},
  ],
};

/// Descriptor for `DeviceId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceIdDescriptor = $convert
    .base64Decode('CghEZXZpY2VJZBIbCglkZXZpY2VfaWQYASABKAlSCGRldmljZUlk');

@$core.Deprecated('Use putDeviceRequestDescriptor instead')
const PutDeviceRequest$json = {
  '1': 'PutDeviceRequest',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'json', '3': 2, '4': 1, '5': 12, '10': 'json'},
  ],
};

/// Descriptor for `PutDeviceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List putDeviceRequestDescriptor = $convert.base64Decode(
    'ChBQdXREZXZpY2VSZXF1ZXN0EhsKCWRldmljZV9pZBgBIAEoCVIIZGV2aWNlSWQSEgoEanNvbh'
    'gCIAEoDFIEanNvbg==');

@$core.Deprecated('Use connectionErrorRequestDescriptor instead')
const ConnectionErrorRequest$json = {
  '1': 'ConnectionErrorRequest',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'error', '3': 2, '4': 1, '5': 5, '10': 'error'},
    {
      '1': 'platform_error_code',
      '3': 3,
      '4': 1,
      '5': 5,
      '10': 'platformErrorCode'
    },
  ],
};

/// Descriptor for `ConnectionErrorRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionErrorRequestDescriptor = $convert.base64Decode(
    'ChZDb25uZWN0aW9uRXJyb3JSZXF1ZXN0EhsKCWRldmljZV9pZBgBIAEoCVIIZGV2aWNlSWQSFA'
    'oFZXJyb3IYAiABKAVSBWVycm9yEi4KE3BsYXRmb3JtX2Vycm9yX2NvZGUYAyABKAVSEXBsYXRm'
    'b3JtRXJyb3JDb2Rl');

@$core.Deprecated('Use connectRequestDescriptor instead')
const ConnectRequest$json = {
  '1': 'ConnectRequest',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'interaction_ids', '3': 2, '4': 3, '5': 9, '10': 'interactionIds'},
  ],
};

/// Descriptor for `ConnectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectRequestDescriptor = $convert.base64Decode(
    'Cg5Db25uZWN0UmVxdWVzdBIbCglkZXZpY2VfaWQYASABKAlSCGRldmljZUlkEicKD2ludGVyYW'
    'N0aW9uX2lkcxgCIAMoCVIOaW50ZXJhY3Rpb25JZHM=');

@$core.Deprecated('Use responseDescriptor instead')
const Response$json = {
  '1': 'Response',
  '2': [
    {
      '1': 'result',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.spotify.connect.discovery.cast.esperanto.proto.CastResult',
      '10': 'result'
    },
  ],
};

/// Descriptor for `Response`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseDescriptor = $convert.base64Decode(
    'CghSZXNwb25zZRJSCgZyZXN1bHQYASABKA4yOi5zcG90aWZ5LmNvbm5lY3QuZGlzY292ZXJ5Lm'
    'Nhc3QuZXNwZXJhbnRvLnByb3RvLkNhc3RSZXN1bHRSBnJlc3VsdA==');

const $core.Map<$core.String, $core.dynamic> CastServiceBase$json = {
  '1': 'CastService',
  '2': [
    {
      '1': 'Connect',
      '2': '.spotify.connect.discovery.cast.esperanto.proto.DeviceId',
      '3': '.spotify.connect.discovery.cast.esperanto.proto.Response'
    },
    {
      '1': 'ConnectionError',
      '2':
          '.spotify.connect.discovery.cast.esperanto.proto.ConnectionErrorRequest',
      '3': '.spotify.connect.discovery.cast.esperanto.proto.Response'
    },
    {
      '1': 'DeleteDevice',
      '2': '.spotify.connect.discovery.cast.esperanto.proto.DeviceId',
      '3': '.spotify.connect.discovery.cast.esperanto.proto.Response'
    },
    {
      '1': 'PutDevice',
      '2': '.spotify.connect.discovery.cast.esperanto.proto.PutDeviceRequest',
      '3': '.spotify.connect.discovery.cast.esperanto.proto.Response'
    },
    {
      '1': 'PutMessage',
      '2': '.google.protobuf.BytesValue',
      '3': '.spotify.connect.discovery.cast.esperanto.proto.Response'
    },
  ],
};

@$core.Deprecated('Use castServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    CastServiceBase$messageJson = {
  '.spotify.connect.discovery.cast.esperanto.proto.DeviceId': DeviceId$json,
  '.spotify.connect.discovery.cast.esperanto.proto.Response': Response$json,
  '.spotify.connect.discovery.cast.esperanto.proto.ConnectionErrorRequest':
      ConnectionErrorRequest$json,
  '.spotify.connect.discovery.cast.esperanto.proto.PutDeviceRequest':
      PutDeviceRequest$json,
  '.google.protobuf.BytesValue': $0.BytesValue$json,
};

/// Descriptor for `CastService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List castServiceDescriptor = $convert.base64Decode(
    'CgtDYXN0U2VydmljZRJ9CgdDb25uZWN0Ejguc3BvdGlmeS5jb25uZWN0LmRpc2NvdmVyeS5jYX'
    'N0LmVzcGVyYW50by5wcm90by5EZXZpY2VJZBo4LnNwb3RpZnkuY29ubmVjdC5kaXNjb3Zlcnku'
    'Y2FzdC5lc3BlcmFudG8ucHJvdG8uUmVzcG9uc2USkwEKD0Nvbm5lY3Rpb25FcnJvchJGLnNwb3'
    'RpZnkuY29ubmVjdC5kaXNjb3ZlcnkuY2FzdC5lc3BlcmFudG8ucHJvdG8uQ29ubmVjdGlvbkVy'
    'cm9yUmVxdWVzdBo4LnNwb3RpZnkuY29ubmVjdC5kaXNjb3ZlcnkuY2FzdC5lc3BlcmFudG8ucH'
    'JvdG8uUmVzcG9uc2USggEKDERlbGV0ZURldmljZRI4LnNwb3RpZnkuY29ubmVjdC5kaXNjb3Zl'
    'cnkuY2FzdC5lc3BlcmFudG8ucHJvdG8uRGV2aWNlSWQaOC5zcG90aWZ5LmNvbm5lY3QuZGlzY2'
    '92ZXJ5LmNhc3QuZXNwZXJhbnRvLnByb3RvLlJlc3BvbnNlEocBCglQdXREZXZpY2USQC5zcG90'
    'aWZ5LmNvbm5lY3QuZGlzY292ZXJ5LmNhc3QuZXNwZXJhbnRvLnByb3RvLlB1dERldmljZVJlcX'
    'Vlc3QaOC5zcG90aWZ5LmNvbm5lY3QuZGlzY292ZXJ5LmNhc3QuZXNwZXJhbnRvLnByb3RvLlJl'
    'c3BvbnNlEmMKClB1dE1lc3NhZ2USGy5nb29nbGUucHJvdG9idWYuQnl0ZXNWYWx1ZRo4LnNwb3'
    'RpZnkuY29ubmVjdC5kaXNjb3ZlcnkuY2FzdC5lc3BlcmFudG8ucHJvdG8uUmVzcG9uc2U=');
