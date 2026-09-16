// This is a generated file - do not edit.
//
// Generated from spotify/casita_true.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class CasitaResponse extends $pb.GeneratedMessage {
  factory CasitaResponse({
    CasitaSections? sections,
    CasitaRepository? repository,
    CasitaPageMeta? pageMeta,
    $core.Iterable<CasitaMixUri>? mixUris,
  }) {
    final result = CasitaResponse._();
    if (sections != null) result.sections = sections;
    if (repository != null) result.repository = repository;
    if (pageMeta != null) result.pageMeta = pageMeta;
    if (mixUris != null) result.mixUris.addAll(mixUris);
    return result;
  }

  CasitaResponse._();

  factory CasitaResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaResponse()..mergeFromBuffer(data, registry);
  factory CasitaResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CasitaResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: CasitaResponse.$_createMessage)
    ..aOM<CasitaSections>(1, _omitFieldNames ? '' : 'sections',
        subBuilder: CasitaSections.$_createMessage)
    ..aOM<CasitaRepository>(2, _omitFieldNames ? '' : 'repository',
        subBuilder: CasitaRepository.$_createMessage)
    ..aOM<CasitaPageMeta>(3, _omitFieldNames ? '' : 'pageMeta',
        subBuilder: CasitaPageMeta.$_createMessage)
    ..pPM<CasitaMixUri>(999, _omitFieldNames ? '' : 'mixUris',
        subBuilder: CasitaMixUri.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaResponse copyWith(void Function(CasitaResponse) updates) =>
      super.copyWith((message) => updates(message as CasitaResponse))
          as CasitaResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CasitaResponse() / CasitaResponse.new instead')
  static CasitaResponse create() => CasitaResponse._();
  static $pb.GeneratedMessage $_createMessage() => CasitaResponse._();
  @$core.override
  CasitaResponse createEmptyInstance() => CasitaResponse._();
  @$core.pragma('dart2js:noInline')
  static CasitaResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CasitaResponse>(
          CasitaResponse.$_createMessage);
  static CasitaResponse? _defaultInstance;

  @$pb.TagNumber(1)
  CasitaSections get sections => $_getN(0);
  @$pb.TagNumber(1)
  set sections(CasitaSections value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSections() => $_has(0);
  @$pb.TagNumber(1)
  void clearSections() => $_clearField(1);
  @$pb.TagNumber(1)
  CasitaSections ensureSections() => $_ensure(0);

  @$pb.TagNumber(2)
  CasitaRepository get repository => $_getN(1);
  @$pb.TagNumber(2)
  set repository(CasitaRepository value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRepository() => $_has(1);
  @$pb.TagNumber(2)
  void clearRepository() => $_clearField(2);
  @$pb.TagNumber(2)
  CasitaRepository ensureRepository() => $_ensure(1);

  @$pb.TagNumber(3)
  CasitaPageMeta get pageMeta => $_getN(2);
  @$pb.TagNumber(3)
  set pageMeta(CasitaPageMeta value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPageMeta() => $_has(2);
  @$pb.TagNumber(3)
  void clearPageMeta() => $_clearField(3);
  @$pb.TagNumber(3)
  CasitaPageMeta ensurePageMeta() => $_ensure(2);

  @$pb.TagNumber(999)
  $pb.PbList<CasitaMixUri> get mixUris => $_getList(3);
}

class CasitaSections extends $pb.GeneratedMessage {
  factory CasitaSections({
    $core.Iterable<CasitaSection>? sections,
  }) {
    final result = CasitaSections._();
    if (sections != null) result.sections.addAll(sections);
    return result;
  }

  CasitaSections._();

  factory CasitaSections.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaSections()..mergeFromBuffer(data, registry);
  factory CasitaSections.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaSections()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CasitaSections',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: CasitaSections.$_createMessage)
    ..pPM<CasitaSection>(1, _omitFieldNames ? '' : 'sections',
        subBuilder: CasitaSection.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaSections clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaSections copyWith(void Function(CasitaSections) updates) =>
      super.copyWith((message) => updates(message as CasitaSections))
          as CasitaSections;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CasitaSections() / CasitaSections.new instead')
  static CasitaSections create() => CasitaSections._();
  static $pb.GeneratedMessage $_createMessage() => CasitaSections._();
  @$core.override
  CasitaSections createEmptyInstance() => CasitaSections._();
  @$core.pragma('dart2js:noInline')
  static CasitaSections getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CasitaSections>(
          CasitaSections.$_createMessage);
  static CasitaSections? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CasitaSection> get sections => $_getList(0);
}

class CasitaSection extends $pb.GeneratedMessage {
  factory CasitaSection({
    SectionIdWrapper? idWrapper,
    SectionBodyShortcuts? bodyShortcuts,
    SectionBodyStandard? bodyStandard,
    SectionBodyPodcast? bodyPodcast,
    SectionBodyMusicfeed? bodyMusicfeed,
    SectionBodyRecents? bodyRecents,
  }) {
    final result = CasitaSection._();
    if (idWrapper != null) result.idWrapper = idWrapper;
    if (bodyShortcuts != null) result.bodyShortcuts = bodyShortcuts;
    if (bodyStandard != null) result.bodyStandard = bodyStandard;
    if (bodyPodcast != null) result.bodyPodcast = bodyPodcast;
    if (bodyMusicfeed != null) result.bodyMusicfeed = bodyMusicfeed;
    if (bodyRecents != null) result.bodyRecents = bodyRecents;
    return result;
  }

  CasitaSection._();

  factory CasitaSection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaSection()..mergeFromBuffer(data, registry);
  factory CasitaSection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaSection()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CasitaSection',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: CasitaSection.$_createMessage)
    ..aOM<SectionIdWrapper>(1, _omitFieldNames ? '' : 'idWrapper',
        subBuilder: SectionIdWrapper.$_createMessage)
    ..aOM<SectionBodyShortcuts>(2, _omitFieldNames ? '' : 'bodyShortcuts',
        subBuilder: SectionBodyShortcuts.$_createMessage)
    ..aOM<SectionBodyStandard>(3, _omitFieldNames ? '' : 'bodyStandard',
        subBuilder: SectionBodyStandard.$_createMessage)
    ..aOM<SectionBodyPodcast>(4, _omitFieldNames ? '' : 'bodyPodcast',
        subBuilder: SectionBodyPodcast.$_createMessage)
    ..aOM<SectionBodyMusicfeed>(6, _omitFieldNames ? '' : 'bodyMusicfeed',
        subBuilder: SectionBodyMusicfeed.$_createMessage)
    ..aOM<SectionBodyRecents>(10, _omitFieldNames ? '' : 'bodyRecents',
        subBuilder: SectionBodyRecents.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaSection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaSection copyWith(void Function(CasitaSection) updates) =>
      super.copyWith((message) => updates(message as CasitaSection))
          as CasitaSection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CasitaSection() / CasitaSection.new instead')
  static CasitaSection create() => CasitaSection._();
  static $pb.GeneratedMessage $_createMessage() => CasitaSection._();
  @$core.override
  CasitaSection createEmptyInstance() => CasitaSection._();
  @$core.pragma('dart2js:noInline')
  static CasitaSection getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CasitaSection>(
          CasitaSection.$_createMessage);
  static CasitaSection? _defaultInstance;

  @$pb.TagNumber(1)
  SectionIdWrapper get idWrapper => $_getN(0);
  @$pb.TagNumber(1)
  set idWrapper(SectionIdWrapper value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasIdWrapper() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdWrapper() => $_clearField(1);
  @$pb.TagNumber(1)
  SectionIdWrapper ensureIdWrapper() => $_ensure(0);

  @$pb.TagNumber(2)
  SectionBodyShortcuts get bodyShortcuts => $_getN(1);
  @$pb.TagNumber(2)
  set bodyShortcuts(SectionBodyShortcuts value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasBodyShortcuts() => $_has(1);
  @$pb.TagNumber(2)
  void clearBodyShortcuts() => $_clearField(2);
  @$pb.TagNumber(2)
  SectionBodyShortcuts ensureBodyShortcuts() => $_ensure(1);

  @$pb.TagNumber(3)
  SectionBodyStandard get bodyStandard => $_getN(2);
  @$pb.TagNumber(3)
  set bodyStandard(SectionBodyStandard value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasBodyStandard() => $_has(2);
  @$pb.TagNumber(3)
  void clearBodyStandard() => $_clearField(3);
  @$pb.TagNumber(3)
  SectionBodyStandard ensureBodyStandard() => $_ensure(2);

  @$pb.TagNumber(4)
  SectionBodyPodcast get bodyPodcast => $_getN(3);
  @$pb.TagNumber(4)
  set bodyPodcast(SectionBodyPodcast value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasBodyPodcast() => $_has(3);
  @$pb.TagNumber(4)
  void clearBodyPodcast() => $_clearField(4);
  @$pb.TagNumber(4)
  SectionBodyPodcast ensureBodyPodcast() => $_ensure(3);

  @$pb.TagNumber(6)
  SectionBodyMusicfeed get bodyMusicfeed => $_getN(4);
  @$pb.TagNumber(6)
  set bodyMusicfeed(SectionBodyMusicfeed value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasBodyMusicfeed() => $_has(4);
  @$pb.TagNumber(6)
  void clearBodyMusicfeed() => $_clearField(6);
  @$pb.TagNumber(6)
  SectionBodyMusicfeed ensureBodyMusicfeed() => $_ensure(4);

  @$pb.TagNumber(10)
  SectionBodyRecents get bodyRecents => $_getN(5);
  @$pb.TagNumber(10)
  set bodyRecents(SectionBodyRecents value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasBodyRecents() => $_has(5);
  @$pb.TagNumber(10)
  void clearBodyRecents() => $_clearField(10);
  @$pb.TagNumber(10)
  SectionBodyRecents ensureBodyRecents() => $_ensure(5);
}

class SectionIdWrapper extends $pb.GeneratedMessage {
  factory SectionIdWrapper({
    $core.String? id,
  }) {
    final result = SectionIdWrapper._();
    if (id != null) result.id = id;
    return result;
  }

  SectionIdWrapper._();

  factory SectionIdWrapper.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionIdWrapper()..mergeFromBuffer(data, registry);
  factory SectionIdWrapper.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionIdWrapper()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SectionIdWrapper',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: SectionIdWrapper.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionIdWrapper clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionIdWrapper copyWith(void Function(SectionIdWrapper) updates) =>
      super.copyWith((message) => updates(message as SectionIdWrapper))
          as SectionIdWrapper;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SectionIdWrapper() / SectionIdWrapper.new instead')
  static SectionIdWrapper create() => SectionIdWrapper._();
  static $pb.GeneratedMessage $_createMessage() => SectionIdWrapper._();
  @$core.override
  SectionIdWrapper createEmptyInstance() => SectionIdWrapper._();
  @$core.pragma('dart2js:noInline')
  static SectionIdWrapper getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SectionIdWrapper>(
          SectionIdWrapper.$_createMessage);
  static SectionIdWrapper? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class SectionBodyShortcuts extends $pb.GeneratedMessage {
  factory SectionBodyShortcuts({
    ShortcutsItemsContainer? itemsContainer,
  }) {
    final result = SectionBodyShortcuts._();
    if (itemsContainer != null) result.itemsContainer = itemsContainer;
    return result;
  }

  SectionBodyShortcuts._();

  factory SectionBodyShortcuts.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionBodyShortcuts()..mergeFromBuffer(data, registry);
  factory SectionBodyShortcuts.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionBodyShortcuts()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SectionBodyShortcuts',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: SectionBodyShortcuts.$_createMessage)
    ..aOM<ShortcutsItemsContainer>(2, _omitFieldNames ? '' : 'itemsContainer',
        subBuilder: ShortcutsItemsContainer.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionBodyShortcuts clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionBodyShortcuts copyWith(void Function(SectionBodyShortcuts) updates) =>
      super.copyWith((message) => updates(message as SectionBodyShortcuts))
          as SectionBodyShortcuts;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SectionBodyShortcuts() / SectionBodyShortcuts.new instead')
  static SectionBodyShortcuts create() => SectionBodyShortcuts._();
  static $pb.GeneratedMessage $_createMessage() => SectionBodyShortcuts._();
  @$core.override
  SectionBodyShortcuts createEmptyInstance() => SectionBodyShortcuts._();
  @$core.pragma('dart2js:noInline')
  static SectionBodyShortcuts getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SectionBodyShortcuts>(
          SectionBodyShortcuts.$_createMessage);
  static SectionBodyShortcuts? _defaultInstance;

  @$pb.TagNumber(2)
  ShortcutsItemsContainer get itemsContainer => $_getN(0);
  @$pb.TagNumber(2)
  set itemsContainer(ShortcutsItemsContainer value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItemsContainer() => $_has(0);
  @$pb.TagNumber(2)
  void clearItemsContainer() => $_clearField(2);
  @$pb.TagNumber(2)
  ShortcutsItemsContainer ensureItemsContainer() => $_ensure(0);
}

class ShortcutsItemsContainer extends $pb.GeneratedMessage {
  factory ShortcutsItemsContainer({
    $core.Iterable<SectionItem>? items,
  }) {
    final result = ShortcutsItemsContainer._();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ShortcutsItemsContainer._();

  factory ShortcutsItemsContainer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ShortcutsItemsContainer()..mergeFromBuffer(data, registry);
  factory ShortcutsItemsContainer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ShortcutsItemsContainer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShortcutsItemsContainer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: ShortcutsItemsContainer.$_createMessage)
    ..pPM<SectionItem>(1, _omitFieldNames ? '' : 'items',
        subBuilder: SectionItem.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShortcutsItemsContainer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShortcutsItemsContainer copyWith(
          void Function(ShortcutsItemsContainer) updates) =>
      super.copyWith((message) => updates(message as ShortcutsItemsContainer))
          as ShortcutsItemsContainer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ShortcutsItemsContainer() / ShortcutsItemsContainer.new instead')
  static ShortcutsItemsContainer create() => ShortcutsItemsContainer._();
  static $pb.GeneratedMessage $_createMessage() => ShortcutsItemsContainer._();
  @$core.override
  ShortcutsItemsContainer createEmptyInstance() => ShortcutsItemsContainer._();
  @$core.pragma('dart2js:noInline')
  static ShortcutsItemsContainer getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ShortcutsItemsContainer>(
          ShortcutsItemsContainer.$_createMessage);
  static ShortcutsItemsContainer? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SectionItem> get items => $_getList(0);
}

class SectionBodyStandard extends $pb.GeneratedMessage {
  factory SectionBodyStandard({
    SectionHeader? header,
    StandardItemsContainer? itemsContainer,
  }) {
    final result = SectionBodyStandard._();
    if (header != null) result.header = header;
    if (itemsContainer != null) result.itemsContainer = itemsContainer;
    return result;
  }

  SectionBodyStandard._();

  factory SectionBodyStandard.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionBodyStandard()..mergeFromBuffer(data, registry);
  factory SectionBodyStandard.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionBodyStandard()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SectionBodyStandard',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: SectionBodyStandard.$_createMessage)
    ..aOM<SectionHeader>(1, _omitFieldNames ? '' : 'header',
        subBuilder: SectionHeader.$_createMessage)
    ..aOM<StandardItemsContainer>(2, _omitFieldNames ? '' : 'itemsContainer',
        subBuilder: StandardItemsContainer.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionBodyStandard clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionBodyStandard copyWith(void Function(SectionBodyStandard) updates) =>
      super.copyWith((message) => updates(message as SectionBodyStandard))
          as SectionBodyStandard;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SectionBodyStandard() / SectionBodyStandard.new instead')
  static SectionBodyStandard create() => SectionBodyStandard._();
  static $pb.GeneratedMessage $_createMessage() => SectionBodyStandard._();
  @$core.override
  SectionBodyStandard createEmptyInstance() => SectionBodyStandard._();
  @$core.pragma('dart2js:noInline')
  static SectionBodyStandard getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SectionBodyStandard>(
          SectionBodyStandard.$_createMessage);
  static SectionBodyStandard? _defaultInstance;

  @$pb.TagNumber(1)
  SectionHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(SectionHeader value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  SectionHeader ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  StandardItemsContainer get itemsContainer => $_getN(1);
  @$pb.TagNumber(2)
  set itemsContainer(StandardItemsContainer value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItemsContainer() => $_has(1);
  @$pb.TagNumber(2)
  void clearItemsContainer() => $_clearField(2);
  @$pb.TagNumber(2)
  StandardItemsContainer ensureItemsContainer() => $_ensure(1);
}

class SectionHeader extends $pb.GeneratedMessage {
  factory SectionHeader({
    SectionTitleWrapper? titleWrapper,
    SectionTemplateWrapper? templateWrapper,
  }) {
    final result = SectionHeader._();
    if (titleWrapper != null) result.titleWrapper = titleWrapper;
    if (templateWrapper != null) result.templateWrapper = templateWrapper;
    return result;
  }

  SectionHeader._();

  factory SectionHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionHeader()..mergeFromBuffer(data, registry);
  factory SectionHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionHeader()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SectionHeader',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: SectionHeader.$_createMessage)
    ..aOM<SectionTitleWrapper>(2, _omitFieldNames ? '' : 'titleWrapper',
        subBuilder: SectionTitleWrapper.$_createMessage)
    ..aOM<SectionTemplateWrapper>(3, _omitFieldNames ? '' : 'templateWrapper',
        subBuilder: SectionTemplateWrapper.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionHeader copyWith(void Function(SectionHeader) updates) =>
      super.copyWith((message) => updates(message as SectionHeader))
          as SectionHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SectionHeader() / SectionHeader.new instead')
  static SectionHeader create() => SectionHeader._();
  static $pb.GeneratedMessage $_createMessage() => SectionHeader._();
  @$core.override
  SectionHeader createEmptyInstance() => SectionHeader._();
  @$core.pragma('dart2js:noInline')
  static SectionHeader getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SectionHeader>(
          SectionHeader.$_createMessage);
  static SectionHeader? _defaultInstance;

  @$pb.TagNumber(2)
  SectionTitleWrapper get titleWrapper => $_getN(0);
  @$pb.TagNumber(2)
  set titleWrapper(SectionTitleWrapper value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTitleWrapper() => $_has(0);
  @$pb.TagNumber(2)
  void clearTitleWrapper() => $_clearField(2);
  @$pb.TagNumber(2)
  SectionTitleWrapper ensureTitleWrapper() => $_ensure(0);

  @$pb.TagNumber(3)
  SectionTemplateWrapper get templateWrapper => $_getN(1);
  @$pb.TagNumber(3)
  set templateWrapper(SectionTemplateWrapper value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTemplateWrapper() => $_has(1);
  @$pb.TagNumber(3)
  void clearTemplateWrapper() => $_clearField(3);
  @$pb.TagNumber(3)
  SectionTemplateWrapper ensureTemplateWrapper() => $_ensure(1);
}

class SectionTitleWrapper extends $pb.GeneratedMessage {
  factory SectionTitleWrapper({
    $core.String? title,
  }) {
    final result = SectionTitleWrapper._();
    if (title != null) result.title = title;
    return result;
  }

  SectionTitleWrapper._();

  factory SectionTitleWrapper.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionTitleWrapper()..mergeFromBuffer(data, registry);
  factory SectionTitleWrapper.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionTitleWrapper()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SectionTitleWrapper',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: SectionTitleWrapper.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionTitleWrapper clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionTitleWrapper copyWith(void Function(SectionTitleWrapper) updates) =>
      super.copyWith((message) => updates(message as SectionTitleWrapper))
          as SectionTitleWrapper;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SectionTitleWrapper() / SectionTitleWrapper.new instead')
  static SectionTitleWrapper create() => SectionTitleWrapper._();
  static $pb.GeneratedMessage $_createMessage() => SectionTitleWrapper._();
  @$core.override
  SectionTitleWrapper createEmptyInstance() => SectionTitleWrapper._();
  @$core.pragma('dart2js:noInline')
  static SectionTitleWrapper getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SectionTitleWrapper>(
          SectionTitleWrapper.$_createMessage);
  static SectionTitleWrapper? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);
}

class SectionTemplateWrapper extends $pb.GeneratedMessage {
  factory SectionTemplateWrapper({
    $core.String? template,
    SectionTemplateParams? params,
  }) {
    final result = SectionTemplateWrapper._();
    if (template != null) result.template = template;
    if (params != null) result.params = params;
    return result;
  }

  SectionTemplateWrapper._();

  factory SectionTemplateWrapper.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionTemplateWrapper()..mergeFromBuffer(data, registry);
  factory SectionTemplateWrapper.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionTemplateWrapper()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SectionTemplateWrapper',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: SectionTemplateWrapper.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'template')
    ..aOM<SectionTemplateParams>(2, _omitFieldNames ? '' : 'params',
        subBuilder: SectionTemplateParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionTemplateWrapper clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionTemplateWrapper copyWith(
          void Function(SectionTemplateWrapper) updates) =>
      super.copyWith((message) => updates(message as SectionTemplateWrapper))
          as SectionTemplateWrapper;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SectionTemplateWrapper() / SectionTemplateWrapper.new instead')
  static SectionTemplateWrapper create() => SectionTemplateWrapper._();
  static $pb.GeneratedMessage $_createMessage() => SectionTemplateWrapper._();
  @$core.override
  SectionTemplateWrapper createEmptyInstance() => SectionTemplateWrapper._();
  @$core.pragma('dart2js:noInline')
  static SectionTemplateWrapper getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SectionTemplateWrapper>(
          SectionTemplateWrapper.$_createMessage);
  static SectionTemplateWrapper? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get template => $_getSZ(0);
  @$pb.TagNumber(1)
  set template($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTemplate() => $_has(0);
  @$pb.TagNumber(1)
  void clearTemplate() => $_clearField(1);

  @$pb.TagNumber(2)
  SectionTemplateParams get params => $_getN(1);
  @$pb.TagNumber(2)
  set params(SectionTemplateParams value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasParams() => $_has(1);
  @$pb.TagNumber(2)
  void clearParams() => $_clearField(2);
  @$pb.TagNumber(2)
  SectionTemplateParams ensureParams() => $_ensure(1);
}

class SectionTemplateParams extends $pb.GeneratedMessage {
  factory SectionTemplateParams({
    $core.String? artistName,
  }) {
    final result = SectionTemplateParams._();
    if (artistName != null) result.artistName = artistName;
    return result;
  }

  SectionTemplateParams._();

  factory SectionTemplateParams.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionTemplateParams()..mergeFromBuffer(data, registry);
  factory SectionTemplateParams.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionTemplateParams()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SectionTemplateParams',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: SectionTemplateParams.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'artistName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionTemplateParams clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionTemplateParams copyWith(
          void Function(SectionTemplateParams) updates) =>
      super.copyWith((message) => updates(message as SectionTemplateParams))
          as SectionTemplateParams;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SectionTemplateParams() / SectionTemplateParams.new instead')
  static SectionTemplateParams create() => SectionTemplateParams._();
  static $pb.GeneratedMessage $_createMessage() => SectionTemplateParams._();
  @$core.override
  SectionTemplateParams createEmptyInstance() => SectionTemplateParams._();
  @$core.pragma('dart2js:noInline')
  static SectionTemplateParams getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SectionTemplateParams>(
          SectionTemplateParams.$_createMessage);
  static SectionTemplateParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get artistName => $_getSZ(0);
  @$pb.TagNumber(1)
  set artistName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasArtistName() => $_has(0);
  @$pb.TagNumber(1)
  void clearArtistName() => $_clearField(1);
}

class StandardItemsContainer extends $pb.GeneratedMessage {
  factory StandardItemsContainer({
    $core.Iterable<SectionItemWrapper>? itemsWrapper,
  }) {
    final result = StandardItemsContainer._();
    if (itemsWrapper != null) result.itemsWrapper.addAll(itemsWrapper);
    return result;
  }

  StandardItemsContainer._();

  factory StandardItemsContainer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StandardItemsContainer()..mergeFromBuffer(data, registry);
  factory StandardItemsContainer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StandardItemsContainer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StandardItemsContainer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: StandardItemsContainer.$_createMessage)
    ..pPM<SectionItemWrapper>(1, _omitFieldNames ? '' : 'itemsWrapper',
        subBuilder: SectionItemWrapper.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StandardItemsContainer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StandardItemsContainer copyWith(
          void Function(StandardItemsContainer) updates) =>
      super.copyWith((message) => updates(message as StandardItemsContainer))
          as StandardItemsContainer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use StandardItemsContainer() / StandardItemsContainer.new instead')
  static StandardItemsContainer create() => StandardItemsContainer._();
  static $pb.GeneratedMessage $_createMessage() => StandardItemsContainer._();
  @$core.override
  StandardItemsContainer createEmptyInstance() => StandardItemsContainer._();
  @$core.pragma('dart2js:noInline')
  static StandardItemsContainer getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StandardItemsContainer>(
          StandardItemsContainer.$_createMessage);
  static StandardItemsContainer? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SectionItemWrapper> get itemsWrapper => $_getList(0);
}

class SectionItemWrapper extends $pb.GeneratedMessage {
  factory SectionItemWrapper({
    SectionItem? item,
  }) {
    final result = SectionItemWrapper._();
    if (item != null) result.item = item;
    return result;
  }

  SectionItemWrapper._();

  factory SectionItemWrapper.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionItemWrapper()..mergeFromBuffer(data, registry);
  factory SectionItemWrapper.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionItemWrapper()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SectionItemWrapper',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: SectionItemWrapper.$_createMessage)
    ..aOM<SectionItem>(1, _omitFieldNames ? '' : 'item',
        subBuilder: SectionItem.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionItemWrapper clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionItemWrapper copyWith(void Function(SectionItemWrapper) updates) =>
      super.copyWith((message) => updates(message as SectionItemWrapper))
          as SectionItemWrapper;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SectionItemWrapper() / SectionItemWrapper.new instead')
  static SectionItemWrapper create() => SectionItemWrapper._();
  static $pb.GeneratedMessage $_createMessage() => SectionItemWrapper._();
  @$core.override
  SectionItemWrapper createEmptyInstance() => SectionItemWrapper._();
  @$core.pragma('dart2js:noInline')
  static SectionItemWrapper getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SectionItemWrapper>(
          SectionItemWrapper.$_createMessage);
  static SectionItemWrapper? _defaultInstance;

  @$pb.TagNumber(1)
  SectionItem get item => $_getN(0);
  @$pb.TagNumber(1)
  set item(SectionItem value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasItem() => $_has(0);
  @$pb.TagNumber(1)
  void clearItem() => $_clearField(1);
  @$pb.TagNumber(1)
  SectionItem ensureItem() => $_ensure(0);
}

class SectionItem extends $pb.GeneratedMessage {
  factory SectionItem({
    $core.String? uri,
  }) {
    final result = SectionItem._();
    if (uri != null) result.uri = uri;
    return result;
  }

  SectionItem._();

  factory SectionItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionItem()..mergeFromBuffer(data, registry);
  factory SectionItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SectionItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: SectionItem.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionItem copyWith(void Function(SectionItem) updates) =>
      super.copyWith((message) => updates(message as SectionItem))
          as SectionItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SectionItem() / SectionItem.new instead')
  static SectionItem create() => SectionItem._();
  static $pb.GeneratedMessage $_createMessage() => SectionItem._();
  @$core.override
  SectionItem createEmptyInstance() => SectionItem._();
  @$core.pragma('dart2js:noInline')
  static SectionItem getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SectionItem>(
          SectionItem.$_createMessage);
  static SectionItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearUri() => $_clearField(1);
}

class SectionBodyPodcast extends $pb.GeneratedMessage {
  factory SectionBodyPodcast({
    SectionHeader? header,
    PodcastItemsContainer? itemsContainer,
  }) {
    final result = SectionBodyPodcast._();
    if (header != null) result.header = header;
    if (itemsContainer != null) result.itemsContainer = itemsContainer;
    return result;
  }

  SectionBodyPodcast._();

  factory SectionBodyPodcast.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionBodyPodcast()..mergeFromBuffer(data, registry);
  factory SectionBodyPodcast.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionBodyPodcast()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SectionBodyPodcast',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: SectionBodyPodcast.$_createMessage)
    ..aOM<SectionHeader>(1, _omitFieldNames ? '' : 'header',
        subBuilder: SectionHeader.$_createMessage)
    ..aOM<PodcastItemsContainer>(2, _omitFieldNames ? '' : 'itemsContainer',
        subBuilder: PodcastItemsContainer.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionBodyPodcast clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionBodyPodcast copyWith(void Function(SectionBodyPodcast) updates) =>
      super.copyWith((message) => updates(message as SectionBodyPodcast))
          as SectionBodyPodcast;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SectionBodyPodcast() / SectionBodyPodcast.new instead')
  static SectionBodyPodcast create() => SectionBodyPodcast._();
  static $pb.GeneratedMessage $_createMessage() => SectionBodyPodcast._();
  @$core.override
  SectionBodyPodcast createEmptyInstance() => SectionBodyPodcast._();
  @$core.pragma('dart2js:noInline')
  static SectionBodyPodcast getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SectionBodyPodcast>(
          SectionBodyPodcast.$_createMessage);
  static SectionBodyPodcast? _defaultInstance;

  @$pb.TagNumber(1)
  SectionHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(SectionHeader value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  SectionHeader ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  PodcastItemsContainer get itemsContainer => $_getN(1);
  @$pb.TagNumber(2)
  set itemsContainer(PodcastItemsContainer value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItemsContainer() => $_has(1);
  @$pb.TagNumber(2)
  void clearItemsContainer() => $_clearField(2);
  @$pb.TagNumber(2)
  PodcastItemsContainer ensureItemsContainer() => $_ensure(1);
}

class PodcastItemsContainer extends $pb.GeneratedMessage {
  factory PodcastItemsContainer({
    $core.String? showUri,
    $core.String? episodeUri,
  }) {
    final result = PodcastItemsContainer._();
    if (showUri != null) result.showUri = showUri;
    if (episodeUri != null) result.episodeUri = episodeUri;
    return result;
  }

  PodcastItemsContainer._();

  factory PodcastItemsContainer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PodcastItemsContainer()..mergeFromBuffer(data, registry);
  factory PodcastItemsContainer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PodcastItemsContainer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PodcastItemsContainer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: PodcastItemsContainer.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'showUri')
    ..aOS(2, _omitFieldNames ? '' : 'episodeUri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PodcastItemsContainer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PodcastItemsContainer copyWith(
          void Function(PodcastItemsContainer) updates) =>
      super.copyWith((message) => updates(message as PodcastItemsContainer))
          as PodcastItemsContainer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PodcastItemsContainer() / PodcastItemsContainer.new instead')
  static PodcastItemsContainer create() => PodcastItemsContainer._();
  static $pb.GeneratedMessage $_createMessage() => PodcastItemsContainer._();
  @$core.override
  PodcastItemsContainer createEmptyInstance() => PodcastItemsContainer._();
  @$core.pragma('dart2js:noInline')
  static PodcastItemsContainer getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PodcastItemsContainer>(
          PodcastItemsContainer.$_createMessage);
  static PodcastItemsContainer? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get showUri => $_getSZ(0);
  @$pb.TagNumber(1)
  set showUri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasShowUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearShowUri() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get episodeUri => $_getSZ(1);
  @$pb.TagNumber(2)
  set episodeUri($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEpisodeUri() => $_has(1);
  @$pb.TagNumber(2)
  void clearEpisodeUri() => $_clearField(2);
}

class SectionBodyMusicfeed extends $pb.GeneratedMessage {
  factory SectionBodyMusicfeed({
    SectionHeader? header,
    MusicfeedItemsContainer? itemsContainer,
  }) {
    final result = SectionBodyMusicfeed._();
    if (header != null) result.header = header;
    if (itemsContainer != null) result.itemsContainer = itemsContainer;
    return result;
  }

  SectionBodyMusicfeed._();

  factory SectionBodyMusicfeed.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionBodyMusicfeed()..mergeFromBuffer(data, registry);
  factory SectionBodyMusicfeed.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionBodyMusicfeed()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SectionBodyMusicfeed',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: SectionBodyMusicfeed.$_createMessage)
    ..aOM<SectionHeader>(1, _omitFieldNames ? '' : 'header',
        subBuilder: SectionHeader.$_createMessage)
    ..aOM<MusicfeedItemsContainer>(2, _omitFieldNames ? '' : 'itemsContainer',
        subBuilder: MusicfeedItemsContainer.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionBodyMusicfeed clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionBodyMusicfeed copyWith(void Function(SectionBodyMusicfeed) updates) =>
      super.copyWith((message) => updates(message as SectionBodyMusicfeed))
          as SectionBodyMusicfeed;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SectionBodyMusicfeed() / SectionBodyMusicfeed.new instead')
  static SectionBodyMusicfeed create() => SectionBodyMusicfeed._();
  static $pb.GeneratedMessage $_createMessage() => SectionBodyMusicfeed._();
  @$core.override
  SectionBodyMusicfeed createEmptyInstance() => SectionBodyMusicfeed._();
  @$core.pragma('dart2js:noInline')
  static SectionBodyMusicfeed getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SectionBodyMusicfeed>(
          SectionBodyMusicfeed.$_createMessage);
  static SectionBodyMusicfeed? _defaultInstance;

  @$pb.TagNumber(1)
  SectionHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(SectionHeader value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  SectionHeader ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  MusicfeedItemsContainer get itemsContainer => $_getN(1);
  @$pb.TagNumber(2)
  set itemsContainer(MusicfeedItemsContainer value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItemsContainer() => $_has(1);
  @$pb.TagNumber(2)
  void clearItemsContainer() => $_clearField(2);
  @$pb.TagNumber(2)
  MusicfeedItemsContainer ensureItemsContainer() => $_ensure(1);
}

class MusicfeedItemsContainer extends $pb.GeneratedMessage {
  factory MusicfeedItemsContainer({
    $core.String? playlistUri,
  }) {
    final result = MusicfeedItemsContainer._();
    if (playlistUri != null) result.playlistUri = playlistUri;
    return result;
  }

  MusicfeedItemsContainer._();

  factory MusicfeedItemsContainer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MusicfeedItemsContainer()..mergeFromBuffer(data, registry);
  factory MusicfeedItemsContainer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MusicfeedItemsContainer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MusicfeedItemsContainer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: MusicfeedItemsContainer.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'playlistUri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MusicfeedItemsContainer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MusicfeedItemsContainer copyWith(
          void Function(MusicfeedItemsContainer) updates) =>
      super.copyWith((message) => updates(message as MusicfeedItemsContainer))
          as MusicfeedItemsContainer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use MusicfeedItemsContainer() / MusicfeedItemsContainer.new instead')
  static MusicfeedItemsContainer create() => MusicfeedItemsContainer._();
  static $pb.GeneratedMessage $_createMessage() => MusicfeedItemsContainer._();
  @$core.override
  MusicfeedItemsContainer createEmptyInstance() => MusicfeedItemsContainer._();
  @$core.pragma('dart2js:noInline')
  static MusicfeedItemsContainer getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MusicfeedItemsContainer>(
          MusicfeedItemsContainer.$_createMessage);
  static MusicfeedItemsContainer? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playlistUri => $_getSZ(0);
  @$pb.TagNumber(1)
  set playlistUri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlaylistUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlaylistUri() => $_clearField(1);
}

class SectionBodyRecents extends $pb.GeneratedMessage {
  factory SectionBodyRecents({
    SectionHeader? header,
  }) {
    final result = SectionBodyRecents._();
    if (header != null) result.header = header;
    return result;
  }

  SectionBodyRecents._();

  factory SectionBodyRecents.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionBodyRecents()..mergeFromBuffer(data, registry);
  factory SectionBodyRecents.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionBodyRecents()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SectionBodyRecents',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: SectionBodyRecents.$_createMessage)
    ..aOM<SectionHeader>(1, _omitFieldNames ? '' : 'header',
        subBuilder: SectionHeader.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionBodyRecents clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionBodyRecents copyWith(void Function(SectionBodyRecents) updates) =>
      super.copyWith((message) => updates(message as SectionBodyRecents))
          as SectionBodyRecents;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SectionBodyRecents() / SectionBodyRecents.new instead')
  static SectionBodyRecents create() => SectionBodyRecents._();
  static $pb.GeneratedMessage $_createMessage() => SectionBodyRecents._();
  @$core.override
  SectionBodyRecents createEmptyInstance() => SectionBodyRecents._();
  @$core.pragma('dart2js:noInline')
  static SectionBodyRecents getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SectionBodyRecents>(
          SectionBodyRecents.$_createMessage);
  static SectionBodyRecents? _defaultInstance;

  @$pb.TagNumber(1)
  SectionHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(SectionHeader value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  SectionHeader ensureHeader() => $_ensure(0);
}

class CasitaRepository extends $pb.GeneratedMessage {
  factory CasitaRepository({
    CasitaRepositoryInner? inner,
  }) {
    final result = CasitaRepository._();
    if (inner != null) result.inner = inner;
    return result;
  }

  CasitaRepository._();

  factory CasitaRepository.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaRepository()..mergeFromBuffer(data, registry);
  factory CasitaRepository.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaRepository()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CasitaRepository',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: CasitaRepository.$_createMessage)
    ..aOM<CasitaRepositoryInner>(1, _omitFieldNames ? '' : 'inner',
        subBuilder: CasitaRepositoryInner.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaRepository clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaRepository copyWith(void Function(CasitaRepository) updates) =>
      super.copyWith((message) => updates(message as CasitaRepository))
          as CasitaRepository;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CasitaRepository() / CasitaRepository.new instead')
  static CasitaRepository create() => CasitaRepository._();
  static $pb.GeneratedMessage $_createMessage() => CasitaRepository._();
  @$core.override
  CasitaRepository createEmptyInstance() => CasitaRepository._();
  @$core.pragma('dart2js:noInline')
  static CasitaRepository getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CasitaRepository>(
          CasitaRepository.$_createMessage);
  static CasitaRepository? _defaultInstance;

  @$pb.TagNumber(1)
  CasitaRepositoryInner get inner => $_getN(0);
  @$pb.TagNumber(1)
  set inner(CasitaRepositoryInner value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasInner() => $_has(0);
  @$pb.TagNumber(1)
  void clearInner() => $_clearField(1);
  @$pb.TagNumber(1)
  CasitaRepositoryInner ensureInner() => $_ensure(0);
}

class CasitaRepositoryInner extends $pb.GeneratedMessage {
  factory CasitaRepositoryInner({
    $core.Iterable<CasitaRepositoryBlock>? blocks,
  }) {
    final result = CasitaRepositoryInner._();
    if (blocks != null) result.blocks.addAll(blocks);
    return result;
  }

  CasitaRepositoryInner._();

  factory CasitaRepositoryInner.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaRepositoryInner()..mergeFromBuffer(data, registry);
  factory CasitaRepositoryInner.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaRepositoryInner()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CasitaRepositoryInner',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: CasitaRepositoryInner.$_createMessage)
    ..pPM<CasitaRepositoryBlock>(2, _omitFieldNames ? '' : 'blocks',
        subBuilder: CasitaRepositoryBlock.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaRepositoryInner clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaRepositoryInner copyWith(
          void Function(CasitaRepositoryInner) updates) =>
      super.copyWith((message) => updates(message as CasitaRepositoryInner))
          as CasitaRepositoryInner;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CasitaRepositoryInner() / CasitaRepositoryInner.new instead')
  static CasitaRepositoryInner create() => CasitaRepositoryInner._();
  static $pb.GeneratedMessage $_createMessage() => CasitaRepositoryInner._();
  @$core.override
  CasitaRepositoryInner createEmptyInstance() => CasitaRepositoryInner._();
  @$core.pragma('dart2js:noInline')
  static CasitaRepositoryInner getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CasitaRepositoryInner>(
          CasitaRepositoryInner.$_createMessage);
  static CasitaRepositoryInner? _defaultInstance;

  @$pb.TagNumber(2)
  $pb.PbList<CasitaRepositoryBlock> get blocks => $_getList(0);
}

class CasitaRepositoryBlock extends $pb.GeneratedMessage {
  factory CasitaRepositoryBlock({
    $core.Iterable<CasitaRepositoryEntry>? entries,
  }) {
    final result = CasitaRepositoryBlock._();
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  CasitaRepositoryBlock._();

  factory CasitaRepositoryBlock.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaRepositoryBlock()..mergeFromBuffer(data, registry);
  factory CasitaRepositoryBlock.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaRepositoryBlock()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CasitaRepositoryBlock',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: CasitaRepositoryBlock.$_createMessage)
    ..pPM<CasitaRepositoryEntry>(3, _omitFieldNames ? '' : 'entries',
        subBuilder: CasitaRepositoryEntry.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaRepositoryBlock clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaRepositoryBlock copyWith(
          void Function(CasitaRepositoryBlock) updates) =>
      super.copyWith((message) => updates(message as CasitaRepositoryBlock))
          as CasitaRepositoryBlock;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CasitaRepositoryBlock() / CasitaRepositoryBlock.new instead')
  static CasitaRepositoryBlock create() => CasitaRepositoryBlock._();
  static $pb.GeneratedMessage $_createMessage() => CasitaRepositoryBlock._();
  @$core.override
  CasitaRepositoryBlock createEmptyInstance() => CasitaRepositoryBlock._();
  @$core.pragma('dart2js:noInline')
  static CasitaRepositoryBlock getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CasitaRepositoryBlock>(
          CasitaRepositoryBlock.$_createMessage);
  static CasitaRepositoryBlock? _defaultInstance;

  @$pb.TagNumber(3)
  $pb.PbList<CasitaRepositoryEntry> get entries => $_getList(0);
}

class CasitaRepositoryEntry extends $pb.GeneratedMessage {
  factory CasitaRepositoryEntry({
    $core.String? uri,
    $0.Any? traitPayload,
  }) {
    final result = CasitaRepositoryEntry._();
    if (uri != null) result.uri = uri;
    if (traitPayload != null) result.traitPayload = traitPayload;
    return result;
  }

  CasitaRepositoryEntry._();

  factory CasitaRepositoryEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaRepositoryEntry()..mergeFromBuffer(data, registry);
  factory CasitaRepositoryEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaRepositoryEntry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CasitaRepositoryEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: CasitaRepositoryEntry.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'uri')
    ..aOM<$0.Any>(3, _omitFieldNames ? '' : 'traitPayload',
        subBuilder: $0.Any.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaRepositoryEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaRepositoryEntry copyWith(
          void Function(CasitaRepositoryEntry) updates) =>
      super.copyWith((message) => updates(message as CasitaRepositoryEntry))
          as CasitaRepositoryEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CasitaRepositoryEntry() / CasitaRepositoryEntry.new instead')
  static CasitaRepositoryEntry create() => CasitaRepositoryEntry._();
  static $pb.GeneratedMessage $_createMessage() => CasitaRepositoryEntry._();
  @$core.override
  CasitaRepositoryEntry createEmptyInstance() => CasitaRepositoryEntry._();
  @$core.pragma('dart2js:noInline')
  static CasitaRepositoryEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CasitaRepositoryEntry>(
          CasitaRepositoryEntry.$_createMessage);
  static CasitaRepositoryEntry? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(2)
  set uri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasUri() => $_has(0);
  @$pb.TagNumber(2)
  void clearUri() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Any get traitPayload => $_getN(1);
  @$pb.TagNumber(3)
  set traitPayload($0.Any value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTraitPayload() => $_has(1);
  @$pb.TagNumber(3)
  void clearTraitPayload() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Any ensureTraitPayload() => $_ensure(1);
}

class SimpleCardTrait extends $pb.GeneratedMessage {
  factory SimpleCardTrait({
    $core.String? imageUrl,
    $core.String? title,
    $core.String? subtitle,
    $core.String? titleRendered,
  }) {
    final result = SimpleCardTrait._();
    if (imageUrl != null) result.imageUrl = imageUrl;
    if (title != null) result.title = title;
    if (subtitle != null) result.subtitle = subtitle;
    if (titleRendered != null) result.titleRendered = titleRendered;
    return result;
  }

  SimpleCardTrait._();

  factory SimpleCardTrait.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SimpleCardTrait()..mergeFromBuffer(data, registry);
  factory SimpleCardTrait.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SimpleCardTrait()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SimpleCardTrait',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: SimpleCardTrait.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'imageUrl')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'subtitle')
    ..aOS(6, _omitFieldNames ? '' : 'titleRendered')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SimpleCardTrait clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SimpleCardTrait copyWith(void Function(SimpleCardTrait) updates) =>
      super.copyWith((message) => updates(message as SimpleCardTrait))
          as SimpleCardTrait;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SimpleCardTrait() / SimpleCardTrait.new instead')
  static SimpleCardTrait create() => SimpleCardTrait._();
  static $pb.GeneratedMessage $_createMessage() => SimpleCardTrait._();
  @$core.override
  SimpleCardTrait createEmptyInstance() => SimpleCardTrait._();
  @$core.pragma('dart2js:noInline')
  static SimpleCardTrait getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SimpleCardTrait>(
          SimpleCardTrait.$_createMessage);
  static SimpleCardTrait? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get imageUrl => $_getSZ(0);
  @$pb.TagNumber(1)
  set imageUrl($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasImageUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearImageUrl() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get subtitle => $_getSZ(2);
  @$pb.TagNumber(3)
  set subtitle($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSubtitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearSubtitle() => $_clearField(3);

  @$pb.TagNumber(6)
  $core.String get titleRendered => $_getSZ(3);
  @$pb.TagNumber(6)
  set titleRendered($core.String value) => $_setString(3, value);
  @$pb.TagNumber(6)
  $core.bool hasTitleRendered() => $_has(3);
  @$pb.TagNumber(6)
  void clearTitleRendered() => $_clearField(6);
}

class ShortcutsCardTrait extends $pb.GeneratedMessage {
  factory ShortcutsCardTrait({
    $core.String? imageUrl,
    $core.String? title,
    $core.String? contextUri,
  }) {
    final result = ShortcutsCardTrait._();
    if (imageUrl != null) result.imageUrl = imageUrl;
    if (title != null) result.title = title;
    if (contextUri != null) result.contextUri = contextUri;
    return result;
  }

  ShortcutsCardTrait._();

  factory ShortcutsCardTrait.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ShortcutsCardTrait()..mergeFromBuffer(data, registry);
  factory ShortcutsCardTrait.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ShortcutsCardTrait()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShortcutsCardTrait',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: ShortcutsCardTrait.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'imageUrl')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'contextUri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShortcutsCardTrait clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShortcutsCardTrait copyWith(void Function(ShortcutsCardTrait) updates) =>
      super.copyWith((message) => updates(message as ShortcutsCardTrait))
          as ShortcutsCardTrait;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ShortcutsCardTrait() / ShortcutsCardTrait.new instead')
  static ShortcutsCardTrait create() => ShortcutsCardTrait._();
  static $pb.GeneratedMessage $_createMessage() => ShortcutsCardTrait._();
  @$core.override
  ShortcutsCardTrait createEmptyInstance() => ShortcutsCardTrait._();
  @$core.pragma('dart2js:noInline')
  static ShortcutsCardTrait getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ShortcutsCardTrait>(
          ShortcutsCardTrait.$_createMessage);
  static ShortcutsCardTrait? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get imageUrl => $_getSZ(0);
  @$pb.TagNumber(1)
  set imageUrl($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasImageUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearImageUrl() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get contextUri => $_getSZ(2);
  @$pb.TagNumber(3)
  set contextUri($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContextUri() => $_has(2);
  @$pb.TagNumber(3)
  void clearContextUri() => $_clearField(3);
}

class PreviewCardTrait extends $pb.GeneratedMessage {
  factory PreviewCardTrait({
    $core.String? title,
    $core.String? author,
    $core.String? imageUrl,
  }) {
    final result = PreviewCardTrait._();
    if (title != null) result.title = title;
    if (author != null) result.author = author;
    if (imageUrl != null) result.imageUrl = imageUrl;
    return result;
  }

  PreviewCardTrait._();

  factory PreviewCardTrait.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewCardTrait()..mergeFromBuffer(data, registry);
  factory PreviewCardTrait.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewCardTrait()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewCardTrait',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: PreviewCardTrait.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'author')
    ..aOS(8, _omitFieldNames ? '' : 'imageUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewCardTrait clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewCardTrait copyWith(void Function(PreviewCardTrait) updates) =>
      super.copyWith((message) => updates(message as PreviewCardTrait))
          as PreviewCardTrait;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PreviewCardTrait() / PreviewCardTrait.new instead')
  static PreviewCardTrait create() => PreviewCardTrait._();
  static $pb.GeneratedMessage $_createMessage() => PreviewCardTrait._();
  @$core.override
  PreviewCardTrait createEmptyInstance() => PreviewCardTrait._();
  @$core.pragma('dart2js:noInline')
  static PreviewCardTrait getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PreviewCardTrait>(
          PreviewCardTrait.$_createMessage);
  static PreviewCardTrait? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  @$pb.TagNumber(3)
  $core.String get author => $_getSZ(1);
  @$pb.TagNumber(3)
  set author($core.String value) => $_setString(1, value);
  @$pb.TagNumber(3)
  $core.bool hasAuthor() => $_has(1);
  @$pb.TagNumber(3)
  void clearAuthor() => $_clearField(3);

  @$pb.TagNumber(8)
  $core.String get imageUrl => $_getSZ(2);
  @$pb.TagNumber(8)
  set imageUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(8)
  $core.bool hasImageUrl() => $_has(2);
  @$pb.TagNumber(8)
  void clearImageUrl() => $_clearField(8);
}

class CasitaPageMeta extends $pb.GeneratedMessage {
  factory CasitaPageMeta({
    $core.String? uri,
    $core.String? pageId,
  }) {
    final result = CasitaPageMeta._();
    if (uri != null) result.uri = uri;
    if (pageId != null) result.pageId = pageId;
    return result;
  }

  CasitaPageMeta._();

  factory CasitaPageMeta.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaPageMeta()..mergeFromBuffer(data, registry);
  factory CasitaPageMeta.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaPageMeta()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CasitaPageMeta',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: CasitaPageMeta.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
    ..aOS(2, _omitFieldNames ? '' : 'pageId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaPageMeta clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaPageMeta copyWith(void Function(CasitaPageMeta) updates) =>
      super.copyWith((message) => updates(message as CasitaPageMeta))
          as CasitaPageMeta;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CasitaPageMeta() / CasitaPageMeta.new instead')
  static CasitaPageMeta create() => CasitaPageMeta._();
  static $pb.GeneratedMessage $_createMessage() => CasitaPageMeta._();
  @$core.override
  CasitaPageMeta createEmptyInstance() => CasitaPageMeta._();
  @$core.pragma('dart2js:noInline')
  static CasitaPageMeta getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CasitaPageMeta>(
          CasitaPageMeta.$_createMessage);
  static CasitaPageMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearUri() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get pageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set pageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageId() => $_clearField(2);
}

class CasitaMixUri extends $pb.GeneratedMessage {
  factory CasitaMixUri({
    $core.String? uri,
  }) {
    final result = CasitaMixUri._();
    if (uri != null) result.uri = uri;
    return result;
  }

  CasitaMixUri._();

  factory CasitaMixUri.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaMixUri()..mergeFromBuffer(data, registry);
  factory CasitaMixUri.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CasitaMixUri()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CasitaMixUri',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'spotify.casita'),
      createEmptyInstance: CasitaMixUri.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaMixUri clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CasitaMixUri copyWith(void Function(CasitaMixUri) updates) =>
      super.copyWith((message) => updates(message as CasitaMixUri))
          as CasitaMixUri;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CasitaMixUri() / CasitaMixUri.new instead')
  static CasitaMixUri create() => CasitaMixUri._();
  static $pb.GeneratedMessage $_createMessage() => CasitaMixUri._();
  @$core.override
  CasitaMixUri createEmptyInstance() => CasitaMixUri._();
  @$core.pragma('dart2js:noInline')
  static CasitaMixUri getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CasitaMixUri>(
          CasitaMixUri.$_createMessage);
  static CasitaMixUri? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearUri() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
