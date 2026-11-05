// This is a generated file - do not edit.
//
// Generated from es_play_as_next_in_queue_request.proto.

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

@$core.Deprecated('Use playAsNextInQueueRequestDescriptor instead')
const PlayAsNextInQueueRequest$json = {
  '1': 'PlayAsNextInQueueRequest',
  '2': [
    {
      '1': 'tracks',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ContextTrack',
      '10': 'tracks'
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

/// Descriptor for `PlayAsNextInQueueRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playAsNextInQueueRequestDescriptor = $convert.base64Decode(
    'ChhQbGF5QXNOZXh0SW5RdWV1ZVJlcXVlc3QSRAoGdHJhY2tzGAEgAygLMiwuc3BvdGlmeS5wbG'
    'F5ZXIuZXNwZXJhbnRvLnByb3RvLkNvbnRleHRUcmFja1IGdHJhY2tzEkgKB29wdGlvbnMYAiAB'
    'KAsyLi5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uQ29tbWFuZE9wdGlvbnNSB29wdG'
    'lvbnMSVAoObG9nZ2luZ19wYXJhbXMYAyABKAsyLS5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8u'
    'cHJvdG8uTG9nZ2luZ1BhcmFtc1INbG9nZ2luZ1BhcmFtcw==');
