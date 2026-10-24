// This is a generated file - do not edit.
//
// Generated from es_stop.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class StopRequest_Reason extends $pb.ProtobufEnum {
  static const StopRequest_Reason INTERACTIVE =
      StopRequest_Reason._(0, _omitEnumNames ? '' : 'INTERACTIVE');
  static const StopRequest_Reason REMOTE_TRANSFER =
      StopRequest_Reason._(1, _omitEnumNames ? '' : 'REMOTE_TRANSFER');
  static const StopRequest_Reason SHUTDOWN =
      StopRequest_Reason._(2, _omitEnumNames ? '' : 'SHUTDOWN');

  static const $core.List<StopRequest_Reason> values = <StopRequest_Reason>[
    INTERACTIVE,
    REMOTE_TRANSFER,
    SHUTDOWN,
  ];

  static final $core.List<StopRequest_Reason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static StopRequest_Reason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const StopRequest_Reason._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
