#include "AudioEngine.h"

#include <cstdlib>
#include <cstring>

// Macro for exporting C-ABI symbols visible to Dart FFI.
#define MUSIFY_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))

// ===========================================================================
// Engine lifecycle
// ===========================================================================

MUSIFY_EXPORT void* musify_engine_create() {
    auto* engine = new AudioEngine();
    return static_cast<void*>(engine);
}

MUSIFY_EXPORT void musify_engine_destroy(void* handle) {
    if (!handle) return;
    auto* engine = static_cast<AudioEngine*>(handle);
    delete engine;
}

// ===========================================================================
// Source loading
// ===========================================================================

MUSIFY_EXPORT int32_t musify_engine_load_local(void* handle, const char* path) {
    if (!handle) return static_cast<int32_t>(EngineStatus::ErrorInvalidArg);
    auto* engine = static_cast<AudioEngine*>(handle);
    return static_cast<int32_t>(engine->loadLocal(path));
}

MUSIFY_EXPORT int32_t musify_engine_load_dual_source(
        void* handle,
        const char* primaryPath,
        const char* secondaryUrl,
        const char* licenseServerUrl,
        const char* authHeader,
        int64_t handoffPositionMs) {
    if (!handle) return static_cast<int32_t>(EngineStatus::ErrorInvalidArg);
    auto* engine = static_cast<AudioEngine*>(handle);
    return static_cast<int32_t>(engine->loadDualSource(
        primaryPath,
        secondaryUrl,
        licenseServerUrl,
        authHeader,
        handoffPositionMs));
}

MUSIFY_EXPORT int32_t musify_engine_load_track_with_head(
        void* handle,
        const char* fileIdHex,
        const char* fullTrackUrl,
        const char* cacheDir,
        const char* licenseServerUrl,
        const char* authHeader) {
    if (!handle) return static_cast<int32_t>(EngineStatus::ErrorInvalidArg);
    auto* engine = static_cast<AudioEngine*>(handle);
    return static_cast<int32_t>(engine->loadTrackWithHead(fileIdHex, fullTrackUrl, cacheDir, licenseServerUrl, authHeader));
}

MUSIFY_EXPORT void musify_engine_prefetch_head(
        void* handle,
        const char* fileIdHex,
        const char* cacheDir) {
    if (!handle) return;
    auto* engine = static_cast<AudioEngine*>(handle);
    engine->prefetchHead(fileIdHex, cacheDir);
}

MUSIFY_EXPORT int32_t musify_engine_set_drm_session(
        void* handle,
        const uint8_t* sessionId,
        int32_t sessionLen) {
    if (!handle) return static_cast<int32_t>(EngineStatus::ErrorInvalidArg);
    auto* engine = static_cast<AudioEngine*>(handle);
    return static_cast<int32_t>(engine->setDrmSessionId(sessionId, sessionLen));
}

MUSIFY_EXPORT int32_t musify_engine_init_encrypted_stream(
        void* handle,
        int64_t totalSize,
        const uint8_t* key16,
        const uint8_t* iv16) {
    if (!handle) return static_cast<int32_t>(EngineStatus::ErrorInvalidArg);
    auto* engine = static_cast<AudioEngine*>(handle);
    return static_cast<int32_t>(engine->initEncryptedStream(totalSize, key16, iv16));
}

MUSIFY_EXPORT int32_t musify_engine_push_stream_chunk(
        void* handle,
        int64_t offset,
        const uint8_t* data,
        int32_t length) {
    if (!handle) return static_cast<int32_t>(EngineStatus::ErrorInvalidArg);
    auto* engine = static_cast<AudioEngine*>(handle);
    return static_cast<int32_t>(engine->pushStreamChunk(offset, data, length));
}

// ===========================================================================
// Playback control
// ===========================================================================

MUSIFY_EXPORT int32_t musify_engine_play(void* handle) {
    if (!handle) return static_cast<int32_t>(EngineStatus::ErrorInvalidArg);
    auto* engine = static_cast<AudioEngine*>(handle);
    return static_cast<int32_t>(engine->play());
}

MUSIFY_EXPORT int32_t musify_engine_pause(void* handle) {
    if (!handle) return static_cast<int32_t>(EngineStatus::ErrorInvalidArg);
    auto* engine = static_cast<AudioEngine*>(handle);
    return static_cast<int32_t>(engine->pause());
}

MUSIFY_EXPORT int32_t musify_engine_seek_ms(void* handle, int64_t positionMs) {
    if (!handle) return static_cast<int32_t>(EngineStatus::ErrorInvalidArg);
    auto* engine = static_cast<AudioEngine*>(handle);
    return static_cast<int32_t>(engine->seekMs(positionMs));
}

// ===========================================================================
// Telemetry (all isLeaf-safe: no GC interaction, no allocation)
// ===========================================================================

MUSIFY_EXPORT int64_t musify_engine_get_position_ms(void* handle) {
    if (!handle) return 0;
    auto* engine = static_cast<AudioEngine*>(handle);
    return engine->getPositionMs();
}

MUSIFY_EXPORT int64_t musify_engine_get_duration_ms(void* handle) {
    if (!handle) return 0;
    auto* engine = static_cast<AudioEngine*>(handle);
    return engine->getDurationMs();
}

MUSIFY_EXPORT int32_t musify_engine_get_state(void* handle) {
    if (!handle) return static_cast<int32_t>(EngineState::Uninitialized);
    auto* engine = static_cast<AudioEngine*>(handle);
    return engine->getState();
}

MUSIFY_EXPORT int32_t musify_engine_get_underrun_count(void* handle) {
    if (!handle) return 0;
    auto* engine = static_cast<AudioEngine*>(handle);
    return engine->getUnderrunCount();
}

MUSIFY_EXPORT int32_t musify_engine_is_dual_source(void* handle) {
    if (!handle) return 0;
    auto* engine = static_cast<AudioEngine*>(handle);
    return engine->isDualSource() ? 1 : 0;
}

MUSIFY_EXPORT int32_t musify_engine_is_handoff_completed(void* handle) {
    if (!handle) return 0;
    auto* engine = static_cast<AudioEngine*>(handle);
    return engine->isHandoffCompleted() ? 1 : 0;
}
