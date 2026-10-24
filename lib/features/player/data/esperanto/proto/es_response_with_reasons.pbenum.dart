// This is a generated file - do not edit.
//
// Generated from es_response_with_reasons.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ResponseWithReasons_Error extends $pb.ProtobufEnum {
  static const ResponseWithReasons_Error OK =
      ResponseWithReasons_Error._(0, _omitEnumNames ? '' : 'OK');
  static const ResponseWithReasons_Error FORBIDDEN =
      ResponseWithReasons_Error._(1, _omitEnumNames ? '' : 'FORBIDDEN');
  static const ResponseWithReasons_Error NOT_FOUND =
      ResponseWithReasons_Error._(2, _omitEnumNames ? '' : 'NOT_FOUND');
  static const ResponseWithReasons_Error CONFLICT =
      ResponseWithReasons_Error._(3, _omitEnumNames ? '' : 'CONFLICT');

  static const $core.List<ResponseWithReasons_Error> values =
      <ResponseWithReasons_Error>[
    OK,
    FORBIDDEN,
    NOT_FOUND,
    CONFLICT,
  ];

  static final $core.List<ResponseWithReasons_Error?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ResponseWithReasons_Error? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ResponseWithReasons_Error._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
