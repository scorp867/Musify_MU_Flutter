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
    {'1': 'revision', '3': 1, '4': 1, '5': 12, '10': 'revision'},
    {'1': 'length', '3': 2, '4': 1, '5': 5, '10': 'length'},
    {
      '1': 'list_attributes',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.RecentsListAttributes',
      '10': 'listAttributes'
    },
    {
      '1': 'list',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.RecentsItemList',
      '10': 'list'
    },
    {'1': 'multiple_heads', '3': 9, '4': 1, '5': 8, '10': 'multipleHeads'},
    {'1': 'up_to_date', '3': 10, '4': 1, '5': 8, '10': 'upToDate'},
    {'1': 'nonces', '3': 14, '4': 3, '5': 3, '10': 'nonces'},
    {'1': 'timestamp', '3': 15, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'owner_username', '3': 16, '4': 1, '5': 9, '10': 'ownerUsername'},
    {
      '1': 'abuse_reporting_enabled',
      '3': 17,
      '4': 1,
      '5': 8,
      '10': 'abuseReportingEnabled'
    },
    {'1': 'geoblock', '3': 19, '4': 3, '5': 5, '10': 'geoblock'},
    {
      '1': 'changes_require_resync',
      '3': 20,
      '4': 1,
      '5': 8,
      '10': 'changesRequireResync'
    },
    {'1': 'created_at', '3': 21, '4': 1, '5': 3, '10': 'createdAt'},
  ],
};

/// Descriptor for `RecentsListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recentsListResponseDescriptor = $convert.base64Decode(
    'ChNSZWNlbnRzTGlzdFJlc3BvbnNlEhoKCHJldmlzaW9uGAEgASgMUghyZXZpc2lvbhIWCgZsZW'
    '5ndGgYAiABKAVSBmxlbmd0aBJTCg9saXN0X2F0dHJpYnV0ZXMYAyABKAsyKi5zcG90aWZ5LnBs'
    'YXlsaXN0LnYyLlJlY2VudHNMaXN0QXR0cmlidXRlc1IObGlzdEF0dHJpYnV0ZXMSOAoEbGlzdB'
    'gFIAEoCzIkLnNwb3RpZnkucGxheWxpc3QudjIuUmVjZW50c0l0ZW1MaXN0UgRsaXN0EiUKDm11'
    'bHRpcGxlX2hlYWRzGAkgASgIUg1tdWx0aXBsZUhlYWRzEhwKCnVwX3RvX2RhdGUYCiABKAhSCH'
    'VwVG9EYXRlEhYKBm5vbmNlcxgOIAMoA1IGbm9uY2VzEhwKCXRpbWVzdGFtcBgPIAEoA1IJdGlt'
    'ZXN0YW1wEiUKDm93bmVyX3VzZXJuYW1lGBAgASgJUg1vd25lclVzZXJuYW1lEjYKF2FidXNlX3'
    'JlcG9ydGluZ19lbmFibGVkGBEgASgIUhVhYnVzZVJlcG9ydGluZ0VuYWJsZWQSGgoIZ2VvYmxv'
    'Y2sYEyADKAVSCGdlb2Jsb2NrEjQKFmNoYW5nZXNfcmVxdWlyZV9yZXN5bmMYFCABKAhSFGNoYW'
    '5nZXNSZXF1aXJlUmVzeW5jEh0KCmNyZWF0ZWRfYXQYFSABKANSCWNyZWF0ZWRBdA==');

@$core.Deprecated('Use recentsListAttributesDescriptor instead')
const RecentsListAttributes$json = {
  '1': 'RecentsListAttributes',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {'1': 'picture', '3': 3, '4': 1, '5': 12, '10': 'picture'},
    {'1': 'collaborative', '3': 4, '4': 1, '5': 8, '10': 'collaborative'},
    {'1': 'pl3_version', '3': 5, '4': 1, '5': 9, '10': 'pl3Version'},
    {'1': 'deleted_by_owner', '3': 6, '4': 1, '5': 8, '10': 'deletedByOwner'},
    {'1': 'client_id', '3': 10, '4': 1, '5': 9, '10': 'clientId'},
    {'1': 'format', '3': 11, '4': 1, '5': 9, '10': 'format'},
    {
      '1': 'format_attributes',
      '3': 12,
      '4': 3,
      '5': 11,
      '6': '.spotify.playlist.v2.FormatAttribute',
      '10': 'formatAttributes'
    },
  ],
};

/// Descriptor for `RecentsListAttributes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recentsListAttributesDescriptor = $convert.base64Decode(
    'ChVSZWNlbnRzTGlzdEF0dHJpYnV0ZXMSEgoEbmFtZRgBIAEoCVIEbmFtZRIgCgtkZXNjcmlwdG'
    'lvbhgCIAEoCVILZGVzY3JpcHRpb24SGAoHcGljdHVyZRgDIAEoDFIHcGljdHVyZRIkCg1jb2xs'
    'YWJvcmF0aXZlGAQgASgIUg1jb2xsYWJvcmF0aXZlEh8KC3BsM192ZXJzaW9uGAUgASgJUgpwbD'
    'NWZXJzaW9uEigKEGRlbGV0ZWRfYnlfb3duZXIYBiABKAhSDmRlbGV0ZWRCeU93bmVyEhsKCWNs'
    'aWVudF9pZBgKIAEoCVIIY2xpZW50SWQSFgoGZm9ybWF0GAsgASgJUgZmb3JtYXQSUQoRZm9ybW'
    'F0X2F0dHJpYnV0ZXMYDCADKAsyJC5zcG90aWZ5LnBsYXlsaXN0LnYyLkZvcm1hdEF0dHJpYnV0'
    'ZVIQZm9ybWF0QXR0cmlidXRlcw==');

@$core.Deprecated('Use recentsItemListDescriptor instead')
const RecentsItemList$json = {
  '1': 'RecentsItemList',
  '2': [
    {'1': 'pos', '3': 1, '4': 1, '5': 5, '10': 'pos'},
    {'1': 'truncated', '3': 2, '4': 1, '5': 8, '10': 'truncated'},
    {
      '1': 'items',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.spotify.playlist.v2.RecentsListItem',
      '10': 'items'
    },
    {
      '1': 'continuation_token',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'continuationToken'
    },
  ],
};

/// Descriptor for `RecentsItemList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recentsItemListDescriptor = $convert.base64Decode(
    'Cg9SZWNlbnRzSXRlbUxpc3QSEAoDcG9zGAEgASgFUgNwb3MSHAoJdHJ1bmNhdGVkGAIgASgIUg'
    'l0cnVuY2F0ZWQSOgoFaXRlbXMYAyADKAsyJC5zcG90aWZ5LnBsYXlsaXN0LnYyLlJlY2VudHNM'
    'aXN0SXRlbVIFaXRlbXMSLQoSY29udGludWF0aW9uX3Rva2VuGAYgASgJUhFjb250aW51YXRpb2'
    '5Ub2tlbg==');

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
    {'1': 'added_by', '3': 1, '4': 1, '5': 9, '10': 'addedBy'},
    {'1': 'timestamp', '3': 2, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'seen_at', '3': 9, '4': 1, '5': 3, '10': 'seenAt'},
    {'1': 'public', '3': 10, '4': 1, '5': 8, '10': 'public'},
    {
      '1': 'format_attributes',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.spotify.playlist.v2.FormatAttribute',
      '10': 'formatAttributes'
    },
    {'1': 'item_id', '3': 12, '4': 1, '5': 12, '10': 'itemId'},
    {'1': 'save_source', '3': 17, '4': 1, '5': 5, '10': 'saveSource'},
  ],
};

/// Descriptor for `RecentsItemAttributes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recentsItemAttributesDescriptor = $convert.base64Decode(
    'ChVSZWNlbnRzSXRlbUF0dHJpYnV0ZXMSGQoIYWRkZWRfYnkYASABKAlSB2FkZGVkQnkSHAoJdG'
    'ltZXN0YW1wGAIgASgDUgl0aW1lc3RhbXASFwoHc2Vlbl9hdBgJIAEoA1IGc2VlbkF0EhYKBnB1'
    'YmxpYxgKIAEoCFIGcHVibGljElEKEWZvcm1hdF9hdHRyaWJ1dGVzGAsgAygLMiQuc3BvdGlmeS'
    '5wbGF5bGlzdC52Mi5Gb3JtYXRBdHRyaWJ1dGVSEGZvcm1hdEF0dHJpYnV0ZXMSFwoHaXRlbV9p'
    'ZBgMIAEoDFIGaXRlbUlkEh8KC3NhdmVfc291cmNlGBEgASgFUgpzYXZlU291cmNl');

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

@$core.Deprecated('Use groupMetadataDescriptor instead')
const GroupMetadata$json = {
  '1': 'GroupMetadata',
  '2': [
    {'1': 'items_count', '3': 1, '4': 1, '5': 5, '10': 'itemsCount'},
    {'1': 'entity_uris', '3': 2, '4': 3, '5': 9, '10': 'entityUris'},
    {'1': 'user_uris', '3': 3, '4': 3, '5': 9, '10': 'userUris'},
    {
      '1': 'filtered_count',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.spotify.playlist.v2.GroupMetadata.FilteredCountEntry',
      '10': 'filteredCount'
    },
    {'1': 'group_name', '3': 5, '4': 1, '5': 9, '10': 'groupName'},
  ],
  '3': [GroupMetadata_FilteredCountEntry$json],
};

@$core.Deprecated('Use groupMetadataDescriptor instead')
const GroupMetadata_FilteredCountEntry$json = {
  '1': 'FilteredCountEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 5, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `GroupMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupMetadataDescriptor = $convert.base64Decode(
    'Cg1Hcm91cE1ldGFkYXRhEh8KC2l0ZW1zX2NvdW50GAEgASgFUgppdGVtc0NvdW50Eh8KC2VudG'
    'l0eV91cmlzGAIgAygJUgplbnRpdHlVcmlzEhsKCXVzZXJfdXJpcxgDIAMoCVIIdXNlclVyaXMS'
    'XAoOZmlsdGVyZWRfY291bnQYBCADKAsyNS5zcG90aWZ5LnBsYXlsaXN0LnYyLkdyb3VwTWV0YW'
    'RhdGEuRmlsdGVyZWRDb3VudEVudHJ5Ug1maWx0ZXJlZENvdW50Eh0KCmdyb3VwX25hbWUYBSAB'
    'KAlSCWdyb3VwTmFtZRpAChJGaWx0ZXJlZENvdW50RW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFA'
    'oFdmFsdWUYAiABKAVSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use shareMetadataDescriptor instead')
const ShareMetadata$json = {
  '1': 'ShareMetadata',
  '2': [
    {'1': 'user_uri', '3': 1, '4': 1, '5': 9, '10': 'userUri'},
    {'1': 'share_deeplink', '3': 2, '4': 1, '5': 9, '10': 'shareDeeplink'},
    {'1': 'source', '3': 3, '4': 1, '5': 9, '10': 'source'},
  ],
};

/// Descriptor for `ShareMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List shareMetadataDescriptor = $convert.base64Decode(
    'Cg1TaGFyZU1ldGFkYXRhEhkKCHVzZXJfdXJpGAEgASgJUgd1c2VyVXJpEiUKDnNoYXJlX2RlZX'
    'BsaW5rGAIgASgJUg1zaGFyZURlZXBsaW5rEhYKBnNvdXJjZRgDIAEoCVIGc291cmNl');
