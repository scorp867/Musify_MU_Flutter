// This is a generated file - do not edit.
//
// Generated from spotify/contentagnostic/v2/on_platform_reputation_trait.proto.

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

@$core.Deprecated('Use verificationDescriptor instead')
const Verification$json = {
  '1': 'Verification',
  '2': [
    {'1': 'is_registered', '3': 1, '4': 1, '5': 8, '10': 'isRegistered'},
    {'1': 'is_verified', '3': 2, '4': 1, '5': 8, '10': 'isVerified'},
  ],
};

/// Descriptor for `Verification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List verificationDescriptor = $convert.base64Decode(
    'CgxWZXJpZmljYXRpb24SIwoNaXNfcmVnaXN0ZXJlZBgBIAEoCFIMaXNSZWdpc3RlcmVkEh8KC2'
    'lzX3ZlcmlmaWVkGAIgASgIUgppc1ZlcmlmaWVk');

@$core.Deprecated('Use chartPositionDescriptor instead')
const ChartPosition$json = {
  '1': 'ChartPosition',
  '2': [
    {'1': 'chart_url', '3': 1, '4': 1, '5': 9, '10': 'chartUrl'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
  ],
};

/// Descriptor for `ChartPosition`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chartPositionDescriptor = $convert.base64Decode(
    'Cg1DaGFydFBvc2l0aW9uEhsKCWNoYXJ0X3VybBgBIAEoCVIIY2hhcnRVcmwSIAoLZGVzY3JpcH'
    'Rpb24YAiABKAlSC2Rlc2NyaXB0aW9u');

@$core.Deprecated('Use ratingDescriptor instead')
const Rating$json = {
  '1': 'Rating',
  '2': [
    {'1': 'average', '3': 1, '4': 1, '5': 1, '10': 'average'},
    {'1': 'count', '3': 2, '4': 1, '5': 5, '10': 'count'},
  ],
};

/// Descriptor for `Rating`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ratingDescriptor = $convert.base64Decode(
    'CgZSYXRpbmcSGAoHYXZlcmFnZRgBIAEoAVIHYXZlcmFnZRIUCgVjb3VudBgCIAEoBVIFY291bn'
    'Q=');

@$core.Deprecated('Use onPlatformReputationTraitDescriptor instead')
const OnPlatformReputationTrait$json = {
  '1': 'OnPlatformReputationTrait',
  '2': [
    {
      '1': 'total_established_user_relationships',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'totalEstablishedUserRelationships'
    },
    {'1': 'total_plays', '3': 3, '4': 1, '5': 3, '10': 'totalPlays'},
    {
      '1': 'monthly_listeners',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'monthlyListeners'
    },
    {
      '1': 'chart_position',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.ChartPosition',
      '10': 'chartPosition'
    },
    {
      '1': 'rating',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.Rating',
      '10': 'rating'
    },
    {
      '1': 'verification',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.Verification',
      '10': 'verification'
    },
  ],
};

/// Descriptor for `OnPlatformReputationTrait`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List onPlatformReputationTraitDescriptor = $convert.base64Decode(
    'ChlPblBsYXRmb3JtUmVwdXRhdGlvblRyYWl0Ek8KJHRvdGFsX2VzdGFibGlzaGVkX3VzZXJfcm'
    'VsYXRpb25zaGlwcxgBIAEoA1IhdG90YWxFc3RhYmxpc2hlZFVzZXJSZWxhdGlvbnNoaXBzEh8K'
    'C3RvdGFsX3BsYXlzGAMgASgDUgp0b3RhbFBsYXlzEisKEW1vbnRobHlfbGlzdGVuZXJzGAQgAS'
    'gDUhBtb250aGx5TGlzdGVuZXJzElAKDmNoYXJ0X3Bvc2l0aW9uGAcgASgLMikuc3BvdGlmeS5j'
    'b250ZW50YWdub3N0aWMudjIuQ2hhcnRQb3NpdGlvblINY2hhcnRQb3NpdGlvbhI6CgZyYXRpbm'
    'cYCCABKAsyIi5zcG90aWZ5LmNvbnRlbnRhZ25vc3RpYy52Mi5SYXRpbmdSBnJhdGluZxJMCgx2'
    'ZXJpZmljYXRpb24YCSABKAsyKC5zcG90aWZ5LmNvbnRlbnRhZ25vc3RpYy52Mi5WZXJpZmljYX'
    'Rpb25SDHZlcmlmaWNhdGlvbg==');
