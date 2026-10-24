// This is a generated file - do not edit.
//
// Generated from es_prepare_play_options.proto.

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

@$core.Deprecated('Use preparePlayOptionsDescriptor instead')
const PreparePlayOptions$json = {
  '1': 'PreparePlayOptions',
  '2': [
    {'1': 'playback_id', '3': 1, '4': 1, '5': 12, '10': 'playbackId'},
    {
      '1': 'always_play_something',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'alwaysPlaySomething'
    },
    {
      '1': 'skip_to',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.SkipToTrack',
      '10': 'skipTo'
    },
    {
      '1': 'seek_to',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.OptionalInt64',
      '10': 'seekTo'
    },
    {'1': 'initially_paused', '3': 5, '4': 1, '5': 8, '10': 'initiallyPaused'},
    {'1': 'system_initiated', '3': 6, '4': 1, '5': 8, '10': 'systemInitiated'},
    {
      '1': 'player_options_override',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ContextPlayerOptionOverrides',
      '10': 'playerOptionsOverride'
    },
    {'1': 'suppressions', '3': 8, '4': 3, '5': 9, '10': 'suppressions'},
    {
      '1': 'prefetch_level',
      '3': 9,
      '4': 1,
      '5': 14,
      '6': '.spotify.player.esperanto.proto.PreparePlayOptions.PrefetchLevel',
      '10': 'prefetchLevel'
    },
    {
      '1': 'audio_stream',
      '3': 10,
      '4': 1,
      '5': 14,
      '6': '.spotify.player.esperanto.proto.PreparePlayOptions.AudioStream',
      '10': 'audioStream'
    },
    {'1': 'session_id', '3': 11, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'license', '3': 12, '4': 1, '5': 9, '10': 'license'},
    {
      '1': 'configuration_override',
      '3': 13,
      '4': 3,
      '5': 11,
      '6':
          '.spotify.player.esperanto.proto.PreparePlayOptions.ConfigurationOverrideEntry',
      '10': 'configurationOverride'
    },
  ],
  '3': [PreparePlayOptions_ConfigurationOverrideEntry$json],
  '4': [
    PreparePlayOptions_PrefetchLevel$json,
    PreparePlayOptions_AudioStream$json
  ],
};

@$core.Deprecated('Use preparePlayOptionsDescriptor instead')
const PreparePlayOptions_ConfigurationOverrideEntry$json = {
  '1': 'ConfigurationOverrideEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use preparePlayOptionsDescriptor instead')
const PreparePlayOptions_PrefetchLevel$json = {
  '1': 'PrefetchLevel',
  '2': [
    {'1': 'NONE', '2': 0},
    {'1': 'MEDIA', '2': 1},
  ],
};

@$core.Deprecated('Use preparePlayOptionsDescriptor instead')
const PreparePlayOptions_AudioStream$json = {
  '1': 'AudioStream',
  '2': [
    {'1': 'DEFAULT', '2': 0},
    {'1': 'ALARM', '2': 1},
  ],
};

/// Descriptor for `PreparePlayOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preparePlayOptionsDescriptor = $convert.base64Decode(
    'ChJQcmVwYXJlUGxheU9wdGlvbnMSHwoLcGxheWJhY2tfaWQYASABKAxSCnBsYXliYWNrSWQSMg'
    'oVYWx3YXlzX3BsYXlfc29tZXRoaW5nGAIgASgIUhNhbHdheXNQbGF5U29tZXRoaW5nEkQKB3Nr'
    'aXBfdG8YAyABKAsyKy5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uU2tpcFRvVHJhY2'
    'tSBnNraXBUbxJGCgdzZWVrX3RvGAQgASgLMi0uc3BvdGlmeS5wbGF5ZXIuZXNwZXJhbnRvLnBy'
    'b3RvLk9wdGlvbmFsSW50NjRSBnNlZWtUbxIpChBpbml0aWFsbHlfcGF1c2VkGAUgASgIUg9pbm'
    'l0aWFsbHlQYXVzZWQSKQoQc3lzdGVtX2luaXRpYXRlZBgGIAEoCFIPc3lzdGVtSW5pdGlhdGVk'
    'EnQKF3BsYXllcl9vcHRpb25zX292ZXJyaWRlGAcgASgLMjwuc3BvdGlmeS5wbGF5ZXIuZXNwZX'
    'JhbnRvLnByb3RvLkNvbnRleHRQbGF5ZXJPcHRpb25PdmVycmlkZXNSFXBsYXllck9wdGlvbnNP'
    'dmVycmlkZRIiCgxzdXBwcmVzc2lvbnMYCCADKAlSDHN1cHByZXNzaW9ucxJnCg5wcmVmZXRjaF'
    '9sZXZlbBgJIAEoDjJALnNwb3RpZnkucGxheWVyLmVzcGVyYW50by5wcm90by5QcmVwYXJlUGxh'
    'eU9wdGlvbnMuUHJlZmV0Y2hMZXZlbFINcHJlZmV0Y2hMZXZlbBJhCgxhdWRpb19zdHJlYW0YCi'
    'ABKA4yPi5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uUHJlcGFyZVBsYXlPcHRpb25z'
    'LkF1ZGlvU3RyZWFtUgthdWRpb1N0cmVhbRIdCgpzZXNzaW9uX2lkGAsgASgJUglzZXNzaW9uSW'
    'QSGAoHbGljZW5zZRgMIAEoCVIHbGljZW5zZRKEAQoWY29uZmlndXJhdGlvbl9vdmVycmlkZRgN'
    'IAMoCzJNLnNwb3RpZnkucGxheWVyLmVzcGVyYW50by5wcm90by5QcmVwYXJlUGxheU9wdGlvbn'
    'MuQ29uZmlndXJhdGlvbk92ZXJyaWRlRW50cnlSFWNvbmZpZ3VyYXRpb25PdmVycmlkZRpIChpD'
    'b25maWd1cmF0aW9uT3ZlcnJpZGVFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIA'
    'EoCVIFdmFsdWU6AjgBIiQKDVByZWZldGNoTGV2ZWwSCAoETk9ORRAAEgkKBU1FRElBEAEiJQoL'
    'QXVkaW9TdHJlYW0SCwoHREVGQVVMVBAAEgkKBUFMQVJNEAE=');
