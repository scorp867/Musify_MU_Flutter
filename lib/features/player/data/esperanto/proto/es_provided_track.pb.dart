// This is a generated file - do not edit.
//
// Generated from es_provided_track.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'es_context_track.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ProvidedTrack extends $pb.GeneratedMessage {
  factory ProvidedTrack({
    $0.ContextTrack? contextTrack,
    $core.Iterable<$core.String>? removed,
    $core.Iterable<$core.String>? blocked,
    $core.String? provider,
  }) {
    final result = ProvidedTrack._();
    if (contextTrack != null) result.contextTrack = contextTrack;
    if (removed != null) result.removed.addAll(removed);
    if (blocked != null) result.blocked.addAll(blocked);
    if (provider != null) result.provider = provider;
    return result;
  }

  ProvidedTrack._();

  factory ProvidedTrack.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ProvidedTrack()..mergeFromBuffer(data, registry);
  factory ProvidedTrack.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ProvidedTrack()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProvidedTrack',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: ProvidedTrack.$_createMessage)
    ..aOM<$0.ContextTrack>(1, _omitFieldNames ? '' : 'contextTrack',
        subBuilder: $0.ContextTrack.$_createMessage)
    ..pPS(2, _omitFieldNames ? '' : 'removed')
    ..pPS(3, _omitFieldNames ? '' : 'blocked')
    ..aOS(4, _omitFieldNames ? '' : 'provider')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProvidedTrack clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProvidedTrack copyWith(void Function(ProvidedTrack) updates) =>
      super.copyWith((message) => updates(message as ProvidedTrack))
          as ProvidedTrack;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ProvidedTrack() / ProvidedTrack.new instead')
  static ProvidedTrack create() => ProvidedTrack._();
  static $pb.GeneratedMessage $_createMessage() => ProvidedTrack._();
  @$core.override
  ProvidedTrack createEmptyInstance() => ProvidedTrack._();
  @$core.pragma('dart2js:noInline')
  static ProvidedTrack getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ProvidedTrack>(
          ProvidedTrack.$_createMessage);
  static ProvidedTrack? _defaultInstance;

  @$pb.TagNumber(1)
  $0.ContextTrack get contextTrack => $_getN(0);
  @$pb.TagNumber(1)
  set contextTrack($0.ContextTrack value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasContextTrack() => $_has(0);
  @$pb.TagNumber(1)
  void clearContextTrack() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.ContextTrack ensureContextTrack() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get removed => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get blocked => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get provider => $_getSZ(3);
  @$pb.TagNumber(4)
  set provider($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProvider() => $_has(3);
  @$pb.TagNumber(4)
  void clearProvider() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
