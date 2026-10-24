// This is a generated file - do not edit.
//
// Generated from es_pauseresume_origin.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class PauseResumeOrigin extends $pb.GeneratedMessage {
  factory PauseResumeOrigin({
    $core.String? featureIdentifier,
  }) {
    final result = PauseResumeOrigin._();
    if (featureIdentifier != null) result.featureIdentifier = featureIdentifier;
    return result;
  }

  PauseResumeOrigin._();

  factory PauseResumeOrigin.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PauseResumeOrigin()..mergeFromBuffer(data, registry);
  factory PauseResumeOrigin.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PauseResumeOrigin()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PauseResumeOrigin',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: PauseResumeOrigin.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'featureIdentifier')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PauseResumeOrigin clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PauseResumeOrigin copyWith(void Function(PauseResumeOrigin) updates) =>
      super.copyWith((message) => updates(message as PauseResumeOrigin))
          as PauseResumeOrigin;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PauseResumeOrigin() / PauseResumeOrigin.new instead')
  static PauseResumeOrigin create() => PauseResumeOrigin._();
  static $pb.GeneratedMessage $_createMessage() => PauseResumeOrigin._();
  @$core.override
  PauseResumeOrigin createEmptyInstance() => PauseResumeOrigin._();
  @$core.pragma('dart2js:noInline')
  static PauseResumeOrigin getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PauseResumeOrigin>(
          PauseResumeOrigin.$_createMessage);
  static PauseResumeOrigin? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get featureIdentifier => $_getSZ(0);
  @$pb.TagNumber(1)
  set featureIdentifier($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFeatureIdentifier() => $_has(0);
  @$pb.TagNumber(1)
  void clearFeatureIdentifier() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
