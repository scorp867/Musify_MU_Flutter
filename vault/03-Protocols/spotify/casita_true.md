---
title: "casita_true.proto"
path: "protos/spotify/casita_true.proto"
type: "protobuf-schema"
tags: [protocol, protobuf, spotify-wire, schema]
syntax: "proto3"
package: "spotify.casita"
messages: 29
---

# casita_true.proto

> Source Schema: `[protos/spotify/casita_true.proto](file:///c:/Users/Admin/Musify_MU/protos/spotify/casita_true.proto)`
> Syntax: `proto3` | Package: `spotify.casita`

## Schema Overview
`casita_true.proto` defines the binary wire protocol contract utilized by Spotify's internal services and decoded by Musify MU.

## Generated Dart Artifacts
The Dart protobuf compiler compiles this `.proto` schema into the following generated files:
- `[lib/core/protocol/generated/spotify/casita_true.pb.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/casita_true.pb.dart)`
- `[lib/core/protocol/generated/spotify/casita_true.pbenum.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/casita_true.pbenum.dart)`
- `[lib/core/protocol/generated/spotify/casita_true.pbjson.dart](file:///c:/Users/Admin/Musify_MU/lib/core/protocol/generated/spotify/casita_true.pbjson.dart)`

## Imported Proto Dependencies
- `google/protobuf/any.proto`

## Message Definitions
### `message CasitaResponse`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `CasitaSections` | `sections` |
| `2` | `optional` | `CasitaRepository` | `repository` |
| `3` | `optional` | `CasitaPageMeta` | `page_meta` |
| `999` | `repeated` | `CasitaMixUri` | `mix_uris` |

### `message CasitaSections`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `CasitaSection` | `sections` |

### `message CasitaSection`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `SectionIdWrapper` | `id_wrapper` |
| `2` | `optional` | `SectionBodyShortcuts` | `body_shortcuts` |
| `3` | `optional` | `SectionBodyStandard` | `body_standard` |
| `4` | `optional` | `SectionBodyPodcast` | `body_podcast` |
| `6` | `optional` | `SectionBodyMusicfeed` | `body_musicfeed` |
| `10` | `optional` | `SectionBodyRecents` | `body_recents` |

### `message SectionIdWrapper`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `id` |

### `message SectionBodyShortcuts`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `2` | `optional` | `ShortcutsItemsContainer` | `items_container` |

### `message ShortcutsItemsContainer`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `SectionItem` | `items` |

### `message SectionBodyStandard`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `SectionHeader` | `header` |
| `2` | `optional` | `StandardItemsContainer` | `items_container` |

### `message SectionHeader`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `2` | `optional` | `SectionTitleWrapper` | `title_wrapper` |
| `3` | `optional` | `SectionTemplateWrapper` | `template_wrapper` |

### `message SectionTitleWrapper`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `title` |

### `message SectionTemplateWrapper`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `template` |
| `2` | `optional` | `SectionTemplateParams` | `params` |

### `message SectionTemplateParams`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `artist_name` |

### `message StandardItemsContainer`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `repeated` | `SectionItemWrapper` | `items_wrapper` |

### `message SectionItemWrapper`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `SectionItem` | `item` |

### `message SectionItem`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `uri` |

### `message SectionBodyPodcast`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `SectionHeader` | `header` |
| `2` | `optional` | `PodcastItemsContainer` | `items_container` |

### `message PodcastItemsContainer`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `show_uri` |
| `2` | `optional` | `string` | `episode_uri` |

### `message SectionBodyMusicfeed`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `SectionHeader` | `header` |
| `2` | `optional` | `MusicfeedItemsContainer` | `items_container` |

### `message MusicfeedItemsContainer`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `playlist_uri` |

### `message SectionBodyRecents`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `SectionHeader` | `header` |

### `message CasitaRepository`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `CasitaRepositoryInner` | `inner` |

### `message CasitaRepositoryInner`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `2` | `repeated` | `CasitaRepositoryBlock` | `blocks` |

### `message CasitaRepositoryBlock`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `3` | `repeated` | `CasitaRepositoryEntry` | `entries` |

### `message CasitaRepositoryEntry`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `2` | `optional` | `string` | `uri` |
| `3` | `optional` | `google.protobuf.Any` | `trait_payload` |

### `message SimpleCardTrait`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `image_url` |
| `2` | `optional` | `string` | `title` |
| `3` | `optional` | `string` | `subtitle` |
| `6` | `optional` | `string` | `title_rendered` |

### `message ShortcutsCardTrait`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `image_url` |
| `2` | `optional` | `string` | `title` |
| `3` | `optional` | `string` | `context_uri` |

### `message PreviewCardTrait`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `title` |
| `2` | `optional` | `string` | `type_label` |
| `3` | `optional` | `string` | `creator` |
| `4` | `optional` | `string` | `description` |
| `5` | `optional` | `string` | `uri` |
| `6` | `optional` | `string` | `uri2` |
| `7` | `optional` | `string` | `uri3` |
| `8` | `optional` | `string` | `image_url` |
| `11` | `optional` | `string` | `background_color` |
| `12` | `optional` | `string` | `secondary_color` |
| `1` | `optional` | `string` | `default_text` |
| `2` | `optional` | `string` | `playing_text` |

### `message Tag`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `name` |

### `message CasitaPageMeta`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `uri` |
| `2` | `optional` | `string` | `page_id` |

### `message CasitaMixUri`
| Tag | Rule | Type | Field Name |
|-----|------|------|------------|
| `1` | `optional` | `string` | `uri` |

## Raw Protobuf Definition
```protobuf
syntax = "proto3";
package spotify.casita;
import "google/protobuf/any.proto";

message CasitaResponse {
  CasitaSections sections = 1;
  CasitaRepository repository = 2;
  CasitaPageMeta page_meta = 3;
  repeated CasitaMixUri mix_uris = 999;
}

message CasitaSections {
  repeated CasitaSection sections = 1;
}

message CasitaSection {
  SectionIdWrapper id_wrapper = 1;
  SectionBodyShortcuts body_shortcuts = 2;
  SectionBodyStandard body_standard = 3;
  SectionBodyPodcast body_podcast = 4;
  SectionBodyMusicfeed body_musicfeed = 6;
  SectionBodyRecents body_recents = 10;
}

message SectionIdWrapper {
  string id = 1;
}

message SectionBodyShortcuts {
  ShortcutsItemsContainer items_container = 2;
}

message ShortcutsItemsContainer {
  repeated SectionItem items = 1;
}

message SectionBodyStandard {
  SectionHeader header = 1;
  StandardItemsContainer items_container = 2;
}

message SectionHeader {
  SectionTitleWrapper title_wrapper = 2;
  SectionTemplateWrapper template_wrapper = 3;
}

message SectionTitleWrapper {
  string title = 1;
}

message SectionTemplateWrapper {
  string template = 1;
  SectionTemplateParams params = 2;
}

message SectionTemplateParams {
  string artist_name = 1;
}

message StandardItemsContainer {
  repeated SectionItemWrapper items_wrapper = 1;
}

message SectionItemWrapper {
  SectionItem item = 1;
}

message SectionItem {
  string uri = 1;
}

message SectionBodyPodcast {
  SectionHeader header = 1;
  PodcastItemsContainer items_container = 2;
}

message PodcastItemsContainer {
  string show_uri = 1;
  string episode_uri = 2;
}

message SectionBodyMusicfeed {
  SectionHeader header = 1;
  MusicfeedItemsContainer items_container = 2;
}

message MusicfeedItemsContainer {
  string playlist_uri = 1;
}

message SectionBodyRecents {
  SectionHeader header = 1;
}

message CasitaRepository {
  CasitaRepositoryInner inner = 1;
}

message CasitaRepositoryInner {
  repeated CasitaRepositoryBlock blocks = 2;
}

message CasitaRepositoryBlock {
  repeated CasitaRepositoryEntry entries = 3;
}

message CasitaRepositoryEntry {
  string uri = 2;
  google.protobuf.Any trait_payload = 3;
}

message SimpleCardTrait {
  string image_url = 1;
  string title = 2;
  string subtitle = 3;
  string title_rendered = 6;
}

message ShortcutsCardTrait {
  string image_url = 1;
  string title = 2;
  string context_uri = 3;
}

message PreviewCardTrait {
  string title = 1;
  string type_label = 2;
  string creator = 3;
  string description = 4;
  string uri = 5;
  string uri2 = 6;
  string uri3 = 7;
  string image_url = 8;
  string background_color = 11;
  string secondary_color = 12;

  message PlayButtonText {
    string default_text = 1;
    string playing_text = 2;
  }
  PlayButtonText button_text = 14;

  message Tag {
    string name = 1;
  }
  repeated Tag tags = 15;

  int32 track_count = 16;
}

message CasitaPageMeta {
  string uri = 1;
  string page_id = 2;
}

message CasitaMixUri {
  string uri = 1;
}
```
