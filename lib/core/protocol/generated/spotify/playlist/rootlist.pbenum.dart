// This is a generated file - do not edit.
//
// Generated from spotify/playlist/rootlist.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PermissionLevel extends $pb.ProtobufEnum {
  static const PermissionLevel PERMISSION_LEVEL_UNKNOWN =
      PermissionLevel._(0, _omitEnumNames ? '' : 'PERMISSION_LEVEL_UNKNOWN');
  static const PermissionLevel BLOCKED =
      PermissionLevel._(1, _omitEnumNames ? '' : 'BLOCKED');
  static const PermissionLevel VIEWER =
      PermissionLevel._(2, _omitEnumNames ? '' : 'VIEWER');
  static const PermissionLevel CONTRIBUTOR =
      PermissionLevel._(3, _omitEnumNames ? '' : 'CONTRIBUTOR');
  static const PermissionLevel MADE_FOR =
      PermissionLevel._(4, _omitEnumNames ? '' : 'MADE_FOR');

  static const $core.List<PermissionLevel> values = <PermissionLevel>[
    PERMISSION_LEVEL_UNKNOWN,
    BLOCKED,
    VIEWER,
    CONTRIBUTOR,
    MADE_FOR,
  ];

  static final $core.List<PermissionLevel?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static PermissionLevel? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PermissionLevel._(super.value, super.name);
}

class GeoblockBlockingType extends $pb.ProtobufEnum {
  static const GeoblockBlockingType GEOBLOCK_BLOCKING_TYPE_UNSPECIFIED =
      GeoblockBlockingType._(
          0, _omitEnumNames ? '' : 'GEOBLOCK_BLOCKING_TYPE_UNSPECIFIED');
  static const GeoblockBlockingType GEOBLOCK_BLOCKING_TYPE_BLOCKED =
      GeoblockBlockingType._(
          1, _omitEnumNames ? '' : 'GEOBLOCK_BLOCKING_TYPE_BLOCKED');

  static const $core.List<GeoblockBlockingType> values = <GeoblockBlockingType>[
    GEOBLOCK_BLOCKING_TYPE_UNSPECIFIED,
    GEOBLOCK_BLOCKING_TYPE_BLOCKED,
  ];

  static final $core.List<GeoblockBlockingType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static GeoblockBlockingType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GeoblockBlockingType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
