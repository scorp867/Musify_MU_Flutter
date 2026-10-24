// This is a generated file - do not edit.
//
// Generated from es_get_state_request.proto.

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

@$core.Deprecated('Use getStateRequestDescriptor instead')
const GetStateRequest$json = {
  '1': 'GetStateRequest',
  '2': [
    {
      '1': 'prev_tracks_cap',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.OptionalInt64',
      '10': 'prevTracksCap'
    },
    {
      '1': 'next_tracks_cap',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.OptionalInt64',
      '10': 'nextTracksCap'
    },
  ],
};

/// Descriptor for `GetStateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStateRequestDescriptor = $convert.base64Decode(
    'Cg9HZXRTdGF0ZVJlcXVlc3QSVQoPcHJldl90cmFja3NfY2FwGAEgASgLMi0uc3BvdGlmeS5wbG'
    'F5ZXIuZXNwZXJhbnRvLnByb3RvLk9wdGlvbmFsSW50NjRSDXByZXZUcmFja3NDYXASVQoPbmV4'
    'dF90cmFja3NfY2FwGAIgASgLMi0uc3BvdGlmeS5wbGF5ZXIuZXNwZXJhbnRvLnByb3RvLk9wdG'
    'lvbmFsSW50NjRSDW5leHRUcmFja3NDYXA=');
