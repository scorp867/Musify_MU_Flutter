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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'playlist_detail.pbenum.dart';
import 'rootlist.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'playlist_detail.pbenum.dart';

class PlaylistResponse extends $pb.GeneratedMessage {
  factory PlaylistResponse({
    $core.List<$core.int>? revision,
    $core.int? length,
    $0.ListAttributes? attributes,
    $0.ListItems? contents,
    Diff? diff,
    Diff? syncResult,
    $core.Iterable<$core.List<$core.int>>? resultingRevisions,
    $core.bool? multipleHeads,
    $core.bool? upToDate,
    $core.Iterable<$fixnum.Int64>? nonces,
    $fixnum.Int64? timestamp,
    $core.String? ownerUsername,
    $core.bool? abuseReportingEnabled,
    $0.Capabilities? capabilities,
    $core.Iterable<$0.GeoblockBlockingType>? geoblock,
    $core.bool? changesRequireResync,
    $fixnum.Int64? createdAt,
  }) {
    final result = PlaylistResponse._();
    if (revision != null) result.revision = revision;
    if (length != null) result.length = length;
    if (attributes != null) result.attributes = attributes;
    if (contents != null) result.contents = contents;
    if (diff != null) result.diff = diff;
    if (syncResult != null) result.syncResult = syncResult;
    if (resultingRevisions != null)
      result.resultingRevisions.addAll(resultingRevisions);
    if (multipleHeads != null) result.multipleHeads = multipleHeads;
    if (upToDate != null) result.upToDate = upToDate;
    if (nonces != null) result.nonces.addAll(nonces);
    if (timestamp != null) result.timestamp = timestamp;
    if (ownerUsername != null) result.ownerUsername = ownerUsername;
    if (abuseReportingEnabled != null)
      result.abuseReportingEnabled = abuseReportingEnabled;
    if (capabilities != null) result.capabilities = capabilities;
    if (geoblock != null) result.geoblock.addAll(geoblock);
    if (changesRequireResync != null)
      result.changesRequireResync = changesRequireResync;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  PlaylistResponse._();

  factory PlaylistResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaylistResponse()..mergeFromBuffer(data, registry);
  factory PlaylistResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaylistResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlaylistResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: PlaylistResponse.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OY)
    ..aI(2, _omitFieldNames ? '' : 'length')
    ..aOM<$0.ListAttributes>(3, _omitFieldNames ? '' : 'attributes',
        subBuilder: $0.ListAttributes.$_createMessage)
    ..aOM<$0.ListItems>(5, _omitFieldNames ? '' : 'contents',
        subBuilder: $0.ListItems.$_createMessage)
    ..aOM<Diff>(6, _omitFieldNames ? '' : 'diff',
        subBuilder: Diff.$_createMessage)
    ..aOM<Diff>(7, _omitFieldNames ? '' : 'syncResult',
        subBuilder: Diff.$_createMessage)
    ..p<$core.List<$core.int>>(
        8, _omitFieldNames ? '' : 'resultingRevisions', $pb.PbFieldType.PY)
    ..aOB(9, _omitFieldNames ? '' : 'multipleHeads')
    ..aOB(10, _omitFieldNames ? '' : 'upToDate')
    ..p<$fixnum.Int64>(14, _omitFieldNames ? '' : 'nonces', $pb.PbFieldType.K6)
    ..aInt64(15, _omitFieldNames ? '' : 'timestamp')
    ..aOS(16, _omitFieldNames ? '' : 'ownerUsername')
    ..aOB(17, _omitFieldNames ? '' : 'abuseReportingEnabled')
    ..aOM<$0.Capabilities>(18, _omitFieldNames ? '' : 'capabilities',
        subBuilder: $0.Capabilities.$_createMessage)
    ..pc<$0.GeoblockBlockingType>(
        19, _omitFieldNames ? '' : 'geoblock', $pb.PbFieldType.KE,
        valueOf: $0.GeoblockBlockingType.valueOf,
        enumValues: $0.GeoblockBlockingType.values,
        defaultEnumValue:
            $0.GeoblockBlockingType.GEOBLOCK_BLOCKING_TYPE_UNSPECIFIED)
    ..aOB(20, _omitFieldNames ? '' : 'changesRequireResync')
    ..aInt64(21, _omitFieldNames ? '' : 'createdAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlaylistResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlaylistResponse copyWith(void Function(PlaylistResponse) updates) =>
      super.copyWith((message) => updates(message as PlaylistResponse))
          as PlaylistResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PlaylistResponse() / PlaylistResponse.new instead')
  static PlaylistResponse create() => PlaylistResponse._();
  static $pb.GeneratedMessage $_createMessage() => PlaylistResponse._();
  @$core.override
  PlaylistResponse createEmptyInstance() => PlaylistResponse._();
  @$core.pragma('dart2js:noInline')
  static PlaylistResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PlaylistResponse>(
          PlaylistResponse.$_createMessage);
  static PlaylistResponse? _defaultInstance;

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
  $0.ListAttributes get attributes => $_getN(2);
  @$pb.TagNumber(3)
  set attributes($0.ListAttributes value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAttributes() => $_has(2);
  @$pb.TagNumber(3)
  void clearAttributes() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.ListAttributes ensureAttributes() => $_ensure(2);

  /// field 4 unused
  @$pb.TagNumber(5)
  $0.ListItems get contents => $_getN(3);
  @$pb.TagNumber(5)
  set contents($0.ListItems value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasContents() => $_has(3);
  @$pb.TagNumber(5)
  void clearContents() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.ListItems ensureContents() => $_ensure(3);

  @$pb.TagNumber(6)
  Diff get diff => $_getN(4);
  @$pb.TagNumber(6)
  set diff(Diff value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasDiff() => $_has(4);
  @$pb.TagNumber(6)
  void clearDiff() => $_clearField(6);
  @$pb.TagNumber(6)
  Diff ensureDiff() => $_ensure(4);

  @$pb.TagNumber(7)
  Diff get syncResult => $_getN(5);
  @$pb.TagNumber(7)
  set syncResult(Diff value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasSyncResult() => $_has(5);
  @$pb.TagNumber(7)
  void clearSyncResult() => $_clearField(7);
  @$pb.TagNumber(7)
  Diff ensureSyncResult() => $_ensure(5);

  @$pb.TagNumber(8)
  $pb.PbList<$core.List<$core.int>> get resultingRevisions => $_getList(6);

  @$pb.TagNumber(9)
  $core.bool get multipleHeads => $_getBF(7);
  @$pb.TagNumber(9)
  set multipleHeads($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(9)
  $core.bool hasMultipleHeads() => $_has(7);
  @$pb.TagNumber(9)
  void clearMultipleHeads() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get upToDate => $_getBF(8);
  @$pb.TagNumber(10)
  set upToDate($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(10)
  $core.bool hasUpToDate() => $_has(8);
  @$pb.TagNumber(10)
  void clearUpToDate() => $_clearField(10);

  @$pb.TagNumber(14)
  $pb.PbList<$fixnum.Int64> get nonces => $_getList(9);

  @$pb.TagNumber(15)
  $fixnum.Int64 get timestamp => $_getI64(10);
  @$pb.TagNumber(15)
  set timestamp($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(15)
  $core.bool hasTimestamp() => $_has(10);
  @$pb.TagNumber(15)
  void clearTimestamp() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get ownerUsername => $_getSZ(11);
  @$pb.TagNumber(16)
  set ownerUsername($core.String value) => $_setString(11, value);
  @$pb.TagNumber(16)
  $core.bool hasOwnerUsername() => $_has(11);
  @$pb.TagNumber(16)
  void clearOwnerUsername() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.bool get abuseReportingEnabled => $_getBF(12);
  @$pb.TagNumber(17)
  set abuseReportingEnabled($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(17)
  $core.bool hasAbuseReportingEnabled() => $_has(12);
  @$pb.TagNumber(17)
  void clearAbuseReportingEnabled() => $_clearField(17);

  @$pb.TagNumber(18)
  $0.Capabilities get capabilities => $_getN(13);
  @$pb.TagNumber(18)
  set capabilities($0.Capabilities value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasCapabilities() => $_has(13);
  @$pb.TagNumber(18)
  void clearCapabilities() => $_clearField(18);
  @$pb.TagNumber(18)
  $0.Capabilities ensureCapabilities() => $_ensure(13);

  @$pb.TagNumber(19)
  $pb.PbList<$0.GeoblockBlockingType> get geoblock => $_getList(14);

  @$pb.TagNumber(20)
  $core.bool get changesRequireResync => $_getBF(15);
  @$pb.TagNumber(20)
  set changesRequireResync($core.bool value) => $_setBool(15, value);
  @$pb.TagNumber(20)
  $core.bool hasChangesRequireResync() => $_has(15);
  @$pb.TagNumber(20)
  void clearChangesRequireResync() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get createdAt => $_getI64(16);
  @$pb.TagNumber(21)
  set createdAt($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(21)
  $core.bool hasCreatedAt() => $_has(16);
  @$pb.TagNumber(21)
  void clearCreatedAt() => $_clearField(21);
}

class Diff extends $pb.GeneratedMessage {
  factory Diff({
    $core.List<$core.int>? fromRevision,
    $core.Iterable<Op>? ops,
    $core.List<$core.int>? toRevision,
    AvailableSignals? availableSignals,
  }) {
    final result = Diff._();
    if (fromRevision != null) result.fromRevision = fromRevision;
    if (ops != null) result.ops.addAll(ops);
    if (toRevision != null) result.toRevision = toRevision;
    if (availableSignals != null) result.availableSignals = availableSignals;
    return result;
  }

  Diff._();

  factory Diff.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Diff()..mergeFromBuffer(data, registry);
  factory Diff.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Diff()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Diff',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: Diff.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'fromRevision', $pb.PbFieldType.OY)
    ..pPM<Op>(2, _omitFieldNames ? '' : 'ops', subBuilder: Op.$_createMessage)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'toRevision', $pb.PbFieldType.OY)
    ..aOM<AvailableSignals>(4, _omitFieldNames ? '' : 'availableSignals',
        subBuilder: AvailableSignals.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Diff clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Diff copyWith(void Function(Diff) updates) =>
      super.copyWith((message) => updates(message as Diff)) as Diff;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Diff() / Diff.new instead')
  static Diff create() => Diff._();
  static $pb.GeneratedMessage $_createMessage() => Diff._();
  @$core.override
  Diff createEmptyInstance() => Diff._();
  @$core.pragma('dart2js:noInline')
  static Diff getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Diff>(Diff.$_createMessage);
  static Diff? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get fromRevision => $_getN(0);
  @$pb.TagNumber(1)
  set fromRevision($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFromRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearFromRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<Op> get ops => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get toRevision => $_getN(2);
  @$pb.TagNumber(3)
  set toRevision($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasToRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearToRevision() => $_clearField(3);

  @$pb.TagNumber(4)
  AvailableSignals get availableSignals => $_getN(3);
  @$pb.TagNumber(4)
  set availableSignals(AvailableSignals value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAvailableSignals() => $_has(3);
  @$pb.TagNumber(4)
  void clearAvailableSignals() => $_clearField(4);
  @$pb.TagNumber(4)
  AvailableSignals ensureAvailableSignals() => $_ensure(3);
}

class Op extends $pb.GeneratedMessage {
  factory Op({
    OpKind? kind,
    Add? add,
    Rem? rem,
    Mov? mov,
    UpdateItemAttributes? updateItemAttributes,
    UpdateListAttributes? updateListAttributes,
    UpdateItemUris? updateItemUris,
  }) {
    final result = Op._();
    if (kind != null) result.kind = kind;
    if (add != null) result.add = add;
    if (rem != null) result.rem = rem;
    if (mov != null) result.mov = mov;
    if (updateItemAttributes != null)
      result.updateItemAttributes = updateItemAttributes;
    if (updateListAttributes != null)
      result.updateListAttributes = updateListAttributes;
    if (updateItemUris != null) result.updateItemUris = updateItemUris;
    return result;
  }

  Op._();

  factory Op.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Op()..mergeFromBuffer(data, registry);
  factory Op.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Op()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Op',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: Op.$_createMessage)
    ..aE<OpKind>(1, _omitFieldNames ? '' : 'kind', enumValues: OpKind.values)
    ..aOM<Add>(2, _omitFieldNames ? '' : 'add', subBuilder: Add.$_createMessage)
    ..aOM<Rem>(3, _omitFieldNames ? '' : 'rem', subBuilder: Rem.$_createMessage)
    ..aOM<Mov>(4, _omitFieldNames ? '' : 'mov', subBuilder: Mov.$_createMessage)
    ..aOM<UpdateItemAttributes>(
        5, _omitFieldNames ? '' : 'updateItemAttributes',
        subBuilder: UpdateItemAttributes.$_createMessage)
    ..aOM<UpdateListAttributes>(
        6, _omitFieldNames ? '' : 'updateListAttributes',
        subBuilder: UpdateListAttributes.$_createMessage)
    ..aOM<UpdateItemUris>(7, _omitFieldNames ? '' : 'updateItemUris',
        subBuilder: UpdateItemUris.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Op clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Op copyWith(void Function(Op) updates) =>
      super.copyWith((message) => updates(message as Op)) as Op;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Op() / Op.new instead')
  static Op create() => Op._();
  static $pb.GeneratedMessage $_createMessage() => Op._();
  @$core.override
  Op createEmptyInstance() => Op._();
  @$core.pragma('dart2js:noInline')
  static Op getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Op>(Op.$_createMessage);
  static Op? _defaultInstance;

  @$pb.TagNumber(1)
  OpKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(OpKind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  Add get add => $_getN(1);
  @$pb.TagNumber(2)
  set add(Add value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAdd() => $_has(1);
  @$pb.TagNumber(2)
  void clearAdd() => $_clearField(2);
  @$pb.TagNumber(2)
  Add ensureAdd() => $_ensure(1);

  @$pb.TagNumber(3)
  Rem get rem => $_getN(2);
  @$pb.TagNumber(3)
  set rem(Rem value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRem() => $_has(2);
  @$pb.TagNumber(3)
  void clearRem() => $_clearField(3);
  @$pb.TagNumber(3)
  Rem ensureRem() => $_ensure(2);

  @$pb.TagNumber(4)
  Mov get mov => $_getN(3);
  @$pb.TagNumber(4)
  set mov(Mov value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMov() => $_has(3);
  @$pb.TagNumber(4)
  void clearMov() => $_clearField(4);
  @$pb.TagNumber(4)
  Mov ensureMov() => $_ensure(3);

  @$pb.TagNumber(5)
  UpdateItemAttributes get updateItemAttributes => $_getN(4);
  @$pb.TagNumber(5)
  set updateItemAttributes(UpdateItemAttributes value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasUpdateItemAttributes() => $_has(4);
  @$pb.TagNumber(5)
  void clearUpdateItemAttributes() => $_clearField(5);
  @$pb.TagNumber(5)
  UpdateItemAttributes ensureUpdateItemAttributes() => $_ensure(4);

  @$pb.TagNumber(6)
  UpdateListAttributes get updateListAttributes => $_getN(5);
  @$pb.TagNumber(6)
  set updateListAttributes(UpdateListAttributes value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasUpdateListAttributes() => $_has(5);
  @$pb.TagNumber(6)
  void clearUpdateListAttributes() => $_clearField(6);
  @$pb.TagNumber(6)
  UpdateListAttributes ensureUpdateListAttributes() => $_ensure(5);

  @$pb.TagNumber(7)
  UpdateItemUris get updateItemUris => $_getN(6);
  @$pb.TagNumber(7)
  set updateItemUris(UpdateItemUris value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasUpdateItemUris() => $_has(6);
  @$pb.TagNumber(7)
  void clearUpdateItemUris() => $_clearField(7);
  @$pb.TagNumber(7)
  UpdateItemUris ensureUpdateItemUris() => $_ensure(6);
}

class Add extends $pb.GeneratedMessage {
  factory Add({
    $core.int? fromIndex,
    $core.Iterable<$0.Item>? items,
    $core.bool? addLast,
    $core.bool? addFirst,
    $0.Item? addBeforeItem,
    $0.Item? addAfterItem,
  }) {
    final result = Add._();
    if (fromIndex != null) result.fromIndex = fromIndex;
    if (items != null) result.items.addAll(items);
    if (addLast != null) result.addLast = addLast;
    if (addFirst != null) result.addFirst = addFirst;
    if (addBeforeItem != null) result.addBeforeItem = addBeforeItem;
    if (addAfterItem != null) result.addAfterItem = addAfterItem;
    return result;
  }

  Add._();

  factory Add.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Add()..mergeFromBuffer(data, registry);
  factory Add.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Add()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Add',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: Add.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'fromIndex')
    ..pPM<$0.Item>(2, _omitFieldNames ? '' : 'items',
        subBuilder: $0.Item.$_createMessage)
    ..aOB(4, _omitFieldNames ? '' : 'addLast')
    ..aOB(5, _omitFieldNames ? '' : 'addFirst')
    ..aOM<$0.Item>(6, _omitFieldNames ? '' : 'addBeforeItem',
        subBuilder: $0.Item.$_createMessage)
    ..aOM<$0.Item>(7, _omitFieldNames ? '' : 'addAfterItem',
        subBuilder: $0.Item.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Add clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Add copyWith(void Function(Add) updates) =>
      super.copyWith((message) => updates(message as Add)) as Add;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Add() / Add.new instead')
  static Add create() => Add._();
  static $pb.GeneratedMessage $_createMessage() => Add._();
  @$core.override
  Add createEmptyInstance() => Add._();
  @$core.pragma('dart2js:noInline')
  static Add getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Add>(Add.$_createMessage);
  static Add? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get fromIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set fromIndex($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFromIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearFromIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$0.Item> get items => $_getList(1);

  /// field 3 unused
  @$pb.TagNumber(4)
  $core.bool get addLast => $_getBF(2);
  @$pb.TagNumber(4)
  set addLast($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(4)
  $core.bool hasAddLast() => $_has(2);
  @$pb.TagNumber(4)
  void clearAddLast() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get addFirst => $_getBF(3);
  @$pb.TagNumber(5)
  set addFirst($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(5)
  $core.bool hasAddFirst() => $_has(3);
  @$pb.TagNumber(5)
  void clearAddFirst() => $_clearField(5);

  @$pb.TagNumber(6)
  $0.Item get addBeforeItem => $_getN(4);
  @$pb.TagNumber(6)
  set addBeforeItem($0.Item value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasAddBeforeItem() => $_has(4);
  @$pb.TagNumber(6)
  void clearAddBeforeItem() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.Item ensureAddBeforeItem() => $_ensure(4);

  @$pb.TagNumber(7)
  $0.Item get addAfterItem => $_getN(5);
  @$pb.TagNumber(7)
  set addAfterItem($0.Item value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasAddAfterItem() => $_has(5);
  @$pb.TagNumber(7)
  void clearAddAfterItem() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Item ensureAddAfterItem() => $_ensure(5);
}

class Rem extends $pb.GeneratedMessage {
  factory Rem({
    $core.int? fromIndex,
    $core.int? length,
    $core.Iterable<$0.Item>? items,
    $core.bool? itemsAsKey,
  }) {
    final result = Rem._();
    if (fromIndex != null) result.fromIndex = fromIndex;
    if (length != null) result.length = length;
    if (items != null) result.items.addAll(items);
    if (itemsAsKey != null) result.itemsAsKey = itemsAsKey;
    return result;
  }

  Rem._();

  factory Rem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Rem()..mergeFromBuffer(data, registry);
  factory Rem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Rem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Rem',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: Rem.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'fromIndex')
    ..aI(2, _omitFieldNames ? '' : 'length')
    ..pPM<$0.Item>(3, _omitFieldNames ? '' : 'items',
        subBuilder: $0.Item.$_createMessage)
    ..aOB(7, _omitFieldNames ? '' : 'itemsAsKey')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Rem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Rem copyWith(void Function(Rem) updates) =>
      super.copyWith((message) => updates(message as Rem)) as Rem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Rem() / Rem.new instead')
  static Rem create() => Rem._();
  static $pb.GeneratedMessage $_createMessage() => Rem._();
  @$core.override
  Rem createEmptyInstance() => Rem._();
  @$core.pragma('dart2js:noInline')
  static Rem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Rem>(Rem.$_createMessage);
  static Rem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get fromIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set fromIndex($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFromIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearFromIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get length => $_getIZ(1);
  @$pb.TagNumber(2)
  set length($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLength() => $_has(1);
  @$pb.TagNumber(2)
  void clearLength() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$0.Item> get items => $_getList(2);

  /// fields 4-6 unused
  @$pb.TagNumber(7)
  $core.bool get itemsAsKey => $_getBF(3);
  @$pb.TagNumber(7)
  set itemsAsKey($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(7)
  $core.bool hasItemsAsKey() => $_has(3);
  @$pb.TagNumber(7)
  void clearItemsAsKey() => $_clearField(7);
}

class Mov extends $pb.GeneratedMessage {
  factory Mov({
    $core.int? fromIndex,
    $core.int? length,
    $core.int? toIndex,
    $core.Iterable<$0.Item>? items,
    $0.Item? addBeforeItem,
    $0.Item? addAfterItem,
    $core.bool? addFirst,
    $core.bool? addLast,
  }) {
    final result = Mov._();
    if (fromIndex != null) result.fromIndex = fromIndex;
    if (length != null) result.length = length;
    if (toIndex != null) result.toIndex = toIndex;
    if (items != null) result.items.addAll(items);
    if (addBeforeItem != null) result.addBeforeItem = addBeforeItem;
    if (addAfterItem != null) result.addAfterItem = addAfterItem;
    if (addFirst != null) result.addFirst = addFirst;
    if (addLast != null) result.addLast = addLast;
    return result;
  }

  Mov._();

  factory Mov.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Mov()..mergeFromBuffer(data, registry);
  factory Mov.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Mov()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Mov',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: Mov.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'fromIndex')
    ..aI(2, _omitFieldNames ? '' : 'length')
    ..aI(3, _omitFieldNames ? '' : 'toIndex')
    ..pPM<$0.Item>(4, _omitFieldNames ? '' : 'items',
        subBuilder: $0.Item.$_createMessage)
    ..aOM<$0.Item>(5, _omitFieldNames ? '' : 'addBeforeItem',
        subBuilder: $0.Item.$_createMessage)
    ..aOM<$0.Item>(6, _omitFieldNames ? '' : 'addAfterItem',
        subBuilder: $0.Item.$_createMessage)
    ..aOB(7, _omitFieldNames ? '' : 'addFirst')
    ..aOB(8, _omitFieldNames ? '' : 'addLast')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Mov clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Mov copyWith(void Function(Mov) updates) =>
      super.copyWith((message) => updates(message as Mov)) as Mov;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Mov() / Mov.new instead')
  static Mov create() => Mov._();
  static $pb.GeneratedMessage $_createMessage() => Mov._();
  @$core.override
  Mov createEmptyInstance() => Mov._();
  @$core.pragma('dart2js:noInline')
  static Mov getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Mov>(Mov.$_createMessage);
  static Mov? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get fromIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set fromIndex($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFromIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearFromIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get length => $_getIZ(1);
  @$pb.TagNumber(2)
  set length($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLength() => $_has(1);
  @$pb.TagNumber(2)
  void clearLength() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get toIndex => $_getIZ(2);
  @$pb.TagNumber(3)
  set toIndex($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasToIndex() => $_has(2);
  @$pb.TagNumber(3)
  void clearToIndex() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$0.Item> get items => $_getList(3);

  @$pb.TagNumber(5)
  $0.Item get addBeforeItem => $_getN(4);
  @$pb.TagNumber(5)
  set addBeforeItem($0.Item value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasAddBeforeItem() => $_has(4);
  @$pb.TagNumber(5)
  void clearAddBeforeItem() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Item ensureAddBeforeItem() => $_ensure(4);

  @$pb.TagNumber(6)
  $0.Item get addAfterItem => $_getN(5);
  @$pb.TagNumber(6)
  set addAfterItem($0.Item value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasAddAfterItem() => $_has(5);
  @$pb.TagNumber(6)
  void clearAddAfterItem() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.Item ensureAddAfterItem() => $_ensure(5);

  @$pb.TagNumber(7)
  $core.bool get addFirst => $_getBF(6);
  @$pb.TagNumber(7)
  set addFirst($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAddFirst() => $_has(6);
  @$pb.TagNumber(7)
  void clearAddFirst() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get addLast => $_getBF(7);
  @$pb.TagNumber(8)
  set addLast($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAddLast() => $_has(7);
  @$pb.TagNumber(8)
  void clearAddLast() => $_clearField(8);
}

class UpdateListAttributes extends $pb.GeneratedMessage {
  factory UpdateListAttributes({
    ListAttributesPartialState? newAttributes,
    ListAttributesPartialState? oldAttributes,
  }) {
    final result = UpdateListAttributes._();
    if (newAttributes != null) result.newAttributes = newAttributes;
    if (oldAttributes != null) result.oldAttributes = oldAttributes;
    return result;
  }

  UpdateListAttributes._();

  factory UpdateListAttributes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateListAttributes()..mergeFromBuffer(data, registry);
  factory UpdateListAttributes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateListAttributes()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateListAttributes',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: UpdateListAttributes.$_createMessage)
    ..aOM<ListAttributesPartialState>(1, _omitFieldNames ? '' : 'newAttributes',
        subBuilder: ListAttributesPartialState.$_createMessage)
    ..aOM<ListAttributesPartialState>(2, _omitFieldNames ? '' : 'oldAttributes',
        subBuilder: ListAttributesPartialState.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateListAttributes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateListAttributes copyWith(void Function(UpdateListAttributes) updates) =>
      super.copyWith((message) => updates(message as UpdateListAttributes))
          as UpdateListAttributes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UpdateListAttributes() / UpdateListAttributes.new instead')
  static UpdateListAttributes create() => UpdateListAttributes._();
  static $pb.GeneratedMessage $_createMessage() => UpdateListAttributes._();
  @$core.override
  UpdateListAttributes createEmptyInstance() => UpdateListAttributes._();
  @$core.pragma('dart2js:noInline')
  static UpdateListAttributes getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateListAttributes>(
          UpdateListAttributes.$_createMessage);
  static UpdateListAttributes? _defaultInstance;

  @$pb.TagNumber(1)
  ListAttributesPartialState get newAttributes => $_getN(0);
  @$pb.TagNumber(1)
  set newAttributes(ListAttributesPartialState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasNewAttributes() => $_has(0);
  @$pb.TagNumber(1)
  void clearNewAttributes() => $_clearField(1);
  @$pb.TagNumber(1)
  ListAttributesPartialState ensureNewAttributes() => $_ensure(0);

  @$pb.TagNumber(2)
  ListAttributesPartialState get oldAttributes => $_getN(1);
  @$pb.TagNumber(2)
  set oldAttributes(ListAttributesPartialState value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOldAttributes() => $_has(1);
  @$pb.TagNumber(2)
  void clearOldAttributes() => $_clearField(2);
  @$pb.TagNumber(2)
  ListAttributesPartialState ensureOldAttributes() => $_ensure(1);
}

/// Confirmed from Playlist4ApiProto$UpdateItemAttributes (decompiled):
///   INDEX_FIELD_NUMBER = 1
///   NEW_ATTRIBUTES_FIELD_NUMBER = 2
///   OLD_ATTRIBUTES_FIELD_NUMBER = 3
///   ITEM_FIELD_NUMBER = 4
class UpdateItemAttributes extends $pb.GeneratedMessage {
  factory UpdateItemAttributes({
    $core.int? index,
    ItemAttributesPartialState? newAttributes,
    ItemAttributesPartialState? oldAttributes,
    $0.Item? item,
  }) {
    final result = UpdateItemAttributes._();
    if (index != null) result.index = index;
    if (newAttributes != null) result.newAttributes = newAttributes;
    if (oldAttributes != null) result.oldAttributes = oldAttributes;
    if (item != null) result.item = item;
    return result;
  }

  UpdateItemAttributes._();

  factory UpdateItemAttributes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateItemAttributes()..mergeFromBuffer(data, registry);
  factory UpdateItemAttributes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateItemAttributes()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateItemAttributes',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: UpdateItemAttributes.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'index')
    ..aOM<ItemAttributesPartialState>(2, _omitFieldNames ? '' : 'newAttributes',
        subBuilder: ItemAttributesPartialState.$_createMessage)
    ..aOM<ItemAttributesPartialState>(3, _omitFieldNames ? '' : 'oldAttributes',
        subBuilder: ItemAttributesPartialState.$_createMessage)
    ..aOM<$0.Item>(4, _omitFieldNames ? '' : 'item',
        subBuilder: $0.Item.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateItemAttributes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateItemAttributes copyWith(void Function(UpdateItemAttributes) updates) =>
      super.copyWith((message) => updates(message as UpdateItemAttributes))
          as UpdateItemAttributes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UpdateItemAttributes() / UpdateItemAttributes.new instead')
  static UpdateItemAttributes create() => UpdateItemAttributes._();
  static $pb.GeneratedMessage $_createMessage() => UpdateItemAttributes._();
  @$core.override
  UpdateItemAttributes createEmptyInstance() => UpdateItemAttributes._();
  @$core.pragma('dart2js:noInline')
  static UpdateItemAttributes getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateItemAttributes>(
          UpdateItemAttributes.$_createMessage);
  static UpdateItemAttributes? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  ItemAttributesPartialState get newAttributes => $_getN(1);
  @$pb.TagNumber(2)
  set newAttributes(ItemAttributesPartialState value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasNewAttributes() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewAttributes() => $_clearField(2);
  @$pb.TagNumber(2)
  ItemAttributesPartialState ensureNewAttributes() => $_ensure(1);

  @$pb.TagNumber(3)
  ItemAttributesPartialState get oldAttributes => $_getN(2);
  @$pb.TagNumber(3)
  set oldAttributes(ItemAttributesPartialState value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOldAttributes() => $_has(2);
  @$pb.TagNumber(3)
  void clearOldAttributes() => $_clearField(3);
  @$pb.TagNumber(3)
  ItemAttributesPartialState ensureOldAttributes() => $_ensure(2);

  @$pb.TagNumber(4)
  $0.Item get item => $_getN(3);
  @$pb.TagNumber(4)
  set item($0.Item value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasItem() => $_has(3);
  @$pb.TagNumber(4)
  void clearItem() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Item ensureItem() => $_ensure(3);
}

/// Confirmed from Playlist4ApiProto$UpdateItemUris (decompiled):
///   URI_REPLACEMENTS_FIELD_NUMBER = 1
class UpdateItemUris extends $pb.GeneratedMessage {
  factory UpdateItemUris({
    $core.Iterable<UriReplacement>? uriReplacements,
  }) {
    final result = UpdateItemUris._();
    if (uriReplacements != null) result.uriReplacements.addAll(uriReplacements);
    return result;
  }

  UpdateItemUris._();

  factory UpdateItemUris.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateItemUris()..mergeFromBuffer(data, registry);
  factory UpdateItemUris.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateItemUris()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateItemUris',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: UpdateItemUris.$_createMessage)
    ..pPM<UriReplacement>(1, _omitFieldNames ? '' : 'uriReplacements',
        subBuilder: UriReplacement.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateItemUris clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateItemUris copyWith(void Function(UpdateItemUris) updates) =>
      super.copyWith((message) => updates(message as UpdateItemUris))
          as UpdateItemUris;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UpdateItemUris() / UpdateItemUris.new instead')
  static UpdateItemUris create() => UpdateItemUris._();
  static $pb.GeneratedMessage $_createMessage() => UpdateItemUris._();
  @$core.override
  UpdateItemUris createEmptyInstance() => UpdateItemUris._();
  @$core.pragma('dart2js:noInline')
  static UpdateItemUris getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateItemUris>(
          UpdateItemUris.$_createMessage);
  static UpdateItemUris? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<UriReplacement> get uriReplacements => $_getList(0);
}

/// Confirmed from Playlist4ApiProto$UriReplacement (decompiled):
///   INDEX_FIELD_NUMBER = 1
///   ITEM_FIELD_NUMBER = 2
///   NEW_URI_FIELD_NUMBER = 3
class UriReplacement extends $pb.GeneratedMessage {
  factory UriReplacement({
    $core.int? index,
    $0.Item? item,
    $core.String? newUri,
  }) {
    final result = UriReplacement._();
    if (index != null) result.index = index;
    if (item != null) result.item = item;
    if (newUri != null) result.newUri = newUri;
    return result;
  }

  UriReplacement._();

  factory UriReplacement.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UriReplacement()..mergeFromBuffer(data, registry);
  factory UriReplacement.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UriReplacement()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UriReplacement',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: UriReplacement.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'index')
    ..aOM<$0.Item>(2, _omitFieldNames ? '' : 'item',
        subBuilder: $0.Item.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'newUri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UriReplacement clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UriReplacement copyWith(void Function(UriReplacement) updates) =>
      super.copyWith((message) => updates(message as UriReplacement))
          as UriReplacement;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UriReplacement() / UriReplacement.new instead')
  static UriReplacement create() => UriReplacement._();
  static $pb.GeneratedMessage $_createMessage() => UriReplacement._();
  @$core.override
  UriReplacement createEmptyInstance() => UriReplacement._();
  @$core.pragma('dart2js:noInline')
  static UriReplacement getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UriReplacement>(
          UriReplacement.$_createMessage);
  static UriReplacement? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Item get item => $_getN(1);
  @$pb.TagNumber(2)
  set item($0.Item value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItem() => $_has(1);
  @$pb.TagNumber(2)
  void clearItem() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Item ensureItem() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get newUri => $_getSZ(2);
  @$pb.TagNumber(3)
  set newUri($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNewUri() => $_has(2);
  @$pb.TagNumber(3)
  void clearNewUri() => $_clearField(3);
}

class ListAttributesPartialState extends $pb.GeneratedMessage {
  factory ListAttributesPartialState({
    $0.ListAttributes? values,
    $core.Iterable<ListAttributeKind>? noValue,
  }) {
    final result = ListAttributesPartialState._();
    if (values != null) result.values = values;
    if (noValue != null) result.noValue.addAll(noValue);
    return result;
  }

  ListAttributesPartialState._();

  factory ListAttributesPartialState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListAttributesPartialState()..mergeFromBuffer(data, registry);
  factory ListAttributesPartialState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListAttributesPartialState()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListAttributesPartialState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: ListAttributesPartialState.$_createMessage)
    ..aOM<$0.ListAttributes>(1, _omitFieldNames ? '' : 'values',
        subBuilder: $0.ListAttributes.$_createMessage)
    ..pc<ListAttributeKind>(
        2, _omitFieldNames ? '' : 'noValue', $pb.PbFieldType.KE,
        valueOf: ListAttributeKind.valueOf,
        enumValues: ListAttributeKind.values,
        defaultEnumValue: ListAttributeKind.LIST_UNKNOWN)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListAttributesPartialState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListAttributesPartialState copyWith(
          void Function(ListAttributesPartialState) updates) =>
      super.copyWith(
              (message) => updates(message as ListAttributesPartialState))
          as ListAttributesPartialState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListAttributesPartialState() / ListAttributesPartialState.new instead')
  static ListAttributesPartialState create() => ListAttributesPartialState._();
  static $pb.GeneratedMessage $_createMessage() =>
      ListAttributesPartialState._();
  @$core.override
  ListAttributesPartialState createEmptyInstance() =>
      ListAttributesPartialState._();
  @$core.pragma('dart2js:noInline')
  static ListAttributesPartialState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListAttributesPartialState>(
          ListAttributesPartialState.$_createMessage);
  static ListAttributesPartialState? _defaultInstance;

  @$pb.TagNumber(1)
  $0.ListAttributes get values => $_getN(0);
  @$pb.TagNumber(1)
  set values($0.ListAttributes value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasValues() => $_has(0);
  @$pb.TagNumber(1)
  void clearValues() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.ListAttributes ensureValues() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<ListAttributeKind> get noValue => $_getList(1);
}

class ItemAttributesPartialState extends $pb.GeneratedMessage {
  factory ItemAttributesPartialState({
    $0.ItemAttributes? values,
    $core.Iterable<ItemAttributeKind>? noValue,
  }) {
    final result = ItemAttributesPartialState._();
    if (values != null) result.values = values;
    if (noValue != null) result.noValue.addAll(noValue);
    return result;
  }

  ItemAttributesPartialState._();

  factory ItemAttributesPartialState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ItemAttributesPartialState()..mergeFromBuffer(data, registry);
  factory ItemAttributesPartialState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ItemAttributesPartialState()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ItemAttributesPartialState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: ItemAttributesPartialState.$_createMessage)
    ..aOM<$0.ItemAttributes>(1, _omitFieldNames ? '' : 'values',
        subBuilder: $0.ItemAttributes.$_createMessage)
    ..pc<ItemAttributeKind>(
        2, _omitFieldNames ? '' : 'noValue', $pb.PbFieldType.KE,
        valueOf: ItemAttributeKind.valueOf,
        enumValues: ItemAttributeKind.values,
        defaultEnumValue: ItemAttributeKind.ITEM_UNKNOWN)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ItemAttributesPartialState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ItemAttributesPartialState copyWith(
          void Function(ItemAttributesPartialState) updates) =>
      super.copyWith(
              (message) => updates(message as ItemAttributesPartialState))
          as ItemAttributesPartialState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ItemAttributesPartialState() / ItemAttributesPartialState.new instead')
  static ItemAttributesPartialState create() => ItemAttributesPartialState._();
  static $pb.GeneratedMessage $_createMessage() =>
      ItemAttributesPartialState._();
  @$core.override
  ItemAttributesPartialState createEmptyInstance() =>
      ItemAttributesPartialState._();
  @$core.pragma('dart2js:noInline')
  static ItemAttributesPartialState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ItemAttributesPartialState>(
          ItemAttributesPartialState.$_createMessage);
  static ItemAttributesPartialState? _defaultInstance;

  @$pb.TagNumber(1)
  $0.ItemAttributes get values => $_getN(0);
  @$pb.TagNumber(1)
  set values($0.ItemAttributes value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasValues() => $_has(0);
  @$pb.TagNumber(1)
  void clearValues() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.ItemAttributes ensureValues() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<ItemAttributeKind> get noValue => $_getList(1);
}

class AvailableSignals extends $pb.GeneratedMessage {
  factory AvailableSignals() => AvailableSignals._();

  AvailableSignals._();

  factory AvailableSignals.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AvailableSignals()..mergeFromBuffer(data, registry);
  factory AvailableSignals.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AvailableSignals()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AvailableSignals',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.playlist.v2'),
      createEmptyInstance: AvailableSignals.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AvailableSignals clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AvailableSignals copyWith(void Function(AvailableSignals) updates) =>
      super.copyWith((message) => updates(message as AvailableSignals))
          as AvailableSignals;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AvailableSignals() / AvailableSignals.new instead')
  static AvailableSignals create() => AvailableSignals._();
  static $pb.GeneratedMessage $_createMessage() => AvailableSignals._();
  @$core.override
  AvailableSignals createEmptyInstance() => AvailableSignals._();
  @$core.pragma('dart2js:noInline')
  static AvailableSignals getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AvailableSignals>(
          AvailableSignals.$_createMessage);
  static AvailableSignals? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
