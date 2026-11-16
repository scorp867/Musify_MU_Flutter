// Replicated from liborbit-jni-spotify.so (ConnectStateClientImpl HTTP endpoints & throttling):
// - Binary symbols / offsets:
//   - ConnectStateClientImpl::putState @ 0xdc1b8c..0xdc2290 (PUT connect-state/v1/devices/{id}[?wake-devices=true], application/protobuf, Content-Encoding: gzip)
//   - ConnectStateClientImpl::rename @ 0xdc22dc..0xdc239c (PUT connect-state/v1/connect/rename/from/{src}/to/{dst})
//   - ConnectStateClientImpl::logout @ 0xdc246c..0xdc24ec (POST connect-state/v1/connect/logout/from/{src}/to/{dst})
//   - ConnectStateClientImpl::sendPlayerCommand @ 0xdc25c4..0xdc26b4 (POST connect-state/v1/player/command/from/{src}/to/{dst})
//   - ConnectStateClientImpl::transfer @ 0xdc27a8..0xdc2960, 0xdc4ca0..0xdc5160 (POST connect-state/v1/connect/transfer/from/{src}/to/{dst})
//   - ConnectStateClientImpl::setVolume @ 0xdc2a64..0xdc2bd8 (PUT connect-state/v1/connect/volume/from/{src}/to/{dst})
//   - ConnectStateClientImpl::group/{add-device,remove-device,delete} @ 0xdc2cc4..0xdc324c
//   - ConnectStateClientImpl::sendSetDeviceInactive @ 0xdc337c..0xdc3414 (PUT connect-state/v1/devices/{id}/inactive)
//   - ConnectStateClientImpl::SetDoDo @ 0xdc3560..0xdc35dc (POST connect-state/connectstate.ConnectStateService/SetDoDo, application/x-protobuf)
//   - ConnectStateClientImpl::wakeUpSleepingCluster @ 0xdc36a4..0xdc36dc (POST connect-state/v1/cluster/wake-devices)
//   - ConnectStateClientImpl::deleteDevice @ 0xdc3788..0xdc37b0 (DELETE connect-state/v1/devices/{id})
//   - ConnectStateClientImpl::updateLocalDevices @ 0xdc3b94..0xdc42bc (PUT connect-state/v1/update_local_devices, application/x-protobuf)
//   - ConnectStateClientImpl::parseAckId @ 0xdc4b74..0xdc4c3c ("ack_id")
// - Java / Esperanto counterparts:
//   - com/spotify/core/corefullimpl/NativeFullAuthenticatedScopeImpl.java
//   - p199p/s77.java, p199p/C2086nd.java, p199p/a0f1.java, p199p/lw51.java

#include "ConnectStateClientImpl.h"

#include <cstdlib>
#include <utility>

#include "DealerWebSocketClient.h"

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

}  // namespace

ConnectStateClientImpl::ConnectStateClientImpl(
    network::NativeHttpClient& http_client,
    std::string spclient_base_url)
    : transport_fn_([&http_client](const HttpRequestSpec& spec) -> network::HttpResponse {
          if (spec.method == "PUT") {
              return http_client.put(
                  spec.url, spec.body, spec.content_type, spec.headers, 8000, 15000, true);
          }
          if (spec.method == "POST") {
              return http_client.post(
                  spec.url, spec.body, spec.content_type, spec.headers, 8000, 15000, true);
          }
          if (spec.method == "DELETE") {
              return http_client.del(spec.url, spec.headers, 8000, 15000, true);
          }
          return http_client.get(spec.url, spec.headers, 8000, 12000, true);
      }),
      spclient_base_url_(std::move(spclient_base_url)) {}

ConnectStateClientImpl::ConnectStateClientImpl(
    TransportFn transport_fn,
    std::string spclient_base_url)
    : transport_fn_(std::move(transport_fn)),
      spclient_base_url_(std::move(spclient_base_url)) {}

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
    {
        std::lock_guard<std::mutex> lock(pending_ctx_mutex_);
        pending_backoff_put_state_ = {};
        pending_volume_put_state_ = {};
        pending_player_put_state_ = {};
        pending_volume_from_device_id_.clear();
        pending_volume_group_id_.clear();
        pending_volume_group_instance_.clear();
    }
}

void ConnectStateClientImpl::set_spclient_base_url(std::string base_url) {
    std::lock_guard<std::mutex> lock(config_mutex_);
    spclient_base_url_ = std::move(base_url);
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

std::vector<std::pair<std::string, std::string>>
ConnectStateClientImpl::default_connect_headers() const {
    std::vector<std::pair<std::string, std::string>> hdrs;
    const std::string cid = connection_id();
    if (!cid.empty()) {
        hdrs.emplace_back("X-Spotify-Connection-Id", cid);
    }
    return hdrs;
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
    const std::vector<uint8_t> serialized = encode_put_state_request(request);
    auto compressed = gzip_compress(serialized.data(), serialized.size());
    if (!compressed.has_value()) {
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
    if (wake_devices) {
        path.append("?wake-devices=true");
    }

    auto headers = default_connect_headers();
    headers.emplace_back("Content-Encoding", "gzip");

    HttpRequestSpec spec{
        .method = "PUT",
        .url = build_url(path),
        .body = std::move(*compressed),
        .content_type = "application/protobuf",
        .headers = std::move(headers),
    };

    const network::HttpResponse resp = dispatch_http(spec);
    if (!resp.transport_ok && resp.status_code == 0) {
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
        decoded_cluster = std::move(cluster);
        notify_cluster(*decoded_cluster);
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
    HttpRequestSpec spec{
        .method = "PUT",
        .url = build_url(
            "connect-state/v1/connect/rename/from/" + from_device_id + "/to/" + to_device_id),
        .body = encode_rename_command(command),
        .content_type = "application/protobuf",
        .headers = default_connect_headers(),
    };
    const network::HttpResponse resp = dispatch_http(spec);
    if (!resp.isSuccess()) {
        return AckHttpResult{
            .ok = false,
            .throttled = false,
            .http_status = resp.status_code,
            .ack_id = {},
            .error_message = response_error_text(resp),
        };
    }
    return AckHttpResult{
        .ok = true,
        .throttled = false,
        .http_status = resp.status_code,
        .ack_id = parse_ack_id(response_body_text(resp)),
        .error_message = {},
    };
}

SimpleHttpResult ConnectStateClientImpl::logout(
    const std::string& from_device_id,
    const std::string& to_device_id,
    const LogoutCommand& command) {
    HttpRequestSpec spec{
        .method = "POST",
        .url = build_url(
            "connect-state/v1/connect/logout/from/" + from_device_id + "/to/" + to_device_id),
        .body = encode_logout_command(command),
        .content_type = "application/protobuf",
        .headers = default_connect_headers(),
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    return SimpleHttpResult{
        .ok = ok,
        .http_status = resp.status_code,
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
    const std::string json_body =
        build_player_command_json(command_json, connection_type, intent_id);
    std::vector<uint8_t> body(json_body.begin(), json_body.end());
    auto headers = default_connect_headers();

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
    };
    const network::HttpResponse resp = dispatch_http(spec);
    if (!resp.isSuccess()) {
        return AckHttpResult{
            .ok = false,
            .throttled = false,
            .http_status = resp.status_code,
            .ack_id = {},
            .error_message = response_error_text(resp),
        };
    }
    return AckHttpResult{
        .ok = true,
        .throttled = false,
        .http_status = resp.status_code,
        .ack_id = parse_ack_id(response_body_text(resp)),
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
    const std::string body_str = build_transfer_json(request);
    HttpRequestSpec spec{
        .method = "POST",
        .url = build_url(
            "connect-state/v1/connect/transfer/from/" + request.from_device_id +
            "/to/" + request.to_device_id),
        .body = std::vector<uint8_t>(body_str.begin(), body_str.end()),
        .content_type = "application/json",
        .headers = default_connect_headers(),
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
        return TransferHttpResult{
            .ok = false,
            .http_status = resp.status_code,
            .ack_id = {},
            .error_description = std::move(err_desc),
            .reasons = std::move(reasons),
        };
    }
    return TransferHttpResult{
        .ok = true,
        .http_status = resp.status_code,
        .ack_id = parse_ack_id(resp_text),
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
    const auto decision = volume_throttler_.submit_volume_command(volume, to_device_id);
    if (decision.action == ThrottleAction::kThrottled) {
        {
            std::lock_guard<std::mutex> lock(pending_ctx_mutex_);
            pending_volume_from_device_id_ = from_device_id;
            pending_volume_group_id_ = group_device_id;
            pending_volume_group_instance_ = group_instance;
        }
        schedule_timer_wake();
        return AckHttpResult{
            .ok = true,
            .throttled = true,
            .http_status = 0,
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
    SetVolumeCommand cmd;
    cmd.volume = static_cast<int32_t>(volume);
    cmd.sent_by_device_id = from_device_id;
    cmd.group_device_identifier = group_device_id;
    cmd.group_instance = group_instance;

    HttpRequestSpec spec{
        .method = "PUT",
        .url = build_url(
            "connect-state/v1/connect/volume/from/" + from_device_id + "/to/" + to_device_id),
        .body = encode_set_volume_command(cmd),
        .content_type = "application/protobuf",
        .headers = default_connect_headers(),
    };
    const network::HttpResponse resp = dispatch_http(spec);
    if (!resp.isSuccess()) {
        return AckHttpResult{
            .ok = false,
            .throttled = false,
            .http_status = resp.status_code,
            .ack_id = {},
            .error_message = response_error_text(resp),
        };
    }
    return AckHttpResult{
        .ok = true,
        .throttled = false,
        .http_status = resp.status_code,
        .ack_id = parse_ack_id(response_body_text(resp)),
        .error_message = {},
    };
}

AckHttpResult ConnectStateClientImpl::add_device_to_group(
    const std::string& from_device_id,
    const std::string& to_device_id,
    const AddDeviceToGroupCommand& command) {
    HttpRequestSpec spec{
        .method = "PUT",
        .url = build_url(
            "connect-state/v1/connect/group/add-device/from/" + from_device_id +
            "/to/" + to_device_id),
        .body = encode_add_device_to_group_command(command),
        .content_type = "application/protobuf",
        .headers = default_connect_headers(),
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    return AckHttpResult{
        .ok = ok,
        .throttled = false,
        .http_status = resp.status_code,
        .ack_id = ok ? parse_ack_id(response_body_text(resp)) : std::string{},
        .error_message = ok ? std::string{} : response_error_text(resp),
    };
}

AckHttpResult ConnectStateClientImpl::remove_device_from_group(
    const std::string& from_device_id,
    const std::string& to_device_id,
    const RemoveDeviceFromGroupCommand& command) {
    HttpRequestSpec spec{
        .method = "PUT",
        .url = build_url(
            "connect-state/v1/connect/group/remove-device/from/" + from_device_id +
            "/to/" + to_device_id),
        .body = encode_remove_device_from_group_command(command),
        .content_type = "application/protobuf",
        .headers = default_connect_headers(),
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    return AckHttpResult{
        .ok = ok,
        .throttled = false,
        .http_status = resp.status_code,
        .ack_id = ok ? parse_ack_id(response_body_text(resp)) : std::string{},
        .error_message = ok ? std::string{} : response_error_text(resp),
    };
}

AckHttpResult ConnectStateClientImpl::delete_group(
    const std::string& from_device_id,
    const std::string& to_device_id,
    const DeleteGroupCommand& command) {
    HttpRequestSpec spec{
        .method = "POST",
        .url = build_url(
            "connect-state/v1/connect/group/delete/from/" + from_device_id +
            "/to/" + to_device_id),
        .body = encode_delete_group_command(command),
        .content_type = "application/protobuf",
        .headers = default_connect_headers(),
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    return AckHttpResult{
        .ok = ok,
        .throttled = false,
        .http_status = resp.status_code,
        .ack_id = ok ? parse_ack_id(response_body_text(resp)) : std::string{},
        .error_message = ok ? std::string{} : response_error_text(resp),
    };
}

SimpleHttpResult ConnectStateClientImpl::send_set_device_inactive(
    const std::string& device_id,
    const SetDeviceInactiveRequest& request) {
    HttpRequestSpec spec{
        .method = "PUT",
        .url = build_url("connect-state/v1/devices/" + device_id + "/inactive"),
        .body = encode_set_device_inactive_request(request),
        .content_type = "application/protobuf",
        .headers = default_connect_headers(),
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    return SimpleHttpResult{
        .ok = ok,
        .http_status = resp.status_code,
        .error_message = ok ? std::string{} : response_error_text(resp),
    };
}

ClusterHttpResult ConnectStateClientImpl::set_dodo(const SetDoDoRequest& request) {
    HttpRequestSpec spec{
        .method = "POST",
        .url = build_url("connect-state/connectstate.ConnectStateService/SetDoDo"),
        .body = encode_set_dodo_request(request),
        .content_type = "application/x-protobuf",
        .headers = default_connect_headers(),
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    std::optional<Cluster> decoded_cluster;
    if (ok && !resp.body.empty()) {
        Cluster cluster;
        if (decode_cluster(resp.body.data(), resp.body.size(), cluster)) {
            decoded_cluster = std::move(cluster);
            notify_cluster(*decoded_cluster);
        }
    }
    return ClusterHttpResult{
        .ok = ok,
        .http_status = resp.status_code,
        .error_message = ok ? std::string{} : response_error_text(resp),
        .cluster = std::move(decoded_cluster),
    };
}

SimpleHttpResult ConnectStateClientImpl::wake_up_sleeping_cluster() {
    HttpRequestSpec spec{
        .method = "POST",
        .url = build_url("connect-state/v1/cluster/wake-devices"),
        .body = {},
        .content_type = "application/json",
        .headers = default_connect_headers(),
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    return SimpleHttpResult{
        .ok = ok,
        .http_status = resp.status_code,
        .error_message = ok ? std::string{} : response_error_text(resp),
    };
}

SimpleHttpResult ConnectStateClientImpl::delete_device(const std::string& device_id) {
    HttpRequestSpec spec{
        .method = "DELETE",
        .url = build_url("connect-state/v1/devices/" + device_id),
        .body = {},
        .content_type = {},
        .headers = default_connect_headers(),
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    return SimpleHttpResult{
        .ok = ok,
        .http_status = resp.status_code,
        .error_message = ok ? std::string{} : response_error_text(resp),
    };
}

SimpleHttpResult ConnectStateClientImpl::update_local_devices(
    const UpdateLocalDevicesRequest& request) {
    HttpRequestSpec spec{
        .method = "PUT",
        .url = build_url("connect-state/v1/update_local_devices"),
        .body = encode_update_local_devices_request(request),
        .content_type = "application/x-protobuf",
        .headers = default_connect_headers(),
    };
    const network::HttpResponse resp = dispatch_http(spec);
    const bool ok = resp.isSuccess();
    return SimpleHttpResult{
        .ok = ok,
        .http_status = resp.status_code,
        .error_message = ok ? std::string{} : response_error_text(resp),
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
            (void)execute_put_state_immediate(
                due_backoff_meta.device_id,
                due_backoff_meta.request,
                due_backoff_meta.wake_devices);
        }

        if (auto pending_vol = volume_throttler_.take_pending_volume_if_ready()) {
            std::string from_id;
            std::string group_id;
            std::string group_inst;
            {
                std::lock_guard<std::mutex> lock(pending_ctx_mutex_);
                from_id = pending_volume_from_device_id_;
                group_id = pending_volume_group_id_;
                group_inst = pending_volume_group_instance_;
            }
            if (!from_id.empty()) {
                (void)execute_set_volume_immediate(
                    from_id,
                    pending_vol->target_device_id,
                    pending_vol->volume,
                    group_id,
                    group_inst);
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
                (void)execute_put_state_immediate(
                    vol_meta.device_id, vol_meta.request, vol_meta.wake_devices);
            }
            if (replay_player_put && !player_meta.device_id.empty()) {
                player_meta.request.put_state_reason = PutStateReason::PLAYER_STATE_CHANGED;
                (void)execute_put_state_immediate(
                    player_meta.device_id, player_meta.request, player_meta.wake_devices);
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
