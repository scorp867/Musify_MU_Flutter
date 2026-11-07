# C++ Full Audio Pipeline & `liborbit` Native Playback Architecture

## 1. Architectural Goal

Migrate 100% of audio playback routing, metadata/file-ID resolution, Chunk 0 Ogg Vorbis head caching, CDN `storage-resolve` resolution, and Widevine DRM license acquisition into `libmusify_audio.so` matching the disassembled `liborbit-jni-spotify.so` architecture 1:1.

1. **1:1 Spotify Domain Model Purity (Dart)**:
   - `TrackV4` (`p199p/e9d1.java` / `p199p/a1a.java`) retains all 19 Spotify fields (`id`, `name`, `albumCover`, `duration`, `isExplicit`, `artists`, `albumUri`, `albumName`, `externalIds`, `contentRatings`, `alternatives`, `availabilities`, `previewId`, `discNumber`, `trackNumber`, `originalTitle`, `versionTitle`, `artistsWithRole`, `files`).
   - `PlaybackTrait` (`p199p/yjs0.java` / `p199p/aks0.java`) retains both `audio` (`UnmodifiableListView<AudioPlayback>`) and `video` (`UnmodifiableListView<VideoPlayback>`).
   - `ContextTrack` remains 100% pure with zero custom transport metadata keys injected from Dart.
   - Dart's Kodiak `DataPoolImpl` seeds raw binary extension payloads (`ExtensionKind` `10`, `12`, `212`) into C++ `TrackInfoProvider` via `musify_metadata_seed_extension`, giving C++ instant `< 30ms` Ogg Vorbis head `fileId` cache hits while preserving full C++ fallback resolution on cache misses.

2. **5-Layer `liborbit-jni-spotify.so` Native Playback Topology (C++)**:
   - **Layer 1 (`ContextPlayerImpl`)**: Manages session queue, context pages, shuffle/repeat state, track transitions, and Esperanto protobuf state serialization. Holds `std::shared_ptr<rendering::TrackPlayer>` and NEVER touches `AudioEngine*` directly.
   - **Layer 2 (`TrackPlayer` / `RoutingTrackPlayer` / `UnplayableTrackPlayer`)**: Routes playable tracks (`spotify:track:*`, `spotify:episode:*`, `spotify:local:*`, `is_local == "true"`) to `AudioTrackPlayer` and unsupported/delimiter tracks to `UnplayableTrackPlayer` (which triggers `AdvanceReason::Unplayable`).
   - **Layer 3 (`AudioTrackPlayer` / `CoreAudioTrackPlayer`)**: Subscribes to `TrackInfoProvider` for metadata/file-ID updates, handles pending tracks while metadata resolves, drives `CoreAudioTrackPlayer` with monotonic session generation cancellation, prefetches next-track head chunks via `peek_track(true)`, and binds `AudioEngine` EOS callbacks cleanly.
   - **Layer 4 (Native Services)**:
     - `AuthSessionStore`: Thread-safe credentials store (`access_token`, `client_token`, `sp_dc`, `country`, `catalogue`, `accept_language`, `cache_dir`) with `NativePort` HTTP 401 token refresh synchronization (`std::condition_variable` + generation deduplication).
     - `NativeHttpClient` + `NativeHttpBridge.kt`: JNI `HttpURLConnection` transport with Spotify WebPlayer headers, GZIP support, timeouts, and automatic single-retry on HTTP 401.
     - `DiskCache`: Thread-safe POSIX LRU disk cache (`<cache_dir>/heads/<fileIdHex>.ogg`, 64 MiB cap).
     - `TrackInfoProvider`: Thread-safe cache and `/extended-metadata/v0/extended-metadata` wire client decoding `Track` (`10`, ZigZag `sint32` durations/numbers + embedded `alternative` files), `Episode` (`12`), and `PlaybackTrait` (`212`).
     - `HeadFileManager`: Instant Chunk 0 Ogg Vorbis head file lookup (`OGG_VORBIS_320 -> 160 -> 96`) from `DiskCache` or `heads-fa-tls13.spotifycdn.com/head/<fileId>`.
     - `StorageResolveClient`: Protobuf/JSON `storage-resolve/v2/files/audio/{interactive|interactive_prefetch}/<format>/<fileId>` client with 45-minute signed CDN URL cache.
     - `WidevineLicenseClient`: `melody/v1/license_url` resolver with TTL caching and `widevine-license/v1/audio/license` fallback.
     - `FileStreamerImpl`: Orchestrates quality selection (`MP4_256 -> MP4_128` for `premium`, `MP4_128` family for `free`), head retrieval, CDN resolution, and DRM header assembly.
   - **Layer 5 (`AudioEngine`)**: Oboe low-latency renderer, dual-source sample-accurate Ogg Vorbis head -> decrypted AAC/FLAC crossfade splicer, `AMediaExtractor` / `AMediaCodec` / `AMediaDrm` / `AMediaCrypto` pipeline, and `setAutoPlay(bool)` / `stop()` controls.

---

## 2. FFI & Esperanto Boundary

### Dart -> C++ Exports (`ffi_bridge.cpp`)
- `musify_engine_create`, `musify_engine_destroy`, `musify_set_volume`, `musify_get_position_ms`, `musify_get_duration_ms`, `musify_is_playing`
- `musify_set_auth_session(access_token, client_token, sp_dc, country, catalogue, accept_language, cache_dir)`
- `musify_set_auth_refresh_port(int64_t dart_port)`
- `musify_metadata_seed_extension(int32_t extension_kind, const char* entity_uri, const uint8_t* payload, int32_t payload_len)`
- `musify_cpi_create(void* engine_handle)` -> constructs the full `PlayerRenderingSetup` (`AuthSessionStore`, `NativeHttpClient`, `DiskCache`, `TrackInfoProvider`, `HeadFileManager`, `StorageResolveClient`, `WidevineLicenseClient`, `FileStreamerImpl`, `CoreAudioTrackPlayer`, `AudioTrackPlayer`, `UnplayableTrackPlayer`, `RoutingTrackPlayer`, `ContextPlayerImpl`)
- `musify_cpi_destroy`, `musify_cpi_set_state_port`, `musify_cpi_set_queue_port`, `musify_cpi_set_error_port`, `musify_cpi_dispatch`

### Deleted Obsolete Dart Audio Files
- `lib/features/player/data/services/spotify_audio_stream_coordinator.dart`
- `lib/features/player/data/services/spotify_audio_stream_registry.dart`
- `lib/core/audio/spotify_head_resolver.dart`
- `lib/core/audio/spotify_storage_resolver.dart`
- `lib/core/audio/spotify_license_resolver.dart`
- `lib/core/audio/models/spotify_audio_file.dart`
- `lib/core/audio/models/spotify_audio_format.dart`
- `lib/core/audio/models/spotify_audio_file_mapper.dart`
- `lib/core/audio/audio_stream_metadata_keys.dart`
