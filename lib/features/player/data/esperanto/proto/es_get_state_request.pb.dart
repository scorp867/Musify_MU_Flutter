// This is a generated file - do not edit.
//
// Generated from es_get_state_request.proto.

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

class GetStateRequest extends $pb.GeneratedMessage {
  factory GetStateRequest({
    $0.OptionalInt64? prevTracksCap,
    $0.OptionalInt64? nextTracksCap,
  }) {
    final result = GetStateRequest._();
    if (prevTracksCap != null) result.prevTracksCap = prevTracksCap;
    if (nextTracksCap != null) result.nextTracksCap = nextTracksCap;
    return result;
  }

  GetStateRequest._();

  factory GetStateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStateRequest()..mergeFromBuffer(data, registry);
  factory GetStateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStateRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStateRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: GetStateRequest.$_createMessage)
    ..aOM<$0.OptionalInt64>(1, _omitFieldNames ? '' : 'prevTracksCap',
        subBuilder: $0.OptionalInt64.$_createMessage)
    ..aOM<$0.OptionalInt64>(2, _omitFieldNames ? '' : 'nextTracksCap',
        subBuilder: $0.OptionalInt64.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStateRequest copyWith(void Function(GetStateRequest) updates) =>
      super.copyWith((message) => updates(message as GetStateRequest))
          as GetStateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetStateRequest() / GetStateRequest.new instead')
  static GetStateRequest create() => GetStateRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetStateRequest._();
  @$core.override
  GetStateRequest createEmptyInstance() => GetStateRequest._();
  @$core.pragma('dart2js:noInline')
  static GetStateRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStateRequest>(
          GetStateRequest.$_createMessage);
  static GetStateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $0.OptionalInt64 get prevTracksCap => $_getN(0);
  @$pb.TagNumber(1)
  set prevTracksCap($0.OptionalInt64 value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPrevTracksCap() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrevTracksCap() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.OptionalInt64 ensurePrevTracksCap() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.OptionalInt64 get nextTracksCap => $_getN(1);
  @$pb.TagNumber(2)
  set nextTracksCap($0.OptionalInt64 value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasNextTracksCap() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextTracksCap() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.OptionalInt64 ensureNextTracksCap() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
