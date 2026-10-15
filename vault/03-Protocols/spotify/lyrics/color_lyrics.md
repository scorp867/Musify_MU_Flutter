---
title: "color_lyrics.proto"
path: "protos/spotify/lyrics/color_lyrics.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.lyrics.v2"
messages: 6
---

# color_lyrics.proto

> Source Schema: `[protos/spotify/lyrics/color_lyrics.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/lyrics/color_lyrics.proto)`
> Syntax: `proto3` | Package: `spotify.lyrics.v2`

## Schema Overview
`color_lyrics.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart)`
- `[lib/core/protocol/generated/spotify/lyrics/color_lyrics.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/lyrics/color_lyrics.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/lyrics/color_lyrics.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/lyrics/color_lyrics.pbjson.dart)`

## Message Definitions
### `message ColorLyricsResponse`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `LyricsResponse` | `lyrics` |
| `2` | `optional` | `ColorData` | `colors` |
| `3` | `optional` | `bool` | `has_vocal_removal` |

### `message ColorData`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `background` |
| `2` | `optional` | `int32` | `text` |
| `3` | `optional` | `int32` | `highlight_text` |

### `message Syllable`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `start_time_ms` |
| `2` | `optional` | `int64` | `num_chars` |

### `message LyricsLine`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int64` | `start_time_ms` |
| `2` | `optional` | `string` | `words` |
| `3` | `repeated` | `Syllable` | `syllables` |

### `message Alternative`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `language` |
| `2` | `repeated` | `string` | `lines` |
| `3` | `optional` | `bool` | `is_rtl_language` |

### `message LyricsResponse`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `sync_type` |
| `2` | `repeated` | `LyricsLine` | `lines` |
| `3` | `optional` | `string` | `provider` |
| `4` | `optional` | `string` | `provider_lyrics_id` |
| `5` | `optional` | `string` | `provider_display_name` |
| `7` | `optional` | `string` | `sync_lyrics_uri` |
| `9` | `repeated` | `Alternative` | `alternatives` |
| `10` | `optional` | `string` | `language` |
| `11` | `optional` | `bool` | `is_rtl_language` |
| `14` | `optional` | `int32` | `cap_status` |
| `18` | `repeated` | `string` | `translation_languages` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.lyrics.v2;

option optimize_for = CODE_SIZE;

// =========================================================================
// Spotify Color Lyrics v2 response
// GET /color-lyrics/v2/track/{trackId}?vocalRemoval=false&clientLanguage=en_US&preview=false
// =========================================================================

message ColorLyricsResponse {
  LyricsResponse lyrics = 1;
  ColorData colors = 2;
  bool has_vocal_removal = 3;
}

message ColorData {
  int32 background = 1;
  int32 text = 2;
  int32 highlight_text = 3;
}

message Syllable {
  int64 start_time_ms = 1;
  int64 num_chars = 2;
}

message LyricsLine {
  int64 start_time_ms = 1;
  string words = 2;
  repeated Syllable syllables = 3;
}

message Alternative {
  string language = 1;
  repeated string lines = 2;
  bool is_rtl_language = 3;
}

message LyricsResponse {
  int32 sync_type = 1;
  repeated LyricsLine lines = 2;
  string provider = 3;
  string provider_lyrics_id = 4;
  string provider_display_name = 5;
  string sync_lyrics_uri = 7;
  repeated Alternative alternatives = 9;
  string language = 10;
  bool is_rtl_language = 11;
  int32 cap_status = 14;
  repeated string translation_languages = 18;
}
```
