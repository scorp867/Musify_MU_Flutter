// Replicated from liborbit-jni-spotify.so (ConnectDevicesImpl cluster, postponement, discovery):
// - Binary symbols / offsets:
//   - ConnectDevicesImpl::acquireClusterUpdatePostponementBlock @ 0xdbdd30..0xdbdd68
//   - ConnectDevicesImpl::releaseClusterUpdatePostponementBlock @ 0xdbdd6c..0xdbdda8 (refcount at [this, #0x2394])
//   - ConnectDevicesImpl::performDiscovery @ 0xdac4e0..0xdac59c (can_discover check)
//   - ConnectDevicesImpl::stopScanning @ 0xdaec9c..0xdaecdc
//   - ConnectDevicesImpl::fetchAndApplyCapabilities @ 0xdb1a60..0xdb1be0
//   - ConnectDevicesImpl::has_received_cluster_update_after_backend_connection (0x5de01b)
// - Java / Esperanto counterparts:
//   - p199p/s77.java (ConnectService.State, ClusterUpdateAfterBackendConnection, SetPreferredIncarnation, AddDeviceToGroup, RemoveDeviceFromGroup)
//   - p199p/C2086nd.java (ConnectService.PerformDiscovery, RefreshCluster)
//   - com/spotify/connect/esperanto/proto/ConnectMessages$StateResponse.java

#include "ConnectDevicesImpl.h"

#include <utility>

#include "ConnectStateClientImpl.h"

namespace spotify::connectstate {

ConnectDevicesImpl::ConnectDevicesImpl(ConnectStateClientImpl& client)
    : client_(client) {}

void ConnectDevicesImpl::set_local_device_info(DeviceInfo local_device) {
    std::lock_guard<std::mutex> lock(mutex_);
    local_device_info_ = std::move(local_device);
    if (!local_device_info_.device_id.empty()) {
        auto it = current_cluster_.devices.find(local_device_info_.device_id);
        if (it != current_cluster_.devices.end()) {
            it->second.volume = local_device_info_.volume;
        }
    }
}

DeviceInfo ConnectDevicesImpl::local_device_info() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return local_device_info_;
}

std::string ConnectDevicesImpl::local_device_id() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return local_device_info_.device_id;
}

void ConnectDevicesImpl::set_preferred_incarnation(std::string incarnation) {
    std::lock_guard<std::mutex> lock(mutex_);
    preferred_incarnation_ = std::move(incarnation);
}

std::string ConnectDevicesImpl::preferred_incarnation() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return preferred_incarnation_;
}

void ConnectDevicesImpl::on_backend_connected() {
    std::lock_guard<std::mutex> lock(mutex_);
    backend_connected_ = true;
    has_received_cluster_after_connect_ = false;
}

void ConnectDevicesImpl::on_backend_disconnected() {
    std::lock_guard<std::mutex> lock(mutex_);
    backend_connected_ = false;
    has_received_cluster_after_connect_ = false;
}

bool ConnectDevicesImpl::is_backend_connected() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return backend_connected_;
}

bool ConnectDevicesImpl::has_received_cluster_update_after_backend_connection() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return has_received_cluster_after_connect_;
}

int32_t ConnectDevicesImpl::acquire_cluster_update_postponement_block() {
    std::lock_guard<std::mutex> lock(mutex_);
    ++postponement_count_;
    return postponement_count_;
}

int32_t ConnectDevicesImpl::release_cluster_update_postponement_block() {
    struct FlushItem {
        Cluster cluster;
        ClusterUpdateReason reason;
        std::vector<ClusterListener> cluster_listeners;
        std::vector<DodoListener> dodo_listeners;
        std::vector<SingleDodo> dodos;
    };

    std::vector<FlushItem> flushed;
    int32_t remaining = 0;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (postponement_count_ > 0) {
            --postponement_count_;
        }
        remaining = postponement_count_;

        if (postponement_count_ == 0 && !postponed_updates_.empty()) {
            while (!postponed_updates_.empty()) {
                auto item = std::move(postponed_updates_.front());
                postponed_updates_.pop_front();
                FlushItem f{};
                f.reason = item.reason;
                commit_cluster_locked(
                    item.cluster,
                    item.reason,
                    f.cluster_listeners,
                    f.dodo_listeners,
                    f.cluster,
                    f.dodos);
                flushed.push_back(std::move(f));
            }
        }
    }

    for (const auto& f : flushed) {
        for (const auto& cb : f.cluster_listeners) {
            if (cb) {
                cb(f.cluster, f.reason);
            }
        }
        for (const auto& cb : f.dodo_listeners) {
            if (cb) {
                cb(f.dodos);
            }
        }
    }

    return remaining;
}

int32_t ConnectDevicesImpl::postponement_block_count() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return postponement_count_;
}

size_t ConnectDevicesImpl::postponed_update_count() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return postponed_updates_.size();
}

void ConnectDevicesImpl::apply_cluster_update(const ClusterUpdate& update) {
    apply_cluster_snapshot(update.cluster, update.update_reason);
}

void ConnectDevicesImpl::apply_cluster_snapshot(
    const Cluster& cluster,
    ClusterUpdateReason reason) {
    std::vector<ClusterListener> cluster_listeners_copy;
    std::vector<DodoListener> dodo_listeners_copy;
    Cluster cluster_copy;
    std::vector<SingleDodo> dodos_copy;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (postponement_count_ > 0) {
            postponed_updates_.push_back(PostponedUpdate{
                .cluster = cluster,
                .reason = reason,
            });
            return;
        }
        commit_cluster_locked(
            cluster,
            reason,
            cluster_listeners_copy,
            dodo_listeners_copy,
            cluster_copy,
            dodos_copy);
    }

    for (const auto& cb : cluster_listeners_copy) {
        if (cb) {
            cb(cluster_copy, reason);
        }
    }
    for (const auto& cb : dodo_listeners_copy) {
        if (cb) {
            cb(dodos_copy);
        }
    }
}

void ConnectDevicesImpl::commit_cluster_locked(
    const Cluster& cluster,
    ClusterUpdateReason reason,
    std::vector<ClusterListener>& out_cluster_listeners,
    std::vector<DodoListener>& out_dodo_listeners,
    Cluster& out_cluster_copy,
    std::vector<SingleDodo>& out_dodos_copy) {
    (void)reason;
    current_cluster_ = cluster;
    if (backend_connected_) {
        has_received_cluster_after_connect_ = true;
    }

    out_cluster_copy = current_cluster_;
    out_dodos_copy = build_dodo_list(current_cluster_);

    out_cluster_listeners.reserve(cluster_listeners_.size());
    for (const auto& [id, cb] : cluster_listeners_) {
        (void)id;
        out_cluster_listeners.push_back(cb);
    }
    out_dodo_listeners.reserve(dodo_listeners_.size());
    for (const auto& [id, cb] : dodo_listeners_) {
        (void)id;
        out_dodo_listeners.push_back(cb);
    }
}

std::vector<SingleDodo> ConnectDevicesImpl::build_dodo_list(const Cluster& cluster) {
    std::vector<SingleDodo> result;
    result.reserve(cluster.dodo_devices.size());
    for (size_t i = 0; i < cluster.dodo_devices.size(); ++i) {
        const auto& dodo = cluster.dodo_devices[i];
        SingleDodo s;
        s.dodo_id = dodo.cs_id;
        s.cs_id = dodo.cs_id;
        s.is_primary = (dodo.cs_id == cluster.active_device_id) ||
                       (i == 0 && cluster.active_device_id.empty());
        s.is_being_observed = dodo.player_state_summary.is_playing ||
                              dodo.player_state_summary.is_paused;
        result.push_back(std::move(s));
    }
    return result;
}

Cluster ConnectDevicesImpl::current_cluster() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return current_cluster_;
}

std::optional<DeviceInfo> ConnectDevicesImpl::find_device(std::string_view device_id) const {
    std::lock_guard<std::mutex> lock(mutex_);
    const auto it = current_cluster_.devices.find(std::string(device_id));
    if (it == current_cluster_.devices.end()) {
        return std::nullopt;
    }
    return it->second;
}

std::optional<DeviceInfo> ConnectDevicesImpl::active_device() const {
    std::lock_guard<std::mutex> lock(mutex_);
    if (current_cluster_.active_device_id.empty()) {
        return std::nullopt;
    }
    const auto it = current_cluster_.devices.find(current_cluster_.active_device_id);
    if (it == current_cluster_.devices.end()) {
        return std::nullopt;
    }
    return it->second;
}

std::string ConnectDevicesImpl::active_device_id() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return current_cluster_.active_device_id;
}

bool ConnectDevicesImpl::is_local_device_active() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return !local_device_info_.device_id.empty() &&
           current_cluster_.active_device_id == local_device_info_.device_id;
}

uint32_t ConnectDevicesImpl::device_volume(std::string_view device_id) const {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!local_device_info_.device_id.empty() &&
        device_id == local_device_info_.device_id) {
        return local_device_info_.volume;
    }
    const auto it = current_cluster_.devices.find(std::string(device_id));
    if (it != current_cluster_.devices.end()) {
        return it->second.volume;
    }
    return 0;
}

std::vector<SingleDodo> ConnectDevicesImpl::dodos_snapshot() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return build_dodo_list(current_cluster_);
}

uint64_t ConnectDevicesImpl::add_cluster_listener(ClusterListener listener) {
    std::lock_guard<std::mutex> lock(mutex_);
    const uint64_t id = next_listener_id_++;
    cluster_listeners_.emplace_back(id, std::move(listener));
    return id;
}

void ConnectDevicesImpl::remove_cluster_listener(uint64_t listener_id) {
    std::lock_guard<std::mutex> lock(mutex_);
    for (auto it = cluster_listeners_.begin(); it != cluster_listeners_.end(); ++it) {
        if (it->first == listener_id) {
            cluster_listeners_.erase(it);
            return;
        }
    }
}

uint64_t ConnectDevicesImpl::add_dodo_listener(DodoListener listener) {
    std::lock_guard<std::mutex> lock(mutex_);
    const uint64_t id = next_listener_id_++;
    dodo_listeners_.emplace_back(id, std::move(listener));
    return id;
}

void ConnectDevicesImpl::remove_dodo_listener(uint64_t listener_id) {
    std::lock_guard<std::mutex> lock(mutex_);
    for (auto it = dodo_listeners_.begin(); it != dodo_listeners_.end(); ++it) {
        if (it->first == listener_id) {
            dodo_listeners_.erase(it);
            return;
        }
    }
}

void ConnectDevicesImpl::set_can_discover(bool can_discover) {
    std::lock_guard<std::mutex> lock(mutex_);
    can_discover_ = can_discover;
    if (!can_discover_) {
        scanning_ = false;
    }
}

bool ConnectDevicesImpl::can_discover() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return can_discover_;
}

bool ConnectDevicesImpl::perform_discovery() {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!can_discover_) {
            return false;
        }
        scanning_ = true;
    }
    const auto wake_res = client_.wake_up_sleeping_cluster();
    return wake_res.ok;
}

void ConnectDevicesImpl::stop_scanning() {
    std::lock_guard<std::mutex> lock(mutex_);
    scanning_ = false;
}

bool ConnectDevicesImpl::is_scanning() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return scanning_;
}

void ConnectDevicesImpl::set_capability_fetcher(CapabilityFetcher fetcher) {
    std::lock_guard<std::mutex> lock(mutex_);
    capability_fetcher_ = std::move(fetcher);
}

bool ConnectDevicesImpl::fetch_and_apply_capabilities(int32_t max_retries) {
    CapabilityFetcher fetcher;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        fetcher = capability_fetcher_;
        last_capability_retry_count_ = 0;
    }

    if (!fetcher) {
        return true;
    }

    const int32_t attempts = max_retries >= 0 ? max_retries + 1 : 1;
    for (int32_t attempt = 0; attempt < attempts; ++attempt) {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            last_capability_retry_count_ = attempt;
        }
        const CapabilityFetchResult res = fetcher();
        if (res.ok) {
            std::lock_guard<std::mutex> lock(mutex_);
            local_device_info_.capabilities = res.capabilities;
            return true;
        }
    }
    return false;
}

int32_t ConnectDevicesImpl::last_capability_retry_count() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return last_capability_retry_count_;
}

void ConnectDevicesImpl::reset() {
    std::lock_guard<std::mutex> lock(mutex_);
    current_cluster_ = Cluster{};
    backend_connected_ = false;
    has_received_cluster_after_connect_ = false;
    postponement_count_ = 0;
    postponed_updates_.clear();
    scanning_ = false;
    last_capability_retry_count_ = 0;
}

}  // namespace spotify::connectstate
