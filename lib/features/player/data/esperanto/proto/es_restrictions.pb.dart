// This is a generated file - do not edit.
//
// Generated from es_restrictions.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ModeRestrictions extends $pb.GeneratedMessage {
  factory ModeRestrictions({
    $core.Iterable<$core.MapEntry<$core.String, RestrictionReasons>>? values,
  }) {
    final result = ModeRestrictions._();
    if (values != null) result.values.addEntries(values);
    return result;
  }

  ModeRestrictions._();

  factory ModeRestrictions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModeRestrictions()..mergeFromBuffer(data, registry);
  factory ModeRestrictions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModeRestrictions()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModeRestrictions',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: ModeRestrictions.$_createMessage)
    ..m<$core.String, RestrictionReasons>(1, _omitFieldNames ? '' : 'values',
        entryClassName: 'ModeRestrictions.ValuesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: RestrictionReasons.$_createMessage,
        valueDefaultOrMaker: RestrictionReasons.getDefault,
        packageName: const $pb.PackageName('spotify.player.esperanto.proto'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModeRestrictions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModeRestrictions copyWith(void Function(ModeRestrictions) updates) =>
      super.copyWith((message) => updates(message as ModeRestrictions))
          as ModeRestrictions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ModeRestrictions() / ModeRestrictions.new instead')
  static ModeRestrictions create() => ModeRestrictions._();
  static $pb.GeneratedMessage $_createMessage() => ModeRestrictions._();
  @$core.override
  ModeRestrictions createEmptyInstance() => ModeRestrictions._();
  @$core.pragma('dart2js:noInline')
  static ModeRestrictions getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ModeRestrictions>(
          ModeRestrictions.$_createMessage);
  static ModeRestrictions? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, RestrictionReasons> get values => $_getMap(0);
}

class RestrictionReasons extends $pb.GeneratedMessage {
  factory RestrictionReasons({
    $core.Iterable<$core.String>? reasons,
  }) {
    final result = RestrictionReasons._();
    if (reasons != null) result.reasons.addAll(reasons);
    return result;
  }

  RestrictionReasons._();

  factory RestrictionReasons.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RestrictionReasons()..mergeFromBuffer(data, registry);
  factory RestrictionReasons.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RestrictionReasons()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RestrictionReasons',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: RestrictionReasons.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'reasons')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RestrictionReasons clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RestrictionReasons copyWith(void Function(RestrictionReasons) updates) =>
      super.copyWith((message) => updates(message as RestrictionReasons))
          as RestrictionReasons;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RestrictionReasons() / RestrictionReasons.new instead')
  static RestrictionReasons create() => RestrictionReasons._();
  static $pb.GeneratedMessage $_createMessage() => RestrictionReasons._();
  @$core.override
  RestrictionReasons createEmptyInstance() => RestrictionReasons._();
  @$core.pragma('dart2js:noInline')
  static RestrictionReasons getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RestrictionReasons>(
          RestrictionReasons.$_createMessage);
  static RestrictionReasons? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get reasons => $_getList(0);
}

class Restrictions extends $pb.GeneratedMessage {
  factory Restrictions({
    $core.Iterable<$core.String>? disallowPausingReasons,
    $core.Iterable<$core.String>? disallowResumingReasons,
    $core.Iterable<$core.String>? disallowSeekingReasons,
    $core.Iterable<$core.String>? disallowPeekingPrevReasons,
    $core.Iterable<$core.String>? disallowPeekingNextReasons,
    $core.Iterable<$core.String>? disallowSkippingPrevReasons,
    $core.Iterable<$core.String>? disallowSkippingNextReasons,
    $core.Iterable<$core.String>? disallowTogglingRepeatContextReasons,
    $core.Iterable<$core.String>? disallowTogglingRepeatTrackReasons,
    $core.Iterable<$core.String>? disallowTogglingShuffleReasons,
    $core.Iterable<$core.String>? disallowSetQueueReasons,
    $core.Iterable<$core.String>? disallowInterruptingPlaybackReasons,
    $core.Iterable<$core.String>? disallowTransferringPlaybackReasons,
    $core.Iterable<$core.String>? disallowRemoteControlReasons,
    $core.Iterable<$core.String>? disallowInsertingIntoNextTracksReasons,
    $core.Iterable<$core.String>? disallowInsertingIntoContextTracksReasons,
    $core.Iterable<$core.String>? disallowReorderingInNextTracksReasons,
    $core.Iterable<$core.String>? disallowReorderingInContextTracksReasons,
    $core.Iterable<$core.String>? disallowRemovingFromNextTracksReasons,
    $core.Iterable<$core.String>? disallowRemovingFromContextTracksReasons,
    $core.Iterable<$core.String>? disallowUpdatingContextReasons,
    $core.Iterable<$core.String>? disallowAddToQueueReasons,
    $core.Iterable<$core.String>? disallowSettingPlaybackSpeedReasons,
    $core.Iterable<$core.MapEntry<$core.String, ModeRestrictions>>?
        disallowSettingModes,
    $core.Iterable<$core.MapEntry<$core.String, RestrictionReasons>>?
        disallowSignals,
  }) {
    final result = Restrictions._();
    if (disallowPausingReasons != null)
      result.disallowPausingReasons.addAll(disallowPausingReasons);
    if (disallowResumingReasons != null)
      result.disallowResumingReasons.addAll(disallowResumingReasons);
    if (disallowSeekingReasons != null)
      result.disallowSeekingReasons.addAll(disallowSeekingReasons);
    if (disallowPeekingPrevReasons != null)
      result.disallowPeekingPrevReasons.addAll(disallowPeekingPrevReasons);
    if (disallowPeekingNextReasons != null)
      result.disallowPeekingNextReasons.addAll(disallowPeekingNextReasons);
    if (disallowSkippingPrevReasons != null)
      result.disallowSkippingPrevReasons.addAll(disallowSkippingPrevReasons);
    if (disallowSkippingNextReasons != null)
      result.disallowSkippingNextReasons.addAll(disallowSkippingNextReasons);
    if (disallowTogglingRepeatContextReasons != null)
      result.disallowTogglingRepeatContextReasons
          .addAll(disallowTogglingRepeatContextReasons);
    if (disallowTogglingRepeatTrackReasons != null)
      result.disallowTogglingRepeatTrackReasons
          .addAll(disallowTogglingRepeatTrackReasons);
    if (disallowTogglingShuffleReasons != null)
      result.disallowTogglingShuffleReasons
          .addAll(disallowTogglingShuffleReasons);
    if (disallowSetQueueReasons != null)
      result.disallowSetQueueReasons.addAll(disallowSetQueueReasons);
    if (disallowInterruptingPlaybackReasons != null)
      result.disallowInterruptingPlaybackReasons
          .addAll(disallowInterruptingPlaybackReasons);
    if (disallowTransferringPlaybackReasons != null)
      result.disallowTransferringPlaybackReasons
          .addAll(disallowTransferringPlaybackReasons);
    if (disallowRemoteControlReasons != null)
      result.disallowRemoteControlReasons.addAll(disallowRemoteControlReasons);
    if (disallowInsertingIntoNextTracksReasons != null)
      result.disallowInsertingIntoNextTracksReasons
          .addAll(disallowInsertingIntoNextTracksReasons);
    if (disallowInsertingIntoContextTracksReasons != null)
      result.disallowInsertingIntoContextTracksReasons
          .addAll(disallowInsertingIntoContextTracksReasons);
    if (disallowReorderingInNextTracksReasons != null)
      result.disallowReorderingInNextTracksReasons
          .addAll(disallowReorderingInNextTracksReasons);
    if (disallowReorderingInContextTracksReasons != null)
      result.disallowReorderingInContextTracksReasons
          .addAll(disallowReorderingInContextTracksReasons);
    if (disallowRemovingFromNextTracksReasons != null)
      result.disallowRemovingFromNextTracksReasons
          .addAll(disallowRemovingFromNextTracksReasons);
    if (disallowRemovingFromContextTracksReasons != null)
      result.disallowRemovingFromContextTracksReasons
          .addAll(disallowRemovingFromContextTracksReasons);
    if (disallowUpdatingContextReasons != null)
      result.disallowUpdatingContextReasons
          .addAll(disallowUpdatingContextReasons);
    if (disallowAddToQueueReasons != null)
      result.disallowAddToQueueReasons.addAll(disallowAddToQueueReasons);
    if (disallowSettingPlaybackSpeedReasons != null)
      result.disallowSettingPlaybackSpeedReasons
          .addAll(disallowSettingPlaybackSpeedReasons);
    if (disallowSettingModes != null)
      result.disallowSettingModes.addEntries(disallowSettingModes);
    if (disallowSignals != null)
      result.disallowSignals.addEntries(disallowSignals);
    return result;
  }

  Restrictions._();

  factory Restrictions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Restrictions()..mergeFromBuffer(data, registry);
  factory Restrictions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Restrictions()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Restrictions',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: Restrictions.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'disallowPausingReasons')
    ..pPS(2, _omitFieldNames ? '' : 'disallowResumingReasons')
    ..pPS(3, _omitFieldNames ? '' : 'disallowSeekingReasons')
    ..pPS(4, _omitFieldNames ? '' : 'disallowPeekingPrevReasons')
    ..pPS(5, _omitFieldNames ? '' : 'disallowPeekingNextReasons')
    ..pPS(6, _omitFieldNames ? '' : 'disallowSkippingPrevReasons')
    ..pPS(7, _omitFieldNames ? '' : 'disallowSkippingNextReasons')
    ..pPS(8, _omitFieldNames ? '' : 'disallowTogglingRepeatContextReasons')
    ..pPS(9, _omitFieldNames ? '' : 'disallowTogglingRepeatTrackReasons')
    ..pPS(10, _omitFieldNames ? '' : 'disallowTogglingShuffleReasons')
    ..pPS(11, _omitFieldNames ? '' : 'disallowSetQueueReasons')
    ..pPS(12, _omitFieldNames ? '' : 'disallowInterruptingPlaybackReasons')
    ..pPS(13, _omitFieldNames ? '' : 'disallowTransferringPlaybackReasons')
    ..pPS(14, _omitFieldNames ? '' : 'disallowRemoteControlReasons')
    ..pPS(15, _omitFieldNames ? '' : 'disallowInsertingIntoNextTracksReasons')
    ..pPS(
        16, _omitFieldNames ? '' : 'disallowInsertingIntoContextTracksReasons')
    ..pPS(17, _omitFieldNames ? '' : 'disallowReorderingInNextTracksReasons')
    ..pPS(18, _omitFieldNames ? '' : 'disallowReorderingInContextTracksReasons')
    ..pPS(19, _omitFieldNames ? '' : 'disallowRemovingFromNextTracksReasons')
    ..pPS(20, _omitFieldNames ? '' : 'disallowRemovingFromContextTracksReasons')
    ..pPS(21, _omitFieldNames ? '' : 'disallowUpdatingContextReasons')
    ..pPS(22, _omitFieldNames ? '' : 'disallowAddToQueueReasons')
    ..pPS(23, _omitFieldNames ? '' : 'disallowSettingPlaybackSpeedReasons')
    ..m<$core.String, ModeRestrictions>(
        25, _omitFieldNames ? '' : 'disallowSettingModes',
        entryClassName: 'Restrictions.DisallowSettingModesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: ModeRestrictions.$_createMessage,
        valueDefaultOrMaker: ModeRestrictions.getDefault,
        packageName: const $pb.PackageName('spotify.player.esperanto.proto'))
    ..m<$core.String, RestrictionReasons>(
        26, _omitFieldNames ? '' : 'disallowSignals',
        entryClassName: 'Restrictions.DisallowSignalsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: RestrictionReasons.$_createMessage,
        valueDefaultOrMaker: RestrictionReasons.getDefault,
        packageName: const $pb.PackageName('spotify.player.esperanto.proto'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Restrictions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Restrictions copyWith(void Function(Restrictions) updates) =>
      super.copyWith((message) => updates(message as Restrictions))
          as Restrictions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Restrictions() / Restrictions.new instead')
  static Restrictions create() => Restrictions._();
  static $pb.GeneratedMessage $_createMessage() => Restrictions._();
  @$core.override
  Restrictions createEmptyInstance() => Restrictions._();
  @$core.pragma('dart2js:noInline')
  static Restrictions getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Restrictions>(
          Restrictions.$_createMessage);
  static Restrictions? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get disallowPausingReasons => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get disallowResumingReasons => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get disallowSeekingReasons => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get disallowPeekingPrevReasons => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get disallowPeekingNextReasons => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get disallowSkippingPrevReasons => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get disallowSkippingNextReasons => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<$core.String> get disallowTogglingRepeatContextReasons =>
      $_getList(7);

  @$pb.TagNumber(9)
  $pb.PbList<$core.String> get disallowTogglingRepeatTrackReasons =>
      $_getList(8);

  @$pb.TagNumber(10)
  $pb.PbList<$core.String> get disallowTogglingShuffleReasons => $_getList(9);

  @$pb.TagNumber(11)
  $pb.PbList<$core.String> get disallowSetQueueReasons => $_getList(10);

  @$pb.TagNumber(12)
  $pb.PbList<$core.String> get disallowInterruptingPlaybackReasons =>
      $_getList(11);

  @$pb.TagNumber(13)
  $pb.PbList<$core.String> get disallowTransferringPlaybackReasons =>
      $_getList(12);

  @$pb.TagNumber(14)
  $pb.PbList<$core.String> get disallowRemoteControlReasons => $_getList(13);

  @$pb.TagNumber(15)
  $pb.PbList<$core.String> get disallowInsertingIntoNextTracksReasons =>
      $_getList(14);

  @$pb.TagNumber(16)
  $pb.PbList<$core.String> get disallowInsertingIntoContextTracksReasons =>
      $_getList(15);

  @$pb.TagNumber(17)
  $pb.PbList<$core.String> get disallowReorderingInNextTracksReasons =>
      $_getList(16);

  @$pb.TagNumber(18)
  $pb.PbList<$core.String> get disallowReorderingInContextTracksReasons =>
      $_getList(17);

  @$pb.TagNumber(19)
  $pb.PbList<$core.String> get disallowRemovingFromNextTracksReasons =>
      $_getList(18);

  @$pb.TagNumber(20)
  $pb.PbList<$core.String> get disallowRemovingFromContextTracksReasons =>
      $_getList(19);

  @$pb.TagNumber(21)
  $pb.PbList<$core.String> get disallowUpdatingContextReasons => $_getList(20);

  @$pb.TagNumber(22)
  $pb.PbList<$core.String> get disallowAddToQueueReasons => $_getList(21);

  @$pb.TagNumber(23)
  $pb.PbList<$core.String> get disallowSettingPlaybackSpeedReasons =>
      $_getList(22);

  @$pb.TagNumber(25)
  $pb.PbMap<$core.String, ModeRestrictions> get disallowSettingModes =>
      $_getMap(23);

  @$pb.TagNumber(26)
  $pb.PbMap<$core.String, RestrictionReasons> get disallowSignals =>
      $_getMap(24);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
