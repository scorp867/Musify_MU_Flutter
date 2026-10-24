// This is a generated file - do not edit.
//
// Generated from es_context_player_state.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PlaybackQuality_BitrateLevel extends $pb.ProtobufEnum {
  static const PlaybackQuality_BitrateLevel UNKNOWN =
      PlaybackQuality_BitrateLevel._(0, _omitEnumNames ? '' : 'UNKNOWN');
  static const PlaybackQuality_BitrateLevel LOW =
      PlaybackQuality_BitrateLevel._(1, _omitEnumNames ? '' : 'LOW');
  static const PlaybackQuality_BitrateLevel NORMAL =
      PlaybackQuality_BitrateLevel._(2, _omitEnumNames ? '' : 'NORMAL');
  static const PlaybackQuality_BitrateLevel HIGH =
      PlaybackQuality_BitrateLevel._(3, _omitEnumNames ? '' : 'HIGH');
  static const PlaybackQuality_BitrateLevel VERY_HIGH =
      PlaybackQuality_BitrateLevel._(4, _omitEnumNames ? '' : 'VERY_HIGH');
  static const PlaybackQuality_BitrateLevel HIFI =
      PlaybackQuality_BitrateLevel._(5, _omitEnumNames ? '' : 'HIFI');
  static const PlaybackQuality_BitrateLevel HIFI24 =
      PlaybackQuality_BitrateLevel._(6, _omitEnumNames ? '' : 'HIFI24');

  static const $core.List<PlaybackQuality_BitrateLevel> values =
      <PlaybackQuality_BitrateLevel>[
    UNKNOWN,
    LOW,
    NORMAL,
    HIGH,
    VERY_HIGH,
    HIFI,
    HIFI24,
  ];

  static final $core.List<PlaybackQuality_BitrateLevel?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static PlaybackQuality_BitrateLevel? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PlaybackQuality_BitrateLevel._(super.value, super.name);
}

class PlaybackQuality_BitrateStrategy extends $pb.ProtobufEnum {
  static const PlaybackQuality_BitrateStrategy UNKNOWN_STRATEGY =
      PlaybackQuality_BitrateStrategy._(
          0, _omitEnumNames ? '' : 'UNKNOWN_STRATEGY');
  static const PlaybackQuality_BitrateStrategy BEST_MATCHING =
      PlaybackQuality_BitrateStrategy._(
          1, _omitEnumNames ? '' : 'BEST_MATCHING');
  static const PlaybackQuality_BitrateStrategy BACKEND_ADVISED =
      PlaybackQuality_BitrateStrategy._(
          2, _omitEnumNames ? '' : 'BACKEND_ADVISED');
  static const PlaybackQuality_BitrateStrategy OFFLINED_FILE =
      PlaybackQuality_BitrateStrategy._(
          3, _omitEnumNames ? '' : 'OFFLINED_FILE');
  static const PlaybackQuality_BitrateStrategy CACHED_FILE =
      PlaybackQuality_BitrateStrategy._(4, _omitEnumNames ? '' : 'CACHED_FILE');
  static const PlaybackQuality_BitrateStrategy LOCAL_FILE =
      PlaybackQuality_BitrateStrategy._(5, _omitEnumNames ? '' : 'LOCAL_FILE');

  static const $core.List<PlaybackQuality_BitrateStrategy> values =
      <PlaybackQuality_BitrateStrategy>[
    UNKNOWN_STRATEGY,
    BEST_MATCHING,
    BACKEND_ADVISED,
    OFFLINED_FILE,
    CACHED_FILE,
    LOCAL_FILE,
  ];

  static final $core.List<PlaybackQuality_BitrateStrategy?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static PlaybackQuality_BitrateStrategy? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PlaybackQuality_BitrateStrategy._(super.value, super.name);
}

class PlaybackQuality_HiFiStatus extends $pb.ProtobufEnum {
  static const PlaybackQuality_HiFiStatus NONE =
      PlaybackQuality_HiFiStatus._(0, _omitEnumNames ? '' : 'NONE');
  static const PlaybackQuality_HiFiStatus OFF =
      PlaybackQuality_HiFiStatus._(1, _omitEnumNames ? '' : 'OFF');
  static const PlaybackQuality_HiFiStatus ON =
      PlaybackQuality_HiFiStatus._(2, _omitEnumNames ? '' : 'ON');

  static const $core.List<PlaybackQuality_HiFiStatus> values =
      <PlaybackQuality_HiFiStatus>[
    NONE,
    OFF,
    ON,
  ];

  static final $core.List<PlaybackQuality_HiFiStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PlaybackQuality_HiFiStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PlaybackQuality_HiFiStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
