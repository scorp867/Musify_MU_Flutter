// ============================================================================
// 1:1 Replicated Spotify Esperanto ConnectService Native Adapter
// Sources:
// - `liborbit-jni-spotify.so` (arm64): `spotify::connect::esperanto::proto::ConnectService`
//   dispatcher @ `0xe3e3dc`, vtable @ `0x18f48b0` (handlers `0xe397c0..0xe3b0e6`)
// - Connect-Group v1 enrichment (`0xd9f810..0xda1818`) & incarnation dedup (`0xdad978..0xdae530`)
// - Decompiled Java: `p199p/s77.java`, `p199p/C2086nd.java`, `p199p/c8k.java`, `p199p/n8d.java`
// ============================================================================

#ifndef MUSIFY_CONNECT_CONNECT_SERVICE_IMPL_H_
#define MUSIFY_CONNECT_CONNECT_SERVICE_IMPL_H_

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

#include "ConnectEsperantoProtos.h"
#include "ConnectSubsystem.h"

namespace spotify::connectstate::esperanto {

enum class EsperantoCallStatus : int32_t {
    kOk = 0,
    kNotFound = 1,
    kInvalidArguments = 2,
    kBackendFailure = 3,
    kUnimplemented = 4,
    kUnknownMethod = 5,
    kDecodeError = 6,
};

struct EsperantoCallResult {
    EsperantoCallStatus status{EsperantoCallStatus::kOk};
    std::vector<uint8_t> payload;
};

// Stateless Esperanto adapter over ConnectSubsystem&.
// Holds no duplicated cluster or device state (ConnectSubsystem / ConnectDevicesImpl is SSOT).
class ConnectServiceImpl final {
public:
    explicit ConnectServiceImpl(ConnectSubsystem& subsystem);
    ~ConnectServiceImpl() = default;

    ConnectServiceImpl(const ConnectServiceImpl&) = delete;
    ConnectServiceImpl& operator=(const ConnectServiceImpl&) = delete;

    [[nodiscard]] EsperantoCallResult dispatch(
        std::string_view method,
        const uint8_t* payload,
        size_t len);

    [[nodiscard]] StateResponse build_state_response(const StateRequest& request) const;

    [[nodiscard]] EsperantoCallResult handle_state(const uint8_t* payload, size_t len) const;
    [[nodiscard]] EsperantoCallResult handle_transfer(const uint8_t* payload, size_t len);
    [[nodiscard]] EsperantoCallResult handle_send_command(const uint8_t* payload, size_t len);
    [[nodiscard]] EsperantoCallResult handle_pull(const uint8_t* payload, size_t len);
    [[nodiscard]] EsperantoCallResult handle_rename(const uint8_t* payload, size_t len);
    [[nodiscard]] EsperantoCallResult handle_logout(const uint8_t* payload, size_t len);
    [[nodiscard]] EsperantoCallResult handle_notify_audio_route_changed(
        const uint8_t* payload,
        size_t len);
    [[nodiscard]] EsperantoCallResult handle_set_preferred_incarnation(
        const uint8_t* payload,
        size_t len);
    [[nodiscard]] EsperantoCallResult handle_create_static_group(
        const uint8_t* payload,
        size_t len) const;
    [[nodiscard]] EsperantoCallResult handle_rename_group(
        const uint8_t* payload,
        size_t len) const;
    [[nodiscard]] EsperantoCallResult handle_add_device_to_group(
        const uint8_t* payload,
        size_t len);
    [[nodiscard]] EsperantoCallResult handle_remove_device_from_group(
        const uint8_t* payload,
        size_t len);
    [[nodiscard]] EsperantoCallResult handle_delete_group(
        const uint8_t* payload,
        size_t len);
    [[nodiscard]] EsperantoCallResult handle_cluster_update_after_backend_connection(
        const uint8_t* payload,
        size_t len) const;
    [[nodiscard]] EsperantoCallResult handle_install_spotify(
        const uint8_t* payload,
        size_t len) const;
    [[nodiscard]] EsperantoCallResult handle_perform_discovery(
        const uint8_t* payload,
        size_t len);
    [[nodiscard]] EsperantoCallResult handle_refresh_cluster(
        const uint8_t* payload,
        size_t len);
    [[nodiscard]] EsperantoCallResult handle_wake_sleeping_cluster_devices(
        const uint8_t* payload,
        size_t len);

private:
    [[nodiscard]] StateDevice map_device(
        const DeviceInfo& info,
        bool is_self,
        const Cluster& cluster,
        const std::string& preferred_incarnation,
        std::optional<uint32_t> preferred_login_type,
        const std::unordered_map<std::string, ConnectGroupDeviceVolume>& group_volumes) const;

    ConnectSubsystem& subsystem_;
};

}  // namespace spotify::connectstate::esperanto

#endif  // MUSIFY_CONNECT_CONNECT_SERVICE_IMPL_H_
