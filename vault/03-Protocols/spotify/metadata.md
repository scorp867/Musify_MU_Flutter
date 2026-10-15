---
title: "metadata.proto"
path: "protos/spotify/metadata.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto2"
package: "spotify.metadata"
messages: 8
---

# metadata.proto

> Source Schema: `[protos/spotify/metadata.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/metadata.proto)`
> Syntax: `proto2` | Package: `spotify.metadata`

## Schema Overview
`metadata.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/metadata.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/metadata.pb.dart)`
- `[lib/core/protocol/generated/spotify/metadata.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/metadata.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/metadata.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/metadata.pbjson.dart)`

## Message Definitions
### `message Artist`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `bytes` | `gid` |
| `2` | `optional` | `string` | `name` |
| `3` | `optional` | `sint32` | `popularity` |
| `17` | `optional` | `ImageGroup` | `portrait_group` |

### `message Album`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `bytes` | `gid` |
| `2` | `optional` | `string` | `name` |
| `3` | `repeated` | `Artist` | `artist` |
| `4` | `optional` | `Type` | `type` |

### `message Track`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `bytes` | `gid` |
| `2` | `optional` | `string` | `name` |
| `3` | `optional` | `Album` | `album` |
| `4` | `repeated` | `Artist` | `artist` |
| `5` | `optional` | `sint32` | `number` |
| `6` | `optional` | `sint32` | `disc_number` |
| `7` | `optional` | `sint32` | `duration` |
| `8` | `optional` | `sint32` | `popularity` |
| `9` | `optional` | `bool` | `explicit` |
| `36` | `optional` | `string` | `canonical_uri` |

### `message Show`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `bytes` | `gid` |
| `2` | `optional` | `string` | `name` |
| `64` | `optional` | `string` | `description` |
| `66` | `optional` | `string` | `publisher` |
| `67` | `optional` | `string` | `language` |
| `68` | `optional` | `bool` | `explicit` |
| `69` | `optional` | `ImageGroup` | `cover_image` |
| `73` | `repeated` | `string` | `keyword` |

### `message Episode`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `bytes` | `gid` |
| `2` | `optional` | `string` | `name` |
| `7` | `optional` | `sint32` | `duration` |
| `64` | `optional` | `string` | `description` |
| `66` | `optional` | `Date` | `publish_time` |
| `68` | `optional` | `ImageGroup` | `cover_image` |
| `69` | `optional` | `string` | `language` |
| `70` | `optional` | `bool` | `explicit` |
| `71` | `optional` | `Show` | `show` |

### `message Date`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `sint32` | `year` |
| `2` | `optional` | `sint32` | `month` |
| `3` | `optional` | `sint32` | `day` |

### `message Image`
- Empty message container or extension wrapper.

### `message ImageGroup`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `Image` | `image` |

## Enum Definitions
### `enum Type`
| Number | Identifier |
|--------|------------|
| `1` | `ALBUM` |
| `2` | `SINGLE` |
| `3` | `COMPILATION` |
| `4` | `EP` |
| `5` | `AUDIOBOOK` |
| `6` | `PODCAST` |

### `enum Size`
| Number | Identifier |
|--------|------------|
| `0` | `DEFAULT` |
| `1` | `SMALL` |
| `2` | `LARGE` |
| `3` | `XLARGE` |

## Raw Protobuf Definition
```protobuf
// Spotify Metadata protobuf  -  trimmed to what we need for extended-metadata.
// Source: Spotify 1.2.52.442 (windows)

syntax = "proto2";

package spotify.metadata;

option optimize_for = CODE_SIZE;

message Artist {
    optional bytes gid = 1;
    optional string name = 2;
    optional sint32 popularity = 3;
    optional ImageGroup portrait_group = 17;
}

message Album {
    optional bytes gid = 1;
    optional string name = 2;
    repeated Artist artist = 3;

    optional Type type = 4;
    enum Type {
        ALBUM = 1;
        SINGLE = 2;
        COMPILATION = 3;
        EP = 4;
        AUDIOBOOK = 5;
        PODCAST = 6;
    }

    optional string label = 5;
    optional Date date = 6;
    optional sint32 popularity = 7;
    optional ImageGroup cover_group = 17;
    optional string type_str = 20;
}

message Track {
    optional bytes gid = 1;
    optional string name = 2;
    optional Album album = 3;
    repeated Artist artist = 4;
    optional sint32 number = 5;
    optional sint32 disc_number = 6;
    optional sint32 duration = 7;
    optional sint32 popularity = 8;
    optional bool explicit = 9;
    optional string canonical_uri = 36;
}

message Show {
    optional bytes gid = 1;
    optional string name = 2;
    optional string description = 64;
    optional string publisher = 66;
    optional string language = 67;
    optional bool explicit = 68;
    optional ImageGroup cover_image = 69;
    repeated string keyword = 73;
}

message Episode {
    optional bytes gid = 1;
    optional string name = 2;
    optional sint32 duration = 7;
    optional string description = 64;
    optional Date publish_time = 66;
    optional ImageGroup cover_image = 68;
    optional string language = 69;
    optional bool explicit = 70;
    optional Show show = 71;
}

message Date {
    optional sint32 year = 1;
    optional sint32 month = 2;
    optional sint32 day = 3;
}

message Image {
    enum Size {
        DEFAULT = 0;
        SMALL = 1;
        LARGE = 2;
        XLARGE = 3;
    }

    optional bytes file_id = 1;
    optional Size size = 2;
    optional sint32 width = 3;
    optional sint32 height = 4;
}

message ImageGroup {
    repeated Image image = 1;
}
```
