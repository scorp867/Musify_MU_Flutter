// This is a generated file - do not edit.
//
// Generated from es_seek_to.proto.

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

@$core.Deprecated('Use seekToRequestDescriptor instead')
const SeekToRequest$json = {
  '1': 'SeekToRequest',
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
    {'1': 'position', '3': 3, '4': 1, '5': 3, '10': 'position'},
    {
      '1': 'relative',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.spotify.player.esperanto.proto.SeekToRequest.Relative',
      '10': 'relative'
    },
  ],
  '4': [SeekToRequest_Relative$json],
};

@$core.Deprecated('Use seekToRequestDescriptor instead')
const SeekToRequest_Relative$json = {
  '1': 'Relative',
  '2': [
    {'1': 'BEGINNING', '2': 0},
    {'1': 'END', '2': 1},
    {'1': 'CURRENT', '2': 2},
  ],
};

/// Descriptor for `SeekToRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List seekToRequestDescriptor = $convert.base64Decode(
    'Cg1TZWVrVG9SZXF1ZXN0EkgKB29wdGlvbnMYASABKAsyLi5zcG90aWZ5LnBsYXllci5lc3Blcm'
    'FudG8ucHJvdG8uQ29tbWFuZE9wdGlvbnNSB29wdGlvbnMSVAoObG9nZ2luZ19wYXJhbXMYAiAB'
    'KAsyLS5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uTG9nZ2luZ1BhcmFtc1INbG9nZ2'
    'luZ1BhcmFtcxIaCghwb3NpdGlvbhgDIAEoA1IIcG9zaXRpb24SUgoIcmVsYXRpdmUYBCABKA4y'
    'Ni5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uU2Vla1RvUmVxdWVzdC5SZWxhdGl2ZV'
    'IIcmVsYXRpdmUiLwoIUmVsYXRpdmUSDQoJQkVHSU5OSU5HEAASBwoDRU5EEAESCwoHQ1VSUkVO'
    'VBAC');
