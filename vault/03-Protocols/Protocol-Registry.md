---
title: "Master Protocol Registry"
type: "protocol-index"
tags: [protocol, registry, protobuf, spotify-wire]
---

# Master Protocol Registry

This registry maps all 24 Spotify internal Protobuf wire definitions used by Musify MU, detailing their field structures, package hierarchy, and compiled Dart representations.

## Protobuf Schema Directory

| Schema Name | Package | Syntax | Messages | Enums | Generated Dart Classes | Reference Note |
|-------------|---------|--------|----------|-------|------------------------|----------------|
| `resolved.proto` | `spotify.browsita.v1.resolved` | `proto3` | 18 | 0 | 6 files | [[03-Protocols/spotify/browsita/resolved|resolved.proto]] |
| `resolved.proto` | `spotify.casita.v1.resolved` | `proto3` | 74 | 0 | 6 files | [[03-Protocols/spotify/casita/resolved|resolved.proto]] |
| `casita_inferred.proto` | `spotify.casita` | `proto2` | 119 | 0 | 0 files | [[03-Protocols/spotify/casita_inferred|casita_inferred.proto]] |
| `casita_true.proto` | `spotify.casita` | `proto3` | 29 | 0 | 3 files | [[03-Protocols/spotify/casita_true|casita_true.proto]] |
| `collection_paging.proto` | `spotify.collection.v2` | `proto3` | 3 | 0 | 3 files | [[03-Protocols/spotify/collection/collection_paging|collection_paging.proto]] |
| `credits_trait.proto` | `spotify.contentagnostic.v2` | `proto3` | 4 | 0 | 3 files | [[03-Protocols/spotify/contentagnostic/v2/credits_trait|credits_trait.proto]] |
| `identity_trait.proto` | `spotify.contentagnostic.v2` | `proto3` | 3 | 0 | 3 files | [[03-Protocols/spotify/contentagnostic/v2/identity_trait|identity_trait.proto]] |
| `on_platform_reputation_trait.proto` | `spotify.contentagnostic.v2` | `proto3` | 4 | 0 | 3 files | [[03-Protocols/spotify/contentagnostic/v2/on_platform_reputation_trait|on_platform_reputation_trait.proto]] |
| `publishing_metadata_trait.proto` | `spotify.contentagnostic.v2` | `proto3` | 5 | 0 | 3 files | [[03-Protocols/spotify/contentagnostic/v2/publishing_metadata_trait|publishing_metadata_trait.proto]] |
| `visual_identity_trait.proto` | `spotify.contentagnostic.v2` | `proto3` | 1 | 0 | 3 files | [[03-Protocols/spotify/contentagnostic/v2/visual_identity_trait|visual_identity_trait.proto]] |
| `visual_types.proto` | `spotify.contentagnostic.v2` | `proto3` | 12 | 2 | 3 files | [[03-Protocols/spotify/contentagnostic/v2/visual_types|visual_types.proto]] |
| `entity_extension_data.proto` | `spotify.extendedmetadata` | `proto3` | 2 | 0 | 3 files | [[03-Protocols/spotify/entity_extension_data|entity_extension_data.proto]] |
| `extended_metadata.proto` | `spotify.extendedmetadata` | `proto3` | 8 | 1 | 3 files | [[03-Protocols/spotify/extended_metadata|extended_metadata.proto]] |
| `extension_kind.proto` | `spotify.extendedmetadata` | `proto3` | 0 | 1 | 3 files | [[03-Protocols/spotify/extension_kind|extension_kind.proto]] |
| `color_lyrics.proto` | `spotify.lyrics.v2` | `proto3` | 6 | 0 | 3 files | [[03-Protocols/spotify/lyrics/color_lyrics|color_lyrics.proto]] |
| `metadata.proto` | `spotify.metadata` | `proto2` | 8 | 2 | 3 files | [[03-Protocols/spotify/metadata|metadata.proto]] |
| `ondemand_selector.proto` | `spotify.ondemandselector` | `proto3` | 1 | 0 | 3 files | [[03-Protocols/spotify/ondemand_selector|ondemand_selector.proto]] |
| `playlist_detail.proto` | `spotify.playlist.v2` | `proto3` | 13 | 3 | 3 files | [[03-Protocols/spotify/playlist/playlist_detail|playlist_detail.proto]] |
| `recents_list.proto` | `spotify.playlist.v2` | `proto3` | 8 | 0 | 3 files | [[03-Protocols/spotify/playlist/recents_list|recents_list.proto]] |
| `rootlist.proto` | `spotify.playlist.v2` | `proto3` | 11 | 2 | 3 files | [[03-Protocols/spotify/playlist/rootlist|rootlist.proto]] |
| `scrollsita.proto` | `spotify.scrollsita.v1` | `proto3` | 18 | 0 | 3 files | [[03-Protocols/spotify/scrollsita/v1/scrollsita|scrollsita.proto]] |
| `preview_card_trait.proto` | `spotify.extendedmetadata.extensions.previewcardtrait` | `proto3` | 4 | 2 | 3 files | [[03-Protocols/spotify/traits/preview_card_trait|preview_card_trait.proto]] |
| `shortcuts_card_trait.proto` | `spotify.extendedmetadata.extensions.shortcutscardtrait` | `proto3` | 1 | 0 | 3 files | [[03-Protocols/spotify/traits/shortcuts_card_trait|shortcuts_card_trait.proto]] |
| `simple_card_trait.proto` | `spotify.extendedmetadata.extensions.simplecardtrait` | `proto3` | 3 | 1 | 3 files | [[03-Protocols/spotify/traits/simple_card_trait|simple_card_trait.proto]] |

## Protobuf Compilation Pipeline

Spotify's binary protobuf responses are retrieved over authenticated HTTP transports (`WebPlayerTransport`, `AndroidTransport`). The application uses `protoc` with the Dart protobuf plugin (`protobuf: ^6.1.0`) to generate typed representations in `lib/core/protocol/generated/spotify/`.

### Ingestion & Parser Flow
```mermaid
flowchart LR
    HTTP[Spotify HTTP Response (Gzip / Wire)] --> B[Protobuf Isolate / Parser]
    B --> C[Compiled Dart PB Classes]
    C --> D[Kodiak Trait Plugins & Casita]
    D --> E[BLoC Reactive State]
```
