# Implementation Plan: App-Wide 60/120 FPS Performance Optimization

**Task Slug:** `performance-optimization`  
**Primary Agent:** `mobile-developer`  
**Key Skills:** `mobile-design`, `clean-code`, `performance-profiling`, `brainstorming`  
**Project Type:** MOBILE (Flutter / Android)  
**Status:** DRAFT (Awaiting User Audit & Approval)  

---

## 1. Executive Summary & Overview

Across both Offline and Online modes, Musify_MU suffers from dropped animation frames and visible micro-stutters during scrolling, mode transitions, and player navigation. A comprehensive audit of the codebase revealed four root systemic causes:
1. **Unbounded Platform Channel Flooding (Offline):** `QueryArtworkWidget` calls native Android MediaStore over MethodChannels for every visible list tile without an LRU memory cache or pre-downsampled bitmap layer.
2. **Zero Memory Downsampling on Network Images (Online):** `CachedNetworkImage` across all 20+ home feed sections, carousels, and playlist views omits `memCacheWidth` and `memCacheHeight`. Full CDN resolutions (up to 1400x1400) are decoded into uncompressed 32-bit RGBA bitmaps, consuming hundreds of megabytes and triggering frequent Garbage Collection (GC) pauses.
3. **Synchronous Heavy Main-Thread Computations:** Main thread sorting/grouping in `OfflineBrowseView` during `build()`, and `wantKeepAlive => true` indefinitely pinning dozens of heavy feed sections in `HomeFeedView`.
4. **Mid-Animation Layout Invalidation:** The Online/Offline flip animation invokes `setState` mid-transition to switch the active Bloc/tab, dropping frames during path clipping.

---

## 2. Measurable Success Criteria

* **Frame Rate:** Sustained 60 FPS on standard displays and 120 FPS on high-refresh displays during rapid scrolling and page transitions in release mode.
* **Bitmap Memory Usage:** 70% to 90% reduction in image raster memory across the Home Feed and Offline screens.
* **Bridge Overhead:** Zero redundant MethodChannel queries for repeat tracks during list scrolling.
* **Main Thread Cleanliness:** Zero O(N log N) grouping or sorting operations inside Flutter `build()` methods.
* **Zero UI Regressions:** Retain 100% of existing visual design (dark theme, Spotify design language, borders, typography).

---

## 3. Detailed Audit Findings & Bottleneck Inventory

### Category A: Offline Artwork & Scrolling
| File | Line / Symbol | Bottleneck | Solution |
|------|---------------|------------|----------|
| `lib/features/local_music/presentation/screens/local_music_screen.dart` | L124 `QueryArtworkWidget` | Uncached MethodChannel queries per song item during fast scroll | Wrap with localized LRU byte cache / downsampled size provider |
| `lib/features/library/presentation/offline_library_view.dart` | L218 `QueryArtworkWidget` | Uncached platform calls per track tile | Reuse shared thumbnail cache |
| `lib/features/browse/presentation/offline_browse_view.dart` | L379, L437 `_ArtistCard`, `_AlbumCard` | Missing `size` / `quality` parameters; queries full-res artwork | Set `size: 150`, downsample to 150x150 |
| `lib/features/browse/presentation/offline_browse_view.dart` | L142-L157 `_buildBrowseGrid` | O(N log N) grouping and `.sort()` on main UI thread inside `build()` | Memoize grouping or compute in Bloc/isolate; convert to lazy builder |
| `lib/features/player/presentation/widgets/queue_track_tile.dart` | L38 `PlayerArtworkImage` | 200px query per queue tile; online tracks show no artwork | Cache thumbnails; support `item.artUri` fallback |

### Category B: Online Image Caching & Memory Pressure
| File | Line / Symbol | Bottleneck | Solution |
|------|---------------|------------|----------|
| `lib/features/home_feed/presentation/widgets/cards/square_card.dart` | L37 `CachedNetworkImage` | Decodes full CDN resolution into uncompressed bitmap (no `memCacheWidth`) | Add `memCacheWidth: 300`, `memCacheHeight: 300` |
| `lib/features/home_feed/presentation/widgets/quick_grid_section.dart` | L80 `_QuickGridTile` | 56x56 thumbnail decodes 640px+ CDN image | Add `memCacheWidth: 120`, `memCacheHeight: 120` |
| `lib/features/home_feed/presentation/widgets/cards/` (all card widgets) | All `CachedNetworkImage` usages | Full resolution decoded into memory for small cards | Standardize `memCacheWidth` based on layout size * DPR |
| `lib/features/browse/presentation/browse_view.dart` | L210 `Image.network` | No disk cache, no downsampling | Replace with `CachedNetworkImage` + `memCacheWidth: 128` |
| `lib/features/library/presentation/library_view.dart` | L441 `Image.network` | No disk cache, raw network fetch | Replace with `CachedNetworkImage` + `memCacheWidth: 128` |
| `lib/features/home_feed/presentation/home_feed_view.dart` | L131 `_KeepAliveSection` | `wantKeepAlive => true` pins all scrolled sections in RAM indefinitely | Remove unnecessary keep-alive or limit window |
| `lib/features/playlist_detail/presentation/playlist_detail_screen.dart` | L220 `_SingleArtwork`, `_MosaicArtwork` | Full resolution decoded for 220px header and 4-image mosaic | Add `memCacheWidth: 440` and `memCacheWidth: 220` per tile |

### Category C: UI Thread & Animation Synchronization
| File | Line / Symbol | Bottleneck | Solution |
|------|---------------|------------|----------|
| `lib/features/shell/presentation/main_screen.dart` | L96-L104 `_toggleMode` | `setState` triggers heavy tab rebuild mid-flip animation | Defer tab rebuild until transition completes or off-screen |
| `lib/features/shell/presentation/main_screen.dart` | L176 `MiniPlayer` | Unisolated MiniPlayer in root Stack invalidates parent layers on seek ticks | Wrap `MiniPlayer` with `RepaintBoundary` |
| `lib/core/color/color_extraction_service.dart` | L63 `PaletteGenerator` | K-means color clustering executes on UI isolate | Offload color quantization to background isolate |

---

## 4. Phased Task Breakdown

### Phase 1: Image Sizing & Memory Optimization (Online)
* **Task 1.1**: Standardize `memCacheWidth` / `memCacheHeight` across all home feed card widgets (`square_card.dart`, `preview_card.dart`, `quick_grid_section.dart`, etc.).
* **Task 1.2**: Replace un-cached `Image.network` in `browse_view.dart` and `library_view.dart` with `CachedNetworkImage` and constrained memory sizes.
* **Task 1.3**: Constrain memory cache in `playlist_detail_screen.dart` single and mosaic artwork.
* **Task 1.4**: Remove aggressive `wantKeepAlive => true` in `home_feed_view.dart` to allow offscreen sections to release bitmap textures.

### Phase 2: Offline Artwork & Computation Optimization (Offline)
* **Task 2.1**: Implement downsampling and parameter guards on `QueryArtworkWidget` in `offline_browse_view.dart` and `offline_library_view.dart`.
* **Task 2.2**: Memoize grouping and sorting in `offline_browse_view.dart` outside of `build()`, converting eager `SliverChildListDelegate` to lazy slivers.
* **Task 2.3**: Enable network `artUri` support in `PlayerArtworkImage` so online songs render artwork in the mini-player and queue.

### Phase 3: Shell & Transition Fluidity
* **Task 3.1**: Isolate `MiniPlayer` with a dedicated `RepaintBoundary` in `main_screen.dart`.
* **Task 3.2**: Synchronize `ModeTransition` so tab state flips seamlessly without interrupting the 800ms flip animation.
* **Task 3.3**: Offload `ColorExtractionService` K-means quantization to a background isolate.

---

## 5. Phase X: Verification & Quality Assurance

* [ ] `dart analyze lib test` passes with 0 issues.
* [ ] `flutter test` passes all unit and widget test suites.
* [ ] Profile memory usage before vs after (verify image cache footprint drops significantly).
* [ ] Verify 60/120 FPS scrolling on Home Feed, Offline Library, and Local Music screens.
* [ ] Verify zero visual regression in dark theme styling and album art appearance.
