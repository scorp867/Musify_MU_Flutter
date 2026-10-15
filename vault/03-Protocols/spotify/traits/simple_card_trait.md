---
title: "simple_card_trait.proto"
path: "protos/spotify/traits/simple_card_trait.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.extendedmetadata.extensions.simplecardtrait"
messages: 3
---

# simple_card_trait.proto

> Source Schema: `[protos/spotify/traits/simple_card_trait.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/traits/simple_card_trait.proto)`
> Syntax: `proto3` | Package: `spotify.extendedmetadata.extensions.simplecardtrait`

## Schema Overview
`simple_card_trait.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/traits/simple_card_trait.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/traits/simple_card_trait.pb.dart)`
- `[lib/core/protocol/generated/spotify/traits/simple_card_trait.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/traits/simple_card_trait.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/traits/simple_card_trait.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/traits/simple_card_trait.pbjson.dart)`

## Imported Proto Dependencies
- `google/protobuf/duration.proto`
- `google/protobuf/timestamp.proto`

## Message Definitions
### `message SimpleCardTrait`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `image_uri` |
| `2` | `optional` | `string` | `title` |
| `3` | `optional` | `string` | `subtitle` |
| `4` | `optional` | `string` | `navigation_uri` |
| `5` | `repeated` | `Label` | `labels` |
| `6` | `optional` | `string` | `accessibility` |
| `7` | `optional` | `Restriction` | `restriction` |
| `8` | `repeated` | `Creator` | `creators` |
| `9` | `optional` | `google.protobuf.Timestamp` | `publish_time` |
| `10` | `optional` | `google.protobuf.Duration` | `duration` |
| `11` | `optional` | `string` | `animation_url` |
| `12` | `optional` | `string` | `title_text_color` |

### `message Label`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `text` |

### `message Creator`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |
| `2` | `optional` | `string` | `uri` |

## Enum Definitions
### `enum Restriction`
| Number | Identifier |
|--------|------------|
| `0` | `NONE` |
| `1` | `IS_EXPLICIT` |
| `2` | `IS_19_PLUS` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.extendedmetadata.extensions.simplecardtrait;

import "google/protobuf/duration.proto";
import "google/protobuf/timestamp.proto";

option optimize_for = CODE_SIZE;

// SimpleCardTrait - ExtensionKind 97
// The primary trait used to render standard card items on the home screen.
// NOT embedded in Casita response; fetched via Extended Metadata API.

message SimpleCardTrait {
  string image_uri = 1;
  string title = 2;
  string subtitle = 3;
  string navigation_uri = 4;
  repeated Label labels = 5;
  string accessibility = 6;
  Restriction restriction = 7;
  repeated Creator creators = 8;
  google.protobuf.Timestamp publish_time = 9;
  google.protobuf.Duration duration = 10;
  string animation_url = 11;
  string title_text_color = 12;
}

message Label {
  string text = 1;
}

message Creator {
  string name = 1;
  string uri = 2;
}

enum Restriction {
  NONE = 0;
  IS_EXPLICIT = 1;
  IS_19_PLUS = 2;
}
```
