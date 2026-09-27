// This is a generated file - do not edit.
//
// Generated from spotify/playlist/rootlist.proto.

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

@$core.Deprecated('Use permissionLevelDescriptor instead')
const PermissionLevel$json = {
  '1': 'PermissionLevel',
  '2': [
    {'1': 'PERMISSION_LEVEL_UNKNOWN', '2': 0},
    {'1': 'BLOCKED', '2': 1},
    {'1': 'VIEWER', '2': 2},
    {'1': 'CONTRIBUTOR', '2': 3},
    {'1': 'MADE_FOR', '2': 4},
  ],
};

/// Descriptor for `PermissionLevel`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List permissionLevelDescriptor = $convert.base64Decode(
    'Cg9QZXJtaXNzaW9uTGV2ZWwSHAoYUEVSTUlTU0lPTl9MRVZFTF9VTktOT1dOEAASCwoHQkxPQ0'
    'tFRBABEgoKBlZJRVdFUhACEg8KC0NPTlRSSUJVVE9SEAMSDAoITUFERV9GT1IQBA==');

@$core.Deprecated('Use geoblockBlockingTypeDescriptor instead')
const GeoblockBlockingType$json = {
  '1': 'GeoblockBlockingType',
  '2': [
    {'1': 'GEOBLOCK_BLOCKING_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'GEOBLOCK_BLOCKING_TYPE_BLOCKED', '2': 1},
  ],
};

/// Descriptor for `GeoblockBlockingType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List geoblockBlockingTypeDescriptor = $convert.base64Decode(
    'ChRHZW9ibG9ja0Jsb2NraW5nVHlwZRImCiJHRU9CTE9DS19CTE9DS0lOR19UWVBFX1VOU1BFQ0'
    'lGSUVEEAASIgoeR0VPQkxPQ0tfQkxPQ0tJTkdfVFlQRV9CTE9DS0VEEAE=');

@$core.Deprecated('Use selectedListContentDescriptor instead')
const SelectedListContent$json = {
  '1': 'SelectedListContent',
  '2': [
    {'1': 'revision', '3': 1, '4': 1, '5': 12, '10': 'revision'},
    {'1': 'length', '3': 2, '4': 1, '5': 5, '10': 'length'},
    {
      '1': 'attributes',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.ListAttributes',
      '10': 'attributes'
    },
    {
      '1': 'contents',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.ListItems',
      '10': 'contents'
    },
    {'1': 'timestamp', '3': 15, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'owner_username', '3': 16, '4': 1, '5': 9, '10': 'ownerUsername'},
    {'1': 'created_at', '3': 21, '4': 1, '5': 3, '10': 'createdAt'},
  ],
};

/// Descriptor for `SelectedListContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List selectedListContentDescriptor = $convert.base64Decode(
    'ChNTZWxlY3RlZExpc3RDb250ZW50EhoKCHJldmlzaW9uGAEgASgMUghyZXZpc2lvbhIWCgZsZW'
    '5ndGgYAiABKAVSBmxlbmd0aBJDCgphdHRyaWJ1dGVzGAMgASgLMiMuc3BvdGlmeS5wbGF5bGlz'
    'dC52Mi5MaXN0QXR0cmlidXRlc1IKYXR0cmlidXRlcxI6Cghjb250ZW50cxgFIAEoCzIeLnNwb3'
    'RpZnkucGxheWxpc3QudjIuTGlzdEl0ZW1zUghjb250ZW50cxIcCgl0aW1lc3RhbXAYDyABKANS'
    'CXRpbWVzdGFtcBIlCg5vd25lcl91c2VybmFtZRgQIAEoCVINb3duZXJVc2VybmFtZRIdCgpjcm'
    'VhdGVkX2F0GBUgASgDUgljcmVhdGVkQXQ=');

@$core.Deprecated('Use listItemsDescriptor instead')
const ListItems$json = {
  '1': 'ListItems',
  '2': [
    {'1': 'pos', '3': 1, '4': 1, '5': 5, '10': 'pos'},
    {'1': 'truncated', '3': 2, '4': 1, '5': 8, '10': 'truncated'},
    {
      '1': 'items',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.spotify.playlist.v2.Item',
      '10': 'items'
    },
    {
      '1': 'meta_items',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.spotify.playlist.v2.MetaItem',
      '10': 'metaItems'
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

/// Descriptor for `ListItems`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listItemsDescriptor = $convert.base64Decode(
    'CglMaXN0SXRlbXMSEAoDcG9zGAEgASgFUgNwb3MSHAoJdHJ1bmNhdGVkGAIgASgIUgl0cnVuY2'
    'F0ZWQSLwoFaXRlbXMYAyADKAsyGS5zcG90aWZ5LnBsYXlsaXN0LnYyLkl0ZW1SBWl0ZW1zEjwK'
    'Cm1ldGFfaXRlbXMYBCADKAsyHS5zcG90aWZ5LnBsYXlsaXN0LnYyLk1ldGFJdGVtUgltZXRhSX'
    'RlbXMSLQoSY29udGludWF0aW9uX3Rva2VuGAYgASgJUhFjb250aW51YXRpb25Ub2tlbg==');

@$core.Deprecated('Use itemDescriptor instead')
const Item$json = {
  '1': 'Item',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {
      '1': 'attributes',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.ItemAttributes',
      '10': 'attributes'
    },
  ],
};

/// Descriptor for `Item`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List itemDescriptor = $convert.base64Decode(
    'CgRJdGVtEhAKA3VyaRgBIAEoCVIDdXJpEkMKCmF0dHJpYnV0ZXMYAiABKAsyIy5zcG90aWZ5Ln'
    'BsYXlsaXN0LnYyLkl0ZW1BdHRyaWJ1dGVzUgphdHRyaWJ1dGVz');

@$core.Deprecated('Use itemAttributesDescriptor instead')
const ItemAttributes$json = {
  '1': 'ItemAttributes',
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
      '6': '.spotify.playlist.v2.FormatListAttribute',
      '10': 'formatAttributes'
    },
    {'1': 'item_id', '3': 12, '4': 1, '5': 12, '10': 'itemId'},
  ],
};

/// Descriptor for `ItemAttributes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List itemAttributesDescriptor = $convert.base64Decode(
    'Cg5JdGVtQXR0cmlidXRlcxIZCghhZGRlZF9ieRgBIAEoCVIHYWRkZWRCeRIcCgl0aW1lc3RhbX'
    'AYAiABKANSCXRpbWVzdGFtcBIXCgdzZWVuX2F0GAkgASgDUgZzZWVuQXQSFgoGcHVibGljGAog'
    'ASgIUgZwdWJsaWMSVQoRZm9ybWF0X2F0dHJpYnV0ZXMYCyADKAsyKC5zcG90aWZ5LnBsYXlsaX'
    'N0LnYyLkZvcm1hdExpc3RBdHRyaWJ1dGVSEGZvcm1hdEF0dHJpYnV0ZXMSFwoHaXRlbV9pZBgM'
    'IAEoDFIGaXRlbUlk');

@$core.Deprecated('Use listAttributesDescriptor instead')
const ListAttributes$json = {
  '1': 'ListAttributes',
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
      '6': '.spotify.playlist.v2.FormatListAttribute',
      '10': 'formatAttributes'
    },
    {
      '1': 'picture_size',
      '3': 13,
      '4': 3,
      '5': 11,
      '6': '.spotify.playlist.v2.PictureSize',
      '10': 'pictureSize'
    },
    {'1': 'recoverable', '3': 17, '4': 1, '5': 8, '10': 'recoverable'},
    {'1': 'is_user_created', '3': 18, '4': 1, '5': 8, '10': 'isUserCreated'},
  ],
};

/// Descriptor for `ListAttributes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listAttributesDescriptor = $convert.base64Decode(
    'Cg5MaXN0QXR0cmlidXRlcxISCgRuYW1lGAEgASgJUgRuYW1lEiAKC2Rlc2NyaXB0aW9uGAIgAS'
    'gJUgtkZXNjcmlwdGlvbhIYCgdwaWN0dXJlGAMgASgMUgdwaWN0dXJlEiQKDWNvbGxhYm9yYXRp'
    'dmUYBCABKAhSDWNvbGxhYm9yYXRpdmUSHwoLcGwzX3ZlcnNpb24YBSABKAlSCnBsM1ZlcnNpb2'
    '4SKAoQZGVsZXRlZF9ieV9vd25lchgGIAEoCFIOZGVsZXRlZEJ5T3duZXISGwoJY2xpZW50X2lk'
    'GAogASgJUghjbGllbnRJZBIWCgZmb3JtYXQYCyABKAlSBmZvcm1hdBJVChFmb3JtYXRfYXR0cm'
    'lidXRlcxgMIAMoCzIoLnNwb3RpZnkucGxheWxpc3QudjIuRm9ybWF0TGlzdEF0dHJpYnV0ZVIQ'
    'Zm9ybWF0QXR0cmlidXRlcxJDCgxwaWN0dXJlX3NpemUYDSADKAsyIC5zcG90aWZ5LnBsYXlsaX'
    'N0LnYyLlBpY3R1cmVTaXplUgtwaWN0dXJlU2l6ZRIgCgtyZWNvdmVyYWJsZRgRIAEoCFILcmVj'
    'b3ZlcmFibGUSJgoPaXNfdXNlcl9jcmVhdGVkGBIgASgIUg1pc1VzZXJDcmVhdGVk');

@$core.Deprecated('Use formatListAttributeDescriptor instead')
const FormatListAttribute$json = {
  '1': 'FormatListAttribute',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `FormatListAttribute`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formatListAttributeDescriptor = $convert.base64Decode(
    'ChNGb3JtYXRMaXN0QXR0cmlidXRlEhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUg'
    'V2YWx1ZQ==');

@$core.Deprecated('Use pictureSizeDescriptor instead')
const PictureSize$json = {
  '1': 'PictureSize',
  '2': [
    {'1': 'target_name', '3': 1, '4': 1, '5': 9, '10': 'targetName'},
    {'1': 'url', '3': 2, '4': 1, '5': 9, '10': 'url'},
  ],
};

/// Descriptor for `PictureSize`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pictureSizeDescriptor = $convert.base64Decode(
    'CgtQaWN0dXJlU2l6ZRIfCgt0YXJnZXRfbmFtZRgBIAEoCVIKdGFyZ2V0TmFtZRIQCgN1cmwYAi'
    'ABKAlSA3VybA==');

@$core.Deprecated('Use metaItemDescriptor instead')
const MetaItem$json = {
  '1': 'MetaItem',
  '2': [
    {'1': 'revision', '3': 1, '4': 1, '5': 12, '10': 'revision'},
    {
      '1': 'attributes',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.ListAttributes',
      '10': 'attributes'
    },
    {'1': 'length', '3': 3, '4': 1, '5': 5, '10': 'length'},
    {'1': 'timestamp', '3': 4, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'owner_username', '3': 5, '4': 1, '5': 9, '10': 'ownerUsername'},
    {
      '1': 'abuse_reporting_enabled',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'abuseReportingEnabled'
    },
    {
      '1': 'capabilities',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.Capabilities',
      '10': 'capabilities'
    },
    {
      '1': 'geoblock',
      '3': 8,
      '4': 3,
      '5': 14,
      '6': '.spotify.playlist.v2.GeoblockBlockingType',
      '10': 'geoblock'
    },
    {'1': 'status_code', '3': 9, '4': 1, '5': 5, '10': 'statusCode'},
  ],
};

/// Descriptor for `MetaItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List metaItemDescriptor = $convert.base64Decode(
    'CghNZXRhSXRlbRIaCghyZXZpc2lvbhgBIAEoDFIIcmV2aXNpb24SQwoKYXR0cmlidXRlcxgCIA'
    'EoCzIjLnNwb3RpZnkucGxheWxpc3QudjIuTGlzdEF0dHJpYnV0ZXNSCmF0dHJpYnV0ZXMSFgoG'
    'bGVuZ3RoGAMgASgFUgZsZW5ndGgSHAoJdGltZXN0YW1wGAQgASgDUgl0aW1lc3RhbXASJQoOb3'
    'duZXJfdXNlcm5hbWUYBSABKAlSDW93bmVyVXNlcm5hbWUSNgoXYWJ1c2VfcmVwb3J0aW5nX2Vu'
    'YWJsZWQYBiABKAhSFWFidXNlUmVwb3J0aW5nRW5hYmxlZBJFCgxjYXBhYmlsaXRpZXMYByABKA'
    'syIS5zcG90aWZ5LnBsYXlsaXN0LnYyLkNhcGFiaWxpdGllc1IMY2FwYWJpbGl0aWVzEkUKCGdl'
    'b2Jsb2NrGAggAygOMikuc3BvdGlmeS5wbGF5bGlzdC52Mi5HZW9ibG9ja0Jsb2NraW5nVHlwZV'
    'IIZ2VvYmxvY2sSHwoLc3RhdHVzX2NvZGUYCSABKAVSCnN0YXR1c0NvZGU=');

@$core.Deprecated('Use capabilitiesDescriptor instead')
const Capabilities$json = {
  '1': 'Capabilities',
  '2': [
    {'1': 'can_view', '3': 1, '4': 1, '5': 8, '10': 'canView'},
    {
      '1': 'can_administrate_permissions',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'canAdministratePermissions'
    },
    {'1': 'can_edit_metadata', '3': 4, '4': 1, '5': 8, '10': 'canEditMetadata'},
    {'1': 'can_edit_items', '3': 5, '4': 1, '5': 8, '10': 'canEditItems'},
    {
      '1': 'can_cancel_membership',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'canCancelMembership'
    },
    {
      '1': 'grantable_levels',
      '3': 7,
      '4': 3,
      '5': 14,
      '6': '.spotify.playlist.v2.PermissionLevel',
      '10': 'grantableLevels'
    },
    {
      '1': 'list_attribute_capabilities',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.ListAttributeCapabilities',
      '10': 'listAttributeCapabilities'
    },
  ],
};

/// Descriptor for `Capabilities`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capabilitiesDescriptor = $convert.base64Decode(
    'CgxDYXBhYmlsaXRpZXMSGQoIY2FuX3ZpZXcYASABKAhSB2NhblZpZXcSQAocY2FuX2FkbWluaX'
    'N0cmF0ZV9wZXJtaXNzaW9ucxgCIAEoCFIaY2FuQWRtaW5pc3RyYXRlUGVybWlzc2lvbnMSKgoR'
    'Y2FuX2VkaXRfbWV0YWRhdGEYBCABKAhSD2NhbkVkaXRNZXRhZGF0YRIkCg5jYW5fZWRpdF9pdG'
    'VtcxgFIAEoCFIMY2FuRWRpdEl0ZW1zEjIKFWNhbl9jYW5jZWxfbWVtYmVyc2hpcBgGIAEoCFIT'
    'Y2FuQ2FuY2VsTWVtYmVyc2hpcBJPChBncmFudGFibGVfbGV2ZWxzGAcgAygOMiQuc3BvdGlmeS'
    '5wbGF5bGlzdC52Mi5QZXJtaXNzaW9uTGV2ZWxSD2dyYW50YWJsZUxldmVscxJuChtsaXN0X2F0'
    'dHJpYnV0ZV9jYXBhYmlsaXRpZXMYCCABKAsyLi5zcG90aWZ5LnBsYXlsaXN0LnYyLkxpc3RBdH'
    'RyaWJ1dGVDYXBhYmlsaXRpZXNSGWxpc3RBdHRyaWJ1dGVDYXBhYmlsaXRpZXM=');

@$core.Deprecated('Use listAttributeCapabilitiesDescriptor instead')
const ListAttributeCapabilities$json = {
  '1': 'ListAttributeCapabilities',
  '2': [
    {
      '1': 'name',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.AttributeCapabilities',
      '10': 'name'
    },
    {
      '1': 'description',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.AttributeCapabilities',
      '10': 'description'
    },
    {
      '1': 'picture',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.AttributeCapabilities',
      '10': 'picture'
    },
    {
      '1': 'collaborative',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.AttributeCapabilities',
      '10': 'collaborative'
    },
  ],
};

/// Descriptor for `ListAttributeCapabilities`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listAttributeCapabilitiesDescriptor = $convert.base64Decode(
    'ChlMaXN0QXR0cmlidXRlQ2FwYWJpbGl0aWVzEj4KBG5hbWUYASABKAsyKi5zcG90aWZ5LnBsYX'
    'lsaXN0LnYyLkF0dHJpYnV0ZUNhcGFiaWxpdGllc1IEbmFtZRJMCgtkZXNjcmlwdGlvbhgCIAEo'
    'CzIqLnNwb3RpZnkucGxheWxpc3QudjIuQXR0cmlidXRlQ2FwYWJpbGl0aWVzUgtkZXNjcmlwdG'
    'lvbhJECgdwaWN0dXJlGAMgASgLMiouc3BvdGlmeS5wbGF5bGlzdC52Mi5BdHRyaWJ1dGVDYXBh'
    'YmlsaXRpZXNSB3BpY3R1cmUSUAoNY29sbGFib3JhdGl2ZRgEIAEoCzIqLnNwb3RpZnkucGxheW'
    'xpc3QudjIuQXR0cmlidXRlQ2FwYWJpbGl0aWVzUg1jb2xsYWJvcmF0aXZl');

@$core.Deprecated('Use attributeCapabilitiesDescriptor instead')
const AttributeCapabilities$json = {
  '1': 'AttributeCapabilities',
  '2': [
    {'1': 'can_edit', '3': 1, '4': 1, '5': 8, '10': 'canEdit'},
  ],
};

/// Descriptor for `AttributeCapabilities`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List attributeCapabilitiesDescriptor =
    $convert.base64Decode(
        'ChVBdHRyaWJ1dGVDYXBhYmlsaXRpZXMSGQoIY2FuX2VkaXQYASABKAhSB2NhbkVkaXQ=');
