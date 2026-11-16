// 1:1 Replicated Spotify Esperanto Dodos Messages Json Descriptors
// Sources:
// - `liborbit-jni-spotify.so` `.rodata` FileDescriptorProto offset `5714450` / `0x5a1dd0`

// This is a generated file - do not edit.
//
// Generated from protos/esperanto/dodos_messages.proto.

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

import 'package:protobuf/well_known_types/google/protobuf/empty.pbjson.dart'
    as $0;

import 'es_common_messages.pbjson.dart' as $1;

@$core.Deprecated('Use singleDodoDescriptor instead')
const SingleDodo$json = {
  '1': 'SingleDodo',
  '2': [
    {'1': 'dodo_id', '3': 1, '4': 1, '5': 9, '10': 'dodoId'},
    {'1': 'cs_id', '3': 2, '4': 1, '5': 9, '10': 'csId'},
    {'1': 'is_primary', '3': 3, '4': 1, '5': 8, '10': 'isPrimary'},
    {'1': 'is_being_observed', '3': 4, '4': 1, '5': 8, '10': 'isBeingObserved'},
  ],
};

/// Descriptor for `SingleDodo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List singleDodoDescriptor = $convert.base64Decode(
    'CgpTaW5nbGVEb2RvEhcKB2RvZG9faWQYASABKAlSBmRvZG9JZBITCgVjc19pZBgCIAEoCVIEY3'
    'NJZBIdCgppc19wcmltYXJ5GAMgASgIUglpc1ByaW1hcnkSKgoRaXNfYmVpbmdfb2JzZXJ2ZWQY'
    'BCABKAhSD2lzQmVpbmdPYnNlcnZlZA==');

@$core.Deprecated('Use switchToDodoRequestDescriptor instead')
const SwitchToDodoRequest$json = {
  '1': 'SwitchToDodoRequest',
  '2': [
    {'1': 'cs_id', '3': 1, '4': 1, '5': 9, '10': 'csId'},
  ],
};

/// Descriptor for `SwitchToDodoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List switchToDodoRequestDescriptor = $convert
    .base64Decode('ChNTd2l0Y2hUb0RvZG9SZXF1ZXN0EhMKBWNzX2lkGAEgASgJUgRjc0lk');

@$core.Deprecated('Use createNewDodoRequestDescriptor instead')
const CreateNewDodoRequest$json = {
  '1': 'CreateNewDodoRequest',
};

/// Descriptor for `CreateNewDodoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createNewDodoRequestDescriptor =
    $convert.base64Decode('ChRDcmVhdGVOZXdEb2RvUmVxdWVzdA==');

@$core.Deprecated('Use endDodoRequestDescriptor instead')
const EndDodoRequest$json = {
  '1': 'EndDodoRequest',
};

/// Descriptor for `EndDodoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List endDodoRequestDescriptor =
    $convert.base64Decode('Cg5FbmREb2RvUmVxdWVzdA==');

@$core.Deprecated('Use dodoSubResponseDescriptor instead')
const DodoSubResponse$json = {
  '1': 'DodoSubResponse',
  '2': [
    {
      '1': 'dodos',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.connect.esperanto.proto.SingleDodo',
      '10': 'dodos'
    },
  ],
};

/// Descriptor for `DodoSubResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dodoSubResponseDescriptor = $convert.base64Decode(
    'Cg9Eb2RvU3ViUmVzcG9uc2USQQoFZG9kb3MYASADKAsyKy5zcG90aWZ5LmNvbm5lY3QuZXNwZX'
    'JhbnRvLnByb3RvLlNpbmdsZURvZG9SBWRvZG9z');

const $core.Map<$core.String, $core.dynamic> DodoServiceBase$json = {
  '1': 'DodoService',
  '2': [
    {
      '1': 'DodoSub',
      '2': '.google.protobuf.Empty',
      '3': '.spotify.connect.esperanto.proto.DodoSubResponse',
      '6': true
    },
    {
      '1': 'SwitchToDodo',
      '2': '.spotify.connect.esperanto.proto.SwitchToDodoRequest',
      '3': '.spotify.connect.esperanto.proto.StatusResponse'
    },
    {
      '1': 'CreateNewDodo',
      '2': '.spotify.connect.esperanto.proto.CreateNewDodoRequest',
      '3': '.spotify.connect.esperanto.proto.StatusResponse'
    },
    {
      '1': 'EndDodo',
      '2': '.spotify.connect.esperanto.proto.EndDodoRequest',
      '3': '.spotify.connect.esperanto.proto.StatusResponse'
    },
  ],
};

@$core.Deprecated('Use dodoServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    DodoServiceBase$messageJson = {
  '.google.protobuf.Empty': $0.Empty$json,
  '.spotify.connect.esperanto.proto.DodoSubResponse': DodoSubResponse$json,
  '.spotify.connect.esperanto.proto.SingleDodo': SingleDodo$json,
  '.spotify.connect.esperanto.proto.SwitchToDodoRequest':
      SwitchToDodoRequest$json,
  '.spotify.connect.esperanto.proto.StatusResponse': $1.StatusResponse$json,
  '.spotify.connect.esperanto.proto.CreateNewDodoRequest':
      CreateNewDodoRequest$json,
  '.spotify.connect.esperanto.proto.EndDodoRequest': EndDodoRequest$json,
};

/// Descriptor for `DodoService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List dodoServiceDescriptor = $convert.base64Decode(
    'CgtEb2RvU2VydmljZRJVCgdEb2RvU3ViEhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5GjAuc3BvdG'
    'lmeS5jb25uZWN0LmVzcGVyYW50by5wcm90by5Eb2RvU3ViUmVzcG9uc2UwARJ1CgxTd2l0Y2hU'
    'b0RvZG8SNC5zcG90aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLlN3aXRjaFRvRG9kb1JlcX'
    'Vlc3QaLy5zcG90aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLlN0YXR1c1Jlc3BvbnNlEncK'
    'DUNyZWF0ZU5ld0RvZG8SNS5zcG90aWZ5LmNvbm5lY3QuZXNwZXJhbnRvLnByb3RvLkNyZWF0ZU'
    '5ld0RvZG9SZXF1ZXN0Gi8uc3BvdGlmeS5jb25uZWN0LmVzcGVyYW50by5wcm90by5TdGF0dXNS'
    'ZXNwb25zZRJrCgdFbmREb2RvEi8uc3BvdGlmeS5jb25uZWN0LmVzcGVyYW50by5wcm90by5Fbm'
    'REb2RvUmVxdWVzdBovLnNwb3RpZnkuY29ubmVjdC5lc3BlcmFudG8ucHJvdG8uU3RhdHVzUmVz'
    'cG9uc2U=');
