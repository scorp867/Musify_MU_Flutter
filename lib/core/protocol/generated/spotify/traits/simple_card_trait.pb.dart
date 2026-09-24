// This is a generated file - do not edit.
//
// Generated from spotify/traits/simple_card_trait.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/duration.pb.dart'
    as $1;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $0;

import 'simple_card_trait.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'simple_card_trait.pbenum.dart';

class SimpleCardTrait extends $pb.GeneratedMessage {
  factory SimpleCardTrait({
    $core.String? imageUri,
    $core.String? title,
    $core.String? subtitle,
    $core.String? navigationUri,
    $core.Iterable<Label>? labels,
    $core.String? accessibility,
    Restriction? restriction,
    $core.Iterable<Creator>? creators,
    $0.Timestamp? publishTime,
    $1.Duration? duration,
    $core.String? animationUrl,
    $core.String? titleTextColor,
  }) {
    final result = SimpleCardTrait._();
    if (imageUri != null) result.imageUri = imageUri;
    if (title != null) result.title = title;
    if (subtitle != null) result.subtitle = subtitle;
    if (navigationUri != null) result.navigationUri = navigationUri;
    if (labels != null) result.labels.addAll(labels);
    if (accessibility != null) result.accessibility = accessibility;
    if (restriction != null) result.restriction = restriction;
    if (creators != null) result.creators.addAll(creators);
    if (publishTime != null) result.publishTime = publishTime;
    if (duration != null) result.duration = duration;
    if (animationUrl != null) result.animationUrl = animationUrl;
    if (titleTextColor != null) result.titleTextColor = titleTextColor;
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
      package: const $pb.PackageName(_omitMessageNames
          ? ''
          : 'spotify.extendedmetadata.extensions.simplecardtrait'),
      createEmptyInstance: SimpleCardTrait.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'imageUri')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'subtitle')
    ..aOS(4, _omitFieldNames ? '' : 'navigationUri')
    ..pPM<Label>(5, _omitFieldNames ? '' : 'labels',
        subBuilder: Label.$_createMessage)
    ..aOS(6, _omitFieldNames ? '' : 'accessibility')
    ..aE<Restriction>(7, _omitFieldNames ? '' : 'restriction',
        enumValues: Restriction.values)
    ..pPM<Creator>(8, _omitFieldNames ? '' : 'creators',
        subBuilder: Creator.$_createMessage)
    ..aOM<$0.Timestamp>(9, _omitFieldNames ? '' : 'publishTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOM<$1.Duration>(10, _omitFieldNames ? '' : 'duration',
        subBuilder: $1.Duration.$_createMessage)
    ..aOS(11, _omitFieldNames ? '' : 'animationUrl')
    ..aOS(12, _omitFieldNames ? '' : 'titleTextColor')
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
  $core.String get imageUri => $_getSZ(0);
  @$pb.TagNumber(1)
  set imageUri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasImageUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearImageUri() => $_clearField(1);

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

  @$pb.TagNumber(4)
  $core.String get navigationUri => $_getSZ(3);
  @$pb.TagNumber(4)
  set navigationUri($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNavigationUri() => $_has(3);
  @$pb.TagNumber(4)
  void clearNavigationUri() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<Label> get labels => $_getList(4);

  @$pb.TagNumber(6)
  $core.String get accessibility => $_getSZ(5);
  @$pb.TagNumber(6)
  set accessibility($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAccessibility() => $_has(5);
  @$pb.TagNumber(6)
  void clearAccessibility() => $_clearField(6);

  @$pb.TagNumber(7)
  Restriction get restriction => $_getN(6);
  @$pb.TagNumber(7)
  set restriction(Restriction value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasRestriction() => $_has(6);
  @$pb.TagNumber(7)
  void clearRestriction() => $_clearField(7);

  @$pb.TagNumber(8)
  $pb.PbList<Creator> get creators => $_getList(7);

  @$pb.TagNumber(9)
  $0.Timestamp get publishTime => $_getN(8);
  @$pb.TagNumber(9)
  set publishTime($0.Timestamp value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasPublishTime() => $_has(8);
  @$pb.TagNumber(9)
  void clearPublishTime() => $_clearField(9);
  @$pb.TagNumber(9)
  $0.Timestamp ensurePublishTime() => $_ensure(8);

  @$pb.TagNumber(10)
  $1.Duration get duration => $_getN(9);
  @$pb.TagNumber(10)
  set duration($1.Duration value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasDuration() => $_has(9);
  @$pb.TagNumber(10)
  void clearDuration() => $_clearField(10);
  @$pb.TagNumber(10)
  $1.Duration ensureDuration() => $_ensure(9);

  @$pb.TagNumber(11)
  $core.String get animationUrl => $_getSZ(10);
  @$pb.TagNumber(11)
  set animationUrl($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasAnimationUrl() => $_has(10);
  @$pb.TagNumber(11)
  void clearAnimationUrl() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get titleTextColor => $_getSZ(11);
  @$pb.TagNumber(12)
  set titleTextColor($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasTitleTextColor() => $_has(11);
  @$pb.TagNumber(12)
  void clearTitleTextColor() => $_clearField(12);
}

class Label extends $pb.GeneratedMessage {
  factory Label({
    $core.String? text,
  }) {
    final result = Label._();
    if (text != null) result.text = text;
    return result;
  }

  Label._();

  factory Label.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Label()..mergeFromBuffer(data, registry);
  factory Label.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Label()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Label',
      package: const $pb.PackageName(_omitMessageNames
          ? ''
          : 'spotify.extendedmetadata.extensions.simplecardtrait'),
      createEmptyInstance: Label.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Label clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Label copyWith(void Function(Label) updates) =>
      super.copyWith((message) => updates(message as Label)) as Label;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Label() / Label.new instead')
  static Label create() => Label._();
  static $pb.GeneratedMessage $_createMessage() => Label._();
  @$core.override
  Label createEmptyInstance() => Label._();
  @$core.pragma('dart2js:noInline')
  static Label getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Label>(Label.$_createMessage);
  static Label? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);
}

class Creator extends $pb.GeneratedMessage {
  factory Creator({
    $core.String? name,
    $core.String? uri,
  }) {
    final result = Creator._();
    if (name != null) result.name = name;
    if (uri != null) result.uri = uri;
    return result;
  }

  Creator._();

  factory Creator.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Creator()..mergeFromBuffer(data, registry);
  factory Creator.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Creator()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Creator',
      package: const $pb.PackageName(_omitMessageNames
          ? ''
          : 'spotify.extendedmetadata.extensions.simplecardtrait'),
      createEmptyInstance: Creator.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'uri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Creator clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Creator copyWith(void Function(Creator) updates) =>
      super.copyWith((message) => updates(message as Creator)) as Creator;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Creator() / Creator.new instead')
  static Creator create() => Creator._();
  static $pb.GeneratedMessage $_createMessage() => Creator._();
  @$core.override
  Creator createEmptyInstance() => Creator._();
  @$core.pragma('dart2js:noInline')
  static Creator getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Creator>(Creator.$_createMessage);
  static Creator? _defaultInstance;

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
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
