// This is a generated file - do not edit.
//
// Generated from es_set_queue_request.proto.

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

@$core.Deprecated('Use setQueueRequestDescriptor instead')
const SetQueueRequest$json = {
  '1': 'SetQueueRequest',
  '2': [
    {
      '1': 'next_tracks',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ProvidedTrack',
      '10': 'nextTracks'
    },
    {
      '1': 'prev_tracks',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ProvidedTrack',
      '10': 'prevTracks'
    },
    {'1': 'queue_revision', '3': 3, '4': 1, '5': 4, '10': 'queueRevision'},
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
  ],
};

/// Descriptor for `SetQueueRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setQueueRequestDescriptor = $convert.base64Decode(
    'Cg9TZXRRdWV1ZVJlcXVlc3QSTgoLbmV4dF90cmFja3MYASADKAsyLS5zcG90aWZ5LnBsYXllci'
    '5lc3BlcmFudG8ucHJvdG8uUHJvdmlkZWRUcmFja1IKbmV4dFRyYWNrcxJOCgtwcmV2X3RyYWNr'
    'cxgCIAMoCzItLnNwb3RpZnkucGxheWVyLmVzcGVyYW50by5wcm90by5Qcm92aWRlZFRyYWNrUg'
    'pwcmV2VHJhY2tzEiUKDnF1ZXVlX3JldmlzaW9uGAMgASgEUg1xdWV1ZVJldmlzaW9uEkgKB29w'
    'dGlvbnMYBCABKAsyLi5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uQ29tbWFuZE9wdG'
    'lvbnNSB29wdGlvbnMSVAoObG9nZ2luZ19wYXJhbXMYBSABKAsyLS5zcG90aWZ5LnBsYXllci5l'
    'c3BlcmFudG8ucHJvdG8uTG9nZ2luZ1BhcmFtc1INbG9nZ2luZ1BhcmFtcw==');
