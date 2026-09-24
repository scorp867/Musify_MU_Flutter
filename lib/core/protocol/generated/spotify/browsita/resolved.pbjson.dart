// This is a generated file - do not edit.
//
// Generated from spotify/browsita/resolved.proto.

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

@$core.Deprecated('Use resolvedBrowseDescriptor instead')
const ResolvedBrowse$json = {
  '1': 'ResolvedBrowse',
  '2': [
    {
      '1': 'structure',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.BrowseStructure',
      '10': 'structure'
    },
    {
      '1': 'response_info',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.ResponseInfo',
      '10': 'responseInfo'
    },
  ],
};

/// Descriptor for `ResolvedBrowse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resolvedBrowseDescriptor = $convert.base64Decode(
    'Cg5SZXNvbHZlZEJyb3dzZRJLCglzdHJ1Y3R1cmUYASABKAsyLS5zcG90aWZ5LmJyb3dzaXRhLn'
    'YxLnJlc29sdmVkLkJyb3dzZVN0cnVjdHVyZVIJc3RydWN0dXJlEk8KDXJlc3BvbnNlX2luZm8Y'
    'AiABKAsyKi5zcG90aWZ5LmJyb3dzaXRhLnYxLnJlc29sdmVkLlJlc3BvbnNlSW5mb1IMcmVzcG'
    '9uc2VJbmZv');

@$core.Deprecated('Use browseStructureDescriptor instead')
const BrowseStructure$json = {
  '1': 'BrowseStructure',
  '2': [
    {
      '1': 'sections',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.Section',
      '10': 'sections'
    },
  ],
};

/// Descriptor for `BrowseStructure`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List browseStructureDescriptor = $convert.base64Decode(
    'Cg9Ccm93c2VTdHJ1Y3R1cmUSQQoIc2VjdGlvbnMYASADKAsyJS5zcG90aWZ5LmJyb3dzaXRhLn'
    'YxLnJlc29sdmVkLlNlY3Rpb25SCHNlY3Rpb25z');

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

@$core.Deprecated('Use sectionDescriptor instead')
const Section$json = {
  '1': 'Section',
  '2': [
    {
      '1': 'section_info',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.SectionInfo',
      '10': 'sectionInfo'
    },
    {
      '1': 'content_category',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.ContentCategory',
      '9': 0,
      '10': 'contentCategory'
    },
    {
      '1': 'promotion_v1',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.PromotionV1',
      '9': 0,
      '10': 'promotionV1'
    },
    {
      '1': 'watch_feed',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.WatchFeed',
      '9': 0,
      '10': 'watchFeed'
    },
    {
      '1': 'promotion_v3',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.PromotionV3',
      '9': 0,
      '10': 'promotionV3'
    },
    {
      '1': 'brand_ads',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.BrandAds',
      '9': 0,
      '10': 'brandAds'
    },
    {
      '1': 'showcase',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.Showcase',
      '9': 0,
      '10': 'showcase'
    },
    {
      '1': 'audio_promo',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.AudioPromo',
      '9': 0,
      '10': 'audioPromo'
    },
    {
      '1': 'play_link_promo',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.PlayLinkPromo',
      '9': 0,
      '10': 'playLinkPromo'
    },
    {
      '1': 'preview_promotion_carousel',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.PreviewPromotionCarousel',
      '9': 0,
      '10': 'previewPromotionCarousel'
    },
    {
      '1': 'video_promo',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.VideoPromo',
      '9': 0,
      '10': 'videoPromo'
    },
    {
      '1': 'audio_spotlight',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.AudioSpotlight',
      '9': 0,
      '10': 'audioSpotlight'
    },
  ],
  '8': [
    {'1': 'feature_type'},
  ],
};

/// Descriptor for `Section`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionDescriptor = $convert.base64Decode(
    'CgdTZWN0aW9uEkwKDHNlY3Rpb25faW5mbxgBIAEoCzIpLnNwb3RpZnkuYnJvd3NpdGEudjEucm'
    'Vzb2x2ZWQuU2VjdGlvbkluZm9SC3NlY3Rpb25JbmZvEloKEGNvbnRlbnRfY2F0ZWdvcnkYAiAB'
    'KAsyLS5zcG90aWZ5LmJyb3dzaXRhLnYxLnJlc29sdmVkLkNvbnRlbnRDYXRlZ29yeUgAUg9jb2'
    '50ZW50Q2F0ZWdvcnkSTgoMcHJvbW90aW9uX3YxGAMgASgLMikuc3BvdGlmeS5icm93c2l0YS52'
    'MS5yZXNvbHZlZC5Qcm9tb3Rpb25WMUgAUgtwcm9tb3Rpb25WMRJICgp3YXRjaF9mZWVkGAQgAS'
    'gLMicuc3BvdGlmeS5icm93c2l0YS52MS5yZXNvbHZlZC5XYXRjaEZlZWRIAFIJd2F0Y2hGZWVk'
    'Ek4KDHByb21vdGlvbl92MxgFIAEoCzIpLnNwb3RpZnkuYnJvd3NpdGEudjEucmVzb2x2ZWQuUH'
    'JvbW90aW9uVjNIAFILcHJvbW90aW9uVjMSRQoJYnJhbmRfYWRzGAYgASgLMiYuc3BvdGlmeS5i'
    'cm93c2l0YS52MS5yZXNvbHZlZC5CcmFuZEFkc0gAUghicmFuZEFkcxJECghzaG93Y2FzZRgHIA'
    'EoCzImLnNwb3RpZnkuYnJvd3NpdGEudjEucmVzb2x2ZWQuU2hvd2Nhc2VIAFIIc2hvd2Nhc2US'
    'SwoLYXVkaW9fcHJvbW8YCCABKAsyKC5zcG90aWZ5LmJyb3dzaXRhLnYxLnJlc29sdmVkLkF1ZG'
    'lvUHJvbW9IAFIKYXVkaW9Qcm9tbxJVCg9wbGF5X2xpbmtfcHJvbW8YCSABKAsyKy5zcG90aWZ5'
    'LmJyb3dzaXRhLnYxLnJlc29sdmVkLlBsYXlMaW5rUHJvbW9IAFINcGxheUxpbmtQcm9tbxJ2Ch'
    'pwcmV2aWV3X3Byb21vdGlvbl9jYXJvdXNlbBgKIAEoCzI2LnNwb3RpZnkuYnJvd3NpdGEudjEu'
    'cmVzb2x2ZWQuUHJldmlld1Byb21vdGlvbkNhcm91c2VsSABSGHByZXZpZXdQcm9tb3Rpb25DYX'
    'JvdXNlbBJLCgt2aWRlb19wcm9tbxgLIAEoCzIoLnNwb3RpZnkuYnJvd3NpdGEudjEucmVzb2x2'
    'ZWQuVmlkZW9Qcm9tb0gAUgp2aWRlb1Byb21vElcKD2F1ZGlvX3Nwb3RsaWdodBgMIAEoCzIsLn'
    'Nwb3RpZnkuYnJvd3NpdGEudjEucmVzb2x2ZWQuQXVkaW9TcG90bGlnaHRIAFIOYXVkaW9TcG90'
    'bGlnaHRCDgoMZmVhdHVyZV90eXBl');

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

@$core.Deprecated('Use contentCategoryDescriptor instead')
const ContentCategory$json = {
  '1': 'ContentCategory',
  '2': [
    {
      '1': 'heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.Heading',
      '10': 'heading'
    },
    {
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.Item',
      '10': 'items'
    },
    {
      '1': 'density',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.DensityConfig',
      '10': 'density'
    },
  ],
};

/// Descriptor for `ContentCategory`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contentCategoryDescriptor = $convert.base64Decode(
    'Cg9Db250ZW50Q2F0ZWdvcnkSPwoHaGVhZGluZxgBIAEoCzIlLnNwb3RpZnkuYnJvd3NpdGEudj'
    'EucmVzb2x2ZWQuSGVhZGluZ1IHaGVhZGluZxI4CgVpdGVtcxgCIAMoCzIiLnNwb3RpZnkuYnJv'
    'd3NpdGEudjEucmVzb2x2ZWQuSXRlbVIFaXRlbXMSRQoHZGVuc2l0eRgDIAEoCzIrLnNwb3RpZn'
    'kuYnJvd3NpdGEudjEucmVzb2x2ZWQuRGVuc2l0eUNvbmZpZ1IHZGVuc2l0eQ==');

@$core.Deprecated('Use headingDescriptor instead')
const Heading$json = {
  '1': 'Heading',
  '2': [
    {
      '1': 'text_heading',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.TextHeading',
      '9': 0,
      '10': 'textHeading'
    },
    {
      '1': 'sponsored_heading',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.SponsoredHeading',
      '9': 0,
      '10': 'sponsoredHeading'
    },
  ],
  '8': [
    {'1': 'heading_type'},
  ],
};

/// Descriptor for `Heading`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List headingDescriptor = $convert.base64Decode(
    'CgdIZWFkaW5nEk4KDHRleHRfaGVhZGluZxgBIAEoCzIpLnNwb3RpZnkuYnJvd3NpdGEudjEucm'
    'Vzb2x2ZWQuVGV4dEhlYWRpbmdIAFILdGV4dEhlYWRpbmcSXQoRc3BvbnNvcmVkX2hlYWRpbmcY'
    'AiABKAsyLi5zcG90aWZ5LmJyb3dzaXRhLnYxLnJlc29sdmVkLlNwb25zb3JlZEhlYWRpbmdIAF'
    'IQc3BvbnNvcmVkSGVhZGluZ0IOCgxoZWFkaW5nX3R5cGU=');

@$core.Deprecated('Use textHeadingDescriptor instead')
const TextHeading$json = {
  '1': 'TextHeading',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {
      '1': 'navigation_action',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.NavigationAction',
      '10': 'navigationAction'
    },
    {'1': 'encore_icon_name', '3': 3, '4': 1, '5': 9, '10': 'encoreIconName'},
  ],
};

/// Descriptor for `TextHeading`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textHeadingDescriptor = $convert.base64Decode(
    'CgtUZXh0SGVhZGluZxISCgR0ZXh0GAEgASgJUgR0ZXh0ElsKEW5hdmlnYXRpb25fYWN0aW9uGA'
    'IgASgLMi4uc3BvdGlmeS5icm93c2l0YS52MS5yZXNvbHZlZC5OYXZpZ2F0aW9uQWN0aW9uUhBu'
    'YXZpZ2F0aW9uQWN0aW9uEigKEGVuY29yZV9pY29uX25hbWUYAyABKAlSDmVuY29yZUljb25OYW'
    '1l');

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

@$core.Deprecated('Use navigationActionDescriptor instead')
const NavigationAction$json = {
  '1': 'NavigationAction',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
  ],
};

/// Descriptor for `NavigationAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List navigationActionDescriptor =
    $convert.base64Decode('ChBOYXZpZ2F0aW9uQWN0aW9uEhAKA3VyaRgBIAEoCVIDdXJp');

@$core.Deprecated('Use densityConfigDescriptor instead')
const DensityConfig$json = {
  '1': 'DensityConfig',
};

/// Descriptor for `DensityConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List densityConfigDescriptor =
    $convert.base64Decode('Cg1EZW5zaXR5Q29uZmln');

@$core.Deprecated('Use itemDescriptor instead')
const Item$json = {
  '1': 'Item',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'target_uri', '3': 2, '4': 1, '5': 9, '10': 'targetUri'},
  ],
};

/// Descriptor for `Item`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List itemDescriptor = $convert.base64Decode(
    'CgRJdGVtEhAKA3VyaRgBIAEoCVIDdXJpEh0KCnRhcmdldF91cmkYAiABKAlSCXRhcmdldFVyaQ'
    '==');

@$core.Deprecated('Use promotionV1Descriptor instead')
const PromotionV1$json = {
  '1': 'PromotionV1',
};

/// Descriptor for `PromotionV1`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promotionV1Descriptor =
    $convert.base64Decode('CgtQcm9tb3Rpb25WMQ==');

@$core.Deprecated('Use promotionV3Descriptor instead')
const PromotionV3$json = {
  '1': 'PromotionV3',
};

/// Descriptor for `PromotionV3`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promotionV3Descriptor =
    $convert.base64Decode('CgtQcm9tb3Rpb25WMw==');

@$core.Deprecated('Use brandAdsDescriptor instead')
const BrandAds$json = {
  '1': 'BrandAds',
};

/// Descriptor for `BrandAds`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List brandAdsDescriptor =
    $convert.base64Decode('CghCcmFuZEFkcw==');

@$core.Deprecated('Use audioPromoDescriptor instead')
const AudioPromo$json = {
  '1': 'AudioPromo',
};

/// Descriptor for `AudioPromo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioPromoDescriptor =
    $convert.base64Decode('CgpBdWRpb1Byb21v');

@$core.Deprecated('Use playLinkPromoDescriptor instead')
const PlayLinkPromo$json = {
  '1': 'PlayLinkPromo',
};

/// Descriptor for `PlayLinkPromo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playLinkPromoDescriptor =
    $convert.base64Decode('Cg1QbGF5TGlua1Byb21v');

@$core.Deprecated('Use videoPromoDescriptor instead')
const VideoPromo$json = {
  '1': 'VideoPromo',
};

/// Descriptor for `VideoPromo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoPromoDescriptor =
    $convert.base64Decode('CgpWaWRlb1Byb21v');

@$core.Deprecated('Use audioSpotlightDescriptor instead')
const AudioSpotlight$json = {
  '1': 'AudioSpotlight',
};

/// Descriptor for `AudioSpotlight`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioSpotlightDescriptor =
    $convert.base64Decode('Cg5BdWRpb1Nwb3RsaWdodA==');

@$core.Deprecated('Use showcaseDescriptor instead')
const Showcase$json = {
  '1': 'Showcase',
};

/// Descriptor for `Showcase`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List showcaseDescriptor =
    $convert.base64Decode('CghTaG93Y2FzZQ==');

@$core.Deprecated('Use watchFeedDescriptor instead')
const WatchFeed$json = {
  '1': 'WatchFeed',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.WatchFeedItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `WatchFeed`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchFeedDescriptor = $convert.base64Decode(
    'CglXYXRjaEZlZWQSQQoFaXRlbXMYASADKAsyKy5zcG90aWZ5LmJyb3dzaXRhLnYxLnJlc29sdm'
    'VkLldhdGNoRmVlZEl0ZW1SBWl0ZW1z');

@$core.Deprecated('Use watchFeedItemDescriptor instead')
const WatchFeedItem$json = {
  '1': 'WatchFeedItem',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {
      '1': 'metadata',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.WatchFeedItemMetadata',
      '10': 'metadata'
    },
  ],
};

/// Descriptor for `WatchFeedItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchFeedItemDescriptor = $convert.base64Decode(
    'Cg1XYXRjaEZlZWRJdGVtEhAKA3VyaRgBIAEoCVIDdXJpEk8KCG1ldGFkYXRhGAIgASgLMjMuc3'
    'BvdGlmeS5icm93c2l0YS52MS5yZXNvbHZlZC5XYXRjaEZlZWRJdGVtTWV0YWRhdGFSCG1ldGFk'
    'YXRh');

@$core.Deprecated('Use watchFeedItemMetadataDescriptor instead')
const WatchFeedItemMetadata$json = {
  '1': 'WatchFeedItemMetadata',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
  ],
};

/// Descriptor for `WatchFeedItemMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchFeedItemMetadataDescriptor =
    $convert.base64Decode(
        'ChVXYXRjaEZlZWRJdGVtTWV0YWRhdGESFAoFdGl0bGUYASABKAlSBXRpdGxl');

@$core.Deprecated('Use previewPromotionCarouselDescriptor instead')
const PreviewPromotionCarousel$json = {
  '1': 'PreviewPromotionCarousel',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.spotify.browsita.v1.resolved.PreviewPromotionCarouselItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `PreviewPromotionCarousel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewPromotionCarouselDescriptor =
    $convert.base64Decode(
        'ChhQcmV2aWV3UHJvbW90aW9uQ2Fyb3VzZWwSUAoFaXRlbXMYASADKAsyOi5zcG90aWZ5LmJyb3'
        'dzaXRhLnYxLnJlc29sdmVkLlByZXZpZXdQcm9tb3Rpb25DYXJvdXNlbEl0ZW1SBWl0ZW1z');

@$core.Deprecated('Use previewPromotionCarouselItemDescriptor instead')
const PreviewPromotionCarouselItem$json = {
  '1': 'PreviewPromotionCarouselItem',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
  ],
};

/// Descriptor for `PreviewPromotionCarouselItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewPromotionCarouselItemDescriptor =
    $convert.base64Decode(
        'ChxQcmV2aWV3UHJvbW90aW9uQ2Fyb3VzZWxJdGVtEhAKA3VyaRgBIAEoCVIDdXJp');
