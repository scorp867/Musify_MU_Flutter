---
title: "resolved.proto"
path: "protos/spotify/casita/resolved.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.casita.v1.resolved"
messages: 74
---

# resolved.proto

> Source Schema: `[protos/spotify/casita/resolved.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/casita/resolved.proto)`
> Syntax: `proto3` | Package: `spotify.casita.v1.resolved`

## Schema Overview
`resolved.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/browsita/resolved.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/browsita/resolved.pb.dart)`
- `[lib/core/protocol/generated/spotify/browsita/resolved.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/browsita/resolved.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/browsita/resolved.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/browsita/resolved.pbjson.dart)`
- `[lib/core/protocol/generated/spotify/casita/resolved.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/casita/resolved.pb.dart)`
- `[lib/core/protocol/generated/spotify/casita/resolved.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/casita/resolved.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/casita/resolved.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/casita/resolved.pbjson.dart)`

## Imported Proto Dependencies
- `spotify/extended_metadata.proto`

## Message Definitions
### `message ResolvedHome`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `HomeStructure` | `structure` |
| `2` | `optional` | `EagerlyLoadedTraits` | `eagerly_loaded_traits` |
| `3` | `optional` | `ResponseInfo` | `response_info` |
| `4` | `optional` | `DebugInfo` | `debug_info` |
| `5` | `optional` | `SandboxDebugInfo` | `sandbox_debug_info` |
| `999` | `optional` | `OndemandSet` | `ondemand_set` |

### `message HomeStructure`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `Section` | `sections` |

### `message EagerlyLoadedTraits`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `spotify.extendedmetadata.BatchedExtensionResponse` | `traits` |

### `message ResponseInfo`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `response_id` |
| `2` | `optional` | `string` | `page_uri` |
| `3` | `optional` | `string` | `page_token` |
| `4` | `optional` | `string` | `refresh_token` |

### `message DebugInfo`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `home_logging_span_id` |

### `message SandboxDebugInfo`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `string` | `invalid_section_uris` |
| `2` | `repeated` | `SectionFailure` | `failed_sections` |

### `message SectionFailure`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `uri` |
| `2` | `optional` | `string` | `reason` |
| `3` | `optional` | `string` | `service_name` |
| `4` | `optional` | `string` | `status` |

### `message OndemandSet`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `string` | `uris` |

### `message Section`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `SectionInfo` | `section_info` |
| `2` | `optional` | `Shortcuts` | `shortcuts` |
| `3` | `optional` | `ImageLink` | `image_link` |
| `4` | `optional` | `Preview` | `preview` |
| `6` | `optional` | `ImmersivePreview` | `immersive_preview` |
| `7` | `optional` | `Anchors` | `anchors` |
| `8` | `optional` | `ContentEvaluationList` | `content_evaluation_list` |
| `9` | `optional` | `CallToAction` | `call_to_action` |
| `10` | `optional` | `RecentsShelf` | `recents_shelf` |
| `11` | `optional` | `WatchFeed` | `watch_feed` |
| `12` | `optional` | `PromotionV1` | `promotion_v1` |
| `13` | `optional` | `PromotionV3` | `promotion_v3` |
| `15` | `optional` | `ActionCardCarousel` | `action_card_carousel` |
| `16` | `optional` | `LiveEvent` | `live_event` |
| `17` | `optional` | `Showcase` | `showcase` |
| `18` | `optional` | `VideoPromo` | `video_promo` |
| `19` | `optional` | `Banner` | `banner` |
| `20` | `optional` | `VideoBrandAd` | `video_brand_ad` |
| `21` | `optional` | `ImageBrandAd` | `image_brand_ad` |
| `23` | `optional` | `CampaignLinkCarousel` | `campaign_link_carousel` |
| `24` | `optional` | `VerticalSingleEntry` | `vertical_single_entry` |
| `25` | `optional` | `VideoCarousel` | `video_carousel` |
| `26` | `optional` | `FullBleedBanner` | `full_bleed_banner` |
| `27` | `optional` | `AssociatedPreview` | `associated_preview` |
| `28` | `optional` | `BannerWithAnimations` | `banner_with_animations` |
| `29` | `optional` | `Narrative` | `narrative` |
| `30` | `optional` | `InteractiveEntrypoint` | `interactive_entrypoint` |
| `31` | `optional` | `TopStoryCarousel` | `top_story_carousel` |
| `32` | `optional` | `PromptableSection` | `promptable_section` |
| `33` | `optional` | `AudioPromo` | `audio_promo` |
| `34` | `optional` | `InlineCard` | `inline_card` |
| `35` | `optional` | `PlayLinkPromo` | `play_link_promo` |
| `36` | `optional` | `AudioSpotlight` | `audio_spotlight` |
| `37` | `optional` | `PreviewCarousel` | `preview_carousel` |
| `38` | `optional` | `ConcertCampaign` | `concert_campaign` |
| `39` | `optional` | `PreviewPromotionCarousel` | `preview_promotion_carousel` |
| `40` | `optional` | `PromptedWorldsShelf` | `prompted_worlds_shelf` |
| `41` | `optional` | `Reflection` | `reflection` |
| `42` | `optional` | `UserPromptedWorldEntrypoint` | `user_prompted_world_entrypoint` |

### `message SectionInfo`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `section_id` |

### `message Item`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `identifier` |
| `2` | `repeated` | `string` | `highlighted_sub_items` |

### `message ItemSource`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Provided` | `provided` |
| `2` | `optional` | `LocalRecentlyPlayed` | `local_recently_played` |
| `3` | `optional` | `ListPlatform` | `list_platform` |

### `message Provided`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `Item` | `items` |

### `message ListPlatform`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `list_uri` |

### `message Heading`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `EmptyHeading` | `empty_heading` |
| `2` | `optional` | `HeadingWithText` | `text_heading` |
| `3` | `optional` | `EnrichedHeading` | `enriched_heading` |
| `4` | `optional` | `SponsoredHeading` | `sponsored_heading` |
| `5` | `optional` | `HeadingWithDescription` | `heading_with_description` |
| `6` | `optional` | `StaticEnrichedHeading` | `static_enriched_heading` |

### `message HeadingWithText`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `text` |
| `2` | `optional` | `string` | `encore_icon_name` |
| `3` | `optional` | `NavigationAction` | `navigation_action` |

### `message EnrichedHeading`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `format` |
| `2` | `optional` | `HeadingAssociatedItem` | `associated_item` |
| `3` | `optional` | `string` | `encore_icon_name` |

### `message HeadingWithDescription`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `title` |
| `2` | `optional` | `string` | `subtitle` |
| `3` | `optional` | `string` | `encore_icon_name` |

### `message StaticEnrichedHeading`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `text` |
| `2` | `optional` | `string` | `subtext` |
| `3` | `optional` | `string` | `image_url` |
| `4` | `optional` | `string` | `navigation_uri` |

### `message SponsoredHeading`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `text` |
| `2` | `optional` | `string` | `subtitle` |

### `message HeadingAssociatedItem`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `title` |
| `2` | `optional` | `string` | `uri` |
| `3` | `optional` | `string` | `image_url` |

### `message NavigationAction`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `text` |
| `2` | `optional` | `string` | `uri` |

### `message Shortcuts`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `ItemSource` | `item_source` |

### `message ImageLink`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `ItemSource` | `item_source` |
| `3` | `optional` | `int32` | `density` |
| `4` | `optional` | `EmbeddedAdMetadata` | `ad_metadata` |
| `5` | `optional` | `int32` | `source` |

### `message Preview`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `Item` | `item` |

### `message ImmersivePreview`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `Item` | `item` |

### `message Anchors`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ItemSource` | `item_source` |

### `message ContentEvaluationList`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `repeated` | `Item` | `items` |

### `message CallToAction`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `RichCallToAction` | `rich_call_to_action` |
| `2` | `optional` | `SimpleCallToAction` | `simple_call_to_action` |
| `3` | `optional` | `DjCallToAction` | `dj_call_to_action` |

### `message RichCallToAction`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `type` |
| `2` | `optional` | `string` | `image_url` |
| `3` | `optional` | `string` | `title` |
| `4` | `optional` | `string` | `subtitle` |
| `5` | `optional` | `string` | `call_to_action_text` |
| `6` | `optional` | `bool` | `is_dismissible` |

### `message SimpleCallToAction`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `type` |
| `2` | `optional` | `string` | `title` |
| `3` | `optional` | `string` | `call_to_action_text` |

### `message DjCallToAction`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `uri` |
| `2` | `optional` | `string` | `title` |
| `3` | `optional` | `string` | `subtitle` |
| `4` | `optional` | `DjVisualMetadata` | `visual_metadata` |
| `5` | `optional` | `string` | `transcript` |
| `6` | `optional` | `Heading` | `heading` |
| `7` | `optional` | `string` | `animation_url` |
| `8` | `optional` | `string` | `transcript_key` |

### `message DjVisualMetadata`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `background_color` |
| `2` | `optional` | `string` | `background_image` |
| `3` | `optional` | `string` | `jellyfish_top_color` |
| `4` | `optional` | `string` | `jellyfish_mid_color` |
| `5` | `optional` | `string` | `jellyfish_bottom_color` |
| `6` | `optional` | `string` | `tag_color` |
| `7` | `optional` | `string` | `text_color` |

### `message RecentsShelf`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `ItemSource` | `item_source` |
| `3` | `optional` | `int32` | `title_density` |

### `message WatchFeed`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `repeated` | `WatchFeedItem` | `items` |

### `message WatchFeedItem`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Item` | `item` |
| `2` | `optional` | `WatchFeedEntrypoint` | `entrypoint` |
| `3` | `optional` | `WatchFeedItemMetadata` | `watch_feed_item_metadata` |

### `message WatchFeedEntrypoint`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `uri` |
| `2` | `optional` | `string` | `first_item_uri` |
| `3` | `optional` | `string` | `overline` |
| `4` | `optional` | `string` | `title` |
| `5` | `optional` | `string` | `subtitle` |
| `6` | `optional` | `WatchFeedImage` | `thumbnail_image` |
| `7` | `optional` | `WatchFeedVideoFile` | `video_file` |
| `8` | `optional` | `string` | `navigation_uri` |
| `9` | `optional` | `string` | `accessibility` |
| `10` | `optional` | `WatchFeedImage` | `cover_image` |
| `11` | `optional` | `string` | `decision_id` |
| `12` | `optional` | `double` | `portrait_horizontal_focus_center_percentage` |
| `13` | `optional` | `WatchFeedImage` | `logo_image` |

### `message WatchFeedImage`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `url` |
| `2` | `optional` | `string` | `placeholder` |

### `message WatchFeedVideoFile`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `uri` |
| `2` | `optional` | `int32` | `type` |
| `3` | `optional` | `int64` | `start_time` |
| `4` | `optional` | `int64` | `end_time` |

### `message WatchFeedItemMetadata`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `decision_id` |
| `2` | `optional` | `string` | `navigation_uri` |
| `3` | `optional` | `string` | `first_item_uri` |

### `message PromotionV1`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `Item` | `item` |
| `3` | `optional` | `EmbeddedAdMetadata` | `ad_metadata` |
| `4` | `optional` | `int32` | `type` |

### `message PromotionV3`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Item` | `item` |
| `2` | `optional` | `EmbeddedAdMetadata` | `ad_metadata` |

### `message ActionCardCarousel`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `repeated` | `Item` | `items` |

### `message LiveEvent`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `ItemSource` | `item_source` |

### `message Showcase`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `Item` | `item` |
| `3` | `optional` | `EmbeddedAdMetadata` | `ad_metadata` |

### `message VideoPromo`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `Item` | `item` |
| `3` | `optional` | `string` | `target_uri` |
| `4` | `optional` | `EmbeddedAdMetadata` | `ad_metadata` |

### `message Banner`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `type` |
| `2` | `optional` | `string` | `color_code` |

### `message VideoBrandAd`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `EmbeddedAd` | `ad` |
| `2` | `optional` | `EmbeddedAdMetadata` | `ad_metadata` |

### `message ImageBrandAd`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `EmbeddedAd` | `ad` |
| `2` | `optional` | `EmbeddedAdMetadata` | `ad_metadata` |

### `message EmbeddedAd`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `advertiser` |
| `2` | `optional` | `string` | `call_to_action` |
| `3` | `optional` | `string` | `clickthrough_url` |
| `7` | `optional` | `string` | `tagline` |
| `8` | `optional` | `string` | `logo_image_url` |

### `message CampaignLinkCarousel`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `ItemSource` | `item_source` |
| `3` | `optional` | `EmbeddedAdMetadata` | `ad_metadata` |

### `message VerticalSingleEntry`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `Item` | `item` |
| `3` | `optional` | `string` | `target_uri` |
| `4` | `optional` | `EmbeddedAdMetadata` | `ad_metadata` |

### `message VideoCarousel`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `repeated` | `Item` | `items` |

### `message FullBleedBanner`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `2` | `optional` | `string` | `color_code` |
| `3` | `optional` | `string` | `image_url` |
| `4` | `optional` | `string` | `description` |
| `5` | `optional` | `string` | `accessibility` |

### `message AssociatedPreview`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `Item` | `item` |

### `message BannerWithAnimations`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Item` | `item` |
| `2` | `optional` | `EmbeddedAdMetadata` | `ad_metadata` |

### `message Narrative`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `title` |
| `2` | `optional` | `string` | `main_text` |

### `message InteractiveEntrypoint`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `prompt` |

### `message TopStoryCarousel`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `TopStory` | `stories` |

### `message TopStory`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `title` |
| `2` | `optional` | `string` | `description` |
| `3` | `repeated` | `Item` | `items` |
| `4` | `optional` | `string` | `story_id` |
| `5` | `optional` | `int64` | `created_at` |

### `message PromptableSection`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `Item` | `item` |
| `3` | `repeated` | `PromptableSuggestion` | `prompt_suggestions` |

### `message PromptableSuggestion`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `suggestion` |

### `message AudioPromo`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `Item` | `item` |
| `3` | `optional` | `EmbeddedAdMetadata` | `ad_metadata` |
| `4` | `optional` | `string` | `preview_entity_uri` |

### `message InlineCard`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `type` |

### `message PlayLinkPromo`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `Item` | `item` |
| `3` | `optional` | `EmbeddedAdMetadata` | `ad_metadata` |

### `message AudioSpotlight`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `Item` | `item` |
| `3` | `optional` | `EmbeddedAdMetadata` | `ad_metadata` |
| `4` | `optional` | `string` | `preview_entity_uri` |

### `message PreviewCarousel`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `repeated` | `Item` | `items` |

### `message ConcertCampaign`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `campaign_uri` |

### `message PreviewPromotionCarousel`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `string` | `promotion_uri` |
| `3` | `repeated` | `PreviewPromotionCarouselItem` | `items` |
| `4` | `optional` | `EmbeddedAdMetadata` | `ad_metadata` |

### `message PreviewPromotionCarouselItem`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `VideoPromo` | `video_promo` |

### `message PromptedWorldsShelf`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `ItemSource` | `item_source` |
| `3` | `optional` | `string` | `list_uri` |

### `message Reflection`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `Item` | `item` |

### `message UserPromptedWorldEntrypoint`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `optional` | `Item` | `item` |

### `message EmbeddedAdMetadata`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `id` |
| `2` | `optional` | `string` | `creative_id` |
| `3` | `optional` | `string` | `playback_id` |
| `4` | `optional` | `string` | `product_name` |
| `5` | `optional` | `string` | `lineitem_id` |
| `6` | `optional` | `string` | `slot` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.casita.v1.resolved;

import "spotify/extended_metadata.proto";

option optimize_for = CODE_SIZE;

// =========================================================================
// Top-level response from the Casita SDUI endpoint
// =========================================================================

message ResolvedHome {
  HomeStructure structure = 1;
  EagerlyLoadedTraits eagerly_loaded_traits = 2;
  ResponseInfo response_info = 3;
  DebugInfo debug_info = 4;
  SandboxDebugInfo sandbox_debug_info = 5;
  OndemandSet ondemand_set = 999;
}

message HomeStructure {
  repeated Section sections = 1;
}

message EagerlyLoadedTraits {
  spotify.extendedmetadata.BatchedExtensionResponse traits = 1;
}

message ResponseInfo {
  string response_id = 1;
  string page_uri = 2;
  string page_token = 3;
  string refresh_token = 4;
}

message DebugInfo {
  string home_logging_span_id = 1;
}

message SandboxDebugInfo {
  repeated string invalid_section_uris = 1;
  repeated SectionFailure failed_sections = 2;
}

message SectionFailure {
  string uri = 1;
  string reason = 2;
  string service_name = 3;
  string status = 4;
}

message OndemandSet {
  repeated string uris = 1;
}

// =========================================================================
// Section: The fundamental UI building block
// Each section has a SectionInfo + exactly ONE body type (oneof)
// Exactly matches com.spotify.casita.v1.resolved.Section
// =========================================================================

message Section {
  SectionInfo section_info = 1;

  oneof feature_type {
    Shortcuts shortcuts = 2;
    ImageLink image_link = 3;
    Preview preview = 4;
    // field 5 is unused
    ImmersivePreview immersive_preview = 6;
    Anchors anchors = 7;
    ContentEvaluationList content_evaluation_list = 8;
    CallToAction call_to_action = 9;
    RecentsShelf recents_shelf = 10;
    WatchFeed watch_feed = 11;
    PromotionV1 promotion_v1 = 12;
    PromotionV3 promotion_v3 = 13;
    ActionCardCarousel action_card_carousel = 15;
    LiveEvent live_event = 16;
    Showcase showcase = 17;
    VideoPromo video_promo = 18;
    Banner banner = 19;
    VideoBrandAd video_brand_ad = 20;
    ImageBrandAd image_brand_ad = 21;
    CampaignLinkCarousel campaign_link_carousel = 23;
    VerticalSingleEntry vertical_single_entry = 24;
    VideoCarousel video_carousel = 25;
    FullBleedBanner full_bleed_banner = 26;
    AssociatedPreview associated_preview = 27;
    BannerWithAnimations banner_with_animations = 28;
    Narrative narrative = 29;
    InteractiveEntrypoint interactive_entrypoint = 30;
    TopStoryCarousel top_story_carousel = 31;
    PromptableSection promptable_section = 32;
    AudioPromo audio_promo = 33;
    InlineCard inline_card = 34;
    PlayLinkPromo play_link_promo = 35;
    AudioSpotlight audio_spotlight = 36;
    PreviewCarousel preview_carousel = 37;
    ConcertCampaign concert_campaign = 38;
    PreviewPromotionCarousel preview_promotion_carousel = 39;
    PromptedWorldsShelf prompted_worlds_shelf = 40;
    Reflection reflection = 41;
    UserPromptedWorldEntrypoint user_prompted_world_entrypoint = 42;
  }
}

message SectionInfo {
  string section_id = 1;
}

// =========================================================================
// Item: The universal content reference
// =========================================================================

message Item {
  string identifier = 1;
  repeated string highlighted_sub_items = 2;
}

// =========================================================================
// Item Sources: How a section gets its items
// =========================================================================

message ItemSource {
  oneof source {
    Provided provided = 1;
    LocalRecentlyPlayed local_recently_played = 2;
    ListPlatform list_platform = 3;
  }
}

message Provided {
  repeated Item items = 1;
}

message LocalRecentlyPlayed {}

message ListPlatform {
  string list_uri = 1;
}

// =========================================================================
// Headings: Section title/header variations
// =========================================================================

message Heading {
  oneof heading {
    EmptyHeading empty_heading = 1;
    HeadingWithText text_heading = 2;
    EnrichedHeading enriched_heading = 3;
    SponsoredHeading sponsored_heading = 4;
    HeadingWithDescription heading_with_description = 5;
    StaticEnrichedHeading static_enriched_heading = 6;
  }
}

message EmptyHeading {}

message HeadingWithText {
  string text = 1;
  string encore_icon_name = 2;
  NavigationAction navigation_action = 3;
}

message EnrichedHeading {
  string format = 1;
  HeadingAssociatedItem associated_item = 2;
  string encore_icon_name = 3;
}

message HeadingWithDescription {
  string title = 1;
  string subtitle = 2;
  string encore_icon_name = 3;
}

message StaticEnrichedHeading {
  string text = 1;
  string subtext = 2;
  string image_url = 3;
  string navigation_uri = 4;
}

message SponsoredHeading {
  string text = 1;
  string subtitle = 2;
}

message HeadingAssociatedItem {
  string title = 1;
  string uri = 2;
  string image_url = 3;
}

message NavigationAction {
  string text = 1;
  string uri = 2;
}

// =========================================================================
// Section Body Types (the actual UI components)
// Verified from com.spotify.casita.v1.resolved APK bytecode
// =========================================================================

// field 2: Shortcuts
message Shortcuts {
  Heading heading = 1;
  ItemSource item_source = 2;
}

// field 3: Standard horizontal image card carousel
message ImageLink {
  Heading heading = 1;
  ItemSource item_source = 2;
  int32 density = 3;
  EmbeddedAdMetadata ad_metadata = 4;
  int32 source = 5;
}

// field 4: Preview section
message Preview {
  Heading heading = 1;
  Item item = 2;
}

// field 6: Full-bleed immersive preview
message ImmersivePreview {
  Heading heading = 1;
  Item item = 2;
}

// field 7: Section anchors (jump chips)
message Anchors {
  ItemSource item_source = 1;
}

// field 8: Content evaluation list
message ContentEvaluationList {
  Heading heading = 1;
  repeated Item items = 2;
}

// field 9: Call to action
message CallToAction {
  oneof variant {
    RichCallToAction rich_call_to_action = 1;
    SimpleCallToAction simple_call_to_action = 2;
    DjCallToAction dj_call_to_action = 3;
  }
}

message RichCallToAction {
  int32 type = 1;
  string image_url = 2;
  string title = 3;
  string subtitle = 4;
  string call_to_action_text = 5;
  bool is_dismissible = 6;
}

message SimpleCallToAction {
  int32 type = 1;
  string title = 2;
  string call_to_action_text = 3;
}

message DjCallToAction {
  string uri = 1;
  string title = 2;
  string subtitle = 3;
  DjVisualMetadata visual_metadata = 4;
  string transcript = 5;
  Heading heading = 6;
  string animation_url = 7;
  string transcript_key = 8;
}

message DjVisualMetadata {
  string background_color = 1;
  string background_image = 2;
  string jellyfish_top_color = 3;
  string jellyfish_mid_color = 4;
  string jellyfish_bottom_color = 5;
  string tag_color = 6;
  string text_color = 7;
}

// field 10: Recently played shelf
message RecentsShelf {
  Heading heading = 1;
  ItemSource item_source = 2;
  int32 title_density = 3;
}

// field 11: Video/watch feed
message WatchFeed {
  Heading heading = 1;
  repeated WatchFeedItem items = 2;
}

message WatchFeedItem {
  Item item = 1;
  WatchFeedEntrypoint entrypoint = 2;
  WatchFeedItemMetadata watch_feed_item_metadata = 3;
}

message WatchFeedEntrypoint {
  string uri = 1;
  string first_item_uri = 2;
  string overline = 3;
  string title = 4;
  string subtitle = 5;
  WatchFeedImage thumbnail_image = 6;
  WatchFeedVideoFile video_file = 7;
  string navigation_uri = 8;
  string accessibility = 9;
  WatchFeedImage cover_image = 10;
  string decision_id = 11;
  double portrait_horizontal_focus_center_percentage = 12;
  WatchFeedImage logo_image = 13;
}

message WatchFeedImage {
  string url = 1;
  string placeholder = 2;
}

message WatchFeedVideoFile {
  string uri = 1;
  int32 type = 2;
  int64 start_time = 3;
  int64 end_time = 4;
}

message WatchFeedItemMetadata {
  string decision_id = 1;
  string navigation_uri = 2;
  string first_item_uri = 3;
}

// field 12: Promotion V1 (featured release / album drop banner)
message PromotionV1 {
  Heading heading = 1;
  Item item = 2;
  EmbeddedAdMetadata ad_metadata = 3;
  int32 type = 4;
}

// field 13: Promotion V3 (modern featured release banner - NO heading in APK bytecode)
message PromotionV3 {
  Item item = 1;
  EmbeddedAdMetadata ad_metadata = 2;
}

// field 15: Action card carousel (repeated items in APK bytecode)
message ActionCardCarousel {
  Heading heading = 1;
  repeated Item items = 2;
}

// field 16: Live event (item_source in APK bytecode)
message LiveEvent {
  Heading heading = 1;
  ItemSource item_source = 2;
}

// field 17: Showcase (featured content)
message Showcase {
  Heading heading = 1;
  Item item = 2;
  EmbeddedAdMetadata ad_metadata = 3;
}

// field 18: Video promo
message VideoPromo {
  Heading heading = 1;
  Item item = 2;
  string target_uri = 3;
  EmbeddedAdMetadata ad_metadata = 4;
}

// field 19: Banner ad
message Banner {
  int32 type = 1;
  string color_code = 2;
}

// field 20: Video brand ad
message VideoBrandAd {
  EmbeddedAd ad = 1;
  EmbeddedAdMetadata ad_metadata = 2;
}

// field 21: Image brand ad
message ImageBrandAd {
  EmbeddedAd ad = 1;
  EmbeddedAdMetadata ad_metadata = 2;
}

message EmbeddedAd {
  string advertiser = 1;
  string call_to_action = 2;
  string clickthrough_url = 3;
  string tagline = 7;
  string logo_image_url = 8;
}

// field 23: Campaign link carousel (editorial campaigns: RADAR, EQUAL, etc.)
message CampaignLinkCarousel {
  Heading heading = 1;
  ItemSource item_source = 2;
  EmbeddedAdMetadata ad_metadata = 3;
}

// field 24: Vertical single entry
message VerticalSingleEntry {
  Heading heading = 1;
  Item item = 2;
  string target_uri = 3;
  EmbeddedAdMetadata ad_metadata = 4;
}

// field 25: Video carousel (repeated items in APK bytecode)
message VideoCarousel {
  Heading heading = 1;
  repeated Item items = 2;
}

// field 26: Full bleed banner
message FullBleedBanner {
  string color_code = 2;
  string image_url = 3;
  string description = 4;
  string accessibility = 5;
}

// field 27: Associated preview
message AssociatedPreview {
  Heading heading = 1;
  Item item = 2;
}

// field 28: Banner with animations (NO heading in APK bytecode)
message BannerWithAnimations {
  Item item = 1;
  EmbeddedAdMetadata ad_metadata = 2;
}

// field 29: Narrative text section
message Narrative {
  string title = 1;
  string main_text = 2;
}

// field 30: Interactive entrypoint (prompt string only in APK bytecode)
message InteractiveEntrypoint {
  string prompt = 1;
}

// field 31: Top story carousel (repeated TopStory in APK bytecode)
message TopStoryCarousel {
  repeated TopStory stories = 1;
}

message TopStory {
  string title = 1;
  string description = 2;
  repeated Item items = 3;
  string story_id = 4;
  int64 created_at = 5;
}

// field 32: Promptable section
message PromptableSection {
  Heading heading = 1;
  Item item = 2;
  repeated PromptableSuggestion prompt_suggestions = 3;
}

message PromptableSuggestion {
  string suggestion = 1;
}

// field 33: Audio promo
message AudioPromo {
  Heading heading = 1;
  Item item = 2;
  EmbeddedAdMetadata ad_metadata = 3;
  string preview_entity_uri = 4;
}

// field 34: Inline card (type enum only in APK bytecode)
message InlineCard {
  int32 type = 1;
}

// field 35: Play link promo (1-tap quick playback banner)
message PlayLinkPromo {
  Heading heading = 1;
  Item item = 2;
  EmbeddedAdMetadata ad_metadata = 3;
}

// field 36: Audio spotlight
message AudioSpotlight {
  Heading heading = 1;
  Item item = 2;
  EmbeddedAdMetadata ad_metadata = 3;
  string preview_entity_uri = 4;
}

// field 37: Preview carousel (large preview cards with repeated items)
message PreviewCarousel {
  Heading heading = 1;
  repeated Item items = 2;
}

// field 38: Concert campaign (campaign_uri only in APK bytecode)
message ConcertCampaign {
  string campaign_uri = 1;
}

// field 39: Preview promotion carousel
message PreviewPromotionCarousel {
  Heading heading = 1;
  string promotion_uri = 2;
  repeated PreviewPromotionCarouselItem items = 3;
  EmbeddedAdMetadata ad_metadata = 4;
}

message PreviewPromotionCarouselItem {
  oneof content {
    VideoPromo video_promo = 1;
  }
}

// field 40: Prompted worlds shelf
message PromptedWorldsShelf {
  Heading heading = 1;
  ItemSource item_source = 2;
  string list_uri = 3;
}

// field 41: Reflection
message Reflection {
  Heading heading = 1;
  Item item = 2;
}

// field 42: User prompted world entrypoint
message UserPromptedWorldEntrypoint {
  Heading heading = 1;
  Item item = 2;
}

// =========================================================================
// Shared / embedded types
// =========================================================================

message EmbeddedAdMetadata {
  string id = 1;
  string creative_id = 2;
  string playback_id = 3;
  string product_name = 4;
  string lineitem_id = 5;
  string slot = 6;
}
```
