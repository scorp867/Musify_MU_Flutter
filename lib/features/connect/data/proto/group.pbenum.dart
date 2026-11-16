// 1:1 Replicated Spotify Connect Group Enums
// Sources:
// - Decompiled Java: `ConnectMessages$GroupData.java`
// - Decompiled Java: `p199p/z9k.java`
// - `liborbit-jni-spotify_memdump.so` offset `0x36de24` (`connect_group.proto`)

// This is a generated file - do not edit.
//
// Generated from protos/spotify/connect/group.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class GroupingStatus extends $pb.ProtobufEnum {
  static const GroupingStatus UNKNOWN_GROUPING_STATUS =
      GroupingStatus._(0, _omitEnumNames ? '' : 'UNKNOWN_GROUPING_STATUS');
  static const GroupingStatus GROUPED =
      GroupingStatus._(1, _omitEnumNames ? '' : 'GROUPED');
  static const GroupingStatus GROUPABLE =
      GroupingStatus._(2, _omitEnumNames ? '' : 'GROUPABLE');
  static const GroupingStatus GROUPING =
      GroupingStatus._(3, _omitEnumNames ? '' : 'GROUPING');

  static const $core.List<GroupingStatus> values = <GroupingStatus>[
    UNKNOWN_GROUPING_STATUS,
    GROUPED,
    GROUPABLE,
    GROUPING,
  ];

  static final $core.List<GroupingStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static GroupingStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GroupingStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
