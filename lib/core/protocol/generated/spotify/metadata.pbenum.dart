// This is a generated file - do not edit.
//
// Generated from spotify/metadata.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Album_Type extends $pb.ProtobufEnum {
  static const Album_Type ALBUM =
      Album_Type._(1, _omitEnumNames ? '' : 'ALBUM');
  static const Album_Type SINGLE =
      Album_Type._(2, _omitEnumNames ? '' : 'SINGLE');
  static const Album_Type COMPILATION =
      Album_Type._(3, _omitEnumNames ? '' : 'COMPILATION');
  static const Album_Type EP = Album_Type._(4, _omitEnumNames ? '' : 'EP');
  static const Album_Type AUDIOBOOK =
      Album_Type._(5, _omitEnumNames ? '' : 'AUDIOBOOK');
  static const Album_Type PODCAST =
      Album_Type._(6, _omitEnumNames ? '' : 'PODCAST');

  static const $core.List<Album_Type> values = <Album_Type>[
    ALBUM,
    SINGLE,
    COMPILATION,
    EP,
    AUDIOBOOK,
    PODCAST,
  ];

  static final $core.List<Album_Type?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static Album_Type? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Album_Type._(super.value, super.name);
}

class AudioFile_Format extends $pb.ProtobufEnum {
  static const AudioFile_Format OGG_VORBIS_96 =
      AudioFile_Format._(0, _omitEnumNames ? '' : 'OGG_VORBIS_96');
  static const AudioFile_Format OGG_VORBIS_160 =
      AudioFile_Format._(1, _omitEnumNames ? '' : 'OGG_VORBIS_160');
  static const AudioFile_Format OGG_VORBIS_320 =
      AudioFile_Format._(2, _omitEnumNames ? '' : 'OGG_VORBIS_320');
  static const AudioFile_Format MP3_256 =
      AudioFile_Format._(3, _omitEnumNames ? '' : 'MP3_256');
  static const AudioFile_Format MP3_320 =
      AudioFile_Format._(4, _omitEnumNames ? '' : 'MP3_320');
  static const AudioFile_Format MP3_160 =
      AudioFile_Format._(5, _omitEnumNames ? '' : 'MP3_160');
  static const AudioFile_Format MP3_96 =
      AudioFile_Format._(6, _omitEnumNames ? '' : 'MP3_96');
  static const AudioFile_Format MP3_160_ENC =
      AudioFile_Format._(7, _omitEnumNames ? '' : 'MP3_160_ENC');
  static const AudioFile_Format MP4_128 =
      AudioFile_Format._(8, _omitEnumNames ? '' : 'MP4_128');
  static const AudioFile_Format MP4_192 =
      AudioFile_Format._(9, _omitEnumNames ? '' : 'MP4_192');
  static const AudioFile_Format MP4_256 =
      AudioFile_Format._(10, _omitEnumNames ? '' : 'MP4_256');
  static const AudioFile_Format MP4_320 =
      AudioFile_Format._(11, _omitEnumNames ? '' : 'MP4_320');
  static const AudioFile_Format MP4_96 =
      AudioFile_Format._(12, _omitEnumNames ? '' : 'MP4_96');
  static const AudioFile_Format MP4_BAM =
      AudioFile_Format._(13, _omitEnumNames ? '' : 'MP4_BAM');
  static const AudioFile_Format FLAC_FLAC =
      AudioFile_Format._(16, _omitEnumNames ? '' : 'FLAC_FLAC');
  static const AudioFile_Format XHE_AAC_24 =
      AudioFile_Format._(22, _omitEnumNames ? '' : 'XHE_AAC_24');

  static const $core.List<AudioFile_Format> values = <AudioFile_Format>[
    OGG_VORBIS_96,
    OGG_VORBIS_160,
    OGG_VORBIS_320,
    MP3_256,
    MP3_320,
    MP3_160,
    MP3_96,
    MP3_160_ENC,
    MP4_128,
    MP4_192,
    MP4_256,
    MP4_320,
    MP4_96,
    MP4_BAM,
    FLAC_FLAC,
    XHE_AAC_24,
  ];

  static final $core.Map<$core.int, AudioFile_Format> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static AudioFile_Format? valueOf($core.int value) => _byValue[value];

  const AudioFile_Format._(super.value, super.name);
}

class Image_Size extends $pb.ProtobufEnum {
  static const Image_Size DEFAULT =
      Image_Size._(0, _omitEnumNames ? '' : 'DEFAULT');
  static const Image_Size SMALL =
      Image_Size._(1, _omitEnumNames ? '' : 'SMALL');
  static const Image_Size LARGE =
      Image_Size._(2, _omitEnumNames ? '' : 'LARGE');
  static const Image_Size XLARGE =
      Image_Size._(3, _omitEnumNames ? '' : 'XLARGE');

  static const $core.List<Image_Size> values = <Image_Size>[
    DEFAULT,
    SMALL,
    LARGE,
    XLARGE,
  ];

  static final $core.List<Image_Size?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static Image_Size? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Image_Size._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
