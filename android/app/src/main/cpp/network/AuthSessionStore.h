#pragma once

#include <condition_variable>
#include <cstdint>
#include <mutex>
#include <string>

namespace spotify::network {

struct AuthCredentials {
    std::string access_token;
    std::string client_token;
    std::string sp_dc;
    std::string country;
    std::string catalogue;
    std::string accept_language;
    std::string cache_dir;
    uint64_t generation{0};
};

class AuthSessionStore {
public:
    AuthSessionStore() = default;
    ~AuthSessionStore() = default;

    AuthSessionStore(const AuthSessionStore&) = delete;
    AuthSessionStore& operator=(const AuthSessionStore&) = delete;

    static AuthSessionStore& instance();

    void updateSession(const char* access_token,
                       const char* client_token,
                       const char* sp_dc,
                       const char* country,
                       const char* catalogue,
                       const char* accept_language,
                       const char* cache_dir);

    void setAuthRefreshPort(int64_t dart_port);

    [[nodiscard]] AuthCredentials snapshot() const;

    /// Requests a token refresh via Dart NativePort if no newer generation has already
    /// arrived, and blocks up to `timeout_ms` waiting for fresh credentials.
    bool requestTokenRefreshAndWait(uint64_t failed_generation, int timeout_ms = 8000);

private:
    mutable std::mutex mutex_;
    std::condition_variable cv_;
    AuthCredentials creds_;
    int64_t auth_refresh_port_{0};
    uint64_t last_requested_generation_{0};
};

} // namespace spotify::network
