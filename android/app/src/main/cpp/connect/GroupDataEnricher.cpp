// ============================================================================
// Replicated Spotify Connect-Group v1 Data & Volume Enricher
// Sources (`liborbit-jni-spotify.so` arm64):
// - Dealer topic `hm://connect-group/v1/group-data-event` (0x39aac6 @ 0xd9f810)
// - Dealer topic `hm://connect-group/v1/group-device-volume-event` (0x34e81a @ 0xd9f85c)
// - HTTP `POST connect-group/v1/refresh-group-data` (0x389e83 @ 0xda0740)
// - Group enrichment & cluster correlation (`0xda0590..0xda1818`)
// ============================================================================

#include "GroupDataEnricher.h"

#include <unordered_set>
#include <utility>
#include <vector>

#include "../network/NativeLog.h"

namespace spotify::connectstate {

GroupDataEnricher::GroupDataEnricher(
    ConnectStateClientImpl& client,
    ConnectDevicesImpl& devices)
    : client_(client),
      devices_(devices) {}

GroupDataEnricher::~GroupDataEnricher() {
    stop();
}

void GroupDataEnricher::start() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (worker_running_) {
        return;
    }
    stop_requested_ = false;
    worker_running_ = true;
    worker_thread_ = std::thread(&GroupDataEnricher::worker_loop, this);
}

void GroupDataEnricher::stop() {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!worker_running_ && !worker_thread_.joinable()) {
            return;
        }
        stop_requested_ = true;
        refresh_pending_ = false;
    }
    cv_.notify_all();
    if (worker_thread_.joinable()) {
        worker_thread_.join();
    }
    {
        std::lock_guard<std::mutex> lock(mutex_);
        worker_running_ = false;
        stop_requested_ = false;
    }
}

void GroupDataEnricher::reset() {
    std::lock_guard<std::mutex> lock(mutex_);
    known_instances_.clear();
    refresh_pending_ = false;
}

void GroupDataEnricher::set_enriched_callback(EnrichedCallback callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    enriched_callback_ = std::move(callback);
}

void GroupDataEnricher::set_volume_enriched_callback(EnrichedCallback callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    volume_enriched_callback_ = std::move(callback);
}

void GroupDataEnricher::notify_enriched() {
    EnrichedCallback cb;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        cb = enriched_callback_;
    }
    if (cb) {
        cb();
    }
}

void GroupDataEnricher::notify_volume_enriched() {
    EnrichedCallback cb;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        cb = volume_enriched_callback_;
    }
    if (cb) {
        cb();
    }
}

void GroupDataEnricher::on_group_data_event(const GroupDataEvent& event) {
    if (event.group_data.empty()) {
        CONNECT_LOGD("GroupDataEnricher::on_group_data_event: empty event payload");
        return;
    }

    {
        std::lock_guard<std::mutex> lock(mutex_);
        for (const auto& gd : event.group_data) {
            if (gd.spotify_device_id.empty()) {
                continue;
            }
            auto it = known_instances_.find(gd.spotify_device_id);
            if (it == known_instances_.end() ||
                gd.timestamp_ms == 0 ||
                gd.timestamp_ms >= it->second.timestamp_ms ||
                gd.group_instance != it->second.group_instance) {
                known_instances_[gd.spotify_device_id] = KnownGroupInstance{
                    .spotify_device_id = gd.spotify_device_id,
                    .group_instance = gd.group_instance,
                    .timestamp_ms = gd.timestamp_ms,
                };
            }
        }
    }

    devices_.apply_group_data(event.group_data);
    CONNECT_LOGI(
        "GroupDataEnricher: applied %zu group-data entries from Dealer event",
        event.group_data.size());
    notify_enriched();
}

void GroupDataEnricher::on_group_device_volume_event(const GroupDeviceVolumeEvent& event) {
    if (event.volumes.empty()) {
        CONNECT_LOGD("GroupDataEnricher::on_group_device_volume_event: empty event payload");
        return;
    }
    devices_.apply_group_device_volumes(event.volumes);
    CONNECT_LOGI(
        "GroupDataEnricher: applied %zu group-device volume entries from Dealer event",
        event.volumes.size());
    notify_volume_enriched();
}

void GroupDataEnricher::on_cluster_updated(const Cluster& cluster) {
    bool needs_refresh = false;
    std::vector<std::string> departed_instances;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        std::unordered_set<std::string> active_group_device_ids;

        for (const auto& [dev_id, dev] : cluster.devices) {
            const bool has_group = dev.is_group || !dev.group_instance.empty();
            if (!has_group) {
                continue;
            }
            active_group_device_ids.insert(dev_id);

            const auto known_it = known_instances_.find(dev_id);
            if (known_it == known_instances_.end()) {
                known_instances_[dev_id] = KnownGroupInstance{
                    .spotify_device_id = dev_id,
                    .group_instance = dev.group_instance,
                    .timestamp_ms = 0,
                };
                needs_refresh = true;
            } else if (!dev.group_instance.empty() &&
                       known_it->second.group_instance != dev.group_instance) {
                known_it->second.group_instance = dev.group_instance;
                known_it->second.timestamp_ms = 0;
                needs_refresh = true;
            }
        }

        for (auto it = known_instances_.begin(); it != known_instances_.end();) {
            if (active_group_device_ids.find(it->first) == active_group_device_ids.end()) {
                if (!it->second.group_instance.empty()) {
                    departed_instances.push_back(it->second.group_instance);
                }
                it = known_instances_.erase(it);
            } else {
                ++it;
            }
        }
    }

    for (const auto& departed : departed_instances) {
        devices_.clear_group_instance(departed);
    }

    if (needs_refresh) {
        CONNECT_LOGD("GroupDataEnricher: cluster contains unenriched group device(s); scheduling refresh");
        request_refresh_async();
    }
}

void GroupDataEnricher::on_device_removed_from_group(std::string_view group_device_id) {
    if (group_device_id.empty()) {
        return;
    }
    devices_.remove_group_device(group_device_id);
    notify_volume_enriched();
    notify_enriched();
}

void GroupDataEnricher::on_group_deleted(std::string_view group_instance) {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (group_instance.empty()) {
            known_instances_.clear();
        } else {
            for (auto it = known_instances_.begin(); it != known_instances_.end();) {
                if (it->second.group_instance == group_instance ||
                    it->first == group_instance) {
                    it = known_instances_.erase(it);
                } else {
                    ++it;
                }
            }
        }
    }
    devices_.clear_group_instance(group_instance);
    notify_volume_enriched();
    notify_enriched();
}

void GroupDataEnricher::request_refresh_async() {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!worker_running_ || stop_requested_) {
            return;
        }
        refresh_pending_ = true;
    }
    cv_.notify_one();
}

GroupDataHttpResult GroupDataEnricher::refresh_group_data() {
    RefreshGroupDataRequest req;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        req.known_instances.reserve(known_instances_.size());
        for (const auto& [dev_id, inst] : known_instances_) {
            if (!dev_id.empty()) {
                req.known_instances.push_back(inst);
            }
        }
    }

    GroupDataHttpResult res = client_.refresh_group_data(req);
    if (!res.ok) {
        CONNECT_LOGW(
            "GroupDataEnricher::refresh_group_data failed http=%d err=%s",
            res.http_status,
            res.error_message.c_str());
        return res;
    }

    if (res.response.has_value()) {
        const auto& payload = *res.response;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            for (const auto& gd : payload.group_data) {
                if (gd.spotify_device_id.empty()) {
                    continue;
                }
                known_instances_[gd.spotify_device_id] = KnownGroupInstance{
                    .spotify_device_id = gd.spotify_device_id,
                    .group_instance = gd.group_instance,
                    .timestamp_ms = gd.timestamp_ms,
                };
            }
        }

        if (!payload.group_data.empty()) {
            devices_.apply_group_data(payload.group_data);
            notify_enriched();
        }
        if (!payload.group_device_volumes.empty()) {
            devices_.apply_group_device_volumes(payload.group_device_volumes);
            notify_volume_enriched();
        }
        CONNECT_LOGI(
            "GroupDataEnricher: refresh_group_data applied groups=%zu volumes=%zu",
            payload.group_data.size(),
            payload.group_device_volumes.size());
    }
    return res;
}

size_t GroupDataEnricher::known_instance_count() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return known_instances_.size();
}

void GroupDataEnricher::worker_loop() {
    while (true) {
        {
            std::unique_lock<std::mutex> lock(mutex_);
            cv_.wait(lock, [this]() {
                return stop_requested_ || refresh_pending_;
            });
            if (stop_requested_) {
                break;
            }
            refresh_pending_ = false;
        }

        const GroupDataHttpResult res = refresh_group_data();
        if (!res.ok) {
            CONNECT_LOGD(
                "GroupDataEnricher worker refresh completed with error_code=%d",
                static_cast<int>(res.error_code));
        }
    }
}

}  // namespace spotify::connectstate
