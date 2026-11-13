#pragma once

#include "../network/AuthSessionStore.h"
#include "../network/NativeHttpClient.h"

#include <media/NdkMediaDrm.h>

#include <chrono>
#include <cstdint>
#include <list>
#include <mutex>
#include <string>
#include <vector>

namespace spotify::drm {

struct WidevineLicenseContext {
    std::string license_url;
    std::string auth_header;
};

/// Pure C++ Widevine DRM manager and license client powered by Android NDK `AMediaDrm`
/// (`libmediandk.so`) and the native `libcurl` + `mbedTLS` HTTP/2 stack (`NativeHttpClient`).
///
/// Responsibilities:
/// - Resolves and caches Spotify Widevine Keymaster URLs (`/melody/v1/license_url`).
/// - Manages the hardware `AMediaDrm` instance and a 6-session LRU pool across track switches.
/// - Executes Widevine CDM device provisioning (`AMediaDrm_getProvisionRequest` /
///   `AMediaDrm_provideProvisionResponse`) and streaming license exchanges
///   (`AMediaDrm_getKeyRequest` / `AMediaDrm_provideKeyResponse`) entirely in C++ with zero JNI/Java overhead.
class WidevineLicenseClient {
public:
    WidevineLicenseClient(network::AuthSessionStore& auth_store,
                          network::NativeHttpClient& http_client);
    ~WidevineLicenseClient();

    WidevineLicenseClient(const WidevineLicenseClient&) = delete;
    WidevineLicenseClient& operator=(const WidevineLicenseClient&) = delete;

    static WidevineLicenseClient& defaultInstance();

    [[nodiscard]] WidevineLicenseContext resolveLicenseContext();

    /// Opens or reuses a hardware Widevine `AMediaDrm` session for the given PSSH box,
    /// performing provisioning and license key exchange over C++ `NativeHttpClient` if needed.
    /// Returns the raw session ID bytes for `AMediaCrypto_new`, or an empty vector on failure.
    [[nodiscard]] std::vector<uint8_t> acquireStreamingSession(
        const std::vector<uint8_t>& pssh_bytes,
        const std::string& license_url,
        const std::string& auth_header,
        int max_retries = 3);

    /// Explicitly closes a specific `AMediaDrm` session and removes it from the LRU cache.
    void closeSession(const std::vector<uint8_t>& session_id);

    /// Closes all cached `AMediaDrm` sessions.
    void closeAllSessions();

    /// Executes a binary Widevine license challenge POST using the native C++ HTTP/2 client.
    [[nodiscard]] network::HttpResponse executeLicensePost(
        const std::string& license_url,
        const std::string& auth_header,
        const std::vector<uint8_t>& challenge) const;

    /// Executes a Widevine CDM device provisioning POST using the native C++ HTTP client.
    [[nodiscard]] network::HttpResponse executeProvisioningPost(
        const std::string& provisioning_url,
        const std::vector<uint8_t>& request_data) const;

private:
    struct CachedSessionEntry {
        std::string cache_key;
        std::vector<uint8_t> session_id;
    };

    static constexpr size_t kMaxConcurrentSessions = 6;

    std::string resolveLicenseUrl();
    bool ensureMediaDrmLocked();
    bool handleProvisioningLocked();
    void evictAllSessionsLocked();
    void putCachedSessionLocked(const std::string& key, const std::vector<uint8_t>& session_id);
    static void closeRawSessionLocked(AMediaDrm* drm, const std::vector<uint8_t>& session_id) noexcept;

    network::AuthSessionStore& auth_store_;
    network::NativeHttpClient& http_client_;

    std::mutex mutex_;
    std::string cached_url_;
    std::chrono::steady_clock::time_point expires_at_{};

    std::mutex drm_mutex_;
    AMediaDrm* media_drm_{nullptr};
    std::list<CachedSessionEntry> session_lru_;
};

} // namespace spotify::drm
