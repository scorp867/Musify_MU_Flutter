// This is a generated file - do not edit.
//
// Generated from es_queue.proto.

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

@$core.Deprecated('Use queueDescriptor instead')
const Queue$json = {
  '1': 'Queue',
  '2': [
    {'1': 'queue_revision', '3': 1, '4': 1, '5': 4, '10': 'queueRevision'},
    {
      '1': 'track',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ProvidedTrack',
      '10': 'track'
    },
    {
      '1': 'next_tracks',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ProvidedTrack',
      '10': 'nextTracks'
    },
    {
      '1': 'prev_tracks',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ProvidedTrack',
      '10': 'prevTracks'
    },
  ],
};

/// Descriptor for `Queue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queueDescriptor = $convert.base64Decode(
    'CgVRdWV1ZRIlCg5xdWV1ZV9yZXZpc2lvbhgBIAEoBFINcXVldWVSZXZpc2lvbhJDCgV0cmFjax'
    'gCIAEoCzItLnNwb3RpZnkucGxheWVyLmVzcGVyYW50by5wcm90by5Qcm92aWRlZFRyYWNrUgV0'
    'cmFjaxJOCgtuZXh0X3RyYWNrcxgDIAMoCzItLnNwb3RpZnkucGxheWVyLmVzcGVyYW50by5wcm'
    '90by5Qcm92aWRlZFRyYWNrUgpuZXh0VHJhY2tzEk4KC3ByZXZfdHJhY2tzGAQgAygLMi0uc3Bv'
    'dGlmeS5wbGF5ZXIuZXNwZXJhbnRvLnByb3RvLlByb3ZpZGVkVHJhY2tSCnByZXZUcmFja3M=');
