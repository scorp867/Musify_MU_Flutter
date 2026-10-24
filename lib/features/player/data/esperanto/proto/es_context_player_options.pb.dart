// This is a generated file - do not edit.
//
// Generated from es_context_player_options.proto.

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

class ContextPlayerOptions extends $pb.GeneratedMessage {
  factory ContextPlayerOptions({
    $core.bool? shufflingContext,
    $core.bool? repeatingContext,
    $core.bool? repeatingTrack,
    $core.double? playbackSpeed,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? modes,
  }) {
    final result = ContextPlayerOptions._();
    if (shufflingContext != null) result.shufflingContext = shufflingContext;
    if (repeatingContext != null) result.repeatingContext = repeatingContext;
    if (repeatingTrack != null) result.repeatingTrack = repeatingTrack;
    if (playbackSpeed != null) result.playbackSpeed = playbackSpeed;
    if (modes != null) result.modes.addEntries(modes);
    return result;
  }

  ContextPlayerOptions._();

  factory ContextPlayerOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContextPlayerOptions()..mergeFromBuffer(data, registry);
  factory ContextPlayerOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContextPlayerOptions()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextPlayerOptions',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: ContextPlayerOptions.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'shufflingContext')
    ..aOB(2, _omitFieldNames ? '' : 'repeatingContext')
    ..aOB(3, _omitFieldNames ? '' : 'repeatingTrack')
    ..aD(4, _omitFieldNames ? '' : 'playbackSpeed',
        fieldType: $pb.PbFieldType.OF)
    ..m<$core.String, $core.String>(5, _omitFieldNames ? '' : 'modes',
        entryClassName: 'ContextPlayerOptions.ModesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('spotify.player.esperanto.proto'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextPlayerOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextPlayerOptions copyWith(void Function(ContextPlayerOptions) updates) =>
      super.copyWith((message) => updates(message as ContextPlayerOptions))
          as ContextPlayerOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ContextPlayerOptions() / ContextPlayerOptions.new instead')
  static ContextPlayerOptions create() => ContextPlayerOptions._();
  static $pb.GeneratedMessage $_createMessage() => ContextPlayerOptions._();
  @$core.override
  ContextPlayerOptions createEmptyInstance() => ContextPlayerOptions._();
  @$core.pragma('dart2js:noInline')
  static ContextPlayerOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContextPlayerOptions>(
          ContextPlayerOptions.$_createMessage);
  static ContextPlayerOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get shufflingContext => $_getBF(0);
  @$pb.TagNumber(1)
  set shufflingContext($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasShufflingContext() => $_has(0);
  @$pb.TagNumber(1)
  void clearShufflingContext() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get repeatingContext => $_getBF(1);
  @$pb.TagNumber(2)
  set repeatingContext($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRepeatingContext() => $_has(1);
  @$pb.TagNumber(2)
  void clearRepeatingContext() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get repeatingTrack => $_getBF(2);
  @$pb.TagNumber(3)
  set repeatingTrack($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRepeatingTrack() => $_has(2);
  @$pb.TagNumber(3)
  void clearRepeatingTrack() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get playbackSpeed => $_getN(3);
  @$pb.TagNumber(4)
  set playbackSpeed($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPlaybackSpeed() => $_has(3);
  @$pb.TagNumber(4)
  void clearPlaybackSpeed() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbMap<$core.String, $core.String> get modes => $_getMap(4);
}

class ContextPlayerOptionOverrides extends $pb.GeneratedMessage {
  factory ContextPlayerOptionOverrides({
    $0.OptionalBoolean? shufflingContext,
    $0.OptionalBoolean? repeatingContext,
    $0.OptionalBoolean? repeatingTrack,
    $core.double? playbackSpeed,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? modes,
  }) {
    final result = ContextPlayerOptionOverrides._();
    if (shufflingContext != null) result.shufflingContext = shufflingContext;
    if (repeatingContext != null) result.repeatingContext = repeatingContext;
    if (repeatingTrack != null) result.repeatingTrack = repeatingTrack;
    if (playbackSpeed != null) result.playbackSpeed = playbackSpeed;
    if (modes != null) result.modes.addEntries(modes);
    return result;
  }

  ContextPlayerOptionOverrides._();

  factory ContextPlayerOptionOverrides.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContextPlayerOptionOverrides()..mergeFromBuffer(data, registry);
  factory ContextPlayerOptionOverrides.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContextPlayerOptionOverrides()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextPlayerOptionOverrides',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: ContextPlayerOptionOverrides.$_createMessage)
    ..aOM<$0.OptionalBoolean>(1, _omitFieldNames ? '' : 'shufflingContext',
        subBuilder: $0.OptionalBoolean.$_createMessage)
    ..aOM<$0.OptionalBoolean>(2, _omitFieldNames ? '' : 'repeatingContext',
        subBuilder: $0.OptionalBoolean.$_createMessage)
    ..aOM<$0.OptionalBoolean>(3, _omitFieldNames ? '' : 'repeatingTrack',
        subBuilder: $0.OptionalBoolean.$_createMessage)
    ..aD(4, _omitFieldNames ? '' : 'playbackSpeed',
        fieldType: $pb.PbFieldType.OF)
    ..m<$core.String, $core.String>(5, _omitFieldNames ? '' : 'modes',
        entryClassName: 'ContextPlayerOptionOverrides.ModesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('spotify.player.esperanto.proto'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextPlayerOptionOverrides clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextPlayerOptionOverrides copyWith(
          void Function(ContextPlayerOptionOverrides) updates) =>
      super.copyWith(
              (message) => updates(message as ContextPlayerOptionOverrides))
          as ContextPlayerOptionOverrides;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ContextPlayerOptionOverrides() / ContextPlayerOptionOverrides.new instead')
  static ContextPlayerOptionOverrides create() =>
      ContextPlayerOptionOverrides._();
  static $pb.GeneratedMessage $_createMessage() =>
      ContextPlayerOptionOverrides._();
  @$core.override
  ContextPlayerOptionOverrides createEmptyInstance() =>
      ContextPlayerOptionOverrides._();
  @$core.pragma('dart2js:noInline')
  static ContextPlayerOptionOverrides getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContextPlayerOptionOverrides>(
          ContextPlayerOptionOverrides.$_createMessage);
  static ContextPlayerOptionOverrides? _defaultInstance;

  @$pb.TagNumber(1)
  $0.OptionalBoolean get shufflingContext => $_getN(0);
  @$pb.TagNumber(1)
  set shufflingContext($0.OptionalBoolean value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasShufflingContext() => $_has(0);
  @$pb.TagNumber(1)
  void clearShufflingContext() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.OptionalBoolean ensureShufflingContext() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.OptionalBoolean get repeatingContext => $_getN(1);
  @$pb.TagNumber(2)
  set repeatingContext($0.OptionalBoolean value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRepeatingContext() => $_has(1);
  @$pb.TagNumber(2)
  void clearRepeatingContext() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.OptionalBoolean ensureRepeatingContext() => $_ensure(1);

  @$pb.TagNumber(3)
  $0.OptionalBoolean get repeatingTrack => $_getN(2);
  @$pb.TagNumber(3)
  set repeatingTrack($0.OptionalBoolean value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRepeatingTrack() => $_has(2);
  @$pb.TagNumber(3)
  void clearRepeatingTrack() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.OptionalBoolean ensureRepeatingTrack() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.double get playbackSpeed => $_getN(3);
  @$pb.TagNumber(4)
  set playbackSpeed($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPlaybackSpeed() => $_has(3);
  @$pb.TagNumber(4)
  void clearPlaybackSpeed() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbMap<$core.String, $core.String> get modes => $_getMap(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
