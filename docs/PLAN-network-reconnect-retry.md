# Implementation Plan: Viewport Network Reconnect Auto-Retry (Self-Healing)

**Task Slug:** `network-reconnect-retry`  
**Primary Agent:** `project-planner` / `mobile-developer`  
**Key Skills:** `clean-code`, `mobile-design`, `plan-writing`  
**Project Type:** MOBILE (Flutter / Android)  
**Status:** DRAFT (Awaiting User Review)  

---

## 1. Problem Statement & Root Cause

When the device loses network connectivity, items currently in the viewport fail to load their metadata or artwork images. When connectivity is restored, the visible cards remain blank or stuck on placeholder icons until the user manually scrolls them out of the viewport and back in.

### Two Root Causes Identified
1. **`CachedNetworkImage` lacks connectivity awareness:** Once an image load fails with a network exception, `CachedNetworkImage` transitions into an immutable `LoadFailed` error state. It stays there as long as the widget remains mounted. Scrolling offscreen disposes the widget; scrolling back in constructs a new `State`, which triggers a fresh download on the restored network.
2. **`DataPoolImpl` prematurely marks traits as resolved:** In `DataPoolImpl._scheduleBatch`, trait kinds are added to `_resolvedKinds` before the network call even executes. When offline, `client.fetchCellsResult` fails with `NetworkFailure`, but `_resolvedKinds` prevents `loadBatch` from ever requesting those traits again. Furthermore, `DataPool` has no listener on `NetworkMonitorService` to retry failed requests upon reconnection.

---

## 2. Proposed Architecture (Option A: Two-Tier Reactive Self-Healing)

```
                       NetworkMonitorService
                                 │
                   (NetworkStatus.restored / online)
                                 │
           ┌─────────────────────┴─────────────────────┐
           ▼                                           ▼
   [Tier 1: Data Layer]                       [Tier 2: UI / Image Layer]
      DataPoolImpl                                 AppNetworkImage
           │                                           │
 1. Don't mark _resolvedKinds                1. Tracks image load error state
    until response succeeds                  2. On reconnect: increments ValueKey
 2. Accumulate _failedRetryKeys                 to reset CachedNetworkImage
 3. On reconnect: debounces 250ms            3. Automatically re-downloads artwork
    and flushes _failedRetryKeys                for all mounted viewport cards
```

---

## 3. Detailed Component Changes

### Tier 1: Data Layer

#### [`lib/core/kodiak/dataloader/data_pool_impl.dart`](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/dataloader/data_pool_impl.dart)
1. **Deferred Resolution Recording:**
   * Remove premature `_resolvedKinds.add(...)` from `_scheduleBatch`.
   * Only record kinds in `_resolvedKinds` when traits are successfully ingested into `_store` in `_onDataSourceUpdated` or `ingestCells`.
2. **Failed Request Retention:**
   * Maintain `final Set<CellKey> _failedRetryKeys = {};`.
   * When `MetadataSubscription` reports a network failure, capture the failed keys in `_failedRetryKeys`.
3. **Connectivity-Triggered Re-dispatch:**
   * Inject `NetworkMonitorService` into `DataPoolImpl`.
   * Listen to `networkMonitor.statusStream`.
   * On `NetworkStatus.restored` or `NetworkStatus.online`:
     * If `_failedRetryKeys` is not empty, debounce by 250 ms and re-dispatch via `_subscription.request(_failedRetryKeys)`.
     * Clear `_failedRetryKeys` upon successful emission.

#### [`lib/core/kodiak/extendedmetadataimpl/metadata_subscription.dart`](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/extendedmetadataimpl/metadata_subscription.dart)
* Add callback or reporting for failed cell keys on `NetworkFailure` so `DataPool` can track them for re-dispatch without poisoning the cache with `markUnavailable`.

---

### Tier 2: Presentation & Image Layer

#### [NEW] [`lib/core/widgets/app_network_image.dart`](file:///c:/Users/Admin/Musify_MU/lib/core/widgets/app_network_image.dart)
Create a drop-in replacement for `CachedNetworkImage` that is connectivity-aware:
* Wraps `CachedNetworkImage` in a `StatefulWidget`.
* Subscribes to `NetworkMonitorService.statusStream` (via GetIt).
* Tracks `bool _hasError`.
* When an error occurs (`errorWidget` invoked), sets `_hasError = true`.
* When `NetworkMonitorService` fires `NetworkStatus.restored` or `NetworkStatus.online`:
  * If `_hasError == true`, resets `_hasError = false` and increments an internal `_retryCount`.
  * Passing `key: ValueKey('${widget.imageUrl}_$_retryCount')` forces `CachedNetworkImage` to re-fetch the image immediately while remaining mounted in the viewport.
* Supports existing options: `memCacheWidth`, `memCacheHeight`, `fit`, `placeholder`, `errorWidget`, and `borderRadius`.

#### Card Component Updates
Update cards to use `AppNetworkImage`:
* [`lib/features/home_feed/presentation/widgets/cards/square_card.dart`](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/cards/square_card.dart)
* [`lib/features/home_feed/presentation/widgets/cards/artist_circle_card.dart`](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/cards/artist_circle_card.dart)
* [`lib/features/home_feed/presentation/widgets/cards/preview_card.dart`](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/cards/preview_card.dart)
* [`lib/features/home_feed/presentation/widgets/cards/episode_preview_card.dart`](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/cards/episode_preview_card.dart)

---

## 4. Verification Plan

### Automated Tests
1. **Unit Test (`test/core/kodiak/data_pool_retry_test.dart`)**:
   * Simulate a failed `fetchCellsResult` while offline.
   * Verify that `_resolvedKinds` does not prematurely mark keys as resolved.
   * Simulate `NetworkStatus.restored` event on `NetworkMonitorService`.
   * Verify that pending cell keys are re-dispatched and ingested.
2. **Widget Test (`test/core/widgets/app_network_image_test.dart`)**:
   * Mount `AppNetworkImage` in an error state.
   * Emit `NetworkStatus.restored`.
   * Verify the widget triggers a reload cycle without being unmounted.
3. **Full Suite**:
   * Run `flutter test test/features/home_feed/kodiak_data_layer_test.dart`.
   * Run `flutter analyze`.

### Manual On-Device Verification
1. Launch app on physical device while connected to Wi-Fi.
2. Turn on Airplane mode / disconnect internet.
3. Scroll to an uncached section of the home feed (observe placeholder icons / offline red bar).
4. Turn off Airplane mode (reconnect to internet).
5. **Verify:** Within 500 ms of the green restored status / bar dismiss, all visible cards in the viewport automatically download artwork and display title metadata without any scrolling.
