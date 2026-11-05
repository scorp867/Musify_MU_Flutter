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
  static const StopRequest_Reason USER =
      StopRequest_Reason._(0, _omitEnumNames ? '' : 'USER');
  static const StopRequest_Reason TRACK_DONE =
      StopRequest_Reason._(1, _omitEnumNames ? '' : 'TRACK_DONE');
  static const StopRequest_Reason CONTEXT_DONE =
      StopRequest_Reason._(2, _omitEnumNames ? '' : 'CONTEXT_DONE');
  static const StopRequest_Reason STOPPED_BY_SKIP =
      StopRequest_Reason._(3, _omitEnumNames ? '' : 'STOPPED_BY_SKIP');

  static const $core.List<StopRequest_Reason> values = <StopRequest_Reason>[
    USER,
    TRACK_DONE,
    CONTEXT_DONE,
    STOPPED_BY_SKIP,
  ];

  static final $core.List<StopRequest_Reason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static StopRequest_Reason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const StopRequest_Reason._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
