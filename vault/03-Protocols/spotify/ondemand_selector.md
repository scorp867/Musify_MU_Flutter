---
title: "ondemand_selector.proto"
path: "protos/spotify/ondemand_selector.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.ondemandselector"
messages: 1
---

# ondemand_selector.proto

> Source Schema: `[protos/spotify/ondemand_selector.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/ondemand_selector.proto)`
> Syntax: `proto3` | Package: `spotify.ondemandselector`

## Schema Overview
`ondemand_selector.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/ondemand_selector.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/ondemand_selector.pb.dart)`
- `[lib/core/protocol/generated/spotify/ondemand_selector.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/ondemand_selector.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/ondemand_selector.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/ondemand_selector.pbjson.dart)`

## Message Definitions
### `message OndemandResponse`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `string` | `uris` |
| `2` | `optional` | `int64` | `expire_timestamp_millis` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.ondemandselector;

option optimize_for = CODE_SIZE;

// Response from GET /ondemand-selector/v1/select-ondemand-set
// Returns the filtered set of URIs that need trait resolution.
message OndemandResponse {
  repeated string uris = 1;
  int64 expire_timestamp_millis = 2;
}
```
