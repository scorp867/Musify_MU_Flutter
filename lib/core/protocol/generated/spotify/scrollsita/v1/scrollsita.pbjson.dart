// This is a generated file - do not edit.
//
// Generated from spotify/scrollsita/v1/scrollsita.proto.

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

@$core.Deprecated('Use npvScrollResponseDescriptor instead')
const NpvScrollResponse$json = {
  '1': 'NpvScrollResponse',
  '2': [
    {
      '1': 'structure',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.scrollsita.v1.NpvScrollStructure',
      '10': 'structure'
    },
    {
      '1': 'response_info',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.scrollsita.v1.ResponseInfo',
      '10': 'responseInfo'
    },
    {
      '1': 'debug_info',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.scrollsita.v1.DebugInfo',
      '10': 'debugInfo'
    },
  ],
};

/// Descriptor for `NpvScrollResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List npvScrollResponseDescriptor = $convert.base64Decode(
    'ChFOcHZTY3JvbGxSZXNwb25zZRJHCglzdHJ1Y3R1cmUYASABKAsyKS5zcG90aWZ5LnNjcm9sbH'
    'NpdGEudjEuTnB2U2Nyb2xsU3RydWN0dXJlUglzdHJ1Y3R1cmUSSAoNcmVzcG9uc2VfaW5mbxgC'
    'IAEoCzIjLnNwb3RpZnkuc2Nyb2xsc2l0YS52MS5SZXNwb25zZUluZm9SDHJlc3BvbnNlSW5mbx'
    'I/CgpkZWJ1Z19pbmZvGAMgASgLMiAuc3BvdGlmeS5zY3JvbGxzaXRhLnYxLkRlYnVnSW5mb1IJ'
    'ZGVidWdJbmZv');

@$core.Deprecated('Use npvScrollStructureDescriptor instead')
const NpvScrollStructure$json = {
  '1': 'NpvScrollStructure',
  '2': [
    {
      '1': 'sections',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.scrollsita.v1.Section',
      '10': 'sections'
    },
  ],
};

/// Descriptor for `NpvScrollStructure`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List npvScrollStructureDescriptor = $convert.base64Decode(
    'ChJOcHZTY3JvbGxTdHJ1Y3R1cmUSOgoIc2VjdGlvbnMYASADKAsyHi5zcG90aWZ5LnNjcm9sbH'
    'NpdGEudjEuU2VjdGlvblIIc2VjdGlvbnM=');

@$core.Deprecated('Use responseInfoDescriptor instead')
const ResponseInfo$json = {
  '1': 'ResponseInfo',
  '2': [
    {'1': 'response_id', '3': 1, '4': 1, '5': 9, '10': 'responseId'},
  ],
};

/// Descriptor for `ResponseInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseInfoDescriptor = $convert.base64Decode(
    'CgxSZXNwb25zZUluZm8SHwoLcmVzcG9uc2VfaWQYASABKAlSCnJlc3BvbnNlSWQ=');

@$core.Deprecated('Use debugInfoDescriptor instead')
const DebugInfo$json = {
  '1': 'DebugInfo',
  '2': [
    {'1': 'debug_message', '3': 1, '4': 1, '5': 9, '10': 'debugMessage'},
  ],
};

/// Descriptor for `DebugInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List debugInfoDescriptor = $convert.base64Decode(
    'CglEZWJ1Z0luZm8SIwoNZGVidWdfbWVzc2FnZRgBIAEoCVIMZGVidWdNZXNzYWdl');

@$core.Deprecated('Use displayConditionDescriptor instead')
const DisplayCondition$json = {
  '1': 'DisplayCondition',
  '2': [
    {'1': 'is_visible', '3': 1, '4': 1, '5': 8, '10': 'isVisible'},
  ],
};

/// Descriptor for `DisplayCondition`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List displayConditionDescriptor = $convert.base64Decode(
    'ChBEaXNwbGF5Q29uZGl0aW9uEh0KCmlzX3Zpc2libGUYASABKAhSCWlzVmlzaWJsZQ==');

@$core.Deprecated('Use sectionInfoDescriptor instead')
const SectionInfo$json = {
  '1': 'SectionInfo',
  '2': [
    {'1': 'section_id', '3': 1, '4': 1, '5': 9, '10': 'sectionId'},
    {
      '1': 'display_condition',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.scrollsita.v1.DisplayCondition',
      '10': 'displayCondition'
    },
  ],
};

/// Descriptor for `SectionInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionInfoDescriptor = $convert.base64Decode(
    'CgtTZWN0aW9uSW5mbxIdCgpzZWN0aW9uX2lkGAEgASgJUglzZWN0aW9uSWQSVAoRZGlzcGxheV'
    '9jb25kaXRpb24YAiABKAsyJy5zcG90aWZ5LnNjcm9sbHNpdGEudjEuRGlzcGxheUNvbmRpdGlv'
    'blIQZGlzcGxheUNvbmRpdGlvbg==');

@$core.Deprecated('Use creatorBioDescriptor instead')
const CreatorBio$json = {
  '1': 'CreatorBio',
  '2': [
    {'1': 'creator_uri', '3': 1, '4': 1, '5': 9, '10': 'creatorUri'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
  ],
};

/// Descriptor for `CreatorBio`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List creatorBioDescriptor = $convert.base64Decode(
    'CgpDcmVhdG9yQmlvEh8KC2NyZWF0b3JfdXJpGAEgASgJUgpjcmVhdG9yVXJpEhQKBXRpdGxlGA'
    'IgASgJUgV0aXRsZQ==');

@$core.Deprecated('Use creditsDescriptor instead')
const Credits$json = {
  '1': 'Credits',
  '2': [
    {'1': 'entity_uri', '3': 1, '4': 1, '5': 9, '10': 'entityUri'},
    {'1': 'contributor_uri', '3': 2, '4': 3, '5': 9, '10': 'contributorUri'},
  ],
};

/// Descriptor for `Credits`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List creditsDescriptor = $convert.base64Decode(
    'CgdDcmVkaXRzEh0KCmVudGl0eV91cmkYASABKAlSCWVudGl0eVVyaRInCg9jb250cmlidXRvcl'
    '91cmkYAiADKAlSDmNvbnRyaWJ1dG9yVXJp');

@$core.Deprecated('Use lyricsDescriptor instead')
const Lyrics$json = {
  '1': 'Lyrics',
  '2': [
    {'1': 'entity_uri', '3': 1, '4': 1, '5': 9, '10': 'entityUri'},
  ],
};

/// Descriptor for `Lyrics`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lyricsDescriptor = $convert
    .base64Decode('CgZMeXJpY3MSHQoKZW50aXR5X3VyaRgBIAEoCVIJZW50aXR5VXJp');

@$core.Deprecated('Use liveEventsDescriptor instead')
const LiveEvents$json = {
  '1': 'LiveEvents',
  '2': [
    {'1': 'concert_uri', '3': 1, '4': 3, '5': 9, '10': 'concertUri'},
    {'1': 'artist_uri', '3': 2, '4': 1, '5': 9, '10': 'artistUri'},
  ],
};

/// Descriptor for `LiveEvents`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List liveEventsDescriptor = $convert.base64Decode(
    'CgpMaXZlRXZlbnRzEh8KC2NvbmNlcnRfdXJpGAEgAygJUgpjb25jZXJ0VXJpEh0KCmFydGlzdF'
    '91cmkYAiABKAlSCWFydGlzdFVyaQ==');

@$core.Deprecated('Use merchDescriptor instead')
const Merch$json = {
  '1': 'Merch',
  '2': [
    {'1': 'entity_uri', '3': 1, '4': 1, '5': 9, '10': 'entityUri'},
  ],
};

/// Descriptor for `Merch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List merchDescriptor = $convert
    .base64Decode('CgVNZXJjaBIdCgplbnRpdHlfdXJpGAEgASgJUgllbnRpdHlVcmk=');

@$core.Deprecated('Use headingDescriptor instead')
const Heading$json = {
  '1': 'Heading',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'format_text', '3': 2, '4': 1, '5': 9, '10': 'formatText'},
  ],
};

/// Descriptor for `Heading`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List headingDescriptor = $convert.base64Decode(
    'CgdIZWFkaW5nEhQKBXRpdGxlGAEgASgJUgV0aXRsZRIfCgtmb3JtYXRfdGV4dBgCIAEoCVIKZm'
    '9ybWF0VGV4dA==');

@$core.Deprecated('Use discoveryFeedDescriptor instead')
const DiscoveryFeed$json = {
  '1': 'DiscoveryFeed',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.scrollsita.v1.Heading',
      '10': 'heading'
    },
    {'1': 'items', '3': 2, '4': 3, '5': 9, '10': 'items'},
  ],
};

/// Descriptor for `DiscoveryFeed`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List discoveryFeedDescriptor = $convert.base64Decode(
    'Cg1EaXNjb3ZlcnlGZWVkEjgKB2hlYWRpbmcYASABKAsyHi5zcG90aWZ5LnNjcm9sbHNpdGEudj'
    'EuSGVhZGluZ1IHaGVhZGluZxIUCgVpdGVtcxgCIAMoCVIFaXRlbXM=');

@$core.Deprecated('Use songDNADescriptor instead')
const SongDNA$json = {
  '1': 'SongDNA',
  '2': [
    {'1': 'entity_uri', '3': 1, '4': 1, '5': 9, '10': 'entityUri'},
    {'1': 'uris', '3': 2, '4': 3, '5': 9, '10': 'uris'},
  ],
};

/// Descriptor for `SongDNA`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List songDNADescriptor = $convert.base64Decode(
    'CgdTb25nRE5BEh0KCmVudGl0eV91cmkYASABKAlSCWVudGl0eVVyaRISCgR1cmlzGAIgAygJUg'
    'R1cmlz');

@$core.Deprecated('Use pollsDescriptor instead')
const Polls$json = {
  '1': 'Polls',
  '2': [
    {'1': 'poll_id', '3': 1, '4': 1, '5': 9, '10': 'pollId'},
  ],
};

/// Descriptor for `Polls`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pollsDescriptor =
    $convert.base64Decode('CgVQb2xscxIXCgdwb2xsX2lkGAEgASgJUgZwb2xsSWQ=');

@$core.Deprecated('Use commentsDescriptor instead')
const Comments$json = {
  '1': 'Comments',
  '2': [
    {'1': 'comment_id', '3': 1, '4': 1, '5': 9, '10': 'commentId'},
  ],
};

/// Descriptor for `Comments`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commentsDescriptor = $convert
    .base64Decode('CghDb21tZW50cxIdCgpjb21tZW50X2lkGAEgASgJUgljb21tZW50SWQ=');

@$core.Deprecated('Use chaptersDescriptor instead')
const Chapters$json = {
  '1': 'Chapters',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
  ],
};

/// Descriptor for `Chapters`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chaptersDescriptor = $convert.base64Decode(
    'CghDaGFwdGVycxIQCgN1cmkYASABKAlSA3VyaRIUCgV0aXRsZRgCIAEoCVIFdGl0bGU=');

@$core.Deprecated('Use sectionDescriptor instead')
const Section$json = {
  '1': 'Section',
  '2': [
    {
      '1': 'section_info',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.spotify.scrollsita.v1.SectionInfo',
      '10': 'sectionInfo'
    },
    {
      '1': 'comments',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.scrollsita.v1.Comments',
      '9': 0,
      '10': 'comments'
    },
    {
      '1': 'creator_bio',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.scrollsita.v1.CreatorBio',
      '9': 0,
      '10': 'creatorBio'
    },
    {
      '1': 'discovery_feed',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.scrollsita.v1.DiscoveryFeed',
      '9': 0,
      '10': 'discoveryFeed'
    },
    {
      '1': 'credits',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.scrollsita.v1.Credits',
      '9': 0,
      '10': 'credits'
    },
    {
      '1': 'lyrics',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.spotify.scrollsita.v1.Lyrics',
      '9': 0,
      '10': 'lyrics'
    },
    {
      '1': 'merch',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.spotify.scrollsita.v1.Merch',
      '9': 0,
      '10': 'merch'
    },
    {
      '1': 'live_events',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.spotify.scrollsita.v1.LiveEvents',
      '9': 0,
      '10': 'liveEvents'
    },
    {
      '1': 'chapters',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.spotify.scrollsita.v1.Chapters',
      '9': 0,
      '10': 'chapters'
    },
    {
      '1': 'polls',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.spotify.scrollsita.v1.Polls',
      '9': 0,
      '10': 'polls'
    },
    {
      '1': 'song_dna',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.spotify.scrollsita.v1.SongDNA',
      '9': 0,
      '10': 'songDna'
    },
  ],
  '8': [
    {'1': 'section_type'},
  ],
};

/// Descriptor for `Section`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionDescriptor = $convert.base64Decode(
    'CgdTZWN0aW9uEkUKDHNlY3Rpb25faW5mbxgXIAEoCzIiLnNwb3RpZnkuc2Nyb2xsc2l0YS52MS'
    '5TZWN0aW9uSW5mb1ILc2VjdGlvbkluZm8SPQoIY29tbWVudHMYASABKAsyHy5zcG90aWZ5LnNj'
    'cm9sbHNpdGEudjEuQ29tbWVudHNIAFIIY29tbWVudHMSRAoLY3JlYXRvcl9iaW8YAiABKAsyIS'
    '5zcG90aWZ5LnNjcm9sbHNpdGEudjEuQ3JlYXRvckJpb0gAUgpjcmVhdG9yQmlvEk0KDmRpc2Nv'
    'dmVyeV9mZWVkGAMgASgLMiQuc3BvdGlmeS5zY3JvbGxzaXRhLnYxLkRpc2NvdmVyeUZlZWRIAF'
    'INZGlzY292ZXJ5RmVlZBI6CgdjcmVkaXRzGAQgASgLMh4uc3BvdGlmeS5zY3JvbGxzaXRhLnYx'
    'LkNyZWRpdHNIAFIHY3JlZGl0cxI3CgZseXJpY3MYBSABKAsyHS5zcG90aWZ5LnNjcm9sbHNpdG'
    'EudjEuTHlyaWNzSABSBmx5cmljcxI0CgVtZXJjaBgGIAEoCzIcLnNwb3RpZnkuc2Nyb2xsc2l0'
    'YS52MS5NZXJjaEgAUgVtZXJjaBJECgtsaXZlX2V2ZW50cxgLIAEoCzIhLnNwb3RpZnkuc2Nyb2'
    'xsc2l0YS52MS5MaXZlRXZlbnRzSABSCmxpdmVFdmVudHMSPQoIY2hhcHRlcnMYECABKAsyHy5z'
    'cG90aWZ5LnNjcm9sbHNpdGEudjEuQ2hhcHRlcnNIAFIIY2hhcHRlcnMSNAoFcG9sbHMYFSABKA'
    'syHC5zcG90aWZ5LnNjcm9sbHNpdGEudjEuUG9sbHNIAFIFcG9sbHMSOwoIc29uZ19kbmEYGyAB'
    'KAsyHi5zcG90aWZ5LnNjcm9sbHNpdGEudjEuU29uZ0ROQUgAUgdzb25nRG5hQg4KDHNlY3Rpb2'
    '5fdHlwZQ==');
