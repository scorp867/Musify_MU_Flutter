// This is a generated file - do not edit.
//
// Generated from spotify/contentagnostic/v2/on_platform_reputation_trait.proto.

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

/// / Verification status for an artist entity.
/// / Decompiled from `Verification.java`.
class Verification extends $pb.GeneratedMessage {
  factory Verification({
    $core.bool? isRegistered,
    $core.bool? isVerified,
  }) {
    final result = Verification._();
    if (isRegistered != null) result.isRegistered = isRegistered;
    if (isVerified != null) result.isVerified = isVerified;
    return result;
  }

  Verification._();

  factory Verification.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Verification()..mergeFromBuffer(data, registry);
  factory Verification.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Verification()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Verification',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: Verification.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'isRegistered')
    ..aOB(2, _omitFieldNames ? '' : 'isVerified')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Verification clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Verification copyWith(void Function(Verification) updates) =>
      super.copyWith((message) => updates(message as Verification))
          as Verification;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Verification() / Verification.new instead')
  static Verification create() => Verification._();
  static $pb.GeneratedMessage $_createMessage() => Verification._();
  @$core.override
  Verification createEmptyInstance() => Verification._();
  @$core.pragma('dart2js:noInline')
  static Verification getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Verification>(
          Verification.$_createMessage);
  static Verification? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isRegistered => $_getBF(0);
  @$pb.TagNumber(1)
  set isRegistered($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIsRegistered() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsRegistered() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isVerified => $_getBF(1);
  @$pb.TagNumber(2)
  set isVerified($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsVerified() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsVerified() => $_clearField(2);
}

/// / Chart position data.
/// / Decompiled from `ChartPosition.java`.
class ChartPosition extends $pb.GeneratedMessage {
  factory ChartPosition({
    $core.String? chartUrl,
    $core.String? description,
  }) {
    final result = ChartPosition._();
    if (chartUrl != null) result.chartUrl = chartUrl;
    if (description != null) result.description = description;
    return result;
  }

  ChartPosition._();

  factory ChartPosition.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChartPosition()..mergeFromBuffer(data, registry);
  factory ChartPosition.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChartPosition()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChartPosition',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: ChartPosition.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'chartUrl')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChartPosition clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChartPosition copyWith(void Function(ChartPosition) updates) =>
      super.copyWith((message) => updates(message as ChartPosition))
          as ChartPosition;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ChartPosition() / ChartPosition.new instead')
  static ChartPosition create() => ChartPosition._();
  static $pb.GeneratedMessage $_createMessage() => ChartPosition._();
  @$core.override
  ChartPosition createEmptyInstance() => ChartPosition._();
  @$core.pragma('dart2js:noInline')
  static ChartPosition getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChartPosition>(
          ChartPosition.$_createMessage);
  static ChartPosition? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get chartUrl => $_getSZ(0);
  @$pb.TagNumber(1)
  set chartUrl($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChartUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearChartUrl() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get description => $_getSZ(1);
  @$pb.TagNumber(2)
  set description($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => $_clearField(2);
}

/// / Rating data.
/// / Decompiled from `Rating.java`.
class Rating extends $pb.GeneratedMessage {
  factory Rating({
    $core.double? average,
    $core.int? count,
  }) {
    final result = Rating._();
    if (average != null) result.average = average;
    if (count != null) result.count = count;
    return result;
  }

  Rating._();

  factory Rating.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Rating()..mergeFromBuffer(data, registry);
  factory Rating.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Rating()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Rating',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: Rating.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'average')
    ..aI(2, _omitFieldNames ? '' : 'count')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Rating clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Rating copyWith(void Function(Rating) updates) =>
      super.copyWith((message) => updates(message as Rating)) as Rating;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Rating() / Rating.new instead')
  static Rating create() => Rating._();
  static $pb.GeneratedMessage $_createMessage() => Rating._();
  @$core.override
  Rating createEmptyInstance() => Rating._();
  @$core.pragma('dart2js:noInline')
  static Rating getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Rating>(Rating.$_createMessage);
  static Rating? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get average => $_getN(0);
  @$pb.TagNumber(1)
  set average($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAverage() => $_has(0);
  @$pb.TagNumber(1)
  void clearAverage() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get count => $_getIZ(1);
  @$pb.TagNumber(2)
  set count($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearCount() => $_clearField(2);
}

/// / ExtensionKind 185 — ON_PLATFORM_REPUTATION_TRAIT.
/// / Decompiled from `OnPlatformReputationTrait.java`.
/// /
/// / Provides monthly listeners, verification status, total plays, etc.
/// / Used by the "About the artist" card to show real metrics.
class OnPlatformReputationTrait extends $pb.GeneratedMessage {
  factory OnPlatformReputationTrait({
    $fixnum.Int64? totalEstablishedUserRelationships,
    $fixnum.Int64? totalPlays,
    $fixnum.Int64? monthlyListeners,
    ChartPosition? chartPosition,
    Rating? rating,
    Verification? verification,
  }) {
    final result = OnPlatformReputationTrait._();
    if (totalEstablishedUserRelationships != null)
      result.totalEstablishedUserRelationships =
          totalEstablishedUserRelationships;
    if (totalPlays != null) result.totalPlays = totalPlays;
    if (monthlyListeners != null) result.monthlyListeners = monthlyListeners;
    if (chartPosition != null) result.chartPosition = chartPosition;
    if (rating != null) result.rating = rating;
    if (verification != null) result.verification = verification;
    return result;
  }

  OnPlatformReputationTrait._();

  factory OnPlatformReputationTrait.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OnPlatformReputationTrait()..mergeFromBuffer(data, registry);
  factory OnPlatformReputationTrait.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OnPlatformReputationTrait()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OnPlatformReputationTrait',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: OnPlatformReputationTrait.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'totalEstablishedUserRelationships')
    ..aInt64(3, _omitFieldNames ? '' : 'totalPlays')
    ..aInt64(4, _omitFieldNames ? '' : 'monthlyListeners')
    ..aOM<ChartPosition>(7, _omitFieldNames ? '' : 'chartPosition',
        subBuilder: ChartPosition.$_createMessage)
    ..aOM<Rating>(8, _omitFieldNames ? '' : 'rating',
        subBuilder: Rating.$_createMessage)
    ..aOM<Verification>(9, _omitFieldNames ? '' : 'verification',
        subBuilder: Verification.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OnPlatformReputationTrait clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OnPlatformReputationTrait copyWith(
          void Function(OnPlatformReputationTrait) updates) =>
      super.copyWith((message) => updates(message as OnPlatformReputationTrait))
          as OnPlatformReputationTrait;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use OnPlatformReputationTrait() / OnPlatformReputationTrait.new instead')
  static OnPlatformReputationTrait create() => OnPlatformReputationTrait._();
  static $pb.GeneratedMessage $_createMessage() =>
      OnPlatformReputationTrait._();
  @$core.override
  OnPlatformReputationTrait createEmptyInstance() =>
      OnPlatformReputationTrait._();
  @$core.pragma('dart2js:noInline')
  static OnPlatformReputationTrait getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OnPlatformReputationTrait>(
          OnPlatformReputationTrait.$_createMessage);
  static OnPlatformReputationTrait? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get totalEstablishedUserRelationships => $_getI64(0);
  @$pb.TagNumber(1)
  set totalEstablishedUserRelationships($fixnum.Int64 value) =>
      $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTotalEstablishedUserRelationships() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotalEstablishedUserRelationships() => $_clearField(1);

  /// field 2: reserved
  @$pb.TagNumber(3)
  $fixnum.Int64 get totalPlays => $_getI64(1);
  @$pb.TagNumber(3)
  set totalPlays($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(3)
  $core.bool hasTotalPlays() => $_has(1);
  @$pb.TagNumber(3)
  void clearTotalPlays() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get monthlyListeners => $_getI64(2);
  @$pb.TagNumber(4)
  set monthlyListeners($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(4)
  $core.bool hasMonthlyListeners() => $_has(2);
  @$pb.TagNumber(4)
  void clearMonthlyListeners() => $_clearField(4);

  /// fields 5-6: reserved
  @$pb.TagNumber(7)
  ChartPosition get chartPosition => $_getN(3);
  @$pb.TagNumber(7)
  set chartPosition(ChartPosition value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasChartPosition() => $_has(3);
  @$pb.TagNumber(7)
  void clearChartPosition() => $_clearField(7);
  @$pb.TagNumber(7)
  ChartPosition ensureChartPosition() => $_ensure(3);

  @$pb.TagNumber(8)
  Rating get rating => $_getN(4);
  @$pb.TagNumber(8)
  set rating(Rating value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasRating() => $_has(4);
  @$pb.TagNumber(8)
  void clearRating() => $_clearField(8);
  @$pb.TagNumber(8)
  Rating ensureRating() => $_ensure(4);

  @$pb.TagNumber(9)
  Verification get verification => $_getN(5);
  @$pb.TagNumber(9)
  set verification(Verification value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasVerification() => $_has(5);
  @$pb.TagNumber(9)
  void clearVerification() => $_clearField(9);
  @$pb.TagNumber(9)
  Verification ensureVerification() => $_ensure(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
