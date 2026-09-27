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
  ],
};

/// Descriptor for `OpKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List opKindDescriptor = $convert.base64Decode(
    'CgZPcEtpbmQSEwoPT1BfS0lORF9VTktOT1dOEAASBwoDQUREEAISBwoDUkVNEAMSBwoDTU9WEA'
    'QSGgoWVVBEQVRFX0lURU1fQVRUUklCVVRFUxAFEhoKFlVQREFURV9MSVNUX0FUVFJJQlVURVMQ'
    'Bg==');

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
    {
      '1': 'ops',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.playlist.v2.Op',
      '10': 'ops'
    },
  ],
};

/// Descriptor for `Diff`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diffDescriptor = $convert.base64Decode(
    'CgREaWZmEikKA29wcxgBIAMoCzIXLnNwb3RpZnkucGxheWxpc3QudjIuT3BSA29wcw==');

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
    {'1': 'from_index', '3': 2, '4': 1, '5': 5, '10': 'fromIndex'},
    {'1': 'to_index', '3': 3, '4': 1, '5': 5, '10': 'toIndex'},
    {'1': 'length', '3': 4, '4': 1, '5': 5, '10': 'length'},
    {
      '1': 'items',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.spotify.playlist.v2.Item',
      '10': 'items'
    },
    {
      '1': 'list_attributes',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.ListAttributes',
      '10': 'listAttributes'
    },
    {
      '1': 'item_attributes',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.spotify.playlist.v2.ItemAttributes',
      '10': 'itemAttributes'
    },
  ],
};

/// Descriptor for `Op`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List opDescriptor = $convert.base64Decode(
    'CgJPcBIvCgRraW5kGAEgASgOMhsuc3BvdGlmeS5wbGF5bGlzdC52Mi5PcEtpbmRSBGtpbmQSHQ'
    'oKZnJvbV9pbmRleBgCIAEoBVIJZnJvbUluZGV4EhkKCHRvX2luZGV4GAMgASgFUgd0b0luZGV4'
    'EhYKBmxlbmd0aBgEIAEoBVIGbGVuZ3RoEi8KBWl0ZW1zGAUgAygLMhkuc3BvdGlmeS5wbGF5bG'
    'lzdC52Mi5JdGVtUgVpdGVtcxJMCg9saXN0X2F0dHJpYnV0ZXMYBiABKAsyIy5zcG90aWZ5LnBs'
    'YXlsaXN0LnYyLkxpc3RBdHRyaWJ1dGVzUg5saXN0QXR0cmlidXRlcxJMCg9pdGVtX2F0dHJpYn'
    'V0ZXMYByABKAsyIy5zcG90aWZ5LnBsYXlsaXN0LnYyLkl0ZW1BdHRyaWJ1dGVzUg5pdGVtQXR0'
    'cmlidXRlcw==');
