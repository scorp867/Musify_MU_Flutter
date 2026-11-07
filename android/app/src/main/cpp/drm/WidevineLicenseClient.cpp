#include "WidevineLicenseClient.h"

#include <android/log.h>
#include <cstdlib>

#define WV_LOG_TAG "MusifyWidevineClient"
#define WV_LOGI(...) __android_log_print(ANDROID_LOG_INFO, WV_LOG_TAG, __VA_ARGS__)
#define WV_LOGW(...) __android_log_print(ANDROID_LOG_WARN, WV_LOG_TAG, __VA_ARGS__)

namespace spotify::drm {

namespace {
constexpr const char* kPrimarySpclient = "https://gae2-spclient.spotify.com";
constexpr const char* kFallbackSpclient = "https://spclient.wg.spotify.com";
constexpr const char* kMelodyPath =
    "/melody/v1/license_url?keysystem=com.widevine.alpha&mediatype=audio&sdk_name=harmony&sdk_version=4.81.1";
constexpr const char* kDirectFallbackLicenseUrl =
    "https://gae2-spclient.spotify.com/widevine-license/v1/audio/license";

std::string extractJsonStringField(const std::string& json, const char* field_name) {
    const std::string needle = std::string("\"") + field_name + "\"";
    const size_t key_pos = json.find(needle);
    if (key_pos == std::string::npos) return {};
    const size_t colon_pos = json.find(':', key_pos + needle.size());
    if (colon_pos == std::string::npos) return {};
    const size_t q1 = json.find('"', colon_pos + 1);
    if (q1 == std::string::npos) return {};
    std::string out;
    for (size_t i = q1 + 1; i < json.size(); ++i) {
        if (json[i] == '\\' && i + 1 < json.size()) {
            out.push_back(json[i + 1]);
            ++i;
            continue;
        }
        if (json[i] == '"') break;
        out.push_back(json[i]);
    }
    return out;
}

int64_t extractJsonIntField(const std::string& json, const char* field_name, int64_t fallback_val) {
    const std::string needle = std::string("\"") + field_name + "\"";
    const size_t key_pos = json.find(needle);
    if (key_pos == std::string::npos) return fallback_val;
    const size_t colon_pos = json.find(':', key_pos + needle.size());
    if (colon_pos == std::string::npos) return fallback_val;
    size_t i = colon_pos + 1;
    while (i < json.size() && (json[i] == ' ' || json[i] == '\t' || json[i] == '\n' || json[i] == '\r')) {
        ++i;
    }
    if (i >= json.size()) return fallback_val;
    char* end_ptr = nullptr;
    const long long parsed = std::strtoll(json.c_str() + i, &end_ptr, 10);
    if (end_ptr == json.c_str() + i) return fallback_val;
    return static_cast<int64_t>(parsed);
}
} // namespace

WidevineLicenseClient::WidevineLicenseClient(
    network::AuthSessionStore& auth_store,
    network::NativeHttpClient& http_client)
    : auth_store_(auth_store),
      http_client_(http_client) {}

WidevineLicenseContext WidevineLicenseClient::resolveLicenseContext() {
    WidevineLicenseContext ctx;
    ctx.license_url = resolveLicenseUrl();

    const auto creds = auth_store_.snapshot();
    if (!creds.access_token.empty()) {
        ctx.auth_header = "Authorization: Bearer " + creds.access_token;
        if (!creds.client_token.empty()) {
            ctx.auth_header += "\r\nclient-token: " + creds.client_token;
        }
    }
    return ctx;
}

std::string WidevineLicenseClient::resolveLicenseUrl() {
    const auto now = std::chrono::steady_clock::now();
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!cached_url_.empty() && expires_at_ > now) {
            return cached_url_;
        }
    }

    const char* hosts[2] = {kPrimarySpclient, kFallbackSpclient};
    for (const char* host : hosts) {
        const std::string req_url = std::string(host) + kMelodyPath;
        const auto resp = http_client_.get(
            req_url,
            {{"Accept", "application/json"}},
            6000,
            10000,
            true);

        if (!resp.isSuccess() || resp.body.empty()) {
            WV_LOGW("melody license_url HTTP %d from %s", resp.status_code, host);
            continue;
        }

        const std::string json(reinterpret_cast<const char*>(resp.body.data()), resp.body.size());
        std::string uri = extractJsonStringField(json, "uri");
        if (uri.empty()) continue;

        if (uri.rfind("hm://", 0) == 0) {
            uri = uri.substr(5);
        }
        if (uri.rfind("https://widevine-license", 0) == 0) {
            uri = uri.substr(std::string("https://").size());
        } else if (uri.rfind("http://widevine-license", 0) == 0) {
            uri = uri.substr(std::string("http://").size());
        }

        if (uri.rfind("http://", 0) != 0 && uri.rfind("https://", 0) != 0) {
            if (!uri.empty() && uri[0] == '/') {
                uri = std::string(host) + uri;
            } else {
                uri = std::string(host) + "/" + uri;
            }
        }

        int64_t ttl_secs = extractJsonIntField(json, "expires", 300);
        if (ttl_secs < 60) ttl_secs = 60;
        if (ttl_secs > 3600) ttl_secs = 3600;
        const int64_t safe_ttl = ttl_secs > 90 ? (ttl_secs - 30) : ttl_secs;

        {
            std::lock_guard<std::mutex> lock(mutex_);
            cached_url_ = uri;
            expires_at_ = std::chrono::steady_clock::now() + std::chrono::seconds(safe_ttl);
        }
        WV_LOGI("Resolved Widevine license URL: %s (ttl=%llds)",
                uri.c_str(), static_cast<long long>(safe_ttl));
        return uri;
    }

    WV_LOGW("Falling back to direct Widevine license endpoint");
    return kDirectFallbackLicenseUrl;
}

} // namespace spotify::drm
