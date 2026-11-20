#include "AuthSessionStore.h"

#include "NativeLog.h"
#include "dart_api_dl.h"

#include <algorithm>
#include <chrono>

namespace spotify::network {

namespace {

constexpr const char* kDefaultWebPlayerClientId = "d8a5ed958d274c2e8ee717e6a4b0971d";
constexpr const char* kDefaultWebPlayerPlatform = "WebPlayer";
constexpr const char* kDefaultWebPlayerVersion = "1.2.87.215.g6e7e7fc2";
constexpr const char* kDefaultWebPlayerUserAgent =
    "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36";

const char* refresh_reason_name(AuthRefreshReason reason) noexcept {
    switch (reason) {
        case AuthRefreshReason::kAccessToken401:
            return "access_token_401";
        case AuthRefreshReason::kClientTokenError:
            return "client_token_error";
        case AuthRefreshReason::kDealerWs401:
            return "dealer_ws_401";
    }
    return "unknown";
}

}  // namespace

AuthSessionStore& AuthSessionStore::instance() {
    static AuthSessionStore s_instance;
    return s_instance;
}

void AuthSessionStore::updateSession(const char* access_token,
                                     const char* client_token,
                                     const char* sp_dc,
                                     const char* country,
                                     const char* catalogue,
                                     const char* accept_language,
                                     const char* cache_dir) {
    AuthCredentials snapshot_copy;
    std::vector<SessionListener> listeners_copy;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (access_token) creds_.access_token = access_token;
        if (client_token) creds_.client_token = client_token;
        if (sp_dc) creds_.sp_dc = sp_dc;
        if (country && country[0] != '\0') creds_.country = country;
        if (catalogue && catalogue[0] != '\0') creds_.catalogue = catalogue;
        if (accept_language && accept_language[0] != '\0') creds_.accept_language = accept_language;
        if (cache_dir && cache_dir[0] != '\0') creds_.cache_dir = cache_dir;

        if (creds_.country.empty()) creds_.country = "US";
        if (creds_.catalogue.empty()) creds_.catalogue = "free";
        if (creds_.accept_language.empty()) creds_.accept_language = "en";

        creds_.generation += 1;
        snapshot_copy = creds_;

        listeners_copy.reserve(listeners_.size());
        for (const auto& entry : listeners_) {
            if (entry.second) {
                listeners_copy.push_back(entry.second);
            }
        }
    }

    NET_LOGI("AuthSessionStore updated (gen=%llu, catalogue=%s, country=%s, accessTokenLen=%zu, clientTokenLen=%zu)",
             static_cast<unsigned long long>(snapshot_copy.generation),
             snapshot_copy.catalogue.c_str(),
             snapshot_copy.country.c_str(),
             snapshot_copy.access_token.size(),
             snapshot_copy.client_token.size());

    cv_.notify_all();
    notify_listeners_unlocked(snapshot_copy, listeners_copy);
}

void AuthSessionStore::clearSession() {
    AuthCredentials snapshot_copy;
    std::vector<SessionListener> listeners_copy;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        creds_.access_token.clear();
        creds_.client_token.clear();
        creds_.sp_dc.clear();
        creds_.generation += 1;
        snapshot_copy = creds_;

        listeners_copy.reserve(listeners_.size());
        for (const auto& entry : listeners_) {
            if (entry.second) {
                listeners_copy.push_back(entry.second);
            }
        }
    }

    NET_LOGI("AuthSessionStore cleared (gen=%llu)",
             static_cast<unsigned long long>(snapshot_copy.generation));

    cv_.notify_all();
    notify_listeners_unlocked(snapshot_copy, listeners_copy);
}

void AuthSessionStore::setAuthRefreshPort(int64_t dart_port) {
    std::lock_guard<std::mutex> lock(mutex_);
    auth_refresh_port_ = dart_port;
}

void AuthSessionStore::set_refresh_request_callback(RefreshRequestCallback callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    refresh_request_callback_ = std::move(callback);
}

AuthCredentials AuthSessionStore::snapshot() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return creds_;
}

void AuthSessionStore::set_client_profile(ClientHeaderProfile profile) {
    if (profile.client_id.empty()) {
        profile.client_id = kDefaultWebPlayerClientId;
    }
    if (profile.app_platform.empty()) {
        profile.app_platform =
            profile.send_origin_headers ? kDefaultWebPlayerPlatform : "Android";
    }
    if (profile.app_version.empty()) {
        profile.app_version =
            profile.send_origin_headers ? kDefaultWebPlayerVersion : "8.9.18";
    }
    if (profile.user_agent.empty()) {
        profile.user_agent =
            profile.send_origin_headers ? kDefaultWebPlayerUserAgent : "Spotify/8.9.18 Android/34";
    }

    {
        std::lock_guard<std::mutex> lock(mutex_);
        client_profile_ = std::move(profile);
        NET_LOGI("ClientHeaderProfile updated (platform=%s, version=%s, send_origin=%d, client_id_len=%zu)",
                 client_profile_.app_platform.c_str(),
                 client_profile_.app_version.c_str(),
                 client_profile_.send_origin_headers ? 1 : 0,
                 client_profile_.client_id.size());
    }
}

void AuthSessionStore::set_client_profile(const char* client_id,
                                          const char* app_platform,
                                          const char* app_version,
                                          const char* user_agent,
                                          bool send_origin_headers) {
    ClientHeaderProfile profile;
    profile.send_origin_headers = send_origin_headers;
    profile.client_id =
        (client_id && client_id[0] != '\0') ? client_id : kDefaultWebPlayerClientId;
    profile.app_platform =
        (app_platform && app_platform[0] != '\0')
            ? app_platform
            : (send_origin_headers ? kDefaultWebPlayerPlatform : "Android");
    profile.app_version =
        (app_version && app_version[0] != '\0')
            ? app_version
            : (send_origin_headers ? kDefaultWebPlayerVersion : "8.9.18");
    profile.user_agent =
        (user_agent && user_agent[0] != '\0')
            ? user_agent
            : (send_origin_headers ? kDefaultWebPlayerUserAgent : "Spotify/8.9.18 Android/34");
    set_client_profile(std::move(profile));
}

ClientHeaderProfile AuthSessionStore::client_profile() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return client_profile_;
}

uint64_t AuthSessionStore::add_listener(SessionListener listener) {
    if (!listener) {
        return 0;
    }
    std::lock_guard<std::mutex> lock(mutex_);
    const uint64_t id = next_listener_id_++;
    listeners_.emplace_back(id, std::move(listener));
    return id;
}

uint64_t AuthSessionStore::add_listener(VoidSessionListener listener) {
    if (!listener) {
        return 0;
    }
    return add_listener([cb = std::move(listener)](const AuthCredentials& /*creds*/) {
        cb();
    });
}

void AuthSessionStore::remove_listener(uint64_t listener_id) {
    if (listener_id == 0) {
        return;
    }
    std::lock_guard<std::mutex> lock(mutex_);
    listeners_.erase(
        std::remove_if(
            listeners_.begin(),
            listeners_.end(),
            [listener_id](const auto& entry) { return entry.first == listener_id; }),
        listeners_.end());
}

void AuthSessionStore::notify_listeners_unlocked(
    const AuthCredentials& snapshot_copy,
    const std::vector<SessionListener>& listeners) const {
    for (const auto& listener : listeners) {
        if (listener) {
            listener(snapshot_copy);
        }
    }
}

bool AuthSessionStore::requestTokenRefreshAndWait(uint64_t failed_generation, int timeout_ms) {
    return requestTokenRefreshAndWait(
        failed_generation,
        AuthRefreshReason::kAccessToken401,
        timeout_ms);
}

bool AuthSessionStore::requestTokenRefreshAndWait(uint64_t failed_generation,
                                                  AuthRefreshReason reason,
                                                  int timeout_ms) {
    int64_t port_to_signal = 0;
    RefreshRequestCallback callback_to_invoke;
    {
        std::unique_lock<std::mutex> lock(mutex_);
        const bool already_refreshed =
            (creds_.generation > failed_generation) &&
            !creds_.access_token.empty() &&
            (reason != AuthRefreshReason::kClientTokenError || !creds_.client_token.empty());
        if (already_refreshed) {
            return true;
        }

        const bool has_port = (auth_refresh_port_ != 0 && Dart_PostCObject_DL != nullptr);
        const bool has_callback = static_cast<bool>(refresh_request_callback_);
        if (!has_port && !has_callback) {
            NET_LOGW("Cannot refresh token (%s, code=%lld): neither auth_refresh_port nor callback configured",
                     refresh_reason_name(reason),
                     static_cast<long long>(reason));
            return false;
        }

        if (last_requested_generation_ < creds_.generation + 1 ||
            last_requested_reason_ != reason) {
            last_requested_generation_ = creds_.generation + 1;
            last_requested_reason_ = reason;
            if (has_callback) {
                callback_to_invoke = refresh_request_callback_;
            } else {
                port_to_signal = auth_refresh_port_;
            }
        }
    }

    const int64_t reason_code = static_cast<int64_t>(reason);
    if (callback_to_invoke) {
        callback_to_invoke(reason_code);
        NET_LOGI("Invoked auth refresh callback (reason=%s, code=%lld, failedGen=%llu)",
                 refresh_reason_name(reason),
                 static_cast<long long>(reason_code),
                 static_cast<unsigned long long>(failed_generation));
    } else if (port_to_signal != 0) {
        Dart_CObject msg;
        msg.type = Dart_CObject_kInt64;
        msg.value.as_int64 = reason_code;
        Dart_PostCObject_DL(port_to_signal, &msg);
        NET_LOGI("Posted auth refresh signal to Dart (reason=%s, code=%lld, failedGen=%llu)",
                 refresh_reason_name(reason),
                 static_cast<long long>(reason_code),
                 static_cast<unsigned long long>(failed_generation));
    }

    std::unique_lock<std::mutex> lock(mutex_);
    const bool updated = cv_.wait_for(
        lock,
        std::chrono::milliseconds(std::max(100, timeout_ms)),
        [this, failed_generation, reason]() {
            if (creds_.generation <= failed_generation || creds_.access_token.empty()) {
                return false;
            }
            if (reason == AuthRefreshReason::kClientTokenError && creds_.client_token.empty()) {
                return false;
            }
            return true;
        });

    if (!updated) {
        NET_LOGW("Timed out waiting for refreshed auth session (reason=%s, code=%lld, failedGen=%llu)",
                 refresh_reason_name(reason),
                 static_cast<long long>(reason_code),
                 static_cast<unsigned long long>(failed_generation));
    }
    return updated;
}

}  // namespace spotify::network
