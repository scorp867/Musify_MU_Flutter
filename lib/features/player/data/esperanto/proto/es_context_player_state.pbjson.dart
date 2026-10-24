// This is a generated file - do not edit.
//
// Generated from es_context_player_state.proto.

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

@$core.Deprecated('Use contextIndexDescriptor instead')
const ContextIndex$json = {
  '1': 'ContextIndex',
  '2': [
    {'1': 'page', '3': 1, '4': 1, '5': 4, '10': 'page'},
    {'1': 'track', '3': 2, '4': 1, '5': 4, '10': 'track'},
  ],
};

/// Descriptor for `ContextIndex`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextIndexDescriptor = $convert.base64Decode(
    'CgxDb250ZXh0SW5kZXgSEgoEcGFnZRgBIAEoBFIEcGFnZRIUCgV0cmFjaxgCIAEoBFIFdHJhY2'
    's=');

@$core.Deprecated('Use playbackQualityDescriptor instead')
const PlaybackQuality$json = {
  '1': 'PlaybackQuality',
  '2': [
    {
      '1': 'bitrate_level',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.spotify.player.esperanto.proto.PlaybackQuality.BitrateLevel',
      '10': 'bitrateLevel'
    },
    {
      '1': 'strategy',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.spotify.player.esperanto.proto.PlaybackQuality.BitrateStrategy',
      '10': 'strategy'
    },
    {
      '1': 'target_bitrate_level',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.spotify.player.esperanto.proto.PlaybackQuality.BitrateLevel',
      '10': 'targetBitrateLevel'
    },
    {
      '1': 'target_bitrate_available',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'targetBitrateAvailable'
    },
    {
      '1': 'hifi_status',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.spotify.player.esperanto.proto.PlaybackQuality.HiFiStatus',
      '10': 'hifiStatus'
    },
  ],
  '4': [
    PlaybackQuality_BitrateLevel$json,
    PlaybackQuality_BitrateStrategy$json,
    PlaybackQuality_HiFiStatus$json
  ],
};

@$core.Deprecated('Use playbackQualityDescriptor instead')
const PlaybackQuality_BitrateLevel$json = {
  '1': 'BitrateLevel',
  '2': [
    {'1': 'UNKNOWN', '2': 0},
    {'1': 'LOW', '2': 1},
    {'1': 'NORMAL', '2': 2},
    {'1': 'HIGH', '2': 3},
    {'1': 'VERY_HIGH', '2': 4},
    {'1': 'HIFI', '2': 5},
    {'1': 'HIFI24', '2': 6},
  ],
};

@$core.Deprecated('Use playbackQualityDescriptor instead')
const PlaybackQuality_BitrateStrategy$json = {
  '1': 'BitrateStrategy',
  '2': [
    {'1': 'UNKNOWN_STRATEGY', '2': 0},
    {'1': 'BEST_MATCHING', '2': 1},
    {'1': 'BACKEND_ADVISED', '2': 2},
    {'1': 'OFFLINED_FILE', '2': 3},
    {'1': 'CACHED_FILE', '2': 4},
    {'1': 'LOCAL_FILE', '2': 5},
  ],
};

@$core.Deprecated('Use playbackQualityDescriptor instead')
const PlaybackQuality_HiFiStatus$json = {
  '1': 'HiFiStatus',
  '2': [
    {'1': 'NONE', '2': 0},
    {'1': 'OFF', '2': 1},
    {'1': 'ON', '2': 2},
  ],
};

/// Descriptor for `PlaybackQuality`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playbackQualityDescriptor = $convert.base64Decode(
    'Cg9QbGF5YmFja1F1YWxpdHkSYQoNYml0cmF0ZV9sZXZlbBgBIAEoDjI8LnNwb3RpZnkucGxheW'
    'VyLmVzcGVyYW50by5wcm90by5QbGF5YmFja1F1YWxpdHkuQml0cmF0ZUxldmVsUgxiaXRyYXRl'
    'TGV2ZWwSWwoIc3RyYXRlZ3kYAiABKA4yPy5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG'
    '8uUGxheWJhY2tRdWFsaXR5LkJpdHJhdGVTdHJhdGVneVIIc3RyYXRlZ3kSbgoUdGFyZ2V0X2Jp'
    'dHJhdGVfbGV2ZWwYAyABKA4yPC5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uUGxheW'
    'JhY2tRdWFsaXR5LkJpdHJhdGVMZXZlbFISdGFyZ2V0Qml0cmF0ZUxldmVsEjgKGHRhcmdldF9i'
    'aXRyYXRlX2F2YWlsYWJsZRgEIAEoCFIWdGFyZ2V0Qml0cmF0ZUF2YWlsYWJsZRJbCgtoaWZpX3'
    'N0YXR1cxgFIAEoDjI6LnNwb3RpZnkucGxheWVyLmVzcGVyYW50by5wcm90by5QbGF5YmFja1F1'
    'YWxpdHkuSGlGaVN0YXR1c1IKaGlmaVN0YXR1cyJfCgxCaXRyYXRlTGV2ZWwSCwoHVU5LTk9XTh'
    'AAEgcKA0xPVxABEgoKBk5PUk1BTBACEggKBEhJR0gQAxINCglWRVJZX0hJR0gQBBIICgRISUZJ'
    'EAUSCgoGSElGSTI0EAYigwEKD0JpdHJhdGVTdHJhdGVneRIUChBVTktOT1dOX1NUUkFURUdZEA'
    'ASEQoNQkVTVF9NQVRDSElORxABEhMKD0JBQ0tFTkRfQURWSVNFRBACEhEKDU9GRkxJTkVEX0ZJ'
    'TEUQAxIPCgtDQUNIRURfRklMRRAEEg4KCkxPQ0FMX0ZJTEUQBSInCgpIaUZpU3RhdHVzEggKBE'
    '5PTkUQABIHCgNPRkYQARIGCgJPThAC');

@$core.Deprecated('Use contextPlayerStateDescriptor instead')
const ContextPlayerState$json = {
  '1': 'ContextPlayerState',
  '2': [
    {'1': 'timestamp', '3': 1, '4': 1, '5': 4, '10': 'timestamp'},
    {'1': 'context_uri', '3': 2, '4': 1, '5': 9, '10': 'contextUri'},
    {'1': 'context_url', '3': 3, '4': 1, '5': 9, '10': 'contextUrl'},
    {
      '1': 'context_restrictions',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.Restrictions',
      '10': 'contextRestrictions'
    },
    {
      '1': 'play_origin',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.PlayOrigin',
      '10': 'playOrigin'
    },
    {
      '1': 'index',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ContextIndex',
      '10': 'index'
    },
    {
      '1': 'track',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ProvidedTrack',
      '10': 'track'
    },
    {'1': 'playback_id', '3': 8, '4': 1, '5': 12, '10': 'playbackId'},
    {
      '1': 'playback_quality',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.PlaybackQuality',
      '10': 'playbackQuality'
    },
    {
      '1': 'playback_speed',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.OptionalDouble',
      '10': 'playbackSpeed'
    },
    {
      '1': 'position_as_of_timestamp',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.OptionalInt64',
      '10': 'positionAsOfTimestamp'
    },
    {
      '1': 'duration',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.OptionalInt64',
      '10': 'duration'
    },
    {'1': 'is_playing', '3': 13, '4': 1, '5': 8, '10': 'isPlaying'},
    {'1': 'is_paused', '3': 14, '4': 1, '5': 8, '10': 'isPaused'},
    {'1': 'is_buffering', '3': 15, '4': 1, '5': 8, '10': 'isBuffering'},
    {
      '1': 'is_system_initiated',
      '3': 16,
      '4': 1,
      '5': 8,
      '10': 'isSystemInitiated'
    },
    {
      '1': 'options',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ContextPlayerOptions',
      '10': 'options'
    },
    {
      '1': 'restrictions',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.Restrictions',
      '10': 'restrictions'
    },
    {'1': 'suppressions', '3': 19, '4': 3, '5': 9, '10': 'suppressions'},
    {
      '1': 'prev_tracks',
      '3': 20,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ProvidedTrack',
      '10': 'prevTracks'
    },
    {
      '1': 'next_tracks',
      '3': 21,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ProvidedTrack',
      '10': 'nextTracks'
    },
    {
      '1': 'context_metadata',
      '3': 22,
      '4': 3,
      '5': 11,
      '6':
          '.spotify.player.esperanto.proto.ContextPlayerState.ContextMetadataEntry',
      '10': 'contextMetadata'
    },
    {
      '1': 'page_metadata',
      '3': 23,
      '4': 3,
      '5': 11,
      '6':
          '.spotify.player.esperanto.proto.ContextPlayerState.PageMetadataEntry',
      '10': 'pageMetadata'
    },
    {'1': 'session_id', '3': 24, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'queue_revision', '3': 25, '4': 1, '5': 4, '10': 'queueRevision'},
    {
      '1': 'audio_stream',
      '3': 26,
      '4': 1,
      '5': 14,
      '6': '.spotify.player.esperanto.proto.PreparePlayOptions.AudioStream',
      '10': 'audioStream'
    },
    {'1': 'signals', '3': 27, '4': 3, '5': 9, '10': 'signals'},
    {
      '1': 'session_command_id',
      '3': 28,
      '4': 1,
      '5': 9,
      '10': 'sessionCommandId'
    },
  ],
  '3': [
    ContextPlayerState_ContextMetadataEntry$json,
    ContextPlayerState_PageMetadataEntry$json
  ],
};

@$core.Deprecated('Use contextPlayerStateDescriptor instead')
const ContextPlayerState_ContextMetadataEntry$json = {
  '1': 'ContextMetadataEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use contextPlayerStateDescriptor instead')
const ContextPlayerState_PageMetadataEntry$json = {
  '1': 'PageMetadataEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ContextPlayerState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextPlayerStateDescriptor = $convert.base64Decode(
    'ChJDb250ZXh0UGxheWVyU3RhdGUSHAoJdGltZXN0YW1wGAEgASgEUgl0aW1lc3RhbXASHwoLY2'
    '9udGV4dF91cmkYAiABKAlSCmNvbnRleHRVcmkSHwoLY29udGV4dF91cmwYAyABKAlSCmNvbnRl'
    'eHRVcmwSXwoUY29udGV4dF9yZXN0cmljdGlvbnMYBCABKAsyLC5zcG90aWZ5LnBsYXllci5lc3'
    'BlcmFudG8ucHJvdG8uUmVzdHJpY3Rpb25zUhNjb250ZXh0UmVzdHJpY3Rpb25zEksKC3BsYXlf'
    'b3JpZ2luGAUgASgLMiouc3BvdGlmeS5wbGF5ZXIuZXNwZXJhbnRvLnByb3RvLlBsYXlPcmlnaW'
    '5SCnBsYXlPcmlnaW4SQgoFaW5kZXgYBiABKAsyLC5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8u'
    'cHJvdG8uQ29udGV4dEluZGV4UgVpbmRleBJDCgV0cmFjaxgHIAEoCzItLnNwb3RpZnkucGxheW'
    'VyLmVzcGVyYW50by5wcm90by5Qcm92aWRlZFRyYWNrUgV0cmFjaxIfCgtwbGF5YmFja19pZBgI'
    'IAEoDFIKcGxheWJhY2tJZBJaChBwbGF5YmFja19xdWFsaXR5GAkgASgLMi8uc3BvdGlmeS5wbG'
    'F5ZXIuZXNwZXJhbnRvLnByb3RvLlBsYXliYWNrUXVhbGl0eVIPcGxheWJhY2tRdWFsaXR5ElUK'
    'DnBsYXliYWNrX3NwZWVkGAogASgLMi4uc3BvdGlmeS5wbGF5ZXIuZXNwZXJhbnRvLnByb3RvLk'
    '9wdGlvbmFsRG91YmxlUg1wbGF5YmFja1NwZWVkEmYKGHBvc2l0aW9uX2FzX29mX3RpbWVzdGFt'
    'cBgLIAEoCzItLnNwb3RpZnkucGxheWVyLmVzcGVyYW50by5wcm90by5PcHRpb25hbEludDY0Uh'
    'Vwb3NpdGlvbkFzT2ZUaW1lc3RhbXASSQoIZHVyYXRpb24YDCABKAsyLS5zcG90aWZ5LnBsYXll'
    'ci5lc3BlcmFudG8ucHJvdG8uT3B0aW9uYWxJbnQ2NFIIZHVyYXRpb24SHQoKaXNfcGxheWluZx'
    'gNIAEoCFIJaXNQbGF5aW5nEhsKCWlzX3BhdXNlZBgOIAEoCFIIaXNQYXVzZWQSIQoMaXNfYnVm'
    'ZmVyaW5nGA8gASgIUgtpc0J1ZmZlcmluZxIuChNpc19zeXN0ZW1faW5pdGlhdGVkGBAgASgIUh'
    'Fpc1N5c3RlbUluaXRpYXRlZBJOCgdvcHRpb25zGBEgASgLMjQuc3BvdGlmeS5wbGF5ZXIuZXNw'
    'ZXJhbnRvLnByb3RvLkNvbnRleHRQbGF5ZXJPcHRpb25zUgdvcHRpb25zElAKDHJlc3RyaWN0aW'
    '9ucxgSIAEoCzIsLnNwb3RpZnkucGxheWVyLmVzcGVyYW50by5wcm90by5SZXN0cmljdGlvbnNS'
    'DHJlc3RyaWN0aW9ucxIiCgxzdXBwcmVzc2lvbnMYEyADKAlSDHN1cHByZXNzaW9ucxJOCgtwcm'
    'V2X3RyYWNrcxgUIAMoCzItLnNwb3RpZnkucGxheWVyLmVzcGVyYW50by5wcm90by5Qcm92aWRl'
    'ZFRyYWNrUgpwcmV2VHJhY2tzEk4KC25leHRfdHJhY2tzGBUgAygLMi0uc3BvdGlmeS5wbGF5ZX'
    'IuZXNwZXJhbnRvLnByb3RvLlByb3ZpZGVkVHJhY2tSCm5leHRUcmFja3MScgoQY29udGV4dF9t'
    'ZXRhZGF0YRgWIAMoCzJHLnNwb3RpZnkucGxheWVyLmVzcGVyYW50by5wcm90by5Db250ZXh0UG'
    'xheWVyU3RhdGUuQ29udGV4dE1ldGFkYXRhRW50cnlSD2NvbnRleHRNZXRhZGF0YRJpCg1wYWdl'
    'X21ldGFkYXRhGBcgAygLMkQuc3BvdGlmeS5wbGF5ZXIuZXNwZXJhbnRvLnByb3RvLkNvbnRleH'
    'RQbGF5ZXJTdGF0ZS5QYWdlTWV0YWRhdGFFbnRyeVIMcGFnZU1ldGFkYXRhEh0KCnNlc3Npb25f'
    'aWQYGCABKAlSCXNlc3Npb25JZBIlCg5xdWV1ZV9yZXZpc2lvbhgZIAEoBFINcXVldWVSZXZpc2'
    'lvbhJhCgxhdWRpb19zdHJlYW0YGiABKA4yPi5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJv'
    'dG8uUHJlcGFyZVBsYXlPcHRpb25zLkF1ZGlvU3RyZWFtUgthdWRpb1N0cmVhbRIYCgdzaWduYW'
    'xzGBsgAygJUgdzaWduYWxzEiwKEnNlc3Npb25fY29tbWFuZF9pZBgcIAEoCVIQc2Vzc2lvbkNv'
    'bW1hbmRJZBpCChRDb250ZXh0TWV0YWRhdGFFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YW'
    'x1ZRgCIAEoCVIFdmFsdWU6AjgBGj8KEVBhZ2VNZXRhZGF0YUVudHJ5EhAKA2tleRgBIAEoCVID'
    'a2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE=');
