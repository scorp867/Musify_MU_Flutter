// This is a generated file - do not edit.
//
// Generated from es_queue.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'es_provided_track.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Queue extends $pb.GeneratedMessage {
  factory Queue({
    $fixnum.Int64? queueRevision,
    $0.ProvidedTrack? track,
    $core.Iterable<$0.ProvidedTrack>? nextTracks,
    $core.Iterable<$0.ProvidedTrack>? prevTracks,
  }) {
    final result = Queue._();
    if (queueRevision != null) result.queueRevision = queueRevision;
    if (track != null) result.track = track;
    if (nextTracks != null) result.nextTracks.addAll(nextTracks);
    if (prevTracks != null) result.prevTracks.addAll(prevTracks);
    return result;
  }

  Queue._();

  factory Queue.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Queue()..mergeFromBuffer(data, registry);
  factory Queue.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Queue()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Queue',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: Queue.$_createMessage)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'queueRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$0.ProvidedTrack>(2, _omitFieldNames ? '' : 'track',
        subBuilder: $0.ProvidedTrack.$_createMessage)
    ..pPM<$0.ProvidedTrack>(3, _omitFieldNames ? '' : 'nextTracks',
        subBuilder: $0.ProvidedTrack.$_createMessage)
    ..pPM<$0.ProvidedTrack>(4, _omitFieldNames ? '' : 'prevTracks',
        subBuilder: $0.ProvidedTrack.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Queue clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Queue copyWith(void Function(Queue) updates) =>
      super.copyWith((message) => updates(message as Queue)) as Queue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Queue() / Queue.new instead')
  static Queue create() => Queue._();
  static $pb.GeneratedMessage $_createMessage() => Queue._();
  @$core.override
  Queue createEmptyInstance() => Queue._();
  @$core.pragma('dart2js:noInline')
  static Queue getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Queue>(Queue.$_createMessage);
  static Queue? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get queueRevision => $_getI64(0);
  @$pb.TagNumber(1)
  set queueRevision($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQueueRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearQueueRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.ProvidedTrack get track => $_getN(1);
  @$pb.TagNumber(2)
  set track($0.ProvidedTrack value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTrack() => $_has(1);
  @$pb.TagNumber(2)
  void clearTrack() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.ProvidedTrack ensureTrack() => $_ensure(1);

  @$pb.TagNumber(3)
  $pb.PbList<$0.ProvidedTrack> get nextTracks => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<$0.ProvidedTrack> get prevTracks => $_getList(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
