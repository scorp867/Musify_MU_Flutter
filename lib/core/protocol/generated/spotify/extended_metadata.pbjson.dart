// This is a generated file - do not edit.
//
// Generated from spotify/extended_metadata.proto.

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

@$core.Deprecated('Use extensionTypeDescriptor instead')
const ExtensionType$json = {
  '1': 'ExtensionType',
  '2': [
    {'1': 'UNKNOWN', '2': 0},
    {'1': 'GENERIC', '2': 1},
    {'1': 'ASSOC', '2': 2},
  ],
};

/// Descriptor for `ExtensionType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List extensionTypeDescriptor = $convert.base64Decode(
    'Cg1FeHRlbnNpb25UeXBlEgsKB1VOS05PV04QABILCgdHRU5FUklDEAESCQoFQVNTT0MQAg==');

@$core.Deprecated('Use extensionQueryDescriptor instead')
const ExtensionQuery$json = {
  '1': 'ExtensionQuery',
  '2': [
    {
      '1': 'extension_kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.spotify.extendedmetadata.ExtensionKind',
      '10': 'extensionKind'
    },
    {'1': 'etag', '3': 2, '4': 1, '5': 9, '10': 'etag'},
  ],
};

/// Descriptor for `ExtensionQuery`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List extensionQueryDescriptor = $convert.base64Decode(
    'Cg5FeHRlbnNpb25RdWVyeRJOCg5leHRlbnNpb25fa2luZBgBIAEoDjInLnNwb3RpZnkuZXh0ZW'
    '5kZWRtZXRhZGF0YS5FeHRlbnNpb25LaW5kUg1leHRlbnNpb25LaW5kEhIKBGV0YWcYAiABKAlS'
    'BGV0YWc=');

@$core.Deprecated('Use entityRequestDescriptor instead')
const EntityRequest$json = {
  '1': 'EntityRequest',
  '2': [
    {'1': 'entity_uri', '3': 1, '4': 1, '5': 9, '10': 'entityUri'},
    {
      '1': 'query',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.extendedmetadata.ExtensionQuery',
      '10': 'query'
    },
  ],
};

/// Descriptor for `EntityRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List entityRequestDescriptor = $convert.base64Decode(
    'Cg1FbnRpdHlSZXF1ZXN0Eh0KCmVudGl0eV91cmkYASABKAlSCWVudGl0eVVyaRI+CgVxdWVyeR'
    'gCIAMoCzIoLnNwb3RpZnkuZXh0ZW5kZWRtZXRhZGF0YS5FeHRlbnNpb25RdWVyeVIFcXVlcnk=');

@$core.Deprecated('Use batchedEntityRequestHeaderDescriptor instead')
const BatchedEntityRequestHeader$json = {
  '1': 'BatchedEntityRequestHeader',
  '2': [
    {'1': 'country', '3': 1, '4': 1, '5': 9, '10': 'country'},
    {'1': 'catalogue', '3': 2, '4': 1, '5': 9, '10': 'catalogue'},
    {'1': 'task_id', '3': 3, '4': 1, '5': 12, '10': 'taskId'},
  ],
};

/// Descriptor for `BatchedEntityRequestHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batchedEntityRequestHeaderDescriptor =
    $convert.base64Decode(
        'ChpCYXRjaGVkRW50aXR5UmVxdWVzdEhlYWRlchIYCgdjb3VudHJ5GAEgASgJUgdjb3VudHJ5Eh'
        'wKCWNhdGFsb2d1ZRgCIAEoCVIJY2F0YWxvZ3VlEhcKB3Rhc2tfaWQYAyABKAxSBnRhc2tJZA==');

@$core.Deprecated('Use batchedEntityRequestDescriptor instead')
const BatchedEntityRequest$json = {
  '1': 'BatchedEntityRequest',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.extendedmetadata.BatchedEntityRequestHeader',
      '10': 'header'
    },
    {
      '1': 'entity_request',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.extendedmetadata.EntityRequest',
      '10': 'entityRequest'
    },
  ],
};

/// Descriptor for `BatchedEntityRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batchedEntityRequestDescriptor = $convert.base64Decode(
    'ChRCYXRjaGVkRW50aXR5UmVxdWVzdBJMCgZoZWFkZXIYASABKAsyNC5zcG90aWZ5LmV4dGVuZG'
    'VkbWV0YWRhdGEuQmF0Y2hlZEVudGl0eVJlcXVlc3RIZWFkZXJSBmhlYWRlchJOCg5lbnRpdHlf'
    'cmVxdWVzdBgCIAMoCzInLnNwb3RpZnkuZXh0ZW5kZWRtZXRhZGF0YS5FbnRpdHlSZXF1ZXN0Ug'
    '1lbnRpdHlSZXF1ZXN0');

@$core.Deprecated('Use entityExtensionDataArrayHeaderDescriptor instead')
const EntityExtensionDataArrayHeader$json = {
  '1': 'EntityExtensionDataArrayHeader',
  '2': [
    {
      '1': 'provider_error_status',
      '3': 1,
      '4': 1,
      '5': 5,
      '10': 'providerErrorStatus'
    },
    {
      '1': 'cache_ttl_in_seconds',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'cacheTtlInSeconds'
    },
    {
      '1': 'offline_ttl_in_seconds',
      '3': 3,
      '4': 1,
      '5': 3,
      '10': 'offlineTtlInSeconds'
    },
    {
      '1': 'extension_type',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.spotify.extendedmetadata.ExtensionType',
      '10': 'extensionType'
    },
  ],
};

/// Descriptor for `EntityExtensionDataArrayHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List entityExtensionDataArrayHeaderDescriptor = $convert.base64Decode(
    'Ch5FbnRpdHlFeHRlbnNpb25EYXRhQXJyYXlIZWFkZXISMgoVcHJvdmlkZXJfZXJyb3Jfc3RhdH'
    'VzGAEgASgFUhNwcm92aWRlckVycm9yU3RhdHVzEi8KFGNhY2hlX3R0bF9pbl9zZWNvbmRzGAIg'
    'ASgDUhFjYWNoZVR0bEluU2Vjb25kcxIzChZvZmZsaW5lX3R0bF9pbl9zZWNvbmRzGAMgASgDUh'
    'NvZmZsaW5lVHRsSW5TZWNvbmRzEk4KDmV4dGVuc2lvbl90eXBlGAQgASgOMicuc3BvdGlmeS5l'
    'eHRlbmRlZG1ldGFkYXRhLkV4dGVuc2lvblR5cGVSDWV4dGVuc2lvblR5cGU=');

@$core.Deprecated('Use entityExtensionDataArrayDescriptor instead')
const EntityExtensionDataArray$json = {
  '1': 'EntityExtensionDataArray',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.extendedmetadata.EntityExtensionDataArrayHeader',
      '10': 'header'
    },
    {
      '1': 'extension_kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.spotify.extendedmetadata.ExtensionKind',
      '10': 'extensionKind'
    },
    {
      '1': 'extension_data',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.spotify.extendedmetadata.EntityExtensionData',
      '10': 'extensionData'
    },
  ],
};

/// Descriptor for `EntityExtensionDataArray`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List entityExtensionDataArrayDescriptor = $convert.base64Decode(
    'ChhFbnRpdHlFeHRlbnNpb25EYXRhQXJyYXkSUAoGaGVhZGVyGAEgASgLMjguc3BvdGlmeS5leH'
    'RlbmRlZG1ldGFkYXRhLkVudGl0eUV4dGVuc2lvbkRhdGFBcnJheUhlYWRlclIGaGVhZGVyEk4K'
    'DmV4dGVuc2lvbl9raW5kGAIgASgOMicuc3BvdGlmeS5leHRlbmRlZG1ldGFkYXRhLkV4dGVuc2'
    'lvbktpbmRSDWV4dGVuc2lvbktpbmQSVAoOZXh0ZW5zaW9uX2RhdGEYAyADKAsyLS5zcG90aWZ5'
    'LmV4dGVuZGVkbWV0YWRhdGEuRW50aXR5RXh0ZW5zaW9uRGF0YVINZXh0ZW5zaW9uRGF0YQ==');

@$core.Deprecated('Use batchedExtensionResponseHeaderDescriptor instead')
const BatchedExtensionResponseHeader$json = {
  '1': 'BatchedExtensionResponseHeader',
};

/// Descriptor for `BatchedExtensionResponseHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batchedExtensionResponseHeaderDescriptor =
    $convert.base64Decode('Ch5CYXRjaGVkRXh0ZW5zaW9uUmVzcG9uc2VIZWFkZXI=');

@$core.Deprecated('Use batchedExtensionResponseDescriptor instead')
const BatchedExtensionResponse$json = {
  '1': 'BatchedExtensionResponse',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.extendedmetadata.BatchedExtensionResponseHeader',
      '10': 'header'
    },
    {
      '1': 'extended_metadata',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.extendedmetadata.EntityExtensionDataArray',
      '10': 'extendedMetadata'
    },
  ],
};

/// Descriptor for `BatchedExtensionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batchedExtensionResponseDescriptor = $convert.base64Decode(
    'ChhCYXRjaGVkRXh0ZW5zaW9uUmVzcG9uc2USUAoGaGVhZGVyGAEgASgLMjguc3BvdGlmeS5leH'
    'RlbmRlZG1ldGFkYXRhLkJhdGNoZWRFeHRlbnNpb25SZXNwb25zZUhlYWRlclIGaGVhZGVyEl8K'
    'EWV4dGVuZGVkX21ldGFkYXRhGAIgAygLMjIuc3BvdGlmeS5leHRlbmRlZG1ldGFkYXRhLkVudG'
    'l0eUV4dGVuc2lvbkRhdGFBcnJheVIQZXh0ZW5kZWRNZXRhZGF0YQ==');
