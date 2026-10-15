---
title: "publishing_metadata_trait.proto"
path: "protos/spotify/contentagnostic/v2/publishing_metadata_trait.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.contentagnostic.v2"
messages: 5
---

# publishing_metadata_trait.proto

> Source Schema: `[protos/spotify/contentagnostic/v2/publishing_metadata_trait.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/contentagnostic/v2/publishing_metadata_trait.proto)`
> Syntax: `proto3` | Package: `spotify.contentagnostic.v2`

## Schema Overview
`publishing_metadata_trait.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/publishing_metadata_trait.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/publishing_metadata_trait.pb.dart)`
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/publishing_metadata_trait.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/publishing_metadata_trait.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/contentagnostic/v2/publishing_metadata_trait.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/contentagnostic/v2/publishing_metadata_trait.pbjson.dart)`

## Imported Proto Dependencies
- `google/protobuf/timestamp.proto`

## Message Definitions
### `message PublishingMetadataTrait`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `TimestampOfVaryingGranularity` | `first_published_at` |
| `2` | `optional` | `google.protobuf.Timestamp` | `published_on_spotify_at` |
| `3` | `optional` | `google.protobuf.Timestamp` | `last_modified_at` |
| `4` | `repeated` | `CopyrightInformation` | `copyright_information` |

### `message TimestampOfVaryingGranularity`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `year` |
| `2` | `optional` | `YearAndMonth` | `year_and_month` |
| `3` | `optional` | `YearMonthAndDay` | `year_month_and_day` |

### `message YearAndMonth`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `year` |
| `2` | `optional` | `int32` | `month` |

### `message YearMonthAndDay`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `int32` | `year` |
| `2` | `optional` | `int32` | `month` |
| `3` | `optional` | `int32` | `day` |

### `message CopyrightInformation`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `type` |
| `2` | `optional` | `string` | `text` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";

package spotify.contentagnostic.v2;

import "google/protobuf/timestamp.proto";

option optimize_for = CODE_SIZE;

// =========================================================================
// PublishingMetadataTrait (ExtensionKind 183)
// Provides publish dates and copyright info for entities.
// Reverse-engineered from PublishingMetadataTrait.java (decompiled APK).
// =========================================================================

message PublishingMetadataTrait {
  TimestampOfVaryingGranularity first_published_at = 1;
  google.protobuf.Timestamp published_on_spotify_at = 2;
  google.protobuf.Timestamp last_modified_at = 3;
  repeated CopyrightInformation copyright_information = 4;
}

message TimestampOfVaryingGranularity {
  // oneof timestamp {
  int32 year = 1;
  YearAndMonth year_and_month = 2;
  YearMonthAndDay year_month_and_day = 3;
  // }
}

message YearAndMonth {
  int32 year = 1;
  int32 month = 2;
}

message YearMonthAndDay {
  int32 year = 1;
  int32 month = 2;
  int32 day = 3;
}

message CopyrightInformation {
  string type = 1;
  string text = 2;
}
```
