// This is a generated file - do not edit.
//
// Generated from spotify/playlist/playlist_detail.proto.

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

@$core.Deprecated('Use opKindDescriptor instead')
const OpKind$json = {
  '1': 'OpKind',
  '2': [
    {'1': 'OP_KIND_UNKNOWN', '2': 0},
    {'1': 'ADD', '2': 2},
    {'1': 'REM', '2': 3},
    {'1': 'MOV', '2': 4},
    {'1': 'UPDATE_ITEM_ATTRIBUTES', '2': 5},
    {'1': 'UPDATE_LIST_ATTRIBUTES', '2': 6},
    {'1': 'UPDATE_ITEM_URIS', '2': 7},
  ],
};

/// Descriptor for `OpKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List opKindDescriptor = $convert.base64Decode(
    'CgZPcEtpbmQSEwoPT1BfS0lORF9VTktOT1dOEAASBwoDQUREEAISBwoDUkVNEAMSBwoDTU9WEA'
    'QSGgoWVVBEQVRFX0lURU1fQVRUUklCVVRFUxAFEhoKFlVQREFURV9MSVNUX0FUVFJJQlVURVMQ'
    'BhIUChBVUERBVEVfSVRFTV9VUklTEAc=');

@$core.Deprecated('Use listAttributeKindDescriptor instead')
const ListAttributeKind$json = {
  '1': 'ListAttributeKind',
  '2': [
    {'1': 'LIST_UNKNOWN', '2': 0},
    {'1': 'LIST_NAME', '2': 1},
    {'1': 'LIST_DESCRIPTION', '2': 2},
    {'1': 'LIST_PICTURE', '2': 3},
    {'1': 'LIST_COLLABORATIVE', '2': 4},
    {'1': 'LIST_PL3_VERSION', '2': 5},
    {'1': 'LIST_DELETED_BY_OWNER', '2': 6},
    {'1': 'LIST_CLIENT_ID', '2': 10},
    {'1': 'LIST_FORMAT', '2': 11},
    {'1': 'LIST_FORMAT_ATTRIBUTES', '2': 12},
    {'1': 'LIST_PICTURE_SIZE', '2': 13},
  ],
};

/// Descriptor for `ListAttributeKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List listAttributeKindDescriptor = $convert.base64Decode(
    'ChFMaXN0QXR0cmlidXRlS2luZBIQCgxMSVNUX1VOS05PV04QABINCglMSVNUX05BTUUQARIUCh'
    'BMSVNUX0RFU0NSSVBUSU9OEAISEAoMTElTVF9QSUNUVVJFEAMSFgoSTElTVF9DT0xMQUJPUkFU'
    'SVZFEAQSFAoQTElTVF9QTDNfVkVSU0lPThAFEhkKFUxJU1RfREVMRVRFRF9CWV9PV05FUhAGEh'
    'IKDkxJU1RfQ0xJRU5UX0lEEAoSDwoLTElTVF9GT1JNQVQQCxIaChZMSVNUX0ZPUk1BVF9BVFRS'
    'SUJVVEVTEAwSFQoRTElTVF9QSUNUVVJFX1NJWkUQDQ==');

@$core.Deprecated('Use itemAttributeKindDescriptor instead')
const ItemAttributeKind$json = {
  '1': 'ItemAttributeKind',
  '2': [
    {'1': 'ITEM_UNKNOWN', '2': 0},
    {'1': 'ITEM_ADDED_BY', '2': 1},
    {'1': 'ITEM_TIMESTAMP', '2': 2},
    {'1': 'ITEM_SEEN_AT', '2': 9},
    {'1': 'ITEM_PUBLIC', '2': 10},
    {'1': 'ITEM_FORMAT_ATTRIBUTES', '2': 11},
    {'1': 'ITEM_ID', '2': 12},
  ],
};

/// Descriptor for `ItemAttributeKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List itemAttributeKindDescriptor = $convert.base64Decode(
    'ChFJdGVtQXR0cmlidXRlS2luZBIQCgxJVEVNX1VOS05PV04QABIRCg1JVEVNX0FEREVEX0JZEA'
    'ESEgoOSVRFTV9USU1FU1RBTVAQAhIQCgxJVEVNX1NFRU5fQVQQCRIPCgtJVEVNX1BVQkxJQxAK'
    'EhoKFklURU1fRk9STUFUX0FUVFJJQlVURVMQCxILCgdJVEVNX0lEEAw=');

@$core.Deprecated('Use playlistResponseDescriptor instead')
const PlaylistResponse$json = {
  '1': 'PlaylistResponse',
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
    {
      '1': 'diff',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.Diff',
      '10': 'diff'
    },
    {
      '1': 'sync_result',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.Diff',
      '10': 'syncResult'
    },
    {
      '1': 'resulting_revisions',
      '3': 8,
      '4': 3,
      '5': 12,
      '10': 'resultingRevisions'
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
    {
      '1': 'capabilities',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.Capabilities',
      '10': 'capabilities'
    },
    {
      '1': 'geoblock',
      '3': 19,
      '4': 3,
      '5': 14,
      '6': '.spotify.playlist.v2.GeoblockBlockingType',
      '10': 'geoblock'
    },
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

/// Descriptor for `PlaylistResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playlistResponseDescriptor = $convert.base64Decode(
    'ChBQbGF5bGlzdFJlc3BvbnNlEhoKCHJldmlzaW9uGAEgASgMUghyZXZpc2lvbhIWCgZsZW5ndG'
    'gYAiABKAVSBmxlbmd0aBJDCgphdHRyaWJ1dGVzGAMgASgLMiMuc3BvdGlmeS5wbGF5bGlzdC52'
    'Mi5MaXN0QXR0cmlidXRlc1IKYXR0cmlidXRlcxI6Cghjb250ZW50cxgFIAEoCzIeLnNwb3RpZn'
    'kucGxheWxpc3QudjIuTGlzdEl0ZW1zUghjb250ZW50cxItCgRkaWZmGAYgASgLMhkuc3BvdGlm'
    'eS5wbGF5bGlzdC52Mi5EaWZmUgRkaWZmEjoKC3N5bmNfcmVzdWx0GAcgASgLMhkuc3BvdGlmeS'
    '5wbGF5bGlzdC52Mi5EaWZmUgpzeW5jUmVzdWx0Ei8KE3Jlc3VsdGluZ19yZXZpc2lvbnMYCCAD'
    'KAxSEnJlc3VsdGluZ1JldmlzaW9ucxIlCg5tdWx0aXBsZV9oZWFkcxgJIAEoCFINbXVsdGlwbG'
    'VIZWFkcxIcCgp1cF90b19kYXRlGAogASgIUgh1cFRvRGF0ZRIWCgZub25jZXMYDiADKANSBm5v'
    'bmNlcxIcCgl0aW1lc3RhbXAYDyABKANSCXRpbWVzdGFtcBIlCg5vd25lcl91c2VybmFtZRgQIA'
    'EoCVINb3duZXJVc2VybmFtZRI2ChdhYnVzZV9yZXBvcnRpbmdfZW5hYmxlZBgRIAEoCFIVYWJ1'
    'c2VSZXBvcnRpbmdFbmFibGVkEkUKDGNhcGFiaWxpdGllcxgSIAEoCzIhLnNwb3RpZnkucGxheW'
    'xpc3QudjIuQ2FwYWJpbGl0aWVzUgxjYXBhYmlsaXRpZXMSRQoIZ2VvYmxvY2sYEyADKA4yKS5z'
    'cG90aWZ5LnBsYXlsaXN0LnYyLkdlb2Jsb2NrQmxvY2tpbmdUeXBlUghnZW9ibG9jaxI0ChZjaG'
    'FuZ2VzX3JlcXVpcmVfcmVzeW5jGBQgASgIUhRjaGFuZ2VzUmVxdWlyZVJlc3luYxIdCgpjcmVh'
    'dGVkX2F0GBUgASgDUgljcmVhdGVkQXQ=');

@$core.Deprecated('Use diffDescriptor instead')
const Diff$json = {
  '1': 'Diff',
  '2': [
    {'1': 'from_revision', '3': 1, '4': 1, '5': 12, '10': 'fromRevision'},
    {
      '1': 'ops',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.playlist.v2.Op',
      '10': 'ops'
    },
    {'1': 'to_revision', '3': 3, '4': 1, '5': 12, '10': 'toRevision'},
    {
      '1': 'available_signals',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.AvailableSignals',
      '10': 'availableSignals'
    },
  ],
};

/// Descriptor for `Diff`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diffDescriptor = $convert.base64Decode(
    'CgREaWZmEiMKDWZyb21fcmV2aXNpb24YASABKAxSDGZyb21SZXZpc2lvbhIpCgNvcHMYAiADKA'
    'syFy5zcG90aWZ5LnBsYXlsaXN0LnYyLk9wUgNvcHMSHwoLdG9fcmV2aXNpb24YAyABKAxSCnRv'
    'UmV2aXNpb24SUgoRYXZhaWxhYmxlX3NpZ25hbHMYBCABKAsyJS5zcG90aWZ5LnBsYXlsaXN0Ln'
    'YyLkF2YWlsYWJsZVNpZ25hbHNSEGF2YWlsYWJsZVNpZ25hbHM=');

@$core.Deprecated('Use opDescriptor instead')
const Op$json = {
  '1': 'Op',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.spotify.playlist.v2.OpKind',
      '10': 'kind'
    },
    {
      '1': 'add',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.Add',
      '10': 'add'
    },
    {
      '1': 'rem',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.Rem',
      '10': 'rem'
    },
    {
      '1': 'mov',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.Mov',
      '10': 'mov'
    },
    {
      '1': 'update_item_attributes',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.UpdateItemAttributes',
      '10': 'updateItemAttributes'
    },
    {
      '1': 'update_list_attributes',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.UpdateListAttributes',
      '10': 'updateListAttributes'
    },
    {
      '1': 'update_item_uris',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.UpdateItemUris',
      '10': 'updateItemUris'
    },
  ],
};

/// Descriptor for `Op`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List opDescriptor = $convert.base64Decode(
    'CgJPcBIvCgRraW5kGAEgASgOMhsuc3BvdGlmeS5wbGF5bGlzdC52Mi5PcEtpbmRSBGtpbmQSKg'
    'oDYWRkGAIgASgLMhguc3BvdGlmeS5wbGF5bGlzdC52Mi5BZGRSA2FkZBIqCgNyZW0YAyABKAsy'
    'GC5zcG90aWZ5LnBsYXlsaXN0LnYyLlJlbVIDcmVtEioKA21vdhgEIAEoCzIYLnNwb3RpZnkucG'
    'xheWxpc3QudjIuTW92UgNtb3YSXwoWdXBkYXRlX2l0ZW1fYXR0cmlidXRlcxgFIAEoCzIpLnNw'
    'b3RpZnkucGxheWxpc3QudjIuVXBkYXRlSXRlbUF0dHJpYnV0ZXNSFHVwZGF0ZUl0ZW1BdHRyaW'
    'J1dGVzEl8KFnVwZGF0ZV9saXN0X2F0dHJpYnV0ZXMYBiABKAsyKS5zcG90aWZ5LnBsYXlsaXN0'
    'LnYyLlVwZGF0ZUxpc3RBdHRyaWJ1dGVzUhR1cGRhdGVMaXN0QXR0cmlidXRlcxJNChB1cGRhdG'
    'VfaXRlbV91cmlzGAcgASgLMiMuc3BvdGlmeS5wbGF5bGlzdC52Mi5VcGRhdGVJdGVtVXJpc1IO'
    'dXBkYXRlSXRlbVVyaXM=');

@$core.Deprecated('Use addDescriptor instead')
const Add$json = {
  '1': 'Add',
  '2': [
    {'1': 'from_index', '3': 1, '4': 1, '5': 5, '10': 'fromIndex'},
    {
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.playlist.v2.Item',
      '10': 'items'
    },
    {'1': 'add_last', '3': 4, '4': 1, '5': 8, '10': 'addLast'},
    {'1': 'add_first', '3': 5, '4': 1, '5': 8, '10': 'addFirst'},
    {
      '1': 'add_before_item',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.Item',
      '10': 'addBeforeItem'
    },
    {
      '1': 'add_after_item',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.Item',
      '10': 'addAfterItem'
    },
  ],
};

/// Descriptor for `Add`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addDescriptor = $convert.base64Decode(
    'CgNBZGQSHQoKZnJvbV9pbmRleBgBIAEoBVIJZnJvbUluZGV4Ei8KBWl0ZW1zGAIgAygLMhkuc3'
    'BvdGlmeS5wbGF5bGlzdC52Mi5JdGVtUgVpdGVtcxIZCghhZGRfbGFzdBgEIAEoCFIHYWRkTGFz'
    'dBIbCglhZGRfZmlyc3QYBSABKAhSCGFkZEZpcnN0EkEKD2FkZF9iZWZvcmVfaXRlbRgGIAEoCz'
    'IZLnNwb3RpZnkucGxheWxpc3QudjIuSXRlbVINYWRkQmVmb3JlSXRlbRI/Cg5hZGRfYWZ0ZXJf'
    'aXRlbRgHIAEoCzIZLnNwb3RpZnkucGxheWxpc3QudjIuSXRlbVIMYWRkQWZ0ZXJJdGVt');

@$core.Deprecated('Use remDescriptor instead')
const Rem$json = {
  '1': 'Rem',
  '2': [
    {'1': 'from_index', '3': 1, '4': 1, '5': 5, '10': 'fromIndex'},
    {'1': 'length', '3': 2, '4': 1, '5': 5, '10': 'length'},
    {
      '1': 'items',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.spotify.playlist.v2.Item',
      '10': 'items'
    },
    {'1': 'items_as_key', '3': 7, '4': 1, '5': 8, '10': 'itemsAsKey'},
  ],
};

/// Descriptor for `Rem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List remDescriptor = $convert.base64Decode(
    'CgNSZW0SHQoKZnJvbV9pbmRleBgBIAEoBVIJZnJvbUluZGV4EhYKBmxlbmd0aBgCIAEoBVIGbG'
    'VuZ3RoEi8KBWl0ZW1zGAMgAygLMhkuc3BvdGlmeS5wbGF5bGlzdC52Mi5JdGVtUgVpdGVtcxIg'
    'CgxpdGVtc19hc19rZXkYByABKAhSCml0ZW1zQXNLZXk=');

@$core.Deprecated('Use movDescriptor instead')
const Mov$json = {
  '1': 'Mov',
  '2': [
    {'1': 'from_index', '3': 1, '4': 1, '5': 5, '10': 'fromIndex'},
    {'1': 'length', '3': 2, '4': 1, '5': 5, '10': 'length'},
    {'1': 'to_index', '3': 3, '4': 1, '5': 5, '10': 'toIndex'},
    {
      '1': 'items',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.spotify.playlist.v2.Item',
      '10': 'items'
    },
    {
      '1': 'add_before_item',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.Item',
      '10': 'addBeforeItem'
    },
    {
      '1': 'add_after_item',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.Item',
      '10': 'addAfterItem'
    },
    {'1': 'add_first', '3': 7, '4': 1, '5': 8, '10': 'addFirst'},
    {'1': 'add_last', '3': 8, '4': 1, '5': 8, '10': 'addLast'},
  ],
};

/// Descriptor for `Mov`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List movDescriptor = $convert.base64Decode(
    'CgNNb3YSHQoKZnJvbV9pbmRleBgBIAEoBVIJZnJvbUluZGV4EhYKBmxlbmd0aBgCIAEoBVIGbG'
    'VuZ3RoEhkKCHRvX2luZGV4GAMgASgFUgd0b0luZGV4Ei8KBWl0ZW1zGAQgAygLMhkuc3BvdGlm'
    'eS5wbGF5bGlzdC52Mi5JdGVtUgVpdGVtcxJBCg9hZGRfYmVmb3JlX2l0ZW0YBSABKAsyGS5zcG'
    '90aWZ5LnBsYXlsaXN0LnYyLkl0ZW1SDWFkZEJlZm9yZUl0ZW0SPwoOYWRkX2FmdGVyX2l0ZW0Y'
    'BiABKAsyGS5zcG90aWZ5LnBsYXlsaXN0LnYyLkl0ZW1SDGFkZEFmdGVySXRlbRIbCglhZGRfZm'
    'lyc3QYByABKAhSCGFkZEZpcnN0EhkKCGFkZF9sYXN0GAggASgIUgdhZGRMYXN0');

@$core.Deprecated('Use updateListAttributesDescriptor instead')
const UpdateListAttributes$json = {
  '1': 'UpdateListAttributes',
  '2': [
    {
      '1': 'new_attributes',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.ListAttributesPartialState',
      '10': 'newAttributes'
    },
    {
      '1': 'old_attributes',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.ListAttributesPartialState',
      '10': 'oldAttributes'
    },
  ],
};

/// Descriptor for `UpdateListAttributes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateListAttributesDescriptor = $convert.base64Decode(
    'ChRVcGRhdGVMaXN0QXR0cmlidXRlcxJWCg5uZXdfYXR0cmlidXRlcxgBIAEoCzIvLnNwb3RpZn'
    'kucGxheWxpc3QudjIuTGlzdEF0dHJpYnV0ZXNQYXJ0aWFsU3RhdGVSDW5ld0F0dHJpYnV0ZXMS'
    'VgoOb2xkX2F0dHJpYnV0ZXMYAiABKAsyLy5zcG90aWZ5LnBsYXlsaXN0LnYyLkxpc3RBdHRyaW'
    'J1dGVzUGFydGlhbFN0YXRlUg1vbGRBdHRyaWJ1dGVz');

@$core.Deprecated('Use updateItemAttributesDescriptor instead')
const UpdateItemAttributes$json = {
  '1': 'UpdateItemAttributes',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 5, '10': 'index'},
    {
      '1': 'new_attributes',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.ItemAttributesPartialState',
      '10': 'newAttributes'
    },
    {
      '1': 'old_attributes',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.ItemAttributesPartialState',
      '10': 'oldAttributes'
    },
    {
      '1': 'item',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.Item',
      '10': 'item'
    },
  ],
};

/// Descriptor for `UpdateItemAttributes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateItemAttributesDescriptor = $convert.base64Decode(
    'ChRVcGRhdGVJdGVtQXR0cmlidXRlcxIUCgVpbmRleBgBIAEoBVIFaW5kZXgSVgoObmV3X2F0dH'
    'JpYnV0ZXMYAiABKAsyLy5zcG90aWZ5LnBsYXlsaXN0LnYyLkl0ZW1BdHRyaWJ1dGVzUGFydGlh'
    'bFN0YXRlUg1uZXdBdHRyaWJ1dGVzElYKDm9sZF9hdHRyaWJ1dGVzGAMgASgLMi8uc3BvdGlmeS'
    '5wbGF5bGlzdC52Mi5JdGVtQXR0cmlidXRlc1BhcnRpYWxTdGF0ZVINb2xkQXR0cmlidXRlcxIt'
    'CgRpdGVtGAQgASgLMhkuc3BvdGlmeS5wbGF5bGlzdC52Mi5JdGVtUgRpdGVt');

@$core.Deprecated('Use updateItemUrisDescriptor instead')
const UpdateItemUris$json = {
  '1': 'UpdateItemUris',
  '2': [
    {
      '1': 'uri_replacements',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.playlist.v2.UriReplacement',
      '10': 'uriReplacements'
    },
  ],
};

/// Descriptor for `UpdateItemUris`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateItemUrisDescriptor = $convert.base64Decode(
    'Cg5VcGRhdGVJdGVtVXJpcxJOChB1cmlfcmVwbGFjZW1lbnRzGAEgAygLMiMuc3BvdGlmeS5wbG'
    'F5bGlzdC52Mi5VcmlSZXBsYWNlbWVudFIPdXJpUmVwbGFjZW1lbnRz');

@$core.Deprecated('Use uriReplacementDescriptor instead')
const UriReplacement$json = {
  '1': 'UriReplacement',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 5, '10': 'index'},
    {
      '1': 'item',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.Item',
      '10': 'item'
    },
    {'1': 'new_uri', '3': 3, '4': 1, '5': 9, '10': 'newUri'},
  ],
};

/// Descriptor for `UriReplacement`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uriReplacementDescriptor = $convert.base64Decode(
    'Cg5VcmlSZXBsYWNlbWVudBIUCgVpbmRleBgBIAEoBVIFaW5kZXgSLQoEaXRlbRgCIAEoCzIZLn'
    'Nwb3RpZnkucGxheWxpc3QudjIuSXRlbVIEaXRlbRIXCgduZXdfdXJpGAMgASgJUgZuZXdVcmk=');

@$core.Deprecated('Use listAttributesPartialStateDescriptor instead')
const ListAttributesPartialState$json = {
  '1': 'ListAttributesPartialState',
  '2': [
    {
      '1': 'values',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.ListAttributes',
      '10': 'values'
    },
    {
      '1': 'no_value',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.spotify.playlist.v2.ListAttributeKind',
      '10': 'noValue'
    },
  ],
};

/// Descriptor for `ListAttributesPartialState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listAttributesPartialStateDescriptor =
    $convert.base64Decode(
        'ChpMaXN0QXR0cmlidXRlc1BhcnRpYWxTdGF0ZRI7CgZ2YWx1ZXMYASABKAsyIy5zcG90aWZ5Ln'
        'BsYXlsaXN0LnYyLkxpc3RBdHRyaWJ1dGVzUgZ2YWx1ZXMSQQoIbm9fdmFsdWUYAiADKA4yJi5z'
        'cG90aWZ5LnBsYXlsaXN0LnYyLkxpc3RBdHRyaWJ1dGVLaW5kUgdub1ZhbHVl');

@$core.Deprecated('Use itemAttributesPartialStateDescriptor instead')
const ItemAttributesPartialState$json = {
  '1': 'ItemAttributesPartialState',
  '2': [
    {
      '1': 'values',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.ItemAttributes',
      '10': 'values'
    },
    {
      '1': 'no_value',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.spotify.playlist.v2.ItemAttributeKind',
      '10': 'noValue'
    },
  ],
};

/// Descriptor for `ItemAttributesPartialState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List itemAttributesPartialStateDescriptor =
    $convert.base64Decode(
        'ChpJdGVtQXR0cmlidXRlc1BhcnRpYWxTdGF0ZRI7CgZ2YWx1ZXMYASABKAsyIy5zcG90aWZ5Ln'
        'BsYXlsaXN0LnYyLkl0ZW1BdHRyaWJ1dGVzUgZ2YWx1ZXMSQQoIbm9fdmFsdWUYAiADKA4yJi5z'
        'cG90aWZ5LnBsYXlsaXN0LnYyLkl0ZW1BdHRyaWJ1dGVLaW5kUgdub1ZhbHVl');

@$core.Deprecated('Use availableSignalsDescriptor instead')
const AvailableSignals$json = {
  '1': 'AvailableSignals',
};

/// Descriptor for `AvailableSignals`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List availableSignalsDescriptor =
    $convert.base64Decode('ChBBdmFpbGFibGVTaWduYWxz');
