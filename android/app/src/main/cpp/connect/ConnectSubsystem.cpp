// ============================================================================
// Replicated from liborbit-jni-spotify.so (ConnectSubsystem bidirectional
// engine orchestrator + IRemotePlaybackDelegate bridge):
// - Binary symbols / offsets (`liborbit-jni-spotify.so` arm64):
//   - DealerWebSocketClient (0xdb4d9c..0xdb50c0),
//   - ConnectStateClientImpl (0xdc1b80..0xdc6310),
//   - PutStateBackoff (0xdc5e8c..0xdc6310),
//   - VolumeThrottler (0xdca2d4..0xdca6fc),
//   - ConnectDevicesImpl (0xdac4e0..0xdbddaa),
//   - TransferManager (0xdf16e8..0xdf4cf8),
//   - GroupDataEnricher (0xd9f810..0xda1818),
//   - StateRestoreController (`LoadLastTransferBlob` @ 0xdb4758, 5000ms @ 0xdb9e10),
//   - LocalDeviceReporter (0xdc3b90..0xdc42bc, 0xdcf304..0xdd232c, 0xdedec0..0xdeffff),
//   - ConnectStateImpl::onClusterChanged (0xdb6740..0xdb7060),
//   - ConnectApiImpl outbound remote command forward (0xda66f0..0xda96ac).
// - Esperanto service contracts:
//   - ConnectService (.so @ 0x3a20cd), ConnectVolumeService (.so @ 0x343b80),
//     DodoService (.so @ 0x36a9f8)
// - Java / Esperanto counterparts:
//   - com/spotify/core/corefullimpl/NativeFullAuthenticatedScopeImpl.java
//   - p199p/s77.java, p199p/c8k.java, p199p/C2086nd.java, p199p/a0f1.java, p199p/lw51.java
// ============================================================================

#include "ConnectSubsystem.h"

#include <algorithm>
#include <charconv>
#include <utility>

#include "../network/NativeLog.h"
#include "dealer/DealerMessageParser.h"
#include "dealer/WsCodec.h"

namespace spotify::connectstate {

namespace {

uint64_t current_epoch_ms() {
    const auto now = std::chrono::system_clock::now();
    return static_cast<uint64_t>(
        std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count());
}

bool is_active_playing_phase(player::ContextPlayerImpl::SessionPlaybackPhase phase) {
    return phase == player::ContextPlayerImpl::SessionPlaybackPhase::Playing ||
           phase == player::ContextPlayerImpl::SessionPlaybackPhase::BufferingPlay;
}

ProvidedTrack to_provided_track(const player::context_view::Entry& entry) {
    ProvidedTrack pt;
    pt.uri = entry.uri;
    pt.uid = entry.uid;
    pt.metadata = entry.metadata;
    pt.provider = entry.provider;
    if (const auto it = entry.metadata.find("album_uri");
        it != entry.metadata.end() && !it->second.empty()) {
        pt.album_uri = it->second;
    }
    if (const auto it = entry.metadata.find("artist_uri");
        it != entry.metadata.end() && !it->second.empty()) {
        pt.artist_uri = it->second;
    }
    return pt;
}

player::context_view::Entry from_provided_track(const ProvidedTrack& pt) {
    player::context_view::Entry entry;
    entry.type = player::ContextProcessor::is_delimiter(pt.uri)
                     ? player::context_view::EntryType::DELIMITER
                     : player::context_view::EntryType::TRACK;
    entry.uri = pt.uri;
    entry.uid = pt.uid;
    entry.provider = pt.provider;
    entry.metadata = pt.metadata;
    if (!pt.album_uri.empty()) {
        const auto it = entry.metadata.find("album_uri");
        if (it == entry.metadata.end() || it->second.empty()) {
            entry.metadata["album_uri"] = pt.album_uri;
        }
    }
    if (!pt.artist_uri.empty()) {
        const auto it = entry.metadata.find("artist_uri");
        if (it == entry.metadata.end() || it->second.empty()) {
            entry.metadata["artist_uri"] = pt.artist_uri;
        }
    }
    return entry;
}

uint64_t parse_uint64_strict(std::string_view text) noexcept {
    if (text.empty()) {
        return 0;
    }
    uint64_t val = 0;
    const auto res = std::from_chars(text.data(), text.data() + text.size(), val);
    if (res.ec != std::errc{} || res.ptr != text.data() + text.size()) {
        return 0;
    }
    return val;
}

std::string default_platform_for_device_type(DeviceType device_type) {
    switch (device_type) {
        case DeviceType::SMARTPHONE:
        case DeviceType::TABLET:
        case DeviceType::CHROMEBOOK:
        case DeviceType::AUTOMOBILE:
        case DeviceType::SMARTWATCH:
            return "Android";
        case DeviceType::COMPUTER:
            return "Desktop";
        default:
            return "Android";
    }
}

bool is_http_or_https_url(std::string_view url) {
    return url.rfind("https://", 0) == 0 || url.rfind("http://", 0) == 0;
}

bool is_ws_or_wss_url(std::string_view url) {
    return url.rfind("wss://", 0) == 0 || url.rfind("ws://", 0) == 0;
}

std::string ensure_command_json_has_endpoint(
    std::string_view endpoint,
    std::string_view payload_json) {
    if (payload_json.empty()) {
        return "{\"endpoint\":\"" + json::json_escape(endpoint) + "\"}";
    }
    const auto parsed = json::parse_json(payload_json);
    if (parsed.has_value() && parsed->is_object()) {
        if (parsed->find("endpoint") != nullptr) {
            return std::string(payload_json);
        }
        json::JsonValue enriched = *parsed;
        json::JsonValue ep_val;
        ep_val.type = json::JsonValue::Type::kString;
        ep_val.string_value = std::string(endpoint);
        enriched.object_value["endpoint"] = std::move(ep_val);
        return json::serialize_json(enriched);
    }
    return std::string(payload_json);
}

}  // namespace

ConnectSubsystem::ConnectSubsystem(
    player::ContextPlayerImpl& player,
    network::AuthSessionStore& auth_store,
    network::NativeHttpClient& http_client,
    std::string spclient_base_url,
    std::string dealer_base_url)
    : player_(player),
      client_(http_client, std::move(spclient_base_url)),
      devices_(client_),
      transfer_manager_(client_, devices_),
      group_enricher_(client_, devices_),
      state_restore_(),
      local_device_reporter_(client_, devices_, http_client),
      dealer_(auth_store, std::move(dealer_base_url)) {}

ConnectSubsystem::ConnectSubsystem(
    player::ContextPlayerImpl& player,
    network::AuthSessionStore& auth_store,
    ConnectStateClientImpl::TransportFn transport_fn,
    std::string spclient_base_url,
    std::string dealer_base_url,
    LocalDeviceReporter::ZeroconfGetFn zeroconf_get_fn)
    : player_(player),
      client_(std::move(transport_fn), std::move(spclient_base_url)),
      devices_(client_),
      transfer_manager_(client_, devices_),
      group_enricher_(client_, devices_),
      state_restore_(),
      local_device_reporter_(client_, devices_, std::move(zeroconf_get_fn)),
      dealer_(auth_store, std::move(dealer_base_url)) {}

ConnectSubsystem::~ConnectSubsystem() {
    stop();
}

int32_t ConnectSubsystem::start(const uint8_t* device_info_bytes, int32_t len) {
    if (device_info_bytes == nullptr || len <= 0) {
        CONNECT_LOGE("ConnectSubsystem::start rejected: empty or null DeviceInfo payload (len=%d)", len);
        return kStartInvalidArgs;
    }
    DeviceInfo decoded;
    if (!decode_device_info(device_info_bytes, static_cast<size_t>(len), decoded)) {
        CONNECT_LOGE("ConnectSubsystem::start rejected: DeviceInfo protobuf decode failed (len=%d)", len);
        return kStartDecodeError;
    }
    return start(decoded);
}

int32_t ConnectSubsystem::start(const std::vector<uint8_t>& device_info_bytes) {
    if (device_info_bytes.empty()) {
        CONNECT_LOGE("ConnectSubsystem::start rejected: empty DeviceInfo byte vector");
        return kStartInvalidArgs;
    }
    return start(device_info_bytes.data(), static_cast<int32_t>(device_info_bytes.size()));
}

int32_t ConnectSubsystem::start(const DeviceInfo& initial_device) {
    if (initial_device.device_id.empty() ||
        initial_device.name.empty() ||
        initial_device.client_id.empty()) {
        CONNECT_LOGE(
            "ConnectSubsystem::start rejected: missing mandatory identity fields "
            "(device_id_empty=%d name_empty=%d client_id_empty=%d)",
            initial_device.device_id.empty() ? 1 : 0,
            initial_device.name.empty() ? 1 : 0,
            initial_device.client_id.empty() ? 1 : 0);
        return kStartMissingIdentity;
    }

    join_pending_logout_stop_thread();
    std::lock_guard<std::mutex> lifecycle_lock(lifecycle_mutex_);
    if (needs_teardown_) {
        CONNECT_LOGI("ConnectSubsystem::start: already running for device_id=%s",
                     devices_.local_device_id().c_str());
        return kStartOk;
    }
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (running_) {
            return kStartOk;
        }
        running_ = true;
        local_active_ = false;
        last_cluster_active_device_id_.clear();
        last_local_state_timestamp_ms_ = 0;
        last_needs_state_updates_ = false;
        last_need_full_player_state_ = false;
        was_playing_ = false;
        started_playing_at_ms_ = 0;
    }
    needs_teardown_ = true;

    DeviceInfo normalized_device = initial_device;
    normalized_device.has_volume = true;
    devices_.set_local_device_info(normalized_device);
    client_.set_local_device_id(normalized_device.device_id);

    client_.set_cluster_callback([this](const Cluster& cluster) {
        devices_.apply_cluster_snapshot(cluster, ClusterUpdateReason::DEVICE_STATE_CHANGED);
    });
    client_.set_volume_applied_callback([this]() {
        notify_volume_listeners();
    });
    transfer_manager_.set_completion_callback([this](const TransferOutcome& outcome) {
        if (!outcome.ok) {
            CONNECT_LOGW(
                "ConnectSubsystem: transfer failed target=%s reason=%s",
                outcome.target_device_id.c_str(),
                outcome.error_description.c_str());
        }
        emit_diagnostic(
            "transfer",
            outcome.ok ? "transfer_succeeded" : "transfer_failed",
            outcome.target_device_id);
        notify_state_listeners();
    });
    group_enricher_.set_enriched_callback([this]() {
        notify_state_listeners();
    });
    group_enricher_.set_volume_enriched_callback([this]() {
        notify_volume_listeners();
    });
    local_device_reporter_.set_devices_changed_callback([this]() {
        notify_state_listeners();
    });
    state_restore_.set_restore_callback([this](const CachedTransferBlob& blob) {
        handle_restore_transfer_blob(blob);
    });

    const uint64_t listener_id = devices_.add_cluster_listener(
        [this](const Cluster& cluster, ClusterUpdateReason /*reason*/) {
            transfer_manager_.on_cluster_update(cluster);
            handle_cluster_changed(cluster);
        });
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        transfer_cluster_listener_id_ = listener_id;
    }

    setup_dealer_callbacks();

    {
        std::lock_guard<std::mutex> lock(queue_mutex_);
        worker_stop_requested_ = false;
        put_state_queue_.clear();
    }
    put_state_worker_ = std::thread(&ConnectSubsystem::put_state_worker_loop, this);

    player_.set_remote_playback_delegate(this);
    player_.add_player_state_listener(this);
    client_.start();
    transfer_manager_.start();
    group_enricher_.start();
    state_restore_.start();
    local_device_reporter_.start();
    dealer_.start();

    CONNECT_LOGI(
        "ConnectSubsystem started device_id=%s name=%s spclient=%s dealer=%s",
        normalized_device.device_id.c_str(),
        normalized_device.name.c_str(),
        sanitize_url_for_log(client_.spclient_base_url()).c_str(),
        sanitize_url_for_log(dealer_.dealer_base_url()).c_str());
    emit_diagnostic("connect", "started", normalized_device.device_id);
    notify_state_listeners();
    return kStartOk;
}

void ConnectSubsystem::join_pending_logout_stop_thread() {
    std::thread thread_to_join;
    {
        std::lock_guard<std::mutex> lock(logout_thread_mutex_);
        if (logout_stop_thread_.joinable() &&
            logout_stop_thread_.get_id() != std::this_thread::get_id()) {
            thread_to_join = std::move(logout_stop_thread_);
        }
    }
    if (thread_to_join.joinable()) {
        thread_to_join.join();
    }
}

void ConnectSubsystem::schedule_stop_from_logout() {
    std::lock_guard<std::mutex> lock(logout_thread_mutex_);
    {
        std::lock_guard<std::mutex> state_lock(state_mutex_);
        running_ = false;
    }
    if (logout_stop_thread_.joinable()) {
        return;
    }
    logout_stop_thread_ = std::thread([this]() { stop(); });
}

void ConnectSubsystem::stop() {
    if (dealer_.is_on_worker_thread()) {
        schedule_stop_from_logout();
        return;
    }

    {
        std::lock_guard<std::mutex> lifecycle_lock(lifecycle_mutex_);
        if (needs_teardown_) {
            const bool was_local_active = is_local_active();
            const std::string local_id = devices_.local_device_id();
            const bool has_conn_id = !client_.connection_id().empty();

            {
                std::lock_guard<std::mutex> lock(state_mutex_);
                running_ = false;
                local_active_ = false;
                last_cluster_active_device_id_.clear();
                last_local_state_timestamp_ms_ = 0;
                last_needs_state_updates_ = false;
                last_need_full_player_state_ = false;
                was_playing_ = false;
                started_playing_at_ms_ = 0;
                group_device_volumes_.clear();
            }

            player_.set_remote_playback_delegate(nullptr);
            player_.remove_player_state_listener(this);
            player_.clear_remote_mirrored_state();

            if (was_local_active && !local_id.empty() && has_conn_id) {
                SetDeviceInactiveRequest inactive_req;
                inactive_req.device_id = local_id;
                inactive_req.notify_others = true;
                inactive_req.client_side_timestamp = current_epoch_ms();
                const SimpleHttpResult res = client_.send_set_device_inactive(
                    local_id, inactive_req, kStopInactiveTimeoutMs);
                if (!res.ok) {
                    CONNECT_LOGW(
                        "ConnectSubsystem::stop: send_set_device_inactive failed http=%d err=%s",
                        res.http_status,
                        res.error_message.c_str());
                } else {
                    CONNECT_LOGI(
                        "ConnectSubsystem::stop: marked device_id=%s inactive (http=%d)",
                        local_id.c_str(),
                        res.http_status);
                }
            }

            uint64_t listener_id = 0;
            {
                std::lock_guard<std::mutex> lock(state_mutex_);
                listener_id = transfer_cluster_listener_id_;
                transfer_cluster_listener_id_ = 0;
            }
            if (listener_id != 0) {
                devices_.remove_cluster_listener(listener_id);
            }

            dealer_.stop();
            local_device_reporter_.stop();
            state_restore_.stop();
            group_enricher_.stop();
            transfer_manager_.stop();

            {
                std::lock_guard<std::mutex> lock(queue_mutex_);
                worker_stop_requested_ = true;
            }
            queue_cv_.notify_all();
            if (put_state_worker_.joinable()) {
                put_state_worker_.join();
            }
            {
                std::lock_guard<std::mutex> lock(queue_mutex_);
                put_state_queue_.clear();
                worker_stop_requested_ = false;
            }

            client_.set_connection_id({});
            client_.shutdown();
            group_enricher_.reset();
            state_restore_.reset();
            local_device_reporter_.reset();
            devices_.reset();
            needs_teardown_ = false;

            CONNECT_LOGI("ConnectSubsystem stopped cleanly");
            emit_diagnostic("connect", "stopped", local_id);
        }
    }

    join_pending_logout_stop_thread();
    notify_state_listeners();
}

bool ConnectSubsystem::is_running() const {
    std::lock_guard<std::mutex> lock(state_mutex_);
    return running_;
}

int32_t ConnectSubsystem::set_endpoints(
    std::string_view spclient_base_url,
    std::string_view dealer_ws_url) {
    if (spclient_base_url.empty() && dealer_ws_url.empty()) {
        CONNECT_LOGW("ConnectSubsystem::set_endpoints rejected: both URLs are empty");
        return -1;
    }
    if (!spclient_base_url.empty() && !is_http_or_https_url(spclient_base_url)) {
        CONNECT_LOGW(
            "ConnectSubsystem::set_endpoints rejected invalid spclient URL: %s",
            sanitize_url_for_log(spclient_base_url).c_str());
        return -1;
    }
    if (!dealer_ws_url.empty() && !is_ws_or_wss_url(dealer_ws_url)) {
        CONNECT_LOGW(
            "ConnectSubsystem::set_endpoints rejected invalid dealer WS URL: %s",
            sanitize_url_for_log(dealer_ws_url).c_str());
        return -1;
    }

    if (!spclient_base_url.empty()) {
        client_.set_spclient_base_url(std::string(spclient_base_url));
        player_.set_spclient_base_url(std::string(spclient_base_url));
    }
    if (!dealer_ws_url.empty()) {
        dealer_.set_dealer_base_url(std::string(dealer_ws_url));
    }

    CONNECT_LOGI(
        "ConnectSubsystem::set_endpoints applied spclient=%s dealer=%s",
        sanitize_url_for_log(client_.spclient_base_url()).c_str(),
        sanitize_url_for_log(dealer_.dealer_base_url()).c_str());
    emit_diagnostic("connect", "endpoints_updated", sanitize_url_for_log(dealer_.dealer_base_url()));
    return 0;
}

int32_t ConnectSubsystem::reconnect(int32_t reason_code) {
    if (!is_running()) {
        CONNECT_LOGW("ConnectSubsystem::reconnect(%d) ignored: subsystem not running", reason_code);
        return -1;
    }
    CONNECT_LOGI("ConnectSubsystem::reconnect(reason=%d)", reason_code);
    dealer_.force_reconnect(reason_code);
    emit_diagnostic("connect", "reconnect_requested", std::to_string(reason_code));
    return 0;
}

void ConnectSubsystem::set_network_available(bool is_available) {
    CONNECT_LOGI("ConnectSubsystem::set_network_available(%d)", is_available ? 1 : 0);
    dealer_.set_network_available(is_available);
    emit_diagnostic("connect", "network_available", is_available ? "true" : "false");
}

int32_t ConnectSubsystem::update_nsd_services(std::string_view services_json_utf8) {
    const int32_t rc = local_device_reporter_.update_nsd_services(services_json_utf8);
    emit_diagnostic("discovery", "nsd_update", rc == 0 ? "ok" : "invalid_json");
    return rc;
}

int32_t ConnectSubsystem::set_local_volume(
    uint32_t volume_0_to_65535,
    int32_t volume_steps,
    int32_t reason_code) {
    if (reason_code != static_cast<int32_t>(LocalVolumeReason::kUser) &&
        reason_code != static_cast<int32_t>(LocalVolumeReason::kSystem)) {
        CONNECT_LOGW("ConnectSubsystem::set_local_volume rejected invalid reason=%d", reason_code);
        return -1;
    }
    return set_local_volume(
        volume_0_to_65535,
        volume_steps,
        static_cast<LocalVolumeReason>(reason_code));
}

int32_t ConnectSubsystem::set_local_volume(
    uint32_t volume_0_to_65535,
    int32_t volume_steps,
    LocalVolumeReason reason) {
    if (volume_0_to_65535 > kMaxVolumeSteps) {
        CONNECT_LOGW(
            "ConnectSubsystem::set_local_volume rejected out-of-range volume=%u",
            volume_0_to_65535);
        return -1;
    }

    DeviceInfo local = devices_.local_device_info();
    const bool changed =
        !local.has_volume ||
        local.volume != volume_0_to_65535 ||
        (volume_steps > 0 && local.capabilities.volume_steps != volume_steps);

    local.volume = volume_0_to_65535;
    local.has_volume = true;
    if (volume_steps > 0) {
        local.capabilities.volume_steps = volume_steps;
    }
    devices_.set_local_device_info(local);

    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        local_volume_reason_ = (reason == LocalVolumeReason::kSystem) ? "system" : "user";
    }

    if (changed && is_running()) {
        QueuedPutStateTask task;
        task.kind = WorkerTaskKind::kPutState;
        task.reason = PutStateReason::VOLUME_CHANGED;
        task.only_write_player_state = false;
        enqueue_put_state(std::move(task));
    }

    notify_volume_listeners();
    notify_state_listeners();
    return 0;
}

void ConnectSubsystem::set_diagnostic_callback(DiagnosticCallback callback) {
    std::lock_guard<std::mutex> lock(cb_mutex_);
    diagnostic_callback_ = std::move(callback);
}

void ConnectSubsystem::emit_diagnostic(
    std::string_view source,
    std::string_view event,
    std::string_view detail) {
    DiagnosticCallback cb;
    {
        std::lock_guard<std::mutex> lock(cb_mutex_);
        cb = diagnostic_callback_;
    }
    if (!cb) {
        return;
    }
    std::string payload;
    payload.reserve(source.size() + event.size() + detail.size() + 96);
    payload.append("{\"source\":\"");
    payload.append(json::json_escape(source));
    payload.append("\",\"event\":\"");
    payload.append(json::json_escape(event));
    payload.append("\",\"detail\":\"");
    payload.append(json::json_escape(detail));
    payload.append("\",\"timestamp_ms\":");
    payload.append(std::to_string(current_epoch_ms()));
    payload.push_back('}');
    cb(payload);
}

bool ConnectSubsystem::is_remote_active() const {
    if (!is_running()) {
        return false;
    }
    const std::string local_id = devices_.local_device_id();
    const std::string active_id = devices_.active_device_id();
    return !active_id.empty() && active_id != local_id;
}

std::string ConnectSubsystem::active_remote_device_id() const {
    if (!is_running()) {
        return {};
    }
    const std::string local_id = devices_.local_device_id();
    const std::string active_id = devices_.active_device_id();
    if (active_id.empty() || active_id == local_id) {
        return {};
    }
    return active_id;
}

bool ConnectSubsystem::forward_player_command(
    const std::string& endpoint,
    const std::string& payload_json,
    const std::string& intent_id) {
    const std::string target_id = active_remote_device_id();
    if (target_id.empty()) {
        CONNECT_LOGW(
            "ConnectSubsystem::forward_player_command(%s): no active remote device",
            endpoint.c_str());
        return false;
    }
    const std::string command_json = ensure_command_json_has_endpoint(endpoint, payload_json);
    const AckHttpResult res = send_player_command(target_id, command_json, intent_id);
    if (!res.ok) {
        CONNECT_LOGW(
            "ConnectSubsystem::forward_player_command(%s -> %s) failed http=%d err=%s",
            endpoint.c_str(),
            target_id.c_str(),
            res.http_status,
            res.error_message.c_str());
        emit_diagnostic("player_forward", "command_failed", endpoint);
        return false;
    }
    CONNECT_LOGI(
        "ConnectSubsystem::forward_player_command(%s -> %s) ok ack=%s",
        endpoint.c_str(),
        target_id.c_str(),
        res.ack_id.c_str());
    return true;
}

void ConnectSubsystem::setup_dealer_callbacks() {
    DealerCallbacks cbs;

    cbs.on_connection_state_changed = [this](DealerConnectionState state) {
        if (state == DealerConnectionState::kConnected) {
            devices_.on_backend_connected();
            state_restore_.on_dealer_reconnected();
            emit_diagnostic("dealer", "connected", {});
        } else if (state == DealerConnectionState::kDisconnected ||
                   state == DealerConnectionState::kReconnecting) {
            const bool local_was_active = is_local_active();
            client_.set_connection_id({});
            devices_.on_backend_disconnected();
            state_restore_.on_dealer_disconnected(local_was_active);
            emit_diagnostic(
                "dealer",
                state == DealerConnectionState::kReconnecting ? "reconnecting" : "disconnected",
                {});
        }
        notify_state_listeners();
    };

    cbs.on_connection_id = [this](const std::string& conn_id) {
        client_.set_connection_id(conn_id);
        local_device_reporter_.trigger_report_if_needed();
        QueuedPutStateTask task;
        task.kind = WorkerTaskKind::kPutState;
        task.reason = PutStateReason::NEW_CONNECTION;
        task.only_write_player_state = false;
        task.wake_devices = false;
        task.snapshot = player_.snapshot_for_connect();
        enqueue_put_state(std::move(task));
        emit_diagnostic("dealer", "connection_id_received", {});
        notify_state_listeners();
    };

    cbs.on_cluster_update = [this](const ClusterUpdate& update) {
        if (!update.ack_id.empty()) {
            const bool matched = client_.on_cluster_ack(update.ack_id);
            CONNECT_LOGD(
                "ConnectSubsystem: cluster update ack_id=%s matched=%d",
                update.ack_id.c_str(),
                matched ? 1 : 0);
        }
        devices_.apply_cluster_update(update);
    };

    cbs.on_player_command = [this](const DealerPlayerCommand& cmd) -> bool {
        if (cmd.has_target_alias_id && cmd.target_alias_id != 0) {
            DeviceInfo local = devices_.local_device_info();
            if (local.device_aliases.find(cmd.target_alias_id) != local.device_aliases.end() &&
                local.selected_alias_id != cmd.target_alias_id) {
                local.selected_alias_id = cmd.target_alias_id;
                devices_.set_local_device_info(local);
            }
        }
        return player_.apply_connect_remote_command(
            cmd.endpoint,
            cmd.command_json,
            cmd.sent_by_device_id,
            cmd.message_id,
            cmd.target_alias_id);
    };

    cbs.on_set_volume = [this](const SetVolumeCommand& cmd) {
        handle_remote_volume_command(cmd);
    };

    cbs.on_logout = [this](const LogoutCommand& cmd) {
        handle_remote_logout_command(cmd);
    };

    cbs.on_set_backend_metadata = [this](const SetBackendMetadataCommand& cmd) {
        handle_remote_backend_metadata_command(cmd);
    };

    cbs.on_proxy_transfer = [this](const ProxyTransferCommand& cmd) {
        if (!cmd.target_device_id.empty()) {
            QueuedPutStateTask task;
            task.kind = WorkerTaskKind::kProxyTransfer;
            task.proxy_transfer_target_device_id = cmd.target_device_id;
            enqueue_put_state(std::move(task));
        }
    };

    cbs.on_proxy_wake = [this](const ProxyWakeCommand& /*cmd*/) {
        // WoL magic packet has already been validated and dispatched by DealerWebSocketClient.
        emit_diagnostic("dealer", "proxy_wake_dispatched", {});
    };

    cbs.on_add_device_to_group = [this](const AddDeviceToGroupCommand& cmd) {
        if (!cmd.group_device_identifier.empty()) {
            group_enricher_.request_refresh_async();
            devices_.apply_cluster_snapshot(
                devices_.current_cluster(),
                ClusterUpdateReason::DEVICE_STATE_CHANGED);
        }
    };

    cbs.on_remove_device_from_group = [this](const RemoveDeviceFromGroupCommand& cmd) {
        if (!cmd.group_device_identifier.empty()) {
            {
                std::lock_guard<std::mutex> lock(state_mutex_);
                group_device_volumes_.erase(cmd.group_device_identifier);
            }
            client_.volume_throttler().clear_target(cmd.group_device_identifier);
            group_enricher_.on_device_removed_from_group(cmd.group_device_identifier);
        }
    };

    cbs.on_delete_group = [this](const DeleteGroupCommand& cmd) {
        {
            std::lock_guard<std::mutex> lock(state_mutex_);
            group_device_volumes_.clear();
        }
        client_.volume_throttler().clear_all();
        group_enricher_.on_group_deleted(cmd.group_instance);
    };

    cbs.on_resync_group_data = [this](const ResyncGroupDataCommand& /*cmd*/) {
        group_enricher_.request_refresh_async();
        QueuedPutStateTask task;
        task.kind = WorkerTaskKind::kPutState;
        task.reason = PutStateReason::PICKER_OPENED;
        task.only_write_player_state = false;
        task.wake_devices = false;
        enqueue_put_state(std::move(task));
    };

    cbs.on_group_data_event = [this](const GroupDataEvent& event) {
        group_enricher_.on_group_data_event(event);
    };

    cbs.on_group_device_volume_event = [this](const GroupDeviceVolumeEvent& event) {
        group_enricher_.on_group_device_volume_event(event);
    };

    cbs.on_diagnostic_event = [this](std::string_view event_type, std::string_view detail) {
        emit_diagnostic("dealer", event_type, detail);
    };

    dealer_.set_callbacks(std::move(cbs));
}

PlayerState ConnectSubsystem::build_connect_player_state(
    const player::ContextPlayerImpl::ConnectPlayerSnapshot& snapshot) {
    PlayerState ps;
    ps.timestamp = snapshot.timestamp_ms;
    ps.context_uri = snapshot.context_uri;
    ps.context_url = snapshot.context_url;
    ps.playback_id = snapshot.playback_id;
    ps.session_id = snapshot.session_id;
    ps.session_command_id = snapshot.session_command_id;
    ps.queue_revision = std::to_string(snapshot.queue_revision);
    ps.signals = snapshot.signals;
    ps.context_metadata = snapshot.context_metadata;
    ps.page_metadata = snapshot.page_metadata;

    ps.index = ContextIndex{
        .page = snapshot.page_index,
        .track = snapshot.track_index >= 0 ? static_cast<uint32_t>(snapshot.track_index) : 0U,
        .has_page = true,
        .has_track = true,
    };

    const bool playing =
        snapshot.playback_phase == player::ContextPlayerImpl::SessionPlaybackPhase::Playing ||
        snapshot.playback_phase == player::ContextPlayerImpl::SessionPlaybackPhase::BufferingPlay;
    const bool paused =
        snapshot.playback_phase == player::ContextPlayerImpl::SessionPlaybackPhase::Paused ||
        snapshot.playback_phase == player::ContextPlayerImpl::SessionPlaybackPhase::BufferingPaused;
    const bool buffering =
        snapshot.playback_phase == player::ContextPlayerImpl::SessionPlaybackPhase::BufferingPlay ||
        snapshot.playback_phase == player::ContextPlayerImpl::SessionPlaybackPhase::BufferingPaused;

    ps.is_playing = playing || paused;
    ps.has_is_playing = true;
    ps.is_paused = paused;
    ps.has_is_paused = true;
    ps.is_buffering = buffering;
    ps.has_is_buffering = true;
    ps.playback_speed =
        snapshot.playback_phase == player::ContextPlayerImpl::SessionPlaybackPhase::Playing
            ? snapshot.playback_speed
            : 0.0;
    ps.has_playback_speed = true;
    ps.position_as_of_timestamp = snapshot.position_ms;
    ps.has_position_as_of_timestamp = true;
    ps.duration = snapshot.duration_ms;
    ps.has_duration = true;

    ps.options.shuffling_context = snapshot.shuffling;
    ps.options.has_shuffling_context = true;
    ps.options.repeating_context =
        snapshot.repeat_mode == player::ContextPlayerImpl::SessionRepeatMode::Context ||
        snapshot.repeat_mode == player::ContextPlayerImpl::SessionRepeatMode::Track;
    ps.options.has_repeating_context = true;
    ps.options.repeating_track =
        snapshot.repeat_mode == player::ContextPlayerImpl::SessionRepeatMode::Track;
    ps.options.has_repeating_track = true;
    ps.options.playback_speed = static_cast<float>(snapshot.playback_speed);
    ps.options.has_playback_speed = true;

    if (snapshot.current_track.has_value()) {
        ps.track = to_provided_track(*snapshot.current_track);
    }

    ps.prev_tracks.reserve(snapshot.prev_tracks.size());
    for (const auto& entry : snapshot.prev_tracks) {
        ps.prev_tracks.push_back(to_provided_track(entry));
    }

    ps.next_tracks.reserve(snapshot.next_tracks.size());
    for (const auto& entry : snapshot.next_tracks) {
        ps.next_tracks.push_back(to_provided_track(entry));
    }

    if (!snapshot.restrictions_bytes.empty()) {
        Restrictions parsed_restrictions;
        if (decode_restrictions(
                snapshot.restrictions_bytes.data(),
                snapshot.restrictions_bytes.size(),
                parsed_restrictions)) {
            ps.restrictions = std::move(parsed_restrictions);
        }
    }

    PlayOrigin po;
    po.feature_identifier = snapshot.play_origin.feature_identifier;
    po.feature_version = snapshot.play_origin.feature_version;
    po.view_uri = snapshot.play_origin.view_uri;
    po.external_referrer = snapshot.play_origin.external_referrer;
    po.referrer_identifier = snapshot.play_origin.referrer_identifier;
    po.device_identifier = snapshot.play_origin.device_identifier;
    po.feature_classes = snapshot.play_origin.feature_classes;
    po.restriction_identifier = snapshot.play_origin.restriction_identifier;
    if (!po.empty()) {
        ps.play_origin = std::move(po);
    }

    return ps;
}

MirroredRemotePlaybackState ConnectSubsystem::build_mirrored_remote_state(
    const Cluster& cluster) {
    const PlayerState& ps = cluster.player_state;
    MirroredRemotePlaybackState mirrored;
    mirrored.active_device_id = cluster.active_device_id;
    mirrored.timestamp_ms =
        ps.timestamp > 0 ? ps.timestamp : cluster.changed_timestamp_ms;
    mirrored.context_uri = ps.context_uri;
    mirrored.context_url = ps.context_url;
    mirrored.playback_id = ps.playback_id;
    mirrored.session_id = ps.session_id;
    mirrored.session_command_id = ps.session_command_id;
    mirrored.queue_revision = parse_uint64_strict(ps.queue_revision);
    mirrored.raw_queue_revision = ps.queue_revision;
    mirrored.position_as_of_timestamp_ms =
        ps.has_position_as_of_timestamp ? ps.position_as_of_timestamp : ps.position;
    mirrored.duration_ms = ps.duration;
    mirrored.playback_speed =
        ps.has_playback_speed
            ? ps.playback_speed
            : ((ps.is_playing && !ps.is_paused && !ps.is_buffering) ? 1.0 : 0.0);
    if (ps.index.has_value()) {
        mirrored.page_index = static_cast<int32_t>(ps.index->page);
        mirrored.track_index = static_cast<int32_t>(ps.index->track);
    }
    mirrored.is_playing = ps.is_playing;
    mirrored.is_paused = ps.is_paused;
    mirrored.is_buffering = ps.is_buffering;
    mirrored.shuffling = ps.options.shuffling_context;
    mirrored.repeating_context = ps.options.repeating_context;
    mirrored.repeating_track = ps.options.repeating_track;
    mirrored.modes = ps.options.modes;

    if (!ps.track.uri.empty() || !ps.track.uid.empty()) {
        mirrored.current_track = from_provided_track(ps.track);
    }
    mirrored.prev_tracks.reserve(ps.prev_tracks.size());
    for (const auto& t : ps.prev_tracks) {
        mirrored.prev_tracks.push_back(from_provided_track(t));
    }
    mirrored.next_tracks.reserve(ps.next_tracks.size());
    for (const auto& t : ps.next_tracks) {
        mirrored.next_tracks.push_back(from_provided_track(t));
    }

    if (ps.restrictions.has_value()) {
        mirrored.restrictions_bytes = encode_restrictions(*ps.restrictions);
    }
    if (ps.suppressions.has_value()) {
        mirrored.suppressions_bytes = encode_suppressions(*ps.suppressions);
    }
    mirrored.context_metadata = ps.context_metadata;
    mirrored.page_metadata = ps.page_metadata;
    if (ps.play_origin.has_value()) {
        mirrored.play_origin.feature_identifier = ps.play_origin->feature_identifier;
        mirrored.play_origin.feature_version = ps.play_origin->feature_version;
        mirrored.play_origin.view_uri = ps.play_origin->view_uri;
        mirrored.play_origin.external_referrer = ps.play_origin->external_referrer;
        mirrored.play_origin.referrer_identifier = ps.play_origin->referrer_identifier;
        mirrored.play_origin.device_identifier = ps.play_origin->device_identifier;
        mirrored.play_origin.feature_classes = ps.play_origin->feature_classes;
        mirrored.play_origin.restriction_identifier = ps.play_origin->restriction_identifier;
    }
    mirrored.signals = ps.signals;
    return mirrored;
}

PutStateRequest ConnectSubsystem::assemble_put_state_request(const QueuedPutStateTask& task) {
    const auto snapshot = task.snapshot.has_value()
                              ? *task.snapshot
                              : player_.snapshot_for_connect();
    const bool is_local_origin =
        player_.playback_origin() == player::PlaybackOrigin::kLocal;
    const uint64_t now_ms = current_epoch_ms();
    const bool playing_or_paused =
        is_local_origin &&
        (snapshot.playback_phase == player::ContextPlayerImpl::SessionPlaybackPhase::Playing ||
         snapshot.playback_phase == player::ContextPlayerImpl::SessionPlaybackPhase::BufferingPlay ||
         snapshot.playback_phase == player::ContextPlayerImpl::SessionPlaybackPhase::Paused ||
         snapshot.playback_phase == player::ContextPlayerImpl::SessionPlaybackPhase::BufferingPaused);

    uint32_t msg_seq = 1;
    uint64_t started_at = 0;
    uint64_t playing_duration_ms = 0;
    bool local_active = false;
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        local_active = local_active_;
    }
    const bool is_active =
        (task.reason != PutStateReason::BECAME_INACTIVE) &&
        is_local_origin &&
        (local_active || devices_.is_local_device_active());
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        msg_seq = put_state_message_seq_++;
        if (is_active && playing_or_paused && !was_playing_) {
            started_playing_at_ms_ = now_ms;
            was_playing_ = true;
        } else if (!is_active || !playing_or_paused) {
            was_playing_ = false;
            started_playing_at_ms_ = 0;
        }
        started_at = started_playing_at_ms_;
        if (was_playing_ && now_ms >= started_playing_at_ms_) {
            playing_duration_ms = now_ms - started_playing_at_ms_;
        }
    }

    PutStateRequest req;
    req.member_type = MemberType::CONNECT_STATE;
    req.put_state_reason = task.reason;
    req.message_id = msg_seq;
    req.is_active = is_active;
    req.has_is_active = true;
    req.last_command_sent_by_device_id = snapshot.last_command_sent_by_device_id;
    req.last_command_message_id = snapshot.last_command_message_id;
    req.started_playing_at = started_at;
    req.has_been_playing_for_ms = playing_duration_ms;
    req.client_side_timestamp = now_ms;
    req.only_write_player_state = task.only_write_player_state;

    req.device.device_info = devices_.local_device_info();
    req.device.platform = default_platform_for_device_type(req.device.device_info.device_type);

    const bool local_snapshot_populated =
        is_local_origin &&
        (snapshot.has_player_state ||
         !snapshot.context_uri.empty() ||
         !snapshot.context_url.empty() ||
         snapshot.current_track.has_value());

    if (local_snapshot_populated) {
        req.device.player_state = build_connect_player_state(snapshot);
        req.device.has_player_state = true;
    } else {
        req.device.has_player_state = false;
        req.only_write_player_state = false;
    }
    return req;
}

PutStateResult ConnectSubsystem::execute_put_state_task(const QueuedPutStateTask& task) {
    const std::string dev_id = devices_.local_device_id();
    if (dev_id.empty()) {
        CONNECT_LOGW("ConnectSubsystem::execute_put_state_task: local device ID is empty");
        return PutStateResult{
            .ok = false,
            .deferred = false,
            .http_status = 0,
            .grpc_status = {},
            .retry_after_ms = 0,
            .error_code = BackoffErrorCode::kPutStateFailed,
            .error_message = "Local Connect device ID is empty",
            .cluster = std::nullopt,
        };
    }
    const PutStateRequest req = assemble_put_state_request(task);
    const PutStateResult res = client_.put_state(dev_id, req, task.wake_devices);
    if (!res.ok && !res.deferred) {
        CONNECT_LOGW(
            "ConnectSubsystem::execute_put_state_task failed reason=%u http=%d err_code=%d msg=%s",
            static_cast<unsigned>(task.reason),
            res.http_status,
            static_cast<int>(res.error_code),
            res.error_message.c_str());
    }
    return res;
}

void ConnectSubsystem::enqueue_put_state(QueuedPutStateTask task) {
    {
        std::lock_guard<std::mutex> lock(queue_mutex_);
        if (worker_stop_requested_) {
            return;
        }
        // Coalesce consecutive PLAYER_STATE_CHANGED tasks so rapid player events upload latest state.
        if (task.kind == WorkerTaskKind::kPutState &&
            task.reason == PutStateReason::PLAYER_STATE_CHANGED &&
            !put_state_queue_.empty() &&
            put_state_queue_.back().kind == WorkerTaskKind::kPutState &&
            put_state_queue_.back().reason == PutStateReason::PLAYER_STATE_CHANGED) {
            put_state_queue_.back() = std::move(task);
        } else {
            put_state_queue_.push_back(std::move(task));
        }
    }
    queue_cv_.notify_one();
}

void ConnectSubsystem::put_state_worker_loop() {
    while (true) {
        QueuedPutStateTask task;
        {
            std::unique_lock<std::mutex> lock(queue_mutex_);
            queue_cv_.wait(lock, [this]() {
                return worker_stop_requested_ || !put_state_queue_.empty();
            });
            if (worker_stop_requested_) {
                break;
            }
            task = std::move(put_state_queue_.front());
            put_state_queue_.pop_front();
        }

        switch (task.kind) {
            case WorkerTaskKind::kPutState: {
                const PutStateResult res = execute_put_state_task(task);
                if (!res.ok && !res.deferred) {
                    emit_diagnostic("put_state", "put_state_failed", res.error_message);
                }
                break;
            }
            case WorkerTaskKind::kSetDeviceInactive: {
                const std::string local_id = devices_.local_device_id();
                if (!local_id.empty()) {
                    SetDeviceInactiveRequest inactive_req;
                    inactive_req.device_id = local_id;
                    inactive_req.notify_others = false;
                    inactive_req.client_side_timestamp = current_epoch_ms();
                    const SimpleHttpResult res =
                        client_.send_set_device_inactive(local_id, inactive_req);
                    if (!res.ok) {
                        CONNECT_LOGW(
                            "ConnectSubsystem worker: send_set_device_inactive failed http=%d err=%s",
                            res.http_status,
                            res.error_message.c_str());
                    }
                }
                break;
            }
            case WorkerTaskKind::kProxyTransfer: {
                if (!task.proxy_transfer_target_device_id.empty()) {
                    const TransferOutcome outcome =
                        transfer_manager_.transfer_to_connect_state_device(
                            task.proxy_transfer_target_device_id);
                    if (!outcome.ok) {
                        CONNECT_LOGW(
                            "ConnectSubsystem worker: proxy_transfer failed target=%s err=%s",
                            task.proxy_transfer_target_device_id.c_str(),
                            outcome.error_description.c_str());
                    }
                }
                break;
            }
        }
    }
}

void ConnectSubsystem::on_player_state_changed(
    const player::ContextPlayerImpl::ConnectPlayerSnapshot& snapshot,
    bool track_changed) {
    // Never upload mirrored remote state back to Spotify as if it were local state.
    if (player_.playback_origin() != player::PlaybackOrigin::kLocal) {
        return;
    }

    bool force_full_state = false;
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (!running_) {
            return;
        }
        if (snapshot.timestamp_ms > last_local_state_timestamp_ms_) {
            last_local_state_timestamp_ms_ = snapshot.timestamp_ms;
        }
        if (is_active_playing_phase(snapshot.playback_phase)) {
            local_active_ = true;
        } else if (snapshot.playback_phase ==
                       player::ContextPlayerImpl::SessionPlaybackPhase::Idle &&
                   snapshot.context_uri.empty() &&
                   snapshot.context_url.empty() &&
                   !snapshot.current_track.has_value()) {
            local_active_ = false;
        }
        force_full_state = last_need_full_player_state_;
    }

    if (is_active_playing_phase(snapshot.playback_phase)) {
        state_restore_.cancel_pending_recovery();
    }

    QueuedPutStateTask task;
    task.kind = WorkerTaskKind::kPutState;
    task.reason = PutStateReason::PLAYER_STATE_CHANGED;
    task.only_write_player_state =
        !force_full_state &&
        !track_changed &&
        devices_.has_received_cluster_update_after_backend_connection();
    task.wake_devices = false;
    task.snapshot = snapshot;
    enqueue_put_state(std::move(task));
}

void ConnectSubsystem::handle_cluster_changed(const Cluster& cluster) {
    const std::string local_id = devices_.local_device_id();

    state_restore_.on_cluster_update(cluster);
    group_enricher_.on_cluster_updated(cluster);
    local_device_reporter_.set_needs_local_devices(cluster.needs_local_devices);

    bool should_clear_active_volume_slot = false;
    bool became_inactive_remote = false;
    bool needs_state_updates_edge = false;
    bool need_full_state = cluster.need_full_player_state;
    int64_t local_ts = 0;
    const bool local_activating = !local_id.empty() && is_being_activated(local_id);

    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (!running_) {
            return;
        }
        local_ts = last_local_state_timestamp_ms_;
        needs_state_updates_edge = cluster.needs_state_updates && !last_needs_state_updates_;
        last_needs_state_updates_ = cluster.needs_state_updates;
        last_need_full_player_state_ = cluster.need_full_player_state;

        if (cluster.active_device_id != last_cluster_active_device_id_) {
            last_cluster_active_device_id_ = cluster.active_device_id;
            should_clear_active_volume_slot = true;
        }
    }

    if (should_clear_active_volume_slot) {
        client_.volume_throttler().clear_target("");
    }

    if (!cluster.active_device_id.empty() && cluster.active_device_id != local_id) {
        const bool stale_cluster_vs_local =
            local_ts > 0 && cluster.changed_timestamp_ms > 0 &&
            local_ts > cluster.changed_timestamp_ms;

        if (local_activating || stale_cluster_vs_local) {
            CONNECT_LOGI(
                "ConnectSubsystem::handle_cluster_changed: ignoring stale remote cluster "
                "(remote=%s local_activating=%d local_ts=%lld cluster_ts=%lld)",
                cluster.active_device_id.c_str(),
                local_activating ? 1 : 0,
                static_cast<long long>(local_ts),
                static_cast<long long>(cluster.changed_timestamp_ms));
        } else {
            {
                std::lock_guard<std::mutex> lock(state_mutex_);
                became_inactive_remote = local_active_;
                local_active_ = false;
                was_playing_ = false;
                started_playing_at_ms_ = 0;
            }
            state_restore_.cancel_pending_recovery();

            const auto local_snap = player_.snapshot_for_connect();
            if (became_inactive_remote || is_active_playing_phase(local_snap.playback_phase)) {
                CONNECT_LOGI(
                    "ConnectSubsystem: remote takeover by %s; pausing local playback and sending inactive",
                    cluster.active_device_id.c_str());
                player_.pause_for_remote_takeover();
                QueuedPutStateTask inactive_task;
                inactive_task.kind = WorkerTaskKind::kSetDeviceInactive;
                enqueue_put_state(std::move(inactive_task));
                emit_diagnostic("cluster", "remote_takeover", cluster.active_device_id);
            }

            const MirroredRemotePlaybackState mirrored = build_mirrored_remote_state(cluster);
            player_.apply_remote_mirrored_state(mirrored);
        }
    } else if (!local_id.empty() && cluster.active_device_id == local_id) {
        {
            std::lock_guard<std::mutex> lock(state_mutex_);
            local_active_ = true;
        }
        player_.clear_remote_mirrored_state();
    } else {
        const auto snap = player_.snapshot_for_connect();
        if (!is_active_playing_phase(snap.playback_phase)) {
            std::lock_guard<std::mutex> lock(state_mutex_);
            local_active_ = false;
        }
        player_.clear_remote_mirrored_state();
    }

    if (needs_state_updates_edge && is_local_active()) {
        CONNECT_LOGI(
            "ConnectSubsystem: Cluster.needs_state_updates transitioned false -> true; forcing PutState");
        QueuedPutStateTask task;
        task.kind = WorkerTaskKind::kPutState;
        task.reason = PutStateReason::PLAYER_STATE_CHANGED;
        task.only_write_player_state = !need_full_state;
        task.wake_devices = false;
        task.snapshot = player_.snapshot_for_connect();
        enqueue_put_state(std::move(task));
    }

    notify_state_listeners();
    notify_volume_listeners();
}

void ConnectSubsystem::handle_restore_transfer_blob(const CachedTransferBlob& blob) {
    if (!is_running() || blob.transfer_data.empty()) {
        return;
    }
    const std::string local_id = devices_.local_device_id();
    const std::string b64 = base64_encode(
        blob.transfer_data.data(),
        blob.transfer_data.size());
    const std::string cmd_json =
        "{\"endpoint\":\"transfer\",\"data\":\"" + b64 +
        "\",\"options\":{\"restore_paused\":\"restore\"}}";
    const bool ok = player_.apply_connect_remote_command(
        "transfer", cmd_json, local_id, 0, 0);
    if (!ok) {
        CONNECT_LOGW(
            "ConnectSubsystem::handle_restore_transfer_blob: LoadLastTransferBlob apply failed");
        emit_diagnostic("state_restore", "restore_failed", {});
    } else {
        CONNECT_LOGI(
            "ConnectSubsystem::handle_restore_transfer_blob: restored cached TransferState (%zu bytes)",
            blob.transfer_data.size());
        emit_diagnostic("state_restore", "restore_applied", {});
    }
}

void ConnectSubsystem::handle_remote_volume_command(const SetVolumeCommand& cmd) {
    if (cmd.volume < 0) {
        CONNECT_LOGW("ConnectSubsystem::handle_remote_volume_command: ignoring negative volume=%d", cmd.volume);
        return;
    }
    const uint32_t vol = static_cast<uint32_t>(
        std::min<int32_t>(cmd.volume, static_cast<int32_t>(kMaxVolumeSteps)));

    if (!cmd.group_device_identifier.empty()) {
        if (!client_.volume_throttler().should_apply_remote_volume(vol, cmd.group_device_identifier)) {
            return;
        }
        {
            std::lock_guard<std::mutex> lock(state_mutex_);
            group_device_volumes_[cmd.group_device_identifier] = vol;
        }
        notify_volume_listeners();
        return;
    }

    if (!client_.volume_throttler().should_apply_remote_volume(vol, "")) {
        return;
    }

    DeviceInfo local = devices_.local_device_info();
    local.volume = vol;
    local.has_volume = true;
    devices_.set_local_device_info(local);
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        local_volume_reason_ = "remote";
    }

    std::function<void(uint32_t)> vol_cb;
    {
        std::lock_guard<std::mutex> lock(cb_mutex_);
        vol_cb = local_volume_callback_;
    }
    if (vol_cb) {
        vol_cb(vol);
    }
    notify_local_volume_listeners(vol, LocalVolumeReason::kSystem);
    notify_volume_listeners();

    QueuedPutStateTask task;
    task.kind = WorkerTaskKind::kPutState;
    task.reason = PutStateReason::VOLUME_CHANGED;
    task.only_write_player_state = false;
    enqueue_put_state(std::move(task));
}

void ConnectSubsystem::handle_remote_logout_command(const LogoutCommand& /*cmd*/) {
    CONNECT_LOGI("ConnectSubsystem: received remote Logout command");
    emit_diagnostic("dealer", "remote_logout", {});
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        running_ = false;
    }
    std::function<void()> cb;
    {
        std::lock_guard<std::mutex> lock(cb_mutex_);
        cb = logout_callback_;
    }
    if (cb) {
        cb();
    }
    if (dealer_.is_on_worker_thread()) {
        schedule_stop_from_logout();
    } else {
        stop();
    }
}

void ConnectSubsystem::handle_remote_backend_metadata_command(
    const SetBackendMetadataCommand& cmd) {
    DeviceInfo local = devices_.local_device_info();
    for (const auto& [k, v] : cmd.metadata) {
        local.metadata_map[k] = v;
    }
    devices_.set_local_device_info(local);

    QueuedPutStateTask task;
    task.kind = WorkerTaskKind::kPutState;
    task.reason = PutStateReason::BACKEND_METADATA_APPLIED;
    task.only_write_player_state = false;
    enqueue_put_state(std::move(task));
}

uint64_t ConnectSubsystem::add_cluster_listener(ConnectDevicesImpl::ClusterListener listener) {
    return devices_.add_cluster_listener(std::move(listener));
}

void ConnectSubsystem::remove_cluster_listener(uint64_t listener_id) {
    devices_.remove_cluster_listener(listener_id);
}

uint64_t ConnectSubsystem::add_dodo_listener(ConnectDevicesImpl::DodoListener listener) {
    return devices_.add_dodo_listener(std::move(listener));
}

void ConnectSubsystem::remove_dodo_listener(uint64_t listener_id) {
    devices_.remove_dodo_listener(listener_id);
}

void ConnectSubsystem::set_local_volume_callback(std::function<void(uint32_t)> callback) {
    std::lock_guard<std::mutex> lock(cb_mutex_);
    local_volume_callback_ = std::move(callback);
}

void ConnectSubsystem::set_logout_callback(std::function<void()> callback) {
    std::lock_guard<std::mutex> lock(cb_mutex_);
    logout_callback_ = std::move(callback);
}

uint64_t ConnectSubsystem::add_state_listener(StateListener listener) {
    std::lock_guard<std::mutex> lock(cb_mutex_);
    const uint64_t id = next_listener_id_++;
    state_listeners_.emplace_back(id, std::move(listener));
    return id;
}

void ConnectSubsystem::remove_state_listener(uint64_t listener_id) {
    std::lock_guard<std::mutex> lock(cb_mutex_);
    for (auto it = state_listeners_.begin(); it != state_listeners_.end(); ++it) {
        if (it->first == listener_id) {
            state_listeners_.erase(it);
            return;
        }
    }
}

uint64_t ConnectSubsystem::add_volume_listener(VolumeListener listener) {
    std::lock_guard<std::mutex> lock(cb_mutex_);
    const uint64_t id = next_listener_id_++;
    volume_listeners_.emplace_back(id, std::move(listener));
    return id;
}

void ConnectSubsystem::remove_volume_listener(uint64_t listener_id) {
    std::lock_guard<std::mutex> lock(cb_mutex_);
    for (auto it = volume_listeners_.begin(); it != volume_listeners_.end(); ++it) {
        if (it->first == listener_id) {
            volume_listeners_.erase(it);
            return;
        }
    }
}

uint64_t ConnectSubsystem::add_local_volume_listener(LocalVolumeListener listener) {
    std::lock_guard<std::mutex> lock(cb_mutex_);
    const uint64_t id = next_listener_id_++;
    local_volume_listeners_.emplace_back(id, std::move(listener));
    return id;
}

void ConnectSubsystem::remove_local_volume_listener(uint64_t listener_id) {
    std::lock_guard<std::mutex> lock(cb_mutex_);
    for (auto it = local_volume_listeners_.begin(); it != local_volume_listeners_.end(); ++it) {
        if (it->first == listener_id) {
            local_volume_listeners_.erase(it);
            return;
        }
    }
}

void ConnectSubsystem::notify_state_listeners() {
    std::vector<StateListener> copy;
    {
        std::lock_guard<std::mutex> lock(cb_mutex_);
        copy.reserve(state_listeners_.size());
        for (const auto& [id, cb] : state_listeners_) {
            if (cb) copy.push_back(cb);
        }
    }
    for (const auto& cb : copy) {
        cb();
    }
}

void ConnectSubsystem::notify_volume_listeners() {
    std::vector<VolumeListener> copy;
    {
        std::lock_guard<std::mutex> lock(cb_mutex_);
        if (volume_listeners_.empty()) return;
        copy.reserve(volume_listeners_.size());
        for (const auto& [id, cb] : volume_listeners_) {
            if (cb) copy.push_back(cb);
        }
    }
    const ConnectVolumeSnapshot snap = current_volume_snapshot();
    for (const auto& cb : copy) {
        cb(snap);
    }
}

void ConnectSubsystem::notify_local_volume_listeners(uint32_t volume, LocalVolumeReason reason) {
    std::vector<LocalVolumeListener> copy;
    {
        std::lock_guard<std::mutex> lock(cb_mutex_);
        copy.reserve(local_volume_listeners_.size());
        for (const auto& [id, cb] : local_volume_listeners_) {
            if (cb) copy.push_back(cb);
        }
    }
    for (const auto& cb : copy) {
        cb(volume, reason);
    }
}

TransferOutcome ConnectSubsystem::transfer(
    const std::string& target_device_id,
    const TransferOptionsParams& options,
    const std::vector<std::string>& interaction_ids,
    bool dodo) {
    TransferOutcome outcome;
    if (dodo) {
        TransferRequest req;
        req.target_device_id = target_device_id;
        req.device_type = ConnectDeviceType::kLoggedIn;
        req.options = options;
        req.interaction_ids = interaction_ids;
        req.dodo_id = "true";
        outcome = transfer_manager_.transfer_to_device(req);
    } else {
        outcome = transfer_manager_.transfer_to_connect_state_device(
            target_device_id, {}, options, interaction_ids);
    }
    notify_state_listeners();
    return outcome;
}

TransferOutcome ConnectSubsystem::pull(const TransferOptionsParams& options) {
    const std::string local_id = devices_.local_device_id();
    TransferOutcome outcome = transfer_manager_.transfer_to_connect_state_device(
        local_id, {}, options, {});
    notify_state_listeners();
    return outcome;
}

AckHttpResult ConnectSubsystem::send_player_command(
    const std::string& target_device_id,
    const std::string& command_json,
    const std::string& intent_id) {
    const std::string local_id = devices_.local_device_id();
    const std::string dst = target_device_id.empty() ? local_id : target_device_id;
    return client_.send_player_command(
        local_id, dst, command_json, "connect", intent_id, false);
}

AckHttpResult ConnectSubsystem::rename(
    const std::string& target_device_id,
    const std::string& new_name) {
    const std::string local_id = devices_.local_device_id();
    const std::string dst = target_device_id.empty() ? local_id : target_device_id;
    RenameCommand cmd;
    cmd.rename_to = new_name;
    AckHttpResult res = client_.rename(local_id, dst, cmd);
    if (res.ok && (dst == local_id || dst.empty())) {
        DeviceInfo local = devices_.local_device_info();
        local.name = new_name;
        devices_.set_local_device_info(local);
        notify_state_listeners();
    }
    return res;
}

SimpleHttpResult ConnectSubsystem::logout(const std::string& target_device_id) {
    const std::string local_id = devices_.local_device_id();
    const std::string dst = target_device_id.empty() ? local_id : target_device_id;
    LogoutCommand cmd;
    SimpleHttpResult res = client_.logout(local_id, dst, cmd);
    notify_state_listeners();
    return res;
}

PutStateResult ConnectSubsystem::notify_audio_route_changed(
    const std::vector<AudioOutputDeviceInfo>& outputs) {
    DeviceInfo local = devices_.local_device_info();
    if (!outputs.empty() && is_audio_output_device_info_populated(outputs.front())) {
        local.audio_output_device_info = outputs.front();
    } else {
        local.audio_output_device_info.reset();
    }
    devices_.set_local_device_info(local);

    QueuedPutStateTask task;
    task.kind = WorkerTaskKind::kPutState;
    task.reason = PutStateReason::AUDIO_DRIVER_INFO_CHANGED;
    task.only_write_player_state = false;
    PutStateResult res = execute_put_state_task(task);
    notify_state_listeners();
    return res;
}

void ConnectSubsystem::set_preferred_incarnation(
    const std::string& device_id,
    std::optional<uint32_t> preferred_login_type) {
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        preferred_incarnation_login_type_ = preferred_login_type;
    }
    devices_.set_preferred_incarnation(device_id);
    notify_state_listeners();
}

std::optional<uint32_t> ConnectSubsystem::preferred_login_type() const {
    std::lock_guard<std::mutex> lock(state_mutex_);
    return preferred_incarnation_login_type_;
}

AckHttpResult ConnectSubsystem::add_device_to_group(
    const std::string& target_device_id,
    const std::string& group_device_id) {
    AddDeviceToGroupCommand cmd;
    cmd.group_device_identifier = group_device_id;
    AckHttpResult res = client_.add_device_to_group(
        devices_.local_device_id(), target_device_id, cmd);
    if (res.ok) {
        group_enricher_.request_refresh_async();
    }
    return res;
}

AckHttpResult ConnectSubsystem::remove_device_from_group(
    const std::string& target_device_id,
    const std::string& group_device_id) {
    RemoveDeviceFromGroupCommand cmd;
    cmd.group_device_identifier = group_device_id;
    AckHttpResult res = client_.remove_device_from_group(
        devices_.local_device_id(), target_device_id, cmd);
    if (res.ok && !group_device_id.empty()) {
        {
            std::lock_guard<std::mutex> lock(state_mutex_);
            group_device_volumes_.erase(group_device_id);
        }
        client_.volume_throttler().clear_target(group_device_id);
        group_enricher_.on_device_removed_from_group(group_device_id);
    }
    return res;
}

AckHttpResult ConnectSubsystem::delete_group(const std::string& group_device_id) {
    DeleteGroupCommand cmd;
    cmd.group_instance = group_device_id;
    AckHttpResult res = client_.delete_group(
        devices_.local_device_id(), group_device_id, cmd);
    if (res.ok && !group_device_id.empty()) {
        {
            std::lock_guard<std::mutex> lock(state_mutex_);
            group_device_volumes_.erase(group_device_id);
        }
        client_.volume_throttler().clear_target(group_device_id);
        group_enricher_.on_group_deleted(group_device_id);
    }
    return res;
}

bool ConnectSubsystem::is_local_active() const {
    if (devices_.is_local_device_active()) {
        return true;
    }
    std::lock_guard<std::mutex> lock(state_mutex_);
    return local_active_;
}

bool ConnectSubsystem::is_being_activated(std::string_view device_id) const {
    const auto active_intent = transfer_manager_.active_intention();
    return active_intent.has_value() && !active_intent->is_finished() &&
           active_intent->target_device_id() == device_id;
}

bool ConnectSubsystem::has_received_cluster_update_after_backend_connection() const {
    return devices_.has_received_cluster_update_after_backend_connection();
}

bool ConnectSubsystem::perform_discovery() {
    local_device_reporter_.trigger_report_if_needed();
    return devices_.perform_discovery();
}

PutStateResult ConnectSubsystem::refresh_cluster() {
    QueuedPutStateTask task;
    task.kind = WorkerTaskKind::kPutState;
    task.reason = PutStateReason::PICKER_OPENED;
    task.only_write_player_state = false;
    task.wake_devices = true;
    return execute_put_state_task(task);
}

SimpleHttpResult ConnectSubsystem::wake_sleeping_cluster_devices() {
    return client_.wake_up_sleeping_cluster();
}

AckHttpResult ConnectSubsystem::volume_set(
    uint32_t volume,
    const std::string& group_device_id) {
    const uint32_t bounded = volume > kMaxVolumeSteps ? kMaxVolumeSteps : volume;
    const std::string local_id = devices_.local_device_id();
    const std::string active_id = devices_.active_device_id();
    const std::string target_id =
        !group_device_id.empty()
            ? (!active_id.empty() ? active_id : group_device_id)
            : (!active_id.empty() ? active_id : local_id);

    if (!group_device_id.empty()) {
        std::lock_guard<std::mutex> lock(state_mutex_);
        group_device_volumes_[group_device_id] = bounded;
    }

    if (group_device_id.empty() && (target_id == local_id || active_id.empty())) {
        DeviceInfo local = devices_.local_device_info();
        local.volume = bounded;
        local.has_volume = true;
        devices_.set_local_device_info(local);
        {
            std::lock_guard<std::mutex> lock(state_mutex_);
            local_volume_reason_ = "user";
        }
        std::function<void(uint32_t)> vol_cb;
        {
            std::lock_guard<std::mutex> lock(cb_mutex_);
            vol_cb = local_volume_callback_;
        }
        if (vol_cb) {
            vol_cb(bounded);
        }
        notify_local_volume_listeners(bounded, LocalVolumeReason::kUser);
        notify_volume_listeners();
        QueuedPutStateTask task;
        task.kind = WorkerTaskKind::kPutState;
        task.reason = PutStateReason::VOLUME_CHANGED;
        task.only_write_player_state = false;
        const auto put_res = execute_put_state_task(task);
        return AckHttpResult{
            .ok = put_res.ok || put_res.deferred,
            .throttled = put_res.deferred,
            .http_status = put_res.http_status,
            .error_code = put_res.error_code,
            .ack_id = {},
            .error_message = put_res.error_message,
        };
    }

    std::string group_instance;
    if (!group_device_id.empty() && !active_id.empty()) {
        if (const auto gd = devices_.group_data_for_device(active_id); gd.has_value()) {
            group_instance = gd->group_instance;
        }
    }

    AckHttpResult res = client_.set_volume(
        local_id, target_id, bounded, group_device_id, group_instance);
    if (res.ok || res.throttled) {
        notify_volume_listeners();
    }
    return res;
}

AckHttpResult ConnectSubsystem::volume_up(
    uint32_t step,
    const std::string& group_device_id) {
    const ConnectVolumeSnapshot snap = current_volume_snapshot();
    uint32_t base = snap.volume;
    if (!group_device_id.empty()) {
        const auto it = snap.group_device_volumes.find(group_device_id);
        if (it != snap.group_device_volumes.end()) {
            base = it->second;
        }
    }
    const uint32_t next = (kMaxVolumeSteps - base < step) ? kMaxVolumeSteps : (base + step);
    return volume_set(next, group_device_id);
}

AckHttpResult ConnectSubsystem::volume_down(
    uint32_t step,
    const std::string& group_device_id) {
    const ConnectVolumeSnapshot snap = current_volume_snapshot();
    uint32_t base = snap.volume;
    if (!group_device_id.empty()) {
        const auto it = snap.group_device_volumes.find(group_device_id);
        if (it != snap.group_device_volumes.end()) {
            base = it->second;
        }
    }
    const uint32_t next = base > step ? (base - step) : 0U;
    return volume_set(next, group_device_id);
}

ConnectVolumeSnapshot ConnectSubsystem::current_volume_snapshot() const {
    ConnectVolumeSnapshot snap;
    snap.active_device_connect_state_identifier = devices_.active_device_id();
    snap.local_volume = devices_.local_device_info().volume;

    // Start with enriched Connect-Group v1 member volumes, then overlay optimistic local overrides.
    snap.group_device_volumes = devices_.group_device_volume_values_snapshot();
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        for (const auto& [member_id, vol] : group_device_volumes_) {
            snap.group_device_volumes[member_id] = vol;
        }
        snap.local_reason = local_volume_reason_;
    }

    // Apply any active per-member wanted volume overrides from VolumeThrottler.
    for (auto& [member_id, vol] : snap.group_device_volumes) {
        if (const auto wanted_member = client_.volume_throttler().active_wanted_volume(member_id)) {
            vol = *wanted_member;
        }
    }

    if (const auto wanted = client_.volume_throttler().active_wanted_volume("")) {
        snap.volume = *wanted;
    } else if (!snap.active_device_connect_state_identifier.empty()) {
        snap.volume = devices_.device_volume(snap.active_device_connect_state_identifier);
    } else {
        snap.volume = snap.local_volume;
    }
    return snap;
}

std::vector<SingleDodo> ConnectSubsystem::list_dodos() const {
    return devices_.dodos_snapshot();
}

ClusterHttpResult ConnectSubsystem::switch_to_dodo(const std::string& cs_id) {
    SetDoDoRequest req;
    req.dodo1 = devices_.local_device_id();
    req.dodo2 = cs_id;
    return client_.set_dodo(req);
}

ClusterHttpResult ConnectSubsystem::create_new_dodo(const std::string& name) {
    SetDoDoRequest req;
    req.dodo1 = devices_.local_device_id();
    req.dodo2 = !name.empty() ? name : devices_.local_device_id();
    return client_.set_dodo(req);
}

ClusterHttpResult ConnectSubsystem::end_dodo() {
    SetDoDoRequest req;
    req.dodo1 = devices_.local_device_id();
    req.dodo2 = {};
    return client_.set_dodo(req);
}

}  // namespace spotify::connectstate
