#pragma once

#include "../network/NativeHttpClient.h"
#include "../network/NativeTrafficController.h"

#include <chrono>
#include <cstdint>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

namespace spotify::content_delivery {

/// Explicit resolution state machine for a `/storage-resolve` lookup.
enum class StorageResolveStatus : uint8_t {
    Unresolved = 0,
    Resolved = 1,
    Restricted = 2,
};

struct StorageResolveResult {
    StorageResolveStatus status{StorageResolveStatus::Unresolved};
    std::vector<std::string> cdn_urls;

    [[nodiscard]] bool isResolved() const noexcept {
        return status == StorageResolveStatus::Resolved && !cdn_urls.empty();
    }

    [[nodiscard]] bool isRestricted() const noexcept {
        return status == StorageResolveStatus::Restricted;
    }
};

/// Native C++ client for `/storage-resolve/v2/files/audio/{interactive|interactive_prefetch}/<format>/<fileId>`.
/// Governed by `NativeTrafficController` (`P1_PlaybackSetup` for `InteractivePlayback`,
/// `P3_BackgroundBatch` for `BackgroundPrefetch`).
class StorageResolveClient {
public:
    explicit StorageResolveClient(network::NativeHttpClient& http_client);
    ~StorageResolveClient() = default;

    StorageResolveClient(const StorageResolveClient&) = delete;
    StorageResolveClient& operator=(const StorageResolveClient&) = delete;

    /// Returns cached CDN URLs for `(format_code, file_id_hex)` in 0ms if present and unexpired.
    [[nodiscard]] StorageResolveResult tryGetCached(
        int32_t format_code,
        const std::string& file_id_hex);

    /// Resolves signed CDN URLs for `(format_code, file_id_hex)` according to `intent`.
    /// When `intent == AcquisitionIntent::InteractivePlayback`, parks in `NativeTrafficController`
    /// (`P1_PlaybackSetup`, `WaitForOnline`) if offline and automatically resumes when online
    /// or aborts in <1ms if `cancel_pred` returns true.
    [[nodiscard]] StorageResolveResult resolveAudioFile(
        int32_t format_code,
        const std::string& file_id_hex,
        network::AcquisitionIntent intent = network::AcquisitionIntent::InteractivePlayback,
        const network::CancelPredicate& cancel_pred = nullptr);

private:
    struct CachedEntry {
        std::vector<std::string> cdn_urls;
        std::chrono::steady_clock::time_point expires_at;
    };

    static bool parseProtobufResponse(const std::vector<uint8_t>& body,
                                      StorageResolveResult& out);
    static bool parseJsonFallback(const std::vector<uint8_t>& body,
                                  StorageResolveResult& out);

    network::NativeHttpClient& http_client_;
    std::mutex mutex_;
    std::unordered_map<std::string, CachedEntry> cache_;
};

} // namespace spotify::content_delivery
