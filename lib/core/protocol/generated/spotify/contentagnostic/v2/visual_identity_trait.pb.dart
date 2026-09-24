// This is a generated file - do not edit.
//
// Generated from spotify/contentagnostic/v2/visual_identity_trait.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'visual_types.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class VisualIdentityTrait extends $pb.GeneratedMessage {
  factory VisualIdentityTrait({
    $0.Image? squareCoverImage,
    $0.Image? sixteenByNineCoverImage,
    $0.Video? nineBySixteenCoverVideo,
    $0.Image? squareFullBleedImage,
    $0.Image? wideFullBleedImage,
    $0.ColorSetContrastOptions? curatedColor,
  }) {
    final result = VisualIdentityTrait._();
    if (squareCoverImage != null) result.squareCoverImage = squareCoverImage;
    if (sixteenByNineCoverImage != null)
      result.sixteenByNineCoverImage = sixteenByNineCoverImage;
    if (nineBySixteenCoverVideo != null)
      result.nineBySixteenCoverVideo = nineBySixteenCoverVideo;
    if (squareFullBleedImage != null)
      result.squareFullBleedImage = squareFullBleedImage;
    if (wideFullBleedImage != null)
      result.wideFullBleedImage = wideFullBleedImage;
    if (curatedColor != null) result.curatedColor = curatedColor;
    return result;
  }

  VisualIdentityTrait._();

  factory VisualIdentityTrait.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VisualIdentityTrait()..mergeFromBuffer(data, registry);
  factory VisualIdentityTrait.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VisualIdentityTrait()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VisualIdentityTrait',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: VisualIdentityTrait.$_createMessage)
    ..aOM<$0.Image>(1, _omitFieldNames ? '' : 'squareCoverImage',
        subBuilder: $0.Image.$_createMessage)
    ..aOM<$0.Image>(2, _omitFieldNames ? '' : 'sixteenByNineCoverImage',
        subBuilder: $0.Image.$_createMessage)
    ..aOM<$0.Video>(4, _omitFieldNames ? '' : 'nineBySixteenCoverVideo',
        subBuilder: $0.Video.$_createMessage)
    ..aOM<$0.Image>(5, _omitFieldNames ? '' : 'squareFullBleedImage',
        subBuilder: $0.Image.$_createMessage)
    ..aOM<$0.Image>(6, _omitFieldNames ? '' : 'wideFullBleedImage',
        subBuilder: $0.Image.$_createMessage)
    ..aOM<$0.ColorSetContrastOptions>(7, _omitFieldNames ? '' : 'curatedColor',
        subBuilder: $0.ColorSetContrastOptions.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VisualIdentityTrait clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VisualIdentityTrait copyWith(void Function(VisualIdentityTrait) updates) =>
      super.copyWith((message) => updates(message as VisualIdentityTrait))
          as VisualIdentityTrait;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use VisualIdentityTrait() / VisualIdentityTrait.new instead')
  static VisualIdentityTrait create() => VisualIdentityTrait._();
  static $pb.GeneratedMessage $_createMessage() => VisualIdentityTrait._();
  @$core.override
  VisualIdentityTrait createEmptyInstance() => VisualIdentityTrait._();
  @$core.pragma('dart2js:noInline')
  static VisualIdentityTrait getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VisualIdentityTrait>(
          VisualIdentityTrait.$_createMessage);
  static VisualIdentityTrait? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Image get squareCoverImage => $_getN(0);
  @$pb.TagNumber(1)
  set squareCoverImage($0.Image value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSquareCoverImage() => $_has(0);
  @$pb.TagNumber(1)
  void clearSquareCoverImage() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Image ensureSquareCoverImage() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.Image get sixteenByNineCoverImage => $_getN(1);
  @$pb.TagNumber(2)
  set sixteenByNineCoverImage($0.Image value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSixteenByNineCoverImage() => $_has(1);
  @$pb.TagNumber(2)
  void clearSixteenByNineCoverImage() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Image ensureSixteenByNineCoverImage() => $_ensure(1);

  /// field 3 unused
  @$pb.TagNumber(4)
  $0.Video get nineBySixteenCoverVideo => $_getN(2);
  @$pb.TagNumber(4)
  set nineBySixteenCoverVideo($0.Video value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasNineBySixteenCoverVideo() => $_has(2);
  @$pb.TagNumber(4)
  void clearNineBySixteenCoverVideo() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Video ensureNineBySixteenCoverVideo() => $_ensure(2);

  @$pb.TagNumber(5)
  $0.Image get squareFullBleedImage => $_getN(3);
  @$pb.TagNumber(5)
  set squareFullBleedImage($0.Image value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSquareFullBleedImage() => $_has(3);
  @$pb.TagNumber(5)
  void clearSquareFullBleedImage() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Image ensureSquareFullBleedImage() => $_ensure(3);

  @$pb.TagNumber(6)
  $0.Image get wideFullBleedImage => $_getN(4);
  @$pb.TagNumber(6)
  set wideFullBleedImage($0.Image value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasWideFullBleedImage() => $_has(4);
  @$pb.TagNumber(6)
  void clearWideFullBleedImage() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.Image ensureWideFullBleedImage() => $_ensure(4);

  @$pb.TagNumber(7)
  $0.ColorSetContrastOptions get curatedColor => $_getN(5);
  @$pb.TagNumber(7)
  set curatedColor($0.ColorSetContrastOptions value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasCuratedColor() => $_has(5);
  @$pb.TagNumber(7)
  void clearCuratedColor() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.ColorSetContrastOptions ensureCuratedColor() => $_ensure(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
