// This is a generated file - do not edit.
//
// Generated from spotify/browsita/resolved.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ResolvedBrowse extends $pb.GeneratedMessage {
  factory ResolvedBrowse({
    BrowseStructure? structure,
    ResponseInfo? responseInfo,
  }) {
    final result = ResolvedBrowse._();
    if (structure != null) result.structure = structure;
    if (responseInfo != null) result.responseInfo = responseInfo;
    return result;
  }

  ResolvedBrowse._();

  factory ResolvedBrowse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResolvedBrowse()..mergeFromBuffer(data, registry);
  factory ResolvedBrowse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResolvedBrowse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResolvedBrowse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: ResolvedBrowse.$_createMessage)
    ..aOM<BrowseStructure>(1, _omitFieldNames ? '' : 'structure',
        subBuilder: BrowseStructure.$_createMessage)
    ..aOM<ResponseInfo>(2, _omitFieldNames ? '' : 'responseInfo',
        subBuilder: ResponseInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolvedBrowse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolvedBrowse copyWith(void Function(ResolvedBrowse) updates) =>
      super.copyWith((message) => updates(message as ResolvedBrowse))
          as ResolvedBrowse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResolvedBrowse() / ResolvedBrowse.new instead')
  static ResolvedBrowse create() => ResolvedBrowse._();
  static $pb.GeneratedMessage $_createMessage() => ResolvedBrowse._();
  @$core.override
  ResolvedBrowse createEmptyInstance() => ResolvedBrowse._();
  @$core.pragma('dart2js:noInline')
  static ResolvedBrowse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedBrowse>(
          ResolvedBrowse.$_createMessage);
  static ResolvedBrowse? _defaultInstance;

  @$pb.TagNumber(1)
  BrowseStructure get structure => $_getN(0);
  @$pb.TagNumber(1)
  set structure(BrowseStructure value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStructure() => $_has(0);
  @$pb.TagNumber(1)
  void clearStructure() => $_clearField(1);
  @$pb.TagNumber(1)
  BrowseStructure ensureStructure() => $_ensure(0);

  @$pb.TagNumber(2)
  ResponseInfo get responseInfo => $_getN(1);
  @$pb.TagNumber(2)
  set responseInfo(ResponseInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasResponseInfo() => $_has(1);
  @$pb.TagNumber(2)
  void clearResponseInfo() => $_clearField(2);
  @$pb.TagNumber(2)
  ResponseInfo ensureResponseInfo() => $_ensure(1);
}

class BrowseStructure extends $pb.GeneratedMessage {
  factory BrowseStructure({
    $core.Iterable<Section>? sections,
  }) {
    final result = BrowseStructure._();
    if (sections != null) result.sections.addAll(sections);
    return result;
  }

  BrowseStructure._();

  factory BrowseStructure.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BrowseStructure()..mergeFromBuffer(data, registry);
  factory BrowseStructure.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BrowseStructure()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BrowseStructure',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: BrowseStructure.$_createMessage)
    ..pPM<Section>(1, _omitFieldNames ? '' : 'sections',
        subBuilder: Section.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BrowseStructure clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BrowseStructure copyWith(void Function(BrowseStructure) updates) =>
      super.copyWith((message) => updates(message as BrowseStructure))
          as BrowseStructure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BrowseStructure() / BrowseStructure.new instead')
  static BrowseStructure create() => BrowseStructure._();
  static $pb.GeneratedMessage $_createMessage() => BrowseStructure._();
  @$core.override
  BrowseStructure createEmptyInstance() => BrowseStructure._();
  @$core.pragma('dart2js:noInline')
  static BrowseStructure getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BrowseStructure>(
          BrowseStructure.$_createMessage);
  static BrowseStructure? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Section> get sections => $_getList(0);
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
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
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

enum Section_FeatureType {
  contentCategory,
  promotionV1,
  watchFeed,
  promotionV3,
  brandAds,
  showcase,
  audioPromo,
  playLinkPromo,
  previewPromotionCarousel,
  videoPromo,
  audioSpotlight,
  notSet
}

class Section extends $pb.GeneratedMessage {
  factory Section({
    SectionInfo? sectionInfo,
    ContentCategory? contentCategory,
    PromotionV1? promotionV1,
    WatchFeed? watchFeed,
    PromotionV3? promotionV3,
    BrandAds? brandAds,
    Showcase? showcase,
    AudioPromo? audioPromo,
    PlayLinkPromo? playLinkPromo,
    PreviewPromotionCarousel? previewPromotionCarousel,
    VideoPromo? videoPromo,
    AudioSpotlight? audioSpotlight,
  }) {
    final result = Section._();
    if (sectionInfo != null) result.sectionInfo = sectionInfo;
    if (contentCategory != null) result.contentCategory = contentCategory;
    if (promotionV1 != null) result.promotionV1 = promotionV1;
    if (watchFeed != null) result.watchFeed = watchFeed;
    if (promotionV3 != null) result.promotionV3 = promotionV3;
    if (brandAds != null) result.brandAds = brandAds;
    if (showcase != null) result.showcase = showcase;
    if (audioPromo != null) result.audioPromo = audioPromo;
    if (playLinkPromo != null) result.playLinkPromo = playLinkPromo;
    if (previewPromotionCarousel != null)
      result.previewPromotionCarousel = previewPromotionCarousel;
    if (videoPromo != null) result.videoPromo = videoPromo;
    if (audioSpotlight != null) result.audioSpotlight = audioSpotlight;
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
    2: Section_FeatureType.contentCategory,
    3: Section_FeatureType.promotionV1,
    4: Section_FeatureType.watchFeed,
    5: Section_FeatureType.promotionV3,
    6: Section_FeatureType.brandAds,
    7: Section_FeatureType.showcase,
    8: Section_FeatureType.audioPromo,
    9: Section_FeatureType.playLinkPromo,
    10: Section_FeatureType.previewPromotionCarousel,
    11: Section_FeatureType.videoPromo,
    12: Section_FeatureType.audioSpotlight,
    0: Section_FeatureType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Section',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: Section.$_createMessage)
    ..oo(0, [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
    ..aOM<SectionInfo>(1, _omitFieldNames ? '' : 'sectionInfo',
        subBuilder: SectionInfo.$_createMessage)
    ..aOM<ContentCategory>(2, _omitFieldNames ? '' : 'contentCategory',
        subBuilder: ContentCategory.$_createMessage)
    ..aOM<PromotionV1>(3, _omitFieldNames ? '' : 'promotionV1',
        subBuilder: PromotionV1.$_createMessage)
    ..aOM<WatchFeed>(4, _omitFieldNames ? '' : 'watchFeed',
        subBuilder: WatchFeed.$_createMessage)
    ..aOM<PromotionV3>(5, _omitFieldNames ? '' : 'promotionV3',
        subBuilder: PromotionV3.$_createMessage)
    ..aOM<BrandAds>(6, _omitFieldNames ? '' : 'brandAds',
        subBuilder: BrandAds.$_createMessage)
    ..aOM<Showcase>(7, _omitFieldNames ? '' : 'showcase',
        subBuilder: Showcase.$_createMessage)
    ..aOM<AudioPromo>(8, _omitFieldNames ? '' : 'audioPromo',
        subBuilder: AudioPromo.$_createMessage)
    ..aOM<PlayLinkPromo>(9, _omitFieldNames ? '' : 'playLinkPromo',
        subBuilder: PlayLinkPromo.$_createMessage)
    ..aOM<PreviewPromotionCarousel>(
        10, _omitFieldNames ? '' : 'previewPromotionCarousel',
        subBuilder: PreviewPromotionCarousel.$_createMessage)
    ..aOM<VideoPromo>(11, _omitFieldNames ? '' : 'videoPromo',
        subBuilder: VideoPromo.$_createMessage)
    ..aOM<AudioSpotlight>(12, _omitFieldNames ? '' : 'audioSpotlight',
        subBuilder: AudioSpotlight.$_createMessage)
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
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  Section_FeatureType whichFeatureType() =>
      _Section_FeatureTypeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
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
  ContentCategory get contentCategory => $_getN(1);
  @$pb.TagNumber(2)
  set contentCategory(ContentCategory value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasContentCategory() => $_has(1);
  @$pb.TagNumber(2)
  void clearContentCategory() => $_clearField(2);
  @$pb.TagNumber(2)
  ContentCategory ensureContentCategory() => $_ensure(1);

  @$pb.TagNumber(3)
  PromotionV1 get promotionV1 => $_getN(2);
  @$pb.TagNumber(3)
  set promotionV1(PromotionV1 value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPromotionV1() => $_has(2);
  @$pb.TagNumber(3)
  void clearPromotionV1() => $_clearField(3);
  @$pb.TagNumber(3)
  PromotionV1 ensurePromotionV1() => $_ensure(2);

  @$pb.TagNumber(4)
  WatchFeed get watchFeed => $_getN(3);
  @$pb.TagNumber(4)
  set watchFeed(WatchFeed value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasWatchFeed() => $_has(3);
  @$pb.TagNumber(4)
  void clearWatchFeed() => $_clearField(4);
  @$pb.TagNumber(4)
  WatchFeed ensureWatchFeed() => $_ensure(3);

  @$pb.TagNumber(5)
  PromotionV3 get promotionV3 => $_getN(4);
  @$pb.TagNumber(5)
  set promotionV3(PromotionV3 value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPromotionV3() => $_has(4);
  @$pb.TagNumber(5)
  void clearPromotionV3() => $_clearField(5);
  @$pb.TagNumber(5)
  PromotionV3 ensurePromotionV3() => $_ensure(4);

  @$pb.TagNumber(6)
  BrandAds get brandAds => $_getN(5);
  @$pb.TagNumber(6)
  set brandAds(BrandAds value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasBrandAds() => $_has(5);
  @$pb.TagNumber(6)
  void clearBrandAds() => $_clearField(6);
  @$pb.TagNumber(6)
  BrandAds ensureBrandAds() => $_ensure(5);

  @$pb.TagNumber(7)
  Showcase get showcase => $_getN(6);
  @$pb.TagNumber(7)
  set showcase(Showcase value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasShowcase() => $_has(6);
  @$pb.TagNumber(7)
  void clearShowcase() => $_clearField(7);
  @$pb.TagNumber(7)
  Showcase ensureShowcase() => $_ensure(6);

  @$pb.TagNumber(8)
  AudioPromo get audioPromo => $_getN(7);
  @$pb.TagNumber(8)
  set audioPromo(AudioPromo value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasAudioPromo() => $_has(7);
  @$pb.TagNumber(8)
  void clearAudioPromo() => $_clearField(8);
  @$pb.TagNumber(8)
  AudioPromo ensureAudioPromo() => $_ensure(7);

  @$pb.TagNumber(9)
  PlayLinkPromo get playLinkPromo => $_getN(8);
  @$pb.TagNumber(9)
  set playLinkPromo(PlayLinkPromo value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasPlayLinkPromo() => $_has(8);
  @$pb.TagNumber(9)
  void clearPlayLinkPromo() => $_clearField(9);
  @$pb.TagNumber(9)
  PlayLinkPromo ensurePlayLinkPromo() => $_ensure(8);

  @$pb.TagNumber(10)
  PreviewPromotionCarousel get previewPromotionCarousel => $_getN(9);
  @$pb.TagNumber(10)
  set previewPromotionCarousel(PreviewPromotionCarousel value) =>
      $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasPreviewPromotionCarousel() => $_has(9);
  @$pb.TagNumber(10)
  void clearPreviewPromotionCarousel() => $_clearField(10);
  @$pb.TagNumber(10)
  PreviewPromotionCarousel ensurePreviewPromotionCarousel() => $_ensure(9);

  @$pb.TagNumber(11)
  VideoPromo get videoPromo => $_getN(10);
  @$pb.TagNumber(11)
  set videoPromo(VideoPromo value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasVideoPromo() => $_has(10);
  @$pb.TagNumber(11)
  void clearVideoPromo() => $_clearField(11);
  @$pb.TagNumber(11)
  VideoPromo ensureVideoPromo() => $_ensure(10);

  @$pb.TagNumber(12)
  AudioSpotlight get audioSpotlight => $_getN(11);
  @$pb.TagNumber(12)
  set audioSpotlight(AudioSpotlight value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasAudioSpotlight() => $_has(11);
  @$pb.TagNumber(12)
  void clearAudioSpotlight() => $_clearField(12);
  @$pb.TagNumber(12)
  AudioSpotlight ensureAudioSpotlight() => $_ensure(11);
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
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
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

class ContentCategory extends $pb.GeneratedMessage {
  factory ContentCategory({
    Heading? heading,
    $core.Iterable<Item>? items,
    DensityConfig? density,
  }) {
    final result = ContentCategory._();
    if (heading != null) result.heading = heading;
    if (items != null) result.items.addAll(items);
    if (density != null) result.density = density;
    return result;
  }

  ContentCategory._();

  factory ContentCategory.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContentCategory()..mergeFromBuffer(data, registry);
  factory ContentCategory.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContentCategory()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContentCategory',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: ContentCategory.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..pPM<Item>(2, _omitFieldNames ? '' : 'items',
        subBuilder: Item.$_createMessage)
    ..aOM<DensityConfig>(3, _omitFieldNames ? '' : 'density',
        subBuilder: DensityConfig.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContentCategory clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContentCategory copyWith(void Function(ContentCategory) updates) =>
      super.copyWith((message) => updates(message as ContentCategory))
          as ContentCategory;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ContentCategory() / ContentCategory.new instead')
  static ContentCategory create() => ContentCategory._();
  static $pb.GeneratedMessage $_createMessage() => ContentCategory._();
  @$core.override
  ContentCategory createEmptyInstance() => ContentCategory._();
  @$core.pragma('dart2js:noInline')
  static ContentCategory getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ContentCategory>(
          ContentCategory.$_createMessage);
  static ContentCategory? _defaultInstance;

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

  @$pb.TagNumber(3)
  DensityConfig get density => $_getN(2);
  @$pb.TagNumber(3)
  set density(DensityConfig value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDensity() => $_has(2);
  @$pb.TagNumber(3)
  void clearDensity() => $_clearField(3);
  @$pb.TagNumber(3)
  DensityConfig ensureDensity() => $_ensure(2);
}

enum Heading_HeadingType { textHeading, sponsoredHeading, notSet }

class Heading extends $pb.GeneratedMessage {
  factory Heading({
    TextHeading? textHeading,
    SponsoredHeading? sponsoredHeading,
  }) {
    final result = Heading._();
    if (textHeading != null) result.textHeading = textHeading;
    if (sponsoredHeading != null) result.sponsoredHeading = sponsoredHeading;
    return result;
  }

  Heading._();

  factory Heading.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Heading()..mergeFromBuffer(data, registry);
  factory Heading.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Heading()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Heading_HeadingType>
      _Heading_HeadingTypeByTag = {
    1: Heading_HeadingType.textHeading,
    2: Heading_HeadingType.sponsoredHeading,
    0: Heading_HeadingType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Heading',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: Heading.$_createMessage)
    ..oo(0, [1, 2])
    ..aOM<TextHeading>(1, _omitFieldNames ? '' : 'textHeading',
        subBuilder: TextHeading.$_createMessage)
    ..aOM<SponsoredHeading>(2, _omitFieldNames ? '' : 'sponsoredHeading',
        subBuilder: SponsoredHeading.$_createMessage)
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
  Heading_HeadingType whichHeadingType() =>
      _Heading_HeadingTypeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearHeadingType() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  TextHeading get textHeading => $_getN(0);
  @$pb.TagNumber(1)
  set textHeading(TextHeading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTextHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearTextHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  TextHeading ensureTextHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  SponsoredHeading get sponsoredHeading => $_getN(1);
  @$pb.TagNumber(2)
  set sponsoredHeading(SponsoredHeading value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSponsoredHeading() => $_has(1);
  @$pb.TagNumber(2)
  void clearSponsoredHeading() => $_clearField(2);
  @$pb.TagNumber(2)
  SponsoredHeading ensureSponsoredHeading() => $_ensure(1);
}

class TextHeading extends $pb.GeneratedMessage {
  factory TextHeading({
    $core.String? text,
    NavigationAction? navigationAction,
    $core.String? encoreIconName,
  }) {
    final result = TextHeading._();
    if (text != null) result.text = text;
    if (navigationAction != null) result.navigationAction = navigationAction;
    if (encoreIconName != null) result.encoreIconName = encoreIconName;
    return result;
  }

  TextHeading._();

  factory TextHeading.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TextHeading()..mergeFromBuffer(data, registry);
  factory TextHeading.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TextHeading()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TextHeading',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: TextHeading.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOM<NavigationAction>(2, _omitFieldNames ? '' : 'navigationAction',
        subBuilder: NavigationAction.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'encoreIconName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextHeading clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextHeading copyWith(void Function(TextHeading) updates) =>
      super.copyWith((message) => updates(message as TextHeading))
          as TextHeading;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TextHeading() / TextHeading.new instead')
  static TextHeading create() => TextHeading._();
  static $pb.GeneratedMessage $_createMessage() => TextHeading._();
  @$core.override
  TextHeading createEmptyInstance() => TextHeading._();
  @$core.pragma('dart2js:noInline')
  static TextHeading getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TextHeading>(
          TextHeading.$_createMessage);
  static TextHeading? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  @$pb.TagNumber(2)
  NavigationAction get navigationAction => $_getN(1);
  @$pb.TagNumber(2)
  set navigationAction(NavigationAction value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasNavigationAction() => $_has(1);
  @$pb.TagNumber(2)
  void clearNavigationAction() => $_clearField(2);
  @$pb.TagNumber(2)
  NavigationAction ensureNavigationAction() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get encoreIconName => $_getSZ(2);
  @$pb.TagNumber(3)
  set encoreIconName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEncoreIconName() => $_has(2);
  @$pb.TagNumber(3)
  void clearEncoreIconName() => $_clearField(3);
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
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
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

class NavigationAction extends $pb.GeneratedMessage {
  factory NavigationAction({
    $core.String? uri,
  }) {
    final result = NavigationAction._();
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
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: NavigationAction.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
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
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearUri() => $_clearField(1);
}

class DensityConfig extends $pb.GeneratedMessage {
  factory DensityConfig() => DensityConfig._();

  DensityConfig._();

  factory DensityConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DensityConfig()..mergeFromBuffer(data, registry);
  factory DensityConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DensityConfig()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DensityConfig',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: DensityConfig.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DensityConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DensityConfig copyWith(void Function(DensityConfig) updates) =>
      super.copyWith((message) => updates(message as DensityConfig))
          as DensityConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DensityConfig() / DensityConfig.new instead')
  static DensityConfig create() => DensityConfig._();
  static $pb.GeneratedMessage $_createMessage() => DensityConfig._();
  @$core.override
  DensityConfig createEmptyInstance() => DensityConfig._();
  @$core.pragma('dart2js:noInline')
  static DensityConfig getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DensityConfig>(
          DensityConfig.$_createMessage);
  static DensityConfig? _defaultInstance;
}

class Item extends $pb.GeneratedMessage {
  factory Item({
    $core.String? uri,
    $core.String? targetUri,
  }) {
    final result = Item._();
    if (uri != null) result.uri = uri;
    if (targetUri != null) result.targetUri = targetUri;
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
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: Item.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
    ..aOS(2, _omitFieldNames ? '' : 'targetUri')
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
  $core.String get targetUri => $_getSZ(1);
  @$pb.TagNumber(2)
  set targetUri($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTargetUri() => $_has(1);
  @$pb.TagNumber(2)
  void clearTargetUri() => $_clearField(2);
}

class PromotionV1 extends $pb.GeneratedMessage {
  factory PromotionV1() => PromotionV1._();

  PromotionV1._();

  factory PromotionV1.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromotionV1()..mergeFromBuffer(data, registry);
  factory PromotionV1.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromotionV1()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PromotionV1',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: PromotionV1.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromotionV1 clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromotionV1 copyWith(void Function(PromotionV1) updates) =>
      super.copyWith((message) => updates(message as PromotionV1))
          as PromotionV1;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PromotionV1() / PromotionV1.new instead')
  static PromotionV1 create() => PromotionV1._();
  static $pb.GeneratedMessage $_createMessage() => PromotionV1._();
  @$core.override
  PromotionV1 createEmptyInstance() => PromotionV1._();
  @$core.pragma('dart2js:noInline')
  static PromotionV1 getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PromotionV1>(
          PromotionV1.$_createMessage);
  static PromotionV1? _defaultInstance;
}

class PromotionV3 extends $pb.GeneratedMessage {
  factory PromotionV3() => PromotionV3._();

  PromotionV3._();

  factory PromotionV3.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromotionV3()..mergeFromBuffer(data, registry);
  factory PromotionV3.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromotionV3()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PromotionV3',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: PromotionV3.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromotionV3 clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromotionV3 copyWith(void Function(PromotionV3) updates) =>
      super.copyWith((message) => updates(message as PromotionV3))
          as PromotionV3;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PromotionV3() / PromotionV3.new instead')
  static PromotionV3 create() => PromotionV3._();
  static $pb.GeneratedMessage $_createMessage() => PromotionV3._();
  @$core.override
  PromotionV3 createEmptyInstance() => PromotionV3._();
  @$core.pragma('dart2js:noInline')
  static PromotionV3 getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PromotionV3>(
          PromotionV3.$_createMessage);
  static PromotionV3? _defaultInstance;
}

class BrandAds extends $pb.GeneratedMessage {
  factory BrandAds() => BrandAds._();

  BrandAds._();

  factory BrandAds.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BrandAds()..mergeFromBuffer(data, registry);
  factory BrandAds.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BrandAds()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BrandAds',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: BrandAds.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BrandAds clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BrandAds copyWith(void Function(BrandAds) updates) =>
      super.copyWith((message) => updates(message as BrandAds)) as BrandAds;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BrandAds() / BrandAds.new instead')
  static BrandAds create() => BrandAds._();
  static $pb.GeneratedMessage $_createMessage() => BrandAds._();
  @$core.override
  BrandAds createEmptyInstance() => BrandAds._();
  @$core.pragma('dart2js:noInline')
  static BrandAds getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BrandAds>(BrandAds.$_createMessage);
  static BrandAds? _defaultInstance;
}

class AudioPromo extends $pb.GeneratedMessage {
  factory AudioPromo() => AudioPromo._();

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
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: AudioPromo.$_createMessage)
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
}

class PlayLinkPromo extends $pb.GeneratedMessage {
  factory PlayLinkPromo() => PlayLinkPromo._();

  PlayLinkPromo._();

  factory PlayLinkPromo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayLinkPromo()..mergeFromBuffer(data, registry);
  factory PlayLinkPromo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayLinkPromo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayLinkPromo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: PlayLinkPromo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayLinkPromo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayLinkPromo copyWith(void Function(PlayLinkPromo) updates) =>
      super.copyWith((message) => updates(message as PlayLinkPromo))
          as PlayLinkPromo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PlayLinkPromo() / PlayLinkPromo.new instead')
  static PlayLinkPromo create() => PlayLinkPromo._();
  static $pb.GeneratedMessage $_createMessage() => PlayLinkPromo._();
  @$core.override
  PlayLinkPromo createEmptyInstance() => PlayLinkPromo._();
  @$core.pragma('dart2js:noInline')
  static PlayLinkPromo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PlayLinkPromo>(
          PlayLinkPromo.$_createMessage);
  static PlayLinkPromo? _defaultInstance;
}

class VideoPromo extends $pb.GeneratedMessage {
  factory VideoPromo() => VideoPromo._();

  VideoPromo._();

  factory VideoPromo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VideoPromo()..mergeFromBuffer(data, registry);
  factory VideoPromo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VideoPromo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VideoPromo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: VideoPromo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VideoPromo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VideoPromo copyWith(void Function(VideoPromo) updates) =>
      super.copyWith((message) => updates(message as VideoPromo)) as VideoPromo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use VideoPromo() / VideoPromo.new instead')
  static VideoPromo create() => VideoPromo._();
  static $pb.GeneratedMessage $_createMessage() => VideoPromo._();
  @$core.override
  VideoPromo createEmptyInstance() => VideoPromo._();
  @$core.pragma('dart2js:noInline')
  static VideoPromo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VideoPromo>(VideoPromo.$_createMessage);
  static VideoPromo? _defaultInstance;
}

class AudioSpotlight extends $pb.GeneratedMessage {
  factory AudioSpotlight() => AudioSpotlight._();

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
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: AudioSpotlight.$_createMessage)
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
}

class Showcase extends $pb.GeneratedMessage {
  factory Showcase() => Showcase._();

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
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: Showcase.$_createMessage)
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
}

class WatchFeed extends $pb.GeneratedMessage {
  factory WatchFeed({
    $core.Iterable<WatchFeedItem>? items,
  }) {
    final result = WatchFeed._();
    if (items != null) result.items.addAll(items);
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
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: WatchFeed.$_createMessage)
    ..pPM<WatchFeedItem>(1, _omitFieldNames ? '' : 'items',
        subBuilder: WatchFeedItem.$_createMessage)
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
  $pb.PbList<WatchFeedItem> get items => $_getList(0);
}

class WatchFeedItem extends $pb.GeneratedMessage {
  factory WatchFeedItem({
    $core.String? uri,
    WatchFeedItemMetadata? metadata,
  }) {
    final result = WatchFeedItem._();
    if (uri != null) result.uri = uri;
    if (metadata != null) result.metadata = metadata;
    return result;
  }

  WatchFeedItem._();

  factory WatchFeedItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchFeedItem()..mergeFromBuffer(data, registry);
  factory WatchFeedItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchFeedItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchFeedItem',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: WatchFeedItem.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
    ..aOM<WatchFeedItemMetadata>(2, _omitFieldNames ? '' : 'metadata',
        subBuilder: WatchFeedItemMetadata.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchFeedItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchFeedItem copyWith(void Function(WatchFeedItem) updates) =>
      super.copyWith((message) => updates(message as WatchFeedItem))
          as WatchFeedItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WatchFeedItem() / WatchFeedItem.new instead')
  static WatchFeedItem create() => WatchFeedItem._();
  static $pb.GeneratedMessage $_createMessage() => WatchFeedItem._();
  @$core.override
  WatchFeedItem createEmptyInstance() => WatchFeedItem._();
  @$core.pragma('dart2js:noInline')
  static WatchFeedItem getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WatchFeedItem>(
          WatchFeedItem.$_createMessage);
  static WatchFeedItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearUri() => $_clearField(1);

  @$pb.TagNumber(2)
  WatchFeedItemMetadata get metadata => $_getN(1);
  @$pb.TagNumber(2)
  set metadata(WatchFeedItemMetadata value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMetadata() => $_has(1);
  @$pb.TagNumber(2)
  void clearMetadata() => $_clearField(2);
  @$pb.TagNumber(2)
  WatchFeedItemMetadata ensureMetadata() => $_ensure(1);
}

class WatchFeedItemMetadata extends $pb.GeneratedMessage {
  factory WatchFeedItemMetadata({
    $core.String? title,
  }) {
    final result = WatchFeedItemMetadata._();
    if (title != null) result.title = title;
    return result;
  }

  WatchFeedItemMetadata._();

  factory WatchFeedItemMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchFeedItemMetadata()..mergeFromBuffer(data, registry);
  factory WatchFeedItemMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchFeedItemMetadata()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchFeedItemMetadata',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: WatchFeedItemMetadata.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchFeedItemMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchFeedItemMetadata copyWith(
          void Function(WatchFeedItemMetadata) updates) =>
      super.copyWith((message) => updates(message as WatchFeedItemMetadata))
          as WatchFeedItemMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use WatchFeedItemMetadata() / WatchFeedItemMetadata.new instead')
  static WatchFeedItemMetadata create() => WatchFeedItemMetadata._();
  static $pb.GeneratedMessage $_createMessage() => WatchFeedItemMetadata._();
  @$core.override
  WatchFeedItemMetadata createEmptyInstance() => WatchFeedItemMetadata._();
  @$core.pragma('dart2js:noInline')
  static WatchFeedItemMetadata getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchFeedItemMetadata>(
          WatchFeedItemMetadata.$_createMessage);
  static WatchFeedItemMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);
}

class PreviewPromotionCarousel extends $pb.GeneratedMessage {
  factory PreviewPromotionCarousel({
    $core.Iterable<PreviewPromotionCarouselItem>? items,
  }) {
    final result = PreviewPromotionCarousel._();
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
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: PreviewPromotionCarousel.$_createMessage)
    ..pPM<PreviewPromotionCarouselItem>(1, _omitFieldNames ? '' : 'items',
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
  $pb.PbList<PreviewPromotionCarouselItem> get items => $_getList(0);
}

class PreviewPromotionCarouselItem extends $pb.GeneratedMessage {
  factory PreviewPromotionCarouselItem({
    $core.String? uri,
  }) {
    final result = PreviewPromotionCarouselItem._();
    if (uri != null) result.uri = uri;
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
          _omitMessageNames ? '' : 'spotify.browsita.v1.resolved'),
      createEmptyInstance: PreviewPromotionCarouselItem.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
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
