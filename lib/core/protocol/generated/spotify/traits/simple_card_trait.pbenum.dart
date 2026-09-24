// This is a generated file - do not edit.
//
// Generated from spotify/traits/simple_card_trait.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Restriction extends $pb.ProtobufEnum {
  static const Restriction NONE =
      Restriction._(0, _omitEnumNames ? '' : 'NONE');
  static const Restriction IS_EXPLICIT =
      Restriction._(1, _omitEnumNames ? '' : 'IS_EXPLICIT');
  static const Restriction IS_19_PLUS =
      Restriction._(2, _omitEnumNames ? '' : 'IS_19_PLUS');

  static const $core.List<Restriction> values = <Restriction>[
    NONE,
    IS_EXPLICIT,
    IS_19_PLUS,
  ];

  static final $core.List<Restriction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Restriction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Restriction._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
