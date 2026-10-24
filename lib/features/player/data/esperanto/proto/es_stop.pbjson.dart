// This is a generated file - do not edit.
//
// Generated from es_stop.proto.

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

@$core.Deprecated('Use stopRequestDescriptor instead')
const StopRequest$json = {
  '1': 'StopRequest',
  '2': [
    {
      '1': 'options',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.CommandOptions',
      '10': 'options'
    },
    {
      '1': 'reason',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.spotify.player.esperanto.proto.StopRequest.Reason',
      '10': 'reason'
    },
    {
      '1': 'logging_params',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.LoggingParams',
      '10': 'loggingParams'
    },
  ],
  '4': [StopRequest_Reason$json],
};

@$core.Deprecated('Use stopRequestDescriptor instead')
const StopRequest_Reason$json = {
  '1': 'Reason',
  '2': [
    {'1': 'INTERACTIVE', '2': 0},
    {'1': 'REMOTE_TRANSFER', '2': 1},
    {'1': 'SHUTDOWN', '2': 2},
  ],
};

/// Descriptor for `StopRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stopRequestDescriptor = $convert.base64Decode(
    'CgtTdG9wUmVxdWVzdBJICgdvcHRpb25zGAEgASgLMi4uc3BvdGlmeS5wbGF5ZXIuZXNwZXJhbn'
    'RvLnByb3RvLkNvbW1hbmRPcHRpb25zUgdvcHRpb25zEkoKBnJlYXNvbhgCIAEoDjIyLnNwb3Rp'
    'ZnkucGxheWVyLmVzcGVyYW50by5wcm90by5TdG9wUmVxdWVzdC5SZWFzb25SBnJlYXNvbhJUCg'
    '5sb2dnaW5nX3BhcmFtcxgDIAEoCzItLnNwb3RpZnkucGxheWVyLmVzcGVyYW50by5wcm90by5M'
    'b2dnaW5nUGFyYW1zUg1sb2dnaW5nUGFyYW1zIjwKBlJlYXNvbhIPCgtJTlRFUkFDVElWRRAAEh'
    'MKD1JFTU9URV9UUkFOU0ZFUhABEgwKCFNIVVRET1dOEAI=');
