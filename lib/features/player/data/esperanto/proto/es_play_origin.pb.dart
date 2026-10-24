// This is a generated file - do not edit.
//
// Generated from es_play_origin.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class PlayOrigin extends $pb.GeneratedMessage {
  factory PlayOrigin({
    $core.String? featureIdentifier,
    $core.String? featureVersion,
    $core.String? viewUri,
    $core.String? externalReferrer,
    $core.String? referrerIdentifier,
    $core.String? deviceIdentifier,
    $core.Iterable<$core.String>? featureClasses,
    $core.String? restrictionIdentifier,
  }) {
    final result = PlayOrigin._();
    if (featureIdentifier != null) result.featureIdentifier = featureIdentifier;
    if (featureVersion != null) result.featureVersion = featureVersion;
    if (viewUri != null) result.viewUri = viewUri;
    if (externalReferrer != null) result.externalReferrer = externalReferrer;
    if (referrerIdentifier != null)
      result.referrerIdentifier = referrerIdentifier;
    if (deviceIdentifier != null) result.deviceIdentifier = deviceIdentifier;
    if (featureClasses != null) result.featureClasses.addAll(featureClasses);
    if (restrictionIdentifier != null)
      result.restrictionIdentifier = restrictionIdentifier;
    return result;
  }

  PlayOrigin._();

  factory PlayOrigin.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayOrigin()..mergeFromBuffer(data, registry);
  factory PlayOrigin.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayOrigin()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayOrigin',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: PlayOrigin.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'featureIdentifier')
    ..aOS(2, _omitFieldNames ? '' : 'featureVersion')
    ..aOS(3, _omitFieldNames ? '' : 'viewUri')
    ..aOS(4, _omitFieldNames ? '' : 'externalReferrer')
    ..aOS(5, _omitFieldNames ? '' : 'referrerIdentifier')
    ..aOS(6, _omitFieldNames ? '' : 'deviceIdentifier')
    ..pPS(7, _omitFieldNames ? '' : 'featureClasses')
    ..aOS(8, _omitFieldNames ? '' : 'restrictionIdentifier')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayOrigin clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayOrigin copyWith(void Function(PlayOrigin) updates) =>
      super.copyWith((message) => updates(message as PlayOrigin)) as PlayOrigin;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PlayOrigin() / PlayOrigin.new instead')
  static PlayOrigin create() => PlayOrigin._();
  static $pb.GeneratedMessage $_createMessage() => PlayOrigin._();
  @$core.override
  PlayOrigin createEmptyInstance() => PlayOrigin._();
  @$core.pragma('dart2js:noInline')
  static PlayOrigin getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlayOrigin>(PlayOrigin.$_createMessage);
  static PlayOrigin? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get featureIdentifier => $_getSZ(0);
  @$pb.TagNumber(1)
  set featureIdentifier($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFeatureIdentifier() => $_has(0);
  @$pb.TagNumber(1)
  void clearFeatureIdentifier() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get featureVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set featureVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFeatureVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearFeatureVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get viewUri => $_getSZ(2);
  @$pb.TagNumber(3)
  set viewUri($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasViewUri() => $_has(2);
  @$pb.TagNumber(3)
  void clearViewUri() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get externalReferrer => $_getSZ(3);
  @$pb.TagNumber(4)
  set externalReferrer($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasExternalReferrer() => $_has(3);
  @$pb.TagNumber(4)
  void clearExternalReferrer() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get referrerIdentifier => $_getSZ(4);
  @$pb.TagNumber(5)
  set referrerIdentifier($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasReferrerIdentifier() => $_has(4);
  @$pb.TagNumber(5)
  void clearReferrerIdentifier() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get deviceIdentifier => $_getSZ(5);
  @$pb.TagNumber(6)
  set deviceIdentifier($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDeviceIdentifier() => $_has(5);
  @$pb.TagNumber(6)
  void clearDeviceIdentifier() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get featureClasses => $_getList(6);

  @$pb.TagNumber(8)
  $core.String get restrictionIdentifier => $_getSZ(7);
  @$pb.TagNumber(8)
  set restrictionIdentifier($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasRestrictionIdentifier() => $_has(7);
  @$pb.TagNumber(8)
  void clearRestrictionIdentifier() => $_clearField(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
