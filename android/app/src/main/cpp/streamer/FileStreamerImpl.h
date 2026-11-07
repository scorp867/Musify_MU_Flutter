#pragma once

#include "../content_delivery/HeadFileManager.h"
#include "../content_delivery/StorageResolveClient.h"
#include "../drm/WidevineLicenseClient.h"
#include "../metadata/TrackInfoProvider.h"
#include "../network/AuthSessionStore.h"

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace spotify::streamer {

struct ResolvedFullStream {
    std::string cdn_url;
    std::string license_url;
    std::string auth_header;
    int32_t format_code{0};
    bool is_encrypted{false};
};

/// 1:1 equivalent of liborbit's `FileStreamerImpl`:
/// - Selects Ogg Vorbis Chunk 0 head `fileId` (`OGG_VORBIS_320 -> 160 -> 96`)
/// - Selects full stream MP4/Ogg file (`MP4_256 -> MP4_128` for `premium`, `MP4_128` family for `free`)
/// - Coordinates `HeadFileManager`, `StorageResolveClient`, and `WidevineLicenseClient`.
class FileStreamerImpl {
public:
    FileStreamerImpl(network::AuthSessionStore& auth_store,
                     content_delivery::HeadFileManager& head_manager,
                     content_delivery::StorageResolveClient& storage_resolve,
                     drm::WidevineLicenseClient& license_client);
    ~FileStreamerImpl() = default;

    FileStreamerImpl(const FileStreamerImpl&) = delete;
    FileStreamerImpl& operator=(const FileStreamerImpl&) = delete;

    /// Picks the highest-priority Ogg Vorbis head file ID (`2 -> 1 -> 0`) from `files`, or empty if none.
    [[nodiscard]] static std::string selectOggHeadFileId(
        const std::vector<metadata::AudioFileDescriptor>& files);

    /// Acquires (or streams first 8 KiB of) the Chunk 0 head file for `ogg_file_id_hex`.
    [[nodiscard]] std::string acquireHeadFile(const std::string& ogg_file_id_hex);

    /// Asynchronously prefetches the best Ogg Vorbis head file for an upcoming track.
    void prefetchTrackHead(const metadata::TrackInfo& info);

    /// Resolves the signed CDN URL and Widevine license context for the full track stream.
    [[nodiscard]] std::optional<ResolvedFullStream> resolveFullTrackStream(
        const metadata::TrackInfo& info);

    [[nodiscard]] std::string currentCacheDir() const;

private:
    [[nodiscard]] std::vector<metadata::AudioFileDescriptor> orderStreamCandidates(
        const std::vector<metadata::AudioFileDescriptor>& files) const;

    static bool isEncryptedMp4Format(int32_t format_code) noexcept;

    network::AuthSessionStore& auth_store_;
    content_delivery::HeadFileManager& head_manager_;
    content_delivery::StorageResolveClient& storage_resolve_;
    drm::WidevineLicenseClient& license_client_;
};

} // namespace spotify::streamer
