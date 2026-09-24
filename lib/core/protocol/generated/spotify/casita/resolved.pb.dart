// This is a generated file - do not edit.
//
// Generated from spotify/casita/resolved.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../extended_metadata.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ResolvedHome extends $pb.GeneratedMessage {
  factory ResolvedHome({
    HomeStructure? structure,
    EagerlyLoadedTraits? eagerlyLoadedTraits,
    ResponseInfo? responseInfo,
    DebugInfo? debugInfo,
    SandboxDebugInfo? sandboxDebugInfo,
    OndemandSet? ondemandSet,
  }) {
    final result = ResolvedHome._();
    if (structure != null) result.structure = structure;
    if (eagerlyLoadedTraits != null)
      result.eagerlyLoadedTraits = eagerlyLoadedTraits;
    if (responseInfo != null) result.responseInfo = responseInfo;
    if (debugInfo != null) result.debugInfo = debugInfo;
    if (sandboxDebugInfo != null) result.sandboxDebugInfo = sandboxDebugInfo;
    if (ondemandSet != null) result.ondemandSet = ondemandSet;
    return result;
  }

  ResolvedHome._();

  factory ResolvedHome.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResolvedHome()..mergeFromBuffer(data, registry);
  factory ResolvedHome.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResolvedHome()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResolvedHome',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: ResolvedHome.$_createMessage)
    ..aOM<HomeStructure>(1, _omitFieldNames ? '' : 'structure',
        subBuilder: HomeStructure.$_createMessage)
    ..aOM<EagerlyLoadedTraits>(2, _omitFieldNames ? '' : 'eagerlyLoadedTraits',
        subBuilder: EagerlyLoadedTraits.$_createMessage)
    ..aOM<ResponseInfo>(3, _omitFieldNames ? '' : 'responseInfo',
        subBuilder: ResponseInfo.$_createMessage)
    ..aOM<DebugInfo>(4, _omitFieldNames ? '' : 'debugInfo',
        subBuilder: DebugInfo.$_createMessage)
    ..aOM<SandboxDebugInfo>(5, _omitFieldNames ? '' : 'sandboxDebugInfo',
        subBuilder: SandboxDebugInfo.$_createMessage)
    ..aOM<OndemandSet>(999, _omitFieldNames ? '' : 'ondemandSet',
        subBuilder: OndemandSet.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolvedHome clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolvedHome copyWith(void Function(ResolvedHome) updates) =>
      super.copyWith((message) => updates(message as ResolvedHome))
          as ResolvedHome;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResolvedHome() / ResolvedHome.new instead')
  static ResolvedHome create() => ResolvedHome._();
  static $pb.GeneratedMessage $_createMessage() => ResolvedHome._();
  @$core.override
  ResolvedHome createEmptyInstance() => ResolvedHome._();
  @$core.pragma('dart2js:noInline')
  static ResolvedHome getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedHome>(
          ResolvedHome.$_createMessage);
  static ResolvedHome? _defaultInstance;

  @$pb.TagNumber(1)
  HomeStructure get structure => $_getN(0);
  @$pb.TagNumber(1)
  set structure(HomeStructure value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStructure() => $_has(0);
  @$pb.TagNumber(1)
  void clearStructure() => $_clearField(1);
  @$pb.TagNumber(1)
  HomeStructure ensureStructure() => $_ensure(0);

  @$pb.TagNumber(2)
  EagerlyLoadedTraits get eagerlyLoadedTraits => $_getN(1);
  @$pb.TagNumber(2)
  set eagerlyLoadedTraits(EagerlyLoadedTraits value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasEagerlyLoadedTraits() => $_has(1);
  @$pb.TagNumber(2)
  void clearEagerlyLoadedTraits() => $_clearField(2);
  @$pb.TagNumber(2)
  EagerlyLoadedTraits ensureEagerlyLoadedTraits() => $_ensure(1);

  @$pb.TagNumber(3)
  ResponseInfo get responseInfo => $_getN(2);
  @$pb.TagNumber(3)
  set responseInfo(ResponseInfo value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasResponseInfo() => $_has(2);
  @$pb.TagNumber(3)
  void clearResponseInfo() => $_clearField(3);
  @$pb.TagNumber(3)
  ResponseInfo ensureResponseInfo() => $_ensure(2);

  @$pb.TagNumber(4)
  DebugInfo get debugInfo => $_getN(3);
  @$pb.TagNumber(4)
  set debugInfo(DebugInfo value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasDebugInfo() => $_has(3);
  @$pb.TagNumber(4)
  void clearDebugInfo() => $_clearField(4);
  @$pb.TagNumber(4)
  DebugInfo ensureDebugInfo() => $_ensure(3);

  @$pb.TagNumber(5)
  SandboxDebugInfo get sandboxDebugInfo => $_getN(4);
  @$pb.TagNumber(5)
  set sandboxDebugInfo(SandboxDebugInfo value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSandboxDebugInfo() => $_has(4);
  @$pb.TagNumber(5)
  void clearSandboxDebugInfo() => $_clearField(5);
  @$pb.TagNumber(5)
  SandboxDebugInfo ensureSandboxDebugInfo() => $_ensure(4);

  @$pb.TagNumber(999)
  OndemandSet get ondemandSet => $_getN(5);
  @$pb.TagNumber(999)
  set ondemandSet(OndemandSet value) => $_setField(999, value);
  @$pb.TagNumber(999)
  $core.bool hasOndemandSet() => $_has(5);
  @$pb.TagNumber(999)
  void clearOndemandSet() => $_clearField(999);
  @$pb.TagNumber(999)
  OndemandSet ensureOndemandSet() => $_ensure(5);
}

class HomeStructure extends $pb.GeneratedMessage {
  factory HomeStructure({
    $core.Iterable<Section>? sections,
  }) {
    final result = HomeStructure._();
    if (sections != null) result.sections.addAll(sections);
    return result;
  }

  HomeStructure._();

  factory HomeStructure.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HomeStructure()..mergeFromBuffer(data, registry);
  factory HomeStructure.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HomeStructure()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HomeStructure',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: HomeStructure.$_createMessage)
    ..pPM<Section>(1, _omitFieldNames ? '' : 'sections',
        subBuilder: Section.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HomeStructure clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HomeStructure copyWith(void Function(HomeStructure) updates) =>
      super.copyWith((message) => updates(message as HomeStructure))
          as HomeStructure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HomeStructure() / HomeStructure.new instead')
  static HomeStructure create() => HomeStructure._();
  static $pb.GeneratedMessage $_createMessage() => HomeStructure._();
  @$core.override
  HomeStructure createEmptyInstance() => HomeStructure._();
  @$core.pragma('dart2js:noInline')
  static HomeStructure getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HomeStructure>(
          HomeStructure.$_createMessage);
  static HomeStructure? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Section> get sections => $_getList(0);
}

class EagerlyLoadedTraits extends $pb.GeneratedMessage {
  factory EagerlyLoadedTraits({
    $0.BatchedExtensionResponse? traits,
  }) {
    final result = EagerlyLoadedTraits._();
    if (traits != null) result.traits = traits;
    return result;
  }

  EagerlyLoadedTraits._();

  factory EagerlyLoadedTraits.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EagerlyLoadedTraits()..mergeFromBuffer(data, registry);
  factory EagerlyLoadedTraits.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EagerlyLoadedTraits()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EagerlyLoadedTraits',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: EagerlyLoadedTraits.$_createMessage)
    ..aOM<$0.BatchedExtensionResponse>(1, _omitFieldNames ? '' : 'traits',
        subBuilder: $0.BatchedExtensionResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EagerlyLoadedTraits clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EagerlyLoadedTraits copyWith(void Function(EagerlyLoadedTraits) updates) =>
      super.copyWith((message) => updates(message as EagerlyLoadedTraits))
          as EagerlyLoadedTraits;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use EagerlyLoadedTraits() / EagerlyLoadedTraits.new instead')
  static EagerlyLoadedTraits create() => EagerlyLoadedTraits._();
  static $pb.GeneratedMessage $_createMessage() => EagerlyLoadedTraits._();
  @$core.override
  EagerlyLoadedTraits createEmptyInstance() => EagerlyLoadedTraits._();
  @$core.pragma('dart2js:noInline')
  static EagerlyLoadedTraits getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EagerlyLoadedTraits>(
          EagerlyLoadedTraits.$_createMessage);
  static EagerlyLoadedTraits? _defaultInstance;

  @$pb.TagNumber(1)
  $0.BatchedExtensionResponse get traits => $_getN(0);
  @$pb.TagNumber(1)
  set traits($0.BatchedExtensionResponse value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTraits() => $_has(0);
  @$pb.TagNumber(1)
  void clearTraits() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.BatchedExtensionResponse ensureTraits() => $_ensure(0);
}

class ResponseInfo extends $pb.GeneratedMessage {
  factory ResponseInfo({
    $core.String? serverVersion,
  }) {
    final result = ResponseInfo._();
    if (serverVersion != null) result.serverVersion = serverVersion;
    return result;
  }

  ResponseInfo._();

  factory ResponseInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResponseInfo()..mergeFromBuffer(data, registry);
  factory ResponseInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResponseInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponseInfo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: ResponseInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'serverVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseInfo copyWith(void Function(ResponseInfo) updates) =>
      super.copyWith((message) => updates(message as ResponseInfo))
          as ResponseInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResponseInfo() / ResponseInfo.new instead')
  static ResponseInfo create() => ResponseInfo._();
  static $pb.GeneratedMessage $_createMessage() => ResponseInfo._();
  @$core.override
  ResponseInfo createEmptyInstance() => ResponseInfo._();
  @$core.pragma('dart2js:noInline')
  static ResponseInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResponseInfo>(
          ResponseInfo.$_createMessage);
  static ResponseInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverVersion => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverVersion($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerVersion() => $_clearField(1);
}

class DebugInfo extends $pb.GeneratedMessage {
  factory DebugInfo() => DebugInfo._();

  DebugInfo._();

  factory DebugInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DebugInfo()..mergeFromBuffer(data, registry);
  factory DebugInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DebugInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DebugInfo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: DebugInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DebugInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DebugInfo copyWith(void Function(DebugInfo) updates) =>
      super.copyWith((message) => updates(message as DebugInfo)) as DebugInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DebugInfo() / DebugInfo.new instead')
  static DebugInfo create() => DebugInfo._();
  static $pb.GeneratedMessage $_createMessage() => DebugInfo._();
  @$core.override
  DebugInfo createEmptyInstance() => DebugInfo._();
  @$core.pragma('dart2js:noInline')
  static DebugInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DebugInfo>(DebugInfo.$_createMessage);
  static DebugInfo? _defaultInstance;
}

class SandboxDebugInfo extends $pb.GeneratedMessage {
  factory SandboxDebugInfo() => SandboxDebugInfo._();

  SandboxDebugInfo._();

  factory SandboxDebugInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SandboxDebugInfo()..mergeFromBuffer(data, registry);
  factory SandboxDebugInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SandboxDebugInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SandboxDebugInfo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: SandboxDebugInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SandboxDebugInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SandboxDebugInfo copyWith(void Function(SandboxDebugInfo) updates) =>
      super.copyWith((message) => updates(message as SandboxDebugInfo))
          as SandboxDebugInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SandboxDebugInfo() / SandboxDebugInfo.new instead')
  static SandboxDebugInfo create() => SandboxDebugInfo._();
  static $pb.GeneratedMessage $_createMessage() => SandboxDebugInfo._();
  @$core.override
  SandboxDebugInfo createEmptyInstance() => SandboxDebugInfo._();
  @$core.pragma('dart2js:noInline')
  static SandboxDebugInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SandboxDebugInfo>(
          SandboxDebugInfo.$_createMessage);
  static SandboxDebugInfo? _defaultInstance;
}

class OndemandSet extends $pb.GeneratedMessage {
  factory OndemandSet({
    $core.Iterable<$core.String>? uris,
  }) {
    final result = OndemandSet._();
    if (uris != null) result.uris.addAll(uris);
    return result;
  }

  OndemandSet._();

  factory OndemandSet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OndemandSet()..mergeFromBuffer(data, registry);
  factory OndemandSet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OndemandSet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OndemandSet',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: OndemandSet.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'uris')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OndemandSet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OndemandSet copyWith(void Function(OndemandSet) updates) =>
      super.copyWith((message) => updates(message as OndemandSet))
          as OndemandSet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use OndemandSet() / OndemandSet.new instead')
  static OndemandSet create() => OndemandSet._();
  static $pb.GeneratedMessage $_createMessage() => OndemandSet._();
  @$core.override
  OndemandSet createEmptyInstance() => OndemandSet._();
  @$core.pragma('dart2js:noInline')
  static OndemandSet getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OndemandSet>(
          OndemandSet.$_createMessage);
  static OndemandSet? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get uris => $_getList(0);
}

enum Section_FeatureType {
  shortcuts,
  imageLink,
  preview,
  immersivePreview,
  contentEvaluationList,
  callToAction,
  recentsShelf,
  watchFeed,
  liveEvent,
  showcase,
  verticalSingleEntry,
  videoCarousel,
  associatedPreview,
  narrative,
  interactiveEntrypoint,
  topStoryCarousel,
  audioPromo,
  inlineCard,
  audioSpotlight,
  previewCarousel,
  previewPromotionCarousel,
  reflection,
  notSet
}

class Section extends $pb.GeneratedMessage {
  factory Section({
    SectionInfo? sectionInfo,
    Shortcuts? shortcuts,
    ImageLink? imageLink,
    Preview? preview,
    ImmersivePreview? immersivePreview,
    ContentEvaluationList? contentEvaluationList,
    CallToAction? callToAction,
    RecentsShelf? recentsShelf,
    WatchFeed? watchFeed,
    LiveEvent? liveEvent,
    Showcase? showcase,
    VerticalSingleEntry? verticalSingleEntry,
    VideoCarousel? videoCarousel,
    AssociatedPreview? associatedPreview,
    Narrative? narrative,
    InteractiveEntrypoint? interactiveEntrypoint,
    TopStoryCarousel? topStoryCarousel,
    AudioPromo? audioPromo,
    InlineCard? inlineCard,
    AudioSpotlight? audioSpotlight,
    PreviewCarousel? previewCarousel,
    PreviewPromotionCarousel? previewPromotionCarousel,
    Reflection? reflection,
  }) {
    final result = Section._();
    if (sectionInfo != null) result.sectionInfo = sectionInfo;
    if (shortcuts != null) result.shortcuts = shortcuts;
    if (imageLink != null) result.imageLink = imageLink;
    if (preview != null) result.preview = preview;
    if (immersivePreview != null) result.immersivePreview = immersivePreview;
    if (contentEvaluationList != null)
      result.contentEvaluationList = contentEvaluationList;
    if (callToAction != null) result.callToAction = callToAction;
    if (recentsShelf != null) result.recentsShelf = recentsShelf;
    if (watchFeed != null) result.watchFeed = watchFeed;
    if (liveEvent != null) result.liveEvent = liveEvent;
    if (showcase != null) result.showcase = showcase;
    if (verticalSingleEntry != null)
      result.verticalSingleEntry = verticalSingleEntry;
    if (videoCarousel != null) result.videoCarousel = videoCarousel;
    if (associatedPreview != null) result.associatedPreview = associatedPreview;
    if (narrative != null) result.narrative = narrative;
    if (interactiveEntrypoint != null)
      result.interactiveEntrypoint = interactiveEntrypoint;
    if (topStoryCarousel != null) result.topStoryCarousel = topStoryCarousel;
    if (audioPromo != null) result.audioPromo = audioPromo;
    if (inlineCard != null) result.inlineCard = inlineCard;
    if (audioSpotlight != null) result.audioSpotlight = audioSpotlight;
    if (previewCarousel != null) result.previewCarousel = previewCarousel;
    if (previewPromotionCarousel != null)
      result.previewPromotionCarousel = previewPromotionCarousel;
    if (reflection != null) result.reflection = reflection;
    return result;
  }

  Section._();

  factory Section.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Section()..mergeFromBuffer(data, registry);
  factory Section.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Section()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Section_FeatureType>
      _Section_FeatureTypeByTag = {
    2: Section_FeatureType.shortcuts,
    3: Section_FeatureType.imageLink,
    4: Section_FeatureType.preview,
    6: Section_FeatureType.immersivePreview,
    8: Section_FeatureType.contentEvaluationList,
    9: Section_FeatureType.callToAction,
    10: Section_FeatureType.recentsShelf,
    11: Section_FeatureType.watchFeed,
    16: Section_FeatureType.liveEvent,
    17: Section_FeatureType.showcase,
    24: Section_FeatureType.verticalSingleEntry,
    25: Section_FeatureType.videoCarousel,
    27: Section_FeatureType.associatedPreview,
    29: Section_FeatureType.narrative,
    30: Section_FeatureType.interactiveEntrypoint,
    31: Section_FeatureType.topStoryCarousel,
    33: Section_FeatureType.audioPromo,
    34: Section_FeatureType.inlineCard,
    36: Section_FeatureType.audioSpotlight,
    37: Section_FeatureType.previewCarousel,
    39: Section_FeatureType.previewPromotionCarousel,
    41: Section_FeatureType.reflection,
    0: Section_FeatureType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Section',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: Section.$_createMessage)
    ..oo(0, [
      2,
      3,
      4,
      6,
      8,
      9,
      10,
      11,
      16,
      17,
      24,
      25,
      27,
      29,
      30,
      31,
      33,
      34,
      36,
      37,
      39,
      41
    ])
    ..aOM<SectionInfo>(1, _omitFieldNames ? '' : 'sectionInfo',
        subBuilder: SectionInfo.$_createMessage)
    ..aOM<Shortcuts>(2, _omitFieldNames ? '' : 'shortcuts',
        subBuilder: Shortcuts.$_createMessage)
    ..aOM<ImageLink>(3, _omitFieldNames ? '' : 'imageLink',
        subBuilder: ImageLink.$_createMessage)
    ..aOM<Preview>(4, _omitFieldNames ? '' : 'preview',
        subBuilder: Preview.$_createMessage)
    ..aOM<ImmersivePreview>(6, _omitFieldNames ? '' : 'immersivePreview',
        subBuilder: ImmersivePreview.$_createMessage)
    ..aOM<ContentEvaluationList>(
        8, _omitFieldNames ? '' : 'contentEvaluationList',
        subBuilder: ContentEvaluationList.$_createMessage)
    ..aOM<CallToAction>(9, _omitFieldNames ? '' : 'callToAction',
        subBuilder: CallToAction.$_createMessage)
    ..aOM<RecentsShelf>(10, _omitFieldNames ? '' : 'recentsShelf',
        subBuilder: RecentsShelf.$_createMessage)
    ..aOM<WatchFeed>(11, _omitFieldNames ? '' : 'watchFeed',
        subBuilder: WatchFeed.$_createMessage)
    ..aOM<LiveEvent>(16, _omitFieldNames ? '' : 'liveEvent',
        subBuilder: LiveEvent.$_createMessage)
    ..aOM<Showcase>(17, _omitFieldNames ? '' : 'showcase',
        subBuilder: Showcase.$_createMessage)
    ..aOM<VerticalSingleEntry>(24, _omitFieldNames ? '' : 'verticalSingleEntry',
        subBuilder: VerticalSingleEntry.$_createMessage)
    ..aOM<VideoCarousel>(25, _omitFieldNames ? '' : 'videoCarousel',
        subBuilder: VideoCarousel.$_createMessage)
    ..aOM<AssociatedPreview>(27, _omitFieldNames ? '' : 'associatedPreview',
        subBuilder: AssociatedPreview.$_createMessage)
    ..aOM<Narrative>(29, _omitFieldNames ? '' : 'narrative',
        subBuilder: Narrative.$_createMessage)
    ..aOM<InteractiveEntrypoint>(
        30, _omitFieldNames ? '' : 'interactiveEntrypoint',
        subBuilder: InteractiveEntrypoint.$_createMessage)
    ..aOM<TopStoryCarousel>(31, _omitFieldNames ? '' : 'topStoryCarousel',
        subBuilder: TopStoryCarousel.$_createMessage)
    ..aOM<AudioPromo>(33, _omitFieldNames ? '' : 'audioPromo',
        subBuilder: AudioPromo.$_createMessage)
    ..aOM<InlineCard>(34, _omitFieldNames ? '' : 'inlineCard',
        subBuilder: InlineCard.$_createMessage)
    ..aOM<AudioSpotlight>(36, _omitFieldNames ? '' : 'audioSpotlight',
        subBuilder: AudioSpotlight.$_createMessage)
    ..aOM<PreviewCarousel>(37, _omitFieldNames ? '' : 'previewCarousel',
        subBuilder: PreviewCarousel.$_createMessage)
    ..aOM<PreviewPromotionCarousel>(
        39, _omitFieldNames ? '' : 'previewPromotionCarousel',
        subBuilder: PreviewPromotionCarousel.$_createMessage)
    ..aOM<Reflection>(41, _omitFieldNames ? '' : 'reflection',
        subBuilder: Reflection.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Section clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Section copyWith(void Function(Section) updates) =>
      super.copyWith((message) => updates(message as Section)) as Section;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Section() / Section.new instead')
  static Section create() => Section._();
  static $pb.GeneratedMessage $_createMessage() => Section._();
  @$core.override
  Section createEmptyInstance() => Section._();
  @$core.pragma('dart2js:noInline')
  static Section getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Section>(Section.$_createMessage);
  static Section? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(6)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(24)
  @$pb.TagNumber(25)
  @$pb.TagNumber(27)
  @$pb.TagNumber(29)
  @$pb.TagNumber(30)
  @$pb.TagNumber(31)
  @$pb.TagNumber(33)
  @$pb.TagNumber(34)
  @$pb.TagNumber(36)
  @$pb.TagNumber(37)
  @$pb.TagNumber(39)
  @$pb.TagNumber(41)
  Section_FeatureType whichFeatureType() =>
      _Section_FeatureTypeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(6)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(24)
  @$pb.TagNumber(25)
  @$pb.TagNumber(27)
  @$pb.TagNumber(29)
  @$pb.TagNumber(30)
  @$pb.TagNumber(31)
  @$pb.TagNumber(33)
  @$pb.TagNumber(34)
  @$pb.TagNumber(36)
  @$pb.TagNumber(37)
  @$pb.TagNumber(39)
  @$pb.TagNumber(41)
  void clearFeatureType() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  SectionInfo get sectionInfo => $_getN(0);
  @$pb.TagNumber(1)
  set sectionInfo(SectionInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSectionInfo() => $_has(0);
  @$pb.TagNumber(1)
  void clearSectionInfo() => $_clearField(1);
  @$pb.TagNumber(1)
  SectionInfo ensureSectionInfo() => $_ensure(0);

  @$pb.TagNumber(2)
  Shortcuts get shortcuts => $_getN(1);
  @$pb.TagNumber(2)
  set shortcuts(Shortcuts value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasShortcuts() => $_has(1);
  @$pb.TagNumber(2)
  void clearShortcuts() => $_clearField(2);
  @$pb.TagNumber(2)
  Shortcuts ensureShortcuts() => $_ensure(1);

  @$pb.TagNumber(3)
  ImageLink get imageLink => $_getN(2);
  @$pb.TagNumber(3)
  set imageLink(ImageLink value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasImageLink() => $_has(2);
  @$pb.TagNumber(3)
  void clearImageLink() => $_clearField(3);
  @$pb.TagNumber(3)
  ImageLink ensureImageLink() => $_ensure(2);

  @$pb.TagNumber(4)
  Preview get preview => $_getN(3);
  @$pb.TagNumber(4)
  set preview(Preview value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPreview() => $_has(3);
  @$pb.TagNumber(4)
  void clearPreview() => $_clearField(4);
  @$pb.TagNumber(4)
  Preview ensurePreview() => $_ensure(3);

  /// field 5 is unused
  @$pb.TagNumber(6)
  ImmersivePreview get immersivePreview => $_getN(4);
  @$pb.TagNumber(6)
  set immersivePreview(ImmersivePreview value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasImmersivePreview() => $_has(4);
  @$pb.TagNumber(6)
  void clearImmersivePreview() => $_clearField(6);
  @$pb.TagNumber(6)
  ImmersivePreview ensureImmersivePreview() => $_ensure(4);

  /// field 7: Anchors (not needed for home)
  @$pb.TagNumber(8)
  ContentEvaluationList get contentEvaluationList => $_getN(5);
  @$pb.TagNumber(8)
  set contentEvaluationList(ContentEvaluationList value) =>
      $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasContentEvaluationList() => $_has(5);
  @$pb.TagNumber(8)
  void clearContentEvaluationList() => $_clearField(8);
  @$pb.TagNumber(8)
  ContentEvaluationList ensureContentEvaluationList() => $_ensure(5);

  @$pb.TagNumber(9)
  CallToAction get callToAction => $_getN(6);
  @$pb.TagNumber(9)
  set callToAction(CallToAction value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasCallToAction() => $_has(6);
  @$pb.TagNumber(9)
  void clearCallToAction() => $_clearField(9);
  @$pb.TagNumber(9)
  CallToAction ensureCallToAction() => $_ensure(6);

  @$pb.TagNumber(10)
  RecentsShelf get recentsShelf => $_getN(7);
  @$pb.TagNumber(10)
  set recentsShelf(RecentsShelf value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasRecentsShelf() => $_has(7);
  @$pb.TagNumber(10)
  void clearRecentsShelf() => $_clearField(10);
  @$pb.TagNumber(10)
  RecentsShelf ensureRecentsShelf() => $_ensure(7);

  @$pb.TagNumber(11)
  WatchFeed get watchFeed => $_getN(8);
  @$pb.TagNumber(11)
  set watchFeed(WatchFeed value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasWatchFeed() => $_has(8);
  @$pb.TagNumber(11)
  void clearWatchFeed() => $_clearField(11);
  @$pb.TagNumber(11)
  WatchFeed ensureWatchFeed() => $_ensure(8);

  /// field 12: PromotionV1 (ad, skip)
  /// field 13: PromotionV3 (ad, skip)
  /// field 15: ActionCardCarousel
  @$pb.TagNumber(16)
  LiveEvent get liveEvent => $_getN(9);
  @$pb.TagNumber(16)
  set liveEvent(LiveEvent value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasLiveEvent() => $_has(9);
  @$pb.TagNumber(16)
  void clearLiveEvent() => $_clearField(16);
  @$pb.TagNumber(16)
  LiveEvent ensureLiveEvent() => $_ensure(9);

  @$pb.TagNumber(17)
  Showcase get showcase => $_getN(10);
  @$pb.TagNumber(17)
  set showcase(Showcase value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasShowcase() => $_has(10);
  @$pb.TagNumber(17)
  void clearShowcase() => $_clearField(17);
  @$pb.TagNumber(17)
  Showcase ensureShowcase() => $_ensure(10);

  /// field 18: VideoPromo (ad)
  /// field 19: Banner (ad)
  /// field 20: VideoBrandAd (ad)
  /// field 21: ImageBrandAd (ad)
  /// field 23: CampaignLinkCarousel (ad)
  @$pb.TagNumber(24)
  VerticalSingleEntry get verticalSingleEntry => $_getN(11);
  @$pb.TagNumber(24)
  set verticalSingleEntry(VerticalSingleEntry value) => $_setField(24, value);
  @$pb.TagNumber(24)
  $core.bool hasVerticalSingleEntry() => $_has(11);
  @$pb.TagNumber(24)
  void clearVerticalSingleEntry() => $_clearField(24);
  @$pb.TagNumber(24)
  VerticalSingleEntry ensureVerticalSingleEntry() => $_ensure(11);

  @$pb.TagNumber(25)
  VideoCarousel get videoCarousel => $_getN(12);
  @$pb.TagNumber(25)
  set videoCarousel(VideoCarousel value) => $_setField(25, value);
  @$pb.TagNumber(25)
  $core.bool hasVideoCarousel() => $_has(12);
  @$pb.TagNumber(25)
  void clearVideoCarousel() => $_clearField(25);
  @$pb.TagNumber(25)
  VideoCarousel ensureVideoCarousel() => $_ensure(12);

  /// field 26: FullBleedBanner (ad)
  @$pb.TagNumber(27)
  AssociatedPreview get associatedPreview => $_getN(13);
  @$pb.TagNumber(27)
  set associatedPreview(AssociatedPreview value) => $_setField(27, value);
  @$pb.TagNumber(27)
  $core.bool hasAssociatedPreview() => $_has(13);
  @$pb.TagNumber(27)
  void clearAssociatedPreview() => $_clearField(27);
  @$pb.TagNumber(27)
  AssociatedPreview ensureAssociatedPreview() => $_ensure(13);

  /// field 28: BannerWithAnimations (ad)
  @$pb.TagNumber(29)
  Narrative get narrative => $_getN(14);
  @$pb.TagNumber(29)
  set narrative(Narrative value) => $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasNarrative() => $_has(14);
  @$pb.TagNumber(29)
  void clearNarrative() => $_clearField(29);
  @$pb.TagNumber(29)
  Narrative ensureNarrative() => $_ensure(14);

  @$pb.TagNumber(30)
  InteractiveEntrypoint get interactiveEntrypoint => $_getN(15);
  @$pb.TagNumber(30)
  set interactiveEntrypoint(InteractiveEntrypoint value) =>
      $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasInteractiveEntrypoint() => $_has(15);
  @$pb.TagNumber(30)
  void clearInteractiveEntrypoint() => $_clearField(30);
  @$pb.TagNumber(30)
  InteractiveEntrypoint ensureInteractiveEntrypoint() => $_ensure(15);

  @$pb.TagNumber(31)
  TopStoryCarousel get topStoryCarousel => $_getN(16);
  @$pb.TagNumber(31)
  set topStoryCarousel(TopStoryCarousel value) => $_setField(31, value);
  @$pb.TagNumber(31)
  $core.bool hasTopStoryCarousel() => $_has(16);
  @$pb.TagNumber(31)
  void clearTopStoryCarousel() => $_clearField(31);
  @$pb.TagNumber(31)
  TopStoryCarousel ensureTopStoryCarousel() => $_ensure(16);

  /// field 32: PromptableSection
  @$pb.TagNumber(33)
  AudioPromo get audioPromo => $_getN(17);
  @$pb.TagNumber(33)
  set audioPromo(AudioPromo value) => $_setField(33, value);
  @$pb.TagNumber(33)
  $core.bool hasAudioPromo() => $_has(17);
  @$pb.TagNumber(33)
  void clearAudioPromo() => $_clearField(33);
  @$pb.TagNumber(33)
  AudioPromo ensureAudioPromo() => $_ensure(17);

  @$pb.TagNumber(34)
  InlineCard get inlineCard => $_getN(18);
  @$pb.TagNumber(34)
  set inlineCard(InlineCard value) => $_setField(34, value);
  @$pb.TagNumber(34)
  $core.bool hasInlineCard() => $_has(18);
  @$pb.TagNumber(34)
  void clearInlineCard() => $_clearField(34);
  @$pb.TagNumber(34)
  InlineCard ensureInlineCard() => $_ensure(18);

  /// field 35: PlayLinkPromo
  @$pb.TagNumber(36)
  AudioSpotlight get audioSpotlight => $_getN(19);
  @$pb.TagNumber(36)
  set audioSpotlight(AudioSpotlight value) => $_setField(36, value);
  @$pb.TagNumber(36)
  $core.bool hasAudioSpotlight() => $_has(19);
  @$pb.TagNumber(36)
  void clearAudioSpotlight() => $_clearField(36);
  @$pb.TagNumber(36)
  AudioSpotlight ensureAudioSpotlight() => $_ensure(19);

  @$pb.TagNumber(37)
  PreviewCarousel get previewCarousel => $_getN(20);
  @$pb.TagNumber(37)
  set previewCarousel(PreviewCarousel value) => $_setField(37, value);
  @$pb.TagNumber(37)
  $core.bool hasPreviewCarousel() => $_has(20);
  @$pb.TagNumber(37)
  void clearPreviewCarousel() => $_clearField(37);
  @$pb.TagNumber(37)
  PreviewCarousel ensurePreviewCarousel() => $_ensure(20);

  /// field 38: ConcertCampaign
  @$pb.TagNumber(39)
  PreviewPromotionCarousel get previewPromotionCarousel => $_getN(21);
  @$pb.TagNumber(39)
  set previewPromotionCarousel(PreviewPromotionCarousel value) =>
      $_setField(39, value);
  @$pb.TagNumber(39)
  $core.bool hasPreviewPromotionCarousel() => $_has(21);
  @$pb.TagNumber(39)
  void clearPreviewPromotionCarousel() => $_clearField(39);
  @$pb.TagNumber(39)
  PreviewPromotionCarousel ensurePreviewPromotionCarousel() => $_ensure(21);

  /// field 40: PromptedWorldsShelf
  @$pb.TagNumber(41)
  Reflection get reflection => $_getN(22);
  @$pb.TagNumber(41)
  set reflection(Reflection value) => $_setField(41, value);
  @$pb.TagNumber(41)
  $core.bool hasReflection() => $_has(22);
  @$pb.TagNumber(41)
  void clearReflection() => $_clearField(41);
  @$pb.TagNumber(41)
  Reflection ensureReflection() => $_ensure(22);
}

class SectionInfo extends $pb.GeneratedMessage {
  factory SectionInfo({
    $core.String? sectionId,
  }) {
    final result = SectionInfo._();
    if (sectionId != null) result.sectionId = sectionId;
    return result;
  }

  SectionInfo._();

  factory SectionInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionInfo()..mergeFromBuffer(data, registry);
  factory SectionInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SectionInfo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: SectionInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sectionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionInfo copyWith(void Function(SectionInfo) updates) =>
      super.copyWith((message) => updates(message as SectionInfo))
          as SectionInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SectionInfo() / SectionInfo.new instead')
  static SectionInfo create() => SectionInfo._();
  static $pb.GeneratedMessage $_createMessage() => SectionInfo._();
  @$core.override
  SectionInfo createEmptyInstance() => SectionInfo._();
  @$core.pragma('dart2js:noInline')
  static SectionInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SectionInfo>(
          SectionInfo.$_createMessage);
  static SectionInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sectionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sectionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSectionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSectionId() => $_clearField(1);
}

class Item extends $pb.GeneratedMessage {
  factory Item({
    $core.String? identifier,
    $core.Iterable<$core.String>? highlightedSubItems,
  }) {
    final result = Item._();
    if (identifier != null) result.identifier = identifier;
    if (highlightedSubItems != null)
      result.highlightedSubItems.addAll(highlightedSubItems);
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
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: Item.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'identifier')
    ..pPS(2, _omitFieldNames ? '' : 'highlightedSubItems')
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
  $core.String get identifier => $_getSZ(0);
  @$pb.TagNumber(1)
  set identifier($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIdentifier() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdentifier() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get highlightedSubItems => $_getList(1);
}

enum ItemSource_Source { provided, localRecentlyPlayed, listPlatform, notSet }

class ItemSource extends $pb.GeneratedMessage {
  factory ItemSource({
    Provided? provided,
    LocalRecentlyPlayed? localRecentlyPlayed,
    ListPlatform? listPlatform,
  }) {
    final result = ItemSource._();
    if (provided != null) result.provided = provided;
    if (localRecentlyPlayed != null)
      result.localRecentlyPlayed = localRecentlyPlayed;
    if (listPlatform != null) result.listPlatform = listPlatform;
    return result;
  }

  ItemSource._();

  factory ItemSource.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ItemSource()..mergeFromBuffer(data, registry);
  factory ItemSource.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ItemSource()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ItemSource_Source> _ItemSource_SourceByTag =
      {
    1: ItemSource_Source.provided,
    2: ItemSource_Source.localRecentlyPlayed,
    3: ItemSource_Source.listPlatform,
    0: ItemSource_Source.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ItemSource',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: ItemSource.$_createMessage)
    ..oo(0, [1, 2, 3])
    ..aOM<Provided>(1, _omitFieldNames ? '' : 'provided',
        subBuilder: Provided.$_createMessage)
    ..aOM<LocalRecentlyPlayed>(2, _omitFieldNames ? '' : 'localRecentlyPlayed',
        subBuilder: LocalRecentlyPlayed.$_createMessage)
    ..aOM<ListPlatform>(3, _omitFieldNames ? '' : 'listPlatform',
        subBuilder: ListPlatform.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ItemSource clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ItemSource copyWith(void Function(ItemSource) updates) =>
      super.copyWith((message) => updates(message as ItemSource)) as ItemSource;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ItemSource() / ItemSource.new instead')
  static ItemSource create() => ItemSource._();
  static $pb.GeneratedMessage $_createMessage() => ItemSource._();
  @$core.override
  ItemSource createEmptyInstance() => ItemSource._();
  @$core.pragma('dart2js:noInline')
  static ItemSource getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ItemSource>(ItemSource.$_createMessage);
  static ItemSource? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  ItemSource_Source whichSource() => _ItemSource_SourceByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearSource() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Provided get provided => $_getN(0);
  @$pb.TagNumber(1)
  set provided(Provided value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProvided() => $_has(0);
  @$pb.TagNumber(1)
  void clearProvided() => $_clearField(1);
  @$pb.TagNumber(1)
  Provided ensureProvided() => $_ensure(0);

  @$pb.TagNumber(2)
  LocalRecentlyPlayed get localRecentlyPlayed => $_getN(1);
  @$pb.TagNumber(2)
  set localRecentlyPlayed(LocalRecentlyPlayed value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLocalRecentlyPlayed() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocalRecentlyPlayed() => $_clearField(2);
  @$pb.TagNumber(2)
  LocalRecentlyPlayed ensureLocalRecentlyPlayed() => $_ensure(1);

  @$pb.TagNumber(3)
  ListPlatform get listPlatform => $_getN(2);
  @$pb.TagNumber(3)
  set listPlatform(ListPlatform value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasListPlatform() => $_has(2);
  @$pb.TagNumber(3)
  void clearListPlatform() => $_clearField(3);
  @$pb.TagNumber(3)
  ListPlatform ensureListPlatform() => $_ensure(2);
}

class Provided extends $pb.GeneratedMessage {
  factory Provided({
    $core.Iterable<Item>? items,
  }) {
    final result = Provided._();
    if (items != null) result.items.addAll(items);
    return result;
  }

  Provided._();

  factory Provided.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Provided()..mergeFromBuffer(data, registry);
  factory Provided.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Provided()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Provided',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: Provided.$_createMessage)
    ..pPM<Item>(1, _omitFieldNames ? '' : 'items',
        subBuilder: Item.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Provided clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Provided copyWith(void Function(Provided) updates) =>
      super.copyWith((message) => updates(message as Provided)) as Provided;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Provided() / Provided.new instead')
  static Provided create() => Provided._();
  static $pb.GeneratedMessage $_createMessage() => Provided._();
  @$core.override
  Provided createEmptyInstance() => Provided._();
  @$core.pragma('dart2js:noInline')
  static Provided getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Provided>(Provided.$_createMessage);
  static Provided? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Item> get items => $_getList(0);
}

class LocalRecentlyPlayed extends $pb.GeneratedMessage {
  factory LocalRecentlyPlayed() => LocalRecentlyPlayed._();

  LocalRecentlyPlayed._();

  factory LocalRecentlyPlayed.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LocalRecentlyPlayed()..mergeFromBuffer(data, registry);
  factory LocalRecentlyPlayed.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LocalRecentlyPlayed()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LocalRecentlyPlayed',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: LocalRecentlyPlayed.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalRecentlyPlayed clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalRecentlyPlayed copyWith(void Function(LocalRecentlyPlayed) updates) =>
      super.copyWith((message) => updates(message as LocalRecentlyPlayed))
          as LocalRecentlyPlayed;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use LocalRecentlyPlayed() / LocalRecentlyPlayed.new instead')
  static LocalRecentlyPlayed create() => LocalRecentlyPlayed._();
  static $pb.GeneratedMessage $_createMessage() => LocalRecentlyPlayed._();
  @$core.override
  LocalRecentlyPlayed createEmptyInstance() => LocalRecentlyPlayed._();
  @$core.pragma('dart2js:noInline')
  static LocalRecentlyPlayed getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LocalRecentlyPlayed>(
          LocalRecentlyPlayed.$_createMessage);
  static LocalRecentlyPlayed? _defaultInstance;
}

class ListPlatform extends $pb.GeneratedMessage {
  factory ListPlatform({
    $core.String? uri,
  }) {
    final result = ListPlatform._();
    if (uri != null) result.uri = uri;
    return result;
  }

  ListPlatform._();

  factory ListPlatform.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListPlatform()..mergeFromBuffer(data, registry);
  factory ListPlatform.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListPlatform()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListPlatform',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: ListPlatform.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPlatform clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPlatform copyWith(void Function(ListPlatform) updates) =>
      super.copyWith((message) => updates(message as ListPlatform))
          as ListPlatform;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListPlatform() / ListPlatform.new instead')
  static ListPlatform create() => ListPlatform._();
  static $pb.GeneratedMessage $_createMessage() => ListPlatform._();
  @$core.override
  ListPlatform createEmptyInstance() => ListPlatform._();
  @$core.pragma('dart2js:noInline')
  static ListPlatform getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListPlatform>(
          ListPlatform.$_createMessage);
  static ListPlatform? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearUri() => $_clearField(1);
}

enum Heading_Heading {
  emptyHeading,
  textHeading,
  enrichedHeading,
  sponsoredHeading,
  headingWithDescription,
  staticEnrichedHeading,
  notSet
}

class Heading extends $pb.GeneratedMessage {
  factory Heading({
    EmptyHeading? emptyHeading,
    HeadingWithText? textHeading,
    EnrichedHeading? enrichedHeading,
    SponsoredHeading? sponsoredHeading,
    HeadingWithDescription? headingWithDescription,
    StaticEnrichedHeading? staticEnrichedHeading,
  }) {
    final result = Heading._();
    if (emptyHeading != null) result.emptyHeading = emptyHeading;
    if (textHeading != null) result.textHeading = textHeading;
    if (enrichedHeading != null) result.enrichedHeading = enrichedHeading;
    if (sponsoredHeading != null) result.sponsoredHeading = sponsoredHeading;
    if (headingWithDescription != null)
      result.headingWithDescription = headingWithDescription;
    if (staticEnrichedHeading != null)
      result.staticEnrichedHeading = staticEnrichedHeading;
    return result;
  }

  Heading._();

  factory Heading.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Heading()..mergeFromBuffer(data, registry);
  factory Heading.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Heading()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Heading_Heading> _Heading_HeadingByTag = {
    1: Heading_Heading.emptyHeading,
    2: Heading_Heading.textHeading,
    3: Heading_Heading.enrichedHeading,
    4: Heading_Heading.sponsoredHeading,
    5: Heading_Heading.headingWithDescription,
    6: Heading_Heading.staticEnrichedHeading,
    0: Heading_Heading.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Heading',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: Heading.$_createMessage)
    ..oo(0, [1, 2, 3, 4, 5, 6])
    ..aOM<EmptyHeading>(1, _omitFieldNames ? '' : 'emptyHeading',
        subBuilder: EmptyHeading.$_createMessage)
    ..aOM<HeadingWithText>(2, _omitFieldNames ? '' : 'textHeading',
        subBuilder: HeadingWithText.$_createMessage)
    ..aOM<EnrichedHeading>(3, _omitFieldNames ? '' : 'enrichedHeading',
        subBuilder: EnrichedHeading.$_createMessage)
    ..aOM<SponsoredHeading>(4, _omitFieldNames ? '' : 'sponsoredHeading',
        subBuilder: SponsoredHeading.$_createMessage)
    ..aOM<HeadingWithDescription>(
        5, _omitFieldNames ? '' : 'headingWithDescription',
        subBuilder: HeadingWithDescription.$_createMessage)
    ..aOM<StaticEnrichedHeading>(
        6, _omitFieldNames ? '' : 'staticEnrichedHeading',
        subBuilder: StaticEnrichedHeading.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Heading clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Heading copyWith(void Function(Heading) updates) =>
      super.copyWith((message) => updates(message as Heading)) as Heading;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Heading() / Heading.new instead')
  static Heading create() => Heading._();
  static $pb.GeneratedMessage $_createMessage() => Heading._();
  @$core.override
  Heading createEmptyInstance() => Heading._();
  @$core.pragma('dart2js:noInline')
  static Heading getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Heading>(Heading.$_createMessage);
  static Heading? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  Heading_Heading whichHeading() => _Heading_HeadingByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  void clearHeading() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  EmptyHeading get emptyHeading => $_getN(0);
  @$pb.TagNumber(1)
  set emptyHeading(EmptyHeading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEmptyHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearEmptyHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  EmptyHeading ensureEmptyHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  HeadingWithText get textHeading => $_getN(1);
  @$pb.TagNumber(2)
  set textHeading(HeadingWithText value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTextHeading() => $_has(1);
  @$pb.TagNumber(2)
  void clearTextHeading() => $_clearField(2);
  @$pb.TagNumber(2)
  HeadingWithText ensureTextHeading() => $_ensure(1);

  @$pb.TagNumber(3)
  EnrichedHeading get enrichedHeading => $_getN(2);
  @$pb.TagNumber(3)
  set enrichedHeading(EnrichedHeading value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasEnrichedHeading() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnrichedHeading() => $_clearField(3);
  @$pb.TagNumber(3)
  EnrichedHeading ensureEnrichedHeading() => $_ensure(2);

  @$pb.TagNumber(4)
  SponsoredHeading get sponsoredHeading => $_getN(3);
  @$pb.TagNumber(4)
  set sponsoredHeading(SponsoredHeading value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSponsoredHeading() => $_has(3);
  @$pb.TagNumber(4)
  void clearSponsoredHeading() => $_clearField(4);
  @$pb.TagNumber(4)
  SponsoredHeading ensureSponsoredHeading() => $_ensure(3);

  @$pb.TagNumber(5)
  HeadingWithDescription get headingWithDescription => $_getN(4);
  @$pb.TagNumber(5)
  set headingWithDescription(HeadingWithDescription value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasHeadingWithDescription() => $_has(4);
  @$pb.TagNumber(5)
  void clearHeadingWithDescription() => $_clearField(5);
  @$pb.TagNumber(5)
  HeadingWithDescription ensureHeadingWithDescription() => $_ensure(4);

  @$pb.TagNumber(6)
  StaticEnrichedHeading get staticEnrichedHeading => $_getN(5);
  @$pb.TagNumber(6)
  set staticEnrichedHeading(StaticEnrichedHeading value) =>
      $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasStaticEnrichedHeading() => $_has(5);
  @$pb.TagNumber(6)
  void clearStaticEnrichedHeading() => $_clearField(6);
  @$pb.TagNumber(6)
  StaticEnrichedHeading ensureStaticEnrichedHeading() => $_ensure(5);
}

class EmptyHeading extends $pb.GeneratedMessage {
  factory EmptyHeading() => EmptyHeading._();

  EmptyHeading._();

  factory EmptyHeading.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EmptyHeading()..mergeFromBuffer(data, registry);
  factory EmptyHeading.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EmptyHeading()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EmptyHeading',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: EmptyHeading.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EmptyHeading clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EmptyHeading copyWith(void Function(EmptyHeading) updates) =>
      super.copyWith((message) => updates(message as EmptyHeading))
          as EmptyHeading;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EmptyHeading() / EmptyHeading.new instead')
  static EmptyHeading create() => EmptyHeading._();
  static $pb.GeneratedMessage $_createMessage() => EmptyHeading._();
  @$core.override
  EmptyHeading createEmptyInstance() => EmptyHeading._();
  @$core.pragma('dart2js:noInline')
  static EmptyHeading getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EmptyHeading>(
          EmptyHeading.$_createMessage);
  static EmptyHeading? _defaultInstance;
}

class HeadingWithText extends $pb.GeneratedMessage {
  factory HeadingWithText({
    $core.String? text,
    $core.String? encoreIconName,
    NavigationAction? navigationAction,
  }) {
    final result = HeadingWithText._();
    if (text != null) result.text = text;
    if (encoreIconName != null) result.encoreIconName = encoreIconName;
    if (navigationAction != null) result.navigationAction = navigationAction;
    return result;
  }

  HeadingWithText._();

  factory HeadingWithText.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HeadingWithText()..mergeFromBuffer(data, registry);
  factory HeadingWithText.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HeadingWithText()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeadingWithText',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: HeadingWithText.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOS(2, _omitFieldNames ? '' : 'encoreIconName')
    ..aOM<NavigationAction>(3, _omitFieldNames ? '' : 'navigationAction',
        subBuilder: NavigationAction.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeadingWithText clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeadingWithText copyWith(void Function(HeadingWithText) updates) =>
      super.copyWith((message) => updates(message as HeadingWithText))
          as HeadingWithText;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HeadingWithText() / HeadingWithText.new instead')
  static HeadingWithText create() => HeadingWithText._();
  static $pb.GeneratedMessage $_createMessage() => HeadingWithText._();
  @$core.override
  HeadingWithText createEmptyInstance() => HeadingWithText._();
  @$core.pragma('dart2js:noInline')
  static HeadingWithText getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HeadingWithText>(
          HeadingWithText.$_createMessage);
  static HeadingWithText? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get encoreIconName => $_getSZ(1);
  @$pb.TagNumber(2)
  set encoreIconName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEncoreIconName() => $_has(1);
  @$pb.TagNumber(2)
  void clearEncoreIconName() => $_clearField(2);

  @$pb.TagNumber(3)
  NavigationAction get navigationAction => $_getN(2);
  @$pb.TagNumber(3)
  set navigationAction(NavigationAction value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasNavigationAction() => $_has(2);
  @$pb.TagNumber(3)
  void clearNavigationAction() => $_clearField(3);
  @$pb.TagNumber(3)
  NavigationAction ensureNavigationAction() => $_ensure(2);
}

class EnrichedHeading extends $pb.GeneratedMessage {
  factory EnrichedHeading({
    $core.String? format,
    HeadingAssociatedItem? associatedItem,
    $core.String? encoreIconName,
  }) {
    final result = EnrichedHeading._();
    if (format != null) result.format = format;
    if (associatedItem != null) result.associatedItem = associatedItem;
    if (encoreIconName != null) result.encoreIconName = encoreIconName;
    return result;
  }

  EnrichedHeading._();

  factory EnrichedHeading.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EnrichedHeading()..mergeFromBuffer(data, registry);
  factory EnrichedHeading.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EnrichedHeading()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnrichedHeading',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: EnrichedHeading.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'format')
    ..aOM<HeadingAssociatedItem>(2, _omitFieldNames ? '' : 'associatedItem',
        subBuilder: HeadingAssociatedItem.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'encoreIconName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnrichedHeading clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnrichedHeading copyWith(void Function(EnrichedHeading) updates) =>
      super.copyWith((message) => updates(message as EnrichedHeading))
          as EnrichedHeading;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EnrichedHeading() / EnrichedHeading.new instead')
  static EnrichedHeading create() => EnrichedHeading._();
  static $pb.GeneratedMessage $_createMessage() => EnrichedHeading._();
  @$core.override
  EnrichedHeading createEmptyInstance() => EnrichedHeading._();
  @$core.pragma('dart2js:noInline')
  static EnrichedHeading getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EnrichedHeading>(
          EnrichedHeading.$_createMessage);
  static EnrichedHeading? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get format => $_getSZ(0);
  @$pb.TagNumber(1)
  set format($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFormat() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormat() => $_clearField(1);

  @$pb.TagNumber(2)
  HeadingAssociatedItem get associatedItem => $_getN(1);
  @$pb.TagNumber(2)
  set associatedItem(HeadingAssociatedItem value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAssociatedItem() => $_has(1);
  @$pb.TagNumber(2)
  void clearAssociatedItem() => $_clearField(2);
  @$pb.TagNumber(2)
  HeadingAssociatedItem ensureAssociatedItem() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get encoreIconName => $_getSZ(2);
  @$pb.TagNumber(3)
  set encoreIconName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEncoreIconName() => $_has(2);
  @$pb.TagNumber(3)
  void clearEncoreIconName() => $_clearField(3);
}

class HeadingWithDescription extends $pb.GeneratedMessage {
  factory HeadingWithDescription({
    $core.String? title,
    $core.String? subtitle,
    $core.String? encoreIconName,
  }) {
    final result = HeadingWithDescription._();
    if (title != null) result.title = title;
    if (subtitle != null) result.subtitle = subtitle;
    if (encoreIconName != null) result.encoreIconName = encoreIconName;
    return result;
  }

  HeadingWithDescription._();

  factory HeadingWithDescription.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HeadingWithDescription()..mergeFromBuffer(data, registry);
  factory HeadingWithDescription.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HeadingWithDescription()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeadingWithDescription',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: HeadingWithDescription.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'subtitle')
    ..aOS(3, _omitFieldNames ? '' : 'encoreIconName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeadingWithDescription clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeadingWithDescription copyWith(
          void Function(HeadingWithDescription) updates) =>
      super.copyWith((message) => updates(message as HeadingWithDescription))
          as HeadingWithDescription;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use HeadingWithDescription() / HeadingWithDescription.new instead')
  static HeadingWithDescription create() => HeadingWithDescription._();
  static $pb.GeneratedMessage $_createMessage() => HeadingWithDescription._();
  @$core.override
  HeadingWithDescription createEmptyInstance() => HeadingWithDescription._();
  @$core.pragma('dart2js:noInline')
  static HeadingWithDescription getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HeadingWithDescription>(
          HeadingWithDescription.$_createMessage);
  static HeadingWithDescription? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get subtitle => $_getSZ(1);
  @$pb.TagNumber(2)
  set subtitle($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSubtitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubtitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get encoreIconName => $_getSZ(2);
  @$pb.TagNumber(3)
  set encoreIconName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEncoreIconName() => $_has(2);
  @$pb.TagNumber(3)
  void clearEncoreIconName() => $_clearField(3);
}

class StaticEnrichedHeading extends $pb.GeneratedMessage {
  factory StaticEnrichedHeading({
    $core.String? text,
    $core.String? subtext,
    $core.String? imageUrl,
    $core.String? navigationUri,
  }) {
    final result = StaticEnrichedHeading._();
    if (text != null) result.text = text;
    if (subtext != null) result.subtext = subtext;
    if (imageUrl != null) result.imageUrl = imageUrl;
    if (navigationUri != null) result.navigationUri = navigationUri;
    return result;
  }

  StaticEnrichedHeading._();

  factory StaticEnrichedHeading.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StaticEnrichedHeading()..mergeFromBuffer(data, registry);
  factory StaticEnrichedHeading.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StaticEnrichedHeading()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StaticEnrichedHeading',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: StaticEnrichedHeading.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOS(2, _omitFieldNames ? '' : 'subtext')
    ..aOS(3, _omitFieldNames ? '' : 'imageUrl')
    ..aOS(4, _omitFieldNames ? '' : 'navigationUri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StaticEnrichedHeading clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StaticEnrichedHeading copyWith(
          void Function(StaticEnrichedHeading) updates) =>
      super.copyWith((message) => updates(message as StaticEnrichedHeading))
          as StaticEnrichedHeading;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use StaticEnrichedHeading() / StaticEnrichedHeading.new instead')
  static StaticEnrichedHeading create() => StaticEnrichedHeading._();
  static $pb.GeneratedMessage $_createMessage() => StaticEnrichedHeading._();
  @$core.override
  StaticEnrichedHeading createEmptyInstance() => StaticEnrichedHeading._();
  @$core.pragma('dart2js:noInline')
  static StaticEnrichedHeading getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StaticEnrichedHeading>(
          StaticEnrichedHeading.$_createMessage);
  static StaticEnrichedHeading? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get subtext => $_getSZ(1);
  @$pb.TagNumber(2)
  set subtext($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSubtext() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubtext() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get imageUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set imageUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasImageUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearImageUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get navigationUri => $_getSZ(3);
  @$pb.TagNumber(4)
  set navigationUri($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNavigationUri() => $_has(3);
  @$pb.TagNumber(4)
  void clearNavigationUri() => $_clearField(4);
}

class SponsoredHeading extends $pb.GeneratedMessage {
  factory SponsoredHeading({
    $core.String? text,
  }) {
    final result = SponsoredHeading._();
    if (text != null) result.text = text;
    return result;
  }

  SponsoredHeading._();

  factory SponsoredHeading.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SponsoredHeading()..mergeFromBuffer(data, registry);
  factory SponsoredHeading.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SponsoredHeading()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SponsoredHeading',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: SponsoredHeading.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SponsoredHeading clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SponsoredHeading copyWith(void Function(SponsoredHeading) updates) =>
      super.copyWith((message) => updates(message as SponsoredHeading))
          as SponsoredHeading;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SponsoredHeading() / SponsoredHeading.new instead')
  static SponsoredHeading create() => SponsoredHeading._();
  static $pb.GeneratedMessage $_createMessage() => SponsoredHeading._();
  @$core.override
  SponsoredHeading createEmptyInstance() => SponsoredHeading._();
  @$core.pragma('dart2js:noInline')
  static SponsoredHeading getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SponsoredHeading>(
          SponsoredHeading.$_createMessage);
  static SponsoredHeading? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);
}

class HeadingAssociatedItem extends $pb.GeneratedMessage {
  factory HeadingAssociatedItem({
    $core.String? title,
    $core.String? uri,
    $core.String? imageUrl,
  }) {
    final result = HeadingAssociatedItem._();
    if (title != null) result.title = title;
    if (uri != null) result.uri = uri;
    if (imageUrl != null) result.imageUrl = imageUrl;
    return result;
  }

  HeadingAssociatedItem._();

  factory HeadingAssociatedItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HeadingAssociatedItem()..mergeFromBuffer(data, registry);
  factory HeadingAssociatedItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HeadingAssociatedItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeadingAssociatedItem',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: HeadingAssociatedItem.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'uri')
    ..aOS(3, _omitFieldNames ? '' : 'imageUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeadingAssociatedItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeadingAssociatedItem copyWith(
          void Function(HeadingAssociatedItem) updates) =>
      super.copyWith((message) => updates(message as HeadingAssociatedItem))
          as HeadingAssociatedItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use HeadingAssociatedItem() / HeadingAssociatedItem.new instead')
  static HeadingAssociatedItem create() => HeadingAssociatedItem._();
  static $pb.GeneratedMessage $_createMessage() => HeadingAssociatedItem._();
  @$core.override
  HeadingAssociatedItem createEmptyInstance() => HeadingAssociatedItem._();
  @$core.pragma('dart2js:noInline')
  static HeadingAssociatedItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HeadingAssociatedItem>(
          HeadingAssociatedItem.$_createMessage);
  static HeadingAssociatedItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get uri => $_getSZ(1);
  @$pb.TagNumber(2)
  set uri($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUri() => $_has(1);
  @$pb.TagNumber(2)
  void clearUri() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get imageUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set imageUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasImageUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearImageUrl() => $_clearField(3);
}

class NavigationAction extends $pb.GeneratedMessage {
  factory NavigationAction({
    $core.String? text,
    $core.String? uri,
  }) {
    final result = NavigationAction._();
    if (text != null) result.text = text;
    if (uri != null) result.uri = uri;
    return result;
  }

  NavigationAction._();

  factory NavigationAction.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NavigationAction()..mergeFromBuffer(data, registry);
  factory NavigationAction.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NavigationAction()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NavigationAction',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: NavigationAction.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOS(2, _omitFieldNames ? '' : 'uri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NavigationAction clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NavigationAction copyWith(void Function(NavigationAction) updates) =>
      super.copyWith((message) => updates(message as NavigationAction))
          as NavigationAction;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NavigationAction() / NavigationAction.new instead')
  static NavigationAction create() => NavigationAction._();
  static $pb.GeneratedMessage $_createMessage() => NavigationAction._();
  @$core.override
  NavigationAction createEmptyInstance() => NavigationAction._();
  @$core.pragma('dart2js:noInline')
  static NavigationAction getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NavigationAction>(
          NavigationAction.$_createMessage);
  static NavigationAction? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get uri => $_getSZ(1);
  @$pb.TagNumber(2)
  set uri($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUri() => $_has(1);
  @$pb.TagNumber(2)
  void clearUri() => $_clearField(2);
}

/// field 2: Quick-access shortcut grid (top of home)
class Shortcuts extends $pb.GeneratedMessage {
  factory Shortcuts({
    Heading? heading,
    ItemSource? itemSource,
  }) {
    final result = Shortcuts._();
    if (heading != null) result.heading = heading;
    if (itemSource != null) result.itemSource = itemSource;
    return result;
  }

  Shortcuts._();

  factory Shortcuts.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Shortcuts()..mergeFromBuffer(data, registry);
  factory Shortcuts.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Shortcuts()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Shortcuts',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: Shortcuts.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<ItemSource>(2, _omitFieldNames ? '' : 'itemSource',
        subBuilder: ItemSource.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Shortcuts clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Shortcuts copyWith(void Function(Shortcuts) updates) =>
      super.copyWith((message) => updates(message as Shortcuts)) as Shortcuts;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Shortcuts() / Shortcuts.new instead')
  static Shortcuts create() => Shortcuts._();
  static $pb.GeneratedMessage $_createMessage() => Shortcuts._();
  @$core.override
  Shortcuts createEmptyInstance() => Shortcuts._();
  @$core.pragma('dart2js:noInline')
  static Shortcuts getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Shortcuts>(Shortcuts.$_createMessage);
  static Shortcuts? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  ItemSource get itemSource => $_getN(1);
  @$pb.TagNumber(2)
  set itemSource(ItemSource value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItemSource() => $_has(1);
  @$pb.TagNumber(2)
  void clearItemSource() => $_clearField(2);
  @$pb.TagNumber(2)
  ItemSource ensureItemSource() => $_ensure(1);
}

/// field 3: Standard horizontal image card carousel (most common section type)
class ImageLink extends $pb.GeneratedMessage {
  factory ImageLink({
    Heading? heading,
    ItemSource? itemSource,
    $core.int? density,
    EmbeddedAdMetadata? adMetadata,
    $core.int? source,
  }) {
    final result = ImageLink._();
    if (heading != null) result.heading = heading;
    if (itemSource != null) result.itemSource = itemSource;
    if (density != null) result.density = density;
    if (adMetadata != null) result.adMetadata = adMetadata;
    if (source != null) result.source = source;
    return result;
  }

  ImageLink._();

  factory ImageLink.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ImageLink()..mergeFromBuffer(data, registry);
  factory ImageLink.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ImageLink()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImageLink',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: ImageLink.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<ItemSource>(2, _omitFieldNames ? '' : 'itemSource',
        subBuilder: ItemSource.$_createMessage)
    ..aI(3, _omitFieldNames ? '' : 'density')
    ..aOM<EmbeddedAdMetadata>(4, _omitFieldNames ? '' : 'adMetadata',
        subBuilder: EmbeddedAdMetadata.$_createMessage)
    ..aI(5, _omitFieldNames ? '' : 'source')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImageLink clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImageLink copyWith(void Function(ImageLink) updates) =>
      super.copyWith((message) => updates(message as ImageLink)) as ImageLink;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ImageLink() / ImageLink.new instead')
  static ImageLink create() => ImageLink._();
  static $pb.GeneratedMessage $_createMessage() => ImageLink._();
  @$core.override
  ImageLink createEmptyInstance() => ImageLink._();
  @$core.pragma('dart2js:noInline')
  static ImageLink getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImageLink>(ImageLink.$_createMessage);
  static ImageLink? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  ItemSource get itemSource => $_getN(1);
  @$pb.TagNumber(2)
  set itemSource(ItemSource value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItemSource() => $_has(1);
  @$pb.TagNumber(2)
  void clearItemSource() => $_clearField(2);
  @$pb.TagNumber(2)
  ItemSource ensureItemSource() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get density => $_getIZ(2);
  @$pb.TagNumber(3)
  set density($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDensity() => $_has(2);
  @$pb.TagNumber(3)
  void clearDensity() => $_clearField(3);

  @$pb.TagNumber(4)
  EmbeddedAdMetadata get adMetadata => $_getN(3);
  @$pb.TagNumber(4)
  set adMetadata(EmbeddedAdMetadata value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAdMetadata() => $_has(3);
  @$pb.TagNumber(4)
  void clearAdMetadata() => $_clearField(4);
  @$pb.TagNumber(4)
  EmbeddedAdMetadata ensureAdMetadata() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.int get source => $_getIZ(4);
  @$pb.TagNumber(5)
  set source($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSource() => $_has(4);
  @$pb.TagNumber(5)
  void clearSource() => $_clearField(5);
}

/// field 4: Preview section (heading + single item reference)
class Preview extends $pb.GeneratedMessage {
  factory Preview({
    Heading? heading,
    Item? item,
  }) {
    final result = Preview._();
    if (heading != null) result.heading = heading;
    if (item != null) result.item = item;
    return result;
  }

  Preview._();

  factory Preview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Preview()..mergeFromBuffer(data, registry);
  factory Preview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Preview()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Preview',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: Preview.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<Item>(2, _omitFieldNames ? '' : 'item',
        subBuilder: Item.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Preview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Preview copyWith(void Function(Preview) updates) =>
      super.copyWith((message) => updates(message as Preview)) as Preview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Preview() / Preview.new instead')
  static Preview create() => Preview._();
  static $pb.GeneratedMessage $_createMessage() => Preview._();
  @$core.override
  Preview createEmptyInstance() => Preview._();
  @$core.pragma('dart2js:noInline')
  static Preview getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Preview>(Preview.$_createMessage);
  static Preview? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  Item get item => $_getN(1);
  @$pb.TagNumber(2)
  set item(Item value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItem() => $_has(1);
  @$pb.TagNumber(2)
  void clearItem() => $_clearField(2);
  @$pb.TagNumber(2)
  Item ensureItem() => $_ensure(1);
}

/// field 6: Full-bleed immersive preview (large hero-style card)
class ImmersivePreview extends $pb.GeneratedMessage {
  factory ImmersivePreview({
    Heading? heading,
    Item? item,
  }) {
    final result = ImmersivePreview._();
    if (heading != null) result.heading = heading;
    if (item != null) result.item = item;
    return result;
  }

  ImmersivePreview._();

  factory ImmersivePreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ImmersivePreview()..mergeFromBuffer(data, registry);
  factory ImmersivePreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ImmersivePreview()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImmersivePreview',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: ImmersivePreview.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<Item>(2, _omitFieldNames ? '' : 'item',
        subBuilder: Item.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImmersivePreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImmersivePreview copyWith(void Function(ImmersivePreview) updates) =>
      super.copyWith((message) => updates(message as ImmersivePreview))
          as ImmersivePreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ImmersivePreview() / ImmersivePreview.new instead')
  static ImmersivePreview create() => ImmersivePreview._();
  static $pb.GeneratedMessage $_createMessage() => ImmersivePreview._();
  @$core.override
  ImmersivePreview createEmptyInstance() => ImmersivePreview._();
  @$core.pragma('dart2js:noInline')
  static ImmersivePreview getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ImmersivePreview>(
          ImmersivePreview.$_createMessage);
  static ImmersivePreview? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  Item get item => $_getN(1);
  @$pb.TagNumber(2)
  set item(Item value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItem() => $_has(1);
  @$pb.TagNumber(2)
  void clearItem() => $_clearField(2);
  @$pb.TagNumber(2)
  Item ensureItem() => $_ensure(1);
}

/// field 8: Content evaluation list
class ContentEvaluationList extends $pb.GeneratedMessage {
  factory ContentEvaluationList({
    Heading? heading,
    ItemSource? itemSource,
  }) {
    final result = ContentEvaluationList._();
    if (heading != null) result.heading = heading;
    if (itemSource != null) result.itemSource = itemSource;
    return result;
  }

  ContentEvaluationList._();

  factory ContentEvaluationList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContentEvaluationList()..mergeFromBuffer(data, registry);
  factory ContentEvaluationList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContentEvaluationList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContentEvaluationList',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: ContentEvaluationList.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<ItemSource>(2, _omitFieldNames ? '' : 'itemSource',
        subBuilder: ItemSource.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContentEvaluationList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContentEvaluationList copyWith(
          void Function(ContentEvaluationList) updates) =>
      super.copyWith((message) => updates(message as ContentEvaluationList))
          as ContentEvaluationList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ContentEvaluationList() / ContentEvaluationList.new instead')
  static ContentEvaluationList create() => ContentEvaluationList._();
  static $pb.GeneratedMessage $_createMessage() => ContentEvaluationList._();
  @$core.override
  ContentEvaluationList createEmptyInstance() => ContentEvaluationList._();
  @$core.pragma('dart2js:noInline')
  static ContentEvaluationList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContentEvaluationList>(
          ContentEvaluationList.$_createMessage);
  static ContentEvaluationList? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  ItemSource get itemSource => $_getN(1);
  @$pb.TagNumber(2)
  set itemSource(ItemSource value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItemSource() => $_has(1);
  @$pb.TagNumber(2)
  void clearItemSource() => $_clearField(2);
  @$pb.TagNumber(2)
  ItemSource ensureItemSource() => $_ensure(1);
}

/// field 9: Call to action
class CallToAction extends $pb.GeneratedMessage {
  factory CallToAction({
    $core.String? title,
    $core.String? subtitle,
    $core.String? buttonText,
    $core.String? uri,
  }) {
    final result = CallToAction._();
    if (title != null) result.title = title;
    if (subtitle != null) result.subtitle = subtitle;
    if (buttonText != null) result.buttonText = buttonText;
    if (uri != null) result.uri = uri;
    return result;
  }

  CallToAction._();

  factory CallToAction.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallToAction()..mergeFromBuffer(data, registry);
  factory CallToAction.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallToAction()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CallToAction',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: CallToAction.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'subtitle')
    ..aOS(3, _omitFieldNames ? '' : 'buttonText')
    ..aOS(4, _omitFieldNames ? '' : 'uri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallToAction clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallToAction copyWith(void Function(CallToAction) updates) =>
      super.copyWith((message) => updates(message as CallToAction))
          as CallToAction;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CallToAction() / CallToAction.new instead')
  static CallToAction create() => CallToAction._();
  static $pb.GeneratedMessage $_createMessage() => CallToAction._();
  @$core.override
  CallToAction createEmptyInstance() => CallToAction._();
  @$core.pragma('dart2js:noInline')
  static CallToAction getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CallToAction>(
          CallToAction.$_createMessage);
  static CallToAction? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get subtitle => $_getSZ(1);
  @$pb.TagNumber(2)
  set subtitle($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSubtitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubtitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get buttonText => $_getSZ(2);
  @$pb.TagNumber(3)
  set buttonText($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasButtonText() => $_has(2);
  @$pb.TagNumber(3)
  void clearButtonText() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get uri => $_getSZ(3);
  @$pb.TagNumber(4)
  set uri($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUri() => $_has(3);
  @$pb.TagNumber(4)
  void clearUri() => $_clearField(4);
}

/// field 10: Recently played shelf
class RecentsShelf extends $pb.GeneratedMessage {
  factory RecentsShelf({
    Heading? heading,
    ItemSource? itemSource,
    $core.int? titleDensity,
  }) {
    final result = RecentsShelf._();
    if (heading != null) result.heading = heading;
    if (itemSource != null) result.itemSource = itemSource;
    if (titleDensity != null) result.titleDensity = titleDensity;
    return result;
  }

  RecentsShelf._();

  factory RecentsShelf.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecentsShelf()..mergeFromBuffer(data, registry);
  factory RecentsShelf.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecentsShelf()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecentsShelf',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: RecentsShelf.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<ItemSource>(2, _omitFieldNames ? '' : 'itemSource',
        subBuilder: ItemSource.$_createMessage)
    ..aI(3, _omitFieldNames ? '' : 'titleDensity')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecentsShelf clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecentsShelf copyWith(void Function(RecentsShelf) updates) =>
      super.copyWith((message) => updates(message as RecentsShelf))
          as RecentsShelf;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RecentsShelf() / RecentsShelf.new instead')
  static RecentsShelf create() => RecentsShelf._();
  static $pb.GeneratedMessage $_createMessage() => RecentsShelf._();
  @$core.override
  RecentsShelf createEmptyInstance() => RecentsShelf._();
  @$core.pragma('dart2js:noInline')
  static RecentsShelf getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RecentsShelf>(
          RecentsShelf.$_createMessage);
  static RecentsShelf? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  ItemSource get itemSource => $_getN(1);
  @$pb.TagNumber(2)
  set itemSource(ItemSource value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItemSource() => $_has(1);
  @$pb.TagNumber(2)
  void clearItemSource() => $_clearField(2);
  @$pb.TagNumber(2)
  ItemSource ensureItemSource() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get titleDensity => $_getIZ(2);
  @$pb.TagNumber(3)
  set titleDensity($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitleDensity() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitleDensity() => $_clearField(3);
}

/// field 11: Video/watch feed
class WatchFeed extends $pb.GeneratedMessage {
  factory WatchFeed({
    Heading? heading,
    ItemSource? itemSource,
  }) {
    final result = WatchFeed._();
    if (heading != null) result.heading = heading;
    if (itemSource != null) result.itemSource = itemSource;
    return result;
  }

  WatchFeed._();

  factory WatchFeed.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchFeed()..mergeFromBuffer(data, registry);
  factory WatchFeed.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchFeed()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchFeed',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: WatchFeed.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<ItemSource>(2, _omitFieldNames ? '' : 'itemSource',
        subBuilder: ItemSource.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchFeed clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchFeed copyWith(void Function(WatchFeed) updates) =>
      super.copyWith((message) => updates(message as WatchFeed)) as WatchFeed;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WatchFeed() / WatchFeed.new instead')
  static WatchFeed create() => WatchFeed._();
  static $pb.GeneratedMessage $_createMessage() => WatchFeed._();
  @$core.override
  WatchFeed createEmptyInstance() => WatchFeed._();
  @$core.pragma('dart2js:noInline')
  static WatchFeed getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchFeed>(WatchFeed.$_createMessage);
  static WatchFeed? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  ItemSource get itemSource => $_getN(1);
  @$pb.TagNumber(2)
  set itemSource(ItemSource value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItemSource() => $_has(1);
  @$pb.TagNumber(2)
  void clearItemSource() => $_clearField(2);
  @$pb.TagNumber(2)
  ItemSource ensureItemSource() => $_ensure(1);
}

/// field 16: Live event
class LiveEvent extends $pb.GeneratedMessage {
  factory LiveEvent({
    Heading? heading,
    Item? item,
  }) {
    final result = LiveEvent._();
    if (heading != null) result.heading = heading;
    if (item != null) result.item = item;
    return result;
  }

  LiveEvent._();

  factory LiveEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LiveEvent()..mergeFromBuffer(data, registry);
  factory LiveEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LiveEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveEvent',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: LiveEvent.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<Item>(2, _omitFieldNames ? '' : 'item',
        subBuilder: Item.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveEvent copyWith(void Function(LiveEvent) updates) =>
      super.copyWith((message) => updates(message as LiveEvent)) as LiveEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LiveEvent() / LiveEvent.new instead')
  static LiveEvent create() => LiveEvent._();
  static $pb.GeneratedMessage $_createMessage() => LiveEvent._();
  @$core.override
  LiveEvent createEmptyInstance() => LiveEvent._();
  @$core.pragma('dart2js:noInline')
  static LiveEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveEvent>(LiveEvent.$_createMessage);
  static LiveEvent? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  Item get item => $_getN(1);
  @$pb.TagNumber(2)
  set item(Item value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItem() => $_has(1);
  @$pb.TagNumber(2)
  void clearItem() => $_clearField(2);
  @$pb.TagNumber(2)
  Item ensureItem() => $_ensure(1);
}

/// field 17: Showcase (featured content)
class Showcase extends $pb.GeneratedMessage {
  factory Showcase({
    Heading? heading,
    Item? item,
    EmbeddedAdMetadata? adMetadata,
  }) {
    final result = Showcase._();
    if (heading != null) result.heading = heading;
    if (item != null) result.item = item;
    if (adMetadata != null) result.adMetadata = adMetadata;
    return result;
  }

  Showcase._();

  factory Showcase.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Showcase()..mergeFromBuffer(data, registry);
  factory Showcase.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Showcase()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Showcase',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: Showcase.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<Item>(2, _omitFieldNames ? '' : 'item',
        subBuilder: Item.$_createMessage)
    ..aOM<EmbeddedAdMetadata>(3, _omitFieldNames ? '' : 'adMetadata',
        subBuilder: EmbeddedAdMetadata.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Showcase clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Showcase copyWith(void Function(Showcase) updates) =>
      super.copyWith((message) => updates(message as Showcase)) as Showcase;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Showcase() / Showcase.new instead')
  static Showcase create() => Showcase._();
  static $pb.GeneratedMessage $_createMessage() => Showcase._();
  @$core.override
  Showcase createEmptyInstance() => Showcase._();
  @$core.pragma('dart2js:noInline')
  static Showcase getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Showcase>(Showcase.$_createMessage);
  static Showcase? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  Item get item => $_getN(1);
  @$pb.TagNumber(2)
  set item(Item value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItem() => $_has(1);
  @$pb.TagNumber(2)
  void clearItem() => $_clearField(2);
  @$pb.TagNumber(2)
  Item ensureItem() => $_ensure(1);

  @$pb.TagNumber(3)
  EmbeddedAdMetadata get adMetadata => $_getN(2);
  @$pb.TagNumber(3)
  set adMetadata(EmbeddedAdMetadata value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAdMetadata() => $_has(2);
  @$pb.TagNumber(3)
  void clearAdMetadata() => $_clearField(3);
  @$pb.TagNumber(3)
  EmbeddedAdMetadata ensureAdMetadata() => $_ensure(2);
}

/// field 24: Vertical single entry
class VerticalSingleEntry extends $pb.GeneratedMessage {
  factory VerticalSingleEntry({
    Heading? heading,
    Item? item,
    $core.String? targetUri,
    EmbeddedAdMetadata? adMetadata,
  }) {
    final result = VerticalSingleEntry._();
    if (heading != null) result.heading = heading;
    if (item != null) result.item = item;
    if (targetUri != null) result.targetUri = targetUri;
    if (adMetadata != null) result.adMetadata = adMetadata;
    return result;
  }

  VerticalSingleEntry._();

  factory VerticalSingleEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VerticalSingleEntry()..mergeFromBuffer(data, registry);
  factory VerticalSingleEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VerticalSingleEntry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VerticalSingleEntry',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: VerticalSingleEntry.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<Item>(2, _omitFieldNames ? '' : 'item',
        subBuilder: Item.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'targetUri')
    ..aOM<EmbeddedAdMetadata>(4, _omitFieldNames ? '' : 'adMetadata',
        subBuilder: EmbeddedAdMetadata.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VerticalSingleEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VerticalSingleEntry copyWith(void Function(VerticalSingleEntry) updates) =>
      super.copyWith((message) => updates(message as VerticalSingleEntry))
          as VerticalSingleEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use VerticalSingleEntry() / VerticalSingleEntry.new instead')
  static VerticalSingleEntry create() => VerticalSingleEntry._();
  static $pb.GeneratedMessage $_createMessage() => VerticalSingleEntry._();
  @$core.override
  VerticalSingleEntry createEmptyInstance() => VerticalSingleEntry._();
  @$core.pragma('dart2js:noInline')
  static VerticalSingleEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VerticalSingleEntry>(
          VerticalSingleEntry.$_createMessage);
  static VerticalSingleEntry? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  Item get item => $_getN(1);
  @$pb.TagNumber(2)
  set item(Item value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItem() => $_has(1);
  @$pb.TagNumber(2)
  void clearItem() => $_clearField(2);
  @$pb.TagNumber(2)
  Item ensureItem() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get targetUri => $_getSZ(2);
  @$pb.TagNumber(3)
  set targetUri($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTargetUri() => $_has(2);
  @$pb.TagNumber(3)
  void clearTargetUri() => $_clearField(3);

  @$pb.TagNumber(4)
  EmbeddedAdMetadata get adMetadata => $_getN(3);
  @$pb.TagNumber(4)
  set adMetadata(EmbeddedAdMetadata value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAdMetadata() => $_has(3);
  @$pb.TagNumber(4)
  void clearAdMetadata() => $_clearField(4);
  @$pb.TagNumber(4)
  EmbeddedAdMetadata ensureAdMetadata() => $_ensure(3);
}

/// field 25: Video carousel
class VideoCarousel extends $pb.GeneratedMessage {
  factory VideoCarousel({
    Heading? heading,
    ItemSource? itemSource,
  }) {
    final result = VideoCarousel._();
    if (heading != null) result.heading = heading;
    if (itemSource != null) result.itemSource = itemSource;
    return result;
  }

  VideoCarousel._();

  factory VideoCarousel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VideoCarousel()..mergeFromBuffer(data, registry);
  factory VideoCarousel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VideoCarousel()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VideoCarousel',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: VideoCarousel.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<ItemSource>(2, _omitFieldNames ? '' : 'itemSource',
        subBuilder: ItemSource.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VideoCarousel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VideoCarousel copyWith(void Function(VideoCarousel) updates) =>
      super.copyWith((message) => updates(message as VideoCarousel))
          as VideoCarousel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use VideoCarousel() / VideoCarousel.new instead')
  static VideoCarousel create() => VideoCarousel._();
  static $pb.GeneratedMessage $_createMessage() => VideoCarousel._();
  @$core.override
  VideoCarousel createEmptyInstance() => VideoCarousel._();
  @$core.pragma('dart2js:noInline')
  static VideoCarousel getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VideoCarousel>(
          VideoCarousel.$_createMessage);
  static VideoCarousel? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  ItemSource get itemSource => $_getN(1);
  @$pb.TagNumber(2)
  set itemSource(ItemSource value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItemSource() => $_has(1);
  @$pb.TagNumber(2)
  void clearItemSource() => $_clearField(2);
  @$pb.TagNumber(2)
  ItemSource ensureItemSource() => $_ensure(1);
}

/// field 27: Associated preview
class AssociatedPreview extends $pb.GeneratedMessage {
  factory AssociatedPreview({
    Heading? heading,
    Item? item,
  }) {
    final result = AssociatedPreview._();
    if (heading != null) result.heading = heading;
    if (item != null) result.item = item;
    return result;
  }

  AssociatedPreview._();

  factory AssociatedPreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AssociatedPreview()..mergeFromBuffer(data, registry);
  factory AssociatedPreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AssociatedPreview()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AssociatedPreview',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: AssociatedPreview.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<Item>(2, _omitFieldNames ? '' : 'item',
        subBuilder: Item.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AssociatedPreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AssociatedPreview copyWith(void Function(AssociatedPreview) updates) =>
      super.copyWith((message) => updates(message as AssociatedPreview))
          as AssociatedPreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AssociatedPreview() / AssociatedPreview.new instead')
  static AssociatedPreview create() => AssociatedPreview._();
  static $pb.GeneratedMessage $_createMessage() => AssociatedPreview._();
  @$core.override
  AssociatedPreview createEmptyInstance() => AssociatedPreview._();
  @$core.pragma('dart2js:noInline')
  static AssociatedPreview getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AssociatedPreview>(
          AssociatedPreview.$_createMessage);
  static AssociatedPreview? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  Item get item => $_getN(1);
  @$pb.TagNumber(2)
  set item(Item value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItem() => $_has(1);
  @$pb.TagNumber(2)
  void clearItem() => $_clearField(2);
  @$pb.TagNumber(2)
  Item ensureItem() => $_ensure(1);
}

/// field 29: Narrative text section
class Narrative extends $pb.GeneratedMessage {
  factory Narrative({
    $core.String? title,
    $core.String? mainText,
  }) {
    final result = Narrative._();
    if (title != null) result.title = title;
    if (mainText != null) result.mainText = mainText;
    return result;
  }

  Narrative._();

  factory Narrative.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Narrative()..mergeFromBuffer(data, registry);
  factory Narrative.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Narrative()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Narrative',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: Narrative.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'mainText')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Narrative clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Narrative copyWith(void Function(Narrative) updates) =>
      super.copyWith((message) => updates(message as Narrative)) as Narrative;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Narrative() / Narrative.new instead')
  static Narrative create() => Narrative._();
  static $pb.GeneratedMessage $_createMessage() => Narrative._();
  @$core.override
  Narrative createEmptyInstance() => Narrative._();
  @$core.pragma('dart2js:noInline')
  static Narrative getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Narrative>(Narrative.$_createMessage);
  static Narrative? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get mainText => $_getSZ(1);
  @$pb.TagNumber(2)
  set mainText($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMainText() => $_has(1);
  @$pb.TagNumber(2)
  void clearMainText() => $_clearField(2);
}

/// field 30: Interactive entrypoint
class InteractiveEntrypoint extends $pb.GeneratedMessage {
  factory InteractiveEntrypoint({
    Heading? heading,
    Item? item,
  }) {
    final result = InteractiveEntrypoint._();
    if (heading != null) result.heading = heading;
    if (item != null) result.item = item;
    return result;
  }

  InteractiveEntrypoint._();

  factory InteractiveEntrypoint.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InteractiveEntrypoint()..mergeFromBuffer(data, registry);
  factory InteractiveEntrypoint.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InteractiveEntrypoint()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InteractiveEntrypoint',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: InteractiveEntrypoint.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<Item>(2, _omitFieldNames ? '' : 'item',
        subBuilder: Item.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InteractiveEntrypoint clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InteractiveEntrypoint copyWith(
          void Function(InteractiveEntrypoint) updates) =>
      super.copyWith((message) => updates(message as InteractiveEntrypoint))
          as InteractiveEntrypoint;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use InteractiveEntrypoint() / InteractiveEntrypoint.new instead')
  static InteractiveEntrypoint create() => InteractiveEntrypoint._();
  static $pb.GeneratedMessage $_createMessage() => InteractiveEntrypoint._();
  @$core.override
  InteractiveEntrypoint createEmptyInstance() => InteractiveEntrypoint._();
  @$core.pragma('dart2js:noInline')
  static InteractiveEntrypoint getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InteractiveEntrypoint>(
          InteractiveEntrypoint.$_createMessage);
  static InteractiveEntrypoint? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  Item get item => $_getN(1);
  @$pb.TagNumber(2)
  set item(Item value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItem() => $_has(1);
  @$pb.TagNumber(2)
  void clearItem() => $_clearField(2);
  @$pb.TagNumber(2)
  Item ensureItem() => $_ensure(1);
}

/// field 31: Top story carousel
class TopStoryCarousel extends $pb.GeneratedMessage {
  factory TopStoryCarousel({
    Heading? heading,
    $core.Iterable<Item>? items,
  }) {
    final result = TopStoryCarousel._();
    if (heading != null) result.heading = heading;
    if (items != null) result.items.addAll(items);
    return result;
  }

  TopStoryCarousel._();

  factory TopStoryCarousel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TopStoryCarousel()..mergeFromBuffer(data, registry);
  factory TopStoryCarousel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TopStoryCarousel()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TopStoryCarousel',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: TopStoryCarousel.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..pPM<Item>(2, _omitFieldNames ? '' : 'items',
        subBuilder: Item.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TopStoryCarousel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TopStoryCarousel copyWith(void Function(TopStoryCarousel) updates) =>
      super.copyWith((message) => updates(message as TopStoryCarousel))
          as TopStoryCarousel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TopStoryCarousel() / TopStoryCarousel.new instead')
  static TopStoryCarousel create() => TopStoryCarousel._();
  static $pb.GeneratedMessage $_createMessage() => TopStoryCarousel._();
  @$core.override
  TopStoryCarousel createEmptyInstance() => TopStoryCarousel._();
  @$core.pragma('dart2js:noInline')
  static TopStoryCarousel getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TopStoryCarousel>(
          TopStoryCarousel.$_createMessage);
  static TopStoryCarousel? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<Item> get items => $_getList(1);
}

/// field 33: Audio promo
class AudioPromo extends $pb.GeneratedMessage {
  factory AudioPromo({
    Heading? heading,
    Item? item,
  }) {
    final result = AudioPromo._();
    if (heading != null) result.heading = heading;
    if (item != null) result.item = item;
    return result;
  }

  AudioPromo._();

  factory AudioPromo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioPromo()..mergeFromBuffer(data, registry);
  factory AudioPromo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioPromo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioPromo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: AudioPromo.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<Item>(2, _omitFieldNames ? '' : 'item',
        subBuilder: Item.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioPromo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioPromo copyWith(void Function(AudioPromo) updates) =>
      super.copyWith((message) => updates(message as AudioPromo)) as AudioPromo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AudioPromo() / AudioPromo.new instead')
  static AudioPromo create() => AudioPromo._();
  static $pb.GeneratedMessage $_createMessage() => AudioPromo._();
  @$core.override
  AudioPromo createEmptyInstance() => AudioPromo._();
  @$core.pragma('dart2js:noInline')
  static AudioPromo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioPromo>(AudioPromo.$_createMessage);
  static AudioPromo? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  Item get item => $_getN(1);
  @$pb.TagNumber(2)
  set item(Item value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItem() => $_has(1);
  @$pb.TagNumber(2)
  void clearItem() => $_clearField(2);
  @$pb.TagNumber(2)
  Item ensureItem() => $_ensure(1);
}

/// field 34: Inline card
class InlineCard extends $pb.GeneratedMessage {
  factory InlineCard({
    Heading? heading,
    Item? item,
  }) {
    final result = InlineCard._();
    if (heading != null) result.heading = heading;
    if (item != null) result.item = item;
    return result;
  }

  InlineCard._();

  factory InlineCard.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InlineCard()..mergeFromBuffer(data, registry);
  factory InlineCard.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InlineCard()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InlineCard',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: InlineCard.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<Item>(2, _omitFieldNames ? '' : 'item',
        subBuilder: Item.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InlineCard clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InlineCard copyWith(void Function(InlineCard) updates) =>
      super.copyWith((message) => updates(message as InlineCard)) as InlineCard;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use InlineCard() / InlineCard.new instead')
  static InlineCard create() => InlineCard._();
  static $pb.GeneratedMessage $_createMessage() => InlineCard._();
  @$core.override
  InlineCard createEmptyInstance() => InlineCard._();
  @$core.pragma('dart2js:noInline')
  static InlineCard getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InlineCard>(InlineCard.$_createMessage);
  static InlineCard? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  Item get item => $_getN(1);
  @$pb.TagNumber(2)
  set item(Item value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItem() => $_has(1);
  @$pb.TagNumber(2)
  void clearItem() => $_clearField(2);
  @$pb.TagNumber(2)
  Item ensureItem() => $_ensure(1);
}

/// field 36: Audio spotlight
class AudioSpotlight extends $pb.GeneratedMessage {
  factory AudioSpotlight({
    Heading? heading,
    Item? item,
    EmbeddedAdMetadata? adMetadata,
    $core.String? previewEntityUri,
  }) {
    final result = AudioSpotlight._();
    if (heading != null) result.heading = heading;
    if (item != null) result.item = item;
    if (adMetadata != null) result.adMetadata = adMetadata;
    if (previewEntityUri != null) result.previewEntityUri = previewEntityUri;
    return result;
  }

  AudioSpotlight._();

  factory AudioSpotlight.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioSpotlight()..mergeFromBuffer(data, registry);
  factory AudioSpotlight.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioSpotlight()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioSpotlight',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: AudioSpotlight.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<Item>(2, _omitFieldNames ? '' : 'item',
        subBuilder: Item.$_createMessage)
    ..aOM<EmbeddedAdMetadata>(3, _omitFieldNames ? '' : 'adMetadata',
        subBuilder: EmbeddedAdMetadata.$_createMessage)
    ..aOS(4, _omitFieldNames ? '' : 'previewEntityUri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioSpotlight clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioSpotlight copyWith(void Function(AudioSpotlight) updates) =>
      super.copyWith((message) => updates(message as AudioSpotlight))
          as AudioSpotlight;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AudioSpotlight() / AudioSpotlight.new instead')
  static AudioSpotlight create() => AudioSpotlight._();
  static $pb.GeneratedMessage $_createMessage() => AudioSpotlight._();
  @$core.override
  AudioSpotlight createEmptyInstance() => AudioSpotlight._();
  @$core.pragma('dart2js:noInline')
  static AudioSpotlight getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AudioSpotlight>(
          AudioSpotlight.$_createMessage);
  static AudioSpotlight? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  Item get item => $_getN(1);
  @$pb.TagNumber(2)
  set item(Item value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItem() => $_has(1);
  @$pb.TagNumber(2)
  void clearItem() => $_clearField(2);
  @$pb.TagNumber(2)
  Item ensureItem() => $_ensure(1);

  @$pb.TagNumber(3)
  EmbeddedAdMetadata get adMetadata => $_getN(2);
  @$pb.TagNumber(3)
  set adMetadata(EmbeddedAdMetadata value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAdMetadata() => $_has(2);
  @$pb.TagNumber(3)
  void clearAdMetadata() => $_clearField(3);
  @$pb.TagNumber(3)
  EmbeddedAdMetadata ensureAdMetadata() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get previewEntityUri => $_getSZ(3);
  @$pb.TagNumber(4)
  set previewEntityUri($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPreviewEntityUri() => $_has(3);
  @$pb.TagNumber(4)
  void clearPreviewEntityUri() => $_clearField(4);
}

/// field 37: Preview carousel (large preview cards with repeated items)
class PreviewCarousel extends $pb.GeneratedMessage {
  factory PreviewCarousel({
    Heading? heading,
    $core.Iterable<Item>? items,
  }) {
    final result = PreviewCarousel._();
    if (heading != null) result.heading = heading;
    if (items != null) result.items.addAll(items);
    return result;
  }

  PreviewCarousel._();

  factory PreviewCarousel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewCarousel()..mergeFromBuffer(data, registry);
  factory PreviewCarousel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewCarousel()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewCarousel',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: PreviewCarousel.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..pPM<Item>(2, _omitFieldNames ? '' : 'items',
        subBuilder: Item.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewCarousel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewCarousel copyWith(void Function(PreviewCarousel) updates) =>
      super.copyWith((message) => updates(message as PreviewCarousel))
          as PreviewCarousel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PreviewCarousel() / PreviewCarousel.new instead')
  static PreviewCarousel create() => PreviewCarousel._();
  static $pb.GeneratedMessage $_createMessage() => PreviewCarousel._();
  @$core.override
  PreviewCarousel createEmptyInstance() => PreviewCarousel._();
  @$core.pragma('dart2js:noInline')
  static PreviewCarousel getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PreviewCarousel>(
          PreviewCarousel.$_createMessage);
  static PreviewCarousel? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<Item> get items => $_getList(1);
}

/// field 39: Preview promotion carousel
class PreviewPromotionCarousel extends $pb.GeneratedMessage {
  factory PreviewPromotionCarousel({
    Heading? heading,
    $core.Iterable<PreviewPromotionCarouselItem>? items,
  }) {
    final result = PreviewPromotionCarousel._();
    if (heading != null) result.heading = heading;
    if (items != null) result.items.addAll(items);
    return result;
  }

  PreviewPromotionCarousel._();

  factory PreviewPromotionCarousel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewPromotionCarousel()..mergeFromBuffer(data, registry);
  factory PreviewPromotionCarousel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewPromotionCarousel()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewPromotionCarousel',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: PreviewPromotionCarousel.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..pPM<PreviewPromotionCarouselItem>(2, _omitFieldNames ? '' : 'items',
        subBuilder: PreviewPromotionCarouselItem.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewPromotionCarousel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewPromotionCarousel copyWith(
          void Function(PreviewPromotionCarousel) updates) =>
      super.copyWith((message) => updates(message as PreviewPromotionCarousel))
          as PreviewPromotionCarousel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PreviewPromotionCarousel() / PreviewPromotionCarousel.new instead')
  static PreviewPromotionCarousel create() => PreviewPromotionCarousel._();
  static $pb.GeneratedMessage $_createMessage() => PreviewPromotionCarousel._();
  @$core.override
  PreviewPromotionCarousel createEmptyInstance() =>
      PreviewPromotionCarousel._();
  @$core.pragma('dart2js:noInline')
  static PreviewPromotionCarousel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewPromotionCarousel>(
          PreviewPromotionCarousel.$_createMessage);
  static PreviewPromotionCarousel? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<PreviewPromotionCarouselItem> get items => $_getList(1);
}

class PreviewPromotionCarouselItem extends $pb.GeneratedMessage {
  factory PreviewPromotionCarouselItem({
    Item? item,
  }) {
    final result = PreviewPromotionCarouselItem._();
    if (item != null) result.item = item;
    return result;
  }

  PreviewPromotionCarouselItem._();

  factory PreviewPromotionCarouselItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewPromotionCarouselItem()..mergeFromBuffer(data, registry);
  factory PreviewPromotionCarouselItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewPromotionCarouselItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewPromotionCarouselItem',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: PreviewPromotionCarouselItem.$_createMessage)
    ..aOM<Item>(1, _omitFieldNames ? '' : 'item',
        subBuilder: Item.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewPromotionCarouselItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewPromotionCarouselItem copyWith(
          void Function(PreviewPromotionCarouselItem) updates) =>
      super.copyWith(
              (message) => updates(message as PreviewPromotionCarouselItem))
          as PreviewPromotionCarouselItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PreviewPromotionCarouselItem() / PreviewPromotionCarouselItem.new instead')
  static PreviewPromotionCarouselItem create() =>
      PreviewPromotionCarouselItem._();
  static $pb.GeneratedMessage $_createMessage() =>
      PreviewPromotionCarouselItem._();
  @$core.override
  PreviewPromotionCarouselItem createEmptyInstance() =>
      PreviewPromotionCarouselItem._();
  @$core.pragma('dart2js:noInline')
  static PreviewPromotionCarouselItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewPromotionCarouselItem>(
          PreviewPromotionCarouselItem.$_createMessage);
  static PreviewPromotionCarouselItem? _defaultInstance;

  @$pb.TagNumber(1)
  Item get item => $_getN(0);
  @$pb.TagNumber(1)
  set item(Item value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasItem() => $_has(0);
  @$pb.TagNumber(1)
  void clearItem() => $_clearField(1);
  @$pb.TagNumber(1)
  Item ensureItem() => $_ensure(0);
}

/// field 41: Reflection
class Reflection extends $pb.GeneratedMessage {
  factory Reflection({
    Heading? heading,
    Item? item,
  }) {
    final result = Reflection._();
    if (heading != null) result.heading = heading;
    if (item != null) result.item = item;
    return result;
  }

  Reflection._();

  factory Reflection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Reflection()..mergeFromBuffer(data, registry);
  factory Reflection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Reflection()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Reflection',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: Reflection.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..aOM<Item>(2, _omitFieldNames ? '' : 'item',
        subBuilder: Item.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Reflection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Reflection copyWith(void Function(Reflection) updates) =>
      super.copyWith((message) => updates(message as Reflection)) as Reflection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Reflection() / Reflection.new instead')
  static Reflection create() => Reflection._();
  static $pb.GeneratedMessage $_createMessage() => Reflection._();
  @$core.override
  Reflection createEmptyInstance() => Reflection._();
  @$core.pragma('dart2js:noInline')
  static Reflection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Reflection>(Reflection.$_createMessage);
  static Reflection? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  Item get item => $_getN(1);
  @$pb.TagNumber(2)
  set item(Item value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasItem() => $_has(1);
  @$pb.TagNumber(2)
  void clearItem() => $_clearField(2);
  @$pb.TagNumber(2)
  Item ensureItem() => $_ensure(1);
}

class EmbeddedAdMetadata extends $pb.GeneratedMessage {
  factory EmbeddedAdMetadata({
    $core.String? trackingId,
  }) {
    final result = EmbeddedAdMetadata._();
    if (trackingId != null) result.trackingId = trackingId;
    return result;
  }

  EmbeddedAdMetadata._();

  factory EmbeddedAdMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EmbeddedAdMetadata()..mergeFromBuffer(data, registry);
  factory EmbeddedAdMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EmbeddedAdMetadata()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EmbeddedAdMetadata',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.casita.v1.resolved'),
      createEmptyInstance: EmbeddedAdMetadata.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'trackingId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EmbeddedAdMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EmbeddedAdMetadata copyWith(void Function(EmbeddedAdMetadata) updates) =>
      super.copyWith((message) => updates(message as EmbeddedAdMetadata))
          as EmbeddedAdMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EmbeddedAdMetadata() / EmbeddedAdMetadata.new instead')
  static EmbeddedAdMetadata create() => EmbeddedAdMetadata._();
  static $pb.GeneratedMessage $_createMessage() => EmbeddedAdMetadata._();
  @$core.override
  EmbeddedAdMetadata createEmptyInstance() => EmbeddedAdMetadata._();
  @$core.pragma('dart2js:noInline')
  static EmbeddedAdMetadata getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EmbeddedAdMetadata>(
          EmbeddedAdMetadata.$_createMessage);
  static EmbeddedAdMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get trackingId => $_getSZ(0);
  @$pb.TagNumber(1)
  set trackingId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTrackingId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTrackingId() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
