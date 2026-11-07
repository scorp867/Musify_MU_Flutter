#pragma once

#include "../cache/DiskCache.h"
#include "../network/AuthSessionStore.h"

#include <string>

namespace spotify::content_delivery {

/// 1:1 equivalent of liborbit's `HeadFileManager`: resolves or streams Chunk 0 Ogg Vorbis head files.
class HeadFileManager {
public:
    HeadFileManager(cache::DiskCache& disk_cache,
                    network::AuthSessionStore& auth_store);
    ~HeadFileManager() = default;

    HeadFileManager(const HeadFileManager&) = delete;
    HeadFileManager& operator=(const HeadFileManager&) = delete;

    /// Synchronously ensures the head file for `file_id_hex` is cached or has at least 8 KiB streamed
    /// to disk for immediate `< 30ms` decoder open. Returns the local file path or empty on failure.
    [[nodiscard]] std::string acquireHeadFile(const std::string& file_id_hex);

    /// Asynchronously prefetches `file_id_hex` into `DiskCache` on a detached background worker.
    void prefetchHeadAsync(const std::string& file_id_hex);

    [[nodiscard]] std::string currentCacheDir() const;

private:
    void syncCacheDir();

    cache::DiskCache& disk_cache_;
    network::AuthSessionStore& auth_store_;
};

} // namespace spotify::content_delivery
