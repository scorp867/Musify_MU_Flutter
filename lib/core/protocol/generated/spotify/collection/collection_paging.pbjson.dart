// This is a generated file - do not edit.
//
// Generated from spotify/collection/collection_paging.proto.

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

@$core.Deprecated('Use pageRequestDescriptor instead')
const PageRequest$json = {
  '1': 'PageRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {'1': 'set_name', '3': 2, '4': 1, '5': 9, '10': 'setName'},
    {'1': 'limit', '3': 4, '4': 1, '5': 17, '10': 'limit'},
  ],
};

/// Descriptor for `PageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pageRequestDescriptor = $convert.base64Decode(
    'CgtQYWdlUmVxdWVzdBIaCgh1c2VybmFtZRgBIAEoCVIIdXNlcm5hbWUSGQoIc2V0X25hbWUYAi'
    'ABKAlSB3NldE5hbWUSFAoFbGltaXQYBCABKBFSBWxpbWl0');

@$core.Deprecated('Use pageResponseDescriptor instead')
const PageResponse$json = {
  '1': 'PageResponse',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.collection.v2.CollectionItem',
      '10': 'items'
    },
    {'1': 'sync_token', '3': 3, '4': 1, '5': 9, '10': 'syncToken'},
  ],
};

/// Descriptor for `PageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pageResponseDescriptor = $convert.base64Decode(
    'CgxQYWdlUmVzcG9uc2USOwoFaXRlbXMYASADKAsyJS5zcG90aWZ5LmNvbGxlY3Rpb24udjIuQ2'
    '9sbGVjdGlvbkl0ZW1SBWl0ZW1zEh0KCnN5bmNfdG9rZW4YAyABKAlSCXN5bmNUb2tlbg==');

@$core.Deprecated('Use collectionItemDescriptor instead')
const CollectionItem$json = {
  '1': 'CollectionItem',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'added_at', '3': 2, '4': 1, '5': 3, '10': 'addedAt'},
  ],
};

/// Descriptor for `CollectionItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List collectionItemDescriptor = $convert.base64Decode(
    'Cg5Db2xsZWN0aW9uSXRlbRIQCgN1cmkYASABKAlSA3VyaRIZCghhZGRlZF9hdBgCIAEoA1IHYW'
    'RkZWRBdA==');
