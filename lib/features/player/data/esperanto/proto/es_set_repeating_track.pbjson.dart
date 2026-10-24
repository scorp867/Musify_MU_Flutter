// This is a generated file - do not edit.
//
// Generated from es_set_repeating_track.proto.

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

@$core.Deprecated('Use setRepeatingTrackRequestDescriptor instead')
const SetRepeatingTrackRequest$json = {
  '1': 'SetRepeatingTrackRequest',
  '2': [
    {'1': 'repeating_track', '3': 1, '4': 1, '5': 8, '10': 'repeatingTrack'},
    {
      '1': 'options',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.CommandOptions',
      '10': 'options'
    },
    {
      '1': 'logging_params',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.LoggingParams',
      '10': 'loggingParams'
    },
  ],
};

/// Descriptor for `SetRepeatingTrackRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setRepeatingTrackRequestDescriptor = $convert.base64Decode(
    'ChhTZXRSZXBlYXRpbmdUcmFja1JlcXVlc3QSJwoPcmVwZWF0aW5nX3RyYWNrGAEgASgIUg5yZX'
    'BlYXRpbmdUcmFjaxJICgdvcHRpb25zGAIgASgLMi4uc3BvdGlmeS5wbGF5ZXIuZXNwZXJhbnRv'
    'LnByb3RvLkNvbW1hbmRPcHRpb25zUgdvcHRpb25zElQKDmxvZ2dpbmdfcGFyYW1zGAMgASgLMi'
    '0uc3BvdGlmeS5wbGF5ZXIuZXNwZXJhbnRvLnByb3RvLkxvZ2dpbmdQYXJhbXNSDWxvZ2dpbmdQ'
    'YXJhbXM=');
