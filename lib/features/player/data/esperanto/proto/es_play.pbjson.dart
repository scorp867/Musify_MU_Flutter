// This is a generated file - do not edit.
//
// Generated from es_play.proto.

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

@$core.Deprecated('Use playRequestDescriptor instead')
const PlayRequest$json = {
  '1': 'PlayRequest',
  '2': [
    {
      '1': 'prepare_play_request',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.PreparePlayRequest',
      '10': 'preparePlayRequest'
    },
    {
      '1': 'play_options',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.PlayOptions',
      '10': 'playOptions'
    },
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

/// Descriptor for `PlayRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playRequestDescriptor = $convert.base64Decode(
    'CgtQbGF5UmVxdWVzdBJkChRwcmVwYXJlX3BsYXlfcmVxdWVzdBgBIAEoCzIyLnNwb3RpZnkucG'
    'xheWVyLmVzcGVyYW50by5wcm90by5QcmVwYXJlUGxheVJlcXVlc3RSEnByZXBhcmVQbGF5UmVx'
    'dWVzdBJOCgxwbGF5X29wdGlvbnMYAiABKAsyKy5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucH'
    'JvdG8uUGxheU9wdGlvbnNSC3BsYXlPcHRpb25zEkgKB29wdGlvbnMYAyABKAsyLi5zcG90aWZ5'
    'LnBsYXllci5lc3BlcmFudG8ucHJvdG8uQ29tbWFuZE9wdGlvbnNSB29wdGlvbnMSVAoObG9nZ2'
    'luZ19wYXJhbXMYBCABKAsyLS5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uTG9nZ2lu'
    'Z1BhcmFtc1INbG9nZ2luZ1BhcmFtcw==');

@$core.Deprecated('Use playPreparedRequestDescriptor instead')
const PlayPreparedRequest$json = {
  '1': 'PlayPreparedRequest',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'play_options',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.PlayOptions',
      '10': 'playOptions'
    },
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

/// Descriptor for `PlayPreparedRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playPreparedRequestDescriptor = $convert.base64Decode(
    'ChNQbGF5UHJlcGFyZWRSZXF1ZXN0Eh0KCnNlc3Npb25faWQYASABKAlSCXNlc3Npb25JZBJOCg'
    'xwbGF5X29wdGlvbnMYAiABKAsyKy5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uUGxh'
    'eU9wdGlvbnNSC3BsYXlPcHRpb25zEkgKB29wdGlvbnMYAyABKAsyLi5zcG90aWZ5LnBsYXllci'
    '5lc3BlcmFudG8ucHJvdG8uQ29tbWFuZE9wdGlvbnNSB29wdGlvbnMSVAoObG9nZ2luZ19wYXJh'
    'bXMYBCABKAsyLS5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uTG9nZ2luZ1BhcmFtc1'
    'INbG9nZ2luZ1BhcmFtcw==');
