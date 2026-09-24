// This is a generated file - do not edit.
//
// Generated from spotify/ondemand_selector.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Response from GET /ondemand-selector/v1/select-ondemand-set
/// Returns the filtered set of URIs that need trait resolution.
class OndemandResponse extends $pb.GeneratedMessage {
  factory OndemandResponse({
    $core.Iterable<$core.String>? uris,
    $fixnum.Int64? expireTimestampMillis,
  }) {
    final result = OndemandResponse._();
    if (uris != null) result.uris.addAll(uris);
    if (expireTimestampMillis != null)
      result.expireTimestampMillis = expireTimestampMillis;
    return result;
  }

  OndemandResponse._();

  factory OndemandResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OndemandResponse()..mergeFromBuffer(data, registry);
  factory OndemandResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OndemandResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OndemandResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.ondemandselector'),
      createEmptyInstance: OndemandResponse.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'uris')
    ..aInt64(2, _omitFieldNames ? '' : 'expireTimestampMillis')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OndemandResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OndemandResponse copyWith(void Function(OndemandResponse) updates) =>
      super.copyWith((message) => updates(message as OndemandResponse))
          as OndemandResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use OndemandResponse() / OndemandResponse.new instead')
  static OndemandResponse create() => OndemandResponse._();
  static $pb.GeneratedMessage $_createMessage() => OndemandResponse._();
  @$core.override
  OndemandResponse createEmptyInstance() => OndemandResponse._();
  @$core.pragma('dart2js:noInline')
  static OndemandResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OndemandResponse>(
          OndemandResponse.$_createMessage);
  static OndemandResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get uris => $_getList(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expireTimestampMillis => $_getI64(1);
  @$pb.TagNumber(2)
  set expireTimestampMillis($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpireTimestampMillis() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpireTimestampMillis() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
