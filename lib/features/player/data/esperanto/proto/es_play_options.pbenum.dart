// This is a generated file - do not edit.
//
// Generated from es_play_options.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PlayOptions_Reason extends $pb.ProtobufEnum {
  static const PlayOptions_Reason INTERACTIVE =
      PlayOptions_Reason._(0, _omitEnumNames ? '' : 'INTERACTIVE');
  static const PlayOptions_Reason REMOTE_TRANSFER =
      PlayOptions_Reason._(1, _omitEnumNames ? '' : 'REMOTE_TRANSFER');
  static const PlayOptions_Reason LICENSE_CHANGE =
      PlayOptions_Reason._(2, _omitEnumNames ? '' : 'LICENSE_CHANGE');

  static const $core.List<PlayOptions_Reason> values = <PlayOptions_Reason>[
    INTERACTIVE,
    REMOTE_TRANSFER,
    LICENSE_CHANGE,
  ];

  static final $core.List<PlayOptions_Reason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PlayOptions_Reason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PlayOptions_Reason._(super.value, super.name);
}

class PlayOptions_Operation extends $pb.ProtobufEnum {
  static const PlayOptions_Operation REPLACE =
      PlayOptions_Operation._(0, _omitEnumNames ? '' : 'REPLACE');
  static const PlayOptions_Operation ENQUEUE =
      PlayOptions_Operation._(1, _omitEnumNames ? '' : 'ENQUEUE');
  static const PlayOptions_Operation PUSH =
      PlayOptions_Operation._(2, _omitEnumNames ? '' : 'PUSH');

  static const $core.List<PlayOptions_Operation> values =
      <PlayOptions_Operation>[
    REPLACE,
    ENQUEUE,
    PUSH,
  ];

  static final $core.List<PlayOptions_Operation?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PlayOptions_Operation? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PlayOptions_Operation._(super.value, super.name);
}

class PlayOptions_Trigger extends $pb.ProtobufEnum {
  static const PlayOptions_Trigger IMMEDIATELY =
      PlayOptions_Trigger._(0, _omitEnumNames ? '' : 'IMMEDIATELY');
  static const PlayOptions_Trigger ADVANCED_PAST_TRACK =
      PlayOptions_Trigger._(1, _omitEnumNames ? '' : 'ADVANCED_PAST_TRACK');
  static const PlayOptions_Trigger ADVANCED_PAST_CONTEXT =
      PlayOptions_Trigger._(2, _omitEnumNames ? '' : 'ADVANCED_PAST_CONTEXT');

  static const $core.List<PlayOptions_Trigger> values = <PlayOptions_Trigger>[
    IMMEDIATELY,
    ADVANCED_PAST_TRACK,
    ADVANCED_PAST_CONTEXT,
  ];

  static final $core.List<PlayOptions_Trigger?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PlayOptions_Trigger? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PlayOptions_Trigger._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
