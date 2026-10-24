// This is a generated file - do not edit.
//
// Generated from es_play_options.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'es_play_options.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'es_play_options.pbenum.dart';

class PlayOptions extends $pb.GeneratedMessage {
  factory PlayOptions({
    PlayOptions_Reason? reason,
    PlayOptions_Operation? operation,
    PlayOptions_Trigger? trigger,
  }) {
    final result = PlayOptions._();
    if (reason != null) result.reason = reason;
    if (operation != null) result.operation = operation;
    if (trigger != null) result.trigger = trigger;
    return result;
  }

  PlayOptions._();

  factory PlayOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayOptions()..mergeFromBuffer(data, registry);
  factory PlayOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayOptions()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayOptions',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: PlayOptions.$_createMessage)
    ..aE<PlayOptions_Reason>(1, _omitFieldNames ? '' : 'reason',
        enumValues: PlayOptions_Reason.values)
    ..aE<PlayOptions_Operation>(2, _omitFieldNames ? '' : 'operation',
        enumValues: PlayOptions_Operation.values)
    ..aE<PlayOptions_Trigger>(3, _omitFieldNames ? '' : 'trigger',
        enumValues: PlayOptions_Trigger.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayOptions copyWith(void Function(PlayOptions) updates) =>
      super.copyWith((message) => updates(message as PlayOptions))
          as PlayOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PlayOptions() / PlayOptions.new instead')
  static PlayOptions create() => PlayOptions._();
  static $pb.GeneratedMessage $_createMessage() => PlayOptions._();
  @$core.override
  PlayOptions createEmptyInstance() => PlayOptions._();
  @$core.pragma('dart2js:noInline')
  static PlayOptions getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PlayOptions>(
          PlayOptions.$_createMessage);
  static PlayOptions? _defaultInstance;

  @$pb.TagNumber(1)
  PlayOptions_Reason get reason => $_getN(0);
  @$pb.TagNumber(1)
  set reason(PlayOptions_Reason value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReason() => $_has(0);
  @$pb.TagNumber(1)
  void clearReason() => $_clearField(1);

  @$pb.TagNumber(2)
  PlayOptions_Operation get operation => $_getN(1);
  @$pb.TagNumber(2)
  set operation(PlayOptions_Operation value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOperation() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperation() => $_clearField(2);

  @$pb.TagNumber(3)
  PlayOptions_Trigger get trigger => $_getN(2);
  @$pb.TagNumber(3)
  set trigger(PlayOptions_Trigger value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTrigger() => $_has(2);
  @$pb.TagNumber(3)
  void clearTrigger() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
