// This is a generated file - do not edit.
//
// Generated from spotify/extended_metadata.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'entity_extension_data.pb.dart' as $0;
import 'extended_metadata.pbenum.dart';
import 'extension_kind.pbenum.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'extended_metadata.pbenum.dart';

class ExtensionQuery extends $pb.GeneratedMessage {
  factory ExtensionQuery({
    $1.ExtensionKind? extensionKind,
    $core.String? etag,
  }) {
    final result = ExtensionQuery._();
    if (extensionKind != null) result.extensionKind = extensionKind;
    if (etag != null) result.etag = etag;
    return result;
  }

  ExtensionQuery._();

  factory ExtensionQuery.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExtensionQuery()..mergeFromBuffer(data, registry);
  factory ExtensionQuery.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExtensionQuery()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExtensionQuery',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.extendedmetadata'),
      createEmptyInstance: ExtensionQuery.$_createMessage)
    ..aE<$1.ExtensionKind>(1, _omitFieldNames ? '' : 'extensionKind',
        enumValues: $1.ExtensionKind.values)
    ..aOS(2, _omitFieldNames ? '' : 'etag')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionQuery clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionQuery copyWith(void Function(ExtensionQuery) updates) =>
      super.copyWith((message) => updates(message as ExtensionQuery))
          as ExtensionQuery;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ExtensionQuery() / ExtensionQuery.new instead')
  static ExtensionQuery create() => ExtensionQuery._();
  static $pb.GeneratedMessage $_createMessage() => ExtensionQuery._();
  @$core.override
  ExtensionQuery createEmptyInstance() => ExtensionQuery._();
  @$core.pragma('dart2js:noInline')
  static ExtensionQuery getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExtensionQuery>(
          ExtensionQuery.$_createMessage);
  static ExtensionQuery? _defaultInstance;

  @$pb.TagNumber(1)
  $1.ExtensionKind get extensionKind => $_getN(0);
  @$pb.TagNumber(1)
  set extensionKind($1.ExtensionKind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasExtensionKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get etag => $_getSZ(1);
  @$pb.TagNumber(2)
  set etag($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEtag() => $_has(1);
  @$pb.TagNumber(2)
  void clearEtag() => $_clearField(2);
}

class EntityRequest extends $pb.GeneratedMessage {
  factory EntityRequest({
    $core.String? entityUri,
    $core.Iterable<ExtensionQuery>? query,
  }) {
    final result = EntityRequest._();
    if (entityUri != null) result.entityUri = entityUri;
    if (query != null) result.query.addAll(query);
    return result;
  }

  EntityRequest._();

  factory EntityRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EntityRequest()..mergeFromBuffer(data, registry);
  factory EntityRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EntityRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EntityRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.extendedmetadata'),
      createEmptyInstance: EntityRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'entityUri')
    ..pPM<ExtensionQuery>(2, _omitFieldNames ? '' : 'query',
        subBuilder: ExtensionQuery.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EntityRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EntityRequest copyWith(void Function(EntityRequest) updates) =>
      super.copyWith((message) => updates(message as EntityRequest))
          as EntityRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EntityRequest() / EntityRequest.new instead')
  static EntityRequest create() => EntityRequest._();
  static $pb.GeneratedMessage $_createMessage() => EntityRequest._();
  @$core.override
  EntityRequest createEmptyInstance() => EntityRequest._();
  @$core.pragma('dart2js:noInline')
  static EntityRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EntityRequest>(
          EntityRequest.$_createMessage);
  static EntityRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get entityUri => $_getSZ(0);
  @$pb.TagNumber(1)
  set entityUri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEntityUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearEntityUri() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<ExtensionQuery> get query => $_getList(1);
}

class BatchedEntityRequestHeader extends $pb.GeneratedMessage {
  factory BatchedEntityRequestHeader({
    $core.String? country,
    $core.String? catalogue,
    $core.List<$core.int>? taskId,
  }) {
    final result = BatchedEntityRequestHeader._();
    if (country != null) result.country = country;
    if (catalogue != null) result.catalogue = catalogue;
    if (taskId != null) result.taskId = taskId;
    return result;
  }

  BatchedEntityRequestHeader._();

  factory BatchedEntityRequestHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatchedEntityRequestHeader()..mergeFromBuffer(data, registry);
  factory BatchedEntityRequestHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatchedEntityRequestHeader()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BatchedEntityRequestHeader',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.extendedmetadata'),
      createEmptyInstance: BatchedEntityRequestHeader.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'country')
    ..aOS(2, _omitFieldNames ? '' : 'catalogue')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'taskId', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatchedEntityRequestHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatchedEntityRequestHeader copyWith(
          void Function(BatchedEntityRequestHeader) updates) =>
      super.copyWith(
              (message) => updates(message as BatchedEntityRequestHeader))
          as BatchedEntityRequestHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use BatchedEntityRequestHeader() / BatchedEntityRequestHeader.new instead')
  static BatchedEntityRequestHeader create() => BatchedEntityRequestHeader._();
  static $pb.GeneratedMessage $_createMessage() =>
      BatchedEntityRequestHeader._();
  @$core.override
  BatchedEntityRequestHeader createEmptyInstance() =>
      BatchedEntityRequestHeader._();
  @$core.pragma('dart2js:noInline')
  static BatchedEntityRequestHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BatchedEntityRequestHeader>(
          BatchedEntityRequestHeader.$_createMessage);
  static BatchedEntityRequestHeader? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get country => $_getSZ(0);
  @$pb.TagNumber(1)
  set country($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCountry() => $_has(0);
  @$pb.TagNumber(1)
  void clearCountry() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get catalogue => $_getSZ(1);
  @$pb.TagNumber(2)
  set catalogue($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCatalogue() => $_has(1);
  @$pb.TagNumber(2)
  void clearCatalogue() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get taskId => $_getN(2);
  @$pb.TagNumber(3)
  set taskId($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTaskId() => $_has(2);
  @$pb.TagNumber(3)
  void clearTaskId() => $_clearField(3);
}

class BatchedEntityRequest extends $pb.GeneratedMessage {
  factory BatchedEntityRequest({
    BatchedEntityRequestHeader? header,
    $core.Iterable<EntityRequest>? entityRequest,
  }) {
    final result = BatchedEntityRequest._();
    if (header != null) result.header = header;
    if (entityRequest != null) result.entityRequest.addAll(entityRequest);
    return result;
  }

  BatchedEntityRequest._();

  factory BatchedEntityRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatchedEntityRequest()..mergeFromBuffer(data, registry);
  factory BatchedEntityRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatchedEntityRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BatchedEntityRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.extendedmetadata'),
      createEmptyInstance: BatchedEntityRequest.$_createMessage)
    ..aOM<BatchedEntityRequestHeader>(1, _omitFieldNames ? '' : 'header',
        subBuilder: BatchedEntityRequestHeader.$_createMessage)
    ..pPM<EntityRequest>(2, _omitFieldNames ? '' : 'entityRequest',
        subBuilder: EntityRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatchedEntityRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatchedEntityRequest copyWith(void Function(BatchedEntityRequest) updates) =>
      super.copyWith((message) => updates(message as BatchedEntityRequest))
          as BatchedEntityRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use BatchedEntityRequest() / BatchedEntityRequest.new instead')
  static BatchedEntityRequest create() => BatchedEntityRequest._();
  static $pb.GeneratedMessage $_createMessage() => BatchedEntityRequest._();
  @$core.override
  BatchedEntityRequest createEmptyInstance() => BatchedEntityRequest._();
  @$core.pragma('dart2js:noInline')
  static BatchedEntityRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BatchedEntityRequest>(
          BatchedEntityRequest.$_createMessage);
  static BatchedEntityRequest? _defaultInstance;

  @$pb.TagNumber(1)
  BatchedEntityRequestHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(BatchedEntityRequestHeader value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  BatchedEntityRequestHeader ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<EntityRequest> get entityRequest => $_getList(1);
}

class EntityExtensionDataArrayHeader extends $pb.GeneratedMessage {
  factory EntityExtensionDataArrayHeader({
    $core.int? providerErrorStatus,
    $fixnum.Int64? cacheTtlInSeconds,
    $fixnum.Int64? offlineTtlInSeconds,
    ExtensionType? extensionType,
  }) {
    final result = EntityExtensionDataArrayHeader._();
    if (providerErrorStatus != null)
      result.providerErrorStatus = providerErrorStatus;
    if (cacheTtlInSeconds != null) result.cacheTtlInSeconds = cacheTtlInSeconds;
    if (offlineTtlInSeconds != null)
      result.offlineTtlInSeconds = offlineTtlInSeconds;
    if (extensionType != null) result.extensionType = extensionType;
    return result;
  }

  EntityExtensionDataArrayHeader._();

  factory EntityExtensionDataArrayHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EntityExtensionDataArrayHeader()..mergeFromBuffer(data, registry);
  factory EntityExtensionDataArrayHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EntityExtensionDataArrayHeader()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EntityExtensionDataArrayHeader',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.extendedmetadata'),
      createEmptyInstance: EntityExtensionDataArrayHeader.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'providerErrorStatus')
    ..aInt64(2, _omitFieldNames ? '' : 'cacheTtlInSeconds')
    ..aInt64(3, _omitFieldNames ? '' : 'offlineTtlInSeconds')
    ..aE<ExtensionType>(4, _omitFieldNames ? '' : 'extensionType',
        enumValues: ExtensionType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EntityExtensionDataArrayHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EntityExtensionDataArrayHeader copyWith(
          void Function(EntityExtensionDataArrayHeader) updates) =>
      super.copyWith(
              (message) => updates(message as EntityExtensionDataArrayHeader))
          as EntityExtensionDataArrayHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use EntityExtensionDataArrayHeader() / EntityExtensionDataArrayHeader.new instead')
  static EntityExtensionDataArrayHeader create() =>
      EntityExtensionDataArrayHeader._();
  static $pb.GeneratedMessage $_createMessage() =>
      EntityExtensionDataArrayHeader._();
  @$core.override
  EntityExtensionDataArrayHeader createEmptyInstance() =>
      EntityExtensionDataArrayHeader._();
  @$core.pragma('dart2js:noInline')
  static EntityExtensionDataArrayHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EntityExtensionDataArrayHeader>(
          EntityExtensionDataArrayHeader.$_createMessage);
  static EntityExtensionDataArrayHeader? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get providerErrorStatus => $_getIZ(0);
  @$pb.TagNumber(1)
  set providerErrorStatus($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProviderErrorStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearProviderErrorStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get cacheTtlInSeconds => $_getI64(1);
  @$pb.TagNumber(2)
  set cacheTtlInSeconds($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCacheTtlInSeconds() => $_has(1);
  @$pb.TagNumber(2)
  void clearCacheTtlInSeconds() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get offlineTtlInSeconds => $_getI64(2);
  @$pb.TagNumber(3)
  set offlineTtlInSeconds($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOfflineTtlInSeconds() => $_has(2);
  @$pb.TagNumber(3)
  void clearOfflineTtlInSeconds() => $_clearField(3);

  @$pb.TagNumber(4)
  ExtensionType get extensionType => $_getN(3);
  @$pb.TagNumber(4)
  set extensionType(ExtensionType value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasExtensionType() => $_has(3);
  @$pb.TagNumber(4)
  void clearExtensionType() => $_clearField(4);
}

class EntityExtensionDataArray extends $pb.GeneratedMessage {
  factory EntityExtensionDataArray({
    EntityExtensionDataArrayHeader? header,
    $1.ExtensionKind? extensionKind,
    $core.Iterable<$0.EntityExtensionData>? extensionData,
  }) {
    final result = EntityExtensionDataArray._();
    if (header != null) result.header = header;
    if (extensionKind != null) result.extensionKind = extensionKind;
    if (extensionData != null) result.extensionData.addAll(extensionData);
    return result;
  }

  EntityExtensionDataArray._();

  factory EntityExtensionDataArray.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EntityExtensionDataArray()..mergeFromBuffer(data, registry);
  factory EntityExtensionDataArray.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EntityExtensionDataArray()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EntityExtensionDataArray',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.extendedmetadata'),
      createEmptyInstance: EntityExtensionDataArray.$_createMessage)
    ..aOM<EntityExtensionDataArrayHeader>(1, _omitFieldNames ? '' : 'header',
        subBuilder: EntityExtensionDataArrayHeader.$_createMessage)
    ..aE<$1.ExtensionKind>(2, _omitFieldNames ? '' : 'extensionKind',
        enumValues: $1.ExtensionKind.values)
    ..pPM<$0.EntityExtensionData>(3, _omitFieldNames ? '' : 'extensionData',
        subBuilder: $0.EntityExtensionData.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EntityExtensionDataArray clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EntityExtensionDataArray copyWith(
          void Function(EntityExtensionDataArray) updates) =>
      super.copyWith((message) => updates(message as EntityExtensionDataArray))
          as EntityExtensionDataArray;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use EntityExtensionDataArray() / EntityExtensionDataArray.new instead')
  static EntityExtensionDataArray create() => EntityExtensionDataArray._();
  static $pb.GeneratedMessage $_createMessage() => EntityExtensionDataArray._();
  @$core.override
  EntityExtensionDataArray createEmptyInstance() =>
      EntityExtensionDataArray._();
  @$core.pragma('dart2js:noInline')
  static EntityExtensionDataArray getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EntityExtensionDataArray>(
          EntityExtensionDataArray.$_createMessage);
  static EntityExtensionDataArray? _defaultInstance;

  @$pb.TagNumber(1)
  EntityExtensionDataArrayHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(EntityExtensionDataArrayHeader value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  EntityExtensionDataArrayHeader ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ExtensionKind get extensionKind => $_getN(1);
  @$pb.TagNumber(2)
  set extensionKind($1.ExtensionKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExtensionKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearExtensionKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$0.EntityExtensionData> get extensionData => $_getList(2);
}

class BatchedExtensionResponseHeader extends $pb.GeneratedMessage {
  factory BatchedExtensionResponseHeader() =>
      BatchedExtensionResponseHeader._();

  BatchedExtensionResponseHeader._();

  factory BatchedExtensionResponseHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatchedExtensionResponseHeader()..mergeFromBuffer(data, registry);
  factory BatchedExtensionResponseHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatchedExtensionResponseHeader()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BatchedExtensionResponseHeader',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.extendedmetadata'),
      createEmptyInstance: BatchedExtensionResponseHeader.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatchedExtensionResponseHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatchedExtensionResponseHeader copyWith(
          void Function(BatchedExtensionResponseHeader) updates) =>
      super.copyWith(
              (message) => updates(message as BatchedExtensionResponseHeader))
          as BatchedExtensionResponseHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use BatchedExtensionResponseHeader() / BatchedExtensionResponseHeader.new instead')
  static BatchedExtensionResponseHeader create() =>
      BatchedExtensionResponseHeader._();
  static $pb.GeneratedMessage $_createMessage() =>
      BatchedExtensionResponseHeader._();
  @$core.override
  BatchedExtensionResponseHeader createEmptyInstance() =>
      BatchedExtensionResponseHeader._();
  @$core.pragma('dart2js:noInline')
  static BatchedExtensionResponseHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BatchedExtensionResponseHeader>(
          BatchedExtensionResponseHeader.$_createMessage);
  static BatchedExtensionResponseHeader? _defaultInstance;
}

class BatchedExtensionResponse extends $pb.GeneratedMessage {
  factory BatchedExtensionResponse({
    BatchedExtensionResponseHeader? header,
    $core.Iterable<EntityExtensionDataArray>? extendedMetadata,
  }) {
    final result = BatchedExtensionResponse._();
    if (header != null) result.header = header;
    if (extendedMetadata != null)
      result.extendedMetadata.addAll(extendedMetadata);
    return result;
  }

  BatchedExtensionResponse._();

  factory BatchedExtensionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatchedExtensionResponse()..mergeFromBuffer(data, registry);
  factory BatchedExtensionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatchedExtensionResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BatchedExtensionResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.extendedmetadata'),
      createEmptyInstance: BatchedExtensionResponse.$_createMessage)
    ..aOM<BatchedExtensionResponseHeader>(1, _omitFieldNames ? '' : 'header',
        subBuilder: BatchedExtensionResponseHeader.$_createMessage)
    ..pPM<EntityExtensionDataArray>(
        2, _omitFieldNames ? '' : 'extendedMetadata',
        subBuilder: EntityExtensionDataArray.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatchedExtensionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatchedExtensionResponse copyWith(
          void Function(BatchedExtensionResponse) updates) =>
      super.copyWith((message) => updates(message as BatchedExtensionResponse))
          as BatchedExtensionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use BatchedExtensionResponse() / BatchedExtensionResponse.new instead')
  static BatchedExtensionResponse create() => BatchedExtensionResponse._();
  static $pb.GeneratedMessage $_createMessage() => BatchedExtensionResponse._();
  @$core.override
  BatchedExtensionResponse createEmptyInstance() =>
      BatchedExtensionResponse._();
  @$core.pragma('dart2js:noInline')
  static BatchedExtensionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BatchedExtensionResponse>(
          BatchedExtensionResponse.$_createMessage);
  static BatchedExtensionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  BatchedExtensionResponseHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(BatchedExtensionResponseHeader value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  BatchedExtensionResponseHeader ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<EntityExtensionDataArray> get extendedMetadata => $_getList(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
