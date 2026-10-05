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
    {'1': 'response_id', '3': 1, '4': 1, '5': 9, '10': 'responseId'},
    {'1': 'page_uri', '3': 2, '4': 1, '5': 9, '10': 'pageUri'},
    {'1': 'page_token', '3': 3, '4': 1, '5': 9, '10': 'pageToken'},
    {'1': 'refresh_token', '3': 4, '4': 1, '5': 9, '10': 'refreshToken'},
  ],
};

/// Descriptor for `ResponseInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseInfoDescriptor = $convert.base64Decode(
    'CgxSZXNwb25zZUluZm8SHwoLcmVzcG9uc2VfaWQYASABKAlSCnJlc3BvbnNlSWQSGQoIcGFnZV'
    '91cmkYAiABKAlSB3BhZ2VVcmkSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuEiMKDXJl'
    'ZnJlc2hfdG9rZW4YBCABKAlSDHJlZnJlc2hUb2tlbg==');

@$core.Deprecated('Use debugInfoDescriptor instead')
const DebugInfo$json = {
  '1': 'DebugInfo',
  '2': [
    {
      '1': 'home_logging_span_id',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'homeLoggingSpanId'
    },
  ],
};

/// Descriptor for `DebugInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List debugInfoDescriptor = $convert.base64Decode(
    'CglEZWJ1Z0luZm8SLwoUaG9tZV9sb2dnaW5nX3NwYW5faWQYASABKAlSEWhvbWVMb2dnaW5nU3'
    'Bhbklk');

@$core.Deprecated('Use sandboxDebugInfoDescriptor instead')
const SandboxDebugInfo$json = {
  '1': 'SandboxDebugInfo',
  '2': [
    {
      '1': 'invalid_section_uris',
      '3': 1,
      '4': 3,
      '5': 9,
      '10': 'invalidSectionUris'
    },
    {
      '1': 'failed_sections',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.SectionFailure',
      '10': 'failedSections'
    },
  ],
};

/// Descriptor for `SandboxDebugInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sandboxDebugInfoDescriptor = $convert.base64Decode(
    'ChBTYW5kYm94RGVidWdJbmZvEjAKFGludmFsaWRfc2VjdGlvbl91cmlzGAEgAygJUhJpbnZhbG'
    'lkU2VjdGlvblVyaXMSUwoPZmFpbGVkX3NlY3Rpb25zGAIgAygLMiouc3BvdGlmeS5jYXNpdGEu'
    'djEucmVzb2x2ZWQuU2VjdGlvbkZhaWx1cmVSDmZhaWxlZFNlY3Rpb25z');

@$core.Deprecated('Use sectionFailureDescriptor instead')
const SectionFailure$json = {
  '1': 'SectionFailure',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'reason', '3': 2, '4': 1, '5': 9, '10': 'reason'},
    {'1': 'service_name', '3': 3, '4': 1, '5': 9, '10': 'serviceName'},
    {'1': 'status', '3': 4, '4': 1, '5': 9, '10': 'status'},
  ],
};

/// Descriptor for `SectionFailure`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionFailureDescriptor = $convert.base64Decode(
    'Cg5TZWN0aW9uRmFpbHVyZRIQCgN1cmkYASABKAlSA3VyaRIWCgZyZWFzb24YAiABKAlSBnJlYX'
    'NvbhIhCgxzZXJ2aWNlX25hbWUYAyABKAlSC3NlcnZpY2VOYW1lEhYKBnN0YXR1cxgEIAEoCVIG'
    'c3RhdHVz');

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
      '1': 'anchors',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Anchors',
      '9': 0,
      '10': 'anchors'
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
      '1': 'promotion_v1',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.PromotionV1',
      '9': 0,
      '10': 'promotionV1'
    },
    {
      '1': 'promotion_v3',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.PromotionV3',
      '9': 0,
      '10': 'promotionV3'
    },
    {
      '1': 'action_card_carousel',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.ActionCardCarousel',
      '9': 0,
      '10': 'actionCardCarousel'
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
      '1': 'video_promo',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.VideoPromo',
      '9': 0,
      '10': 'videoPromo'
    },
    {
      '1': 'banner',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Banner',
      '9': 0,
      '10': 'banner'
    },
    {
      '1': 'video_brand_ad',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.VideoBrandAd',
      '9': 0,
      '10': 'videoBrandAd'
    },
    {
      '1': 'image_brand_ad',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.ImageBrandAd',
      '9': 0,
      '10': 'imageBrandAd'
    },
    {
      '1': 'campaign_link_carousel',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.CampaignLinkCarousel',
      '9': 0,
      '10': 'campaignLinkCarousel'
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
      '1': 'full_bleed_banner',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.FullBleedBanner',
      '9': 0,
      '10': 'fullBleedBanner'
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
      '1': 'banner_with_animations',
      '3': 28,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.BannerWithAnimations',
      '9': 0,
      '10': 'bannerWithAnimations'
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
      '1': 'promptable_section',
      '3': 32,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.PromptableSection',
      '9': 0,
      '10': 'promptableSection'
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
      '1': 'play_link_promo',
      '3': 35,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.PlayLinkPromo',
      '9': 0,
      '10': 'playLinkPromo'
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
      '1': 'concert_campaign',
      '3': 38,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.ConcertCampaign',
      '9': 0,
      '10': 'concertCampaign'
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
      '1': 'prompted_worlds_shelf',
      '3': 40,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.PromptedWorldsShelf',
      '9': 0,
      '10': 'promptedWorldsShelf'
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
    {
      '1': 'user_prompted_world_entrypoint',
      '3': 42,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.UserPromptedWorldEntrypoint',
      '9': 0,
      '10': 'userPromptedWorldEntrypoint'
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
    'c2l0YS52MS5yZXNvbHZlZC5JbW1lcnNpdmVQcmV2aWV3SABSEGltbWVyc2l2ZVByZXZpZXcSPw'
    'oHYW5jaG9ycxgHIAEoCzIjLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLkFuY2hvcnNIAFIH'
    'YW5jaG9ycxJrChdjb250ZW50X2V2YWx1YXRpb25fbGlzdBgIIAEoCzIxLnNwb3RpZnkuY2FzaX'
    'RhLnYxLnJlc29sdmVkLkNvbnRlbnRFdmFsdWF0aW9uTGlzdEgAUhVjb250ZW50RXZhbHVhdGlv'
    'bkxpc3QSUAoOY2FsbF90b19hY3Rpb24YCSABKAsyKC5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbH'
    'ZlZC5DYWxsVG9BY3Rpb25IAFIMY2FsbFRvQWN0aW9uEk8KDXJlY2VudHNfc2hlbGYYCiABKAsy'
    'KC5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5SZWNlbnRzU2hlbGZIAFIMcmVjZW50c1NoZW'
    'xmEkYKCndhdGNoX2ZlZWQYCyABKAsyJS5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5XYXRj'
    'aEZlZWRIAFIJd2F0Y2hGZWVkEkwKDHByb21vdGlvbl92MRgMIAEoCzInLnNwb3RpZnkuY2FzaX'
    'RhLnYxLnJlc29sdmVkLlByb21vdGlvblYxSABSC3Byb21vdGlvblYxEkwKDHByb21vdGlvbl92'
    'MxgNIAEoCzInLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLlByb21vdGlvblYzSABSC3Byb2'
    '1vdGlvblYzEmIKFGFjdGlvbl9jYXJkX2Nhcm91c2VsGA8gASgLMi4uc3BvdGlmeS5jYXNpdGEu'
    'djEucmVzb2x2ZWQuQWN0aW9uQ2FyZENhcm91c2VsSABSEmFjdGlvbkNhcmRDYXJvdXNlbBJGCg'
    'psaXZlX2V2ZW50GBAgASgLMiUuc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZWQuTGl2ZUV2ZW50'
    'SABSCWxpdmVFdmVudBJCCghzaG93Y2FzZRgRIAEoCzIkLnNwb3RpZnkuY2FzaXRhLnYxLnJlc2'
    '9sdmVkLlNob3djYXNlSABSCHNob3djYXNlEkkKC3ZpZGVvX3Byb21vGBIgASgLMiYuc3BvdGlm'
    'eS5jYXNpdGEudjEucmVzb2x2ZWQuVmlkZW9Qcm9tb0gAUgp2aWRlb1Byb21vEjwKBmJhbm5lch'
    'gTIAEoCzIiLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLkJhbm5lckgAUgZiYW5uZXISUAoO'
    'dmlkZW9fYnJhbmRfYWQYFCABKAsyKC5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5WaWRlb0'
    'JyYW5kQWRIAFIMdmlkZW9CcmFuZEFkElAKDmltYWdlX2JyYW5kX2FkGBUgASgLMiguc3BvdGlm'
    'eS5jYXNpdGEudjEucmVzb2x2ZWQuSW1hZ2VCcmFuZEFkSABSDGltYWdlQnJhbmRBZBJoChZjYW'
    '1wYWlnbl9saW5rX2Nhcm91c2VsGBcgASgLMjAuc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZWQu'
    'Q2FtcGFpZ25MaW5rQ2Fyb3VzZWxIAFIUY2FtcGFpZ25MaW5rQ2Fyb3VzZWwSZQoVdmVydGljYW'
    'xfc2luZ2xlX2VudHJ5GBggASgLMi8uc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZWQuVmVydGlj'
    'YWxTaW5nbGVFbnRyeUgAUhN2ZXJ0aWNhbFNpbmdsZUVudHJ5ElIKDnZpZGVvX2Nhcm91c2VsGB'
    'kgASgLMikuc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZWQuVmlkZW9DYXJvdXNlbEgAUg12aWRl'
    'b0Nhcm91c2VsElkKEWZ1bGxfYmxlZWRfYmFubmVyGBogASgLMisuc3BvdGlmeS5jYXNpdGEudj'
    'EucmVzb2x2ZWQuRnVsbEJsZWVkQmFubmVySABSD2Z1bGxCbGVlZEJhbm5lchJeChJhc3NvY2lh'
    'dGVkX3ByZXZpZXcYGyABKAsyLS5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5Bc3NvY2lhdG'
    'VkUHJldmlld0gAUhFhc3NvY2lhdGVkUHJldmlldxJoChZiYW5uZXJfd2l0aF9hbmltYXRpb25z'
    'GBwgASgLMjAuc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZWQuQmFubmVyV2l0aEFuaW1hdGlvbn'
    'NIAFIUYmFubmVyV2l0aEFuaW1hdGlvbnMSRQoJbmFycmF0aXZlGB0gASgLMiUuc3BvdGlmeS5j'
    'YXNpdGEudjEucmVzb2x2ZWQuTmFycmF0aXZlSABSCW5hcnJhdGl2ZRJqChZpbnRlcmFjdGl2ZV'
    '9lbnRyeXBvaW50GB4gASgLMjEuc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZWQuSW50ZXJhY3Rp'
    'dmVFbnRyeXBvaW50SABSFWludGVyYWN0aXZlRW50cnlwb2ludBJcChJ0b3Bfc3RvcnlfY2Fyb3'
    'VzZWwYHyABKAsyLC5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5Ub3BTdG9yeUNhcm91c2Vs'
    'SABSEHRvcFN0b3J5Q2Fyb3VzZWwSXgoScHJvbXB0YWJsZV9zZWN0aW9uGCAgASgLMi0uc3BvdG'
    'lmeS5jYXNpdGEudjEucmVzb2x2ZWQuUHJvbXB0YWJsZVNlY3Rpb25IAFIRcHJvbXB0YWJsZVNl'
    'Y3Rpb24SSQoLYXVkaW9fcHJvbW8YISABKAsyJi5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC'
    '5BdWRpb1Byb21vSABSCmF1ZGlvUHJvbW8SSQoLaW5saW5lX2NhcmQYIiABKAsyJi5zcG90aWZ5'
    'LmNhc2l0YS52MS5yZXNvbHZlZC5JbmxpbmVDYXJkSABSCmlubGluZUNhcmQSUwoPcGxheV9saW'
    '5rX3Byb21vGCMgASgLMikuc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZWQuUGxheUxpbmtQcm9t'
    'b0gAUg1wbGF5TGlua1Byb21vElUKD2F1ZGlvX3Nwb3RsaWdodBgkIAEoCzIqLnNwb3RpZnkuY2'
    'FzaXRhLnYxLnJlc29sdmVkLkF1ZGlvU3BvdGxpZ2h0SABSDmF1ZGlvU3BvdGxpZ2h0ElgKEHBy'
    'ZXZpZXdfY2Fyb3VzZWwYJSABKAsyKy5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5QcmV2aW'
    'V3Q2Fyb3VzZWxIAFIPcHJldmlld0Nhcm91c2VsElgKEGNvbmNlcnRfY2FtcGFpZ24YJiABKAsy'
    'Ky5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5Db25jZXJ0Q2FtcGFpZ25IAFIPY29uY2VydE'
    'NhbXBhaWduEnQKGnByZXZpZXdfcHJvbW90aW9uX2Nhcm91c2VsGCcgASgLMjQuc3BvdGlmeS5j'
    'YXNpdGEudjEucmVzb2x2ZWQuUHJldmlld1Byb21vdGlvbkNhcm91c2VsSABSGHByZXZpZXdQcm'
    '9tb3Rpb25DYXJvdXNlbBJlChVwcm9tcHRlZF93b3JsZHNfc2hlbGYYKCABKAsyLy5zcG90aWZ5'
    'LmNhc2l0YS52MS5yZXNvbHZlZC5Qcm9tcHRlZFdvcmxkc1NoZWxmSABSE3Byb21wdGVkV29ybG'
    'RzU2hlbGYSSAoKcmVmbGVjdGlvbhgpIAEoCzImLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVk'
    'LlJlZmxlY3Rpb25IAFIKcmVmbGVjdGlvbhJ+Ch51c2VyX3Byb21wdGVkX3dvcmxkX2VudHJ5cG'
    '9pbnQYKiABKAsyNy5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5Vc2VyUHJvbXB0ZWRXb3Js'
    'ZEVudHJ5cG9pbnRIAFIbdXNlclByb21wdGVkV29ybGRFbnRyeXBvaW50Qg4KDGZlYXR1cmVfdH'
    'lwZQ==');

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
    {'1': 'list_uri', '3': 1, '4': 1, '5': 9, '10': 'listUri'},
  ],
};

/// Descriptor for `ListPlatform`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listPlatformDescriptor = $convert
    .base64Decode('CgxMaXN0UGxhdGZvcm0SGQoIbGlzdF91cmkYASABKAlSB2xpc3RVcmk=');

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
    {'1': 'subtitle', '3': 2, '4': 1, '5': 9, '10': 'subtitle'},
  ],
};

/// Descriptor for `SponsoredHeading`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sponsoredHeadingDescriptor = $convert.base64Decode(
    'ChBTcG9uc29yZWRIZWFkaW5nEhIKBHRleHQYASABKAlSBHRleHQSGgoIc3VidGl0bGUYAiABKA'
    'lSCHN1YnRpdGxl');

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

@$core.Deprecated('Use anchorsDescriptor instead')
const Anchors$json = {
  '1': 'Anchors',
  '2': [
    {
      '1': 'item_source',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.ItemSource',
      '10': 'itemSource'
    },
  ],
};

/// Descriptor for `Anchors`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List anchorsDescriptor = $convert.base64Decode(
    'CgdBbmNob3JzEkcKC2l0ZW1fc291cmNlGAEgASgLMiYuc3BvdGlmeS5jYXNpdGEudjEucmVzb2'
    'x2ZWQuSXRlbVNvdXJjZVIKaXRlbVNvdXJjZQ==');

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
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ContentEvaluationList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contentEvaluationListDescriptor = $convert.base64Decode(
    'ChVDb250ZW50RXZhbHVhdGlvbkxpc3QSPQoHaGVhZGluZxgBIAEoCzIjLnNwb3RpZnkuY2FzaX'
    'RhLnYxLnJlc29sdmVkLkhlYWRpbmdSB2hlYWRpbmcSNgoFaXRlbXMYAiADKAsyIC5zcG90aWZ5'
    'LmNhc2l0YS52MS5yZXNvbHZlZC5JdGVtUgVpdGVtcw==');

@$core.Deprecated('Use callToActionDescriptor instead')
const CallToAction$json = {
  '1': 'CallToAction',
  '2': [
    {
      '1': 'rich_call_to_action',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.RichCallToAction',
      '9': 0,
      '10': 'richCallToAction'
    },
    {
      '1': 'simple_call_to_action',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.SimpleCallToAction',
      '9': 0,
      '10': 'simpleCallToAction'
    },
    {
      '1': 'dj_call_to_action',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.DjCallToAction',
      '9': 0,
      '10': 'djCallToAction'
    },
  ],
  '8': [
    {'1': 'variant'},
  ],
};

/// Descriptor for `CallToAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List callToActionDescriptor = $convert.base64Decode(
    'CgxDYWxsVG9BY3Rpb24SXQoTcmljaF9jYWxsX3RvX2FjdGlvbhgBIAEoCzIsLnNwb3RpZnkuY2'
    'FzaXRhLnYxLnJlc29sdmVkLlJpY2hDYWxsVG9BY3Rpb25IAFIQcmljaENhbGxUb0FjdGlvbhJj'
    'ChVzaW1wbGVfY2FsbF90b19hY3Rpb24YAiABKAsyLi5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbH'
    'ZlZC5TaW1wbGVDYWxsVG9BY3Rpb25IAFISc2ltcGxlQ2FsbFRvQWN0aW9uElcKEWRqX2NhbGxf'
    'dG9fYWN0aW9uGAMgASgLMiouc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZWQuRGpDYWxsVG9BY3'
    'Rpb25IAFIOZGpDYWxsVG9BY3Rpb25CCQoHdmFyaWFudA==');

@$core.Deprecated('Use richCallToActionDescriptor instead')
const RichCallToAction$json = {
  '1': 'RichCallToAction',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 5, '10': 'type'},
    {'1': 'image_url', '3': 2, '4': 1, '5': 9, '10': 'imageUrl'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'subtitle', '3': 4, '4': 1, '5': 9, '10': 'subtitle'},
    {
      '1': 'call_to_action_text',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'callToActionText'
    },
    {'1': 'is_dismissible', '3': 6, '4': 1, '5': 8, '10': 'isDismissible'},
  ],
};

/// Descriptor for `RichCallToAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List richCallToActionDescriptor = $convert.base64Decode(
    'ChBSaWNoQ2FsbFRvQWN0aW9uEhIKBHR5cGUYASABKAVSBHR5cGUSGwoJaW1hZ2VfdXJsGAIgAS'
    'gJUghpbWFnZVVybBIUCgV0aXRsZRgDIAEoCVIFdGl0bGUSGgoIc3VidGl0bGUYBCABKAlSCHN1'
    'YnRpdGxlEi0KE2NhbGxfdG9fYWN0aW9uX3RleHQYBSABKAlSEGNhbGxUb0FjdGlvblRleHQSJQ'
    'oOaXNfZGlzbWlzc2libGUYBiABKAhSDWlzRGlzbWlzc2libGU=');

@$core.Deprecated('Use simpleCallToActionDescriptor instead')
const SimpleCallToAction$json = {
  '1': 'SimpleCallToAction',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 5, '10': 'type'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {
      '1': 'call_to_action_text',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'callToActionText'
    },
  ],
};

/// Descriptor for `SimpleCallToAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List simpleCallToActionDescriptor = $convert.base64Decode(
    'ChJTaW1wbGVDYWxsVG9BY3Rpb24SEgoEdHlwZRgBIAEoBVIEdHlwZRIUCgV0aXRsZRgCIAEoCV'
    'IFdGl0bGUSLQoTY2FsbF90b19hY3Rpb25fdGV4dBgDIAEoCVIQY2FsbFRvQWN0aW9uVGV4dA==');

@$core.Deprecated('Use djCallToActionDescriptor instead')
const DjCallToAction$json = {
  '1': 'DjCallToAction',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'subtitle', '3': 3, '4': 1, '5': 9, '10': 'subtitle'},
    {
      '1': 'visual_metadata',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.DjVisualMetadata',
      '10': 'visualMetadata'
    },
    {'1': 'transcript', '3': 5, '4': 1, '5': 9, '10': 'transcript'},
    {
      '1': 'heading',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Heading',
      '10': 'heading'
    },
    {'1': 'animation_url', '3': 7, '4': 1, '5': 9, '10': 'animationUrl'},
    {'1': 'transcript_key', '3': 8, '4': 1, '5': 9, '10': 'transcriptKey'},
  ],
};

/// Descriptor for `DjCallToAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List djCallToActionDescriptor = $convert.base64Decode(
    'Cg5EakNhbGxUb0FjdGlvbhIQCgN1cmkYASABKAlSA3VyaRIUCgV0aXRsZRgCIAEoCVIFdGl0bG'
    'USGgoIc3VidGl0bGUYAyABKAlSCHN1YnRpdGxlElUKD3Zpc3VhbF9tZXRhZGF0YRgEIAEoCzIs'
    'LnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLkRqVmlzdWFsTWV0YWRhdGFSDnZpc3VhbE1ldG'
    'FkYXRhEh4KCnRyYW5zY3JpcHQYBSABKAlSCnRyYW5zY3JpcHQSPQoHaGVhZGluZxgGIAEoCzIj'
    'LnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLkhlYWRpbmdSB2hlYWRpbmcSIwoNYW5pbWF0aW'
    '9uX3VybBgHIAEoCVIMYW5pbWF0aW9uVXJsEiUKDnRyYW5zY3JpcHRfa2V5GAggASgJUg10cmFu'
    'c2NyaXB0S2V5');

@$core.Deprecated('Use djVisualMetadataDescriptor instead')
const DjVisualMetadata$json = {
  '1': 'DjVisualMetadata',
  '2': [
    {'1': 'background_color', '3': 1, '4': 1, '5': 9, '10': 'backgroundColor'},
    {'1': 'background_image', '3': 2, '4': 1, '5': 9, '10': 'backgroundImage'},
    {
      '1': 'jellyfish_top_color',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'jellyfishTopColor'
    },
    {
      '1': 'jellyfish_mid_color',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'jellyfishMidColor'
    },
    {
      '1': 'jellyfish_bottom_color',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'jellyfishBottomColor'
    },
    {'1': 'tag_color', '3': 6, '4': 1, '5': 9, '10': 'tagColor'},
    {'1': 'text_color', '3': 7, '4': 1, '5': 9, '10': 'textColor'},
  ],
};

/// Descriptor for `DjVisualMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List djVisualMetadataDescriptor = $convert.base64Decode(
    'ChBEalZpc3VhbE1ldGFkYXRhEikKEGJhY2tncm91bmRfY29sb3IYASABKAlSD2JhY2tncm91bm'
    'RDb2xvchIpChBiYWNrZ3JvdW5kX2ltYWdlGAIgASgJUg9iYWNrZ3JvdW5kSW1hZ2USLgoTamVs'
    'bHlmaXNoX3RvcF9jb2xvchgDIAEoCVIRamVsbHlmaXNoVG9wQ29sb3ISLgoTamVsbHlmaXNoX2'
    '1pZF9jb2xvchgEIAEoCVIRamVsbHlmaXNoTWlkQ29sb3ISNAoWamVsbHlmaXNoX2JvdHRvbV9j'
    'b2xvchgFIAEoCVIUamVsbHlmaXNoQm90dG9tQ29sb3ISGwoJdGFnX2NvbG9yGAYgASgJUgh0YW'
    'dDb2xvchIdCgp0ZXh0X2NvbG9yGAcgASgJUgl0ZXh0Q29sb3I=');

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
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.WatchFeedItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `WatchFeed`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchFeedDescriptor = $convert.base64Decode(
    'CglXYXRjaEZlZWQSPQoHaGVhZGluZxgBIAEoCzIjLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdm'
    'VkLkhlYWRpbmdSB2hlYWRpbmcSPwoFaXRlbXMYAiADKAsyKS5zcG90aWZ5LmNhc2l0YS52MS5y'
    'ZXNvbHZlZC5XYXRjaEZlZWRJdGVtUgVpdGVtcw==');

@$core.Deprecated('Use watchFeedItemDescriptor instead')
const WatchFeedItem$json = {
  '1': 'WatchFeedItem',
  '2': [
    {
      '1': 'item',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'item'
    },
    {
      '1': 'entrypoint',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.WatchFeedEntrypoint',
      '10': 'entrypoint'
    },
    {
      '1': 'watch_feed_item_metadata',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.WatchFeedItemMetadata',
      '10': 'watchFeedItemMetadata'
    },
  ],
};

/// Descriptor for `WatchFeedItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchFeedItemDescriptor = $convert.base64Decode(
    'Cg1XYXRjaEZlZWRJdGVtEjQKBGl0ZW0YASABKAsyIC5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbH'
    'ZlZC5JdGVtUgRpdGVtEk8KCmVudHJ5cG9pbnQYAiABKAsyLy5zcG90aWZ5LmNhc2l0YS52MS5y'
    'ZXNvbHZlZC5XYXRjaEZlZWRFbnRyeXBvaW50UgplbnRyeXBvaW50EmoKGHdhdGNoX2ZlZWRfaX'
    'RlbV9tZXRhZGF0YRgDIAEoCzIxLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLldhdGNoRmVl'
    'ZEl0ZW1NZXRhZGF0YVIVd2F0Y2hGZWVkSXRlbU1ldGFkYXRh');

@$core.Deprecated('Use watchFeedEntrypointDescriptor instead')
const WatchFeedEntrypoint$json = {
  '1': 'WatchFeedEntrypoint',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'first_item_uri', '3': 2, '4': 1, '5': 9, '10': 'firstItemUri'},
    {'1': 'overline', '3': 3, '4': 1, '5': 9, '10': 'overline'},
    {'1': 'title', '3': 4, '4': 1, '5': 9, '10': 'title'},
    {'1': 'subtitle', '3': 5, '4': 1, '5': 9, '10': 'subtitle'},
    {
      '1': 'thumbnail_image',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.WatchFeedImage',
      '10': 'thumbnailImage'
    },
    {
      '1': 'video_file',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.WatchFeedVideoFile',
      '10': 'videoFile'
    },
    {'1': 'navigation_uri', '3': 8, '4': 1, '5': 9, '10': 'navigationUri'},
    {'1': 'accessibility', '3': 9, '4': 1, '5': 9, '10': 'accessibility'},
    {
      '1': 'cover_image',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.WatchFeedImage',
      '10': 'coverImage'
    },
    {'1': 'decision_id', '3': 11, '4': 1, '5': 9, '10': 'decisionId'},
    {
      '1': 'portrait_horizontal_focus_center_percentage',
      '3': 12,
      '4': 1,
      '5': 1,
      '10': 'portraitHorizontalFocusCenterPercentage'
    },
    {
      '1': 'logo_image',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.WatchFeedImage',
      '10': 'logoImage'
    },
  ],
};

/// Descriptor for `WatchFeedEntrypoint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchFeedEntrypointDescriptor = $convert.base64Decode(
    'ChNXYXRjaEZlZWRFbnRyeXBvaW50EhAKA3VyaRgBIAEoCVIDdXJpEiQKDmZpcnN0X2l0ZW1fdX'
    'JpGAIgASgJUgxmaXJzdEl0ZW1VcmkSGgoIb3ZlcmxpbmUYAyABKAlSCG92ZXJsaW5lEhQKBXRp'
    'dGxlGAQgASgJUgV0aXRsZRIaCghzdWJ0aXRsZRgFIAEoCVIIc3VidGl0bGUSUwoPdGh1bWJuYW'
    'lsX2ltYWdlGAYgASgLMiouc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZWQuV2F0Y2hGZWVkSW1h'
    'Z2VSDnRodW1ibmFpbEltYWdlEk0KCnZpZGVvX2ZpbGUYByABKAsyLi5zcG90aWZ5LmNhc2l0YS'
    '52MS5yZXNvbHZlZC5XYXRjaEZlZWRWaWRlb0ZpbGVSCXZpZGVvRmlsZRIlCg5uYXZpZ2F0aW9u'
    'X3VyaRgIIAEoCVINbmF2aWdhdGlvblVyaRIkCg1hY2Nlc3NpYmlsaXR5GAkgASgJUg1hY2Nlc3'
    'NpYmlsaXR5EksKC2NvdmVyX2ltYWdlGAogASgLMiouc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2'
    'ZWQuV2F0Y2hGZWVkSW1hZ2VSCmNvdmVySW1hZ2USHwoLZGVjaXNpb25faWQYCyABKAlSCmRlY2'
    'lzaW9uSWQSXAorcG9ydHJhaXRfaG9yaXpvbnRhbF9mb2N1c19jZW50ZXJfcGVyY2VudGFnZRgM'
    'IAEoAVIncG9ydHJhaXRIb3Jpem9udGFsRm9jdXNDZW50ZXJQZXJjZW50YWdlEkkKCmxvZ29faW'
    '1hZ2UYDSABKAsyKi5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5XYXRjaEZlZWRJbWFnZVIJ'
    'bG9nb0ltYWdl');

@$core.Deprecated('Use watchFeedImageDescriptor instead')
const WatchFeedImage$json = {
  '1': 'WatchFeedImage',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    {'1': 'placeholder', '3': 2, '4': 1, '5': 9, '10': 'placeholder'},
  ],
};

/// Descriptor for `WatchFeedImage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchFeedImageDescriptor = $convert.base64Decode(
    'Cg5XYXRjaEZlZWRJbWFnZRIQCgN1cmwYASABKAlSA3VybBIgCgtwbGFjZWhvbGRlchgCIAEoCV'
    'ILcGxhY2Vob2xkZXI=');

@$core.Deprecated('Use watchFeedVideoFileDescriptor instead')
const WatchFeedVideoFile$json = {
  '1': 'WatchFeedVideoFile',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'type', '3': 2, '4': 1, '5': 5, '10': 'type'},
    {'1': 'start_time', '3': 3, '4': 1, '5': 3, '10': 'startTime'},
    {'1': 'end_time', '3': 4, '4': 1, '5': 3, '10': 'endTime'},
  ],
};

/// Descriptor for `WatchFeedVideoFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchFeedVideoFileDescriptor = $convert.base64Decode(
    'ChJXYXRjaEZlZWRWaWRlb0ZpbGUSEAoDdXJpGAEgASgJUgN1cmkSEgoEdHlwZRgCIAEoBVIEdH'
    'lwZRIdCgpzdGFydF90aW1lGAMgASgDUglzdGFydFRpbWUSGQoIZW5kX3RpbWUYBCABKANSB2Vu'
    'ZFRpbWU=');

@$core.Deprecated('Use watchFeedItemMetadataDescriptor instead')
const WatchFeedItemMetadata$json = {
  '1': 'WatchFeedItemMetadata',
  '2': [
    {'1': 'decision_id', '3': 1, '4': 1, '5': 9, '10': 'decisionId'},
    {'1': 'navigation_uri', '3': 2, '4': 1, '5': 9, '10': 'navigationUri'},
    {'1': 'first_item_uri', '3': 3, '4': 1, '5': 9, '10': 'firstItemUri'},
  ],
};

/// Descriptor for `WatchFeedItemMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchFeedItemMetadataDescriptor = $convert.base64Decode(
    'ChVXYXRjaEZlZWRJdGVtTWV0YWRhdGESHwoLZGVjaXNpb25faWQYASABKAlSCmRlY2lzaW9uSW'
    'QSJQoObmF2aWdhdGlvbl91cmkYAiABKAlSDW5hdmlnYXRpb25VcmkSJAoOZmlyc3RfaXRlbV91'
    'cmkYAyABKAlSDGZpcnN0SXRlbVVyaQ==');

@$core.Deprecated('Use promotionV1Descriptor instead')
const PromotionV1$json = {
  '1': 'PromotionV1',
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
    {'1': 'type', '3': 4, '4': 1, '5': 5, '10': 'type'},
  ],
};

/// Descriptor for `PromotionV1`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promotionV1Descriptor = $convert.base64Decode(
    'CgtQcm9tb3Rpb25WMRI9CgdoZWFkaW5nGAEgASgLMiMuc3BvdGlmeS5jYXNpdGEudjEucmVzb2'
    'x2ZWQuSGVhZGluZ1IHaGVhZGluZxI0CgRpdGVtGAIgASgLMiAuc3BvdGlmeS5jYXNpdGEudjEu'
    'cmVzb2x2ZWQuSXRlbVIEaXRlbRJPCgthZF9tZXRhZGF0YRgDIAEoCzIuLnNwb3RpZnkuY2FzaX'
    'RhLnYxLnJlc29sdmVkLkVtYmVkZGVkQWRNZXRhZGF0YVIKYWRNZXRhZGF0YRISCgR0eXBlGAQg'
    'ASgFUgR0eXBl');

@$core.Deprecated('Use promotionV3Descriptor instead')
const PromotionV3$json = {
  '1': 'PromotionV3',
  '2': [
    {
      '1': 'item',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'item'
    },
    {
      '1': 'ad_metadata',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.EmbeddedAdMetadata',
      '10': 'adMetadata'
    },
  ],
};

/// Descriptor for `PromotionV3`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promotionV3Descriptor = $convert.base64Decode(
    'CgtQcm9tb3Rpb25WMxI0CgRpdGVtGAEgASgLMiAuc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZW'
    'QuSXRlbVIEaXRlbRJPCgthZF9tZXRhZGF0YRgCIAEoCzIuLnNwb3RpZnkuY2FzaXRhLnYxLnJl'
    'c29sdmVkLkVtYmVkZGVkQWRNZXRhZGF0YVIKYWRNZXRhZGF0YQ==');

@$core.Deprecated('Use actionCardCarouselDescriptor instead')
const ActionCardCarousel$json = {
  '1': 'ActionCardCarousel',
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

/// Descriptor for `ActionCardCarousel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List actionCardCarouselDescriptor = $convert.base64Decode(
    'ChJBY3Rpb25DYXJkQ2Fyb3VzZWwSPQoHaGVhZGluZxgBIAEoCzIjLnNwb3RpZnkuY2FzaXRhLn'
    'YxLnJlc29sdmVkLkhlYWRpbmdSB2hlYWRpbmcSNgoFaXRlbXMYAiADKAsyIC5zcG90aWZ5LmNh'
    'c2l0YS52MS5yZXNvbHZlZC5JdGVtUgVpdGVtcw==');

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
      '1': 'item_source',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.ItemSource',
      '10': 'itemSource'
    },
  ],
};

/// Descriptor for `LiveEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List liveEventDescriptor = $convert.base64Decode(
    'CglMaXZlRXZlbnQSPQoHaGVhZGluZxgBIAEoCzIjLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdm'
    'VkLkhlYWRpbmdSB2hlYWRpbmcSRwoLaXRlbV9zb3VyY2UYAiABKAsyJi5zcG90aWZ5LmNhc2l0'
    'YS52MS5yZXNvbHZlZC5JdGVtU291cmNlUgppdGVtU291cmNl');

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

@$core.Deprecated('Use videoPromoDescriptor instead')
const VideoPromo$json = {
  '1': 'VideoPromo',
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

/// Descriptor for `VideoPromo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoPromoDescriptor = $convert.base64Decode(
    'CgpWaWRlb1Byb21vEj0KB2hlYWRpbmcYASABKAsyIy5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbH'
    'ZlZC5IZWFkaW5nUgdoZWFkaW5nEjQKBGl0ZW0YAiABKAsyIC5zcG90aWZ5LmNhc2l0YS52MS5y'
    'ZXNvbHZlZC5JdGVtUgRpdGVtEh0KCnRhcmdldF91cmkYAyABKAlSCXRhcmdldFVyaRJPCgthZF'
    '9tZXRhZGF0YRgEIAEoCzIuLnNwb3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLkVtYmVkZGVkQWRN'
    'ZXRhZGF0YVIKYWRNZXRhZGF0YQ==');

@$core.Deprecated('Use bannerDescriptor instead')
const Banner$json = {
  '1': 'Banner',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 5, '10': 'type'},
    {'1': 'color_code', '3': 2, '4': 1, '5': 9, '10': 'colorCode'},
  ],
};

/// Descriptor for `Banner`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bannerDescriptor = $convert.base64Decode(
    'CgZCYW5uZXISEgoEdHlwZRgBIAEoBVIEdHlwZRIdCgpjb2xvcl9jb2RlGAIgASgJUgljb2xvck'
    'NvZGU=');

@$core.Deprecated('Use videoBrandAdDescriptor instead')
const VideoBrandAd$json = {
  '1': 'VideoBrandAd',
  '2': [
    {
      '1': 'ad',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.EmbeddedAd',
      '10': 'ad'
    },
    {
      '1': 'ad_metadata',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.EmbeddedAdMetadata',
      '10': 'adMetadata'
    },
  ],
};

/// Descriptor for `VideoBrandAd`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoBrandAdDescriptor = $convert.base64Decode(
    'CgxWaWRlb0JyYW5kQWQSNgoCYWQYASABKAsyJi5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC'
    '5FbWJlZGRlZEFkUgJhZBJPCgthZF9tZXRhZGF0YRgCIAEoCzIuLnNwb3RpZnkuY2FzaXRhLnYx'
    'LnJlc29sdmVkLkVtYmVkZGVkQWRNZXRhZGF0YVIKYWRNZXRhZGF0YQ==');

@$core.Deprecated('Use imageBrandAdDescriptor instead')
const ImageBrandAd$json = {
  '1': 'ImageBrandAd',
  '2': [
    {
      '1': 'ad',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.EmbeddedAd',
      '10': 'ad'
    },
    {
      '1': 'ad_metadata',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.EmbeddedAdMetadata',
      '10': 'adMetadata'
    },
  ],
};

/// Descriptor for `ImageBrandAd`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imageBrandAdDescriptor = $convert.base64Decode(
    'CgxJbWFnZUJyYW5kQWQSNgoCYWQYASABKAsyJi5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC'
    '5FbWJlZGRlZEFkUgJhZBJPCgthZF9tZXRhZGF0YRgCIAEoCzIuLnNwb3RpZnkuY2FzaXRhLnYx'
    'LnJlc29sdmVkLkVtYmVkZGVkQWRNZXRhZGF0YVIKYWRNZXRhZGF0YQ==');

@$core.Deprecated('Use embeddedAdDescriptor instead')
const EmbeddedAd$json = {
  '1': 'EmbeddedAd',
  '2': [
    {'1': 'advertiser', '3': 1, '4': 1, '5': 9, '10': 'advertiser'},
    {'1': 'call_to_action', '3': 2, '4': 1, '5': 9, '10': 'callToAction'},
    {'1': 'clickthrough_url', '3': 3, '4': 1, '5': 9, '10': 'clickthroughUrl'},
    {'1': 'tagline', '3': 7, '4': 1, '5': 9, '10': 'tagline'},
    {'1': 'logo_image_url', '3': 8, '4': 1, '5': 9, '10': 'logoImageUrl'},
  ],
};

/// Descriptor for `EmbeddedAd`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List embeddedAdDescriptor = $convert.base64Decode(
    'CgpFbWJlZGRlZEFkEh4KCmFkdmVydGlzZXIYASABKAlSCmFkdmVydGlzZXISJAoOY2FsbF90b1'
    '9hY3Rpb24YAiABKAlSDGNhbGxUb0FjdGlvbhIpChBjbGlja3Rocm91Z2hfdXJsGAMgASgJUg9j'
    'bGlja3Rocm91Z2hVcmwSGAoHdGFnbGluZRgHIAEoCVIHdGFnbGluZRIkCg5sb2dvX2ltYWdlX3'
    'VybBgIIAEoCVIMbG9nb0ltYWdlVXJs');

@$core.Deprecated('Use campaignLinkCarouselDescriptor instead')
const CampaignLinkCarousel$json = {
  '1': 'CampaignLinkCarousel',
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

/// Descriptor for `CampaignLinkCarousel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List campaignLinkCarouselDescriptor = $convert.base64Decode(
    'ChRDYW1wYWlnbkxpbmtDYXJvdXNlbBI9CgdoZWFkaW5nGAEgASgLMiMuc3BvdGlmeS5jYXNpdG'
    'EudjEucmVzb2x2ZWQuSGVhZGluZ1IHaGVhZGluZxJHCgtpdGVtX3NvdXJjZRgCIAEoCzImLnNw'
    'b3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLkl0ZW1Tb3VyY2VSCml0ZW1Tb3VyY2USTwoLYWRfbW'
    'V0YWRhdGEYAyABKAsyLi5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5FbWJlZGRlZEFkTWV0'
    'YWRhdGFSCmFkTWV0YWRhdGE=');

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
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'items'
    },
  ],
};

/// Descriptor for `VideoCarousel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoCarouselDescriptor = $convert.base64Decode(
    'Cg1WaWRlb0Nhcm91c2VsEj0KB2hlYWRpbmcYASABKAsyIy5zcG90aWZ5LmNhc2l0YS52MS5yZX'
    'NvbHZlZC5IZWFkaW5nUgdoZWFkaW5nEjYKBWl0ZW1zGAIgAygLMiAuc3BvdGlmeS5jYXNpdGEu'
    'djEucmVzb2x2ZWQuSXRlbVIFaXRlbXM=');

@$core.Deprecated('Use fullBleedBannerDescriptor instead')
const FullBleedBanner$json = {
  '1': 'FullBleedBanner',
  '2': [
    {'1': 'color_code', '3': 2, '4': 1, '5': 9, '10': 'colorCode'},
    {'1': 'image_url', '3': 3, '4': 1, '5': 9, '10': 'imageUrl'},
    {'1': 'description', '3': 4, '4': 1, '5': 9, '10': 'description'},
    {'1': 'accessibility', '3': 5, '4': 1, '5': 9, '10': 'accessibility'},
  ],
};

/// Descriptor for `FullBleedBanner`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fullBleedBannerDescriptor = $convert.base64Decode(
    'Cg9GdWxsQmxlZWRCYW5uZXISHQoKY29sb3JfY29kZRgCIAEoCVIJY29sb3JDb2RlEhsKCWltYW'
    'dlX3VybBgDIAEoCVIIaW1hZ2VVcmwSIAoLZGVzY3JpcHRpb24YBCABKAlSC2Rlc2NyaXB0aW9u'
    'EiQKDWFjY2Vzc2liaWxpdHkYBSABKAlSDWFjY2Vzc2liaWxpdHk=');

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

@$core.Deprecated('Use bannerWithAnimationsDescriptor instead')
const BannerWithAnimations$json = {
  '1': 'BannerWithAnimations',
  '2': [
    {
      '1': 'item',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'item'
    },
    {
      '1': 'ad_metadata',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.EmbeddedAdMetadata',
      '10': 'adMetadata'
    },
  ],
};

/// Descriptor for `BannerWithAnimations`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bannerWithAnimationsDescriptor = $convert.base64Decode(
    'ChRCYW5uZXJXaXRoQW5pbWF0aW9ucxI0CgRpdGVtGAEgASgLMiAuc3BvdGlmeS5jYXNpdGEudj'
    'EucmVzb2x2ZWQuSXRlbVIEaXRlbRJPCgthZF9tZXRhZGF0YRgCIAEoCzIuLnNwb3RpZnkuY2Fz'
    'aXRhLnYxLnJlc29sdmVkLkVtYmVkZGVkQWRNZXRhZGF0YVIKYWRNZXRhZGF0YQ==');

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
    {'1': 'prompt', '3': 1, '4': 1, '5': 9, '10': 'prompt'},
  ],
};

/// Descriptor for `InteractiveEntrypoint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List interactiveEntrypointDescriptor =
    $convert.base64Decode(
        'ChVJbnRlcmFjdGl2ZUVudHJ5cG9pbnQSFgoGcHJvbXB0GAEgASgJUgZwcm9tcHQ=');

@$core.Deprecated('Use topStoryCarouselDescriptor instead')
const TopStoryCarousel$json = {
  '1': 'TopStoryCarousel',
  '2': [
    {
      '1': 'stories',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.TopStory',
      '10': 'stories'
    },
  ],
};

/// Descriptor for `TopStoryCarousel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List topStoryCarouselDescriptor = $convert.base64Decode(
    'ChBUb3BTdG9yeUNhcm91c2VsEj4KB3N0b3JpZXMYASADKAsyJC5zcG90aWZ5LmNhc2l0YS52MS'
    '5yZXNvbHZlZC5Ub3BTdG9yeVIHc3Rvcmllcw==');

@$core.Deprecated('Use topStoryDescriptor instead')
const TopStory$json = {
  '1': 'TopStory',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'items',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.Item',
      '10': 'items'
    },
    {'1': 'story_id', '3': 4, '4': 1, '5': 9, '10': 'storyId'},
    {'1': 'created_at', '3': 5, '4': 1, '5': 3, '10': 'createdAt'},
  ],
};

/// Descriptor for `TopStory`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List topStoryDescriptor = $convert.base64Decode(
    'CghUb3BTdG9yeRIUCgV0aXRsZRgBIAEoCVIFdGl0bGUSIAoLZGVzY3JpcHRpb24YAiABKAlSC2'
    'Rlc2NyaXB0aW9uEjYKBWl0ZW1zGAMgAygLMiAuc3BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZWQu'
    'SXRlbVIFaXRlbXMSGQoIc3RvcnlfaWQYBCABKAlSB3N0b3J5SWQSHQoKY3JlYXRlZF9hdBgFIA'
    'EoA1IJY3JlYXRlZEF0');

@$core.Deprecated('Use promptableSectionDescriptor instead')
const PromptableSection$json = {
  '1': 'PromptableSection',
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
      '1': 'prompt_suggestions',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.PromptableSuggestion',
      '10': 'promptSuggestions'
    },
  ],
};

/// Descriptor for `PromptableSection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promptableSectionDescriptor = $convert.base64Decode(
    'ChFQcm9tcHRhYmxlU2VjdGlvbhI9CgdoZWFkaW5nGAEgASgLMiMuc3BvdGlmeS5jYXNpdGEudj'
    'EucmVzb2x2ZWQuSGVhZGluZ1IHaGVhZGluZxI0CgRpdGVtGAIgASgLMiAuc3BvdGlmeS5jYXNp'
    'dGEudjEucmVzb2x2ZWQuSXRlbVIEaXRlbRJfChJwcm9tcHRfc3VnZ2VzdGlvbnMYAyADKAsyMC'
    '5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5Qcm9tcHRhYmxlU3VnZ2VzdGlvblIRcHJvbXB0'
    'U3VnZ2VzdGlvbnM=');

@$core.Deprecated('Use promptableSuggestionDescriptor instead')
const PromptableSuggestion$json = {
  '1': 'PromptableSuggestion',
  '2': [
    {'1': 'suggestion', '3': 1, '4': 1, '5': 9, '10': 'suggestion'},
  ],
};

/// Descriptor for `PromptableSuggestion`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promptableSuggestionDescriptor = $convert.base64Decode(
    'ChRQcm9tcHRhYmxlU3VnZ2VzdGlvbhIeCgpzdWdnZXN0aW9uGAEgASgJUgpzdWdnZXN0aW9u');

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

/// Descriptor for `AudioPromo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioPromoDescriptor = $convert.base64Decode(
    'CgpBdWRpb1Byb21vEj0KB2hlYWRpbmcYASABKAsyIy5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbH'
    'ZlZC5IZWFkaW5nUgdoZWFkaW5nEjQKBGl0ZW0YAiABKAsyIC5zcG90aWZ5LmNhc2l0YS52MS5y'
    'ZXNvbHZlZC5JdGVtUgRpdGVtEk8KC2FkX21ldGFkYXRhGAMgASgLMi4uc3BvdGlmeS5jYXNpdG'
    'EudjEucmVzb2x2ZWQuRW1iZWRkZWRBZE1ldGFkYXRhUgphZE1ldGFkYXRhEiwKEnByZXZpZXdf'
    'ZW50aXR5X3VyaRgEIAEoCVIQcHJldmlld0VudGl0eVVyaQ==');

@$core.Deprecated('Use inlineCardDescriptor instead')
const InlineCard$json = {
  '1': 'InlineCard',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 5, '10': 'type'},
  ],
};

/// Descriptor for `InlineCard`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inlineCardDescriptor =
    $convert.base64Decode('CgpJbmxpbmVDYXJkEhIKBHR5cGUYASABKAVSBHR5cGU=');

@$core.Deprecated('Use playLinkPromoDescriptor instead')
const PlayLinkPromo$json = {
  '1': 'PlayLinkPromo',
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

/// Descriptor for `PlayLinkPromo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playLinkPromoDescriptor = $convert.base64Decode(
    'Cg1QbGF5TGlua1Byb21vEj0KB2hlYWRpbmcYASABKAsyIy5zcG90aWZ5LmNhc2l0YS52MS5yZX'
    'NvbHZlZC5IZWFkaW5nUgdoZWFkaW5nEjQKBGl0ZW0YAiABKAsyIC5zcG90aWZ5LmNhc2l0YS52'
    'MS5yZXNvbHZlZC5JdGVtUgRpdGVtEk8KC2FkX21ldGFkYXRhGAMgASgLMi4uc3BvdGlmeS5jYX'
    'NpdGEudjEucmVzb2x2ZWQuRW1iZWRkZWRBZE1ldGFkYXRhUgphZE1ldGFkYXRh');

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

@$core.Deprecated('Use concertCampaignDescriptor instead')
const ConcertCampaign$json = {
  '1': 'ConcertCampaign',
  '2': [
    {'1': 'campaign_uri', '3': 1, '4': 1, '5': 9, '10': 'campaignUri'},
  ],
};

/// Descriptor for `ConcertCampaign`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List concertCampaignDescriptor = $convert.base64Decode(
    'Cg9Db25jZXJ0Q2FtcGFpZ24SIQoMY2FtcGFpZ25fdXJpGAEgASgJUgtjYW1wYWlnblVyaQ==');

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
    {'1': 'promotion_uri', '3': 2, '4': 1, '5': 9, '10': 'promotionUri'},
    {
      '1': 'items',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.PreviewPromotionCarouselItem',
      '10': 'items'
    },
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

/// Descriptor for `PreviewPromotionCarousel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewPromotionCarouselDescriptor = $convert.base64Decode(
    'ChhQcmV2aWV3UHJvbW90aW9uQ2Fyb3VzZWwSPQoHaGVhZGluZxgBIAEoCzIjLnNwb3RpZnkuY2'
    'FzaXRhLnYxLnJlc29sdmVkLkhlYWRpbmdSB2hlYWRpbmcSIwoNcHJvbW90aW9uX3VyaRgCIAEo'
    'CVIMcHJvbW90aW9uVXJpEk4KBWl0ZW1zGAMgAygLMjguc3BvdGlmeS5jYXNpdGEudjEucmVzb2'
    'x2ZWQuUHJldmlld1Byb21vdGlvbkNhcm91c2VsSXRlbVIFaXRlbXMSTwoLYWRfbWV0YWRhdGEY'
    'BCABKAsyLi5zcG90aWZ5LmNhc2l0YS52MS5yZXNvbHZlZC5FbWJlZGRlZEFkTWV0YWRhdGFSCm'
    'FkTWV0YWRhdGE=');

@$core.Deprecated('Use previewPromotionCarouselItemDescriptor instead')
const PreviewPromotionCarouselItem$json = {
  '1': 'PreviewPromotionCarouselItem',
  '2': [
    {
      '1': 'video_promo',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.casita.v1.resolved.VideoPromo',
      '9': 0,
      '10': 'videoPromo'
    },
  ],
  '8': [
    {'1': 'content'},
  ],
};

/// Descriptor for `PreviewPromotionCarouselItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewPromotionCarouselItemDescriptor =
    $convert.base64Decode(
        'ChxQcmV2aWV3UHJvbW90aW9uQ2Fyb3VzZWxJdGVtEkkKC3ZpZGVvX3Byb21vGAEgASgLMiYuc3'
        'BvdGlmeS5jYXNpdGEudjEucmVzb2x2ZWQuVmlkZW9Qcm9tb0gAUgp2aWRlb1Byb21vQgkKB2Nv'
        'bnRlbnQ=');

@$core.Deprecated('Use promptedWorldsShelfDescriptor instead')
const PromptedWorldsShelf$json = {
  '1': 'PromptedWorldsShelf',
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
    {'1': 'list_uri', '3': 3, '4': 1, '5': 9, '10': 'listUri'},
  ],
};

/// Descriptor for `PromptedWorldsShelf`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promptedWorldsShelfDescriptor = $convert.base64Decode(
    'ChNQcm9tcHRlZFdvcmxkc1NoZWxmEj0KB2hlYWRpbmcYASABKAsyIy5zcG90aWZ5LmNhc2l0YS'
    '52MS5yZXNvbHZlZC5IZWFkaW5nUgdoZWFkaW5nEkcKC2l0ZW1fc291cmNlGAIgASgLMiYuc3Bv'
    'dGlmeS5jYXNpdGEudjEucmVzb2x2ZWQuSXRlbVNvdXJjZVIKaXRlbVNvdXJjZRIZCghsaXN0X3'
    'VyaRgDIAEoCVIHbGlzdFVyaQ==');

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

@$core.Deprecated('Use userPromptedWorldEntrypointDescriptor instead')
const UserPromptedWorldEntrypoint$json = {
  '1': 'UserPromptedWorldEntrypoint',
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

/// Descriptor for `UserPromptedWorldEntrypoint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userPromptedWorldEntrypointDescriptor =
    $convert.base64Decode(
        'ChtVc2VyUHJvbXB0ZWRXb3JsZEVudHJ5cG9pbnQSPQoHaGVhZGluZxgBIAEoCzIjLnNwb3RpZn'
        'kuY2FzaXRhLnYxLnJlc29sdmVkLkhlYWRpbmdSB2hlYWRpbmcSNAoEaXRlbRgCIAEoCzIgLnNw'
        'b3RpZnkuY2FzaXRhLnYxLnJlc29sdmVkLkl0ZW1SBGl0ZW0=');

@$core.Deprecated('Use embeddedAdMetadataDescriptor instead')
const EmbeddedAdMetadata$json = {
  '1': 'EmbeddedAdMetadata',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'creative_id', '3': 2, '4': 1, '5': 9, '10': 'creativeId'},
    {'1': 'playback_id', '3': 3, '4': 1, '5': 9, '10': 'playbackId'},
    {'1': 'product_name', '3': 4, '4': 1, '5': 9, '10': 'productName'},
    {'1': 'lineitem_id', '3': 5, '4': 1, '5': 9, '10': 'lineitemId'},
    {'1': 'slot', '3': 6, '4': 1, '5': 9, '10': 'slot'},
  ],
};

/// Descriptor for `EmbeddedAdMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List embeddedAdMetadataDescriptor = $convert.base64Decode(
    'ChJFbWJlZGRlZEFkTWV0YWRhdGESDgoCaWQYASABKAlSAmlkEh8KC2NyZWF0aXZlX2lkGAIgAS'
    'gJUgpjcmVhdGl2ZUlkEh8KC3BsYXliYWNrX2lkGAMgASgJUgpwbGF5YmFja0lkEiEKDHByb2R1'
    'Y3RfbmFtZRgEIAEoCVILcHJvZHVjdE5hbWUSHwoLbGluZWl0ZW1faWQYBSABKAlSCmxpbmVpdG'
    'VtSWQSEgoEc2xvdBgGIAEoCVIEc2xvdA==');
