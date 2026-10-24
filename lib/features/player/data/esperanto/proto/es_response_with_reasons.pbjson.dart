// This is a generated file - do not edit.
//
// Generated from es_response_with_reasons.proto.

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

@$core.Deprecated('Use responseWithReasonsDescriptor instead')
const ResponseWithReasons$json = {
  '1': 'ResponseWithReasons',
  '2': [
    {
      '1': 'error',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.spotify.player.esperanto.proto.ResponseWithReasons.Error',
      '10': 'error'
    },
    {'1': 'reasons', '3': 2, '4': 1, '5': 9, '10': 'reasons'},
  ],
  '4': [ResponseWithReasons_Error$json],
};

@$core.Deprecated('Use responseWithReasonsDescriptor instead')
const ResponseWithReasons_Error$json = {
  '1': 'Error',
  '2': [
    {'1': 'OK', '2': 0},
    {'1': 'FORBIDDEN', '2': 1},
    {'1': 'NOT_FOUND', '2': 2},
    {'1': 'CONFLICT', '2': 3},
  ],
};

/// Descriptor for `ResponseWithReasons`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseWithReasonsDescriptor = $convert.base64Decode(
    'ChNSZXNwb25zZVdpdGhSZWFzb25zEk8KBWVycm9yGAEgASgOMjkuc3BvdGlmeS5wbGF5ZXIuZX'
    'NwZXJhbnRvLnByb3RvLlJlc3BvbnNlV2l0aFJlYXNvbnMuRXJyb3JSBWVycm9yEhgKB3JlYXNv'
    'bnMYAiABKAlSB3JlYXNvbnMiOwoFRXJyb3ISBgoCT0sQABINCglGT1JCSURERU4QARINCglOT1'
    'RfRk9VTkQQAhIMCghDT05GTElDVBAD');
