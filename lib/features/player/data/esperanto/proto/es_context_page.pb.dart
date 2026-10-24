// This is a generated file - do not edit.
//
// Generated from es_context_page.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'es_context_track.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ContextPage extends $pb.GeneratedMessage {
  factory ContextPage({
    $core.Iterable<$0.ContextTrack>? tracks,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? metadata,
    $core.String? pageUrl,
    $core.String? nextPageUrl,
    $core.bool? isLoading,
  }) {
    final result = ContextPage._();
    if (tracks != null) result.tracks.addAll(tracks);
    if (metadata != null) result.metadata.addEntries(metadata);
    if (pageUrl != null) result.pageUrl = pageUrl;
    if (nextPageUrl != null) result.nextPageUrl = nextPageUrl;
    if (isLoading != null) result.isLoading = isLoading;
    return result;
  }

  ContextPage._();

  factory ContextPage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContextPage()..mergeFromBuffer(data, registry);
  factory ContextPage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ContextPage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextPage',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: ContextPage.$_createMessage)
    ..pPM<$0.ContextTrack>(1, _omitFieldNames ? '' : 'tracks',
        subBuilder: $0.ContextTrack.$_createMessage)
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'metadata',
        entryClassName: 'ContextPage.MetadataEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('spotify.player.esperanto.proto'))
    ..aOS(3, _omitFieldNames ? '' : 'pageUrl')
    ..aOS(4, _omitFieldNames ? '' : 'nextPageUrl')
    ..aOB(5, _omitFieldNames ? '' : 'isLoading')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextPage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextPage copyWith(void Function(ContextPage) updates) =>
      super.copyWith((message) => updates(message as ContextPage))
          as ContextPage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ContextPage() / ContextPage.new instead')
  static ContextPage create() => ContextPage._();
  static $pb.GeneratedMessage $_createMessage() => ContextPage._();
  @$core.override
  ContextPage createEmptyInstance() => ContextPage._();
  @$core.pragma('dart2js:noInline')
  static ContextPage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ContextPage>(
          ContextPage.$_createMessage);
  static ContextPage? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.ContextTrack> get tracks => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get metadata => $_getMap(1);

  @$pb.TagNumber(3)
  $core.String get pageUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set pageUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPageUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearPageUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get nextPageUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set nextPageUrl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNextPageUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearNextPageUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isLoading => $_getBF(4);
  @$pb.TagNumber(5)
  set isLoading($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsLoading() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsLoading() => $_clearField(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
