// This is a generated file - do not edit.
//
// Generated from es_seek_to.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'es_command_options.pb.dart' as $0;
import 'es_logging_params.pb.dart' as $1;
import 'es_seek_to.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'es_seek_to.pbenum.dart';

class SeekToRequest extends $pb.GeneratedMessage {
  factory SeekToRequest({
    $0.CommandOptions? options,
    $1.LoggingParams? loggingParams,
    $fixnum.Int64? position,
    SeekToRequest_Relative? relative,
  }) {
    final result = SeekToRequest._();
    if (options != null) result.options = options;
    if (loggingParams != null) result.loggingParams = loggingParams;
    if (position != null) result.position = position;
    if (relative != null) result.relative = relative;
    return result;
  }

  SeekToRequest._();

  factory SeekToRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SeekToRequest()..mergeFromBuffer(data, registry);
  factory SeekToRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SeekToRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SeekToRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: SeekToRequest.$_createMessage)
    ..aOM<$0.CommandOptions>(1, _omitFieldNames ? '' : 'options',
        subBuilder: $0.CommandOptions.$_createMessage)
    ..aOM<$1.LoggingParams>(2, _omitFieldNames ? '' : 'loggingParams',
        subBuilder: $1.LoggingParams.$_createMessage)
    ..aInt64(3, _omitFieldNames ? '' : 'position')
    ..aE<SeekToRequest_Relative>(4, _omitFieldNames ? '' : 'relative',
        enumValues: SeekToRequest_Relative.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SeekToRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SeekToRequest copyWith(void Function(SeekToRequest) updates) =>
      super.copyWith((message) => updates(message as SeekToRequest))
          as SeekToRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SeekToRequest() / SeekToRequest.new instead')
  static SeekToRequest create() => SeekToRequest._();
  static $pb.GeneratedMessage $_createMessage() => SeekToRequest._();
  @$core.override
  SeekToRequest createEmptyInstance() => SeekToRequest._();
  @$core.pragma('dart2js:noInline')
  static SeekToRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SeekToRequest>(
          SeekToRequest.$_createMessage);
  static SeekToRequest? _defaultInstance;

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
  $fixnum.Int64 get position => $_getI64(2);
  @$pb.TagNumber(3)
  set position($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPosition() => $_has(2);
  @$pb.TagNumber(3)
  void clearPosition() => $_clearField(3);

  @$pb.TagNumber(4)
  SeekToRequest_Relative get relative => $_getN(3);
  @$pb.TagNumber(4)
  set relative(SeekToRequest_Relative value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasRelative() => $_has(3);
  @$pb.TagNumber(4)
  void clearRelative() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
