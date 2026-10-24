// This is a generated file - do not edit.
//
// Generated from es_context_player_error.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ContextPlayerError_ErrorCode extends $pb.ProtobufEnum {
  static const ContextPlayerError_ErrorCode SUCCESS =
      ContextPlayerError_ErrorCode._(0, _omitEnumNames ? '' : 'SUCCESS');
  static const ContextPlayerError_ErrorCode PLAYBACK_STUCK =
      ContextPlayerError_ErrorCode._(1, _omitEnumNames ? '' : 'PLAYBACK_STUCK');
  static const ContextPlayerError_ErrorCode PLAYBACK_ERROR =
      ContextPlayerError_ErrorCode._(2, _omitEnumNames ? '' : 'PLAYBACK_ERROR');
  static const ContextPlayerError_ErrorCode LICENSE_CHANGE =
      ContextPlayerError_ErrorCode._(3, _omitEnumNames ? '' : 'LICENSE_CHANGE');
  static const ContextPlayerError_ErrorCode PLAY_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          4, _omitEnumNames ? '' : 'PLAY_RESTRICTED');
  static const ContextPlayerError_ErrorCode STOP_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          5, _omitEnumNames ? '' : 'STOP_RESTRICTED');
  static const ContextPlayerError_ErrorCode UPDATE_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          6, _omitEnumNames ? '' : 'UPDATE_RESTRICTED');
  static const ContextPlayerError_ErrorCode PAUSE_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          7, _omitEnumNames ? '' : 'PAUSE_RESTRICTED');
  static const ContextPlayerError_ErrorCode RESUME_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          8, _omitEnumNames ? '' : 'RESUME_RESTRICTED');
  static const ContextPlayerError_ErrorCode SKIP_TO_PREV_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          9, _omitEnumNames ? '' : 'SKIP_TO_PREV_RESTRICTED');
  static const ContextPlayerError_ErrorCode SKIP_TO_NEXT_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          10, _omitEnumNames ? '' : 'SKIP_TO_NEXT_RESTRICTED');
  static const ContextPlayerError_ErrorCode SKIP_TO_NON_EXISTENT_TRACK =
      ContextPlayerError_ErrorCode._(
          11, _omitEnumNames ? '' : 'SKIP_TO_NON_EXISTENT_TRACK');
  static const ContextPlayerError_ErrorCode SEEK_TO_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          12, _omitEnumNames ? '' : 'SEEK_TO_RESTRICTED');
  static const ContextPlayerError_ErrorCode TOGGLE_REPEAT_CONTEXT_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          13, _omitEnumNames ? '' : 'TOGGLE_REPEAT_CONTEXT_RESTRICTED');
  static const ContextPlayerError_ErrorCode TOGGLE_REPEAT_TRACK_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          14, _omitEnumNames ? '' : 'TOGGLE_REPEAT_TRACK_RESTRICTED');
  static const ContextPlayerError_ErrorCode SET_OPTIONS_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          15, _omitEnumNames ? '' : 'SET_OPTIONS_RESTRICTED');
  static const ContextPlayerError_ErrorCode TOGGLE_SHUFFLE_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          16, _omitEnumNames ? '' : 'TOGGLE_SHUFFLE_RESTRICTED');
  static const ContextPlayerError_ErrorCode SET_QUEUE_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          17, _omitEnumNames ? '' : 'SET_QUEUE_RESTRICTED');
  static const ContextPlayerError_ErrorCode INTERRUPT_PLAYBACK_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          18, _omitEnumNames ? '' : 'INTERRUPT_PLAYBACK_RESTRICTED');
  static const ContextPlayerError_ErrorCode ONE_TRACK_UNPLAYABLE =
      ContextPlayerError_ErrorCode._(
          19, _omitEnumNames ? '' : 'ONE_TRACK_UNPLAYABLE');
  static const ContextPlayerError_ErrorCode ONE_TRACK_UNPLAYABLE_AUTO_STOPPED =
      ContextPlayerError_ErrorCode._(
          20, _omitEnumNames ? '' : 'ONE_TRACK_UNPLAYABLE_AUTO_STOPPED');
  static const ContextPlayerError_ErrorCode ALL_TRACKS_UNPLAYABLE_AUTO_STOPPED =
      ContextPlayerError_ErrorCode._(
          21, _omitEnumNames ? '' : 'ALL_TRACKS_UNPLAYABLE_AUTO_STOPPED');
  static const ContextPlayerError_ErrorCode
      SKIP_TO_NON_EXISTENT_TRACK_AUTO_STOPPED = ContextPlayerError_ErrorCode._(
          22, _omitEnumNames ? '' : 'SKIP_TO_NON_EXISTENT_TRACK_AUTO_STOPPED');
  static const ContextPlayerError_ErrorCode QUEUE_REVISION_MISMATCH =
      ContextPlayerError_ErrorCode._(
          23, _omitEnumNames ? '' : 'QUEUE_REVISION_MISMATCH');
  static const ContextPlayerError_ErrorCode VIDEO_PLAYBACK_ERROR =
      ContextPlayerError_ErrorCode._(
          24, _omitEnumNames ? '' : 'VIDEO_PLAYBACK_ERROR');
  static const ContextPlayerError_ErrorCode VIDEO_GEOGRAPHICALLY_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          25, _omitEnumNames ? '' : 'VIDEO_GEOGRAPHICALLY_RESTRICTED');
  static const ContextPlayerError_ErrorCode VIDEO_UNSUPPORTED_PLATFORM_VERSION =
      ContextPlayerError_ErrorCode._(
          26, _omitEnumNames ? '' : 'VIDEO_UNSUPPORTED_PLATFORM_VERSION');
  static const ContextPlayerError_ErrorCode VIDEO_UNSUPPORTED_CLIENT_VERSION =
      ContextPlayerError_ErrorCode._(
          27, _omitEnumNames ? '' : 'VIDEO_UNSUPPORTED_CLIENT_VERSION');
  static const ContextPlayerError_ErrorCode VIDEO_UNSUPPORTED_KEY_SYSTEM =
      ContextPlayerError_ErrorCode._(
          28, _omitEnumNames ? '' : 'VIDEO_UNSUPPORTED_KEY_SYSTEM');
  static const ContextPlayerError_ErrorCode VIDEO_MANIFEST_DELETED =
      ContextPlayerError_ErrorCode._(
          29, _omitEnumNames ? '' : 'VIDEO_MANIFEST_DELETED');
  static const ContextPlayerError_ErrorCode VIDEO_COUNTRY_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          30, _omitEnumNames ? '' : 'VIDEO_COUNTRY_RESTRICTED');
  static const ContextPlayerError_ErrorCode VIDEO_UNAVAILABLE =
      ContextPlayerError_ErrorCode._(
          31, _omitEnumNames ? '' : 'VIDEO_UNAVAILABLE');
  static const ContextPlayerError_ErrorCode VIDEO_CATALOGUE_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          32, _omitEnumNames ? '' : 'VIDEO_CATALOGUE_RESTRICTED');
  static const ContextPlayerError_ErrorCode INVALID =
      ContextPlayerError_ErrorCode._(33, _omitEnumNames ? '' : 'INVALID');
  static const ContextPlayerError_ErrorCode TIMEOUT =
      ContextPlayerError_ErrorCode._(34, _omitEnumNames ? '' : 'TIMEOUT');
  static const ContextPlayerError_ErrorCode PLAYBACK_REPORTING_ERROR =
      ContextPlayerError_ErrorCode._(
          35, _omitEnumNames ? '' : 'PLAYBACK_REPORTING_ERROR');
  static const ContextPlayerError_ErrorCode UNKNOWN =
      ContextPlayerError_ErrorCode._(36, _omitEnumNames ? '' : 'UNKNOWN');
  static const ContextPlayerError_ErrorCode ADD_TO_QUEUE_RESTRICTED =
      ContextPlayerError_ErrorCode._(
          37, _omitEnumNames ? '' : 'ADD_TO_QUEUE_RESTRICTED');
  static const ContextPlayerError_ErrorCode PICK_AND_SHUFFLE_CAPPED =
      ContextPlayerError_ErrorCode._(
          38, _omitEnumNames ? '' : 'PICK_AND_SHUFFLE_CAPPED');
  static const ContextPlayerError_ErrorCode
      PICK_AND_SHUFFLE_CONNECT_RESTRICTED = ContextPlayerError_ErrorCode._(
          39, _omitEnumNames ? '' : 'PICK_AND_SHUFFLE_CONNECT_RESTRICTED');
  static const ContextPlayerError_ErrorCode CONTEXT_LOADING_FAILED =
      ContextPlayerError_ErrorCode._(
          40, _omitEnumNames ? '' : 'CONTEXT_LOADING_FAILED');
  static const ContextPlayerError_ErrorCode AUDIOBOOK_NOT_PLAYABLE =
      ContextPlayerError_ErrorCode._(
          41, _omitEnumNames ? '' : 'AUDIOBOOK_NOT_PLAYABLE');
  static const ContextPlayerError_ErrorCode SIGNAL_NOT_AVAILABLE =
      ContextPlayerError_ErrorCode._(
          42, _omitEnumNames ? '' : 'SIGNAL_NOT_AVAILABLE');

  static const $core.List<ContextPlayerError_ErrorCode> values =
      <ContextPlayerError_ErrorCode>[
    SUCCESS,
    PLAYBACK_STUCK,
    PLAYBACK_ERROR,
    LICENSE_CHANGE,
    PLAY_RESTRICTED,
    STOP_RESTRICTED,
    UPDATE_RESTRICTED,
    PAUSE_RESTRICTED,
    RESUME_RESTRICTED,
    SKIP_TO_PREV_RESTRICTED,
    SKIP_TO_NEXT_RESTRICTED,
    SKIP_TO_NON_EXISTENT_TRACK,
    SEEK_TO_RESTRICTED,
    TOGGLE_REPEAT_CONTEXT_RESTRICTED,
    TOGGLE_REPEAT_TRACK_RESTRICTED,
    SET_OPTIONS_RESTRICTED,
    TOGGLE_SHUFFLE_RESTRICTED,
    SET_QUEUE_RESTRICTED,
    INTERRUPT_PLAYBACK_RESTRICTED,
    ONE_TRACK_UNPLAYABLE,
    ONE_TRACK_UNPLAYABLE_AUTO_STOPPED,
    ALL_TRACKS_UNPLAYABLE_AUTO_STOPPED,
    SKIP_TO_NON_EXISTENT_TRACK_AUTO_STOPPED,
    QUEUE_REVISION_MISMATCH,
    VIDEO_PLAYBACK_ERROR,
    VIDEO_GEOGRAPHICALLY_RESTRICTED,
    VIDEO_UNSUPPORTED_PLATFORM_VERSION,
    VIDEO_UNSUPPORTED_CLIENT_VERSION,
    VIDEO_UNSUPPORTED_KEY_SYSTEM,
    VIDEO_MANIFEST_DELETED,
    VIDEO_COUNTRY_RESTRICTED,
    VIDEO_UNAVAILABLE,
    VIDEO_CATALOGUE_RESTRICTED,
    INVALID,
    TIMEOUT,
    PLAYBACK_REPORTING_ERROR,
    UNKNOWN,
    ADD_TO_QUEUE_RESTRICTED,
    PICK_AND_SHUFFLE_CAPPED,
    PICK_AND_SHUFFLE_CONNECT_RESTRICTED,
    CONTEXT_LOADING_FAILED,
    AUDIOBOOK_NOT_PLAYABLE,
    SIGNAL_NOT_AVAILABLE,
  ];

  static final $core.List<ContextPlayerError_ErrorCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 42);
  static ContextPlayerError_ErrorCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ContextPlayerError_ErrorCode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
