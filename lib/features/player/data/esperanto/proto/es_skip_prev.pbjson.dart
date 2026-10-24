// This is a generated file - do not edit.
//
// Generated from es_skip_prev.proto.

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

@$core.Deprecated('Use skipPrevRequestDescriptor instead')
const SkipPrevRequest$json = {
  '1': 'SkipPrevRequest',
  '2': [
    {
      '1': 'options',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.CommandOptions',
      '10': 'options'
    },
    {'1': 'allow_seeking', '3': 2, '4': 1, '5': 8, '10': 'allowSeeking'},
    {
      '1': 'logging_params',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.LoggingParams',
      '10': 'loggingParams'
    },
    {
      '1': 'track',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ContextTrack',
      '10': 'track'
    },
  ],
};

/// Descriptor for `SkipPrevRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List skipPrevRequestDescriptor = $convert.base64Decode(
    'Cg9Ta2lwUHJldlJlcXVlc3QSSAoHb3B0aW9ucxgBIAEoCzIuLnNwb3RpZnkucGxheWVyLmVzcG'
    'VyYW50by5wcm90by5Db21tYW5kT3B0aW9uc1IHb3B0aW9ucxIjCg1hbGxvd19zZWVraW5nGAIg'
    'ASgIUgxhbGxvd1NlZWtpbmcSVAoObG9nZ2luZ19wYXJhbXMYAyABKAsyLS5zcG90aWZ5LnBsYX'
    'llci5lc3BlcmFudG8ucHJvdG8uTG9nZ2luZ1BhcmFtc1INbG9nZ2luZ1BhcmFtcxJCCgV0cmFj'
    'axgEIAEoCzIsLnNwb3RpZnkucGxheWVyLmVzcGVyYW50by5wcm90by5Db250ZXh0VHJhY2tSBX'
    'RyYWNr');
