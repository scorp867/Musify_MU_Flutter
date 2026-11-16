// 1:1 Replicated Spotify Esperanto Common Messages Enums
// Sources:
// - Decompiled Java: `com/spotify/connect/esperanto/proto/CommonMessages.java`
// - Decompiled Java: `p199p/r1h.java`
// - `liborbit-jni-spotify_memdump.so` offset `0x3a79bc` (`common_messages.proto`)

// This is a generated file - do not edit.
//
// Generated from protos/esperanto/common_messages.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Status extends $pb.ProtobufEnum {
  static const Status OK = Status._(0, _omitEnumNames ? '' : 'OK');
  static const Status NOT_FOUND =
      Status._(1, _omitEnumNames ? '' : 'NOT_FOUND');
  static const Status INVALID_ARGUMENTS =
      Status._(2, _omitEnumNames ? '' : 'INVALID_ARGUMENTS');
  static const Status BACKEND_FAILURE =
      Status._(3, _omitEnumNames ? '' : 'BACKEND_FAILURE');
  static const Status UNIMPLEMENTED =
      Status._(4, _omitEnumNames ? '' : 'UNIMPLEMENTED');

  static const $core.List<Status> values = <Status>[
    OK,
    NOT_FOUND,
    INVALID_ARGUMENTS,
    BACKEND_FAILURE,
    UNIMPLEMENTED,
  ];

  static final $core.List<Status?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static Status? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Status._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
