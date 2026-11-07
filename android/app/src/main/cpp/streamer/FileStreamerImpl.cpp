#include "FileStreamerImpl.h"

#include <android/log.h>

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

bool FileStreamerImpl::isEncryptedMp4Format(int32_t format_code) noexcept {
    return format_code == kMp4_128 ||
           format_code == kMp4_256 ||
           format_code == kMp4_128Dual ||
           format_code == kMp4_256Dual ||
           format_code == kMp4_128Cbcs ||
           format_code == kMp4_256Cbcs ||
           format_code == kMp4Flac;
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

std::optional<ResolvedFullStream> FileStreamerImpl::resolveFullTrackStream(
    const metadata::TrackInfo& info) {
    if (!info.pass_through_url.empty()) {
        ResolvedFullStream out;
        out.cdn_url = info.pass_through_url;
        out.format_code = -1;
        out.is_encrypted = false;
        return out;
    }

    const auto candidates = orderStreamCandidates(info.files);
    if (candidates.empty()) {
        FS_LOGW("No playable audio file candidates for %s", info.uri.c_str());
        return std::nullopt;
    }

    for (const auto& candidate : candidates) {
        const auto sr = storage_resolve_.resolveAudioFile(candidate.format, candidate.file_id_hex, false);
        if (!sr.ok || sr.cdn_urls.empty()) {
            continue;
        }

        ResolvedFullStream out;
        out.cdn_url = sr.cdn_urls.front();
        out.format_code = candidate.format;
        out.is_encrypted = isEncryptedMp4Format(candidate.format);

        if (out.is_encrypted) {
            const auto drm_ctx = license_client_.resolveLicenseContext();
            out.license_url = drm_ctx.license_url;
            out.auth_header = drm_ctx.auth_header;
        }

        FS_LOGI("Selected stream format=%d encrypted=%d for %s",
                static_cast<int>(out.format_code),
                out.is_encrypted ? 1 : 0,
                info.uri.c_str());
        return out;
    }

    FS_LOGW("All storage-resolve candidates failed for %s", info.uri.c_str());
    return std::nullopt;
}

} // namespace spotify::streamer
