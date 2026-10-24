// This is a generated file - do not edit.
//
// Generated from es_context_player_error.proto.

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

@$core.Deprecated('Use contextPlayerErrorDescriptor instead')
const ContextPlayerError$json = {
  '1': 'ContextPlayerError',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.spotify.player.esperanto.proto.ContextPlayerError.ErrorCode',
      '10': 'code'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'data',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ContextPlayerError.DataEntry',
      '10': 'data'
    },
  ],
  '3': [ContextPlayerError_DataEntry$json],
  '4': [ContextPlayerError_ErrorCode$json],
};

@$core.Deprecated('Use contextPlayerErrorDescriptor instead')
const ContextPlayerError_DataEntry$json = {
  '1': 'DataEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use contextPlayerErrorDescriptor instead')
const ContextPlayerError_ErrorCode$json = {
  '1': 'ErrorCode',
  '2': [
    {'1': 'SUCCESS', '2': 0},
    {'1': 'PLAYBACK_STUCK', '2': 1},
    {'1': 'PLAYBACK_ERROR', '2': 2},
    {'1': 'LICENSE_CHANGE', '2': 3},
    {'1': 'PLAY_RESTRICTED', '2': 4},
    {'1': 'STOP_RESTRICTED', '2': 5},
    {'1': 'UPDATE_RESTRICTED', '2': 6},
    {'1': 'PAUSE_RESTRICTED', '2': 7},
    {'1': 'RESUME_RESTRICTED', '2': 8},
    {'1': 'SKIP_TO_PREV_RESTRICTED', '2': 9},
    {'1': 'SKIP_TO_NEXT_RESTRICTED', '2': 10},
    {'1': 'SKIP_TO_NON_EXISTENT_TRACK', '2': 11},
    {'1': 'SEEK_TO_RESTRICTED', '2': 12},
    {'1': 'TOGGLE_REPEAT_CONTEXT_RESTRICTED', '2': 13},
    {'1': 'TOGGLE_REPEAT_TRACK_RESTRICTED', '2': 14},
    {'1': 'SET_OPTIONS_RESTRICTED', '2': 15},
    {'1': 'TOGGLE_SHUFFLE_RESTRICTED', '2': 16},
    {'1': 'SET_QUEUE_RESTRICTED', '2': 17},
    {'1': 'INTERRUPT_PLAYBACK_RESTRICTED', '2': 18},
    {'1': 'ONE_TRACK_UNPLAYABLE', '2': 19},
    {'1': 'ONE_TRACK_UNPLAYABLE_AUTO_STOPPED', '2': 20},
    {'1': 'ALL_TRACKS_UNPLAYABLE_AUTO_STOPPED', '2': 21},
    {'1': 'SKIP_TO_NON_EXISTENT_TRACK_AUTO_STOPPED', '2': 22},
    {'1': 'QUEUE_REVISION_MISMATCH', '2': 23},
    {'1': 'VIDEO_PLAYBACK_ERROR', '2': 24},
    {'1': 'VIDEO_GEOGRAPHICALLY_RESTRICTED', '2': 25},
    {'1': 'VIDEO_UNSUPPORTED_PLATFORM_VERSION', '2': 26},
    {'1': 'VIDEO_UNSUPPORTED_CLIENT_VERSION', '2': 27},
    {'1': 'VIDEO_UNSUPPORTED_KEY_SYSTEM', '2': 28},
    {'1': 'VIDEO_MANIFEST_DELETED', '2': 29},
    {'1': 'VIDEO_COUNTRY_RESTRICTED', '2': 30},
    {'1': 'VIDEO_UNAVAILABLE', '2': 31},
    {'1': 'VIDEO_CATALOGUE_RESTRICTED', '2': 32},
    {'1': 'INVALID', '2': 33},
    {'1': 'TIMEOUT', '2': 34},
    {'1': 'PLAYBACK_REPORTING_ERROR', '2': 35},
    {'1': 'UNKNOWN', '2': 36},
    {'1': 'ADD_TO_QUEUE_RESTRICTED', '2': 37},
    {'1': 'PICK_AND_SHUFFLE_CAPPED', '2': 38},
    {'1': 'PICK_AND_SHUFFLE_CONNECT_RESTRICTED', '2': 39},
    {'1': 'CONTEXT_LOADING_FAILED', '2': 40},
    {'1': 'AUDIOBOOK_NOT_PLAYABLE', '2': 41},
    {'1': 'SIGNAL_NOT_AVAILABLE', '2': 42},
  ],
};

/// Descriptor for `ContextPlayerError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextPlayerErrorDescriptor = $convert.base64Decode(
    'ChJDb250ZXh0UGxheWVyRXJyb3ISUAoEY29kZRgBIAEoDjI8LnNwb3RpZnkucGxheWVyLmVzcG'
    'VyYW50by5wcm90by5Db250ZXh0UGxheWVyRXJyb3IuRXJyb3JDb2RlUgRjb2RlEhgKB21lc3Nh'
    'Z2UYAiABKAlSB21lc3NhZ2USUAoEZGF0YRgDIAMoCzI8LnNwb3RpZnkucGxheWVyLmVzcGVyYW'
    '50by5wcm90by5Db250ZXh0UGxheWVyRXJyb3IuRGF0YUVudHJ5UgRkYXRhGjcKCURhdGFFbnRy'
    'eRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIsMJCglFcnJvck'
    'NvZGUSCwoHU1VDQ0VTUxAAEhIKDlBMQVlCQUNLX1NUVUNLEAESEgoOUExBWUJBQ0tfRVJST1IQ'
    'AhISCg5MSUNFTlNFX0NIQU5HRRADEhMKD1BMQVlfUkVTVFJJQ1RFRBAEEhMKD1NUT1BfUkVTVF'
    'JJQ1RFRBAFEhUKEVVQREFURV9SRVNUUklDVEVEEAYSFAoQUEFVU0VfUkVTVFJJQ1RFRBAHEhUK'
    'EVJFU1VNRV9SRVNUUklDVEVEEAgSGwoXU0tJUF9UT19QUkVWX1JFU1RSSUNURUQQCRIbChdTS0'
    'lQX1RPX05FWFRfUkVTVFJJQ1RFRBAKEh4KGlNLSVBfVE9fTk9OX0VYSVNURU5UX1RSQUNLEAsS'
    'FgoSU0VFS19UT19SRVNUUklDVEVEEAwSJAogVE9HR0xFX1JFUEVBVF9DT05URVhUX1JFU1RSSU'
    'NURUQQDRIiCh5UT0dHTEVfUkVQRUFUX1RSQUNLX1JFU1RSSUNURUQQDhIaChZTRVRfT1BUSU9O'
    'U19SRVNUUklDVEVEEA8SHQoZVE9HR0xFX1NIVUZGTEVfUkVTVFJJQ1RFRBAQEhgKFFNFVF9RVU'
    'VVRV9SRVNUUklDVEVEEBESIQodSU5URVJSVVBUX1BMQVlCQUNLX1JFU1RSSUNURUQQEhIYChRP'
    'TkVfVFJBQ0tfVU5QTEFZQUJMRRATEiUKIU9ORV9UUkFDS19VTlBMQVlBQkxFX0FVVE9fU1RPUF'
    'BFRBAUEiYKIkFMTF9UUkFDS1NfVU5QTEFZQUJMRV9BVVRPX1NUT1BQRUQQFRIrCidTS0lQX1RP'
    'X05PTl9FWElTVEVOVF9UUkFDS19BVVRPX1NUT1BQRUQQFhIbChdRVUVVRV9SRVZJU0lPTl9NSV'
    'NNQVRDSBAXEhgKFFZJREVPX1BMQVlCQUNLX0VSUk9SEBgSIwofVklERU9fR0VPR1JBUEhJQ0FM'
    'TFlfUkVTVFJJQ1RFRBAZEiYKIlZJREVPX1VOU1VQUE9SVEVEX1BMQVRGT1JNX1ZFUlNJT04QGh'
    'IkCiBWSURFT19VTlNVUFBPUlRFRF9DTElFTlRfVkVSU0lPThAbEiAKHFZJREVPX1VOU1VQUE9S'
    'VEVEX0tFWV9TWVNURU0QHBIaChZWSURFT19NQU5JRkVTVF9ERUxFVEVEEB0SHAoYVklERU9fQ0'
    '9VTlRSWV9SRVNUUklDVEVEEB4SFQoRVklERU9fVU5BVkFJTEFCTEUQHxIeChpWSURFT19DQVRB'
    'TE9HVUVfUkVTVFJJQ1RFRBAgEgsKB0lOVkFMSUQQIRILCgdUSU1FT1VUECISHAoYUExBWUJBQ0'
    'tfUkVQT1JUSU5HX0VSUk9SECMSCwoHVU5LTk9XThAkEhsKF0FERF9UT19RVUVVRV9SRVNUUklD'
    'VEVEECUSGwoXUElDS19BTkRfU0hVRkZMRV9DQVBQRUQQJhInCiNQSUNLX0FORF9TSFVGRkxFX0'
    'NPTk5FQ1RfUkVTVFJJQ1RFRBAnEhoKFkNPTlRFWFRfTE9BRElOR19GQUlMRUQQKBIaChZBVURJ'
    'T0JPT0tfTk9UX1BMQVlBQkxFECkSGAoUU0lHTkFMX05PVF9BVkFJTEFCTEUQKg==');
