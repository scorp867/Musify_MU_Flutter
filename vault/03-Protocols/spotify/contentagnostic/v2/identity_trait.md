---
title: "identity_trait.proto"
path: "protos/spotify/contentagnostic/v2/identity_trait.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.contentagnostic.v2"
messages: 3
---

# identity_trait.proto

> Source Schema: `[protos/spotify/contentagnostic/v2/identity_trait.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/contentagnostic/v2/identity_trait.proto)`
> Syntax: `proto3` | Package: `spotify.contentagnostic.v2`

## Schema Overview
`identity_trait.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/identity_trait.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/identity_trait.pb.dart)`
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/identity_trait.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/identity_trait.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/identity_trait.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/identity_trait.pbjson.dart)`

## Message Definitions
### `message IdentityTrait`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `type` |
| `2` | `optional` | `string` | `name` |
| `3` | `optional` | `string` | `description` |
| `4` | `optional` | `EntityReference` | `content_hierarchy_parent` |
| `5` | `repeated` | `ContributorReference` | `contributors` |

### `message EntityReference`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |
| `2` | `optional` | `string` | `uri` |

### `message ContributorReference`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |
| `2` | `optional` | `string` | `uri` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.contentagnostic.v2;

option optimize_for = CODE_SIZE;

// =========================================================================
// IdentityTrait (ExtensionKind 178)
// Provides name, type, description for entities
// =========================================================================

message IdentityTrait {
  string type = 1;
  string name = 2;
  string description = 3;
  EntityReference content_hierarchy_parent = 4;
  repeated ContributorReference contributors = 5;
}

message EntityReference {
  string name = 1;
  string uri = 2;
}

message ContributorReference {
  string name = 1;
  string uri = 2;
}
```
