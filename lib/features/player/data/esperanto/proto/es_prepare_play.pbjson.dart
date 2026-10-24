// This is a generated file - do not edit.
//
// Generated from es_prepare_play.proto.

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

@$core.Deprecated('Use preparePlayRequestDescriptor instead')
const PreparePlayRequest$json = {
  '1': 'PreparePlayRequest',
  '2': [
    {
      '1': 'context',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.Context',
      '10': 'context'
    },
    {
      '1': 'options',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.PreparePlayOptions',
      '10': 'options'
    },
    {
      '1': 'play_origin',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.PlayOrigin',
      '10': 'playOrigin'
    },
  ],
};

/// Descriptor for `PreparePlayRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preparePlayRequestDescriptor = $convert.base64Decode(
    'ChJQcmVwYXJlUGxheVJlcXVlc3QSQQoHY29udGV4dBgBIAEoCzInLnNwb3RpZnkucGxheWVyLm'
    'VzcGVyYW50by5wcm90by5Db250ZXh0Ugdjb250ZXh0EkwKB29wdGlvbnMYAiABKAsyMi5zcG90'
    'aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uUHJlcGFyZVBsYXlPcHRpb25zUgdvcHRpb25zEk'
    'sKC3BsYXlfb3JpZ2luGAMgASgLMiouc3BvdGlmeS5wbGF5ZXIuZXNwZXJhbnRvLnByb3RvLlBs'
    'YXlPcmlnaW5SCnBsYXlPcmlnaW4=');
