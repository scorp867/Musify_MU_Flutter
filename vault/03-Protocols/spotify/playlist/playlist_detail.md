---
title: "playlist_detail.proto"
path: "protos/spotify/playlist/playlist_detail.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.playlist.v2"
messages: 13
---

# playlist_detail.proto

> Source Schema: `[protos/spotify/playlist/playlist_detail.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/playlist/playlist_detail.proto)`
> Syntax: `proto3` | Package: `spotify.playlist.v2`

## Schema Overview
`playlist_detail.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/playlist/playlist_detail.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/playlist/playlist_detail.pb.dart)`
- `[lib/core/protocol/generated/spotify/playlist/playlist_detail.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/playlist/playlist_detail.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/playlist/playlist_detail.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/playlist/playlist_detail.pbjson.dart)`

## Imported Proto Dependencies
- `spotify/playlist/rootlist.proto`

## Message Definitions
### `message PlaylistResponse`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `bytes` | `revision` |
| `2` | `optional` | `int32` | `length` |
| `3` | `optional` | `ListAttributes` | `attributes` |
| `5` | `optional` | `ListItems` | `contents` |
| `6` | `optional` | `Diff` | `diff` |
| `7` | `optional` | `Diff` | `sync_result` |
| `8` | `repeated` | `bytes` | `resulting_revisions` |
| `9` | `optional` | `bool` | `multiple_heads` |
| `10` | `optional` | `bool` | `up_to_date` |
| `14` | `repeated` | `int64` | `nonces` |
| `15` | `optional` | `int64` | `timestamp` |
| `16` | `optional` | `string` | `owner_username` |
| `17` | `optional` | `bool` | `abuse_reporting_enabled` |
| `18` | `optional` | `Capabilities` | `capabilities` |
| `19` | `repeated` | `GeoblockBlockingType` | `geoblock` |
| `20` | `optional` | `bool` | `changes_require_resync` |
| `21` | `optional` | `int64` | `created_at` |

### `message Diff`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `bytes` | `from_revision` |
| `2` | `repeated` | `Op` | `ops` |
| `3` | `optional` | `bytes` | `to_revision` |
| `4` | `optional` | `AvailableSignals` | `available_signals` |

### `message Op`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `OpKind` | `kind` |
| `2` | `optional` | `Add` | `add` |
| `3` | `optional` | `Rem` | `rem` |
| `4` | `optional` | `Mov` | `mov` |
| `5` | `optional` | `UpdateItemAttributes` | `update_item_attributes` |
| `6` | `optional` | `UpdateListAttributes` | `update_list_attributes` |
| `7` | `optional` | `UpdateItemUris` | `update_item_uris` |

### `message Add`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `from_index` |
| `2` | `repeated` | `Item` | `items` |
| `4` | `optional` | `bool` | `add_last` |
| `5` | `optional` | `bool` | `add_first` |
| `6` | `optional` | `Item` | `add_before_item` |
| `7` | `optional` | `Item` | `add_after_item` |

### `message Rem`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `from_index` |
| `2` | `optional` | `int32` | `length` |
| `3` | `repeated` | `Item` | `items` |
| `7` | `optional` | `bool` | `items_as_key` |

### `message Mov`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `from_index` |
| `2` | `optional` | `int32` | `length` |
| `3` | `optional` | `int32` | `to_index` |
| `4` | `repeated` | `Item` | `items` |
| `5` | `optional` | `Item` | `add_before_item` |
| `6` | `optional` | `Item` | `add_after_item` |
| `7` | `optional` | `bool` | `add_first` |
| `8` | `optional` | `bool` | `add_last` |

### `message UpdateListAttributes`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ListAttributesPartialState` | `new_attributes` |
| `2` | `optional` | `ListAttributesPartialState` | `old_attributes` |

### `message UpdateItemAttributes`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `index` |
| `2` | `optional` | `ItemAttributesPartialState` | `new_attributes` |
| `3` | `optional` | `ItemAttributesPartialState` | `old_attributes` |
| `4` | `optional` | `Item` | `item` |

### `message UpdateItemUris`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `UriReplacement` | `uri_replacements` |

### `message UriReplacement`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `index` |
| `2` | `optional` | `Item` | `item` |
| `3` | `optional` | `string` | `new_uri` |

### `message ListAttributesPartialState`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ListAttributes` | `values` |
| `2` | `repeated` | `ListAttributeKind` | `no_value` |

### `message ItemAttributesPartialState`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ItemAttributes` | `values` |
| `2` | `repeated` | `ItemAttributeKind` | `no_value` |

### `message AvailableSignals`
- Empty message container or extension wrapper.

## Enum Definitions
### `enum OpKind`
| Number | Identifier |
|--------|------------|
| `0` | `OP_KIND_UNKNOWN` |
| `2` | `ADD` |
| `3` | `REM` |
| `4` | `MOV` |
| `5` | `UPDATE_ITEM_ATTRIBUTES` |
| `6` | `UPDATE_LIST_ATTRIBUTES` |
| `7` | `UPDATE_ITEM_URIS` |

### `enum ListAttributeKind`
| Number | Identifier |
|--------|------------|
| `0` | `LIST_UNKNOWN` |
| `1` | `LIST_NAME` |
| `2` | `LIST_DESCRIPTION` |
| `3` | `LIST_PICTURE` |
| `4` | `LIST_COLLABORATIVE` |
| `5` | `LIST_PL3_VERSION` |
| `6` | `LIST_DELETED_BY_OWNER` |
| `10` | `LIST_CLIENT_ID` |
| `11` | `LIST_FORMAT` |
| `12` | `LIST_FORMAT_ATTRIBUTES` |
| `13` | `LIST_PICTURE_SIZE` |

### `enum ItemAttributeKind`
| Number | Identifier |
|--------|------------|
| `0` | `ITEM_UNKNOWN` |
| `1` | `ITEM_ADDED_BY` |
| `2` | `ITEM_TIMESTAMP` |
| `9` | `ITEM_SEEN_AT` |
| `10` | `ITEM_PUBLIC` |
| `11` | `ITEM_FORMAT_ATTRIBUTES` |
| `12` | `ITEM_ID` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.playlist.v2;

option optimize_for = CODE_SIZE;

import "spotify/playlist/rootlist.proto";

// Response from:
//   GET /playlist/v2/playlist/{playlistId}
//   GET /playlist/v2/playlist/{playlistId}/diff?revision=...&handlesContent=
//
// Reverse-engineered from Playlist4ApiProto.java (decompiled APK).

message PlaylistResponse {
  bytes revision = 1;
  int32 length = 2;
  ListAttributes attributes = 3;
  // field 4 unused
  ListItems contents = 5;
  Diff diff = 6;
  Diff sync_result = 7;
  repeated bytes resulting_revisions = 8;
  bool multiple_heads = 9;
  bool up_to_date = 10;
  repeated int64 nonces = 14;
  int64 timestamp = 15;
  string owner_username = 16;
  bool abuse_reporting_enabled = 17;
  Capabilities capabilities = 18;
  repeated GeoblockBlockingType geoblock = 19;
  bool changes_require_resync = 20;
  int64 created_at = 21;
}

// ─── Diff ────────────────────────────────────────────────────────────
// Confirmed from Playlist4ApiProto$Diff (decompiled):
//   FROM_REVISION_FIELD_NUMBER = 1
//   OPS_FIELD_NUMBER = 2
//   TO_REVISION_FIELD_NUMBER = 3
//   AVAILABLE_SIGNALS_FIELD_NUMBER = 4

message Diff {
  bytes from_revision = 1;
  repeated Op ops = 2;
  bytes to_revision = 3;
  AvailableSignals available_signals = 4;
}

// ─── Op ──────────────────────────────────────────────────────────────
// Confirmed from Playlist4ApiProto$Op (decompiled):
//   KIND_FIELD_NUMBER = 1
//   ADD_FIELD_NUMBER = 2
//   REM_FIELD_NUMBER = 3
//   MOV_FIELD_NUMBER = 4
//   UPDATE_ITEM_ATTRIBUTES_FIELD_NUMBER = 5
//   UPDATE_LIST_ATTRIBUTES_FIELD_NUMBER = 6
//   UPDATE_ITEM_URIS_FIELD_NUMBER = 7

message Op {
  OpKind kind = 1;
  Add add = 2;
  Rem rem = 3;
  Mov mov = 4;
  UpdateItemAttributes update_item_attributes = 5;
  UpdateListAttributes update_list_attributes = 6;
  UpdateItemUris update_item_uris = 7;
}

// Confirmed from Playlist4ApiProto$Op$Kind (decompiled).
enum OpKind {
  OP_KIND_UNKNOWN = 0;
  // 1 unused
  ADD = 2;
  REM = 3;
  MOV = 4;
  UPDATE_ITEM_ATTRIBUTES = 5;
  UPDATE_LIST_ATTRIBUTES = 6;
  UPDATE_ITEM_URIS = 7;
}

// ─── Op payloads ─────────────────────────────────────────────────────
// Confirmed from Playlist4ApiProto$Add (decompiled):
//   FROM_INDEX_FIELD_NUMBER = 1
//   ITEMS_FIELD_NUMBER = 2
//   ADD_LAST_FIELD_NUMBER = 4
//   ADD_FIRST_FIELD_NUMBER = 5
//   ADD_BEFORE_ITEM_FIELD_NUMBER = 6
//   ADD_AFTER_ITEM_FIELD_NUMBER = 7

message Add {
  int32 from_index = 1;
  repeated Item items = 2;
  // field 3 unused
  bool add_last = 4;
  bool add_first = 5;
  Item add_before_item = 6;
  Item add_after_item = 7;
}

// Confirmed from Playlist4ApiProto$Rem (decompiled):
//   FROM_INDEX_FIELD_NUMBER = 1
//   LENGTH_FIELD_NUMBER = 2
//   ITEMS_FIELD_NUMBER = 3
//   ITEMS_AS_KEY_FIELD_NUMBER = 7

message Rem {
  int32 from_index = 1;
  int32 length = 2;
  repeated Item items = 3;
  // fields 4-6 unused
  bool items_as_key = 7;
}

// Confirmed from Playlist4ApiProto$Mov (decompiled):
//   FROM_INDEX_FIELD_NUMBER = 1
//   LENGTH_FIELD_NUMBER = 2
//   TO_INDEX_FIELD_NUMBER = 3
//   ITEMS_FIELD_NUMBER = 4
//   ADD_BEFORE_ITEM_FIELD_NUMBER = 5
//   ADD_AFTER_ITEM_FIELD_NUMBER = 6
//   ADD_FIRST_FIELD_NUMBER = 7
//   ADD_LAST_FIELD_NUMBER = 8

message Mov {
  int32 from_index = 1;
  int32 length = 2;
  int32 to_index = 3;
  repeated Item items = 4;
  Item add_before_item = 5;
  Item add_after_item = 6;
  bool add_first = 7;
  bool add_last = 8;
}

// Confirmed from Playlist4ApiProto$UpdateListAttributes (decompiled):
//   NEW_ATTRIBUTES_FIELD_NUMBER = 1
//   OLD_ATTRIBUTES_FIELD_NUMBER = 2

message UpdateListAttributes {
  ListAttributesPartialState new_attributes = 1;
  ListAttributesPartialState old_attributes = 2;
}

// Confirmed from Playlist4ApiProto$UpdateItemAttributes (decompiled):
//   INDEX_FIELD_NUMBER = 1
//   NEW_ATTRIBUTES_FIELD_NUMBER = 2
//   OLD_ATTRIBUTES_FIELD_NUMBER = 3
//   ITEM_FIELD_NUMBER = 4
message UpdateItemAttributes {
  int32 index = 1;
  ItemAttributesPartialState new_attributes = 2;
  ItemAttributesPartialState old_attributes = 3;
  Item item = 4;
}

// Confirmed from Playlist4ApiProto$UpdateItemUris (decompiled):
//   URI_REPLACEMENTS_FIELD_NUMBER = 1
message UpdateItemUris {
  repeated UriReplacement uri_replacements = 1;
}

// Confirmed from Playlist4ApiProto$UriReplacement (decompiled):
//   INDEX_FIELD_NUMBER = 1
//   ITEM_FIELD_NUMBER = 2
//   NEW_URI_FIELD_NUMBER = 3
message UriReplacement {
  int32 index = 1;
  Item item = 2;
  string new_uri = 3;
}

// ─── Partial state wrappers ──────────────────────────────────────────
// Confirmed from Playlist4ApiProto$ListAttributesPartialState:
//   VALUES_FIELD_NUMBER = 1
//   NO_VALUE_FIELD_NUMBER = 2

message ListAttributesPartialState {
  ListAttributes values = 1;
  repeated ListAttributeKind no_value = 2;
}

message ItemAttributesPartialState {
  ItemAttributes values = 1;
  repeated ItemAttributeKind no_value = 2;
}

// ─── Attribute kind enums ────────────────────────────────────────────

enum ListAttributeKind {
  LIST_UNKNOWN = 0;
  LIST_NAME = 1;
  LIST_DESCRIPTION = 2;
  LIST_PICTURE = 3;
  LIST_COLLABORATIVE = 4;
  LIST_PL3_VERSION = 5;
  LIST_DELETED_BY_OWNER = 6;
  LIST_CLIENT_ID = 10;
  LIST_FORMAT = 11;
  LIST_FORMAT_ATTRIBUTES = 12;
  LIST_PICTURE_SIZE = 13;
}

enum ItemAttributeKind {
  ITEM_UNKNOWN = 0;
  ITEM_ADDED_BY = 1;
  ITEM_TIMESTAMP = 2;
  ITEM_SEEN_AT = 9;
  ITEM_PUBLIC = 10;
  ITEM_FORMAT_ATTRIBUTES = 11;
  ITEM_ID = 12;
}

// ─── AvailableSignals ────────────────────────────────────────────────

message AvailableSignals {
  // TODO: reverse-engineer when needed
}
```
