// ============================================================================
// 1:1 Replicated Spotify Native HTTP Client (libcurl + mbedTLS + Android CA)
// Sources:
// - `liborbit-jni-spotify.so` offsets 0x35a175, 0x378272 ("connect-state/v1/devices/")
// - `liborbit-jni-spotify.so` offsets 0x44b598 ("POST"), 0x44b5b0 ("DELETE"), 0x44b5c8 ("PUT")
// - `liborbit-jni-spotify.so` offsets 0x3e1028 ("grpc-status"), 0x38bcd4 ("Retry-After")
// - `liborbit-jni-spotify.so` offset 0x39c1c3 ("X-Spotify-Connection-Id")
// ============================================================================

#include "NativeHttpClient.h"

#include <android/log.h>
#include <arpa/inet.h>
#include <curl/curl.h>
#include <dirent.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <sys/socket.h>
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
    const int fd = ::open(path.c_str(), O_RDONLY | O_CLOEXEC);
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
        curl_easy_setopt(easy, CURLOPT_MAXCONNECTS, 12L);
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
    static constexpr size_t kMaxPooledHandles = 16;

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
            curl_share_setopt(share_handle_, CURLSHOPT_SHARE, CURL_LOCK_DATA_CONNECT);
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
    std::array<std::mutex, 16> share_mutexes_{};
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
    std::vector<std::pair<std::string, std::string>> headers;
};

size_t headerCollectorCallback(char* buffer, size_t size, size_t nitems, void* userdata) {
    const size_t total = size * nitems;
    auto* parsed = static_cast<ParsedHeaders*>(userdata);
    if (!parsed || total == 0) return total;

    if (equalsIgnoreCasePrefix(buffer, total, "HTTP/")) {
        parsed->content_range_total = -1;
        parsed->content_length = -1;
        parsed->accepts_ranges = false;
        parsed->headers.clear();
        return total;
    }

    const void* colon_ptr = std::memchr(buffer, ':', total);
    if (colon_ptr != nullptr) {
        const size_t colon_idx = static_cast<const char*>(colon_ptr) - buffer;
        std::string name = trimAsciiWhitespace(buffer, colon_idx);
        std::string val = trimAsciiWhitespace(buffer + colon_idx + 1, total - colon_idx - 1);
        if (!name.empty()) {
            parsed->headers.emplace_back(std::move(name), std::move(val));
        }
    }

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

struct CancelContext {
    const std::atomic<bool>* cancel_flag{nullptr};
    const CancelPredicate* cancel_pred{nullptr};

    [[nodiscard]] bool isCanceled() const {
        if (cancel_flag && cancel_flag->load(std::memory_order_acquire)) {
            return true;
        }
        if (cancel_pred && *cancel_pred && (*cancel_pred)()) {
            return true;
        }
        return false;
    }
};

int cancelProgressCallback(void* clientp,
                           curl_off_t /*dltotal*/,
                           curl_off_t /*dlnow*/,
                           curl_off_t /*ultotal*/,
                           curl_off_t /*ulnow*/) {
    const auto* ctx = static_cast<const CancelContext*>(clientp);
    if (ctx && ctx->isCanceled()) {
        return 1;
    }
    return 0;
}

struct VectorWriteContext {
    std::vector<uint8_t>* buffer{nullptr};
    const CancelContext* cancel_ctx{nullptr};
    size_t max_bytes{0}; // 0 means unlimited
};

size_t vectorWriteCallback(char* ptr, size_t size, size_t nmemb, void* userdata) {
    const size_t total = size * nmemb;
    auto* ctx = static_cast<VectorWriteContext*>(userdata);
    if (!ctx) return total;
    if (ctx->cancel_ctx && ctx->cancel_ctx->isCanceled()) {
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

struct RangeStreamWriteContext {
    CURL* easy{nullptr};
    const ParsedHeaders* parsed_headers{nullptr};
    std::vector<uint8_t>* buffer{nullptr};
    const RangeChunkCallback* on_chunk{nullptr};
    const CancelContext* cancel_ctx{nullptr};
    int64_t requested_offset{0};
    size_t requested_length{0};
    int64_t raw_stream_pos{0};
    bool aborted_by_caller{false};
    bool completed_full_200_slice{false};
};

size_t rangeStreamWriteCallback(char* ptr, size_t size, size_t nmemb, void* userdata) {
    const size_t total = size * nmemb;
    auto* ctx = static_cast<RangeStreamWriteContext*>(userdata);
    if (!ctx) return total;

    if (ctx->cancel_ctx && ctx->cancel_ctx->isCanceled()) {
        ctx->aborted_by_caller = true;
        return 0;
    }
    if (total == 0) return 0;

    long http_code = 0;
    curl_easy_getinfo(ctx->easy, CURLINFO_RESPONSE_CODE, &http_code);

    const auto* u8 = reinterpret_cast<const uint8_t*>(ptr);

    if (http_code == 206) {
        const int64_t total_size =
            ctx->parsed_headers ? ctx->parsed_headers->content_range_total : -1;
        if (ctx->buffer) {
            ctx->buffer->insert(ctx->buffer->end(), u8, u8 + total);
        }
        if (ctx->on_chunk && *ctx->on_chunk) {
            if (!(*ctx->on_chunk)(u8, total, total_size)) {
                ctx->aborted_by_caller = true;
                return 0;
            }
        }
        return total;
    }

    if (http_code == 200) {
        // Server ignored Range and returned the full entity from byte 0.
        const int64_t total_size =
            ctx->parsed_headers ? ctx->parsed_headers->content_length : -1;
        const int64_t chunk_start = ctx->raw_stream_pos;
        const int64_t chunk_end = chunk_start + static_cast<int64_t>(total);
        ctx->raw_stream_pos = chunk_end;

        const int64_t req_start = ctx->requested_offset;
        const int64_t req_end = req_start + static_cast<int64_t>(ctx->requested_length);

        const int64_t overlap_start = std::max(chunk_start, req_start);
        const int64_t overlap_end = std::min(chunk_end, req_end);

        if (overlap_end > overlap_start) {
            const size_t slice_off = static_cast<size_t>(overlap_start - chunk_start);
            const size_t slice_len = static_cast<size_t>(overlap_end - overlap_start);
            if (ctx->buffer) {
                ctx->buffer->insert(ctx->buffer->end(), u8 + slice_off, u8 + slice_off + slice_len);
            }
            if (ctx->on_chunk && *ctx->on_chunk) {
                if (!(*ctx->on_chunk)(u8 + slice_off, slice_len, total_size)) {
                    ctx->aborted_by_caller = true;
                    return 0;
                }
            }
        }
        if (chunk_end >= req_end) {
            ctx->completed_full_200_slice = true;
            return 0;
        }
        return total;
    }

    return total;
}

struct StreamWriteContext {
    CURL* easy{nullptr};
    const StreamChunkCallback* on_chunk{nullptr};
    const CancelContext* cancel_ctx{nullptr};
    int64_t bytes_received{0};
    bool aborted_by_callback{false};
};

size_t streamWriteCallback(char* ptr, size_t size, size_t nmemb, void* userdata) {
    const size_t total = size * nmemb;
    auto* ctx = static_cast<StreamWriteContext*>(userdata);
    if (!ctx) return total;

    if (ctx->cancel_ctx && ctx->cancel_ctx->isCanceled()) {
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

bool NativeHttpClient::hasActiveNetworkRoute() noexcept {
    // Synchronous in-kernel FIB routing table lookup via UDP connect().
    // Calling connect() on a SOCK_DGRAM socket performs zero network I/O and sends zero packets;
    // the kernel immediately checks whether a non-loopback outgoing route exists (~3 microseconds).
    const int fd4 = ::socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC, 0);
    if (fd4 >= 0) {
        struct sockaddr_in addr4{};
        addr4.sin_family = AF_INET;
        addr4.sin_port = htons(53);
        addr4.sin_addr.s_addr = htonl(0x08080808U); // 8.8.8.8
        const int rc = ::connect(fd4, reinterpret_cast<const struct sockaddr*>(&addr4), sizeof(addr4));
        ::close(fd4);
        if (rc == 0) {
            return true;
        }
    }

    const int fd6 = ::socket(AF_INET6, SOCK_DGRAM | SOCK_CLOEXEC, 0);
    if (fd6 >= 0) {
        struct sockaddr_in6 addr6{};
        addr6.sin6_family = AF_INET6;
        addr6.sin6_port = htons(53);
        // 2001:4860:4860::8888 (IPv6 route check for IPv6-only cellular networks)
        static constexpr uint8_t kDns6[16] = {
            0x20, 0x01, 0x48, 0x60, 0x48, 0x60, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x88, 0x88
        };
        std::memcpy(addr6.sin6_addr.s6_addr, kDns6, sizeof(kDns6));
        const int rc = ::connect(fd6, reinterpret_cast<const struct sockaddr*>(&addr6), sizeof(addr6));
        ::close(fd6);
        if (rc == 0) {
            return true;
        }
    }

    return false;
}

HttpResponse NativeHttpClient::get(
    const std::string& url,
    const std::vector<std::pair<std::string, std::string>>& extra_headers,
    int connect_timeout_ms,
    int read_timeout_ms,
    bool include_spotify_auth,
    const CancelPredicate& cancel_pred) const {
    return executeWithAuthRetry(
        "GET",
        url,
        extra_headers,
        nullptr,
        connect_timeout_ms,
        read_timeout_ms,
        include_spotify_auth,
        cancel_pred);
}

HttpResponse NativeHttpClient::post(
    const std::string& url,
    const std::vector<uint8_t>& body,
    const std::string& content_type,
    const std::vector<std::pair<std::string, std::string>>& extra_headers,
    int connect_timeout_ms,
    int read_timeout_ms,
    bool include_spotify_auth,
    const CancelPredicate& cancel_pred) const {
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
        include_spotify_auth,
        cancel_pred);
}

HttpResponse NativeHttpClient::put(
    const std::string& url,
    const std::vector<uint8_t>& body,
    const std::string& content_type,
    const std::vector<std::pair<std::string, std::string>>& extra_headers,
    int connect_timeout_ms,
    int read_timeout_ms,
    bool include_spotify_auth,
    const CancelPredicate& cancel_pred) const {
    std::vector<std::pair<std::string, std::string>> merged = extra_headers;
    if (!content_type.empty() && !hasHeaderCaseInsensitive(merged, "Content-Type")) {
        merged.emplace_back("Content-Type", content_type);
    }
    return executeWithAuthRetry(
        "PUT",
        url,
        merged,
        &body,
        connect_timeout_ms,
        read_timeout_ms,
        include_spotify_auth,
        cancel_pred);
}

HttpResponse NativeHttpClient::del(
    const std::string& url,
    const std::vector<std::pair<std::string, std::string>>& extra_headers,
    int connect_timeout_ms,
    int read_timeout_ms,
    bool include_spotify_auth,
    const CancelPredicate& cancel_pred) const {
    return executeWithAuthRetry(
        "DELETE",
        url,
        extra_headers,
        nullptr,
        connect_timeout_ms,
        read_timeout_ms,
        include_spotify_auth,
        cancel_pred);
}

HttpResponse NativeHttpClient::executeWithAuthRetry(
    const std::string& method,
    const std::string& url,
    const std::vector<std::pair<std::string, std::string>>& extra_headers,
    const std::vector<uint8_t>* body,
    int connect_timeout_ms,
    int read_timeout_ms,
    bool include_spotify_auth,
    const CancelPredicate& cancel_pred) const {
    for (int attempt = 0; attempt < 2; ++attempt) {
        if (cancel_pred && cancel_pred()) {
            return HttpResponse{};
        }
        if (!hasActiveNetworkRoute()) {
            return HttpResponse{};
        }

        const AuthCredentials creds = auth_store_.snapshot();
        std::vector<std::pair<std::string, std::string>> headers;
        headers.reserve(extra_headers.size() + 9);

        if (include_spotify_auth) {
            if (!creds.access_token.empty() &&
                !hasHeaderCaseInsensitive(extra_headers, "authorization")) {
                headers.emplace_back("Authorization", "Bearer " + creds.access_token);
            }
            if (!creds.client_token.empty() &&
                !hasHeaderCaseInsensitive(extra_headers, "client-token")) {
                headers.emplace_back("client-token", creds.client_token);
            }
            if (!creds.sp_dc.empty() &&
                !hasHeaderCaseInsensitive(extra_headers, "cookie")) {
                headers.emplace_back("Cookie", "sp_dc=" + creds.sp_dc);
            }
            if (!hasHeaderCaseInsensitive(extra_headers, "app-platform")) {
                headers.emplace_back("app-platform", "WebPlayer");
            }
            if (!hasHeaderCaseInsensitive(extra_headers, "spotify-app-version")) {
                headers.emplace_back("spotify-app-version", kWebPlayerAppVersion);
            }
            if (!hasHeaderCaseInsensitive(extra_headers, "user-agent")) {
                headers.emplace_back("User-Agent", kWebPlayerUserAgent);
            }
            if (!hasHeaderCaseInsensitive(extra_headers, "origin")) {
                headers.emplace_back("Origin", "https://open.spotify.com");
            }
            if (!hasHeaderCaseInsensitive(extra_headers, "referer")) {
                headers.emplace_back("Referer", "https://open.spotify.com/");
            }
            if (!creds.accept_language.empty() &&
                !hasHeaderCaseInsensitive(extra_headers, "accept-language")) {
                headers.emplace_back("accept-language", creds.accept_language);
            }
        }

        for (const auto& kv : extra_headers) {
            headers.push_back(kv);
        }

        HttpResponse resp = executeOnce(
            method, url, headers, body, connect_timeout_ms, read_timeout_ms, cancel_pred);

        if (cancel_pred && cancel_pred()) {
            return HttpResponse{};
        }

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
    int read_timeout_ms,
    const CancelPredicate& cancel_pred) const {
    HttpResponse out;
    if (url.empty() || (cancel_pred && cancel_pred()) || !hasActiveNetworkRoute()) return out;

    CurlEasyGuard easy;
    if (!easy.handle) return out;

    CancelContext cancel_ctx{nullptr, cancel_pred ? &cancel_pred : nullptr};

    curl_easy_setopt(easy.handle, CURLOPT_URL, url.c_str());
    curl_easy_setopt(easy.handle, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(easy.handle, CURLOPT_MAXREDIRS, 8L);
    curl_easy_setopt(easy.handle, CURLOPT_ACCEPT_ENCODING, "gzip, deflate");
    curl_easy_setopt(easy.handle, CURLOPT_CONNECTTIMEOUT_MS, static_cast<long>(std::max(1000, connect_timeout_ms)));
    curl_easy_setopt(easy.handle, CURLOPT_TIMEOUT_MS, static_cast<long>(std::max(2000, connect_timeout_ms + read_timeout_ms)));
    if (cancel_pred) {
        curl_easy_setopt(easy.handle, CURLOPT_NOPROGRESS, 0L);
        curl_easy_setopt(easy.handle, CURLOPT_XFERINFOFUNCTION, &cancelProgressCallback);
        curl_easy_setopt(easy.handle, CURLOPT_XFERINFODATA, &cancel_ctx);
    } else {
        curl_easy_setopt(easy.handle, CURLOPT_NOPROGRESS, 1L);
    }

    if (method == "POST") {
        curl_easy_setopt(easy.handle, CURLOPT_POST, 1L);
        if (body && !body->empty()) {
            curl_easy_setopt(easy.handle, CURLOPT_POSTFIELDS, body->data());
            curl_easy_setopt(easy.handle, CURLOPT_POSTFIELDSIZE_LARGE, static_cast<curl_off_t>(body->size()));
        } else {
            curl_easy_setopt(easy.handle, CURLOPT_POSTFIELDS, "");
            curl_easy_setopt(easy.handle, CURLOPT_POSTFIELDSIZE_LARGE, static_cast<curl_off_t>(0));
        }
    } else if (method == "PUT") {
        curl_easy_setopt(easy.handle, CURLOPT_CUSTOMREQUEST, "PUT");
        if (body && !body->empty()) {
            curl_easy_setopt(easy.handle, CURLOPT_POSTFIELDS, body->data());
            curl_easy_setopt(easy.handle, CURLOPT_POSTFIELDSIZE_LARGE, static_cast<curl_off_t>(body->size()));
        } else {
            curl_easy_setopt(easy.handle, CURLOPT_POSTFIELDS, "");
            curl_easy_setopt(easy.handle, CURLOPT_POSTFIELDSIZE_LARGE, static_cast<curl_off_t>(0));
        }
    } else if (method != "GET") {
        curl_easy_setopt(easy.handle, CURLOPT_CUSTOMREQUEST, method.c_str());
        if (body && !body->empty()) {
            curl_easy_setopt(easy.handle, CURLOPT_POSTFIELDS, body->data());
            curl_easy_setopt(easy.handle, CURLOPT_POSTFIELDSIZE_LARGE, static_cast<curl_off_t>(body->size()));
        }
    }

    CurlSlistGuard header_list;
    for (const auto& kv : headers) {
        if (!equalsIgnoreCasePrefix(kv.first.c_str(), kv.first.size(), "accept-encoding")) {
            header_list.append(kv.first + ": " + kv.second);
        }
    }
    if ((method == "POST" || method == "PUT") && !hasHeaderCaseInsensitive(headers, "expect")) {
        header_list.append("Expect:");
    }
    if (header_list.list) {
        curl_easy_setopt(easy.handle, CURLOPT_HTTPHEADER, header_list.list);
    }

    ParsedHeaders parsed_headers;
    VectorWriteContext write_ctx{&out.body, cancel_pred ? &cancel_ctx : nullptr, 0};
    curl_easy_setopt(easy.handle, CURLOPT_HEADERFUNCTION, &headerCollectorCallback);
    curl_easy_setopt(easy.handle, CURLOPT_HEADERDATA, &parsed_headers);
    curl_easy_setopt(easy.handle, CURLOPT_WRITEFUNCTION, &vectorWriteCallback);
    curl_easy_setopt(easy.handle, CURLOPT_WRITEDATA, &write_ctx);

    const CURLcode rc = curl_easy_perform(easy.handle);
    easy.reusable = true;
    if (rc != CURLE_OK) {
        HTTP_LOGW("libcurl %s %s failed: %s (%d)",
                  method.c_str(), url.c_str(), curl_easy_strerror(rc), static_cast<int>(rc));
        out.body.clear();
        return out;
    }

    long status_code = 0;
    curl_easy_getinfo(easy.handle, CURLINFO_RESPONSE_CODE, &status_code);
    char* eff_url = nullptr;
    if (curl_easy_getinfo(easy.handle, CURLINFO_EFFECTIVE_URL, &eff_url) == CURLE_OK && eff_url) {
        out.effective_url = eff_url;
    }

    out.status_code = static_cast<int32_t>(status_code);
    out.content_length = parsed_headers.content_length;
    out.accepts_ranges = parsed_headers.accepts_ranges || (status_code == 206);
    out.headers = std::move(parsed_headers.headers);
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
    CancelContext cancel_ctx{cancel_flag, nullptr};
    if (cancel_ctx.isCanceled()) {
        probe.canceled = true;
        return probe;
    }
    if (!hasActiveNetworkRoute()) {
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
    VectorWriteContext write_ctx{&discard, &cancel_ctx, 1024};
    curl_easy_setopt(easy.handle, CURLOPT_HEADERFUNCTION, &headerCollectorCallback);
    curl_easy_setopt(easy.handle, CURLOPT_HEADERDATA, &parsed_headers);
    curl_easy_setopt(easy.handle, CURLOPT_WRITEFUNCTION, &vectorWriteCallback);
    curl_easy_setopt(easy.handle, CURLOPT_WRITEDATA, &write_ctx);

    if (cancel_flag) {
        curl_easy_setopt(easy.handle, CURLOPT_NOPROGRESS, 0L);
        curl_easy_setopt(easy.handle, CURLOPT_XFERINFOFUNCTION, &cancelProgressCallback);
        curl_easy_setopt(easy.handle, CURLOPT_XFERINFODATA, &cancel_ctx);
    }

    const CURLcode rc = curl_easy_perform(easy.handle);
    easy.reusable = true;
    if (cancel_ctx.isCanceled()) {
        probe.canceled = true;
        return probe;
    }
    if (rc != CURLE_OK) {
        HTTP_LOGW("probeRangeLength %s failed: %s (%d)",
                  url.c_str(), curl_easy_strerror(rc), static_cast<int>(rc));
        return probe;
    }

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
    return streamByteRange(
        url,
        offset,
        length,
        nullptr,
        extra_headers,
        cancel_flag,
        nullptr,
        connect_timeout_ms,
        read_timeout_ms);
}

HttpRangeResult NativeHttpClient::streamByteRange(
    const std::string& url,
    int64_t offset,
    size_t length,
    const RangeChunkCallback& on_chunk,
    const std::vector<std::pair<std::string, std::string>>& extra_headers,
    const std::atomic<bool>* cancel_flag,
    const CancelPredicate& cancel_pred,
    int connect_timeout_ms,
    int read_timeout_ms) const {
    HttpRangeResult out;
    if (url.empty() || offset < 0 || length == 0) {
        return out;
    }
    CancelContext cancel_ctx{cancel_flag, &cancel_pred};
    if (cancel_ctx.isCanceled()) {
        out.status = RangeFetchStatus::Canceled;
        return out;
    }
    if (!hasActiveNetworkRoute()) {
        out.status = RangeFetchStatus::Offline;
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

    RangeStreamWriteContext stream_ctx{
        easy.handle,
        &parsed_headers,
        &raw_body,
        &on_chunk,
        &cancel_ctx,
        offset,
        length,
        0,
        false,
        false
    };

    curl_easy_setopt(easy.handle, CURLOPT_HEADERFUNCTION, &headerCollectorCallback);
    curl_easy_setopt(easy.handle, CURLOPT_HEADERDATA, &parsed_headers);
    curl_easy_setopt(easy.handle, CURLOPT_WRITEFUNCTION, &rangeStreamWriteCallback);
    curl_easy_setopt(easy.handle, CURLOPT_WRITEDATA, &stream_ctx);

    if (cancel_flag || cancel_pred) {
        curl_easy_setopt(easy.handle, CURLOPT_NOPROGRESS, 0L);
        curl_easy_setopt(easy.handle, CURLOPT_XFERINFOFUNCTION, &cancelProgressCallback);
        curl_easy_setopt(easy.handle, CURLOPT_XFERINFODATA, &cancel_ctx);
    }

    const CURLcode rc = curl_easy_perform(easy.handle);
    easy.reusable = true;

    if (stream_ctx.aborted_by_caller || cancel_ctx.isCanceled()) {
        out.status = RangeFetchStatus::Canceled;
        return out;
    }

    long status_code = 0;
    curl_easy_getinfo(easy.handle, CURLINFO_RESPONSE_CODE, &status_code);
    out.http_status = static_cast<int32_t>(status_code);
    out.total_size = parsed_headers.content_range_total;

    if (status_code == 200 && stream_ctx.completed_full_200_slice) {
        if (parsed_headers.content_length >= 0) {
            out.total_size = parsed_headers.content_length;
        }
        out.status = RangeFetchStatus::Ok;
        out.data = std::move(raw_body);
        return out;
    }

    if (rc != CURLE_OK) {
        if (rc == CURLE_ABORTED_BY_CALLBACK) {
            out.status = RangeFetchStatus::Canceled;
            return out;
        }
        if (!hasActiveNetworkRoute()) {
            out.status = RangeFetchStatus::Offline;
            return out;
        }
        HTTP_LOGW("streamByteRange(%s, bytes=%s) failed: %s (%d)",
                  url.c_str(), range_buf, curl_easy_strerror(rc), static_cast<int>(rc));
        out.status = RangeFetchStatus::NetworkError;
        return out;
    }

    if (status_code == 206) {
        out.status = RangeFetchStatus::Ok;
        out.data = std::move(raw_body);
        return out;
    }

    if (status_code == 200) {
        if (parsed_headers.content_length >= 0) {
            out.total_size = parsed_headers.content_length;
        }
        out.status = RangeFetchStatus::Ok;
        out.data = std::move(raw_body);
        return out;
    }

    if (status_code == 416) {
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
    CancelContext cancel_ctx{cancel_flag, nullptr};
    if (cancel_ctx.isCanceled()) {
        out.canceled = true;
        return out;
    }
    if (!hasActiveNetworkRoute()) {
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
    StreamWriteContext stream_ctx{easy.handle, &on_chunk, &cancel_ctx, 0, false};

    curl_easy_setopt(easy.handle, CURLOPT_HEADERFUNCTION, &headerCollectorCallback);
    curl_easy_setopt(easy.handle, CURLOPT_HEADERDATA, &parsed_headers);
    curl_easy_setopt(easy.handle, CURLOPT_WRITEFUNCTION, &streamWriteCallback);
    curl_easy_setopt(easy.handle, CURLOPT_WRITEDATA, &stream_ctx);

    if (cancel_flag) {
        curl_easy_setopt(easy.handle, CURLOPT_NOPROGRESS, 0L);
        curl_easy_setopt(easy.handle, CURLOPT_XFERINFOFUNCTION, &cancelProgressCallback);
        curl_easy_setopt(easy.handle, CURLOPT_XFERINFODATA, &cancel_ctx);
    }

    const CURLcode rc = curl_easy_perform(easy.handle);
    easy.reusable = true;
    if (cancel_ctx.isCanceled()) {
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

    out.ok = (status_code >= 200 && status_code < 300);
    return out;
}

} // namespace spotify::network
