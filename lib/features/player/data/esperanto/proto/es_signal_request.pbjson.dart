// This is a generated file - do not edit.
//
// Generated from es_signal_request.proto.

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

@$core.Deprecated('Use signalRequestDescriptor instead')
const SignalRequest$json = {
  '1': 'SignalRequest',
  '2': [
    {'1': 'signal_id', '3': 1, '4': 1, '5': 9, '10': 'signalId'},
    {'1': 'parameters', '3': 2, '4': 1, '5': 9, '10': 'parameters'},
    {
      '1': 'options',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.CommandOptions',
      '10': 'options'
    },
    {
      '1': 'logging_params',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.LoggingParams',
      '10': 'loggingParams'
    },
  ],
};

/// Descriptor for `SignalRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signalRequestDescriptor = $convert.base64Decode(
    'Cg1TaWduYWxSZXF1ZXN0EhsKCXNpZ25hbF9pZBgBIAEoCVIIc2lnbmFsSWQSHgoKcGFyYW1ldG'
    'VycxgCIAEoCVIKcGFyYW1ldGVycxJICgdvcHRpb25zGAMgASgLMi4uc3BvdGlmeS5wbGF5ZXIu'
    'ZXNwZXJhbnRvLnByb3RvLkNvbW1hbmRPcHRpb25zUgdvcHRpb25zElQKDmxvZ2dpbmdfcGFyYW'
    '1zGAQgASgLMi0uc3BvdGlmeS5wbGF5ZXIuZXNwZXJhbnRvLnByb3RvLkxvZ2dpbmdQYXJhbXNS'
    'DWxvZ2dpbmdQYXJhbXM=');
