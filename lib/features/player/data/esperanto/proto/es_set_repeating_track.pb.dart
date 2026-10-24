// This is a generated file - do not edit.
//
// Generated from es_set_repeating_track.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'es_command_options.pb.dart' as $0;
import 'es_logging_params.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SetRepeatingTrackRequest extends $pb.GeneratedMessage {
  factory SetRepeatingTrackRequest({
    $core.bool? repeatingTrack,
    $0.CommandOptions? options,
    $1.LoggingParams? loggingParams,
  }) {
    final result = SetRepeatingTrackRequest._();
    if (repeatingTrack != null) result.repeatingTrack = repeatingTrack;
    if (options != null) result.options = options;
    if (loggingParams != null) result.loggingParams = loggingParams;
    return result;
  }

  SetRepeatingTrackRequest._();

  factory SetRepeatingTrackRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetRepeatingTrackRequest()..mergeFromBuffer(data, registry);
  factory SetRepeatingTrackRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetRepeatingTrackRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetRepeatingTrackRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: SetRepeatingTrackRequest.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'repeatingTrack')
    ..aOM<$0.CommandOptions>(2, _omitFieldNames ? '' : 'options',
        subBuilder: $0.CommandOptions.$_createMessage)
    ..aOM<$1.LoggingParams>(3, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRepeatingTrackRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRepeatingTrackRequest copyWith(
          void Function(SetRepeatingTrackRequest) updates) =>
      super.copyWith((message) => updates(message as SetRepeatingTrackRequest))
          as SetRepeatingTrackRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetRepeatingTrackRequest() / SetRepeatingTrackRequest.new instead')
  static SetRepeatingTrackRequest create() => SetRepeatingTrackRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetRepeatingTrackRequest._();
  @$core.override
  SetRepeatingTrackRequest createEmptyInstance() =>
      SetRepeatingTrackRequest._();
  @$core.pragma('dart2js:noInline')
  static SetRepeatingTrackRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetRepeatingTrackRequest>(
          SetRepeatingTrackRequest.$_createMessage);
  static SetRepeatingTrackRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get repeatingTrack => $_getBF(0);
  @$pb.TagNumber(1)
  set repeatingTrack($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepeatingTrack() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepeatingTrack() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.CommandOptions get options => $_getN(1);
  @$pb.TagNumber(2)
  set options($0.CommandOptions value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOptions() => $_has(1);
  @$pb.TagNumber(2)
  void clearOptions() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.CommandOptions ensureOptions() => $_ensure(1);

  @$pb.TagNumber(3)
  $1.LoggingParams get loggingParams => $_getN(2);
  @$pb.TagNumber(3)
  set loggingParams($1.LoggingParams value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasLoggingParams() => $_has(2);
  @$pb.TagNumber(3)
  void clearLoggingParams() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.LoggingParams ensureLoggingParams() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
