// This is a generated file - do not edit.
//
// Generated from es_response_with_reasons.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'es_response_with_reasons.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'es_response_with_reasons.pbenum.dart';

class ResponseWithReasons extends $pb.GeneratedMessage {
  factory ResponseWithReasons({
    ResponseWithReasons_Error? error,
    $core.String? reasons,
  }) {
    final result = ResponseWithReasons._();
    if (error != null) result.error = error;
    if (reasons != null) result.reasons = reasons;
    return result;
  }

  ResponseWithReasons._();

  factory ResponseWithReasons.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResponseWithReasons()..mergeFromBuffer(data, registry);
  factory ResponseWithReasons.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResponseWithReasons()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponseWithReasons',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: ResponseWithReasons.$_createMessage)
    ..aE<ResponseWithReasons_Error>(1, _omitFieldNames ? '' : 'error',
        enumValues: ResponseWithReasons_Error.values)
    ..aOS(2, _omitFieldNames ? '' : 'reasons')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseWithReasons clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseWithReasons copyWith(void Function(ResponseWithReasons) updates) =>
      super.copyWith((message) => updates(message as ResponseWithReasons))
          as ResponseWithReasons;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ResponseWithReasons() / ResponseWithReasons.new instead')
  static ResponseWithReasons create() => ResponseWithReasons._();
  static $pb.GeneratedMessage $_createMessage() => ResponseWithReasons._();
  @$core.override
  ResponseWithReasons createEmptyInstance() => ResponseWithReasons._();
  @$core.pragma('dart2js:noInline')
  static ResponseWithReasons getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResponseWithReasons>(
          ResponseWithReasons.$_createMessage);
  static ResponseWithReasons? _defaultInstance;

  @$pb.TagNumber(1)
  ResponseWithReasons_Error get error => $_getN(0);
  @$pb.TagNumber(1)
  set error(ResponseWithReasons_Error value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get reasons => $_getSZ(1);
  @$pb.TagNumber(2)
  set reasons($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReasons() => $_has(1);
  @$pb.TagNumber(2)
  void clearReasons() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
