// This is a generated file - do not edit.
//
// Generated from es_command_options.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class CommandOptions extends $pb.GeneratedMessage {
  factory CommandOptions({
    $core.bool? overrideRestrictions,
    $core.bool? onlyForLocalDevice,
    $core.bool? systemInitiated,
    $core.List<$core.int>? onlyForPlaybackId,
  }) {
    final result = CommandOptions._();
    if (overrideRestrictions != null)
      result.overrideRestrictions = overrideRestrictions;
    if (onlyForLocalDevice != null)
      result.onlyForLocalDevice = onlyForLocalDevice;
    if (systemInitiated != null) result.systemInitiated = systemInitiated;
    if (onlyForPlaybackId != null) result.onlyForPlaybackId = onlyForPlaybackId;
    return result;
  }

  CommandOptions._();

  factory CommandOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CommandOptions()..mergeFromBuffer(data, registry);
  factory CommandOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CommandOptions()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CommandOptions',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: CommandOptions.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'overrideRestrictions')
    ..aOB(2, _omitFieldNames ? '' : 'onlyForLocalDevice')
    ..aOB(3, _omitFieldNames ? '' : 'systemInitiated')
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'onlyForPlaybackId', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CommandOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CommandOptions copyWith(void Function(CommandOptions) updates) =>
      super.copyWith((message) => updates(message as CommandOptions))
          as CommandOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CommandOptions() / CommandOptions.new instead')
  static CommandOptions create() => CommandOptions._();
  static $pb.GeneratedMessage $_createMessage() => CommandOptions._();
  @$core.override
  CommandOptions createEmptyInstance() => CommandOptions._();
  @$core.pragma('dart2js:noInline')
  static CommandOptions getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CommandOptions>(
          CommandOptions.$_createMessage);
  static CommandOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get overrideRestrictions => $_getBF(0);
  @$pb.TagNumber(1)
  set overrideRestrictions($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOverrideRestrictions() => $_has(0);
  @$pb.TagNumber(1)
  void clearOverrideRestrictions() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get onlyForLocalDevice => $_getBF(1);
  @$pb.TagNumber(2)
  set onlyForLocalDevice($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOnlyForLocalDevice() => $_has(1);
  @$pb.TagNumber(2)
  void clearOnlyForLocalDevice() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get systemInitiated => $_getBF(2);
  @$pb.TagNumber(3)
  set systemInitiated($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSystemInitiated() => $_has(2);
  @$pb.TagNumber(3)
  void clearSystemInitiated() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get onlyForPlaybackId => $_getN(3);
  @$pb.TagNumber(4)
  set onlyForPlaybackId($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOnlyForPlaybackId() => $_has(3);
  @$pb.TagNumber(4)
  void clearOnlyForPlaybackId() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
