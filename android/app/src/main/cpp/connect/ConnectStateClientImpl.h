// ============================================================================
// Replicated from liborbit-jni-spotify.so (ConnectStateClientImpl HTTP endpoints,
// Connection-ID Gating, Ack Tracking & Outbound Rate Limiters):
// - Binary symbols / offsets:
//   - Default spclient fallback `https://spclient.wg.spotify.com` (0x350245 @ 0xb1d15c)
//   - connection_id_decorator missing X-Spotify-Connection-Id err=8 (0x39c1c3 @ 0x12effc4..0x12f0040)
//   - ConnectStateClientImpl::putState @ 0xdc1b8c..0xdc2290 (?wake-devices=true|false on PICKER_OPENED=6 @ 0xdc1ba0..0xdc1be0)
//   - ConnectStateClientImpl::rename @ 0xdc22dc..0xdc239c
//   - ConnectStateClientImpl::logout @ 0xdc246c..0xdc24ec
//   - ConnectStateClientImpl::sendPlayerCommand @ 0xdc25c4..0xdc26b4
//   - ConnectStateClientImpl::transfer @ 0xdc27a8..0xdc2960, 0xdc4ca0..0xdc5160
//   - ConnectStateClientImpl::setVolume @ 0xdc2a64..0xdc2bd8
//   - ConnectStateClientImpl::group/{add-device,remove-device,delete} @ 0xdc2cc4..0xdc324c
//   - ConnectStateClientImpl::sendSetDeviceInactive @ 0xdc337c..0xdc3414
//   - ConnectStateClientImpl::SetDoDo @ 0xdc3560..0xdc35dc
//   - ConnectStateClientImpl::wakeUpSleepingCluster @ 0xdc36a4..0xdc36dc
//   - ConnectStateClientImpl::deleteDevice @ 0xdc3788..0xdc37b0
//   - ConnectStateClientImpl::updateLocalDevices @ 0xdc3b94..0xdc42bc (application/x-protobuf, uncompressed)
//   - POST connect-group/v1/refresh-group-data (0x389e83 @ 0xda0740, application/protobuf)
//   - ConnectStateImpl::onCommandResponse ack correlation @ 0xdbea00..0xdbf500
//   - ConnectSetupImpl sliding-window rate limiters @ 0xd8fb94..0xd8fce0 (60/10s, 5 update_context/10s)
// ============================================================================

#ifndef MUSIFY_CONNECT_CONNECT_STATE_CLIENT_IMPL_H_
#define MUSIFY_CONNECT_CONNECT_STATE_CLIENT_IMPL_H_

#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <functional>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <thread>
#include <unordered_map>
#include <utility>
#include <vector>

#include "../network/NativeHttpClient.h"
#include "ConnectStateProtos.h"
#include "PutStateBackoff.h"
#include "VolumeThrottler.h"

namespace spotify::connectstate {

class SlidingWindowRateLimiter {
public:
    using Clock = std::function<std::chrono::steady_clock::time_point()>;

    SlidingWindowRateLimiter(
        size_t max_calls,
        int64_t window_ms,
        Clock clock = {});

    [[nodiscard]] bool try_acquire();
    [[nodiscard]] size_t current_count() const;
    void reset();

private:
    void prune_locked(std::chrono::steady_clock::time_point now_tp) const;

    size_t max_calls_{0};
    int64_t window_ms_{0};
    Clock clock_;
    mutable std::mutex mutex_;
    mutable std::deque<std::chrono::steady_clock::time_point> timestamps_;
};

struct PendingCommandAck {
    std::string ack_id;
    std::string target_device_id;
    std::string command_name;
    uint32_t message_id{0};
    std::chrono::steady_clock::time_point registered_at{};
};

class CommandAckTracker {
public:
    static constexpr int64_t kDefaultAckTtlMs = 30000;
    using Clock = std::function<std::chrono::steady_clock::time_point()>;
    using AckCallback = std::function<void(const PendingCommandAck&)>;

    explicit CommandAckTracker(Clock clock = {});

    void set_ack_callback(AckCallback callback);
    void register_ack(
        std::string ack_id,
        std::string target_device_id,
        std::string command_name,
        uint32_t message_id = 0);

    bool on_cluster_ack(std::string_view ack_id);
    bool on_command_message_id_ack(std::string_view device_id, uint32_t message_id);
    void prune_expired(int64_t max_age_ms = kDefaultAckTtlMs);
    [[nodiscard]] size_t pending_count() const;
    [[nodiscard]] std::string last_acked_id() const;
    void reset();

private:
    Clock clock_;
    mutable std::mutex mutex_;
    AckCallback ack_callback_;
    std::unordered_map<std::string, PendingCommandAck> pending_by_ack_id_;
    std::string last_acked_id_;
};

struct TransferOptionsParams {
    bool extrapolate{true};
    bool last_known{false};
    bool only_current{false};
    bool always_play_something{false};
};

struct TransferHttpRequest {
    std::string from_device_id;
    std::string to_device_id;
    TransferOptionsParams options;
    std::string transfer_intent_id;
    std::string command_id;
    bool without_active_device{false};
    std::string target_alias_id;
    std::string dodo;
};

struct PutStateResult {
    bool ok{false};
    bool deferred{false};
    int32_t http_status{0};
    std::string grpc_status;
    int64_t retry_after_ms{0};
    BackoffErrorCode error_code{BackoffErrorCode::kNone};
    std::string error_message;
    std::optional<Cluster> cluster;
};

struct AckHttpResult {
    bool ok{false};
    bool throttled{false};
    int32_t http_status{0};
    BackoffErrorCode error_code{BackoffErrorCode::kNone};
    std::string ack_id;
    std::string error_message;
};

struct TransferHttpResult {
    bool ok{false};
    int32_t http_status{0};
    BackoffErrorCode error_code{BackoffErrorCode::kNone};
    std::string ack_id;
    std::string error_description;
    std::vector<std::string> reasons;
};

struct SimpleHttpResult {
    bool ok{false};
    int32_t http_status{0};
    BackoffErrorCode error_code{BackoffErrorCode::kNone};
    std::string error_message;
};

struct ClusterHttpResult {
    bool ok{false};
    int32_t http_status{0};
    BackoffErrorCode error_code{BackoffErrorCode::kNone};
    std::string error_message;
    std::optional<Cluster> cluster;
};

struct GroupDataHttpResult {
    bool ok{false};
    int32_t http_status{0};
    BackoffErrorCode error_code{BackoffErrorCode::kNone};
    std::string error_message;
    std::optional<GetAllGroupDataResponse> response;
};

struct HttpRequestSpec {
    std::string method;
    std::string url;
    std::vector<uint8_t> body;
    std::string content_type;
    std::vector<std::pair<std::string, std::string>> headers;
    int connect_timeout_ms{8000};
    int read_timeout_ms{15000};
};

class ConnectStateClientImpl {
public:
    static constexpr const char* kDefaultSpclientBaseUrl =
        "https://spclient.wg.spotify.com/";

    static constexpr size_t kMaxCommandsPerWindow = 60;
    static constexpr int64_t kCommandRateLimiterWindowMs = 10000;
    static constexpr size_t kMaxUpdateContextPerWindow = 5;
    static constexpr int64_t kUpdateContextRateLimiterWindowMs = 10000;

    using TransportFn = std::function<network::HttpResponse(const HttpRequestSpec&)>;
    using ClusterCallback = std::function<void(const Cluster&)>;
    using VolumeAppliedCallback = std::function<void()>;

    explicit ConnectStateClientImpl(
        network::NativeHttpClient& http_client,
        std::string spclient_base_url = kDefaultSpclientBaseUrl);

    ConnectStateClientImpl(
        TransportFn transport_fn,
        std::string spclient_base_url = kDefaultSpclientBaseUrl);

    ~ConnectStateClientImpl();

    ConnectStateClientImpl(const ConnectStateClientImpl&) = delete;
    ConnectStateClientImpl& operator=(const ConnectStateClientImpl&) = delete;

    void start();
    void shutdown();

    void set_spclient_base_url(std::string base_url);
    [[nodiscard]] std::string spclient_base_url() const;

    void set_connection_id(std::string connection_id);
    [[nodiscard]] std::string connection_id() const;

    void set_local_device_id(std::string device_id);
    [[nodiscard]] std::string local_device_id() const;

    void set_cluster_callback(ClusterCallback callback);
    void set_volume_applied_callback(VolumeAppliedCallback callback);

    [[nodiscard]] PutStateBackoff& put_state_backoff() noexcept { return backoff_; }
    [[nodiscard]] const PutStateBackoff& put_state_backoff() const noexcept { return backoff_; }

    [[nodiscard]] VolumeThrottler& volume_throttler() noexcept { return volume_throttler_; }
    [[nodiscard]] const VolumeThrottler& volume_throttler() const noexcept {
        return volume_throttler_;
    }

    [[nodiscard]] CommandAckTracker& command_ack_tracker() noexcept { return ack_tracker_; }
    [[nodiscard]] const CommandAckTracker& command_ack_tracker() const noexcept {
        return ack_tracker_;
    }

    bool on_cluster_ack(std::string_view ack_id);

    // 1. PUT connect-state/v1/devices/{device_id}[?wake-devices=true|false on PICKER_OPENED]
    PutStateResult put_state(
        const std::string& device_id,
        const PutStateRequest& request,
        bool wake_devices = false);

    // 2. PUT connect-state/v1/connect/rename/from/{src}/to/{dst}
    AckHttpResult rename(
        const std::string& from_device_id,
        const std::string& to_device_id,
        const RenameCommand& command);

    // 3. POST connect-state/v1/connect/logout/from/{src}/to/{dst}
    SimpleHttpResult logout(
        const std::string& from_device_id,
        const std::string& to_device_id,
        const LogoutCommand& command);

    // 4. POST connect-state/v1/player/command/from/{src}/to/{dst}
    AckHttpResult send_player_command(
        const std::string& from_device_id,
        const std::string& to_device_id,
        std::string_view command_json,
        std::string_view connection_type,
        std::string_view intent_id,
        bool gzip_body = false);

    // 5. POST connect-state/v1/connect/transfer/from/{src}/to/{dst}
    TransferHttpResult transfer(const TransferHttpRequest& request);

    // 6. PUT connect-state/v1/connect/volume/from/{src}/to/{dst}
    AckHttpResult set_volume(
        const std::string& from_device_id,
        const std::string& to_device_id,
        uint32_t volume,
        const std::string& group_device_id = "",
        const std::string& group_instance = "");

    // 7. PUT connect-state/v1/connect/group/add-device/from/{src}/to/{dst}
    AckHttpResult add_device_to_group(
        const std::string& from_device_id,
        const std::string& to_device_id,
        const AddDeviceToGroupCommand& command);

    // 8. PUT connect-state/v1/connect/group/remove-device/from/{src}/to/{dst}
    AckHttpResult remove_device_from_group(
        const std::string& from_device_id,
        const std::string& to_device_id,
        const RemoveDeviceFromGroupCommand& command);

    // 9. POST connect-state/v1/connect/group/delete/from/{src}/to/{dst}
    AckHttpResult delete_group(
        const std::string& from_device_id,
        const std::string& to_device_id,
        const DeleteGroupCommand& command);

    // 10. PUT connect-state/v1/devices/{device_id}/inactive
    SimpleHttpResult send_set_device_inactive(
        const std::string& device_id,
        const SetDeviceInactiveRequest& request,
        int read_timeout_ms = 15000);

    // 11. POST connect-state/connectstate.ConnectStateService/SetDoDo
    ClusterHttpResult set_dodo(const SetDoDoRequest& request);

    // 12. POST connect-state/v1/cluster/wake-devices
    SimpleHttpResult wake_up_sleeping_cluster();

    // 13. DELETE connect-state/v1/devices/{device_id}
    SimpleHttpResult delete_device(const std::string& device_id);

    // 14. PUT connect-state/v1/update_local_devices (application/x-protobuf, uncompressed)
    SimpleHttpResult update_local_devices(const UpdateLocalDevicesRequest& request);

    // 15. POST connect-group/v1/refresh-group-data (application/protobuf -> GetAllGroupDataResponse)
    GroupDataHttpResult refresh_group_data(const RefreshGroupDataRequest& request);

    // Extracts "ack_id" from JSON response; returns "" when absent/invalid.
    [[nodiscard]] static std::string parse_ack_id(std::string_view response_body);

    // Parses transfer HTTP error JSON fields "error_description" and "reasons".
    static void parse_transfer_error_json(
        std::string_view response_body,
        std::string& out_error_description,
        std::vector<std::string>& out_reasons);

    // Builds the transfer JSON payload string.
    [[nodiscard]] static std::string build_transfer_json(const TransferHttpRequest& request);

    // Builds the player command JSON payload string.
    [[nodiscard]] static std::string build_player_command_json(
        std::string_view command_json,
        std::string_view connection_type,
        std::string_view intent_id);

private:
    PutStateResult execute_put_state_immediate(
        const std::string& device_id,
        const PutStateRequest& request,
        bool wake_devices);

    AckHttpResult execute_set_volume_immediate(
        const std::string& from_device_id,
        const std::string& to_device_id,
        uint32_t volume,
        const std::string& group_device_id,
        const std::string& group_instance);

    network::HttpResponse dispatch_http(const HttpRequestSpec& spec) const;
    [[nodiscard]] std::string build_url(std::string_view relative_path) const;
    [[nodiscard]] bool acquire_connect_headers(
        std::vector<std::pair<std::string, std::string>>& out_headers) const;
    void notify_cluster(const Cluster& cluster);
    void schedule_timer_wake();
    void timer_loop();

    TransportFn transport_fn_;
    mutable std::mutex config_mutex_;
    std::string spclient_base_url_;
    std::string connection_id_;
    std::string local_device_id_;

    mutable std::mutex callback_mutex_;
    ClusterCallback cluster_callback_;
    VolumeAppliedCallback volume_applied_callback_;

    PutStateBackoff backoff_;
    VolumeThrottler volume_throttler_;
    CommandAckTracker ack_tracker_;
    SlidingWindowRateLimiter command_rate_limiter_;
    SlidingWindowRateLimiter update_context_rate_limiter_;

    struct PendingPutStateMeta {
        std::string device_id;
        PutStateRequest request;
        bool wake_devices{false};
    };

    struct PendingVolumeMeta {
        std::string from_device_id;
        std::string group_device_id;
        std::string group_instance;
    };

    mutable std::mutex pending_ctx_mutex_;
    PendingPutStateMeta pending_backoff_put_state_;
    PendingPutStateMeta pending_volume_put_state_;
    PendingPutStateMeta pending_player_put_state_;
    std::unordered_map<std::string, PendingVolumeMeta> pending_volume_meta_by_key_;

    mutable std::mutex timer_mutex_;
    std::condition_variable timer_cv_;
    bool timer_running_{false};
    bool timer_stop_requested_{false};
    uint64_t timer_wake_epoch_{0};
    std::thread timer_thread_;
};

}  // namespace spotify::connectstate

#endif  // MUSIFY_CONNECT_CONNECT_STATE_CLIENT_IMPL_H_
