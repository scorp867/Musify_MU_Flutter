---
title: "visual_identity_trait.proto"
path: "protos/spotify/contentagnostic/v2/visual_identity_trait.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.contentagnostic.v2"
messages: 1
---

# visual_identity_trait.proto

> Source Schema: `[protos/spotify/contentagnostic/v2/visual_identity_trait.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/contentagnostic/v2/visual_identity_trait.proto)`
> Syntax: `proto3` | Package: `spotify.contentagnostic.v2`

## Schema Overview
`visual_identity_trait.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/visual_identity_trait.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/visual_identity_trait.pb.dart)`
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/visual_identity_trait.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/visual_identity_trait.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/visual_identity_trait.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/visual_identity_trait.pbjson.dart)`

## Imported Proto Dependencies
- `spotify/contentagnostic/v2/visual_types.proto`

## Message Definitions
### `message VisualIdentityTrait`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Image` | `square_cover_image` |
| `2` | `optional` | `Image` | `sixteen_by_nine_cover_image` |
| `4` | `optional` | `Video` | `nine_by_sixteen_cover_video` |
| `5` | `optional` | `Image` | `square_full_bleed_image` |
| `6` | `optional` | `Image` | `wide_full_bleed_image` |
| `7` | `optional` | `ColorSetContrastOptions` | `curated_color` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.contentagnostic.v2;

import "spotify/contentagnostic/v2/visual_types.proto";

option optimize_for = CODE_SIZE;

// =========================================================================
// VisualIdentityTrait (ExtensionKind 179)
// Provides cover images and curated colors for entities
// =========================================================================

message VisualIdentityTrait {
  Image square_cover_image = 1;
  Image sixteen_by_nine_cover_image = 2;
  // field 3 unused
  Video nine_by_sixteen_cover_video = 4;
  Image square_full_bleed_image = 5;
  Image wide_full_bleed_image = 6;
  ColorSetContrastOptions curated_color = 7;
}
```
