---
title: "extended_metadata.proto"
path: "protos/spotify/extended_metadata.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.extendedmetadata"
messages: 8
---

# extended_metadata.proto

> Source Schema: `[protos/spotify/extended_metadata.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/extended_metadata.proto)`
> Syntax: `proto3` | Package: `spotify.extendedmetadata`

## Schema Overview
`extended_metadata.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/extended_metadata.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/extended_metadata.pb.dart)`
- `[lib/core/protocol/generated/spotify/extended_metadata.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/extended_metadata.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/extended_metadata.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/extended_metadata.pbjson.dart)`

## Imported Proto Dependencies
- `spotify/extension_kind.proto`
- `spotify/entity_extension_data.proto`

## Message Definitions
### `message ExtensionQuery`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ExtensionKind` | `extension_kind` |
| `2` | `optional` | `string` | `etag` |

### `message EntityRequest`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `entity_uri` |
| `2` | `repeated` | `ExtensionQuery` | `query` |

### `message BatchedEntityRequestHeader`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `country` |
| `2` | `optional` | `string` | `catalogue` |
| `3` | `optional` | `bytes` | `task_id` |

### `message BatchedEntityRequest`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `BatchedEntityRequestHeader` | `header` |
| `2` | `repeated` | `EntityRequest` | `entity_request` |

### `message EntityExtensionDataArrayHeader`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `provider_error_status` |
| `2` | `optional` | `int64` | `cache_ttl_in_seconds` |
| `3` | `optional` | `int64` | `offline_ttl_in_seconds` |
| `4` | `optional` | `ExtensionType` | `extension_type` |

### `message EntityExtensionDataArray`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `EntityExtensionDataArrayHeader` | `header` |
| `2` | `optional` | `ExtensionKind` | `extension_kind` |
| `3` | `repeated` | `EntityExtensionData` | `extension_data` |

### `message BatchedExtensionResponseHeader`
- Empty message container or extension wrapper.

### `message BatchedExtensionResponse`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `BatchedExtensionResponseHeader` | `header` |
| `2` | `repeated` | `EntityExtensionDataArray` | `extended_metadata` |

## Enum Definitions
### `enum ExtensionType`
| Number | Identifier |
|--------|------------|
| `0` | `UNKNOWN` |
| `1` | `GENERIC` |
| `2` | `ASSOC` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.extendedmetadata;

import "spotify/extension_kind.proto";
import "spotify/entity_extension_data.proto";

option optimize_for = CODE_SIZE;

message ExtensionQuery {
    ExtensionKind extension_kind = 1;
    string etag = 2;
}

message EntityRequest {
    string entity_uri = 1;
    repeated ExtensionQuery query = 2;
}

message BatchedEntityRequestHeader {
    string country = 1;
    string catalogue = 2;
    bytes task_id = 3;
}

message BatchedEntityRequest {
    BatchedEntityRequestHeader header = 1;
    repeated EntityRequest entity_request = 2;
}

enum ExtensionType {
    UNKNOWN = 0;
    GENERIC = 1;
    ASSOC = 2;
}

message EntityExtensionDataArrayHeader {
    int32 provider_error_status = 1;
    int64 cache_ttl_in_seconds = 2;
    int64 offline_ttl_in_seconds = 3;
    ExtensionType extension_type = 4;
}

message EntityExtensionDataArray {
    EntityExtensionDataArrayHeader header = 1;
    ExtensionKind extension_kind = 2;
    repeated EntityExtensionData extension_data = 3;
}

message BatchedExtensionResponseHeader {
}

message BatchedExtensionResponse {
    BatchedExtensionResponseHeader header = 1;
    repeated EntityExtensionDataArray extended_metadata = 2;
}
```
