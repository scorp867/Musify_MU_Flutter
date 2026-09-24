// This is a generated file - do not edit.
//
// Generated from spotify/playlist/recents_list.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class RecentsListResponse extends $pb.GeneratedMessage {
  factory RecentsListResponse({
    RecentsItemList? list,
  }) {
    final result = RecentsListResponse._();
    if (list != null) result.list = list;
    return result;
  }

  RecentsListResponse._();

  factory RecentsListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecentsListResponse()..mergeFromBuffer(data, registry);
  factory RecentsListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecentsListResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecentsListResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: RecentsListResponse.$_createMessage)
    ..aOM<RecentsItemList>(5, _omitFieldNames ? '' : 'list',
        subBuilder: RecentsItemList.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecentsListResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecentsListResponse copyWith(void Function(RecentsListResponse) updates) =>
      super.copyWith((message) => updates(message as RecentsListResponse))
          as RecentsListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use RecentsListResponse() / RecentsListResponse.new instead')
  static RecentsListResponse create() => RecentsListResponse._();
  static $pb.GeneratedMessage $_createMessage() => RecentsListResponse._();
  @$core.override
  RecentsListResponse createEmptyInstance() => RecentsListResponse._();
  @$core.pragma('dart2js:noInline')
  static RecentsListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RecentsListResponse>(
          RecentsListResponse.$_createMessage);
  static RecentsListResponse? _defaultInstance;

  /// Fields 1-4 are unknown/unused
  @$pb.TagNumber(5)
  RecentsItemList get list => $_getN(0);
  @$pb.TagNumber(5)
  set list(RecentsItemList value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasList() => $_has(0);
  @$pb.TagNumber(5)
  void clearList() => $_clearField(5);
  @$pb.TagNumber(5)
  RecentsItemList ensureList() => $_ensure(0);
}

class RecentsItemList extends $pb.GeneratedMessage {
  factory RecentsItemList({
    $core.Iterable<RecentsListItem>? items,
  }) {
    final result = RecentsItemList._();
    if (items != null) result.items.addAll(items);
    return result;
  }

  RecentsItemList._();

  factory RecentsItemList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecentsItemList()..mergeFromBuffer(data, registry);
  factory RecentsItemList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecentsItemList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecentsItemList',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: RecentsItemList.$_createMessage)
    ..pPM<RecentsListItem>(3, _omitFieldNames ? '' : 'items',
        subBuilder: RecentsListItem.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecentsItemList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecentsItemList copyWith(void Function(RecentsItemList) updates) =>
      super.copyWith((message) => updates(message as RecentsItemList))
          as RecentsItemList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RecentsItemList() / RecentsItemList.new instead')
  static RecentsItemList create() => RecentsItemList._();
  static $pb.GeneratedMessage $_createMessage() => RecentsItemList._();
  @$core.override
  RecentsItemList createEmptyInstance() => RecentsItemList._();
  @$core.pragma('dart2js:noInline')
  static RecentsItemList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RecentsItemList>(
          RecentsItemList.$_createMessage);
  static RecentsItemList? _defaultInstance;

  /// Fields 1-2 are unknown/unused
  @$pb.TagNumber(3)
  $pb.PbList<RecentsListItem> get items => $_getList(0);
}

class RecentsListItem extends $pb.GeneratedMessage {
  factory RecentsListItem({
    $core.String? uri,
    RecentsItemAttributes? attributes,
  }) {
    final result = RecentsListItem._();
    if (uri != null) result.uri = uri;
    if (attributes != null) result.attributes = attributes;
    return result;
  }

  RecentsListItem._();

  factory RecentsListItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecentsListItem()..mergeFromBuffer(data, registry);
  factory RecentsListItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecentsListItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecentsListItem',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: RecentsListItem.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
    ..aOM<RecentsItemAttributes>(2, _omitFieldNames ? '' : 'attributes',
        subBuilder: RecentsItemAttributes.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecentsListItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecentsListItem copyWith(void Function(RecentsListItem) updates) =>
      super.copyWith((message) => updates(message as RecentsListItem))
          as RecentsListItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RecentsListItem() / RecentsListItem.new instead')
  static RecentsListItem create() => RecentsListItem._();
  static $pb.GeneratedMessage $_createMessage() => RecentsListItem._();
  @$core.override
  RecentsListItem createEmptyInstance() => RecentsListItem._();
  @$core.pragma('dart2js:noInline')
  static RecentsListItem getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RecentsListItem>(
          RecentsListItem.$_createMessage);
  static RecentsListItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearUri() => $_clearField(1);

  @$pb.TagNumber(2)
  RecentsItemAttributes get attributes => $_getN(1);
  @$pb.TagNumber(2)
  set attributes(RecentsItemAttributes value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAttributes() => $_has(1);
  @$pb.TagNumber(2)
  void clearAttributes() => $_clearField(2);
  @$pb.TagNumber(2)
  RecentsItemAttributes ensureAttributes() => $_ensure(1);
}

class RecentsItemAttributes extends $pb.GeneratedMessage {
  factory RecentsItemAttributes({
    $core.Iterable<FormatAttribute>? formatAttributes,
  }) {
    final result = RecentsItemAttributes._();
    if (formatAttributes != null)
      result.formatAttributes.addAll(formatAttributes);
    return result;
  }

  RecentsItemAttributes._();

  factory RecentsItemAttributes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecentsItemAttributes()..mergeFromBuffer(data, registry);
  factory RecentsItemAttributes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecentsItemAttributes()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecentsItemAttributes',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: RecentsItemAttributes.$_createMessage)
    ..pPM<FormatAttribute>(11, _omitFieldNames ? '' : 'formatAttributes',
        subBuilder: FormatAttribute.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecentsItemAttributes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecentsItemAttributes copyWith(
          void Function(RecentsItemAttributes) updates) =>
      super.copyWith((message) => updates(message as RecentsItemAttributes))
          as RecentsItemAttributes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RecentsItemAttributes() / RecentsItemAttributes.new instead')
  static RecentsItemAttributes create() => RecentsItemAttributes._();
  static $pb.GeneratedMessage $_createMessage() => RecentsItemAttributes._();
  @$core.override
  RecentsItemAttributes createEmptyInstance() => RecentsItemAttributes._();
  @$core.pragma('dart2js:noInline')
  static RecentsItemAttributes getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RecentsItemAttributes>(
          RecentsItemAttributes.$_createMessage);
  static RecentsItemAttributes? _defaultInstance;

  /// Fields 1-10 are unknown/unused
  @$pb.TagNumber(11)
  $pb.PbList<FormatAttribute> get formatAttributes => $_getList(0);
}

class FormatAttribute extends $pb.GeneratedMessage {
  factory FormatAttribute({
    $core.String? key,
    $core.String? value,
  }) {
    final result = FormatAttribute._();
    if (key != null) result.key = key;
    if (value != null) result.value = value;
    return result;
  }

  FormatAttribute._();

  factory FormatAttribute.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FormatAttribute()..mergeFromBuffer(data, registry);
  factory FormatAttribute.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FormatAttribute()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormatAttribute',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: FormatAttribute.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormatAttribute clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormatAttribute copyWith(void Function(FormatAttribute) updates) =>
      super.copyWith((message) => updates(message as FormatAttribute))
          as FormatAttribute;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use FormatAttribute() / FormatAttribute.new instead')
  static FormatAttribute create() => FormatAttribute._();
  static $pb.GeneratedMessage $_createMessage() => FormatAttribute._();
  @$core.override
  FormatAttribute createEmptyInstance() => FormatAttribute._();
  @$core.pragma('dart2js:noInline')
  static FormatAttribute getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormatAttribute>(
          FormatAttribute.$_createMessage);
  static FormatAttribute? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
