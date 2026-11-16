// 1:1 Replicated Spotify Esperanto Common Messages Json Descriptors
// Sources:
// - Decompiled Java: `com/spotify/connect/esperanto/proto/CommonMessages.java`
// - `liborbit-jni-spotify_memdump.so` offset `0x3a79bc` (`common_messages.proto`)

// This is a generated file - do not edit.
//
// Generated from protos/esperanto/common_messages.proto.

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

@$core.Deprecated('Use statusDescriptor instead')
const Status$json = {
  '1': 'Status',
  '2': [
    {'1': 'OK', '2': 0},
    {'1': 'NOT_FOUND', '2': 1},
    {'1': 'INVALID_ARGUMENTS', '2': 2},
    {'1': 'BACKEND_FAILURE', '2': 3},
    {'1': 'UNIMPLEMENTED', '2': 4},
  ],
};

/// Descriptor for `Status`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List statusDescriptor = $convert.base64Decode(
    'CgZTdGF0dXMSBgoCT0sQABINCglOT1RfRk9VTkQQARIVChFJTlZBTElEX0FSR1VNRU5UUxACEh'
    'MKD0JBQ0tFTkRfRkFJTFVSRRADEhEKDVVOSU1QTEVNRU5URUQQBA==');

@$core.Deprecated('Use loggingParamsDescriptor instead')
const LoggingParams$json = {
  '1': 'LoggingParams',
  '2': [
    {
      '1': 'command_initiated_time',
      '3': 1,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'commandInitiatedTime',
      '17': true
    },
    {
      '1': 'command_received_time',
      '3': 2,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'commandReceivedTime',
      '17': true
    },
    {'1': 'page_instance_ids', '3': 3, '4': 3, '5': 9, '10': 'pageInstanceIds'},
    {'1': 'interaction_ids', '3': 4, '4': 3, '5': 9, '10': 'interactionIds'},
    {
      '1': 'command_id',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'commandId',
      '17': true
    },
    {
      '1': 'feature_identifier',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'featureIdentifier',
      '17': true
    },
  ],
  '8': [
    {'1': '_command_initiated_time'},
    {'1': '_command_received_time'},
    {'1': '_command_id'},
    {'1': '_feature_identifier'},
  ],
};

/// Descriptor for `LoggingParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loggingParamsDescriptor = $convert.base64Decode(
    'Cg1Mb2dnaW5nUGFyYW1zEjkKFmNvbW1hbmRfaW5pdGlhdGVkX3RpbWUYASABKANIAFIUY29tbW'
    'FuZEluaXRpYXRlZFRpbWWIAQESNwoVY29tbWFuZF9yZWNlaXZlZF90aW1lGAIgASgDSAFSE2Nv'
    'bW1hbmRSZWNlaXZlZFRpbWWIAQESKgoRcGFnZV9pbnN0YW5jZV9pZHMYAyADKAlSD3BhZ2VJbn'
    'N0YW5jZUlkcxInCg9pbnRlcmFjdGlvbl9pZHMYBCADKAlSDmludGVyYWN0aW9uSWRzEiIKCmNv'
    'bW1hbmRfaWQYBSABKAlIAlIJY29tbWFuZElkiAEBEjIKEmZlYXR1cmVfaWRlbnRpZmllchgGIA'
    'EoCUgDUhFmZWF0dXJlSWRlbnRpZmllcogBAUIZChdfY29tbWFuZF9pbml0aWF0ZWRfdGltZUIY'
    'ChZfY29tbWFuZF9yZWNlaXZlZF90aW1lQg0KC19jb21tYW5kX2lkQhUKE19mZWF0dXJlX2lkZW'
    '50aWZpZXI=');

@$core.Deprecated('Use statusResponseDescriptor instead')
const StatusResponse$json = {
  '1': 'StatusResponse',
  '2': [
    {
      '1': 'status',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.spotify.connect.esperanto.proto.Status',
      '10': 'status'
    },
  ],
};

/// Descriptor for `StatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statusResponseDescriptor = $convert.base64Decode(
    'Cg5TdGF0dXNSZXNwb25zZRI/CgZzdGF0dXMYASABKA4yJy5zcG90aWZ5LmNvbm5lY3QuZXNwZX'
    'JhbnRvLnByb3RvLlN0YXR1c1IGc3RhdHVz');
