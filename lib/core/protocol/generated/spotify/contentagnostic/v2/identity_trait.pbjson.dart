// This is a generated file - do not edit.
//
// Generated from spotify/contentagnostic/v2/identity_trait.proto.

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

@$core.Deprecated('Use identityTraitDescriptor instead')
const IdentityTrait$json = {
  '1': 'IdentityTrait',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'content_hierarchy_parent',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.EntityReference',
      '10': 'contentHierarchyParent'
    },
    {
      '1': 'contributors',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.Contributor',
      '10': 'contributors'
    },
  ],
};

/// Descriptor for `IdentityTrait`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List identityTraitDescriptor = $convert.base64Decode(
    'Cg1JZGVudGl0eVRyYWl0EhIKBHR5cGUYASABKAlSBHR5cGUSEgoEbmFtZRgCIAEoCVIEbmFtZR'
    'IgCgtkZXNjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRpb24SZQoYY29udGVudF9oaWVyYXJjaHlf'
    'cGFyZW50GAQgASgLMisuc3BvdGlmeS5jb250ZW50YWdub3N0aWMudjIuRW50aXR5UmVmZXJlbm'
    'NlUhZjb250ZW50SGllcmFyY2h5UGFyZW50EksKDGNvbnRyaWJ1dG9ycxgFIAMoCzInLnNwb3Rp'
    'ZnkuY29udGVudGFnbm9zdGljLnYyLkNvbnRyaWJ1dG9yUgxjb250cmlidXRvcnM=');

@$core.Deprecated('Use entityReferenceDescriptor instead')
const EntityReference$json = {
  '1': 'EntityReference',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
  ],
};

/// Descriptor for `EntityReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List entityReferenceDescriptor =
    $convert.base64Decode('Cg9FbnRpdHlSZWZlcmVuY2USEAoDdXJpGAEgASgJUgN1cmk=');

@$core.Deprecated('Use contributorDescriptor instead')
const Contributor$json = {
  '1': 'Contributor',
  '2': [
    {
      '1': 'reference',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.contentagnostic.v2.ContributorReference',
      '10': 'reference'
    },
    {'1': 'role', '3': 2, '4': 1, '5': 9, '10': 'role'},
  ],
};

/// Descriptor for `Contributor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contributorDescriptor = $convert.base64Decode(
    'CgtDb250cmlidXRvchJOCglyZWZlcmVuY2UYASABKAsyMC5zcG90aWZ5LmNvbnRlbnRhZ25vc3'
    'RpYy52Mi5Db250cmlidXRvclJlZmVyZW5jZVIJcmVmZXJlbmNlEhIKBHJvbGUYAiABKAlSBHJv'
    'bGU=');

@$core.Deprecated('Use contributorReferenceDescriptor instead')
const ContributorReference$json = {
  '1': 'ContributorReference',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `ContributorReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contributorReferenceDescriptor = $convert.base64Decode(
    'ChRDb250cmlidXRvclJlZmVyZW5jZRIQCgN1cmkYASABKAlSA3VyaRISCgRuYW1lGAIgASgJUg'
    'RuYW1l');
