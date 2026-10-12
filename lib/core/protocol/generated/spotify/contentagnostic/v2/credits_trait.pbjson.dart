// This is a generated file - do not edit.
//
// Generated from spotify/contentagnostic/v2/credits_trait.proto.

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

@$core.Deprecated('Use roleGroupDescriptor instead')
const RoleGroup$json = {
  '1': 'RoleGroup',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `RoleGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roleGroupDescriptor =
    $convert.base64Decode('CglSb2xlR3JvdXASEgoEbmFtZRgBIAEoCVIEbmFtZQ==');

@$core.Deprecated('Use contributorDescriptor instead')
const Contributor$json = {
  '1': 'Contributor',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'role', '3': 2, '4': 1, '5': 9, '10': 'role'},
    {'1': 'uri', '3': 3, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'url', '3': 5, '4': 1, '5': 9, '10': 'url'},
    {
      '1': 'role_group',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.RoleGroup',
      '10': 'roleGroup'
    },
  ],
};

/// Descriptor for `Contributor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contributorDescriptor = $convert.base64Decode(
    'CgtDb250cmlidXRvchISCgRuYW1lGAEgASgJUgRuYW1lEhIKBHJvbGUYAiABKAlSBHJvbGUSEA'
    'oDdXJpGAMgASgJUgN1cmkSEAoDdXJsGAUgASgJUgN1cmwSRAoKcm9sZV9ncm91cBgGIAEoCzIl'
    'LnNwb3RpZnkuY29udGVudGFnbm9zdGljLnYyLlJvbGVHcm91cFIJcm9sZUdyb3Vw');

@$core.Deprecated('Use creditsSourceDescriptor instead')
const CreditsSource$json = {
  '1': 'CreditsSource',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `CreditsSource`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List creditsSourceDescriptor =
    $convert.base64Decode('Cg1DcmVkaXRzU291cmNlEhIKBG5hbWUYASABKAlSBG5hbWU=');

@$core.Deprecated('Use creditsTraitDescriptor instead')
const CreditsTrait$json = {
  '1': 'CreditsTrait',
  '2': [
    {
      '1': 'contributors',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.Contributor',
      '10': 'contributors'
    },
    {
      '1': 'sources',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.CreditsSource',
      '10': 'sources'
    },
  ],
};

/// Descriptor for `CreditsTrait`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List creditsTraitDescriptor = $convert.base64Decode(
    'CgxDcmVkaXRzVHJhaXQSSwoMY29udHJpYnV0b3JzGAEgAygLMicuc3BvdGlmeS5jb250ZW50YW'
    'dub3N0aWMudjIuQ29udHJpYnV0b3JSDGNvbnRyaWJ1dG9ycxJDCgdzb3VyY2VzGAIgAygLMiku'
    'c3BvdGlmeS5jb250ZW50YWdub3N0aWMudjIuQ3JlZGl0c1NvdXJjZVIHc291cmNlcw==');
