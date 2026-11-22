// ============================================================================
// Replicated from liborbit-jni-spotify.so (ConnectStateClientImpl HTTP endpoints,
// Connection-ID Gating, Ack Tracking & Outbound Rate Limiters):
// - Binary symbols / offsets:
//   - Default spclient fallback `https://spclient.wg.spotify.com` (0x350245 @ 0xb1d15c)
//   - connection_id_decorator missing X-Spotify-Connection-Id err=8 (0x39c1c3 @ 0x12effc4..0x12f0040)
//   - ConnectStateClientImpl::putState @ 0xdc1b8c..0xdc2290 (?wake-devices=true|false on PICKER_OPENED=6)
//   - ConnectStateClientImpl::updateLocalDevices @ 0xdc3b94..0xdc42bc (application/x-protobuf, uncompressed)
//   - POST connect-group/v1/refresh-group-data (0x389e83 @ 0xda0740, application/protobuf)
//   - ConnectStateImpl::onCommandResponse ack correlation @ 0xdbea00..0xdbf500
//   - ConnectSetupImpl sliding-window rate limiters @ 0xd8fb94..0xd8fce0
// ============================================================================

#include "ConnectStateClientImpl.h"

#include "../network/NativeLog.h"
#include "dealer/DealerMessageParser.h"
#include "dealer/WsCodec.h"

#include <algorithm>
#include <cstdlib>
#include <utility>

namespace spotify::connectstate {

namespace {

int64_t parse_retry_after_ms(const network::HttpResponse& resp) {
    const std::string hdr = resp.getHeader("Retry-After");
    if (hdr.empty()) {
        return 0;
    }
    char* endptr = nullptr;
    const long long seconds = std::strtoll(hdr.c_str(), &endptr, 10);
    if (endptr != hdr.c_str() && seconds > 0) {
        return static_cast<int64_t>(seconds) * 1000;
    }
    return 0;
}

std::string response_body_text(const network::HttpResponse& resp) {
    if (resp.body.empty()) {
        return {};
    }
    return std::string(reinterpret_cast<const char*>(resp.body.data()), resp.body.size());
}

std::string response_error_text(const network::HttpResponse& resp) {
    std::string body_str = response_body_text(resp);
    if (!body_str.empty()) {
        return body_str;
    }
    if (!resp.transport_ok) {
        return "HTTP transport failure";
    }
    return "HTTP " + std::to_string(resp.status_code);
}

bool is_update_context_command_json(std::string_view command_json) {
    const auto parsed = json::parse_json(command_json);
    if (parsed.has_value() && parsed->is_object()) {
        if (const auto ep = parsed->get_string("endpoint")) {
            return *ep == "update_context";
        }
        if (const json::JsonValue* inner = parsed->find("command");
            inner != nullptr && inner->is_object()) {
            if (const auto ep = inner->get_string("endpoint")) {
                return *ep == "update_context";
            }
        }
    }
    return false;
}

std::string extract_endpoint_for_log(std::string_view command_json) {
    const auto parsed = json::parse_json(command_json);
    if (parsed.has_value() && parsed->is_object()) {
        if (const auto ep = parsed->get_string("endpoint")) {
            return *ep;
        }
        if (const json::JsonValue* inner = parsed->find("command");
            inner != nullptr && inner->is_object()) {
            if (const auto ep = inner->get_string("endpoint")) {
                return *ep;
            }
        }
    }
    return "player_command";
}

}  // namespace

// ============================================================================
// SlidingWindowRateLimiter
// ============================================================================

SlidingWindowRateLimiter::SlidingWindowRateLimiter(
    size_t max_calls,
    int64_t window_ms,
    Clock clock)
    : max_calls_(max_calls),
      window_ms_(window_ms > 0 ? window_ms : 1000),
      clock_(clock ? std::move(clock) : Clock([]() {
          return std::chrono::steady_clock::now();
      })) {}

void SlidingWindowRateLimiter::prune_locked(std::chrono::steady_clock::time_point now_tp) const {
    const auto window = std::chrono::milliseconds(window_ms_);
    while (!timestamps_.empty() && (now_tp - timestamps_.front()) >= window) {
        timestamps_.pop_front();
    }
}

bool SlidingWindowRateLimiter::try_acquire() {
    if (max_calls_ == 0U) {
        return false;
    }
    const auto now_tp = clock_();
    std::lock_guard<std::mutex> lock(mutex_);
    prune_locked(now_tp);
    if (timestamps_.size() >= max_calls_) {
        return false;
    }
    timestamps_.push_back(now_tp);
    return true;
}

size_t SlidingWindowRateLimiter::current_count() const {
    const auto now_tp = clock_();
    std::lock_guard<std::mutex> lock(mutex_);
    prune_locked(now_tp);
    return timestamps_.size();
}

void SlidingWindowRateLimiter::reset() {
    std::lock_guard<std::mutex> lock(mutex_);
    timestamps_.clear();
}

// ============================================================================
// CommandAckTracker
// ============================================================================

CommandAckTracker::CommandAckTracker(Clock clock)
    : clock_(clock ? std::move(clock) : Clock([]() {
          return std::chrono::steady_clock::now();
      })) {}

void CommandAckTracker::set_ack_callback(AckCallback callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    ack_callback_ = std::move(callback);
}

void CommandAckTracker::register_ack(
    std::string ack_id,
    std::string target_device_id,
    std::string command_name,
    uint32_t message_id) {
    if (ack_id.empty()) {
        return;
    }
    const auto now_tp = clock_();
    std::lock_guard<std::mutex> lock(mutex_);
    pending_by_ack_id_[ack_id] = PendingCommandAck{
        .ack_id = ack_id,
        .target_device_id = std::move(target_device_id),
        .command_name = std::move(command_name),
        .message_id = message_id,
        .registered_at = now_tp,
    };
}

bool CommandAckTracker::on_cluster_ack(std::string_view ack_id) {
    if (ack_id.empty()) {
        return false;
    }
    std::optional<PendingCommandAck> matched;
    AckCallback cb;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        const auto it = pending_by_ack_id_.find(std::string(ack_id));
        if (it == pending_by_ack_id_.end()) {
            return false;
        }
        matched = std::move(it->second);
        pending_by_ack_id_.erase(it);
        last_acked_id_ = matched->ack_id;
        cb = ack_callback_;
    }
    CONNECT_LOGD("Correlated Connect command ack_id=%s command=%s target=%s",
                 matched->ack_id.c_str(),
                 matched->command_name.c_str(),
                 matched->target_device_id.c_str());
    if (cb) {
        cb(*matched);
    }
    return true;
}

bool CommandAckTracker::on_command_message_id_ack(
    std::string_view device_id,
    uint32_t message_id) {
    if (message_id == 0U) {
        return false;
    }
    std::optional<PendingCommandAck> matched;
    AckCallback cb;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        for (auto it = pending_by_ack_id_.begin(); it != pending_by_ack_id_.end(); ++it) {
            if (it->second.message_id == message_id &&
                (device_id.empty() || it->second.target_device_id == device_id)) {
                matched = std::move(it->second);
                pending_by_ack_id_.erase(it);
                last_acked_id_ = matched->ack_id;
                cb = ack_callback_;
                break;
            }
        }
    }
    if (matched.has_value() && cb) {
        cb(*matched);
    }
    return matched.has_value();
}

void CommandAckTracker::prune_expired(int64_t max_age_ms) {
    const auto now_tp = clock_();
    const auto max_age = std::chrono::milliseconds(max_age_ms > 0 ? max_age_ms : kDefaultAckTtlMs);
    std::lock_guard<std::mutex> lock(mutex_);
    for (auto it = pending_by_ack_id_.begin(); it != pending_by_ack_id_.end();) {
        if ((now_tp - it->second.registered_at) >= max_age) {
            it = pending_by_ack_id_.erase(it);
        } else {
            ++it;
        }
    }
}

size_t CommandAckTracker::pending_count() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return pending_by_ack_id_.size();
}

std::string CommandAckTracker::last_acked_id() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return last_acked_id_;
}

void CommandAckTracker::reset() {
    std::lock_guard<std::mutex> lock(mutex_);
    pending_by_ack_id_.clear();
    last_acked_id_.clear();
}

// ============================================================================
// ConnectStateClientImpl
// ============================================================================

ConnectStateClientImpl::ConnectStateClientImpl(
    network::NativeHttpClient& http_client,
    std::string spclient_base_url)
    : transport_fn_([&http_client](const HttpRequestSpec& spec) -> network::HttpResponse {
          // Per liborbit WebGate: NEVER send Cookie header on Connect spclient requests.
          network::HttpRequestOptions opts;
          opts.connect_timeout_ms = spec.connect_timeout_ms;
          opts.read_timeout_ms = spec.read_timeout_ms;
          opts.include_spotify_auth = true;
          opts.include_cookie = false;
          if (spec.method == "PUT") {
              return http_client.put(spec.url, spec.body, spec.content_type, spec.headers, opts);
          }
          if (spec.method == "POST") {
              return http_client.post(spec.url, spec.body, spec.content_type, spec.headers, opts);
          }
          if (spec.method == "DELETE") {
              return http_client.del(spec.url, spec.headers, opts);
          }
          return http_client.get(spec.url, spec.headers, opts);
      }),
      spclient_base_url_(
          spclient_base_url.empty() ? std::string(kDefaultSpclientBaseUrl)
                                    : std::move(spclient_base_url)),
      command_rate_limiter_(kMaxCommandsPerWindow, kCommandRateLimiterWindowMs),
      update_context_rate_limiter_(
          kMaxUpdateContextPerWindow, kUpdateContextRateLimiterWindowMs) {}

ConnectStateClientImpl::ConnectStateClientImpl(
    TransportFn transport_fn,
    std::string spclient_base_url)
    : transport_fn_(std::move(transport_fn)),
      spclient_base_url_(
          spclient_base_url.empty() ? std::string(kDefaultSpclientBaseUrl)
                                    : std::move(spclient_base_url)),
      command_rate_limiter_(kMaxCommandsPerWindow, kCommandRateLimiterWindowMs),
      update_context_rate_limiter_(
          kMaxUpdateContextPerWindow, kUpdateContextRateLimiterWindowMs) {}

ConnectStateClientImpl::~ConnectStateClientImpl() {
    shutdown();
}

void ConnectStateClientImpl::start() {
    std::lock_guard<std::mutex> lock(timer_mutex_);
    if (timer_running_) {
        return;
    }
    timer_stop_requested_ = false;
    timer_running_ = true;
    timer_thread_ = std::thread(&ConnectStateClientImpl::timer_loop, this);
}

void ConnectStateClientImpl::shutdown() {
    bool should_join = false;
    {
        std::lock_guard<std::mutex> lock(timer_mutex_);
        if (timer_running_ || timer_thread_.joinable()) {
            timer_stop_requested_ = true;
            should_join = true;
        }
    }
    if (should_join) {
        timer_cv_.notify_all();
        if (timer_thread_.joinable()) {
            timer_thread_.join();
        }
        std::lock_guard<std::mutex> lock(timer_mutex_);
        timer_running_ = false;
        timer_stop_requested_ = false;
    }
    backoff_.reset();
    volume_throttler_.reset();
    ack_tracker_.reset();
    command_rate_limiter_.reset();
    update_context_rate_limiter_.reset();
    {
        std::lock_guard<std::mutex> lock(pending_ctx_mutex_);
        pending_backoff_put_state_ = {};
        pending_volume_put_state_ = {};
        pending_player_put_state_ = {};
        pending_volume_meta_by_key_.clear();
    }
}

void ConnectStateClientImpl::set_spclient_base_url(std::string base_url) {
    if (base_url.empty()) {
        return;
    }
    {
        std::lock_guard<std::mutex> lock(config_mutex_);
        spclient_base_url_ = std::move(base_url);
    }
    CONNECT_LOGI("Connect spclient base URL set to %s",
                 sanitize_url_for_log(spclient_base_url()).c_str());
}

std::string ConnectStateClientImpl::spclient_base_url() const {
    std::lock_guard<std::mutex> lock(config_mutex_);
    return spclient_base_url_;
}

void ConnectStateClientImpl::set_connection_id(std::string connection_id) {
    std::lock_guard<std::mutex> lock(config_mutex_);
    connection_id_ = std::move(connection_id);
}

std::string ConnectStateClientImpl::connection_id() const {
    std::lock_guard<std::mutex> lock(config_mutex_);
    return connection_id_;
}

void ConnectStateClientImpl::set_local_device_id(std::string device_id) {
    std::lock_guard<std::mutex> lock(config_mutex_);
    local_device_id_ = std::move(device_id);
}

std::string ConnectStateClientImpl::local_device_id() const {
    std::lock_guard<std::mutex> lock(config_mutex_);
    return local_device_id_;
}

void ConnectStateClientImpl::set_cluster_callback(ClusterCallback callback) {
    std::lock_guard<std::mutex> lock(callback_mutex_);
    cluster_callback_ = std::move(callback);
}

void ConnectStateClientImpl::set_volume_applied_callback(VolumeAppliedCallback callback) {
    std::lock_guard<std::mutex> lock(callback_mutex_);
    volume_applied_callback_ = std::move(callback);
}

bool ConnectStateClientImpl::on_cluster_ack(std::string_view ack_id) {
    ack_tracker_.prune_expired();
    return ack_tracker_.on_cluster_ack(ack_id);
}

std::string ConnectStateClientImpl::build_url(std::string_view relative_path) const {
    std::string base = spclient_base_url();
    if (base.empty()) {
        base = kDefaultSpclientBaseUrl;
    }
    if (base.back() != '/') {
        base.push_back('/');
    }
    while (!relative_path.empty() && relative_path.front() == '/') {
        relative_path.remove_prefix(1);
    }
    base.append(relative_path);
    return base;
}

bool ConnectStateClientImpl::acquire_connect_headers(
    std::vector<std::pair<std::string, std::string>>& out_headers) const {
    out_headers.clear();
    const std::string cid = connection_id();
    if (cid.empty()) {
        return false;
    }
    out_headers.emplace_back("X-Spotify-Connection-Id", cid);
    return true;
}

network::HttpResponse ConnectStateClientImpl::dispatch_http(
    const HttpRequestSpec& spec) const {
    if (!transport_fn_) {
        return network::HttpResponse{};
    }
    return transport_fn_(spec);
}

void ConnectStateClientImpl::notify_cluster(const Cluster& cluster) {
    ClusterCallback cb;
    {
        std::lock_guard<std::mutex> lock(callback_mutex_);
        cb = cluster_callback_;
    }
    if (cb) {
        cb(cluster);
    }
}

PutStateResult ConnectStateClientImpl::put_state(
    const std::string& device_id,
    const PutStateRequest& request,
    bool wake_devices) {
    if (device_id.empty()) {
        CONNECT_LOGW("put_state rejected: device_id is empty");
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

    if (connection_id().empty()) {
        CONNECT_LOGW("put_state gated (reason=%u): missing X-Spotify-Connection-Id",
                     static_cast<unsigned int>(request.put_state_reason));
        return PutStateResult{
            .ok = false,
            .deferred = false,
            .http_status = 0,
            .grpc_status = {},
            .retry_after_ms = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .error_message = "Missing X-Spotify-Connection-Id",
            .cluster = std::nullopt,
        };
    }

    if (request.put_state_reason == PutStateReason::PLAYER_STATE_CHANGED &&
        backoff_.should_defer_put_state(request.put_state_reason)) {
        {
            std::lock_guard<std::mutex> lock(pending_ctx_mutex_);
            pending_backoff_put_state_ = PendingPutStateMeta{
                .device_id = device_id,
                .request = request,
                .wake_devices = wake_devices,
            };
        }
        backoff_.stash_pending_state(PendingPutState{
            .reason = request.put_state_reason,
            .device = request.device,
            .wake_devices = wake_devices,
            .captured_at = {},
        });
        schedule_timer_wake();
        return PutStateResult{
            .ok = false,
            .deferred = true,
            .http_status = 0,
            .grpc_status = {},
            .retry_after_ms = backoff_.remaining_backoff().count(),
            .error_code = BackoffErrorCode::kPutStateRateLimited,
            .error_message = "PutState deferred during active 10000ms backoff",
            .cluster = std::nullopt,
        };
    }

    if (request.put_state_reason == PutStateReason::VOLUME_CHANGED) {
        const auto decision = volume_throttler_.evaluate_put_state_volume_changed();
        if (decision.action == ThrottleAction::kThrottled) {
            {
                std::lock_guard<std::mutex> lock(pending_ctx_mutex_);
                pending_volume_put_state_ = PendingPutStateMeta{
                    .device_id = device_id,
                    .request = request,
                    .wake_devices = wake_devices,
                };
            }
            schedule_timer_wake();
            return PutStateResult{
                .ok = true,
                .deferred = true,
                .http_status = 0,
                .grpc_status = {},
                .retry_after_ms = decision.retry_after.count(),
                .error_code = BackoffErrorCode::kNone,
                .error_message = {},
                .cluster = std::nullopt,
            };
        }
    } else if (request.put_state_reason == PutStateReason::PLAYER_STATE_CHANGED) {
        const auto decision = volume_throttler_.evaluate_put_state_player_state_changed();
        if (decision.action == ThrottleAction::kThrottled) {
            {
                std::lock_guard<std::mutex> lock(pending_ctx_mutex_);
                pending_player_put_state_ = PendingPutStateMeta{
                    .device_id = device_id,
                    .request = request,
                    .wake_devices = wake_devices,
                };
            }
            schedule_timer_wake();
            return PutStateResult{
                .ok = true,
                .deferred = true,
                .http_status = 0,
                .grpc_status = {},
                .retry_after_ms = decision.retry_after.count(),
                .error_code = BackoffErrorCode::kNone,
                .error_message = {},
                .cluster = std::nullopt,
            };
        }
    }

    return execute_put_state_immediate(device_id, request, wake_devices);
}

PutStateResult ConnectStateClientImpl::execute_put_state_immediate(
    const std::string& device_id,
    const PutStateRequest& request,
    bool wake_devices) {
    std::vector<std::pair<std::string, std::string>> headers;
    if (!acquire_connect_headers(headers)) {
        CONNECT_LOGW("execute_put_state_immediate aborted: missing X-Spotify-Connection-Id");
        return PutStateResult{
            .ok = false,
            .deferred = false,
            .http_status = 0,
            .grpc_status = {},
            .retry_after_ms = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .error_message = "Missing X-Spotify-Connection-Id",
            .cluster = std::nullopt,
        };
    }

    const std::vector<uint8_t> serialized = encode_put_state_request(request);
    auto compressed = gzip_compress(serialized.data(), serialized.size());
    if (!compressed.has_value()) {
        CONNECT_LOGE("Unable to gzip-compress PutStateRequest (%zu bytes)", serialized.size());
        return PutStateResult{
            .ok = false,
            .deferred = false,
            .http_status = 0,
            .grpc_status = {},
            .retry_after_ms = 0,
            .error_code = BackoffErrorCode::kPutStateFailed,
            .error_message = "Unable to compress PutStateRequest",
            .cluster = std::nullopt,
        };
    }

    std::string path = "connect-state/v1/devices/" + device_id;
    // liborbit 0xdc1ba0..0xdc1be0: append ?wake-devices=true|false strictly on PICKER_OPENED (6).
    if (request.put_state_reason == PutStateReason::PICKER_OPENED) {
        path.append(wake_devices ? "?wake-devices=true" : "?wake-devices=false");
    }

    headers.emplace_back("Content-Encoding", "gzip");

    HttpRequestSpec spec{
        .method = "PUT",
        .url = build_url(path),
        .body = std::move(*compressed),
        .content_type = "application/protobuf",
        .headers = std::move(headers),
        .connect_timeout_ms = 8000,
        .read_timeout_ms = 15000,
    };

    const std::string safe_url = sanitize_url_for_log(spec.url);
    const network::HttpResponse resp = dispatch_http(spec);
    if (!resp.transport_ok && resp.status_code == 0) {
        CONNECT_LOGW("PutState transport failure: reason=%u url=%s",
                     static_cast<unsigned int>(request.put_state_reason),
                     safe_url.c_str());
        return PutStateResult{
            .ok = false,
            .deferred = false,
            .http_status = 0,
            .grpc_status = {},
            .retry_after_ms = 0,
            .error_code = BackoffErrorCode::kSystemError,
            .error_message = response_error_text(resp),
            .cluster = std::nullopt,
        };
    }

    const std::string grpc_status = resp.getHeader("grpc-status");
    const int64_t retry_after_ms = parse_retry_after_ms(resp);

    const BackoffEvaluation eval = backoff_.on_put_state_response(
        request.put_state_reason,
        resp.status_code,
        grpc_status);
    if (eval.triggered) {
        CONNECT_LOGW("PutState rate-limited (status=%d, grpc=%s); arming 10000ms backoff",
                     resp.status_code,
                     grpc_status.c_str());
        {
            std::lock_guard<std::mutex> lock(pending_ctx_mutex_);
            pending_backoff_put_state_ = PendingPutStateMeta{
                .device_id = device_id,
                .request = request,
                .wake_devices = wake_devices,
            };
        }
        backoff_.stash_pending_state(PendingPutState{
            .reason = request.put_state_reason,
            .device = request.device,
            .wake_devices = wake_devices,
            .captured_at = {},
        });
        schedule_timer_wake();
        return PutStateResult{
            .ok = false,
            .deferred = false,
            .http_status = resp.status_code,
            .grpc_status = grpc_status,
            .retry_after_ms = retry_after_ms > 0 ? retry_after_ms : eval.delay.count(),
            .error_code = eval.error_code,
            .error_message = "PutState rate-limited; armed 10000ms backoff",
            .cluster = std::nullopt,
        };
    }

    if (!resp.isSuccess() || eval.error_code != BackoffErrorCode::kNone) {
        std::string error_msg = response_body_text(resp);
        if (error_msg.empty()) {
            if (!resp.transport_ok) {
                error_msg = "HTTP transport failure";
            } else if (resp.isSuccess()) {
                error_msg = !grpc_status.empty()
                                ? ("gRPC status " + grpc_status)
                                : ("PutState failed (error_code=" +
                                   std::to_string(static_cast<int32_t>(eval.error_code)) + ")");
            } else {
                error_msg = "HTTP " + std::to_string(resp.status_code);
            }
        }
        CONNECT_LOGW("PutState failed: reason=%u status=%d grpc='%s' url=%s err='%s'",
                     static_cast<unsigned int>(request.put_state_reason),
                     resp.status_code,
                     grpc_status.c_str(),
                     safe_url.c_str(),
                     error_msg.c_str());
        return PutStateResult{
            .ok = false,
            .deferred = false,
            .http_status = resp.status_code,
            .grpc_status = grpc_status,
            .retry_after_ms = retry_after_ms,
            .error_code = eval.error_code != BackoffErrorCode::kNone
                              ? eval.error_code
                              : (!resp.transport_ok
                                     ? BackoffErrorCode::kSystemError
                                     : BackoffErrorCode::kPutStateFailed),
            .error_message = std::move(error_msg),
            .cluster = std::nullopt,
        };
    }

    std::optional<Cluster> decoded_cluster;
    if (!resp.body.empty()) {
        Cluster cluster;
        if (!decode_cluster(resp.body.data(), resp.body.size(), cluster)) {
            CONNECT_LOGE("PutState cluster protobuf decode failed (%zu bytes)", resp.body.size());
            return PutStateResult{
                .ok = false,
                .deferred = false,
                .http_status = resp.status_code,
                .grpc_status = grpc_status,
                .retry_after_ms = 0,
                .error_code = BackoffErrorCode::kPutStateCanceled,
                .error_message = "Could not parse protobuf cluster",
                .cluster = std::nullopt,
            };
        }
        CONNECT_LOGI("PutState succeeded: reason=%u status=%d devices=%zu active=%s",
                     static_cast<unsigned int>(request.put_state_reason),
                     resp.status_code,
                     cluster.devices.size(),
                     cluster.active_device_id.c_str());
        decoded_cluster = std::move(cluster);
        notify_cluster(*decoded_cluster);
    } else {
        CONNECT_LOGD("PutState succeeded with empty body: reason=%u status=%d",
                     static_cast<unsigned int>(request.put_state_reason),
                     resp.status_code);
    }

    return PutStateResult{
        .ok = true,
        .deferred = false,
        .http_status = resp.status_code,
        .grpc_status = grpc_status,
        .retry_after_ms = 0,
        .error_code = BackoffErrorCode::kNone,
        .error_message = {},
        .cluster = std::move(decoded_cluster),
    };
}

AckHttpResult ConnectStateClientImpl::rename(
    const std::string& from_device_id,
    const std::string& to_device_id,
    const RenameCommand& command) {
    std::vector<std::pair<std::string, std::string>> headers;
    if (!acquire_connect_headers(headers)) {
        CONNECT_LOGW("rename gated: missing X-Spotify-Connection-Id");
        return AckHttpResult{
            .ok = false,
            .throttled = false,
            .http_status = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .ack_id = {},
            .error_message = "Missing X-Spotify-Connection-Id",
        };
    }

    HttpRequestSpec spec{
        .method = "PUT",
        .url = build_url(
            "connect-state/v1/connect/rename/from/" + from_device_id + "/to/" + to_device_id),
        .body = encode_rename_command(command),
        .content_type = "application/protobuf",
        .headers = std::move(headers),
        .connect_timeout_ms = 8000,
        .read_timeout_ms = 15000,
    };
    const network::HttpResponse resp = dispatch_http(spec);
    if (!resp.isSuccess()) {
        const std::string err = response_error_text(resp);
        CONNECT_LOGW("rename failed: target=%s status=%d err='%s'",
                     to_device_id.c_str(),
                     resp.status_code,
                     err.c_str());
        return AckHttpResult{
            .ok = false,
            .throttled = false,
            .http_status = resp.status_code,
            .error_code = BackoffErrorCode::kPutStateFailed,
            .ack_id = {},
            .error_message = err,
        };
    }
    const std::string ack = parse_ack_id(response_body_text(resp));
    ack_tracker_.register_ack(
        ack, to_device_id, "rename", static_cast<uint32_t>(command.command_options.message_id));
    return AckHttpResult{
        .ok = true,
        .throttled = false,
        .http_status = resp.status_code,
        .error_code = BackoffErrorCode::kNone,
        .ack_id = ack,
        .error_message = {},
    };
}

SimpleHttpResult ConnectStateClientImpl::logout(
    const std::string& from_device_id,
    const std::string& to_device_id,
    const LogoutCommand& command) {
    std::vector<std::pair<std::string, std::string>> headers;
    if (!acquire_connect_headers(headers)) {
        CONNECT_LOGW("logout gated: missing X-Spotify-Connection-Id");
        return SimpleHttpResult{
            .ok = false,
            .http_status = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .error_message = "Missing X-Spotify-Connection-Id",
        };
    }

    HttpRequestSpec spec{
        .method = "POST",
        .url = build_url(
            "connect-state/v1/connect/logout/from/" + from_device_id + "/to/" + to_device_id),
        .body = encode_logout_command(command),
        .content_type = "application/protobuf",
        .headers = std::move(headers),
        .connect_timeout_ms = 8000,
        .read_timeout_ms = 15000,
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    if (!ok) {
        CONNECT_LOGW("logout failed: target=%s status=%d", to_device_id.c_str(), resp.status_code);
    }
    return SimpleHttpResult{
        .ok = ok,
        .http_status = resp.status_code,
        .error_code = ok ? BackoffErrorCode::kNone : BackoffErrorCode::kPutStateFailed,
        .error_message = ok ? std::string{} : response_error_text(resp),
    };
}

std::string ConnectStateClientImpl::build_player_command_json(
    std::string_view command_json,
    std::string_view connection_type,
    std::string_view intent_id) {
    std::string payload;
    payload.reserve(command_json.size() + connection_type.size() + intent_id.size() + 64);
    payload.append("{\"command\":");
    payload.append(command_json.empty() ? "{}" : command_json);
    payload.append(",\"connection_type\":\"");
    payload.append(json::json_escape(connection_type));
    payload.append("\",\"intent_id\":\"");
    payload.append(json::json_escape(intent_id));
    payload.append("\"}");
    return payload;
}

AckHttpResult ConnectStateClientImpl::send_player_command(
    const std::string& from_device_id,
    const std::string& to_device_id,
    std::string_view command_json,
    std::string_view connection_type,
    std::string_view intent_id,
    bool gzip_body) {
    std::vector<std::pair<std::string, std::string>> headers;
    if (!acquire_connect_headers(headers)) {
        CONNECT_LOGW("send_player_command gated: missing X-Spotify-Connection-Id");
        return AckHttpResult{
            .ok = false,
            .throttled = false,
            .http_status = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .ack_id = {},
            .error_message = "Missing X-Spotify-Connection-Id",
        };
    }

    const bool is_update_context = is_update_context_command_json(command_json);
    if (is_update_context && !update_context_rate_limiter_.try_acquire()) {
        CONNECT_LOGW("send_player_command rate-limited: update_context exceeded %zu/%lldms",
                     kMaxUpdateContextPerWindow,
                     static_cast<long long>(kUpdateContextRateLimiterWindowMs));
        return AckHttpResult{
            .ok = false,
            .throttled = true,
            .http_status = 429,
            .error_code = BackoffErrorCode::kPutStateRateLimited,
            .ack_id = {},
            .error_message = "update_context command rate limit exceeded",
        };
    }
    if (!command_rate_limiter_.try_acquire()) {
        CONNECT_LOGW("send_player_command rate-limited: exceeded %zu/%lldms",
                     kMaxCommandsPerWindow,
                     static_cast<long long>(kCommandRateLimiterWindowMs));
        return AckHttpResult{
            .ok = false,
            .throttled = true,
            .http_status = 429,
            .error_code = BackoffErrorCode::kPutStateRateLimited,
            .ack_id = {},
            .error_message = "Outbound Connect command rate limit exceeded",
        };
    }

    const std::string json_body =
        build_player_command_json(command_json, connection_type, intent_id);
    std::vector<uint8_t> body(json_body.begin(), json_body.end());

    if (gzip_body) {
        auto gz = gzip_compress(body.data(), body.size());
        if (gz.has_value()) {
            body = std::move(*gz);
            headers.emplace_back("Content-Encoding", "gzip");
        }
    }

    HttpRequestSpec spec{
        .method = "POST",
        .url = build_url(
            "connect-state/v1/player/command/from/" + from_device_id + "/to/" + to_device_id),
        .body = std::move(body),
        .content_type = "application/json",
        .headers = std::move(headers),
        .connect_timeout_ms = 8000,
        .read_timeout_ms = 15000,
    };
    const std::string endpoint_name = extract_endpoint_for_log(command_json);
    const network::HttpResponse resp = dispatch_http(spec);
    if (!resp.isSuccess()) {
        const std::string err = response_error_text(resp);
        CONNECT_LOGW("send_player_command failed: ep=%s target=%s status=%d err='%s'",
                     endpoint_name.c_str(),
                     to_device_id.c_str(),
                     resp.status_code,
                     err.c_str());
        return AckHttpResult{
            .ok = false,
            .throttled = false,
            .http_status = resp.status_code,
            .error_code = BackoffErrorCode::kPutStateFailed,
            .ack_id = {},
            .error_message = err,
        };
    }
    const std::string ack = parse_ack_id(response_body_text(resp));
    ack_tracker_.register_ack(ack, to_device_id, endpoint_name);
    CONNECT_LOGD("send_player_command ok: ep=%s target=%s status=%d ack=%s",
                 endpoint_name.c_str(),
                 to_device_id.c_str(),
                 resp.status_code,
                 ack.c_str());
    return AckHttpResult{
        .ok = true,
        .throttled = false,
        .http_status = resp.status_code,
        .error_code = BackoffErrorCode::kNone,
        .ack_id = ack,
        .error_message = {},
    };
}

std::string ConnectStateClientImpl::build_transfer_json(
    const TransferHttpRequest& request) {
    std::string out = "{\"options\":{";
    out.append("\"extrapolate\":");
    out.append(request.options.extrapolate ? "true" : "false");
    out.append(",\"last_known\":");
    out.append(request.options.last_known ? "true" : "false");
    out.append(",\"only_current\":");
    out.append(request.options.only_current ? "true" : "false");
    out.append(",\"always_play_something\":");
    out.append(request.options.always_play_something ? "true" : "false");
    out.push_back('}');

    if (!request.transfer_intent_id.empty()) {
        out.append(",\"transfer_intent_id\":\"");
        out.append(json::json_escape(request.transfer_intent_id));
        out.push_back('"');
    }
    if (!request.command_id.empty()) {
        out.append(",\"command_id\":\"");
        out.append(json::json_escape(request.command_id));
        out.push_back('"');
    }
    if (request.without_active_device) {
        out.append(",\"without_active_device\":true");
    }
    if (!request.target_alias_id.empty()) {
        out.append(",\"target_alias_id\":\"");
        out.append(json::json_escape(request.target_alias_id));
        out.push_back('"');
    }
    if (!request.dodo.empty()) {
        out.append(",\"dodo\":\"");
        out.append(json::json_escape(request.dodo));
        out.push_back('"');
    }
    out.push_back('}');
    return out;
}

void ConnectStateClientImpl::parse_transfer_error_json(
    std::string_view response_body,
    std::string& out_error_description,
    std::vector<std::string>& out_reasons) {
    out_error_description.clear();
    out_reasons.clear();
    auto parsed = json::parse_json(response_body);
    if (!parsed.has_value() || !parsed->is_object()) {
        return;
    }
    if (auto desc = parsed->get_string("error_description")) {
        out_error_description = std::move(*desc);
    }
    if (const json::JsonValue* reasons = parsed->find("reasons");
        reasons != nullptr && reasons->is_array()) {
        for (const auto& r : reasons->array_value) {
            if (r.is_string()) {
                out_reasons.push_back(r.string_value);
            }
        }
    }
}

TransferHttpResult ConnectStateClientImpl::transfer(const TransferHttpRequest& request) {
    std::vector<std::pair<std::string, std::string>> headers;
    if (!acquire_connect_headers(headers)) {
        CONNECT_LOGW("transfer gated: missing X-Spotify-Connection-Id");
        return TransferHttpResult{
            .ok = false,
            .http_status = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .ack_id = {},
            .error_description = "Missing X-Spotify-Connection-Id",
            .reasons = {"missing_connection_id"},
        };
    }

    const std::string body_str = build_transfer_json(request);
    HttpRequestSpec spec{
        .method = "POST",
        .url = build_url(
            "connect-state/v1/connect/transfer/from/" + request.from_device_id +
            "/to/" + request.to_device_id),
        .body = std::vector<uint8_t>(body_str.begin(), body_str.end()),
        .content_type = "application/json",
        .headers = std::move(headers),
        .connect_timeout_ms = 8000,
        .read_timeout_ms = 15000,
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const std::string resp_text = response_body_text(resp);
    if (!resp.isSuccess()) {
        std::string err_desc;
        std::vector<std::string> reasons;
        parse_transfer_error_json(resp_text, err_desc, reasons);
        if (err_desc.empty()) {
            err_desc = response_error_text(resp);
        }
        CONNECT_LOGW("transfer failed: from=%s to=%s status=%d err='%s'",
                     request.from_device_id.c_str(),
                     request.to_device_id.c_str(),
                     resp.status_code,
                     err_desc.c_str());
        return TransferHttpResult{
            .ok = false,
            .http_status = resp.status_code,
            .error_code = BackoffErrorCode::kPutStateFailed,
            .ack_id = {},
            .error_description = std::move(err_desc),
            .reasons = std::move(reasons),
        };
    }
    const std::string ack = parse_ack_id(resp_text);
    ack_tracker_.register_ack(ack, request.to_device_id, "transfer");
    CONNECT_LOGI("transfer accepted: from=%s to=%s status=%d ack=%s",
                 request.from_device_id.c_str(),
                 request.to_device_id.c_str(),
                 resp.status_code,
                 ack.c_str());
    return TransferHttpResult{
        .ok = true,
        .http_status = resp.status_code,
        .error_code = BackoffErrorCode::kNone,
        .ack_id = ack,
        .error_description = {},
        .reasons = {},
    };
}

AckHttpResult ConnectStateClientImpl::set_volume(
    const std::string& from_device_id,
    const std::string& to_device_id,
    uint32_t volume,
    const std::string& group_device_id,
    const std::string& group_instance) {
    if (connection_id().empty()) {
        CONNECT_LOGW("set_volume gated: missing X-Spotify-Connection-Id");
        return AckHttpResult{
            .ok = false,
            .throttled = false,
            .http_status = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .ack_id = {},
            .error_message = "Missing X-Spotify-Connection-Id",
        };
    }

    const std::string target_key = group_device_id;
    const auto decision =
        volume_throttler_.submit_volume_command(volume, to_device_id, target_key);
    if (decision.action == ThrottleAction::kThrottled) {
        {
            std::lock_guard<std::mutex> lock(pending_ctx_mutex_);
            pending_volume_meta_by_key_[target_key] = PendingVolumeMeta{
                .from_device_id = from_device_id,
                .group_device_id = group_device_id,
                .group_instance = group_instance,
            };
        }
        schedule_timer_wake();
        return AckHttpResult{
            .ok = true,
            .throttled = true,
            .http_status = 0,
            .error_code = BackoffErrorCode::kNone,
            .ack_id = {},
            .error_message = {},
        };
    }

    return execute_set_volume_immediate(
        from_device_id, to_device_id, volume, group_device_id, group_instance);
}

AckHttpResult ConnectStateClientImpl::execute_set_volume_immediate(
    const std::string& from_device_id,
    const std::string& to_device_id,
    uint32_t volume,
    const std::string& group_device_id,
    const std::string& group_instance) {
    std::vector<std::pair<std::string, std::string>> headers;
    if (!acquire_connect_headers(headers)) {
        CONNECT_LOGW("execute_set_volume_immediate aborted: missing X-Spotify-Connection-Id");
        return AckHttpResult{
            .ok = false,
            .throttled = false,
            .http_status = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .ack_id = {},
            .error_message = "Missing X-Spotify-Connection-Id",
        };
    }

    SetVolumeCommand cmd;
    cmd.volume = static_cast<int32_t>(volume);
    cmd.has_volume = true;
    cmd.sent_by_device_id = from_device_id;
    cmd.group_device_identifier = group_device_id;
    cmd.group_instance = group_instance;

    HttpRequestSpec spec{
        .method = "PUT",
        .url = build_url(
            "connect-state/v1/connect/volume/from/" + from_device_id + "/to/" + to_device_id),
        .body = encode_set_volume_command(cmd),
        .content_type = "application/protobuf",
        .headers = std::move(headers),
        .connect_timeout_ms = 8000,
        .read_timeout_ms = 15000,
    };
    const network::HttpResponse resp = dispatch_http(spec);
    if (!resp.isSuccess()) {
        const std::string err = response_error_text(resp);
        CONNECT_LOGW("set_volume failed: target=%s group_dev=%s vol=%u status=%d err='%s'",
                     to_device_id.c_str(),
                     group_device_id.c_str(),
                     volume,
                     resp.status_code,
                     err.c_str());
        return AckHttpResult{
            .ok = false,
            .throttled = false,
            .http_status = resp.status_code,
            .error_code = BackoffErrorCode::kPutStateFailed,
            .ack_id = {},
            .error_message = err,
        };
    }
    const std::string ack = parse_ack_id(response_body_text(resp));
    ack_tracker_.register_ack(ack, to_device_id, "set_volume");
    return AckHttpResult{
        .ok = true,
        .throttled = false,
        .http_status = resp.status_code,
        .error_code = BackoffErrorCode::kNone,
        .ack_id = ack,
        .error_message = {},
    };
}

AckHttpResult ConnectStateClientImpl::add_device_to_group(
    const std::string& from_device_id,
    const std::string& to_device_id,
    const AddDeviceToGroupCommand& command) {
    std::vector<std::pair<std::string, std::string>> headers;
    if (!acquire_connect_headers(headers)) {
        CONNECT_LOGW("add_device_to_group gated: missing X-Spotify-Connection-Id");
        return AckHttpResult{
            .ok = false,
            .throttled = false,
            .http_status = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .ack_id = {},
            .error_message = "Missing X-Spotify-Connection-Id",
        };
    }

    HttpRequestSpec spec{
        .method = "PUT",
        .url = build_url(
            "connect-state/v1/connect/group/add-device/from/" + from_device_id +
            "/to/" + to_device_id),
        .body = encode_add_device_to_group_command(command),
        .content_type = "application/protobuf",
        .headers = std::move(headers),
        .connect_timeout_ms = 8000,
        .read_timeout_ms = 15000,
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    const std::string ack = ok ? parse_ack_id(response_body_text(resp)) : std::string{};
    if (ok) {
        ack_tracker_.register_ack(ack, to_device_id, "add_device_to_group");
    } else {
        CONNECT_LOGW("add_device_to_group failed: target=%s status=%d",
                     to_device_id.c_str(),
                     resp.status_code);
    }
    return AckHttpResult{
        .ok = ok,
        .throttled = false,
        .http_status = resp.status_code,
        .error_code = ok ? BackoffErrorCode::kNone : BackoffErrorCode::kPutStateFailed,
        .ack_id = ack,
        .error_message = ok ? std::string{} : response_error_text(resp),
    };
}

AckHttpResult ConnectStateClientImpl::remove_device_from_group(
    const std::string& from_device_id,
    const std::string& to_device_id,
    const RemoveDeviceFromGroupCommand& command) {
    std::vector<std::pair<std::string, std::string>> headers;
    if (!acquire_connect_headers(headers)) {
        CONNECT_LOGW("remove_device_from_group gated: missing X-Spotify-Connection-Id");
        return AckHttpResult{
            .ok = false,
            .throttled = false,
            .http_status = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .ack_id = {},
            .error_message = "Missing X-Spotify-Connection-Id",
        };
    }

    HttpRequestSpec spec{
        .method = "PUT",
        .url = build_url(
            "connect-state/v1/connect/group/remove-device/from/" + from_device_id +
            "/to/" + to_device_id),
        .body = encode_remove_device_from_group_command(command),
        .content_type = "application/protobuf",
        .headers = std::move(headers),
        .connect_timeout_ms = 8000,
        .read_timeout_ms = 15000,
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    const std::string ack = ok ? parse_ack_id(response_body_text(resp)) : std::string{};
    if (ok) {
        ack_tracker_.register_ack(ack, to_device_id, "remove_device_from_group");
    } else {
        CONNECT_LOGW("remove_device_from_group failed: target=%s status=%d",
                     to_device_id.c_str(),
                     resp.status_code);
    }
    return AckHttpResult{
        .ok = ok,
        .throttled = false,
        .http_status = resp.status_code,
        .error_code = ok ? BackoffErrorCode::kNone : BackoffErrorCode::kPutStateFailed,
        .ack_id = ack,
        .error_message = ok ? std::string{} : response_error_text(resp),
    };
}

AckHttpResult ConnectStateClientImpl::delete_group(
    const std::string& from_device_id,
    const std::string& to_device_id,
    const DeleteGroupCommand& command) {
    std::vector<std::pair<std::string, std::string>> headers;
    if (!acquire_connect_headers(headers)) {
        CONNECT_LOGW("delete_group gated: missing X-Spotify-Connection-Id");
        return AckHttpResult{
            .ok = false,
            .throttled = false,
            .http_status = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .ack_id = {},
            .error_message = "Missing X-Spotify-Connection-Id",
        };
    }

    HttpRequestSpec spec{
        .method = "POST",
        .url = build_url(
            "connect-state/v1/connect/group/delete/from/" + from_device_id +
            "/to/" + to_device_id),
        .body = encode_delete_group_command(command),
        .content_type = "application/protobuf",
        .headers = std::move(headers),
        .connect_timeout_ms = 8000,
        .read_timeout_ms = 15000,
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    const std::string ack = ok ? parse_ack_id(response_body_text(resp)) : std::string{};
    if (ok) {
        ack_tracker_.register_ack(ack, to_device_id, "delete_group");
    } else {
        CONNECT_LOGW("delete_group failed: target=%s status=%d",
                     to_device_id.c_str(),
                     resp.status_code);
    }
    return AckHttpResult{
        .ok = ok,
        .throttled = false,
        .http_status = resp.status_code,
        .error_code = ok ? BackoffErrorCode::kNone : BackoffErrorCode::kPutStateFailed,
        .ack_id = ack,
        .error_message = ok ? std::string{} : response_error_text(resp),
    };
}

SimpleHttpResult ConnectStateClientImpl::send_set_device_inactive(
    const std::string& device_id,
    const SetDeviceInactiveRequest& request,
    int read_timeout_ms) {
    std::vector<std::pair<std::string, std::string>> headers;
    if (!acquire_connect_headers(headers)) {
        CONNECT_LOGW("send_set_device_inactive gated: missing X-Spotify-Connection-Id");
        return SimpleHttpResult{
            .ok = false,
            .http_status = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .error_message = "Missing X-Spotify-Connection-Id",
        };
    }

    const int bounded_read_ms = read_timeout_ms > 0 ? read_timeout_ms : 15000;
    HttpRequestSpec spec{
        .method = "PUT",
        .url = build_url("connect-state/v1/devices/" + device_id + "/inactive"),
        .body = encode_set_device_inactive_request(request),
        .content_type = "application/protobuf",
        .headers = std::move(headers),
        .connect_timeout_ms = std::min(bounded_read_ms, 8000),
        .read_timeout_ms = bounded_read_ms,
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    if (!ok) {
        CONNECT_LOGW("send_set_device_inactive failed: device=%s status=%d",
                     device_id.c_str(),
                     resp.status_code);
    }
    return SimpleHttpResult{
        .ok = ok,
        .http_status = resp.status_code,
        .error_code = ok ? BackoffErrorCode::kNone : BackoffErrorCode::kPutStateFailed,
        .error_message = ok ? std::string{} : response_error_text(resp),
    };
}

ClusterHttpResult ConnectStateClientImpl::set_dodo(const SetDoDoRequest& request) {
    std::vector<std::pair<std::string, std::string>> headers;
    if (!acquire_connect_headers(headers)) {
        CONNECT_LOGW("set_dodo gated: missing X-Spotify-Connection-Id");
        return ClusterHttpResult{
            .ok = false,
            .http_status = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .error_message = "Missing X-Spotify-Connection-Id",
            .cluster = std::nullopt,
        };
    }

    HttpRequestSpec spec{
        .method = "POST",
        .url = build_url("connect-state/connectstate.ConnectStateService/SetDoDo"),
        .body = encode_set_dodo_request(request),
        .content_type = "application/x-protobuf",
        .headers = std::move(headers),
        .connect_timeout_ms = 8000,
        .read_timeout_ms = 15000,
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    std::optional<Cluster> decoded_cluster;
    if (ok && !resp.body.empty()) {
        Cluster cluster;
        if (decode_cluster(resp.body.data(), resp.body.size(), cluster)) {
            decoded_cluster = std::move(cluster);
            notify_cluster(*decoded_cluster);
        } else {
            CONNECT_LOGW("set_dodo returned malformed Cluster protobuf (%zu bytes)",
                         resp.body.size());
        }
    } else if (!ok) {
        CONNECT_LOGW("set_dodo failed: status=%d", resp.status_code);
    }
    return ClusterHttpResult{
        .ok = ok,
        .http_status = resp.status_code,
        .error_code = ok ? BackoffErrorCode::kNone : BackoffErrorCode::kPutStateFailed,
        .error_message = ok ? std::string{} : response_error_text(resp),
        .cluster = std::move(decoded_cluster),
    };
}

SimpleHttpResult ConnectStateClientImpl::wake_up_sleeping_cluster() {
    std::vector<std::pair<std::string, std::string>> headers;
    if (!acquire_connect_headers(headers)) {
        CONNECT_LOGW("wake_up_sleeping_cluster gated: missing X-Spotify-Connection-Id");
        return SimpleHttpResult{
            .ok = false,
            .http_status = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .error_message = "Missing X-Spotify-Connection-Id",
        };
    }

    HttpRequestSpec spec{
        .method = "POST",
        .url = build_url("connect-state/v1/cluster/wake-devices"),
        .body = {},
        .content_type = "application/json",
        .headers = std::move(headers),
        .connect_timeout_ms = 8000,
        .read_timeout_ms = 15000,
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    if (!ok) {
        CONNECT_LOGW("wake_up_sleeping_cluster failed: status=%d", resp.status_code);
    }
    return SimpleHttpResult{
        .ok = ok,
        .http_status = resp.status_code,
        .error_code = ok ? BackoffErrorCode::kNone : BackoffErrorCode::kPutStateFailed,
        .error_message = ok ? std::string{} : response_error_text(resp),
    };
}

SimpleHttpResult ConnectStateClientImpl::delete_device(const std::string& device_id) {
    std::vector<std::pair<std::string, std::string>> headers;
    if (!acquire_connect_headers(headers)) {
        CONNECT_LOGW("delete_device gated: missing X-Spotify-Connection-Id");
        return SimpleHttpResult{
            .ok = false,
            .http_status = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .error_message = "Missing X-Spotify-Connection-Id",
        };
    }

    HttpRequestSpec spec{
        .method = "DELETE",
        .url = build_url("connect-state/v1/devices/" + device_id),
        .body = {},
        .content_type = {},
        .headers = std::move(headers),
        .connect_timeout_ms = 8000,
        .read_timeout_ms = 15000,
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    if (!ok) {
        CONNECT_LOGW("delete_device failed: device=%s status=%d",
                     device_id.c_str(),
                     resp.status_code);
    }
    return SimpleHttpResult{
        .ok = ok,
        .http_status = resp.status_code,
        .error_code = ok ? BackoffErrorCode::kNone : BackoffErrorCode::kPutStateFailed,
        .error_message = ok ? std::string{} : response_error_text(resp),
    };
}

SimpleHttpResult ConnectStateClientImpl::update_local_devices(
    const UpdateLocalDevicesRequest& request) {
    std::vector<std::pair<std::string, std::string>> headers;
    if (!acquire_connect_headers(headers)) {
        CONNECT_LOGW("update_local_devices gated: missing X-Spotify-Connection-Id");
        return SimpleHttpResult{
            .ok = false,
            .http_status = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .error_message = "Missing X-Spotify-Connection-Id",
        };
    }

    // Per liborbit @ 0xdc3bc4: Content-Type application/x-protobuf, uncompressed.
    HttpRequestSpec spec{
        .method = "PUT",
        .url = build_url("connect-state/v1/update_local_devices"),
        .body = encode_update_local_devices_request(request),
        .content_type = "application/x-protobuf",
        .headers = std::move(headers),
        .connect_timeout_ms = 8000,
        .read_timeout_ms = 15000,
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    if (!ok) {
        CONNECT_LOGW("update_local_devices failed: count=%zu status=%d",
                     request.local_devices.size(),
                     resp.status_code);
    } else {
        CONNECT_LOGI("update_local_devices ok: reported=%zu status=%d",
                     request.local_devices.size(),
                     resp.status_code);
    }
    return SimpleHttpResult{
        .ok = ok,
        .http_status = resp.status_code,
        .error_code = ok ? BackoffErrorCode::kNone : BackoffErrorCode::kPutStateFailed,
        .error_message = ok ? std::string{} : response_error_text(resp),
    };
}

GroupDataHttpResult ConnectStateClientImpl::refresh_group_data(
    const RefreshGroupDataRequest& request) {
    std::vector<std::pair<std::string, std::string>> headers;
    if (!acquire_connect_headers(headers)) {
        CONNECT_LOGW("refresh_group_data gated: missing X-Spotify-Connection-Id");
        return GroupDataHttpResult{
            .ok = false,
            .http_status = 0,
            .error_code = BackoffErrorCode::kMissingConnectionId,
            .error_message = "Missing X-Spotify-Connection-Id",
            .response = std::nullopt,
        };
    }

    // Per liborbit 0x389e83 @ 0xda0740..0xda0780: Content-Type application/protobuf.
    HttpRequestSpec spec{
        .method = "POST",
        .url = build_url("connect-group/v1/refresh-group-data"),
        .body = encode_refresh_group_data_request(request),
        .content_type = "application/protobuf",
        .headers = std::move(headers),
        .connect_timeout_ms = 8000,
        .read_timeout_ms = 15000,
    };
    const network::HttpResponse resp = dispatch_http(spec);
    if (!resp.isSuccess()) {
        const std::string err = response_error_text(resp);
        CONNECT_LOGW("refresh_group_data failed: status=%d err='%s'",
                     resp.status_code,
                     err.c_str());
        return GroupDataHttpResult{
            .ok = false,
            .http_status = resp.status_code,
            .error_code = BackoffErrorCode::kPutStateFailed,
            .error_message = err,
            .response = std::nullopt,
        };
    }

    GetAllGroupDataResponse parsed;
    if (!resp.body.empty() &&
        !decode_get_all_group_data_response(resp.body.data(), resp.body.size(), parsed)) {
        CONNECT_LOGE("refresh_group_data decode failed (%zu bytes)", resp.body.size());
        return GroupDataHttpResult{
            .ok = false,
            .http_status = resp.status_code,
            .error_code = BackoffErrorCode::kPutStateCanceled,
            .error_message = "Could not decode GetAllGroupDataResponse",
            .response = std::nullopt,
        };
    }

    CONNECT_LOGD("refresh_group_data ok: groups=%zu volumes=%zu",
                 parsed.group_data.size(),
                 parsed.group_device_volumes.size());
    return GroupDataHttpResult{
        .ok = true,
        .http_status = resp.status_code,
        .error_code = BackoffErrorCode::kNone,
        .error_message = {},
        .response = std::move(parsed),
    };
}

std::string ConnectStateClientImpl::parse_ack_id(std::string_view response_body) {
    auto parsed = json::parse_json(response_body);
    if (!parsed.has_value() || !parsed->is_object()) {
        return {};
    }
    return parsed->get_string("ack_id").value_or(std::string{});
}

void ConnectStateClientImpl::schedule_timer_wake() {
    {
        std::lock_guard<std::mutex> lock(timer_mutex_);
        ++timer_wake_epoch_;
    }
    timer_cv_.notify_all();
}

void ConnectStateClientImpl::timer_loop() {
    while (true) {
        std::optional<PendingPutState> due_backoff_state;
        PendingPutStateMeta due_backoff_meta;

        if (auto pending = backoff_.take_pending_if_ready()) {
            {
                std::lock_guard<std::mutex> lock(pending_ctx_mutex_);
                due_backoff_meta = std::move(pending_backoff_put_state_);
                pending_backoff_put_state_ = {};
            }
            due_backoff_meta.request.put_state_reason = pending->reason;
            due_backoff_meta.request.device = std::move(pending->device);
            due_backoff_meta.wake_devices = pending->wake_devices;
            due_backoff_state = std::move(*pending);
        }

        if (due_backoff_state.has_value() && !due_backoff_meta.device_id.empty()) {
            const PutStateResult replay_res = execute_put_state_immediate(
                due_backoff_meta.device_id,
                due_backoff_meta.request,
                due_backoff_meta.wake_devices);
            if (!replay_res.ok) {
                CONNECT_LOGW("Backoff PutState replay failed: status=%d err='%s'",
                             replay_res.http_status,
                             replay_res.error_message.c_str());
            }
        }

        const auto ready_volumes = volume_throttler_.take_all_pending_volumes_if_ready();
        for (const auto& pending_vol : ready_volumes) {
            PendingVolumeMeta meta;
            {
                std::lock_guard<std::mutex> lock(pending_ctx_mutex_);
                const auto it = pending_volume_meta_by_key_.find(pending_vol.target_key);
                if (it != pending_volume_meta_by_key_.end()) {
                    meta = it->second;
                }
            }
            if (!meta.from_device_id.empty()) {
                const AckHttpResult vol_res = execute_set_volume_immediate(
                    meta.from_device_id,
                    pending_vol.target_device_id,
                    pending_vol.volume,
                    meta.group_device_id,
                    meta.group_instance);
                if (!vol_res.ok) {
                    CONNECT_LOGW("Deferred set_volume replay failed: target=%s key=%s status=%d err='%s'",
                                 pending_vol.target_device_id.c_str(),
                                 pending_vol.target_key.c_str(),
                                 vol_res.http_status,
                                 vol_res.error_message.c_str());
                } else {
                    VolumeAppliedCallback vol_cb;
                    {
                        std::lock_guard<std::mutex> lock(callback_mutex_);
                        vol_cb = volume_applied_callback_;
                    }
                    if (vol_cb) {
                        vol_cb();
                    }
                }
            }
        }

        const bool replay_vol_put =
            volume_throttler_.take_pending_volume_put_state_if_ready();
        const bool replay_player_put =
            volume_throttler_.take_pending_player_put_state_if_ready();
        if (replay_vol_put || replay_player_put) {
            PendingPutStateMeta vol_meta;
            PendingPutStateMeta player_meta;
            {
                std::lock_guard<std::mutex> lock(pending_ctx_mutex_);
                if (replay_vol_put) {
                    vol_meta = std::move(pending_volume_put_state_);
                    pending_volume_put_state_ = {};
                }
                if (replay_player_put) {
                    player_meta = std::move(pending_player_put_state_);
                    pending_player_put_state_ = {};
                }
            }
            if (replay_vol_put && !vol_meta.device_id.empty()) {
                vol_meta.request.put_state_reason = PutStateReason::VOLUME_CHANGED;
                const PutStateResult res = execute_put_state_immediate(
                    vol_meta.device_id, vol_meta.request, vol_meta.wake_devices);
                if (!res.ok) {
                    CONNECT_LOGW("Deferred VOLUME_CHANGED PutState replay failed: status=%d err='%s'",
                                 res.http_status,
                                 res.error_message.c_str());
                }
            }
            if (replay_player_put && !player_meta.device_id.empty()) {
                // liborbit @ 0xdc0ec4: deferred PLAYER_STATE_CHANGED (4) rewrites reason to PUT_STATE_RATE_LIMITED (12).
                player_meta.request.put_state_reason = PutStateReason::PUT_STATE_RATE_LIMITED;
                const PutStateResult res = execute_put_state_immediate(
                    player_meta.device_id, player_meta.request, player_meta.wake_devices);
                if (!res.ok) {
                    CONNECT_LOGW("Deferred PLAYER_STATE_CHANGED PutState replay failed: status=%d err='%s'",
                                 res.http_status,
                                 res.error_message.c_str());
                }
            }
        }

        uint64_t observed_epoch = 0;
        {
            std::lock_guard<std::mutex> lock(timer_mutex_);
            if (timer_stop_requested_) {
                break;
            }
            observed_epoch = timer_wake_epoch_;
        }

        std::chrono::milliseconds wait_ms(0);
        bool has_pending = false;

        if (backoff_.is_backoff_active()) {
            const auto rem = backoff_.remaining_backoff();
            wait_ms = rem.count() > 0 ? rem : std::chrono::milliseconds(1);
            has_pending = true;
        }
        if (auto vol_delay = volume_throttler_.pending_volume_delay()) {
            const auto d = vol_delay->count() > 0 ? *vol_delay : std::chrono::milliseconds(0);
            wait_ms = has_pending ? std::min(wait_ms, d) : d;
            has_pending = true;
        }
        if (auto vol_put_delay = volume_throttler_.pending_volume_put_state_delay()) {
            const auto d =
                vol_put_delay->count() > 0 ? *vol_put_delay : std::chrono::milliseconds(0);
            wait_ms = has_pending ? std::min(wait_ms, d) : d;
            has_pending = true;
        }
        if (auto player_put_delay = volume_throttler_.pending_player_put_state_delay()) {
            const auto d =
                player_put_delay->count() > 0 ? *player_put_delay : std::chrono::milliseconds(0);
            wait_ms = has_pending ? std::min(wait_ms, d) : d;
            has_pending = true;
        }

        if (has_pending && wait_ms.count() <= 0) {
            continue;
        }

        std::unique_lock<std::mutex> lock(timer_mutex_);
        if (timer_stop_requested_) {
            break;
        }
        if (timer_wake_epoch_ != observed_epoch) {
            continue;
        }
        if (has_pending) {
            timer_cv_.wait_for(lock, wait_ms, [this, observed_epoch]() {
                return timer_stop_requested_ || timer_wake_epoch_ != observed_epoch;
            });
        } else {
            timer_cv_.wait(lock, [this, observed_epoch]() {
                return timer_stop_requested_ ||
                       timer_wake_epoch_ != observed_epoch ||
                       backoff_.is_backoff_active() ||
                       volume_throttler_.pending_volume_delay().has_value() ||
                       volume_throttler_.has_pending_volume_put_state() ||
                       volume_throttler_.has_pending_player_put_state();
            });
        }
        if (timer_stop_requested_) {
            break;
        }
    }
}

}  // namespace spotify::connectstate
