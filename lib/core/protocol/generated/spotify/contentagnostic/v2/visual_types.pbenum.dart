// This is a generated file - do not edit.
//
// Generated from spotify/contentagnostic/v2/visual_types.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Mask extends $pb.ProtobufEnum {
  static const Mask MASK_UNSPECIFIED =
      Mask._(0, _omitEnumNames ? '' : 'MASK_UNSPECIFIED');
  static const Mask MASK_CIRCULAR =
      Mask._(1, _omitEnumNames ? '' : 'MASK_CIRCULAR');

  static const $core.List<Mask> values = <Mask>[
    MASK_UNSPECIFIED,
    MASK_CIRCULAR,
  ];

  static final $core.List<Mask?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static Mask? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Mask._(super.value, super.name);
}

class ImageSize extends $pb.ProtobufEnum {
  static const ImageSize IMAGE_SIZE_UNSPECIFIED =
      ImageSize._(0, _omitEnumNames ? '' : 'IMAGE_SIZE_UNSPECIFIED');
  static const ImageSize IMAGE_SIZE_SMALL =
      ImageSize._(1, _omitEnumNames ? '' : 'IMAGE_SIZE_SMALL');
  static const ImageSize IMAGE_SIZE_DEFAULT =
      ImageSize._(2, _omitEnumNames ? '' : 'IMAGE_SIZE_DEFAULT');
  static const ImageSize IMAGE_SIZE_LARGE =
      ImageSize._(3, _omitEnumNames ? '' : 'IMAGE_SIZE_LARGE');
  static const ImageSize IMAGE_SIZE_XLARGE =
      ImageSize._(4, _omitEnumNames ? '' : 'IMAGE_SIZE_XLARGE');
  static const ImageSize IMAGE_SIZE_XXLARGE =
      ImageSize._(5, _omitEnumNames ? '' : 'IMAGE_SIZE_XXLARGE');

  static const $core.List<ImageSize> values = <ImageSize>[
    IMAGE_SIZE_UNSPECIFIED,
    IMAGE_SIZE_SMALL,
    IMAGE_SIZE_DEFAULT,
    IMAGE_SIZE_LARGE,
    IMAGE_SIZE_XLARGE,
    IMAGE_SIZE_XXLARGE,
  ];

  static final $core.List<ImageSize?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static ImageSize? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ImageSize._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
