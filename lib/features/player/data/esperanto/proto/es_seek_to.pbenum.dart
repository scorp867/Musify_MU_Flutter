// This is a generated file - do not edit.
//
// Generated from es_seek_to.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class SeekToRequest_Relative extends $pb.ProtobufEnum {
  static const SeekToRequest_Relative BEGINNING =
      SeekToRequest_Relative._(0, _omitEnumNames ? '' : 'BEGINNING');
  static const SeekToRequest_Relative END =
      SeekToRequest_Relative._(1, _omitEnumNames ? '' : 'END');
  static const SeekToRequest_Relative CURRENT =
      SeekToRequest_Relative._(2, _omitEnumNames ? '' : 'CURRENT');

  static const $core.List<SeekToRequest_Relative> values =
      <SeekToRequest_Relative>[
    BEGINNING,
    END,
    CURRENT,
  ];

  static final $core.List<SeekToRequest_Relative?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SeekToRequest_Relative? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SeekToRequest_Relative._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
