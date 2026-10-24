// This is a generated file - do not edit.
//
// Generated from es_prepare_play_options.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PreparePlayOptions_PrefetchLevel extends $pb.ProtobufEnum {
  static const PreparePlayOptions_PrefetchLevel NONE =
      PreparePlayOptions_PrefetchLevel._(0, _omitEnumNames ? '' : 'NONE');
  static const PreparePlayOptions_PrefetchLevel MEDIA =
      PreparePlayOptions_PrefetchLevel._(1, _omitEnumNames ? '' : 'MEDIA');

  static const $core.List<PreparePlayOptions_PrefetchLevel> values =
      <PreparePlayOptions_PrefetchLevel>[
    NONE,
    MEDIA,
  ];

  static final $core.List<PreparePlayOptions_PrefetchLevel?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static PreparePlayOptions_PrefetchLevel? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PreparePlayOptions_PrefetchLevel._(super.value, super.name);
}

class PreparePlayOptions_AudioStream extends $pb.ProtobufEnum {
  static const PreparePlayOptions_AudioStream DEFAULT =
      PreparePlayOptions_AudioStream._(0, _omitEnumNames ? '' : 'DEFAULT');
  static const PreparePlayOptions_AudioStream ALARM =
      PreparePlayOptions_AudioStream._(1, _omitEnumNames ? '' : 'ALARM');

  static const $core.List<PreparePlayOptions_AudioStream> values =
      <PreparePlayOptions_AudioStream>[
    DEFAULT,
    ALARM,
  ];

  static final $core.List<PreparePlayOptions_AudioStream?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static PreparePlayOptions_AudioStream? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PreparePlayOptions_AudioStream._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
