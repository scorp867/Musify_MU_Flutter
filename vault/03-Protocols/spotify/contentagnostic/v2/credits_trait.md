---
title: "credits_trait.proto"
path: "protos/spotify/contentagnostic/v2/credits_trait.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.contentagnostic.v2"
messages: 4
---

# credits_trait.proto

> Source Schema: `[protos/spotify/contentagnostic/v2/credits_trait.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/contentagnostic/v2/credits_trait.proto)`
> Syntax: `proto3` | Package: `spotify.contentagnostic.v2`

## Schema Overview
`credits_trait.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/credits_trait.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/credits_trait.pb.dart)`
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/credits_trait.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/credits_trait.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/credits_trait.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/credits_trait.pbjson.dart)`

## Message Definitions
### `message RoleGroup`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |

### `message Contributor`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |
| `2` | `optional` | `string` | `role` |
| `3` | `optional` | `string` | `uri` |
| `5` | `optional` | `string` | `url` |
| `6` | `optional` | `RoleGroup` | `role_group` |

### `message CreditsSource`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |

### `message CreditsTrait`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `Contributor` | `contributors` |
| `2` | `repeated` | `CreditsSource` | `sources` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.contentagnostic.v2;

option java_package = "com.spotify.contentagnostic.v2";

/// Role group categorization for a contributor.
/// Decompiled from `RoleGroup.java`.
message RoleGroup {
  string name = 1;
}

/// A single contributor (artist, writer, producer, etc.) on a track.
/// Decompiled from `Contributor.java`.
///
/// Field numbers match the decompiled APK exactly:
///   name=1, role=2, uri=3, reference=4, url=5, role_group=6, ai_attribution=7
message Contributor {
  string name = 1;
  string role = 2;
  string uri = 3;
  // field 4: Reference (nested message  -  omitted, not needed for card UI)
  string url = 5;
  RoleGroup role_group = 6;
  // field 7: AiAttribution (nested message  -  omitted)
}

/// Source attribution for credits.
/// Decompiled from `CreditsSource.java`.
message CreditsSource {
  string name = 1;
}

/// ExtensionKind 186  -  CREDITS_V2_TRAIT.
/// Decompiled from `CreditsTrait.java`.
///
/// Contains the full list of track contributors with their roles,
/// and optional source attributions.
message CreditsTrait {
  repeated Contributor contributors = 1;
  repeated CreditsSource sources = 2;
}
```
