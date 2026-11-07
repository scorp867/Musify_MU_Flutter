#include "AudioEngine.h"
#include "ContextProcessor.h"
#include "ProtobufWireHelper.h"
#include "cache/DiskCache.h"
#include "content_delivery/HeadFileManager.h"
#include "content_delivery/StorageResolveClient.h"
#include "drm/WidevineLicenseClient.h"
#include "metadata/TrackInfoProvider.h"
#include "network/AuthSessionStore.h"
#include "network/NativeHttpClient.h"
#include "player/ContextPlayerImpl.h"
#include "rendering/AudioTrackPlayer.h"
#include "rendering/CoreAudioTrackPlayer.h"
#include "rendering/RoutingTrackPlayer.h"
#include "rendering/UnplayableTrackPlayer.h"
#include "streamer/FileStreamerImpl.h"

#include "dart_api_dl.h"

#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#define MUSIFY_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))

namespace {

/// Process-wide singleton holding native liborbit Layer 4 playback services so Kodiak
/// metadata seeding and auth session updates work deterministically at any lifecycle point.
struct NativePlaybackServices {
    spotify::network::AuthSessionStore& auth_store;
    spotify::network::NativeHttpClient http_client;
    spotify::cache::DiskCache disk_cache;
    spotify::metadata::TrackInfoProvider track_info_provider;
    spotify::content_delivery::HeadFileManager head_file_manager;
    spotify::content_delivery::StorageResolveClient storage_resolve_client;
    spotify::drm::WidevineLicenseClient widevine_license_client;
    spotify::streamer::FileStreamerImpl file_streamer;

    NativePlaybackServices()
        : auth_store(spotify::network::AuthSessionStore::instance()),
          http_client(auth_store),
          disk_cache(),
          track_info_provider(auth_store, http_client),
          head_file_manager(disk_cache, auth_store),
          storage_resolve_client(http_client),
          widevine_license_client(auth_store, http_client),
          file_streamer(auth_store, head_file_manager, storage_resolve_client, widevine_license_client) {}

    static NativePlaybackServices& instance() {
        static NativePlaybackServices s_services;
        return s_services;
    }
};

std::shared_ptr<spotify::player::rendering::TrackPlayer> buildRoutingTrackPlayer(AudioEngine* engine) {
    auto& services = NativePlaybackServices::instance();
    auto core_player = std::make_shared<spotify::player::rendering::CoreAudioTrackPlayer>(
        engine,
        services.file_streamer,
        services.track_info_provider);
    auto audio_player = std::make_shared<spotify::player::rendering::AudioTrackPlayer>(
        std::move(core_player),
        services.track_info_provider);
    auto unplayable_player = std::make_shared<spotify::player::rendering::UnplayableTrackPlayer>();

    std::vector<std::shared_ptr<spotify::player::rendering::TrackPlayer>> child_players;
    child_players.push_back(std::move(audio_player));
    return std::make_shared<spotify::player::rendering::RoutingTrackPlayer>(
        std::move(child_players),
        std::move(unplayable_player));
}

} // namespace

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
// Source loading & Direct Engine Controls
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
    return static_cast<int32_t>(engine->loadTrackWithHead(
        fileIdHex, fullTrackUrl, cacheDir, licenseServerUrl, authHeader, trackDurationMs));
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

MUSIFY_EXPORT void musify_engine_stop(void* handle) {
    if (!handle) return;
    auto* engine = static_cast<AudioEngine*>(handle);
    engine->stop();
}

// ===========================================================================
// Telemetry (isLeaf-safe: no GC interaction, no allocation)
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
// Memory helpers
// ===========================================================================

MUSIFY_EXPORT void musify_free_string(char* str) {
    if (str) {
        std::free(str);
    }
}

MUSIFY_EXPORT void musify_free_bytes(uint8_t* bytes) {
    if (bytes) {
        std::free(bytes);
    }
}

// ===========================================================================
// Native Auth Session & Kodiak Binary Extension Seeding
// ===========================================================================

MUSIFY_EXPORT void musify_set_auth_session(
        const char* access_token,
        const char* client_token,
        const char* sp_dc,
        const char* country,
        const char* catalogue,
        const char* accept_language,
        const char* cache_dir) {
    auto& services = NativePlaybackServices::instance();
    services.auth_store.updateSession(
        access_token,
        client_token,
        sp_dc,
        country,
        catalogue,
        accept_language,
        cache_dir);
    if (cache_dir && cache_dir[0] != '\0') {
        services.disk_cache.setBaseCacheDir(cache_dir);
    }
}

MUSIFY_EXPORT void musify_set_auth_refresh_port(int64_t dart_port) {
    NativePlaybackServices::instance().auth_store.setAuthRefreshPort(dart_port);
}

MUSIFY_EXPORT void musify_metadata_seed_extension(
        int32_t extension_kind,
        const char* entity_uri,
        const uint8_t* payload,
        int32_t payload_len) {
    if (!entity_uri || !payload || payload_len <= 0) return;
    NativePlaybackServices::instance().track_info_provider.seedExtensionPayload(
        extension_kind,
        std::string(entity_uri),
        payload,
        static_cast<size_t>(payload_len));
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

    auto* buffer = static_cast<uint8_t*>(std::malloc(proto_bytes.size()));
    if (!buffer) {
        *out_len = 0;
        return nullptr;
    }
    std::memcpy(buffer, proto_bytes.data(), proto_bytes.size());
    return buffer;
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

// ===========================================================================
// Dart DL API Initialization
// ===========================================================================

MUSIFY_EXPORT intptr_t musify_init_dart_api_dl(void* data) {
    return Dart_InitializeApiDL(data);
}

// ===========================================================================
// ContextPlayerImpl + PlayerRenderingSetup (1:1 with liborbit-jni-spotify.so)
// ===========================================================================

MUSIFY_EXPORT void* musify_cpi_create(void* engine_handle) {
    auto* engine = static_cast<AudioEngine*>(engine_handle);
    auto routing_player = buildRoutingTrackPlayer(engine);
    auto* cpi = new spotify::player::ContextPlayerImpl(std::move(routing_player));
    return static_cast<void*>(cpi);
}

MUSIFY_EXPORT void musify_cpi_destroy(void* handle) {
    if (!handle) return;
    auto* cpi = static_cast<spotify::player::ContextPlayerImpl*>(handle);
    delete cpi;
}

MUSIFY_EXPORT void musify_cpi_set_audio_engine(void* handle, void* engine_handle) {
    if (!handle) return;
    auto* cpi = static_cast<spotify::player::ContextPlayerImpl*>(handle);
    auto* engine = static_cast<AudioEngine*>(engine_handle);
    cpi->set_track_player(buildRoutingTrackPlayer(engine));
}

MUSIFY_EXPORT int32_t musify_cpi_handle_command(
        void* handle,
        const char* method,
        const uint8_t* payload,
        int32_t payload_len) {
    if (!handle || !method) return 0;
    auto* cpi = static_cast<spotify::player::ContextPlayerImpl*>(handle);
    const size_t len = (payload && payload_len > 0) ? static_cast<size_t>(payload_len) : 0;
    return cpi->handle_command(std::string(method), payload, len) ? 1 : 0;
}

MUSIFY_EXPORT void musify_cpi_advance_to_next_track(void* handle) {
    if (!handle) return;
    auto* cpi = static_cast<spotify::player::ContextPlayerImpl*>(handle);
    cpi->advance_to_next_track();
}

MUSIFY_EXPORT uint8_t* musify_cpi_get_state(void* handle, int32_t* out_len) {
    if (!handle || !out_len) {
        if (out_len) *out_len = 0;
        return nullptr;
    }
    auto* cpi = static_cast<spotify::player::ContextPlayerImpl*>(handle);
    auto state_vec = cpi->get_state();
    *out_len = static_cast<int32_t>(state_vec.size());
    if (state_vec.empty()) {
        return nullptr;
    }
    auto* buffer = static_cast<uint8_t*>(std::malloc(state_vec.size()));
    if (!buffer) {
        *out_len = 0;
        return nullptr;
    }
    std::memcpy(buffer, state_vec.data(), state_vec.size());
    return buffer;
}

MUSIFY_EXPORT uint8_t* musify_cpi_get_queue(void* handle, int32_t* out_len) {
    if (!handle || !out_len) {
        if (out_len) *out_len = 0;
        return nullptr;
    }
    auto* cpi = static_cast<spotify::player::ContextPlayerImpl*>(handle);
    auto queue_vec = cpi->get_queue();
    *out_len = static_cast<int32_t>(queue_vec.size());
    if (queue_vec.empty()) {
        return nullptr;
    }
    auto* buffer = static_cast<uint8_t*>(std::malloc(queue_vec.size()));
    if (!buffer) {
        *out_len = 0;
        return nullptr;
    }
    std::memcpy(buffer, queue_vec.data(), queue_vec.size());
    return buffer;
}

// ---------------------------------------------------------------------------
// Callback registration using Dart NativePorts
// ---------------------------------------------------------------------------

MUSIFY_EXPORT void musify_cpi_set_state_changed_port(void* handle, int64_t dart_port) {
    if (!handle) return;
    auto* cpi = static_cast<spotify::player::ContextPlayerImpl*>(handle);
    if (dart_port == 0) {
        cpi->set_state_changed_callback(nullptr);
        return;
    }
    cpi->set_state_changed_callback([dart_port](const uint8_t* data, size_t len) {
        if (!data || len == 0) return;
        Dart_CObject cobj;
        cobj.type = Dart_CObject_kTypedData;
        cobj.value.as_typed_data.type = Dart_TypedData_kUint8;
        cobj.value.as_typed_data.length = static_cast<intptr_t>(len);
        cobj.value.as_typed_data.values = data;
        Dart_PostCObject_DL(dart_port, &cobj);
    });
}

MUSIFY_EXPORT void musify_cpi_set_queue_changed_port(void* handle, int64_t dart_port) {
    if (!handle) return;
    auto* cpi = static_cast<spotify::player::ContextPlayerImpl*>(handle);
    if (dart_port == 0) {
        cpi->set_queue_changed_callback(nullptr);
        return;
    }
    cpi->set_queue_changed_callback([dart_port](const uint8_t* data, size_t len) {
        if (!data || len == 0) return;
        Dart_CObject cobj;
        cobj.type = Dart_CObject_kTypedData;
        cobj.value.as_typed_data.type = Dart_TypedData_kUint8;
        cobj.value.as_typed_data.length = static_cast<intptr_t>(len);
        cobj.value.as_typed_data.values = data;
        Dart_PostCObject_DL(dart_port, &cobj);
    });
}

MUSIFY_EXPORT void musify_cpi_set_error_port(void* handle, int64_t dart_port) {
    if (!handle) return;
    auto* cpi = static_cast<spotify::player::ContextPlayerImpl*>(handle);
    if (dart_port == 0) {
        cpi->set_error_callback(nullptr);
        return;
    }
    cpi->set_error_callback([dart_port](const std::string& error_code, const std::string& message) {
        std::string err_str = error_code;
        if (!message.empty()) {
            if (!err_str.empty()) err_str += ": ";
            err_str += message;
        }
        if (err_str.empty()) return;

        Dart_CObject cobj;
        cobj.type = Dart_CObject_kTypedData;
        cobj.value.as_typed_data.type = Dart_TypedData_kUint8;
        cobj.value.as_typed_data.length = static_cast<intptr_t>(err_str.size());
        cobj.value.as_typed_data.values = reinterpret_cast<const uint8_t*>(err_str.data());
        Dart_PostCObject_DL(dart_port, &cobj);
    });
}
