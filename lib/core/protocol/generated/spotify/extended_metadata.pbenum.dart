// This is a generated file - do not edit.
//
// Generated from spotify/extended_metadata.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ExtensionType extends $pb.ProtobufEnum {
  static const ExtensionType UNKNOWN =
      ExtensionType._(0, _omitEnumNames ? '' : 'UNKNOWN');
  static const ExtensionType GENERIC =
      ExtensionType._(1, _omitEnumNames ? '' : 'GENERIC');
  static const ExtensionType ASSOC =
      ExtensionType._(2, _omitEnumNames ? '' : 'ASSOC');

  static const $core.List<ExtensionType> values = <ExtensionType>[
    UNKNOWN,
    GENERIC,
    ASSOC,
  ];

  static final $core.List<ExtensionType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ExtensionType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ExtensionType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
