// This is a generated file - do not edit.
//
// Generated from spotify/playlist/recents_list.proto.

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

@$core.Deprecated('Use recentsListResponseDescriptor instead')
const RecentsListResponse$json = {
  '1': 'RecentsListResponse',
  '2': [
    {
      '1': 'list',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.RecentsItemList',
      '10': 'list'
    },
  ],
};

/// Descriptor for `RecentsListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recentsListResponseDescriptor = $convert.base64Decode(
    'ChNSZWNlbnRzTGlzdFJlc3BvbnNlEjgKBGxpc3QYBSABKAsyJC5zcG90aWZ5LnBsYXlsaXN0Ln'
    'YyLlJlY2VudHNJdGVtTGlzdFIEbGlzdA==');

@$core.Deprecated('Use recentsItemListDescriptor instead')
const RecentsItemList$json = {
  '1': 'RecentsItemList',
  '2': [
    {
      '1': 'items',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.spotify.playlist.v2.RecentsListItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `RecentsItemList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recentsItemListDescriptor = $convert.base64Decode(
    'Cg9SZWNlbnRzSXRlbUxpc3QSOgoFaXRlbXMYAyADKAsyJC5zcG90aWZ5LnBsYXlsaXN0LnYyLl'
    'JlY2VudHNMaXN0SXRlbVIFaXRlbXM=');

@$core.Deprecated('Use recentsListItemDescriptor instead')
const RecentsListItem$json = {
  '1': 'RecentsListItem',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {
      '1': 'attributes',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.RecentsItemAttributes',
      '10': 'attributes'
    },
  ],
};

/// Descriptor for `RecentsListItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recentsListItemDescriptor = $convert.base64Decode(
    'Cg9SZWNlbnRzTGlzdEl0ZW0SEAoDdXJpGAEgASgJUgN1cmkSSgoKYXR0cmlidXRlcxgCIAEoCz'
    'IqLnNwb3RpZnkucGxheWxpc3QudjIuUmVjZW50c0l0ZW1BdHRyaWJ1dGVzUgphdHRyaWJ1dGVz');

@$core.Deprecated('Use recentsItemAttributesDescriptor instead')
const RecentsItemAttributes$json = {
  '1': 'RecentsItemAttributes',
  '2': [
    {
      '1': 'format_attributes',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.spotify.playlist.v2.FormatAttribute',
      '10': 'formatAttributes'
    },
  ],
};

/// Descriptor for `RecentsItemAttributes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recentsItemAttributesDescriptor = $convert.base64Decode(
    'ChVSZWNlbnRzSXRlbUF0dHJpYnV0ZXMSUQoRZm9ybWF0X2F0dHJpYnV0ZXMYCyADKAsyJC5zcG'
    '90aWZ5LnBsYXlsaXN0LnYyLkZvcm1hdEF0dHJpYnV0ZVIQZm9ybWF0QXR0cmlidXRlcw==');

@$core.Deprecated('Use formatAttributeDescriptor instead')
const FormatAttribute$json = {
  '1': 'FormatAttribute',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `FormatAttribute`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formatAttributeDescriptor = $convert.base64Decode(
    'Cg9Gb3JtYXRBdHRyaWJ1dGUSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbH'
    'Vl');
