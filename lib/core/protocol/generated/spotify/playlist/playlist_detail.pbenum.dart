// This is a generated file - do not edit.
//
// Generated from spotify/playlist/playlist_detail.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class OpKind extends $pb.ProtobufEnum {
  static const OpKind OP_KIND_UNKNOWN =
      OpKind._(0, _omitEnumNames ? '' : 'OP_KIND_UNKNOWN');

  /// 1 unused
  static const OpKind ADD = OpKind._(2, _omitEnumNames ? '' : 'ADD');
  static const OpKind REM = OpKind._(3, _omitEnumNames ? '' : 'REM');
  static const OpKind MOV = OpKind._(4, _omitEnumNames ? '' : 'MOV');
  static const OpKind UPDATE_ITEM_ATTRIBUTES =
      OpKind._(5, _omitEnumNames ? '' : 'UPDATE_ITEM_ATTRIBUTES');
  static const OpKind UPDATE_LIST_ATTRIBUTES =
      OpKind._(6, _omitEnumNames ? '' : 'UPDATE_LIST_ATTRIBUTES');

  static const $core.List<OpKind> values = <OpKind>[
    OP_KIND_UNKNOWN,
    ADD,
    REM,
    MOV,
    UPDATE_ITEM_ATTRIBUTES,
    UPDATE_LIST_ATTRIBUTES,
  ];

  static final $core.List<OpKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static OpKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OpKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
