#include "AudioEngine.h"
#include "ContextProcessor.h"
#include "ProtobufWireHelper.h"
#include "cache/DiskCache.h"
#include "connect/ConnectEsperantoProtos.h"
#include "connect/ConnectRpcExecutor.h"
#include "connect/ConnectServiceImpl.h"
#include "connect/ConnectStateProtos.h"
#include "connect/ConnectSubsystem.h"
#include "connect/ConnectVolumeServiceImpl.h"
#include "connect/DodoServiceImpl.h"
#include "content_delivery/HeadFileManager.h"
#include "content_delivery/StorageResolveClient.h"
#include "drm/WidevineLicenseClient.h"
#include "metadata/TrackInfoProvider.h"
#include "network/AuthSessionStore.h"
#include "network/NativeHttpClient.h"
#include "network/NativeLog.h"
#include "player/ContextPlayerImpl.h"
#include "rendering/AudioTrackPlayer.h"
#include "rendering/CoreAudioTrackPlayer.h"
#include "rendering/RoutingTrackPlayer.h"
#include "rendering/UnplayableTrackPlayer.h"
#include "streamer/FileStreamerImpl.h"

#include "dart_api_dl.h"

#include <atomic>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#define MUSIFY_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))

namespace {

std::atomic<int64_t> g_auth_refresh_port{0};

/// Process-wide singleton holding native liborbit Layer 4 playback services so Kodiak
/// metadata seeding, Tier 2 DiskCache, and auth session updates work deterministically
/// across all playback and JNI subsystems.
struct NativePlaybackServices {
    spotify::network::AuthSessionStore& auth_store;
    spotify::network::NativeHttpClient& http_client;
    spotify::cache::DiskCache& disk_cache;
    spotify::metadata::TrackInfoProvider track_info_provider;
    spotify::content_delivery::HeadFileManager head_file_manager;
    spotify::content_delivery::StorageResolveClient storage_resolve_client;
    spotify::drm::WidevineLicenseClient& widevine_license_client;
    spotify::streamer::FileStreamerImpl file_streamer;

    NativePlaybackServices()
        : auth_store(spotify::network::AuthSessionStore::instance()),
          http_client(spotify::network::NativeHttpClient::defaultInstance()),
          disk_cache(spotify::cache::DiskCache::defaultInstance()),
          track_info_provider(auth_store, http_client),
          head_file_manager(disk_cache, auth_store, http_client),
          storage_resolve_client(http_client),
          widevine_license_client(spotify::drm::WidevineLicenseClient::defaultInstance()),
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
// Native Auth Session, Client Header Profile & Kodiak Binary Extension Seeding
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
    g_auth_refresh_port.store(dart_port, std::memory_order_release);
    auto& auth_store = NativePlaybackServices::instance().auth_store;
    auth_store.setAuthRefreshPort(dart_port);
    if (dart_port == 0) {
        auth_store.set_refresh_request_callback(nullptr);
        return;
    }
    auth_store.set_refresh_request_callback([](int64_t reason_code) {
        const int64_t port = g_auth_refresh_port.load(std::memory_order_acquire);
        if (port == 0 || Dart_PostCObject_DL == nullptr) {
            return;
        }
        Dart_CObject msg;
        msg.type = Dart_CObject_kInt64;
        msg.value.as_int64 = reason_code;
        if (!Dart_PostCObject_DL(port, &msg)) {
            NET_LOGD(
                "Dart_PostCObject_DL(auth_refresh) returned false for port=%lld reason=%lld",
                static_cast<long long>(port),
                static_cast<long long>(reason_code));
        }
    });
}

MUSIFY_EXPORT void musify_set_client_profile(
        const char* client_id,
        const char* app_platform,
        const char* app_version,
        const char* user_agent,
        int32_t send_origin_headers) {
    NativePlaybackServices::instance().auth_store.set_client_profile(
        client_id,
        app_platform,
        app_version,
        user_agent,
        send_origin_headers != 0);
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
    const int32_t iteration = cp->get_current_iteration();
    const uint64_t queue_rev = iteration > 0 ? static_cast<uint64_t>(iteration) : 0ULL;
    auto proto_bytes = spotify::player::encode_queue(cur_ptr, next, prev, queue_rev);

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
    auto* cpi = new spotify::player::ContextPlayerImpl(
        std::move(routing_player),
        &NativePlaybackServices::instance().track_info_provider);
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
        if (!data || len == 0 || Dart_PostCObject_DL == nullptr) return;
        Dart_CObject cobj;
        cobj.type = Dart_CObject_kTypedData;
        cobj.value.as_typed_data.type = Dart_TypedData_kUint8;
        cobj.value.as_typed_data.length = static_cast<intptr_t>(len);
        cobj.value.as_typed_data.values = data;
        if (!Dart_PostCObject_DL(dart_port, &cobj)) {
            PLAYER_REMOTE_LOGD(
                "Dart_PostCObject_DL(state_changed) returned false for port=%lld",
                static_cast<long long>(dart_port));
        }
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
        if (!data || len == 0 || Dart_PostCObject_DL == nullptr) return;
        Dart_CObject cobj;
        cobj.type = Dart_CObject_kTypedData;
        cobj.value.as_typed_data.type = Dart_TypedData_kUint8;
        cobj.value.as_typed_data.length = static_cast<intptr_t>(len);
        cobj.value.as_typed_data.values = data;
        if (!Dart_PostCObject_DL(dart_port, &cobj)) {
            PLAYER_REMOTE_LOGD(
                "Dart_PostCObject_DL(queue_changed) returned false for port=%lld",
                static_cast<long long>(dart_port));
        }
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
        if (Dart_PostCObject_DL == nullptr) return;
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
        if (!Dart_PostCObject_DL(dart_port, &cobj)) {
            PLAYER_REMOTE_LOGD(
                "Dart_PostCObject_DL(player_error) returned false for port=%lld",
                static_cast<long long>(dart_port));
        }
    });
}

// ===========================================================================
// ConnectSubsystem + Esperanto Services FFI Bridge (Items 126-130 + #47 §2)
// ===========================================================================

namespace {

struct NativeConnectBundle {
    spotify::connectstate::ConnectSubsystem subsystem;
    spotify::connectstate::esperanto::ConnectServiceImpl connect_service;
    spotify::connectstate::esperanto::ConnectVolumeServiceImpl volume_service;
    spotify::connectstate::esperanto::DodoServiceImpl dodo_service;
    spotify::connectstate::esperanto::ConnectRpcExecutor rpc_executor;

    std::mutex state_request_mutex;
    spotify::connectstate::esperanto::StateRequest state_request;

    std::atomic<bool> destroyed{false};
    std::atomic<int64_t> state_port{0};
    std::atomic<int64_t> volume_port{0};
    std::atomic<int64_t> local_volume_port{0};
    std::atomic<int64_t> dodo_port{0};
    std::atomic<int64_t> install_spotify_port{0};
    std::atomic<int64_t> diagnostic_port{0};

    uint64_t state_listener_id{0};
    uint64_t volume_listener_id{0};
    uint64_t local_volume_listener_id{0};
    uint64_t dodo_listener_id{0};

    explicit NativeConnectBundle(spotify::player::ContextPlayerImpl& player)
        : subsystem(
              player,
              NativePlaybackServices::instance().auth_store,
              NativePlaybackServices::instance().http_client),
          connect_service(subsystem),
          volume_service(subsystem),
          dodo_service(subsystem),
          rpc_executor(connect_service, volume_service, dodo_service) {}
};

void post_bytes_to_dart_port(int64_t port, const std::vector<uint8_t>& bytes) {
    if (port == 0 || Dart_PostCObject_DL == nullptr) {
        return;
    }
    static constexpr uint8_t kEmptyByte = 0;
    Dart_CObject cobj;
    cobj.type = Dart_CObject_kTypedData;
    cobj.value.as_typed_data.type = Dart_TypedData_kUint8;
    cobj.value.as_typed_data.length = static_cast<intptr_t>(bytes.size());
    cobj.value.as_typed_data.values = bytes.empty() ? &kEmptyByte : bytes.data();
    if (!Dart_PostCObject_DL(port, &cobj)) {
        CONNECT_LOGD(
            "Dart_PostCObject_DL(bytes) returned false for port=%lld len=%zu",
            static_cast<long long>(port),
            bytes.size());
    }
}

void post_string_to_dart_port(int64_t port, const std::string& str) {
    if (port == 0 || Dart_PostCObject_DL == nullptr) {
        return;
    }
    Dart_CObject cobj;
    cobj.type = Dart_CObject_kString;
    cobj.value.as_string = str.c_str();
    if (!Dart_PostCObject_DL(port, &cobj)) {
        CONNECT_LOGD(
            "Dart_PostCObject_DL(string) returned false for port=%lld len=%zu",
            static_cast<long long>(port),
            str.size());
    }
}

void post_rpc_result_to_dart_port(
    int64_t reply_port,
    int64_t request_id,
    spotify::connectstate::esperanto::EsperantoCallStatus status,
    const std::vector<uint8_t>& payload) {
    if (reply_port == 0 || Dart_PostCObject_DL == nullptr) {
        return;
    }
    static constexpr uint8_t kEmptyByte = 0;

    Dart_CObject elem_request_id;
    elem_request_id.type = Dart_CObject_kInt64;
    elem_request_id.value.as_int64 = request_id;

    Dart_CObject elem_status;
    elem_status.type = Dart_CObject_kInt32;
    elem_status.value.as_int32 = static_cast<int32_t>(status);

    Dart_CObject elem_payload;
    elem_payload.type = Dart_CObject_kTypedData;
    elem_payload.value.as_typed_data.type = Dart_TypedData_kUint8;
    elem_payload.value.as_typed_data.length = static_cast<intptr_t>(payload.size());
    elem_payload.value.as_typed_data.values =
        payload.empty() ? &kEmptyByte : payload.data();

    Dart_CObject* elements[3] = {
        &elem_request_id,
        &elem_status,
        &elem_payload,
    };

    Dart_CObject array_obj;
    array_obj.type = Dart_CObject_kArray;
    array_obj.value.as_array.length = 3;
    array_obj.value.as_array.values = elements;

    if (!Dart_PostCObject_DL(reply_port, &array_obj)) {
        CONNECT_LOGD(
            "Dart_PostCObject_DL(rpc_reply) returned false for port=%lld req_id=%lld",
            static_cast<long long>(reply_port),
            static_cast<long long>(request_id));
    }
}

void set_connect_port_atomic(
    NativeConnectBundle* bundle,
    std::atomic<int64_t>& target,
    int64_t dart_port) {
    if (!bundle) {
        return;
    }
    if (bundle->destroyed.load(std::memory_order_seq_cst)) {
        return;
    }
    target.store(dart_port, std::memory_order_seq_cst);
    if (bundle->destroyed.load(std::memory_order_seq_cst)) {
        target.store(0, std::memory_order_seq_cst);
    }
}

uint8_t* marshal_esperanto_result(
    const spotify::connectstate::esperanto::EsperantoCallResult& res,
    int32_t* out_len,
    int32_t* out_status) {
    if (out_status != nullptr) {
        *out_status = static_cast<int32_t>(res.status);
    }
    if (out_len == nullptr) {
        return nullptr;
    }
    if (res.payload.empty()) {
        *out_len = 0;
        return nullptr;
    }
    auto* buf = static_cast<uint8_t*>(std::malloc(res.payload.size()));
    if (buf == nullptr) {
        *out_len = 0;
        if (out_status != nullptr) {
            *out_status = static_cast<int32_t>(
                spotify::connectstate::esperanto::EsperantoCallStatus::kBackendFailure);
        }
        return nullptr;
    }
    std::memcpy(buf, res.payload.data(), res.payload.size());
    *out_len = static_cast<int32_t>(res.payload.size());
    return buf;
}

}  // namespace

MUSIFY_EXPORT void* musify_connect_create(void* cpi_handle) {
    if (!cpi_handle) {
        return nullptr;
    }
    auto* cpi = static_cast<spotify::player::ContextPlayerImpl*>(cpi_handle);
    auto* bundle = new (std::nothrow) NativeConnectBundle(*cpi);
    if (!bundle) {
        return nullptr;
    }

    bundle->rpc_executor.set_state_request_observer(
        [bundle](const spotify::connectstate::esperanto::StateRequest& req) {
            if (bundle->destroyed.load(std::memory_order_acquire)) {
                return;
            }
            std::lock_guard<std::mutex> lock(bundle->state_request_mutex);
            bundle->state_request = req;
        });
    bundle->rpc_executor.start();

    bundle->state_listener_id = bundle->subsystem.add_state_listener([bundle]() {
        if (bundle->destroyed.load(std::memory_order_acquire)) {
            return;
        }
        if (bundle->state_port.load(std::memory_order_acquire) == 0) {
            return;
        }
        spotify::connectstate::esperanto::StateRequest req;
        {
            std::lock_guard<std::mutex> lock(bundle->state_request_mutex);
            req = bundle->state_request;
        }
        const auto bytes = spotify::connectstate::esperanto::encode_state_response(
            bundle->connect_service.build_state_response(req));
        if (bundle->destroyed.load(std::memory_order_acquire)) {
            return;
        }
        const int64_t port = bundle->state_port.load(std::memory_order_acquire);
        if (port != 0) {
            post_bytes_to_dart_port(port, bytes);
        }
    });

    bundle->volume_listener_id = bundle->subsystem.add_volume_listener(
        [bundle](const spotify::connectstate::ConnectVolumeSnapshot& snap) {
            if (bundle->destroyed.load(std::memory_order_acquire)) {
                return;
            }
            if (bundle->volume_port.load(std::memory_order_acquire) == 0) {
                return;
            }
            const auto bytes = bundle->volume_service.encode_volume_snapshot(snap);
            if (bundle->destroyed.load(std::memory_order_acquire)) {
                return;
            }
            const int64_t port = bundle->volume_port.load(std::memory_order_acquire);
            if (port != 0) {
                post_bytes_to_dart_port(port, bytes);
            }
        });

    bundle->local_volume_listener_id = bundle->subsystem.add_local_volume_listener(
        [bundle](uint32_t vol, spotify::connectstate::LocalVolumeReason reason) {
            if (bundle->destroyed.load(std::memory_order_acquire)) {
                return;
            }
            if (bundle->local_volume_port.load(std::memory_order_acquire) == 0) {
                return;
            }
            const auto bytes = bundle->volume_service.encode_local_volume(vol, reason);
            if (bundle->destroyed.load(std::memory_order_acquire)) {
                return;
            }
            const int64_t port = bundle->local_volume_port.load(std::memory_order_acquire);
            if (port != 0) {
                post_bytes_to_dart_port(port, bytes);
            }
        });

    bundle->dodo_listener_id = bundle->subsystem.add_dodo_listener(
        [bundle](const std::vector<spotify::connectstate::SingleDodo>& dodos) {
            if (bundle->destroyed.load(std::memory_order_acquire)) {
                return;
            }
            if (bundle->dodo_port.load(std::memory_order_acquire) == 0) {
                return;
            }
            const auto bytes = bundle->dodo_service.encode_dodos(dodos);
            if (bundle->destroyed.load(std::memory_order_acquire)) {
                return;
            }
            const int64_t port = bundle->dodo_port.load(std::memory_order_acquire);
            if (port != 0) {
                post_bytes_to_dart_port(port, bytes);
            }
        });

    return static_cast<void*>(bundle);
}

MUSIFY_EXPORT void musify_connect_destroy(void* handle) {
    if (!handle) {
        return;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    bundle->destroyed.store(true, std::memory_order_seq_cst);
    bundle->state_port.store(0, std::memory_order_seq_cst);
    bundle->volume_port.store(0, std::memory_order_seq_cst);
    bundle->local_volume_port.store(0, std::memory_order_seq_cst);
    bundle->dodo_port.store(0, std::memory_order_seq_cst);
    bundle->install_spotify_port.store(0, std::memory_order_seq_cst);
    bundle->diagnostic_port.store(0, std::memory_order_seq_cst);

    bundle->subsystem.set_diagnostic_callback(nullptr);
    bundle->rpc_executor.set_state_request_observer(nullptr);

    if (bundle->state_listener_id != 0) {
        bundle->subsystem.remove_state_listener(bundle->state_listener_id);
        bundle->state_listener_id = 0;
    }
    if (bundle->volume_listener_id != 0) {
        bundle->subsystem.remove_volume_listener(bundle->volume_listener_id);
        bundle->volume_listener_id = 0;
    }
    if (bundle->local_volume_listener_id != 0) {
        bundle->subsystem.remove_local_volume_listener(bundle->local_volume_listener_id);
        bundle->local_volume_listener_id = 0;
    }
    if (bundle->dodo_listener_id != 0) {
        bundle->subsystem.remove_dodo_listener(bundle->dodo_listener_id);
        bundle->dodo_listener_id = 0;
    }

    bundle->rpc_executor.stop();
    bundle->subsystem.stop();
    delete bundle;
}

MUSIFY_EXPORT int32_t musify_connect_start(
    void* handle,
    const uint8_t* device_info_bytes,
    int32_t len) {
    if (!handle || !device_info_bytes || len <= 0) {
        CONNECT_LOGE(
            "musify_connect_start rejected: invalid handle or empty DeviceInfo payload "
            "(handle=%p bytes=%p len=%d)",
            handle,
            static_cast<const void*>(device_info_bytes),
            len);
        return spotify::connectstate::ConnectSubsystem::kStartInvalidArgs;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    if (bundle->destroyed.load(std::memory_order_acquire)) {
        CONNECT_LOGE("musify_connect_start rejected: NativeConnectBundle is destroyed");
        return spotify::connectstate::ConnectSubsystem::kStartInvalidArgs;
    }
    bundle->rpc_executor.start();
    return bundle->subsystem.start(device_info_bytes, len);
}

MUSIFY_EXPORT void musify_connect_stop(void* handle) {
    if (!handle) {
        return;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    bundle->rpc_executor.stop();
    bundle->subsystem.stop();
}

MUSIFY_EXPORT int32_t musify_connect_call_async(
    void* handle,
    int32_t service_id,
    const char* method,
    const uint8_t* payload,
    int32_t payload_len,
    int64_t request_id,
    int64_t reply_port) {
    if (!handle || !method || method[0] == '\0' || payload_len < 0 ||
        (payload_len > 0 && !payload) || reply_port == 0) {
        return spotify::connectstate::esperanto::ConnectRpcExecutor::kSubmitInvalidArgs;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    if (bundle->destroyed.load(std::memory_order_acquire)) {
        return spotify::connectstate::esperanto::ConnectRpcExecutor::kSubmitStopped;
    }
    return bundle->rpc_executor.submit(
        service_id,
        method,
        payload,
        payload_len,
        request_id,
        [reply_port](
            int64_t req_id,
            spotify::connectstate::esperanto::EsperantoCallStatus status,
            std::vector<uint8_t> res_payload) {
            post_rpc_result_to_dart_port(reply_port, req_id, status, res_payload);
        });
}

MUSIFY_EXPORT int32_t musify_connect_set_endpoints(
    void* handle,
    const char* spclient_base_url,
    const char* dealer_ws_url) {
    if (!handle) {
        return -1;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    if (bundle->destroyed.load(std::memory_order_acquire)) {
        return -1;
    }
    const std::string_view spclient_sv =
        spclient_base_url ? std::string_view(spclient_base_url) : std::string_view{};
    const std::string_view dealer_sv =
        dealer_ws_url ? std::string_view(dealer_ws_url) : std::string_view{};
    const int32_t rc = bundle->subsystem.set_endpoints(spclient_sv, dealer_sv);
    if (rc == 0 && !spclient_sv.empty()) {
        NativePlaybackServices::instance().track_info_provider.set_spclient_base_url(
            std::string(spclient_sv));
    }
    return rc;
}

MUSIFY_EXPORT int32_t musify_connect_reconnect(void* handle, int32_t reason_code) {
    if (!handle) {
        return -1;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    if (bundle->destroyed.load(std::memory_order_acquire)) {
        return -1;
    }
    return bundle->subsystem.reconnect(reason_code);
}

MUSIFY_EXPORT void musify_connect_set_network_available(void* handle, int32_t is_available) {
    if (!handle) {
        return;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    if (bundle->destroyed.load(std::memory_order_acquire)) {
        return;
    }
    bundle->subsystem.set_network_available(is_available != 0);
}

MUSIFY_EXPORT int32_t musify_connect_update_nsd_services(
    void* handle,
    const char* services_json_utf8) {
    if (!handle) {
        return -1;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    if (bundle->destroyed.load(std::memory_order_acquire)) {
        return -1;
    }
    return bundle->subsystem.update_nsd_services(
        services_json_utf8 ? std::string_view(services_json_utf8) : std::string_view{});
}

MUSIFY_EXPORT int32_t musify_connect_set_local_volume(
    void* handle,
    uint32_t volume_0_to_65535,
    int32_t volume_steps,
    int32_t reason_code) {
    if (!handle) {
        return -1;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    if (bundle->destroyed.load(std::memory_order_acquire)) {
        return -1;
    }
    return bundle->subsystem.set_local_volume(volume_0_to_65535, volume_steps, reason_code);
}

MUSIFY_EXPORT uint8_t* musify_connect_service_call(
    void* handle,
    const char* method,
    const uint8_t* payload,
    int32_t payload_len,
    int32_t* out_len,
    int32_t* out_status) {
    if (!handle || !method || payload_len < 0 || (payload_len > 0 && !payload)) {
        if (out_len) *out_len = 0;
        if (out_status) {
            *out_status = static_cast<int32_t>(
                spotify::connectstate::esperanto::EsperantoCallStatus::kInvalidArguments);
        }
        return nullptr;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    if (bundle->destroyed.load(std::memory_order_acquire)) {
        if (out_len) *out_len = 0;
        if (out_status) {
            *out_status = static_cast<int32_t>(
                spotify::connectstate::esperanto::EsperantoCallStatus::kBackendFailure);
        }
        return nullptr;
    }

    const std::string_view method_sv(method);
    const size_t len = static_cast<size_t>(payload_len);
    if (method_sv == "State") {
        spotify::connectstate::esperanto::StateRequest req;
        if (!spotify::connectstate::esperanto::decode_state_request(payload, len, req)) {
            spotify::connectstate::esperanto::EsperantoCallResult err{
                .status = spotify::connectstate::esperanto::EsperantoCallStatus::kDecodeError,
                .payload = {},
            };
            return marshal_esperanto_result(err, out_len, out_status);
        }
        {
            std::lock_guard<std::mutex> lock(bundle->state_request_mutex);
            bundle->state_request = req;
        }
    }

    const auto res = bundle->connect_service.dispatch(method_sv, payload, len);
    return marshal_esperanto_result(res, out_len, out_status);
}

MUSIFY_EXPORT uint8_t* musify_connect_volume_service_call(
    void* handle,
    const char* method,
    const uint8_t* payload,
    int32_t payload_len,
    int32_t* out_len,
    int32_t* out_status) {
    if (!handle || !method || payload_len < 0 || (payload_len > 0 && !payload)) {
        if (out_len) *out_len = 0;
        if (out_status) {
            *out_status = static_cast<int32_t>(
                spotify::connectstate::esperanto::EsperantoCallStatus::kInvalidArguments);
        }
        return nullptr;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    if (bundle->destroyed.load(std::memory_order_acquire)) {
        if (out_len) *out_len = 0;
        if (out_status) {
            *out_status = static_cast<int32_t>(
                spotify::connectstate::esperanto::EsperantoCallStatus::kBackendFailure);
        }
        return nullptr;
    }
    const auto res = bundle->volume_service.dispatch(
        method, payload, static_cast<size_t>(payload_len));
    return marshal_esperanto_result(res, out_len, out_status);
}

MUSIFY_EXPORT uint8_t* musify_dodo_service_call(
    void* handle,
    const char* method,
    const uint8_t* payload,
    int32_t payload_len,
    int32_t* out_len,
    int32_t* out_status) {
    if (!handle || !method || payload_len < 0 || (payload_len > 0 && !payload)) {
        if (out_len) *out_len = 0;
        if (out_status) {
            *out_status = static_cast<int32_t>(
                spotify::connectstate::esperanto::EsperantoCallStatus::kInvalidArguments);
        }
        return nullptr;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    if (bundle->destroyed.load(std::memory_order_acquire)) {
        if (out_len) *out_len = 0;
        if (out_status) {
            *out_status = static_cast<int32_t>(
                spotify::connectstate::esperanto::EsperantoCallStatus::kBackendFailure);
        }
        return nullptr;
    }
    const auto res = bundle->dodo_service.dispatch(
        method, payload, static_cast<size_t>(payload_len));
    return marshal_esperanto_result(res, out_len, out_status);
}

MUSIFY_EXPORT void musify_connect_set_state_port(void* handle, int64_t dart_port) {
    if (!handle) {
        return;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    set_connect_port_atomic(bundle, bundle->state_port, dart_port);
}

MUSIFY_EXPORT void musify_connect_set_volume_port(void* handle, int64_t dart_port) {
    if (!handle) {
        return;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    set_connect_port_atomic(bundle, bundle->volume_port, dart_port);
}

MUSIFY_EXPORT void musify_connect_set_local_volume_port(void* handle, int64_t dart_port) {
    if (!handle) {
        return;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    set_connect_port_atomic(bundle, bundle->local_volume_port, dart_port);
}

MUSIFY_EXPORT void musify_connect_set_dodo_port(void* handle, int64_t dart_port) {
    if (!handle) {
        return;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    set_connect_port_atomic(bundle, bundle->dodo_port, dart_port);
}

MUSIFY_EXPORT void musify_connect_set_install_spotify_port(void* handle, int64_t dart_port) {
    if (!handle) {
        return;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    set_connect_port_atomic(bundle, bundle->install_spotify_port, dart_port);
}

MUSIFY_EXPORT void musify_connect_set_diagnostic_port(void* handle, int64_t dart_port) {
    if (!handle) {
        return;
    }
    auto* bundle = static_cast<NativeConnectBundle*>(handle);
    set_connect_port_atomic(bundle, bundle->diagnostic_port, dart_port);
    if (dart_port == 0 || bundle->destroyed.load(std::memory_order_acquire)) {
        bundle->subsystem.set_diagnostic_callback(nullptr);
        return;
    }
    bundle->subsystem.set_diagnostic_callback([bundle](const std::string& json_payload) {
        if (bundle->destroyed.load(std::memory_order_acquire) || json_payload.empty()) {
            return;
        }
        const int64_t port = bundle->diagnostic_port.load(std::memory_order_acquire);
        if (port != 0) {
            post_string_to_dart_port(port, json_payload);
        }
    });
}
