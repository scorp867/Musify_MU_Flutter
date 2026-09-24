// This is a generated file - do not edit.
//
// Generated from spotify/traits/preview_card_trait.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PreviewRestriction extends $pb.ProtobufEnum {
  static const PreviewRestriction PREVIEW_RESTRICTION_NONE =
      PreviewRestriction._(0, _omitEnumNames ? '' : 'PREVIEW_RESTRICTION_NONE');
  static const PreviewRestriction PREVIEW_IS_EXPLICIT =
      PreviewRestriction._(1, _omitEnumNames ? '' : 'PREVIEW_IS_EXPLICIT');
  static const PreviewRestriction PREVIEW_IS_19_PLUS =
      PreviewRestriction._(2, _omitEnumNames ? '' : 'PREVIEW_IS_19_PLUS');

  static const $core.List<PreviewRestriction> values = <PreviewRestriction>[
    PREVIEW_RESTRICTION_NONE,
    PREVIEW_IS_EXPLICIT,
    PREVIEW_IS_19_PLUS,
  ];

  static final $core.List<PreviewRestriction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PreviewRestriction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PreviewRestriction._(super.value, super.name);
}

class SubtitleSource extends $pb.ProtobufEnum {
  static const SubtitleSource SUBTITLE_SOURCE_UNKNOWN =
      SubtitleSource._(0, _omitEnumNames ? '' : 'SUBTITLE_SOURCE_UNKNOWN');
  static const SubtitleSource SUBTITLE_SOURCE_GENERATED_METADATA =
      SubtitleSource._(
          1, _omitEnumNames ? '' : 'SUBTITLE_SOURCE_GENERATED_METADATA');
  static const SubtitleSource SUBTITLE_SOURCE_OPERATOR_AUTHORED =
      SubtitleSource._(
          2, _omitEnumNames ? '' : 'SUBTITLE_SOURCE_OPERATOR_AUTHORED');

  static const $core.List<SubtitleSource> values = <SubtitleSource>[
    SUBTITLE_SOURCE_UNKNOWN,
    SUBTITLE_SOURCE_GENERATED_METADATA,
    SUBTITLE_SOURCE_OPERATOR_AUTHORED,
  ];

  static final $core.List<SubtitleSource?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SubtitleSource? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SubtitleSource._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
