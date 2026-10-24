// This is a generated file - do not edit.
//
// Generated from es_resume.proto.

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

@$core.Deprecated('Use resumeRequestDescriptor instead')
const ResumeRequest$json = {
  '1': 'ResumeRequest',
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
      '1': 'resume_origin',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.PauseResumeOrigin',
      '10': 'resumeOrigin'
    },
  ],
};

/// Descriptor for `ResumeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resumeRequestDescriptor = $convert.base64Decode(
    'Cg1SZXN1bWVSZXF1ZXN0EkgKB29wdGlvbnMYASABKAsyLi5zcG90aWZ5LnBsYXllci5lc3Blcm'
    'FudG8ucHJvdG8uQ29tbWFuZE9wdGlvbnNSB29wdGlvbnMSVAoObG9nZ2luZ19wYXJhbXMYAiAB'
    'KAsyLS5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uTG9nZ2luZ1BhcmFtc1INbG9nZ2'
    'luZ1BhcmFtcxJWCg1yZXN1bWVfb3JpZ2luGAMgASgLMjEuc3BvdGlmeS5wbGF5ZXIuZXNwZXJh'
    'bnRvLnByb3RvLlBhdXNlUmVzdW1lT3JpZ2luUgxyZXN1bWVPcmlnaW4=');
