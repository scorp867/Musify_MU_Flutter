// ============================================================================
// Replicated Spotify Connect-Group v1 Data & Volume Enricher
// Sources (`liborbit-jni-spotify.so` arm64):
// - Dealer topic `hm://connect-group/v1/group-data-event` (0x39aac6 @ 0xd9f810)
// - Dealer topic `hm://connect-group/v1/group-device-volume-event` (0x34e81a @ 0xd9f85c)
// - HTTP `POST connect-group/v1/refresh-group-data` (0x389e83 @ 0xda0740)
// - Group enrichment & cluster correlation (`0xda0590..0xda1818`)
// ============================================================================

#ifndef MUSIFY_CONNECT_GROUP_DATA_ENRICHER_H_
#define MUSIFY_CONNECT_GROUP_DATA_ENRICHER_H_

#include <condition_variable>
#include <cstdint>
#include <functional>
#include <mutex>
#include <string>
#include <string_view>
#include <thread>
#include <unordered_map>

#include "ConnectDevicesImpl.h"
#include "ConnectStateClientImpl.h"
#include "ConnectStateProtos.h"

namespace spotify::connectstate {

class GroupDataEnricher {
public:
    using EnrichedCallback = std::function<void()>;

    GroupDataEnricher(
        ConnectStateClientImpl& client,
        ConnectDevicesImpl& devices);

    ~GroupDataEnricher();

    GroupDataEnricher(const GroupDataEnricher&) = delete;
    GroupDataEnricher& operator=(const GroupDataEnricher&) = delete;

    void start();
    void stop();
    void reset();

    void set_enriched_callback(EnrichedCallback callback);
    void set_volume_enriched_callback(EnrichedCallback callback);

    // Processes inbound `hm://connect-group/v1/group-data-event` Dealer pushes.
    void on_group_data_event(const GroupDataEvent& event);

    // Processes inbound `hm://connect-group/v1/group-device-volume-event` Dealer pushes.
    void on_group_device_volume_event(const GroupDeviceVolumeEvent& event);

    // Evaluates cluster membership for group devices needing enrichment or pruning.
    // Schedules an off-thread `POST connect-group/v1/refresh-group-data` when needed.
    void on_cluster_updated(const Cluster& cluster);

    void on_device_removed_from_group(std::string_view group_device_id);
    void on_group_deleted(std::string_view group_instance);

    // Coalesced asynchronous trigger for `refresh_group_data()` (safe from Dealer thread).
    void request_refresh_async();

    // Synchronous execution of `POST connect-group/v1/refresh-group-data`.
    GroupDataHttpResult refresh_group_data();

    [[nodiscard]] size_t known_instance_count() const;

private:
    void worker_loop();
    void notify_enriched();
    void notify_volume_enriched();

    ConnectStateClientImpl& client_;
    ConnectDevicesImpl& devices_;

    mutable std::mutex mutex_;
    std::condition_variable cv_;
    std::unordered_map<std::string, KnownGroupInstance> known_instances_;
    EnrichedCallback enriched_callback_;
    EnrichedCallback volume_enriched_callback_;

    bool worker_running_{false};
    bool stop_requested_{false};
    bool refresh_pending_{false};
    std::thread worker_thread_;
};

}  // namespace spotify::connectstate

#endif  // MUSIFY_CONNECT_GROUP_DATA_ENRICHER_H_
