// 1:1 Replicated Spotify Esperanto Volume Messages Enums
// Sources:
// - Decompiled Java: `com/spotify/connect/esperanto/proto/VolumeMessages.java`
// - `liborbit-jni-spotify_memdump.so` offset `0x36a7bc` (`volume_messages.proto`)

// This is a generated file - do not edit.
//
// Generated from protos/esperanto/volume_messages.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class LocalVolumeResponse_Reason extends $pb.ProtobufEnum {
  static const LocalVolumeResponse_Reason USER =
      LocalVolumeResponse_Reason._(0, _omitEnumNames ? '' : 'USER');
  static const LocalVolumeResponse_Reason SYSTEM =
      LocalVolumeResponse_Reason._(1, _omitEnumNames ? '' : 'SYSTEM');

  static const $core.List<LocalVolumeResponse_Reason> values =
      <LocalVolumeResponse_Reason>[
    USER,
    SYSTEM,
  ];

  static final $core.List<LocalVolumeResponse_Reason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static LocalVolumeResponse_Reason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LocalVolumeResponse_Reason._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
