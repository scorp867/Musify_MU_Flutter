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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'metadata.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'metadata.pbenum.dart';

class Date extends $pb.GeneratedMessage {
  factory Date({
    $core.int? year,
    $core.int? month,
    $core.int? day,
    $core.int? hour,
    $core.int? minute,
  }) {
    final result = Date._();
    if (year != null) result.year = year;
    if (month != null) result.month = month;
    if (day != null) result.day = day;
    if (hour != null) result.hour = hour;
    if (minute != null) result.minute = minute;
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
    ..aI(4, _omitFieldNames ? '' : 'hour', fieldType: $pb.PbFieldType.OS3)
    ..aI(5, _omitFieldNames ? '' : 'minute', fieldType: $pb.PbFieldType.OS3)
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

  @$pb.TagNumber(4)
  $core.int get hour => $_getIZ(3);
  @$pb.TagNumber(4)
  set hour($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHour() => $_has(3);
  @$pb.TagNumber(4)
  void clearHour() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get minute => $_getIZ(4);
  @$pb.TagNumber(5)
  set minute($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMinute() => $_has(4);
  @$pb.TagNumber(5)
  void clearMinute() => $_clearField(5);
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

class ExternalId extends $pb.GeneratedMessage {
  factory ExternalId({
    $core.String? type,
    $core.String? id,
  }) {
    final result = ExternalId._();
    if (type != null) result.type = type;
    if (id != null) result.id = id;
    return result;
  }

  ExternalId._();

  factory ExternalId.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExternalId()..mergeFromBuffer(data, registry);
  factory ExternalId.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExternalId()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExternalId',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: ExternalId.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExternalId clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExternalId copyWith(void Function(ExternalId) updates) =>
      super.copyWith((message) => updates(message as ExternalId)) as ExternalId;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ExternalId() / ExternalId.new instead')
  static ExternalId create() => ExternalId._();
  static $pb.GeneratedMessage $_createMessage() => ExternalId._();
  @$core.override
  ExternalId createEmptyInstance() => ExternalId._();
  @$core.pragma('dart2js:noInline')
  static ExternalId getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExternalId>(ExternalId.$_createMessage);
  static ExternalId? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);
}

class Restriction extends $pb.GeneratedMessage {
  factory Restriction({
    $core.Iterable<$core.int>? catalogue,
    $core.int? type,
    $core.Iterable<$core.String>? catalogueStr,
  }) {
    final result = Restriction._();
    if (catalogue != null) result.catalogue.addAll(catalogue);
    if (type != null) result.type = type;
    if (catalogueStr != null) result.catalogueStr.addAll(catalogueStr);
    return result;
  }

  Restriction._();

  factory Restriction.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Restriction()..mergeFromBuffer(data, registry);
  factory Restriction.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Restriction()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Restriction',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: Restriction.$_createMessage)
    ..p<$core.int>(1, _omitFieldNames ? '' : 'catalogue', $pb.PbFieldType.PS3)
    ..aI(4, _omitFieldNames ? '' : 'type', fieldType: $pb.PbFieldType.OS3)
    ..pPS(5, _omitFieldNames ? '' : 'catalogueStr')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Restriction clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Restriction copyWith(void Function(Restriction) updates) =>
      super.copyWith((message) => updates(message as Restriction))
          as Restriction;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Restriction() / Restriction.new instead')
  static Restriction create() => Restriction._();
  static $pb.GeneratedMessage $_createMessage() => Restriction._();
  @$core.override
  Restriction createEmptyInstance() => Restriction._();
  @$core.pragma('dart2js:noInline')
  static Restriction getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Restriction>(
          Restriction.$_createMessage);
  static Restriction? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.int> get catalogue => $_getList(0);

  @$pb.TagNumber(4)
  $core.int get type => $_getIZ(1);
  @$pb.TagNumber(4)
  set type($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(4)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(4)
  void clearType() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get catalogueStr => $_getList(2);
}

class Licensor extends $pb.GeneratedMessage {
  factory Licensor({
    $core.List<$core.int>? uuid,
  }) {
    final result = Licensor._();
    if (uuid != null) result.uuid = uuid;
    return result;
  }

  Licensor._();

  factory Licensor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Licensor()..mergeFromBuffer(data, registry);
  factory Licensor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Licensor()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Licensor',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: Licensor.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'uuid', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Licensor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Licensor copyWith(void Function(Licensor) updates) =>
      super.copyWith((message) => updates(message as Licensor)) as Licensor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Licensor() / Licensor.new instead')
  static Licensor create() => Licensor._();
  static $pb.GeneratedMessage $_createMessage() => Licensor._();
  @$core.override
  Licensor createEmptyInstance() => Licensor._();
  @$core.pragma('dart2js:noInline')
  static Licensor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Licensor>(Licensor.$_createMessage);
  static Licensor? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get uuid => $_getN(0);
  @$pb.TagNumber(1)
  set uuid($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUuid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUuid() => $_clearField(1);
}

class Audio extends $pb.GeneratedMessage {
  factory Audio({
    $core.List<$core.int>? uuid,
    Audio_Format? format,
  }) {
    final result = Audio._();
    if (uuid != null) result.uuid = uuid;
    if (format != null) result.format = format;
    return result;
  }

  Audio._();

  factory Audio.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Audio()..mergeFromBuffer(data, registry);
  factory Audio.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Audio()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Audio',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: Audio.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'uuid', $pb.PbFieldType.OY)
    ..aE<Audio_Format>(2, _omitFieldNames ? '' : 'format',
        enumValues: Audio_Format.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Audio clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Audio copyWith(void Function(Audio) updates) =>
      super.copyWith((message) => updates(message as Audio)) as Audio;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Audio() / Audio.new instead')
  static Audio create() => Audio._();
  static $pb.GeneratedMessage $_createMessage() => Audio._();
  @$core.override
  Audio createEmptyInstance() => Audio._();
  @$core.pragma('dart2js:noInline')
  static Audio getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Audio>(Audio.$_createMessage);
  static Audio? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get uuid => $_getN(0);
  @$pb.TagNumber(1)
  set uuid($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUuid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUuid() => $_clearField(1);

  @$pb.TagNumber(2)
  Audio_Format get format => $_getN(1);
  @$pb.TagNumber(2)
  set format(Audio_Format value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormat() => $_clearField(2);
}

class TrackAudioFormat extends $pb.GeneratedMessage {
  factory TrackAudioFormat({
    Audio? originalAudio,
  }) {
    final result = TrackAudioFormat._();
    if (originalAudio != null) result.originalAudio = originalAudio;
    return result;
  }

  TrackAudioFormat._();

  factory TrackAudioFormat.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TrackAudioFormat()..mergeFromBuffer(data, registry);
  factory TrackAudioFormat.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TrackAudioFormat()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrackAudioFormat',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: TrackAudioFormat.$_createMessage)
    ..aOM<Audio>(1, _omitFieldNames ? '' : 'originalAudio',
        subBuilder: Audio.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrackAudioFormat clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrackAudioFormat copyWith(void Function(TrackAudioFormat) updates) =>
      super.copyWith((message) => updates(message as TrackAudioFormat))
          as TrackAudioFormat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TrackAudioFormat() / TrackAudioFormat.new instead')
  static TrackAudioFormat create() => TrackAudioFormat._();
  static $pb.GeneratedMessage $_createMessage() => TrackAudioFormat._();
  @$core.override
  TrackAudioFormat createEmptyInstance() => TrackAudioFormat._();
  @$core.pragma('dart2js:noInline')
  static TrackAudioFormat getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TrackAudioFormat>(
          TrackAudioFormat.$_createMessage);
  static TrackAudioFormat? _defaultInstance;

  @$pb.TagNumber(1)
  Audio get originalAudio => $_getN(0);
  @$pb.TagNumber(1)
  set originalAudio(Audio value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOriginalAudio() => $_has(0);
  @$pb.TagNumber(1)
  void clearOriginalAudio() => $_clearField(1);
  @$pb.TagNumber(1)
  Audio ensureOriginalAudio() => $_ensure(0);
}

class Video extends $pb.GeneratedMessage {
  factory Video({
    $core.List<$core.int>? gid,
  }) {
    final result = Video._();
    if (gid != null) result.gid = gid;
    return result;
  }

  Video._();

  factory Video.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Video()..mergeFromBuffer(data, registry);
  factory Video.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Video()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Video',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: Video.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'gid', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Video clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Video copyWith(void Function(Video) updates) =>
      super.copyWith((message) => updates(message as Video)) as Video;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Video() / Video.new instead')
  static Video create() => Video._();
  static $pb.GeneratedMessage $_createMessage() => Video._();
  @$core.override
  Video createEmptyInstance() => Video._();
  @$core.pragma('dart2js:noInline')
  static Video getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Video>(Video.$_createMessage);
  static Video? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get gid => $_getN(0);
  @$pb.TagNumber(1)
  set gid($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGid() => $_has(0);
  @$pb.TagNumber(1)
  void clearGid() => $_clearField(1);
}

class ContentRating extends $pb.GeneratedMessage {
  factory ContentRating({
    $core.String? country,
    $core.Iterable<$core.String>? tag,
  }) {
    final result = ContentRating._();
    if (country != null) result.country = country;
    if (tag != null) result.tag.addAll(tag);
    return result;
  }

  ContentRating._();

  factory ContentRating.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContentRating()..mergeFromBuffer(data, registry);
  factory ContentRating.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContentRating()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContentRating',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: ContentRating.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'country')
    ..pPS(2, _omitFieldNames ? '' : 'tag')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContentRating clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContentRating copyWith(void Function(ContentRating) updates) =>
      super.copyWith((message) => updates(message as ContentRating))
          as ContentRating;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ContentRating() / ContentRating.new instead')
  static ContentRating create() => ContentRating._();
  static $pb.GeneratedMessage $_createMessage() => ContentRating._();
  @$core.override
  ContentRating createEmptyInstance() => ContentRating._();
  @$core.pragma('dart2js:noInline')
  static ContentRating getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ContentRating>(
          ContentRating.$_createMessage);
  static ContentRating? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get country => $_getSZ(0);
  @$pb.TagNumber(1)
  set country($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCountry() => $_has(0);
  @$pb.TagNumber(1)
  void clearCountry() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get tag => $_getList(1);
}

class ArtistWithRole extends $pb.GeneratedMessage {
  factory ArtistWithRole({
    $core.List<$core.int>? artistGid,
    $core.String? artistName,
    ArtistWithRole_Role? role,
  }) {
    final result = ArtistWithRole._();
    if (artistGid != null) result.artistGid = artistGid;
    if (artistName != null) result.artistName = artistName;
    if (role != null) result.role = role;
    return result;
  }

  ArtistWithRole._();

  factory ArtistWithRole.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ArtistWithRole()..mergeFromBuffer(data, registry);
  factory ArtistWithRole.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ArtistWithRole()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArtistWithRole',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: ArtistWithRole.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'artistGid', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'artistName')
    ..aE<ArtistWithRole_Role>(3, _omitFieldNames ? '' : 'role',
        enumValues: ArtistWithRole_Role.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtistWithRole clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtistWithRole copyWith(void Function(ArtistWithRole) updates) =>
      super.copyWith((message) => updates(message as ArtistWithRole))
          as ArtistWithRole;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ArtistWithRole() / ArtistWithRole.new instead')
  static ArtistWithRole create() => ArtistWithRole._();
  static $pb.GeneratedMessage $_createMessage() => ArtistWithRole._();
  @$core.override
  ArtistWithRole createEmptyInstance() => ArtistWithRole._();
  @$core.pragma('dart2js:noInline')
  static ArtistWithRole getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ArtistWithRole>(
          ArtistWithRole.$_createMessage);
  static ArtistWithRole? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get artistGid => $_getN(0);
  @$pb.TagNumber(1)
  set artistGid($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasArtistGid() => $_has(0);
  @$pb.TagNumber(1)
  void clearArtistGid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get artistName => $_getSZ(1);
  @$pb.TagNumber(2)
  set artistName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasArtistName() => $_has(1);
  @$pb.TagNumber(2)
  void clearArtistName() => $_clearField(2);

  @$pb.TagNumber(3)
  ArtistWithRole_Role get role => $_getN(2);
  @$pb.TagNumber(3)
  set role(ArtistWithRole_Role value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRole() => $_has(2);
  @$pb.TagNumber(3)
  void clearRole() => $_clearField(3);
}

class ContentWindowing extends $pb.GeneratedMessage {
  factory ContentWindowing() => ContentWindowing._();

  ContentWindowing._();

  factory ContentWindowing.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContentWindowing()..mergeFromBuffer(data, registry);
  factory ContentWindowing.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContentWindowing()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContentWindowing',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: ContentWindowing.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContentWindowing clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContentWindowing copyWith(void Function(ContentWindowing) updates) =>
      super.copyWith((message) => updates(message as ContentWindowing))
          as ContentWindowing;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ContentWindowing() / ContentWindowing.new instead')
  static ContentWindowing create() => ContentWindowing._();
  static $pb.GeneratedMessage $_createMessage() => ContentWindowing._();
  @$core.override
  ContentWindowing createEmptyInstance() => ContentWindowing._();
  @$core.pragma('dart2js:noInline')
  static ContentWindowing getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ContentWindowing>(
          ContentWindowing.$_createMessage);
  static ContentWindowing? _defaultInstance;
}

class ContentGated extends $pb.GeneratedMessage {
  factory ContentGated() => ContentGated._();

  ContentGated._();

  factory ContentGated.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContentGated()..mergeFromBuffer(data, registry);
  factory ContentGated.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContentGated()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContentGated',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: ContentGated.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContentGated clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContentGated copyWith(void Function(ContentGated) updates) =>
      super.copyWith((message) => updates(message as ContentGated))
          as ContentGated;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ContentGated() / ContentGated.new instead')
  static ContentGated create() => ContentGated._();
  static $pb.GeneratedMessage $_createMessage() => ContentGated._();
  @$core.override
  ContentGated createEmptyInstance() => ContentGated._();
  @$core.pragma('dart2js:noInline')
  static ContentGated getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ContentGated>(
          ContentGated.$_createMessage);
  static ContentGated? _defaultInstance;
}

enum ContentAccessStatus_Status { contentWindowing, contentGated, notSet }

class ContentAccessStatus extends $pb.GeneratedMessage {
  factory ContentAccessStatus({
    ContentWindowing? contentWindowing,
    ContentGated? contentGated,
  }) {
    final result = ContentAccessStatus._();
    if (contentWindowing != null) result.contentWindowing = contentWindowing;
    if (contentGated != null) result.contentGated = contentGated;
    return result;
  }

  ContentAccessStatus._();

  factory ContentAccessStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContentAccessStatus()..mergeFromBuffer(data, registry);
  factory ContentAccessStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContentAccessStatus()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ContentAccessStatus_Status>
      _ContentAccessStatus_StatusByTag = {
    1: ContentAccessStatus_Status.contentWindowing,
    2: ContentAccessStatus_Status.contentGated,
    0: ContentAccessStatus_Status.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContentAccessStatus',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: ContentAccessStatus.$_createMessage)
    ..oo(0, [1, 2])
    ..aOM<ContentWindowing>(1, _omitFieldNames ? '' : 'contentWindowing',
        subBuilder: ContentWindowing.$_createMessage)
    ..aOM<ContentGated>(2, _omitFieldNames ? '' : 'contentGated',
        subBuilder: ContentGated.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContentAccessStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContentAccessStatus copyWith(void Function(ContentAccessStatus) updates) =>
      super.copyWith((message) => updates(message as ContentAccessStatus))
          as ContentAccessStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ContentAccessStatus() / ContentAccessStatus.new instead')
  static ContentAccessStatus create() => ContentAccessStatus._();
  static $pb.GeneratedMessage $_createMessage() => ContentAccessStatus._();
  @$core.override
  ContentAccessStatus createEmptyInstance() => ContentAccessStatus._();
  @$core.pragma('dart2js:noInline')
  static ContentAccessStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContentAccessStatus>(
          ContentAccessStatus.$_createMessage);
  static ContentAccessStatus? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ContentAccessStatus_Status whichStatus() =>
      _ContentAccessStatus_StatusByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ContentWindowing get contentWindowing => $_getN(0);
  @$pb.TagNumber(1)
  set contentWindowing(ContentWindowing value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasContentWindowing() => $_has(0);
  @$pb.TagNumber(1)
  void clearContentWindowing() => $_clearField(1);
  @$pb.TagNumber(1)
  ContentWindowing ensureContentWindowing() => $_ensure(0);

  @$pb.TagNumber(2)
  ContentGated get contentGated => $_getN(1);
  @$pb.TagNumber(2)
  set contentGated(ContentGated value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasContentGated() => $_has(1);
  @$pb.TagNumber(2)
  void clearContentGated() => $_clearField(2);
  @$pb.TagNumber(2)
  ContentGated ensureContentGated() => $_ensure(1);
}

class Availability extends $pb.GeneratedMessage {
  factory Availability({
    $core.Iterable<$core.String>? catalogueStr,
    Date? start,
  }) {
    final result = Availability._();
    if (catalogueStr != null) result.catalogueStr.addAll(catalogueStr);
    if (start != null) result.start = start;
    return result;
  }

  Availability._();

  factory Availability.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Availability()..mergeFromBuffer(data, registry);
  factory Availability.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Availability()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Availability',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: Availability.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'catalogueStr')
    ..aOM<Date>(2, _omitFieldNames ? '' : 'start',
        subBuilder: Date.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Availability clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Availability copyWith(void Function(Availability) updates) =>
      super.copyWith((message) => updates(message as Availability))
          as Availability;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Availability() / Availability.new instead')
  static Availability create() => Availability._();
  static $pb.GeneratedMessage $_createMessage() => Availability._();
  @$core.override
  Availability createEmptyInstance() => Availability._();
  @$core.pragma('dart2js:noInline')
  static Availability getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Availability>(
          Availability.$_createMessage);
  static Availability? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get catalogueStr => $_getList(0);

  @$pb.TagNumber(2)
  Date get start => $_getN(1);
  @$pb.TagNumber(2)
  set start(Date value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStart() => $_has(1);
  @$pb.TagNumber(2)
  void clearStart() => $_clearField(2);
  @$pb.TagNumber(2)
  Date ensureStart() => $_ensure(1);
}

class SalePeriod extends $pb.GeneratedMessage {
  factory SalePeriod({
    $core.Iterable<Restriction>? restriction,
    Date? start,
    Date? end,
  }) {
    final result = SalePeriod._();
    if (restriction != null) result.restriction.addAll(restriction);
    if (start != null) result.start = start;
    if (end != null) result.end = end;
    return result;
  }

  SalePeriod._();

  factory SalePeriod.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SalePeriod()..mergeFromBuffer(data, registry);
  factory SalePeriod.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SalePeriod()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SalePeriod',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: SalePeriod.$_createMessage)
    ..pPM<Restriction>(1, _omitFieldNames ? '' : 'restriction',
        subBuilder: Restriction.$_createMessage)
    ..aOM<Date>(2, _omitFieldNames ? '' : 'start',
        subBuilder: Date.$_createMessage)
    ..aOM<Date>(3, _omitFieldNames ? '' : 'end',
        subBuilder: Date.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SalePeriod clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SalePeriod copyWith(void Function(SalePeriod) updates) =>
      super.copyWith((message) => updates(message as SalePeriod)) as SalePeriod;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SalePeriod() / SalePeriod.new instead')
  static SalePeriod create() => SalePeriod._();
  static $pb.GeneratedMessage $_createMessage() => SalePeriod._();
  @$core.override
  SalePeriod createEmptyInstance() => SalePeriod._();
  @$core.pragma('dart2js:noInline')
  static SalePeriod getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SalePeriod>(SalePeriod.$_createMessage);
  static SalePeriod? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Restriction> get restriction => $_getList(0);

  @$pb.TagNumber(2)
  Date get start => $_getN(1);
  @$pb.TagNumber(2)
  set start(Date value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStart() => $_has(1);
  @$pb.TagNumber(2)
  void clearStart() => $_clearField(2);
  @$pb.TagNumber(2)
  Date ensureStart() => $_ensure(1);

  @$pb.TagNumber(3)
  Date get end => $_getN(2);
  @$pb.TagNumber(3)
  set end(Date value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasEnd() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnd() => $_clearField(3);
  @$pb.TagNumber(3)
  Date ensureEnd() => $_ensure(2);
}

class Copyright extends $pb.GeneratedMessage {
  factory Copyright({
    Copyright_Type? type,
    $core.String? text,
  }) {
    final result = Copyright._();
    if (type != null) result.type = type;
    if (text != null) result.text = text;
    return result;
  }

  Copyright._();

  factory Copyright.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Copyright()..mergeFromBuffer(data, registry);
  factory Copyright.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Copyright()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Copyright',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: Copyright.$_createMessage)
    ..aE<Copyright_Type>(1, _omitFieldNames ? '' : 'type',
        enumValues: Copyright_Type.values)
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Copyright clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Copyright copyWith(void Function(Copyright) updates) =>
      super.copyWith((message) => updates(message as Copyright)) as Copyright;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Copyright() / Copyright.new instead')
  static Copyright create() => Copyright._();
  static $pb.GeneratedMessage $_createMessage() => Copyright._();
  @$core.override
  Copyright createEmptyInstance() => Copyright._();
  @$core.pragma('dart2js:noInline')
  static Copyright getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Copyright>(Copyright.$_createMessage);
  static Copyright? _defaultInstance;

  @$pb.TagNumber(1)
  Copyright_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(Copyright_Type value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);
}

class Disc extends $pb.GeneratedMessage {
  factory Disc({
    $core.int? number,
    $core.String? name,
    $core.Iterable<Track>? track,
  }) {
    final result = Disc._();
    if (number != null) result.number = number;
    if (name != null) result.name = name;
    if (track != null) result.track.addAll(track);
    return result;
  }

  Disc._();

  factory Disc.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Disc()..mergeFromBuffer(data, registry);
  factory Disc.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Disc()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Disc',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: Disc.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'number', fieldType: $pb.PbFieldType.OS3)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..pPM<Track>(3, _omitFieldNames ? '' : 'track',
        subBuilder: Track.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Disc clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Disc copyWith(void Function(Disc) updates) =>
      super.copyWith((message) => updates(message as Disc)) as Disc;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Disc() / Disc.new instead')
  static Disc create() => Disc._();
  static $pb.GeneratedMessage $_createMessage() => Disc._();
  @$core.override
  Disc createEmptyInstance() => Disc._();
  @$core.pragma('dart2js:noInline')
  static Disc getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Disc>(Disc.$_createMessage);
  static Disc? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get number => $_getIZ(0);
  @$pb.TagNumber(1)
  set number($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNumber() => $_has(0);
  @$pb.TagNumber(1)
  void clearNumber() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<Track> get track => $_getList(2);
}

class ActivityPeriod extends $pb.GeneratedMessage {
  factory ActivityPeriod({
    $core.int? startYear,
    $core.int? endYear,
    $core.int? decade,
  }) {
    final result = ActivityPeriod._();
    if (startYear != null) result.startYear = startYear;
    if (endYear != null) result.endYear = endYear;
    if (decade != null) result.decade = decade;
    return result;
  }

  ActivityPeriod._();

  factory ActivityPeriod.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ActivityPeriod()..mergeFromBuffer(data, registry);
  factory ActivityPeriod.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ActivityPeriod()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActivityPeriod',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: ActivityPeriod.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'startYear', fieldType: $pb.PbFieldType.OS3)
    ..aI(2, _omitFieldNames ? '' : 'endYear', fieldType: $pb.PbFieldType.OS3)
    ..aI(3, _omitFieldNames ? '' : 'decade', fieldType: $pb.PbFieldType.OS3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActivityPeriod clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActivityPeriod copyWith(void Function(ActivityPeriod) updates) =>
      super.copyWith((message) => updates(message as ActivityPeriod))
          as ActivityPeriod;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ActivityPeriod() / ActivityPeriod.new instead')
  static ActivityPeriod create() => ActivityPeriod._();
  static $pb.GeneratedMessage $_createMessage() => ActivityPeriod._();
  @$core.override
  ActivityPeriod createEmptyInstance() => ActivityPeriod._();
  @$core.pragma('dart2js:noInline')
  static ActivityPeriod getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ActivityPeriod>(
          ActivityPeriod.$_createMessage);
  static ActivityPeriod? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get startYear => $_getIZ(0);
  @$pb.TagNumber(1)
  set startYear($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStartYear() => $_has(0);
  @$pb.TagNumber(1)
  void clearStartYear() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get endYear => $_getIZ(1);
  @$pb.TagNumber(2)
  set endYear($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEndYear() => $_has(1);
  @$pb.TagNumber(2)
  void clearEndYear() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get decade => $_getIZ(2);
  @$pb.TagNumber(3)
  set decade($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDecade() => $_has(2);
  @$pb.TagNumber(3)
  void clearDecade() => $_clearField(3);
}

class Biography extends $pb.GeneratedMessage {
  factory Biography({
    $core.String? text,
    $core.Iterable<Image>? portrait,
    $core.Iterable<ImageGroup>? portraitGroup,
  }) {
    final result = Biography._();
    if (text != null) result.text = text;
    if (portrait != null) result.portrait.addAll(portrait);
    if (portraitGroup != null) result.portraitGroup.addAll(portraitGroup);
    return result;
  }

  Biography._();

  factory Biography.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Biography()..mergeFromBuffer(data, registry);
  factory Biography.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Biography()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Biography',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: Biography.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..pPM<Image>(2, _omitFieldNames ? '' : 'portrait',
        subBuilder: Image.$_createMessage)
    ..pPM<ImageGroup>(3, _omitFieldNames ? '' : 'portraitGroup',
        subBuilder: ImageGroup.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Biography clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Biography copyWith(void Function(Biography) updates) =>
      super.copyWith((message) => updates(message as Biography)) as Biography;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Biography() / Biography.new instead')
  static Biography create() => Biography._();
  static $pb.GeneratedMessage $_createMessage() => Biography._();
  @$core.override
  Biography createEmptyInstance() => Biography._();
  @$core.pragma('dart2js:noInline')
  static Biography getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Biography>(Biography.$_createMessage);
  static Biography? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<Image> get portrait => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<ImageGroup> get portraitGroup => $_getList(2);
}

class TopTracks extends $pb.GeneratedMessage {
  factory TopTracks({
    $core.String? country,
    $core.Iterable<Track>? track,
  }) {
    final result = TopTracks._();
    if (country != null) result.country = country;
    if (track != null) result.track.addAll(track);
    return result;
  }

  TopTracks._();

  factory TopTracks.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TopTracks()..mergeFromBuffer(data, registry);
  factory TopTracks.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TopTracks()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TopTracks',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: TopTracks.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'country')
    ..pPM<Track>(2, _omitFieldNames ? '' : 'track',
        subBuilder: Track.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TopTracks clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TopTracks copyWith(void Function(TopTracks) updates) =>
      super.copyWith((message) => updates(message as TopTracks)) as TopTracks;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TopTracks() / TopTracks.new instead')
  static TopTracks create() => TopTracks._();
  static $pb.GeneratedMessage $_createMessage() => TopTracks._();
  @$core.override
  TopTracks createEmptyInstance() => TopTracks._();
  @$core.pragma('dart2js:noInline')
  static TopTracks getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TopTracks>(TopTracks.$_createMessage);
  static TopTracks? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get country => $_getSZ(0);
  @$pb.TagNumber(1)
  set country($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCountry() => $_has(0);
  @$pb.TagNumber(1)
  void clearCountry() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<Track> get track => $_getList(1);
}

class AlbumGroup extends $pb.GeneratedMessage {
  factory AlbumGroup({
    $core.Iterable<Album>? album,
  }) {
    final result = AlbumGroup._();
    if (album != null) result.album.addAll(album);
    return result;
  }

  AlbumGroup._();

  factory AlbumGroup.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AlbumGroup()..mergeFromBuffer(data, registry);
  factory AlbumGroup.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AlbumGroup()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AlbumGroup',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'spotify.metadata'),
      createEmptyInstance: AlbumGroup.$_createMessage)
    ..pPM<Album>(1, _omitFieldNames ? '' : 'album',
        subBuilder: Album.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AlbumGroup clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AlbumGroup copyWith(void Function(AlbumGroup) updates) =>
      super.copyWith((message) => updates(message as AlbumGroup)) as AlbumGroup;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AlbumGroup() / AlbumGroup.new instead')
  static AlbumGroup create() => AlbumGroup._();
  static $pb.GeneratedMessage $_createMessage() => AlbumGroup._();
  @$core.override
  AlbumGroup createEmptyInstance() => AlbumGroup._();
  @$core.pragma('dart2js:noInline')
  static AlbumGroup getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AlbumGroup>(AlbumGroup.$_createMessage);
  static AlbumGroup? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Album> get album => $_getList(0);
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

class Artist extends $pb.GeneratedMessage {
  factory Artist({
    $core.List<$core.int>? gid,
    $core.String? name,
    $core.int? popularity,
    $core.Iterable<TopTracks>? topTrack,
    $core.Iterable<AlbumGroup>? albumGroup,
    $core.Iterable<AlbumGroup>? singleGroup,
    $core.Iterable<AlbumGroup>? compilationGroup,
    $core.Iterable<AlbumGroup>? appearsOnGroup,
    $core.Iterable<ExternalId>? externalId,
    $core.Iterable<Image>? portrait,
    $core.Iterable<Biography>? biography,
    $core.Iterable<ActivityPeriod>? activityPeriod,
    $core.Iterable<Restriction>? restriction,
    $core.Iterable<Artist>? related,
    $core.bool? isPortraitAlbumCover,
    ImageGroup? portraitGroup,
    $core.Iterable<SalePeriod>? salePeriod,
    $core.Iterable<Availability>? availability,
  }) {
    final result = Artist._();
    if (gid != null) result.gid = gid;
    if (name != null) result.name = name;
    if (popularity != null) result.popularity = popularity;
    if (topTrack != null) result.topTrack.addAll(topTrack);
    if (albumGroup != null) result.albumGroup.addAll(albumGroup);
    if (singleGroup != null) result.singleGroup.addAll(singleGroup);
    if (compilationGroup != null)
      result.compilationGroup.addAll(compilationGroup);
    if (appearsOnGroup != null) result.appearsOnGroup.addAll(appearsOnGroup);
    if (externalId != null) result.externalId.addAll(externalId);
    if (portrait != null) result.portrait.addAll(portrait);
    if (biography != null) result.biography.addAll(biography);
    if (activityPeriod != null) result.activityPeriod.addAll(activityPeriod);
    if (restriction != null) result.restriction.addAll(restriction);
    if (related != null) result.related.addAll(related);
    if (isPortraitAlbumCover != null)
      result.isPortraitAlbumCover = isPortraitAlbumCover;
    if (portraitGroup != null) result.portraitGroup = portraitGroup;
    if (salePeriod != null) result.salePeriod.addAll(salePeriod);
    if (availability != null) result.availability.addAll(availability);
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
    ..pPM<TopTracks>(4, _omitFieldNames ? '' : 'topTrack',
        subBuilder: TopTracks.$_createMessage)
    ..pPM<AlbumGroup>(5, _omitFieldNames ? '' : 'albumGroup',
        subBuilder: AlbumGroup.$_createMessage)
    ..pPM<AlbumGroup>(6, _omitFieldNames ? '' : 'singleGroup',
        subBuilder: AlbumGroup.$_createMessage)
    ..pPM<AlbumGroup>(7, _omitFieldNames ? '' : 'compilationGroup',
        subBuilder: AlbumGroup.$_createMessage)
    ..pPM<AlbumGroup>(8, _omitFieldNames ? '' : 'appearsOnGroup',
        subBuilder: AlbumGroup.$_createMessage)
    ..pPM<ExternalId>(10, _omitFieldNames ? '' : 'externalId',
        subBuilder: ExternalId.$_createMessage)
    ..pPM<Image>(11, _omitFieldNames ? '' : 'portrait',
        subBuilder: Image.$_createMessage)
    ..pPM<Biography>(12, _omitFieldNames ? '' : 'biography',
        subBuilder: Biography.$_createMessage)
    ..pPM<ActivityPeriod>(13, _omitFieldNames ? '' : 'activityPeriod',
        subBuilder: ActivityPeriod.$_createMessage)
    ..pPM<Restriction>(14, _omitFieldNames ? '' : 'restriction',
        subBuilder: Restriction.$_createMessage)
    ..pPM<Artist>(15, _omitFieldNames ? '' : 'related',
        subBuilder: Artist.$_createMessage)
    ..aOB(16, _omitFieldNames ? '' : 'isPortraitAlbumCover')
    ..aOM<ImageGroup>(17, _omitFieldNames ? '' : 'portraitGroup',
        subBuilder: ImageGroup.$_createMessage)
    ..pPM<SalePeriod>(18, _omitFieldNames ? '' : 'salePeriod',
        subBuilder: SalePeriod.$_createMessage)
    ..pPM<Availability>(20, _omitFieldNames ? '' : 'availability',
        subBuilder: Availability.$_createMessage)
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

  @$pb.TagNumber(4)
  $pb.PbList<TopTracks> get topTrack => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<AlbumGroup> get albumGroup => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<AlbumGroup> get singleGroup => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<AlbumGroup> get compilationGroup => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<AlbumGroup> get appearsOnGroup => $_getList(7);

  @$pb.TagNumber(10)
  $pb.PbList<ExternalId> get externalId => $_getList(8);

  @$pb.TagNumber(11)
  $pb.PbList<Image> get portrait => $_getList(9);

  @$pb.TagNumber(12)
  $pb.PbList<Biography> get biography => $_getList(10);

  @$pb.TagNumber(13)
  $pb.PbList<ActivityPeriod> get activityPeriod => $_getList(11);

  @$pb.TagNumber(14)
  $pb.PbList<Restriction> get restriction => $_getList(12);

  @$pb.TagNumber(15)
  $pb.PbList<Artist> get related => $_getList(13);

  @$pb.TagNumber(16)
  $core.bool get isPortraitAlbumCover => $_getBF(14);
  @$pb.TagNumber(16)
  set isPortraitAlbumCover($core.bool value) => $_setBool(14, value);
  @$pb.TagNumber(16)
  $core.bool hasIsPortraitAlbumCover() => $_has(14);
  @$pb.TagNumber(16)
  void clearIsPortraitAlbumCover() => $_clearField(16);

  @$pb.TagNumber(17)
  ImageGroup get portraitGroup => $_getN(15);
  @$pb.TagNumber(17)
  set portraitGroup(ImageGroup value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasPortraitGroup() => $_has(15);
  @$pb.TagNumber(17)
  void clearPortraitGroup() => $_clearField(17);
  @$pb.TagNumber(17)
  ImageGroup ensurePortraitGroup() => $_ensure(15);

  @$pb.TagNumber(18)
  $pb.PbList<SalePeriod> get salePeriod => $_getList(16);

  @$pb.TagNumber(20)
  $pb.PbList<Availability> get availability => $_getList(17);
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
    $core.Iterable<Image>? cover,
    $core.Iterable<ExternalId>? externalId,
    $core.Iterable<Disc>? disc,
    $core.Iterable<$core.String>? review,
    $core.Iterable<Copyright>? copyright,
    $core.Iterable<Restriction>? restriction,
    $core.Iterable<Album>? related,
    $core.Iterable<SalePeriod>? salePeriod,
    ImageGroup? coverGroup,
    $core.String? originalTitle,
    $core.String? versionTitle,
    $core.String? typeStr,
    $core.Iterable<Availability>? availability,
    $fixnum.Int64? prereleaseEndDate,
    ContentAccessStatus? contentAccessStatus,
  }) {
    final result = Album._();
    if (gid != null) result.gid = gid;
    if (name != null) result.name = name;
    if (artist != null) result.artist.addAll(artist);
    if (type != null) result.type = type;
    if (label != null) result.label = label;
    if (date != null) result.date = date;
    if (popularity != null) result.popularity = popularity;
    if (cover != null) result.cover.addAll(cover);
    if (externalId != null) result.externalId.addAll(externalId);
    if (disc != null) result.disc.addAll(disc);
    if (review != null) result.review.addAll(review);
    if (copyright != null) result.copyright.addAll(copyright);
    if (restriction != null) result.restriction.addAll(restriction);
    if (related != null) result.related.addAll(related);
    if (salePeriod != null) result.salePeriod.addAll(salePeriod);
    if (coverGroup != null) result.coverGroup = coverGroup;
    if (originalTitle != null) result.originalTitle = originalTitle;
    if (versionTitle != null) result.versionTitle = versionTitle;
    if (typeStr != null) result.typeStr = typeStr;
    if (availability != null) result.availability.addAll(availability);
    if (prereleaseEndDate != null) result.prereleaseEndDate = prereleaseEndDate;
    if (contentAccessStatus != null)
      result.contentAccessStatus = contentAccessStatus;
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
    ..pPM<Image>(9, _omitFieldNames ? '' : 'cover',
        subBuilder: Image.$_createMessage)
    ..pPM<ExternalId>(10, _omitFieldNames ? '' : 'externalId',
        subBuilder: ExternalId.$_createMessage)
    ..pPM<Disc>(11, _omitFieldNames ? '' : 'disc',
        subBuilder: Disc.$_createMessage)
    ..pPS(12, _omitFieldNames ? '' : 'review')
    ..pPM<Copyright>(13, _omitFieldNames ? '' : 'copyright',
        subBuilder: Copyright.$_createMessage)
    ..pPM<Restriction>(14, _omitFieldNames ? '' : 'restriction',
        subBuilder: Restriction.$_createMessage)
    ..pPM<Album>(15, _omitFieldNames ? '' : 'related',
        subBuilder: Album.$_createMessage)
    ..pPM<SalePeriod>(16, _omitFieldNames ? '' : 'salePeriod',
        subBuilder: SalePeriod.$_createMessage)
    ..aOM<ImageGroup>(17, _omitFieldNames ? '' : 'coverGroup',
        subBuilder: ImageGroup.$_createMessage)
    ..aOS(18, _omitFieldNames ? '' : 'originalTitle')
    ..aOS(19, _omitFieldNames ? '' : 'versionTitle')
    ..aOS(20, _omitFieldNames ? '' : 'typeStr')
    ..pPM<Availability>(23, _omitFieldNames ? '' : 'availability',
        subBuilder: Availability.$_createMessage)
    ..aInt64(42, _omitFieldNames ? '' : 'prereleaseEndDate')
    ..aOM<ContentAccessStatus>(44, _omitFieldNames ? '' : 'contentAccessStatus',
        subBuilder: ContentAccessStatus.$_createMessage)
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

  @$pb.TagNumber(9)
  $pb.PbList<Image> get cover => $_getList(7);

  @$pb.TagNumber(10)
  $pb.PbList<ExternalId> get externalId => $_getList(8);

  @$pb.TagNumber(11)
  $pb.PbList<Disc> get disc => $_getList(9);

  @$pb.TagNumber(12)
  $pb.PbList<$core.String> get review => $_getList(10);

  @$pb.TagNumber(13)
  $pb.PbList<Copyright> get copyright => $_getList(11);

  @$pb.TagNumber(14)
  $pb.PbList<Restriction> get restriction => $_getList(12);

  @$pb.TagNumber(15)
  $pb.PbList<Album> get related => $_getList(13);

  @$pb.TagNumber(16)
  $pb.PbList<SalePeriod> get salePeriod => $_getList(14);

  @$pb.TagNumber(17)
  ImageGroup get coverGroup => $_getN(15);
  @$pb.TagNumber(17)
  set coverGroup(ImageGroup value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasCoverGroup() => $_has(15);
  @$pb.TagNumber(17)
  void clearCoverGroup() => $_clearField(17);
  @$pb.TagNumber(17)
  ImageGroup ensureCoverGroup() => $_ensure(15);

  @$pb.TagNumber(18)
  $core.String get originalTitle => $_getSZ(16);
  @$pb.TagNumber(18)
  set originalTitle($core.String value) => $_setString(16, value);
  @$pb.TagNumber(18)
  $core.bool hasOriginalTitle() => $_has(16);
  @$pb.TagNumber(18)
  void clearOriginalTitle() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.String get versionTitle => $_getSZ(17);
  @$pb.TagNumber(19)
  set versionTitle($core.String value) => $_setString(17, value);
  @$pb.TagNumber(19)
  $core.bool hasVersionTitle() => $_has(17);
  @$pb.TagNumber(19)
  void clearVersionTitle() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.String get typeStr => $_getSZ(18);
  @$pb.TagNumber(20)
  set typeStr($core.String value) => $_setString(18, value);
  @$pb.TagNumber(20)
  $core.bool hasTypeStr() => $_has(18);
  @$pb.TagNumber(20)
  void clearTypeStr() => $_clearField(20);

  @$pb.TagNumber(23)
  $pb.PbList<Availability> get availability => $_getList(19);

  @$pb.TagNumber(42)
  $fixnum.Int64 get prereleaseEndDate => $_getI64(20);
  @$pb.TagNumber(42)
  set prereleaseEndDate($fixnum.Int64 value) => $_setInt64(20, value);
  @$pb.TagNumber(42)
  $core.bool hasPrereleaseEndDate() => $_has(20);
  @$pb.TagNumber(42)
  void clearPrereleaseEndDate() => $_clearField(42);

  @$pb.TagNumber(44)
  ContentAccessStatus get contentAccessStatus => $_getN(21);
  @$pb.TagNumber(44)
  set contentAccessStatus(ContentAccessStatus value) => $_setField(44, value);
  @$pb.TagNumber(44)
  $core.bool hasContentAccessStatus() => $_has(21);
  @$pb.TagNumber(44)
  void clearContentAccessStatus() => $_clearField(44);
  @$pb.TagNumber(44)
  ContentAccessStatus ensureContentAccessStatus() => $_ensure(21);
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
    $core.Iterable<ExternalId>? externalId,
    $core.Iterable<Restriction>? restriction,
    $core.Iterable<AudioFile>? file,
    $core.Iterable<Track>? alternative,
    $core.Iterable<SalePeriod>? salePeriod,
    $core.Iterable<AudioFile>? preview,
    $core.Iterable<$core.String>? tags,
    $fixnum.Int64? earliestLiveTimestamp,
    $core.bool? hasLyrics,
    $core.Iterable<Availability>? availability,
    Licensor? licensor,
    $core.Iterable<$core.String>? languageOfPerformance,
    Audio? originalAudio,
    $core.Iterable<ContentRating>? contentRating,
    $core.String? originalTitle,
    $core.String? versionTitle,
    $core.Iterable<ArtistWithRole>? artistWithRole,
    $core.String? canonicalUri,
    $core.Iterable<Video>? originalVideo,
    $core.Iterable<TrackAudioFormat>? audioFormats,
    ContentAccessStatus? contentAccessStatus,
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
    if (externalId != null) result.externalId.addAll(externalId);
    if (restriction != null) result.restriction.addAll(restriction);
    if (file != null) result.file.addAll(file);
    if (alternative != null) result.alternative.addAll(alternative);
    if (salePeriod != null) result.salePeriod.addAll(salePeriod);
    if (preview != null) result.preview.addAll(preview);
    if (tags != null) result.tags.addAll(tags);
    if (earliestLiveTimestamp != null)
      result.earliestLiveTimestamp = earliestLiveTimestamp;
    if (hasLyrics != null) result.hasLyrics = hasLyrics;
    if (availability != null) result.availability.addAll(availability);
    if (licensor != null) result.licensor = licensor;
    if (languageOfPerformance != null)
      result.languageOfPerformance.addAll(languageOfPerformance);
    if (originalAudio != null) result.originalAudio = originalAudio;
    if (contentRating != null) result.contentRating.addAll(contentRating);
    if (originalTitle != null) result.originalTitle = originalTitle;
    if (versionTitle != null) result.versionTitle = versionTitle;
    if (artistWithRole != null) result.artistWithRole.addAll(artistWithRole);
    if (canonicalUri != null) result.canonicalUri = canonicalUri;
    if (originalVideo != null) result.originalVideo.addAll(originalVideo);
    if (audioFormats != null) result.audioFormats.addAll(audioFormats);
    if (contentAccessStatus != null)
      result.contentAccessStatus = contentAccessStatus;
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
    ..pPM<ExternalId>(10, _omitFieldNames ? '' : 'externalId',
        subBuilder: ExternalId.$_createMessage)
    ..pPM<Restriction>(11, _omitFieldNames ? '' : 'restriction',
        subBuilder: Restriction.$_createMessage)
    ..pPM<AudioFile>(12, _omitFieldNames ? '' : 'file',
        subBuilder: AudioFile.$_createMessage)
    ..pPM<Track>(13, _omitFieldNames ? '' : 'alternative',
        subBuilder: Track.$_createMessage)
    ..pPM<SalePeriod>(14, _omitFieldNames ? '' : 'salePeriod',
        subBuilder: SalePeriod.$_createMessage)
    ..pPM<AudioFile>(15, _omitFieldNames ? '' : 'preview',
        subBuilder: AudioFile.$_createMessage)
    ..pPS(16, _omitFieldNames ? '' : 'tags')
    ..aInt64(17, _omitFieldNames ? '' : 'earliestLiveTimestamp')
    ..aOB(18, _omitFieldNames ? '' : 'hasLyrics')
    ..pPM<Availability>(19, _omitFieldNames ? '' : 'availability',
        subBuilder: Availability.$_createMessage)
    ..aOM<Licensor>(21, _omitFieldNames ? '' : 'licensor',
        subBuilder: Licensor.$_createMessage)
    ..pPS(22, _omitFieldNames ? '' : 'languageOfPerformance')
    ..aOM<Audio>(24, _omitFieldNames ? '' : 'originalAudio',
        subBuilder: Audio.$_createMessage)
    ..pPM<ContentRating>(25, _omitFieldNames ? '' : 'contentRating',
        subBuilder: ContentRating.$_createMessage)
    ..aOS(27, _omitFieldNames ? '' : 'originalTitle')
    ..aOS(28, _omitFieldNames ? '' : 'versionTitle')
    ..pPM<ArtistWithRole>(32, _omitFieldNames ? '' : 'artistWithRole',
        subBuilder: ArtistWithRole.$_createMessage)
    ..aOS(36, _omitFieldNames ? '' : 'canonicalUri')
    ..pPM<Video>(38, _omitFieldNames ? '' : 'originalVideo',
        subBuilder: Video.$_createMessage)
    ..pPM<TrackAudioFormat>(41, _omitFieldNames ? '' : 'audioFormats',
        subBuilder: TrackAudioFormat.$_createMessage)
    ..aOM<ContentAccessStatus>(51, _omitFieldNames ? '' : 'contentAccessStatus',
        subBuilder: ContentAccessStatus.$_createMessage)
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

  @$pb.TagNumber(10)
  $pb.PbList<ExternalId> get externalId => $_getList(9);

  @$pb.TagNumber(11)
  $pb.PbList<Restriction> get restriction => $_getList(10);

  @$pb.TagNumber(12)
  $pb.PbList<AudioFile> get file => $_getList(11);

  @$pb.TagNumber(13)
  $pb.PbList<Track> get alternative => $_getList(12);

  @$pb.TagNumber(14)
  $pb.PbList<SalePeriod> get salePeriod => $_getList(13);

  @$pb.TagNumber(15)
  $pb.PbList<AudioFile> get preview => $_getList(14);

  @$pb.TagNumber(16)
  $pb.PbList<$core.String> get tags => $_getList(15);

  @$pb.TagNumber(17)
  $fixnum.Int64 get earliestLiveTimestamp => $_getI64(16);
  @$pb.TagNumber(17)
  set earliestLiveTimestamp($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(17)
  $core.bool hasEarliestLiveTimestamp() => $_has(16);
  @$pb.TagNumber(17)
  void clearEarliestLiveTimestamp() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.bool get hasLyrics => $_getBF(17);
  @$pb.TagNumber(18)
  set hasLyrics($core.bool value) => $_setBool(17, value);
  @$pb.TagNumber(18)
  $core.bool hasHasLyrics() => $_has(17);
  @$pb.TagNumber(18)
  void clearHasLyrics() => $_clearField(18);

  @$pb.TagNumber(19)
  $pb.PbList<Availability> get availability => $_getList(18);

  @$pb.TagNumber(21)
  Licensor get licensor => $_getN(19);
  @$pb.TagNumber(21)
  set licensor(Licensor value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasLicensor() => $_has(19);
  @$pb.TagNumber(21)
  void clearLicensor() => $_clearField(21);
  @$pb.TagNumber(21)
  Licensor ensureLicensor() => $_ensure(19);

  @$pb.TagNumber(22)
  $pb.PbList<$core.String> get languageOfPerformance => $_getList(20);

  @$pb.TagNumber(24)
  Audio get originalAudio => $_getN(21);
  @$pb.TagNumber(24)
  set originalAudio(Audio value) => $_setField(24, value);
  @$pb.TagNumber(24)
  $core.bool hasOriginalAudio() => $_has(21);
  @$pb.TagNumber(24)
  void clearOriginalAudio() => $_clearField(24);
  @$pb.TagNumber(24)
  Audio ensureOriginalAudio() => $_ensure(21);

  @$pb.TagNumber(25)
  $pb.PbList<ContentRating> get contentRating => $_getList(22);

  @$pb.TagNumber(27)
  $core.String get originalTitle => $_getSZ(23);
  @$pb.TagNumber(27)
  set originalTitle($core.String value) => $_setString(23, value);
  @$pb.TagNumber(27)
  $core.bool hasOriginalTitle() => $_has(23);
  @$pb.TagNumber(27)
  void clearOriginalTitle() => $_clearField(27);

  @$pb.TagNumber(28)
  $core.String get versionTitle => $_getSZ(24);
  @$pb.TagNumber(28)
  set versionTitle($core.String value) => $_setString(24, value);
  @$pb.TagNumber(28)
  $core.bool hasVersionTitle() => $_has(24);
  @$pb.TagNumber(28)
  void clearVersionTitle() => $_clearField(28);

  @$pb.TagNumber(32)
  $pb.PbList<ArtistWithRole> get artistWithRole => $_getList(25);

  @$pb.TagNumber(36)
  $core.String get canonicalUri => $_getSZ(26);
  @$pb.TagNumber(36)
  set canonicalUri($core.String value) => $_setString(26, value);
  @$pb.TagNumber(36)
  $core.bool hasCanonicalUri() => $_has(26);
  @$pb.TagNumber(36)
  void clearCanonicalUri() => $_clearField(36);

  @$pb.TagNumber(38)
  $pb.PbList<Video> get originalVideo => $_getList(27);

  @$pb.TagNumber(41)
  $pb.PbList<TrackAudioFormat> get audioFormats => $_getList(28);

  @$pb.TagNumber(51)
  ContentAccessStatus get contentAccessStatus => $_getN(29);
  @$pb.TagNumber(51)
  set contentAccessStatus(ContentAccessStatus value) => $_setField(51, value);
  @$pb.TagNumber(51)
  $core.bool hasContentAccessStatus() => $_has(29);
  @$pb.TagNumber(51)
  void clearContentAccessStatus() => $_clearField(51);
  @$pb.TagNumber(51)
  ContentAccessStatus ensureContentAccessStatus() => $_ensure(29);
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

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
