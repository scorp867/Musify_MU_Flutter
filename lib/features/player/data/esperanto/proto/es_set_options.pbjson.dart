// This is a generated file - do not edit.
//
// Generated from es_set_options.proto.

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

@$core.Deprecated('Use setOptionsRequestDescriptor instead')
const SetOptionsRequest$json = {
  '1': 'SetOptionsRequest',
  '2': [
    {
      '1': 'repeating_track',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.OptionalBoolean',
      '10': 'repeatingTrack'
    },
    {
      '1': 'repeating_context',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.OptionalBoolean',
      '10': 'repeatingContext'
    },
    {
      '1': 'shuffling_context',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.OptionalBoolean',
      '10': 'shufflingContext'
    },
    {
      '1': 'options',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.CommandOptions',
      '10': 'options'
    },
    {
      '1': 'logging_params',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.LoggingParams',
      '10': 'loggingParams'
    },
    {
      '1': 'modes',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.SetOptionsRequest.ModesEntry',
      '10': 'modes'
    },
    {
      '1': 'playback_speed',
      '3': 6,
      '4': 1,
      '5': 2,
      '9': 0,
      '10': 'playbackSpeed',
      '17': true
    },
  ],
  '3': [SetOptionsRequest_ModesEntry$json],
  '8': [
    {'1': '_playback_speed'},
  ],
};

@$core.Deprecated('Use setOptionsRequestDescriptor instead')
const SetOptionsRequest_ModesEntry$json = {
  '1': 'ModesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `SetOptionsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setOptionsRequestDescriptor = $convert.base64Decode(
    'ChFTZXRPcHRpb25zUmVxdWVzdBJYCg9yZXBlYXRpbmdfdHJhY2sYASABKAsyLy5zcG90aWZ5Ln'
    'BsYXllci5lc3BlcmFudG8ucHJvdG8uT3B0aW9uYWxCb29sZWFuUg5yZXBlYXRpbmdUcmFjaxJc'
    'ChFyZXBlYXRpbmdfY29udGV4dBgCIAEoCzIvLnNwb3RpZnkucGxheWVyLmVzcGVyYW50by5wcm'
    '90by5PcHRpb25hbEJvb2xlYW5SEHJlcGVhdGluZ0NvbnRleHQSXAoRc2h1ZmZsaW5nX2NvbnRl'
    'eHQYAyABKAsyLy5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uT3B0aW9uYWxCb29sZW'
    'FuUhBzaHVmZmxpbmdDb250ZXh0EkgKB29wdGlvbnMYBCABKAsyLi5zcG90aWZ5LnBsYXllci5l'
    'c3BlcmFudG8ucHJvdG8uQ29tbWFuZE9wdGlvbnNSB29wdGlvbnMSVAoObG9nZ2luZ19wYXJhbX'
    'MYBSABKAsyLS5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uTG9nZ2luZ1BhcmFtc1IN'
    'bG9nZ2luZ1BhcmFtcxJSCgVtb2RlcxgHIAMoCzI8LnNwb3RpZnkucGxheWVyLmVzcGVyYW50by'
    '5wcm90by5TZXRPcHRpb25zUmVxdWVzdC5Nb2Rlc0VudHJ5UgVtb2RlcxIqCg5wbGF5YmFja19z'
    'cGVlZBgGIAEoAkgAUg1wbGF5YmFja1NwZWVkiAEBGjgKCk1vZGVzRW50cnkSEAoDa2V5GAEgAS'
    'gJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AUIRCg9fcGxheWJhY2tfc3BlZWQ=');
