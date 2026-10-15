---
title: "scrollsita.proto"
path: "protos/spotify/scrollsita/v1/scrollsita.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.scrollsita.v1"
messages: 18
---

# scrollsita.proto

> Source Schema: `[protos/spotify/scrollsita/v1/scrollsita.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/scrollsita/v1/scrollsita.proto)`
> Syntax: `proto3` | Package: `spotify.scrollsita.v1`

## Schema Overview
`scrollsita.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/scrollsita/v1/scrollsita.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/scrollsita/v1/scrollsita.pb.dart)`
- `[lib/core/protocol/generated/spotify/scrollsita/v1/scrollsita.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/scrollsita/v1/scrollsita.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/scrollsita/v1/scrollsita.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/scrollsita/v1/scrollsita.pbjson.dart)`

## Message Definitions
### `message NpvScrollResponse`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `NpvScrollStructure` | `structure` |
| `2` | `optional` | `ResponseInfo` | `response_info` |
| `3` | `optional` | `DebugInfo` | `debug_info` |

### `message NpvScrollStructure`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `Section` | `sections` |

### `message ResponseInfo`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `response_id` |

### `message DebugInfo`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `debug_message` |

### `message DisplayCondition`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `bool` | `is_visible` |

### `message SectionInfo`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `section_id` |
| `2` | `optional` | `DisplayCondition` | `display_condition` |

### `message CreatorBio`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `creator_uri` |
| `2` | `optional` | `string` | `title` |

### `message Credits`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `entity_uri` |
| `2` | `repeated` | `string` | `contributor_uri` |

### `message Lyrics`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `entity_uri` |

### `message LiveEvents`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `string` | `concert_uri` |
| `2` | `optional` | `string` | `artist_uri` |

### `message Merch`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `entity_uri` |

### `message Heading`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `title` |
| `2` | `optional` | `string` | `format_text` |

### `message DiscoveryFeed`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `Heading` | `heading` |
| `2` | `repeated` | `string` | `items` |

### `message SongDNA`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `entity_uri` |
| `2` | `repeated` | `string` | `uris` |

### `message Polls`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `poll_id` |

### `message Comments`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `comment_id` |

### `message Chapters`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `uri` |
| `2` | `optional` | `string` | `title` |

### `message Section`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `23` | `optional` | `SectionInfo` | `section_info` |
| `1` | `optional` | `Comments` | `comments` |
| `2` | `optional` | `CreatorBio` | `creator_bio` |
| `3` | `optional` | `DiscoveryFeed` | `discovery_feed` |
| `4` | `optional` | `Credits` | `credits` |
| `5` | `optional` | `Lyrics` | `lyrics` |
| `6` | `optional` | `Merch` | `merch` |
| `11` | `optional` | `LiveEvents` | `live_events` |
| `16` | `optional` | `Chapters` | `chapters` |
| `21` | `optional` | `Polls` | `polls` |
| `27` | `optional` | `SongDNA` | `song_dna` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.scrollsita.v1;

option optimize_for = CODE_SIZE;

// =========================================================================
// Top-level response from Spotify Now Playing Scroll endpoint
// GET /scrollsita/v1/scroll/{now_playing_uri}
// =========================================================================

message NpvScrollResponse {
  NpvScrollStructure structure = 1;
  ResponseInfo response_info = 2;
  DebugInfo debug_info = 3;
}

message NpvScrollStructure {
  repeated Section sections = 1;
}

message ResponseInfo {
  string response_id = 1;
}

message DebugInfo {
  string debug_message = 1;
}

message DisplayCondition {
  bool is_visible = 1;
}

message SectionInfo {
  string section_id = 1;
  DisplayCondition display_condition = 2;
}

message CreatorBio {
  string creator_uri = 1;
  string title = 2;
}

message Credits {
  string entity_uri = 1;
  repeated string contributor_uri = 2;
}

message Lyrics {
  string entity_uri = 1;
}

message LiveEvents {
  repeated string concert_uri = 1;
  string artist_uri = 2;
}

message Merch {
  string entity_uri = 1;
}

message Heading {
  string title = 1;
  string format_text = 2;
}

message DiscoveryFeed {
  Heading heading = 1;
  repeated string items = 2;
}

message SongDNA {
  string entity_uri = 1;
  repeated string uris = 2;
}

message Polls {
  string poll_id = 1;
}

message Comments {
  string comment_id = 1;
}

message Chapters {
  string uri = 1;
  string title = 2;
}

message Section {
  SectionInfo section_info = 23;

  oneof section_type {
    Comments comments = 1;
    CreatorBio creator_bio = 2;
    DiscoveryFeed discovery_feed = 3;
    Credits credits = 4;
    Lyrics lyrics = 5;
    Merch merch = 6;
    LiveEvents live_events = 11;
    Chapters chapters = 16;
    Polls polls = 21;
    SongDNA song_dna = 27;
  }
}
```
