// This is a generated file - do not edit.
//
// Generated from spotify/traits/preview_card_trait.proto.

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

@$core.Deprecated('Use previewRestrictionDescriptor instead')
const PreviewRestriction$json = {
  '1': 'PreviewRestriction',
  '2': [
    {'1': 'PREVIEW_RESTRICTION_NONE', '2': 0},
    {'1': 'PREVIEW_IS_EXPLICIT', '2': 1},
    {'1': 'PREVIEW_IS_19_PLUS', '2': 2},
  ],
};

/// Descriptor for `PreviewRestriction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List previewRestrictionDescriptor = $convert.base64Decode(
    'ChJQcmV2aWV3UmVzdHJpY3Rpb24SHAoYUFJFVklFV19SRVNUUklDVElPTl9OT05FEAASFwoTUF'
    'JFVklFV19JU19FWFBMSUNJVBABEhYKElBSRVZJRVdfSVNfMTlfUExVUxAC');

@$core.Deprecated('Use subtitleSourceDescriptor instead')
const SubtitleSource$json = {
  '1': 'SubtitleSource',
  '2': [
    {'1': 'SUBTITLE_SOURCE_UNKNOWN', '2': 0},
    {'1': 'SUBTITLE_SOURCE_GENERATED_METADATA', '2': 1},
    {'1': 'SUBTITLE_SOURCE_OPERATOR_AUTHORED', '2': 2},
  ],
};

/// Descriptor for `SubtitleSource`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List subtitleSourceDescriptor = $convert.base64Decode(
    'Cg5TdWJ0aXRsZVNvdXJjZRIbChdTVUJUSVRMRV9TT1VSQ0VfVU5LTk9XThAAEiYKIlNVQlRJVE'
    'xFX1NPVVJDRV9HRU5FUkFURURfTUVUQURBVEEQARIlCiFTVUJUSVRMRV9TT1VSQ0VfT1BFUkFU'
    'T1JfQVVUSE9SRUQQAg==');

@$core.Deprecated('Use previewCardTraitDescriptor instead')
const PreviewCardTrait$json = {
  '1': 'PreviewCardTrait',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'content_type_name', '3': 2, '4': 1, '5': 9, '10': 'contentTypeName'},
    {'1': 'description', '3': 4, '4': 1, '5': 9, '10': 'description'},
    {'1': 'entity_uri', '3': 5, '4': 1, '5': 9, '10': 'entityUri'},
    {'1': 'navigate_uri', '3': 6, '4': 1, '5': 9, '10': 'navigateUri'},
    {'1': 'like_uri', '3': 7, '4': 1, '5': 9, '10': 'likeUri'},
    {'1': 'entity_image_url', '3': 8, '4': 1, '5': 9, '10': 'entityImageUrl'},
    {
      '1': 'duration',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Duration',
      '10': 'duration'
    },
    {
      '1': 'publish_time',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'publishTime'
    },
    {
      '1': 'background_color_hex',
      '3': 11,
      '4': 1,
      '5': 9,
      '10': 'backgroundColorHex'
    },
    {
      '1': 'waveform_color_hex',
      '3': 12,
      '4': 1,
      '5': 9,
      '10': 'waveformColorHex'
    },
    {
      '1': 'preview_restriction',
      '3': 13,
      '4': 1,
      '5': 14,
      '6':
          '.spotify.extendedmetadata.extensions.previewcardtrait.PreviewRestriction',
      '10': 'previewRestriction'
    },
    {
      '1': 'labels',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.spotify.extendedmetadata.extensions.previewcardtrait.Labels',
      '10': 'labels'
    },
    {
      '1': 'descriptor_tags',
      '3': 15,
      '4': 3,
      '5': 11,
      '6':
          '.spotify.extendedmetadata.extensions.previewcardtrait.DescriptorTag',
      '10': 'descriptorTags'
    },
    {'1': 'number_of_items', '3': 16, '4': 1, '5': 5, '10': 'numberOfItems'},
    {
      '1': 'content_parent',
      '3': 17,
      '4': 1,
      '5': 11,
      '6':
          '.spotify.extendedmetadata.extensions.previewcardtrait.ContentParent',
      '10': 'contentParent'
    },
    {
      '1': 'subtitle_source',
      '3': 18,
      '4': 1,
      '5': 14,
      '6':
          '.spotify.extendedmetadata.extensions.previewcardtrait.SubtitleSource',
      '10': 'subtitleSource'
    },
  ],
};

/// Descriptor for `PreviewCardTrait`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewCardTraitDescriptor = $convert.base64Decode(
    'ChBQcmV2aWV3Q2FyZFRyYWl0EhQKBXRpdGxlGAEgASgJUgV0aXRsZRIqChFjb250ZW50X3R5cG'
    'VfbmFtZRgCIAEoCVIPY29udGVudFR5cGVOYW1lEiAKC2Rlc2NyaXB0aW9uGAQgASgJUgtkZXNj'
    'cmlwdGlvbhIdCgplbnRpdHlfdXJpGAUgASgJUgllbnRpdHlVcmkSIQoMbmF2aWdhdGVfdXJpGA'
    'YgASgJUgtuYXZpZ2F0ZVVyaRIZCghsaWtlX3VyaRgHIAEoCVIHbGlrZVVyaRIoChBlbnRpdHlf'
    'aW1hZ2VfdXJsGAggASgJUg5lbnRpdHlJbWFnZVVybBI1CghkdXJhdGlvbhgJIAEoCzIZLmdvb2'
    'dsZS5wcm90b2J1Zi5EdXJhdGlvblIIZHVyYXRpb24SPQoMcHVibGlzaF90aW1lGAogASgLMhou'
    'Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFILcHVibGlzaFRpbWUSMAoUYmFja2dyb3VuZF9jb2'
    'xvcl9oZXgYCyABKAlSEmJhY2tncm91bmRDb2xvckhleBIsChJ3YXZlZm9ybV9jb2xvcl9oZXgY'
    'DCABKAlSEHdhdmVmb3JtQ29sb3JIZXgSeQoTcHJldmlld19yZXN0cmljdGlvbhgNIAEoDjJILn'
    'Nwb3RpZnkuZXh0ZW5kZWRtZXRhZGF0YS5leHRlbnNpb25zLnByZXZpZXdjYXJkdHJhaXQuUHJl'
    'dmlld1Jlc3RyaWN0aW9uUhJwcmV2aWV3UmVzdHJpY3Rpb24SVAoGbGFiZWxzGA4gASgLMjwuc3'
    'BvdGlmeS5leHRlbmRlZG1ldGFkYXRhLmV4dGVuc2lvbnMucHJldmlld2NhcmR0cmFpdC5MYWJl'
    'bHNSBmxhYmVscxJsCg9kZXNjcmlwdG9yX3RhZ3MYDyADKAsyQy5zcG90aWZ5LmV4dGVuZGVkbW'
    'V0YWRhdGEuZXh0ZW5zaW9ucy5wcmV2aWV3Y2FyZHRyYWl0LkRlc2NyaXB0b3JUYWdSDmRlc2Ny'
    'aXB0b3JUYWdzEiYKD251bWJlcl9vZl9pdGVtcxgQIAEoBVINbnVtYmVyT2ZJdGVtcxJqCg5jb2'
    '50ZW50X3BhcmVudBgRIAEoCzJDLnNwb3RpZnkuZXh0ZW5kZWRtZXRhZGF0YS5leHRlbnNpb25z'
    'LnByZXZpZXdjYXJkdHJhaXQuQ29udGVudFBhcmVudFINY29udGVudFBhcmVudBJtCg9zdWJ0aX'
    'RsZV9zb3VyY2UYEiABKA4yRC5zcG90aWZ5LmV4dGVuZGVkbWV0YWRhdGEuZXh0ZW5zaW9ucy5w'
    'cmV2aWV3Y2FyZHRyYWl0LlN1YnRpdGxlU291cmNlUg5zdWJ0aXRsZVNvdXJjZQ==');

@$core.Deprecated('Use labelsDescriptor instead')
const Labels$json = {
  '1': 'Labels',
  '2': [
    {'1': 'preview_label', '3': 1, '4': 1, '5': 9, '10': 'previewLabel'},
    {'1': 'playing_label', '3': 2, '4': 1, '5': 9, '10': 'playingLabel'},
  ],
};

/// Descriptor for `Labels`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List labelsDescriptor = $convert.base64Decode(
    'CgZMYWJlbHMSIwoNcHJldmlld19sYWJlbBgBIAEoCVIMcHJldmlld0xhYmVsEiMKDXBsYXlpbm'
    'dfbGFiZWwYAiABKAlSDHBsYXlpbmdMYWJlbA==');

@$core.Deprecated('Use descriptorTagDescriptor instead')
const DescriptorTag$json = {
  '1': 'DescriptorTag',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `DescriptorTag`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List descriptorTagDescriptor =
    $convert.base64Decode('Cg1EZXNjcmlwdG9yVGFnEhIKBG5hbWUYASABKAlSBG5hbWU=');

@$core.Deprecated('Use contentParentDescriptor instead')
const ContentParent$json = {
  '1': 'ContentParent',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'uri', '3': 2, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'image_url', '3': 3, '4': 1, '5': 9, '10': 'imageUrl'},
  ],
};

/// Descriptor for `ContentParent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contentParentDescriptor = $convert.base64Decode(
    'Cg1Db250ZW50UGFyZW50EhIKBG5hbWUYASABKAlSBG5hbWUSEAoDdXJpGAIgASgJUgN1cmkSGw'
    'oJaW1hZ2VfdXJsGAMgASgJUghpbWFnZVVybA==');
