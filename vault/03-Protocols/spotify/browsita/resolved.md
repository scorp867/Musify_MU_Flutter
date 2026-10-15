---
title: "resolved.proto"
path: "protos/spotify/browsita/resolved.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.browsita.v1.resolved"
messages: 18
---

# resolved.proto

> Source Schema: `[protos/spotify/browsita/resolved.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/browsita/resolved.proto)`
> Syntax: `proto3` | Package: `spotify.browsita.v1.resolved`

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

## Message Definitions
### `message ResolvedBrowse`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `BrowseStructure` | `structure` |
| `2` | `optional` | `ResponseInfo` | `response_info` |

### `message BrowseStructure`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `Section` | `sections` |

### `message ResponseInfo`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `server_version` |

### `message Section`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `SectionInfo` | `section_info` |
| `2` | `optional` | `ContentCategory` | `content_category` |
| `3` | `optional` | `PromotionV1` | `promotion_v1` |
| `4` | `optional` | `WatchFeed` | `watch_feed` |
| `5` | `optional` | `PromotionV3` | `promotion_v3` |
| `6` | `optional` | `BrandAds` | `brand_ads` |
| `7` | `optional` | `Showcase` | `showcase` |
| `8` | `optional` | `AudioPromo` | `audio_promo` |
| `9` | `optional` | `PlayLinkPromo` | `play_link_promo` |
| `10` | `optional` | `PreviewPromotionCarousel` | `preview_promotion_carousel` |
| `11` | `optional` | `VideoPromo` | `video_promo` |
| `12` | `optional` | `AudioSpotlight` | `audio_spotlight` |

### `message SectionInfo`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `section_id` |

### `message ContentCategory`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `repeated` | `Item` | `items` |
| `3` | `optional` | `DensityConfig` | `density` |

### `message Heading`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `TextHeading` | `text_heading` |
| `2` | `optional` | `SponsoredHeading` | `sponsored_heading` |

### `message TextHeading`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `text` |
| `2` | `optional` | `NavigationAction` | `navigation_action` |
| `3` | `optional` | `string` | `encore_icon_name` |

### `message SponsoredHeading`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `text` |

### `message NavigationAction`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `uri` |

### `message DensityConfig`
- Empty message container or extension wrapper.

### `message Item`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `uri` |
| `2` | `optional` | `string` | `target_uri` |

### `message Showcase`
- Empty message container or extension wrapper.

### `message WatchFeed`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `WatchFeedItem` | `items` |

### `message WatchFeedItem`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `uri` |
| `2` | `optional` | `WatchFeedItemMetadata` | `metadata` |

### `message WatchFeedItemMetadata`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `title` |

### `message PreviewPromotionCarousel`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `PreviewPromotionCarouselItem` | `items` |

### `message PreviewPromotionCarouselItem`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `uri` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.browsita.v1.resolved;

option optimize_for = CODE_SIZE;

// =========================================================================
// Top-level response from the Browsita browse endpoint
// GET /browsita/v1/browse?timezone=...
// =========================================================================

message ResolvedBrowse {
  BrowseStructure structure = 1;
  ResponseInfo response_info = 2;
}

message BrowseStructure {
  repeated Section sections = 1;
}

message ResponseInfo {
  string server_version = 1;
}

// =========================================================================
// Section: Each section has SectionInfo + one feature_type
// =========================================================================

message Section {
  SectionInfo section_info = 1;

  oneof feature_type {
    ContentCategory content_category = 2;
    PromotionV1 promotion_v1 = 3;
    WatchFeed watch_feed = 4;
    PromotionV3 promotion_v3 = 5;
    BrandAds brand_ads = 6;
    Showcase showcase = 7;
    AudioPromo audio_promo = 8;
    PlayLinkPromo play_link_promo = 9;
    PreviewPromotionCarousel preview_promotion_carousel = 10;
    VideoPromo video_promo = 11;
    AudioSpotlight audio_spotlight = 12;
  }
}

message SectionInfo {
  string section_id = 1;
}

// =========================================================================
// ContentCategory: The main browse grid section
// Shows a heading + list of category/genre items
// =========================================================================

message ContentCategory {
  Heading heading = 1;
  repeated Item items = 2;
  DensityConfig density = 3;
}

message Heading {
  oneof heading_type {
    TextHeading text_heading = 1;
    SponsoredHeading sponsored_heading = 2;
  }
}

message TextHeading {
  string text = 1;
  NavigationAction navigation_action = 2;
  string encore_icon_name = 3;
}

message SponsoredHeading {
  string text = 1;
}

message NavigationAction {
  string uri = 1;
}

message DensityConfig {
  // Density configuration for the grid layout
}

// =========================================================================
// Item: A single browse category card (e.g. genre card)
// =========================================================================

message Item {
  string uri = 1;
  string target_uri = 2;
}

// =========================================================================
// Other section types (mostly ads/promos, parsed but may be skipped)
// =========================================================================

message PromotionV1 {}
message PromotionV3 {}
message BrandAds {}
message AudioPromo {}
message PlayLinkPromo {}
message VideoPromo {}
message AudioSpotlight {}

message Showcase {
  // Showcase promo section
}

message WatchFeed {
  repeated WatchFeedItem items = 1;
}

message WatchFeedItem {
  string uri = 1;
  WatchFeedItemMetadata metadata = 2;
}

message WatchFeedItemMetadata {
  string title = 1;
}

message PreviewPromotionCarousel {
  repeated PreviewPromotionCarouselItem items = 1;
}

message PreviewPromotionCarouselItem {
  string uri = 1;
}
```
