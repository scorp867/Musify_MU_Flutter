// This is a generated file - do not edit.
//
// Generated from es_resume.proto.

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
import 'es_pauseresume_origin.pb.dart' as $2;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ResumeRequest extends $pb.GeneratedMessage {
  factory ResumeRequest({
    $0.CommandOptions? options,
    $1.LoggingParams? loggingParams,
    $2.PauseResumeOrigin? resumeOrigin,
  }) {
    final result = ResumeRequest._();
    if (options != null) result.options = options;
    if (loggingParams != null) result.loggingParams = loggingParams;
    if (resumeOrigin != null) result.resumeOrigin = resumeOrigin;
    return result;
  }

  ResumeRequest._();

  factory ResumeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResumeRequest()..mergeFromBuffer(data, registry);
  factory ResumeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResumeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResumeRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: ResumeRequest.$_createMessage)
    ..aOM<$0.CommandOptions>(1, _omitFieldNames ? '' : 'options',
        subBuilder: $0.CommandOptions.$_createMessage)
    ..aOM<$1.LoggingParams>(2, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..aOM<$2.PauseResumeOrigin>(3, _omitFieldNames ? '' : 'resumeOrigin',
        subBuilder: $2.PauseResumeOrigin.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResumeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResumeRequest copyWith(void Function(ResumeRequest) updates) =>
      super.copyWith((message) => updates(message as ResumeRequest))
          as ResumeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResumeRequest() / ResumeRequest.new instead')
  static ResumeRequest create() => ResumeRequest._();
  static $pb.GeneratedMessage $_createMessage() => ResumeRequest._();
  @$core.override
  ResumeRequest createEmptyInstance() => ResumeRequest._();
  @$core.pragma('dart2js:noInline')
  static ResumeRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResumeRequest>(
          ResumeRequest.$_createMessage);
  static ResumeRequest? _defaultInstance;

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
  $1.LoggingParams get loggingParams => $_getN(1);
  @$pb.TagNumber(2)
  set loggingParams($1.LoggingParams value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLoggingParams() => $_has(1);
  @$pb.TagNumber(2)
  void clearLoggingParams() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.LoggingParams ensureLoggingParams() => $_ensure(1);

  @$pb.TagNumber(3)
  $2.PauseResumeOrigin get resumeOrigin => $_getN(2);
  @$pb.TagNumber(3)
  set resumeOrigin($2.PauseResumeOrigin value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasResumeOrigin() => $_has(2);
  @$pb.TagNumber(3)
  void clearResumeOrigin() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.PauseResumeOrigin ensureResumeOrigin() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
