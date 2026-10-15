---
title: "shortcuts_card_trait.proto"
path: "protos/spotify/traits/shortcuts_card_trait.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.extendedmetadata.extensions.shortcutscardtrait"
messages: 1
---

# shortcuts_card_trait.proto

> Source Schema: `[protos/spotify/traits/shortcuts_card_trait.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/traits/shortcuts_card_trait.proto)`
> Syntax: `proto3` | Package: `spotify.extendedmetadata.extensions.shortcutscardtrait`

## Schema Overview
`shortcuts_card_trait.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/traits/shortcuts_card_trait.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/traits/shortcuts_card_trait.pb.dart)`
- `[lib/core/protocol/generated/spotify/traits/shortcuts_card_trait.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/traits/shortcuts_card_trait.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/traits/shortcuts_card_trait.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/traits/shortcuts_card_trait.pbjson.dart)`

## Message Definitions
### `message ShortcutsCardTrait`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `image_url` |
| `2` | `optional` | `string` | `title` |
| `3` | `optional` | `string` | `navigation_uri` |
| `4` | `optional` | `string` | `entity_uri` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.extendedmetadata.extensions.shortcutscardtrait;

option optimize_for = CODE_SIZE;

// ShortcutsCardTrait - Used for the quick-access shortcut grid at the top of home
// Embedded in the Casita response via EagerlyLoadedTraits

message ShortcutsCardTrait {
  string image_url = 1;
  string title = 2;
  string navigation_uri = 3;
  string entity_uri = 4;
}
```
