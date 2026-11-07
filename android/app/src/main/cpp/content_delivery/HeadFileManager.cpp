#include "HeadFileManager.h"

#include "../AudioEngine.h"

#include <thread>

namespace spotify::content_delivery {

HeadFileManager::HeadFileManager(cache::DiskCache& disk_cache,
                                 network::AuthSessionStore& auth_store)
    : disk_cache_(disk_cache),
      auth_store_(auth_store) {}

void HeadFileManager::syncCacheDir() {
    const auto creds = auth_store_.snapshot();
    if (!creds.cache_dir.empty()) {
        disk_cache_.setBaseCacheDir(creds.cache_dir);
    }
}

std::string HeadFileManager::currentCacheDir() const {
    const auto creds = auth_store_.snapshot();
    if (!creds.cache_dir.empty()) {
        return creds.cache_dir;
    }
    return "/data/data/um.musify.mu.musify_mu/cache";
}

std::string HeadFileManager::acquireHeadFile(const std::string& file_id_hex) {
    if (file_id_hex.empty()) return {};
    syncCacheDir();

    std::string existing = disk_cache_.lookupValidHead(file_id_hex);
    if (!existing.empty()) {
        return existing;
    }

    const std::string target_path = disk_cache_.resolveHeadPath(file_id_hex);
    if (AudioEngine::downloadHeadFileNative(file_id_hex.c_str(), target_path.c_str())) {
        disk_cache_.onHeadStored(file_id_hex);
        return target_path;
    }
    return {};
}

void HeadFileManager::prefetchHeadAsync(const std::string& file_id_hex) {
    if (file_id_hex.empty()) return;
    syncCacheDir();

    if (!disk_cache_.lookupValidHead(file_id_hex).empty()) {
        return;
    }

    const std::string target_path = disk_cache_.resolveHeadPath(file_id_hex);
    std::thread([this, file_id_hex, target_path]() {
        if (AudioEngine::downloadHeadFileNative(file_id_hex.c_str(), target_path.c_str())) {
            disk_cache_.onHeadStored(file_id_hex);
        }
    }).detach();
}

} // namespace spotify::content_delivery
