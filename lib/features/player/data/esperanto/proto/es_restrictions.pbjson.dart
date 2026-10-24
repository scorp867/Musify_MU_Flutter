// This is a generated file - do not edit.
//
// Generated from es_restrictions.proto.

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

@$core.Deprecated('Use modeRestrictionsDescriptor instead')
const ModeRestrictions$json = {
  '1': 'ModeRestrictions',
  '2': [
    {
      '1': 'values',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ModeRestrictions.ValuesEntry',
      '10': 'values'
    },
  ],
  '3': [ModeRestrictions_ValuesEntry$json],
};

@$core.Deprecated('Use modeRestrictionsDescriptor instead')
const ModeRestrictions_ValuesEntry$json = {
  '1': 'ValuesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.RestrictionReasons',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `ModeRestrictions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modeRestrictionsDescriptor = $convert.base64Decode(
    'ChBNb2RlUmVzdHJpY3Rpb25zElQKBnZhbHVlcxgBIAMoCzI8LnNwb3RpZnkucGxheWVyLmVzcG'
    'VyYW50by5wcm90by5Nb2RlUmVzdHJpY3Rpb25zLlZhbHVlc0VudHJ5UgZ2YWx1ZXMabQoLVmFs'
    'dWVzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSSAoFdmFsdWUYAiABKAsyMi5zcG90aWZ5LnBsYX'
    'llci5lc3BlcmFudG8ucHJvdG8uUmVzdHJpY3Rpb25SZWFzb25zUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use restrictionReasonsDescriptor instead')
const RestrictionReasons$json = {
  '1': 'RestrictionReasons',
  '2': [
    {'1': 'reasons', '3': 1, '4': 3, '5': 9, '10': 'reasons'},
  ],
};

/// Descriptor for `RestrictionReasons`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List restrictionReasonsDescriptor =
    $convert.base64Decode(
        'ChJSZXN0cmljdGlvblJlYXNvbnMSGAoHcmVhc29ucxgBIAMoCVIHcmVhc29ucw==');

@$core.Deprecated('Use restrictionsDescriptor instead')
const Restrictions$json = {
  '1': 'Restrictions',
  '2': [
    {
      '1': 'disallow_pausing_reasons',
      '3': 1,
      '4': 3,
      '5': 9,
      '10': 'disallowPausingReasons'
    },
    {
      '1': 'disallow_resuming_reasons',
      '3': 2,
      '4': 3,
      '5': 9,
      '10': 'disallowResumingReasons'
    },
    {
      '1': 'disallow_seeking_reasons',
      '3': 3,
      '4': 3,
      '5': 9,
      '10': 'disallowSeekingReasons'
    },
    {
      '1': 'disallow_peeking_prev_reasons',
      '3': 4,
      '4': 3,
      '5': 9,
      '10': 'disallowPeekingPrevReasons'
    },
    {
      '1': 'disallow_peeking_next_reasons',
      '3': 5,
      '4': 3,
      '5': 9,
      '10': 'disallowPeekingNextReasons'
    },
    {
      '1': 'disallow_skipping_prev_reasons',
      '3': 6,
      '4': 3,
      '5': 9,
      '10': 'disallowSkippingPrevReasons'
    },
    {
      '1': 'disallow_skipping_next_reasons',
      '3': 7,
      '4': 3,
      '5': 9,
      '10': 'disallowSkippingNextReasons'
    },
    {
      '1': 'disallow_toggling_repeat_context_reasons',
      '3': 8,
      '4': 3,
      '5': 9,
      '10': 'disallowTogglingRepeatContextReasons'
    },
    {
      '1': 'disallow_toggling_repeat_track_reasons',
      '3': 9,
      '4': 3,
      '5': 9,
      '10': 'disallowTogglingRepeatTrackReasons'
    },
    {
      '1': 'disallow_toggling_shuffle_reasons',
      '3': 10,
      '4': 3,
      '5': 9,
      '10': 'disallowTogglingShuffleReasons'
    },
    {
      '1': 'disallow_set_queue_reasons',
      '3': 11,
      '4': 3,
      '5': 9,
      '10': 'disallowSetQueueReasons'
    },
    {
      '1': 'disallow_interrupting_playback_reasons',
      '3': 12,
      '4': 3,
      '5': 9,
      '10': 'disallowInterruptingPlaybackReasons'
    },
    {
      '1': 'disallow_transferring_playback_reasons',
      '3': 13,
      '4': 3,
      '5': 9,
      '10': 'disallowTransferringPlaybackReasons'
    },
    {
      '1': 'disallow_remote_control_reasons',
      '3': 14,
      '4': 3,
      '5': 9,
      '10': 'disallowRemoteControlReasons'
    },
    {
      '1': 'disallow_inserting_into_next_tracks_reasons',
      '3': 15,
      '4': 3,
      '5': 9,
      '10': 'disallowInsertingIntoNextTracksReasons'
    },
    {
      '1': 'disallow_inserting_into_context_tracks_reasons',
      '3': 16,
      '4': 3,
      '5': 9,
      '10': 'disallowInsertingIntoContextTracksReasons'
    },
    {
      '1': 'disallow_reordering_in_next_tracks_reasons',
      '3': 17,
      '4': 3,
      '5': 9,
      '10': 'disallowReorderingInNextTracksReasons'
    },
    {
      '1': 'disallow_reordering_in_context_tracks_reasons',
      '3': 18,
      '4': 3,
      '5': 9,
      '10': 'disallowReorderingInContextTracksReasons'
    },
    {
      '1': 'disallow_removing_from_next_tracks_reasons',
      '3': 19,
      '4': 3,
      '5': 9,
      '10': 'disallowRemovingFromNextTracksReasons'
    },
    {
      '1': 'disallow_removing_from_context_tracks_reasons',
      '3': 20,
      '4': 3,
      '5': 9,
      '10': 'disallowRemovingFromContextTracksReasons'
    },
    {
      '1': 'disallow_updating_context_reasons',
      '3': 21,
      '4': 3,
      '5': 9,
      '10': 'disallowUpdatingContextReasons'
    },
    {
      '1': 'disallow_add_to_queue_reasons',
      '3': 22,
      '4': 3,
      '5': 9,
      '10': 'disallowAddToQueueReasons'
    },
    {
      '1': 'disallow_setting_playback_speed_reasons',
      '3': 23,
      '4': 3,
      '5': 9,
      '10': 'disallowSettingPlaybackSpeedReasons'
    },
    {
      '1': 'disallow_setting_modes',
      '3': 25,
      '4': 3,
      '5': 11,
      '6':
          '.spotify.player.esperanto.proto.Restrictions.DisallowSettingModesEntry',
      '10': 'disallowSettingModes'
    },
    {
      '1': 'disallow_signals',
      '3': 26,
      '4': 3,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.Restrictions.DisallowSignalsEntry',
      '10': 'disallowSignals'
    },
  ],
  '3': [
    Restrictions_DisallowSettingModesEntry$json,
    Restrictions_DisallowSignalsEntry$json
  ],
};

@$core.Deprecated('Use restrictionsDescriptor instead')
const Restrictions_DisallowSettingModesEntry$json = {
  '1': 'DisallowSettingModesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.ModeRestrictions',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use restrictionsDescriptor instead')
const Restrictions_DisallowSignalsEntry$json = {
  '1': 'DisallowSignalsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.player.esperanto.proto.RestrictionReasons',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `Restrictions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List restrictionsDescriptor = $convert.base64Decode(
    'CgxSZXN0cmljdGlvbnMSOAoYZGlzYWxsb3dfcGF1c2luZ19yZWFzb25zGAEgAygJUhZkaXNhbG'
    'xvd1BhdXNpbmdSZWFzb25zEjoKGWRpc2FsbG93X3Jlc3VtaW5nX3JlYXNvbnMYAiADKAlSF2Rp'
    'c2FsbG93UmVzdW1pbmdSZWFzb25zEjgKGGRpc2FsbG93X3NlZWtpbmdfcmVhc29ucxgDIAMoCV'
    'IWZGlzYWxsb3dTZWVraW5nUmVhc29ucxJBCh1kaXNhbGxvd19wZWVraW5nX3ByZXZfcmVhc29u'
    'cxgEIAMoCVIaZGlzYWxsb3dQZWVraW5nUHJldlJlYXNvbnMSQQodZGlzYWxsb3dfcGVla2luZ1'
    '9uZXh0X3JlYXNvbnMYBSADKAlSGmRpc2FsbG93UGVla2luZ05leHRSZWFzb25zEkMKHmRpc2Fs'
    'bG93X3NraXBwaW5nX3ByZXZfcmVhc29ucxgGIAMoCVIbZGlzYWxsb3dTa2lwcGluZ1ByZXZSZW'
    'Fzb25zEkMKHmRpc2FsbG93X3NraXBwaW5nX25leHRfcmVhc29ucxgHIAMoCVIbZGlzYWxsb3dT'
    'a2lwcGluZ05leHRSZWFzb25zElYKKGRpc2FsbG93X3RvZ2dsaW5nX3JlcGVhdF9jb250ZXh0X3'
    'JlYXNvbnMYCCADKAlSJGRpc2FsbG93VG9nZ2xpbmdSZXBlYXRDb250ZXh0UmVhc29ucxJSCiZk'
    'aXNhbGxvd190b2dnbGluZ19yZXBlYXRfdHJhY2tfcmVhc29ucxgJIAMoCVIiZGlzYWxsb3dUb2'
    'dnbGluZ1JlcGVhdFRyYWNrUmVhc29ucxJJCiFkaXNhbGxvd190b2dnbGluZ19zaHVmZmxlX3Jl'
    'YXNvbnMYCiADKAlSHmRpc2FsbG93VG9nZ2xpbmdTaHVmZmxlUmVhc29ucxI7ChpkaXNhbGxvd1'
    '9zZXRfcXVldWVfcmVhc29ucxgLIAMoCVIXZGlzYWxsb3dTZXRRdWV1ZVJlYXNvbnMSUwomZGlz'
    'YWxsb3dfaW50ZXJydXB0aW5nX3BsYXliYWNrX3JlYXNvbnMYDCADKAlSI2Rpc2FsbG93SW50ZX'
    'JydXB0aW5nUGxheWJhY2tSZWFzb25zElMKJmRpc2FsbG93X3RyYW5zZmVycmluZ19wbGF5YmFj'
    'a19yZWFzb25zGA0gAygJUiNkaXNhbGxvd1RyYW5zZmVycmluZ1BsYXliYWNrUmVhc29ucxJFCh'
    '9kaXNhbGxvd19yZW1vdGVfY29udHJvbF9yZWFzb25zGA4gAygJUhxkaXNhbGxvd1JlbW90ZUNv'
    'bnRyb2xSZWFzb25zElsKK2Rpc2FsbG93X2luc2VydGluZ19pbnRvX25leHRfdHJhY2tzX3JlYX'
    'NvbnMYDyADKAlSJmRpc2FsbG93SW5zZXJ0aW5nSW50b05leHRUcmFja3NSZWFzb25zEmEKLmRp'
    'c2FsbG93X2luc2VydGluZ19pbnRvX2NvbnRleHRfdHJhY2tzX3JlYXNvbnMYECADKAlSKWRpc2'
    'FsbG93SW5zZXJ0aW5nSW50b0NvbnRleHRUcmFja3NSZWFzb25zElkKKmRpc2FsbG93X3Jlb3Jk'
    'ZXJpbmdfaW5fbmV4dF90cmFja3NfcmVhc29ucxgRIAMoCVIlZGlzYWxsb3dSZW9yZGVyaW5nSW'
    '5OZXh0VHJhY2tzUmVhc29ucxJfCi1kaXNhbGxvd19yZW9yZGVyaW5nX2luX2NvbnRleHRfdHJh'
    'Y2tzX3JlYXNvbnMYEiADKAlSKGRpc2FsbG93UmVvcmRlcmluZ0luQ29udGV4dFRyYWNrc1JlYX'
    'NvbnMSWQoqZGlzYWxsb3dfcmVtb3ZpbmdfZnJvbV9uZXh0X3RyYWNrc19yZWFzb25zGBMgAygJ'
    'UiVkaXNhbGxvd1JlbW92aW5nRnJvbU5leHRUcmFja3NSZWFzb25zEl8KLWRpc2FsbG93X3JlbW'
    '92aW5nX2Zyb21fY29udGV4dF90cmFja3NfcmVhc29ucxgUIAMoCVIoZGlzYWxsb3dSZW1vdmlu'
    'Z0Zyb21Db250ZXh0VHJhY2tzUmVhc29ucxJJCiFkaXNhbGxvd191cGRhdGluZ19jb250ZXh0X3'
    'JlYXNvbnMYFSADKAlSHmRpc2FsbG93VXBkYXRpbmdDb250ZXh0UmVhc29ucxJACh1kaXNhbGxv'
    'd19hZGRfdG9fcXVldWVfcmVhc29ucxgWIAMoCVIZZGlzYWxsb3dBZGRUb1F1ZXVlUmVhc29ucx'
    'JUCidkaXNhbGxvd19zZXR0aW5nX3BsYXliYWNrX3NwZWVkX3JlYXNvbnMYFyADKAlSI2Rpc2Fs'
    'bG93U2V0dGluZ1BsYXliYWNrU3BlZWRSZWFzb25zEnwKFmRpc2FsbG93X3NldHRpbmdfbW9kZX'
    'MYGSADKAsyRi5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uUmVzdHJpY3Rpb25zLkRp'
    'c2FsbG93U2V0dGluZ01vZGVzRW50cnlSFGRpc2FsbG93U2V0dGluZ01vZGVzEmwKEGRpc2FsbG'
    '93X3NpZ25hbHMYGiADKAsyQS5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uUmVzdHJp'
    'Y3Rpb25zLkRpc2FsbG93U2lnbmFsc0VudHJ5Ug9kaXNhbGxvd1NpZ25hbHMaeQoZRGlzYWxsb3'
    'dTZXR0aW5nTW9kZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRJGCgV2YWx1ZRgCIAEoCzIwLnNw'
    'b3RpZnkucGxheWVyLmVzcGVyYW50by5wcm90by5Nb2RlUmVzdHJpY3Rpb25zUgV2YWx1ZToCOA'
    'EadgoURGlzYWxsb3dTaWduYWxzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSSAoFdmFsdWUYAiAB'
    'KAsyMi5zcG90aWZ5LnBsYXllci5lc3BlcmFudG8ucHJvdG8uUmVzdHJpY3Rpb25SZWFzb25zUg'
    'V2YWx1ZToCOAE=');
