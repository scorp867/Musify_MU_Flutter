// This is a generated file - do not edit.
//
// Generated from es_prepare_play.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'es_context.pb.dart' as $0;
import 'es_play_origin.pb.dart' as $2;
import 'es_prepare_play_options.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class PreparePlayRequest extends $pb.GeneratedMessage {
  factory PreparePlayRequest({
    $0.Context? context,
    $1.PreparePlayOptions? options,
    $2.PlayOrigin? playOrigin,
  }) {
    final result = PreparePlayRequest._();
    if (context != null) result.context = context;
    if (options != null) result.options = options;
    if (playOrigin != null) result.playOrigin = playOrigin;
    return result;
  }

  PreparePlayRequest._();

  factory PreparePlayRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreparePlayRequest()..mergeFromBuffer(data, registry);
  factory PreparePlayRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreparePlayRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreparePlayRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: PreparePlayRequest.$_createMessage)
    ..aOM<$0.Context>(1, _omitFieldNames ? '' : 'context',
        subBuilder: $0.Context.$_createMessage)
    ..aOM<$1.PreparePlayOptions>(2, _omitFieldNames ? '' : 'options',
        subBuilder: $1.PreparePlayOptions.$_createMessage)
    ..aOM<$2.PlayOrigin>(3, _omitFieldNames ? '' : 'playOrigin',
        subBuilder: $2.PlayOrigin.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreparePlayRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreparePlayRequest copyWith(void Function(PreparePlayRequest) updates) =>
      super.copyWith((message) => updates(message as PreparePlayRequest))
          as PreparePlayRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PreparePlayRequest() / PreparePlayRequest.new instead')
  static PreparePlayRequest create() => PreparePlayRequest._();
  static $pb.GeneratedMessage $_createMessage() => PreparePlayRequest._();
  @$core.override
  PreparePlayRequest createEmptyInstance() => PreparePlayRequest._();
  @$core.pragma('dart2js:noInline')
  static PreparePlayRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreparePlayRequest>(
          PreparePlayRequest.$_createMessage);
  static PreparePlayRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Context get context => $_getN(0);
  @$pb.TagNumber(1)
  set context($0.Context value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasContext() => $_has(0);
  @$pb.TagNumber(1)
  void clearContext() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Context ensureContext() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.PreparePlayOptions get options => $_getN(1);
  @$pb.TagNumber(2)
  set options($1.PreparePlayOptions value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOptions() => $_has(1);
  @$pb.TagNumber(2)
  void clearOptions() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.PreparePlayOptions ensureOptions() => $_ensure(1);

  @$pb.TagNumber(3)
  $2.PlayOrigin get playOrigin => $_getN(2);
  @$pb.TagNumber(3)
  set playOrigin($2.PlayOrigin value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPlayOrigin() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlayOrigin() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.PlayOrigin ensurePlayOrigin() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
