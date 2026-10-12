// This is a generated file - do not edit.
//
// Generated from spotify/contentagnostic/v2/credits_trait.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// / Role group categorization for a contributor.
/// / Decompiled from `RoleGroup.java`.
class RoleGroup extends $pb.GeneratedMessage {
  factory RoleGroup({
    $core.String? name,
  }) {
    final result = RoleGroup._();
    if (name != null) result.name = name;
    return result;
  }

  RoleGroup._();

  factory RoleGroup.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RoleGroup()..mergeFromBuffer(data, registry);
  factory RoleGroup.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RoleGroup()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RoleGroup',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: RoleGroup.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoleGroup clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoleGroup copyWith(void Function(RoleGroup) updates) =>
      super.copyWith((message) => updates(message as RoleGroup)) as RoleGroup;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RoleGroup() / RoleGroup.new instead')
  static RoleGroup create() => RoleGroup._();
  static $pb.GeneratedMessage $_createMessage() => RoleGroup._();
  @$core.override
  RoleGroup createEmptyInstance() => RoleGroup._();
  @$core.pragma('dart2js:noInline')
  static RoleGroup getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RoleGroup>(RoleGroup.$_createMessage);
  static RoleGroup? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
}

/// / A single contributor (artist, writer, producer, etc.) on a track.
/// / Decompiled from `Contributor.java`.
/// /
/// / Field numbers match the decompiled APK exactly:
/// /   name=1, role=2, uri=3, reference=4, url=5, role_group=6, ai_attribution=7
class Contributor extends $pb.GeneratedMessage {
  factory Contributor({
    $core.String? name,
    $core.String? role,
    $core.String? uri,
    $core.String? url,
    RoleGroup? roleGroup,
  }) {
    final result = Contributor._();
    if (name != null) result.name = name;
    if (role != null) result.role = role;
    if (uri != null) result.uri = uri;
    if (url != null) result.url = url;
    if (roleGroup != null) result.roleGroup = roleGroup;
    return result;
  }

  Contributor._();

  factory Contributor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Contributor()..mergeFromBuffer(data, registry);
  factory Contributor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Contributor()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Contributor',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: Contributor.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'role')
    ..aOS(3, _omitFieldNames ? '' : 'uri')
    ..aOS(5, _omitFieldNames ? '' : 'url')
    ..aOM<RoleGroup>(6, _omitFieldNames ? '' : 'roleGroup',
        subBuilder: RoleGroup.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Contributor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Contributor copyWith(void Function(Contributor) updates) =>
      super.copyWith((message) => updates(message as Contributor))
          as Contributor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Contributor() / Contributor.new instead')
  static Contributor create() => Contributor._();
  static $pb.GeneratedMessage $_createMessage() => Contributor._();
  @$core.override
  Contributor createEmptyInstance() => Contributor._();
  @$core.pragma('dart2js:noInline')
  static Contributor getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Contributor>(
          Contributor.$_createMessage);
  static Contributor? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get role => $_getSZ(1);
  @$pb.TagNumber(2)
  set role($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRole() => $_has(1);
  @$pb.TagNumber(2)
  void clearRole() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get uri => $_getSZ(2);
  @$pb.TagNumber(3)
  set uri($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUri() => $_has(2);
  @$pb.TagNumber(3)
  void clearUri() => $_clearField(3);

  /// field 4: Reference (nested message — omitted, not needed for card UI)
  @$pb.TagNumber(5)
  $core.String get url => $_getSZ(3);
  @$pb.TagNumber(5)
  set url($core.String value) => $_setString(3, value);
  @$pb.TagNumber(5)
  $core.bool hasUrl() => $_has(3);
  @$pb.TagNumber(5)
  void clearUrl() => $_clearField(5);

  @$pb.TagNumber(6)
  RoleGroup get roleGroup => $_getN(4);
  @$pb.TagNumber(6)
  set roleGroup(RoleGroup value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRoleGroup() => $_has(4);
  @$pb.TagNumber(6)
  void clearRoleGroup() => $_clearField(6);
  @$pb.TagNumber(6)
  RoleGroup ensureRoleGroup() => $_ensure(4);
}

/// / Source attribution for credits.
/// / Decompiled from `CreditsSource.java`.
class CreditsSource extends $pb.GeneratedMessage {
  factory CreditsSource({
    $core.String? name,
  }) {
    final result = CreditsSource._();
    if (name != null) result.name = name;
    return result;
  }

  CreditsSource._();

  factory CreditsSource.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreditsSource()..mergeFromBuffer(data, registry);
  factory CreditsSource.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreditsSource()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreditsSource',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: CreditsSource.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreditsSource clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreditsSource copyWith(void Function(CreditsSource) updates) =>
      super.copyWith((message) => updates(message as CreditsSource))
          as CreditsSource;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CreditsSource() / CreditsSource.new instead')
  static CreditsSource create() => CreditsSource._();
  static $pb.GeneratedMessage $_createMessage() => CreditsSource._();
  @$core.override
  CreditsSource createEmptyInstance() => CreditsSource._();
  @$core.pragma('dart2js:noInline')
  static CreditsSource getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreditsSource>(
          CreditsSource.$_createMessage);
  static CreditsSource? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
}

/// / ExtensionKind 186 — CREDITS_V2_TRAIT.
/// / Decompiled from `CreditsTrait.java`.
/// /
/// / Contains the full list of track contributors with their roles,
/// / and optional source attributions.
class CreditsTrait extends $pb.GeneratedMessage {
  factory CreditsTrait({
    $core.Iterable<Contributor>? contributors,
    $core.Iterable<CreditsSource>? sources,
  }) {
    final result = CreditsTrait._();
    if (contributors != null) result.contributors.addAll(contributors);
    if (sources != null) result.sources.addAll(sources);
    return result;
  }

  CreditsTrait._();

  factory CreditsTrait.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreditsTrait()..mergeFromBuffer(data, registry);
  factory CreditsTrait.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreditsTrait()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreditsTrait',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: CreditsTrait.$_createMessage)
    ..pPM<Contributor>(1, _omitFieldNames ? '' : 'contributors',
        subBuilder: Contributor.$_createMessage)
    ..pPM<CreditsSource>(2, _omitFieldNames ? '' : 'sources',
        subBuilder: CreditsSource.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreditsTrait clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreditsTrait copyWith(void Function(CreditsTrait) updates) =>
      super.copyWith((message) => updates(message as CreditsTrait))
          as CreditsTrait;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CreditsTrait() / CreditsTrait.new instead')
  static CreditsTrait create() => CreditsTrait._();
  static $pb.GeneratedMessage $_createMessage() => CreditsTrait._();
  @$core.override
  CreditsTrait createEmptyInstance() => CreditsTrait._();
  @$core.pragma('dart2js:noInline')
  static CreditsTrait getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreditsTrait>(
          CreditsTrait.$_createMessage);
  static CreditsTrait? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Contributor> get contributors => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<CreditsSource> get sources => $_getList(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
