// This is a generated file - do not edit.
//
// Generated from es_context_page.proto.

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

@$core.Deprecated('Use contextPageDescriptor instead')
const ContextPage$json = {
  '1': 'ContextPage',
  '2': [
    {
      '1': 'tracks',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ContextTrack',
      '10': 'tracks'
    },
    {
      '1': 'metadata',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ContextPage.MetadataEntry',
      '10': 'metadata'
    },
    {'1': 'page_url', '3': 3, '4': 1, '5': 9, '10': 'pageUrl'},
    {'1': 'next_page_url', '3': 4, '4': 1, '5': 9, '10': 'nextPageUrl'},
    {'1': 'is_loading', '3': 5, '4': 1, '5': 8, '10': 'isLoading'},
  ],
  '3': [ContextPage_MetadataEntry$json],
};

@$core.Deprecated('Use contextPageDescriptor instead')
const ContextPage_MetadataEntry$json = {
  '1': 'MetadataEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ContextPage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextPageDescriptor = $convert.base64Decode(
    'CgtDb250ZXh0UGFnZRJECgZ0cmFja3MYASADKAsyLC5zcG90aWZ5LnBsYXllci5lc3BlcmFudG'
    '8ucHJvdG8uQ29udGV4dFRyYWNrUgZ0cmFja3MSVQoIbWV0YWRhdGEYAiADKAsyOS5zcG90aWZ5'
    'LnBsYXllci5lc3BlcmFudG8ucHJvdG8uQ29udGV4dFBhZ2UuTWV0YWRhdGFFbnRyeVIIbWV0YW'
    'RhdGESGQoIcGFnZV91cmwYAyABKAlSB3BhZ2VVcmwSIgoNbmV4dF9wYWdlX3VybBgEIAEoCVIL'
    'bmV4dFBhZ2VVcmwSHQoKaXNfbG9hZGluZxgFIAEoCFIJaXNMb2FkaW5nGjsKDU1ldGFkYXRhRW'
    '50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AQ==');
