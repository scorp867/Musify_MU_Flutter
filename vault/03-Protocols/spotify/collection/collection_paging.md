---
title: "collection_paging.proto"
path: "protos/spotify/collection/collection_paging.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.collection.v2"
messages: 3
---

# collection_paging.proto

> Source Schema: `[protos/spotify/collection/collection_paging.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/collection/collection_paging.proto)`
> Syntax: `proto3` | Package: `spotify.collection.v2`

## Schema Overview
`collection_paging.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/collection/collection_paging.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/collection/collection_paging.pb.dart)`
- `[lib/core/protocol/generated/spotify/collection/collection_paging.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/collection/collection_paging.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/collection/collection_paging.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/collection/collection_paging.pbjson.dart)`

## Message Definitions
### `message PageRequest`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `username` |
| `2` | `optional` | `string` | `set_name` |
| `4` | `optional` | `sint32` | `limit` |

### `message PageResponse`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `CollectionItem` | `items` |
| `3` | `optional` | `string` | `sync_token` |

### `message CollectionItem`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `uri` |
| `2` | `optional` | `int64` | `added_at` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.collection.v2;

option optimize_for = CODE_SIZE;

// Request for POST /collection/v2/paging
// Reverse-engineered from MITM captures.
//
// The request payload is:
//   field 1: username (string)
//   field 2: set_name (string) -- "collection", "artist", "show", "ylpin", etc.
//   field 4: limit (sint32, zigzag encoded)

message PageRequest {
  string username = 1;
  string set_name = 2;
  // field 3 is unused/unknown
  sint32 limit = 4;
}

// Response from POST /collection/v2/paging
// Content-Type: application/vnd.collection-v2.spotify.proto
//
// From MITM capture:
//   field 1: repeated Item { 1: uri, 2: added_at }
//   field 3: sync_token (string, looks like a timestamp)

message PageResponse {
  repeated CollectionItem items = 1;
  // field 2 is unused/unknown
  string sync_token = 3;
}

message CollectionItem {
  string uri = 1;
  int64 added_at = 2;
  // Higher fields (1001-1009) contain ItemData oneofs,
  // not needed for library rendering.
}
```
