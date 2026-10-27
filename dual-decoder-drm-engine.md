# Dual-Decoder & Widevine MediaDrm Engine Specification

## Goal
Implement a production-grade dual-decoder pipeline and native Android MediaDrm subsystem in Musify_MU's audio engine:
- **Instant TTFA (< 50ms)**: Decode clear OGG Vorbis/Opus preview immediately into the SPSC RingBuffer.
- **Dynamic Handoff (Option C)**: Natural stream EOF by default, or parameterized `handoffPositionMs` override.
- **Background DRM & MediaCrypto**: Native Android MediaDrm (Widevine UUID `edef8ba9-79d6-4ace-a3c8-27dcd51d21ed`) acquires streaming license keys in the background via HTTP POST with automatic 3x exponential backoff retries.
- **Seamless PCM Transition**: Equal-power micro-crossfade between trailing OGG frames and leading AAC frames inside `RingBuffer`.
- **Fault Boundary Safety**: If license acquisition fails repeatedly, gracefully pause at the handoff boundary and emit a typed error.

---

## Tasks

- [x] Task 1: Create `android/app/src/main/kotlin/um/musify/mu/musify_mu/MusifyDrmManager.kt` with Widevine MediaDrm session handling, key request generation, and HTTP POST with 3x exponential backoff retry.
- [x] Task 2: Update `android/app/src/main/kotlin/um/musify/mu/musify_mu/MainActivity.kt` to expose `MusifyDrmManager` method channels and JNI hooks.
- [x] Task 3: Update `android/app/src/main/cpp/NativeDecoder.h` and `android/app/src/main/cpp/NativeDecoder.cpp` to support `AMediaCrypto*`, secure input buffer queuing via `AMediaCodec_queueSecureInputBuffer`, and frame-bounded decoding for handoff.
- [x] Task 4: Update `android/app/src/main/cpp/DataSource.h` and `android/app/src/main/cpp/DataSource.cpp` to support remote HTTP/HTTPS CDN data sources (`HttpMediaDataSource`) alongside local files.
- [x] Task 5: Update `android/app/src/main/cpp/AudioEngine.h` and `android/app/src/main/cpp/AudioEngine.cpp` to manage `mPrimaryDecoder` and `mSecondaryDecoder`, background DRM orchestration, equal-power PCM crossfading, and boundary faulting.
- [x] Task 6: Update `android/app/src/main/cpp/ffi_bridge.cpp` to export `musify_engine_load_dual_source` and DRM session configuration hooks.
- [x] Task 7: Update `lib/core/audio/musify_ffi_bindings.dart` and `lib/core/audio/musify_native_audio_engine.dart` with Dart FFI bindings for dual-source playback.
- [x] Task 8: Update `lib/features/player/data/esperanto/native_esperanto_transport.dart` to wire up dual-source playback when track metadata contains preview OGG and CDN AAC URLs.
- [x] Task 9: Verification pass: Compile native libraries (`libmusify_audio.so`), run `flutter analyze` and tests.

---

## Done When
- [x] Dual-source engine decodes clear OGG with < 50ms TTFA.
- [x] Secondary DRM AAC source is configured via MediaCrypto in the background without blocking audio thread.
- [x] Handoff transitions smoothly with zero audible pops, clicks, or pitch shifts.
- [x] Network/license server failures retry 3 times with exponential backoff before safely pausing at boundary.
- [x] Code compiles cleanly and passes all static analysis and invariant checks.
