// This is a generated file - do not edit.
//
// Generated from spotify/contentagnostic/v2/visual_types.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Image extends $pb.GeneratedMessage {
  factory Image({
    $core.Iterable<ImageInstance>? instances,
    ColorSetContrastOptions? extractedColorSet,
    $core.int? mask,
  }) {
    final result = Image._();
    if (instances != null) result.instances.addAll(instances);
    if (extractedColorSet != null) result.extractedColorSet = extractedColorSet;
    if (mask != null) result.mask = mask;
    return result;
  }

  Image._();

  factory Image.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Image()..mergeFromBuffer(data, registry);
  factory Image.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Image()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Image',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: Image.$_createMessage)
    ..pPM<ImageInstance>(1, _omitFieldNames ? '' : 'instances',
        subBuilder: ImageInstance.$_createMessage)
    ..aOM<ColorSetContrastOptions>(
        2, _omitFieldNames ? '' : 'extractedColorSet',
        subBuilder: ColorSetContrastOptions.$_createMessage)
    ..aI(3, _omitFieldNames ? '' : 'mask')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Image clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Image copyWith(void Function(Image) updates) =>
      super.copyWith((message) => updates(message as Image)) as Image;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Image() / Image.new instead')
  static Image create() => Image._();
  static $pb.GeneratedMessage $_createMessage() => Image._();
  @$core.override
  Image createEmptyInstance() => Image._();
  @$core.pragma('dart2js:noInline')
  static Image getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Image>(Image.$_createMessage);
  static Image? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ImageInstance> get instances => $_getList(0);

  @$pb.TagNumber(2)
  ColorSetContrastOptions get extractedColorSet => $_getN(1);
  @$pb.TagNumber(2)
  set extractedColorSet(ColorSetContrastOptions value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExtractedColorSet() => $_has(1);
  @$pb.TagNumber(2)
  void clearExtractedColorSet() => $_clearField(2);
  @$pb.TagNumber(2)
  ColorSetContrastOptions ensureExtractedColorSet() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get mask => $_getIZ(2);
  @$pb.TagNumber(3)
  set mask($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMask() => $_has(2);
  @$pb.TagNumber(3)
  void clearMask() => $_clearField(3);
}

class ImageInstance extends $pb.GeneratedMessage {
  factory ImageInstance({
    FlatFile? flatFile,
    $core.int? size,
  }) {
    final result = ImageInstance._();
    if (flatFile != null) result.flatFile = flatFile;
    if (size != null) result.size = size;
    return result;
  }

  ImageInstance._();

  factory ImageInstance.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ImageInstance()..mergeFromBuffer(data, registry);
  factory ImageInstance.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ImageInstance()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImageInstance',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: ImageInstance.$_createMessage)
    ..aOM<FlatFile>(1, _omitFieldNames ? '' : 'flatFile',
        subBuilder: FlatFile.$_createMessage)
    ..aI(2, _omitFieldNames ? '' : 'size')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImageInstance clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImageInstance copyWith(void Function(ImageInstance) updates) =>
      super.copyWith((message) => updates(message as ImageInstance))
          as ImageInstance;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ImageInstance() / ImageInstance.new instead')
  static ImageInstance create() => ImageInstance._();
  static $pb.GeneratedMessage $_createMessage() => ImageInstance._();
  @$core.override
  ImageInstance createEmptyInstance() => ImageInstance._();
  @$core.pragma('dart2js:noInline')
  static ImageInstance getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ImageInstance>(
          ImageInstance.$_createMessage);
  static ImageInstance? _defaultInstance;

  @$pb.TagNumber(1)
  FlatFile get flatFile => $_getN(0);
  @$pb.TagNumber(1)
  set flatFile(FlatFile value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFlatFile() => $_has(0);
  @$pb.TagNumber(1)
  void clearFlatFile() => $_clearField(1);
  @$pb.TagNumber(1)
  FlatFile ensureFlatFile() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get size => $_getIZ(1);
  @$pb.TagNumber(2)
  set size($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearSize() => $_clearField(2);
}

class FlatFile extends $pb.GeneratedMessage {
  factory FlatFile({
    $core.String? cdnUrl,
  }) {
    final result = FlatFile._();
    if (cdnUrl != null) result.cdnUrl = cdnUrl;
    return result;
  }

  FlatFile._();

  factory FlatFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FlatFile()..mergeFromBuffer(data, registry);
  factory FlatFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FlatFile()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FlatFile',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: FlatFile.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'cdnUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FlatFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FlatFile copyWith(void Function(FlatFile) updates) =>
      super.copyWith((message) => updates(message as FlatFile)) as FlatFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use FlatFile() / FlatFile.new instead')
  static FlatFile create() => FlatFile._();
  static $pb.GeneratedMessage $_createMessage() => FlatFile._();
  @$core.override
  FlatFile createEmptyInstance() => FlatFile._();
  @$core.pragma('dart2js:noInline')
  static FlatFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FlatFile>(FlatFile.$_createMessage);
  static FlatFile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get cdnUrl => $_getSZ(0);
  @$pb.TagNumber(1)
  set cdnUrl($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCdnUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearCdnUrl() => $_clearField(1);
}

class Video extends $pb.GeneratedMessage {
  factory Video() => Video._();

  Video._();

  factory Video.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Video()..mergeFromBuffer(data, registry);
  factory Video.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Video()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Video',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: Video.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Video clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Video copyWith(void Function(Video) updates) =>
      super.copyWith((message) => updates(message as Video)) as Video;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Video() / Video.new instead')
  static Video create() => Video._();
  static $pb.GeneratedMessage $_createMessage() => Video._();
  @$core.override
  Video createEmptyInstance() => Video._();
  @$core.pragma('dart2js:noInline')
  static Video getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Video>(Video.$_createMessage);
  static Video? _defaultInstance;
}

class ColorSetContrastOptions extends $pb.GeneratedMessage {
  factory ColorSetContrastOptions({
    ColorSet? minContrast,
    ColorSet? highContrast,
    ColorSet? higherContrast,
    RgbaColor? encoreBaseSetTextColor,
  }) {
    final result = ColorSetContrastOptions._();
    if (minContrast != null) result.minContrast = minContrast;
    if (highContrast != null) result.highContrast = highContrast;
    if (higherContrast != null) result.higherContrast = higherContrast;
    if (encoreBaseSetTextColor != null)
      result.encoreBaseSetTextColor = encoreBaseSetTextColor;
    return result;
  }

  ColorSetContrastOptions._();

  factory ColorSetContrastOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ColorSetContrastOptions()..mergeFromBuffer(data, registry);
  factory ColorSetContrastOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ColorSetContrastOptions()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ColorSetContrastOptions',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: ColorSetContrastOptions.$_createMessage)
    ..aOM<ColorSet>(1, _omitFieldNames ? '' : 'minContrast',
        subBuilder: ColorSet.$_createMessage)
    ..aOM<ColorSet>(2, _omitFieldNames ? '' : 'highContrast',
        subBuilder: ColorSet.$_createMessage)
    ..aOM<ColorSet>(3, _omitFieldNames ? '' : 'higherContrast',
        subBuilder: ColorSet.$_createMessage)
    ..aOM<RgbaColor>(4, _omitFieldNames ? '' : 'encoreBaseSetTextColor',
        subBuilder: RgbaColor.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColorSetContrastOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColorSetContrastOptions copyWith(
          void Function(ColorSetContrastOptions) updates) =>
      super.copyWith((message) => updates(message as ColorSetContrastOptions))
          as ColorSetContrastOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ColorSetContrastOptions() / ColorSetContrastOptions.new instead')
  static ColorSetContrastOptions create() => ColorSetContrastOptions._();
  static $pb.GeneratedMessage $_createMessage() => ColorSetContrastOptions._();
  @$core.override
  ColorSetContrastOptions createEmptyInstance() => ColorSetContrastOptions._();
  @$core.pragma('dart2js:noInline')
  static ColorSetContrastOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ColorSetContrastOptions>(
          ColorSetContrastOptions.$_createMessage);
  static ColorSetContrastOptions? _defaultInstance;

  @$pb.TagNumber(1)
  ColorSet get minContrast => $_getN(0);
  @$pb.TagNumber(1)
  set minContrast(ColorSet value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMinContrast() => $_has(0);
  @$pb.TagNumber(1)
  void clearMinContrast() => $_clearField(1);
  @$pb.TagNumber(1)
  ColorSet ensureMinContrast() => $_ensure(0);

  @$pb.TagNumber(2)
  ColorSet get highContrast => $_getN(1);
  @$pb.TagNumber(2)
  set highContrast(ColorSet value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasHighContrast() => $_has(1);
  @$pb.TagNumber(2)
  void clearHighContrast() => $_clearField(2);
  @$pb.TagNumber(2)
  ColorSet ensureHighContrast() => $_ensure(1);

  @$pb.TagNumber(3)
  ColorSet get higherContrast => $_getN(2);
  @$pb.TagNumber(3)
  set higherContrast(ColorSet value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasHigherContrast() => $_has(2);
  @$pb.TagNumber(3)
  void clearHigherContrast() => $_clearField(3);
  @$pb.TagNumber(3)
  ColorSet ensureHigherContrast() => $_ensure(2);

  @$pb.TagNumber(4)
  RgbaColor get encoreBaseSetTextColor => $_getN(3);
  @$pb.TagNumber(4)
  set encoreBaseSetTextColor(RgbaColor value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasEncoreBaseSetTextColor() => $_has(3);
  @$pb.TagNumber(4)
  void clearEncoreBaseSetTextColor() => $_clearField(4);
  @$pb.TagNumber(4)
  RgbaColor ensureEncoreBaseSetTextColor() => $_ensure(3);
}

class ColorSet extends $pb.GeneratedMessage {
  factory ColorSet({
    RgbaColor? backgroundBase,
    RgbaColor? backgroundTintedBase,
    RgbaColor? textBase,
    RgbaColor? textSubdued,
    RgbaColor? textBrightAccent,
  }) {
    final result = ColorSet._();
    if (backgroundBase != null) result.backgroundBase = backgroundBase;
    if (backgroundTintedBase != null)
      result.backgroundTintedBase = backgroundTintedBase;
    if (textBase != null) result.textBase = textBase;
    if (textSubdued != null) result.textSubdued = textSubdued;
    if (textBrightAccent != null) result.textBrightAccent = textBrightAccent;
    return result;
  }

  ColorSet._();

  factory ColorSet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ColorSet()..mergeFromBuffer(data, registry);
  factory ColorSet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ColorSet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ColorSet',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: ColorSet.$_createMessage)
    ..aOM<RgbaColor>(1, _omitFieldNames ? '' : 'backgroundBase',
        subBuilder: RgbaColor.$_createMessage)
    ..aOM<RgbaColor>(2, _omitFieldNames ? '' : 'backgroundTintedBase',
        subBuilder: RgbaColor.$_createMessage)
    ..aOM<RgbaColor>(3, _omitFieldNames ? '' : 'textBase',
        subBuilder: RgbaColor.$_createMessage)
    ..aOM<RgbaColor>(4, _omitFieldNames ? '' : 'textSubdued',
        subBuilder: RgbaColor.$_createMessage)
    ..aOM<RgbaColor>(5, _omitFieldNames ? '' : 'textBrightAccent',
        subBuilder: RgbaColor.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColorSet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColorSet copyWith(void Function(ColorSet) updates) =>
      super.copyWith((message) => updates(message as ColorSet)) as ColorSet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ColorSet() / ColorSet.new instead')
  static ColorSet create() => ColorSet._();
  static $pb.GeneratedMessage $_createMessage() => ColorSet._();
  @$core.override
  ColorSet createEmptyInstance() => ColorSet._();
  @$core.pragma('dart2js:noInline')
  static ColorSet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ColorSet>(ColorSet.$_createMessage);
  static ColorSet? _defaultInstance;

  @$pb.TagNumber(1)
  RgbaColor get backgroundBase => $_getN(0);
  @$pb.TagNumber(1)
  set backgroundBase(RgbaColor value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBackgroundBase() => $_has(0);
  @$pb.TagNumber(1)
  void clearBackgroundBase() => $_clearField(1);
  @$pb.TagNumber(1)
  RgbaColor ensureBackgroundBase() => $_ensure(0);

  @$pb.TagNumber(2)
  RgbaColor get backgroundTintedBase => $_getN(1);
  @$pb.TagNumber(2)
  set backgroundTintedBase(RgbaColor value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasBackgroundTintedBase() => $_has(1);
  @$pb.TagNumber(2)
  void clearBackgroundTintedBase() => $_clearField(2);
  @$pb.TagNumber(2)
  RgbaColor ensureBackgroundTintedBase() => $_ensure(1);

  @$pb.TagNumber(3)
  RgbaColor get textBase => $_getN(2);
  @$pb.TagNumber(3)
  set textBase(RgbaColor value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTextBase() => $_has(2);
  @$pb.TagNumber(3)
  void clearTextBase() => $_clearField(3);
  @$pb.TagNumber(3)
  RgbaColor ensureTextBase() => $_ensure(2);

  @$pb.TagNumber(4)
  RgbaColor get textSubdued => $_getN(3);
  @$pb.TagNumber(4)
  set textSubdued(RgbaColor value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasTextSubdued() => $_has(3);
  @$pb.TagNumber(4)
  void clearTextSubdued() => $_clearField(4);
  @$pb.TagNumber(4)
  RgbaColor ensureTextSubdued() => $_ensure(3);

  @$pb.TagNumber(5)
  RgbaColor get textBrightAccent => $_getN(4);
  @$pb.TagNumber(5)
  set textBrightAccent(RgbaColor value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasTextBrightAccent() => $_has(4);
  @$pb.TagNumber(5)
  void clearTextBrightAccent() => $_clearField(5);
  @$pb.TagNumber(5)
  RgbaColor ensureTextBrightAccent() => $_ensure(4);
}

class RgbaColor extends $pb.GeneratedMessage {
  factory RgbaColor({
    $core.int? r,
    $core.int? g,
    $core.int? b,
    $core.int? a,
  }) {
    final result = RgbaColor._();
    if (r != null) result.r = r;
    if (g != null) result.g = g;
    if (b != null) result.b = b;
    if (a != null) result.a = a;
    return result;
  }

  RgbaColor._();

  factory RgbaColor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RgbaColor()..mergeFromBuffer(data, registry);
  factory RgbaColor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RgbaColor()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RgbaColor',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: RgbaColor.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'r')
    ..aI(2, _omitFieldNames ? '' : 'g')
    ..aI(3, _omitFieldNames ? '' : 'b')
    ..aI(4, _omitFieldNames ? '' : 'a')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RgbaColor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RgbaColor copyWith(void Function(RgbaColor) updates) =>
      super.copyWith((message) => updates(message as RgbaColor)) as RgbaColor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RgbaColor() / RgbaColor.new instead')
  static RgbaColor create() => RgbaColor._();
  static $pb.GeneratedMessage $_createMessage() => RgbaColor._();
  @$core.override
  RgbaColor createEmptyInstance() => RgbaColor._();
  @$core.pragma('dart2js:noInline')
  static RgbaColor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RgbaColor>(RgbaColor.$_createMessage);
  static RgbaColor? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get r => $_getIZ(0);
  @$pb.TagNumber(1)
  set r($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasR() => $_has(0);
  @$pb.TagNumber(1)
  void clearR() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get g => $_getIZ(1);
  @$pb.TagNumber(2)
  set g($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasG() => $_has(1);
  @$pb.TagNumber(2)
  void clearG() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get b => $_getIZ(2);
  @$pb.TagNumber(3)
  set b($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasB() => $_has(2);
  @$pb.TagNumber(3)
  void clearB() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get a => $_getIZ(3);
  @$pb.TagNumber(4)
  set a($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasA() => $_has(3);
  @$pb.TagNumber(4)
  void clearA() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
