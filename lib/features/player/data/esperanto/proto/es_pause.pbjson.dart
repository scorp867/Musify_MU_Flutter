// This is a generated file - do not edit.
//
// Generated from es_pause.proto.

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

@$core.Deprecated('Use pauseRequestDescriptor instead')
const PauseRequest$json = {
  '1': 'PauseRequest',
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
      '1': 'logging_params',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.LoggingParams',
      '10': 'loggingParams'
    },
    {
      '1': 'pause_origin',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.PauseResumeOrigin',
      '10': 'pauseOrigin'
    },
  ],
};

/// Descriptor for `PauseRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pauseRequestDescriptor = $convert.base64Decode(
    'CgxQYXVzZVJlcXVlc3QSSAoHb3B0aW9ucxgBIAEoCzIuLnNwb3RpZnkucGxheWVyLmVzcGVyYW'
    '50by5wcm90by5Db21tYW5kT3B0aW9uc1IHb3B0aW9ucxJUCg5sb2dnaW5nX3BhcmFtcxgCIAEo'
    'CzItLnNwb3RpZnkucGxheWVyLmVzcGVyYW50by5wcm90by5Mb2dnaW5nUGFyYW1zUg1sb2dnaW'
    '5nUGFyYW1zElQKDHBhdXNlX29yaWdpbhgDIAEoCzIxLnNwb3RpZnkucGxheWVyLmVzcGVyYW50'
    'by5wcm90by5QYXVzZVJlc3VtZU9yaWdpblILcGF1c2VPcmlnaW4=');
