#pragma once

#include "../network/NativeHttpClient.h"

#include <chrono>
#include <cstdint>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

namespace spotify::content_delivery {

struct StorageResolveResult {
    bool ok{false};
    bool restricted{false};
    std::vector<std::string> cdn_urls;
};

/// Native C++ client for `/storage-resolve/v2/files/audio/{interactive|interactive_prefetch}/<format>/<fileId>`.
class StorageResolveClient {
public:
    explicit StorageResolveClient(network::NativeHttpClient& http_client);
    ~StorageResolveClient() = default;

    StorageResolveClient(const StorageResolveClient&) = delete;
    StorageResolveClient& operator=(const StorageResolveClient&) = delete;

    [[nodiscard]] StorageResolveResult resolveAudioFile(
        int32_t format_code,
        const std::string& file_id_hex,
        bool is_prefetch = false);

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
