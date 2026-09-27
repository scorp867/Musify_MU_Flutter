// This is a generated file - do not edit.
//
// Generated from spotify/collection/collection_paging.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class PageRequest extends $pb.GeneratedMessage {
  factory PageRequest({
    $core.String? username,
    $core.String? setName,
    $core.int? limit,
  }) {
    final result = PageRequest._();
    if (username != null) result.username = username;
    if (setName != null) result.setName = setName;
    if (limit != null) result.limit = limit;
    return result;
  }

  PageRequest._();

  factory PageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PageRequest()..mergeFromBuffer(data, registry);
  factory PageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PageRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.collection.v2'),
      createEmptyInstance: PageRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..aOS(2, _omitFieldNames ? '' : 'setName')
    ..aI(4, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OS3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PageRequest copyWith(void Function(PageRequest) updates) =>
      super.copyWith((message) => updates(message as PageRequest))
          as PageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PageRequest() / PageRequest.new instead')
  static PageRequest create() => PageRequest._();
  static $pb.GeneratedMessage $_createMessage() => PageRequest._();
  @$core.override
  PageRequest createEmptyInstance() => PageRequest._();
  @$core.pragma('dart2js:noInline')
  static PageRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PageRequest>(
          PageRequest.$_createMessage);
  static PageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get setName => $_getSZ(1);
  @$pb.TagNumber(2)
  set setName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSetName() => $_has(1);
  @$pb.TagNumber(2)
  void clearSetName() => $_clearField(2);

  /// field 3 is unused/unknown
  @$pb.TagNumber(4)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(4)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(4)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(4)
  void clearLimit() => $_clearField(4);
}

class PageResponse extends $pb.GeneratedMessage {
  factory PageResponse({
    $core.Iterable<CollectionItem>? items,
    $core.String? syncToken,
  }) {
    final result = PageResponse._();
    if (items != null) result.items.addAll(items);
    if (syncToken != null) result.syncToken = syncToken;
    return result;
  }

  PageResponse._();

  factory PageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PageResponse()..mergeFromBuffer(data, registry);
  factory PageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PageResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PageResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.collection.v2'),
      createEmptyInstance: PageResponse.$_createMessage)
    ..pPM<CollectionItem>(1, _omitFieldNames ? '' : 'items',
        subBuilder: CollectionItem.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'syncToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PageResponse copyWith(void Function(PageResponse) updates) =>
      super.copyWith((message) => updates(message as PageResponse))
          as PageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PageResponse() / PageResponse.new instead')
  static PageResponse create() => PageResponse._();
  static $pb.GeneratedMessage $_createMessage() => PageResponse._();
  @$core.override
  PageResponse createEmptyInstance() => PageResponse._();
  @$core.pragma('dart2js:noInline')
  static PageResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PageResponse>(
          PageResponse.$_createMessage);
  static PageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CollectionItem> get items => $_getList(0);

  /// field 2 is unused/unknown
  @$pb.TagNumber(3)
  $core.String get syncToken => $_getSZ(1);
  @$pb.TagNumber(3)
  set syncToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(3)
  $core.bool hasSyncToken() => $_has(1);
  @$pb.TagNumber(3)
  void clearSyncToken() => $_clearField(3);
}

class CollectionItem extends $pb.GeneratedMessage {
  factory CollectionItem({
    $core.String? uri,
    $fixnum.Int64? addedAt,
  }) {
    final result = CollectionItem._();
    if (uri != null) result.uri = uri;
    if (addedAt != null) result.addedAt = addedAt;
    return result;
  }

  CollectionItem._();

  factory CollectionItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CollectionItem()..mergeFromBuffer(data, registry);
  factory CollectionItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CollectionItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CollectionItem',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.collection.v2'),
      createEmptyInstance: CollectionItem.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
    ..aInt64(2, _omitFieldNames ? '' : 'addedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CollectionItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CollectionItem copyWith(void Function(CollectionItem) updates) =>
      super.copyWith((message) => updates(message as CollectionItem))
          as CollectionItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CollectionItem() / CollectionItem.new instead')
  static CollectionItem create() => CollectionItem._();
  static $pb.GeneratedMessage $_createMessage() => CollectionItem._();
  @$core.override
  CollectionItem createEmptyInstance() => CollectionItem._();
  @$core.pragma('dart2js:noInline')
  static CollectionItem getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CollectionItem>(
          CollectionItem.$_createMessage);
  static CollectionItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearUri() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get addedAt => $_getI64(1);
  @$pb.TagNumber(2)
  set addedAt($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAddedAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearAddedAt() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
