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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class RecentsListResponse extends $pb.GeneratedMessage {
  factory RecentsListResponse({
    $core.List<$core.int>? revision,
    $core.int? length,
    RecentsListAttributes? listAttributes,
    RecentsItemList? list,
    $core.bool? multipleHeads,
    $core.bool? upToDate,
    $core.Iterable<$fixnum.Int64>? nonces,
    $fixnum.Int64? timestamp,
    $core.String? ownerUsername,
    $core.bool? abuseReportingEnabled,
    $core.Iterable<$core.int>? geoblock,
    $core.bool? changesRequireResync,
    $fixnum.Int64? createdAt,
  }) {
    final result = RecentsListResponse._();
    if (revision != null) result.revision = revision;
    if (length != null) result.length = length;
    if (listAttributes != null) result.listAttributes = listAttributes;
    if (list != null) result.list = list;
    if (multipleHeads != null) result.multipleHeads = multipleHeads;
    if (upToDate != null) result.upToDate = upToDate;
    if (nonces != null) result.nonces.addAll(nonces);
    if (timestamp != null) result.timestamp = timestamp;
    if (ownerUsername != null) result.ownerUsername = ownerUsername;
    if (abuseReportingEnabled != null)
      result.abuseReportingEnabled = abuseReportingEnabled;
    if (geoblock != null) result.geoblock.addAll(geoblock);
    if (changesRequireResync != null)
      result.changesRequireResync = changesRequireResync;
    if (createdAt != null) result.createdAt = createdAt;
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
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OY)
    ..aI(2, _omitFieldNames ? '' : 'length')
    ..aOM<RecentsListAttributes>(3, _omitFieldNames ? '' : 'listAttributes',
        subBuilder: RecentsListAttributes.$_createMessage)
    ..aOM<RecentsItemList>(5, _omitFieldNames ? '' : 'list',
        subBuilder: RecentsItemList.$_createMessage)
    ..aOB(9, _omitFieldNames ? '' : 'multipleHeads')
    ..aOB(10, _omitFieldNames ? '' : 'upToDate')
    ..p<$fixnum.Int64>(14, _omitFieldNames ? '' : 'nonces', $pb.PbFieldType.K6)
    ..aInt64(15, _omitFieldNames ? '' : 'timestamp')
    ..aOS(16, _omitFieldNames ? '' : 'ownerUsername')
    ..aOB(17, _omitFieldNames ? '' : 'abuseReportingEnabled')
    ..p<$core.int>(19, _omitFieldNames ? '' : 'geoblock', $pb.PbFieldType.K3)
    ..aOB(20, _omitFieldNames ? '' : 'changesRequireResync')
    ..aInt64(21, _omitFieldNames ? '' : 'createdAt')
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
  RecentsListAttributes get listAttributes => $_getN(2);
  @$pb.TagNumber(3)
  set listAttributes(RecentsListAttributes value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasListAttributes() => $_has(2);
  @$pb.TagNumber(3)
  void clearListAttributes() => $_clearField(3);
  @$pb.TagNumber(3)
  RecentsListAttributes ensureListAttributes() => $_ensure(2);

  /// Field 4 reserved
  @$pb.TagNumber(5)
  RecentsItemList get list => $_getN(3);
  @$pb.TagNumber(5)
  set list(RecentsItemList value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasList() => $_has(3);
  @$pb.TagNumber(5)
  void clearList() => $_clearField(5);
  @$pb.TagNumber(5)
  RecentsItemList ensureList() => $_ensure(3);

  /// Fields 6-7: Diff/SyncResult (unused)
  /// Field 8: resulting_revisions (unused)
  @$pb.TagNumber(9)
  $core.bool get multipleHeads => $_getBF(4);
  @$pb.TagNumber(9)
  set multipleHeads($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(9)
  $core.bool hasMultipleHeads() => $_has(4);
  @$pb.TagNumber(9)
  void clearMultipleHeads() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get upToDate => $_getBF(5);
  @$pb.TagNumber(10)
  set upToDate($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(10)
  $core.bool hasUpToDate() => $_has(5);
  @$pb.TagNumber(10)
  void clearUpToDate() => $_clearField(10);

  /// Fields 11-13 reserved
  @$pb.TagNumber(14)
  $pb.PbList<$fixnum.Int64> get nonces => $_getList(6);

  @$pb.TagNumber(15)
  $fixnum.Int64 get timestamp => $_getI64(7);
  @$pb.TagNumber(15)
  set timestamp($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(15)
  $core.bool hasTimestamp() => $_has(7);
  @$pb.TagNumber(15)
  void clearTimestamp() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get ownerUsername => $_getSZ(8);
  @$pb.TagNumber(16)
  set ownerUsername($core.String value) => $_setString(8, value);
  @$pb.TagNumber(16)
  $core.bool hasOwnerUsername() => $_has(8);
  @$pb.TagNumber(16)
  void clearOwnerUsername() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.bool get abuseReportingEnabled => $_getBF(9);
  @$pb.TagNumber(17)
  set abuseReportingEnabled($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(17)
  $core.bool hasAbuseReportingEnabled() => $_has(9);
  @$pb.TagNumber(17)
  void clearAbuseReportingEnabled() => $_clearField(17);

  /// Field 18: Capabilities (unused)
  @$pb.TagNumber(19)
  $pb.PbList<$core.int> get geoblock => $_getList(10);

  @$pb.TagNumber(20)
  $core.bool get changesRequireResync => $_getBF(11);
  @$pb.TagNumber(20)
  set changesRequireResync($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(20)
  $core.bool hasChangesRequireResync() => $_has(11);
  @$pb.TagNumber(20)
  void clearChangesRequireResync() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get createdAt => $_getI64(12);
  @$pb.TagNumber(21)
  set createdAt($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(21)
  $core.bool hasCreatedAt() => $_has(12);
  @$pb.TagNumber(21)
  void clearCreatedAt() => $_clearField(21);
}

class RecentsListAttributes extends $pb.GeneratedMessage {
  factory RecentsListAttributes({
    $core.String? name,
    $core.String? description,
    $core.List<$core.int>? picture,
    $core.bool? collaborative,
    $core.String? pl3Version,
    $core.bool? deletedByOwner,
    $core.String? clientId,
    $core.String? format,
    $core.Iterable<FormatAttribute>? formatAttributes,
  }) {
    final result = RecentsListAttributes._();
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
    return result;
  }

  RecentsListAttributes._();

  factory RecentsListAttributes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecentsListAttributes()..mergeFromBuffer(data, registry);
  factory RecentsListAttributes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecentsListAttributes()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecentsListAttributes',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: RecentsListAttributes.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'picture', $pb.PbFieldType.OY)
    ..aOB(4, _omitFieldNames ? '' : 'collaborative')
    ..aOS(5, _omitFieldNames ? '' : 'pl3Version')
    ..aOB(6, _omitFieldNames ? '' : 'deletedByOwner')
    ..aOS(10, _omitFieldNames ? '' : 'clientId')
    ..aOS(11, _omitFieldNames ? '' : 'format')
    ..pPM<FormatAttribute>(12, _omitFieldNames ? '' : 'formatAttributes',
        subBuilder: FormatAttribute.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecentsListAttributes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecentsListAttributes copyWith(
          void Function(RecentsListAttributes) updates) =>
      super.copyWith((message) => updates(message as RecentsListAttributes))
          as RecentsListAttributes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RecentsListAttributes() / RecentsListAttributes.new instead')
  static RecentsListAttributes create() => RecentsListAttributes._();
  static $pb.GeneratedMessage $_createMessage() => RecentsListAttributes._();
  @$core.override
  RecentsListAttributes createEmptyInstance() => RecentsListAttributes._();
  @$core.pragma('dart2js:noInline')
  static RecentsListAttributes getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RecentsListAttributes>(
          RecentsListAttributes.$_createMessage);
  static RecentsListAttributes? _defaultInstance;

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

  /// Fields 7-9 unused
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
  $pb.PbList<FormatAttribute> get formatAttributes => $_getList(8);
}

class RecentsItemList extends $pb.GeneratedMessage {
  factory RecentsItemList({
    $core.int? pos,
    $core.bool? truncated,
    $core.Iterable<RecentsListItem>? items,
    $core.String? continuationToken,
  }) {
    final result = RecentsItemList._();
    if (pos != null) result.pos = pos;
    if (truncated != null) result.truncated = truncated;
    if (items != null) result.items.addAll(items);
    if (continuationToken != null) result.continuationToken = continuationToken;
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
    ..aI(1, _omitFieldNames ? '' : 'pos')
    ..aOB(2, _omitFieldNames ? '' : 'truncated')
    ..pPM<RecentsListItem>(3, _omitFieldNames ? '' : 'items',
        subBuilder: RecentsListItem.$_createMessage)
    ..aOS(6, _omitFieldNames ? '' : 'continuationToken')
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
  $pb.PbList<RecentsListItem> get items => $_getList(2);

  /// Field 4: MetaItems (unused)
  /// Field 5: Signals (unused)
  @$pb.TagNumber(6)
  $core.String get continuationToken => $_getSZ(3);
  @$pb.TagNumber(6)
  set continuationToken($core.String value) => $_setString(3, value);
  @$pb.TagNumber(6)
  $core.bool hasContinuationToken() => $_has(3);
  @$pb.TagNumber(6)
  void clearContinuationToken() => $_clearField(6);
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
    $core.String? addedBy,
    $fixnum.Int64? timestamp,
    $fixnum.Int64? seenAt,
    $core.bool? public,
    $core.Iterable<FormatAttribute>? formatAttributes,
    $core.List<$core.int>? itemId,
    $core.int? saveSource,
  }) {
    final result = RecentsItemAttributes._();
    if (addedBy != null) result.addedBy = addedBy;
    if (timestamp != null) result.timestamp = timestamp;
    if (seenAt != null) result.seenAt = seenAt;
    if (public != null) result.public = public;
    if (formatAttributes != null)
      result.formatAttributes.addAll(formatAttributes);
    if (itemId != null) result.itemId = itemId;
    if (saveSource != null) result.saveSource = saveSource;
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
    ..aOS(1, _omitFieldNames ? '' : 'addedBy')
    ..aInt64(2, _omitFieldNames ? '' : 'timestamp')
    ..aInt64(9, _omitFieldNames ? '' : 'seenAt')
    ..aOB(10, _omitFieldNames ? '' : 'public')
    ..pPM<FormatAttribute>(11, _omitFieldNames ? '' : 'formatAttributes',
        subBuilder: FormatAttribute.$_createMessage)
    ..a<$core.List<$core.int>>(
        12, _omitFieldNames ? '' : 'itemId', $pb.PbFieldType.OY)
    ..aI(17, _omitFieldNames ? '' : 'saveSource')
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

  /// Fields 3-8 unused
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
  $pb.PbList<FormatAttribute> get formatAttributes => $_getList(4);

  @$pb.TagNumber(12)
  $core.List<$core.int> get itemId => $_getN(5);
  @$pb.TagNumber(12)
  set itemId($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(12)
  $core.bool hasItemId() => $_has(5);
  @$pb.TagNumber(12)
  void clearItemId() => $_clearField(12);

  /// Field 13: SourceLens (unused)
  /// Field 14: Signals (unused)
  /// Field 15: RecommendationInfo (unused)
  /// Field 16: sequence_child_template (unused)
  @$pb.TagNumber(17)
  $core.int get saveSource => $_getIZ(6);
  @$pb.TagNumber(17)
  set saveSource($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(17)
  $core.bool hasSaveSource() => $_has(6);
  @$pb.TagNumber(17)
  void clearSaveSource() => $_clearField(17);
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

/// Sub-proto decoded from format_attribute key="group_metadata" (Base64-encoded).
/// Maps to com.spotify.recents.recentsdatasourceimpl.GroupMetadata
class GroupMetadata extends $pb.GeneratedMessage {
  factory GroupMetadata({
    $core.int? itemsCount,
    $core.Iterable<$core.String>? entityUris,
    $core.Iterable<$core.String>? userUris,
    $core.Iterable<$core.MapEntry<$core.String, $core.int>>? filteredCount,
    $core.String? groupName,
  }) {
    final result = GroupMetadata._();
    if (itemsCount != null) result.itemsCount = itemsCount;
    if (entityUris != null) result.entityUris.addAll(entityUris);
    if (userUris != null) result.userUris.addAll(userUris);
    if (filteredCount != null) result.filteredCount.addEntries(filteredCount);
    if (groupName != null) result.groupName = groupName;
    return result;
  }

  GroupMetadata._();

  factory GroupMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupMetadata()..mergeFromBuffer(data, registry);
  factory GroupMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupMetadata()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GroupMetadata',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: GroupMetadata.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'itemsCount')
    ..pPS(2, _omitFieldNames ? '' : 'entityUris')
    ..pPS(3, _omitFieldNames ? '' : 'userUris')
    ..m<$core.String, $core.int>(4, _omitFieldNames ? '' : 'filteredCount',
        entryClassName: 'GroupMetadata.FilteredCountEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.O3,
        packageName: const $pb.PackageName('spotify.playlist.v2'))
    ..aOS(5, _omitFieldNames ? '' : 'groupName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupMetadata copyWith(void Function(GroupMetadata) updates) =>
      super.copyWith((message) => updates(message as GroupMetadata))
          as GroupMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GroupMetadata() / GroupMetadata.new instead')
  static GroupMetadata create() => GroupMetadata._();
  static $pb.GeneratedMessage $_createMessage() => GroupMetadata._();
  @$core.override
  GroupMetadata createEmptyInstance() => GroupMetadata._();
  @$core.pragma('dart2js:noInline')
  static GroupMetadata getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupMetadata>(
          GroupMetadata.$_createMessage);
  static GroupMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get itemsCount => $_getIZ(0);
  @$pb.TagNumber(1)
  set itemsCount($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasItemsCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearItemsCount() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get entityUris => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get userUris => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbMap<$core.String, $core.int> get filteredCount => $_getMap(3);

  @$pb.TagNumber(5)
  $core.String get groupName => $_getSZ(4);
  @$pb.TagNumber(5)
  set groupName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGroupName() => $_has(4);
  @$pb.TagNumber(5)
  void clearGroupName() => $_clearField(5);
}

/// Sub-proto decoded from format_attribute key="share" (Base64-encoded).
/// Maps to com.spotify.recents.recentsdatasourceimpl.Share
class ShareMetadata extends $pb.GeneratedMessage {
  factory ShareMetadata({
    $core.String? userUri,
    $core.String? shareDeeplink,
    $core.String? source,
  }) {
    final result = ShareMetadata._();
    if (userUri != null) result.userUri = userUri;
    if (shareDeeplink != null) result.shareDeeplink = shareDeeplink;
    if (source != null) result.source = source;
    return result;
  }

  ShareMetadata._();

  factory ShareMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ShareMetadata()..mergeFromBuffer(data, registry);
  factory ShareMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ShareMetadata()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShareMetadata',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: ShareMetadata.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userUri')
    ..aOS(2, _omitFieldNames ? '' : 'shareDeeplink')
    ..aOS(3, _omitFieldNames ? '' : 'source')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShareMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShareMetadata copyWith(void Function(ShareMetadata) updates) =>
      super.copyWith((message) => updates(message as ShareMetadata))
          as ShareMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ShareMetadata() / ShareMetadata.new instead')
  static ShareMetadata create() => ShareMetadata._();
  static $pb.GeneratedMessage $_createMessage() => ShareMetadata._();
  @$core.override
  ShareMetadata createEmptyInstance() => ShareMetadata._();
  @$core.pragma('dart2js:noInline')
  static ShareMetadata getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ShareMetadata>(
          ShareMetadata.$_createMessage);
  static ShareMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userUri => $_getSZ(0);
  @$pb.TagNumber(1)
  set userUri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserUri() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get shareDeeplink => $_getSZ(1);
  @$pb.TagNumber(2)
  set shareDeeplink($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasShareDeeplink() => $_has(1);
  @$pb.TagNumber(2)
  void clearShareDeeplink() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get source => $_getSZ(2);
  @$pb.TagNumber(3)
  set source($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
