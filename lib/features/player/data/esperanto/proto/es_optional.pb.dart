// This is a generated file - do not edit.
//
// Generated from es_optional.proto.

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

class OptionalInt64 extends $pb.GeneratedMessage {
  factory OptionalInt64({
    $fixnum.Int64? value,
  }) {
    final result = OptionalInt64._();
    if (value != null) result.value = value;
    return result;
  }

  OptionalInt64._();

  factory OptionalInt64.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OptionalInt64()..mergeFromBuffer(data, registry);
  factory OptionalInt64.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OptionalInt64()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OptionalInt64',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: OptionalInt64.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OptionalInt64 clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OptionalInt64 copyWith(void Function(OptionalInt64) updates) =>
      super.copyWith((message) => updates(message as OptionalInt64))
          as OptionalInt64;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use OptionalInt64() / OptionalInt64.new instead')
  static OptionalInt64 create() => OptionalInt64._();
  static $pb.GeneratedMessage $_createMessage() => OptionalInt64._();
  @$core.override
  OptionalInt64 createEmptyInstance() => OptionalInt64._();
  @$core.pragma('dart2js:noInline')
  static OptionalInt64 getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OptionalInt64>(
          OptionalInt64.$_createMessage);
  static OptionalInt64? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get value => $_getI64(0);
  @$pb.TagNumber(1)
  set value($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class OptionalDouble extends $pb.GeneratedMessage {
  factory OptionalDouble({
    $core.double? value,
  }) {
    final result = OptionalDouble._();
    if (value != null) result.value = value;
    return result;
  }

  OptionalDouble._();

  factory OptionalDouble.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OptionalDouble()..mergeFromBuffer(data, registry);
  factory OptionalDouble.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OptionalDouble()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OptionalDouble',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: OptionalDouble.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OptionalDouble clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OptionalDouble copyWith(void Function(OptionalDouble) updates) =>
      super.copyWith((message) => updates(message as OptionalDouble))
          as OptionalDouble;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use OptionalDouble() / OptionalDouble.new instead')
  static OptionalDouble create() => OptionalDouble._();
  static $pb.GeneratedMessage $_createMessage() => OptionalDouble._();
  @$core.override
  OptionalDouble createEmptyInstance() => OptionalDouble._();
  @$core.pragma('dart2js:noInline')
  static OptionalDouble getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OptionalDouble>(
          OptionalDouble.$_createMessage);
  static OptionalDouble? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get value => $_getN(0);
  @$pb.TagNumber(1)
  set value($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class OptionalBoolean extends $pb.GeneratedMessage {
  factory OptionalBoolean({
    $core.bool? value,
  }) {
    final result = OptionalBoolean._();
    if (value != null) result.value = value;
    return result;
  }

  OptionalBoolean._();

  factory OptionalBoolean.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OptionalBoolean()..mergeFromBuffer(data, registry);
  factory OptionalBoolean.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OptionalBoolean()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OptionalBoolean',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: OptionalBoolean.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OptionalBoolean clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OptionalBoolean copyWith(void Function(OptionalBoolean) updates) =>
      super.copyWith((message) => updates(message as OptionalBoolean))
          as OptionalBoolean;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use OptionalBoolean() / OptionalBoolean.new instead')
  static OptionalBoolean create() => OptionalBoolean._();
  static $pb.GeneratedMessage $_createMessage() => OptionalBoolean._();
  @$core.override
  OptionalBoolean createEmptyInstance() => OptionalBoolean._();
  @$core.pragma('dart2js:noInline')
  static OptionalBoolean getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OptionalBoolean>(
          OptionalBoolean.$_createMessage);
  static OptionalBoolean? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
