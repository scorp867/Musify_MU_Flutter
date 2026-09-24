// This is a generated file - do not edit.
//
// Generated from spotify/traits/simple_card_trait.proto.

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

@$core.Deprecated('Use restrictionDescriptor instead')
const Restriction$json = {
  '1': 'Restriction',
  '2': [
    {'1': 'NONE', '2': 0},
    {'1': 'IS_EXPLICIT', '2': 1},
    {'1': 'IS_19_PLUS', '2': 2},
  ],
};

/// Descriptor for `Restriction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List restrictionDescriptor = $convert.base64Decode(
    'CgtSZXN0cmljdGlvbhIICgROT05FEAASDwoLSVNfRVhQTElDSVQQARIOCgpJU18xOV9QTFVTEA'
    'I=');

@$core.Deprecated('Use simpleCardTraitDescriptor instead')
const SimpleCardTrait$json = {
  '1': 'SimpleCardTrait',
  '2': [
    {'1': 'image_uri', '3': 1, '4': 1, '5': 9, '10': 'imageUri'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'subtitle', '3': 3, '4': 1, '5': 9, '10': 'subtitle'},
    {'1': 'navigation_uri', '3': 4, '4': 1, '5': 9, '10': 'navigationUri'},
    {
      '1': 'labels',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.spotify.extendedmetadata.extensions.simplecardtrait.Label',
      '10': 'labels'
    },
    {'1': 'accessibility', '3': 6, '4': 1, '5': 9, '10': 'accessibility'},
    {
      '1': 'restriction',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.spotify.extendedmetadata.extensions.simplecardtrait.Restriction',
      '10': 'restriction'
    },
    {
      '1': 'creators',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.spotify.extendedmetadata.extensions.simplecardtrait.Creator',
      '10': 'creators'
    },
    {
      '1': 'publish_time',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'publishTime'
    },
    {
      '1': 'duration',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Duration',
      '10': 'duration'
    },
    {'1': 'animation_url', '3': 11, '4': 1, '5': 9, '10': 'animationUrl'},
    {'1': 'title_text_color', '3': 12, '4': 1, '5': 9, '10': 'titleTextColor'},
  ],
};

/// Descriptor for `SimpleCardTrait`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List simpleCardTraitDescriptor = $convert.base64Decode(
    'Cg9TaW1wbGVDYXJkVHJhaXQSGwoJaW1hZ2VfdXJpGAEgASgJUghpbWFnZVVyaRIUCgV0aXRsZR'
    'gCIAEoCVIFdGl0bGUSGgoIc3VidGl0bGUYAyABKAlSCHN1YnRpdGxlEiUKDm5hdmlnYXRpb25f'
    'dXJpGAQgASgJUg1uYXZpZ2F0aW9uVXJpElIKBmxhYmVscxgFIAMoCzI6LnNwb3RpZnkuZXh0ZW'
    '5kZWRtZXRhZGF0YS5leHRlbnNpb25zLnNpbXBsZWNhcmR0cmFpdC5MYWJlbFIGbGFiZWxzEiQK'
    'DWFjY2Vzc2liaWxpdHkYBiABKAlSDWFjY2Vzc2liaWxpdHkSYgoLcmVzdHJpY3Rpb24YByABKA'
    '4yQC5zcG90aWZ5LmV4dGVuZGVkbWV0YWRhdGEuZXh0ZW5zaW9ucy5zaW1wbGVjYXJkdHJhaXQu'
    'UmVzdHJpY3Rpb25SC3Jlc3RyaWN0aW9uElgKCGNyZWF0b3JzGAggAygLMjwuc3BvdGlmeS5leH'
    'RlbmRlZG1ldGFkYXRhLmV4dGVuc2lvbnMuc2ltcGxlY2FyZHRyYWl0LkNyZWF0b3JSCGNyZWF0'
    'b3JzEj0KDHB1Ymxpc2hfdGltZRgJIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSC3'
    'B1Ymxpc2hUaW1lEjUKCGR1cmF0aW9uGAogASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9u'
    'UghkdXJhdGlvbhIjCg1hbmltYXRpb25fdXJsGAsgASgJUgxhbmltYXRpb25VcmwSKAoQdGl0bG'
    'VfdGV4dF9jb2xvchgMIAEoCVIOdGl0bGVUZXh0Q29sb3I=');

@$core.Deprecated('Use labelDescriptor instead')
const Label$json = {
  '1': 'Label',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `Label`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List labelDescriptor =
    $convert.base64Decode('CgVMYWJlbBISCgR0ZXh0GAEgASgJUgR0ZXh0');

@$core.Deprecated('Use creatorDescriptor instead')
const Creator$json = {
  '1': 'Creator',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'uri', '3': 2, '4': 1, '5': 9, '10': 'uri'},
  ],
};

/// Descriptor for `Creator`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List creatorDescriptor = $convert.base64Decode(
    'CgdDcmVhdG9yEhIKBG5hbWUYASABKAlSBG5hbWUSEAoDdXJpGAIgASgJUgN1cmk=');
