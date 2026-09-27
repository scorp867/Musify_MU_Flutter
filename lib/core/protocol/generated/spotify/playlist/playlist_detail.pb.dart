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
    $core.Iterable<Op>? ops,
  }) {
    final result = Diff._();
    if (ops != null) result.ops.addAll(ops);
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
    ..pPM<Op>(1, _omitFieldNames ? '' : 'ops', subBuilder: Op.$_createMessage)
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
  $pb.PbList<Op> get ops => $_getList(0);
}

class Op extends $pb.GeneratedMessage {
  factory Op({
    OpKind? kind,
    $core.int? fromIndex,
    $core.int? toIndex,
    $core.int? length,
    $core.Iterable<$0.Item>? items,
    $0.ListAttributes? listAttributes,
    $0.ItemAttributes? itemAttributes,
  }) {
    final result = Op._();
    if (kind != null) result.kind = kind;
    if (fromIndex != null) result.fromIndex = fromIndex;
    if (toIndex != null) result.toIndex = toIndex;
    if (length != null) result.length = length;
    if (items != null) result.items.addAll(items);
    if (listAttributes != null) result.listAttributes = listAttributes;
    if (itemAttributes != null) result.itemAttributes = itemAttributes;
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
    ..aI(2, _omitFieldNames ? '' : 'fromIndex')
    ..aI(3, _omitFieldNames ? '' : 'toIndex')
    ..aI(4, _omitFieldNames ? '' : 'length')
    ..pPM<$0.Item>(5, _omitFieldNames ? '' : 'items',
        subBuilder: $0.Item.$_createMessage)
    ..aOM<$0.ListAttributes>(6, _omitFieldNames ? '' : 'listAttributes',
        subBuilder: $0.ListAttributes.$_createMessage)
    ..aOM<$0.ItemAttributes>(7, _omitFieldNames ? '' : 'itemAttributes',
        subBuilder: $0.ItemAttributes.$_createMessage)
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
  $core.int get fromIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set fromIndex($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFromIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearFromIndex() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get toIndex => $_getIZ(2);
  @$pb.TagNumber(3)
  set toIndex($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasToIndex() => $_has(2);
  @$pb.TagNumber(3)
  void clearToIndex() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get length => $_getIZ(3);
  @$pb.TagNumber(4)
  set length($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLength() => $_has(3);
  @$pb.TagNumber(4)
  void clearLength() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$0.Item> get items => $_getList(4);

  @$pb.TagNumber(6)
  $0.ListAttributes get listAttributes => $_getN(5);
  @$pb.TagNumber(6)
  set listAttributes($0.ListAttributes value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasListAttributes() => $_has(5);
  @$pb.TagNumber(6)
  void clearListAttributes() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.ListAttributes ensureListAttributes() => $_ensure(5);

  @$pb.TagNumber(7)
  $0.ItemAttributes get itemAttributes => $_getN(6);
  @$pb.TagNumber(7)
  set itemAttributes($0.ItemAttributes value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasItemAttributes() => $_has(6);
  @$pb.TagNumber(7)
  void clearItemAttributes() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.ItemAttributes ensureItemAttributes() => $_ensure(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
