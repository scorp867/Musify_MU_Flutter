// This is a generated file - do not edit.
//
// Generated from es_set_sleep_timer_request.proto.

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

@$core.Deprecated('Use setSleepTimerRequestDescriptor instead')
const SetSleepTimerRequest$json = {
  '1': 'SetSleepTimerRequest',
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
      '1': 'clear',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.SetSleepTimerRequest.Clear',
      '9': 0,
      '10': 'clear'
    },
    {
      '1': 'duration',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.SetSleepTimerRequest.Duration',
      '9': 0,
      '10': 'duration'
    },
    {
      '1': 'end_of_track',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.SetSleepTimerRequest.EndOfTrack',
      '9': 0,
      '10': 'endOfTrack'
    },
  ],
  '3': [
    SetSleepTimerRequest_Clear$json,
    SetSleepTimerRequest_Duration$json,
    SetSleepTimerRequest_EndOfTrack$json
  ],
  '8': [
    {'1': 'timer_type'},
  ],
};

@$core.Deprecated('Use setSleepTimerRequestDescriptor instead')
const SetSleepTimerRequest_Clear$json = {
  '1': 'Clear',
};

@$core.Deprecated('Use setSleepTimerRequestDescriptor instead')
const SetSleepTimerRequest_Duration$json = {
  '1': 'Duration',
  '2': [
    {'1': 'seconds', '3': 1, '4': 1, '5': 3, '10': 'seconds'},
  ],
};

@$core.Deprecated('Use setSleepTimerRequestDescriptor instead')
const SetSleepTimerRequest_EndOfTrack$json = {
  '1': 'EndOfTrack',
};

/// Descriptor for `SetSleepTimerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSleepTimerRequestDescriptor = $convert.base64Decode(
    'ChRTZXRTbGVlcFRpbWVyUmVxdWVzdBJICgdvcHRpb25zGAEgASgLMi4uc3BvdGlmeS5wbGF5ZX'
    'IuZXNwZXJhbnRvLnByb3RvLkNvbW1hbmRPcHRpb25zUgdvcHRpb25zElQKDmxvZ2dpbmdfcGFy'
    'YW1zGAIgASgLMi0uc3BvdGlmeS5wbGF5ZXIuZXNwZXJhbnRvLnByb3RvLkxvZ2dpbmdQYXJhbX'
    'NSDWxvZ2dpbmdQYXJhbXMSUgoFY2xlYXIYAyABKAsyOi5zcG90aWZ5LnBsYXllci5lc3BlcmFu'
    'dG8ucHJvdG8uU2V0U2xlZXBUaW1lclJlcXVlc3QuQ2xlYXJIAFIFY2xlYXISWwoIZHVyYXRpb2'
    '4YBCABKAsyPS5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uU2V0U2xlZXBUaW1lclJl'
    'cXVlc3QuRHVyYXRpb25IAFIIZHVyYXRpb24SYwoMZW5kX29mX3RyYWNrGAUgASgLMj8uc3BvdG'
    'lmeS5wbGF5ZXIuZXNwZXJhbnRvLnByb3RvLlNldFNsZWVwVGltZXJSZXF1ZXN0LkVuZE9mVHJh'
    'Y2tIAFIKZW5kT2ZUcmFjaxoHCgVDbGVhchokCghEdXJhdGlvbhIYCgdzZWNvbmRzGAEgASgDUg'
    'dzZWNvbmRzGgwKCkVuZE9mVHJhY2tCDAoKdGltZXJfdHlwZQ==');
