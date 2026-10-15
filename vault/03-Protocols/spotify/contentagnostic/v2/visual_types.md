---
title: "visual_types.proto"
path: "protos/spotify/contentagnostic/v2/visual_types.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.contentagnostic.v2"
messages: 12
---

# visual_types.proto

> Source Schema: `[protos/spotify/contentagnostic/v2/visual_types.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/contentagnostic/v2/visual_types.proto)`
> Syntax: `proto3` | Package: `spotify.contentagnostic.v2`

## Schema Overview
`visual_types.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/visual_types.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/visual_types.pb.dart)`
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/visual_types.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/visual_types.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/visual_types.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/visual_types.pbjson.dart)`

## Message Definitions
### `message Image`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `ImageInstance` | `instances` |
| `2` | `optional` | `ColorSetContrastOptions` | `extracted_color_set` |
| `3` | `optional` | `Mask` | `mask` |

### `message ImageInstance`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `FlatFile` | `flat_file` |
| `2` | `optional` | `ImageSize` | `size` |

### `message FlatFile`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `cdn_url` |

### `message Video`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `VideoAsset` | `asset` |
| `2` | `optional` | `Image` | `fallback_image` |
| `3` | `optional` | `Audio` | `fallback_audio` |
| `4` | `optional` | `Transcript` | `transcript` |

### `message VideoAsset`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `FlatFile` | `flat_file` |
| `2` | `optional` | `HLSVideo` | `hls` |

### `message HLSVideo`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `manifest_id` |

### `message Audio`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `2` | `optional` | `Transcript` | `transcript` |
| `3` | `optional` | `AudioAsset` | `asset` |

### `message AudioAsset`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `FlatFile` | `flat_file` |

### `message Transcript`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `FlatFile` | `flat_file` |

### `message ColorSetContrastOptions`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `ColorSet` | `min_contrast` |
| `2` | `optional` | `ColorSet` | `high_contrast` |
| `3` | `optional` | `ColorSet` | `higher_contrast` |
| `4` | `optional` | `RgbaColor` | `encore_base_set_text_color` |

### `message ColorSet`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `RgbaColor` | `background_base` |
| `2` | `optional` | `RgbaColor` | `background_tinted_base` |
| `3` | `optional` | `RgbaColor` | `text_base` |
| `4` | `optional` | `RgbaColor` | `text_subdued` |
| `5` | `optional` | `RgbaColor` | `text_bright_accent` |

### `message RgbaColor`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `r` |
| `2` | `optional` | `int32` | `g` |
| `3` | `optional` | `int32` | `b` |
| `4` | `optional` | `int32` | `a` |

## Enum Definitions
### `enum Mask`
| Number | Identifier |
|--------|------------|
| `0` | `MASK_UNSPECIFIED` |
| `1` | `MASK_CIRCULAR` |

### `enum ImageSize`
| Number | Identifier |
|--------|------------|
| `0` | `IMAGE_SIZE_UNSPECIFIED` |
| `1` | `IMAGE_SIZE_SMALL` |
| `2` | `IMAGE_SIZE_DEFAULT` |
| `3` | `IMAGE_SIZE_LARGE` |
| `4` | `IMAGE_SIZE_XLARGE` |
| `5` | `IMAGE_SIZE_XXLARGE` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.contentagnostic.v2;

option optimize_for = CODE_SIZE;

// =========================================================================
// Shared visual types used across traits
// Exactly matches com.spotify.contentagnostic.v2 in Spotify APK
// =========================================================================

enum Mask {
  MASK_UNSPECIFIED = 0;
  MASK_CIRCULAR = 1;
}

enum ImageSize {
  IMAGE_SIZE_UNSPECIFIED = 0;
  IMAGE_SIZE_SMALL = 1;
  IMAGE_SIZE_DEFAULT = 2;
  IMAGE_SIZE_LARGE = 3;
  IMAGE_SIZE_XLARGE = 4;
  IMAGE_SIZE_XXLARGE = 5;
}

message Image {
  repeated ImageInstance instances = 1;
  ColorSetContrastOptions extracted_color_set = 2;
  Mask mask = 3;
}

message ImageInstance {
  FlatFile flat_file = 1;
  ImageSize size = 2;
}

message FlatFile {
  string cdn_url = 1;
}

message Video {
  VideoAsset asset = 1;
  Image fallback_image = 2;
  Audio fallback_audio = 3;
  Transcript transcript = 4;
}

message VideoAsset {
  oneof video_type {
    FlatFile flat_file = 1;
    HLSVideo hls = 2;
  }
}

message HLSVideo {
  string manifest_id = 1;
}

message Audio {
  Transcript transcript = 2;
  AudioAsset asset = 3;
}

message AudioAsset {
  oneof audio_type {
    FlatFile flat_file = 1;
  }
}

message Transcript {
  FlatFile flat_file = 1;
}

// =========================================================================
// Color system
// =========================================================================

message ColorSetContrastOptions {
  ColorSet min_contrast = 1;
  ColorSet high_contrast = 2;
  ColorSet higher_contrast = 3;
  RgbaColor encore_base_set_text_color = 4;
}

message ColorSet {
  RgbaColor background_base = 1;
  RgbaColor background_tinted_base = 2;
  RgbaColor text_base = 3;
  RgbaColor text_subdued = 4;
  RgbaColor text_bright_accent = 5;
}

message RgbaColor {
  int32 r = 1;
  int32 g = 2;
  int32 b = 3;
  int32 a = 4;
}
```
