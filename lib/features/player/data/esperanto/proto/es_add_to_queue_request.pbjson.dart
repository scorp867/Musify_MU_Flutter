// This is a generated file - do not edit.
//
// Generated from es_add_to_queue_request.proto.

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

@$core.Deprecated('Use addToQueueRequestDescriptor instead')
const AddToQueueRequest$json = {
  '1': 'AddToQueueRequest',
  '2': [
    {
      '1': 'track',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ContextTrack',
      '10': 'track'
    },
    {
      '1': 'options',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.CommandOptions',
      '10': 'options'
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
};

/// Descriptor for `AddToQueueRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addToQueueRequestDescriptor = $convert.base64Decode(
    'ChFBZGRUb1F1ZXVlUmVxdWVzdBJCCgV0cmFjaxgBIAEoCzIsLnNwb3RpZnkucGxheWVyLmVzcG'
    'VyYW50by5wcm90by5Db250ZXh0VHJhY2tSBXRyYWNrEkgKB29wdGlvbnMYAiABKAsyLi5zcG90'
    'aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uQ29tbWFuZE9wdGlvbnNSB29wdGlvbnMSVAoObG'
    '9nZ2luZ19wYXJhbXMYAyABKAsyLS5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uTG9n'
    'Z2luZ1BhcmFtc1INbG9nZ2luZ1BhcmFtcw==');
