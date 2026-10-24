// This is a generated file - do not edit.
//
// Generated from es_set_options.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'es_command_options.pb.dart' as $1;
import 'es_logging_params.pb.dart' as $2;
import 'es_optional.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SetOptionsRequest extends $pb.GeneratedMessage {
  factory SetOptionsRequest({
    $0.OptionalBoolean? repeatingTrack,
    $0.OptionalBoolean? repeatingContext,
    $0.OptionalBoolean? shufflingContext,
    $1.CommandOptions? options,
    $2.LoggingParams? loggingParams,
    $core.double? playbackSpeed,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? modes,
  }) {
    final result = SetOptionsRequest._();
    if (repeatingTrack != null) result.repeatingTrack = repeatingTrack;
    if (repeatingContext != null) result.repeatingContext = repeatingContext;
    if (shufflingContext != null) result.shufflingContext = shufflingContext;
    if (options != null) result.options = options;
    if (loggingParams != null) result.loggingParams = loggingParams;
    if (playbackSpeed != null) result.playbackSpeed = playbackSpeed;
    if (modes != null) result.modes.addEntries(modes);
    return result;
  }

  SetOptionsRequest._();

  factory SetOptionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetOptionsRequest()..mergeFromBuffer(data, registry);
  factory SetOptionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetOptionsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetOptionsRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: SetOptionsRequest.$_createMessage)
    ..aOM<$0.OptionalBoolean>(1, _omitFieldNames ? '' : 'repeatingTrack',
        subBuilder: $0.OptionalBoolean.$_createMessage)
    ..aOM<$0.OptionalBoolean>(2, _omitFieldNames ? '' : 'repeatingContext',
        subBuilder: $0.OptionalBoolean.$_createMessage)
    ..aOM<$0.OptionalBoolean>(3, _omitFieldNames ? '' : 'shufflingContext',
        subBuilder: $0.OptionalBoolean.$_createMessage)
    ..aOM<$1.CommandOptions>(4, _omitFieldNames ? '' : 'options',
        subBuilder: $1.CommandOptions.$_createMessage)
    ..aOM<$2.LoggingParams>(5, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $2.LoggingParams.$_createMessage)
    ..aD(6, _omitFieldNames ? '' : 'playbackSpeed',
        fieldType: $pb.PbFieldType.OF)
    ..m<$core.String, $core.String>(7, _omitFieldNames ? '' : 'modes',
        entryClassName: 'SetOptionsRequest.ModesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('spotify.player.esperanto.proto'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetOptionsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetOptionsRequest copyWith(void Function(SetOptionsRequest) updates) =>
      super.copyWith((message) => updates(message as SetOptionsRequest))
          as SetOptionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetOptionsRequest() / SetOptionsRequest.new instead')
  static SetOptionsRequest create() => SetOptionsRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetOptionsRequest._();
  @$core.override
  SetOptionsRequest createEmptyInstance() => SetOptionsRequest._();
  @$core.pragma('dart2js:noInline')
  static SetOptionsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetOptionsRequest>(
          SetOptionsRequest.$_createMessage);
  static SetOptionsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $0.OptionalBoolean get repeatingTrack => $_getN(0);
  @$pb.TagNumber(1)
  set repeatingTrack($0.OptionalBoolean value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRepeatingTrack() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepeatingTrack() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.OptionalBoolean ensureRepeatingTrack() => $_ensure(0);

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
  $0.OptionalBoolean get shufflingContext => $_getN(2);
  @$pb.TagNumber(3)
  set shufflingContext($0.OptionalBoolean value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasShufflingContext() => $_has(2);
  @$pb.TagNumber(3)
  void clearShufflingContext() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.OptionalBoolean ensureShufflingContext() => $_ensure(2);

  @$pb.TagNumber(4)
  $1.CommandOptions get options => $_getN(3);
  @$pb.TagNumber(4)
  set options($1.CommandOptions value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasOptions() => $_has(3);
  @$pb.TagNumber(4)
  void clearOptions() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.CommandOptions ensureOptions() => $_ensure(3);

  @$pb.TagNumber(5)
  $2.LoggingParams get loggingParams => $_getN(4);
  @$pb.TagNumber(5)
  set loggingParams($2.LoggingParams value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasLoggingParams() => $_has(4);
  @$pb.TagNumber(5)
  void clearLoggingParams() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.LoggingParams ensureLoggingParams() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.double get playbackSpeed => $_getN(5);
  @$pb.TagNumber(6)
  set playbackSpeed($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPlaybackSpeed() => $_has(5);
  @$pb.TagNumber(6)
  void clearPlaybackSpeed() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbMap<$core.String, $core.String> get modes => $_getMap(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
