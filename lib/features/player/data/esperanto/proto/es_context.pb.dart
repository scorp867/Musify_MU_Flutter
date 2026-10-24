// This is a generated file - do not edit.
//
// Generated from es_context.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'es_context_page.pb.dart' as $0;
import 'es_restrictions.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Context extends $pb.GeneratedMessage {
  factory Context({
    $core.Iterable<$0.ContextPage>? pages,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? metadata,
    $core.String? uri,
    $core.String? url,
    $core.bool? isLoading,
    $1.Restrictions? restrictions,
  }) {
    final result = Context._();
    if (pages != null) result.pages.addAll(pages);
    if (metadata != null) result.metadata.addEntries(metadata);
    if (uri != null) result.uri = uri;
    if (url != null) result.url = url;
    if (isLoading != null) result.isLoading = isLoading;
    if (restrictions != null) result.restrictions = restrictions;
    return result;
  }

  Context._();

  factory Context.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Context()..mergeFromBuffer(data, registry);
  factory Context.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Context()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Context',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'spotify.player.esperanto.proto'),
      createEmptyInstance: Context.$_createMessage)
    ..pPM<$0.ContextPage>(1, _omitFieldNames ? '' : 'pages',
        subBuilder: $0.ContextPage.$_createMessage)
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'metadata',
        entryClassName: 'Context.MetadataEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('spotify.player.esperanto.proto'))
    ..aOS(3, _omitFieldNames ? '' : 'uri')
    ..aOS(4, _omitFieldNames ? '' : 'url')
    ..aOB(5, _omitFieldNames ? '' : 'isLoading')
    ..aOM<$1.Restrictions>(6, _omitFieldNames ? '' : 'restrictions',
        subBuilder: $1.Restrictions.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Context clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Context copyWith(void Function(Context) updates) =>
      super.copyWith((message) => updates(message as Context)) as Context;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Context() / Context.new instead')
  static Context create() => Context._();
  static $pb.GeneratedMessage $_createMessage() => Context._();
  @$core.override
  Context createEmptyInstance() => Context._();
  @$core.pragma('dart2js:noInline')
  static Context getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Context>(Context.$_createMessage);
  static Context? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.ContextPage> get pages => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get metadata => $_getMap(1);

  @$pb.TagNumber(3)
  $core.String get uri => $_getSZ(2);
  @$pb.TagNumber(3)
  set uri($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUri() => $_has(2);
  @$pb.TagNumber(3)
  void clearUri() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get url => $_getSZ(3);
  @$pb.TagNumber(4)
  set url($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isLoading => $_getBF(4);
  @$pb.TagNumber(5)
  set isLoading($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsLoading() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsLoading() => $_clearField(5);

  @$pb.TagNumber(6)
  $1.Restrictions get restrictions => $_getN(5);
  @$pb.TagNumber(6)
  set restrictions($1.Restrictions value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRestrictions() => $_has(5);
  @$pb.TagNumber(6)
  void clearRestrictions() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.Restrictions ensureRestrictions() => $_ensure(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
