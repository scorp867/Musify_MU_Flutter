// This is a generated file - do not edit.
//
// Generated from spotify/casita/resolved.proto.

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

@$core.Deprecated('Use resolvedHomeDescriptor instead')
const ResolvedHome$json = {
  '1': 'ResolvedHome',
  '2': [
    {
      '1': 'structure',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.HomeStructure',
      '10': 'structure'
    },
    {
      '1': 'eagerly_loaded_traits',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.EagerlyLoadedTraits',
      '10': 'eagerlyLoadedTraits'
    },
    {
      '1': 'response_info',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.ResponseInfo',
      '10': 'responseInfo'
    },
    {
      '1': 'debug_info',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.DebugInfo',
      '10': 'debugInfo'
    },
    {
      '1': 'sandbox_debug_info',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.SandboxDebugInfo',
      '10': 'sandboxDebugInfo'
    },
    {
      '1': 'ondemand_set',
      '3': 999,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.OndemandSet',
      '10': 'ondemandSet'
    },
  ],
};

/// Descriptor for `ResolvedHome`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resolvedHomeDescriptor = $convert.base64Decode(
    'CgxSZXNvbHZlZEhvbWUSRwoJc3RydWN0dXJlGAEgASgLMikuc3BvdGlmeS5jYXNpdGEudjEucm'
    'Vzb2x2ZWQuSG9tZVN0cnVjdHVyZVIJc3RydWN0dXJlEmMKFWVhZ2VybHlfbG9hZGVkX3RyYWl0'
    'cxgCIAEoCzIvLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLkVhZ2VybHlMb2FkZWRUcmFpdH'
    'NSE2VhZ2VybHlMb2FkZWRUcmFpdHMSTQoNcmVzcG9uc2VfaW5mbxgDIAEoCzIoLnNwb3RpZnku'
    'Y2FzaXRhLnYxLnJlc29sdmVkLlJlc3BvbnNlSW5mb1IMcmVzcG9uc2VJbmZvEkQKCmRlYnVnX2'
    'luZm8YBCABKAsyJS5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5EZWJ1Z0luZm9SCWRlYnVn'
    'SW5mbxJaChJzYW5kYm94X2RlYnVnX2luZm8YBSABKAsyLC5zcG90aWZ5LmNhc2l0YS52MS5yZX'
    'NvbHZlZC5TYW5kYm94RGVidWdJbmZvUhBzYW5kYm94RGVidWdJbmZvEksKDG9uZGVtYW5kX3Nl'
    'dBjnByABKAsyJy5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5PbmRlbWFuZFNldFILb25kZW'
    '1hbmRTZXQ=');

@$core.Deprecated('Use homeStructureDescriptor instead')
const HomeStructure$json = {
  '1': 'HomeStructure',
  '2': [
    {
      '1': 'sections',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Section',
      '10': 'sections'
    },
  ],
};

/// Descriptor for `HomeStructure`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List homeStructureDescriptor = $convert.base64Decode(
    'Cg1Ib21lU3RydWN0dXJlEj8KCHNlY3Rpb25zGAEgAygLMiMuc3BvdGlmeS5jYXNpdGEudjEucm'
    'Vzb2x2ZWQuU2VjdGlvblIIc2VjdGlvbnM=');

@$core.Deprecated('Use eagerlyLoadedTraitsDescriptor instead')
const EagerlyLoadedTraits$json = {
  '1': 'EagerlyLoadedTraits',
  '2': [
    {
      '1': 'traits',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.extendedmetadata.BatchedExtensionResponse',
      '10': 'traits'
    },
  ],
};

/// Descriptor for `EagerlyLoadedTraits`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eagerlyLoadedTraitsDescriptor = $convert.base64Decode(
    'ChNFYWdlcmx5TG9hZGVkVHJhaXRzEkoKBnRyYWl0cxgBIAEoCzIyLnNwb3RpZnkuZXh0ZW5kZW'
    'RtZXRhZGF0YS5CYXRjaGVkRXh0ZW5zaW9uUmVzcG9uc2VSBnRyYWl0cw==');

@$core.Deprecated('Use responseInfoDescriptor instead')
const ResponseInfo$json = {
  '1': 'ResponseInfo',
  '2': [
    {'1': 'server_version', '3': 1, '4': 1, '5': 9, '10': 'serverVersion'},
  ],
};

/// Descriptor for `ResponseInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseInfoDescriptor = $convert.base64Decode(
    'CgxSZXNwb25zZUluZm8SJQoOc2VydmVyX3ZlcnNpb24YASABKAlSDXNlcnZlclZlcnNpb24=');

@$core.Deprecated('Use debugInfoDescriptor instead')
const DebugInfo$json = {
  '1': 'DebugInfo',
};

/// Descriptor for `DebugInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List debugInfoDescriptor =
    $convert.base64Decode('CglEZWJ1Z0luZm8=');

@$core.Deprecated('Use sandboxDebugInfoDescriptor instead')
const SandboxDebugInfo$json = {
  '1': 'SandboxDebugInfo',
};

/// Descriptor for `SandboxDebugInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sandboxDebugInfoDescriptor =
    $convert.base64Decode('ChBTYW5kYm94RGVidWdJbmZv');

@$core.Deprecated('Use ondemandSetDescriptor instead')
const OndemandSet$json = {
  '1': 'OndemandSet',
  '2': [
    {'1': 'uris', '3': 1, '4': 3, '5': 9, '10': 'uris'},
  ],
};

/// Descriptor for `OndemandSet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ondemandSetDescriptor =
    $convert.base64Decode('CgtPbmRlbWFuZFNldBISCgR1cmlzGAEgAygJUgR1cmlz');

@$core.Deprecated('Use sectionDescriptor instead')
const Section$json = {
  '1': 'Section',
  '2': [
    {
      '1': 'section_info',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.SectionInfo',
      '10': 'sectionInfo'
    },
    {
      '1': 'shortcuts',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Shortcuts',
      '9': 0,
      '10': 'shortcuts'
    },
    {
      '1': 'image_link',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.ImageLink',
      '9': 0,
      '10': 'imageLink'
    },
    {
      '1': 'preview',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Preview',
      '9': 0,
      '10': 'preview'
    },
    {
      '1': 'immersive_preview',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.ImmersivePreview',
      '9': 0,
      '10': 'immersivePreview'
    },
    {
      '1': 'content_evaluation_list',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.ContentEvaluationList',
      '9': 0,
      '10': 'contentEvaluationList'
    },
    {
      '1': 'call_to_action',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.CallToAction',
      '9': 0,
      '10': 'callToAction'
    },
    {
      '1': 'recents_shelf',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.RecentsShelf',
      '9': 0,
      '10': 'recentsShelf'
    },
    {
      '1': 'watch_feed',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.WatchFeed',
      '9': 0,
      '10': 'watchFeed'
    },
    {
      '1': 'live_event',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.LiveEvent',
      '9': 0,
      '10': 'liveEvent'
    },
    {
      '1': 'showcase',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Showcase',
      '9': 0,
      '10': 'showcase'
    },
    {
      '1': 'vertical_single_entry',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.VerticalSingleEntry',
      '9': 0,
      '10': 'verticalSingleEntry'
    },
    {
      '1': 'video_carousel',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.VideoCarousel',
      '9': 0,
      '10': 'videoCarousel'
    },
    {
      '1': 'associated_preview',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.AssociatedPreview',
      '9': 0,
      '10': 'associatedPreview'
    },
    {
      '1': 'narrative',
      '3': 29,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Narrative',
      '9': 0,
      '10': 'narrative'
    },
    {
      '1': 'interactive_entrypoint',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.InteractiveEntrypoint',
      '9': 0,
      '10': 'interactiveEntrypoint'
    },
    {
      '1': 'top_story_carousel',
      '3': 31,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.TopStoryCarousel',
      '9': 0,
      '10': 'topStoryCarousel'
    },
    {
      '1': 'audio_promo',
      '3': 33,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.AudioPromo',
      '9': 0,
      '10': 'audioPromo'
    },
    {
      '1': 'inline_card',
      '3': 34,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.InlineCard',
      '9': 0,
      '10': 'inlineCard'
    },
    {
      '1': 'audio_spotlight',
      '3': 36,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.AudioSpotlight',
      '9': 0,
      '10': 'audioSpotlight'
    },
    {
      '1': 'preview_carousel',
      '3': 37,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.PreviewCarousel',
      '9': 0,
      '10': 'previewCarousel'
    },
    {
      '1': 'preview_promotion_carousel',
      '3': 39,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.PreviewPromotionCarousel',
      '9': 0,
      '10': 'previewPromotionCarousel'
    },
    {
      '1': 'reflection',
      '3': 41,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Reflection',
      '9': 0,
      '10': 'reflection'
    },
  ],
  '8': [
    {'1': 'feature_type'},
  ],
};

/// Descriptor for `Section`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionDescriptor = $convert.base64Decode(
    'CgdTZWN0aW9uEkoKDHNlY3Rpb25faW5mbxgBIAEoCzInLnNwb3RpZnkuY2FzaXRhLnYxLnJlc2'
    '9sdmVkLlNlY3Rpb25JbmZvUgtzZWN0aW9uSW5mbxJFCglzaG9ydGN1dHMYAiABKAsyJS5zcG90'
    'aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5TaG9ydGN1dHNIAFIJc2hvcnRjdXRzEkYKCmltYWdlX2'
    'xpbmsYAyABKAsyJS5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5JbWFnZUxpbmtIAFIJaW1h'
    'Z2VMaW5rEj8KB3ByZXZpZXcYBCABKAsyIy5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5Qcm'
    'V2aWV3SABSB3ByZXZpZXcSWwoRaW1tZXJzaXZlX3ByZXZpZXcYBiABKAsyLC5zcG90aWZ5LmNh'
    'c2l0YS52MS5yZXNvbHZlZC5JbW1lcnNpdmVQcmV2aWV3SABSEGltbWVyc2l2ZVByZXZpZXcSaw'
    'oXY29udGVudF9ldmFsdWF0aW9uX2xpc3QYCCABKAsyMS5zcG90aWZ5LmNhc2l0YS52MS5yZXNv'
    'bHZlZC5Db250ZW50RXZhbHVhdGlvbkxpc3RIAFIVY29udGVudEV2YWx1YXRpb25MaXN0ElAKDm'
    'NhbGxfdG9fYWN0aW9uGAkgASgLMiguc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZWQuQ2FsbFRv'
    'QWN0aW9uSABSDGNhbGxUb0FjdGlvbhJPCg1yZWNlbnRzX3NoZWxmGAogASgLMiguc3BvdGlmeS'
    '5jYXNpdGEudjEucmVzb2x2ZWQuUmVjZW50c1NoZWxmSABSDHJlY2VudHNTaGVsZhJGCgp3YXRj'
    'aF9mZWVkGAsgASgLMiUuc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZWQuV2F0Y2hGZWVkSABSCX'
    'dhdGNoRmVlZBJGCgpsaXZlX2V2ZW50GBAgASgLMiUuc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2'
    'ZWQuTGl2ZUV2ZW50SABSCWxpdmVFdmVudBJCCghzaG93Y2FzZRgRIAEoCzIkLnNwb3RpZnkuY2'
    'FzaXRhLnYxLnJlc29sdmVkLlNob3djYXNlSABSCHNob3djYXNlEmUKFXZlcnRpY2FsX3Npbmds'
    'ZV9lbnRyeRgYIAEoCzIvLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLlZlcnRpY2FsU2luZ2'
    'xlRW50cnlIAFITdmVydGljYWxTaW5nbGVFbnRyeRJSCg52aWRlb19jYXJvdXNlbBgZIAEoCzIp'
    'LnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLlZpZGVvQ2Fyb3VzZWxIAFINdmlkZW9DYXJvdX'
    'NlbBJeChJhc3NvY2lhdGVkX3ByZXZpZXcYGyABKAsyLS5zcG90aWZ5LmNhc2l0YS52MS5yZXNv'
    'bHZlZC5Bc3NvY2lhdGVkUHJldmlld0gAUhFhc3NvY2lhdGVkUHJldmlldxJFCgluYXJyYXRpdm'
    'UYHSABKAsyJS5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5OYXJyYXRpdmVIAFIJbmFycmF0'
    'aXZlEmoKFmludGVyYWN0aXZlX2VudHJ5cG9pbnQYHiABKAsyMS5zcG90aWZ5LmNhc2l0YS52MS'
    '5yZXNvbHZlZC5JbnRlcmFjdGl2ZUVudHJ5cG9pbnRIAFIVaW50ZXJhY3RpdmVFbnRyeXBvaW50'
    'ElwKEnRvcF9zdG9yeV9jYXJvdXNlbBgfIAEoCzIsLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdm'
    'VkLlRvcFN0b3J5Q2Fyb3VzZWxIAFIQdG9wU3RvcnlDYXJvdXNlbBJJCgthdWRpb19wcm9tbxgh'
    'IAEoCzImLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLkF1ZGlvUHJvbW9IAFIKYXVkaW9Qcm'
    '9tbxJJCgtpbmxpbmVfY2FyZBgiIAEoCzImLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLklu'
    'bGluZUNhcmRIAFIKaW5saW5lQ2FyZBJVCg9hdWRpb19zcG90bGlnaHQYJCABKAsyKi5zcG90aW'
    'Z5LmNhc2l0YS52MS5yZXNvbHZlZC5BdWRpb1Nwb3RsaWdodEgAUg5hdWRpb1Nwb3RsaWdodBJY'
    'ChBwcmV2aWV3X2Nhcm91c2VsGCUgASgLMisuc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZWQuUH'
    'Jldmlld0Nhcm91c2VsSABSD3ByZXZpZXdDYXJvdXNlbBJ0ChpwcmV2aWV3X3Byb21vdGlvbl9j'
    'YXJvdXNlbBgnIAEoCzI0LnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLlByZXZpZXdQcm9tb3'
    'Rpb25DYXJvdXNlbEgAUhhwcmV2aWV3UHJvbW90aW9uQ2Fyb3VzZWwSSAoKcmVmbGVjdGlvbhgp'
    'IAEoCzImLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLlJlZmxlY3Rpb25IAFIKcmVmbGVjdG'
    'lvbkIOCgxmZWF0dXJlX3R5cGU=');

@$core.Deprecated('Use sectionInfoDescriptor instead')
const SectionInfo$json = {
  '1': 'SectionInfo',
  '2': [
    {'1': 'section_id', '3': 1, '4': 1, '5': 9, '10': 'sectionId'},
  ],
};

/// Descriptor for `SectionInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionInfoDescriptor = $convert.base64Decode(
    'CgtTZWN0aW9uSW5mbxIdCgpzZWN0aW9uX2lkGAEgASgJUglzZWN0aW9uSWQ=');

@$core.Deprecated('Use itemDescriptor instead')
const Item$json = {
  '1': 'Item',
  '2': [
    {'1': 'identifier', '3': 1, '4': 1, '5': 9, '10': 'identifier'},
    {
      '1': 'highlighted_sub_items',
      '3': 2,
      '4': 3,
      '5': 9,
      '10': 'highlightedSubItems'
    },
  ],
};

/// Descriptor for `Item`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List itemDescriptor = $convert.base64Decode(
    'CgRJdGVtEh4KCmlkZW50aWZpZXIYASABKAlSCmlkZW50aWZpZXISMgoVaGlnaGxpZ2h0ZWRfc3'
    'ViX2l0ZW1zGAIgAygJUhNoaWdobGlnaHRlZFN1Ykl0ZW1z');

@$core.Deprecated('Use itemSourceDescriptor instead')
const ItemSource$json = {
  '1': 'ItemSource',
  '2': [
    {
      '1': 'provided',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Provided',
      '9': 0,
      '10': 'provided'
    },
    {
      '1': 'local_recently_played',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.LocalRecentlyPlayed',
      '9': 0,
      '10': 'localRecentlyPlayed'
    },
    {
      '1': 'list_platform',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.ListPlatform',
      '9': 0,
      '10': 'listPlatform'
    },
  ],
  '8': [
    {'1': 'source'},
  ],
};

/// Descriptor for `ItemSource`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List itemSourceDescriptor = $convert.base64Decode(
    'CgpJdGVtU291cmNlEkIKCHByb3ZpZGVkGAEgASgLMiQuc3BvdGlmeS5jYXNpdGEudjEucmVzb2'
    'x2ZWQuUHJvdmlkZWRIAFIIcHJvdmlkZWQSZQoVbG9jYWxfcmVjZW50bHlfcGxheWVkGAIgASgL'
    'Mi8uc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZWQuTG9jYWxSZWNlbnRseVBsYXllZEgAUhNsb2'
    'NhbFJlY2VudGx5UGxheWVkEk8KDWxpc3RfcGxhdGZvcm0YAyABKAsyKC5zcG90aWZ5LmNhc2l0'
    'YS52MS5yZXNvbHZlZC5MaXN0UGxhdGZvcm1IAFIMbGlzdFBsYXRmb3JtQggKBnNvdXJjZQ==');

@$core.Deprecated('Use providedDescriptor instead')
const Provided$json = {
  '1': 'Provided',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'items'
    },
  ],
};

/// Descriptor for `Provided`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List providedDescriptor = $convert.base64Decode(
    'CghQcm92aWRlZBI2CgVpdGVtcxgBIAMoCzIgLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLk'
    'l0ZW1SBWl0ZW1z');

@$core.Deprecated('Use localRecentlyPlayedDescriptor instead')
const LocalRecentlyPlayed$json = {
  '1': 'LocalRecentlyPlayed',
};

/// Descriptor for `LocalRecentlyPlayed`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List localRecentlyPlayedDescriptor =
    $convert.base64Decode('ChNMb2NhbFJlY2VudGx5UGxheWVk');

@$core.Deprecated('Use listPlatformDescriptor instead')
const ListPlatform$json = {
  '1': 'ListPlatform',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
  ],
};

/// Descriptor for `ListPlatform`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listPlatformDescriptor =
    $convert.base64Decode('CgxMaXN0UGxhdGZvcm0SEAoDdXJpGAEgASgJUgN1cmk=');

@$core.Deprecated('Use headingDescriptor instead')
const Heading$json = {
  '1': 'Heading',
  '2': [
    {
      '1': 'empty_heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.EmptyHeading',
      '9': 0,
      '10': 'emptyHeading'
    },
    {
      '1': 'text_heading',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.HeadingWithText',
      '9': 0,
      '10': 'textHeading'
    },
    {
      '1': 'enriched_heading',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.EnrichedHeading',
      '9': 0,
      '10': 'enrichedHeading'
    },
    {
      '1': 'sponsored_heading',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.SponsoredHeading',
      '9': 0,
      '10': 'sponsoredHeading'
    },
    {
      '1': 'heading_with_description',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.HeadingWithDescription',
      '9': 0,
      '10': 'headingWithDescription'
    },
    {
      '1': 'static_enriched_heading',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.StaticEnrichedHeading',
      '9': 0,
      '10': 'staticEnrichedHeading'
    },
  ],
  '8': [
    {'1': 'heading'},
  ],
};

/// Descriptor for `Heading`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List headingDescriptor = $convert.base64Decode(
    'CgdIZWFkaW5nEk8KDWVtcHR5X2hlYWRpbmcYASABKAsyKC5zcG90aWZ5LmNhc2l0YS52MS5yZX'
    'NvbHZlZC5FbXB0eUhlYWRpbmdIAFIMZW1wdHlIZWFkaW5nElAKDHRleHRfaGVhZGluZxgCIAEo'
    'CzIrLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLkhlYWRpbmdXaXRoVGV4dEgAUgt0ZXh0SG'
    'VhZGluZxJYChBlbnJpY2hlZF9oZWFkaW5nGAMgASgLMisuc3BvdGlmeS5jYXNpdGEudjEucmVz'
    'b2x2ZWQuRW5yaWNoZWRIZWFkaW5nSABSD2VucmljaGVkSGVhZGluZxJbChFzcG9uc29yZWRfaG'
    'VhZGluZxgEIAEoCzIsLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLlNwb25zb3JlZEhlYWRp'
    'bmdIAFIQc3BvbnNvcmVkSGVhZGluZxJuChhoZWFkaW5nX3dpdGhfZGVzY3JpcHRpb24YBSABKA'
    'syMi5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5IZWFkaW5nV2l0aERlc2NyaXB0aW9uSABS'
    'FmhlYWRpbmdXaXRoRGVzY3JpcHRpb24SawoXc3RhdGljX2VucmljaGVkX2hlYWRpbmcYBiABKA'
    'syMS5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5TdGF0aWNFbnJpY2hlZEhlYWRpbmdIAFIV'
    'c3RhdGljRW5yaWNoZWRIZWFkaW5nQgkKB2hlYWRpbmc=');

@$core.Deprecated('Use emptyHeadingDescriptor instead')
const EmptyHeading$json = {
  '1': 'EmptyHeading',
};

/// Descriptor for `EmptyHeading`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyHeadingDescriptor =
    $convert.base64Decode('CgxFbXB0eUhlYWRpbmc=');

@$core.Deprecated('Use headingWithTextDescriptor instead')
const HeadingWithText$json = {
  '1': 'HeadingWithText',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {'1': 'encore_icon_name', '3': 2, '4': 1, '5': 9, '10': 'encoreIconName'},
    {
      '1': 'navigation_action',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.NavigationAction',
      '10': 'navigationAction'
    },
  ],
};

/// Descriptor for `HeadingWithText`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List headingWithTextDescriptor = $convert.base64Decode(
    'Cg9IZWFkaW5nV2l0aFRleHQSEgoEdGV4dBgBIAEoCVIEdGV4dBIoChBlbmNvcmVfaWNvbl9uYW'
    '1lGAIgASgJUg5lbmNvcmVJY29uTmFtZRJZChFuYXZpZ2F0aW9uX2FjdGlvbhgDIAEoCzIsLnNw'
    'b3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLk5hdmlnYXRpb25BY3Rpb25SEG5hdmlnYXRpb25BY3'
    'Rpb24=');

@$core.Deprecated('Use enrichedHeadingDescriptor instead')
const EnrichedHeading$json = {
  '1': 'EnrichedHeading',
  '2': [
    {'1': 'format', '3': 1, '4': 1, '5': 9, '10': 'format'},
    {
      '1': 'associated_item',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.HeadingAssociatedItem',
      '10': 'associatedItem'
    },
    {'1': 'encore_icon_name', '3': 3, '4': 1, '5': 9, '10': 'encoreIconName'},
  ],
};

/// Descriptor for `EnrichedHeading`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List enrichedHeadingDescriptor = $convert.base64Decode(
    'Cg9FbnJpY2hlZEhlYWRpbmcSFgoGZm9ybWF0GAEgASgJUgZmb3JtYXQSWgoPYXNzb2NpYXRlZF'
    '9pdGVtGAIgASgLMjEuc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZWQuSGVhZGluZ0Fzc29jaWF0'
    'ZWRJdGVtUg5hc3NvY2lhdGVkSXRlbRIoChBlbmNvcmVfaWNvbl9uYW1lGAMgASgJUg5lbmNvcm'
    'VJY29uTmFtZQ==');

@$core.Deprecated('Use headingWithDescriptionDescriptor instead')
const HeadingWithDescription$json = {
  '1': 'HeadingWithDescription',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'subtitle', '3': 2, '4': 1, '5': 9, '10': 'subtitle'},
    {'1': 'encore_icon_name', '3': 3, '4': 1, '5': 9, '10': 'encoreIconName'},
  ],
};

/// Descriptor for `HeadingWithDescription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List headingWithDescriptionDescriptor = $convert.base64Decode(
    'ChZIZWFkaW5nV2l0aERlc2NyaXB0aW9uEhQKBXRpdGxlGAEgASgJUgV0aXRsZRIaCghzdWJ0aX'
    'RsZRgCIAEoCVIIc3VidGl0bGUSKAoQZW5jb3JlX2ljb25fbmFtZRgDIAEoCVIOZW5jb3JlSWNv'
    'bk5hbWU=');

@$core.Deprecated('Use staticEnrichedHeadingDescriptor instead')
const StaticEnrichedHeading$json = {
  '1': 'StaticEnrichedHeading',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {'1': 'subtext', '3': 2, '4': 1, '5': 9, '10': 'subtext'},
    {'1': 'image_url', '3': 3, '4': 1, '5': 9, '10': 'imageUrl'},
    {'1': 'navigation_uri', '3': 4, '4': 1, '5': 9, '10': 'navigationUri'},
  ],
};

/// Descriptor for `StaticEnrichedHeading`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List staticEnrichedHeadingDescriptor = $convert.base64Decode(
    'ChVTdGF0aWNFbnJpY2hlZEhlYWRpbmcSEgoEdGV4dBgBIAEoCVIEdGV4dBIYCgdzdWJ0ZXh0GA'
    'IgASgJUgdzdWJ0ZXh0EhsKCWltYWdlX3VybBgDIAEoCVIIaW1hZ2VVcmwSJQoObmF2aWdhdGlv'
    'bl91cmkYBCABKAlSDW5hdmlnYXRpb25Vcmk=');

@$core.Deprecated('Use sponsoredHeadingDescriptor instead')
const SponsoredHeading$json = {
  '1': 'SponsoredHeading',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `SponsoredHeading`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sponsoredHeadingDescriptor = $convert
    .base64Decode('ChBTcG9uc29yZWRIZWFkaW5nEhIKBHRleHQYASABKAlSBHRleHQ=');

@$core.Deprecated('Use headingAssociatedItemDescriptor instead')
const HeadingAssociatedItem$json = {
  '1': 'HeadingAssociatedItem',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'uri', '3': 2, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'image_url', '3': 3, '4': 1, '5': 9, '10': 'imageUrl'},
  ],
};

/// Descriptor for `HeadingAssociatedItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List headingAssociatedItemDescriptor = $convert.base64Decode(
    'ChVIZWFkaW5nQXNzb2NpYXRlZEl0ZW0SFAoFdGl0bGUYASABKAlSBXRpdGxlEhAKA3VyaRgCIA'
    'EoCVIDdXJpEhsKCWltYWdlX3VybBgDIAEoCVIIaW1hZ2VVcmw=');

@$core.Deprecated('Use navigationActionDescriptor instead')
const NavigationAction$json = {
  '1': 'NavigationAction',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {'1': 'uri', '3': 2, '4': 1, '5': 9, '10': 'uri'},
  ],
};

/// Descriptor for `NavigationAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List navigationActionDescriptor = $convert.base64Decode(
    'ChBOYXZpZ2F0aW9uQWN0aW9uEhIKBHRleHQYASABKAlSBHRleHQSEAoDdXJpGAIgASgJUgN1cm'
    'k=');

@$core.Deprecated('Use shortcutsDescriptor instead')
const Shortcuts$json = {
  '1': 'Shortcuts',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item_source',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.ItemSource',
      '10': 'itemSource'
    },
  ],
};

/// Descriptor for `Shortcuts`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List shortcutsDescriptor = $convert.base64Decode(
    'CglTaG9ydGN1dHMSPQoHaGVhZGluZxgBIAEoCzIjLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdm'
    'VkLkhlYWRpbmdSB2hlYWRpbmcSRwoLaXRlbV9zb3VyY2UYAiABKAsyJi5zcG90aWZ5LmNhc2l0'
    'YS52MS5yZXNvbHZlZC5JdGVtU291cmNlUgppdGVtU291cmNl');

@$core.Deprecated('Use imageLinkDescriptor instead')
const ImageLink$json = {
  '1': 'ImageLink',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item_source',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.ItemSource',
      '10': 'itemSource'
    },
    {'1': 'density', '3': 3, '4': 1, '5': 5, '10': 'density'},
    {
      '1': 'ad_metadata',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.EmbeddedAdMetadata',
      '10': 'adMetadata'
    },
    {'1': 'source', '3': 5, '4': 1, '5': 5, '10': 'source'},
  ],
};

/// Descriptor for `ImageLink`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imageLinkDescriptor = $convert.base64Decode(
    'CglJbWFnZUxpbmsSPQoHaGVhZGluZxgBIAEoCzIjLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdm'
    'VkLkhlYWRpbmdSB2hlYWRpbmcSRwoLaXRlbV9zb3VyY2UYAiABKAsyJi5zcG90aWZ5LmNhc2l0'
    'YS52MS5yZXNvbHZlZC5JdGVtU291cmNlUgppdGVtU291cmNlEhgKB2RlbnNpdHkYAyABKAVSB2'
    'RlbnNpdHkSTwoLYWRfbWV0YWRhdGEYBCABKAsyLi5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZl'
    'ZC5FbWJlZGRlZEFkTWV0YWRhdGFSCmFkTWV0YWRhdGESFgoGc291cmNlGAUgASgFUgZzb3VyY2'
    'U=');

@$core.Deprecated('Use previewDescriptor instead')
const Preview$json = {
  '1': 'Preview',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'item'
    },
  ],
};

/// Descriptor for `Preview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewDescriptor = $convert.base64Decode(
    'CgdQcmV2aWV3Ej0KB2hlYWRpbmcYASABKAsyIy5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC'
    '5IZWFkaW5nUgdoZWFkaW5nEjQKBGl0ZW0YAiABKAsyIC5zcG90aWZ5LmNhc2l0YS52MS5yZXNv'
    'bHZlZC5JdGVtUgRpdGVt');

@$core.Deprecated('Use immersivePreviewDescriptor instead')
const ImmersivePreview$json = {
  '1': 'ImmersivePreview',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'item'
    },
  ],
};

/// Descriptor for `ImmersivePreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List immersivePreviewDescriptor = $convert.base64Decode(
    'ChBJbW1lcnNpdmVQcmV2aWV3Ej0KB2hlYWRpbmcYASABKAsyIy5zcG90aWZ5LmNhc2l0YS52MS'
    '5yZXNvbHZlZC5IZWFkaW5nUgdoZWFkaW5nEjQKBGl0ZW0YAiABKAsyIC5zcG90aWZ5LmNhc2l0'
    'YS52MS5yZXNvbHZlZC5JdGVtUgRpdGVt');

@$core.Deprecated('Use contentEvaluationListDescriptor instead')
const ContentEvaluationList$json = {
  '1': 'ContentEvaluationList',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item_source',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.ItemSource',
      '10': 'itemSource'
    },
  ],
};

/// Descriptor for `ContentEvaluationList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contentEvaluationListDescriptor = $convert.base64Decode(
    'ChVDb250ZW50RXZhbHVhdGlvbkxpc3QSPQoHaGVhZGluZxgBIAEoCzIjLnNwb3RpZnkuY2FzaX'
    'RhLnYxLnJlc29sdmVkLkhlYWRpbmdSB2hlYWRpbmcSRwoLaXRlbV9zb3VyY2UYAiABKAsyJi5z'
    'cG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5JdGVtU291cmNlUgppdGVtU291cmNl');

@$core.Deprecated('Use callToActionDescriptor instead')
const CallToAction$json = {
  '1': 'CallToAction',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'subtitle', '3': 2, '4': 1, '5': 9, '10': 'subtitle'},
    {'1': 'button_text', '3': 3, '4': 1, '5': 9, '10': 'buttonText'},
    {'1': 'uri', '3': 4, '4': 1, '5': 9, '10': 'uri'},
  ],
};

/// Descriptor for `CallToAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List callToActionDescriptor = $convert.base64Decode(
    'CgxDYWxsVG9BY3Rpb24SFAoFdGl0bGUYASABKAlSBXRpdGxlEhoKCHN1YnRpdGxlGAIgASgJUg'
    'hzdWJ0aXRsZRIfCgtidXR0b25fdGV4dBgDIAEoCVIKYnV0dG9uVGV4dBIQCgN1cmkYBCABKAlS'
    'A3VyaQ==');

@$core.Deprecated('Use recentsShelfDescriptor instead')
const RecentsShelf$json = {
  '1': 'RecentsShelf',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item_source',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.ItemSource',
      '10': 'itemSource'
    },
    {'1': 'title_density', '3': 3, '4': 1, '5': 5, '10': 'titleDensity'},
  ],
};

/// Descriptor for `RecentsShelf`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recentsShelfDescriptor = $convert.base64Decode(
    'CgxSZWNlbnRzU2hlbGYSPQoHaGVhZGluZxgBIAEoCzIjLnNwb3RpZnkuY2FzaXRhLnYxLnJlc2'
    '9sdmVkLkhlYWRpbmdSB2hlYWRpbmcSRwoLaXRlbV9zb3VyY2UYAiABKAsyJi5zcG90aWZ5LmNh'
    'c2l0YS52MS5yZXNvbHZlZC5JdGVtU291cmNlUgppdGVtU291cmNlEiMKDXRpdGxlX2RlbnNpdH'
    'kYAyABKAVSDHRpdGxlRGVuc2l0eQ==');

@$core.Deprecated('Use watchFeedDescriptor instead')
const WatchFeed$json = {
  '1': 'WatchFeed',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item_source',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.ItemSource',
      '10': 'itemSource'
    },
  ],
};

/// Descriptor for `WatchFeed`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchFeedDescriptor = $convert.base64Decode(
    'CglXYXRjaEZlZWQSPQoHaGVhZGluZxgBIAEoCzIjLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdm'
    'VkLkhlYWRpbmdSB2hlYWRpbmcSRwoLaXRlbV9zb3VyY2UYAiABKAsyJi5zcG90aWZ5LmNhc2l0'
    'YS52MS5yZXNvbHZlZC5JdGVtU291cmNlUgppdGVtU291cmNl');

@$core.Deprecated('Use liveEventDescriptor instead')
const LiveEvent$json = {
  '1': 'LiveEvent',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'item'
    },
  ],
};

/// Descriptor for `LiveEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List liveEventDescriptor = $convert.base64Decode(
    'CglMaXZlRXZlbnQSPQoHaGVhZGluZxgBIAEoCzIjLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdm'
    'VkLkhlYWRpbmdSB2hlYWRpbmcSNAoEaXRlbRgCIAEoCzIgLnNwb3RpZnkuY2FzaXRhLnYxLnJl'
    'c29sdmVkLkl0ZW1SBGl0ZW0=');

@$core.Deprecated('Use showcaseDescriptor instead')
const Showcase$json = {
  '1': 'Showcase',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'item'
    },
    {
      '1': 'ad_metadata',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.EmbeddedAdMetadata',
      '10': 'adMetadata'
    },
  ],
};

/// Descriptor for `Showcase`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List showcaseDescriptor = $convert.base64Decode(
    'CghTaG93Y2FzZRI9CgdoZWFkaW5nGAEgASgLMiMuc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZW'
    'QuSGVhZGluZ1IHaGVhZGluZxI0CgRpdGVtGAIgASgLMiAuc3BvdGlmeS5jYXNpdGEudjEucmVz'
    'b2x2ZWQuSXRlbVIEaXRlbRJPCgthZF9tZXRhZGF0YRgDIAEoCzIuLnNwb3RpZnkuY2FzaXRhLn'
    'YxLnJlc29sdmVkLkVtYmVkZGVkQWRNZXRhZGF0YVIKYWRNZXRhZGF0YQ==');

@$core.Deprecated('Use verticalSingleEntryDescriptor instead')
const VerticalSingleEntry$json = {
  '1': 'VerticalSingleEntry',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'item'
    },
    {'1': 'target_uri', '3': 3, '4': 1, '5': 9, '10': 'targetUri'},
    {
      '1': 'ad_metadata',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.EmbeddedAdMetadata',
      '10': 'adMetadata'
    },
  ],
};

/// Descriptor for `VerticalSingleEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List verticalSingleEntryDescriptor = $convert.base64Decode(
    'ChNWZXJ0aWNhbFNpbmdsZUVudHJ5Ej0KB2hlYWRpbmcYASABKAsyIy5zcG90aWZ5LmNhc2l0YS'
    '52MS5yZXNvbHZlZC5IZWFkaW5nUgdoZWFkaW5nEjQKBGl0ZW0YAiABKAsyIC5zcG90aWZ5LmNh'
    'c2l0YS52MS5yZXNvbHZlZC5JdGVtUgRpdGVtEh0KCnRhcmdldF91cmkYAyABKAlSCXRhcmdldF'
    'VyaRJPCgthZF9tZXRhZGF0YRgEIAEoCzIuLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLkVt'
    'YmVkZGVkQWRNZXRhZGF0YVIKYWRNZXRhZGF0YQ==');

@$core.Deprecated('Use videoCarouselDescriptor instead')
const VideoCarousel$json = {
  '1': 'VideoCarousel',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item_source',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.ItemSource',
      '10': 'itemSource'
    },
  ],
};

/// Descriptor for `VideoCarousel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoCarouselDescriptor = $convert.base64Decode(
    'Cg1WaWRlb0Nhcm91c2VsEj0KB2hlYWRpbmcYASABKAsyIy5zcG90aWZ5LmNhc2l0YS52MS5yZX'
    'NvbHZlZC5IZWFkaW5nUgdoZWFkaW5nEkcKC2l0ZW1fc291cmNlGAIgASgLMiYuc3BvdGlmeS5j'
    'YXNpdGEudjEucmVzb2x2ZWQuSXRlbVNvdXJjZVIKaXRlbVNvdXJjZQ==');

@$core.Deprecated('Use associatedPreviewDescriptor instead')
const AssociatedPreview$json = {
  '1': 'AssociatedPreview',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'item'
    },
  ],
};

/// Descriptor for `AssociatedPreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List associatedPreviewDescriptor = $convert.base64Decode(
    'ChFBc3NvY2lhdGVkUHJldmlldxI9CgdoZWFkaW5nGAEgASgLMiMuc3BvdGlmeS5jYXNpdGEudj'
    'EucmVzb2x2ZWQuSGVhZGluZ1IHaGVhZGluZxI0CgRpdGVtGAIgASgLMiAuc3BvdGlmeS5jYXNp'
    'dGEudjEucmVzb2x2ZWQuSXRlbVIEaXRlbQ==');

@$core.Deprecated('Use narrativeDescriptor instead')
const Narrative$json = {
  '1': 'Narrative',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'main_text', '3': 2, '4': 1, '5': 9, '10': 'mainText'},
  ],
};

/// Descriptor for `Narrative`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List narrativeDescriptor = $convert.base64Decode(
    'CglOYXJyYXRpdmUSFAoFdGl0bGUYASABKAlSBXRpdGxlEhsKCW1haW5fdGV4dBgCIAEoCVIIbW'
    'FpblRleHQ=');

@$core.Deprecated('Use interactiveEntrypointDescriptor instead')
const InteractiveEntrypoint$json = {
  '1': 'InteractiveEntrypoint',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'item'
    },
  ],
};

/// Descriptor for `InteractiveEntrypoint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List interactiveEntrypointDescriptor = $convert.base64Decode(
    'ChVJbnRlcmFjdGl2ZUVudHJ5cG9pbnQSPQoHaGVhZGluZxgBIAEoCzIjLnNwb3RpZnkuY2FzaX'
    'RhLnYxLnJlc29sdmVkLkhlYWRpbmdSB2hlYWRpbmcSNAoEaXRlbRgCIAEoCzIgLnNwb3RpZnku'
    'Y2FzaXRhLnYxLnJlc29sdmVkLkl0ZW1SBGl0ZW0=');

@$core.Deprecated('Use topStoryCarouselDescriptor instead')
const TopStoryCarousel$json = {
  '1': 'TopStoryCarousel',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'items'
    },
  ],
};

/// Descriptor for `TopStoryCarousel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List topStoryCarouselDescriptor = $convert.base64Decode(
    'ChBUb3BTdG9yeUNhcm91c2VsEj0KB2hlYWRpbmcYASABKAsyIy5zcG90aWZ5LmNhc2l0YS52MS'
    '5yZXNvbHZlZC5IZWFkaW5nUgdoZWFkaW5nEjYKBWl0ZW1zGAIgAygLMiAuc3BvdGlmeS5jYXNp'
    'dGEudjEucmVzb2x2ZWQuSXRlbVIFaXRlbXM=');

@$core.Deprecated('Use audioPromoDescriptor instead')
const AudioPromo$json = {
  '1': 'AudioPromo',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'item'
    },
  ],
};

/// Descriptor for `AudioPromo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioPromoDescriptor = $convert.base64Decode(
    'CgpBdWRpb1Byb21vEj0KB2hlYWRpbmcYASABKAsyIy5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbH'
    'ZlZC5IZWFkaW5nUgdoZWFkaW5nEjQKBGl0ZW0YAiABKAsyIC5zcG90aWZ5LmNhc2l0YS52MS5y'
    'ZXNvbHZlZC5JdGVtUgRpdGVt');

@$core.Deprecated('Use inlineCardDescriptor instead')
const InlineCard$json = {
  '1': 'InlineCard',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'item'
    },
  ],
};

/// Descriptor for `InlineCard`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inlineCardDescriptor = $convert.base64Decode(
    'CgpJbmxpbmVDYXJkEj0KB2hlYWRpbmcYASABKAsyIy5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbH'
    'ZlZC5IZWFkaW5nUgdoZWFkaW5nEjQKBGl0ZW0YAiABKAsyIC5zcG90aWZ5LmNhc2l0YS52MS5y'
    'ZXNvbHZlZC5JdGVtUgRpdGVt');

@$core.Deprecated('Use audioSpotlightDescriptor instead')
const AudioSpotlight$json = {
  '1': 'AudioSpotlight',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'item'
    },
    {
      '1': 'ad_metadata',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.EmbeddedAdMetadata',
      '10': 'adMetadata'
    },
    {
      '1': 'preview_entity_uri',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'previewEntityUri'
    },
  ],
};

/// Descriptor for `AudioSpotlight`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioSpotlightDescriptor = $convert.base64Decode(
    'Cg5BdWRpb1Nwb3RsaWdodBI9CgdoZWFkaW5nGAEgASgLMiMuc3BvdGlmeS5jYXNpdGEudjEucm'
    'Vzb2x2ZWQuSGVhZGluZ1IHaGVhZGluZxI0CgRpdGVtGAIgASgLMiAuc3BvdGlmeS5jYXNpdGEu'
    'djEucmVzb2x2ZWQuSXRlbVIEaXRlbRJPCgthZF9tZXRhZGF0YRgDIAEoCzIuLnNwb3RpZnkuY2'
    'FzaXRhLnYxLnJlc29sdmVkLkVtYmVkZGVkQWRNZXRhZGF0YVIKYWRNZXRhZGF0YRIsChJwcmV2'
    'aWV3X2VudGl0eV91cmkYBCABKAlSEHByZXZpZXdFbnRpdHlVcmk=');

@$core.Deprecated('Use previewCarouselDescriptor instead')
const PreviewCarousel$json = {
  '1': 'PreviewCarousel',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'items'
    },
  ],
};

/// Descriptor for `PreviewCarousel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewCarouselDescriptor = $convert.base64Decode(
    'Cg9QcmV2aWV3Q2Fyb3VzZWwSPQoHaGVhZGluZxgBIAEoCzIjLnNwb3RpZnkuY2FzaXRhLnYxLn'
    'Jlc29sdmVkLkhlYWRpbmdSB2hlYWRpbmcSNgoFaXRlbXMYAiADKAsyIC5zcG90aWZ5LmNhc2l0'
    'YS52MS5yZXNvbHZlZC5JdGVtUgVpdGVtcw==');

@$core.Deprecated('Use previewPromotionCarouselDescriptor instead')
const PreviewPromotionCarousel$json = {
  '1': 'PreviewPromotionCarousel',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.PreviewPromotionCarouselItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `PreviewPromotionCarousel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewPromotionCarouselDescriptor = $convert.base64Decode(
    'ChhQcmV2aWV3UHJvbW90aW9uQ2Fyb3VzZWwSPQoHaGVhZGluZxgBIAEoCzIjLnNwb3RpZnkuY2'
    'FzaXRhLnYxLnJlc29sdmVkLkhlYWRpbmdSB2hlYWRpbmcSTgoFaXRlbXMYAiADKAsyOC5zcG90'
    'aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5QcmV2aWV3UHJvbW90aW9uQ2Fyb3VzZWxJdGVtUgVpdG'
    'Vtcw==');

@$core.Deprecated('Use previewPromotionCarouselItemDescriptor instead')
const PreviewPromotionCarouselItem$json = {
  '1': 'PreviewPromotionCarouselItem',
  '2': [
    {
      '1': 'item',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'item'
    },
  ],
};

/// Descriptor for `PreviewPromotionCarouselItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewPromotionCarouselItemDescriptor =
    $convert.base64Decode(
        'ChxQcmV2aWV3UHJvbW90aW9uQ2Fyb3VzZWxJdGVtEjQKBGl0ZW0YASABKAsyIC5zcG90aWZ5Lm'
        'Nhc2l0YS52MS5yZXNvbHZlZC5JdGVtUgRpdGVt');

@$core.Deprecated('Use reflectionDescriptor instead')
const Reflection$json = {
  '1': 'Reflection',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'item',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'item'
    },
  ],
};

/// Descriptor for `Reflection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reflectionDescriptor = $convert.base64Decode(
    'CgpSZWZsZWN0aW9uEj0KB2hlYWRpbmcYASABKAsyIy5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbH'
    'ZlZC5IZWFkaW5nUgdoZWFkaW5nEjQKBGl0ZW0YAiABKAsyIC5zcG90aWZ5LmNhc2l0YS52MS5y'
    'ZXNvbHZlZC5JdGVtUgRpdGVt');

@$core.Deprecated('Use embeddedAdMetadataDescriptor instead')
const EmbeddedAdMetadata$json = {
  '1': 'EmbeddedAdMetadata',
  '2': [
    {'1': 'tracking_id', '3': 1, '4': 1, '5': 9, '10': 'trackingId'},
  ],
};

/// Descriptor for `EmbeddedAdMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List embeddedAdMetadataDescriptor = $convert.base64Decode(
    'ChJFbWJlZGRlZEFkTWV0YWRhdGESHwoLdHJhY2tpbmdfaWQYASABKAlSCnRyYWNraW5nSWQ=');
