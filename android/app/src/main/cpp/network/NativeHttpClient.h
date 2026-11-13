#pragma once

#include "AuthSessionStore.h"

#include <atomic>
#include <cstdint>
#include <functional>
#include <string>
#include <utility>
#include <vector>

namespace spotify::network {

struct HttpResponse {
    int32_t status_code{0};
    std::vector<uint8_t> body;
    bool transport_ok{false};
    int64_t content_length{-1};
    bool accepts_ranges{false};
    std::string effective_url;

    [[nodiscard]] bool isSuccess() const noexcept {
        return transport_ok && status_code >= 200 && status_code < 300;
    }
};

struct HttpRangeProbe {
    bool ok{false};
    bool canceled{false};
    bool accepts_ranges{false};
    int32_t status_code{0};
    int64_t content_length{-1};
    std::string effective_url;
};

enum class RangeFetchStatus : int32_t {
    Ok = 0,
    Canceled = 1,
    ExpiredOrForbidden = 2,
    HttpError = 3,
    NetworkError = 4,
};

struct HttpRangeResult {
    RangeFetchStatus status{RangeFetchStatus::NetworkError};
    int32_t http_status{0};
    int64_t total_size{-1};
    std::vector<uint8_t> data;

    [[nodiscard]] bool isSuccess() const noexcept {
        return status == RangeFetchStatus::Ok;
    }
};

struct HttpStreamResult {
    bool ok{false};
    bool canceled{false};
    int32_t status_code{0};
    int64_t content_length{-1};
    int64_t bytes_received{0};
};

/// Return false from the callback to abort an active transfer immediately.
using StreamChunkCallback = std::function<bool(
    const uint8_t* data,
    size_t len,
    int64_t expected_total_bytes)>;

/// Pure C++ HTTPS client built over libcurl + mbedTLS + Android CA stores.
class NativeHttpClient {
public:
    explicit NativeHttpClient(AuthSessionStore& auth_store);
    ~NativeHttpClient() = default;

    NativeHttpClient(const NativeHttpClient&) = delete;
    NativeHttpClient& operator=(const NativeHttpClient&) = delete;

    [[nodiscard]] static NativeHttpClient& defaultInstance();

    [[nodiscard]] HttpResponse get(
        const std::string& url,
        const std::vector<std::pair<std::string, std::string>>& extra_headers = {},
        int connect_timeout_ms = 8000,
        int read_timeout_ms = 12000,
        bool include_spotify_auth = true) const;

    [[nodiscard]] HttpResponse post(
        const std::string& url,
        const std::vector<uint8_t>& body,
        const std::string& content_type,
        const std::vector<std::pair<std::string, std::string>>& extra_headers = {},
        int connect_timeout_ms = 8000,
        int read_timeout_ms = 15000,
        bool include_spotify_auth = true) const;

    [[nodiscard]] HttpRangeProbe probeRangeLength(
        const std::string& url,
        const std::vector<std::pair<std::string, std::string>>& extra_headers = {},
        const std::atomic<bool>* cancel_flag = nullptr,
        int connect_timeout_ms = 8000,
        int read_timeout_ms = 12000) const;

    [[nodiscard]] HttpRangeResult fetchByteRange(
        const std::string& url,
        int64_t offset,
        size_t length,
        const std::vector<std::pair<std::string, std::string>>& extra_headers = {},
        const std::atomic<bool>* cancel_flag = nullptr,
        int connect_timeout_ms = 8000,
        int read_timeout_ms = 15000) const;

    [[nodiscard]] HttpStreamResult downloadToStream(
        const std::string& url,
        const StreamChunkCallback& on_chunk,
        const std::vector<std::pair<std::string, std::string>>& extra_headers = {},
        const std::atomic<bool>* cancel_flag = nullptr,
        int connect_timeout_ms = 5000,
        int read_timeout_ms = 12000) const;

private:
    [[nodiscard]] HttpResponse executeOnce(
        const std::string& method,
        const std::string& url,
        const std::vector<std::pair<std::string, std::string>>& headers,
        const std::vector<uint8_t>* body,
        int connect_timeout_ms,
        int read_timeout_ms) const;

    [[nodiscard]] HttpResponse executeWithAuthRetry(
        const std::string& method,
        const std::string& url,
        const std::vector<std::pair<std::string, std::string>>& extra_headers,
        const std::vector<uint8_t>* body,
        int connect_timeout_ms,
        int read_timeout_ms,
        bool include_spotify_auth) const;

    AuthSessionStore& auth_store_;
};

} // namespace spotify::network
