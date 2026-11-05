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

class Audio_Format extends $pb.ProtobufEnum {
  static const Audio_Format UNKNOWN =
      Audio_Format._(0, _omitEnumNames ? '' : 'UNKNOWN');
  static const Audio_Format DEFAULT =
      Audio_Format._(1, _omitEnumNames ? '' : 'DEFAULT');
  static const Audio_Format PARROT =
      Audio_Format._(2, _omitEnumNames ? '' : 'PARROT');

  static const $core.List<Audio_Format> values = <Audio_Format>[
    UNKNOWN,
    DEFAULT,
    PARROT,
  ];

  static final $core.List<Audio_Format?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Audio_Format? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Audio_Format._(super.value, super.name);
}

class ArtistWithRole_Role extends $pb.ProtobufEnum {
  static const ArtistWithRole_Role ARTIST_ROLE_UNKNOWN =
      ArtistWithRole_Role._(0, _omitEnumNames ? '' : 'ARTIST_ROLE_UNKNOWN');
  static const ArtistWithRole_Role ARTIST_ROLE_MAIN_ARTIST =
      ArtistWithRole_Role._(1, _omitEnumNames ? '' : 'ARTIST_ROLE_MAIN_ARTIST');
  static const ArtistWithRole_Role ARTIST_ROLE_FEATURED_ARTIST =
      ArtistWithRole_Role._(
          2, _omitEnumNames ? '' : 'ARTIST_ROLE_FEATURED_ARTIST');
  static const ArtistWithRole_Role ARTIST_ROLE_REMIXER =
      ArtistWithRole_Role._(3, _omitEnumNames ? '' : 'ARTIST_ROLE_REMIXER');
  static const ArtistWithRole_Role ARTIST_ROLE_ACTOR =
      ArtistWithRole_Role._(4, _omitEnumNames ? '' : 'ARTIST_ROLE_ACTOR');
  static const ArtistWithRole_Role ARTIST_ROLE_COMPOSER =
      ArtistWithRole_Role._(5, _omitEnumNames ? '' : 'ARTIST_ROLE_COMPOSER');
  static const ArtistWithRole_Role ARTIST_ROLE_CONDUCTOR =
      ArtistWithRole_Role._(6, _omitEnumNames ? '' : 'ARTIST_ROLE_CONDUCTOR');
  static const ArtistWithRole_Role ARTIST_ROLE_ORCHESTRA =
      ArtistWithRole_Role._(7, _omitEnumNames ? '' : 'ARTIST_ROLE_ORCHESTRA');

  static const $core.List<ArtistWithRole_Role> values = <ArtistWithRole_Role>[
    ARTIST_ROLE_UNKNOWN,
    ARTIST_ROLE_MAIN_ARTIST,
    ARTIST_ROLE_FEATURED_ARTIST,
    ARTIST_ROLE_REMIXER,
    ARTIST_ROLE_ACTOR,
    ARTIST_ROLE_COMPOSER,
    ARTIST_ROLE_CONDUCTOR,
    ARTIST_ROLE_ORCHESTRA,
  ];

  static final $core.List<ArtistWithRole_Role?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static ArtistWithRole_Role? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ArtistWithRole_Role._(super.value, super.name);
}

class Copyright_Type extends $pb.ProtobufEnum {
  static const Copyright_Type P_COPYRIGHT =
      Copyright_Type._(0, _omitEnumNames ? '' : 'P_COPYRIGHT');
  static const Copyright_Type C_COPYRIGHT =
      Copyright_Type._(1, _omitEnumNames ? '' : 'C_COPYRIGHT');

  static const $core.List<Copyright_Type> values = <Copyright_Type>[
    P_COPYRIGHT,
    C_COPYRIGHT,
  ];

  static final $core.List<Copyright_Type?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static Copyright_Type? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Copyright_Type._(super.value, super.name);
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
  static const AudioFile_Format AAC_24 =
      AudioFile_Format._(8, _omitEnumNames ? '' : 'AAC_24');
  static const AudioFile_Format AAC_48 =
      AudioFile_Format._(9, _omitEnumNames ? '' : 'AAC_48');
  static const AudioFile_Format MP4_128 =
      AudioFile_Format._(10, _omitEnumNames ? '' : 'MP4_128');
  static const AudioFile_Format MP4_256 =
      AudioFile_Format._(11, _omitEnumNames ? '' : 'MP4_256');
  static const AudioFile_Format MP4_128_DUAL =
      AudioFile_Format._(12, _omitEnumNames ? '' : 'MP4_128_DUAL');
  static const AudioFile_Format MP4_256_DUAL =
      AudioFile_Format._(13, _omitEnumNames ? '' : 'MP4_256_DUAL');
  static const AudioFile_Format MP4_128_CBCS =
      AudioFile_Format._(14, _omitEnumNames ? '' : 'MP4_128_CBCS');
  static const AudioFile_Format MP4_256_CBCS =
      AudioFile_Format._(15, _omitEnumNames ? '' : 'MP4_256_CBCS');
  static const AudioFile_Format FLAC_FLAC =
      AudioFile_Format._(16, _omitEnumNames ? '' : 'FLAC_FLAC');
  static const AudioFile_Format MP4_FLAC =
      AudioFile_Format._(17, _omitEnumNames ? '' : 'MP4_FLAC');

  static const $core.List<AudioFile_Format> values = <AudioFile_Format>[
    OGG_VORBIS_96,
    OGG_VORBIS_160,
    OGG_VORBIS_320,
    MP3_256,
    MP3_320,
    MP3_160,
    MP3_96,
    MP3_160_ENC,
    AAC_24,
    AAC_48,
    MP4_128,
    MP4_256,
    MP4_128_DUAL,
    MP4_256_DUAL,
    MP4_128_CBCS,
    MP4_256_CBCS,
    FLAC_FLAC,
    MP4_FLAC,
  ];

  static final $core.List<AudioFile_Format?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 17);
  static AudioFile_Format? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AudioFile_Format._(super.value, super.name);
}

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

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
