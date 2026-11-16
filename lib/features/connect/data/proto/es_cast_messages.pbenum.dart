// 1:1 Replicated Spotify Esperanto Cast Messages Enums
// Sources:
// - Decompiled Java: `com/spotify/connect/discovery/cast/esperanto/proto/CastMessages.java`
// - `liborbit-jni-spotify_memdump.so` offset `0x36d3b8` (`cast_messages.proto`)

// This is a generated file - do not edit.
//
// Generated from protos/esperanto/cast_messages.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class CastResult extends $pb.ProtobufEnum {
  static const CastResult CAST_RESULT_OK =
      CastResult._(0, _omitEnumNames ? '' : 'CAST_RESULT_OK');
  static const CastResult CAST_RESULT_NOT_FOUND =
      CastResult._(1, _omitEnumNames ? '' : 'CAST_RESULT_NOT_FOUND');
  static const CastResult CAST_RESULT_FAILED_TO_PARSE_JSON =
      CastResult._(2, _omitEnumNames ? '' : 'CAST_RESULT_FAILED_TO_PARSE_JSON');
  static const CastResult CAST_RESULT_INVALID_STATE =
      CastResult._(3, _omitEnumNames ? '' : 'CAST_RESULT_INVALID_STATE');

  static const $core.List<CastResult> values = <CastResult>[
    CAST_RESULT_OK,
    CAST_RESULT_NOT_FOUND,
    CAST_RESULT_FAILED_TO_PARSE_JSON,
    CAST_RESULT_INVALID_STATE,
  ];

  static final $core.List<CastResult?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static CastResult? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CastResult._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
