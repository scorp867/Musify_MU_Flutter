// This is a generated file - do not edit.
//
// Generated from spotify/entity_extension_data.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class EntityExtensionDataHeader extends $pb.GeneratedMessage {
  factory EntityExtensionDataHeader({
    $core.int? statusCode,
    $core.String? etag,
    $core.String? locale,
    $fixnum.Int64? cacheTtlInSeconds,
    $fixnum.Int64? offlineTtlInSeconds,
  }) {
    final result = EntityExtensionDataHeader._();
    if (statusCode != null) result.statusCode = statusCode;
    if (etag != null) result.etag = etag;
    if (locale != null) result.locale = locale;
    if (cacheTtlInSeconds != null) result.cacheTtlInSeconds = cacheTtlInSeconds;
    if (offlineTtlInSeconds != null)
      result.offlineTtlInSeconds = offlineTtlInSeconds;
    return result;
  }

  EntityExtensionDataHeader._();

  factory EntityExtensionDataHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EntityExtensionDataHeader()..mergeFromBuffer(data, registry);
  factory EntityExtensionDataHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EntityExtensionDataHeader()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EntityExtensionDataHeader',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.extendedmetadata'),
      createEmptyInstance: EntityExtensionDataHeader.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'statusCode')
    ..aOS(2, _omitFieldNames ? '' : 'etag')
    ..aOS(3, _omitFieldNames ? '' : 'locale')
    ..aInt64(4, _omitFieldNames ? '' : 'cacheTtlInSeconds')
    ..aInt64(5, _omitFieldNames ? '' : 'offlineTtlInSeconds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EntityExtensionDataHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EntityExtensionDataHeader copyWith(
          void Function(EntityExtensionDataHeader) updates) =>
      super.copyWith((message) => updates(message as EntityExtensionDataHeader))
          as EntityExtensionDataHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use EntityExtensionDataHeader() / EntityExtensionDataHeader.new instead')
  static EntityExtensionDataHeader create() => EntityExtensionDataHeader._();
  static $pb.GeneratedMessage $_createMessage() =>
      EntityExtensionDataHeader._();
  @$core.override
  EntityExtensionDataHeader createEmptyInstance() =>
      EntityExtensionDataHeader._();
  @$core.pragma('dart2js:noInline')
  static EntityExtensionDataHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EntityExtensionDataHeader>(
          EntityExtensionDataHeader.$_createMessage);
  static EntityExtensionDataHeader? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get statusCode => $_getIZ(0);
  @$pb.TagNumber(1)
  set statusCode($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatusCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatusCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get etag => $_getSZ(1);
  @$pb.TagNumber(2)
  set etag($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEtag() => $_has(1);
  @$pb.TagNumber(2)
  void clearEtag() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get locale => $_getSZ(2);
  @$pb.TagNumber(3)
  set locale($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLocale() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocale() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get cacheTtlInSeconds => $_getI64(3);
  @$pb.TagNumber(4)
  set cacheTtlInSeconds($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCacheTtlInSeconds() => $_has(3);
  @$pb.TagNumber(4)
  void clearCacheTtlInSeconds() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get offlineTtlInSeconds => $_getI64(4);
  @$pb.TagNumber(5)
  set offlineTtlInSeconds($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOfflineTtlInSeconds() => $_has(4);
  @$pb.TagNumber(5)
  void clearOfflineTtlInSeconds() => $_clearField(5);
}

class EntityExtensionData extends $pb.GeneratedMessage {
  factory EntityExtensionData({
    EntityExtensionDataHeader? header,
    $core.String? entityUri,
    $0.Any? extensionData,
  }) {
    final result = EntityExtensionData._();
    if (header != null) result.header = header;
    if (entityUri != null) result.entityUri = entityUri;
    if (extensionData != null) result.extensionData = extensionData;
    return result;
  }

  EntityExtensionData._();

  factory EntityExtensionData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EntityExtensionData()..mergeFromBuffer(data, registry);
  factory EntityExtensionData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EntityExtensionData()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EntityExtensionData',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.extendedmetadata'),
      createEmptyInstance: EntityExtensionData.$_createMessage)
    ..aOM<EntityExtensionDataHeader>(1, _omitFieldNames ? '' : 'header',
        subBuilder: EntityExtensionDataHeader.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'entityUri')
    ..aOM<$0.Any>(3, _omitFieldNames ? '' : 'extensionData',
        subBuilder: $0.Any.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EntityExtensionData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EntityExtensionData copyWith(void Function(EntityExtensionData) updates) =>
      super.copyWith((message) => updates(message as EntityExtensionData))
          as EntityExtensionData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use EntityExtensionData() / EntityExtensionData.new instead')
  static EntityExtensionData create() => EntityExtensionData._();
  static $pb.GeneratedMessage $_createMessage() => EntityExtensionData._();
  @$core.override
  EntityExtensionData createEmptyInstance() => EntityExtensionData._();
  @$core.pragma('dart2js:noInline')
  static EntityExtensionData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EntityExtensionData>(
          EntityExtensionData.$_createMessage);
  static EntityExtensionData? _defaultInstance;

  @$pb.TagNumber(1)
  EntityExtensionDataHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(EntityExtensionDataHeader value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  EntityExtensionDataHeader ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get entityUri => $_getSZ(1);
  @$pb.TagNumber(2)
  set entityUri($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEntityUri() => $_has(1);
  @$pb.TagNumber(2)
  void clearEntityUri() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Any get extensionData => $_getN(2);
  @$pb.TagNumber(3)
  set extensionData($0.Any value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasExtensionData() => $_has(2);
  @$pb.TagNumber(3)
  void clearExtensionData() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Any ensureExtensionData() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
