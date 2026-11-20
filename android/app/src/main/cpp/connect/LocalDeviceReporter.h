// ============================================================================
// Replicated Spotify Connect LocalDeviceReporter & Zeroconf getInfo Prober
// Sources (`liborbit-jni-spotify.so` arm64):
// - LocalDeviceReporter & `PUT connect-state/v1/update_local_devices`
//   (`0xdc3b90..0xdc42bc`, `0xdedec0..0xdeffff`, application/x-protobuf uncompressed)
// - `ConnectZeroconfLoginProtocol` (`0xdcf304..0xdd232c`,
//   `?action=getInfo&version=2.12.0` @ `0xdcf3dc`)
// - `Cluster.needs_local_devices` tag 13 gating (`0xdb7060`)
// ============================================================================

#ifndef MUSIFY_CONNECT_LOCAL_DEVICE_REPORTER_H_
#define MUSIFY_CONNECT_LOCAL_DEVICE_REPORTER_H_

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <functional>
#include <mutex>
#include <string>
#include <string_view>
#include <thread>
#include <unordered_map>
#include <vector>

#include "../network/NativeHttpClient.h"
#include "ConnectDevicesImpl.h"
#include "ConnectStateClientImpl.h"
#include "ConnectStateProtos.h"

namespace spotify::connectstate {

struct NsdServiceRecord {
    std::string service_name;
    std::string host;
    uint16_t port{0};
    std::string cpath{"/"};
    std::string version;
    std::string stack;
};

class LocalDeviceReporter {
public:
    static constexpr int kZeroconfConnectTimeoutMs = 2500;
    static constexpr int kZeroconfReadTimeoutMs = 3000;
    static constexpr int64_t kGetInfoCacheTtlMs = 30000;

    using ZeroconfGetFn = std::function<network::HttpResponse(
        const std::string& url,
        const network::HttpRequestOptions& options)>;
    using DevicesChangedCallback = std::function<void()>;

    LocalDeviceReporter(
        ConnectStateClientImpl& client,
        ConnectDevicesImpl& devices,
        network::NativeHttpClient& http_client);

    LocalDeviceReporter(
        ConnectStateClientImpl& client,
        ConnectDevicesImpl& devices,
        ZeroconfGetFn zeroconf_get_fn);

    ~LocalDeviceReporter();

    LocalDeviceReporter(const LocalDeviceReporter&) = delete;
    LocalDeviceReporter& operator=(const LocalDeviceReporter&) = delete;

    void start();
    void stop();
    void reset();

    void set_devices_changed_callback(DevicesChangedCallback callback);

    // Parses Android NSD JSON snapshot and schedules off-thread Zeroconf getInfo probing
    // + ConnectDevicesImpl merge/deduplication. Returns 0 on success, -1 on invalid JSON.
    int32_t update_nsd_services(std::string_view services_json_utf8);

    // Driven by `Cluster.needs_local_devices`. When true, posts
    // `PUT connect-state/v1/update_local_devices` with discovered local devices.
    void set_needs_local_devices(bool needs_local_devices);
    [[nodiscard]] bool needs_local_devices() const;

    // Triggers a report upload if `needs_local_devices` is true (e.g., after connection_id arrives).
    void trigger_report_if_needed();

    // Pure helpers (unit-testable).
    [[nodiscard]] static bool parse_nsd_services_json(
        std::string_view json_utf8,
        std::vector<NsdServiceRecord>& out_records);
    [[nodiscard]] static std::string build_zeroconf_get_info_url(
        const NsdServiceRecord& record);
    [[nodiscard]] static bool parse_zeroconf_get_info_json(
        std::string_view response_body,
        const NsdServiceRecord& record,
        DiscoveredLocalEntry& out_entry);
    [[nodiscard]] static DeviceType parse_device_type_string(std::string_view raw);
    [[nodiscard]] static IncarnationType infer_incarnation_type(
        const NsdServiceRecord& record,
        DeviceType device_type);

private:
    struct CachedProbeEntry {
        DiscoveredLocalEntry entry;
        std::chrono::steady_clock::time_point fetched_at{};
    };

    void worker_loop();
    void probe_and_apply_services(
        const std::vector<NsdServiceRecord>& records,
        uint64_t epoch);
    void report_local_devices_to_backend();
    void notify_devices_changed();

    ConnectStateClientImpl& client_;
    ConnectDevicesImpl& devices_;
    ZeroconfGetFn zeroconf_get_fn_;

    mutable std::mutex mutex_;
    std::condition_variable cv_;
    DevicesChangedCallback devices_changed_callback_;

    std::vector<NsdServiceRecord> latest_records_;
    std::unordered_map<std::string, CachedProbeEntry> probe_cache_;

    bool worker_running_{false};
    bool stop_requested_{false};
    bool services_dirty_{false};
    bool report_dirty_{false};
    bool needs_local_devices_{false};
    std::atomic<uint64_t> nsd_epoch_{0};
    std::atomic<bool> atomic_stop_{false};
    std::thread worker_thread_;
};

}  // namespace spotify::connectstate

#endif  // MUSIFY_CONNECT_LOCAL_DEVICE_REPORTER_H_
