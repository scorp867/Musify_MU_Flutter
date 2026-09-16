// This is a generated file - do not edit.
//
// Generated from spotify/casita_true.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use casitaResponseDescriptor instead')
const CasitaResponse$json = {
  '1': 'CasitaResponse',
  '2': [
    {
      '1': 'sections',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.CasitaSections',
      '10': 'sections'
    },
    {
      '1': 'repository',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.CasitaRepository',
      '10': 'repository'
    },
    {
      '1': 'page_meta',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.CasitaPageMeta',
      '10': 'pageMeta'
    },
    {
      '1': 'mix_uris',
      '3': 999,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.CasitaMixUri',
      '10': 'mixUris'
    },
  ],
};

/// Descriptor for `CasitaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List casitaResponseDescriptor = $convert.base64Decode(
    'Cg5DYXNpdGFSZXNwb25zZRI6CghzZWN0aW9ucxgBIAEoCzIeLnNwb3RpZnkuY2FzaXRhLkNhc2'
    'l0YVNlY3Rpb25zUghzZWN0aW9ucxJACgpyZXBvc2l0b3J5GAIgASgLMiAuc3BvdGlmeS5jYXNp'
    'dGEuQ2FzaXRhUmVwb3NpdG9yeVIKcmVwb3NpdG9yeRI7CglwYWdlX21ldGEYAyABKAsyHi5zcG'
    '90aWZ5LmNhc2l0YS5DYXNpdGFQYWdlTWV0YVIIcGFnZU1ldGESOAoIbWl4X3VyaXMY5wcgAygL'
    'Mhwuc3BvdGlmeS5jYXNpdGEuQ2FzaXRhTWl4VXJpUgdtaXhVcmlz');

@$core.Deprecated('Use casitaSectionsDescriptor instead')
const CasitaSections$json = {
  '1': 'CasitaSections',
  '2': [
    {
      '1': 'sections',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.CasitaSection',
      '10': 'sections'
    },
  ],
};

/// Descriptor for `CasitaSections`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List casitaSectionsDescriptor = $convert.base64Decode(
    'Cg5DYXNpdGFTZWN0aW9ucxI5CghzZWN0aW9ucxgBIAMoCzIdLnNwb3RpZnkuY2FzaXRhLkNhc2'
    'l0YVNlY3Rpb25SCHNlY3Rpb25z');

@$core.Deprecated('Use casitaSectionDescriptor instead')
const CasitaSection$json = {
  '1': 'CasitaSection',
  '2': [
    {
      '1': 'id_wrapper',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.SectionIdWrapper',
      '10': 'idWrapper'
    },
    {
      '1': 'body_shortcuts',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.SectionBodyShortcuts',
      '10': 'bodyShortcuts'
    },
    {
      '1': 'body_standard',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.SectionBodyStandard',
      '10': 'bodyStandard'
    },
    {
      '1': 'body_podcast',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.SectionBodyPodcast',
      '10': 'bodyPodcast'
    },
    {
      '1': 'body_musicfeed',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.SectionBodyMusicfeed',
      '10': 'bodyMusicfeed'
    },
    {
      '1': 'body_recents',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.SectionBodyRecents',
      '10': 'bodyRecents'
    },
  ],
};

/// Descriptor for `CasitaSection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List casitaSectionDescriptor = $convert.base64Decode(
    'Cg1DYXNpdGFTZWN0aW9uEj8KCmlkX3dyYXBwZXIYASABKAsyIC5zcG90aWZ5LmNhc2l0YS5TZW'
    'N0aW9uSWRXcmFwcGVyUglpZFdyYXBwZXISSwoOYm9keV9zaG9ydGN1dHMYAiABKAsyJC5zcG90'
    'aWZ5LmNhc2l0YS5TZWN0aW9uQm9keVNob3J0Y3V0c1INYm9keVNob3J0Y3V0cxJICg1ib2R5X3'
    'N0YW5kYXJkGAMgASgLMiMuc3BvdGlmeS5jYXNpdGEuU2VjdGlvbkJvZHlTdGFuZGFyZFIMYm9k'
    'eVN0YW5kYXJkEkUKDGJvZHlfcG9kY2FzdBgEIAEoCzIiLnNwb3RpZnkuY2FzaXRhLlNlY3Rpb2'
    '5Cb2R5UG9kY2FzdFILYm9keVBvZGNhc3QSSwoOYm9keV9tdXNpY2ZlZWQYBiABKAsyJC5zcG90'
    'aWZ5LmNhc2l0YS5TZWN0aW9uQm9keU11c2ljZmVlZFINYm9keU11c2ljZmVlZBJFCgxib2R5X3'
    'JlY2VudHMYCiABKAsyIi5zcG90aWZ5LmNhc2l0YS5TZWN0aW9uQm9keVJlY2VudHNSC2JvZHlS'
    'ZWNlbnRz');

@$core.Deprecated('Use sectionIdWrapperDescriptor instead')
const SectionIdWrapper$json = {
  '1': 'SectionIdWrapper',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `SectionIdWrapper`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionIdWrapperDescriptor =
    $convert.base64Decode('ChBTZWN0aW9uSWRXcmFwcGVyEg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use sectionBodyShortcutsDescriptor instead')
const SectionBodyShortcuts$json = {
  '1': 'SectionBodyShortcuts',
  '2': [
    {
      '1': 'items_container',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.ShortcutsItemsContainer',
      '10': 'itemsContainer'
    },
  ],
};

/// Descriptor for `SectionBodyShortcuts`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionBodyShortcutsDescriptor = $convert.base64Decode(
    'ChRTZWN0aW9uQm9keVNob3J0Y3V0cxJQCg9pdGVtc19jb250YWluZXIYAiABKAsyJy5zcG90aW'
    'Z5LmNhc2l0YS5TaG9ydGN1dHNJdGVtc0NvbnRhaW5lclIOaXRlbXNDb250YWluZXI=');

@$core.Deprecated('Use shortcutsItemsContainerDescriptor instead')
const ShortcutsItemsContainer$json = {
  '1': 'ShortcutsItemsContainer',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.SectionItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ShortcutsItemsContainer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List shortcutsItemsContainerDescriptor =
    $convert.base64Decode(
        'ChdTaG9ydGN1dHNJdGVtc0NvbnRhaW5lchIxCgVpdGVtcxgBIAMoCzIbLnNwb3RpZnkuY2FzaX'
        'RhLlNlY3Rpb25JdGVtUgVpdGVtcw==');

@$core.Deprecated('Use sectionBodyStandardDescriptor instead')
const SectionBodyStandard$json = {
  '1': 'SectionBodyStandard',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.SectionHeader',
      '10': 'header'
    },
    {
      '1': 'items_container',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.StandardItemsContainer',
      '10': 'itemsContainer'
    },
  ],
};

/// Descriptor for `SectionBodyStandard`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionBodyStandardDescriptor = $convert.base64Decode(
    'ChNTZWN0aW9uQm9keVN0YW5kYXJkEjUKBmhlYWRlchgBIAEoCzIdLnNwb3RpZnkuY2FzaXRhLl'
    'NlY3Rpb25IZWFkZXJSBmhlYWRlchJPCg9pdGVtc19jb250YWluZXIYAiABKAsyJi5zcG90aWZ5'
    'LmNhc2l0YS5TdGFuZGFyZEl0ZW1zQ29udGFpbmVyUg5pdGVtc0NvbnRhaW5lcg==');

@$core.Deprecated('Use sectionHeaderDescriptor instead')
const SectionHeader$json = {
  '1': 'SectionHeader',
  '2': [
    {
      '1': 'title_wrapper',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.SectionTitleWrapper',
      '10': 'titleWrapper'
    },
    {
      '1': 'template_wrapper',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.SectionTemplateWrapper',
      '10': 'templateWrapper'
    },
  ],
};

/// Descriptor for `SectionHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionHeaderDescriptor = $convert.base64Decode(
    'Cg1TZWN0aW9uSGVhZGVyEkgKDXRpdGxlX3dyYXBwZXIYAiABKAsyIy5zcG90aWZ5LmNhc2l0YS'
    '5TZWN0aW9uVGl0bGVXcmFwcGVyUgx0aXRsZVdyYXBwZXISUQoQdGVtcGxhdGVfd3JhcHBlchgD'
    'IAEoCzImLnNwb3RpZnkuY2FzaXRhLlNlY3Rpb25UZW1wbGF0ZVdyYXBwZXJSD3RlbXBsYXRlV3'
    'JhcHBlcg==');

@$core.Deprecated('Use sectionTitleWrapperDescriptor instead')
const SectionTitleWrapper$json = {
  '1': 'SectionTitleWrapper',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
  ],
};

/// Descriptor for `SectionTitleWrapper`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionTitleWrapperDescriptor =
    $convert.base64Decode(
        'ChNTZWN0aW9uVGl0bGVXcmFwcGVyEhQKBXRpdGxlGAEgASgJUgV0aXRsZQ==');

@$core.Deprecated('Use sectionTemplateWrapperDescriptor instead')
const SectionTemplateWrapper$json = {
  '1': 'SectionTemplateWrapper',
  '2': [
    {'1': 'template', '3': 1, '4': 1, '5': 9, '10': 'template'},
    {
      '1': 'params',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.SectionTemplateParams',
      '10': 'params'
    },
  ],
};

/// Descriptor for `SectionTemplateWrapper`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionTemplateWrapperDescriptor = $convert.base64Decode(
    'ChZTZWN0aW9uVGVtcGxhdGVXcmFwcGVyEhoKCHRlbXBsYXRlGAEgASgJUgh0ZW1wbGF0ZRI9Cg'
    'ZwYXJhbXMYAiABKAsyJS5zcG90aWZ5LmNhc2l0YS5TZWN0aW9uVGVtcGxhdGVQYXJhbXNSBnBh'
    'cmFtcw==');

@$core.Deprecated('Use sectionTemplateParamsDescriptor instead')
const SectionTemplateParams$json = {
  '1': 'SectionTemplateParams',
  '2': [
    {'1': 'artist_name', '3': 1, '4': 1, '5': 9, '10': 'artistName'},
  ],
};

/// Descriptor for `SectionTemplateParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionTemplateParamsDescriptor = $convert.base64Decode(
    'ChVTZWN0aW9uVGVtcGxhdGVQYXJhbXMSHwoLYXJ0aXN0X25hbWUYASABKAlSCmFydGlzdE5hbW'
    'U=');

@$core.Deprecated('Use standardItemsContainerDescriptor instead')
const StandardItemsContainer$json = {
  '1': 'StandardItemsContainer',
  '2': [
    {
      '1': 'items_wrapper',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.SectionItemWrapper',
      '10': 'itemsWrapper'
    },
  ],
};

/// Descriptor for `StandardItemsContainer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List standardItemsContainerDescriptor =
    $convert.base64Decode(
        'ChZTdGFuZGFyZEl0ZW1zQ29udGFpbmVyEkcKDWl0ZW1zX3dyYXBwZXIYASADKAsyIi5zcG90aW'
        'Z5LmNhc2l0YS5TZWN0aW9uSXRlbVdyYXBwZXJSDGl0ZW1zV3JhcHBlcg==');

@$core.Deprecated('Use sectionItemWrapperDescriptor instead')
const SectionItemWrapper$json = {
  '1': 'SectionItemWrapper',
  '2': [
    {
      '1': 'item',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.SectionItem',
      '10': 'item'
    },
  ],
};

/// Descriptor for `SectionItemWrapper`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionItemWrapperDescriptor = $convert.base64Decode(
    'ChJTZWN0aW9uSXRlbVdyYXBwZXISLwoEaXRlbRgBIAEoCzIbLnNwb3RpZnkuY2FzaXRhLlNlY3'
    'Rpb25JdGVtUgRpdGVt');

@$core.Deprecated('Use sectionItemDescriptor instead')
const SectionItem$json = {
  '1': 'SectionItem',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
  ],
};

/// Descriptor for `SectionItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionItemDescriptor =
    $convert.base64Decode('CgtTZWN0aW9uSXRlbRIQCgN1cmkYASABKAlSA3VyaQ==');

@$core.Deprecated('Use sectionBodyPodcastDescriptor instead')
const SectionBodyPodcast$json = {
  '1': 'SectionBodyPodcast',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.SectionHeader',
      '10': 'header'
    },
    {
      '1': 'items_container',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.PodcastItemsContainer',
      '10': 'itemsContainer'
    },
  ],
};

/// Descriptor for `SectionBodyPodcast`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionBodyPodcastDescriptor = $convert.base64Decode(
    'ChJTZWN0aW9uQm9keVBvZGNhc3QSNQoGaGVhZGVyGAEgASgLMh0uc3BvdGlmeS5jYXNpdGEuU2'
    'VjdGlvbkhlYWRlclIGaGVhZGVyEk4KD2l0ZW1zX2NvbnRhaW5lchgCIAEoCzIlLnNwb3RpZnku'
    'Y2FzaXRhLlBvZGNhc3RJdGVtc0NvbnRhaW5lclIOaXRlbXNDb250YWluZXI=');

@$core.Deprecated('Use podcastItemsContainerDescriptor instead')
const PodcastItemsContainer$json = {
  '1': 'PodcastItemsContainer',
  '2': [
    {'1': 'show_uri', '3': 1, '4': 1, '5': 9, '10': 'showUri'},
    {'1': 'episode_uri', '3': 2, '4': 1, '5': 9, '10': 'episodeUri'},
  ],
};

/// Descriptor for `PodcastItemsContainer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List podcastItemsContainerDescriptor = $convert.base64Decode(
    'ChVQb2RjYXN0SXRlbXNDb250YWluZXISGQoIc2hvd191cmkYASABKAlSB3Nob3dVcmkSHwoLZX'
    'Bpc29kZV91cmkYAiABKAlSCmVwaXNvZGVVcmk=');

@$core.Deprecated('Use sectionBodyMusicfeedDescriptor instead')
const SectionBodyMusicfeed$json = {
  '1': 'SectionBodyMusicfeed',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.SectionHeader',
      '10': 'header'
    },
    {
      '1': 'items_container',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.MusicfeedItemsContainer',
      '10': 'itemsContainer'
    },
  ],
};

/// Descriptor for `SectionBodyMusicfeed`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionBodyMusicfeedDescriptor = $convert.base64Decode(
    'ChRTZWN0aW9uQm9keU11c2ljZmVlZBI1CgZoZWFkZXIYASABKAsyHS5zcG90aWZ5LmNhc2l0YS'
    '5TZWN0aW9uSGVhZGVyUgZoZWFkZXISUAoPaXRlbXNfY29udGFpbmVyGAIgASgLMicuc3BvdGlm'
    'eS5jYXNpdGEuTXVzaWNmZWVkSXRlbXNDb250YWluZXJSDml0ZW1zQ29udGFpbmVy');

@$core.Deprecated('Use musicfeedItemsContainerDescriptor instead')
const MusicfeedItemsContainer$json = {
  '1': 'MusicfeedItemsContainer',
  '2': [
    {'1': 'playlist_uri', '3': 1, '4': 1, '5': 9, '10': 'playlistUri'},
  ],
};

/// Descriptor for `MusicfeedItemsContainer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List musicfeedItemsContainerDescriptor =
    $convert.base64Decode(
        'ChdNdXNpY2ZlZWRJdGVtc0NvbnRhaW5lchIhCgxwbGF5bGlzdF91cmkYASABKAlSC3BsYXlsaX'
        'N0VXJp');

@$core.Deprecated('Use sectionBodyRecentsDescriptor instead')
const SectionBodyRecents$json = {
  '1': 'SectionBodyRecents',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.SectionHeader',
      '10': 'header'
    },
  ],
};

/// Descriptor for `SectionBodyRecents`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionBodyRecentsDescriptor = $convert.base64Decode(
    'ChJTZWN0aW9uQm9keVJlY2VudHMSNQoGaGVhZGVyGAEgASgLMh0uc3BvdGlmeS5jYXNpdGEuU2'
    'VjdGlvbkhlYWRlclIGaGVhZGVy');

@$core.Deprecated('Use casitaRepositoryDescriptor instead')
const CasitaRepository$json = {
  '1': 'CasitaRepository',
  '2': [
    {
      '1': 'inner',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.CasitaRepositoryInner',
      '10': 'inner'
    },
  ],
};

/// Descriptor for `CasitaRepository`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List casitaRepositoryDescriptor = $convert.base64Decode(
    'ChBDYXNpdGFSZXBvc2l0b3J5EjsKBWlubmVyGAEgASgLMiUuc3BvdGlmeS5jYXNpdGEuQ2FzaX'
    'RhUmVwb3NpdG9yeUlubmVyUgVpbm5lcg==');

@$core.Deprecated('Use casitaRepositoryInnerDescriptor instead')
const CasitaRepositoryInner$json = {
  '1': 'CasitaRepositoryInner',
  '2': [
    {
      '1': 'blocks',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.CasitaRepositoryBlock',
      '10': 'blocks'
    },
  ],
};

/// Descriptor for `CasitaRepositoryInner`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List casitaRepositoryInnerDescriptor = $convert.base64Decode(
    'ChVDYXNpdGFSZXBvc2l0b3J5SW5uZXISPQoGYmxvY2tzGAIgAygLMiUuc3BvdGlmeS5jYXNpdG'
    'EuQ2FzaXRhUmVwb3NpdG9yeUJsb2NrUgZibG9ja3M=');

@$core.Deprecated('Use casitaRepositoryBlockDescriptor instead')
const CasitaRepositoryBlock$json = {
  '1': 'CasitaRepositoryBlock',
  '2': [
    {
      '1': 'entries',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.CasitaRepositoryEntry',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `CasitaRepositoryBlock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List casitaRepositoryBlockDescriptor = $convert.base64Decode(
    'ChVDYXNpdGFSZXBvc2l0b3J5QmxvY2sSPwoHZW50cmllcxgDIAMoCzIlLnNwb3RpZnkuY2FzaX'
    'RhLkNhc2l0YVJlcG9zaXRvcnlFbnRyeVIHZW50cmllcw==');

@$core.Deprecated('Use casitaRepositoryEntryDescriptor instead')
const CasitaRepositoryEntry$json = {
  '1': 'CasitaRepositoryEntry',
  '2': [
    {'1': 'uri', '3': 2, '4': 1, '5': 9, '10': 'uri'},
    {
      '1': 'trait_payload',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Any',
      '10': 'traitPayload'
    },
  ],
};

/// Descriptor for `CasitaRepositoryEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List casitaRepositoryEntryDescriptor = $convert.base64Decode(
    'ChVDYXNpdGFSZXBvc2l0b3J5RW50cnkSEAoDdXJpGAIgASgJUgN1cmkSOQoNdHJhaXRfcGF5bG'
    '9hZBgDIAEoCzIULmdvb2dsZS5wcm90b2J1Zi5BbnlSDHRyYWl0UGF5bG9hZA==');

@$core.Deprecated('Use simpleCardTraitDescriptor instead')
const SimpleCardTrait$json = {
  '1': 'SimpleCardTrait',
  '2': [
    {'1': 'image_url', '3': 1, '4': 1, '5': 9, '10': 'imageUrl'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'subtitle', '3': 3, '4': 1, '5': 9, '10': 'subtitle'},
    {'1': 'title_rendered', '3': 6, '4': 1, '5': 9, '10': 'titleRendered'},
  ],
};

/// Descriptor for `SimpleCardTrait`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List simpleCardTraitDescriptor = $convert.base64Decode(
    'Cg9TaW1wbGVDYXJkVHJhaXQSGwoJaW1hZ2VfdXJsGAEgASgJUghpbWFnZVVybBIUCgV0aXRsZR'
    'gCIAEoCVIFdGl0bGUSGgoIc3VidGl0bGUYAyABKAlSCHN1YnRpdGxlEiUKDnRpdGxlX3JlbmRl'
    'cmVkGAYgASgJUg10aXRsZVJlbmRlcmVk');

@$core.Deprecated('Use shortcutsCardTraitDescriptor instead')
const ShortcutsCardTrait$json = {
  '1': 'ShortcutsCardTrait',
  '2': [
    {'1': 'image_url', '3': 1, '4': 1, '5': 9, '10': 'imageUrl'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'context_uri', '3': 3, '4': 1, '5': 9, '10': 'contextUri'},
  ],
};

/// Descriptor for `ShortcutsCardTrait`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List shortcutsCardTraitDescriptor = $convert.base64Decode(
    'ChJTaG9ydGN1dHNDYXJkVHJhaXQSGwoJaW1hZ2VfdXJsGAEgASgJUghpbWFnZVVybBIUCgV0aX'
    'RsZRgCIAEoCVIFdGl0bGUSHwoLY29udGV4dF91cmkYAyABKAlSCmNvbnRleHRVcmk=');

@$core.Deprecated('Use previewCardTraitDescriptor instead')
const PreviewCardTrait$json = {
  '1': 'PreviewCardTrait',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'author', '3': 3, '4': 1, '5': 9, '10': 'author'},
    {'1': 'image_url', '3': 8, '4': 1, '5': 9, '10': 'imageUrl'},
  ],
};

/// Descriptor for `PreviewCardTrait`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewCardTraitDescriptor = $convert.base64Decode(
    'ChBQcmV2aWV3Q2FyZFRyYWl0EhQKBXRpdGxlGAEgASgJUgV0aXRsZRIWCgZhdXRob3IYAyABKA'
    'lSBmF1dGhvchIbCglpbWFnZV91cmwYCCABKAlSCGltYWdlVXJs');

@$core.Deprecated('Use casitaPageMetaDescriptor instead')
const CasitaPageMeta$json = {
  '1': 'CasitaPageMeta',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'page_id', '3': 2, '4': 1, '5': 9, '10': 'pageId'},
  ],
};

/// Descriptor for `CasitaPageMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List casitaPageMetaDescriptor = $convert.base64Decode(
    'Cg5DYXNpdGFQYWdlTWV0YRIQCgN1cmkYASABKAlSA3VyaRIXCgdwYWdlX2lkGAIgASgJUgZwYW'
    'dlSWQ=');

@$core.Deprecated('Use casitaMixUriDescriptor instead')
const CasitaMixUri$json = {
  '1': 'CasitaMixUri',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
  ],
};

/// Descriptor for `CasitaMixUri`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List casitaMixUriDescriptor =
    $convert.base64Decode('CgxDYXNpdGFNaXhVcmkSEAoDdXJpGAEgASgJUgN1cmk=');
