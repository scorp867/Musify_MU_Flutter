// This is a generated file - do not edit.
//
// Generated from spotify/contentagnostic/v2/identity_trait.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class IdentityTrait extends $pb.GeneratedMessage {
  factory IdentityTrait({
    $core.String? type,
    $core.String? name,
    $core.String? description,
    EntityReference? contentHierarchyParent,
    $core.Iterable<Contributor>? contributors,
  }) {
    final result = IdentityTrait._();
    if (type != null) result.type = type;
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (contentHierarchyParent != null)
      result.contentHierarchyParent = contentHierarchyParent;
    if (contributors != null) result.contributors.addAll(contributors);
    return result;
  }

  IdentityTrait._();

  factory IdentityTrait.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IdentityTrait()..mergeFromBuffer(data, registry);
  factory IdentityTrait.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IdentityTrait()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IdentityTrait',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: IdentityTrait.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..aOM<EntityReference>(4, _omitFieldNames ? '' : 'contentHierarchyParent',
        subBuilder: EntityReference.$_createMessage)
    ..pPM<Contributor>(5, _omitFieldNames ? '' : 'contributors',
        subBuilder: Contributor.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IdentityTrait clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IdentityTrait copyWith(void Function(IdentityTrait) updates) =>
      super.copyWith((message) => updates(message as IdentityTrait))
          as IdentityTrait;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use IdentityTrait() / IdentityTrait.new instead')
  static IdentityTrait create() => IdentityTrait._();
  static $pb.GeneratedMessage $_createMessage() => IdentityTrait._();
  @$core.override
  IdentityTrait createEmptyInstance() => IdentityTrait._();
  @$core.pragma('dart2js:noInline')
  static IdentityTrait getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IdentityTrait>(
          IdentityTrait.$_createMessage);
  static IdentityTrait? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);

  @$pb.TagNumber(4)
  EntityReference get contentHierarchyParent => $_getN(3);
  @$pb.TagNumber(4)
  set contentHierarchyParent(EntityReference value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasContentHierarchyParent() => $_has(3);
  @$pb.TagNumber(4)
  void clearContentHierarchyParent() => $_clearField(4);
  @$pb.TagNumber(4)
  EntityReference ensureContentHierarchyParent() => $_ensure(3);

  @$pb.TagNumber(5)
  $pb.PbList<Contributor> get contributors => $_getList(4);
}

class EntityReference extends $pb.GeneratedMessage {
  factory EntityReference({
    $core.String? uri,
  }) {
    final result = EntityReference._();
    if (uri != null) result.uri = uri;
    return result;
  }

  EntityReference._();

  factory EntityReference.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EntityReference()..mergeFromBuffer(data, registry);
  factory EntityReference.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EntityReference()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EntityReference',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: EntityReference.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EntityReference clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EntityReference copyWith(void Function(EntityReference) updates) =>
      super.copyWith((message) => updates(message as EntityReference))
          as EntityReference;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EntityReference() / EntityReference.new instead')
  static EntityReference create() => EntityReference._();
  static $pb.GeneratedMessage $_createMessage() => EntityReference._();
  @$core.override
  EntityReference createEmptyInstance() => EntityReference._();
  @$core.pragma('dart2js:noInline')
  static EntityReference getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EntityReference>(
          EntityReference.$_createMessage);
  static EntityReference? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearUri() => $_clearField(1);
}

class Contributor extends $pb.GeneratedMessage {
  factory Contributor({
    ContributorReference? reference,
    $core.String? role,
  }) {
    final result = Contributor._();
    if (reference != null) result.reference = reference;
    if (role != null) result.role = role;
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
    ..aOM<ContributorReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: ContributorReference.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'role')
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
  ContributorReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference(ContributorReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  ContributorReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get role => $_getSZ(1);
  @$pb.TagNumber(2)
  set role($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRole() => $_has(1);
  @$pb.TagNumber(2)
  void clearRole() => $_clearField(2);
}

class ContributorReference extends $pb.GeneratedMessage {
  factory ContributorReference({
    $core.String? uri,
    $core.String? name,
  }) {
    final result = ContributorReference._();
    if (uri != null) result.uri = uri;
    if (name != null) result.name = name;
    return result;
  }

  ContributorReference._();

  factory ContributorReference.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContributorReference()..mergeFromBuffer(data, registry);
  factory ContributorReference.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContributorReference()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContributorReference',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: ContributorReference.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContributorReference clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContributorReference copyWith(void Function(ContributorReference) updates) =>
      super.copyWith((message) => updates(message as ContributorReference))
          as ContributorReference;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ContributorReference() / ContributorReference.new instead')
  static ContributorReference create() => ContributorReference._();
  static $pb.GeneratedMessage $_createMessage() => ContributorReference._();
  @$core.override
  ContributorReference createEmptyInstance() => ContributorReference._();
  @$core.pragma('dart2js:noInline')
  static ContributorReference getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContributorReference>(
          ContributorReference.$_createMessage);
  static ContributorReference? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearUri() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
