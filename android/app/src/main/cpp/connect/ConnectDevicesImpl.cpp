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
//   - PutState response cluster race guard @ 0xdb2e84..0xdb3048 -> 0xdb3154 (`0x39e395`)
// ============================================================================

#include "ConnectDevicesImpl.h"

#include "../network/NativeLog.h"
#include "ConnectStateClientImpl.h"

#include <algorithm>
#include <unordered_set>
#include <utility>

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
            it->second.has_volume = local_device_info_.has_volume;
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
    has_committed_cluster_ = false;
}

void ConnectDevicesImpl::on_backend_disconnected() {
    std::lock_guard<std::mutex> lock(mutex_);
    backend_connected_ = false;
    has_received_cluster_after_connect_ = false;
    has_committed_cluster_ = false;
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
                if (commit_cluster_locked(
                        item.cluster,
                        item.reason,
                        f.cluster_listeners,
                        f.dodo_listeners,
                        f.cluster,
                        f.dodos)) {
                    flushed.push_back(std::move(f));
                }
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

    bool committed = false;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (postponement_count_ > 0) {
            postponed_updates_.push_back(PostponedUpdate{
                .cluster = cluster,
                .reason = reason,
            });
            return;
        }
        committed = commit_cluster_locked(
            cluster,
            reason,
            cluster_listeners_copy,
            dodo_listeners_copy,
            cluster_copy,
            dodos_copy);
    }

    if (!committed) {
        return;
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

bool ConnectDevicesImpl::commit_cluster_locked(
    const Cluster& cluster,
    ClusterUpdateReason /*reason*/,
    std::vector<ClusterListener>& out_cluster_listeners,
    std::vector<DodoListener>& out_dodo_listeners,
    Cluster& out_cluster_copy,
    std::vector<SingleDodo>& out_dodos_copy) {
    // 1:1 with liborbit PutState response race guard (0xdb2e84..0xdb3048 -> 0xdb3154):
    // Reject strictly older out-of-order cluster snapshots using lexicographic ordering
    // on `(changed_timestamp_ms, server_timestamp_ms)` so a delayed HTTP PutState response
    // never clobbers a newer Dealer ClusterUpdate, while a strictly newer mutation
    // (`changed_timestamp_ms > current`) is never dropped by edge replica NTP skew in
    // `server_timestamp_ms`. Equal timestamps remain accepted for group enrichment.
    if (has_committed_cluster_) {
        const bool older_server_ts =
            cluster.server_timestamp_ms > 0 &&
            current_cluster_.server_timestamp_ms > 0 &&
            cluster.server_timestamp_ms < current_cluster_.server_timestamp_ms;
        bool is_stale = false;
        if (cluster.changed_timestamp_ms > 0 && current_cluster_.changed_timestamp_ms > 0) {
            if (cluster.changed_timestamp_ms < current_cluster_.changed_timestamp_ms) {
                is_stale = true;
            } else if (cluster.changed_timestamp_ms == current_cluster_.changed_timestamp_ms) {
                is_stale = older_server_ts;
            }
        } else {
            is_stale = older_server_ts;
        }
        if (is_stale) {
            CONNECT_LOGI(
                "ConnectDevicesImpl::commit_cluster_locked: rejecting stale cluster snapshot "
                "(incoming server=%lld changed=%lld active=%s vs current server=%lld changed=%lld active=%s)",
                static_cast<long long>(cluster.server_timestamp_ms),
                static_cast<long long>(cluster.changed_timestamp_ms),
                cluster.active_device_id.c_str(),
                static_cast<long long>(current_cluster_.server_timestamp_ms),
                static_cast<long long>(current_cluster_.changed_timestamp_ms),
                current_cluster_.active_device_id.c_str());
            return false;
        }
    }

    current_cluster_ = cluster;
    has_committed_cluster_ = true;
    if (backend_connected_) {
        has_received_cluster_after_connect_ = true;
    }

    out_cluster_copy = current_cluster_;
    out_dodos_copy = build_dodo_list(current_cluster_);

    out_cluster_listeners.reserve(cluster_listeners_.size());
    for (const auto& entry : cluster_listeners_) {
        out_cluster_listeners.push_back(entry.second);
    }
    out_dodo_listeners.reserve(dodo_listeners_.size());
    for (const auto& entry : dodo_listeners_) {
        out_dodo_listeners.push_back(entry.second);
    }
    return true;
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

DeviceInfo ConnectDevicesImpl::synthesize_device_from_local(const DiscoveredLocalEntry& entry) {
    const LocalDevice& ld = entry.device;
    DeviceInfo info;
    info.can_play = ld.supports_on_demand || true;
    info.volume = 65535;
    info.has_volume = false;
    info.name = ld.device_name;
    info.device_type = ld.device_type;
    info.device_id = ld.device_id;
    info.client_id = ld.client_id;
    info.brand = ld.brand;
    info.model = ld.model;
    info.product_id = ld.product_id;
    info.deduplication_id = entry.deduplication_id.empty() ? ld.device_id : entry.deduplication_id;
    info.selected_alias_id = ld.alias_id;
    info.public_ip = ld.local_ip;
    info.license = ld.license;
    info.is_locally_discovered = true;
    info.is_offline = false;
    info.is_public = false;
    info.is_wol_capable = ld.wol_info.has_value();
    info.capabilities.supported_types = ld.supported_media_types;
    info.capabilities.supports_dj = ld.supports_dj;
    info.capabilities.is_voice_enabled = ld.is_voice_enabled;
    info.capabilities.supports_hifi = ld.supports_hifi;
    info.capabilities.connect_capabilities = ld.connect_capabilities;
    info.capabilities.supports_external_episodes = ld.supports_external_episodes;
    info.disallow_transfer_reasons = ld.disallow_reasons;
    return info;
}

void ConnectDevicesImpl::apply_local_devices(std::vector<DiscoveredLocalEntry> entries) {
    std::lock_guard<std::mutex> lock(mutex_);
    discovered_local_entries_ = std::move(entries);
    CONNECT_LOGD("Updated locally discovered Connect devices: count=%zu",
                 discovered_local_entries_.size());
}

std::vector<LocalDevice> ConnectDevicesImpl::local_devices_snapshot() const {
    std::lock_guard<std::mutex> lock(mutex_);
    std::vector<LocalDevice> out;
    out.reserve(discovered_local_entries_.size());
    for (const auto& entry : discovered_local_entries_) {
        out.push_back(entry.device);
    }
    return out;
}

std::vector<DeviceInfo> ConnectDevicesImpl::merged_devices_snapshot() const {
    std::lock_guard<std::mutex> lock(mutex_);

    // Start with all Connect-State cluster devices keyed by device_id.
    std::unordered_map<std::string, DeviceInfo> merged_by_id = current_cluster_.devices;
    std::unordered_map<std::string, std::string> dedup_to_device_id;
    for (const auto& [id, dev] : merged_by_id) {
        if (!dev.deduplication_id.empty()) {
            dedup_to_device_id[dev.deduplication_id] = id;
        }
    }

    // Merge/deduplicate ZEROCONF/CAST/DIAL local incarnations against cluster devices.
    for (const auto& local_entry : discovered_local_entries_) {
        const std::string& ld_id = local_entry.device.device_id;
        if (ld_id.empty()) {
            continue;
        }
        if (!local_device_info_.device_id.empty() && ld_id == local_device_info_.device_id) {
            continue;
        }

        std::string matched_id;
        if (merged_by_id.find(ld_id) != merged_by_id.end()) {
            matched_id = ld_id;
        } else if (!local_entry.deduplication_id.empty()) {
            const auto dit = dedup_to_device_id.find(local_entry.deduplication_id);
            if (dit != dedup_to_device_id.end()) {
                matched_id = dit->second;
            }
        }

        if (!matched_id.empty()) {
            DeviceInfo& existing = merged_by_id[matched_id];
            existing.is_locally_discovered = true;
            if (existing.public_ip.empty() && !local_entry.device.local_ip.empty()) {
                existing.public_ip = local_entry.device.local_ip;
            }
            if (existing.deduplication_id.empty() && !local_entry.deduplication_id.empty()) {
                existing.deduplication_id = local_entry.deduplication_id;
            }
        } else {
            DeviceInfo synthesized = synthesize_device_from_local(local_entry);
            if (!synthesized.deduplication_id.empty()) {
                dedup_to_device_id[synthesized.deduplication_id] = ld_id;
            }
            merged_by_id[ld_id] = std::move(synthesized);
        }
    }

    std::vector<DeviceInfo> out;
    out.reserve(merged_by_id.size());
    for (auto& [id, dev] : merged_by_id) {
        out.push_back(std::move(dev));
    }
    std::sort(out.begin(), out.end(), [](const DeviceInfo& a, const DeviceInfo& b) {
        return a.device_id < b.device_id;
    });
    return out;
}

std::vector<Incarnation> ConnectDevicesImpl::incarnations_for_device(
    std::string_view device_id,
    std::string_view deduplication_id) const {
    std::lock_guard<std::mutex> lock(mutex_);
    std::vector<Incarnation> result;
    const std::string dev_id_str(device_id);
    const std::string dedup_str(deduplication_id);

    const bool in_cluster =
        !dev_id_str.empty() &&
        (current_cluster_.devices.find(dev_id_str) != current_cluster_.devices.end() ||
         dev_id_str == local_device_info_.device_id);
    if (in_cluster) {
        Incarnation inc;
        inc.type = IncarnationType::CONNECT;
        inc.identifier = dev_id_str;
        inc.connect_state_identifier = dev_id_str;
        inc.preferred = (preferred_incarnation_ == dev_id_str);
        result.push_back(std::move(inc));
    }

    for (const auto& entry : discovered_local_entries_) {
        const bool match_id = !dev_id_str.empty() && entry.device.device_id == dev_id_str;
        const bool match_dedup =
            !dedup_str.empty() &&
            (!entry.deduplication_id.empty() && entry.deduplication_id == dedup_str);
        if (!match_id && !match_dedup) {
            continue;
        }
        bool duplicate = false;
        for (const auto& existing : result) {
            if (existing.type == entry.incarnation_type &&
                existing.identifier == entry.device.device_id) {
                duplicate = true;
                break;
            }
        }
        if (duplicate) {
            continue;
        }
        Incarnation inc;
        inc.type = entry.incarnation_type;
        inc.identifier = entry.device.device_id;
        inc.connect_state_identifier = in_cluster ? dev_id_str : entry.device.device_id;
        inc.local_ip = entry.device.local_ip;
        inc.port = entry.port;
        inc.preferred = (preferred_incarnation_ == entry.device.device_id &&
                         inc.type != IncarnationType::CONNECT);
        result.push_back(std::move(inc));
    }
    return result;
}

void ConnectDevicesImpl::apply_group_data(const std::vector<ConnectGroupData>& groups) {
    std::lock_guard<std::mutex> lock(mutex_);
    for (const auto& gd : groups) {
        if (gd.spotify_device_id.empty()) {
            continue;
        }
        const auto it = group_data_by_device_id_.find(gd.spotify_device_id);
        if (it != group_data_by_device_id_.end() &&
            it->second.timestamp_ms > 0 && gd.timestamp_ms > 0 &&
            gd.timestamp_ms < it->second.timestamp_ms) {
            continue;
        }
        group_data_by_device_id_[gd.spotify_device_id] = gd;
    }
}

void ConnectDevicesImpl::apply_group_device_volumes(
    const std::vector<ConnectGroupDeviceVolume>& volumes) {
    std::lock_guard<std::mutex> lock(mutex_);
    for (const auto& vol : volumes) {
        if (vol.group_device_identifier.empty()) {
            continue;
        }
        const auto it = group_volumes_by_member_id_.find(vol.group_device_identifier);
        if (it != group_volumes_by_member_id_.end() &&
            it->second.timestamp_ms > 0 && vol.timestamp_ms > 0 &&
            vol.timestamp_ms < it->second.timestamp_ms) {
            continue;
        }
        group_volumes_by_member_id_[vol.group_device_identifier] = vol;
    }
}

void ConnectDevicesImpl::remove_group_device(std::string_view group_device_id) {
    if (group_device_id.empty()) {
        return;
    }
    const std::string key(group_device_id);
    std::lock_guard<std::mutex> lock(mutex_);
    group_volumes_by_member_id_.erase(key);
    for (auto& [dev_id, gd] : group_data_by_device_id_) {
        auto& members = gd.grouped_devices;
        members.erase(
            std::remove_if(
                members.begin(),
                members.end(),
                [&key](const ConnectGroupedDevice& d) {
                    return d.group_device_identifier == key;
                }),
            members.end());
    }
}

void ConnectDevicesImpl::clear_group_instance(std::string_view group_instance) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (group_instance.empty()) {
        group_data_by_device_id_.clear();
        group_volumes_by_member_id_.clear();
        return;
    }
    for (auto it = group_data_by_device_id_.begin(); it != group_data_by_device_id_.end();) {
        if (it->second.group_instance == group_instance || it->first == group_instance) {
            it = group_data_by_device_id_.erase(it);
        } else {
            ++it;
        }
    }
    for (auto it = group_volumes_by_member_id_.begin(); it != group_volumes_by_member_id_.end();) {
        if (it->second.group_instance == group_instance ||
            it->second.spotify_device_id == group_instance) {
            it = group_volumes_by_member_id_.erase(it);
        } else {
            ++it;
        }
    }
}

std::optional<ConnectGroupData> ConnectDevicesImpl::group_data_for_device(
    std::string_view spotify_device_id) const {
    std::lock_guard<std::mutex> lock(mutex_);
    const auto it = group_data_by_device_id_.find(std::string(spotify_device_id));
    if (it == group_data_by_device_id_.end()) {
        return std::nullopt;
    }
    return it->second;
}

std::unordered_map<std::string, ConnectGroupDeviceVolume>
ConnectDevicesImpl::group_device_volumes_snapshot() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return group_volumes_by_member_id_;
}

std::unordered_map<std::string, uint32_t>
ConnectDevicesImpl::group_device_volume_values_snapshot() const {
    std::lock_guard<std::mutex> lock(mutex_);
    std::unordered_map<std::string, uint32_t> out;
    out.reserve(group_volumes_by_member_id_.size());
    for (const auto& [member_id, vol] : group_volumes_by_member_id_) {
        out[member_id] = vol.volume;
    }
    return out;
}

Cluster ConnectDevicesImpl::current_cluster() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return current_cluster_;
}

std::optional<DeviceInfo> ConnectDevicesImpl::find_device(std::string_view device_id) const {
    std::lock_guard<std::mutex> lock(mutex_);
    const auto it = current_cluster_.devices.find(std::string(device_id));
    if (it != current_cluster_.devices.end()) {
        return it->second;
    }
    for (const auto& local_entry : discovered_local_entries_) {
        if (local_entry.device.device_id == device_id) {
            return synthesize_device_from_local(local_entry);
        }
    }
    return std::nullopt;
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
    const auto git = group_volumes_by_member_id_.find(std::string(device_id));
    if (git != group_volumes_by_member_id_.end()) {
        return git->second.volume;
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
            CONNECT_LOGD("perform_discovery skipped: can_discover=false");
            return false;
        }
        scanning_ = true;
    }
    const auto wake_res = client_.wake_up_sleeping_cluster();
    if (!wake_res.ok) {
        CONNECT_LOGW("perform_discovery wake_up_sleeping_cluster failed: status=%d err='%s'",
                     wake_res.http_status,
                     wake_res.error_message.c_str());
    }
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
        CONNECT_LOGW("fetch_and_apply_capabilities attempt %d/%d failed: %s",
                     attempt + 1,
                     attempts,
                     res.error_message.c_str());
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
    has_committed_cluster_ = false;
    discovered_local_entries_.clear();
    group_data_by_device_id_.clear();
    group_volumes_by_member_id_.clear();
    backend_connected_ = false;
    has_received_cluster_after_connect_ = false;
    postponement_count_ = 0;
    postponed_updates_.clear();
    scanning_ = false;
    last_capability_retry_count_ = 0;
}

}  // namespace spotify::connectstate
