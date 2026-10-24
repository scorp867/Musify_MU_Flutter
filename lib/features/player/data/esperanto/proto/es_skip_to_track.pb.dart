// This is a generated file - do not edit.
//
// Generated from es_skip_to_track.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'es_optional.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SkipToTrack extends $pb.GeneratedMessage {
  factory SkipToTrack({
    $core.String? pageUrl,
    $0.OptionalInt64? pageIndex,
    $core.String? trackUid,
    $core.String? trackUri,
    $0.OptionalInt64? trackIndex,
  }) {
    final result = SkipToTrack._();
    if (pageUrl != null) result.pageUrl = pageUrl;
    if (pageIndex != null) result.pageIndex = pageIndex;
    if (trackUid != null) result.trackUid = trackUid;
    if (trackUri != null) result.trackUri = trackUri;
    if (trackIndex != null) result.trackIndex = trackIndex;
    return result;
  }

  SkipToTrack._();

  factory SkipToTrack.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SkipToTrack()..mergeFromBuffer(data, registry);
  factory SkipToTrack.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SkipToTrack()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkipToTrack',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: SkipToTrack.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pageUrl')
    ..aOM<$0.OptionalInt64>(2, _omitFieldNames ? '' : 'pageIndex',
        subBuilder: $0.OptionalInt64.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'trackUid')
    ..aOS(4, _omitFieldNames ? '' : 'trackUri')
    ..aOM<$0.OptionalInt64>(5, _omitFieldNames ? '' : 'trackIndex',
        subBuilder: $0.OptionalInt64.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkipToTrack clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkipToTrack copyWith(void Function(SkipToTrack) updates) =>
      super.copyWith((message) => updates(message as SkipToTrack))
          as SkipToTrack;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SkipToTrack() / SkipToTrack.new instead')
  static SkipToTrack create() => SkipToTrack._();
  static $pb.GeneratedMessage $_createMessage() => SkipToTrack._();
  @$core.override
  SkipToTrack createEmptyInstance() => SkipToTrack._();
  @$core.pragma('dart2js:noInline')
  static SkipToTrack getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SkipToTrack>(
          SkipToTrack.$_createMessage);
  static SkipToTrack? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pageUrl => $_getSZ(0);
  @$pb.TagNumber(1)
  set pageUrl($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPageUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearPageUrl() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.OptionalInt64 get pageIndex => $_getN(1);
  @$pb.TagNumber(2)
  set pageIndex($0.OptionalInt64 value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPageIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageIndex() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.OptionalInt64 ensurePageIndex() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get trackUid => $_getSZ(2);
  @$pb.TagNumber(3)
  set trackUid($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTrackUid() => $_has(2);
  @$pb.TagNumber(3)
  void clearTrackUid() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get trackUri => $_getSZ(3);
  @$pb.TagNumber(4)
  set trackUri($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTrackUri() => $_has(3);
  @$pb.TagNumber(4)
  void clearTrackUri() => $_clearField(4);

  @$pb.TagNumber(5)
  $0.OptionalInt64 get trackIndex => $_getN(4);
  @$pb.TagNumber(5)
  set trackIndex($0.OptionalInt64 value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasTrackIndex() => $_has(4);
  @$pb.TagNumber(5)
  void clearTrackIndex() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.OptionalInt64 ensureTrackIndex() => $_ensure(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
