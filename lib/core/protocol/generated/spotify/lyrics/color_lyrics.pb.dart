// This is a generated file - do not edit.
//
// Generated from spotify/lyrics/color_lyrics.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ColorLyricsResponse extends $pb.GeneratedMessage {
  factory ColorLyricsResponse({
    LyricsResponse? lyrics,
    ColorData? colors,
    $core.bool? hasVocalRemoval,
  }) {
    final result = ColorLyricsResponse._();
    if (lyrics != null) result.lyrics = lyrics;
    if (colors != null) result.colors = colors;
    if (hasVocalRemoval != null) result.hasVocalRemoval = hasVocalRemoval;
    return result;
  }

  ColorLyricsResponse._();

  factory ColorLyricsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ColorLyricsResponse()..mergeFromBuffer(data, registry);
  factory ColorLyricsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ColorLyricsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ColorLyricsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.lyrics.v2'),
      createEmptyInstance: ColorLyricsResponse.$_createMessage)
    ..aOM<LyricsResponse>(1, _omitFieldNames ? '' : 'lyrics',
        subBuilder: LyricsResponse.$_createMessage)
    ..aOM<ColorData>(2, _omitFieldNames ? '' : 'colors',
        subBuilder: ColorData.$_createMessage)
    ..aOB(3, _omitFieldNames ? '' : 'hasVocalRemoval')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColorLyricsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColorLyricsResponse copyWith(void Function(ColorLyricsResponse) updates) =>
      super.copyWith((message) => updates(message as ColorLyricsResponse))
          as ColorLyricsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ColorLyricsResponse() / ColorLyricsResponse.new instead')
  static ColorLyricsResponse create() => ColorLyricsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ColorLyricsResponse._();
  @$core.override
  ColorLyricsResponse createEmptyInstance() => ColorLyricsResponse._();
  @$core.pragma('dart2js:noInline')
  static ColorLyricsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ColorLyricsResponse>(
          ColorLyricsResponse.$_createMessage);
  static ColorLyricsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  LyricsResponse get lyrics => $_getN(0);
  @$pb.TagNumber(1)
  set lyrics(LyricsResponse value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLyrics() => $_has(0);
  @$pb.TagNumber(1)
  void clearLyrics() => $_clearField(1);
  @$pb.TagNumber(1)
  LyricsResponse ensureLyrics() => $_ensure(0);

  @$pb.TagNumber(2)
  ColorData get colors => $_getN(1);
  @$pb.TagNumber(2)
  set colors(ColorData value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasColors() => $_has(1);
  @$pb.TagNumber(2)
  void clearColors() => $_clearField(2);
  @$pb.TagNumber(2)
  ColorData ensureColors() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.bool get hasVocalRemoval => $_getBF(2);
  @$pb.TagNumber(3)
  set hasVocalRemoval($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHasVocalRemoval() => $_has(2);
  @$pb.TagNumber(3)
  void clearHasVocalRemoval() => $_clearField(3);
}

class ColorData extends $pb.GeneratedMessage {
  factory ColorData({
    $core.int? background,
    $core.int? text,
    $core.int? highlightText,
  }) {
    final result = ColorData._();
    if (background != null) result.background = background;
    if (text != null) result.text = text;
    if (highlightText != null) result.highlightText = highlightText;
    return result;
  }

  ColorData._();

  factory ColorData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ColorData()..mergeFromBuffer(data, registry);
  factory ColorData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ColorData()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ColorData',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.lyrics.v2'),
      createEmptyInstance: ColorData.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'background')
    ..aI(2, _omitFieldNames ? '' : 'text')
    ..aI(3, _omitFieldNames ? '' : 'highlightText')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColorData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ColorData copyWith(void Function(ColorData) updates) =>
      super.copyWith((message) => updates(message as ColorData)) as ColorData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ColorData() / ColorData.new instead')
  static ColorData create() => ColorData._();
  static $pb.GeneratedMessage $_createMessage() => ColorData._();
  @$core.override
  ColorData createEmptyInstance() => ColorData._();
  @$core.pragma('dart2js:noInline')
  static ColorData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ColorData>(ColorData.$_createMessage);
  static ColorData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get background => $_getIZ(0);
  @$pb.TagNumber(1)
  set background($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBackground() => $_has(0);
  @$pb.TagNumber(1)
  void clearBackground() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get text => $_getIZ(1);
  @$pb.TagNumber(2)
  set text($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get highlightText => $_getIZ(2);
  @$pb.TagNumber(3)
  set highlightText($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHighlightText() => $_has(2);
  @$pb.TagNumber(3)
  void clearHighlightText() => $_clearField(3);
}

class Syllable extends $pb.GeneratedMessage {
  factory Syllable({
    $fixnum.Int64? startTimeMs,
    $fixnum.Int64? numChars,
  }) {
    final result = Syllable._();
    if (startTimeMs != null) result.startTimeMs = startTimeMs;
    if (numChars != null) result.numChars = numChars;
    return result;
  }

  Syllable._();

  factory Syllable.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Syllable()..mergeFromBuffer(data, registry);
  factory Syllable.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Syllable()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Syllable',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.lyrics.v2'),
      createEmptyInstance: Syllable.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'startTimeMs')
    ..aInt64(2, _omitFieldNames ? '' : 'numChars')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Syllable clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Syllable copyWith(void Function(Syllable) updates) =>
      super.copyWith((message) => updates(message as Syllable)) as Syllable;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Syllable() / Syllable.new instead')
  static Syllable create() => Syllable._();
  static $pb.GeneratedMessage $_createMessage() => Syllable._();
  @$core.override
  Syllable createEmptyInstance() => Syllable._();
  @$core.pragma('dart2js:noInline')
  static Syllable getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Syllable>(Syllable.$_createMessage);
  static Syllable? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get startTimeMs => $_getI64(0);
  @$pb.TagNumber(1)
  set startTimeMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStartTimeMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearStartTimeMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get numChars => $_getI64(1);
  @$pb.TagNumber(2)
  set numChars($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNumChars() => $_has(1);
  @$pb.TagNumber(2)
  void clearNumChars() => $_clearField(2);
}

class LyricsLine extends $pb.GeneratedMessage {
  factory LyricsLine({
    $fixnum.Int64? startTimeMs,
    $core.String? words,
    $core.Iterable<Syllable>? syllables,
  }) {
    final result = LyricsLine._();
    if (startTimeMs != null) result.startTimeMs = startTimeMs;
    if (words != null) result.words = words;
    if (syllables != null) result.syllables.addAll(syllables);
    return result;
  }

  LyricsLine._();

  factory LyricsLine.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LyricsLine()..mergeFromBuffer(data, registry);
  factory LyricsLine.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LyricsLine()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LyricsLine',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.lyrics.v2'),
      createEmptyInstance: LyricsLine.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'startTimeMs')
    ..aOS(2, _omitFieldNames ? '' : 'words')
    ..pPM<Syllable>(3, _omitFieldNames ? '' : 'syllables',
        subBuilder: Syllable.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LyricsLine clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LyricsLine copyWith(void Function(LyricsLine) updates) =>
      super.copyWith((message) => updates(message as LyricsLine)) as LyricsLine;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LyricsLine() / LyricsLine.new instead')
  static LyricsLine create() => LyricsLine._();
  static $pb.GeneratedMessage $_createMessage() => LyricsLine._();
  @$core.override
  LyricsLine createEmptyInstance() => LyricsLine._();
  @$core.pragma('dart2js:noInline')
  static LyricsLine getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LyricsLine>(LyricsLine.$_createMessage);
  static LyricsLine? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get startTimeMs => $_getI64(0);
  @$pb.TagNumber(1)
  set startTimeMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStartTimeMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearStartTimeMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get words => $_getSZ(1);
  @$pb.TagNumber(2)
  set words($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWords() => $_has(1);
  @$pb.TagNumber(2)
  void clearWords() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<Syllable> get syllables => $_getList(2);
}

class Alternative extends $pb.GeneratedMessage {
  factory Alternative({
    $core.String? language,
    $core.Iterable<$core.String>? lines,
    $core.bool? isRtlLanguage,
  }) {
    final result = Alternative._();
    if (language != null) result.language = language;
    if (lines != null) result.lines.addAll(lines);
    if (isRtlLanguage != null) result.isRtlLanguage = isRtlLanguage;
    return result;
  }

  Alternative._();

  factory Alternative.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Alternative()..mergeFromBuffer(data, registry);
  factory Alternative.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Alternative()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Alternative',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.lyrics.v2'),
      createEmptyInstance: Alternative.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'language')
    ..pPS(2, _omitFieldNames ? '' : 'lines')
    ..aOB(3, _omitFieldNames ? '' : 'isRtlLanguage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Alternative clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Alternative copyWith(void Function(Alternative) updates) =>
      super.copyWith((message) => updates(message as Alternative))
          as Alternative;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Alternative() / Alternative.new instead')
  static Alternative create() => Alternative._();
  static $pb.GeneratedMessage $_createMessage() => Alternative._();
  @$core.override
  Alternative createEmptyInstance() => Alternative._();
  @$core.pragma('dart2js:noInline')
  static Alternative getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Alternative>(
          Alternative.$_createMessage);
  static Alternative? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get language => $_getSZ(0);
  @$pb.TagNumber(1)
  set language($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLanguage() => $_has(0);
  @$pb.TagNumber(1)
  void clearLanguage() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get lines => $_getList(1);

  @$pb.TagNumber(3)
  $core.bool get isRtlLanguage => $_getBF(2);
  @$pb.TagNumber(3)
  set isRtlLanguage($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsRtlLanguage() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsRtlLanguage() => $_clearField(3);
}

class LyricsResponse extends $pb.GeneratedMessage {
  factory LyricsResponse({
    $core.int? syncType,
    $core.Iterable<LyricsLine>? lines,
    $core.String? provider,
    $core.String? providerLyricsId,
    $core.String? providerDisplayName,
    $core.String? syncLyricsUri,
    $core.Iterable<Alternative>? alternatives,
    $core.String? language,
    $core.bool? isRtlLanguage,
    $core.int? capStatus,
    $core.Iterable<$core.String>? translationLanguages,
  }) {
    final result = LyricsResponse._();
    if (syncType != null) result.syncType = syncType;
    if (lines != null) result.lines.addAll(lines);
    if (provider != null) result.provider = provider;
    if (providerLyricsId != null) result.providerLyricsId = providerLyricsId;
    if (providerDisplayName != null)
      result.providerDisplayName = providerDisplayName;
    if (syncLyricsUri != null) result.syncLyricsUri = syncLyricsUri;
    if (alternatives != null) result.alternatives.addAll(alternatives);
    if (language != null) result.language = language;
    if (isRtlLanguage != null) result.isRtlLanguage = isRtlLanguage;
    if (capStatus != null) result.capStatus = capStatus;
    if (translationLanguages != null)
      result.translationLanguages.addAll(translationLanguages);
    return result;
  }

  LyricsResponse._();

  factory LyricsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LyricsResponse()..mergeFromBuffer(data, registry);
  factory LyricsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LyricsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LyricsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.lyrics.v2'),
      createEmptyInstance: LyricsResponse.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'syncType')
    ..pPM<LyricsLine>(2, _omitFieldNames ? '' : 'lines',
        subBuilder: LyricsLine.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'provider')
    ..aOS(4, _omitFieldNames ? '' : 'providerLyricsId')
    ..aOS(5, _omitFieldNames ? '' : 'providerDisplayName')
    ..aOS(7, _omitFieldNames ? '' : 'syncLyricsUri')
    ..pPM<Alternative>(9, _omitFieldNames ? '' : 'alternatives',
        subBuilder: Alternative.$_createMessage)
    ..aOS(10, _omitFieldNames ? '' : 'language')
    ..aOB(11, _omitFieldNames ? '' : 'isRtlLanguage')
    ..aI(14, _omitFieldNames ? '' : 'capStatus')
    ..pPS(18, _omitFieldNames ? '' : 'translationLanguages')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LyricsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LyricsResponse copyWith(void Function(LyricsResponse) updates) =>
      super.copyWith((message) => updates(message as LyricsResponse))
          as LyricsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LyricsResponse() / LyricsResponse.new instead')
  static LyricsResponse create() => LyricsResponse._();
  static $pb.GeneratedMessage $_createMessage() => LyricsResponse._();
  @$core.override
  LyricsResponse createEmptyInstance() => LyricsResponse._();
  @$core.pragma('dart2js:noInline')
  static LyricsResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LyricsResponse>(
          LyricsResponse.$_createMessage);
  static LyricsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get syncType => $_getIZ(0);
  @$pb.TagNumber(1)
  set syncType($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSyncType() => $_has(0);
  @$pb.TagNumber(1)
  void clearSyncType() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<LyricsLine> get lines => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get provider => $_getSZ(2);
  @$pb.TagNumber(3)
  set provider($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProvider() => $_has(2);
  @$pb.TagNumber(3)
  void clearProvider() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get providerLyricsId => $_getSZ(3);
  @$pb.TagNumber(4)
  set providerLyricsId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProviderLyricsId() => $_has(3);
  @$pb.TagNumber(4)
  void clearProviderLyricsId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get providerDisplayName => $_getSZ(4);
  @$pb.TagNumber(5)
  set providerDisplayName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProviderDisplayName() => $_has(4);
  @$pb.TagNumber(5)
  void clearProviderDisplayName() => $_clearField(5);

  @$pb.TagNumber(7)
  $core.String get syncLyricsUri => $_getSZ(5);
  @$pb.TagNumber(7)
  set syncLyricsUri($core.String value) => $_setString(5, value);
  @$pb.TagNumber(7)
  $core.bool hasSyncLyricsUri() => $_has(5);
  @$pb.TagNumber(7)
  void clearSyncLyricsUri() => $_clearField(7);

  @$pb.TagNumber(9)
  $pb.PbList<Alternative> get alternatives => $_getList(6);

  @$pb.TagNumber(10)
  $core.String get language => $_getSZ(7);
  @$pb.TagNumber(10)
  set language($core.String value) => $_setString(7, value);
  @$pb.TagNumber(10)
  $core.bool hasLanguage() => $_has(7);
  @$pb.TagNumber(10)
  void clearLanguage() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get isRtlLanguage => $_getBF(8);
  @$pb.TagNumber(11)
  set isRtlLanguage($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(11)
  $core.bool hasIsRtlLanguage() => $_has(8);
  @$pb.TagNumber(11)
  void clearIsRtlLanguage() => $_clearField(11);

  @$pb.TagNumber(14)
  $core.int get capStatus => $_getIZ(9);
  @$pb.TagNumber(14)
  set capStatus($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(14)
  $core.bool hasCapStatus() => $_has(9);
  @$pb.TagNumber(14)
  void clearCapStatus() => $_clearField(14);

  @$pb.TagNumber(18)
  $pb.PbList<$core.String> get translationLanguages => $_getList(10);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
