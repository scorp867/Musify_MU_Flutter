// This is a generated file - do not edit.
//
// Generated from es_context_player_options.proto.

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

@$core.Deprecated('Use contextPlayerOptionsDescriptor instead')
const ContextPlayerOptions$json = {
  '1': 'ContextPlayerOptions',
  '2': [
    {
      '1': 'shuffling_context',
      '3': 1,
      '4': 1,
      '5': 8,
      '10': 'shufflingContext'
    },
    {
      '1': 'repeating_context',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'repeatingContext'
    },
    {'1': 'repeating_track', '3': 3, '4': 1, '5': 8, '10': 'repeatingTrack'},
    {
      '1': 'modes',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ContextPlayerOptions.ModesEntry',
      '10': 'modes'
    },
    {
      '1': 'playback_speed',
      '3': 4,
      '4': 1,
      '5': 2,
      '9': 0,
      '10': 'playbackSpeed',
      '17': true
    },
  ],
  '3': [ContextPlayerOptions_ModesEntry$json],
  '8': [
    {'1': '_playback_speed'},
  ],
};

@$core.Deprecated('Use contextPlayerOptionsDescriptor instead')
const ContextPlayerOptions_ModesEntry$json = {
  '1': 'ModesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ContextPlayerOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextPlayerOptionsDescriptor = $convert.base64Decode(
    'ChRDb250ZXh0UGxheWVyT3B0aW9ucxIrChFzaHVmZmxpbmdfY29udGV4dBgBIAEoCFIQc2h1Zm'
    'ZsaW5nQ29udGV4dBIrChFyZXBlYXRpbmdfY29udGV4dBgCIAEoCFIQcmVwZWF0aW5nQ29udGV4'
    'dBInCg9yZXBlYXRpbmdfdHJhY2sYAyABKAhSDnJlcGVhdGluZ1RyYWNrElUKBW1vZGVzGAUgAy'
    'gLMj8uc3BvdGlmeS5wbGF5ZXIuZXNwZXJhbnRvLnByb3RvLkNvbnRleHRQbGF5ZXJPcHRpb25z'
    'Lk1vZGVzRW50cnlSBW1vZGVzEioKDnBsYXliYWNrX3NwZWVkGAQgASgCSABSDXBsYXliYWNrU3'
    'BlZWSIAQEaOAoKTW9kZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIF'
    'dmFsdWU6AjgBQhEKD19wbGF5YmFja19zcGVlZA==');

@$core.Deprecated('Use contextPlayerOptionOverridesDescriptor instead')
const ContextPlayerOptionOverrides$json = {
  '1': 'ContextPlayerOptionOverrides',
  '2': [
    {
      '1': 'shuffling_context',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.OptionalBoolean',
      '10': 'shufflingContext'
    },
    {
      '1': 'repeating_context',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.OptionalBoolean',
      '10': 'repeatingContext'
    },
    {
      '1': 'repeating_track',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.OptionalBoolean',
      '10': 'repeatingTrack'
    },
    {
      '1': 'modes',
      '3': 5,
      '4': 3,
      '5': 11,
      '6':
          '.spotify.player.esperanto.proto.ContextPlayerOptionOverrides.ModesEntry',
      '10': 'modes'
    },
    {
      '1': 'playback_speed',
      '3': 4,
      '4': 1,
      '5': 2,
      '9': 0,
      '10': 'playbackSpeed',
      '17': true
    },
  ],
  '3': [ContextPlayerOptionOverrides_ModesEntry$json],
  '8': [
    {'1': '_playback_speed'},
  ],
};

@$core.Deprecated('Use contextPlayerOptionOverridesDescriptor instead')
const ContextPlayerOptionOverrides_ModesEntry$json = {
  '1': 'ModesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ContextPlayerOptionOverrides`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextPlayerOptionOverridesDescriptor = $convert.base64Decode(
    'ChxDb250ZXh0UGxheWVyT3B0aW9uT3ZlcnJpZGVzElwKEXNodWZmbGluZ19jb250ZXh0GAEgAS'
    'gLMi8uc3BvdGlmeS5wbGF5ZXIuZXNwZXJhbnRvLnByb3RvLk9wdGlvbmFsQm9vbGVhblIQc2h1'
    'ZmZsaW5nQ29udGV4dBJcChFyZXBlYXRpbmdfY29udGV4dBgCIAEoCzIvLnNwb3RpZnkucGxheW'
    'VyLmVzcGVyYW50by5wcm90by5PcHRpb25hbEJvb2xlYW5SEHJlcGVhdGluZ0NvbnRleHQSWAoP'
    'cmVwZWF0aW5nX3RyYWNrGAMgASgLMi8uc3BvdGlmeS5wbGF5ZXIuZXNwZXJhbnRvLnByb3RvLk'
    '9wdGlvbmFsQm9vbGVhblIOcmVwZWF0aW5nVHJhY2sSXQoFbW9kZXMYBSADKAsyRy5zcG90aWZ5'
    'LnBsYXllci5lc3BlcmFudG8ucHJvdG8uQ29udGV4dFBsYXllck9wdGlvbk92ZXJyaWRlcy5Nb2'
    'Rlc0VudHJ5UgVtb2RlcxIqCg5wbGF5YmFja19zcGVlZBgEIAEoAkgAUg1wbGF5YmFja1NwZWVk'
    'iAEBGjgKCk1vZGVzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbH'
    'VlOgI4AUIRCg9fcGxheWJhY2tfc3BlZWQ=');
