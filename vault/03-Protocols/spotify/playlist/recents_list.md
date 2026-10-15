---
title: "recents_list.proto"
path: "protos/spotify/playlist/recents_list.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.playlist.v2"
messages: 8
---

# recents_list.proto

> Source Schema: `[protos/spotify/playlist/recents_list.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/playlist/recents_list.proto)`
> Syntax: `proto3` | Package: `spotify.playlist.v2`

## Schema Overview
`recents_list.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/playlist/recents_list.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/playlist/recents_list.pb.dart)`
- `[lib/core/protocol/generated/spotify/playlist/recents_list.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/playlist/recents_list.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/playlist/recents_list.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/playlist/recents_list.pbjson.dart)`

## Message Definitions
### `message RecentsListResponse`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `bytes` | `revision` |
| `2` | `optional` | `int32` | `length` |
| `3` | `optional` | `RecentsListAttributes` | `list_attributes` |
| `5` | `optional` | `RecentsItemList` | `list` |
| `9` | `optional` | `bool` | `multiple_heads` |
| `10` | `optional` | `bool` | `up_to_date` |
| `14` | `repeated` | `int64` | `nonces` |
| `15` | `optional` | `int64` | `timestamp` |
| `16` | `optional` | `string` | `owner_username` |
| `17` | `optional` | `bool` | `abuse_reporting_enabled` |
| `19` | `repeated` | `int32` | `geoblock` |
| `20` | `optional` | `bool` | `changes_require_resync` |
| `21` | `optional` | `int64` | `created_at` |

### `message RecentsListAttributes`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |
| `2` | `optional` | `string` | `description` |
| `3` | `optional` | `bytes` | `picture` |
| `4` | `optional` | `bool` | `collaborative` |
| `5` | `optional` | `string` | `pl3_version` |
| `6` | `optional` | `bool` | `deleted_by_owner` |
| `10` | `optional` | `string` | `client_id` |
| `11` | `optional` | `string` | `format` |
| `12` | `repeated` | `FormatAttribute` | `format_attributes` |

### `message RecentsItemList`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `pos` |
| `2` | `optional` | `bool` | `truncated` |
| `3` | `repeated` | `RecentsListItem` | `items` |
| `6` | `optional` | `string` | `continuation_token` |

### `message RecentsListItem`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `uri` |
| `2` | `optional` | `RecentsItemAttributes` | `attributes` |

### `message RecentsItemAttributes`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `added_by` |
| `2` | `optional` | `int64` | `timestamp` |
| `9` | `optional` | `int64` | `seen_at` |
| `10` | `optional` | `bool` | `public` |
| `11` | `repeated` | `FormatAttribute` | `format_attributes` |
| `12` | `optional` | `bytes` | `item_id` |
| `17` | `optional` | `int32` | `save_source` |

### `message FormatAttribute`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `key` |
| `2` | `optional` | `string` | `value` |

### `message GroupMetadata`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `items_count` |
| `2` | `repeated` | `string` | `entity_uris` |
| `3` | `repeated` | `string` | `user_uris` |
| `5` | `optional` | `string` | `group_name` |

### `message ShareMetadata`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `user_uri` |
| `2` | `optional` | `string` | `share_deeplink` |
| `3` | `optional` | `string` | `source` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.playlist.v2;

option optimize_for = CODE_SIZE;

// Response from /playlist/v2/list/recents/main
// Maps to com.spotify.playlist4.proto.Playlist4ApiProto.SelectedListContent

message RecentsListResponse {
  bytes revision = 1;
  int32 length = 2;
  RecentsListAttributes list_attributes = 3;
  // Field 4 reserved
  RecentsItemList list = 5;
  // Fields 6-7: Diff/SyncResult (unused)
  // Field 8: resulting_revisions (unused)
  bool multiple_heads = 9;
  bool up_to_date = 10;
  // Fields 11-13 reserved
  repeated int64 nonces = 14;
  int64 timestamp = 15;
  string owner_username = 16;
  bool abuse_reporting_enabled = 17;
  // Field 18: Capabilities (unused)
  repeated int32 geoblock = 19;
  bool changes_require_resync = 20;
  int64 created_at = 21;
}

message RecentsListAttributes {
  string name = 1;
  string description = 2;
  bytes picture = 3;
  bool collaborative = 4;
  string pl3_version = 5;
  bool deleted_by_owner = 6;
  // Fields 7-9 unused
  string client_id = 10;
  string format = 11;
  repeated FormatAttribute format_attributes = 12;
}

message RecentsItemList {
  int32 pos = 1;
  bool truncated = 2;
  repeated RecentsListItem items = 3;
  // Field 4: MetaItems (unused)
  // Field 5: Signals (unused)
  string continuation_token = 6;
}

message RecentsListItem {
  string uri = 1;
  RecentsItemAttributes attributes = 2;
}

message RecentsItemAttributes {
  string added_by = 1;
  int64 timestamp = 2;
  // Fields 3-8 unused
  int64 seen_at = 9;
  bool public = 10;
  repeated FormatAttribute format_attributes = 11;
  bytes item_id = 12;
  // Field 13: SourceLens (unused)
  // Field 14: Signals (unused)
  // Field 15: RecommendationInfo (unused)
  // Field 16: sequence_child_template (unused)
  int32 save_source = 17;
}

message FormatAttribute {
  string key = 1;
  string value = 2;
}

// Sub-proto decoded from format_attribute key="group_metadata" (Base64-encoded).
// Maps to com.spotify.recents.recentsdatasourceimpl.GroupMetadata
message GroupMetadata {
  int32 items_count = 1;
  repeated string entity_uris = 2;
  repeated string user_uris = 3;
  map<string, int32> filtered_count = 4;
  string group_name = 5;
}

// Sub-proto decoded from format_attribute key="share" (Base64-encoded).
// Maps to com.spotify.recents.recentsdatasourceimpl.Share
message ShareMetadata {
  string user_uri = 1;
  string share_deeplink = 2;
  string source = 3;
}
```
