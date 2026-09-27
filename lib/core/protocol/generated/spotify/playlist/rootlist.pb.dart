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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'rootlist.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'rootlist.pbenum.dart';

class SelectedListContent extends $pb.GeneratedMessage {
  factory SelectedListContent({
    $core.List<$core.int>? revision,
    $core.int? length,
    ListAttributes? attributes,
    ListItems? contents,
    $fixnum.Int64? timestamp,
    $core.String? ownerUsername,
    $fixnum.Int64? createdAt,
  }) {
    final result = SelectedListContent._();
    if (revision != null) result.revision = revision;
    if (length != null) result.length = length;
    if (attributes != null) result.attributes = attributes;
    if (contents != null) result.contents = contents;
    if (timestamp != null) result.timestamp = timestamp;
    if (ownerUsername != null) result.ownerUsername = ownerUsername;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  SelectedListContent._();

  factory SelectedListContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SelectedListContent()..mergeFromBuffer(data, registry);
  factory SelectedListContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SelectedListContent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SelectedListContent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: SelectedListContent.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OY)
    ..aI(2, _omitFieldNames ? '' : 'length')
    ..aOM<ListAttributes>(3, _omitFieldNames ? '' : 'attributes',
        subBuilder: ListAttributes.$_createMessage)
    ..aOM<ListItems>(5, _omitFieldNames ? '' : 'contents',
        subBuilder: ListItems.$_createMessage)
    ..aInt64(15, _omitFieldNames ? '' : 'timestamp')
    ..aOS(16, _omitFieldNames ? '' : 'ownerUsername')
    ..aInt64(21, _omitFieldNames ? '' : 'createdAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SelectedListContent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SelectedListContent copyWith(void Function(SelectedListContent) updates) =>
      super.copyWith((message) => updates(message as SelectedListContent))
          as SelectedListContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SelectedListContent() / SelectedListContent.new instead')
  static SelectedListContent create() => SelectedListContent._();
  static $pb.GeneratedMessage $_createMessage() => SelectedListContent._();
  @$core.override
  SelectedListContent createEmptyInstance() => SelectedListContent._();
  @$core.pragma('dart2js:noInline')
  static SelectedListContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SelectedListContent>(
          SelectedListContent.$_createMessage);
  static SelectedListContent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get revision => $_getN(0);
  @$pb.TagNumber(1)
  set revision($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get length => $_getIZ(1);
  @$pb.TagNumber(2)
  set length($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLength() => $_has(1);
  @$pb.TagNumber(2)
  void clearLength() => $_clearField(2);

  @$pb.TagNumber(3)
  ListAttributes get attributes => $_getN(2);
  @$pb.TagNumber(3)
  set attributes(ListAttributes value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAttributes() => $_has(2);
  @$pb.TagNumber(3)
  void clearAttributes() => $_clearField(3);
  @$pb.TagNumber(3)
  ListAttributes ensureAttributes() => $_ensure(2);

  /// field 4 unused
  @$pb.TagNumber(5)
  ListItems get contents => $_getN(3);
  @$pb.TagNumber(5)
  set contents(ListItems value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasContents() => $_has(3);
  @$pb.TagNumber(5)
  void clearContents() => $_clearField(5);
  @$pb.TagNumber(5)
  ListItems ensureContents() => $_ensure(3);

  /// field 6: diff (see playlist_detail.proto)
  /// field 7: sync_result
  /// field 8: resulting_revisions
  /// field 9: multiple_heads
  /// field 10: up_to_date
  /// field 14: nonces
  @$pb.TagNumber(15)
  $fixnum.Int64 get timestamp => $_getI64(4);
  @$pb.TagNumber(15)
  set timestamp($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(15)
  $core.bool hasTimestamp() => $_has(4);
  @$pb.TagNumber(15)
  void clearTimestamp() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get ownerUsername => $_getSZ(5);
  @$pb.TagNumber(16)
  set ownerUsername($core.String value) => $_setString(5, value);
  @$pb.TagNumber(16)
  $core.bool hasOwnerUsername() => $_has(5);
  @$pb.TagNumber(16)
  void clearOwnerUsername() => $_clearField(16);

  /// field 17: abuse_reporting_enabled
  /// field 18: capabilities
  /// field 19: geoblock
  /// field 20: changes_require_resync
  @$pb.TagNumber(21)
  $fixnum.Int64 get createdAt => $_getI64(6);
  @$pb.TagNumber(21)
  set createdAt($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(21)
  $core.bool hasCreatedAt() => $_has(6);
  @$pb.TagNumber(21)
  void clearCreatedAt() => $_clearField(21);
}

class ListItems extends $pb.GeneratedMessage {
  factory ListItems({
    $core.int? pos,
    $core.bool? truncated,
    $core.Iterable<Item>? items,
    $core.Iterable<MetaItem>? metaItems,
    $core.String? continuationToken,
  }) {
    final result = ListItems._();
    if (pos != null) result.pos = pos;
    if (truncated != null) result.truncated = truncated;
    if (items != null) result.items.addAll(items);
    if (metaItems != null) result.metaItems.addAll(metaItems);
    if (continuationToken != null) result.continuationToken = continuationToken;
    return result;
  }

  ListItems._();

  factory ListItems.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListItems()..mergeFromBuffer(data, registry);
  factory ListItems.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListItems()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListItems',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: ListItems.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'pos')
    ..aOB(2, _omitFieldNames ? '' : 'truncated')
    ..pPM<Item>(3, _omitFieldNames ? '' : 'items',
        subBuilder: Item.$_createMessage)
    ..pPM<MetaItem>(4, _omitFieldNames ? '' : 'metaItems',
        subBuilder: MetaItem.$_createMessage)
    ..aOS(6, _omitFieldNames ? '' : 'continuationToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListItems clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListItems copyWith(void Function(ListItems) updates) =>
      super.copyWith((message) => updates(message as ListItems)) as ListItems;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListItems() / ListItems.new instead')
  static ListItems create() => ListItems._();
  static $pb.GeneratedMessage $_createMessage() => ListItems._();
  @$core.override
  ListItems createEmptyInstance() => ListItems._();
  @$core.pragma('dart2js:noInline')
  static ListItems getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListItems>(ListItems.$_createMessage);
  static ListItems? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get pos => $_getIZ(0);
  @$pb.TagNumber(1)
  set pos($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPos() => $_has(0);
  @$pb.TagNumber(1)
  void clearPos() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get truncated => $_getBF(1);
  @$pb.TagNumber(2)
  set truncated($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTruncated() => $_has(1);
  @$pb.TagNumber(2)
  void clearTruncated() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<Item> get items => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<MetaItem> get metaItems => $_getList(3);

  /// field 5: available_signals
  @$pb.TagNumber(6)
  $core.String get continuationToken => $_getSZ(4);
  @$pb.TagNumber(6)
  set continuationToken($core.String value) => $_setString(4, value);
  @$pb.TagNumber(6)
  $core.bool hasContinuationToken() => $_has(4);
  @$pb.TagNumber(6)
  void clearContinuationToken() => $_clearField(6);
}

class Item extends $pb.GeneratedMessage {
  factory Item({
    $core.String? uri,
    ItemAttributes? attributes,
  }) {
    final result = Item._();
    if (uri != null) result.uri = uri;
    if (attributes != null) result.attributes = attributes;
    return result;
  }

  Item._();

  factory Item.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Item()..mergeFromBuffer(data, registry);
  factory Item.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Item()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Item',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: Item.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
    ..aOM<ItemAttributes>(2, _omitFieldNames ? '' : 'attributes',
        subBuilder: ItemAttributes.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Item clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Item copyWith(void Function(Item) updates) =>
      super.copyWith((message) => updates(message as Item)) as Item;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Item() / Item.new instead')
  static Item create() => Item._();
  static $pb.GeneratedMessage $_createMessage() => Item._();
  @$core.override
  Item createEmptyInstance() => Item._();
  @$core.pragma('dart2js:noInline')
  static Item getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Item>(Item.$_createMessage);
  static Item? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearUri() => $_clearField(1);

  @$pb.TagNumber(2)
  ItemAttributes get attributes => $_getN(1);
  @$pb.TagNumber(2)
  set attributes(ItemAttributes value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAttributes() => $_has(1);
  @$pb.TagNumber(2)
  void clearAttributes() => $_clearField(2);
  @$pb.TagNumber(2)
  ItemAttributes ensureAttributes() => $_ensure(1);
}

class ItemAttributes extends $pb.GeneratedMessage {
  factory ItemAttributes({
    $core.String? addedBy,
    $fixnum.Int64? timestamp,
    $fixnum.Int64? seenAt,
    $core.bool? public,
    $core.Iterable<FormatListAttribute>? formatAttributes,
    $core.List<$core.int>? itemId,
  }) {
    final result = ItemAttributes._();
    if (addedBy != null) result.addedBy = addedBy;
    if (timestamp != null) result.timestamp = timestamp;
    if (seenAt != null) result.seenAt = seenAt;
    if (public != null) result.public = public;
    if (formatAttributes != null)
      result.formatAttributes.addAll(formatAttributes);
    if (itemId != null) result.itemId = itemId;
    return result;
  }

  ItemAttributes._();

  factory ItemAttributes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ItemAttributes()..mergeFromBuffer(data, registry);
  factory ItemAttributes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ItemAttributes()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ItemAttributes',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: ItemAttributes.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'addedBy')
    ..aInt64(2, _omitFieldNames ? '' : 'timestamp')
    ..aInt64(9, _omitFieldNames ? '' : 'seenAt')
    ..aOB(10, _omitFieldNames ? '' : 'public')
    ..pPM<FormatListAttribute>(11, _omitFieldNames ? '' : 'formatAttributes',
        subBuilder: FormatListAttribute.$_createMessage)
    ..a<$core.List<$core.int>>(
        12, _omitFieldNames ? '' : 'itemId', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ItemAttributes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ItemAttributes copyWith(void Function(ItemAttributes) updates) =>
      super.copyWith((message) => updates(message as ItemAttributes))
          as ItemAttributes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ItemAttributes() / ItemAttributes.new instead')
  static ItemAttributes create() => ItemAttributes._();
  static $pb.GeneratedMessage $_createMessage() => ItemAttributes._();
  @$core.override
  ItemAttributes createEmptyInstance() => ItemAttributes._();
  @$core.pragma('dart2js:noInline')
  static ItemAttributes getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ItemAttributes>(
          ItemAttributes.$_createMessage);
  static ItemAttributes? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get addedBy => $_getSZ(0);
  @$pb.TagNumber(1)
  set addedBy($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAddedBy() => $_has(0);
  @$pb.TagNumber(1)
  void clearAddedBy() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get timestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set timestamp($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestamp() => $_clearField(2);

  /// field 3-8 unused
  @$pb.TagNumber(9)
  $fixnum.Int64 get seenAt => $_getI64(2);
  @$pb.TagNumber(9)
  set seenAt($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(9)
  $core.bool hasSeenAt() => $_has(2);
  @$pb.TagNumber(9)
  void clearSeenAt() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get public => $_getBF(3);
  @$pb.TagNumber(10)
  set public($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(10)
  $core.bool hasPublic() => $_has(3);
  @$pb.TagNumber(10)
  void clearPublic() => $_clearField(10);

  @$pb.TagNumber(11)
  $pb.PbList<FormatListAttribute> get formatAttributes => $_getList(4);

  @$pb.TagNumber(12)
  $core.List<$core.int> get itemId => $_getN(5);
  @$pb.TagNumber(12)
  set itemId($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(12)
  $core.bool hasItemId() => $_has(5);
  @$pb.TagNumber(12)
  void clearItemId() => $_clearField(12);
}

class ListAttributes extends $pb.GeneratedMessage {
  factory ListAttributes({
    $core.String? name,
    $core.String? description,
    $core.List<$core.int>? picture,
    $core.bool? collaborative,
    $core.String? pl3Version,
    $core.bool? deletedByOwner,
    $core.String? clientId,
    $core.String? format,
    $core.Iterable<FormatListAttribute>? formatAttributes,
    $core.Iterable<PictureSize>? pictureSize,
    $core.bool? recoverable,
    $core.bool? isUserCreated,
  }) {
    final result = ListAttributes._();
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (picture != null) result.picture = picture;
    if (collaborative != null) result.collaborative = collaborative;
    if (pl3Version != null) result.pl3Version = pl3Version;
    if (deletedByOwner != null) result.deletedByOwner = deletedByOwner;
    if (clientId != null) result.clientId = clientId;
    if (format != null) result.format = format;
    if (formatAttributes != null)
      result.formatAttributes.addAll(formatAttributes);
    if (pictureSize != null) result.pictureSize.addAll(pictureSize);
    if (recoverable != null) result.recoverable = recoverable;
    if (isUserCreated != null) result.isUserCreated = isUserCreated;
    return result;
  }

  ListAttributes._();

  factory ListAttributes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListAttributes()..mergeFromBuffer(data, registry);
  factory ListAttributes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListAttributes()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListAttributes',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: ListAttributes.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'picture', $pb.PbFieldType.OY)
    ..aOB(4, _omitFieldNames ? '' : 'collaborative')
    ..aOS(5, _omitFieldNames ? '' : 'pl3Version')
    ..aOB(6, _omitFieldNames ? '' : 'deletedByOwner')
    ..aOS(10, _omitFieldNames ? '' : 'clientId')
    ..aOS(11, _omitFieldNames ? '' : 'format')
    ..pPM<FormatListAttribute>(12, _omitFieldNames ? '' : 'formatAttributes',
        subBuilder: FormatListAttribute.$_createMessage)
    ..pPM<PictureSize>(13, _omitFieldNames ? '' : 'pictureSize',
        subBuilder: PictureSize.$_createMessage)
    ..aOB(17, _omitFieldNames ? '' : 'recoverable')
    ..aOB(18, _omitFieldNames ? '' : 'isUserCreated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListAttributes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListAttributes copyWith(void Function(ListAttributes) updates) =>
      super.copyWith((message) => updates(message as ListAttributes))
          as ListAttributes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListAttributes() / ListAttributes.new instead')
  static ListAttributes create() => ListAttributes._();
  static $pb.GeneratedMessage $_createMessage() => ListAttributes._();
  @$core.override
  ListAttributes createEmptyInstance() => ListAttributes._();
  @$core.pragma('dart2js:noInline')
  static ListAttributes getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListAttributes>(
          ListAttributes.$_createMessage);
  static ListAttributes? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get description => $_getSZ(1);
  @$pb.TagNumber(2)
  set description($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get picture => $_getN(2);
  @$pb.TagNumber(3)
  set picture($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPicture() => $_has(2);
  @$pb.TagNumber(3)
  void clearPicture() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get collaborative => $_getBF(3);
  @$pb.TagNumber(4)
  set collaborative($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCollaborative() => $_has(3);
  @$pb.TagNumber(4)
  void clearCollaborative() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get pl3Version => $_getSZ(4);
  @$pb.TagNumber(5)
  set pl3Version($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPl3Version() => $_has(4);
  @$pb.TagNumber(5)
  void clearPl3Version() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get deletedByOwner => $_getBF(5);
  @$pb.TagNumber(6)
  set deletedByOwner($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDeletedByOwner() => $_has(5);
  @$pb.TagNumber(6)
  void clearDeletedByOwner() => $_clearField(6);

  /// fields 7-9 unused
  @$pb.TagNumber(10)
  $core.String get clientId => $_getSZ(6);
  @$pb.TagNumber(10)
  set clientId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(10)
  $core.bool hasClientId() => $_has(6);
  @$pb.TagNumber(10)
  void clearClientId() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get format => $_getSZ(7);
  @$pb.TagNumber(11)
  set format($core.String value) => $_setString(7, value);
  @$pb.TagNumber(11)
  $core.bool hasFormat() => $_has(7);
  @$pb.TagNumber(11)
  void clearFormat() => $_clearField(11);

  @$pb.TagNumber(12)
  $pb.PbList<FormatListAttribute> get formatAttributes => $_getList(8);

  @$pb.TagNumber(13)
  $pb.PbList<PictureSize> get pictureSize => $_getList(9);

  /// field 14: sequence_context_template
  /// field 15: ai_curation_reference_id
  /// field 16: item_id_algorithm
  @$pb.TagNumber(17)
  $core.bool get recoverable => $_getBF(10);
  @$pb.TagNumber(17)
  set recoverable($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(17)
  $core.bool hasRecoverable() => $_has(10);
  @$pb.TagNumber(17)
  void clearRecoverable() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.bool get isUserCreated => $_getBF(11);
  @$pb.TagNumber(18)
  set isUserCreated($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(18)
  $core.bool hasIsUserCreated() => $_has(11);
  @$pb.TagNumber(18)
  void clearIsUserCreated() => $_clearField(18);
}

class FormatListAttribute extends $pb.GeneratedMessage {
  factory FormatListAttribute({
    $core.String? key,
    $core.String? value,
  }) {
    final result = FormatListAttribute._();
    if (key != null) result.key = key;
    if (value != null) result.value = value;
    return result;
  }

  FormatListAttribute._();

  factory FormatListAttribute.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FormatListAttribute()..mergeFromBuffer(data, registry);
  factory FormatListAttribute.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FormatListAttribute()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormatListAttribute',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: FormatListAttribute.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormatListAttribute clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormatListAttribute copyWith(void Function(FormatListAttribute) updates) =>
      super.copyWith((message) => updates(message as FormatListAttribute))
          as FormatListAttribute;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use FormatListAttribute() / FormatListAttribute.new instead')
  static FormatListAttribute create() => FormatListAttribute._();
  static $pb.GeneratedMessage $_createMessage() => FormatListAttribute._();
  @$core.override
  FormatListAttribute createEmptyInstance() => FormatListAttribute._();
  @$core.pragma('dart2js:noInline')
  static FormatListAttribute getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormatListAttribute>(
          FormatListAttribute.$_createMessage);
  static FormatListAttribute? _defaultInstance;

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

class PictureSize extends $pb.GeneratedMessage {
  factory PictureSize({
    $core.String? targetName,
    $core.String? url,
  }) {
    final result = PictureSize._();
    if (targetName != null) result.targetName = targetName;
    if (url != null) result.url = url;
    return result;
  }

  PictureSize._();

  factory PictureSize.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PictureSize()..mergeFromBuffer(data, registry);
  factory PictureSize.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PictureSize()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PictureSize',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: PictureSize.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'targetName')
    ..aOS(2, _omitFieldNames ? '' : 'url')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PictureSize clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PictureSize copyWith(void Function(PictureSize) updates) =>
      super.copyWith((message) => updates(message as PictureSize))
          as PictureSize;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PictureSize() / PictureSize.new instead')
  static PictureSize create() => PictureSize._();
  static $pb.GeneratedMessage $_createMessage() => PictureSize._();
  @$core.override
  PictureSize createEmptyInstance() => PictureSize._();
  @$core.pragma('dart2js:noInline')
  static PictureSize getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PictureSize>(
          PictureSize.$_createMessage);
  static PictureSize? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get targetName => $_getSZ(0);
  @$pb.TagNumber(1)
  set targetName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTargetName() => $_has(0);
  @$pb.TagNumber(1)
  void clearTargetName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get url => $_getSZ(1);
  @$pb.TagNumber(2)
  set url($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearUrl() => $_clearField(2);
}

class MetaItem extends $pb.GeneratedMessage {
  factory MetaItem({
    $core.List<$core.int>? revision,
    ListAttributes? attributes,
    $core.int? length,
    $fixnum.Int64? timestamp,
    $core.String? ownerUsername,
    $core.bool? abuseReportingEnabled,
    Capabilities? capabilities,
    $core.Iterable<GeoblockBlockingType>? geoblock,
    $core.int? statusCode,
  }) {
    final result = MetaItem._();
    if (revision != null) result.revision = revision;
    if (attributes != null) result.attributes = attributes;
    if (length != null) result.length = length;
    if (timestamp != null) result.timestamp = timestamp;
    if (ownerUsername != null) result.ownerUsername = ownerUsername;
    if (abuseReportingEnabled != null)
      result.abuseReportingEnabled = abuseReportingEnabled;
    if (capabilities != null) result.capabilities = capabilities;
    if (geoblock != null) result.geoblock.addAll(geoblock);
    if (statusCode != null) result.statusCode = statusCode;
    return result;
  }

  MetaItem._();

  factory MetaItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MetaItem()..mergeFromBuffer(data, registry);
  factory MetaItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MetaItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MetaItem',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: MetaItem.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OY)
    ..aOM<ListAttributes>(2, _omitFieldNames ? '' : 'attributes',
        subBuilder: ListAttributes.$_createMessage)
    ..aI(3, _omitFieldNames ? '' : 'length')
    ..aInt64(4, _omitFieldNames ? '' : 'timestamp')
    ..aOS(5, _omitFieldNames ? '' : 'ownerUsername')
    ..aOB(6, _omitFieldNames ? '' : 'abuseReportingEnabled')
    ..aOM<Capabilities>(7, _omitFieldNames ? '' : 'capabilities',
        subBuilder: Capabilities.$_createMessage)
    ..pc<GeoblockBlockingType>(
        8, _omitFieldNames ? '' : 'geoblock', $pb.PbFieldType.KE,
        valueOf: GeoblockBlockingType.valueOf,
        enumValues: GeoblockBlockingType.values,
        defaultEnumValue:
            GeoblockBlockingType.GEOBLOCK_BLOCKING_TYPE_UNSPECIFIED)
    ..aI(9, _omitFieldNames ? '' : 'statusCode')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MetaItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MetaItem copyWith(void Function(MetaItem) updates) =>
      super.copyWith((message) => updates(message as MetaItem)) as MetaItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MetaItem() / MetaItem.new instead')
  static MetaItem create() => MetaItem._();
  static $pb.GeneratedMessage $_createMessage() => MetaItem._();
  @$core.override
  MetaItem createEmptyInstance() => MetaItem._();
  @$core.pragma('dart2js:noInline')
  static MetaItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MetaItem>(MetaItem.$_createMessage);
  static MetaItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get revision => $_getN(0);
  @$pb.TagNumber(1)
  set revision($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  ListAttributes get attributes => $_getN(1);
  @$pb.TagNumber(2)
  set attributes(ListAttributes value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAttributes() => $_has(1);
  @$pb.TagNumber(2)
  void clearAttributes() => $_clearField(2);
  @$pb.TagNumber(2)
  ListAttributes ensureAttributes() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get length => $_getIZ(2);
  @$pb.TagNumber(3)
  set length($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLength() => $_has(2);
  @$pb.TagNumber(3)
  void clearLength() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get timestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set timestamp($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimestamp() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get ownerUsername => $_getSZ(4);
  @$pb.TagNumber(5)
  set ownerUsername($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOwnerUsername() => $_has(4);
  @$pb.TagNumber(5)
  void clearOwnerUsername() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get abuseReportingEnabled => $_getBF(5);
  @$pb.TagNumber(6)
  set abuseReportingEnabled($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAbuseReportingEnabled() => $_has(5);
  @$pb.TagNumber(6)
  void clearAbuseReportingEnabled() => $_clearField(6);

  @$pb.TagNumber(7)
  Capabilities get capabilities => $_getN(6);
  @$pb.TagNumber(7)
  set capabilities(Capabilities value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasCapabilities() => $_has(6);
  @$pb.TagNumber(7)
  void clearCapabilities() => $_clearField(7);
  @$pb.TagNumber(7)
  Capabilities ensureCapabilities() => $_ensure(6);

  @$pb.TagNumber(8)
  $pb.PbList<GeoblockBlockingType> get geoblock => $_getList(7);

  @$pb.TagNumber(9)
  $core.int get statusCode => $_getIZ(8);
  @$pb.TagNumber(9)
  set statusCode($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasStatusCode() => $_has(8);
  @$pb.TagNumber(9)
  void clearStatusCode() => $_clearField(9);
}

class Capabilities extends $pb.GeneratedMessage {
  factory Capabilities({
    $core.bool? canView,
    $core.bool? canAdministratePermissions,
    $core.bool? canEditMetadata,
    $core.bool? canEditItems,
    $core.bool? canCancelMembership,
    $core.Iterable<PermissionLevel>? grantableLevels,
    ListAttributeCapabilities? listAttributeCapabilities,
  }) {
    final result = Capabilities._();
    if (canView != null) result.canView = canView;
    if (canAdministratePermissions != null)
      result.canAdministratePermissions = canAdministratePermissions;
    if (canEditMetadata != null) result.canEditMetadata = canEditMetadata;
    if (canEditItems != null) result.canEditItems = canEditItems;
    if (canCancelMembership != null)
      result.canCancelMembership = canCancelMembership;
    if (grantableLevels != null) result.grantableLevels.addAll(grantableLevels);
    if (listAttributeCapabilities != null)
      result.listAttributeCapabilities = listAttributeCapabilities;
    return result;
  }

  Capabilities._();

  factory Capabilities.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Capabilities()..mergeFromBuffer(data, registry);
  factory Capabilities.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Capabilities()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Capabilities',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: Capabilities.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'canView')
    ..aOB(2, _omitFieldNames ? '' : 'canAdministratePermissions')
    ..aOB(4, _omitFieldNames ? '' : 'canEditMetadata')
    ..aOB(5, _omitFieldNames ? '' : 'canEditItems')
    ..aOB(6, _omitFieldNames ? '' : 'canCancelMembership')
    ..pc<PermissionLevel>(
        7, _omitFieldNames ? '' : 'grantableLevels', $pb.PbFieldType.KE,
        valueOf: PermissionLevel.valueOf,
        enumValues: PermissionLevel.values,
        defaultEnumValue: PermissionLevel.PERMISSION_LEVEL_UNKNOWN)
    ..aOM<ListAttributeCapabilities>(
        8, _omitFieldNames ? '' : 'listAttributeCapabilities',
        subBuilder: ListAttributeCapabilities.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Capabilities clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Capabilities copyWith(void Function(Capabilities) updates) =>
      super.copyWith((message) => updates(message as Capabilities))
          as Capabilities;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Capabilities() / Capabilities.new instead')
  static Capabilities create() => Capabilities._();
  static $pb.GeneratedMessage $_createMessage() => Capabilities._();
  @$core.override
  Capabilities createEmptyInstance() => Capabilities._();
  @$core.pragma('dart2js:noInline')
  static Capabilities getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Capabilities>(
          Capabilities.$_createMessage);
  static Capabilities? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get canView => $_getBF(0);
  @$pb.TagNumber(1)
  set canView($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCanView() => $_has(0);
  @$pb.TagNumber(1)
  void clearCanView() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get canAdministratePermissions => $_getBF(1);
  @$pb.TagNumber(2)
  set canAdministratePermissions($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCanAdministratePermissions() => $_has(1);
  @$pb.TagNumber(2)
  void clearCanAdministratePermissions() => $_clearField(2);

  /// field 3 unused
  @$pb.TagNumber(4)
  $core.bool get canEditMetadata => $_getBF(2);
  @$pb.TagNumber(4)
  set canEditMetadata($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(4)
  $core.bool hasCanEditMetadata() => $_has(2);
  @$pb.TagNumber(4)
  void clearCanEditMetadata() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get canEditItems => $_getBF(3);
  @$pb.TagNumber(5)
  set canEditItems($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(5)
  $core.bool hasCanEditItems() => $_has(3);
  @$pb.TagNumber(5)
  void clearCanEditItems() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get canCancelMembership => $_getBF(4);
  @$pb.TagNumber(6)
  set canCancelMembership($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(6)
  $core.bool hasCanCancelMembership() => $_has(4);
  @$pb.TagNumber(6)
  void clearCanCancelMembership() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<PermissionLevel> get grantableLevels => $_getList(5);

  @$pb.TagNumber(8)
  ListAttributeCapabilities get listAttributeCapabilities => $_getN(6);
  @$pb.TagNumber(8)
  set listAttributeCapabilities(ListAttributeCapabilities value) =>
      $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasListAttributeCapabilities() => $_has(6);
  @$pb.TagNumber(8)
  void clearListAttributeCapabilities() => $_clearField(8);
  @$pb.TagNumber(8)
  ListAttributeCapabilities ensureListAttributeCapabilities() => $_ensure(6);
}

class ListAttributeCapabilities extends $pb.GeneratedMessage {
  factory ListAttributeCapabilities({
    AttributeCapabilities? name,
    AttributeCapabilities? description,
    AttributeCapabilities? picture,
    AttributeCapabilities? collaborative,
  }) {
    final result = ListAttributeCapabilities._();
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (picture != null) result.picture = picture;
    if (collaborative != null) result.collaborative = collaborative;
    return result;
  }

  ListAttributeCapabilities._();

  factory ListAttributeCapabilities.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListAttributeCapabilities()..mergeFromBuffer(data, registry);
  factory ListAttributeCapabilities.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListAttributeCapabilities()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListAttributeCapabilities',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: ListAttributeCapabilities.$_createMessage)
    ..aOM<AttributeCapabilities>(1, _omitFieldNames ? '' : 'name',
        subBuilder: AttributeCapabilities.$_createMessage)
    ..aOM<AttributeCapabilities>(2, _omitFieldNames ? '' : 'description',
        subBuilder: AttributeCapabilities.$_createMessage)
    ..aOM<AttributeCapabilities>(3, _omitFieldNames ? '' : 'picture',
        subBuilder: AttributeCapabilities.$_createMessage)
    ..aOM<AttributeCapabilities>(4, _omitFieldNames ? '' : 'collaborative',
        subBuilder: AttributeCapabilities.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListAttributeCapabilities clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListAttributeCapabilities copyWith(
          void Function(ListAttributeCapabilities) updates) =>
      super.copyWith((message) => updates(message as ListAttributeCapabilities))
          as ListAttributeCapabilities;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListAttributeCapabilities() / ListAttributeCapabilities.new instead')
  static ListAttributeCapabilities create() => ListAttributeCapabilities._();
  static $pb.GeneratedMessage $_createMessage() =>
      ListAttributeCapabilities._();
  @$core.override
  ListAttributeCapabilities createEmptyInstance() =>
      ListAttributeCapabilities._();
  @$core.pragma('dart2js:noInline')
  static ListAttributeCapabilities getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListAttributeCapabilities>(
          ListAttributeCapabilities.$_createMessage);
  static ListAttributeCapabilities? _defaultInstance;

  @$pb.TagNumber(1)
  AttributeCapabilities get name => $_getN(0);
  @$pb.TagNumber(1)
  set name(AttributeCapabilities value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
  @$pb.TagNumber(1)
  AttributeCapabilities ensureName() => $_ensure(0);

  @$pb.TagNumber(2)
  AttributeCapabilities get description => $_getN(1);
  @$pb.TagNumber(2)
  set description(AttributeCapabilities value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => $_clearField(2);
  @$pb.TagNumber(2)
  AttributeCapabilities ensureDescription() => $_ensure(1);

  @$pb.TagNumber(3)
  AttributeCapabilities get picture => $_getN(2);
  @$pb.TagNumber(3)
  set picture(AttributeCapabilities value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPicture() => $_has(2);
  @$pb.TagNumber(3)
  void clearPicture() => $_clearField(3);
  @$pb.TagNumber(3)
  AttributeCapabilities ensurePicture() => $_ensure(2);

  @$pb.TagNumber(4)
  AttributeCapabilities get collaborative => $_getN(3);
  @$pb.TagNumber(4)
  set collaborative(AttributeCapabilities value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCollaborative() => $_has(3);
  @$pb.TagNumber(4)
  void clearCollaborative() => $_clearField(4);
  @$pb.TagNumber(4)
  AttributeCapabilities ensureCollaborative() => $_ensure(3);
}

class AttributeCapabilities extends $pb.GeneratedMessage {
  factory AttributeCapabilities({
    $core.bool? canEdit,
  }) {
    final result = AttributeCapabilities._();
    if (canEdit != null) result.canEdit = canEdit;
    return result;
  }

  AttributeCapabilities._();

  factory AttributeCapabilities.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttributeCapabilities()..mergeFromBuffer(data, registry);
  factory AttributeCapabilities.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttributeCapabilities()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AttributeCapabilities',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: AttributeCapabilities.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'canEdit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttributeCapabilities clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttributeCapabilities copyWith(
          void Function(AttributeCapabilities) updates) =>
      super.copyWith((message) => updates(message as AttributeCapabilities))
          as AttributeCapabilities;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use AttributeCapabilities() / AttributeCapabilities.new instead')
  static AttributeCapabilities create() => AttributeCapabilities._();
  static $pb.GeneratedMessage $_createMessage() => AttributeCapabilities._();
  @$core.override
  AttributeCapabilities createEmptyInstance() => AttributeCapabilities._();
  @$core.pragma('dart2js:noInline')
  static AttributeCapabilities getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AttributeCapabilities>(
          AttributeCapabilities.$_createMessage);
  static AttributeCapabilities? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get canEdit => $_getBF(0);
  @$pb.TagNumber(1)
  set canEdit($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCanEdit() => $_has(0);
  @$pb.TagNumber(1)
  void clearCanEdit() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
