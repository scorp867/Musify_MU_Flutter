# Vault Playlist, App-Wide Artwork & C++ Audit Plan

**Task Slug:** `vault-artwork-perf`
**Project Type:** MOBILE (Flutter / Dart + Android Kotlin + Android NDK C++)
**Orchestration Agents:** `orchestrator`, `mobile-developer`, `performance-optimizer`, `code-archaeologist`
**Verification Scope:** `dart analyze` and `flutter test` (Android Gradle/NDK build skipped per user decision)

## Goal
Eliminate 400-song Vault playlist loading and `PrivatePlaylistDetailScreen` re-open bottlenecks via an optimized Vault SQLite v2 schema plus a lock-cleared in-memory cache, resolve app-wide artwork extraction/caching redundancies, and deliver a thorough OOP audit of `android/app/src/main/cpp/` (report only, zero C++ edits by this session).

## Success Criteria
1. **Vault Playlists & Detail Screen:**
   - Vault Drift SQLite upgraded to `schemaVersion => 2` with an idempotent v1 -> v2 migration, batched native decryption IPC / consolidated track payload, and indexed `(playlist_id, track_index)` ordering.
   - Session-scoped, lock-cleared in-memory cache (`VaultSessionCache` cleared on `VaultAuthService.clearSessionKeysFromRam`, `VaultCoordinator` lock/purge, and `VaultStorageRepository.purgeAllVaultData`) with monotonic generation guards so opening and re-opening `PrivatePlaylistDetailScreen` renders synchronously on frame 0 without stale RAM writes or redundant decryptions.
   - Zero secret key bytes in Dart RAM; plaintext cache wiped/evicted deterministically when the Vault locks.
2. **App-Wide Artwork Performance:**
   - Eliminate duplicate native extractions (`querySize` bucket normalization `256`/`720` in `LocalFileImageLoader`, 720-to-256 byte cache reuse, deduplicated `_store.getAll()` index load, cross-keyed LRU `_knownMissing`, native Kotlin `8 MiB` `LruCache` + in-flight coalescing + `downsampleArtwork` in `MainActivity.kt`), fix `ColorCache` debounced atomic persistence + `AppCacheManager` `_guest` fallback + `ColorExtractionService` in-flight dedup & mosaic tile reuse, and bound/clean up UI image widgets and color listeners across Vault, Player, Playlist, Library, Browse, and Home Feed.
   - Maintain 100% visual parity across Vault, Player, Local Music, Library, Browse, and ColorExtraction.
3. **C++ Layer OOP Audit:**
   - Complete file-by-file OOP/RAII/SOLID/Rule-of-5 violation report across `android/app/src/main/cpp/` with exact file paths, line numbers, symbols, and concrete remediation guidance (zero C++ edits made in this task).
4. **Verification:**
   - `dart analyze` passes with 0 errors across `lib/` and updated test suites.
   - `flutter test` passes all targeted existing and newly added unit, widget, integration, and migration tests.

## Tech Stack
- Flutter / Dart (`sdk: ^3.11.4`), `flutter_bloc: ^9.1.1`, `bloc_concurrency: ^0.3.0`, `drift: ^2.34.4`, `cached_network_image: ^4.0.4`, `on_audio_query: ^2.9.0`
- Native Android Kotlin (`VaultHardwareKeyStoreBridge.kt`, `MainActivity.kt`)
- Native Android C++ (`android/app/src/main/cpp/`) [Audit only]

## Task Breakdown

- [x] **Task 1: Parallel Deep Audits (Research Subagents, Model: Gemini 4 Hydrogen / inherit)**
  - **1A (Vault DB, Crypto & UI Audit):** Audited `lib/features/vault/`, `VaultHardwareKeyStoreBridge.kt`, `vault_injection.dart`, and `test/features/vault/`.
  - **1B (App-Wide Artwork Audit):** Audited `LocalFileImageLoader`, `VaultArtworkImage`, `PlayerArtworkImage`, `ColorExtractionService`, `ColorCache`, `AppCacheManager`, `local_music/`, `library/`, `browse/`, `home_feed/`, `playlist/`, `player/`, and `MainActivity.kt`.
  - **1C (C++ OOP Audit):** Audited all 39 files in `android/app/src/main/cpp/` and checked `windows/runner/` and `linux/runner/` (audit only).

- [x] **Task 2: Execute Vault v2 Schema, Batched Crypto IPC & Lock-Cleared Cache**
  - Implemented `VaultPlaylistPayloadV2Dto` / `VaultTrackPayloadV2Dto`, `VaultDatabase` `schemaVersion => 2` with idempotent `_ensureColumnExists` + `idx_vault_track_refs_playlist_order` index, Kotlin & Dart `encryptPayloadsBatch` / `decryptPayloadsBatch`, `VaultSessionCache` with generation-checked writes, lazy `v1 -> v2` repackaging on read, `VaultMediaIsolationManager.getIsolatedTrackFilesBatch`, `VaultAudioPlaybackService` batch resolution, batch UI writes in picker/portability/more-options sheets, and frame-0 cache hit + fixed `itemExtent: 62.0` on `PrivatePlaylistDetailScreen`.

- [x] **Task 3: Execute App-Wide Artwork Consolidation & Performance Fixes**
  - Implemented `LocalFileImageLoader` query-size bucketing (`256`/`720`), 720->256 cache reuse, coalesced `_ensureIndexLoaded` (preserving `_didFallbackRefresh` across fallback refresh), cross-keyed `_knownMissing` LRU, bounded `ResizeImage` width+height with `ResizeImagePolicy.fit`, and `dispose()`.
  - Updated `MainActivity.kt` with `8 MiB` `LruCache`, `artworkInFlight` coalescing, `downsampleArtwork`, `TRIM_MEMORY_RUNNING_LOW` & `onDestroy` cleanup.
  - Updated `VaultArtworkImage` & `PlayerArtworkImage` (`_maxFallbackTracks = 4`, single-pass synchronous candidate skipping, `notifyIfSyncHit`, `maxDim > 220` threshold, `AppNetworkImage` with `memCacheWidth`/`memCacheHeight`, removed dead `PlayerBackdrop`), fixed `ColorCache` debounced atomic persistence + `AppCacheManager` `_guest` fallback + `ColorExtractionService` dedup/tile reuse + `ColorExtractionService.init()` startup hook, fixed build-time side-effects/stale async guards in `PlaylistScreen`, `MiniPlayer`, `PreviewCard`, `ShowPreviewCard`, `EpisodePreviewCard`, replaced raw `Image.network`/`NetworkImage` with bounded `AppNetworkImage`/`CachedNetworkImageProvider`, and removed dead `LocalFileImageState`.

- [x] **Task 4: Final Verification & Synthesis Report (Phase X)**
  - `dart analyze` across `lib/` and all updated test suites exited with code 0 (only 10 pre-existing unrelated `prefer_if_null_operators` infos).
  - `flutter test` across Vault, Color, Local Artwork Loader, Library Cover Resolver, Player Artwork, More Options, Queue Sheet, Banner Sections, and Kodiak Reconnect suites exited with code 0 (`1,382` passed, `0` failed).

## Phase X: Verification Checklist
- [x] `dart analyze` clean across modified files (exit 0; 10 pre-existing unrelated infos)
- [x] `flutter test` targeted suites pass (`+1382`, 0 failures; two pre-existing stale playlist tests `playlist_headers_test.dart` and `playlist_playback_flow_test.dart` remain uncompilable on pre-existing model changes unrelated to this task)
- [x] Vault v1 -> v2 migration unit test passes (`vault_database_test.dart`)
- [x] Lock-cleared cache eviction on lock/purge and 400-track batching verified by unit & widget tests (`vault_storage_repository_test.dart`, `private_playlist_detail_screen_test.dart`)
- [x] Artwork deduplication & cache-hit verified by unit/widget tests (`local_file_image_loader_test.dart`, `color_extraction_service_test.dart`, `player_artwork_test.dart`, `six_fixes_regression_test.dart`)
- [x] C++ OOP violation report delivered with zero C++ edits performed by this session
