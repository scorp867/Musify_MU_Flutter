// Replicated from liborbit-jni-spotify.so (ConnectSubsystem bidirectional engine orchestrator):
// - Binary symbols / offsets (`liborbit-jni-spotify.so`):
//   - Internal C++ wiring connecting DealerWebSocketClient (0xdb4d9c..0xdb50c0),
//     ConnectStateClientImpl (0xdc1b80..0xdc6310), PutStateBackoff (0xdc5e8c..0xdc6310),
//     VolumeThrottler (0xdca2d4..0xdca6fc), ConnectDevicesImpl (0xdac4e0..0xdbddaa),
//     TransferManager (0xdf16e8..0xdf4cf8), and ContextPlayerImpl local playback state.
// - Esperanto service contracts (`liborbit-jni-spotify.so` / `liborbit-jni-spotify_memdump.so`):
//   - ConnectService (.so @ 0x3a20cd), ConnectVolumeService (.so @ 0x343b80,
//     LocalVolumeResponse @ .so 0x5a24d5 / memdump 0x36ac39),
//     DodoService (.so @ 0x36a9f8, dodos_messages.proto @ .so 0x5a1dd0 / memdump 0x36a536)
// - Java / Esperanto counterparts:
//   - com/spotify/core/corefullimpl/NativeFullAuthenticatedScopeImpl.java
//   - p199p/s77.java, p199p/c8k.java, p199p/C2086nd.java, p199p/a0f1.java, p199p/lw51.java

#include "ConnectSubsystem.h"

#include <algorithm>
#include <utility>

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
    return pt;
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
      dealer_(auth_store, std::move(dealer_base_url)) {}

ConnectSubsystem::ConnectSubsystem(
    player::ContextPlayerImpl& player,
    network::AuthSessionStore& auth_store,
    ConnectStateClientImpl::TransportFn transport_fn,
    std::string spclient_base_url,
    std::string dealer_base_url)
    : player_(player),
      client_(std::move(transport_fn), std::move(spclient_base_url)),
      devices_(client_),
      transfer_manager_(client_, devices_),
      dealer_(auth_store, std::move(dealer_base_url)) {}

ConnectSubsystem::~ConnectSubsystem() {
    stop();
}

void ConnectSubsystem::start(const DeviceInfo& initial_device) {
    join_pending_logout_stop_thread();
    std::lock_guard<std::mutex> lifecycle_lock(lifecycle_mutex_);
    if (needs_teardown_) {
        return;
    }
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (running_) {
            return;
        }
        running_ = true;
        local_active_ = false;
        last_cluster_active_device_id_.clear();
        was_playing_ = false;
        started_playing_at_ms_ = 0;
    }
    needs_teardown_ = true;

    devices_.set_local_device_info(initial_device);
    client_.set_local_device_id(initial_device.device_id);

    client_.set_cluster_callback([this](const Cluster& cluster) {
        devices_.apply_cluster_snapshot(cluster, ClusterUpdateReason::DEVICE_STATE_CHANGED);
    });
    client_.set_volume_applied_callback([this]() {
        notify_volume_listeners();
    });
    transfer_manager_.set_completion_callback([this](const TransferOutcome& /*outcome*/) {
        notify_state_listeners();
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

    player_.add_player_state_listener(this);
    client_.start();
    transfer_manager_.start();
    dealer_.start();
    notify_state_listeners();
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
            {
                std::lock_guard<std::mutex> lock(state_mutex_);
                running_ = false;
                local_active_ = false;
                last_cluster_active_device_id_.clear();
                was_playing_ = false;
                started_playing_at_ms_ = 0;
            }

            player_.remove_player_state_listener(this);

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

            client_.shutdown();
            devices_.reset();
            needs_teardown_ = false;
        }
    }

    join_pending_logout_stop_thread();
    notify_state_listeners();
}

bool ConnectSubsystem::is_running() const {
    std::lock_guard<std::mutex> lock(state_mutex_);
    return running_;
}

void ConnectSubsystem::setup_dealer_callbacks() {
    DealerCallbacks cbs;

    cbs.on_connection_state_changed = [this](DealerConnectionState state) {
        if (state == DealerConnectionState::kConnected) {
            devices_.on_backend_connected();
        } else if (state == DealerConnectionState::kDisconnected ||
                   state == DealerConnectionState::kReconnecting) {
            devices_.on_backend_disconnected();
        }
        notify_state_listeners();
    };

    cbs.on_connection_id = [this](const std::string& conn_id) {
        client_.set_connection_id(conn_id);
        QueuedPutStateTask task;
        task.reason = PutStateReason::NEW_DEVICE;
        task.only_write_player_state = false;
        task.wake_devices = false;
        task.snapshot = player_.snapshot_for_connect();
        enqueue_put_state(std::move(task));
        notify_state_listeners();
    };

    cbs.on_cluster_update = [this](const ClusterUpdate& update) {
        devices_.apply_cluster_update(update);
    };

    cbs.on_player_command = [this](const DealerPlayerCommand& cmd) -> bool {
        return player_.apply_connect_remote_command(
            cmd.endpoint,
            cmd.command_json,
            cmd.sent_by_device_id,
            cmd.message_id);
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
            (void)transfer_manager_.transfer_to_connect_state_device(cmd.target_device_id);
        }
    };

    cbs.on_proxy_wake = [](const ProxyWakeCommand& /*cmd*/) {
        // WoL magic packet has already been validated and dispatched by DealerWebSocketClient.
    };

    cbs.on_add_device_to_group = [this](const AddDeviceToGroupCommand& cmd) {
        if (!cmd.group_device_identifier.empty()) {
            devices_.apply_cluster_snapshot(devices_.current_cluster(),
                                            ClusterUpdateReason::DEVICE_STATE_CHANGED);
        }
    };

    cbs.on_remove_device_from_group = [this](const RemoveDeviceFromGroupCommand& cmd) {
        if (!cmd.group_device_identifier.empty()) {
            std::lock_guard<std::mutex> lock(state_mutex_);
            group_device_volumes_.erase(cmd.group_device_identifier);
        }
    };

    cbs.on_delete_group = [this](const DeleteGroupCommand& /*cmd*/) {
        std::lock_guard<std::mutex> lock(state_mutex_);
        group_device_volumes_.clear();
    };

    cbs.on_resync_group_data = [this](const ResyncGroupDataCommand& /*cmd*/) {
        (void)refresh_cluster();
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
    ps.is_paused = paused;
    ps.is_buffering = buffering;
    ps.playback_speed =
        snapshot.playback_phase == player::ContextPlayerImpl::SessionPlaybackPhase::Playing
            ? snapshot.playback_speed
            : 0.0;
    ps.position_as_of_timestamp = snapshot.position_ms;
    ps.duration = snapshot.duration_ms;

    ps.options.shuffling_context = snapshot.shuffling;
    ps.options.repeating_context =
        snapshot.repeat_mode == player::ContextPlayerImpl::SessionRepeatMode::Context ||
        snapshot.repeat_mode == player::ContextPlayerImpl::SessionRepeatMode::Track;
    ps.options.repeating_track =
        snapshot.repeat_mode == player::ContextPlayerImpl::SessionRepeatMode::Track;
    ps.options.playback_speed = static_cast<float>(snapshot.playback_speed);

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

PutStateRequest ConnectSubsystem::assemble_put_state_request(const QueuedPutStateTask& task) {
    const auto snapshot = task.snapshot.has_value()
                              ? *task.snapshot
                              : player_.snapshot_for_connect();
    const uint64_t now_ms = current_epoch_ms();
    const bool playing_or_paused =
        snapshot.playback_phase == player::ContextPlayerImpl::SessionPlaybackPhase::Playing ||
        snapshot.playback_phase == player::ContextPlayerImpl::SessionPlaybackPhase::BufferingPlay ||
        snapshot.playback_phase == player::ContextPlayerImpl::SessionPlaybackPhase::Paused ||
        snapshot.playback_phase == player::ContextPlayerImpl::SessionPlaybackPhase::BufferingPaused;

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
    req.last_command_sent_by_device_id = snapshot.last_command_sent_by_device_id;
    req.last_command_message_id = snapshot.last_command_message_id;
    req.started_playing_at = started_at;
    req.has_been_playing_for_ms = playing_duration_ms;
    req.client_side_timestamp = now_ms;
    req.only_write_player_state = task.only_write_player_state;

    req.device.device_info = devices_.local_device_info();
    if (!task.only_write_player_state) {
        req.device.player_state = build_connect_player_state(snapshot);
        req.device.has_player_state = !snapshot.context_uri.empty() ||
                                      !snapshot.context_url.empty() ||
                                      snapshot.current_track.has_value();
    } else {
        req.device.player_state = build_connect_player_state(snapshot);
        req.device.has_player_state = true;
    }
    return req;
}

PutStateResult ConnectSubsystem::execute_put_state_task(const QueuedPutStateTask& task) {
    const std::string dev_id = devices_.local_device_id();
    if (dev_id.empty()) {
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
    return client_.put_state(dev_id, req, task.wake_devices);
}

void ConnectSubsystem::enqueue_put_state(QueuedPutStateTask task) {
    {
        std::lock_guard<std::mutex> lock(queue_mutex_);
        if (worker_stop_requested_) {
            return;
        }
        // Coalesce consecutive PLAYER_STATE_CHANGED tasks so rapid player events upload latest state.
        if (task.reason == PutStateReason::PLAYER_STATE_CHANGED &&
            !put_state_queue_.empty() &&
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
        (void)execute_put_state_task(task);
    }
}

void ConnectSubsystem::on_player_state_changed(
    const player::ContextPlayerImpl::ConnectPlayerSnapshot& snapshot,
    bool track_changed) {
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (!running_) {
            return;
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
    }
    QueuedPutStateTask task;
    task.reason = PutStateReason::PLAYER_STATE_CHANGED;
    task.only_write_player_state =
        !track_changed && devices_.has_received_cluster_update_after_backend_connection();
    task.wake_devices = false;
    task.snapshot = snapshot;
    enqueue_put_state(std::move(task));
}

void ConnectSubsystem::handle_cluster_changed(const Cluster& cluster) {
    const std::string local_id = devices_.local_device_id();
    bool should_clear_wanted = false;
    bool became_inactive_remote = false;
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (!running_) {
            return;
        }
        if (cluster.active_device_id != last_cluster_active_device_id_) {
            last_cluster_active_device_id_ = cluster.active_device_id;
            should_clear_wanted = true;
        }
        if (!cluster.active_device_id.empty() && cluster.active_device_id != local_id) {
            became_inactive_remote = local_active_;
            local_active_ = false;
            was_playing_ = false;
            started_playing_at_ms_ = 0;
        } else if (!local_id.empty() && cluster.active_device_id == local_id) {
            local_active_ = true;
        }
    }
    if (should_clear_wanted) {
        client_.volume_throttler().clear_wanted_volume();
    }
    if (!cluster.active_device_id.empty() && cluster.active_device_id != local_id) {
        const auto snap = player_.snapshot_for_connect();
        if (is_active_playing_phase(snap.playback_phase)) {
            (void)player_.pause();
        }
        if (became_inactive_remote) {
            QueuedPutStateTask task;
            task.reason = PutStateReason::BECAME_INACTIVE;
            task.only_write_player_state = false;
            task.wake_devices = false;
            task.snapshot = player_.snapshot_for_connect();
            enqueue_put_state(std::move(task));
        }
    } else if (cluster.active_device_id.empty()) {
        const auto snap = player_.snapshot_for_connect();
        if (!is_active_playing_phase(snap.playback_phase)) {
            std::lock_guard<std::mutex> lock(state_mutex_);
            local_active_ = false;
        }
    }
    notify_state_listeners();
    notify_volume_listeners();
}

void ConnectSubsystem::handle_remote_volume_command(const SetVolumeCommand& cmd) {
    if (cmd.volume < 0) {
        return;
    }
    const uint32_t vol = static_cast<uint32_t>(
        std::min<int32_t>(cmd.volume, static_cast<int32_t>(kMaxVolumeSteps)));

    if (!cmd.group_device_identifier.empty()) {
        {
            std::lock_guard<std::mutex> lock(state_mutex_);
            group_device_volumes_[cmd.group_device_identifier] = vol;
        }
        notify_volume_listeners();
        return;
    }

    if (!client_.volume_throttler().should_apply_remote_volume(vol)) {
        return;
    }

    DeviceInfo local = devices_.local_device_info();
    local.volume = vol;
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
    task.reason = PutStateReason::VOLUME_CHANGED;
    task.only_write_player_state = false;
    enqueue_put_state(std::move(task));
}

void ConnectSubsystem::handle_remote_logout_command(const LogoutCommand& /*cmd*/) {
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
    local.audio_output_device_info =
        !outputs.empty() ? outputs.front() : AudioOutputDeviceInfo{};
    devices_.set_local_device_info(local);

    QueuedPutStateTask task;
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
    return client_.add_device_to_group(
        devices_.local_device_id(), target_device_id, cmd);
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
        notify_volume_listeners();
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
        notify_volume_listeners();
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
    return devices_.perform_discovery();
}

PutStateResult ConnectSubsystem::refresh_cluster() {
    QueuedPutStateTask task;
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
            ? group_device_id
            : (!active_id.empty() ? active_id : local_id);

    if (!group_device_id.empty()) {
        std::lock_guard<std::mutex> lock(state_mutex_);
        group_device_volumes_[group_device_id] = bounded;
    }

    if (group_device_id.empty() && (target_id == local_id || active_id.empty())) {
        DeviceInfo local = devices_.local_device_info();
        local.volume = bounded;
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
        task.reason = PutStateReason::VOLUME_CHANGED;
        task.only_write_player_state = false;
        const auto put_res = execute_put_state_task(task);
        return AckHttpResult{
            .ok = put_res.ok || put_res.deferred,
            .throttled = put_res.deferred,
            .http_status = put_res.http_status,
            .ack_id = {},
            .error_message = put_res.error_message,
        };
    }

    AckHttpResult res = client_.set_volume(local_id, target_id, bounded, group_device_id);
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
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        snap.group_device_volumes = group_device_volumes_;
        snap.local_reason = local_volume_reason_;
    }

    if (const auto wanted = client_.volume_throttler().active_wanted_volume()) {
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
