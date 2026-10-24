// This is a generated file - do not edit.
//
// Generated from es_skip_prev.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'es_command_options.pb.dart' as $0;
import 'es_context_track.pb.dart' as $2;
import 'es_logging_params.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SkipPrevRequest extends $pb.GeneratedMessage {
  factory SkipPrevRequest({
    $0.CommandOptions? options,
    $core.bool? allowSeeking,
    $1.LoggingParams? loggingParams,
    $2.ContextTrack? track,
  }) {
    final result = SkipPrevRequest._();
    if (options != null) result.options = options;
    if (allowSeeking != null) result.allowSeeking = allowSeeking;
    if (loggingParams != null) result.loggingParams = loggingParams;
    if (track != null) result.track = track;
    return result;
  }

  SkipPrevRequest._();

  factory SkipPrevRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SkipPrevRequest()..mergeFromBuffer(data, registry);
  factory SkipPrevRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SkipPrevRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkipPrevRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: SkipPrevRequest.$_createMessage)
    ..aOM<$0.CommandOptions>(1, _omitFieldNames ? '' : 'options',
        subBuilder: $0.CommandOptions.$_createMessage)
    ..aOB(2, _omitFieldNames ? '' : 'allowSeeking')
    ..aOM<$1.LoggingParams>(3, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..aOM<$2.ContextTrack>(4, _omitFieldNames ? '' : 'track',
        subBuilder: $2.ContextTrack.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkipPrevRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkipPrevRequest copyWith(void Function(SkipPrevRequest) updates) =>
      super.copyWith((message) => updates(message as SkipPrevRequest))
          as SkipPrevRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SkipPrevRequest() / SkipPrevRequest.new instead')
  static SkipPrevRequest create() => SkipPrevRequest._();
  static $pb.GeneratedMessage $_createMessage() => SkipPrevRequest._();
  @$core.override
  SkipPrevRequest createEmptyInstance() => SkipPrevRequest._();
  @$core.pragma('dart2js:noInline')
  static SkipPrevRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SkipPrevRequest>(
          SkipPrevRequest.$_createMessage);
  static SkipPrevRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $0.CommandOptions get options => $_getN(0);
  @$pb.TagNumber(1)
  set options($0.CommandOptions value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOptions() => $_has(0);
  @$pb.TagNumber(1)
  void clearOptions() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.CommandOptions ensureOptions() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get allowSeeking => $_getBF(1);
  @$pb.TagNumber(2)
  set allowSeeking($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAllowSeeking() => $_has(1);
  @$pb.TagNumber(2)
  void clearAllowSeeking() => $_clearField(2);

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

  @$pb.TagNumber(4)
  $2.ContextTrack get track => $_getN(3);
  @$pb.TagNumber(4)
  set track($2.ContextTrack value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasTrack() => $_has(3);
  @$pb.TagNumber(4)
  void clearTrack() => $_clearField(4);
  @$pb.TagNumber(4)
  $2.ContextTrack ensureTrack() => $_ensure(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
