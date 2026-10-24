// This is a generated file - do not edit.
//
// Generated from es_context_player_error.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'es_context_player_error.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'es_context_player_error.pbenum.dart';

class ContextPlayerError extends $pb.GeneratedMessage {
  factory ContextPlayerError({
    ContextPlayerError_ErrorCode? code,
    $core.String? message,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? data,
  }) {
    final result = ContextPlayerError._();
    if (code != null) result.code = code;
    if (message != null) result.message = message;
    if (data != null) result.data.addEntries(data);
    return result;
  }

  ContextPlayerError._();

  factory ContextPlayerError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContextPlayerError()..mergeFromBuffer(data, registry);
  factory ContextPlayerError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContextPlayerError()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextPlayerError',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: ContextPlayerError.$_createMessage)
    ..aE<ContextPlayerError_ErrorCode>(1, _omitFieldNames ? '' : 'code',
        enumValues: ContextPlayerError_ErrorCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..m<$core.String, $core.String>(3, _omitFieldNames ? '' : 'data',
        entryClassName: 'ContextPlayerError.DataEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('spotify.player.esperanto.proto'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextPlayerError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextPlayerError copyWith(void Function(ContextPlayerError) updates) =>
      super.copyWith((message) => updates(message as ContextPlayerError))
          as ContextPlayerError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ContextPlayerError() / ContextPlayerError.new instead')
  static ContextPlayerError create() => ContextPlayerError._();
  static $pb.GeneratedMessage $_createMessage() => ContextPlayerError._();
  @$core.override
  ContextPlayerError createEmptyInstance() => ContextPlayerError._();
  @$core.pragma('dart2js:noInline')
  static ContextPlayerError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContextPlayerError>(
          ContextPlayerError.$_createMessage);
  static ContextPlayerError? _defaultInstance;

  @$pb.TagNumber(1)
  ContextPlayerError_ErrorCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(ContextPlayerError_ErrorCode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbMap<$core.String, $core.String> get data => $_getMap(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
