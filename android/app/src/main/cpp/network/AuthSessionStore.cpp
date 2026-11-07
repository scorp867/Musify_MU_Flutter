#include "AuthSessionStore.h"

#include "dart_api_dl.h"

#include <android/log.h>
#include <chrono>

#define AUTH_LOG_TAG "MusifyAuthStore"
#define AUTH_LOGI(...) __android_log_print(ANDROID_LOG_INFO, AUTH_LOG_TAG, __VA_ARGS__)
#define AUTH_LOGW(...) __android_log_print(ANDROID_LOG_WARN, AUTH_LOG_TAG, __VA_ARGS__)

namespace spotify::network {

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
        AUTH_LOGI("Session updated (gen=%llu, catalogue=%s, country=%s, tokenLen=%zu)",
                  static_cast<unsigned long long>(creds_.generation),
                  creds_.catalogue.c_str(),
                  creds_.country.c_str(),
                  creds_.access_token.size());
    }
    cv_.notify_all();
}

void AuthSessionStore::setAuthRefreshPort(int64_t dart_port) {
    std::lock_guard<std::mutex> lock(mutex_);
    auth_refresh_port_ = dart_port;
}

AuthCredentials AuthSessionStore::snapshot() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return creds_;
}

bool AuthSessionStore::requestTokenRefreshAndWait(uint64_t failed_generation, int timeout_ms) {
    int64_t port_to_signal = 0;
    {
        std::unique_lock<std::mutex> lock(mutex_);
        if (creds_.generation > failed_generation && !creds_.access_token.empty()) {
            return true;
        }
        if (auth_refresh_port_ == 0 || !Dart_PostCObject_DL) {
            AUTH_LOGW("Cannot refresh token on 401: auth_refresh_port not configured");
            return false;
        }
        if (last_requested_generation_ < creds_.generation + 1) {
            last_requested_generation_ = creds_.generation + 1;
            port_to_signal = auth_refresh_port_;
        }
    }

    if (port_to_signal != 0) {
        Dart_CObject msg;
        msg.type = Dart_CObject_kInt64;
        msg.value.as_int64 = static_cast<int64_t>(failed_generation);
        Dart_PostCObject_DL(port_to_signal, &msg);
        AUTH_LOGI("Posted 401 token refresh signal to Dart (failedGen=%llu)",
                  static_cast<unsigned long long>(failed_generation));
    }

    std::unique_lock<std::mutex> lock(mutex_);
    const bool updated = cv_.wait_for(
        lock,
        std::chrono::milliseconds(timeout_ms),
        [this, failed_generation]() {
            return creds_.generation > failed_generation && !creds_.access_token.empty();
        });
    if (!updated) {
        AUTH_LOGW("Timed out waiting for refreshed auth session (failedGen=%llu)",
                  static_cast<unsigned long long>(failed_generation));
    }
    return updated;
}

} // namespace spotify::network
