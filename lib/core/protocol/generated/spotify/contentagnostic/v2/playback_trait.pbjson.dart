// This is a generated file - do not edit.
//
// Generated from spotify/contentagnostic/v2/playback_trait.proto.

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

@$core.Deprecated('Use durationDescriptor instead')
const Duration$json = {
  '1': 'Duration',
  '2': [
    {'1': 'seconds', '3': 1, '4': 1, '5': 3, '10': 'seconds'},
    {'1': 'nanos', '3': 2, '4': 1, '5': 5, '10': 'nanos'},
  ],
};

/// Descriptor for `Duration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List durationDescriptor = $convert.base64Decode(
    'CghEdXJhdGlvbhIYCgdzZWNvbmRzGAEgASgDUgdzZWNvbmRzEhQKBW5hbm9zGAIgASgFUgVuYW'
    '5vcw==');

@$core.Deprecated('Use normalizationParamsDescriptor instead')
const NormalizationParams$json = {
  '1': 'NormalizationParams',
  '2': [
    {'1': 'loudness_db', '3': 1, '4': 1, '5': 2, '10': 'loudnessDb'},
    {'1': 'true_peak_db', '3': 2, '4': 1, '5': 2, '10': 'truePeakDb'},
  ],
};

/// Descriptor for `NormalizationParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List normalizationParamsDescriptor = $convert.base64Decode(
    'ChNOb3JtYWxpemF0aW9uUGFyYW1zEh8KC2xvdWRuZXNzX2RiGAEgASgCUgpsb3VkbmVzc0RiEi'
    'AKDHRydWVfcGVha19kYhgCIAEoAlIKdHJ1ZVBlYWtEYg==');

@$core.Deprecated('Use audioFileDescriptor instead')
const AudioFile$json = {
  '1': 'AudioFile',
  '2': [
    {'1': 'file_id', '3': 1, '4': 1, '5': 12, '10': 'fileId'},
    {'1': 'average_bitrate', '3': 3, '4': 1, '5': 5, '10': 'averageBitrate'},
  ],
};

/// Descriptor for `AudioFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioFileDescriptor = $convert.base64Decode(
    'CglBdWRpb0ZpbGUSFwoHZmlsZV9pZBgBIAEoDFIGZmlsZUlkEicKD2F2ZXJhZ2VfYml0cmF0ZR'
    'gDIAEoBVIOYXZlcmFnZUJpdHJhdGU=');

@$core.Deprecated('Use audioHostedDescriptor instead')
const AudioHosted$json = {
  '1': 'AudioHosted',
  '2': [
    {
      '1': 'files',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.AudioFile',
      '10': 'files'
    },
    {'1': 'audio_id', '3': 2, '4': 1, '5': 12, '10': 'audioId'},
    {
      '1': 'file_norm',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.NormalizationParams',
      '10': 'fileNorm'
    },
    {
      '1': 'group_norm',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.NormalizationParams',
      '10': 'groupNorm'
    },
  ],
};

/// Descriptor for `AudioHosted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioHostedDescriptor = $convert.base64Decode(
    'CgtBdWRpb0hvc3RlZBI7CgVmaWxlcxgBIAMoCzIlLnNwb3RpZnkuY29udGVudGFnbm9zdGljLn'
    'YyLkF1ZGlvRmlsZVIFZmlsZXMSGQoIYXVkaW9faWQYAiABKAxSB2F1ZGlvSWQSTAoJZmlsZV9u'
    'b3JtGAMgASgLMi8uc3BvdGlmeS5jb250ZW50YWdub3N0aWMudjIuTm9ybWFsaXphdGlvblBhcm'
    'Ftc1IIZmlsZU5vcm0STgoKZ3JvdXBfbm9ybRgEIAEoCzIvLnNwb3RpZnkuY29udGVudGFnbm9z'
    'dGljLnYyLk5vcm1hbGl6YXRpb25QYXJhbXNSCWdyb3VwTm9ybQ==');

@$core.Deprecated('Use flatFileDescriptor instead')
const FlatFile$json = {
  '1': 'FlatFile',
  '2': [
    {'1': 'cdn_url', '3': 1, '4': 1, '5': 9, '10': 'cdnUrl'},
  ],
};

/// Descriptor for `FlatFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List flatFileDescriptor =
    $convert.base64Decode('CghGbGF0RmlsZRIXCgdjZG5fdXJsGAEgASgJUgZjZG5Vcmw=');

@$core.Deprecated('Use audioPassThroughDescriptor instead')
const AudioPassThrough$json = {
  '1': 'AudioPassThrough',
  '2': [
    {
      '1': 'flat_file',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.FlatFile',
      '10': 'flatFile'
    },
  ],
};

/// Descriptor for `AudioPassThrough`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioPassThroughDescriptor = $convert.base64Decode(
    'ChBBdWRpb1Bhc3NUaHJvdWdoEkEKCWZsYXRfZmlsZRgBIAEoCzIkLnNwb3RpZnkuY29udGVudG'
    'Fnbm9zdGljLnYyLkZsYXRGaWxlUghmbGF0RmlsZQ==');

@$core.Deprecated('Use playbackOffsetsDescriptor instead')
const PlaybackOffsets$json = {
  '1': 'PlaybackOffsets',
  '2': [
    {
      '1': 'start',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.Duration',
      '10': 'start'
    },
    {
      '1': 'end',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.Duration',
      '10': 'end'
    },
  ],
};

/// Descriptor for `PlaybackOffsets`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playbackOffsetsDescriptor = $convert.base64Decode(
    'Cg9QbGF5YmFja09mZnNldHMSOgoFc3RhcnQYASABKAsyJC5zcG90aWZ5LmNvbnRlbnRhZ25vc3'
    'RpYy52Mi5EdXJhdGlvblIFc3RhcnQSNgoDZW5kGAIgASgLMiQuc3BvdGlmeS5jb250ZW50YWdu'
    'b3N0aWMudjIuRHVyYXRpb25SA2VuZA==');

@$core.Deprecated('Use audioPlaybackDescriptor instead')
const AudioPlayback$json = {
  '1': 'AudioPlayback',
  '2': [
    {
      '1': 'pass_through',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.AudioPassThrough',
      '10': 'passThrough'
    },
    {
      '1': 'hosted',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.AudioHosted',
      '10': 'hosted'
    },
    {'1': 'reporting_uri', '3': 3, '4': 1, '5': 9, '10': 'reportingUri'},
    {
      '1': 'offsets',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.PlaybackOffsets',
      '10': 'offsets'
    },
  ],
};

/// Descriptor for `AudioPlayback`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioPlaybackDescriptor = $convert.base64Decode(
    'Cg1BdWRpb1BsYXliYWNrEk8KDHBhc3NfdGhyb3VnaBgBIAEoCzIsLnNwb3RpZnkuY29udGVudG'
    'Fnbm9zdGljLnYyLkF1ZGlvUGFzc1Rocm91Z2hSC3Bhc3NUaHJvdWdoEj8KBmhvc3RlZBgCIAEo'
    'CzInLnNwb3RpZnkuY29udGVudGFnbm9zdGljLnYyLkF1ZGlvSG9zdGVkUgZob3N0ZWQSIwoNcm'
    'Vwb3J0aW5nX3VyaRgDIAEoCVIMcmVwb3J0aW5nVXJpEkUKB29mZnNldHMYBCABKAsyKy5zcG90'
    'aWZ5LmNvbnRlbnRhZ25vc3RpYy52Mi5QbGF5YmFja09mZnNldHNSB29mZnNldHM=');

@$core.Deprecated('Use audioMapEntryDescriptor instead')
const AudioMapEntry$json = {
  '1': 'AudioMapEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 5, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.AudioPlayback',
      '10': 'value'
    },
  ],
};

/// Descriptor for `AudioMapEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioMapEntryDescriptor = $convert.base64Decode(
    'Cg1BdWRpb01hcEVudHJ5EhAKA2tleRgBIAEoBVIDa2V5Ej8KBXZhbHVlGAIgASgLMikuc3BvdG'
    'lmeS5jb250ZW50YWdub3N0aWMudjIuQXVkaW9QbGF5YmFja1IFdmFsdWU=');

@$core.Deprecated('Use videoHostedDescriptor instead')
const VideoHosted$json = {
  '1': 'VideoHosted',
  '2': [
    {'1': 'video_id', '3': 1, '4': 1, '5': 12, '10': 'videoId'},
  ],
};

/// Descriptor for `VideoHosted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoHostedDescriptor = $convert
    .base64Decode('CgtWaWRlb0hvc3RlZBIZCgh2aWRlb19pZBgBIAEoDFIHdmlkZW9JZA==');

@$core.Deprecated('Use videoPlaybackDescriptor instead')
const VideoPlayback$json = {
  '1': 'VideoPlayback',
  '2': [
    {
      '1': 'hosted',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.VideoHosted',
      '10': 'hosted'
    },
    {'1': 'reporting_uri', '3': 2, '4': 1, '5': 9, '10': 'reportingUri'},
    {
      '1': 'offsets',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.PlaybackOffsets',
      '10': 'offsets'
    },
  ],
};

/// Descriptor for `VideoPlayback`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoPlaybackDescriptor = $convert.base64Decode(
    'Cg1WaWRlb1BsYXliYWNrEj8KBmhvc3RlZBgBIAEoCzInLnNwb3RpZnkuY29udGVudGFnbm9zdG'
    'ljLnYyLlZpZGVvSG9zdGVkUgZob3N0ZWQSIwoNcmVwb3J0aW5nX3VyaRgCIAEoCVIMcmVwb3J0'
    'aW5nVXJpEkUKB29mZnNldHMYAyABKAsyKy5zcG90aWZ5LmNvbnRlbnRhZ25vc3RpYy52Mi5QbG'
    'F5YmFja09mZnNldHNSB29mZnNldHM=');

@$core.Deprecated('Use videoMapEntryDescriptor instead')
const VideoMapEntry$json = {
  '1': 'VideoMapEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 5, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.VideoPlayback',
      '10': 'value'
    },
  ],
};

/// Descriptor for `VideoMapEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoMapEntryDescriptor = $convert.base64Decode(
    'Cg1WaWRlb01hcEVudHJ5EhAKA2tleRgBIAEoBVIDa2V5Ej8KBXZhbHVlGAIgASgLMikuc3BvdG'
    'lmeS5jb250ZW50YWdub3N0aWMudjIuVmlkZW9QbGF5YmFja1IFdmFsdWU=');

@$core.Deprecated('Use playbackTraitDescriptor instead')
const PlaybackTrait$json = {
  '1': 'PlaybackTrait',
  '2': [
    {
      '1': 'audio',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.AudioMapEntry',
      '10': 'audio'
    },
    {
      '1': 'video',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.VideoMapEntry',
      '10': 'video'
    },
  ],
};

/// Descriptor for `PlaybackTrait`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playbackTraitDescriptor = $convert.base64Decode(
    'Cg1QbGF5YmFja1RyYWl0Ej8KBWF1ZGlvGAEgAygLMikuc3BvdGlmeS5jb250ZW50YWdub3N0aW'
    'MudjIuQXVkaW9NYXBFbnRyeVIFYXVkaW8SPwoFdmlkZW8YAiADKAsyKS5zcG90aWZ5LmNvbnRl'
    'bnRhZ25vc3RpYy52Mi5WaWRlb01hcEVudHJ5UgV2aWRlbw==');
