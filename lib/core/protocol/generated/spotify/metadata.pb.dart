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

import 'metadata.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'metadata.pbenum.dart';

class Artist extends $pb.GeneratedMessage {
  factory Artist({
    $core.List<$core.int>? gid,
    $core.String? name,
    $core.int? popularity,
    ImageGroup? portraitGroup,
  }) {
    final result = Artist._();
    if (gid != null) result.gid = gid;
    if (name != null) result.name = name;
    if (popularity != null) result.popularity = popularity;
    if (portraitGroup != null) result.portraitGroup = portraitGroup;
    return result;
  }

  Artist._();

  factory Artist.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Artist()..mergeFromBuffer(data, registry);
  factory Artist.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Artist()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Artist',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: Artist.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'gid', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aI(3, _omitFieldNames ? '' : 'popularity', fieldType: $pb.PbFieldType.OS3)
    ..aOM<ImageGroup>(17, _omitFieldNames ? '' : 'portraitGroup',
        subBuilder: ImageGroup.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Artist clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Artist copyWith(void Function(Artist) updates) =>
      super.copyWith((message) => updates(message as Artist)) as Artist;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Artist() / Artist.new instead')
  static Artist create() => Artist._();
  static $pb.GeneratedMessage $_createMessage() => Artist._();
  @$core.override
  Artist createEmptyInstance() => Artist._();
  @$core.pragma('dart2js:noInline')
  static Artist getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Artist>(Artist.$_createMessage);
  static Artist? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get gid => $_getN(0);
  @$pb.TagNumber(1)
  set gid($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGid() => $_has(0);
  @$pb.TagNumber(1)
  void clearGid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get popularity => $_getIZ(2);
  @$pb.TagNumber(3)
  set popularity($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPopularity() => $_has(2);
  @$pb.TagNumber(3)
  void clearPopularity() => $_clearField(3);

  @$pb.TagNumber(17)
  ImageGroup get portraitGroup => $_getN(3);
  @$pb.TagNumber(17)
  set portraitGroup(ImageGroup value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasPortraitGroup() => $_has(3);
  @$pb.TagNumber(17)
  void clearPortraitGroup() => $_clearField(17);
  @$pb.TagNumber(17)
  ImageGroup ensurePortraitGroup() => $_ensure(3);
}

class Album extends $pb.GeneratedMessage {
  factory Album({
    $core.List<$core.int>? gid,
    $core.String? name,
    $core.Iterable<Artist>? artist,
    Album_Type? type,
    $core.String? label,
    Date? date,
    $core.int? popularity,
    ImageGroup? coverGroup,
    $core.String? typeStr,
  }) {
    final result = Album._();
    if (gid != null) result.gid = gid;
    if (name != null) result.name = name;
    if (artist != null) result.artist.addAll(artist);
    if (type != null) result.type = type;
    if (label != null) result.label = label;
    if (date != null) result.date = date;
    if (popularity != null) result.popularity = popularity;
    if (coverGroup != null) result.coverGroup = coverGroup;
    if (typeStr != null) result.typeStr = typeStr;
    return result;
  }

  Album._();

  factory Album.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Album()..mergeFromBuffer(data, registry);
  factory Album.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Album()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Album',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: Album.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'gid', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..pPM<Artist>(3, _omitFieldNames ? '' : 'artist',
        subBuilder: Artist.$_createMessage)
    ..aE<Album_Type>(4, _omitFieldNames ? '' : 'type',
        enumValues: Album_Type.values)
    ..aOS(5, _omitFieldNames ? '' : 'label')
    ..aOM<Date>(6, _omitFieldNames ? '' : 'date',
        subBuilder: Date.$_createMessage)
    ..aI(7, _omitFieldNames ? '' : 'popularity', fieldType: $pb.PbFieldType.OS3)
    ..aOM<ImageGroup>(17, _omitFieldNames ? '' : 'coverGroup',
        subBuilder: ImageGroup.$_createMessage)
    ..aOS(20, _omitFieldNames ? '' : 'typeStr')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Album clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Album copyWith(void Function(Album) updates) =>
      super.copyWith((message) => updates(message as Album)) as Album;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Album() / Album.new instead')
  static Album create() => Album._();
  static $pb.GeneratedMessage $_createMessage() => Album._();
  @$core.override
  Album createEmptyInstance() => Album._();
  @$core.pragma('dart2js:noInline')
  static Album getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Album>(Album.$_createMessage);
  static Album? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get gid => $_getN(0);
  @$pb.TagNumber(1)
  set gid($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGid() => $_has(0);
  @$pb.TagNumber(1)
  void clearGid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<Artist> get artist => $_getList(2);

  @$pb.TagNumber(4)
  Album_Type get type => $_getN(3);
  @$pb.TagNumber(4)
  set type(Album_Type value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasType() => $_has(3);
  @$pb.TagNumber(4)
  void clearType() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get label => $_getSZ(4);
  @$pb.TagNumber(5)
  set label($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLabel() => $_has(4);
  @$pb.TagNumber(5)
  void clearLabel() => $_clearField(5);

  @$pb.TagNumber(6)
  Date get date => $_getN(5);
  @$pb.TagNumber(6)
  set date(Date value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasDate() => $_has(5);
  @$pb.TagNumber(6)
  void clearDate() => $_clearField(6);
  @$pb.TagNumber(6)
  Date ensureDate() => $_ensure(5);

  @$pb.TagNumber(7)
  $core.int get popularity => $_getIZ(6);
  @$pb.TagNumber(7)
  set popularity($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPopularity() => $_has(6);
  @$pb.TagNumber(7)
  void clearPopularity() => $_clearField(7);

  @$pb.TagNumber(17)
  ImageGroup get coverGroup => $_getN(7);
  @$pb.TagNumber(17)
  set coverGroup(ImageGroup value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasCoverGroup() => $_has(7);
  @$pb.TagNumber(17)
  void clearCoverGroup() => $_clearField(17);
  @$pb.TagNumber(17)
  ImageGroup ensureCoverGroup() => $_ensure(7);

  @$pb.TagNumber(20)
  $core.String get typeStr => $_getSZ(8);
  @$pb.TagNumber(20)
  set typeStr($core.String value) => $_setString(8, value);
  @$pb.TagNumber(20)
  $core.bool hasTypeStr() => $_has(8);
  @$pb.TagNumber(20)
  void clearTypeStr() => $_clearField(20);
}

class AudioFile extends $pb.GeneratedMessage {
  factory AudioFile({
    $core.List<$core.int>? fileId,
    AudioFile_Format? format,
  }) {
    final result = AudioFile._();
    if (fileId != null) result.fileId = fileId;
    if (format != null) result.format = format;
    return result;
  }

  AudioFile._();

  factory AudioFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioFile()..mergeFromBuffer(data, registry);
  factory AudioFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioFile()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioFile',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: AudioFile.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'fileId', $pb.PbFieldType.OY)
    ..aE<AudioFile_Format>(2, _omitFieldNames ? '' : 'format',
        enumValues: AudioFile_Format.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioFile copyWith(void Function(AudioFile) updates) =>
      super.copyWith((message) => updates(message as AudioFile)) as AudioFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AudioFile() / AudioFile.new instead')
  static AudioFile create() => AudioFile._();
  static $pb.GeneratedMessage $_createMessage() => AudioFile._();
  @$core.override
  AudioFile createEmptyInstance() => AudioFile._();
  @$core.pragma('dart2js:noInline')
  static AudioFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AudioFile>(AudioFile.$_createMessage);
  static AudioFile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get fileId => $_getN(0);
  @$pb.TagNumber(1)
  set fileId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFileId() => $_clearField(1);

  @$pb.TagNumber(2)
  AudioFile_Format get format => $_getN(1);
  @$pb.TagNumber(2)
  set format(AudioFile_Format value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormat() => $_clearField(2);
}

class Track extends $pb.GeneratedMessage {
  factory Track({
    $core.List<$core.int>? gid,
    $core.String? name,
    Album? album,
    $core.Iterable<Artist>? artist,
    $core.int? number,
    $core.int? discNumber,
    $core.int? duration,
    $core.int? popularity,
    $core.bool? explicit,
    $core.Iterable<AudioFile>? file,
    $core.Iterable<AudioFile>? preview,
    $core.String? canonicalUri,
  }) {
    final result = Track._();
    if (gid != null) result.gid = gid;
    if (name != null) result.name = name;
    if (album != null) result.album = album;
    if (artist != null) result.artist.addAll(artist);
    if (number != null) result.number = number;
    if (discNumber != null) result.discNumber = discNumber;
    if (duration != null) result.duration = duration;
    if (popularity != null) result.popularity = popularity;
    if (explicit != null) result.explicit = explicit;
    if (file != null) result.file.addAll(file);
    if (preview != null) result.preview.addAll(preview);
    if (canonicalUri != null) result.canonicalUri = canonicalUri;
    return result;
  }

  Track._();

  factory Track.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Track()..mergeFromBuffer(data, registry);
  factory Track.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Track()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Track',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: Track.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'gid', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOM<Album>(3, _omitFieldNames ? '' : 'album',
        subBuilder: Album.$_createMessage)
    ..pPM<Artist>(4, _omitFieldNames ? '' : 'artist',
        subBuilder: Artist.$_createMessage)
    ..aI(5, _omitFieldNames ? '' : 'number', fieldType: $pb.PbFieldType.OS3)
    ..aI(6, _omitFieldNames ? '' : 'discNumber', fieldType: $pb.PbFieldType.OS3)
    ..aI(7, _omitFieldNames ? '' : 'duration', fieldType: $pb.PbFieldType.OS3)
    ..aI(8, _omitFieldNames ? '' : 'popularity', fieldType: $pb.PbFieldType.OS3)
    ..aOB(9, _omitFieldNames ? '' : 'explicit')
    ..pPM<AudioFile>(14, _omitFieldNames ? '' : 'file',
        subBuilder: AudioFile.$_createMessage)
    ..pPM<AudioFile>(17, _omitFieldNames ? '' : 'preview',
        subBuilder: AudioFile.$_createMessage)
    ..aOS(36, _omitFieldNames ? '' : 'canonicalUri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Track clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Track copyWith(void Function(Track) updates) =>
      super.copyWith((message) => updates(message as Track)) as Track;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Track() / Track.new instead')
  static Track create() => Track._();
  static $pb.GeneratedMessage $_createMessage() => Track._();
  @$core.override
  Track createEmptyInstance() => Track._();
  @$core.pragma('dart2js:noInline')
  static Track getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Track>(Track.$_createMessage);
  static Track? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get gid => $_getN(0);
  @$pb.TagNumber(1)
  set gid($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGid() => $_has(0);
  @$pb.TagNumber(1)
  void clearGid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  Album get album => $_getN(2);
  @$pb.TagNumber(3)
  set album(Album value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAlbum() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlbum() => $_clearField(3);
  @$pb.TagNumber(3)
  Album ensureAlbum() => $_ensure(2);

  @$pb.TagNumber(4)
  $pb.PbList<Artist> get artist => $_getList(3);

  @$pb.TagNumber(5)
  $core.int get number => $_getIZ(4);
  @$pb.TagNumber(5)
  set number($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNumber() => $_has(4);
  @$pb.TagNumber(5)
  void clearNumber() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get discNumber => $_getIZ(5);
  @$pb.TagNumber(6)
  set discNumber($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDiscNumber() => $_has(5);
  @$pb.TagNumber(6)
  void clearDiscNumber() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get duration => $_getIZ(6);
  @$pb.TagNumber(7)
  set duration($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDuration() => $_has(6);
  @$pb.TagNumber(7)
  void clearDuration() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get popularity => $_getIZ(7);
  @$pb.TagNumber(8)
  set popularity($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPopularity() => $_has(7);
  @$pb.TagNumber(8)
  void clearPopularity() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get explicit => $_getBF(8);
  @$pb.TagNumber(9)
  set explicit($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasExplicit() => $_has(8);
  @$pb.TagNumber(9)
  void clearExplicit() => $_clearField(9);

  @$pb.TagNumber(14)
  $pb.PbList<AudioFile> get file => $_getList(9);

  @$pb.TagNumber(17)
  $pb.PbList<AudioFile> get preview => $_getList(10);

  @$pb.TagNumber(36)
  $core.String get canonicalUri => $_getSZ(11);
  @$pb.TagNumber(36)
  set canonicalUri($core.String value) => $_setString(11, value);
  @$pb.TagNumber(36)
  $core.bool hasCanonicalUri() => $_has(11);
  @$pb.TagNumber(36)
  void clearCanonicalUri() => $_clearField(36);
}

class Show extends $pb.GeneratedMessage {
  factory Show({
    $core.List<$core.int>? gid,
    $core.String? name,
    $core.String? description,
    $core.String? publisher,
    $core.String? language,
    $core.bool? explicit,
    ImageGroup? coverImage,
    $core.Iterable<$core.String>? keyword,
  }) {
    final result = Show._();
    if (gid != null) result.gid = gid;
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (publisher != null) result.publisher = publisher;
    if (language != null) result.language = language;
    if (explicit != null) result.explicit = explicit;
    if (coverImage != null) result.coverImage = coverImage;
    if (keyword != null) result.keyword.addAll(keyword);
    return result;
  }

  Show._();

  factory Show.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Show()..mergeFromBuffer(data, registry);
  factory Show.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Show()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Show',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: Show.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'gid', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(64, _omitFieldNames ? '' : 'description')
    ..aOS(66, _omitFieldNames ? '' : 'publisher')
    ..aOS(67, _omitFieldNames ? '' : 'language')
    ..aOB(68, _omitFieldNames ? '' : 'explicit')
    ..aOM<ImageGroup>(69, _omitFieldNames ? '' : 'coverImage',
        subBuilder: ImageGroup.$_createMessage)
    ..pPS(73, _omitFieldNames ? '' : 'keyword')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Show clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Show copyWith(void Function(Show) updates) =>
      super.copyWith((message) => updates(message as Show)) as Show;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Show() / Show.new instead')
  static Show create() => Show._();
  static $pb.GeneratedMessage $_createMessage() => Show._();
  @$core.override
  Show createEmptyInstance() => Show._();
  @$core.pragma('dart2js:noInline')
  static Show getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Show>(Show.$_createMessage);
  static Show? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get gid => $_getN(0);
  @$pb.TagNumber(1)
  set gid($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGid() => $_has(0);
  @$pb.TagNumber(1)
  void clearGid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(64)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(64)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(64)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(64)
  void clearDescription() => $_clearField(64);

  @$pb.TagNumber(66)
  $core.String get publisher => $_getSZ(3);
  @$pb.TagNumber(66)
  set publisher($core.String value) => $_setString(3, value);
  @$pb.TagNumber(66)
  $core.bool hasPublisher() => $_has(3);
  @$pb.TagNumber(66)
  void clearPublisher() => $_clearField(66);

  @$pb.TagNumber(67)
  $core.String get language => $_getSZ(4);
  @$pb.TagNumber(67)
  set language($core.String value) => $_setString(4, value);
  @$pb.TagNumber(67)
  $core.bool hasLanguage() => $_has(4);
  @$pb.TagNumber(67)
  void clearLanguage() => $_clearField(67);

  @$pb.TagNumber(68)
  $core.bool get explicit => $_getBF(5);
  @$pb.TagNumber(68)
  set explicit($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(68)
  $core.bool hasExplicit() => $_has(5);
  @$pb.TagNumber(68)
  void clearExplicit() => $_clearField(68);

  @$pb.TagNumber(69)
  ImageGroup get coverImage => $_getN(6);
  @$pb.TagNumber(69)
  set coverImage(ImageGroup value) => $_setField(69, value);
  @$pb.TagNumber(69)
  $core.bool hasCoverImage() => $_has(6);
  @$pb.TagNumber(69)
  void clearCoverImage() => $_clearField(69);
  @$pb.TagNumber(69)
  ImageGroup ensureCoverImage() => $_ensure(6);

  @$pb.TagNumber(73)
  $pb.PbList<$core.String> get keyword => $_getList(7);
}

class Episode extends $pb.GeneratedMessage {
  factory Episode({
    $core.List<$core.int>? gid,
    $core.String? name,
    $core.int? duration,
    $core.String? description,
    Date? publishTime,
    ImageGroup? coverImage,
    $core.String? language,
    $core.bool? explicit,
    Show? show,
  }) {
    final result = Episode._();
    if (gid != null) result.gid = gid;
    if (name != null) result.name = name;
    if (duration != null) result.duration = duration;
    if (description != null) result.description = description;
    if (publishTime != null) result.publishTime = publishTime;
    if (coverImage != null) result.coverImage = coverImage;
    if (language != null) result.language = language;
    if (explicit != null) result.explicit = explicit;
    if (show != null) result.show = show;
    return result;
  }

  Episode._();

  factory Episode.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Episode()..mergeFromBuffer(data, registry);
  factory Episode.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Episode()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Episode',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: Episode.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'gid', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aI(7, _omitFieldNames ? '' : 'duration', fieldType: $pb.PbFieldType.OS3)
    ..aOS(64, _omitFieldNames ? '' : 'description')
    ..aOM<Date>(66, _omitFieldNames ? '' : 'publishTime',
        subBuilder: Date.$_createMessage)
    ..aOM<ImageGroup>(68, _omitFieldNames ? '' : 'coverImage',
        subBuilder: ImageGroup.$_createMessage)
    ..aOS(69, _omitFieldNames ? '' : 'language')
    ..aOB(70, _omitFieldNames ? '' : 'explicit')
    ..aOM<Show>(71, _omitFieldNames ? '' : 'show',
        subBuilder: Show.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Episode clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Episode copyWith(void Function(Episode) updates) =>
      super.copyWith((message) => updates(message as Episode)) as Episode;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Episode() / Episode.new instead')
  static Episode create() => Episode._();
  static $pb.GeneratedMessage $_createMessage() => Episode._();
  @$core.override
  Episode createEmptyInstance() => Episode._();
  @$core.pragma('dart2js:noInline')
  static Episode getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Episode>(Episode.$_createMessage);
  static Episode? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get gid => $_getN(0);
  @$pb.TagNumber(1)
  set gid($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGid() => $_has(0);
  @$pb.TagNumber(1)
  void clearGid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(7)
  $core.int get duration => $_getIZ(2);
  @$pb.TagNumber(7)
  set duration($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(7)
  $core.bool hasDuration() => $_has(2);
  @$pb.TagNumber(7)
  void clearDuration() => $_clearField(7);

  @$pb.TagNumber(64)
  $core.String get description => $_getSZ(3);
  @$pb.TagNumber(64)
  set description($core.String value) => $_setString(3, value);
  @$pb.TagNumber(64)
  $core.bool hasDescription() => $_has(3);
  @$pb.TagNumber(64)
  void clearDescription() => $_clearField(64);

  @$pb.TagNumber(66)
  Date get publishTime => $_getN(4);
  @$pb.TagNumber(66)
  set publishTime(Date value) => $_setField(66, value);
  @$pb.TagNumber(66)
  $core.bool hasPublishTime() => $_has(4);
  @$pb.TagNumber(66)
  void clearPublishTime() => $_clearField(66);
  @$pb.TagNumber(66)
  Date ensurePublishTime() => $_ensure(4);

  @$pb.TagNumber(68)
  ImageGroup get coverImage => $_getN(5);
  @$pb.TagNumber(68)
  set coverImage(ImageGroup value) => $_setField(68, value);
  @$pb.TagNumber(68)
  $core.bool hasCoverImage() => $_has(5);
  @$pb.TagNumber(68)
  void clearCoverImage() => $_clearField(68);
  @$pb.TagNumber(68)
  ImageGroup ensureCoverImage() => $_ensure(5);

  @$pb.TagNumber(69)
  $core.String get language => $_getSZ(6);
  @$pb.TagNumber(69)
  set language($core.String value) => $_setString(6, value);
  @$pb.TagNumber(69)
  $core.bool hasLanguage() => $_has(6);
  @$pb.TagNumber(69)
  void clearLanguage() => $_clearField(69);

  @$pb.TagNumber(70)
  $core.bool get explicit => $_getBF(7);
  @$pb.TagNumber(70)
  set explicit($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(70)
  $core.bool hasExplicit() => $_has(7);
  @$pb.TagNumber(70)
  void clearExplicit() => $_clearField(70);

  @$pb.TagNumber(71)
  Show get show => $_getN(8);
  @$pb.TagNumber(71)
  set show(Show value) => $_setField(71, value);
  @$pb.TagNumber(71)
  $core.bool hasShow() => $_has(8);
  @$pb.TagNumber(71)
  void clearShow() => $_clearField(71);
  @$pb.TagNumber(71)
  Show ensureShow() => $_ensure(8);
}

class Date extends $pb.GeneratedMessage {
  factory Date({
    $core.int? year,
    $core.int? month,
    $core.int? day,
  }) {
    final result = Date._();
    if (year != null) result.year = year;
    if (month != null) result.month = month;
    if (day != null) result.day = day;
    return result;
  }

  Date._();

  factory Date.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Date()..mergeFromBuffer(data, registry);
  factory Date.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Date()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Date',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: Date.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'year', fieldType: $pb.PbFieldType.OS3)
    ..aI(2, _omitFieldNames ? '' : 'month', fieldType: $pb.PbFieldType.OS3)
    ..aI(3, _omitFieldNames ? '' : 'day', fieldType: $pb.PbFieldType.OS3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Date clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Date copyWith(void Function(Date) updates) =>
      super.copyWith((message) => updates(message as Date)) as Date;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Date() / Date.new instead')
  static Date create() => Date._();
  static $pb.GeneratedMessage $_createMessage() => Date._();
  @$core.override
  Date createEmptyInstance() => Date._();
  @$core.pragma('dart2js:noInline')
  static Date getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Date>(Date.$_createMessage);
  static Date? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get year => $_getIZ(0);
  @$pb.TagNumber(1)
  set year($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasYear() => $_has(0);
  @$pb.TagNumber(1)
  void clearYear() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get month => $_getIZ(1);
  @$pb.TagNumber(2)
  set month($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMonth() => $_has(1);
  @$pb.TagNumber(2)
  void clearMonth() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get day => $_getIZ(2);
  @$pb.TagNumber(3)
  set day($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDay() => $_has(2);
  @$pb.TagNumber(3)
  void clearDay() => $_clearField(3);
}

class Image extends $pb.GeneratedMessage {
  factory Image({
    $core.List<$core.int>? fileId,
    Image_Size? size,
    $core.int? width,
    $core.int? height,
  }) {
    final result = Image._();
    if (fileId != null) result.fileId = fileId;
    if (size != null) result.size = size;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    return result;
  }

  Image._();

  factory Image.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Image()..mergeFromBuffer(data, registry);
  factory Image.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Image()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Image',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: Image.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'fileId', $pb.PbFieldType.OY)
    ..aE<Image_Size>(2, _omitFieldNames ? '' : 'size',
        enumValues: Image_Size.values)
    ..aI(3, _omitFieldNames ? '' : 'width', fieldType: $pb.PbFieldType.OS3)
    ..aI(4, _omitFieldNames ? '' : 'height', fieldType: $pb.PbFieldType.OS3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Image clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Image copyWith(void Function(Image) updates) =>
      super.copyWith((message) => updates(message as Image)) as Image;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Image() / Image.new instead')
  static Image create() => Image._();
  static $pb.GeneratedMessage $_createMessage() => Image._();
  @$core.override
  Image createEmptyInstance() => Image._();
  @$core.pragma('dart2js:noInline')
  static Image getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Image>(Image.$_createMessage);
  static Image? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get fileId => $_getN(0);
  @$pb.TagNumber(1)
  set fileId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFileId() => $_clearField(1);

  @$pb.TagNumber(2)
  Image_Size get size => $_getN(1);
  @$pb.TagNumber(2)
  set size(Image_Size value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearSize() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get width => $_getIZ(2);
  @$pb.TagNumber(3)
  set width($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWidth() => $_has(2);
  @$pb.TagNumber(3)
  void clearWidth() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get height => $_getIZ(3);
  @$pb.TagNumber(4)
  set height($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHeight() => $_has(3);
  @$pb.TagNumber(4)
  void clearHeight() => $_clearField(4);
}

class ImageGroup extends $pb.GeneratedMessage {
  factory ImageGroup({
    $core.Iterable<Image>? image,
  }) {
    final result = ImageGroup._();
    if (image != null) result.image.addAll(image);
    return result;
  }

  ImageGroup._();

  factory ImageGroup.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ImageGroup()..mergeFromBuffer(data, registry);
  factory ImageGroup.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ImageGroup()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImageGroup',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: ImageGroup.$_createMessage)
    ..pPM<Image>(1, _omitFieldNames ? '' : 'image',
        subBuilder: Image.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImageGroup clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImageGroup copyWith(void Function(ImageGroup) updates) =>
      super.copyWith((message) => updates(message as ImageGroup)) as ImageGroup;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ImageGroup() / ImageGroup.new instead')
  static ImageGroup create() => ImageGroup._();
  static $pb.GeneratedMessage $_createMessage() => ImageGroup._();
  @$core.override
  ImageGroup createEmptyInstance() => ImageGroup._();
  @$core.pragma('dart2js:noInline')
  static ImageGroup getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImageGroup>(ImageGroup.$_createMessage);
  static ImageGroup? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Image> get image => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
