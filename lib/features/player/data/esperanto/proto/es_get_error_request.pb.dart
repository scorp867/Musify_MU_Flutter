// This is a generated file - do not edit.
//
// Generated from es_get_error_request.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class GetErrorRequest extends $pb.GeneratedMessage {
  factory GetErrorRequest() => GetErrorRequest._();

  GetErrorRequest._();

  factory GetErrorRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetErrorRequest()..mergeFromBuffer(data, registry);
  factory GetErrorRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetErrorRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetErrorRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: GetErrorRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetErrorRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetErrorRequest copyWith(void Function(GetErrorRequest) updates) =>
      super.copyWith((message) => updates(message as GetErrorRequest))
          as GetErrorRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetErrorRequest() / GetErrorRequest.new instead')
  static GetErrorRequest create() => GetErrorRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetErrorRequest._();
  @$core.override
  GetErrorRequest createEmptyInstance() => GetErrorRequest._();
  @$core.pragma('dart2js:noInline')
  static GetErrorRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetErrorRequest>(
          GetErrorRequest.$_createMessage);
  static GetErrorRequest? _defaultInstance;
}

const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
