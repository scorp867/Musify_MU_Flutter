#include "FileStreamerImpl.h"

#include "../cache/DiskCache.h"
#include "../network/HttpRangeStreamCache.h"

#include <android/log.h>
#include <future>

#define FS_LOG_TAG "MusifyFileStreamer"
#define FS_LOGI(...) __android_log_print(ANDROID_LOG_INFO, FS_LOG_TAG, __VA_ARGS__)
#define FS_LOGW(...) __android_log_print(ANDROID_LOG_WARN, FS_LOG_TAG, __VA_ARGS__)

namespace spotify::streamer {

namespace {
// spotify.metadata.AudioFile.Format enum values
constexpr int32_t kOggVorbis96 = 0;
constexpr int32_t kOggVorbis160 = 1;
constexpr int32_t kOggVorbis320 = 2;
constexpr int32_t kMp4_128 = 10;
constexpr int32_t kMp4_256 = 11;
constexpr int32_t kMp4_128Dual = 12;
constexpr int32_t kMp4_256Dual = 13;
constexpr int32_t kMp4_128Cbcs = 14;
constexpr int32_t kMp4_256Cbcs = 15;
constexpr int32_t kFlacFlac = 16;
constexpr int32_t kMp4Flac = 17;
} // namespace

FileStreamerImpl::FileStreamerImpl(
    network::AuthSessionStore& auth_store,
    content_delivery::HeadFileManager& head_manager,
    content_delivery::StorageResolveClient& storage_resolve,
    drm::WidevineLicenseClient& license_client)
    : auth_store_(auth_store),
      head_manager_(head_manager),
      storage_resolve_(storage_resolve),
      license_client_(license_client) {}

std::string FileStreamerImpl::selectOggHeadFileId(
    const std::vector<metadata::AudioFileDescriptor>& files) {
    const int32_t priorities[3] = {kOggVorbis320, kOggVorbis160, kOggVorbis96};
    for (int32_t target_fmt : priorities) {
        for (const auto& f : files) {
            if (f.format == target_fmt && !f.file_id_hex.empty()) {
                return f.file_id_hex;
            }
        }
    }
    return {};
}

std::string FileStreamerImpl::acquireHeadFile(const std::string& ogg_file_id_hex) {
    return head_manager_.acquireHeadFile(ogg_file_id_hex);
}

void FileStreamerImpl::prefetchTrackHead(const metadata::TrackInfo& info) {
    const std::string ogg_id = selectOggHeadFileId(info.files);
    if (!ogg_id.empty()) {
        head_manager_.prefetchHeadAsync(ogg_id);
    }
}

std::string FileStreamerImpl::currentCacheDir() const {
    return head_manager_.currentCacheDir();
}

StreamEncryptionScheme FileStreamerImpl::encryptionSchemeForFormat(int32_t format_code) noexcept {
    if (format_code == kMp4_128 ||
        format_code == kMp4_256 ||
        format_code == kMp4_128Dual ||
        format_code == kMp4_256Dual ||
        format_code == kMp4_128Cbcs ||
        format_code == kMp4_256Cbcs ||
        format_code == kMp4Flac) {
        return StreamEncryptionScheme::WidevineCenc;
    }
    return StreamEncryptionScheme::Unencrypted;
}

std::vector<metadata::AudioFileDescriptor> FileStreamerImpl::orderStreamCandidates(
    const std::vector<metadata::AudioFileDescriptor>& files) const {
    const auto creds = auth_store_.snapshot();
    const bool is_premium = (creds.catalogue == "premium");

    const int32_t premium_order[] = {
        kMp4_256,
        kMp4_256Dual,
        kMp4_256Cbcs,
        kMp4_128,
        kMp4_128Dual,
        kMp4_128Cbcs,
        kOggVorbis320,
        kOggVorbis160,
        kOggVorbis96,
        kFlacFlac,
    };

    const int32_t free_order[] = {
        kMp4_128,
        kMp4_128Dual,
        kMp4_128Cbcs,
        kMp4_256,
        kMp4_256Dual,
        kMp4_256Cbcs,
        kOggVorbis160,
        kOggVorbis96,
        kOggVorbis320,
    };

    const int32_t* order = is_premium ? premium_order : free_order;
    const size_t order_len = is_premium
                                 ? (sizeof(premium_order) / sizeof(premium_order[0]))
                                 : (sizeof(free_order) / sizeof(free_order[0]));

    std::vector<metadata::AudioFileDescriptor> ordered;
    ordered.reserve(files.size());

    for (size_t i = 0; i < order_len; ++i) {
        const int32_t fmt = order[i];
        for (const auto& f : files) {
            if (f.format == fmt && !f.file_id_hex.empty()) {
                ordered.push_back(f);
            }
        }
    }
    return ordered;
}

bool FileStreamerImpl::hasCachedFullTrackStream(const metadata::TrackInfo& info) const {
    if (!info.pass_through_url.empty()) return false;
    const auto candidates = orderStreamCandidates(info.files);
    auto& disk_cache = cache::DiskCache::defaultInstance();
    for (const auto& candidate : candidates) {
        if (disk_cache.readStreamTotalSize(candidate.file_id_hex) > 0) {
            const auto block0 = disk_cache.readStreamBlock(candidate.file_id_hex, 0);
            if (block0 && !block0->empty()) {
                return true;
            }
        }
    }
    return false;
}

std::optional<ResolvedFullStream> FileStreamerImpl::resolveFullTrackStream(
    const metadata::TrackInfo& info,
    const network::CancelPredicate& cancel_pred,
    network::AcquisitionIntent intent) {
    if (!info.pass_through_url.empty()) {
        ResolvedFullStream out;
        out.cdn_url = info.pass_through_url;
        out.cdn_urls.push_back(info.pass_through_url);
        out.format_code = -1;
        out.encryption_scheme = StreamEncryptionScheme::Unencrypted;
        return out;
    }

    const auto candidates = orderStreamCandidates(info.files);
    if (candidates.empty()) {
        FS_LOGW("No playable audio file candidates for %s", info.uri.c_str());
        return std::nullopt;
    }

    // 1. Offline DiskCache fast-path: if the device is currently offline and any candidate
    // stream has its blocks cached in DiskCache, open directly from DiskCache in 0ms!
    if (!network::NativeTrafficController::instance().isOnline()) {
        auto& disk_cache = cache::DiskCache::defaultInstance();
        for (const auto& candidate : candidates) {
            if (disk_cache.readStreamTotalSize(candidate.file_id_hex) <= 0) {
                continue;
            }
            const auto block0 = disk_cache.readStreamBlock(candidate.file_id_hex, 0);
            if (!block0 || block0->empty()) {
                continue;
            }

            ResolvedFullStream out;
            const auto cached_sr = storage_resolve_.tryGetCached(candidate.format, candidate.file_id_hex);
            if (cached_sr.isResolved()) {
                out.cdn_url = cached_sr.cdn_urls.front();
                out.cdn_urls = cached_sr.cdn_urls;
            } else {
                out.cdn_url = std::string(network::HttpRangeStreamCache::kOfflineSyntheticUrlPrefix) +
                              candidate.file_id_hex;
                out.cdn_urls.push_back(out.cdn_url);
            }
            out.format_code = candidate.format;
            out.encryption_scheme = encryptionSchemeForFormat(candidate.format);
            if (out.usesWidevine()) {
                const auto creds = auth_store_.snapshot();
                if (!creds.access_token.empty()) {
                    out.auth_header = "Authorization: Bearer " + creds.access_token;
                    if (!creds.client_token.empty()) {
                        out.auth_header += "\r\nclient-token: " + creds.client_token;
                    }
                }
            }
            FS_LOGI("Offline DiskCache hit for %s (fileId=%s, format=%d, encrypted=%d)",
                    info.uri.c_str(),
                    candidate.file_id_hex.c_str(),
                    static_cast<int>(out.format_code),
                    out.usesWidevine() ? 1 : 0);
            return out;
        }

        if (intent == network::AcquisitionIntent::BackgroundPrefetch) {
            return std::nullopt;
        }
    }

    // 2. RAM cache fast-path: check if any candidate already has unexpired CDN URLs in memory
    for (const auto& candidate : candidates) {
        const auto cached_sr = storage_resolve_.tryGetCached(candidate.format, candidate.file_id_hex);
        if (cached_sr.isResolved()) {
            ResolvedFullStream out;
            out.cdn_url = cached_sr.cdn_urls.front();
            out.cdn_urls = cached_sr.cdn_urls;
            out.format_code = candidate.format;
            out.encryption_scheme = encryptionSchemeForFormat(candidate.format);
            if (out.usesWidevine()) {
                const auto drm_ctx = license_client_.resolveLicenseContext();
                out.license_url = drm_ctx.license_url;
                out.auth_header = drm_ctx.auth_header;
            }
            return out;
        }
    }

    bool any_encrypted = false;
    for (const auto& candidate : candidates) {
        if (encryptionSchemeForFormat(candidate.format) == StreamEncryptionScheme::WidevineCenc) {
            any_encrypted = true;
            break;
        }
    }

    std::future<drm::WidevineLicenseContext> license_future;
    if (any_encrypted && intent == network::AcquisitionIntent::InteractivePlayback) {
        license_future = std::async(std::launch::async, [this]() {
            return license_client_.resolveLicenseContext();
        });
    }

    for (const auto& candidate : candidates) {
        if (cancel_pred && cancel_pred()) {
            return std::nullopt;
        }
        const auto sr = storage_resolve_.resolveAudioFile(
            candidate.format,
            candidate.file_id_hex,
            intent,
            cancel_pred);
        if (!sr.isResolved()) {
            continue;
        }

        ResolvedFullStream out;
        out.cdn_url = sr.cdn_urls.front();
        out.cdn_urls = sr.cdn_urls;
        out.format_code = candidate.format;
        out.encryption_scheme = encryptionSchemeForFormat(candidate.format);

        if (out.usesWidevine()) {
            const auto drm_ctx = license_future.valid()
                                     ? license_future.get()
                                     : license_client_.resolveLicenseContext();
            out.license_url = drm_ctx.license_url;
            out.auth_header = drm_ctx.auth_header;
        }

        FS_LOGI("Selected stream format=%d encrypted=%d for %s",
                static_cast<int>(out.format_code),
                out.usesWidevine() ? 1 : 0,
                info.uri.c_str());
        return out;
    }

    FS_LOGW("All storage-resolve candidates failed for %s", info.uri.c_str());
    return std::nullopt;
}

} // namespace spotify::streamer
