# Native C++ HTTP DataSource and Audio Timeline Synchronization Plan

## Problem Statement

Two coupled defects exist in the Android native playback pipeline (`libmusify_audio.so`):

1. **EOS / Teardown Native `SIGABRT`**:
   `HttpMediaDataSource` passes raw HTTPS URLs to `AMediaExtractor_setDataSource(mExtractor, mUrl)`, which instantiates Android's Java-backed `MediaHTTP` / `BpMediaHTTPConnection`. When playback stops or reaches end-of-stream (`AudioEngine::stopPlayback()` -> `~HttpMediaDataSource()` -> `AMediaExtractor_delete`), `NuMediaExtractor::~NuMediaExtractor` disconnects the Binder proxy from native threads without an attached JVM, aborting in `JavaBBinder::onTransact`:
   `Binder thread started or Java binder used, but env null. Attach JVM?`

2. **Duration Mismatch, Early Advance, and End-of-Track Desync**:
   - **Duration Authority Conflict**: `loadDualSource()` sets `mDurationMs` from Chunk 0's ~6.5s head duration, `secondaryWorkerFunc()` only updates `mDurationMs` upward (`if (secDurMs > mDurationMs)`), and `CoreAudioTrackPlayer::getDurationMs()` clamps to metadata hint (`if (hint_dur > eng_dur) return hint_dur`). When the actual MP4 stream is shorter or longer than Kodiak metadata, EOS fires 4-5s early or plays past UI end.
   - **Blind Client-Side Time Extrapolation**: `AudioEngine` does not push transitions (`Prebuffering` -> `Playing`, Chunk 0 EOF stall -> `Paused`, stall recovery -> `Playing`, authoritative duration updates) to `CoreAudioTrackPlayer` / `AudioTrackPlayer` / `ContextPlayerImpl`. Dart `PlayerState.position(now)` extrapolates forward at `1.0x` during stalls and buffering waits, advancing ahead of real audio hardware.
   - **Oboe EOS / Seek Handling**: `AudioEngine::onAudioReady()` returns `oboe::DataCallbackResult::Continue` after setting `EngineState::Stopped`, keeping the hardware callback active on silence; `AudioEngine::secondaryWorkerFunc()` allows `EngineState::Stopped` in `resumable`; `AudioEngine::seekMs()` relies on `AMEDIAEXTRACTOR_SEEK_CLOSEST_SYNC` instead of `SEEK_PREVIOUS_SYNC` + `mDiscardPriorToUs`, creating seek position skew and tail anomalies.

## Target Architecture Decisions

- **HTTP / TLS Stack**: Replace Android `MediaHTTP` and Kotlin `NativeHttpBridge` / `NativeHeadDownloader` with CMake `FetchContent` builds of static `mbedtls` and `libcurl` inside `libmusify_audio.so`, backed by an aligned C++ `HttpRangeStreamCache` feeding direct NDK `AMediaDataSource` (`AMediaExtractor_setDataSourceCustom`).
- **Android API Floor**: Raise `minSdk` to `28` so `AMediaDataSource` (including `AMediaDataSource_setClose`) is statically linked from `<media/NdkMediaDataSource.h>` (`libmediandk`) with zero `dlopen`/`dlsym` shims.
- **Dual-Source Preservation**: Keep Chunk 0 Ogg Vorbis (`loadTrackWithHead` + `attachSecondaryStream`) for instant startup, while unifying duration authority, Ogg-to-MP4 handoff calibration, hardware clock reporting, and event-driven phase propagation.
- **Widevine DRM Scope**: Keep `MusifyDrmManager` / `NativeDrmBridge` (`android.media.MediaDrm`) in Kotlin because NDK `AMediaDrm` lacks uniform OEM provisioning behavior; confine `JniThreadAttacher` solely to `AudioEngine::acquireWidevineCrypto()`.

---

## Implementation Plan (Dependency-Ordered)

### Step 1: Raise `minSdk = 28` and Wire Static `mbedtls` + `libcurl` in CMake
**Files**:
- `android/app/build.gradle.kts`
- `android/app/src/main/cpp/CMakeLists.txt`

**Changes**:
1. Update `android/app/build.gradle.kts` `defaultConfig.minSdk` from `flutter.minSdkVersion` to `28`.
2. In `android/app/src/main/cpp/CMakeLists.txt`, add `include(FetchContent)` with pinned releases (for example `mbedtls` `v3.6.2` and `curl` `curl-8_11_1`):
   - Configure `mbedtls` as static libraries with `ENABLE_PROGRAMS=OFF`, `ENABLE_TESTING=OFF`.
   - Configure `curl` as a static library with `BUILD_SHARED_LIBS=OFF`, `BUILD_CURL_EXE=OFF`, `CURL_USE_MBEDTLS=ON`, `CURL_ZLIB=ON`, `HTTP_ONLY=ON`, `CURL_USE_LIBPSL=OFF`, `USE_LIBIDN2=OFF`, `CURL_BROTLI=OFF`, `CURL_ZSTD=OFF`.
   - Link `libcurl` against static `mbedtls` targets and NDK `z` (`zlib`) for gzip decompression.
   - Apply `-Wno-error` strictly to the third-party C targets (`mbedtls`, `mbedcrypto`, `mbedx509`, `libcurl`) via `target_compile_options` so `musify_audio` continues compiling cleanly under `-std=c++20 -Wall -Wextra -Werror -fno-exceptions`.
   - Link `libcurl`, `mbedtls`, `mbedx509`, `mbedcrypto`, `z`, `oboe::oboe`, `log`, and `mediandk` into `musify_audio`.

**Verify**:
- `INPUT`: Clean Gradle native configure + build (`cd android && ./gradlew externalNativeBuildDebug`).
- `OUTPUT`: Static `libcurl` + `mbedtls` compile for target Android ABIs and `libmusify_audio.so` links with `-Werror` enabled on all project C++ sources.

---

### Step 2: Refactor `NativeHttpClient` to Pure C++ (`libcurl` + Android CA Trust) and Migrate Head Downloads
**Files**:
- `android/app/src/main/cpp/network/NativeHttpClient.h`
- `android/app/src/main/cpp/network/NativeHttpClient.cpp`
- `android/app/src/main/cpp/AudioEngine.cpp` (`downloadHeadFileNative`, `JNI_OnLoad`)
- `android/app/src/main/kotlin/um/musify/mu/musify_mu/NativeHttpBridge.kt` (delete)
- `android/app/src/main/kotlin/um/musify/mu/musify_mu/MainActivity.kt` (remove `NativeHeadDownloader`)
- `android/app/proguard-rules.pro`

**Changes**:
1. Replace `HttpURLConnection` JNI dispatch in `NativeHttpClient` with pure C++ `libcurl` execution backed by a thread-safe `CURLSH*` share handle (caching DNS lookups and TLS session IDs across handles) with `CURLOPT_NOSIGNAL = 1L`, HTTP/2 + HTTP/1.1 TLS negotiation, explicit connect/total timeouts, and automatic gzip acceptance.
2. Implement native Android CA trust initialization (zero JNI): scan `/apex/com.android.conscrypt/cacerts` (Android 14+ Conscrypt APEX) first and fallback to `/system/etc/security/cacerts`, assemble the PEM bundle once in memory, and attach it via `CURLOPT_CAINFO_BLOB` (`CURL_BLOB_NOCOPY`) so TLS handshakes avoid repeated directory scans.
3. Preserve full request/response and 401 token-refresh parity (`get()`, `post()`, `executeWithAuthRetry()`) for existing consumers (`TrackInfoProvider`, `StorageResolveClient`, `WidevineLicenseClient`, `ffi_bridge.cpp`).
4. Add streaming primitives needed by playback and Chunk 0 head caching:
   - `probeLength(url, headers, cancelToken)` returning `{statusCode, totalSize, supportsRanges, finalUrl}` via `HEAD` (falling back to `Range: bytes=0-0` if `HEAD` omits `Content-Length`).
   - `fetchRange(url, headers, offset, length, cancelToken, outBytes, outContentRangeTotal)` using `CURLOPT_RANGE` and `CURLOPT_XFERINFOFUNCTION` polling `cancelToken` (`std::atomic<bool>`) so active transfers abort immediately on close/seek without blocking until timeout.
5. Rewrite `AudioEngine::downloadHeadFileNative()` to download Chunk 0 via `NativeHttpClient` into a `.tmp` file and atomically `rename()`, removing `NativeHttpBridge.kt`, `NativeHeadDownloader` from `MainActivity.kt`, cached JNI HTTP class/method globals in `AudioEngine.cpp`, and `NativeHeadDownloader` rules in `android/app/proguard-rules.pro`.

**Verify**:
- `INPUT`: Play a track requiring native Kodiak metadata resolution, `/storage-resolve`, Widevine license URL lookup, and Chunk 0 head download.
- `OUTPUT`: All HTTPS calls succeed through `libcurl` + `mbedtls` with zero calls to `NativeHttpBridge` or `NativeHeadDownloader` (`rg` confirms zero remaining references).

---

### Step 3: Build `HttpRangeStreamCache` and Replace URL `HttpMediaDataSource` with Direct `AMediaDataSource`
**Files**:
- `android/app/src/main/cpp/DataSource.h`
- `android/app/src/main/cpp/DataSource.cpp`
- `android/app/src/main/cpp/AudioEngine.h`
- `android/app/src/main/cpp/AudioEngine.cpp`
- `android/app/src/main/cpp/NativeDecoder.cpp`

**Changes**:
1. Remove the `NdkMediaDataSourceApi` `dlopen`/`dlsym` loader in `DataSource.cpp` and include `<media/NdkMediaDataSource.h>` directly (`minSdk = 28`).
2. Implement `HttpRangeStreamCache` in C++:
   - Fixed aligned block granularity (256 KiB per block) with bounded LRU in-memory cache so container headers (`ftyp`, `moov`, `sidx`) and linear frames remain cached without unbounded RAM growth.
   - Single-flight in-flight deduplication per block (`mutex` + `condition_variable`) so overlapping `readAt()` calls share one HTTP range fetch.
   - Dedicated background sequential prefetch worker (1-2 blocks ahead, canceled on non-sequential seek or `cancel()`).
   - Automatic CDN failover and URL expiry recovery (using resolved backup `cdn_urls` from `StorageResolveClient` / optional re-resolve callback when a CDN returns HTTP 401/403/404/410 mid-track).
   - Clean `cancel()` lifecycle setting `std::atomic<bool> canceled{true}`, waking all waiters, and aborting any active `libcurl` transfer immediately.
3. Refactor `HttpMediaDataSource` (and `ProgressiveFileDataSource`) in `DataSource.h` / `DataSource.cpp`:
   - Attach `AMediaDataSource_setReadAt`, `AMediaDataSource_setGetSize`, and `AMediaDataSource_setClose` to a `std::shared_ptr<HttpRangeStreamCache>` (or shared state holder) cleared safely on `AMediaDataSource_delete`.
   - Call `AMediaExtractor_setDataSourceCustom(mExtractor, mCustomDataSource)` exclusively; never call `AMediaExtractor_setDataSource(mExtractor, url)`.
   - Follow Android `AMediaDataSource` contract strictly: return positive byte count on success, `0` ONLY on true EOF (`offset >= totalSize`), and `-1` on canceled/IO error.
4. Fix `AudioEngine::stopPlayback()` teardown ordering:
   - Invoke `close()` (which calls `cache->cancel()`) on active `mPrimarySource`, `mSecondarySource`, and `mDataSource` **before** joining `mSecondaryWorkerThread` and stopping `NativeDecoder` threads so blocked `AMediaExtractor` calls unwind instantaneously.
5. Remove `JniThreadAttacher` from `NativeDecoder::threadFunc()` and `CoreAudioTrackPlayer` stream workers, keeping `JniThreadAttacher` scoped exclusively inside `AudioEngine::acquireWidevineCrypto()` for Kotlin `MediaDrm`.

**Verify**:
- `INPUT`: Stream encrypted and clear tracks to EOS with no next track queued; issue rapid next/prev skips and seeks mid-fetch.
- `OUTPUT`: Zero `MediaHTTPConnection` / `JavaBBinder` logs or `SIGABRT` crashes; `stopPlayback()` completes without blocking on socket reads.

---

### Step 4: Dual-Source Splice Calibration, Sample-Accurate Seeking, and Clean EOS Lifecycle
**Files**:
- `android/app/src/main/cpp/AudioEngine.h`
- `android/app/src/main/cpp/AudioEngine.cpp`
- `android/app/src/main/cpp/NativeDecoder.h`
- `android/app/src/main/cpp/NativeDecoder.cpp`

**Changes**:
1. **Ogg-Head -> MP4-Body Timeline Calibration**:
   - In `AudioEngine::loadDualSource()`, do not overwrite `mDurationMs` with `primarySource->getDurationUs() / 1000` (which only reflects the ~6.5s Chunk 0 Ogg file). Retain metadata `trackDurationMs` until secondary MP4 attaches.
   - Verify and log the exact Container Start PTS / Priming delta when opening `secSource` (`secSource->seekTo(0, ...)` vs `handoffUs`), and compute handoff frame boundary cleanly against `mPrimaryDecoder->getDecodedFrames()` at the shared sample rate.
   - Use `SEEK_PREVIOUS_SYNC` + `setDiscardPriorToUs(handoffUs)` on secondary start AND unify `AudioEngine::seekMs()` / `NativeDecoder::executeSeek()` to use `AMEDIAEXTRACTOR_SEEK_PREVIOUS_SYNC` + `setDiscardPriorToUs(targetUs)` instead of `AMEDIAEXTRACTOR_SEEK_CLOSEST_SYNC`.
   - In `AudioEngine::seekMs()`, handle seeks while `EngineState::Stopped` cleanly (reset `mEosNotified`, reopen/restart Oboe stream if stopped, and preserve/restore intended play vs pause state) and invalidate any pending dual-source handoff if seeking past Chunk 0.
2. **Event-Driven Oboe EOS Stop & Spurious-Resume Prevention**:
   - In `AudioEngine::onAudioReady()`, when `eos && mRingBuffer.availableToRead() == 0`, fill only the remaining tail with zero, add `framesRead` to `mFramesConsumedByHardware`, transition `mState` from `Playing` -> `Stopped`, notify the EOS dispatcher condition variable immediately, and return `oboe::DataCallbackResult::Stop` so hardware DMA stops cleanly after the final drained burst instead of continuing on silence.
   - In `AudioEngine::secondaryWorkerFunc()`, remove `EngineState::Stopped` from the `resumable` auto-resume predicate (`AudioEngine.cpp:1118`) so late secondary readiness cannot restart an already finished or stopped track.

**Verify**:
- `INPUT`: Play full tracks from 0s across Chunk 0 -> Chunk 1 handoff through final EOS; also seek before handoff, seek mid-track, and seek to `duration - 3s`.
- `OUTPUT`: Audible handoff has no repeated 3-5s loop or skip; seeking lands at exact target timestamp; EOS halts Oboe cleanly on first drain and transitions once.

---

### Step 5: Authoritative Duration Hierarchy and Hardware-Clock SSOT Synchronization
**Files**:
- `android/app/src/main/cpp/AudioEngine.h`
- `android/app/src/main/cpp/AudioEngine.cpp`
- `android/app/src/main/cpp/rendering/CoreAudioTrackPlayer.h`
- `android/app/src/main/cpp/rendering/CoreAudioTrackPlayer.cpp`
- `android/app/src/main/cpp/rendering/AudioTrackPlayer.h`
- `android/app/src/main/cpp/rendering/AudioTrackPlayer.cpp`
- `android/app/src/main/cpp/player/ContextPlayerImpl.cpp`
- `lib/features/player/presentation/widgets/player_controls.dart`

**Changes**:
1. **Single Authoritative Duration Source**:
   - Track `mDurationAuthoritative` in `AudioEngine`. Chunk 0 leaves `mDurationAuthoritative = false` using `trackDurationMs` hint; once full MP4 `secSource` (or full local/single source) opens with `secDurMs > 0`, set `mDurationMs = secDurMs` unconditionally (updating both upward and downward when metadata hint differs from true encoded stream duration) and set `mDurationAuthoritative = true`.
   - Update `CoreAudioTrackPlayer::getDurationMs()` to prefer `AudioEngine`'s authoritative duration over `duration_hint_ms_`, falling back to `duration_hint_ms_` only before the full stream opens.
2. **Phase, Stall, and Duration Push Callbacks (`AudioEngine` -> `ContextPlayerImpl`)**:
   - Register state/duration callbacks from `AudioEngine` into `CoreAudioTrackPlayer` so `AudioEngine::decoderMonitorFunc()` and `onAudioReady()` push transitions (`Prebuffering` -> `Buffering`, `Playing`, `Paused` at Chunk 0 EOF stall / underrun, `Stopped`) and authoritative duration changes through `AudioTrackPlayer::emitStateChanged()` -> `ContextPlayerImpl::emit_state_locked()`.
   - Map `TrackPlayerPhase::Buffering`, `Paused`, and `Stopped` to `playback_speed = 0.0` (with `is_buffering = true` for `Buffering`) in `AudioTrackPlayer::getState()` / `ContextPlayerImpl` so Dart `PlayerState.position(now)` never extrapolates forward while audio hardware is paused or waiting on network/DRM.
3. **Latency-Compensated Position Telemetry**:
   - In `AudioEngine::getPositionMs()`, account for Oboe output pipeline latency (`getTimestamp(CLOCK_MONOTONIC)` / buffered frames) when active and clamp cleanly to `[0, mDurationMs]` when duration is known, preventing UI progress overshoot past `duration`.
   - Keep `PlayerControls` seekbar clamped to `[0, durationMs]` as a defensive presentation invariant.

**Verify**:
- `INPUT`: Throttle network / trigger Chunk 0 EOF wait; play tracks whose Kodiak metadata duration differs from encoded MP4 duration.
- `OUTPUT`: UI timer freezes (`playbackSpeed = 0.0`) during buffering stalls, updates smoothly to authoritative MP4 duration upon handoff, and reaches `duration` synchronously with audio EOS.

---

### Step 6: Full Build, Unit Checks, and Device Integration Verification
**Files**:
- No production code files modified in this step; test/build verification only.

**Verification Commands & Matrix**:
1. Static checks:
   - `flutter analyze`
   - `flutter test`
   - `cd android && ./gradlew assembleDebug`
2. Runtime checks on connected Android API 28+ device (`adb logcat -s MusifyEngine:I AudioTrackPlayer:I ContextPlayer:I NativeHttpClient:I HttpRangeCache:I AndroidRuntime:E libc:F`):
   - **Test A (No-Next-Track EOS Crash Regression)**: Play final track in queue past EOS; verify zero `JavaBinder`, `SIGABRT`, or Oboe silence callback spin.
   - **Test B (Duration Accuracy)**: Play tracks with Chunk 0 head -> MP4 body; confirm `[0..dur]` progress aligns with audio completion without 4-5s early advance or overshoot.
   - **Test C (Seek & Skip Stress)**: Rapidly seek before handoff, seek to `duration - 2s`, and skip next/prev repeatedly; verify instant HTTP range cancellation and clean position reset.
   - **Test D (Throttle / Network Stall)**: Simulate slow connection after Chunk 0; confirm UI pauses (`playbackSpeed = 0.0`) at Chunk 0 boundary and resumes seamlessly once secondary stream opens.
