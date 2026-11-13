#include "NativeHttpClient.h"

#include <android/log.h>
#include <curl/curl.h>
#include <dirent.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

#include <algorithm>
#include <array>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <mutex>
#include <string>

#define HTTP_LOG_TAG "MusifyNativeHttp"
#define HTTP_LOGI(...) __android_log_print(ANDROID_LOG_INFO, HTTP_LOG_TAG, __VA_ARGS__)
#define HTTP_LOGW(...) __android_log_print(ANDROID_LOG_WARN, HTTP_LOG_TAG, __VA_ARGS__)
#define HTTP_LOGE(...) __android_log_print(ANDROID_LOG_ERROR, HTTP_LOG_TAG, __VA_ARGS__)

namespace spotify::network {

namespace {

constexpr const char* kWebPlayerAppVersion = "1.2.87.215.g6e7e7fc2";
constexpr const char* kWebPlayerUserAgent =
    "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36";

constexpr const char* kApexCaDir = "/apex/com.android.conscrypt/cacerts";
constexpr const char* kSystemCaDir = "/system/etc/security/cacerts";
constexpr const char* kUserAddedCaDir = "/data/misc/user/0/cacerts-added";

void extractPemCertificatesFromFile(const std::string& path,
                                    std::string& out_bundle,
                                    size_t& out_cert_count) {
    const int fd = ::open(path.c_str(), O_RDONLY);
    if (fd < 0) return;

    struct stat st{};
    if (::fstat(fd, &st) != 0 || !S_ISREG(st.st_mode) || st.st_size <= 0 || st.st_size > 262144) {
        ::close(fd);
        return;
    }

    std::string raw(static_cast<size_t>(st.st_size), '\0');
    size_t total_read = 0;
    while (total_read < raw.size()) {
        const ssize_t n = ::read(fd, raw.data() + total_read, raw.size() - total_read);
        if (n <= 0) break;
        total_read += static_cast<size_t>(n);
    }
    ::close(fd);
    raw.resize(total_read);

    static constexpr const char kBeginMarker[] = "-----BEGIN CERTIFICATE-----";
    static constexpr const char kEndMarker[] = "-----END CERTIFICATE-----";
    size_t search_pos = 0;
    while (true) {
        const size_t begin = raw.find(kBeginMarker, search_pos);
        if (begin == std::string::npos) break;
        const size_t end = raw.find(kEndMarker, begin);
        if (end == std::string::npos) break;
        const size_t block_end = end + sizeof(kEndMarker) - 1;
        out_bundle.append(raw, begin, block_end - begin);
        out_bundle.push_back('\n');
        out_cert_count++;
        search_pos = block_end;
    }
}

size_t loadCertificatesFromDirectory(const char* dir_path, std::string& out_bundle) {
    DIR* dir = ::opendir(dir_path);
    if (!dir) return 0;

    size_t loaded = 0;
    while (struct dirent* entry = ::readdir(dir)) {
        if (entry->d_name[0] == '\0' || entry->d_name[0] == '.') continue;
        std::string full_path(dir_path);
        full_path.push_back('/');
        full_path.append(entry->d_name);
        extractPemCertificatesFromFile(full_path, out_bundle, loaded);
    }
    ::closedir(dir);
    return loaded;
}

class CurlEnvironment {
public:
    static CurlEnvironment& instance() {
        static CurlEnvironment env;
        return env;
    }

    CurlEnvironment(const CurlEnvironment&) = delete;
    CurlEnvironment& operator=(const CurlEnvironment&) = delete;

    [[nodiscard]] CURLSH* shareHandle() const noexcept { return share_handle_; }
    [[nodiscard]] const std::string& caPemBundle() const noexcept { return ca_pem_bundle_; }
    [[nodiscard]] const char* fallbackCaDir() const noexcept { return fallback_ca_dir_; }

    CURL* acquireHandle() {
        {
            std::lock_guard<std::mutex> lock(pool_mutex_);
            if (!free_handles_.empty()) {
                CURL* handle = free_handles_.back();
                free_handles_.pop_back();
                applyDefaults(handle);
                return handle;
            }
        }
        CURL* handle = curl_easy_init();
        if (handle) {
            applyDefaults(handle);
        }
        return handle;
    }

    void releaseHandle(CURL* handle, bool reusable) {
        if (!handle) return;
        if (!reusable) {
            curl_easy_cleanup(handle);
            return;
        }
        curl_easy_reset(handle);
        std::lock_guard<std::mutex> lock(pool_mutex_);
        if (shutting_down_ || free_handles_.size() >= kMaxPooledHandles) {
            curl_easy_cleanup(handle);
            return;
        }
        free_handles_.push_back(handle);
    }

    void applyDefaults(CURL* easy) const noexcept {
        curl_easy_setopt(easy, CURLOPT_NOSIGNAL, 1L);
        curl_easy_setopt(easy, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_2TLS);
        curl_easy_setopt(easy, CURLOPT_TCP_KEEPALIVE, 1L);
        curl_easy_setopt(easy, CURLOPT_TCP_NODELAY, 1L);
        curl_easy_setopt(easy, CURLOPT_PIPEWAIT, 1L);
        curl_easy_setopt(easy, CURLOPT_MAXCONNECTS, 10L);
        curl_easy_setopt(easy, CURLOPT_SSL_VERIFYPEER, 1L);
        curl_easy_setopt(easy, CURLOPT_SSL_VERIFYHOST, 2L);
        curl_easy_setopt(easy, CURLOPT_SHARE, share_handle_);

        if (!ca_pem_bundle_.empty()) {
            curl_blob blob{};
            blob.data = const_cast<char*>(ca_pem_bundle_.data());
            blob.len = ca_pem_bundle_.size();
            blob.flags = CURL_BLOB_NOCOPY;
            const CURLcode rc = curl_easy_setopt(easy, CURLOPT_CAINFO_BLOB, &blob);
            if (rc == CURLE_OK) {
                return;
            }
        }
        curl_easy_setopt(easy, CURLOPT_CAPATH, fallback_ca_dir_);
    }

private:
    static constexpr size_t kMaxPooledHandles = 12;
    static void shareLockCallback(CURL* /*handle*/,
                                  curl_lock_data data,
                                  curl_lock_access /*access*/,
                                  void* userptr) {
        auto* self = static_cast<CurlEnvironment*>(userptr);
        const size_t idx = static_cast<size_t>(data) % self->share_mutexes_.size();
        self->share_mutexes_[idx].lock();
    }

    static void shareUnlockCallback(CURL* /*handle*/,
                                    curl_lock_data data,
                                    void* userptr) {
        auto* self = static_cast<CurlEnvironment*>(userptr);
        const size_t idx = static_cast<size_t>(data) % self->share_mutexes_.size();
        self->share_mutexes_[idx].unlock();
    }

    CurlEnvironment() {
        curl_global_init(CURL_GLOBAL_DEFAULT);

        share_handle_ = curl_share_init();
        if (share_handle_) {
            curl_share_setopt(share_handle_, CURLSHOPT_USERDATA, this);
            curl_share_setopt(share_handle_, CURLSHOPT_LOCKFUNC, &CurlEnvironment::shareLockCallback);
            curl_share_setopt(share_handle_, CURLSHOPT_UNLOCKFUNC, &CurlEnvironment::shareUnlockCallback);
            curl_share_setopt(share_handle_, CURLSHOPT_SHARE, CURL_LOCK_DATA_DNS);
            curl_share_setopt(share_handle_, CURLSHOPT_SHARE, CURL_LOCK_DATA_SSL_SESSION);
        }

        ca_pem_bundle_.reserve(320 * 1024);
        size_t system_count = loadCertificatesFromDirectory(kApexCaDir, ca_pem_bundle_);
        if (system_count > 0) {
            fallback_ca_dir_ = kApexCaDir;
        } else {
            system_count = loadCertificatesFromDirectory(kSystemCaDir, ca_pem_bundle_);
            fallback_ca_dir_ = kSystemCaDir;
        }
        const size_t user_count = loadCertificatesFromDirectory(kUserAddedCaDir, ca_pem_bundle_);
        HTTP_LOGI("NativeHttpClient initialized: ca_certs=%zu (user=%zu, bundle_bytes=%zu, fallback_dir=%s)",
                  system_count, user_count, ca_pem_bundle_.size(), fallback_ca_dir_);
    }

    ~CurlEnvironment() {
        {
            std::lock_guard<std::mutex> lock(pool_mutex_);
            shutting_down_ = true;
            for (CURL* h : free_handles_) {
                if (h) curl_easy_cleanup(h);
            }
            free_handles_.clear();
        }
        if (share_handle_) {
            curl_share_cleanup(share_handle_);
            share_handle_ = nullptr;
        }
        curl_global_cleanup();
    }

    CURLSH* share_handle_{nullptr};
    std::array<std::mutex, 8> share_mutexes_{};
    std::mutex pool_mutex_;
    std::vector<CURL*> free_handles_;
    bool shutting_down_{false};
    std::string ca_pem_bundle_;
    const char* fallback_ca_dir_{kSystemCaDir};
};

struct CurlEasyGuard {
    CURL* handle{nullptr};
    bool reusable{false};

    CurlEasyGuard() : handle(CurlEnvironment::instance().acquireHandle()) {}
    ~CurlEasyGuard() {
        CurlEnvironment::instance().releaseHandle(handle, reusable);
    }

    CurlEasyGuard(const CurlEasyGuard&) = delete;
    CurlEasyGuard& operator=(const CurlEasyGuard&) = delete;
};

struct CurlSlistGuard {
    struct curl_slist* list{nullptr};

    ~CurlSlistGuard() {
        if (list) {
            curl_slist_free_all(list);
        }
    }

    void append(const std::string& header_line) {
        list = curl_slist_append(list, header_line.c_str());
    }

    CurlSlistGuard(const CurlSlistGuard&) = delete;
    CurlSlistGuard& operator=(const CurlSlistGuard&) = delete;
    CurlSlistGuard() = default;
};

bool equalsIgnoreCasePrefix(const char* str, size_t len, const char* prefix) noexcept {
    const size_t prefix_len = std::strlen(prefix);
    if (len < prefix_len) return false;
    for (size_t i = 0; i < prefix_len; ++i) {
        if (std::tolower(static_cast<unsigned char>(str[i])) !=
            std::tolower(static_cast<unsigned char>(prefix[i]))) {
            return false;
        }
    }
    return true;
}

std::string trimAsciiWhitespace(const char* data, size_t len) {
    size_t start = 0;
    while (start < len && std::isspace(static_cast<unsigned char>(data[start]))) {
        start++;
    }
    size_t end = len;
    while (end > start && std::isspace(static_cast<unsigned char>(data[end - 1]))) {
        end--;
    }
    return std::string(data + start, end - start);
}

struct ParsedHeaders {
    int64_t content_range_total{-1};
    int64_t content_length{-1};
    bool accepts_ranges{false};
};

size_t headerCollectorCallback(char* buffer, size_t size, size_t nitems, void* userdata) {
    const size_t total = size * nitems;
    auto* parsed = static_cast<ParsedHeaders*>(userdata);
    if (!parsed || total == 0) return total;

    if (equalsIgnoreCasePrefix(buffer, total, "content-range:")) {
        const std::string value = trimAsciiWhitespace(buffer + 14, total - 14);
        const size_t slash = value.rfind('/');
        if (slash != std::string::npos && slash + 1 < value.size()) {
            const char* total_str = value.c_str() + slash + 1;
            if (total_str[0] != '*') {
                char* end_ptr = nullptr;
                const long long val = std::strtoll(total_str, &end_ptr, 10);
                if (end_ptr != total_str && val >= 0) {
                    parsed->content_range_total = static_cast<int64_t>(val);
                }
            }
        }
    } else if (equalsIgnoreCasePrefix(buffer, total, "content-length:")) {
        const std::string value = trimAsciiWhitespace(buffer + 15, total - 15);
        char* end_ptr = nullptr;
        const long long val = std::strtoll(value.c_str(), &end_ptr, 10);
        if (end_ptr != value.c_str() && val >= 0) {
            parsed->content_length = static_cast<int64_t>(val);
        }
    } else if (equalsIgnoreCasePrefix(buffer, total, "accept-ranges:")) {
        const std::string value = trimAsciiWhitespace(buffer + 14, total - 14);
        if (equalsIgnoreCasePrefix(value.c_str(), value.size(), "bytes")) {
            parsed->accepts_ranges = true;
        }
    }

    return total;
}

int cancelProgressCallback(void* clientp,
                           curl_off_t /*dltotal*/,
                           curl_off_t /*dlnow*/,
                           curl_off_t /*ultotal*/,
                           curl_off_t /*ulnow*/) {
    const auto* cancel_flag = static_cast<const std::atomic<bool>*>(clientp);
    if (cancel_flag && cancel_flag->load(std::memory_order_acquire)) {
        return 1;
    }
    return 0;
}

struct VectorWriteContext {
    std::vector<uint8_t>* buffer{nullptr};
    const std::atomic<bool>* cancel_flag{nullptr};
    size_t max_bytes{0}; // 0 means unlimited
};

size_t vectorWriteCallback(char* ptr, size_t size, size_t nmemb, void* userdata) {
    const size_t total = size * nmemb;
    auto* ctx = static_cast<VectorWriteContext*>(userdata);
    if (!ctx) return total;
    if (ctx->cancel_flag && ctx->cancel_flag->load(std::memory_order_acquire)) {
        return 0;
    }
    if (!ctx->buffer || total == 0) return total;

    if (ctx->max_bytes > 0 && ctx->buffer->size() >= ctx->max_bytes) {
        return total;
    }
    size_t to_copy = total;
    if (ctx->max_bytes > 0 && ctx->buffer->size() + to_copy > ctx->max_bytes) {
        to_copy = ctx->max_bytes - ctx->buffer->size();
    }
    const auto* u8 = reinterpret_cast<const uint8_t*>(ptr);
    ctx->buffer->insert(ctx->buffer->end(), u8, u8 + to_copy);
    return total;
}

struct StreamWriteContext {
    CURL* easy{nullptr};
    const StreamChunkCallback* on_chunk{nullptr};
    const std::atomic<bool>* cancel_flag{nullptr};
    int64_t bytes_received{0};
    bool aborted_by_callback{false};
};

size_t streamWriteCallback(char* ptr, size_t size, size_t nmemb, void* userdata) {
    const size_t total = size * nmemb;
    auto* ctx = static_cast<StreamWriteContext*>(userdata);
    if (!ctx) return total;

    if (ctx->cancel_flag && ctx->cancel_flag->load(std::memory_order_acquire)) {
        ctx->aborted_by_callback = true;
        return 0;
    }

    long http_code = 0;
    curl_easy_getinfo(ctx->easy, CURLINFO_RESPONSE_CODE, &http_code);
    if (http_code < 200 || http_code >= 300) {
        return total;
    }

    if (total > 0 && ctx->on_chunk && *ctx->on_chunk) {
        curl_off_t cl = -1;
        curl_easy_getinfo(ctx->easy, CURLINFO_CONTENT_LENGTH_DOWNLOAD_T, &cl);
        const int64_t expected_total = (cl >= 0) ? static_cast<int64_t>(cl) : -1;
        if (!(*ctx->on_chunk)(reinterpret_cast<const uint8_t*>(ptr), total, expected_total)) {
            ctx->aborted_by_callback = true;
            return 0;
        }
        ctx->bytes_received += static_cast<int64_t>(total);
    }

    return total;
}

bool hasHeaderCaseInsensitive(const std::vector<std::pair<std::string, std::string>>& headers,
                              const char* key) {
    const size_t key_len = std::strlen(key);
    for (const auto& kv : headers) {
        if (kv.first.size() == key_len &&
            equalsIgnoreCasePrefix(kv.first.c_str(), kv.first.size(), key)) {
            return true;
        }
    }
    return false;
}

} // namespace

NativeHttpClient::NativeHttpClient(AuthSessionStore& auth_store)
    : auth_store_(auth_store) {
    (void)CurlEnvironment::instance();
}

NativeHttpClient& NativeHttpClient::defaultInstance() {
    static NativeHttpClient instance(AuthSessionStore::instance());
    return instance;
}

HttpResponse NativeHttpClient::get(
    const std::string& url,
    const std::vector<std::pair<std::string, std::string>>& extra_headers,
    int connect_timeout_ms,
    int read_timeout_ms,
    bool include_spotify_auth) const {
    return executeWithAuthRetry(
        "GET",
        url,
        extra_headers,
        nullptr,
        connect_timeout_ms,
        read_timeout_ms,
        include_spotify_auth);
}

HttpResponse NativeHttpClient::post(
    const std::string& url,
    const std::vector<uint8_t>& body,
    const std::string& content_type,
    const std::vector<std::pair<std::string, std::string>>& extra_headers,
    int connect_timeout_ms,
    int read_timeout_ms,
    bool include_spotify_auth) const {
    std::vector<std::pair<std::string, std::string>> merged = extra_headers;
    if (!content_type.empty() && !hasHeaderCaseInsensitive(merged, "Content-Type")) {
        merged.emplace_back("Content-Type", content_type);
    }
    return executeWithAuthRetry(
        "POST",
        url,
        merged,
        &body,
        connect_timeout_ms,
        read_timeout_ms,
        include_spotify_auth);
}

HttpResponse NativeHttpClient::executeWithAuthRetry(
    const std::string& method,
    const std::string& url,
    const std::vector<std::pair<std::string, std::string>>& extra_headers,
    const std::vector<uint8_t>* body,
    int connect_timeout_ms,
    int read_timeout_ms,
    bool include_spotify_auth) const {
    for (int attempt = 0; attempt < 2; ++attempt) {
        const AuthCredentials creds = auth_store_.snapshot();
        std::vector<std::pair<std::string, std::string>> headers;
        headers.reserve(extra_headers.size() + 8);

        if (include_spotify_auth) {
            if (!creds.access_token.empty()) {
                headers.emplace_back("Authorization", "Bearer " + creds.access_token);
            }
            if (!creds.client_token.empty()) {
                headers.emplace_back("client-token", creds.client_token);
            }
            if (!creds.sp_dc.empty()) {
                headers.emplace_back("Cookie", "sp_dc=" + creds.sp_dc);
            }
            headers.emplace_back("app-platform", "WebPlayer");
            headers.emplace_back("spotify-app-version", kWebPlayerAppVersion);
            headers.emplace_back("User-Agent", kWebPlayerUserAgent);
            headers.emplace_back("Origin", "https://open.spotify.com");
            headers.emplace_back("Referer", "https://open.spotify.com/");
            if (!creds.accept_language.empty()) {
                headers.emplace_back("accept-language", creds.accept_language);
            }
        }

        for (const auto& kv : extra_headers) {
            headers.push_back(kv);
        }

        HttpResponse resp = executeOnce(
            method, url, headers, body, connect_timeout_ms, read_timeout_ms);

        if (include_spotify_auth && resp.transport_ok && resp.status_code == 401 && attempt == 0) {
            HTTP_LOGW("HTTP 401 on %s %s; requesting token refresh from Dart",
                      method.c_str(), url.c_str());
            if (auth_store_.requestTokenRefreshAndWait(creds.generation, 8000)) {
                continue;
            }
        }
        return resp;
    }

    return HttpResponse{};
}

HttpResponse NativeHttpClient::executeOnce(
    const std::string& method,
    const std::string& url,
    const std::vector<std::pair<std::string, std::string>>& headers,
    const std::vector<uint8_t>* body,
    int connect_timeout_ms,
    int read_timeout_ms) const {
    HttpResponse out;
    if (url.empty()) return out;

    CurlEasyGuard easy;
    if (!easy.handle) return out;

    curl_easy_setopt(easy.handle, CURLOPT_URL, url.c_str());
    curl_easy_setopt(easy.handle, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(easy.handle, CURLOPT_MAXREDIRS, 8L);
    curl_easy_setopt(easy.handle, CURLOPT_ACCEPT_ENCODING, "gzip, deflate");
    curl_easy_setopt(easy.handle, CURLOPT_CONNECTTIMEOUT_MS, static_cast<long>(std::max(1000, connect_timeout_ms)));
    curl_easy_setopt(easy.handle, CURLOPT_TIMEOUT_MS, static_cast<long>(std::max(2000, connect_timeout_ms + read_timeout_ms)));

    if (method == "POST") {
        curl_easy_setopt(easy.handle, CURLOPT_POST, 1L);
        if (body && !body->empty()) {
            curl_easy_setopt(easy.handle, CURLOPT_POSTFIELDS, body->data());
            curl_easy_setopt(easy.handle, CURLOPT_POSTFIELDSIZE_LARGE, static_cast<curl_off_t>(body->size()));
        } else {
            curl_easy_setopt(easy.handle, CURLOPT_POSTFIELDS, "");
            curl_easy_setopt(easy.handle, CURLOPT_POSTFIELDSIZE_LARGE, static_cast<curl_off_t>(0));
        }
    } else if (method != "GET") {
        curl_easy_setopt(easy.handle, CURLOPT_CUSTOMREQUEST, method.c_str());
    }

    CurlSlistGuard header_list;
    for (const auto& kv : headers) {
        if (!equalsIgnoreCasePrefix(kv.first.c_str(), kv.first.size(), "accept-encoding")) {
            header_list.append(kv.first + ": " + kv.second);
        }
    }
    if (header_list.list) {
        curl_easy_setopt(easy.handle, CURLOPT_HTTPHEADER, header_list.list);
    }

    ParsedHeaders parsed_headers;
    VectorWriteContext write_ctx{&out.body, nullptr, 0};
    curl_easy_setopt(easy.handle, CURLOPT_HEADERFUNCTION, &headerCollectorCallback);
    curl_easy_setopt(easy.handle, CURLOPT_HEADERDATA, &parsed_headers);
    curl_easy_setopt(easy.handle, CURLOPT_WRITEFUNCTION, &vectorWriteCallback);
    curl_easy_setopt(easy.handle, CURLOPT_WRITEDATA, &write_ctx);

    const CURLcode rc = curl_easy_perform(easy.handle);
    if (rc != CURLE_OK) {
        HTTP_LOGW("libcurl %s %s failed: %s (%d)",
                  method.c_str(), url.c_str(), curl_easy_strerror(rc), static_cast<int>(rc));
        out.body.clear();
        return out;
    }
    easy.reusable = true;

    long status_code = 0;
    curl_easy_getinfo(easy.handle, CURLINFO_RESPONSE_CODE, &status_code);
    char* eff_url = nullptr;
    if (curl_easy_getinfo(easy.handle, CURLINFO_EFFECTIVE_URL, &eff_url) == CURLE_OK && eff_url) {
        out.effective_url = eff_url;
    }

    out.status_code = static_cast<int32_t>(status_code);
    out.content_length = parsed_headers.content_length;
    out.accepts_ranges = parsed_headers.accepts_ranges || (status_code == 206);
    out.transport_ok = true;
    return out;
}

HttpRangeProbe NativeHttpClient::probeRangeLength(
    const std::string& url,
    const std::vector<std::pair<std::string, std::string>>& extra_headers,
    const std::atomic<bool>* cancel_flag,
    int connect_timeout_ms,
    int read_timeout_ms) const {
    HttpRangeProbe probe;
    if (url.empty()) return probe;
    if (cancel_flag && cancel_flag->load(std::memory_order_acquire)) {
        probe.canceled = true;
        return probe;
    }

    CurlEasyGuard easy;
    if (!easy.handle) return probe;

    curl_easy_setopt(easy.handle, CURLOPT_URL, url.c_str());
    curl_easy_setopt(easy.handle, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(easy.handle, CURLOPT_MAXREDIRS, 8L);
    curl_easy_setopt(easy.handle, CURLOPT_RANGE, "0-0");
    curl_easy_setopt(easy.handle, CURLOPT_CONNECTTIMEOUT_MS, static_cast<long>(std::max(1000, connect_timeout_ms)));
    curl_easy_setopt(easy.handle, CURLOPT_TIMEOUT_MS, static_cast<long>(std::max(2000, connect_timeout_ms + read_timeout_ms)));
    curl_easy_setopt(easy.handle, CURLOPT_LOW_SPEED_LIMIT, 1L);
    curl_easy_setopt(easy.handle, CURLOPT_LOW_SPEED_TIME, 10L);

    CurlSlistGuard header_list;
    header_list.append("Accept-Encoding: identity");
    if (!hasHeaderCaseInsensitive(extra_headers, "User-Agent")) {
        header_list.append(std::string("User-Agent: ") + kWebPlayerUserAgent);
    }
    for (const auto& kv : extra_headers) {
        if (!equalsIgnoreCasePrefix(kv.first.c_str(), kv.first.size(), "accept-encoding") &&
            !equalsIgnoreCasePrefix(kv.first.c_str(), kv.first.size(), "range")) {
            header_list.append(kv.first + ": " + kv.second);
        }
    }
    curl_easy_setopt(easy.handle, CURLOPT_HTTPHEADER, header_list.list);

    ParsedHeaders parsed_headers;
    std::vector<uint8_t> discard;
    VectorWriteContext write_ctx{&discard, cancel_flag, 1024};
    curl_easy_setopt(easy.handle, CURLOPT_HEADERFUNCTION, &headerCollectorCallback);
    curl_easy_setopt(easy.handle, CURLOPT_HEADERDATA, &parsed_headers);
    curl_easy_setopt(easy.handle, CURLOPT_WRITEFUNCTION, &vectorWriteCallback);
    curl_easy_setopt(easy.handle, CURLOPT_WRITEDATA, &write_ctx);

    if (cancel_flag) {
        curl_easy_setopt(easy.handle, CURLOPT_NOPROGRESS, 0L);
        curl_easy_setopt(easy.handle, CURLOPT_XFERINFOFUNCTION, &cancelProgressCallback);
        curl_easy_setopt(easy.handle, CURLOPT_XFERINFODATA, const_cast<std::atomic<bool>*>(cancel_flag));
    }

    const CURLcode rc = curl_easy_perform(easy.handle);
    if (cancel_flag && cancel_flag->load(std::memory_order_acquire)) {
        probe.canceled = true;
        return probe;
    }
    if (rc != CURLE_OK) {
        HTTP_LOGW("probeRangeLength %s failed: %s (%d)",
                  url.c_str(), curl_easy_strerror(rc), static_cast<int>(rc));
        return probe;
    }
    easy.reusable = true;

    long status_code = 0;
    curl_easy_getinfo(easy.handle, CURLINFO_RESPONSE_CODE, &status_code);
    char* eff_url = nullptr;
    if (curl_easy_getinfo(easy.handle, CURLINFO_EFFECTIVE_URL, &eff_url) == CURLE_OK && eff_url) {
        probe.effective_url = eff_url;
    }

    probe.status_code = static_cast<int32_t>(status_code);
    probe.accepts_ranges = (status_code == 206) || parsed_headers.accepts_ranges;
    if (parsed_headers.content_range_total >= 0) {
        probe.content_length = parsed_headers.content_range_total;
    } else if (status_code == 200 && parsed_headers.content_length >= 0) {
        probe.content_length = parsed_headers.content_length;
    }
    probe.ok = (status_code == 206 || status_code == 200) && probe.content_length > 0;
    return probe;
}

HttpRangeResult NativeHttpClient::fetchByteRange(
    const std::string& url,
    int64_t offset,
    size_t length,
    const std::vector<std::pair<std::string, std::string>>& extra_headers,
    const std::atomic<bool>* cancel_flag,
    int connect_timeout_ms,
    int read_timeout_ms) const {
    HttpRangeResult out;
    if (url.empty() || offset < 0 || length == 0) {
        return out;
    }
    if (cancel_flag && cancel_flag->load(std::memory_order_acquire)) {
        out.status = RangeFetchStatus::Canceled;
        return out;
    }

    CurlEasyGuard easy;
    if (!easy.handle) return out;

    const int64_t end_byte = offset + static_cast<int64_t>(length) - 1;
    char range_buf[64];
    std::snprintf(range_buf, sizeof(range_buf), "%lld-%lld",
                  static_cast<long long>(offset), static_cast<long long>(end_byte));

    curl_easy_setopt(easy.handle, CURLOPT_URL, url.c_str());
    curl_easy_setopt(easy.handle, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(easy.handle, CURLOPT_MAXREDIRS, 8L);
    curl_easy_setopt(easy.handle, CURLOPT_RANGE, range_buf);
    curl_easy_setopt(easy.handle, CURLOPT_CONNECTTIMEOUT_MS, static_cast<long>(std::max(1000, connect_timeout_ms)));
    curl_easy_setopt(easy.handle, CURLOPT_TIMEOUT_MS, static_cast<long>(std::max(2000, connect_timeout_ms + read_timeout_ms)));
    curl_easy_setopt(easy.handle, CURLOPT_LOW_SPEED_LIMIT, 1024L);
    curl_easy_setopt(easy.handle, CURLOPT_LOW_SPEED_TIME, 8L);

    CurlSlistGuard header_list;
    header_list.append("Accept-Encoding: identity");
    if (!hasHeaderCaseInsensitive(extra_headers, "User-Agent")) {
        header_list.append(std::string("User-Agent: ") + kWebPlayerUserAgent);
    }
    for (const auto& kv : extra_headers) {
        if (!equalsIgnoreCasePrefix(kv.first.c_str(), kv.first.size(), "accept-encoding") &&
            !equalsIgnoreCasePrefix(kv.first.c_str(), kv.first.size(), "range")) {
            header_list.append(kv.first + ": " + kv.second);
        }
    }
    curl_easy_setopt(easy.handle, CURLOPT_HTTPHEADER, header_list.list);

    ParsedHeaders parsed_headers;
    std::vector<uint8_t> raw_body;
    raw_body.reserve(length + 256);
    VectorWriteContext write_ctx{&raw_body, cancel_flag, 0};

    curl_easy_setopt(easy.handle, CURLOPT_HEADERFUNCTION, &headerCollectorCallback);
    curl_easy_setopt(easy.handle, CURLOPT_HEADERDATA, &parsed_headers);
    curl_easy_setopt(easy.handle, CURLOPT_WRITEFUNCTION, &vectorWriteCallback);
    curl_easy_setopt(easy.handle, CURLOPT_WRITEDATA, &write_ctx);

    if (cancel_flag) {
        curl_easy_setopt(easy.handle, CURLOPT_NOPROGRESS, 0L);
        curl_easy_setopt(easy.handle, CURLOPT_XFERINFOFUNCTION, &cancelProgressCallback);
        curl_easy_setopt(easy.handle, CURLOPT_XFERINFODATA, const_cast<std::atomic<bool>*>(cancel_flag));
    }

    const CURLcode rc = curl_easy_perform(easy.handle);
    if (cancel_flag && cancel_flag->load(std::memory_order_acquire)) {
        out.status = RangeFetchStatus::Canceled;
        return out;
    }
    if (rc != CURLE_OK) {
        HTTP_LOGW("fetchByteRange(%s, bytes=%s) failed: %s (%d)",
                  url.c_str(), range_buf, curl_easy_strerror(rc), static_cast<int>(rc));
        out.status = (rc == CURLE_ABORTED_BY_CALLBACK)
            ? RangeFetchStatus::Canceled
            : RangeFetchStatus::NetworkError;
        return out;
    }
    easy.reusable = true;

    long status_code = 0;
    curl_easy_getinfo(easy.handle, CURLINFO_RESPONSE_CODE, &status_code);
    out.http_status = static_cast<int32_t>(status_code);
    out.total_size = parsed_headers.content_range_total;

    if (status_code == 206) {
        out.status = RangeFetchStatus::Ok;
        out.data = std::move(raw_body);
        return out;
    }

    if (status_code == 200) {
        // Server ignored Range and returned the full entity.
        if (parsed_headers.content_length >= 0) {
            out.total_size = parsed_headers.content_length;
        }
        const size_t uoffset = static_cast<size_t>(offset);
        if (uoffset < raw_body.size()) {
            const size_t avail = raw_body.size() - uoffset;
            const size_t count = std::min(avail, length);
            out.data.assign(raw_body.begin() + static_cast<ptrdiff_t>(uoffset),
                            raw_body.begin() + static_cast<ptrdiff_t>(uoffset + count));
            out.status = RangeFetchStatus::Ok;
        } else {
            out.status = RangeFetchStatus::Ok;
        }
        return out;
    }

    if (status_code == 416) {
        // Satisfy EOF beyond total length cleanly when Content-Range reports "bytes */total"
        out.status = RangeFetchStatus::Ok;
        return out;
    }

    if (status_code == 401 || status_code == 403 || status_code == 404 || status_code == 410) {
        out.status = RangeFetchStatus::ExpiredOrForbidden;
        return out;
    }

    out.status = RangeFetchStatus::HttpError;
    return out;
}

HttpStreamResult NativeHttpClient::downloadToStream(
    const std::string& url,
    const StreamChunkCallback& on_chunk,
    const std::vector<std::pair<std::string, std::string>>& extra_headers,
    const std::atomic<bool>* cancel_flag,
    int connect_timeout_ms,
    int read_timeout_ms) const {
    HttpStreamResult out;
    if (url.empty()) return out;
    if (cancel_flag && cancel_flag->load(std::memory_order_acquire)) {
        out.canceled = true;
        return out;
    }

    CurlEasyGuard easy;
    if (!easy.handle) return out;

    curl_easy_setopt(easy.handle, CURLOPT_URL, url.c_str());
    curl_easy_setopt(easy.handle, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(easy.handle, CURLOPT_MAXREDIRS, 8L);
    curl_easy_setopt(easy.handle, CURLOPT_CONNECTTIMEOUT_MS, static_cast<long>(std::max(1000, connect_timeout_ms)));
    curl_easy_setopt(easy.handle, CURLOPT_TIMEOUT_MS, static_cast<long>(std::max(2000, connect_timeout_ms + read_timeout_ms)));
    curl_easy_setopt(easy.handle, CURLOPT_LOW_SPEED_LIMIT, 512L);
    curl_easy_setopt(easy.handle, CURLOPT_LOW_SPEED_TIME, 8L);

    CurlSlistGuard header_list;
    header_list.append("Accept-Encoding: identity");
    if (!hasHeaderCaseInsensitive(extra_headers, "User-Agent")) {
        header_list.append("User-Agent: Spotify/8.9.18 Android/34");
    }
    for (const auto& kv : extra_headers) {
        if (!equalsIgnoreCasePrefix(kv.first.c_str(), kv.first.size(), "accept-encoding")) {
            header_list.append(kv.first + ": " + kv.second);
        }
    }
    curl_easy_setopt(easy.handle, CURLOPT_HTTPHEADER, header_list.list);

    ParsedHeaders parsed_headers;
    StreamWriteContext stream_ctx{easy.handle, &on_chunk, cancel_flag, 0, false};

    curl_easy_setopt(easy.handle, CURLOPT_HEADERFUNCTION, &headerCollectorCallback);
    curl_easy_setopt(easy.handle, CURLOPT_HEADERDATA, &parsed_headers);
    curl_easy_setopt(easy.handle, CURLOPT_WRITEFUNCTION, &streamWriteCallback);
    curl_easy_setopt(easy.handle, CURLOPT_WRITEDATA, &stream_ctx);

    if (cancel_flag) {
        curl_easy_setopt(easy.handle, CURLOPT_NOPROGRESS, 0L);
        curl_easy_setopt(easy.handle, CURLOPT_XFERINFOFUNCTION, &cancelProgressCallback);
        curl_easy_setopt(easy.handle, CURLOPT_XFERINFODATA, const_cast<std::atomic<bool>*>(cancel_flag));
    }

    const CURLcode rc = curl_easy_perform(easy.handle);
    if (cancel_flag && cancel_flag->load(std::memory_order_acquire)) {
        out.canceled = true;
        out.bytes_received = stream_ctx.bytes_received;
        return out;
    }

    long status_code = 0;
    curl_easy_getinfo(easy.handle, CURLINFO_RESPONSE_CODE, &status_code);
    out.status_code = static_cast<int32_t>(status_code);
    out.content_length = parsed_headers.content_length;
    out.bytes_received = stream_ctx.bytes_received;

    if (stream_ctx.aborted_by_callback) {
        out.canceled = true;
        return out;
    }
    if (rc != CURLE_OK) {
        HTTP_LOGW("downloadToStream %s failed: %s (%d)",
                  url.c_str(), curl_easy_strerror(rc), static_cast<int>(rc));
        return out;
    }
    easy.reusable = true;

    out.ok = (status_code >= 200 && status_code < 300);
    return out;
}

} // namespace spotify::network
