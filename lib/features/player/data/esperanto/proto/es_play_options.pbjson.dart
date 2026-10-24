// This is a generated file - do not edit.
//
// Generated from es_play_options.proto.

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

@$core.Deprecated('Use playOptionsDescriptor instead')
const PlayOptions$json = {
  '1': 'PlayOptions',
  '2': [
    {
      '1': 'reason',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.spotify.player.esperanto.proto.PlayOptions.Reason',
      '10': 'reason'
    },
    {
      '1': 'operation',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.spotify.player.esperanto.proto.PlayOptions.Operation',
      '10': 'operation'
    },
    {
      '1': 'trigger',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.spotify.player.esperanto.proto.PlayOptions.Trigger',
      '10': 'trigger'
    },
  ],
  '4': [
    PlayOptions_Reason$json,
    PlayOptions_Operation$json,
    PlayOptions_Trigger$json
  ],
};

@$core.Deprecated('Use playOptionsDescriptor instead')
const PlayOptions_Reason$json = {
  '1': 'Reason',
  '2': [
    {'1': 'INTERACTIVE', '2': 0},
    {'1': 'REMOTE_TRANSFER', '2': 1},
    {'1': 'LICENSE_CHANGE', '2': 2},
  ],
};

@$core.Deprecated('Use playOptionsDescriptor instead')
const PlayOptions_Operation$json = {
  '1': 'Operation',
  '2': [
    {'1': 'REPLACE', '2': 0},
    {'1': 'ENQUEUE', '2': 1},
    {'1': 'PUSH', '2': 2},
  ],
};

@$core.Deprecated('Use playOptionsDescriptor instead')
const PlayOptions_Trigger$json = {
  '1': 'Trigger',
  '2': [
    {'1': 'IMMEDIATELY', '2': 0},
    {'1': 'ADVANCED_PAST_TRACK', '2': 1},
    {'1': 'ADVANCED_PAST_CONTEXT', '2': 2},
  ],
};

/// Descriptor for `PlayOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playOptionsDescriptor = $convert.base64Decode(
    'CgtQbGF5T3B0aW9ucxJKCgZyZWFzb24YASABKA4yMi5zcG90aWZ5LnBsYXllci5lc3BlcmFudG'
    '8ucHJvdG8uUGxheU9wdGlvbnMuUmVhc29uUgZyZWFzb24SUwoJb3BlcmF0aW9uGAIgASgOMjUu'
    'c3BvdGlmeS5wbGF5ZXIuZXNwZXJhbnRvLnByb3RvLlBsYXlPcHRpb25zLk9wZXJhdGlvblIJb3'
    'BlcmF0aW9uEk0KB3RyaWdnZXIYAyABKA4yMy5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJv'
    'dG8uUGxheU9wdGlvbnMuVHJpZ2dlclIHdHJpZ2dlciJCCgZSZWFzb24SDwoLSU5URVJBQ1RJVk'
    'UQABITCg9SRU1PVEVfVFJBTlNGRVIQARISCg5MSUNFTlNFX0NIQU5HRRACIi8KCU9wZXJhdGlv'
    'bhILCgdSRVBMQUNFEAASCwoHRU5RVUVVRRABEggKBFBVU0gQAiJOCgdUcmlnZ2VyEg8KC0lNTU'
    'VESUFURUxZEAASFwoTQURWQU5DRURfUEFTVF9UUkFDSxABEhkKFUFEVkFOQ0VEX1BBU1RfQ09O'
    'VEVYVBAC');
