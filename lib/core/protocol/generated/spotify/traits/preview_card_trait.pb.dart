// This is a generated file - do not edit.
//
// Generated from spotify/traits/preview_card_trait.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/duration.pb.dart'
    as $0;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

import 'preview_card_trait.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'preview_card_trait.pbenum.dart';

class PreviewCardTrait extends $pb.GeneratedMessage {
  factory PreviewCardTrait({
    $core.String? title,
    $core.String? contentTypeName,
    $core.String? description,
    $core.String? entityUri,
    $core.String? navigateUri,
    $core.String? likeUri,
    $core.String? entityImageUrl,
    $0.Duration? duration,
    $1.Timestamp? publishTime,
    $core.String? backgroundColorHex,
    $core.String? waveformColorHex,
    PreviewRestriction? previewRestriction,
    Labels? labels,
    $core.Iterable<DescriptorTag>? descriptorTags,
    $core.int? numberOfItems,
    ContentParent? contentParent,
    SubtitleSource? subtitleSource,
  }) {
    final result = PreviewCardTrait._();
    if (title != null) result.title = title;
    if (contentTypeName != null) result.contentTypeName = contentTypeName;
    if (description != null) result.description = description;
    if (entityUri != null) result.entityUri = entityUri;
    if (navigateUri != null) result.navigateUri = navigateUri;
    if (likeUri != null) result.likeUri = likeUri;
    if (entityImageUrl != null) result.entityImageUrl = entityImageUrl;
    if (duration != null) result.duration = duration;
    if (publishTime != null) result.publishTime = publishTime;
    if (backgroundColorHex != null)
      result.backgroundColorHex = backgroundColorHex;
    if (waveformColorHex != null) result.waveformColorHex = waveformColorHex;
    if (previewRestriction != null)
      result.previewRestriction = previewRestriction;
    if (labels != null) result.labels = labels;
    if (descriptorTags != null) result.descriptorTags.addAll(descriptorTags);
    if (numberOfItems != null) result.numberOfItems = numberOfItems;
    if (contentParent != null) result.contentParent = contentParent;
    if (subtitleSource != null) result.subtitleSource = subtitleSource;
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
      package: const $pb.PackageName(_omitMessageNames
          ? ''
          : 'spotify.extendedmetadata.extensions.previewcardtrait'),
      createEmptyInstance: PreviewCardTrait.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'contentTypeName')
    ..aOS(4, _omitFieldNames ? '' : 'description')
    ..aOS(5, _omitFieldNames ? '' : 'entityUri')
    ..aOS(6, _omitFieldNames ? '' : 'navigateUri')
    ..aOS(7, _omitFieldNames ? '' : 'likeUri')
    ..aOS(8, _omitFieldNames ? '' : 'entityImageUrl')
    ..aOM<$0.Duration>(9, _omitFieldNames ? '' : 'duration',
        subBuilder: $0.Duration.$_createMessage)
    ..aOM<$1.Timestamp>(10, _omitFieldNames ? '' : 'publishTime',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aOS(11, _omitFieldNames ? '' : 'backgroundColorHex')
    ..aOS(12, _omitFieldNames ? '' : 'waveformColorHex')
    ..aE<PreviewRestriction>(13, _omitFieldNames ? '' : 'previewRestriction',
        enumValues: PreviewRestriction.values)
    ..aOM<Labels>(14, _omitFieldNames ? '' : 'labels',
        subBuilder: Labels.$_createMessage)
    ..pPM<DescriptorTag>(15, _omitFieldNames ? '' : 'descriptorTags',
        subBuilder: DescriptorTag.$_createMessage)
    ..aI(16, _omitFieldNames ? '' : 'numberOfItems')
    ..aOM<ContentParent>(17, _omitFieldNames ? '' : 'contentParent',
        subBuilder: ContentParent.$_createMessage)
    ..aE<SubtitleSource>(18, _omitFieldNames ? '' : 'subtitleSource',
        enumValues: SubtitleSource.values)
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

  @$pb.TagNumber(2)
  $core.String get contentTypeName => $_getSZ(1);
  @$pb.TagNumber(2)
  set contentTypeName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContentTypeName() => $_has(1);
  @$pb.TagNumber(2)
  void clearContentTypeName() => $_clearField(2);

  /// field 3 is reserved (not used in current schema)
  @$pb.TagNumber(4)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(4)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(4)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(4)
  void clearDescription() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get entityUri => $_getSZ(3);
  @$pb.TagNumber(5)
  set entityUri($core.String value) => $_setString(3, value);
  @$pb.TagNumber(5)
  $core.bool hasEntityUri() => $_has(3);
  @$pb.TagNumber(5)
  void clearEntityUri() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get navigateUri => $_getSZ(4);
  @$pb.TagNumber(6)
  set navigateUri($core.String value) => $_setString(4, value);
  @$pb.TagNumber(6)
  $core.bool hasNavigateUri() => $_has(4);
  @$pb.TagNumber(6)
  void clearNavigateUri() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get likeUri => $_getSZ(5);
  @$pb.TagNumber(7)
  set likeUri($core.String value) => $_setString(5, value);
  @$pb.TagNumber(7)
  $core.bool hasLikeUri() => $_has(5);
  @$pb.TagNumber(7)
  void clearLikeUri() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get entityImageUrl => $_getSZ(6);
  @$pb.TagNumber(8)
  set entityImageUrl($core.String value) => $_setString(6, value);
  @$pb.TagNumber(8)
  $core.bool hasEntityImageUrl() => $_has(6);
  @$pb.TagNumber(8)
  void clearEntityImageUrl() => $_clearField(8);

  @$pb.TagNumber(9)
  $0.Duration get duration => $_getN(7);
  @$pb.TagNumber(9)
  set duration($0.Duration value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasDuration() => $_has(7);
  @$pb.TagNumber(9)
  void clearDuration() => $_clearField(9);
  @$pb.TagNumber(9)
  $0.Duration ensureDuration() => $_ensure(7);

  @$pb.TagNumber(10)
  $1.Timestamp get publishTime => $_getN(8);
  @$pb.TagNumber(10)
  set publishTime($1.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasPublishTime() => $_has(8);
  @$pb.TagNumber(10)
  void clearPublishTime() => $_clearField(10);
  @$pb.TagNumber(10)
  $1.Timestamp ensurePublishTime() => $_ensure(8);

  @$pb.TagNumber(11)
  $core.String get backgroundColorHex => $_getSZ(9);
  @$pb.TagNumber(11)
  set backgroundColorHex($core.String value) => $_setString(9, value);
  @$pb.TagNumber(11)
  $core.bool hasBackgroundColorHex() => $_has(9);
  @$pb.TagNumber(11)
  void clearBackgroundColorHex() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get waveformColorHex => $_getSZ(10);
  @$pb.TagNumber(12)
  set waveformColorHex($core.String value) => $_setString(10, value);
  @$pb.TagNumber(12)
  $core.bool hasWaveformColorHex() => $_has(10);
  @$pb.TagNumber(12)
  void clearWaveformColorHex() => $_clearField(12);

  @$pb.TagNumber(13)
  PreviewRestriction get previewRestriction => $_getN(11);
  @$pb.TagNumber(13)
  set previewRestriction(PreviewRestriction value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasPreviewRestriction() => $_has(11);
  @$pb.TagNumber(13)
  void clearPreviewRestriction() => $_clearField(13);

  @$pb.TagNumber(14)
  Labels get labels => $_getN(12);
  @$pb.TagNumber(14)
  set labels(Labels value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasLabels() => $_has(12);
  @$pb.TagNumber(14)
  void clearLabels() => $_clearField(14);
  @$pb.TagNumber(14)
  Labels ensureLabels() => $_ensure(12);

  @$pb.TagNumber(15)
  $pb.PbList<DescriptorTag> get descriptorTags => $_getList(13);

  @$pb.TagNumber(16)
  $core.int get numberOfItems => $_getIZ(14);
  @$pb.TagNumber(16)
  set numberOfItems($core.int value) => $_setSignedInt32(14, value);
  @$pb.TagNumber(16)
  $core.bool hasNumberOfItems() => $_has(14);
  @$pb.TagNumber(16)
  void clearNumberOfItems() => $_clearField(16);

  @$pb.TagNumber(17)
  ContentParent get contentParent => $_getN(15);
  @$pb.TagNumber(17)
  set contentParent(ContentParent value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasContentParent() => $_has(15);
  @$pb.TagNumber(17)
  void clearContentParent() => $_clearField(17);
  @$pb.TagNumber(17)
  ContentParent ensureContentParent() => $_ensure(15);

  @$pb.TagNumber(18)
  SubtitleSource get subtitleSource => $_getN(16);
  @$pb.TagNumber(18)
  set subtitleSource(SubtitleSource value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasSubtitleSource() => $_has(16);
  @$pb.TagNumber(18)
  void clearSubtitleSource() => $_clearField(18);
}

class Labels extends $pb.GeneratedMessage {
  factory Labels({
    $core.String? previewLabel,
    $core.String? playingLabel,
  }) {
    final result = Labels._();
    if (previewLabel != null) result.previewLabel = previewLabel;
    if (playingLabel != null) result.playingLabel = playingLabel;
    return result;
  }

  Labels._();

  factory Labels.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Labels()..mergeFromBuffer(data, registry);
  factory Labels.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Labels()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Labels',
      package: const $pb.PackageName(_omitMessageNames
          ? ''
          : 'spotify.extendedmetadata.extensions.previewcardtrait'),
      createEmptyInstance: Labels.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'previewLabel')
    ..aOS(2, _omitFieldNames ? '' : 'playingLabel')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Labels clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Labels copyWith(void Function(Labels) updates) =>
      super.copyWith((message) => updates(message as Labels)) as Labels;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Labels() / Labels.new instead')
  static Labels create() => Labels._();
  static $pb.GeneratedMessage $_createMessage() => Labels._();
  @$core.override
  Labels createEmptyInstance() => Labels._();
  @$core.pragma('dart2js:noInline')
  static Labels getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Labels>(Labels.$_createMessage);
  static Labels? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get previewLabel => $_getSZ(0);
  @$pb.TagNumber(1)
  set previewLabel($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPreviewLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreviewLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get playingLabel => $_getSZ(1);
  @$pb.TagNumber(2)
  set playingLabel($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPlayingLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlayingLabel() => $_clearField(2);
}

class DescriptorTag extends $pb.GeneratedMessage {
  factory DescriptorTag({
    $core.String? name,
  }) {
    final result = DescriptorTag._();
    if (name != null) result.name = name;
    return result;
  }

  DescriptorTag._();

  factory DescriptorTag.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DescriptorTag()..mergeFromBuffer(data, registry);
  factory DescriptorTag.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DescriptorTag()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DescriptorTag',
      package: const $pb.PackageName(_omitMessageNames
          ? ''
          : 'spotify.extendedmetadata.extensions.previewcardtrait'),
      createEmptyInstance: DescriptorTag.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DescriptorTag clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DescriptorTag copyWith(void Function(DescriptorTag) updates) =>
      super.copyWith((message) => updates(message as DescriptorTag))
          as DescriptorTag;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DescriptorTag() / DescriptorTag.new instead')
  static DescriptorTag create() => DescriptorTag._();
  static $pb.GeneratedMessage $_createMessage() => DescriptorTag._();
  @$core.override
  DescriptorTag createEmptyInstance() => DescriptorTag._();
  @$core.pragma('dart2js:noInline')
  static DescriptorTag getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DescriptorTag>(
          DescriptorTag.$_createMessage);
  static DescriptorTag? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
}

class ContentParent extends $pb.GeneratedMessage {
  factory ContentParent({
    $core.String? name,
    $core.String? uri,
    $core.String? imageUrl,
  }) {
    final result = ContentParent._();
    if (name != null) result.name = name;
    if (uri != null) result.uri = uri;
    if (imageUrl != null) result.imageUrl = imageUrl;
    return result;
  }

  ContentParent._();

  factory ContentParent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContentParent()..mergeFromBuffer(data, registry);
  factory ContentParent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContentParent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContentParent',
      package: const $pb.PackageName(_omitMessageNames
          ? ''
          : 'spotify.extendedmetadata.extensions.previewcardtrait'),
      createEmptyInstance: ContentParent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'uri')
    ..aOS(3, _omitFieldNames ? '' : 'imageUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContentParent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContentParent copyWith(void Function(ContentParent) updates) =>
      super.copyWith((message) => updates(message as ContentParent))
          as ContentParent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ContentParent() / ContentParent.new instead')
  static ContentParent create() => ContentParent._();
  static $pb.GeneratedMessage $_createMessage() => ContentParent._();
  @$core.override
  ContentParent createEmptyInstance() => ContentParent._();
  @$core.pragma('dart2js:noInline')
  static ContentParent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ContentParent>(
          ContentParent.$_createMessage);
  static ContentParent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

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

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
