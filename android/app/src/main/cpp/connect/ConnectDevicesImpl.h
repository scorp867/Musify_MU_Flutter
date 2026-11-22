// ============================================================================
// Replicated from liborbit-jni-spotify.so (ConnectDevicesImpl cluster,
// postponement, discovery, incarnation deduplication & group enrichment):
// - Binary symbols / offsets:
//   - ConnectDevicesImpl::acquireClusterUpdatePostponementBlock @ 0xdbdd30..0xdbdd68
//   - ConnectDevicesImpl::releaseClusterUpdatePostponementBlock @ 0xdbdd6c..0xdbdda8
//   - ConnectDevicesImpl::performDiscovery @ 0xdac4e0..0xdac59c
//   - ConnectDevicesImpl::stopScanning @ 0xdaec9c..0xdaecdc
//   - ConnectDevicesImpl::fetchAndApplyCapabilities @ 0xdb1a60..0xdb1be0
//   - ConnectDevicesImpl incarnation deduplication @ 0xdad978..0xdae530
//   - ConnectDevicesImpl::has_received_cluster_update_after_backend_connection (0x5de01b)
//   - PutState response cluster race guard @ 0xdb2e84..0xdb3048 -> 0xdb3154 (`0x39e395`)
// ============================================================================

#ifndef MUSIFY_CONNECT_CONNECT_DEVICES_IMPL_H_
#define MUSIFY_CONNECT_CONNECT_DEVICES_IMPL_H_

#include <cstdint>
#include <deque>
#include <functional>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>
#include <vector>

#include "ConnectStateProtos.h"

namespace spotify::connectstate {

class ConnectStateClientImpl;

struct CapabilityFetchResult {
    bool ok{false};
    Capabilities capabilities;
    std::string error_message;
};

struct DiscoveredLocalEntry {
    LocalDevice device;
    IncarnationType incarnation_type{IncarnationType::ZEROCONF};
    uint16_t port{0};
    std::string deduplication_id;
};

class ConnectDevicesImpl {
public:
    static constexpr int32_t kDefaultCapabilityMaxRetries = 3;

    using ClusterListener =
        std::function<void(const Cluster&, ClusterUpdateReason)>;
    using DodoListener =
        std::function<void(const std::vector<SingleDodo>&)>;
    using CapabilityFetcher = std::function<CapabilityFetchResult()>;

    explicit ConnectDevicesImpl(ConnectStateClientImpl& client);
    ~ConnectDevicesImpl() = default;

    ConnectDevicesImpl(const ConnectDevicesImpl&) = delete;
    ConnectDevicesImpl& operator=(const ConnectDevicesImpl&) = delete;

    void set_local_device_info(DeviceInfo local_device);
    [[nodiscard]] DeviceInfo local_device_info() const;
    [[nodiscard]] std::string local_device_id() const;

    void set_preferred_incarnation(std::string incarnation);
    [[nodiscard]] std::string preferred_incarnation() const;

    void on_backend_connected();
    void on_backend_disconnected();
    [[nodiscard]] bool is_backend_connected() const;
    [[nodiscard]] bool has_received_cluster_update_after_backend_connection() const;

    // Reference-counted cluster update postponement (liborbit @ 0xdbdd30..0xdbdda8).
    int32_t acquire_cluster_update_postponement_block();
    int32_t release_cluster_update_postponement_block();
    [[nodiscard]] int32_t postponement_block_count() const;
    [[nodiscard]] size_t postponed_update_count() const;

    // Applies an incoming ClusterUpdate (from Dealer) or full Cluster (from PutState/SetDoDo).
    void apply_cluster_update(const ClusterUpdate& update);
    void apply_cluster_snapshot(
        const Cluster& cluster,
        ClusterUpdateReason reason = ClusterUpdateReason::DEVICE_STATE_CHANGED);

    [[nodiscard]] Cluster current_cluster() const;
    [[nodiscard]] std::optional<DeviceInfo> find_device(std::string_view device_id) const;
    [[nodiscard]] std::optional<DeviceInfo> active_device() const;
    [[nodiscard]] std::string active_device_id() const;
    [[nodiscard]] bool is_local_device_active() const;
    [[nodiscard]] uint32_t device_volume(std::string_view device_id) const;
    [[nodiscard]] std::vector<SingleDodo> dodos_snapshot() const;

    // Local network discovery & incarnation deduplication (CONNECT/ZEROCONF/CAST/DIAL).
    void apply_local_devices(std::vector<DiscoveredLocalEntry> entries);
    [[nodiscard]] std::vector<LocalDevice> local_devices_snapshot() const;
    [[nodiscard]] std::vector<DeviceInfo> merged_devices_snapshot() const;
    [[nodiscard]] std::vector<Incarnation> incarnations_for_device(
        std::string_view device_id,
        std::string_view deduplication_id = {}) const;

    // Group data & member volume enrichment (driven by GroupDataEnricher).
    void apply_group_data(const std::vector<ConnectGroupData>& groups);
    void apply_group_device_volumes(const std::vector<ConnectGroupDeviceVolume>& volumes);
    void remove_group_device(std::string_view group_device_id);
    void clear_group_instance(std::string_view group_instance);
    [[nodiscard]] std::optional<ConnectGroupData> group_data_for_device(
        std::string_view spotify_device_id) const;
    [[nodiscard]] std::unordered_map<std::string, ConnectGroupDeviceVolume>
    group_device_volumes_snapshot() const;
    [[nodiscard]] std::unordered_map<std::string, uint32_t>
    group_device_volume_values_snapshot() const;

    // Listeners (returns subscription ID for removal).
    uint64_t add_cluster_listener(ClusterListener listener);
    void remove_cluster_listener(uint64_t listener_id);

    uint64_t add_dodo_listener(DodoListener listener);
    void remove_dodo_listener(uint64_t listener_id);

    // Discovery & scanning lifecycle (0xdac4e0..0xdac59c, 0xdaec9c..0xdaecdc).
    void set_can_discover(bool can_discover);
    [[nodiscard]] bool can_discover() const;
    bool perform_discovery();
    void stop_scanning();
    [[nodiscard]] bool is_scanning() const;

    // Capabilities fetch & retry loop (0xdb1a60..0xdb1be0).
    void set_capability_fetcher(CapabilityFetcher fetcher);
    bool fetch_and_apply_capabilities(int32_t max_retries = kDefaultCapabilityMaxRetries);
    [[nodiscard]] int32_t last_capability_retry_count() const;

    void reset();

private:
    struct PostponedUpdate {
        Cluster cluster;
        ClusterUpdateReason reason{ClusterUpdateReason::UNKNOWN_CLUSTER_UPDATE_REASON};
    };

    bool commit_cluster_locked(
        const Cluster& cluster,
        ClusterUpdateReason reason,
        std::vector<ClusterListener>& out_cluster_listeners,
        std::vector<DodoListener>& out_dodo_listeners,
        Cluster& out_cluster_copy,
        std::vector<SingleDodo>& out_dodos_copy);

    static std::vector<SingleDodo> build_dodo_list(const Cluster& cluster);
    static DeviceInfo synthesize_device_from_local(const DiscoveredLocalEntry& entry);

    ConnectStateClientImpl& client_;
    mutable std::mutex mutex_;

    DeviceInfo local_device_info_;
    std::string preferred_incarnation_;
    Cluster current_cluster_;
    bool has_committed_cluster_{false};

    std::vector<DiscoveredLocalEntry> discovered_local_entries_;
    std::unordered_map<std::string, ConnectGroupData> group_data_by_device_id_;
    std::unordered_map<std::string, ConnectGroupDeviceVolume> group_volumes_by_member_id_;

    bool backend_connected_{false};
    bool has_received_cluster_after_connect_{false};

    int32_t postponement_count_{0};
    std::deque<PostponedUpdate> postponed_updates_;

    bool can_discover_{true};
    bool scanning_{false};

    CapabilityFetcher capability_fetcher_;
    int32_t last_capability_retry_count_{0};

    uint64_t next_listener_id_{1};
    std::vector<std::pair<uint64_t, ClusterListener>> cluster_listeners_;
    std::vector<std::pair<uint64_t, DodoListener>> dodo_listeners_;
};

}  // namespace spotify::connectstate

#endif  // MUSIFY_CONNECT_CONNECT_DEVICES_IMPL_H_
