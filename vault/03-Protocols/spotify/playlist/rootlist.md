---
title: "rootlist.proto"
path: "protos/spotify/playlist/rootlist.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.playlist.v2"
messages: 11
---

# rootlist.proto

> Source Schema: `[protos/spotify/playlist/rootlist.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/playlist/rootlist.proto)`
> Syntax: `proto3` | Package: `spotify.playlist.v2`

## Schema Overview
`rootlist.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/playlist/rootlist.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/playlist/rootlist.pb.dart)`
- `[lib/core/protocol/generated/spotify/playlist/rootlist.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/playlist/rootlist.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/playlist/rootlist.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/playlist/rootlist.pbjson.dart)`

## Message Definitions
### `message SelectedListContent`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `bytes` | `revision` |
| `2` | `optional` | `int32` | `length` |
| `3` | `optional` | `ListAttributes` | `attributes` |
| `5` | `optional` | `ListItems` | `contents` |
| `15` | `optional` | `int64` | `timestamp` |
| `16` | `optional` | `string` | `owner_username` |
| `21` | `optional` | `int64` | `created_at` |

### `message ListItems`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `pos` |
| `2` | `optional` | `bool` | `truncated` |
| `3` | `repeated` | `Item` | `items` |
| `4` | `repeated` | `MetaItem` | `meta_items` |
| `6` | `optional` | `string` | `continuation_token` |

### `message Item`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `uri` |
| `2` | `optional` | `ItemAttributes` | `attributes` |

### `message ItemAttributes`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `added_by` |
| `2` | `optional` | `int64` | `timestamp` |
| `9` | `optional` | `int64` | `seen_at` |
| `10` | `optional` | `bool` | `public` |
| `11` | `repeated` | `FormatListAttribute` | `format_attributes` |
| `12` | `optional` | `bytes` | `item_id` |

### `message ListAttributes`
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
| `12` | `repeated` | `FormatListAttribute` | `format_attributes` |
| `13` | `repeated` | `PictureSize` | `picture_size` |
| `17` | `optional` | `bool` | `recoverable` |
| `18` | `optional` | `bool` | `is_user_created` |

### `message FormatListAttribute`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `key` |
| `2` | `optional` | `string` | `value` |

### `message PictureSize`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `target_name` |
| `2` | `optional` | `string` | `url` |

### `message MetaItem`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `bytes` | `revision` |
| `2` | `optional` | `ListAttributes` | `attributes` |
| `3` | `optional` | `int32` | `length` |
| `4` | `optional` | `int64` | `timestamp` |
| `5` | `optional` | `string` | `owner_username` |
| `6` | `optional` | `bool` | `abuse_reporting_enabled` |
| `7` | `optional` | `Capabilities` | `capabilities` |
| `8` | `repeated` | `GeoblockBlockingType` | `geoblock` |
| `9` | `optional` | `int32` | `status_code` |

### `message Capabilities`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `bool` | `can_view` |
| `2` | `optional` | `bool` | `can_administrate_permissions` |
| `4` | `optional` | `bool` | `can_edit_metadata` |
| `5` | `optional` | `bool` | `can_edit_items` |
| `6` | `optional` | `bool` | `can_cancel_membership` |
| `7` | `repeated` | `PermissionLevel` | `grantable_levels` |
| `8` | `optional` | `ListAttributeCapabilities` | `list_attribute_capabilities` |

### `message ListAttributeCapabilities`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `AttributeCapabilities` | `name` |
| `2` | `optional` | `AttributeCapabilities` | `description` |
| `3` | `optional` | `AttributeCapabilities` | `picture` |
| `4` | `optional` | `AttributeCapabilities` | `collaborative` |

### `message AttributeCapabilities`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `bool` | `can_edit` |

## Enum Definitions
### `enum PermissionLevel`
| Number | Identifier |
|--------|------------|
| `0` | `PERMISSION_LEVEL_UNKNOWN` |
| `1` | `BLOCKED` |
| `2` | `VIEWER` |
| `3` | `CONTRIBUTOR` |
| `4` | `MADE_FOR` |

### `enum GeoblockBlockingType`
| Number | Identifier |
|--------|------------|
| `0` | `GEOBLOCK_BLOCKING_TYPE_UNSPECIFIED` |
| `1` | `GEOBLOCK_BLOCKING_TYPE_BLOCKED` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.playlist.v2;

option optimize_for = CODE_SIZE;

// Response from GET /playlist/v2/user/{userId}/rootlist
// Reverse-engineered from Playlist4ApiProto.java (decompiled APK).

message SelectedListContent {
  bytes revision = 1;
  int32 length = 2;
  ListAttributes attributes = 3;
  // field 4 unused
  ListItems contents = 5;
  // field 6: diff (see playlist_detail.proto)
  // field 7: sync_result
  // field 8: resulting_revisions
  // field 9: multiple_heads
  // field 10: up_to_date
  // field 14: nonces
  int64 timestamp = 15;
  string owner_username = 16;
  // field 17: abuse_reporting_enabled
  // field 18: capabilities
  // field 19: geoblock
  // field 20: changes_require_resync
  int64 created_at = 21;
}

// ─── Shared types used by rootlist AND playlist detail ────────────────

message ListItems {
  int32 pos = 1;
  bool truncated = 2;
  repeated Item items = 3;
  repeated MetaItem meta_items = 4;
  // field 5: available_signals
  string continuation_token = 6;
}

message Item {
  string uri = 1;
  ItemAttributes attributes = 2;
}

message ItemAttributes {
  string added_by = 1;
  int64 timestamp = 2;
  // field 3-8 unused
  int64 seen_at = 9;
  bool public = 10;
  repeated FormatListAttribute format_attributes = 11;
  bytes item_id = 12;
}

message ListAttributes {
  string name = 1;
  string description = 2;
  bytes picture = 3;
  bool collaborative = 4;
  string pl3_version = 5;
  bool deleted_by_owner = 6;
  // fields 7-9 unused
  string client_id = 10;
  string format = 11;
  repeated FormatListAttribute format_attributes = 12;
  repeated PictureSize picture_size = 13;
  // field 14: sequence_context_template
  // field 15: ai_curation_reference_id
  // field 16: item_id_algorithm
  bool recoverable = 17;
  bool is_user_created = 18;
}

message FormatListAttribute {
  string key = 1;
  string value = 2;
}

message PictureSize {
  string target_name = 1;
  string url = 2;
}

message MetaItem {
  bytes revision = 1;
  ListAttributes attributes = 2;
  int32 length = 3;
  int64 timestamp = 4;
  string owner_username = 5;
  bool abuse_reporting_enabled = 6;
  Capabilities capabilities = 7;
  repeated GeoblockBlockingType geoblock = 8;
  int32 status_code = 9;
}

// ─── Capabilities (used by both MetaItem and playlist detail) ────────

message Capabilities {
  bool can_view = 1;
  bool can_administrate_permissions = 2;
  // field 3 unused
  bool can_edit_metadata = 4;
  bool can_edit_items = 5;
  bool can_cancel_membership = 6;
  repeated PermissionLevel grantable_levels = 7;
  ListAttributeCapabilities list_attribute_capabilities = 8;
}

message ListAttributeCapabilities {
  AttributeCapabilities name = 1;
  AttributeCapabilities description = 2;
  AttributeCapabilities picture = 3;
  AttributeCapabilities collaborative = 4;
}

message AttributeCapabilities {
  bool can_edit = 1;
}

enum PermissionLevel {
  PERMISSION_LEVEL_UNKNOWN = 0;
  BLOCKED = 1;
  VIEWER = 2;
  CONTRIBUTOR = 3;
  MADE_FOR = 4;
}

enum GeoblockBlockingType {
  GEOBLOCK_BLOCKING_TYPE_UNSPECIFIED = 0;
  GEOBLOCK_BLOCKING_TYPE_BLOCKED = 1;
}
```
