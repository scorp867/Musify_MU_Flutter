# C++ Audio Engine Seek Latency & TTFA Refactoring Plan (`cpp-audio-seek-ttfa-refactor.md`)

## Objective
Eliminate seek latency and minimize Time-To-First-Audio (TTFA) across the C++ native audio pipeline (`android/app/src/main/cpp/`) by replacing full-track memory-only buffering, synchronous waterfalls, JNI/Kotlin DRM bridges, and lock-free race conditions with a deterministic, strictly demand-driven two-tier (RAM + Disk) block-streaming architecture, pure-C++ NDK `AMediaDrm` + `libcurl` Widevine stack, epoch-safe SPSC ring buffer, and persistent Oboe hardware stream reuse.

---

## Layer 1: Streaming Network Pool, Progressive Sub-Block Read & Two-Tier (RAM + Disk) Block Cache
- [x] **Task 1.1 (`DiskCache.h` / `DiskCache.cpp`)**:
  - Add a process-wide `DiskCache::defaultInstance()` accessor synchronized with `AuthSessionStore`'s `cache_dir` so all C++ components share a single unified disk cache instance.
  - Extend `DiskCache` with a dedicated stream block storage tier (`<cache_dir>/streams/`) alongside the existing `heads/` tier, with a separate LRU budget (`kDefaultMaxStreamBytes = 256 MiB`).
  - Implement stream metadata persistence (`readStreamTotalSize(stream_key)` / `writeStreamTotalSize(stream_key, total_size)`) and atomic 64 KiB block read/write (`readStreamBlock(stream_key, block_index, expected_max_size)` / `writeStreamBlock(stream_key, block_index, data, len)`) using write-to-temp-and-rename and periodic mtime-based LRU eviction.
- [x] **Task 1.2 (`NativeHttpClient.h` / `NativeHttpClient.cpp` & `CMakeLists.txt`)**:
  - Enable `CURL_LOCK_DATA_CONNECT` in `CurlEnvironment`'s `CURLSH*` share handle (with a dedicated mutex array large enough for all `curl_lock_data` constants) so pooled `CURL*` handles share TCP/TLS connections across on-demand extractor reads.
  - Add `NativeHttpClient::hasActiveNetworkRoute()` using an in-kernel UDP (`SOCK_DGRAM | SOCK_CLOEXEC`) FIB routing table lookup (IPv4 + IPv6) that detects offline state in ~3 microseconds with zero network I/O, preventing any `libcurl` or DNS calls when the device has no internet connection.
  - Force `HAVE_EVENTFD=0` and `HAVE_SYS_EVENTFD_H=0` in `CMakeLists.txt` so `libcurl 8.11.1`'s threaded DNS resolver uses `Curl_pipe()` (two distinct file descriptors) instead of `Curl_eventfd()`, eliminating the upstream `asyn-thread.c` double-close `fdsan` abort.
  - Add `streamByteRange()` to `NativeHttpClient` that parses `Content-Range` / `Content-Length` headers as soon as response headers arrive and streams incoming body chunks immediately via a `RangeChunkCallback` while also supporting custom cancellation predicates (`std::function<bool()>`).
- [x] **Task 1.3 (`HttpRangeStreamCache.h` / `HttpRangeStreamCache.cpp` & `DataSource.h` / `DataSource.cpp`)**:
  - Change block geometry to `kBlockSize = 64 * 1024` (64 KiB) and `kPinnedHeaderBlocks = 4` (256 KiB pinned MP4 `ftyp`/`moov`/`sidx` header), eliminating speculative background prefetching so blocks are fetched strictly on demand when requested by `NativeDecoder`.
  - Integrate `DiskCache` lookup and write-through in `HttpRangeStreamCache` keyed by the 40-char hex `fileId` extracted from the CDN URL (or deterministic FNV-1a URL path hash when no `fileId` is present):
    - On `open()`, if `DiskCache` already has total stream size and Block 0 on disk, open in `< 1 ms` with zero network RTT!
    - On `readAt()` / `readFromBlock()`, check RAM `blocks_` -> check `DiskCache` -> stream on demand from network (only if `hasActiveNetworkRoute()` is true) and persist completed blocks to `DiskCache`.
  - Implement progressive sub-block streaming inside `InFlightBlock`:
    - Store a mutable `buffer` and `filled_bytes` inside `InFlightBlock` protected by `mu_`.
    - As `NativeHttpClient::streamByteRange` receives socket chunks (4-16 KiB), append directly into the `InFlightBlock` buffer and notify `block_cv_`.
    - In `readAt(offset, buffer, size)`, wake up as soon as `in_block_offset + to_copy <= flight->filled_bytes` (or `flight->done`), copying the requested slice to `AMediaExtractor` immediately without waiting for the rest of the 64 KiB block to finish downloading.
  - Add a monotonic `seek_epoch_` atomic counter and `onSeek()` method on `HttpRangeStreamCache` (and `IAudioDataSource::onSeek()`) that increments `seek_epoch_` and aborts any stale in-flight transfer from an older seek epoch.

---

## Layer 2: Deterministic SPSC RingBuffer, Epoch-Safe Seek & Event-Driven Decoder/Monitor Synchronization
- [x] **Task 2.1 (`RingBuffer.h`)**:
  - Remove the synchronous 4 MiB `std::memset(mData, 0, sizeof(mData))` from `RingBuffer::reset()` so cursor resets execute in O(1) time without stalling the calling thread or thrashing L1/L2 caches.
  - Add an atomic generation/epoch token (`std::atomic<uint64_t> mEpoch`) and epoch-aware `reset()` / `writeForEpoch()` so stale pre-seek PCM frames from a decoder iteration started before a seek can never be committed to the ring buffer.
- [x] **Task 2.2 (`NativeDecoder.h` / `NativeDecoder.cpp`)**:
  - Replace the 1ms/5ms polling sleeps in `NativeDecoder::threadFunc()` and `drainOutputBuffer()` with a condition variable (`mWakeCv` / `mWakeMutex`) signaled on `requestSeek()`, `stop()`, and ring buffer consumption.
  - Make `NativeDecoder` own the authoritative post-flush `mRingBuffer.reset()` inside `executeSeek()` immediately after `AMediaCodec_flush(mCodec)`, and notify a decoder-progress callback so `AudioEngine::decoderMonitorFunc` wakes immediately when the prebuffer watermark is reached.
- [x] **Task 2.3 (`AudioEngine.h` / `AudioEngine.cpp`)**:
  - Add condition variable notification (`mMonitorCv` / `mMonitorMutex`) so `decoderMonitorFunc()` wakes immediately when `NativeDecoder` commits frames past the watermark or when state changes, rather than polling solely on sleep intervals.
  - Refactor `AudioEngine::seekMs()` to increment the seek epoch, invoke `onSeek()` on active data sources, and coordinate cleanly with `NativeDecoder::requestSeek()`.
  - Fix dual-source pre-handoff and post-handoff seek coordination using `mSeekGeneration` and `mPendingSeekOverrideMs` so rapid user seeks while `secondaryWorkerFunc` is still opening the MP4 stream never lose the latest seek target or race with `mPrimarySeekInvalidated`.

---

## Layer 3: Progressive Head Streaming & 100% Pure-C++ Widevine DRM (`AMediaDrm` + `libcurl`)
- [x] **Task 3.1 (`DataSource.h` / `DataSource.cpp` & `HeadFileManager.h` / `HeadFileManager.cpp`)**:
  - Fix `ProgressiveFileDataSource::getSize()` to return `-1` (unknown/streaming size) while the `.part` file is still actively downloading, only returning the exact byte length once the completed `.ogg` file is atomically renamed into place. This prevents Android's `OggExtractor` from seeking to `size - 65536` (EOF) during `open()` and blocking TTFA until all 128 KiB are downloaded.
  - Add condition-variable notification from `HeadFileManager`'s download worker (`waitForHeadBytes(file_id_hex, required_bytes, timeout_ms)`) so `ProgressiveFileDataSource::open()` and `readAt()` wake the instant new bytes hit the `.part` file instead of sleeping in 2ms polling loops.
- [x] **Task 3.2 (`WidevineLicenseClient.h` / `WidevineLicenseClient.cpp`, `AudioEngine.cpp`, `MainActivity.kt`)**:
  - Completely eliminate Kotlin `MusifyDrmManager.kt`, `NativeDrmBridge`, and `JniHelper.h`.
  - Implement the entire Widevine DRM session lifecycle (`AMediaDrm_createByUUID`, `AMediaDrm_openSession`, `AMediaDrm_getKeyRequest`, `AMediaDrm_provideKeyResponse`, `AMediaDrm_getProvisionRequest`, `AMediaDrm_provideProvisionResponse`, `AMediaDrm_queryKeyStatus`, and a 6-session LRU pool) directly in C++ inside `WidevineLicenseClient` using `<media/NdkMediaDrm.h>` (`libmediandk.so`) and `NativeHttpClient` (`libcurl` + `mbedTLS`).
  - Keep Widevine DRM sessions active across track transitions: `WidevineLicenseClient`'s 6-session LRU cache retains active hardware CDM sessions across track switches and replays (only closing on LRU eviction or engine destruction).
- [x] **Task 3.3 (`FileStreamerImpl.cpp` & `AudioEngine.cpp`)**:
  - In `FileStreamerImpl::resolveFullTrackStream()`, overlap `storage_resolve_.resolveAudioFile(...)` with `license_client_.resolveLicenseContext()` in parallel when the candidate format is encrypted MP4.
  - In `AudioEngine::secondaryWorkerFunc()` and `AudioEngine::loadEncryptedStream()`, derive the 20-byte `fileId` from the CDN URL upfront to construct the Widevine PSSH box and run `acquireWidevineCrypto()` in parallel (`std::async`) with `HttpMediaDataSource::open()`, cutting cold encrypted stream startup latency in half.

---

## Layer 4: Persistent Oboe Hardware Stream Across Track Transitions
- [x] **Task 4.1 (`AudioEngine.h` / `AudioEngine.cpp` & `CoreAudioTrackPlayer.cpp`)**:
  - Track `mStreamSampleRate` in `AudioEngine` and modify `stopPlayback()` to pause (`requestPause()`) and flush (`requestFlush()`) `mStream` instead of closing and destroying it on every track switch.
  - In `openOboeStream()`, reuse the existing `mStream` when it is open/healthy and `mStreamSampleRate == mSampleRate`, only closing and recreating the hardware stream when the sample rate changes, the audio route disconnects, or `~AudioEngine()` runs (`closeOboeStream()`).
  - In `AudioEngine::onAudioReady()`, when EOS is reached and `mRingBuffer` drains, transition `mState` to `EngineState::Stopped` and output digital silence (`Continue`) while notifying `mMonitorCv`, avoiding `DataCallbackResult::Stop` stream state transitions that require stream teardown/reopen.
  - Remove the redundant `engine_->stop()` call in `CoreAudioTrackPlayer::startRemoteTrack()` prior to spawning the stream worker since `loadTrackWithHead` / `loadEncryptedStream` / `loadLocal` already reset playback state cleanly.

---

## Verification
- [x] **Task 5.1**: Compile the Android native C++ and Kotlin targets via Gradle (`./gradlew :app:externalNativeBuildDebug` and `:app:compileDebugKotlin`) and verify zero build errors.
