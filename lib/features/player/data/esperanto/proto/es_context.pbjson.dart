// This is a generated file - do not edit.
//
// Generated from es_context.proto.

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

@$core.Deprecated('Use contextDescriptor instead')
const Context$json = {
  '1': 'Context',
  '2': [
    {
      '1': 'pages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ContextPage',
      '10': 'pages'
    },
    {
      '1': 'metadata',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.Context.MetadataEntry',
      '10': 'metadata'
    },
    {'1': 'uri', '3': 3, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'url', '3': 4, '4': 1, '5': 9, '10': 'url'},
    {'1': 'is_loading', '3': 5, '4': 1, '5': 8, '10': 'isLoading'},
    {
      '1': 'restrictions',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.Restrictions',
      '10': 'restrictions'
    },
  ],
  '3': [Context_MetadataEntry$json],
};

@$core.Deprecated('Use contextDescriptor instead')
const Context_MetadataEntry$json = {
  '1': 'MetadataEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `Context`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextDescriptor = $convert.base64Decode(
    'CgdDb250ZXh0EkEKBXBhZ2VzGAEgAygLMisuc3BvdGlmeS5wbGF5ZXIuZXNwZXJhbnRvLnByb3'
    'RvLkNvbnRleHRQYWdlUgVwYWdlcxJRCghtZXRhZGF0YRgCIAMoCzI1LnNwb3RpZnkucGxheWVy'
    'LmVzcGVyYW50by5wcm90by5Db250ZXh0Lk1ldGFkYXRhRW50cnlSCG1ldGFkYXRhEhAKA3VyaR'
    'gDIAEoCVIDdXJpEhAKA3VybBgEIAEoCVIDdXJsEh0KCmlzX2xvYWRpbmcYBSABKAhSCWlzTG9h'
    'ZGluZxJQCgxyZXN0cmljdGlvbnMYBiABKAsyLC5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucH'
    'JvdG8uUmVzdHJpY3Rpb25zUgxyZXN0cmljdGlvbnMaOwoNTWV0YWRhdGFFbnRyeRIQCgNrZXkY'
    'ASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB');
