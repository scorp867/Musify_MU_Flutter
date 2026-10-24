// This is a generated file - do not edit.
//
// Generated from es_logging_params.proto.

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

@$core.Deprecated('Use loggingParamsDescriptor instead')
const LoggingParams$json = {
  '1': 'LoggingParams',
  '2': [
    {
      '1': 'command_initiated_time',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.OptionalInt64',
      '10': 'commandInitiatedTime'
    },
    {
      '1': 'command_received_time',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.OptionalInt64',
      '10': 'commandReceivedTime'
    },
    {'1': 'page_instance_ids', '3': 3, '4': 3, '5': 9, '10': 'pageInstanceIds'},
    {'1': 'interaction_ids', '3': 4, '4': 3, '5': 9, '10': 'interactionIds'},
  ],
};

/// Descriptor for `LoggingParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loggingParamsDescriptor = $convert.base64Decode(
    'Cg1Mb2dnaW5nUGFyYW1zEmMKFmNvbW1hbmRfaW5pdGlhdGVkX3RpbWUYASABKAsyLS5zcG90aW'
    'Z5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uT3B0aW9uYWxJbnQ2NFIUY29tbWFuZEluaXRpYXRl'
    'ZFRpbWUSYQoVY29tbWFuZF9yZWNlaXZlZF90aW1lGAIgASgLMi0uc3BvdGlmeS5wbGF5ZXIuZX'
    'NwZXJhbnRvLnByb3RvLk9wdGlvbmFsSW50NjRSE2NvbW1hbmRSZWNlaXZlZFRpbWUSKgoRcGFn'
    'ZV9pbnN0YW5jZV9pZHMYAyADKAlSD3BhZ2VJbnN0YW5jZUlkcxInCg9pbnRlcmFjdGlvbl9pZH'
    'MYBCADKAlSDmludGVyYWN0aW9uSWRz');
