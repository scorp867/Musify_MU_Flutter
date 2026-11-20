// ============================================================================
// Asynchronous Worker Thread Pool for Non-Blocking Connect Esperanto RPCs
// Backs `musify_connect_call_async` (`#47 §2`):
// - service_id 1 = `spotify.connect.esperanto.proto.ConnectService`
// - service_id 2 = `spotify.connect.esperanto.proto.ConnectVolumeService`
// - service_id 3 = `spotify.connect.esperanto.proto.DodoService`
// Dispatches RPCs off the Flutter UI thread and delivers
// `(request_id, EsperantoCallStatus, payload_bytes)` on completion.
// ============================================================================

#ifndef MUSIFY_CONNECT_CONNECT_RPC_EXECUTOR_H_
#define MUSIFY_CONNECT_CONNECT_RPC_EXECUTOR_H_

#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <functional>
#include <mutex>
#include <string>
#include <string_view>
#include <thread>
#include <vector>

#include "ConnectEsperantoProtos.h"
#include "ConnectServiceImpl.h"
#include "ConnectVolumeServiceImpl.h"
#include "DodoServiceImpl.h"

namespace spotify::connectstate::esperanto {

enum class ConnectServiceId : int32_t {
    kConnectService = 1,
    kConnectVolumeService = 2,
    kDodoService = 3,
};

class ConnectRpcExecutor final {
public:
    static constexpr size_t kDefaultWorkerCount = 2;

    static constexpr int32_t kSubmitQueued = 0;
    static constexpr int32_t kSubmitInvalidArgs = -1;
    static constexpr int32_t kSubmitStopped = -2;

    using CompletionCallback = std::function<void(
        int64_t request_id,
        EsperantoCallStatus status,
        std::vector<uint8_t> payload)>;

    // Optional observer notified whenever `ConnectService::State` decodes a valid StateRequest,
    // allowing FFI bridge live-push listeners to stay synchronized with Dart's filter flags.
    using StateRequestObserver = std::function<void(const StateRequest&)>;

    ConnectRpcExecutor(
        ConnectServiceImpl& connect_service,
        ConnectVolumeServiceImpl& volume_service,
        DodoServiceImpl& dodo_service,
        size_t worker_count = kDefaultWorkerCount);

    ~ConnectRpcExecutor();

    ConnectRpcExecutor(const ConnectRpcExecutor&) = delete;
    ConnectRpcExecutor& operator=(const ConnectRpcExecutor&) = delete;

    void start();
    void stop();
    [[nodiscard]] bool is_running() const;

    void set_state_request_observer(StateRequestObserver observer);

    // Enqueues an asynchronous Esperanto RPC onto the worker pool.
    // Returns:
    //   0  (kSubmitQueued)      : accepted and queued for worker execution
    //  -1  (kSubmitInvalidArgs) : unknown service_id, empty method, invalid payload, or null callback
    //  -2  (kSubmitStopped)     : executor is stopped or shutting down
    int32_t submit(
        int32_t service_id,
        std::string method,
        std::vector<uint8_t> payload,
        int64_t request_id,
        CompletionCallback completion);

    int32_t submit(
        int32_t service_id,
        const char* method,
        const uint8_t* payload,
        int32_t payload_len,
        int64_t request_id,
        CompletionCallback completion);

    // Synchronous dispatch helper used internally by workers (and testable directly).
    [[nodiscard]] EsperantoCallResult dispatch_sync(
        ConnectServiceId service_id,
        std::string_view method,
        const uint8_t* payload,
        size_t payload_len);

    [[nodiscard]] static bool try_parse_service_id(
        int32_t raw_service_id,
        ConnectServiceId& out_service_id) noexcept;

private:
    struct PendingTask {
        ConnectServiceId service_id{ConnectServiceId::kConnectService};
        std::string method;
        std::vector<uint8_t> payload;
        int64_t request_id{0};
        CompletionCallback completion;
    };

    void worker_loop();

    ConnectServiceImpl& connect_service_;
    ConnectVolumeServiceImpl& volume_service_;
    DodoServiceImpl& dodo_service_;
    size_t worker_count_{kDefaultWorkerCount};

    mutable std::mutex mutex_;
    std::condition_variable cv_;
    StateRequestObserver state_request_observer_;
    std::deque<PendingTask> queue_;
    std::vector<std::thread> workers_;
    bool running_{false};
    bool stop_requested_{false};
};

}  // namespace spotify::connectstate::esperanto

#endif  // MUSIFY_CONNECT_CONNECT_RPC_EXECUTOR_H_
