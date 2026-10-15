---
title: "network_reconnect_retry_test.dart"
path: "test/core/kodiak/network_reconnect_retry_test.dart"
type: "unit-test"
tags: [test, unit-test, flutter-test, verification, kodiak, network, self-healing]
lines: 151
---

# network_reconnect_retry_test.dart

> Test File: `[test/core/kodiak/network_reconnect_retry_test.dart](file:///c:/Users/Admin/Musify_MU/test/core/kodiak/network_reconnect_retry_test.dart)`
> Target Component: `[data_pool_impl.dart](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/dataloader/data_pool_impl.dart)`

## Test Suite Overview
`network_reconnect_retry_test.dart` verifies the self-healing and reconnection recovery behavior of the Kodiak `DataPoolImpl` reactive table. It ensures that when network connectivity drops during batch metadata hydration, failed cells are preserved in retry queues and automatically re-dispatched upon `NetworkStatus.restored` without poisoning the in-memory cache with permanent unavailable flags.

## Target Components Verified
- [[04-Reference/lib/core/kodiak/dataloader/data_pool_impl|data_pool_impl.dart]] (`lib/core/kodiak/dataloader/data_pool_impl.dart`)
- [[04-Reference/lib/core/network/status/network_monitor_service|network_monitor_service.dart]] (`lib/core/network/status/network_monitor_service.dart`)

## Test Cases & Verification Scenarios

### 1. Retention of Failed Cell Keys on Network Failure
- **Scenario**: A batch load of `ImageLinkCardDataElement` is requested right before network drops.
- **Assertion**:
  - Cell keys are NOT resolved (`isKindResolved(uri, 97) == false`).
  - Transitioning status to `NetworkStatus.offline` and subsequently `NetworkStatus.restored` initiates a 250ms debounce window without throwing exceptions or corrupting cell states.

### 2. Auto-Re-dispatch on `NetworkStatus.restored`
- **Scenario**: Network restores after an outage.
- **Assertion**:
  - The failed cells awaiting retry are aggregated and re-dispatched to `ExtendedMetadataDataSourceImpl`.
  - Ingested traits clear the retry tracking map, completing end-to-end SDUI self-healing.

## Architectural Value
Guarantees resilient offline-to-online transitions: users driving through tunnels or experiencing airplane mode toggles see their feed cards populate automatically upon reconnection without needing a manual pull-to-refresh.
