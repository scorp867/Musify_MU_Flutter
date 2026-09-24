// This is a generated file - do not edit.
//
// Generated from spotify/traits/shortcuts_card_trait.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ShortcutsCardTrait extends $pb.GeneratedMessage {
  factory ShortcutsCardTrait({
    $core.String? imageUrl,
    $core.String? title,
    $core.String? navigationUri,
    $core.String? entityUri,
  }) {
    final result = ShortcutsCardTrait._();
    if (imageUrl != null) result.imageUrl = imageUrl;
    if (title != null) result.title = title;
    if (navigationUri != null) result.navigationUri = navigationUri;
    if (entityUri != null) result.entityUri = entityUri;
    return result;
  }

  ShortcutsCardTrait._();

  factory ShortcutsCardTrait.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ShortcutsCardTrait()..mergeFromBuffer(data, registry);
  factory ShortcutsCardTrait.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ShortcutsCardTrait()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShortcutsCardTrait',
      package: const $pb.PackageName(_omitMessageNames
          ? ''
          : 'spotify.extendedmetadata.extensions.shortcutscardtrait'),
      createEmptyInstance: ShortcutsCardTrait.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'imageUrl')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'navigationUri')
    ..aOS(4, _omitFieldNames ? '' : 'entityUri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShortcutsCardTrait clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShortcutsCardTrait copyWith(void Function(ShortcutsCardTrait) updates) =>
      super.copyWith((message) => updates(message as ShortcutsCardTrait))
          as ShortcutsCardTrait;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ShortcutsCardTrait() / ShortcutsCardTrait.new instead')
  static ShortcutsCardTrait create() => ShortcutsCardTrait._();
  static $pb.GeneratedMessage $_createMessage() => ShortcutsCardTrait._();
  @$core.override
  ShortcutsCardTrait createEmptyInstance() => ShortcutsCardTrait._();
  @$core.pragma('dart2js:noInline')
  static ShortcutsCardTrait getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ShortcutsCardTrait>(
          ShortcutsCardTrait.$_createMessage);
  static ShortcutsCardTrait? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get imageUrl => $_getSZ(0);
  @$pb.TagNumber(1)
  set imageUrl($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasImageUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearImageUrl() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get navigationUri => $_getSZ(2);
  @$pb.TagNumber(3)
  set navigationUri($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNavigationUri() => $_has(2);
  @$pb.TagNumber(3)
  void clearNavigationUri() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get entityUri => $_getSZ(3);
  @$pb.TagNumber(4)
  set entityUri($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEntityUri() => $_has(3);
  @$pb.TagNumber(4)
  void clearEntityUri() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
