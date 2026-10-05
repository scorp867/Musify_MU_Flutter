// This is a generated file - do not edit.
//
// Generated from spotify/contentagnostic/v2/visual_types.proto.

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

@$core.Deprecated('Use maskDescriptor instead')
const Mask$json = {
  '1': 'Mask',
  '2': [
    {'1': 'MASK_UNSPECIFIED', '2': 0},
    {'1': 'MASK_CIRCULAR', '2': 1},
  ],
};

/// Descriptor for `Mask`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List maskDescriptor = $convert.base64Decode(
    'CgRNYXNrEhQKEE1BU0tfVU5TUEVDSUZJRUQQABIRCg1NQVNLX0NJUkNVTEFSEAE=');

@$core.Deprecated('Use imageSizeDescriptor instead')
const ImageSize$json = {
  '1': 'ImageSize',
  '2': [
    {'1': 'IMAGE_SIZE_UNSPECIFIED', '2': 0},
    {'1': 'IMAGE_SIZE_SMALL', '2': 1},
    {'1': 'IMAGE_SIZE_DEFAULT', '2': 2},
    {'1': 'IMAGE_SIZE_LARGE', '2': 3},
    {'1': 'IMAGE_SIZE_XLARGE', '2': 4},
    {'1': 'IMAGE_SIZE_XXLARGE', '2': 5},
  ],
};

/// Descriptor for `ImageSize`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List imageSizeDescriptor = $convert.base64Decode(
    'CglJbWFnZVNpemUSGgoWSU1BR0VfU0laRV9VTlNQRUNJRklFRBAAEhQKEElNQUdFX1NJWkVfU0'
    '1BTEwQARIWChJJTUFHRV9TSVpFX0RFRkFVTFQQAhIUChBJTUFHRV9TSVpFX0xBUkdFEAMSFQoR'
    'SU1BR0VfU0laRV9YTEFSR0UQBBIWChJJTUFHRV9TSVpFX1hYTEFSR0UQBQ==');

@$core.Deprecated('Use imageDescriptor instead')
const Image$json = {
  '1': 'Image',
  '2': [
    {
      '1': 'instances',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.ImageInstance',
      '10': 'instances'
    },
    {
      '1': 'extracted_color_set',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.ColorSetContrastOptions',
      '10': 'extractedColorSet'
    },
    {
      '1': 'mask',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.spotify.contentagnostic.v2.Mask',
      '10': 'mask'
    },
  ],
};

/// Descriptor for `Image`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imageDescriptor = $convert.base64Decode(
    'CgVJbWFnZRJHCglpbnN0YW5jZXMYASADKAsyKS5zcG90aWZ5LmNvbnRlbnRhZ25vc3RpYy52Mi'
    '5JbWFnZUluc3RhbmNlUglpbnN0YW5jZXMSYwoTZXh0cmFjdGVkX2NvbG9yX3NldBgCIAEoCzIz'
    'LnNwb3RpZnkuY29udGVudGFnbm9zdGljLnYyLkNvbG9yU2V0Q29udHJhc3RPcHRpb25zUhFleH'
    'RyYWN0ZWRDb2xvclNldBI0CgRtYXNrGAMgASgOMiAuc3BvdGlmeS5jb250ZW50YWdub3N0aWMu'
    'djIuTWFza1IEbWFzaw==');

@$core.Deprecated('Use imageInstanceDescriptor instead')
const ImageInstance$json = {
  '1': 'ImageInstance',
  '2': [
    {
      '1': 'flat_file',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.FlatFile',
      '10': 'flatFile'
    },
    {
      '1': 'size',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.spotify.contentagnostic.v2.ImageSize',
      '10': 'size'
    },
  ],
};

/// Descriptor for `ImageInstance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imageInstanceDescriptor = $convert.base64Decode(
    'Cg1JbWFnZUluc3RhbmNlEkEKCWZsYXRfZmlsZRgBIAEoCzIkLnNwb3RpZnkuY29udGVudGFnbm'
    '9zdGljLnYyLkZsYXRGaWxlUghmbGF0RmlsZRI5CgRzaXplGAIgASgOMiUuc3BvdGlmeS5jb250'
    'ZW50YWdub3N0aWMudjIuSW1hZ2VTaXplUgRzaXpl');

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

@$core.Deprecated('Use videoDescriptor instead')
const Video$json = {
  '1': 'Video',
  '2': [
    {
      '1': 'asset',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.VideoAsset',
      '10': 'asset'
    },
    {
      '1': 'fallback_image',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.Image',
      '10': 'fallbackImage'
    },
    {
      '1': 'fallback_audio',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.Audio',
      '10': 'fallbackAudio'
    },
    {
      '1': 'transcript',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.Transcript',
      '10': 'transcript'
    },
  ],
};

/// Descriptor for `Video`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoDescriptor = $convert.base64Decode(
    'CgVWaWRlbxI8CgVhc3NldBgBIAEoCzImLnNwb3RpZnkuY29udGVudGFnbm9zdGljLnYyLlZpZG'
    'VvQXNzZXRSBWFzc2V0EkgKDmZhbGxiYWNrX2ltYWdlGAIgASgLMiEuc3BvdGlmeS5jb250ZW50'
    'YWdub3N0aWMudjIuSW1hZ2VSDWZhbGxiYWNrSW1hZ2USSAoOZmFsbGJhY2tfYXVkaW8YAyABKA'
    'syIS5zcG90aWZ5LmNvbnRlbnRhZ25vc3RpYy52Mi5BdWRpb1INZmFsbGJhY2tBdWRpbxJGCgp0'
    'cmFuc2NyaXB0GAQgASgLMiYuc3BvdGlmeS5jb250ZW50YWdub3N0aWMudjIuVHJhbnNjcmlwdF'
    'IKdHJhbnNjcmlwdA==');

@$core.Deprecated('Use videoAssetDescriptor instead')
const VideoAsset$json = {
  '1': 'VideoAsset',
  '2': [
    {
      '1': 'flat_file',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.FlatFile',
      '9': 0,
      '10': 'flatFile'
    },
    {
      '1': 'hls',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.HLSVideo',
      '9': 0,
      '10': 'hls'
    },
  ],
  '8': [
    {'1': 'video_type'},
  ],
};

/// Descriptor for `VideoAsset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoAssetDescriptor = $convert.base64Decode(
    'CgpWaWRlb0Fzc2V0EkMKCWZsYXRfZmlsZRgBIAEoCzIkLnNwb3RpZnkuY29udGVudGFnbm9zdG'
    'ljLnYyLkZsYXRGaWxlSABSCGZsYXRGaWxlEjgKA2hscxgCIAEoCzIkLnNwb3RpZnkuY29udGVu'
    'dGFnbm9zdGljLnYyLkhMU1ZpZGVvSABSA2hsc0IMCgp2aWRlb190eXBl');

@$core.Deprecated('Use hLSVideoDescriptor instead')
const HLSVideo$json = {
  '1': 'HLSVideo',
  '2': [
    {'1': 'manifest_id', '3': 1, '4': 1, '5': 9, '10': 'manifestId'},
  ],
};

/// Descriptor for `HLSVideo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hLSVideoDescriptor = $convert.base64Decode(
    'CghITFNWaWRlbxIfCgttYW5pZmVzdF9pZBgBIAEoCVIKbWFuaWZlc3RJZA==');

@$core.Deprecated('Use audioDescriptor instead')
const Audio$json = {
  '1': 'Audio',
  '2': [
    {
      '1': 'transcript',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.Transcript',
      '10': 'transcript'
    },
    {
      '1': 'asset',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.AudioAsset',
      '10': 'asset'
    },
  ],
};

/// Descriptor for `Audio`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioDescriptor = $convert.base64Decode(
    'CgVBdWRpbxJGCgp0cmFuc2NyaXB0GAIgASgLMiYuc3BvdGlmeS5jb250ZW50YWdub3N0aWMudj'
    'IuVHJhbnNjcmlwdFIKdHJhbnNjcmlwdBI8CgVhc3NldBgDIAEoCzImLnNwb3RpZnkuY29udGVu'
    'dGFnbm9zdGljLnYyLkF1ZGlvQXNzZXRSBWFzc2V0');

@$core.Deprecated('Use audioAssetDescriptor instead')
const AudioAsset$json = {
  '1': 'AudioAsset',
  '2': [
    {
      '1': 'flat_file',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.FlatFile',
      '9': 0,
      '10': 'flatFile'
    },
  ],
  '8': [
    {'1': 'audio_type'},
  ],
};

/// Descriptor for `AudioAsset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioAssetDescriptor = $convert.base64Decode(
    'CgpBdWRpb0Fzc2V0EkMKCWZsYXRfZmlsZRgBIAEoCzIkLnNwb3RpZnkuY29udGVudGFnbm9zdG'
    'ljLnYyLkZsYXRGaWxlSABSCGZsYXRGaWxlQgwKCmF1ZGlvX3R5cGU=');

@$core.Deprecated('Use transcriptDescriptor instead')
const Transcript$json = {
  '1': 'Transcript',
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

/// Descriptor for `Transcript`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transcriptDescriptor = $convert.base64Decode(
    'CgpUcmFuc2NyaXB0EkEKCWZsYXRfZmlsZRgBIAEoCzIkLnNwb3RpZnkuY29udGVudGFnbm9zdG'
    'ljLnYyLkZsYXRGaWxlUghmbGF0RmlsZQ==');

@$core.Deprecated('Use colorSetContrastOptionsDescriptor instead')
const ColorSetContrastOptions$json = {
  '1': 'ColorSetContrastOptions',
  '2': [
    {
      '1': 'min_contrast',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.ColorSet',
      '10': 'minContrast'
    },
    {
      '1': 'high_contrast',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.ColorSet',
      '10': 'highContrast'
    },
    {
      '1': 'higher_contrast',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.ColorSet',
      '10': 'higherContrast'
    },
    {
      '1': 'encore_base_set_text_color',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.RgbaColor',
      '10': 'encoreBaseSetTextColor'
    },
  ],
};

/// Descriptor for `ColorSetContrastOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colorSetContrastOptionsDescriptor = $convert.base64Decode(
    'ChdDb2xvclNldENvbnRyYXN0T3B0aW9ucxJHCgxtaW5fY29udHJhc3QYASABKAsyJC5zcG90aW'
    'Z5LmNvbnRlbnRhZ25vc3RpYy52Mi5Db2xvclNldFILbWluQ29udHJhc3QSSQoNaGlnaF9jb250'
    'cmFzdBgCIAEoCzIkLnNwb3RpZnkuY29udGVudGFnbm9zdGljLnYyLkNvbG9yU2V0UgxoaWdoQ2'
    '9udHJhc3QSTQoPaGlnaGVyX2NvbnRyYXN0GAMgASgLMiQuc3BvdGlmeS5jb250ZW50YWdub3N0'
    'aWMudjIuQ29sb3JTZXRSDmhpZ2hlckNvbnRyYXN0EmEKGmVuY29yZV9iYXNlX3NldF90ZXh0X2'
    'NvbG9yGAQgASgLMiUuc3BvdGlmeS5jb250ZW50YWdub3N0aWMudjIuUmdiYUNvbG9yUhZlbmNv'
    'cmVCYXNlU2V0VGV4dENvbG9y');

@$core.Deprecated('Use colorSetDescriptor instead')
const ColorSet$json = {
  '1': 'ColorSet',
  '2': [
    {
      '1': 'background_base',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.RgbaColor',
      '10': 'backgroundBase'
    },
    {
      '1': 'background_tinted_base',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.RgbaColor',
      '10': 'backgroundTintedBase'
    },
    {
      '1': 'text_base',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.RgbaColor',
      '10': 'textBase'
    },
    {
      '1': 'text_subdued',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.RgbaColor',
      '10': 'textSubdued'
    },
    {
      '1': 'text_bright_accent',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.RgbaColor',
      '10': 'textBrightAccent'
    },
  ],
};

/// Descriptor for `ColorSet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List colorSetDescriptor = $convert.base64Decode(
    'CghDb2xvclNldBJOCg9iYWNrZ3JvdW5kX2Jhc2UYASABKAsyJS5zcG90aWZ5LmNvbnRlbnRhZ2'
    '5vc3RpYy52Mi5SZ2JhQ29sb3JSDmJhY2tncm91bmRCYXNlElsKFmJhY2tncm91bmRfdGludGVk'
    'X2Jhc2UYAiABKAsyJS5zcG90aWZ5LmNvbnRlbnRhZ25vc3RpYy52Mi5SZ2JhQ29sb3JSFGJhY2'
    'tncm91bmRUaW50ZWRCYXNlEkIKCXRleHRfYmFzZRgDIAEoCzIlLnNwb3RpZnkuY29udGVudGFn'
    'bm9zdGljLnYyLlJnYmFDb2xvclIIdGV4dEJhc2USSAoMdGV4dF9zdWJkdWVkGAQgASgLMiUuc3'
    'BvdGlmeS5jb250ZW50YWdub3N0aWMudjIuUmdiYUNvbG9yUgt0ZXh0U3ViZHVlZBJTChJ0ZXh0'
    'X2JyaWdodF9hY2NlbnQYBSABKAsyJS5zcG90aWZ5LmNvbnRlbnRhZ25vc3RpYy52Mi5SZ2JhQ2'
    '9sb3JSEHRleHRCcmlnaHRBY2NlbnQ=');

@$core.Deprecated('Use rgbaColorDescriptor instead')
const RgbaColor$json = {
  '1': 'RgbaColor',
  '2': [
    {'1': 'r', '3': 1, '4': 1, '5': 5, '10': 'r'},
    {'1': 'g', '3': 2, '4': 1, '5': 5, '10': 'g'},
    {'1': 'b', '3': 3, '4': 1, '5': 5, '10': 'b'},
    {'1': 'a', '3': 4, '4': 1, '5': 5, '10': 'a'},
  ],
};

/// Descriptor for `RgbaColor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rgbaColorDescriptor = $convert.base64Decode(
    'CglSZ2JhQ29sb3ISDAoBchgBIAEoBVIBchIMCgFnGAIgASgFUgFnEgwKAWIYAyABKAVSAWISDA'
    'oBYRgEIAEoBVIBYQ==');
