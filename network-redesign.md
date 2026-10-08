# Musify_MU Network System Redesign: Production & Ultra-Low TTFL Engine

## Goal
Redesign and harden the network infrastructure of Musify_MU to solve every discovered failure point and achieve the lowest possible TTFL (Time-To-First-Listen) for music playback:
- **Ultra-Low TTFL Engine**: Pair Dio with native engines (Cronet HTTP/3 & QUIC 0-RTT on Android, NSURLSession on iOS) + Priority Scheduler (playback traffic preempts background queues).
- **Kodiak Resilience**: Stop marking cells as permanently unavailable on transport timeouts or network drops.
- **Connection Optimization**: Persistent connection pooling and HTTP keep-alive replace ephemeral socket recreation.
- **Mutex Queue**: Async 401 refresh lock halts parallel refresh storms and replays requests cleanly.
- **Metadata Unification**: Media ExtendedMetadataService is unified with Kodiak's `ExtendedMetadataClient`.
- **Concurrency Throttling**: Cap high-volume library sync bursts to max 4 concurrent calls.
- **Multi-Host Routing**: Enable Pathfinder GraphQL (`SpotifyProfileFetcher`) to use managed transport with auto-refresh.

## Tasks
- [x] Task 1: Add `dio: ^5.7.0` and `native_dio_adapter: ^1.4.0` to `pubspec.yaml` -> Verify: Dependencies resolved cleanly
- [x] Task 2: Create `lib/core/network/priority/network_priority.dart` with priority tiers (playback = 0, interactive = 1, background = 2) -> Verify: Enum defined
- [x] Task 3: Create `lib/core/network/result/network_result.dart` with typed status and `NetworkFailureReason` -> Verify: Functional result model ready
- [x] Task 4: Create `lib/core/network/client/network_client.dart` and `dio_network_client.dart` with Cronet/Cupertino native engines, mutex 401 refresh, and keep-alive -> Verify: 10 concurrent 401s execute only 1 refresh
- [x] Task 5: Upgrade `lib/core/network/spotify/transport/base_spotify_transport.dart` to use `NetworkClient` with multi-host support -> Verify: Backward compatibility maintained
- [x] Task 6: Fix Kodiak false-unavailable bug in `lib/core/kodiak/extendedmetadataimpl/metadata_subscription.dart` -> Verify: Network drops do not mark cells as unavailable
- [x] Task 7: Consolidate metadata fetchers around Kodiak's `ExtendedMetadataClient` -> Verify: Single isolate-backed pipeline handles trait queries
- [x] Task 8: Implement `lib/core/utils/concurrency_limiter.dart` and throttle `LibraryRepositoryImpl._syncPlaylistDetails` to max 4 concurrent requests -> Verify: Max 4 in-flight requests in logs
- [x] Task 9: Migrate `SpotifyProfileFetcher` to use `SpotifyTransport` with multi-host routing -> Verify: Profile fetch benefits from automatic 401 refresh
- [x] Task 10: Register new components in `lib/app/di/injection.dart` and run tests -> Verify: `flutter analyze` and `flutter test` pass 100%

## Done When
- [x] Playback requests have 0ms queue latency and use persistent/QUIC keep-alive connections
- [x] All network traffic reuses sockets (no ephemeral socket creation)
- [x] Kodiak cards seamlessly recover from network drops without blank cards
- [x] Library playlist sync is throttled and does not trigger rate limits
- [x] Zero breaking changes for existing feature repository contracts
