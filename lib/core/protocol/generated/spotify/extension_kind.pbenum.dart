// This is a generated file - do not edit.
//
// Generated from spotify/extension_kind.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// ExtensionKind enum - from decompiled n5w.java
/// Only including values relevant to our use cases
class ExtensionKind extends $pb.ProtobufEnum {
  static const ExtensionKind UNKNOWN_EXTENSION =
      ExtensionKind._(0, _omitEnumNames ? '' : 'UNKNOWN_EXTENSION');
  static const ExtensionKind CANVAZ =
      ExtensionKind._(1, _omitEnumNames ? '' : 'CANVAZ');
  static const ExtensionKind ARTIST_V4 =
      ExtensionKind._(8, _omitEnumNames ? '' : 'ARTIST_V4');
  static const ExtensionKind ALBUM_V4 =
      ExtensionKind._(9, _omitEnumNames ? '' : 'ALBUM_V4');
  static const ExtensionKind TRACK_V4 =
      ExtensionKind._(10, _omitEnumNames ? '' : 'TRACK_V4');
  static const ExtensionKind SHOW_V4 =
      ExtensionKind._(11, _omitEnumNames ? '' : 'SHOW_V4');
  static const ExtensionKind EPISODE_V4 =
      ExtensionKind._(12, _omitEnumNames ? '' : 'EPISODE_V4');
  static const ExtensionKind USER_PROFILE =
      ExtensionKind._(15, _omitEnumNames ? '' : 'USER_PROFILE');
  static const ExtensionKind EXTRACTED_COLOR =
      ExtensionKind._(23, _omitEnumNames ? '' : 'EXTRACTED_COLOR');
  static const ExtensionKind PLAY_TRAIT =
      ExtensionKind._(57, _omitEnumNames ? '' : 'PLAY_TRAIT');
  static const ExtensionKind NAVIGABLE_TRAIT =
      ExtensionKind._(62, _omitEnumNames ? '' : 'NAVIGABLE_TRAIT');
  static const ExtensionKind PLAYABILITY =
      ExtensionKind._(78, _omitEnumNames ? '' : 'PLAYABILITY');
  static const ExtensionKind COVER_IMAGE =
      ExtensionKind._(79, _omitEnumNames ? '' : 'COVER_IMAGE');
  static const ExtensionKind SHARE_TRAIT =
      ExtensionKind._(80, _omitEnumNames ? '' : 'SHARE_TRAIT');
  static const ExtensionKind SIMPLE_TRAIT =
      ExtensionKind._(97, _omitEnumNames ? '' : 'SIMPLE_TRAIT');
  static const ExtensionKind AUDIO_PREVIEW_PLAYBACK_TRAIT = ExtensionKind._(
      116, _omitEnumNames ? '' : 'AUDIO_PREVIEW_PLAYBACK_TRAIT');
  static const ExtensionKind PREVIEW_CARD_TRAIT =
      ExtensionKind._(118, _omitEnumNames ? '' : 'PREVIEW_CARD_TRAIT');
  static const ExtensionKind SHORTCUTS_CARD_TRAIT =
      ExtensionKind._(119, _omitEnumNames ? '' : 'SHORTCUTS_CARD_TRAIT');
  static const ExtensionKind VIDEO_PREVIEW_PLAYBACK_TRAIT = ExtensionKind._(
      120, _omitEnumNames ? '' : 'VIDEO_PREVIEW_PLAYBACK_TRAIT');
  static const ExtensionKind IDENTITY_TRAIT =
      ExtensionKind._(178, _omitEnumNames ? '' : 'IDENTITY_TRAIT');
  static const ExtensionKind VISUAL_IDENTITY_TRAIT =
      ExtensionKind._(179, _omitEnumNames ? '' : 'VISUAL_IDENTITY_TRAIT');
  static const ExtensionKind CONTENT_TYPE_V2_TRAIT =
      ExtensionKind._(180, _omitEnumNames ? '' : 'CONTENT_TYPE_V2_TRAIT');
  static const ExtensionKind PREVIEW_PLAYBACK_TRAIT =
      ExtensionKind._(181, _omitEnumNames ? '' : 'PREVIEW_PLAYBACK_TRAIT');
  static const ExtensionKind PLAYBACK_TRAIT =
      ExtensionKind._(212, _omitEnumNames ? '' : 'PLAYBACK_TRAIT');
  static const ExtensionKind ENTITY_TYPE_TRAIT =
      ExtensionKind._(220, _omitEnumNames ? '' : 'ENTITY_TYPE_TRAIT');

  static const $core.List<ExtensionKind> values = <ExtensionKind>[
    UNKNOWN_EXTENSION,
    CANVAZ,
    ARTIST_V4,
    ALBUM_V4,
    TRACK_V4,
    SHOW_V4,
    EPISODE_V4,
    USER_PROFILE,
    EXTRACTED_COLOR,
    PLAY_TRAIT,
    NAVIGABLE_TRAIT,
    PLAYABILITY,
    COVER_IMAGE,
    SHARE_TRAIT,
    SIMPLE_TRAIT,
    AUDIO_PREVIEW_PLAYBACK_TRAIT,
    PREVIEW_CARD_TRAIT,
    SHORTCUTS_CARD_TRAIT,
    VIDEO_PREVIEW_PLAYBACK_TRAIT,
    IDENTITY_TRAIT,
    VISUAL_IDENTITY_TRAIT,
    CONTENT_TYPE_V2_TRAIT,
    PREVIEW_PLAYBACK_TRAIT,
    PLAYBACK_TRAIT,
    ENTITY_TYPE_TRAIT,
  ];

  static final $core.Map<$core.int, ExtensionKind> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ExtensionKind? valueOf($core.int value) => _byValue[value];

  const ExtensionKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
