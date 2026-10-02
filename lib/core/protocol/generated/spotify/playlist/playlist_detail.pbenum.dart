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

/// Confirmed from Playlist4ApiProto$Op$Kind (decompiled).
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
  static const OpKind UPDATE_ITEM_URIS =
      OpKind._(7, _omitEnumNames ? '' : 'UPDATE_ITEM_URIS');

  static const $core.List<OpKind> values = <OpKind>[
    OP_KIND_UNKNOWN,
    ADD,
    REM,
    MOV,
    UPDATE_ITEM_ATTRIBUTES,
    UPDATE_LIST_ATTRIBUTES,
    UPDATE_ITEM_URIS,
  ];

  static final $core.List<OpKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static OpKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OpKind._(super.value, super.name);
}

class ListAttributeKind extends $pb.ProtobufEnum {
  static const ListAttributeKind LIST_UNKNOWN =
      ListAttributeKind._(0, _omitEnumNames ? '' : 'LIST_UNKNOWN');
  static const ListAttributeKind LIST_NAME =
      ListAttributeKind._(1, _omitEnumNames ? '' : 'LIST_NAME');
  static const ListAttributeKind LIST_DESCRIPTION =
      ListAttributeKind._(2, _omitEnumNames ? '' : 'LIST_DESCRIPTION');
  static const ListAttributeKind LIST_PICTURE =
      ListAttributeKind._(3, _omitEnumNames ? '' : 'LIST_PICTURE');
  static const ListAttributeKind LIST_COLLABORATIVE =
      ListAttributeKind._(4, _omitEnumNames ? '' : 'LIST_COLLABORATIVE');
  static const ListAttributeKind LIST_PL3_VERSION =
      ListAttributeKind._(5, _omitEnumNames ? '' : 'LIST_PL3_VERSION');
  static const ListAttributeKind LIST_DELETED_BY_OWNER =
      ListAttributeKind._(6, _omitEnumNames ? '' : 'LIST_DELETED_BY_OWNER');
  static const ListAttributeKind LIST_CLIENT_ID =
      ListAttributeKind._(10, _omitEnumNames ? '' : 'LIST_CLIENT_ID');
  static const ListAttributeKind LIST_FORMAT =
      ListAttributeKind._(11, _omitEnumNames ? '' : 'LIST_FORMAT');
  static const ListAttributeKind LIST_FORMAT_ATTRIBUTES =
      ListAttributeKind._(12, _omitEnumNames ? '' : 'LIST_FORMAT_ATTRIBUTES');
  static const ListAttributeKind LIST_PICTURE_SIZE =
      ListAttributeKind._(13, _omitEnumNames ? '' : 'LIST_PICTURE_SIZE');

  static const $core.List<ListAttributeKind> values = <ListAttributeKind>[
    LIST_UNKNOWN,
    LIST_NAME,
    LIST_DESCRIPTION,
    LIST_PICTURE,
    LIST_COLLABORATIVE,
    LIST_PL3_VERSION,
    LIST_DELETED_BY_OWNER,
    LIST_CLIENT_ID,
    LIST_FORMAT,
    LIST_FORMAT_ATTRIBUTES,
    LIST_PICTURE_SIZE,
  ];

  static final $core.List<ListAttributeKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 13);
  static ListAttributeKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ListAttributeKind._(super.value, super.name);
}

class ItemAttributeKind extends $pb.ProtobufEnum {
  static const ItemAttributeKind ITEM_UNKNOWN =
      ItemAttributeKind._(0, _omitEnumNames ? '' : 'ITEM_UNKNOWN');
  static const ItemAttributeKind ITEM_ADDED_BY =
      ItemAttributeKind._(1, _omitEnumNames ? '' : 'ITEM_ADDED_BY');
  static const ItemAttributeKind ITEM_TIMESTAMP =
      ItemAttributeKind._(2, _omitEnumNames ? '' : 'ITEM_TIMESTAMP');
  static const ItemAttributeKind ITEM_SEEN_AT =
      ItemAttributeKind._(9, _omitEnumNames ? '' : 'ITEM_SEEN_AT');
  static const ItemAttributeKind ITEM_PUBLIC =
      ItemAttributeKind._(10, _omitEnumNames ? '' : 'ITEM_PUBLIC');
  static const ItemAttributeKind ITEM_FORMAT_ATTRIBUTES =
      ItemAttributeKind._(11, _omitEnumNames ? '' : 'ITEM_FORMAT_ATTRIBUTES');
  static const ItemAttributeKind ITEM_ID =
      ItemAttributeKind._(12, _omitEnumNames ? '' : 'ITEM_ID');

  static const $core.List<ItemAttributeKind> values = <ItemAttributeKind>[
    ITEM_UNKNOWN,
    ITEM_ADDED_BY,
    ITEM_TIMESTAMP,
    ITEM_SEEN_AT,
    ITEM_PUBLIC,
    ITEM_FORMAT_ATTRIBUTES,
    ITEM_ID,
  ];

  static final $core.Map<$core.int, ItemAttributeKind> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ItemAttributeKind? valueOf($core.int value) => _byValue[value];

  const ItemAttributeKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
