#include "StorageResolveClient.h"

#include "../ProtobufWireHelper.h"

#include <android/log.h>
#include <cstdio>

#define SR_LOG_TAG "MusifyStorageResolve"
#define SR_LOGI(...) __android_log_print(ANDROID_LOG_INFO, SR_LOG_TAG, __VA_ARGS__)
#define SR_LOGW(...) __android_log_print(ANDROID_LOG_WARN, SR_LOG_TAG, __VA_ARGS__)

namespace spotify::content_delivery {

namespace {
constexpr const char* kPrimarySpclient = "https://gae2-spclient.spotify.com";
constexpr const char* kFallbackSpclient = "https://spclient.wg.spotify.com";
constexpr auto kCdnUrlTtl = std::chrono::minutes(45);
} // namespace

StorageResolveClient::StorageResolveClient(network::NativeHttpClient& http_client)
    : http_client_(http_client) {}

StorageResolveResult StorageResolveClient::resolveAudioFile(
    int32_t format_code,
    const std::string& file_id_hex,
    bool is_prefetch) {
    StorageResolveResult result;
    if (file_id_hex.empty() || format_code < 0) {
        return result;
    }

    const std::string cache_key = std::to_string(format_code) + ":" + file_id_hex;
    const auto now = std::chrono::steady_clock::now();
    {
        std::lock_guard<std::mutex> lock(mutex_);
        auto it = cache_.find(cache_key);
        if (it != cache_.end()) {
            if (it->second.expires_at > now && !it->second.cdn_urls.empty()) {
                result.ok = true;
                result.cdn_urls = it->second.cdn_urls;
                return result;
            }
            cache_.erase(it);
        }
    }

    const char* mode = is_prefetch ? "interactive_prefetch" : "interactive";
    char path_buf[256];
    std::snprintf(
        path_buf,
        sizeof(path_buf),
        "/storage-resolve/v2/files/audio/%s/%d/%s?version=10000000&product=9&platform=39",
        mode,
        static_cast<int>(format_code),
        file_id_hex.c_str());

    const char* hosts[2] = {kPrimarySpclient, kFallbackSpclient};
    for (const char* host : hosts) {
        const std::string url = std::string(host) + path_buf;
        const auto resp = http_client_.get(
            url,
            {{"Accept", "application/x-protobuf"}},
            6000,
            10000,
            true);

        if (!resp.isSuccess() || resp.body.empty()) {
            SR_LOGW("storage-resolve HTTP %d from %s for %s",
                    resp.status_code, host, file_id_hex.c_str());
            continue;
        }

        StorageResolveResult parsed;
        if (resp.body[0] == '{') {
            parseJsonFallback(resp.body, parsed);
        } else {
            if (!parseProtobufResponse(resp.body, parsed)) {
                parseJsonFallback(resp.body, parsed);
            }
        }

        if (parsed.restricted) {
            return parsed;
        }

        if (parsed.ok && !parsed.cdn_urls.empty()) {
            {
                std::lock_guard<std::mutex> lock(mutex_);
                if (cache_.size() > 512) {
                    cache_.clear();
                }
                cache_[cache_key] = CachedEntry{
                    parsed.cdn_urls,
                    std::chrono::steady_clock::now() + kCdnUrlTtl,
                };
            }
            SR_LOGI("Resolved %zu CDN URLs for fileId=%s (format=%d)",
                    parsed.cdn_urls.size(),
                    file_id_hex.c_str(),
                    static_cast<int>(format_code));
            return parsed;
        }
    }

    return result;
}

bool StorageResolveClient::parseProtobufResponse(
    const std::vector<uint8_t>& body,
    StorageResolveResult& out) {
    const uint8_t* ptr = body.data();
    const uint8_t* end = ptr + body.size();
    uint64_t result_enum = 0;

    while (ptr < end) {
        uint64_t tag = 0;
        if (!player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);

        if (field_num == 1 && wire_type == 0) {
            if (!player::decode_varint(ptr, end, result_enum)) return false;
        } else if (field_num == 2 && wire_type == 2) {
            uint64_t len = 0;
            if (!player::decode_varint(ptr, end, len) || ptr + len > end) return false;
            if (len > 0) {
                out.cdn_urls.emplace_back(reinterpret_cast<const char*>(ptr), len);
            }
            ptr += len;
        } else {
            if (!player::skip_field(ptr, end, wire_type)) return false;
        }
    }

    if (result_enum == 3) {
        out.restricted = true;
        return true;
    }

    out.ok = !out.cdn_urls.empty();
    return out.ok;
}

bool StorageResolveClient::parseJsonFallback(
    const std::vector<uint8_t>& body,
    StorageResolveResult& out) {
    const std::string text(reinterpret_cast<const char*>(body.data()), body.size());
    const size_t key_pos = text.find("\"cdnurl\"");
    if (key_pos == std::string::npos) return false;

    const size_t bracket_start = text.find('[', key_pos);
    const size_t bracket_end = text.find(']', bracket_start == std::string::npos ? key_pos : bracket_start);
    if (bracket_start == std::string::npos || bracket_end == std::string::npos || bracket_end <= bracket_start) {
        return false;
    }

    size_t pos = bracket_start + 1;
    while (pos < bracket_end) {
        const size_t q1 = text.find('"', pos);
        if (q1 == std::string::npos || q1 >= bracket_end) break;
        std::string url;
        size_t i = q1 + 1;
        while (i < bracket_end) {
            if (text[i] == '\\' && i + 1 < bracket_end) {
                url.push_back(text[i + 1]);
                i += 2;
                continue;
            }
            if (text[i] == '"') {
                break;
            }
            url.push_back(text[i]);
            ++i;
        }
        if (!url.empty()) {
            out.cdn_urls.push_back(std::move(url));
        }
        pos = i + 1;
    }

    out.ok = !out.cdn_urls.empty();
    return out.ok;
}

} // namespace spotify::content_delivery
