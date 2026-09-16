// This is a generated file - do not edit.
//
// Generated from spotify/entity_extension_data.proto.

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

@$core.Deprecated('Use entityExtensionDataHeaderDescriptor instead')
const EntityExtensionDataHeader$json = {
  '1': 'EntityExtensionDataHeader',
  '2': [
    {'1': 'status_code', '3': 1, '4': 1, '5': 5, '10': 'statusCode'},
    {'1': 'etag', '3': 2, '4': 1, '5': 9, '10': 'etag'},
    {'1': 'locale', '3': 3, '4': 1, '5': 9, '10': 'locale'},
    {
      '1': 'cache_ttl_in_seconds',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'cacheTtlInSeconds'
    },
    {
      '1': 'offline_ttl_in_seconds',
      '3': 5,
      '4': 1,
      '5': 3,
      '10': 'offlineTtlInSeconds'
    },
  ],
};

/// Descriptor for `EntityExtensionDataHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List entityExtensionDataHeaderDescriptor = $convert.base64Decode(
    'ChlFbnRpdHlFeHRlbnNpb25EYXRhSGVhZGVyEh8KC3N0YXR1c19jb2RlGAEgASgFUgpzdGF0dX'
    'NDb2RlEhIKBGV0YWcYAiABKAlSBGV0YWcSFgoGbG9jYWxlGAMgASgJUgZsb2NhbGUSLwoUY2Fj'
    'aGVfdHRsX2luX3NlY29uZHMYBCABKANSEWNhY2hlVHRsSW5TZWNvbmRzEjMKFm9mZmxpbmVfdH'
    'RsX2luX3NlY29uZHMYBSABKANSE29mZmxpbmVUdGxJblNlY29uZHM=');

@$core.Deprecated('Use entityExtensionDataDescriptor instead')
const EntityExtensionData$json = {
  '1': 'EntityExtensionData',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.extendedmetadata.EntityExtensionDataHeader',
      '10': 'header'
    },
    {'1': 'entity_uri', '3': 2, '4': 1, '5': 9, '10': 'entityUri'},
    {
      '1': 'extension_data',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Any',
      '10': 'extensionData'
    },
  ],
};

/// Descriptor for `EntityExtensionData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List entityExtensionDataDescriptor = $convert.base64Decode(
    'ChNFbnRpdHlFeHRlbnNpb25EYXRhEksKBmhlYWRlchgBIAEoCzIzLnNwb3RpZnkuZXh0ZW5kZW'
    'RtZXRhZGF0YS5FbnRpdHlFeHRlbnNpb25EYXRhSGVhZGVyUgZoZWFkZXISHQoKZW50aXR5X3Vy'
    'aRgCIAEoCVIJZW50aXR5VXJpEjsKDmV4dGVuc2lvbl9kYXRhGAMgASgLMhQuZ29vZ2xlLnByb3'
    'RvYnVmLkFueVINZXh0ZW5zaW9uRGF0YQ==');
