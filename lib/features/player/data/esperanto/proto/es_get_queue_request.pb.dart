// This is a generated file - do not edit.
//
// Generated from es_get_queue_request.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class GetQueueRequest extends $pb.GeneratedMessage {
  factory GetQueueRequest() => GetQueueRequest._();

  GetQueueRequest._();

  factory GetQueueRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetQueueRequest()..mergeFromBuffer(data, registry);
  factory GetQueueRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetQueueRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetQueueRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: GetQueueRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetQueueRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetQueueRequest copyWith(void Function(GetQueueRequest) updates) =>
      super.copyWith((message) => updates(message as GetQueueRequest))
          as GetQueueRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetQueueRequest() / GetQueueRequest.new instead')
  static GetQueueRequest create() => GetQueueRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetQueueRequest._();
  @$core.override
  GetQueueRequest createEmptyInstance() => GetQueueRequest._();
  @$core.pragma('dart2js:noInline')
  static GetQueueRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetQueueRequest>(
          GetQueueRequest.$_createMessage);
  static GetQueueRequest? _defaultInstance;
}

const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
