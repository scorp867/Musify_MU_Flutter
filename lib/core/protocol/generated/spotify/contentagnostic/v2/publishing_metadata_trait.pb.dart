// This is a generated file - do not edit.
//
// Generated from spotify/contentagnostic/v2/publishing_metadata_trait.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class PublishingMetadataTrait extends $pb.GeneratedMessage {
  factory PublishingMetadataTrait({
    TimestampOfVaryingGranularity? firstPublishedAt,
    $0.Timestamp? publishedOnSpotifyAt,
    $0.Timestamp? lastModifiedAt,
    $core.Iterable<CopyrightInformation>? copyrightInformation,
  }) {
    final result = PublishingMetadataTrait._();
    if (firstPublishedAt != null) result.firstPublishedAt = firstPublishedAt;
    if (publishedOnSpotifyAt != null)
      result.publishedOnSpotifyAt = publishedOnSpotifyAt;
    if (lastModifiedAt != null) result.lastModifiedAt = lastModifiedAt;
    if (copyrightInformation != null)
      result.copyrightInformation.addAll(copyrightInformation);
    return result;
  }

  PublishingMetadataTrait._();

  factory PublishingMetadataTrait.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PublishingMetadataTrait()..mergeFromBuffer(data, registry);
  factory PublishingMetadataTrait.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PublishingMetadataTrait()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PublishingMetadataTrait',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: PublishingMetadataTrait.$_createMessage)
    ..aOM<TimestampOfVaryingGranularity>(
        1, _omitFieldNames ? '' : 'firstPublishedAt',
        subBuilder: TimestampOfVaryingGranularity.$_createMessage)
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'publishedOnSpotifyAt',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOM<$0.Timestamp>(3, _omitFieldNames ? '' : 'lastModifiedAt',
        subBuilder: $0.Timestamp.$_createMessage)
    ..pPM<CopyrightInformation>(
        4, _omitFieldNames ? '' : 'copyrightInformation',
        subBuilder: CopyrightInformation.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishingMetadataTrait clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishingMetadataTrait copyWith(
          void Function(PublishingMetadataTrait) updates) =>
      super.copyWith((message) => updates(message as PublishingMetadataTrait))
          as PublishingMetadataTrait;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PublishingMetadataTrait() / PublishingMetadataTrait.new instead')
  static PublishingMetadataTrait create() => PublishingMetadataTrait._();
  static $pb.GeneratedMessage $_createMessage() => PublishingMetadataTrait._();
  @$core.override
  PublishingMetadataTrait createEmptyInstance() => PublishingMetadataTrait._();
  @$core.pragma('dart2js:noInline')
  static PublishingMetadataTrait getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PublishingMetadataTrait>(
          PublishingMetadataTrait.$_createMessage);
  static PublishingMetadataTrait? _defaultInstance;

  @$pb.TagNumber(1)
  TimestampOfVaryingGranularity get firstPublishedAt => $_getN(0);
  @$pb.TagNumber(1)
  set firstPublishedAt(TimestampOfVaryingGranularity value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFirstPublishedAt() => $_has(0);
  @$pb.TagNumber(1)
  void clearFirstPublishedAt() => $_clearField(1);
  @$pb.TagNumber(1)
  TimestampOfVaryingGranularity ensureFirstPublishedAt() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.Timestamp get publishedOnSpotifyAt => $_getN(1);
  @$pb.TagNumber(2)
  set publishedOnSpotifyAt($0.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPublishedOnSpotifyAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearPublishedOnSpotifyAt() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensurePublishedOnSpotifyAt() => $_ensure(1);

  @$pb.TagNumber(3)
  $0.Timestamp get lastModifiedAt => $_getN(2);
  @$pb.TagNumber(3)
  set lastModifiedAt($0.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasLastModifiedAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearLastModifiedAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Timestamp ensureLastModifiedAt() => $_ensure(2);

  @$pb.TagNumber(4)
  $pb.PbList<CopyrightInformation> get copyrightInformation => $_getList(3);
}

class TimestampOfVaryingGranularity extends $pb.GeneratedMessage {
  factory TimestampOfVaryingGranularity({
    $core.int? year,
    YearAndMonth? yearAndMonth,
    YearMonthAndDay? yearMonthAndDay,
  }) {
    final result = TimestampOfVaryingGranularity._();
    if (year != null) result.year = year;
    if (yearAndMonth != null) result.yearAndMonth = yearAndMonth;
    if (yearMonthAndDay != null) result.yearMonthAndDay = yearMonthAndDay;
    return result;
  }

  TimestampOfVaryingGranularity._();

  factory TimestampOfVaryingGranularity.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TimestampOfVaryingGranularity()..mergeFromBuffer(data, registry);
  factory TimestampOfVaryingGranularity.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TimestampOfVaryingGranularity()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TimestampOfVaryingGranularity',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: TimestampOfVaryingGranularity.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'year')
    ..aOM<YearAndMonth>(2, _omitFieldNames ? '' : 'yearAndMonth',
        subBuilder: YearAndMonth.$_createMessage)
    ..aOM<YearMonthAndDay>(3, _omitFieldNames ? '' : 'yearMonthAndDay',
        subBuilder: YearMonthAndDay.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TimestampOfVaryingGranularity clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TimestampOfVaryingGranularity copyWith(
          void Function(TimestampOfVaryingGranularity) updates) =>
      super.copyWith(
              (message) => updates(message as TimestampOfVaryingGranularity))
          as TimestampOfVaryingGranularity;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use TimestampOfVaryingGranularity() / TimestampOfVaryingGranularity.new instead')
  static TimestampOfVaryingGranularity create() =>
      TimestampOfVaryingGranularity._();
  static $pb.GeneratedMessage $_createMessage() =>
      TimestampOfVaryingGranularity._();
  @$core.override
  TimestampOfVaryingGranularity createEmptyInstance() =>
      TimestampOfVaryingGranularity._();
  @$core.pragma('dart2js:noInline')
  static TimestampOfVaryingGranularity getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TimestampOfVaryingGranularity>(
          TimestampOfVaryingGranularity.$_createMessage);
  static TimestampOfVaryingGranularity? _defaultInstance;

  /// oneof timestamp {
  @$pb.TagNumber(1)
  $core.int get year => $_getIZ(0);
  @$pb.TagNumber(1)
  set year($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasYear() => $_has(0);
  @$pb.TagNumber(1)
  void clearYear() => $_clearField(1);

  @$pb.TagNumber(2)
  YearAndMonth get yearAndMonth => $_getN(1);
  @$pb.TagNumber(2)
  set yearAndMonth(YearAndMonth value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasYearAndMonth() => $_has(1);
  @$pb.TagNumber(2)
  void clearYearAndMonth() => $_clearField(2);
  @$pb.TagNumber(2)
  YearAndMonth ensureYearAndMonth() => $_ensure(1);

  @$pb.TagNumber(3)
  YearMonthAndDay get yearMonthAndDay => $_getN(2);
  @$pb.TagNumber(3)
  set yearMonthAndDay(YearMonthAndDay value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasYearMonthAndDay() => $_has(2);
  @$pb.TagNumber(3)
  void clearYearMonthAndDay() => $_clearField(3);
  @$pb.TagNumber(3)
  YearMonthAndDay ensureYearMonthAndDay() => $_ensure(2);
}

class YearAndMonth extends $pb.GeneratedMessage {
  factory YearAndMonth({
    $core.int? year,
    $core.int? month,
  }) {
    final result = YearAndMonth._();
    if (year != null) result.year = year;
    if (month != null) result.month = month;
    return result;
  }

  YearAndMonth._();

  factory YearAndMonth.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      YearAndMonth()..mergeFromBuffer(data, registry);
  factory YearAndMonth.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      YearAndMonth()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'YearAndMonth',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: YearAndMonth.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'year')
    ..aI(2, _omitFieldNames ? '' : 'month')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  YearAndMonth clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  YearAndMonth copyWith(void Function(YearAndMonth) updates) =>
      super.copyWith((message) => updates(message as YearAndMonth))
          as YearAndMonth;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use YearAndMonth() / YearAndMonth.new instead')
  static YearAndMonth create() => YearAndMonth._();
  static $pb.GeneratedMessage $_createMessage() => YearAndMonth._();
  @$core.override
  YearAndMonth createEmptyInstance() => YearAndMonth._();
  @$core.pragma('dart2js:noInline')
  static YearAndMonth getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<YearAndMonth>(
          YearAndMonth.$_createMessage);
  static YearAndMonth? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get year => $_getIZ(0);
  @$pb.TagNumber(1)
  set year($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasYear() => $_has(0);
  @$pb.TagNumber(1)
  void clearYear() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get month => $_getIZ(1);
  @$pb.TagNumber(2)
  set month($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMonth() => $_has(1);
  @$pb.TagNumber(2)
  void clearMonth() => $_clearField(2);
}

class YearMonthAndDay extends $pb.GeneratedMessage {
  factory YearMonthAndDay({
    $core.int? year,
    $core.int? month,
    $core.int? day,
  }) {
    final result = YearMonthAndDay._();
    if (year != null) result.year = year;
    if (month != null) result.month = month;
    if (day != null) result.day = day;
    return result;
  }

  YearMonthAndDay._();

  factory YearMonthAndDay.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      YearMonthAndDay()..mergeFromBuffer(data, registry);
  factory YearMonthAndDay.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      YearMonthAndDay()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'YearMonthAndDay',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: YearMonthAndDay.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'year')
    ..aI(2, _omitFieldNames ? '' : 'month')
    ..aI(3, _omitFieldNames ? '' : 'day')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  YearMonthAndDay clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  YearMonthAndDay copyWith(void Function(YearMonthAndDay) updates) =>
      super.copyWith((message) => updates(message as YearMonthAndDay))
          as YearMonthAndDay;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use YearMonthAndDay() / YearMonthAndDay.new instead')
  static YearMonthAndDay create() => YearMonthAndDay._();
  static $pb.GeneratedMessage $_createMessage() => YearMonthAndDay._();
  @$core.override
  YearMonthAndDay createEmptyInstance() => YearMonthAndDay._();
  @$core.pragma('dart2js:noInline')
  static YearMonthAndDay getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<YearMonthAndDay>(
          YearMonthAndDay.$_createMessage);
  static YearMonthAndDay? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get year => $_getIZ(0);
  @$pb.TagNumber(1)
  set year($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasYear() => $_has(0);
  @$pb.TagNumber(1)
  void clearYear() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get month => $_getIZ(1);
  @$pb.TagNumber(2)
  set month($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMonth() => $_has(1);
  @$pb.TagNumber(2)
  void clearMonth() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get day => $_getIZ(2);
  @$pb.TagNumber(3)
  set day($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDay() => $_has(2);
  @$pb.TagNumber(3)
  void clearDay() => $_clearField(3);
}

class CopyrightInformation extends $pb.GeneratedMessage {
  factory CopyrightInformation({
    $core.String? type,
    $core.String? text,
  }) {
    final result = CopyrightInformation._();
    if (type != null) result.type = type;
    if (text != null) result.text = text;
    return result;
  }

  CopyrightInformation._();

  factory CopyrightInformation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CopyrightInformation()..mergeFromBuffer(data, registry);
  factory CopyrightInformation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CopyrightInformation()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CopyrightInformation',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: CopyrightInformation.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CopyrightInformation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CopyrightInformation copyWith(void Function(CopyrightInformation) updates) =>
      super.copyWith((message) => updates(message as CopyrightInformation))
          as CopyrightInformation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CopyrightInformation() / CopyrightInformation.new instead')
  static CopyrightInformation create() => CopyrightInformation._();
  static $pb.GeneratedMessage $_createMessage() => CopyrightInformation._();
  @$core.override
  CopyrightInformation createEmptyInstance() => CopyrightInformation._();
  @$core.pragma('dart2js:noInline')
  static CopyrightInformation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CopyrightInformation>(
          CopyrightInformation.$_createMessage);
  static CopyrightInformation? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
