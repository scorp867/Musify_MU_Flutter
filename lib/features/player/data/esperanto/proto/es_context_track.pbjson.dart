// This is a generated file - do not edit.
//
// Generated from es_context_track.proto.

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

@$core.Deprecated('Use contextTrackDescriptor instead')
const ContextTrack$json = {
  '1': 'ContextTrack',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'uid', '3': 2, '4': 1, '5': 9, '10': 'uid'},
    {
      '1': 'metadata',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ContextTrack.MetadataEntry',
      '10': 'metadata'
    },
  ],
  '3': [ContextTrack_MetadataEntry$json],
};

@$core.Deprecated('Use contextTrackDescriptor instead')
const ContextTrack_MetadataEntry$json = {
  '1': 'MetadataEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ContextTrack`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextTrackDescriptor = $convert.base64Decode(
    'CgxDb250ZXh0VHJhY2sSEAoDdXJpGAEgASgJUgN1cmkSEAoDdWlkGAIgASgJUgN1aWQSVgoIbW'
    'V0YWRhdGEYAyADKAsyOi5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uQ29udGV4dFRy'
    'YWNrLk1ldGFkYXRhRW50cnlSCG1ldGFkYXRhGjsKDU1ldGFkYXRhRW50cnkSEAoDa2V5GAEgAS'
    'gJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AQ==');
