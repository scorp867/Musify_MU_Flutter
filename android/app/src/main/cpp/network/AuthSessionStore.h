#pragma once

#include <condition_variable>
#include <cstdint>
#include <functional>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

namespace spotify::network {

enum class AuthRefreshReason : int64_t {
    kAccessToken401 = 1,
    kClientTokenError = 2,
    kDealerWs401 = 3,
};

struct ClientHeaderProfile {
    std::string client_id{"d8a5ed958d274c2e8ee717e6a4b0971d"};
    std::string app_platform{"WebPlayer"};
    std::string app_version{"1.2.87.215.g6e7e7fc2"};
    std::string user_agent{
        "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36"};
    bool send_origin_headers{true};

    [[nodiscard]] static ClientHeaderProfile defaultWebPlayerProfile() {
        return ClientHeaderProfile{};
    }
};

struct AuthCredentials {
    std::string access_token;
    std::string client_token;
    std::string sp_dc;
    std::string country;
    std::string catalogue;
    std::string accept_language;
    std::string cache_dir;
    uint64_t generation{0};

    [[nodiscard]] bool hasAccessToken() const noexcept {
        return !access_token.empty();
    }
};

class AuthSessionStore {
public:
    using SessionListener = std::function<void(const AuthCredentials&)>;
    using VoidSessionListener = std::function<void()>;
    using RefreshRequestCallback = std::function<void(int64_t reason_code)>;

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

    void clearSession();
    void clear_session() { clearSession(); }

    void setAuthRefreshPort(int64_t dart_port);
    void set_refresh_request_callback(RefreshRequestCallback callback);
    void setRefreshRequestCallback(RefreshRequestCallback callback) {
        set_refresh_request_callback(std::move(callback));
    }

    [[nodiscard]] AuthCredentials snapshot() const;

    void set_client_profile(ClientHeaderProfile profile);
    void set_client_profile(const char* client_id,
                            const char* app_platform,
                            const char* app_version,
                            const char* user_agent,
                            bool send_origin_headers);

    void setClientProfile(ClientHeaderProfile profile) {
        set_client_profile(std::move(profile));
    }
    void setClientProfile(const char* client_id,
                          const char* app_platform,
                          const char* app_version,
                          const char* user_agent,
                          bool send_origin_headers) {
        set_client_profile(client_id, app_platform, app_version, user_agent, send_origin_headers);
    }

    [[nodiscard]] ClientHeaderProfile client_profile() const;
    [[nodiscard]] ClientHeaderProfile clientProfile() const {
        return client_profile();
    }

    /// Thread-safe observer registration. Listeners are invoked outside `mutex_`
    /// immediately whenever `updateSession` or `clearSession` mutates credentials.
    uint64_t add_listener(SessionListener listener);
    uint64_t add_listener(VoidSessionListener listener);
    void remove_listener(uint64_t listener_id);

    uint64_t add_session_listener(SessionListener listener) {
        return add_listener(std::move(listener));
    }
    uint64_t add_session_listener(VoidSessionListener listener) {
        return add_listener(std::move(listener));
    }
    void remove_session_listener(uint64_t listener_id) {
        remove_listener(listener_id);
    }

    uint64_t addListener(SessionListener listener) {
        return add_listener(std::move(listener));
    }
    uint64_t addListener(VoidSessionListener listener) {
        return add_listener(std::move(listener));
    }
    void removeListener(uint64_t listener_id) {
        remove_listener(listener_id);
    }

    /// Requests a token refresh via Dart NativePort (or registered callback) with an
    /// explicit `AuthRefreshReason` (`1 = kAccessToken401`, `2 = kClientTokenError`,
    /// `3 = kDealerWs401`) if no newer generation has already arrived, and blocks
    /// up to `timeout_ms` waiting for fresh credentials.
    bool requestTokenRefreshAndWait(uint64_t failed_generation,
                                    AuthRefreshReason reason,
                                    int timeout_ms = 8000);

    /// Backward-compatible overload defaulting to `AuthRefreshReason::kAccessToken401`.
    bool requestTokenRefreshAndWait(uint64_t failed_generation, int timeout_ms = 8000);

private:
    void notify_listeners_unlocked(const AuthCredentials& snapshot_copy,
                                   const std::vector<SessionListener>& listeners) const;

    mutable std::mutex mutex_;
    std::condition_variable cv_;
    AuthCredentials creds_;
    ClientHeaderProfile client_profile_;
    int64_t auth_refresh_port_{0};
    RefreshRequestCallback refresh_request_callback_;
    uint64_t last_requested_generation_{0};
    AuthRefreshReason last_requested_reason_{AuthRefreshReason::kAccessToken401};
    uint64_t next_listener_id_{1};
    std::vector<std::pair<uint64_t, SessionListener>> listeners_;
};

}  // namespace spotify::network
