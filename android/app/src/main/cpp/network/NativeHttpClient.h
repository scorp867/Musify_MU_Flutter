#pragma once

#include "AuthSessionStore.h"

#include <cstdint>
#include <string>
#include <utility>
#include <vector>

namespace spotify::network {

struct HttpResponse {
    int32_t status_code{0};
    std::vector<uint8_t> body;
    bool transport_ok{false};

    [[nodiscard]] bool isSuccess() const noexcept {
        return transport_ok && status_code >= 200 && status_code < 300;
    }
};

class NativeHttpClient {
public:
    explicit NativeHttpClient(AuthSessionStore& auth_store);
    ~NativeHttpClient() = default;

    NativeHttpClient(const NativeHttpClient&) = delete;
    NativeHttpClient& operator=(const NativeHttpClient&) = delete;

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
