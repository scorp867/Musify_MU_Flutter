// This is a generated file - do not edit.
//
// Generated from spotify/contentagnostic/v2/playback_trait.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Duration extends $pb.GeneratedMessage {
  factory Duration({
    $fixnum.Int64? seconds,
    $core.int? nanos,
  }) {
    final result = Duration._();
    if (seconds != null) result.seconds = seconds;
    if (nanos != null) result.nanos = nanos;
    return result;
  }

  Duration._();

  factory Duration.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Duration()..mergeFromBuffer(data, registry);
  factory Duration.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Duration()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Duration',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: Duration.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'seconds')
    ..aI(2, _omitFieldNames ? '' : 'nanos')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Duration clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Duration copyWith(void Function(Duration) updates) =>
      super.copyWith((message) => updates(message as Duration)) as Duration;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Duration() / Duration.new instead')
  static Duration create() => Duration._();
  static $pb.GeneratedMessage $_createMessage() => Duration._();
  @$core.override
  Duration createEmptyInstance() => Duration._();
  @$core.pragma('dart2js:noInline')
  static Duration getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Duration>(Duration.$_createMessage);
  static Duration? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get seconds => $_getI64(0);
  @$pb.TagNumber(1)
  set seconds($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSeconds() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeconds() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get nanos => $_getIZ(1);
  @$pb.TagNumber(2)
  set nanos($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNanos() => $_has(1);
  @$pb.TagNumber(2)
  void clearNanos() => $_clearField(2);
}

class NormalizationParams extends $pb.GeneratedMessage {
  factory NormalizationParams({
    $core.double? loudnessDb,
    $core.double? truePeakDb,
  }) {
    final result = NormalizationParams._();
    if (loudnessDb != null) result.loudnessDb = loudnessDb;
    if (truePeakDb != null) result.truePeakDb = truePeakDb;
    return result;
  }

  NormalizationParams._();

  factory NormalizationParams.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NormalizationParams()..mergeFromBuffer(data, registry);
  factory NormalizationParams.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NormalizationParams()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NormalizationParams',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: NormalizationParams.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'loudnessDb', fieldType: $pb.PbFieldType.OF)
    ..aD(2, _omitFieldNames ? '' : 'truePeakDb', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NormalizationParams clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NormalizationParams copyWith(void Function(NormalizationParams) updates) =>
      super.copyWith((message) => updates(message as NormalizationParams))
          as NormalizationParams;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use NormalizationParams() / NormalizationParams.new instead')
  static NormalizationParams create() => NormalizationParams._();
  static $pb.GeneratedMessage $_createMessage() => NormalizationParams._();
  @$core.override
  NormalizationParams createEmptyInstance() => NormalizationParams._();
  @$core.pragma('dart2js:noInline')
  static NormalizationParams getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NormalizationParams>(
          NormalizationParams.$_createMessage);
  static NormalizationParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get loudnessDb => $_getN(0);
  @$pb.TagNumber(1)
  set loudnessDb($core.double value) => $_setFloat(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLoudnessDb() => $_has(0);
  @$pb.TagNumber(1)
  void clearLoudnessDb() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get truePeakDb => $_getN(1);
  @$pb.TagNumber(2)
  set truePeakDb($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTruePeakDb() => $_has(1);
  @$pb.TagNumber(2)
  void clearTruePeakDb() => $_clearField(2);
}

class AudioFile extends $pb.GeneratedMessage {
  factory AudioFile({
    $core.List<$core.int>? fileId,
    $core.int? averageBitrate,
  }) {
    final result = AudioFile._();
    if (fileId != null) result.fileId = fileId;
    if (averageBitrate != null) result.averageBitrate = averageBitrate;
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
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: AudioFile.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'fileId', $pb.PbFieldType.OY)
    ..aI(3, _omitFieldNames ? '' : 'averageBitrate')
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

  @$pb.TagNumber(3)
  $core.int get averageBitrate => $_getIZ(1);
  @$pb.TagNumber(3)
  set averageBitrate($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(3)
  $core.bool hasAverageBitrate() => $_has(1);
  @$pb.TagNumber(3)
  void clearAverageBitrate() => $_clearField(3);
}

class AudioHosted extends $pb.GeneratedMessage {
  factory AudioHosted({
    $core.Iterable<AudioFile>? files,
    $core.List<$core.int>? audioId,
    NormalizationParams? fileNorm,
    NormalizationParams? groupNorm,
  }) {
    final result = AudioHosted._();
    if (files != null) result.files.addAll(files);
    if (audioId != null) result.audioId = audioId;
    if (fileNorm != null) result.fileNorm = fileNorm;
    if (groupNorm != null) result.groupNorm = groupNorm;
    return result;
  }

  AudioHosted._();

  factory AudioHosted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioHosted()..mergeFromBuffer(data, registry);
  factory AudioHosted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioHosted()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioHosted',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: AudioHosted.$_createMessage)
    ..pPM<AudioFile>(1, _omitFieldNames ? '' : 'files',
        subBuilder: AudioFile.$_createMessage)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'audioId', $pb.PbFieldType.OY)
    ..aOM<NormalizationParams>(3, _omitFieldNames ? '' : 'fileNorm',
        subBuilder: NormalizationParams.$_createMessage)
    ..aOM<NormalizationParams>(4, _omitFieldNames ? '' : 'groupNorm',
        subBuilder: NormalizationParams.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioHosted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioHosted copyWith(void Function(AudioHosted) updates) =>
      super.copyWith((message) => updates(message as AudioHosted))
          as AudioHosted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AudioHosted() / AudioHosted.new instead')
  static AudioHosted create() => AudioHosted._();
  static $pb.GeneratedMessage $_createMessage() => AudioHosted._();
  @$core.override
  AudioHosted createEmptyInstance() => AudioHosted._();
  @$core.pragma('dart2js:noInline')
  static AudioHosted getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AudioHosted>(
          AudioHosted.$_createMessage);
  static AudioHosted? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<AudioFile> get files => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get audioId => $_getN(1);
  @$pb.TagNumber(2)
  set audioId($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAudioId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAudioId() => $_clearField(2);

  @$pb.TagNumber(3)
  NormalizationParams get fileNorm => $_getN(2);
  @$pb.TagNumber(3)
  set fileNorm(NormalizationParams value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasFileNorm() => $_has(2);
  @$pb.TagNumber(3)
  void clearFileNorm() => $_clearField(3);
  @$pb.TagNumber(3)
  NormalizationParams ensureFileNorm() => $_ensure(2);

  @$pb.TagNumber(4)
  NormalizationParams get groupNorm => $_getN(3);
  @$pb.TagNumber(4)
  set groupNorm(NormalizationParams value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasGroupNorm() => $_has(3);
  @$pb.TagNumber(4)
  void clearGroupNorm() => $_clearField(4);
  @$pb.TagNumber(4)
  NormalizationParams ensureGroupNorm() => $_ensure(3);
}

class FlatFile extends $pb.GeneratedMessage {
  factory FlatFile({
    $core.String? cdnUrl,
  }) {
    final result = FlatFile._();
    if (cdnUrl != null) result.cdnUrl = cdnUrl;
    return result;
  }

  FlatFile._();

  factory FlatFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FlatFile()..mergeFromBuffer(data, registry);
  factory FlatFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FlatFile()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FlatFile',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: FlatFile.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'cdnUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FlatFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FlatFile copyWith(void Function(FlatFile) updates) =>
      super.copyWith((message) => updates(message as FlatFile)) as FlatFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use FlatFile() / FlatFile.new instead')
  static FlatFile create() => FlatFile._();
  static $pb.GeneratedMessage $_createMessage() => FlatFile._();
  @$core.override
  FlatFile createEmptyInstance() => FlatFile._();
  @$core.pragma('dart2js:noInline')
  static FlatFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FlatFile>(FlatFile.$_createMessage);
  static FlatFile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get cdnUrl => $_getSZ(0);
  @$pb.TagNumber(1)
  set cdnUrl($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCdnUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearCdnUrl() => $_clearField(1);
}

class AudioPassThrough extends $pb.GeneratedMessage {
  factory AudioPassThrough({
    FlatFile? flatFile,
  }) {
    final result = AudioPassThrough._();
    if (flatFile != null) result.flatFile = flatFile;
    return result;
  }

  AudioPassThrough._();

  factory AudioPassThrough.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioPassThrough()..mergeFromBuffer(data, registry);
  factory AudioPassThrough.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioPassThrough()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioPassThrough',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: AudioPassThrough.$_createMessage)
    ..aOM<FlatFile>(1, _omitFieldNames ? '' : 'flatFile',
        subBuilder: FlatFile.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioPassThrough clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioPassThrough copyWith(void Function(AudioPassThrough) updates) =>
      super.copyWith((message) => updates(message as AudioPassThrough))
          as AudioPassThrough;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AudioPassThrough() / AudioPassThrough.new instead')
  static AudioPassThrough create() => AudioPassThrough._();
  static $pb.GeneratedMessage $_createMessage() => AudioPassThrough._();
  @$core.override
  AudioPassThrough createEmptyInstance() => AudioPassThrough._();
  @$core.pragma('dart2js:noInline')
  static AudioPassThrough getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AudioPassThrough>(
          AudioPassThrough.$_createMessage);
  static AudioPassThrough? _defaultInstance;

  @$pb.TagNumber(1)
  FlatFile get flatFile => $_getN(0);
  @$pb.TagNumber(1)
  set flatFile(FlatFile value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFlatFile() => $_has(0);
  @$pb.TagNumber(1)
  void clearFlatFile() => $_clearField(1);
  @$pb.TagNumber(1)
  FlatFile ensureFlatFile() => $_ensure(0);
}

class PlaybackOffsets extends $pb.GeneratedMessage {
  factory PlaybackOffsets({
    Duration? start,
    Duration? end,
  }) {
    final result = PlaybackOffsets._();
    if (start != null) result.start = start;
    if (end != null) result.end = end;
    return result;
  }

  PlaybackOffsets._();

  factory PlaybackOffsets.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaybackOffsets()..mergeFromBuffer(data, registry);
  factory PlaybackOffsets.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaybackOffsets()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlaybackOffsets',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: PlaybackOffsets.$_createMessage)
    ..aOM<Duration>(1, _omitFieldNames ? '' : 'start',
        subBuilder: Duration.$_createMessage)
    ..aOM<Duration>(2, _omitFieldNames ? '' : 'end',
        subBuilder: Duration.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlaybackOffsets clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlaybackOffsets copyWith(void Function(PlaybackOffsets) updates) =>
      super.copyWith((message) => updates(message as PlaybackOffsets))
          as PlaybackOffsets;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PlaybackOffsets() / PlaybackOffsets.new instead')
  static PlaybackOffsets create() => PlaybackOffsets._();
  static $pb.GeneratedMessage $_createMessage() => PlaybackOffsets._();
  @$core.override
  PlaybackOffsets createEmptyInstance() => PlaybackOffsets._();
  @$core.pragma('dart2js:noInline')
  static PlaybackOffsets getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PlaybackOffsets>(
          PlaybackOffsets.$_createMessage);
  static PlaybackOffsets? _defaultInstance;

  @$pb.TagNumber(1)
  Duration get start => $_getN(0);
  @$pb.TagNumber(1)
  set start(Duration value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStart() => $_has(0);
  @$pb.TagNumber(1)
  void clearStart() => $_clearField(1);
  @$pb.TagNumber(1)
  Duration ensureStart() => $_ensure(0);

  @$pb.TagNumber(2)
  Duration get end => $_getN(1);
  @$pb.TagNumber(2)
  set end(Duration value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasEnd() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnd() => $_clearField(2);
  @$pb.TagNumber(2)
  Duration ensureEnd() => $_ensure(1);
}

class AudioPlayback extends $pb.GeneratedMessage {
  factory AudioPlayback({
    AudioPassThrough? passThrough,
    AudioHosted? hosted,
    $core.String? reportingUri,
    PlaybackOffsets? offsets,
  }) {
    final result = AudioPlayback._();
    if (passThrough != null) result.passThrough = passThrough;
    if (hosted != null) result.hosted = hosted;
    if (reportingUri != null) result.reportingUri = reportingUri;
    if (offsets != null) result.offsets = offsets;
    return result;
  }

  AudioPlayback._();

  factory AudioPlayback.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioPlayback()..mergeFromBuffer(data, registry);
  factory AudioPlayback.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioPlayback()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioPlayback',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: AudioPlayback.$_createMessage)
    ..aOM<AudioPassThrough>(1, _omitFieldNames ? '' : 'passThrough',
        subBuilder: AudioPassThrough.$_createMessage)
    ..aOM<AudioHosted>(2, _omitFieldNames ? '' : 'hosted',
        subBuilder: AudioHosted.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'reportingUri')
    ..aOM<PlaybackOffsets>(4, _omitFieldNames ? '' : 'offsets',
        subBuilder: PlaybackOffsets.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioPlayback clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioPlayback copyWith(void Function(AudioPlayback) updates) =>
      super.copyWith((message) => updates(message as AudioPlayback))
          as AudioPlayback;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AudioPlayback() / AudioPlayback.new instead')
  static AudioPlayback create() => AudioPlayback._();
  static $pb.GeneratedMessage $_createMessage() => AudioPlayback._();
  @$core.override
  AudioPlayback createEmptyInstance() => AudioPlayback._();
  @$core.pragma('dart2js:noInline')
  static AudioPlayback getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AudioPlayback>(
          AudioPlayback.$_createMessage);
  static AudioPlayback? _defaultInstance;

  @$pb.TagNumber(1)
  AudioPassThrough get passThrough => $_getN(0);
  @$pb.TagNumber(1)
  set passThrough(AudioPassThrough value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPassThrough() => $_has(0);
  @$pb.TagNumber(1)
  void clearPassThrough() => $_clearField(1);
  @$pb.TagNumber(1)
  AudioPassThrough ensurePassThrough() => $_ensure(0);

  @$pb.TagNumber(2)
  AudioHosted get hosted => $_getN(1);
  @$pb.TagNumber(2)
  set hosted(AudioHosted value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasHosted() => $_has(1);
  @$pb.TagNumber(2)
  void clearHosted() => $_clearField(2);
  @$pb.TagNumber(2)
  AudioHosted ensureHosted() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get reportingUri => $_getSZ(2);
  @$pb.TagNumber(3)
  set reportingUri($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReportingUri() => $_has(2);
  @$pb.TagNumber(3)
  void clearReportingUri() => $_clearField(3);

  @$pb.TagNumber(4)
  PlaybackOffsets get offsets => $_getN(3);
  @$pb.TagNumber(4)
  set offsets(PlaybackOffsets value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasOffsets() => $_has(3);
  @$pb.TagNumber(4)
  void clearOffsets() => $_clearField(4);
  @$pb.TagNumber(4)
  PlaybackOffsets ensureOffsets() => $_ensure(3);
}

class AudioMapEntry extends $pb.GeneratedMessage {
  factory AudioMapEntry({
    $core.int? key,
    AudioPlayback? value,
  }) {
    final result = AudioMapEntry._();
    if (key != null) result.key = key;
    if (value != null) result.value = value;
    return result;
  }

  AudioMapEntry._();

  factory AudioMapEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioMapEntry()..mergeFromBuffer(data, registry);
  factory AudioMapEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AudioMapEntry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AudioMapEntry',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: AudioMapEntry.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'key')
    ..aOM<AudioPlayback>(2, _omitFieldNames ? '' : 'value',
        subBuilder: AudioPlayback.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioMapEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AudioMapEntry copyWith(void Function(AudioMapEntry) updates) =>
      super.copyWith((message) => updates(message as AudioMapEntry))
          as AudioMapEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AudioMapEntry() / AudioMapEntry.new instead')
  static AudioMapEntry create() => AudioMapEntry._();
  static $pb.GeneratedMessage $_createMessage() => AudioMapEntry._();
  @$core.override
  AudioMapEntry createEmptyInstance() => AudioMapEntry._();
  @$core.pragma('dart2js:noInline')
  static AudioMapEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AudioMapEntry>(
          AudioMapEntry.$_createMessage);
  static AudioMapEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get key => $_getIZ(0);
  @$pb.TagNumber(1)
  set key($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  AudioPlayback get value => $_getN(1);
  @$pb.TagNumber(2)
  set value(AudioPlayback value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
  @$pb.TagNumber(2)
  AudioPlayback ensureValue() => $_ensure(1);
}

class VideoHosted extends $pb.GeneratedMessage {
  factory VideoHosted({
    $core.List<$core.int>? videoId,
  }) {
    final result = VideoHosted._();
    if (videoId != null) result.videoId = videoId;
    return result;
  }

  VideoHosted._();

  factory VideoHosted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VideoHosted()..mergeFromBuffer(data, registry);
  factory VideoHosted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VideoHosted()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VideoHosted',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: VideoHosted.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'videoId', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VideoHosted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VideoHosted copyWith(void Function(VideoHosted) updates) =>
      super.copyWith((message) => updates(message as VideoHosted))
          as VideoHosted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use VideoHosted() / VideoHosted.new instead')
  static VideoHosted create() => VideoHosted._();
  static $pb.GeneratedMessage $_createMessage() => VideoHosted._();
  @$core.override
  VideoHosted createEmptyInstance() => VideoHosted._();
  @$core.pragma('dart2js:noInline')
  static VideoHosted getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VideoHosted>(
          VideoHosted.$_createMessage);
  static VideoHosted? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get videoId => $_getN(0);
  @$pb.TagNumber(1)
  set videoId($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVideoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVideoId() => $_clearField(1);
}

class VideoPlayback extends $pb.GeneratedMessage {
  factory VideoPlayback({
    VideoHosted? hosted,
    $core.String? reportingUri,
    PlaybackOffsets? offsets,
  }) {
    final result = VideoPlayback._();
    if (hosted != null) result.hosted = hosted;
    if (reportingUri != null) result.reportingUri = reportingUri;
    if (offsets != null) result.offsets = offsets;
    return result;
  }

  VideoPlayback._();

  factory VideoPlayback.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VideoPlayback()..mergeFromBuffer(data, registry);
  factory VideoPlayback.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VideoPlayback()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VideoPlayback',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: VideoPlayback.$_createMessage)
    ..aOM<VideoHosted>(1, _omitFieldNames ? '' : 'hosted',
        subBuilder: VideoHosted.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'reportingUri')
    ..aOM<PlaybackOffsets>(3, _omitFieldNames ? '' : 'offsets',
        subBuilder: PlaybackOffsets.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VideoPlayback clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VideoPlayback copyWith(void Function(VideoPlayback) updates) =>
      super.copyWith((message) => updates(message as VideoPlayback))
          as VideoPlayback;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use VideoPlayback() / VideoPlayback.new instead')
  static VideoPlayback create() => VideoPlayback._();
  static $pb.GeneratedMessage $_createMessage() => VideoPlayback._();
  @$core.override
  VideoPlayback createEmptyInstance() => VideoPlayback._();
  @$core.pragma('dart2js:noInline')
  static VideoPlayback getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VideoPlayback>(
          VideoPlayback.$_createMessage);
  static VideoPlayback? _defaultInstance;

  @$pb.TagNumber(1)
  VideoHosted get hosted => $_getN(0);
  @$pb.TagNumber(1)
  set hosted(VideoHosted value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHosted() => $_has(0);
  @$pb.TagNumber(1)
  void clearHosted() => $_clearField(1);
  @$pb.TagNumber(1)
  VideoHosted ensureHosted() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get reportingUri => $_getSZ(1);
  @$pb.TagNumber(2)
  set reportingUri($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReportingUri() => $_has(1);
  @$pb.TagNumber(2)
  void clearReportingUri() => $_clearField(2);

  @$pb.TagNumber(3)
  PlaybackOffsets get offsets => $_getN(2);
  @$pb.TagNumber(3)
  set offsets(PlaybackOffsets value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOffsets() => $_has(2);
  @$pb.TagNumber(3)
  void clearOffsets() => $_clearField(3);
  @$pb.TagNumber(3)
  PlaybackOffsets ensureOffsets() => $_ensure(2);
}

class VideoMapEntry extends $pb.GeneratedMessage {
  factory VideoMapEntry({
    $core.int? key,
    VideoPlayback? value,
  }) {
    final result = VideoMapEntry._();
    if (key != null) result.key = key;
    if (value != null) result.value = value;
    return result;
  }

  VideoMapEntry._();

  factory VideoMapEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VideoMapEntry()..mergeFromBuffer(data, registry);
  factory VideoMapEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VideoMapEntry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VideoMapEntry',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: VideoMapEntry.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'key')
    ..aOM<VideoPlayback>(2, _omitFieldNames ? '' : 'value',
        subBuilder: VideoPlayback.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VideoMapEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VideoMapEntry copyWith(void Function(VideoMapEntry) updates) =>
      super.copyWith((message) => updates(message as VideoMapEntry))
          as VideoMapEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use VideoMapEntry() / VideoMapEntry.new instead')
  static VideoMapEntry create() => VideoMapEntry._();
  static $pb.GeneratedMessage $_createMessage() => VideoMapEntry._();
  @$core.override
  VideoMapEntry createEmptyInstance() => VideoMapEntry._();
  @$core.pragma('dart2js:noInline')
  static VideoMapEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VideoMapEntry>(
          VideoMapEntry.$_createMessage);
  static VideoMapEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get key => $_getIZ(0);
  @$pb.TagNumber(1)
  set key($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  VideoPlayback get value => $_getN(1);
  @$pb.TagNumber(2)
  set value(VideoPlayback value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
  @$pb.TagNumber(2)
  VideoPlayback ensureValue() => $_ensure(1);
}

class PlaybackTrait extends $pb.GeneratedMessage {
  factory PlaybackTrait({
    $core.Iterable<AudioMapEntry>? audio,
    $core.Iterable<VideoMapEntry>? video,
  }) {
    final result = PlaybackTrait._();
    if (audio != null) result.audio.addAll(audio);
    if (video != null) result.video.addAll(video);
    return result;
  }

  PlaybackTrait._();

  factory PlaybackTrait.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaybackTrait()..mergeFromBuffer(data, registry);
  factory PlaybackTrait.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaybackTrait()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlaybackTrait',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.contentagnostic.v2'),
      createEmptyInstance: PlaybackTrait.$_createMessage)
    ..pPM<AudioMapEntry>(1, _omitFieldNames ? '' : 'audio',
        subBuilder: AudioMapEntry.$_createMessage)
    ..pPM<VideoMapEntry>(2, _omitFieldNames ? '' : 'video',
        subBuilder: VideoMapEntry.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlaybackTrait clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlaybackTrait copyWith(void Function(PlaybackTrait) updates) =>
      super.copyWith((message) => updates(message as PlaybackTrait))
          as PlaybackTrait;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PlaybackTrait() / PlaybackTrait.new instead')
  static PlaybackTrait create() => PlaybackTrait._();
  static $pb.GeneratedMessage $_createMessage() => PlaybackTrait._();
  @$core.override
  PlaybackTrait createEmptyInstance() => PlaybackTrait._();
  @$core.pragma('dart2js:noInline')
  static PlaybackTrait getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PlaybackTrait>(
          PlaybackTrait.$_createMessage);
  static PlaybackTrait? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<AudioMapEntry> get audio => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<VideoMapEntry> get video => $_getList(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
