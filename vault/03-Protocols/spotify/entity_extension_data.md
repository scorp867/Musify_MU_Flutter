---
title: "entity_extension_data.proto"
path: "protos/spotify/entity_extension_data.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.extendedmetadata"
messages: 2
---

# entity_extension_data.proto

> Source Schema: `[protos/spotify/entity_extension_data.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/entity_extension_data.proto)`
> Syntax: `proto3` | Package: `spotify.extendedmetadata`

## Schema Overview
`entity_extension_data.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/entity_extension_data.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/entity_extension_data.pb.dart)`
- `[lib/core/protocol/generated/spotify/entity_extension_data.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/entity_extension_data.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/entity_extension_data.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/entity_extension_data.pbjson.dart)`

## Imported Proto Dependencies
- `google/protobuf/any.proto`

## Message Definitions
### `message EntityExtensionDataHeader`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `status_code` |
| `2` | `optional` | `string` | `etag` |
| `3` | `optional` | `string` | `locale` |
| `4` | `optional` | `int64` | `cache_ttl_in_seconds` |
| `5` | `optional` | `int64` | `offline_ttl_in_seconds` |

### `message EntityExtensionData`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `EntityExtensionDataHeader` | `header` |
| `2` | `optional` | `string` | `entity_uri` |
| `3` | `optional` | `google.protobuf.Any` | `extension_data` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.extendedmetadata;

import "google/protobuf/any.proto";

option optimize_for = CODE_SIZE;

message EntityExtensionDataHeader {
    int32 status_code = 1;
    string etag = 2;
    string locale = 3;
    int64 cache_ttl_in_seconds = 4;
    int64 offline_ttl_in_seconds = 5;
}

message EntityExtensionData {
    EntityExtensionDataHeader header = 1;
    string entity_uri = 2;
    google.protobuf.Any extension_data = 3;
}
```
