#pragma once

#include "../network/AuthSessionStore.h"
#include "../network/NativeHttpClient.h"

#include <chrono>
#include <mutex>
#include <string>

namespace spotify::drm {

struct WidevineLicenseContext {
    std::string license_url;
    std::string auth_header;
};

/// Resolves Spotify Widevine Keymaster URLs (`/melody/v1/license_url`) and formats DRM auth headers.
class WidevineLicenseClient {
public:
    WidevineLicenseClient(network::AuthSessionStore& auth_store,
                          network::NativeHttpClient& http_client);
    ~WidevineLicenseClient() = default;

    WidevineLicenseClient(const WidevineLicenseClient&) = delete;
    WidevineLicenseClient& operator=(const WidevineLicenseClient&) = delete;

    [[nodiscard]] WidevineLicenseContext resolveLicenseContext();

private:
    std::string resolveLicenseUrl();

    network::AuthSessionStore& auth_store_;
    network::NativeHttpClient& http_client_;
    std::mutex mutex_;
    std::string cached_url_;
    std::chrono::steady_clock::time_point expires_at_{};
};

} // namespace spotify::drm
