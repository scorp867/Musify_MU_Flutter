// ============================================================================
// Replicated Spotify Dealer WebSocket Client (Slim Orchestrator Implementation)
// Sources (`liborbit-jni-spotify.so` arm64):
// - Connect-State 12 dealer topics @ 0xdb4d9c..0xdb50c0
// - Connect-Group 2 dealer topics @ 0xd9f810, 0xd9f85c
// - dealerPingTime = 30000ms (0x7530)
// - WebSocket auth error refresh @ 0xb99358, connectivity/foreground @ 0xb98884, 0xb9893c
// ============================================================================

#include "DealerWebSocketClient.h"

#include "../network/NativeHttpClient.h"
#include "../network/NativeLog.h"

#include <curl/curl.h>
#include <poll.h>
#include <sys/eventfd.h>
#include <unistd.h>

#include <algorithm>
#include <array>
#include <cerrno>
#include <cstring>
#include <utility>

namespace spotify::connectstate {

namespace {

const char* reconnect_reason_label(int32_t reason_code) noexcept {
    switch (reason_code) {
        case 1: return "foreground";
        case 2: return "network_restored";
        case 3: return "auth_updated";
        case 4: return "manual";
        case 5: return "endpoint_updated";
        default: return "other";
    }
}

void drain_eventfd(int fd) {
    if (fd < 0) {
        return;
    }
    uint64_t drained = 0;
    while (true) {
        const ssize_t rc = ::read(fd, &drained, sizeof(drained));
        if (rc > 0) {
            continue;
        }
        if (rc < 0 && errno == EINTR) {
            continue;
        }
        if (rc < 0 && errno != EAGAIN && errno != EWOULDBLOCK) {
            DEALER_LOGD("Dealer wakeup_fd drain error: errno=%d (%s)",
                        errno,
                        std::strerror(errno));
        }
        break;
    }
}

}  // namespace

DealerWebSocketClient::DealerWebSocketClient(
    network::AuthSessionStore& auth_store,
    std::string dealer_base_url)
    : auth_store_(auth_store),
      dealer_base_url_(
          dealer_base_url.empty() ? std::string(kDefaultDealerWsUrl) : std::move(dealer_base_url)) {}

DealerWebSocketClient::~DealerWebSocketClient() {
    stop();
    close_wakeup_fd();
}

void DealerWebSocketClient::set_callbacks(DealerCallbacks callbacks) {
    std::lock_guard<std::mutex> lock(callbacks_mutex_);
    callbacks_ = std::move(callbacks);
}

void DealerWebSocketClient::set_dealer_base_url(std::string dealer_base_url) {
    if (dealer_base_url.empty()) {
        return;
    }
    bool should_reconnect = false;
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (dealer_base_url_ == dealer_base_url) {
            return;
        }
        dealer_base_url_ = std::move(dealer_base_url);
        if (running_ && !stop_requested_) {
            reconnect_requested_ = true;
            reset_backoff_requested_ = true;
            should_reconnect = true;
        }
    }
    DEALER_LOGI("Dealer endpoint updated to %s (reconnect=%d)",
                sanitize_url_for_log(dealer_base_url_).c_str(),
                should_reconnect ? 1 : 0);
    if (should_reconnect) {
        state_cv_.notify_all();
        wake_io_loop();
    }
}

std::string DealerWebSocketClient::dealer_base_url() const {
    std::lock_guard<std::mutex> lock(state_mutex_);
    return dealer_base_url_;
}

void DealerWebSocketClient::set_network_available(bool is_available) {
    bool changed = false;
    bool is_running_now = false;
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (network_available_ == is_available) {
            return;
        }
        network_available_ = is_available;
        changed = true;
        is_running_now = running_ && !stop_requested_;
        if (is_running_now) {
            reconnect_requested_ = true;
            if (is_available) {
                reset_backoff_requested_ = true;
            }
        }
    }
    if (changed) {
        DEALER_LOGI("Dealer network availability changed: available=%d", is_available ? 1 : 0);
        emit_diagnostic("dealer_network", is_available ? "online" : "offline");
        if (is_running_now) {
            state_cv_.notify_all();
            wake_io_loop();
        }
    }
}

bool DealerWebSocketClient::is_network_available() const {
    std::lock_guard<std::mutex> lock(state_mutex_);
    return network_available_;
}

void DealerWebSocketClient::on_auth_session_updated(const network::AuthCredentials& creds) {
    bool should_wake = false;
    bool cleared = false;
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (!running_ || stop_requested_) {
            return;
        }
        const bool token_changed = (creds.access_token != last_access_token_);
        last_auth_generation_ = creds.generation;
        last_access_token_ = creds.access_token;

        if (!creds.hasAccessToken()) {
            cleared = true;
            reconnect_requested_ = true;
            should_wake = true;
        } else if (state_ != DealerConnectionState::kConnected || token_changed) {
            reconnect_requested_ = true;
            reset_backoff_requested_ = true;
            should_wake = true;
        }
    }
    if (should_wake) {
        DEALER_LOGI("Dealer auth session update wakeup (has_token=%d, gen=%llu, cleared=%d)",
                    creds.hasAccessToken() ? 1 : 0,
                    static_cast<unsigned long long>(creds.generation),
                    cleared ? 1 : 0);
        state_cv_.notify_all();
        wake_io_loop();
    }
}

void DealerWebSocketClient::start() {
    if (is_on_worker_thread()) {
        return;
    }

    std::lock_guard<std::mutex> lifecycle_lock(lifecycle_mutex_);
    std::thread stale_thread;
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (running_) {
            return;
        }
        if (worker_thread_.joinable()) {
            stale_thread = std::move(worker_thread_);
        }
    }
    if (stale_thread.joinable()) {
        stale_thread.join();
    }

    {
        std::lock_guard<std::mutex> lock(outbound_mutex_);
        outbound_queue_.clear();
    }
    const auto initial_creds = auth_store_.snapshot();
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        stop_requested_ = false;
        reconnect_requested_ = false;
        reset_backoff_requested_ = true;
        connection_id_.clear();
        last_auth_generation_ = initial_creds.generation;
        last_access_token_ = initial_creds.access_token;
        running_ = true;
    }

    if (auth_listener_id_ == 0) {
        auth_listener_id_ = auth_store_.add_listener(
            [this](const network::AuthCredentials& creds) {
                on_auth_session_updated(creds);
            });
    }

    open_wakeup_fd();
    DEALER_LOGI("Starting Dealer WebSocket client (url=%s, has_token=%d)",
                sanitize_url_for_log(dealer_base_url()).c_str(),
                initial_creds.hasAccessToken() ? 1 : 0);
    worker_thread_ = std::thread(&DealerWebSocketClient::worker_loop, this);
}

void DealerWebSocketClient::stop() {
    if (is_on_worker_thread()) {
        {
            std::lock_guard<std::mutex> lock(state_mutex_);
            if (!running_) {
                return;
            }
            stop_requested_ = true;
            connection_id_.clear();
        }
        state_cv_.notify_all();
        wake_io_loop();
        return;
    }

    std::lock_guard<std::mutex> lifecycle_lock(lifecycle_mutex_);
    if (auth_listener_id_ != 0) {
        auth_store_.remove_listener(auth_listener_id_);
        auth_listener_id_ = 0;
    }

    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (!running_ && !worker_thread_.joinable()) {
            return;
        }
        stop_requested_ = true;
        connection_id_.clear();
    }
    state_cv_.notify_all();
    wake_io_loop();

    if (worker_thread_.joinable()) {
        worker_thread_.join();
    }

    {
        std::lock_guard<std::mutex> lock(outbound_mutex_);
        outbound_queue_.clear();
    }
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        running_ = false;
        stop_requested_ = false;
        reconnect_requested_ = false;
        reset_backoff_requested_ = false;
        connection_id_.clear();
        state_ = DealerConnectionState::kDisconnected;
    }
    close_wakeup_fd();
    DEALER_LOGI("Dealer WebSocket client stopped");
}

void DealerWebSocketClient::force_reconnect(int32_t reason_code) {
    bool wake = false;
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (!running_ || stop_requested_) {
            return;
        }
        reconnect_requested_ = true;
        reset_backoff_requested_ = true;
        wake = true;
    }
    if (wake) {
        DEALER_LOGI("Dealer force_reconnect requested (reason=%d:%s)",
                    reason_code,
                    reconnect_reason_label(reason_code));
        emit_diagnostic("dealer_force_reconnect", reconnect_reason_label(reason_code));
        state_cv_.notify_all();
        wake_io_loop();
    }
}

void DealerWebSocketClient::reconnect_now() {
    force_reconnect(4);
}

DealerConnectionState DealerWebSocketClient::connection_state() const {
    std::lock_guard<std::mutex> lock(state_mutex_);
    return state_;
}

std::string DealerWebSocketClient::connection_id() const {
    std::lock_guard<std::mutex> lock(state_mutex_);
    return connection_id_;
}

bool DealerWebSocketClient::is_running() const {
    std::lock_guard<std::mutex> lock(state_mutex_);
    return running_;
}

bool DealerWebSocketClient::is_on_worker_thread() const noexcept {
    const auto tid = worker_thread_id_.load(std::memory_order_acquire);
    return tid != std::thread::id{} && tid == std::this_thread::get_id();
}

bool DealerWebSocketClient::send_text(std::string text) {
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (!running_ || stop_requested_) {
            return false;
        }
    }
    {
        std::lock_guard<std::mutex> lock(outbound_mutex_);
        outbound_queue_.push_back(std::move(text));
    }
    wake_io_loop();
    return true;
}

bool DealerWebSocketClient::send_reply(std::string_view key, bool success) {
    if (key.empty()) {
        return false;
    }
    // Exact ping/reply JSON expected by Spotify Dealer: {"success": true }
    std::string body = "{\"type\":\"reply\",\"key\":\"";
    body.append(json::json_escape(key));
    body.append("\",\"payload\":{\"success\": ");
    body.append(success ? "true" : "false");
    body.append(" }}");
    return send_text(std::move(body));
}

void DealerWebSocketClient::open_wakeup_fd() {
    std::lock_guard<std::mutex> lock(wakeup_mutex_);
    const int existing = wakeup_fd_.load(std::memory_order_relaxed);
    if (existing >= 0) {
        drain_eventfd(existing);
        return;
    }
    const int fd = ::eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    if (fd < 0) {
        DEALER_LOGW("Failed to create Dealer wakeup eventfd: errno=%d (%s)",
                    errno,
                    std::strerror(errno));
    }
    wakeup_fd_.store(fd, std::memory_order_release);
}

void DealerWebSocketClient::wake_io_loop() {
    std::lock_guard<std::mutex> lock(wakeup_mutex_);
    const int fd = wakeup_fd_.load(std::memory_order_acquire);
    if (fd >= 0) {
        const uint64_t val = 1;
        const ssize_t rc = ::write(fd, &val, sizeof(val));
        if (rc < 0 && errno != EAGAIN && errno != EWOULDBLOCK) {
            DEALER_LOGD("Dealer wakeup_fd write failed: errno=%d (%s)",
                        errno,
                        std::strerror(errno));
        }
    }
}

void DealerWebSocketClient::close_wakeup_fd() {
    std::lock_guard<std::mutex> lock(wakeup_mutex_);
    const int fd = wakeup_fd_.exchange(-1, std::memory_order_acq_rel);
    if (fd >= 0) {
        ::close(fd);
    }
}

void DealerWebSocketClient::set_state(DealerConnectionState state) {
    DealerCallbacks cb_copy;
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (state_ == state) {
            return;
        }
        state_ = state;
        if (state != DealerConnectionState::kConnected) {
            connection_id_.clear();
        }
    }
    {
        std::lock_guard<std::mutex> lock(callbacks_mutex_);
        cb_copy = callbacks_;
    }
    if (cb_copy.on_connection_state_changed) {
        cb_copy.on_connection_state_changed(state);
    }
}

void DealerWebSocketClient::emit_diagnostic(
    std::string_view event_type,
    std::string_view detail) {
    std::function<void(std::string_view, std::string_view)> diag_cb;
    {
        std::lock_guard<std::mutex> lock(callbacks_mutex_);
        diag_cb = callbacks_.on_diagnostic_event;
    }
    if (diag_cb) {
        diag_cb(event_type, detail);
    }
}

std::string DealerWebSocketClient::build_connection_url(
    std::string_view base_url,
    std::string_view access_token) {
    std::string url(base_url);
    if (url.empty()) {
        url = kDefaultDealerWsUrl;
    }

    const std::string encoded_token = percent_encode_query_value(access_token);
    if (url.find('?') != std::string::npos) {
        if (url.back() != '&' && url.back() != '?') {
            url.push_back('&');
        }
    } else {
        if (url.back() != '/') {
            url.push_back('/');
        }
        url.push_back('?');
    }
    url.append("access_token=");
    url.append(encoded_token);
    return url;
}

std::string DealerWebSocketClient::build_profile_ws_url(
    std::string_view base_url,
    std::string_view access_token,
    const network::ClientHeaderProfile& profile) {
    if (profile.send_origin_headers) {
        // WebPlayer wire contract: wss://<dealer-host>/?access_token=<url_encoded>
        return build_connection_url(base_url, access_token);
    }
    // Native Android wire contract (liborbit 0x5a6068 -> p199p/C1637b6.java:972-978):
    // bare wss://<dealer-host>/ (access token goes in Authorization: Bearer header).
    std::string url(base_url.empty() ? std::string_view(kDefaultDealerWsUrl) : base_url);
    const size_t q = url.find('?');
    if (q != std::string::npos) {
        url.resize(q);
    }
    if (url.back() != '/') {
        url.push_back('/');
    }
    return url;
}

std::string DealerWebSocketClient::build_upgrade_request(
    std::string_view request_target,
    std::string_view host_header,
    std::string_view sec_websocket_key,
    std::string_view access_token,
    const network::ClientHeaderProfile& profile) {
    std::string req;
    req.reserve(384U + request_target.size() + host_header.size() + profile.user_agent.size());
    req.append("GET ");
    req.append(request_target);
    req.append(" HTTP/1.1\r\nHost: ");
    req.append(host_header);
    req.append("\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: ");
    req.append(sec_websocket_key);
    req.append("\r\nSec-WebSocket-Version: 13\r\n");
    if (profile.send_origin_headers) {
        req.append("Origin: https://open.spotify.com\r\n");
    } else if (!access_token.empty()) {
        req.append("Authorization: Bearer ");
        req.append(access_token);
        req.append("\r\n");
    }
    if (!profile.user_agent.empty()) {
        req.append("User-Agent: ");
        req.append(profile.user_agent);
        req.append("\r\n");
    }
    req.append("\r\n");
    return req;
}

std::optional<DealerEnvelope> DealerWebSocketClient::parse_dealer_envelope(std::string_view text) {
    return DealerMessageParser::parse_dealer_envelope(text);
}

std::optional<DealerPlayerCommand> DealerWebSocketClient::parse_player_command_envelope(
    const DealerEnvelope& envelope) {
    return DealerMessageParser::parse_player_command_envelope(envelope);
}

std::optional<std::vector<uint8_t>> DealerWebSocketClient::decode_protobuf_payload(
    const DealerEnvelope& envelope) {
    return DealerMessageParser::decode_protobuf_payload(envelope);
}

bool DealerWebSocketClient::validate_wol_info(const WakeOnLanInfo& info) {
    return WakeOnLanSender::validate_wol_info(info);
}

std::optional<std::vector<uint8_t>> DealerWebSocketClient::build_wol_magic_packet(
    const WakeOnLanInfo& info) {
    return WakeOnLanSender::build_wol_magic_packet(info);
}

bool DealerWebSocketClient::send_wol_magic_packet(const WakeOnLanInfo& info) {
    return WakeOnLanSender::send_wol_magic_packet(info);
}

bool DealerWebSocketClient::handle_incoming_text_message(std::string_view text) {
    return process_inbound_text_frame(text, nullptr);
}

bool DealerWebSocketClient::process_inbound_text_frame(
    std::string_view text,
    bool* out_received_pong) {
    if (text.empty()) {
        return true;
    }
    auto env = DealerMessageParser::parse_dealer_envelope(text);
    if (!env.has_value()) {
        DEALER_LOGW("Failed to parse Dealer JSON text frame (bytes=%zu)", text.size());
        return false;
    }
    if (env->type == "pong") {
        if (out_received_pong != nullptr) {
            *out_received_pong = true;
        }
        return true;
    }
    dispatch_dealer_envelope(*env);
    return true;
}

void DealerWebSocketClient::dispatch_dealer_envelope(const DealerEnvelope& envelope) {
    DealerCallbacks cb_copy;
    {
        std::lock_guard<std::mutex> lock(callbacks_mutex_);
        cb_copy = callbacks_;
    }

    if (envelope.type == "pong" || envelope.type == "ping") {
        if (envelope.type == "ping") {
            if (!send_text("{\"type\":\"pong\"}")) {
                DEALER_LOGW("Failed to queue Dealer pong response");
            }
        }
        return;
    }

    const auto conn_id_hdr = DealerMessageParser::extract_connection_id(envelope);
    if (conn_id_hdr.has_value() && !conn_id_hdr->empty()) {
        bool changed = false;
        {
            std::lock_guard<std::mutex> lock(state_mutex_);
            if (connection_id_ != *conn_id_hdr) {
                connection_id_ = *conn_id_hdr;
                changed = true;
            }
        }
        if (changed) {
            DEALER_LOGI("Received Spotify-Connection-Id (len=%zu)", conn_id_hdr->size());
            emit_diagnostic("dealer_connection_id", "received");
            if (cb_copy.on_connection_id) {
                cb_copy.on_connection_id(*conn_id_hdr);
            }
        }
    }

    const std::string_view topic =
        !envelope.message_ident.empty() ? std::string_view(envelope.message_ident)
                                        : std::string_view(envelope.uri);

    if (topic.rfind(kPusherConnectionsPrefix, 0) == 0 && conn_id_hdr.has_value()) {
        return;
    }

    if (topic == kTopicPing) {
        if (!send_reply(envelope.key, true)) {
            DEALER_LOGW("Failed to send Dealer ping reply");
        }
        return;
    }

    if (topic == kTopicPlayerCommand) {
        const auto cmd = DealerMessageParser::parse_player_command_envelope(envelope);
        bool ok = false;
        if (!cmd.has_value()) {
            DEALER_LOGW("Failed to parse Dealer player command envelope");
        } else {
            DEALER_LOGI("Inbound Dealer player command: endpoint=%s msg_id=%u alias=%u",
                        cmd->endpoint.c_str(),
                        cmd->message_id,
                        cmd->target_alias_id);
            if (cb_copy.on_player_command) {
                ok = cb_copy.on_player_command(*cmd);
            }
        }
        if (!envelope.key.empty() && !send_reply(envelope.key, ok)) {
            DEALER_LOGW("Failed to send Dealer reply for player command");
        }
        return;
    }

    if (topic == kTopicGroupDataEvent) {
        GroupDataEvent ev;
        const bool decode_ok = DealerMessageParser::decode_group_data_event_payload(envelope, ev);
        if (!decode_ok) {
            DEALER_LOGW("Failed to decode Dealer GroupDataEvent payload");
        } else if (cb_copy.on_group_data_event) {
            cb_copy.on_group_data_event(ev);
        }
        if (!envelope.key.empty() && !send_reply(envelope.key, decode_ok)) {
            DEALER_LOGW("Failed to send Dealer reply for group-data-event");
        }
        return;
    }

    if (topic == kTopicGroupDeviceVolumeEvent) {
        GroupDeviceVolumeEvent ev;
        const bool decode_ok =
            DealerMessageParser::decode_group_device_volume_event_payload(envelope, ev);
        if (!decode_ok) {
            DEALER_LOGW("Failed to decode Dealer GroupDeviceVolumeEvent payload");
        } else if (cb_copy.on_group_device_volume_event) {
            cb_copy.on_group_device_volume_event(ev);
        }
        if (!envelope.key.empty() && !send_reply(envelope.key, decode_ok)) {
            DEALER_LOGW("Failed to send Dealer reply for group-device-volume-event");
        }
        return;
    }

    const auto raw_pb = DealerMessageParser::decode_protobuf_payload(envelope);
    if (!raw_pb.has_value()) {
        DEALER_LOGW("Failed to decode base64/gzip payload for topic=%.*s",
                    static_cast<int>(topic.size()),
                    topic.data());
        if (!envelope.key.empty() && !send_reply(envelope.key, false)) {
            DEALER_LOGW("Failed to send negative Dealer reply");
        }
        return;
    }

    bool known_topic = true;
    bool decode_ok = false;

    if (topic == kTopicCluster) {
        ClusterUpdate update;
        decode_ok = decode_cluster_update(raw_pb->data(), raw_pb->size(), update);
        if (!decode_ok) {
            DEALER_LOGW("Failed to decode ClusterUpdate protobuf (%zu bytes)", raw_pb->size());
        } else if (cb_copy.on_cluster_update) {
            cb_copy.on_cluster_update(update);
        }
    } else if (topic == kTopicVolume) {
        SetVolumeCommand cmd;
        decode_ok = decode_set_volume_command(raw_pb->data(), raw_pb->size(), cmd);
        if (!decode_ok) {
            DEALER_LOGW("Failed to decode SetVolumeCommand protobuf (%zu bytes)", raw_pb->size());
        } else if (cb_copy.on_set_volume) {
            cb_copy.on_set_volume(cmd);
        }
    } else if (topic == kTopicLogout) {
        LogoutCommand cmd;
        decode_ok = decode_logout_command(raw_pb->data(), raw_pb->size(), cmd);
        if (!envelope.key.empty() && !send_reply(envelope.key, decode_ok)) {
            DEALER_LOGW("Failed to send Dealer reply for logout command");
        }
        if (decode_ok && cb_copy.on_logout) {
            cb_copy.on_logout(cmd);
        }
        return;
    } else if (topic == kTopicBackendMetadata) {
        SetBackendMetadataCommand cmd;
        decode_ok = decode_set_backend_metadata_command(raw_pb->data(), raw_pb->size(), cmd);
        if (!decode_ok) {
            DEALER_LOGW("Failed to decode SetBackendMetadataCommand protobuf");
        } else if (cb_copy.on_set_backend_metadata) {
            cb_copy.on_set_backend_metadata(cmd);
        }
    } else if (topic == kTopicProxyTransfer) {
        ProxyTransferCommand cmd;
        decode_ok = decode_proxy_transfer_command(raw_pb->data(), raw_pb->size(), cmd);
        if (decode_ok) {
            if (cmd.wol_info.has_value() && WakeOnLanSender::validate_wol_info(*cmd.wol_info)) {
                if (!WakeOnLanSender::send_wol_magic_packet(*cmd.wol_info)) {
                    DEALER_LOGW("WakeOnLan send failed during proxy_transfer");
                }
            }
            if (cb_copy.on_proxy_transfer) {
                cb_copy.on_proxy_transfer(cmd);
            }
        } else {
            DEALER_LOGW("Failed to decode ProxyTransferCommand protobuf");
        }
    } else if (topic == kTopicProxyWake) {
        ProxyWakeCommand cmd;
        decode_ok = decode_proxy_wake_command(raw_pb->data(), raw_pb->size(), cmd);
        if (decode_ok) {
            if (cmd.wol_info.has_value() && WakeOnLanSender::validate_wol_info(*cmd.wol_info)) {
                if (!WakeOnLanSender::send_wol_magic_packet(*cmd.wol_info)) {
                    DEALER_LOGW("WakeOnLan send failed during proxy_wake");
                }
            }
            if (cb_copy.on_proxy_wake) {
                cb_copy.on_proxy_wake(cmd);
            }
        } else {
            DEALER_LOGW("Failed to decode ProxyWakeCommand protobuf");
        }
    } else if (topic == kTopicGroupAddDevice) {
        AddDeviceToGroupCommand cmd;
        decode_ok = decode_add_device_to_group_command(raw_pb->data(), raw_pb->size(), cmd);
        if (decode_ok && cb_copy.on_add_device_to_group) {
            cb_copy.on_add_device_to_group(cmd);
        }
    } else if (topic == kTopicGroupRemoveDevice) {
        RemoveDeviceFromGroupCommand cmd;
        decode_ok = decode_remove_device_from_group_command(raw_pb->data(), raw_pb->size(), cmd);
        if (decode_ok && cb_copy.on_remove_device_from_group) {
            cb_copy.on_remove_device_from_group(cmd);
        }
    } else if (topic == kTopicGroupDelete) {
        DeleteGroupCommand cmd;
        decode_ok = decode_delete_group_command(raw_pb->data(), raw_pb->size(), cmd);
        if (decode_ok && cb_copy.on_delete_group) {
            cb_copy.on_delete_group(cmd);
        }
    } else if (topic == kTopicGroupResync) {
        ResyncGroupDataCommand cmd;
        decode_ok = decode_resync_group_data_command(raw_pb->data(), raw_pb->size(), cmd);
        if (decode_ok && cb_copy.on_resync_group_data) {
            cb_copy.on_resync_group_data(cmd);
        }
    } else {
        known_topic = false;
        DEALER_LOGD("Ignoring unhandled Dealer topic: %.*s",
                    static_cast<int>(topic.size()),
                    topic.data());
    }

    if (!envelope.key.empty() && !send_reply(envelope.key, known_topic && decode_ok)) {
        DEALER_LOGW("Failed to send Dealer reply for topic=%.*s",
                    static_cast<int>(topic.size()),
                    topic.data());
    }
}

void DealerWebSocketClient::worker_loop() {
    struct WorkerThreadIdGuard {
        explicit WorkerThreadIdGuard(std::atomic<std::thread::id>& slot) : slot_(slot) {
            slot_.store(std::this_thread::get_id(), std::memory_order_release);
        }
        ~WorkerThreadIdGuard() {
            slot_.store(std::thread::id{}, std::memory_order_release);
        }
        std::atomic<std::thread::id>& slot_;
    } thread_id_guard(worker_thread_id_);

    const std::string& ca_bundle = network::NativeHttpClient::caPemBundle();
    const char* fallback_ca_dir = network::NativeHttpClient::fallbackCaDir();
    int64_t reconnect_delay_ms = kInitialReconnectDelayMs;

    auto wait_backoff = [&](bool indefinite_park) {
        set_state(DealerConnectionState::kReconnecting);
        std::unique_lock<std::mutex> lock(state_mutex_);
        if (stop_requested_) {
            return;
        }
        if (reset_backoff_requested_) {
            reconnect_delay_ms = kInitialReconnectDelayMs;
            reset_backoff_requested_ = false;
            return;
        }
        if (indefinite_park) {
            state_cv_.wait(lock, [this]() {
                return stop_requested_ || reconnect_requested_;
            });
            if (reset_backoff_requested_) {
                reconnect_delay_ms = kInitialReconnectDelayMs;
                reset_backoff_requested_ = false;
            }
            return;
        }
        state_cv_.wait_for(
            lock,
            std::chrono::milliseconds(reconnect_delay_ms),
            [this]() { return stop_requested_ || reconnect_requested_; });
        if (reset_backoff_requested_) {
            reconnect_delay_ms = kInitialReconnectDelayMs;
            reset_backoff_requested_ = false;
        } else {
            reconnect_delay_ms = std::min(reconnect_delay_ms * 2, kMaxReconnectDelayMs);
        }
    };

    while (true) {
        std::string current_base_url;
        bool net_avail = true;
        {
            std::lock_guard<std::mutex> lock(state_mutex_);
            if (stop_requested_) {
                break;
            }
            if (reset_backoff_requested_) {
                reconnect_delay_ms = kInitialReconnectDelayMs;
                reset_backoff_requested_ = false;
            }
            reconnect_requested_ = false;
            current_base_url = dealer_base_url_;
            net_avail = network_available_;
        }

        // Wait cleanly for an access token via AuthSessionStore observer (zero polling).
        const auto creds = auth_store_.snapshot();
        if (!creds.hasAccessToken()) {
            DEALER_LOGI("Dealer waiting for access token (AuthSessionStore listener active)");
            wait_backoff(/*indefinite_park=*/true);
            continue;
        }

        // Wait cleanly when offline (either explicit Android network flag or kernel FIB).
        if (!net_avail || !network::NativeHttpClient::hasActiveNetworkRoute()) {
            DEALER_LOGI("Dealer paused: network unavailable (net_flag=%d)", net_avail ? 1 : 0);
            wait_backoff(/*indefinite_park=*/!net_avail);
            continue;
        }

        set_state(DealerConnectionState::kConnecting);

        CURL* curl = curl_easy_init();
        if (curl == nullptr) {
            DEALER_LOGE("curl_easy_init failed for Dealer WebSocket");
            wait_backoff(false);
            continue;
        }

        const auto profile = auth_store_.client_profile();
        const std::string ws_url =
            build_profile_ws_url(current_base_url, creds.access_token, profile);
        const std::string safe_log_url = sanitize_url_for_log(ws_url);

        std::string connect_url;
        std::string host_header;
        std::string request_target;
        if (!parse_ws_connect_params(ws_url, connect_url, host_header, request_target)) {
            DEALER_LOGE("Invalid Dealer WebSocket URL: %s", safe_log_url.c_str());
            curl_easy_cleanup(curl);
            wait_backoff(false);
            continue;
        }

        curl_easy_setopt(curl, CURLOPT_URL, connect_url.c_str());
        curl_easy_setopt(curl, CURLOPT_CONNECT_ONLY, 1L);
        curl_easy_setopt(curl, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_1_1);
        curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
        curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT_MS, 15000L);
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1L);
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 2L);

        curl_blob ca_blob{};
        if (!ca_bundle.empty()) {
            ca_blob.data = const_cast<char*>(ca_bundle.data());
            ca_blob.len = ca_bundle.size();
            ca_blob.flags = CURL_BLOB_NOCOPY;
            curl_easy_setopt(curl, CURLOPT_CAINFO_BLOB, &ca_blob);
        } else if (fallback_ca_dir != nullptr && fallback_ca_dir[0] != '\0') {
            curl_easy_setopt(curl, CURLOPT_CAPATH, fallback_ca_dir);
        }

        DEALER_LOGI("Connecting Dealer WS: %s (profile=%s)",
                    safe_log_url.c_str(),
                    profile.send_origin_headers ? "webPlayer" : "android");

        const CURLcode connect_rc = curl_easy_perform(curl);
        curl_socket_t sockfd = CURL_SOCKET_BAD;
        if (connect_rc == CURLE_OK) {
            curl_easy_getinfo(curl, CURLINFO_ACTIVESOCKET, &sockfd);
        }

        if (connect_rc != CURLE_OK || sockfd == CURL_SOCKET_BAD) {
            DEALER_LOGW("Dealer WS TLS connect failed: url=%s curl=%d (%s)",
                        safe_log_url.c_str(),
                        static_cast<int>(connect_rc),
                        curl_easy_strerror(connect_rc));
            emit_diagnostic("dealer_connect_error", curl_easy_strerror(connect_rc));
            curl_easy_cleanup(curl);
            wait_backoff(false);
            continue;
        }

        // Perform non-blocking RFC 6455 §4.1 HTTP/1.1 Upgrade over curl_easy_send/recv.
        Rfc6455FrameParser parser;
        bool upgrade_ok = false;
        HttpUpgradeResponseInfo upgrade_info;
        {
            std::array<uint8_t, 16> nonce{};
            if (fill_csprng_bytes(nonce.data(), nonce.size())) {
                const std::string sec_ws_key = base64_encode(nonce.data(), nonce.size());
                const std::string expected_accept = compute_websocket_accept(sec_ws_key);
                const std::string upgrade_req = build_upgrade_request(
                    request_target, host_header, sec_ws_key, creds.access_token, profile);

                size_t req_sent = 0;
                std::string upgrade_rx;
                const auto upgrade_deadline =
                    std::chrono::steady_clock::now() + std::chrono::milliseconds(15000);
                bool handshake_failed = false;

                while (!handshake_failed && !upgrade_ok) {
                    {
                        std::lock_guard<std::mutex> lock(state_mutex_);
                        if (stop_requested_ || reconnect_requested_) {
                            handshake_failed = true;
                            break;
                        }
                    }

                    while (req_sent < upgrade_req.size()) {
                        size_t sent = 0;
                        const CURLcode send_rc = curl_easy_send(
                            curl,
                            upgrade_req.data() + req_sent,
                            upgrade_req.size() - req_sent,
                            &sent);
                        if (send_rc == CURLE_AGAIN) {
                            break;
                        }
                        if (send_rc != CURLE_OK || sent == 0U) {
                            handshake_failed = true;
                            break;
                        }
                        req_sent += sent;
                    }
                    if (handshake_failed) {
                        break;
                    }

                    if (req_sent == upgrade_req.size()) {
                        while (!handshake_failed && !upgrade_ok) {
                            std::array<char, 4096> rx_tmp{};
                            size_t rlen = 0;
                            const CURLcode recv_rc =
                                curl_easy_recv(curl, rx_tmp.data(), rx_tmp.size(), &rlen);
                            if (recv_rc == CURLE_AGAIN) {
                                break;
                            }
                            if (recv_rc != CURLE_OK || rlen == 0U) {
                                handshake_failed = true;
                                break;
                            }
                            upgrade_rx.append(rx_tmp.data(), rlen);
                            const HttpUpgradeParseResult hres = parse_websocket_upgrade_response(
                                upgrade_rx, expected_accept, upgrade_info);
                            if (hres == HttpUpgradeParseResult::kHttpError ||
                                hres == HttpUpgradeParseResult::kProtocolError) {
                                handshake_failed = true;
                                break;
                            }
                            if (hres == HttpUpgradeParseResult::kOk) {
                                if (upgrade_info.header_bytes < upgrade_rx.size()) {
                                    parser.feed(
                                        reinterpret_cast<const uint8_t*>(
                                            upgrade_rx.data() + upgrade_info.header_bytes),
                                        upgrade_rx.size() - upgrade_info.header_bytes);
                                }
                                upgrade_ok = true;
                                break;
                            }
                        }
                    }

                    if (handshake_failed || upgrade_ok) {
                        break;
                    }

                    const auto now_hs = std::chrono::steady_clock::now();
                    if (now_hs >= upgrade_deadline) {
                        handshake_failed = true;
                        break;
                    }
                    const auto rem_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                                            upgrade_deadline - now_hs)
                                            .count();
                    const int poll_ms = static_cast<int>(std::min<int64_t>(rem_ms, 500));

                    struct pollfd hs_fds[2]{};
                    nfds_t hs_nfds = 1;
                    hs_fds[0].fd = static_cast<int>(sockfd);
                    hs_fds[0].events =
                        POLLIN | POLLERR | POLLHUP | (req_sent < upgrade_req.size() ? POLLOUT : 0);
                    const int wfd = wakeup_fd_.load(std::memory_order_acquire);
                    if (wfd >= 0) {
                        hs_fds[1].fd = wfd;
                        hs_fds[1].events = POLLIN;
                        hs_nfds = 2;
                    }
                    const int hs_poll_rc = ::poll(hs_fds, hs_nfds, std::max(1, poll_ms));
                    if (hs_poll_rc < 0 && errno != EINTR) {
                        handshake_failed = true;
                        break;
                    }
                    if (hs_nfds == 2 && (hs_fds[1].revents & POLLIN) != 0) {
                        drain_eventfd(wfd);
                    }
                    if ((hs_fds[0].revents & (POLLERR | POLLNVAL)) != 0 ||
                        ((hs_fds[0].revents & POLLHUP) != 0 &&
                         (hs_fds[0].revents & POLLIN) == 0)) {
                        handshake_failed = true;
                        break;
                    }
                }
            } else {
                DEALER_LOGE("CSPRNG failure generating Sec-WebSocket-Key");
            }
        }

        if (!upgrade_ok) {
            curl_easy_cleanup(curl);
            DEALER_LOGW("Dealer WS HTTP/1.1 Upgrade failed: status=%d status_line='%s' url=%s",
                        upgrade_info.http_status_code,
                        upgrade_info.status_line.c_str(),
                        safe_log_url.c_str());
            emit_diagnostic(
                "dealer_upgrade_failed",
                upgrade_info.status_line.empty() ? "handshake_failed" : upgrade_info.status_line);

            {
                std::lock_guard<std::mutex> lock(state_mutex_);
                if (stop_requested_) {
                    break;
                }
            }

            if (upgrade_info.http_status_code == 401 || upgrade_info.http_status_code == 403) {
                DEALER_LOGW(
                    "Dealer WS received auth error (%d); requesting token refresh (gen=%llu)",
                    upgrade_info.http_status_code,
                    static_cast<unsigned long long>(creds.generation));
                emit_diagnostic("dealer_auth_refresh", std::to_string(upgrade_info.http_status_code));
                const bool refreshed = auth_store_.requestTokenRefreshAndWait(
                    creds.generation,
                    network::AuthRefreshReason::kDealerWs401,
                    8000);
                if (refreshed) {
                    DEALER_LOGI("Dealer WS auth token refreshed; reconnecting immediately");
                    reconnect_delay_ms = kInitialReconnectDelayMs;
                    continue;
                }
                DEALER_LOGW("Dealer WS auth token refresh timed out or failed");
            }

            {
                std::lock_guard<std::mutex> lock(state_mutex_);
                if (stop_requested_) {
                    break;
                }
                if (reconnect_requested_) {
                    reconnect_delay_ms = kInitialReconnectDelayMs;
                    reset_backoff_requested_ = false;
                    continue;
                }
            }
            wait_backoff(false);
            continue;
        }

        DEALER_LOGI("Dealer WebSocket connected: %s", safe_log_url.c_str());
        emit_diagnostic("dealer_connected", safe_log_url);
        set_state(DealerConnectionState::kConnected);
        reconnect_delay_ms = kInitialReconnectDelayMs;

        auto last_ping_sent_at = std::chrono::steady_clock::now();
        bool awaiting_pong = false;

        std::vector<uint8_t> raw_tx_buffer;
        size_t raw_tx_offset = 0;
        bool session_alive = true;

        auto compact_tx = [&]() {
            if (raw_tx_offset == raw_tx_buffer.size()) {
                raw_tx_buffer.clear();
                raw_tx_offset = 0;
            } else if (raw_tx_offset >= 65536U) {
                raw_tx_buffer.erase(
                    raw_tx_buffer.begin(),
                    raw_tx_buffer.begin() + static_cast<std::ptrdiff_t>(raw_tx_offset));
                raw_tx_offset = 0;
            }
        };

        auto enqueue_frame = [&](Rfc6455Opcode op, const uint8_t* data, size_t len) -> bool {
            if (!encode_rfc6455_client_frame(op, data, len, raw_tx_buffer)) {
                DEALER_LOGW("Failed to encode RFC 6455 client frame (opcode=%u, len=%zu)",
                            static_cast<unsigned int>(op),
                            len);
                session_alive = false;
                return false;
            }
            return true;
        };

        auto flush_raw_tx = [&]() {
            while (session_alive && raw_tx_offset < raw_tx_buffer.size()) {
                size_t sent = 0;
                const CURLcode send_rc = curl_easy_send(
                    curl,
                    raw_tx_buffer.data() + raw_tx_offset,
                    raw_tx_buffer.size() - raw_tx_offset,
                    &sent);
                if (send_rc == CURLE_AGAIN) {
                    break;
                }
                if (send_rc != CURLE_OK || sent == 0U) {
                    DEALER_LOGW("Dealer WS send failed: curl=%d (%s)",
                                static_cast<int>(send_rc),
                                curl_easy_strerror(send_rc));
                    session_alive = false;
                    break;
                }
                raw_tx_offset += sent;
            }
            compact_tx();
        };

        auto drain_outbound = [&]() {
            std::deque<std::string> pending;
            {
                std::lock_guard<std::mutex> lock(outbound_mutex_);
                pending.swap(outbound_queue_);
            }
            while (!pending.empty() && session_alive) {
                const std::string& msg = pending.front();
                if (!enqueue_frame(
                        Rfc6455Opcode::kText,
                        reinterpret_cast<const uint8_t*>(msg.data()),
                        msg.size())) {
                    break;
                }
                pending.pop_front();
            }
            flush_raw_tx();
        };

        auto should_stop_or_reconnect = [&]() -> bool {
            std::lock_guard<std::mutex> lock(state_mutex_);
            return stop_requested_ || reconnect_requested_ || !network_available_;
        };

        auto flush_pending_tx_bounded = [&]() {
            if (!session_alive || raw_tx_offset >= raw_tx_buffer.size()) {
                return;
            }
            const auto flush_deadline =
                std::chrono::steady_clock::now() + std::chrono::milliseconds(250);
            while (session_alive && raw_tx_offset < raw_tx_buffer.size()) {
                flush_raw_tx();
                if (!session_alive || raw_tx_offset >= raw_tx_buffer.size()) {
                    break;
                }
                const auto now_flush = std::chrono::steady_clock::now();
                if (now_flush >= flush_deadline) {
                    break;
                }
                const auto rem_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                                        flush_deadline - now_flush)
                                        .count();
                struct pollfd pfd{};
                pfd.fd = static_cast<int>(sockfd);
                pfd.events = POLLOUT | POLLERR | POLLHUP;
                const int prc = ::poll(&pfd, 1, static_cast<int>(std::max<int64_t>(1, rem_ms)));
                if (prc <= 0 || (pfd.revents & (POLLERR | POLLHUP | POLLNVAL)) != 0) {
                    break;
                }
            }
        };

        auto process_parser_frames = [&]() {
            while (session_alive) {
                Rfc6455Frame frame;
                const Rfc6455ParseResult pres = parser.next_frame(frame);
                if (pres == Rfc6455ParseResult::kNeedMoreData) {
                    break;
                }
                if (pres == Rfc6455ParseResult::kProtocolError) {
                    DEALER_LOGW("Dealer WS RFC 6455 protocol error; closing session");
                    session_alive = false;
                    break;
                }
                switch (frame.opcode) {
                    case Rfc6455Opcode::kClose: {
                        const size_t close_len = frame.payload.size() >= 2U ? 2U : 0U;
                        const uint8_t* close_ptr =
                            close_len > 0U
                                ? reinterpret_cast<const uint8_t*>(frame.payload.data())
                                : nullptr;
                        if (enqueue_frame(Rfc6455Opcode::kClose, close_ptr, close_len)) {
                            flush_raw_tx();
                        }
                        DEALER_LOGI("Dealer WS received peer Close frame");
                        session_alive = false;
                        break;
                    }
                    case Rfc6455Opcode::kPing: {
                        const uint8_t* ping_ptr =
                            frame.payload.empty()
                                ? nullptr
                                : reinterpret_cast<const uint8_t*>(frame.payload.data());
                        if (enqueue_frame(Rfc6455Opcode::kPong, ping_ptr, frame.payload.size())) {
                            flush_raw_tx();
                        }
                        break;
                    }
                    case Rfc6455Opcode::kPong: {
                        awaiting_pong = false;
                        break;
                    }
                    case Rfc6455Opcode::kText: {
                        bool got_pong = false;
                        if (!process_inbound_text_frame(frame.payload, &got_pong)) {
                            DEALER_LOGW("Dealer WS dropped malformed text frame");
                        }
                        if (got_pong) {
                            awaiting_pong = false;
                        }
                        break;
                    }
                    case Rfc6455Opcode::kBinary:
                    case Rfc6455Opcode::kContinuation:
                        break;
                }
                if (!session_alive || should_stop_or_reconnect()) {
                    break;
                }
            }
        };

        while (session_alive) {
            drain_outbound();
            if (!session_alive) {
                break;
            }
            if (should_stop_or_reconnect()) {
                flush_pending_tx_bounded();
                session_alive = false;
                break;
            }

            if (parser.buffered_bytes() > 0U) {
                process_parser_frames();
                drain_outbound();
                if (!session_alive) {
                    break;
                }
                if (should_stop_or_reconnect()) {
                    flush_pending_tx_bounded();
                    session_alive = false;
                    break;
                }
            }

            const auto now = std::chrono::steady_clock::now();
            if (awaiting_pong &&
                std::chrono::duration_cast<std::chrono::milliseconds>(now - last_ping_sent_at)
                        .count() >= kDealerPongTimeoutMs) {
                DEALER_LOGW("Dealer WS pong timeout (%lldms); reconnecting",
                            static_cast<long long>(kDealerPongTimeoutMs));
                emit_diagnostic("dealer_pong_timeout", "reconnecting");
                session_alive = false;
                break;
            }
            if (!awaiting_pong &&
                std::chrono::duration_cast<std::chrono::milliseconds>(now - last_ping_sent_at)
                        .count() >= kDealerPingIntervalMs) {
                static constexpr const char kPingFrame[] = "{\"type\":\"ping\"}";
                if (enqueue_frame(
                        Rfc6455Opcode::kText,
                        reinterpret_cast<const uint8_t*>(kPingFrame),
                        sizeof(kPingFrame) - 1U)) {
                    flush_raw_tx();
                    if (session_alive) {
                        last_ping_sent_at = now;
                        awaiting_pong = true;
                    }
                }
                if (!session_alive) {
                    break;
                }
            }

            while (session_alive) {
                std::array<uint8_t, 32768> buf{};
                size_t rlen = 0;
                const CURLcode recv_rc = curl_easy_recv(curl, buf.data(), buf.size(), &rlen);
                if (recv_rc == CURLE_AGAIN) {
                    break;
                }
                if (recv_rc != CURLE_OK || rlen == 0U) {
                    DEALER_LOGI("Dealer WS recv ended: curl=%d (%s), bytes=%zu",
                                static_cast<int>(recv_rc),
                                curl_easy_strerror(recv_rc),
                                rlen);
                    session_alive = false;
                    break;
                }
                parser.feed(buf.data(), rlen);
                process_parser_frames();
                if (should_stop_or_reconnect()) {
                    break;
                }
            }

            drain_outbound();
            if (!session_alive) {
                break;
            }
            if (should_stop_or_reconnect()) {
                flush_pending_tx_bounded();
                session_alive = false;
                break;
            }

            struct pollfd fds[2]{};
            nfds_t nfds = 1;
            fds[0].fd = static_cast<int>(sockfd);
            fds[0].events =
                POLLIN | POLLERR | POLLHUP | (raw_tx_offset < raw_tx_buffer.size() ? POLLOUT : 0);
            const int wfd = wakeup_fd_.load(std::memory_order_acquire);
            if (wfd >= 0) {
                fds[1].fd = wfd;
                fds[1].events = POLLIN;
                nfds = 2;
            }
            const int poll_rc = ::poll(fds, nfds, 500);
            if (poll_rc < 0 && errno != EINTR) {
                DEALER_LOGW("Dealer WS poll error: errno=%d (%s)", errno, std::strerror(errno));
                session_alive = false;
                break;
            }
            if (nfds == 2 && (fds[1].revents & POLLIN) != 0) {
                drain_eventfd(wfd);
            }
            if ((fds[0].revents & (POLLERR | POLLNVAL)) != 0 ||
                ((fds[0].revents & POLLHUP) != 0 && (fds[0].revents & POLLIN) == 0)) {
                DEALER_LOGI("Dealer WS socket closed (revents=0x%x)",
                            static_cast<unsigned int>(fds[0].revents));
                session_alive = false;
                break;
            }
        }

        curl_easy_cleanup(curl);

        {
            std::lock_guard<std::mutex> lock(state_mutex_);
            if (stop_requested_) {
                break;
            }
            if (reconnect_requested_) {
                reconnect_delay_ms = kInitialReconnectDelayMs;
                reset_backoff_requested_ = false;
                continue;
            }
        }

        wait_backoff(false);
    }

    close_wakeup_fd();
    {
        std::lock_guard<std::mutex> lock(outbound_mutex_);
        outbound_queue_.clear();
    }
    bool notify_disconnected = false;
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        running_ = false;
        stop_requested_ = false;
        reconnect_requested_ = false;
        reset_backoff_requested_ = false;
        connection_id_.clear();
        if (state_ != DealerConnectionState::kDisconnected) {
            state_ = DealerConnectionState::kDisconnected;
            notify_disconnected = true;
        }
    }
    state_cv_.notify_all();
    if (notify_disconnected) {
        DealerCallbacks cb_copy;
        {
            std::lock_guard<std::mutex> lock(callbacks_mutex_);
            cb_copy = callbacks_;
        }
        if (cb_copy.on_connection_state_changed) {
            cb_copy.on_connection_state_changed(DealerConnectionState::kDisconnected);
        }
    }
}

}  // namespace spotify::connectstate
