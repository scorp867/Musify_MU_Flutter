// This is a generated file - do not edit.
//
// Generated from es_session_response.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SessionResponse extends $pb.GeneratedMessage {
  factory SessionResponse({
    $core.String? sessionId,
  }) {
    final result = SessionResponse._();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  SessionResponse._();

  factory SessionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SessionResponse()..mergeFromBuffer(data, registry);
  factory SessionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SessionResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: SessionResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionResponse copyWith(void Function(SessionResponse) updates) =>
      super.copyWith((message) => updates(message as SessionResponse))
          as SessionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SessionResponse() / SessionResponse.new instead')
  static SessionResponse create() => SessionResponse._();
  static $pb.GeneratedMessage $_createMessage() => SessionResponse._();
  @$core.override
  SessionResponse createEmptyInstance() => SessionResponse._();
  @$core.pragma('dart2js:noInline')
  static SessionResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SessionResponse>(
          SessionResponse.$_createMessage);
  static SessionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
