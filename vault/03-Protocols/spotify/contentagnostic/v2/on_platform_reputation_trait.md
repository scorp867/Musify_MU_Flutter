---
title: "on_platform_reputation_trait.proto"
path: "protos/spotify/contentagnostic/v2/on_platform_reputation_trait.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.contentagnostic.v2"
messages: 4
---

# on_platform_reputation_trait.proto

> Source Schema: `[protos/spotify/contentagnostic/v2/on_platform_reputation_trait.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/contentagnostic/v2/on_platform_reputation_trait.proto)`
> Syntax: `proto3` | Package: `spotify.contentagnostic.v2`

## Schema Overview
`on_platform_reputation_trait.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/on_platform_reputation_trait.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/on_platform_reputation_trait.pb.dart)`
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/on_platform_reputation_trait.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/on_platform_reputation_trait.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/on_platform_reputation_trait.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/on_platform_reputation_trait.pbjson.dart)`

## Message Definitions
### `message Verification`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `bool` | `is_registered` |
| `2` | `optional` | `bool` | `is_verified` |

### `message ChartPosition`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `chart_url` |
| `2` | `optional` | `string` | `description` |

### `message Rating`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `double` | `average` |
| `2` | `optional` | `int32` | `count` |

### `message OnPlatformReputationTrait`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `total_established_user_relationships` |
| `3` | `optional` | `int64` | `total_plays` |
| `4` | `optional` | `int64` | `monthly_listeners` |
| `7` | `optional` | `ChartPosition` | `chart_position` |
| `8` | `optional` | `Rating` | `rating` |
| `9` | `optional` | `Verification` | `verification` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.contentagnostic.v2;

option java_package = "com.spotify.contentagnostic.v2";

/// Verification status for an artist entity.
/// Decompiled from `Verification.java`.
message Verification {
  bool is_registered = 1;
  bool is_verified = 2;
  // field 3: AiPersona  -  omitted (not needed for UI)
}

/// Chart position data.
/// Decompiled from `ChartPosition.java`.
message ChartPosition {
  string chart_url = 1;
  string description = 2;
}

/// Rating data.
/// Decompiled from `Rating.java`.
message Rating {
  double average = 1;
  int32 count = 2;
}

/// ExtensionKind 185  -  ON_PLATFORM_REPUTATION_TRAIT.
/// Decompiled from `OnPlatformReputationTrait.java`.
///
/// Provides monthly listeners, verification status, total plays, etc.
/// Used by the "About the artist" card to show real metrics.
message OnPlatformReputationTrait {
  int64 total_established_user_relationships = 1;
  // field 2: reserved
  int64 total_plays = 3;
  int64 monthly_listeners = 4;
  // fields 5-6: reserved
  ChartPosition chart_position = 7;
  Rating rating = 8;
  Verification verification = 9;
}
```
