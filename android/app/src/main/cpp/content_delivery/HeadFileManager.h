#pragma once

#include "../cache/DiskCache.h"
#include "../network/AuthSessionStore.h"
#include "../network/NativeHttpClient.h"
#include "../network/NativeTrafficController.h"

#include <atomic>
#include <cstdint>
#include <string>

namespace spotify::content_delivery {

/// Resolves or progressively streams Chunk 0 Ogg Vorbis head files in pure C++.
class HeadFileManager {
public:
    HeadFileManager(cache::DiskCache& disk_cache,
                    network::AuthSessionStore& auth_store,
                    network::NativeHttpClient& http_client);
    ~HeadFileManager() = default;

    HeadFileManager(const HeadFileManager&) = delete;
    HeadFileManager& operator=(const HeadFileManager&) = delete;

    /// Downloads or joins an active download for `file_id_hex` into `target_path`,
    /// returning true once at least 4 KiB is flushed to disk (for <30ms decoder open)
    /// or the complete head file already exists.
    static bool streamHeadFile(network::NativeHttpClient& http_client,
                               const std::string& file_id_hex,
                               const std::string& target_path,
                               network::AcquisitionIntent intent =
                                   network::AcquisitionIntent::InteractivePlayback);

    /// Returns the local path if `file_id_hex` is already validly cached on disk, or empty string.
    [[nodiscard]] std::string lookupCachedHeadFile(const std::string& file_id_hex);

    /// Waits on the active download condition variable until `part_or_target_path` has
    /// at least `required_bytes` written to disk, the download completes, `cancel_flag` becomes
    /// true, or `timeout_ms` elapses.
    static bool waitForHeadBytes(const std::string& part_or_target_path,
                                 int64_t required_bytes,
                                 int timeout_ms,
                                 const std::atomic<bool>& cancel_flag);

    /// Wakes all threads currently waiting in `waitForHeadBytes()` (e.g., when a data source cancels).
    static void wakeAllWaiters();

    /// Synchronously ensures the head file for `file_id_hex` is cached or has at least 4 KiB
    /// streamed to disk for immediate decoder open. Returns local file path or empty on failure.
    [[nodiscard]] std::string acquireHeadFile(const std::string& file_id_hex);

    /// Asynchronously prefetches `file_id_hex` into `DiskCache` on a background worker.
    void prefetchHeadAsync(const std::string& file_id_hex);

    [[nodiscard]] std::string currentCacheDir() const;

private:
    void syncCacheDir();

    cache::DiskCache& disk_cache_;
    network::AuthSessionStore& auth_store_;
    network::NativeHttpClient& http_client_;
};

} // namespace spotify::content_delivery
