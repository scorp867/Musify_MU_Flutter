// ============================================================================
// Asynchronous Worker Thread Pool for Non-Blocking Connect Esperanto RPCs
// Backs `musify_connect_call_async` (`#47 §2`):
// - service_id 1 = `spotify.connect.esperanto.proto.ConnectService`
// - service_id 2 = `spotify.connect.esperanto.proto.ConnectVolumeService`
// - service_id 3 = `spotify.connect.esperanto.proto.DodoService`
// Dispatches RPCs off the Flutter UI thread and delivers
// `(request_id, EsperantoCallStatus, payload_bytes)` on completion.
// ============================================================================

#include "ConnectRpcExecutor.h"

#include <utility>

#include "../network/NativeLog.h"

namespace spotify::connectstate::esperanto {

ConnectRpcExecutor::ConnectRpcExecutor(
    ConnectServiceImpl& connect_service,
    ConnectVolumeServiceImpl& volume_service,
    DodoServiceImpl& dodo_service,
    size_t worker_count)
    : connect_service_(connect_service),
      volume_service_(volume_service),
      dodo_service_(dodo_service),
      worker_count_(worker_count > 0 ? worker_count : kDefaultWorkerCount) {}

ConnectRpcExecutor::~ConnectRpcExecutor() {
    stop();
}

bool ConnectRpcExecutor::try_parse_service_id(
    int32_t raw_service_id,
    ConnectServiceId& out_service_id) noexcept {
    switch (raw_service_id) {
        case static_cast<int32_t>(ConnectServiceId::kConnectService):
            out_service_id = ConnectServiceId::kConnectService;
            return true;
        case static_cast<int32_t>(ConnectServiceId::kConnectVolumeService):
            out_service_id = ConnectServiceId::kConnectVolumeService;
            return true;
        case static_cast<int32_t>(ConnectServiceId::kDodoService):
            out_service_id = ConnectServiceId::kDodoService;
            return true;
        default:
            return false;
    }
}

void ConnectRpcExecutor::start() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (running_) {
        return;
    }
    stop_requested_ = false;
    running_ = true;
    workers_.reserve(worker_count_);
    for (size_t i = 0; i < worker_count_; ++i) {
        workers_.emplace_back(&ConnectRpcExecutor::worker_loop, this);
    }
    CONNECT_LOGI("ConnectRpcExecutor started with %zu worker thread(s)", worker_count_);
}

void ConnectRpcExecutor::stop() {
    std::deque<PendingTask> cancelled_tasks;
    std::vector<std::thread> workers_to_join;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!running_ && workers_.empty()) {
            return;
        }
        stop_requested_ = true;
        running_ = false;
        cancelled_tasks.swap(queue_);
        workers_to_join.swap(workers_);
    }

    cv_.notify_all();
    for (auto& worker : workers_to_join) {
        if (worker.joinable()) {
            worker.join();
        }
    }

    {
        std::lock_guard<std::mutex> lock(mutex_);
        stop_requested_ = false;
    }

    // Complete any queued tasks that never started so callers never hang waiting on a reply port.
    for (auto& task : cancelled_tasks) {
        if (task.completion) {
            task.completion(
                task.request_id,
                EsperantoCallStatus::kBackendFailure,
                {});
        }
    }
    CONNECT_LOGI(
        "ConnectRpcExecutor stopped cleanly (cancelled_queued=%zu)",
        cancelled_tasks.size());
}

bool ConnectRpcExecutor::is_running() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return running_;
}

void ConnectRpcExecutor::set_state_request_observer(StateRequestObserver observer) {
    std::lock_guard<std::mutex> lock(mutex_);
    state_request_observer_ = std::move(observer);
}

int32_t ConnectRpcExecutor::submit(
    int32_t service_id,
    std::string method,
    std::vector<uint8_t> payload,
    int64_t request_id,
    CompletionCallback completion) {
    ConnectServiceId parsed_service = ConnectServiceId::kConnectService;
    if (!try_parse_service_id(service_id, parsed_service) ||
        method.empty() ||
        !completion) {
        CONNECT_LOGW(
            "ConnectRpcExecutor::submit rejected invalid args service_id=%d method_empty=%d",
            service_id,
            method.empty() ? 1 : 0);
        return kSubmitInvalidArgs;
    }

    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!running_ || stop_requested_) {
            CONNECT_LOGW(
                "ConnectRpcExecutor::submit rejected: executor stopped (service=%d method=%s)",
                service_id,
                method.c_str());
            return kSubmitStopped;
        }
        queue_.push_back(PendingTask{
            .service_id = parsed_service,
            .method = std::move(method),
            .payload = std::move(payload),
            .request_id = request_id,
            .completion = std::move(completion),
        });
    }
    cv_.notify_one();
    return kSubmitQueued;
}

int32_t ConnectRpcExecutor::submit(
    int32_t service_id,
    const char* method,
    const uint8_t* payload,
    int32_t payload_len,
    int64_t request_id,
    CompletionCallback completion) {
    if (method == nullptr || payload_len < 0 || (payload_len > 0 && payload == nullptr)) {
        return kSubmitInvalidArgs;
    }
    std::vector<uint8_t> body;
    if (payload_len > 0) {
        body.assign(payload, payload + payload_len);
    }
    return submit(
        service_id,
        std::string(method),
        std::move(body),
        request_id,
        std::move(completion));
}

EsperantoCallResult ConnectRpcExecutor::dispatch_sync(
    ConnectServiceId service_id,
    std::string_view method,
    const uint8_t* payload,
    size_t payload_len) {
    switch (service_id) {
        case ConnectServiceId::kConnectService: {
            if (method == "State") {
                StateRequest decoded_req;
                if (decode_state_request(payload, payload_len, decoded_req)) {
                    StateRequestObserver observer;
                    {
                        std::lock_guard<std::mutex> lock(mutex_);
                        observer = state_request_observer_;
                    }
                    if (observer) {
                        observer(decoded_req);
                    }
                }
            }
            return connect_service_.dispatch(method, payload, payload_len);
        }
        case ConnectServiceId::kConnectVolumeService:
            return volume_service_.dispatch(method, payload, payload_len);
        case ConnectServiceId::kDodoService:
            return dodo_service_.dispatch(method, payload, payload_len);
    }
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kUnknownMethod,
        .payload = {},
    };
}

void ConnectRpcExecutor::worker_loop() {
    while (true) {
        PendingTask task;
        {
            std::unique_lock<std::mutex> lock(mutex_);
            cv_.wait(lock, [this]() {
                return stop_requested_ || !queue_.empty();
            });
            if (stop_requested_) {
                break;
            }
            task = std::move(queue_.front());
            queue_.pop_front();
        }

        const uint8_t* data_ptr = task.payload.empty() ? nullptr : task.payload.data();
        EsperantoCallResult res = dispatch_sync(
            task.service_id,
            task.method,
            data_ptr,
            task.payload.size());

        if (task.completion) {
            task.completion(task.request_id, res.status, std::move(res.payload));
        }
    }
}

}  // namespace spotify::connectstate::esperanto
