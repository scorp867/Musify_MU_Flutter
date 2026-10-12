// This is a generated file - do not edit.
//
// Generated from spotify/scrollsita/v1/scrollsita.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class NpvScrollResponse extends $pb.GeneratedMessage {
  factory NpvScrollResponse({
    NpvScrollStructure? structure,
    ResponseInfo? responseInfo,
    DebugInfo? debugInfo,
  }) {
    final result = NpvScrollResponse._();
    if (structure != null) result.structure = structure;
    if (responseInfo != null) result.responseInfo = responseInfo;
    if (debugInfo != null) result.debugInfo = debugInfo;
    return result;
  }

  NpvScrollResponse._();

  factory NpvScrollResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NpvScrollResponse()..mergeFromBuffer(data, registry);
  factory NpvScrollResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NpvScrollResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NpvScrollResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: NpvScrollResponse.$_createMessage)
    ..aOM<NpvScrollStructure>(1, _omitFieldNames ? '' : 'structure',
        subBuilder: NpvScrollStructure.$_createMessage)
    ..aOM<ResponseInfo>(2, _omitFieldNames ? '' : 'responseInfo',
        subBuilder: ResponseInfo.$_createMessage)
    ..aOM<DebugInfo>(3, _omitFieldNames ? '' : 'debugInfo',
        subBuilder: DebugInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NpvScrollResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NpvScrollResponse copyWith(void Function(NpvScrollResponse) updates) =>
      super.copyWith((message) => updates(message as NpvScrollResponse))
          as NpvScrollResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NpvScrollResponse() / NpvScrollResponse.new instead')
  static NpvScrollResponse create() => NpvScrollResponse._();
  static $pb.GeneratedMessage $_createMessage() => NpvScrollResponse._();
  @$core.override
  NpvScrollResponse createEmptyInstance() => NpvScrollResponse._();
  @$core.pragma('dart2js:noInline')
  static NpvScrollResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NpvScrollResponse>(
          NpvScrollResponse.$_createMessage);
  static NpvScrollResponse? _defaultInstance;

  @$pb.TagNumber(1)
  NpvScrollStructure get structure => $_getN(0);
  @$pb.TagNumber(1)
  set structure(NpvScrollStructure value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStructure() => $_has(0);
  @$pb.TagNumber(1)
  void clearStructure() => $_clearField(1);
  @$pb.TagNumber(1)
  NpvScrollStructure ensureStructure() => $_ensure(0);

  @$pb.TagNumber(2)
  ResponseInfo get responseInfo => $_getN(1);
  @$pb.TagNumber(2)
  set responseInfo(ResponseInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasResponseInfo() => $_has(1);
  @$pb.TagNumber(2)
  void clearResponseInfo() => $_clearField(2);
  @$pb.TagNumber(2)
  ResponseInfo ensureResponseInfo() => $_ensure(1);

  @$pb.TagNumber(3)
  DebugInfo get debugInfo => $_getN(2);
  @$pb.TagNumber(3)
  set debugInfo(DebugInfo value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDebugInfo() => $_has(2);
  @$pb.TagNumber(3)
  void clearDebugInfo() => $_clearField(3);
  @$pb.TagNumber(3)
  DebugInfo ensureDebugInfo() => $_ensure(2);
}

class NpvScrollStructure extends $pb.GeneratedMessage {
  factory NpvScrollStructure({
    $core.Iterable<Section>? sections,
  }) {
    final result = NpvScrollStructure._();
    if (sections != null) result.sections.addAll(sections);
    return result;
  }

  NpvScrollStructure._();

  factory NpvScrollStructure.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NpvScrollStructure()..mergeFromBuffer(data, registry);
  factory NpvScrollStructure.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NpvScrollStructure()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NpvScrollStructure',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: NpvScrollStructure.$_createMessage)
    ..pPM<Section>(1, _omitFieldNames ? '' : 'sections',
        subBuilder: Section.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NpvScrollStructure clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NpvScrollStructure copyWith(void Function(NpvScrollStructure) updates) =>
      super.copyWith((message) => updates(message as NpvScrollStructure))
          as NpvScrollStructure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NpvScrollStructure() / NpvScrollStructure.new instead')
  static NpvScrollStructure create() => NpvScrollStructure._();
  static $pb.GeneratedMessage $_createMessage() => NpvScrollStructure._();
  @$core.override
  NpvScrollStructure createEmptyInstance() => NpvScrollStructure._();
  @$core.pragma('dart2js:noInline')
  static NpvScrollStructure getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NpvScrollStructure>(
          NpvScrollStructure.$_createMessage);
  static NpvScrollStructure? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Section> get sections => $_getList(0);
}

class ResponseInfo extends $pb.GeneratedMessage {
  factory ResponseInfo({
    $core.String? responseId,
  }) {
    final result = ResponseInfo._();
    if (responseId != null) result.responseId = responseId;
    return result;
  }

  ResponseInfo._();

  factory ResponseInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResponseInfo()..mergeFromBuffer(data, registry);
  factory ResponseInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResponseInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponseInfo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: ResponseInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'responseId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseInfo copyWith(void Function(ResponseInfo) updates) =>
      super.copyWith((message) => updates(message as ResponseInfo))
          as ResponseInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResponseInfo() / ResponseInfo.new instead')
  static ResponseInfo create() => ResponseInfo._();
  static $pb.GeneratedMessage $_createMessage() => ResponseInfo._();
  @$core.override
  ResponseInfo createEmptyInstance() => ResponseInfo._();
  @$core.pragma('dart2js:noInline')
  static ResponseInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResponseInfo>(
          ResponseInfo.$_createMessage);
  static ResponseInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get responseId => $_getSZ(0);
  @$pb.TagNumber(1)
  set responseId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasResponseId() => $_has(0);
  @$pb.TagNumber(1)
  void clearResponseId() => $_clearField(1);
}

class DebugInfo extends $pb.GeneratedMessage {
  factory DebugInfo({
    $core.String? debugMessage,
  }) {
    final result = DebugInfo._();
    if (debugMessage != null) result.debugMessage = debugMessage;
    return result;
  }

  DebugInfo._();

  factory DebugInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DebugInfo()..mergeFromBuffer(data, registry);
  factory DebugInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DebugInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DebugInfo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: DebugInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'debugMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DebugInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DebugInfo copyWith(void Function(DebugInfo) updates) =>
      super.copyWith((message) => updates(message as DebugInfo)) as DebugInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DebugInfo() / DebugInfo.new instead')
  static DebugInfo create() => DebugInfo._();
  static $pb.GeneratedMessage $_createMessage() => DebugInfo._();
  @$core.override
  DebugInfo createEmptyInstance() => DebugInfo._();
  @$core.pragma('dart2js:noInline')
  static DebugInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DebugInfo>(DebugInfo.$_createMessage);
  static DebugInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get debugMessage => $_getSZ(0);
  @$pb.TagNumber(1)
  set debugMessage($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDebugMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearDebugMessage() => $_clearField(1);
}

class DisplayCondition extends $pb.GeneratedMessage {
  factory DisplayCondition({
    $core.bool? isVisible,
  }) {
    final result = DisplayCondition._();
    if (isVisible != null) result.isVisible = isVisible;
    return result;
  }

  DisplayCondition._();

  factory DisplayCondition.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisplayCondition()..mergeFromBuffer(data, registry);
  factory DisplayCondition.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisplayCondition()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DisplayCondition',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: DisplayCondition.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'isVisible')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisplayCondition clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisplayCondition copyWith(void Function(DisplayCondition) updates) =>
      super.copyWith((message) => updates(message as DisplayCondition))
          as DisplayCondition;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DisplayCondition() / DisplayCondition.new instead')
  static DisplayCondition create() => DisplayCondition._();
  static $pb.GeneratedMessage $_createMessage() => DisplayCondition._();
  @$core.override
  DisplayCondition createEmptyInstance() => DisplayCondition._();
  @$core.pragma('dart2js:noInline')
  static DisplayCondition getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DisplayCondition>(
          DisplayCondition.$_createMessage);
  static DisplayCondition? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isVisible => $_getBF(0);
  @$pb.TagNumber(1)
  set isVisible($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIsVisible() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsVisible() => $_clearField(1);
}

class SectionInfo extends $pb.GeneratedMessage {
  factory SectionInfo({
    $core.String? sectionId,
    DisplayCondition? displayCondition,
  }) {
    final result = SectionInfo._();
    if (sectionId != null) result.sectionId = sectionId;
    if (displayCondition != null) result.displayCondition = displayCondition;
    return result;
  }

  SectionInfo._();

  factory SectionInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionInfo()..mergeFromBuffer(data, registry);
  factory SectionInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SectionInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SectionInfo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: SectionInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sectionId')
    ..aOM<DisplayCondition>(2, _omitFieldNames ? '' : 'displayCondition',
        subBuilder: DisplayCondition.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SectionInfo copyWith(void Function(SectionInfo) updates) =>
      super.copyWith((message) => updates(message as SectionInfo))
          as SectionInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SectionInfo() / SectionInfo.new instead')
  static SectionInfo create() => SectionInfo._();
  static $pb.GeneratedMessage $_createMessage() => SectionInfo._();
  @$core.override
  SectionInfo createEmptyInstance() => SectionInfo._();
  @$core.pragma('dart2js:noInline')
  static SectionInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SectionInfo>(
          SectionInfo.$_createMessage);
  static SectionInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sectionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sectionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSectionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSectionId() => $_clearField(1);

  @$pb.TagNumber(2)
  DisplayCondition get displayCondition => $_getN(1);
  @$pb.TagNumber(2)
  set displayCondition(DisplayCondition value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDisplayCondition() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisplayCondition() => $_clearField(2);
  @$pb.TagNumber(2)
  DisplayCondition ensureDisplayCondition() => $_ensure(1);
}

class CreatorBio extends $pb.GeneratedMessage {
  factory CreatorBio({
    $core.String? creatorUri,
    $core.String? title,
  }) {
    final result = CreatorBio._();
    if (creatorUri != null) result.creatorUri = creatorUri;
    if (title != null) result.title = title;
    return result;
  }

  CreatorBio._();

  factory CreatorBio.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreatorBio()..mergeFromBuffer(data, registry);
  factory CreatorBio.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreatorBio()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreatorBio',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: CreatorBio.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'creatorUri')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatorBio clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatorBio copyWith(void Function(CreatorBio) updates) =>
      super.copyWith((message) => updates(message as CreatorBio)) as CreatorBio;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CreatorBio() / CreatorBio.new instead')
  static CreatorBio create() => CreatorBio._();
  static $pb.GeneratedMessage $_createMessage() => CreatorBio._();
  @$core.override
  CreatorBio createEmptyInstance() => CreatorBio._();
  @$core.pragma('dart2js:noInline')
  static CreatorBio getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreatorBio>(CreatorBio.$_createMessage);
  static CreatorBio? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get creatorUri => $_getSZ(0);
  @$pb.TagNumber(1)
  set creatorUri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCreatorUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearCreatorUri() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);
}

class Credits extends $pb.GeneratedMessage {
  factory Credits({
    $core.String? entityUri,
    $core.Iterable<$core.String>? contributorUri,
  }) {
    final result = Credits._();
    if (entityUri != null) result.entityUri = entityUri;
    if (contributorUri != null) result.contributorUri.addAll(contributorUri);
    return result;
  }

  Credits._();

  factory Credits.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Credits()..mergeFromBuffer(data, registry);
  factory Credits.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Credits()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Credits',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: Credits.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'entityUri')
    ..pPS(2, _omitFieldNames ? '' : 'contributorUri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Credits clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Credits copyWith(void Function(Credits) updates) =>
      super.copyWith((message) => updates(message as Credits)) as Credits;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Credits() / Credits.new instead')
  static Credits create() => Credits._();
  static $pb.GeneratedMessage $_createMessage() => Credits._();
  @$core.override
  Credits createEmptyInstance() => Credits._();
  @$core.pragma('dart2js:noInline')
  static Credits getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Credits>(Credits.$_createMessage);
  static Credits? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get entityUri => $_getSZ(0);
  @$pb.TagNumber(1)
  set entityUri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEntityUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearEntityUri() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get contributorUri => $_getList(1);
}

class Lyrics extends $pb.GeneratedMessage {
  factory Lyrics({
    $core.String? entityUri,
  }) {
    final result = Lyrics._();
    if (entityUri != null) result.entityUri = entityUri;
    return result;
  }

  Lyrics._();

  factory Lyrics.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Lyrics()..mergeFromBuffer(data, registry);
  factory Lyrics.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Lyrics()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Lyrics',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: Lyrics.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'entityUri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Lyrics clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Lyrics copyWith(void Function(Lyrics) updates) =>
      super.copyWith((message) => updates(message as Lyrics)) as Lyrics;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Lyrics() / Lyrics.new instead')
  static Lyrics create() => Lyrics._();
  static $pb.GeneratedMessage $_createMessage() => Lyrics._();
  @$core.override
  Lyrics createEmptyInstance() => Lyrics._();
  @$core.pragma('dart2js:noInline')
  static Lyrics getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Lyrics>(Lyrics.$_createMessage);
  static Lyrics? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get entityUri => $_getSZ(0);
  @$pb.TagNumber(1)
  set entityUri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEntityUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearEntityUri() => $_clearField(1);
}

class LiveEvents extends $pb.GeneratedMessage {
  factory LiveEvents({
    $core.Iterable<$core.String>? concertUri,
    $core.String? artistUri,
  }) {
    final result = LiveEvents._();
    if (concertUri != null) result.concertUri.addAll(concertUri);
    if (artistUri != null) result.artistUri = artistUri;
    return result;
  }

  LiveEvents._();

  factory LiveEvents.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LiveEvents()..mergeFromBuffer(data, registry);
  factory LiveEvents.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LiveEvents()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveEvents',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: LiveEvents.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'concertUri')
    ..aOS(2, _omitFieldNames ? '' : 'artistUri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveEvents clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveEvents copyWith(void Function(LiveEvents) updates) =>
      super.copyWith((message) => updates(message as LiveEvents)) as LiveEvents;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LiveEvents() / LiveEvents.new instead')
  static LiveEvents create() => LiveEvents._();
  static $pb.GeneratedMessage $_createMessage() => LiveEvents._();
  @$core.override
  LiveEvents createEmptyInstance() => LiveEvents._();
  @$core.pragma('dart2js:noInline')
  static LiveEvents getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveEvents>(LiveEvents.$_createMessage);
  static LiveEvents? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get concertUri => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get artistUri => $_getSZ(1);
  @$pb.TagNumber(2)
  set artistUri($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasArtistUri() => $_has(1);
  @$pb.TagNumber(2)
  void clearArtistUri() => $_clearField(2);
}

class Merch extends $pb.GeneratedMessage {
  factory Merch({
    $core.String? entityUri,
  }) {
    final result = Merch._();
    if (entityUri != null) result.entityUri = entityUri;
    return result;
  }

  Merch._();

  factory Merch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Merch()..mergeFromBuffer(data, registry);
  factory Merch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Merch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Merch',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: Merch.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'entityUri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Merch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Merch copyWith(void Function(Merch) updates) =>
      super.copyWith((message) => updates(message as Merch)) as Merch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Merch() / Merch.new instead')
  static Merch create() => Merch._();
  static $pb.GeneratedMessage $_createMessage() => Merch._();
  @$core.override
  Merch createEmptyInstance() => Merch._();
  @$core.pragma('dart2js:noInline')
  static Merch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Merch>(Merch.$_createMessage);
  static Merch? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get entityUri => $_getSZ(0);
  @$pb.TagNumber(1)
  set entityUri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEntityUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearEntityUri() => $_clearField(1);
}

class Heading extends $pb.GeneratedMessage {
  factory Heading({
    $core.String? title,
    $core.String? formatText,
  }) {
    final result = Heading._();
    if (title != null) result.title = title;
    if (formatText != null) result.formatText = formatText;
    return result;
  }

  Heading._();

  factory Heading.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Heading()..mergeFromBuffer(data, registry);
  factory Heading.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Heading()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Heading',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: Heading.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'formatText')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Heading clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Heading copyWith(void Function(Heading) updates) =>
      super.copyWith((message) => updates(message as Heading)) as Heading;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Heading() / Heading.new instead')
  static Heading create() => Heading._();
  static $pb.GeneratedMessage $_createMessage() => Heading._();
  @$core.override
  Heading createEmptyInstance() => Heading._();
  @$core.pragma('dart2js:noInline')
  static Heading getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Heading>(Heading.$_createMessage);
  static Heading? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get formatText => $_getSZ(1);
  @$pb.TagNumber(2)
  set formatText($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFormatText() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormatText() => $_clearField(2);
}

class DiscoveryFeed extends $pb.GeneratedMessage {
  factory DiscoveryFeed({
    Heading? heading,
    $core.Iterable<$core.String>? items,
  }) {
    final result = DiscoveryFeed._();
    if (heading != null) result.heading = heading;
    if (items != null) result.items.addAll(items);
    return result;
  }

  DiscoveryFeed._();

  factory DiscoveryFeed.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DiscoveryFeed()..mergeFromBuffer(data, registry);
  factory DiscoveryFeed.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DiscoveryFeed()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiscoveryFeed',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: DiscoveryFeed.$_createMessage)
    ..aOM<Heading>(1, _omitFieldNames ? '' : 'heading',
        subBuilder: Heading.$_createMessage)
    ..pPS(2, _omitFieldNames ? '' : 'items')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscoveryFeed clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscoveryFeed copyWith(void Function(DiscoveryFeed) updates) =>
      super.copyWith((message) => updates(message as DiscoveryFeed))
          as DiscoveryFeed;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DiscoveryFeed() / DiscoveryFeed.new instead')
  static DiscoveryFeed create() => DiscoveryFeed._();
  static $pb.GeneratedMessage $_createMessage() => DiscoveryFeed._();
  @$core.override
  DiscoveryFeed createEmptyInstance() => DiscoveryFeed._();
  @$core.pragma('dart2js:noInline')
  static DiscoveryFeed getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DiscoveryFeed>(
          DiscoveryFeed.$_createMessage);
  static DiscoveryFeed? _defaultInstance;

  @$pb.TagNumber(1)
  Heading get heading => $_getN(0);
  @$pb.TagNumber(1)
  set heading(Heading value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeading() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeading() => $_clearField(1);
  @$pb.TagNumber(1)
  Heading ensureHeading() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get items => $_getList(1);
}

class SongDNA extends $pb.GeneratedMessage {
  factory SongDNA({
    $core.String? entityUri,
    $core.Iterable<$core.String>? uris,
  }) {
    final result = SongDNA._();
    if (entityUri != null) result.entityUri = entityUri;
    if (uris != null) result.uris.addAll(uris);
    return result;
  }

  SongDNA._();

  factory SongDNA.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SongDNA()..mergeFromBuffer(data, registry);
  factory SongDNA.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SongDNA()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SongDNA',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: SongDNA.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'entityUri')
    ..pPS(2, _omitFieldNames ? '' : 'uris')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SongDNA clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SongDNA copyWith(void Function(SongDNA) updates) =>
      super.copyWith((message) => updates(message as SongDNA)) as SongDNA;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SongDNA() / SongDNA.new instead')
  static SongDNA create() => SongDNA._();
  static $pb.GeneratedMessage $_createMessage() => SongDNA._();
  @$core.override
  SongDNA createEmptyInstance() => SongDNA._();
  @$core.pragma('dart2js:noInline')
  static SongDNA getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SongDNA>(SongDNA.$_createMessage);
  static SongDNA? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get entityUri => $_getSZ(0);
  @$pb.TagNumber(1)
  set entityUri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEntityUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearEntityUri() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get uris => $_getList(1);
}

class Polls extends $pb.GeneratedMessage {
  factory Polls({
    $core.String? pollId,
  }) {
    final result = Polls._();
    if (pollId != null) result.pollId = pollId;
    return result;
  }

  Polls._();

  factory Polls.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Polls()..mergeFromBuffer(data, registry);
  factory Polls.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Polls()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Polls',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: Polls.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pollId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Polls clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Polls copyWith(void Function(Polls) updates) =>
      super.copyWith((message) => updates(message as Polls)) as Polls;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Polls() / Polls.new instead')
  static Polls create() => Polls._();
  static $pb.GeneratedMessage $_createMessage() => Polls._();
  @$core.override
  Polls createEmptyInstance() => Polls._();
  @$core.pragma('dart2js:noInline')
  static Polls getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Polls>(Polls.$_createMessage);
  static Polls? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pollId => $_getSZ(0);
  @$pb.TagNumber(1)
  set pollId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPollId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPollId() => $_clearField(1);
}

class Comments extends $pb.GeneratedMessage {
  factory Comments({
    $core.String? commentId,
  }) {
    final result = Comments._();
    if (commentId != null) result.commentId = commentId;
    return result;
  }

  Comments._();

  factory Comments.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Comments()..mergeFromBuffer(data, registry);
  factory Comments.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Comments()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Comments',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: Comments.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'commentId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Comments clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Comments copyWith(void Function(Comments) updates) =>
      super.copyWith((message) => updates(message as Comments)) as Comments;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Comments() / Comments.new instead')
  static Comments create() => Comments._();
  static $pb.GeneratedMessage $_createMessage() => Comments._();
  @$core.override
  Comments createEmptyInstance() => Comments._();
  @$core.pragma('dart2js:noInline')
  static Comments getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Comments>(Comments.$_createMessage);
  static Comments? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get commentId => $_getSZ(0);
  @$pb.TagNumber(1)
  set commentId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCommentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCommentId() => $_clearField(1);
}

class Chapters extends $pb.GeneratedMessage {
  factory Chapters({
    $core.String? uri,
    $core.String? title,
  }) {
    final result = Chapters._();
    if (uri != null) result.uri = uri;
    if (title != null) result.title = title;
    return result;
  }

  Chapters._();

  factory Chapters.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Chapters()..mergeFromBuffer(data, registry);
  factory Chapters.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Chapters()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Chapters',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: Chapters.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'uri')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Chapters clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Chapters copyWith(void Function(Chapters) updates) =>
      super.copyWith((message) => updates(message as Chapters)) as Chapters;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Chapters() / Chapters.new instead')
  static Chapters create() => Chapters._();
  static $pb.GeneratedMessage $_createMessage() => Chapters._();
  @$core.override
  Chapters createEmptyInstance() => Chapters._();
  @$core.pragma('dart2js:noInline')
  static Chapters getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Chapters>(Chapters.$_createMessage);
  static Chapters? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uri => $_getSZ(0);
  @$pb.TagNumber(1)
  set uri($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUri() => $_has(0);
  @$pb.TagNumber(1)
  void clearUri() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);
}

enum Section_SectionType {
  comments,
  creatorBio,
  discoveryFeed,
  credits,
  lyrics,
  merch,
  liveEvents,
  chapters,
  polls,
  songDna,
  notSet
}

class Section extends $pb.GeneratedMessage {
  factory Section({
    Comments? comments,
    CreatorBio? creatorBio,
    DiscoveryFeed? discoveryFeed,
    Credits? credits,
    Lyrics? lyrics,
    Merch? merch,
    LiveEvents? liveEvents,
    Chapters? chapters,
    Polls? polls,
    SectionInfo? sectionInfo,
    SongDNA? songDna,
  }) {
    final result = Section._();
    if (comments != null) result.comments = comments;
    if (creatorBio != null) result.creatorBio = creatorBio;
    if (discoveryFeed != null) result.discoveryFeed = discoveryFeed;
    if (credits != null) result.credits = credits;
    if (lyrics != null) result.lyrics = lyrics;
    if (merch != null) result.merch = merch;
    if (liveEvents != null) result.liveEvents = liveEvents;
    if (chapters != null) result.chapters = chapters;
    if (polls != null) result.polls = polls;
    if (sectionInfo != null) result.sectionInfo = sectionInfo;
    if (songDna != null) result.songDna = songDna;
    return result;
  }

  Section._();

  factory Section.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Section()..mergeFromBuffer(data, registry);
  factory Section.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Section()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Section_SectionType>
      _Section_SectionTypeByTag = {
    1: Section_SectionType.comments,
    2: Section_SectionType.creatorBio,
    3: Section_SectionType.discoveryFeed,
    4: Section_SectionType.credits,
    5: Section_SectionType.lyrics,
    6: Section_SectionType.merch,
    11: Section_SectionType.liveEvents,
    16: Section_SectionType.chapters,
    21: Section_SectionType.polls,
    27: Section_SectionType.songDna,
    0: Section_SectionType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Section',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.scrollsita.v1'),
      createEmptyInstance: Section.$_createMessage)
    ..oo(0, [1, 2, 3, 4, 5, 6, 11, 16, 21, 27])
    ..aOM<Comments>(1, _omitFieldNames ? '' : 'comments',
        subBuilder: Comments.$_createMessage)
    ..aOM<CreatorBio>(2, _omitFieldNames ? '' : 'creatorBio',
        subBuilder: CreatorBio.$_createMessage)
    ..aOM<DiscoveryFeed>(3, _omitFieldNames ? '' : 'discoveryFeed',
        subBuilder: DiscoveryFeed.$_createMessage)
    ..aOM<Credits>(4, _omitFieldNames ? '' : 'credits',
        subBuilder: Credits.$_createMessage)
    ..aOM<Lyrics>(5, _omitFieldNames ? '' : 'lyrics',
        subBuilder: Lyrics.$_createMessage)
    ..aOM<Merch>(6, _omitFieldNames ? '' : 'merch',
        subBuilder: Merch.$_createMessage)
    ..aOM<LiveEvents>(11, _omitFieldNames ? '' : 'liveEvents',
        subBuilder: LiveEvents.$_createMessage)
    ..aOM<Chapters>(16, _omitFieldNames ? '' : 'chapters',
        subBuilder: Chapters.$_createMessage)
    ..aOM<Polls>(21, _omitFieldNames ? '' : 'polls',
        subBuilder: Polls.$_createMessage)
    ..aOM<SectionInfo>(23, _omitFieldNames ? '' : 'sectionInfo',
        subBuilder: SectionInfo.$_createMessage)
    ..aOM<SongDNA>(27, _omitFieldNames ? '' : 'songDna',
        subBuilder: SongDNA.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Section clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Section copyWith(void Function(Section) updates) =>
      super.copyWith((message) => updates(message as Section)) as Section;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Section() / Section.new instead')
  static Section create() => Section._();
  static $pb.GeneratedMessage $_createMessage() => Section._();
  @$core.override
  Section createEmptyInstance() => Section._();
  @$core.pragma('dart2js:noInline')
  static Section getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Section>(Section.$_createMessage);
  static Section? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(11)
  @$pb.TagNumber(16)
  @$pb.TagNumber(21)
  @$pb.TagNumber(27)
  Section_SectionType whichSectionType() =>
      _Section_SectionTypeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(11)
  @$pb.TagNumber(16)
  @$pb.TagNumber(21)
  @$pb.TagNumber(27)
  void clearSectionType() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Comments get comments => $_getN(0);
  @$pb.TagNumber(1)
  set comments(Comments value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasComments() => $_has(0);
  @$pb.TagNumber(1)
  void clearComments() => $_clearField(1);
  @$pb.TagNumber(1)
  Comments ensureComments() => $_ensure(0);

  @$pb.TagNumber(2)
  CreatorBio get creatorBio => $_getN(1);
  @$pb.TagNumber(2)
  set creatorBio(CreatorBio value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCreatorBio() => $_has(1);
  @$pb.TagNumber(2)
  void clearCreatorBio() => $_clearField(2);
  @$pb.TagNumber(2)
  CreatorBio ensureCreatorBio() => $_ensure(1);

  @$pb.TagNumber(3)
  DiscoveryFeed get discoveryFeed => $_getN(2);
  @$pb.TagNumber(3)
  set discoveryFeed(DiscoveryFeed value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDiscoveryFeed() => $_has(2);
  @$pb.TagNumber(3)
  void clearDiscoveryFeed() => $_clearField(3);
  @$pb.TagNumber(3)
  DiscoveryFeed ensureDiscoveryFeed() => $_ensure(2);

  @$pb.TagNumber(4)
  Credits get credits => $_getN(3);
  @$pb.TagNumber(4)
  set credits(Credits value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCredits() => $_has(3);
  @$pb.TagNumber(4)
  void clearCredits() => $_clearField(4);
  @$pb.TagNumber(4)
  Credits ensureCredits() => $_ensure(3);

  @$pb.TagNumber(5)
  Lyrics get lyrics => $_getN(4);
  @$pb.TagNumber(5)
  set lyrics(Lyrics value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasLyrics() => $_has(4);
  @$pb.TagNumber(5)
  void clearLyrics() => $_clearField(5);
  @$pb.TagNumber(5)
  Lyrics ensureLyrics() => $_ensure(4);

  @$pb.TagNumber(6)
  Merch get merch => $_getN(5);
  @$pb.TagNumber(6)
  set merch(Merch value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasMerch() => $_has(5);
  @$pb.TagNumber(6)
  void clearMerch() => $_clearField(6);
  @$pb.TagNumber(6)
  Merch ensureMerch() => $_ensure(5);

  @$pb.TagNumber(11)
  LiveEvents get liveEvents => $_getN(6);
  @$pb.TagNumber(11)
  set liveEvents(LiveEvents value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasLiveEvents() => $_has(6);
  @$pb.TagNumber(11)
  void clearLiveEvents() => $_clearField(11);
  @$pb.TagNumber(11)
  LiveEvents ensureLiveEvents() => $_ensure(6);

  @$pb.TagNumber(16)
  Chapters get chapters => $_getN(7);
  @$pb.TagNumber(16)
  set chapters(Chapters value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasChapters() => $_has(7);
  @$pb.TagNumber(16)
  void clearChapters() => $_clearField(16);
  @$pb.TagNumber(16)
  Chapters ensureChapters() => $_ensure(7);

  @$pb.TagNumber(21)
  Polls get polls => $_getN(8);
  @$pb.TagNumber(21)
  set polls(Polls value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasPolls() => $_has(8);
  @$pb.TagNumber(21)
  void clearPolls() => $_clearField(21);
  @$pb.TagNumber(21)
  Polls ensurePolls() => $_ensure(8);

  @$pb.TagNumber(23)
  SectionInfo get sectionInfo => $_getN(9);
  @$pb.TagNumber(23)
  set sectionInfo(SectionInfo value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasSectionInfo() => $_has(9);
  @$pb.TagNumber(23)
  void clearSectionInfo() => $_clearField(23);
  @$pb.TagNumber(23)
  SectionInfo ensureSectionInfo() => $_ensure(9);

  @$pb.TagNumber(27)
  SongDNA get songDna => $_getN(10);
  @$pb.TagNumber(27)
  set songDna(SongDNA value) => $_setField(27, value);
  @$pb.TagNumber(27)
  $core.bool hasSongDna() => $_has(10);
  @$pb.TagNumber(27)
  void clearSongDna() => $_clearField(27);
  @$pb.TagNumber(27)
  SongDNA ensureSongDna() => $_ensure(10);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
