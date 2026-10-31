#include "AudioEngine.h"
#include "ContextProcessor.h"
#include "ProtobufWireHelper.h"

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

MUSIFY_EXPORT int32_t musify_engine_load_encrypted(
        void* handle,
        const char* url,
        const char* licenseServerUrl,
        const char* authHeader) {
    if (!handle) return static_cast<int32_t>(EngineStatus::ErrorInvalidArg);
    auto* engine = static_cast<AudioEngine*>(handle);
    return static_cast<int32_t>(engine->loadEncryptedStream(
        url,
        licenseServerUrl,
        authHeader));
}

MUSIFY_EXPORT int32_t musify_engine_attach_secondary_stream(
        void* handle,
        const char* secondaryUrl,
        const char* licenseServerUrl,
        const char* authHeader,
        int64_t handoffPositionMs) {
    if (!handle) return static_cast<int32_t>(EngineStatus::ErrorInvalidArg);
    auto* engine = static_cast<AudioEngine*>(handle);
    return static_cast<int32_t>(engine->attachSecondaryStream(
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
        const char* authHeader,
        int64_t trackDurationMs) {
    if (!handle) return static_cast<int32_t>(EngineStatus::ErrorInvalidArg);
    auto* engine = static_cast<AudioEngine*>(handle);
    return static_cast<int32_t>(engine->loadTrackWithHead(fileIdHex, fullTrackUrl, cacheDir, licenseServerUrl, authHeader, trackDurationMs));
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

// ===========================================================================
// String memory management
// ===========================================================================

MUSIFY_EXPORT void musify_free_string(char* str) {
    if (str) {
        std::free(str);
    }
}

// ===========================================================================
// Spotify ContextProcessor & Queue Delimiter Pagination (1:1 with liborbit.so)
// ===========================================================================

MUSIFY_EXPORT void* musify_context_processor_create() {
    auto* cp = new spotify::player::ContextProcessor();
    return static_cast<void*>(cp);
}

MUSIFY_EXPORT void musify_context_processor_destroy(void* handle) {
    if (!handle) return;
    auto* cp = static_cast<spotify::player::ContextProcessor*>(handle);
    delete cp;
}

MUSIFY_EXPORT int32_t musify_context_processor_is_delimiter(const char* uri) {
    if (!uri) return 0;
    return spotify::player::ContextProcessor::is_delimiter(uri) ? 1 : 0;
}

MUSIFY_EXPORT int32_t musify_context_processor_set_context_proto(
        void* handle,
        const char* context_uri,
        const uint8_t* page_proto_bytes,
        int32_t page_proto_len,
        int32_t initial_index) {
    if (!handle) return -1;
    auto* cp = static_cast<spotify::player::ContextProcessor*>(handle);
    std::string page_url;
    std::string next_page_url;
    std::vector<spotify::player::context_view::Entry> tracks;
    if (page_proto_bytes && page_proto_len > 0) {
        spotify::player::decode_context_page(
            page_proto_bytes,
            static_cast<size_t>(page_proto_len),
            page_url,
            next_page_url,
            tracks);
    }
    cp->set_context(
        context_uri ? context_uri : "",
        page_url,
        tracks,
        next_page_url,
        initial_index);
    return 0;
}

MUSIFY_EXPORT int32_t musify_context_processor_parse_loaded_page_proto(
        void* handle,
        int32_t iteration,
        const uint8_t* page_proto_bytes,
        int32_t page_proto_len) {
    if (!handle) return -1;
    auto* cp = static_cast<spotify::player::ContextProcessor*>(handle);
    std::string page_url;
    std::string next_page_url;
    std::vector<spotify::player::context_view::Entry> tracks;
    if (page_proto_bytes && page_proto_len > 0) {
        spotify::player::decode_context_page(
            page_proto_bytes,
            static_cast<size_t>(page_proto_len),
            page_url,
            next_page_url,
            tracks);
    }
    cp->parseLoadedContextPage(
        iteration,
        page_url,
        tracks,
        next_page_url);
    return 0;
}

MUSIFY_EXPORT uint8_t* musify_context_processor_get_queue_proto(
        void* handle,
        int32_t max_next_count,
        int32_t* out_len) {
    if (!handle || !out_len) {
        if (out_len) *out_len = 0;
        return nullptr;
    }
    auto* cp = static_cast<spotify::player::ContextProcessor*>(handle);
    auto current = cp->get_current_track();
    auto next = cp->get_next_tracks(max_next_count);
    auto prev = cp->get_prev_tracks();

    const spotify::player::context_view::Entry* cur_ptr = current.has_value() ? &current.value() : nullptr;
    auto proto_bytes = spotify::player::encode_queue(cur_ptr, next, prev, cp->get_current_iteration());

    *out_len = static_cast<int32_t>(proto_bytes.size());
    if (proto_bytes.empty()) return nullptr;

    auto* buffer = static_cast<uint8_t*>(malloc(proto_bytes.size()));
    if (!buffer) {
        *out_len = 0;
        return nullptr;
    }
    std::memcpy(buffer, proto_bytes.data(), proto_bytes.size());
    return buffer;
}

MUSIFY_EXPORT void musify_free_bytes(uint8_t* bytes) {
    if (bytes) {
        free(bytes);
    }
}

MUSIFY_EXPORT int32_t musify_context_processor_skip_next(void* handle) {
    if (!handle) return 0;
    auto* cp = static_cast<spotify::player::ContextProcessor*>(handle);
    return cp->skip_next() ? 1 : 0;
}

MUSIFY_EXPORT int32_t musify_context_processor_skip_prev(void* handle) {
    if (!handle) return 0;
    auto* cp = static_cast<spotify::player::ContextProcessor*>(handle);
    return cp->skip_prev() ? 1 : 0;
}

MUSIFY_EXPORT int32_t musify_context_processor_skip_to_index(void* handle, int32_t index) {
    if (!handle) return 0;
    auto* cp = static_cast<spotify::player::ContextProcessor*>(handle);
    return cp->skip_to_index(index) ? 1 : 0;
}

MUSIFY_EXPORT int32_t musify_context_processor_skip_to_uri(void* handle, const char* uri) {
    if (!handle || !uri) return 0;
    auto* cp = static_cast<spotify::player::ContextProcessor*>(handle);
    return cp->skip_to_uri(uri) ? 1 : 0;
}

MUSIFY_EXPORT int32_t musify_context_processor_skip_to_uid(void* handle, const char* uid) {
    if (!handle || !uid) return 0;
    auto* cp = static_cast<spotify::player::ContextProcessor*>(handle);
    return cp->skip_to_uid(uid) ? 1 : 0;
}

MUSIFY_EXPORT void musify_context_processor_set_shuffling(void* handle, int32_t shuffle) {
    if (!handle) return;
    auto* cp = static_cast<spotify::player::ContextProcessor*>(handle);
    cp->set_shuffling(shuffle != 0);
}

MUSIFY_EXPORT int32_t musify_context_processor_is_shuffling(void* handle) {
    if (!handle) return 0;
    auto* cp = static_cast<spotify::player::ContextProcessor*>(handle);
    return cp->is_shuffling() ? 1 : 0;
}

MUSIFY_EXPORT int32_t musify_context_processor_needs_next_page(void* handle) {
    if (!handle) return 0;
    auto* cp = static_cast<spotify::player::ContextProcessor*>(handle);
    return cp->needs_next_page() ? 1 : 0;
}

MUSIFY_EXPORT char* musify_context_processor_get_next_page_url(void* handle) {
    if (!handle) return nullptr;
    auto* cp = static_cast<spotify::player::ContextProcessor*>(handle);
    std::string url = cp->get_next_page_url();
    return strdup(url.c_str());
}

MUSIFY_EXPORT int32_t musify_context_processor_get_current_iteration(void* handle) {
    if (!handle) return 0;
    auto* cp = static_cast<spotify::player::ContextProcessor*>(handle);
    return cp->get_current_iteration();
}

MUSIFY_EXPORT int32_t musify_context_processor_get_current_index(void* handle) {
    if (!handle) return 0;
    auto* cp = static_cast<spotify::player::ContextProcessor*>(handle);
    return cp->get_current_index();
}

