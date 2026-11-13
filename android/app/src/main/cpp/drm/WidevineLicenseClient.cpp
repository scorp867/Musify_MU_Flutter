#include "WidevineLicenseClient.h"

#include <android/log.h>
#include <cctype>
#include <cstdlib>
#include <thread>

#define WV_LOG_TAG "MusifyWidevineClient"
#define WV_LOGI(...) __android_log_print(ANDROID_LOG_INFO, WV_LOG_TAG, __VA_ARGS__)
#define WV_LOGW(...) __android_log_print(ANDROID_LOG_WARN, WV_LOG_TAG, __VA_ARGS__)
#define WV_LOGE(...) __android_log_print(ANDROID_LOG_ERROR, WV_LOG_TAG, __VA_ARGS__)

namespace spotify::drm {

namespace {
constexpr uint8_t kWidevineUuid[16] = {
    0xed, 0xef, 0x8b, 0xa9, 0x79, 0xd6, 0x4a, 0xce,
    0xa3, 0xc8, 0x27, 0xdc, 0xd5, 0x1d, 0x21, 0xed
};

constexpr const char* kPrimarySpclient = "https://gae2-spclient.spotify.com";
constexpr const char* kFallbackSpclient = "https://spclient.wg.spotify.com";
constexpr const char* kMelodyPath =
    "/melody/v1/license_url?keysystem=com.widevine.alpha&mediatype=audio&sdk_name=harmony&sdk_version=4.81.1";
constexpr const char* kDirectFallbackLicenseUrl =
    "https://gae2-spclient.spotify.com/widevine-license/v1/audio/license";
constexpr int64_t kBaseBackoffMs = 350;

bool isPsshBox(const std::vector<uint8_t>& bytes) noexcept {
    if (bytes.size() < 32) return false;
    return bytes[4] == static_cast<uint8_t>('p') &&
           bytes[5] == static_cast<uint8_t>('s') &&
           bytes[6] == static_cast<uint8_t>('s') &&
           bytes[7] == static_cast<uint8_t>('h');
}

std::vector<uint8_t> wrapInPsshBox(const std::vector<uint8_t>& payload) {
    const uint32_t data_len = static_cast<uint32_t>(payload.size());
    const uint32_t total_size = 32u + data_len;
    std::vector<uint8_t> out;
    out.reserve(total_size);

    out.push_back(static_cast<uint8_t>((total_size >> 24) & 0xFF));
    out.push_back(static_cast<uint8_t>((total_size >> 16) & 0xFF));
    out.push_back(static_cast<uint8_t>((total_size >> 8) & 0xFF));
    out.push_back(static_cast<uint8_t>(total_size & 0xFF));

    out.push_back(static_cast<uint8_t>('p'));
    out.push_back(static_cast<uint8_t>('s'));
    out.push_back(static_cast<uint8_t>('s'));
    out.push_back(static_cast<uint8_t>('h'));

    // Version 0, flags 0
    out.push_back(0x00);
    out.push_back(0x00);
    out.push_back(0x00);
    out.push_back(0x00);

    out.insert(out.end(), kWidevineUuid, kWidevineUuid + 16);

    out.push_back(static_cast<uint8_t>((data_len >> 24) & 0xFF));
    out.push_back(static_cast<uint8_t>((data_len >> 16) & 0xFF));
    out.push_back(static_cast<uint8_t>((data_len >> 8) & 0xFF));
    out.push_back(static_cast<uint8_t>(data_len & 0xFF));

    out.insert(out.end(), payload.begin(), payload.end());
    return out;
}

std::string bytesToHex(const std::vector<uint8_t>& bytes) {
    static constexpr char kHexDigits[] = "0123456789abcdef";
    std::string out;
    out.reserve(bytes.size() * 2);
    for (uint8_t b : bytes) {
        out.push_back(kHexDigits[(b >> 4) & 0x0F]);
        out.push_back(kHexDigits[b & 0x0F]);
    }
    return out;
}

std::string trimAscii(const std::string& s) {
    size_t start = 0;
    while (start < s.size() && std::isspace(static_cast<unsigned char>(s[start]))) {
        ++start;
    }
    size_t end = s.size();
    while (end > start && std::isspace(static_cast<unsigned char>(s[end - 1]))) {
        --end;
    }
    return s.substr(start, end - start);
}

bool startsWithIgnoreCase(const std::string& str, const char* prefix) {
    size_t i = 0;
    while (prefix[i] != '\0') {
        if (i >= str.size()) return false;
        if (std::tolower(static_cast<unsigned char>(str[i])) !=
            std::tolower(static_cast<unsigned char>(prefix[i]))) {
            return false;
        }
        ++i;
    }
    return true;
}

void appendExtraAuthHeaders(
    const std::string& auth_header,
    bool has_store_token,
    std::vector<std::pair<std::string, std::string>>& headers) {
    if (auth_header.empty() || has_store_token) {
        return;
    }
    size_t pos = 0;
    while (pos < auth_header.size()) {
        size_t next = auth_header.find('\n', pos);
        if (next == std::string::npos) {
            next = auth_header.size();
        }
        const std::string line = trimAscii(auth_header.substr(pos, next - pos));
        pos = next + 1;
        if (line.empty()) continue;

        if (startsWithIgnoreCase(line, "client-token:")) {
            const std::string token = trimAscii(line.substr(13));
            if (!token.empty()) {
                headers.emplace_back("client-token", token);
            }
        } else if (startsWithIgnoreCase(line, "authorization:")) {
            std::string val = trimAscii(line.substr(14));
            if (!val.empty()) {
                if (!startsWithIgnoreCase(val, "Bearer ")) {
                    val = "Bearer " + val;
                }
                headers.emplace_back("Authorization", val);
            }
        } else if (startsWithIgnoreCase(line, "Bearer ")) {
            headers.emplace_back("Authorization", line);
        } else if (line.find(':') == std::string::npos) {
            headers.emplace_back("Authorization", "Bearer " + line);
        }
    }
}

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

WidevineLicenseClient::~WidevineLicenseClient() {
    std::lock_guard<std::mutex> lock(drm_mutex_);
    evictAllSessionsLocked();
    if (media_drm_) {
        AMediaDrm_release(media_drm_);
        media_drm_ = nullptr;
    }
}

WidevineLicenseClient& WidevineLicenseClient::defaultInstance() {
    static WidevineLicenseClient s_instance(
        network::AuthSessionStore::instance(),
        network::NativeHttpClient::defaultInstance());
    return s_instance;
}

bool WidevineLicenseClient::ensureMediaDrmLocked() {
    if (media_drm_) {
        return true;
    }
    if (!AMediaDrm_isCryptoSchemeSupported(kWidevineUuid, nullptr)) {
        WV_LOGE("Widevine crypto scheme is not supported on this device");
        return false;
    }
    media_drm_ = AMediaDrm_createByUUID(kWidevineUuid);
    if (!media_drm_) {
        WV_LOGE("AMediaDrm_createByUUID failed for Widevine");
        return false;
    }
    WV_LOGI("Instantiated native NDK AMediaDrm for Widevine");
    return true;
}

void WidevineLicenseClient::closeRawSessionLocked(
    AMediaDrm* drm,
    const std::vector<uint8_t>& session_id) noexcept {
    if (!drm || session_id.empty()) return;
    const AMediaDrmSessionId sid{session_id.data(), session_id.size()};
    (void)AMediaDrm_closeSession(drm, &sid);
}

void WidevineLicenseClient::evictAllSessionsLocked() {
    if (media_drm_) {
        for (const auto& entry : session_lru_) {
            closeRawSessionLocked(media_drm_, entry.session_id);
        }
    }
    session_lru_.clear();
}

void WidevineLicenseClient::putCachedSessionLocked(
    const std::string& key,
    const std::vector<uint8_t>& session_id) {
    for (auto it = session_lru_.begin(); it != session_lru_.end(); ++it) {
        if (it->cache_key == key) {
            if (it->session_id != session_id && media_drm_) {
                closeRawSessionLocked(media_drm_, it->session_id);
            }
            session_lru_.erase(it);
            break;
        }
    }
    session_lru_.push_front(CachedSessionEntry{key, session_id});

    while (session_lru_.size() > kMaxConcurrentSessions) {
        const auto eldest = std::move(session_lru_.back());
        session_lru_.pop_back();
        if (media_drm_) {
            WV_LOGI("LRU pool evicting and closing old AMediaDrm session to free hardware CDM slot");
            closeRawSessionLocked(media_drm_, eldest.session_id);
        }
    }
}

bool WidevineLicenseClient::handleProvisioningLocked() {
    if (!media_drm_) return false;

    const uint8_t* prov_req_ptr = nullptr;
    size_t prov_req_size = 0;
    const char* server_url = nullptr;

    const media_status_t st = AMediaDrm_getProvisionRequest(
        media_drm_,
        &prov_req_ptr,
        &prov_req_size,
        &server_url);
    if (st != AMEDIA_OK || !prov_req_ptr || prov_req_size == 0 || !server_url) {
        WV_LOGE("AMediaDrm_getProvisionRequest failed: status=%d", static_cast<int>(st));
        return false;
    }

    const std::string default_url(server_url);
    const std::vector<uint8_t> req_bytes(prov_req_ptr, prov_req_ptr + prov_req_size);

    const auto resp = executeProvisioningPost(default_url, req_bytes);
    if (!resp.isSuccess() || resp.body.empty()) {
        WV_LOGE("Widevine provisioning HTTP exchange failed");
        return false;
    }

    const media_status_t prov_st = AMediaDrm_provideProvisionResponse(
        media_drm_,
        resp.body.data(),
        resp.body.size());
    if (prov_st != AMEDIA_OK) {
        WV_LOGE("AMediaDrm_provideProvisionResponse failed: status=%d", static_cast<int>(prov_st));
        return false;
    }

    WV_LOGI("Native AMediaDrm device provisioning completed and certificate installed");
    return true;
}

std::vector<uint8_t> WidevineLicenseClient::acquireStreamingSession(
    const std::vector<uint8_t>& pssh_bytes,
    const std::string& license_url,
    const std::string& auth_header,
    int max_retries) {
    if (pssh_bytes.empty()) {
        WV_LOGE("acquireStreamingSession called with empty PSSH bytes");
        return {};
    }

    const std::vector<uint8_t> formatted_pssh =
        isPsshBox(pssh_bytes) ? pssh_bytes : wrapInPsshBox(pssh_bytes);
    const std::string cache_key = bytesToHex(formatted_pssh);

    std::lock_guard<std::mutex> lock(drm_mutex_);
    if (!ensureMediaDrmLocked()) {
        return {};
    }

    // 1. Check LRU session cache and verify session liveness via AMediaDrm_queryKeyStatus.
    for (auto it = session_lru_.begin(); it != session_lru_.end(); ++it) {
        if (it->cache_key == cache_key) {
            const AMediaDrmSessionId cached_sid{it->session_id.data(), it->session_id.size()};
            AMediaDrmKeyValue status_pairs[16]{};
            size_t num_pairs = 16;
            const media_status_t qst =
                AMediaDrm_queryKeyStatus(media_drm_, &cached_sid, status_pairs, &num_pairs);
            if (qst == AMEDIA_OK || qst == AMEDIA_DRM_SHORT_BUFFER) {
                std::vector<uint8_t> hit_id = it->session_id;
                session_lru_.splice(session_lru_.begin(), session_lru_, it);
                WV_LOGI("Native AMediaDrm session cache HIT for track PSSH (0 network calls)");
                return hit_id;
            }
            WV_LOGW("Cached AMediaDrm session no longer valid (status=%d), evicting",
                    static_cast<int>(qst));
            closeRawSessionLocked(media_drm_, it->session_id);
            session_lru_.erase(it);
            break;
        }
    }

    // 2. Open a fresh hardware Widevine session.
    AMediaDrmSessionId raw_sid{nullptr, 0};
    media_status_t open_st = AMediaDrm_openSession(media_drm_, &raw_sid);
    if (open_st == AMEDIA_DRM_NOT_PROVISIONED) {
        WV_LOGW("Device not provisioned for Widevine, executing native provisioning...");
        if (handleProvisioningLocked()) {
            open_st = AMediaDrm_openSession(media_drm_, &raw_sid);
        }
    } else if (open_st == AMEDIA_DRM_RESOURCE_BUSY) {
        WV_LOGW("AMediaDrm resource busy, evicting cached sessions and retrying...");
        evictAllSessionsLocked();
        open_st = AMediaDrm_openSession(media_drm_, &raw_sid);
        if (open_st != AMEDIA_OK) {
            AMediaDrm_release(media_drm_);
            media_drm_ = nullptr;
            if (ensureMediaDrmLocked()) {
                open_st = AMediaDrm_openSession(media_drm_, &raw_sid);
            }
        }
    }

    if (open_st != AMEDIA_OK || !raw_sid.ptr || raw_sid.length == 0) {
        WV_LOGE("AMediaDrm_openSession failed: status=%d", static_cast<int>(open_st));
        return {};
    }

    std::vector<uint8_t> session_id(raw_sid.ptr, raw_sid.ptr + raw_sid.length);
    const AMediaDrmSessionId sid{session_id.data(), session_id.size()};

    // 3. Generate Widevine streaming key request challenge.
    const uint8_t* key_req_ptr = nullptr;
    size_t key_req_size = 0;
    media_status_t kr_st = AMediaDrm_getKeyRequest(
        media_drm_,
        &sid,
        formatted_pssh.data(),
        formatted_pssh.size(),
        "audio/mp4",
        KEY_TYPE_STREAMING,
        nullptr,
        0,
        &key_req_ptr,
        &key_req_size);
    if (kr_st == AMEDIA_DRM_NOT_PROVISIONED) {
        WV_LOGW("AMediaDrm_getKeyRequest returned NOT_PROVISIONED, provisioning and retrying...");
        if (handleProvisioningLocked()) {
            kr_st = AMediaDrm_getKeyRequest(
                media_drm_,
                &sid,
                formatted_pssh.data(),
                formatted_pssh.size(),
                "audio/mp4",
                KEY_TYPE_STREAMING,
                nullptr,
                0,
                &key_req_ptr,
                &key_req_size);
        }
    }

    if (kr_st != AMEDIA_OK || !key_req_ptr || key_req_size == 0) {
        WV_LOGE("AMediaDrm_getKeyRequest failed: status=%d", static_cast<int>(kr_st));
        closeRawSessionLocked(media_drm_, session_id);
        return {};
    }

    const std::vector<uint8_t> challenge(key_req_ptr, key_req_ptr + key_req_size);

    // 4. Execute license POST over C++ libcurl + mbedTLS with retry/backoff.
    const int attempts_allowed = max_retries > 0 ? max_retries : 1;
    network::HttpResponse license_resp;
    int64_t delay_ms = kBaseBackoffMs;
    for (int attempt = 1; attempt <= attempts_allowed; ++attempt) {
        license_resp = executeLicensePost(license_url, auth_header, challenge);
        if (license_resp.isSuccess() && !license_resp.body.empty()) {
            break;
        }
        if (license_resp.status_code == 429) {
            WV_LOGE("Widevine license server returned HTTP 429; aborting retries immediately");
            break;
        }
        if (attempt < attempts_allowed) {
            std::this_thread::sleep_for(std::chrono::milliseconds(delay_ms));
            delay_ms *= 2;
        }
    }

    if (!license_resp.isSuccess() || license_resp.body.empty()) {
        WV_LOGE("Widevine license exchange failed after retries");
        closeRawSessionLocked(media_drm_, session_id);
        return {};
    }

    // 5. Provide license response to hardware CDM.
    AMediaDrmKeySetId key_set_id{nullptr, 0};
    const media_status_t pkr_st = AMediaDrm_provideKeyResponse(
        media_drm_,
        &sid,
        license_resp.body.data(),
        license_resp.body.size(),
        &key_set_id);
    if (pkr_st != AMEDIA_OK) {
        WV_LOGE("AMediaDrm_provideKeyResponse failed: status=%d", static_cast<int>(pkr_st));
        closeRawSessionLocked(media_drm_, session_id);
        return {};
    }

    WV_LOGI("Widevine license installed natively via AMediaDrm + C++ HTTP/2 stack");
    putCachedSessionLocked(cache_key, session_id);
    return session_id;
}

void WidevineLicenseClient::closeSession(const std::vector<uint8_t>& session_id) {
    if (session_id.empty()) return;
    std::lock_guard<std::mutex> lock(drm_mutex_);
    for (auto it = session_lru_.begin(); it != session_lru_.end(); ++it) {
        if (it->session_id == session_id) {
            session_lru_.erase(it);
            break;
        }
    }
    if (media_drm_) {
        closeRawSessionLocked(media_drm_, session_id);
        WV_LOGI("AMediaDrm session explicitly closed");
    }
}

void WidevineLicenseClient::closeAllSessions() {
    std::lock_guard<std::mutex> lock(drm_mutex_);
    evictAllSessionsLocked();
}

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

network::HttpResponse WidevineLicenseClient::executeLicensePost(
    const std::string& license_url,
    const std::string& auth_header,
    const std::vector<uint8_t>& challenge) const {
    const std::string target_url =
        license_url.empty() ? std::string(kDirectFallbackLicenseUrl) : license_url;

    const auto creds = auth_store_.snapshot();
    const bool has_store_token = !creds.access_token.empty();

    std::vector<std::pair<std::string, std::string>> headers = {
        {"Accept", "*/*"},
        {"Origin", "https://open.spotify.com"},
        {"Referer", "https://open.spotify.com/"},
        {"Sec-Fetch-Dest", "empty"},
        {"Sec-Fetch-Mode", "cors"},
        {"Sec-Fetch-Site", "same-site"},
        {"Priority", "u=4"},
        {"TE", "trailers"},
    };
    appendExtraAuthHeaders(auth_header, has_store_token, headers);

    WV_LOGI("Executing native C++ Widevine license POST: url=%s challenge=%zu bytes",
            target_url.c_str(), challenge.size());

    auto resp = http_client_.post(
        target_url,
        challenge,
        "application/octet-stream",
        headers,
        6000,
        10000,
        has_store_token);

    if (!resp.isSuccess()) {
        WV_LOGE("Widevine license POST failed: status=%d transport_ok=%d body_len=%zu",
                resp.status_code, resp.transport_ok ? 1 : 0, resp.body.size());
    } else {
        WV_LOGI("Widevine license POST succeeded: status=%d response=%zu bytes",
                resp.status_code, resp.body.size());
    }
    return resp;
}

network::HttpResponse WidevineLicenseClient::executeProvisioningPost(
    const std::string& provisioning_url,
    const std::vector<uint8_t>& request_data) const {
    if (provisioning_url.empty()) {
        return network::HttpResponse{};
    }

    const std::string signed_request(
        reinterpret_cast<const char*>(request_data.data()), request_data.size());
    const char sep = (provisioning_url.find('?') != std::string::npos) ? '&' : '?';
    const std::string full_url = provisioning_url + sep + "signedRequest=" + signed_request;

    WV_LOGI("Executing native C++ Widevine provisioning POST: %s", full_url.c_str());

    const std::vector<uint8_t> empty_body;
    const std::vector<std::pair<std::string, std::string>> headers = {
        {"Accept", "*/*"},
    };

    auto resp = http_client_.post(
        full_url,
        empty_body,
        "application/octet-stream",
        headers,
        8000,
        12000,
        false);

    if (!resp.isSuccess()) {
        WV_LOGE("Widevine provisioning POST failed: status=%d transport_ok=%d",
                resp.status_code, resp.transport_ok ? 1 : 0);
    } else {
        WV_LOGI("Widevine provisioning POST succeeded: status=%d bytes=%zu",
                resp.status_code, resp.body.size());
    }
    return resp;
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
