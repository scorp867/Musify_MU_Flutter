---
title: "preview_card_trait.proto"
path: "protos/spotify/traits/preview_card_trait.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.extendedmetadata.extensions.previewcardtrait"
messages: 4
---

# preview_card_trait.proto

> Source Schema: `[protos/spotify/traits/preview_card_trait.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/traits/preview_card_trait.proto)`
> Syntax: `proto3` | Package: `spotify.extendedmetadata.extensions.previewcardtrait`

## Schema Overview
`preview_card_trait.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/traits/preview_card_trait.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/traits/preview_card_trait.pb.dart)`
- `[lib/core/protocol/generated/spotify/traits/preview_card_trait.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/traits/preview_card_trait.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/traits/preview_card_trait.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/traits/preview_card_trait.pbjson.dart)`

## Imported Proto Dependencies
- `google/protobuf/duration.proto`
- `google/protobuf/timestamp.proto`

## Message Definitions
### `message PreviewCardTrait`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `title` |
| `2` | `optional` | `string` | `content_type_name` |
| `4` | `optional` | `string` | `description` |
| `5` | `optional` | `string` | `entity_uri` |
| `6` | `optional` | `string` | `navigate_uri` |
| `7` | `optional` | `string` | `like_uri` |
| `8` | `optional` | `string` | `entity_image_url` |
| `9` | `optional` | `google.protobuf.Duration` | `duration` |
| `10` | `optional` | `google.protobuf.Timestamp` | `publish_time` |
| `11` | `optional` | `string` | `background_color_hex` |
| `12` | `optional` | `string` | `waveform_color_hex` |
| `13` | `optional` | `PreviewRestriction` | `preview_restriction` |
| `14` | `optional` | `Labels` | `labels` |
| `15` | `repeated` | `DescriptorTag` | `descriptor_tags` |
| `16` | `optional` | `int32` | `number_of_items` |
| `17` | `optional` | `ContentParent` | `content_parent` |
| `18` | `optional` | `SubtitleSource` | `subtitle_source` |

### `message Labels`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `preview_label` |
| `2` | `optional` | `string` | `playing_label` |

### `message DescriptorTag`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |

### `message ContentParent`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |
| `2` | `optional` | `string` | `uri` |
| `3` | `optional` | `string` | `image_url` |

## Enum Definitions
### `enum PreviewRestriction`
| Number | Identifier |
|--------|------------|
| `0` | `PREVIEW_RESTRICTION_NONE` |
| `1` | `PREVIEW_IS_EXPLICIT` |
| `2` | `PREVIEW_IS_19_PLUS` |

### `enum SubtitleSource`
| Number | Identifier |
|--------|------------|
| `0` | `SUBTITLE_SOURCE_UNKNOWN` |
| `1` | `SUBTITLE_SOURCE_GENERATED_METADATA` |
| `2` | `SUBTITLE_SOURCE_OPERATOR_AUTHORED` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.extendedmetadata.extensions.previewcardtrait;

import "google/protobuf/duration.proto";
import "google/protobuf/timestamp.proto";

option optimize_for = CODE_SIZE;

// PreviewCardTrait - ExtensionKind 118
// Embedded in the Casita response (via EagerlyLoadedTraits).
// Renders as a large preview card with background color, tags, and play preview.

message PreviewCardTrait {
  string title = 1;
  string content_type_name = 2;
  // field 3 is reserved (not used in current schema)
  string description = 4;
  string entity_uri = 5;
  string navigate_uri = 6;
  string like_uri = 7;
  string entity_image_url = 8;
  google.protobuf.Duration duration = 9;
  google.protobuf.Timestamp publish_time = 10;
  string background_color_hex = 11;
  string waveform_color_hex = 12;
  PreviewRestriction preview_restriction = 13;
  Labels labels = 14;
  repeated DescriptorTag descriptor_tags = 15;
  int32 number_of_items = 16;
  ContentParent content_parent = 17;
  SubtitleSource subtitle_source = 18;
}

message Labels {
  string preview_label = 1;
  string playing_label = 2;
}

message DescriptorTag {
  string name = 1;
}

message ContentParent {
  string name = 1;
  string uri = 2;
  string image_url = 3;
}

enum PreviewRestriction {
  PREVIEW_RESTRICTION_NONE = 0;
  PREVIEW_IS_EXPLICIT = 1;
  PREVIEW_IS_19_PLUS = 2;
}

enum SubtitleSource {
  SUBTITLE_SOURCE_UNKNOWN = 0;
  SUBTITLE_SOURCE_GENERATED_METADATA = 1;
  SUBTITLE_SOURCE_OPERATOR_AUTHORED = 2;
}
```
