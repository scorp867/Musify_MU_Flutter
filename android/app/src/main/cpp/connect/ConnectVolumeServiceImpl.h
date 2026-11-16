// 1:1 Replicated Spotify Esperanto ConnectVolumeService Native Adapter
// Sources:
// - `liborbit-jni-spotify.so`: `spotify::connect::esperanto::proto::ConnectVolumeService`
//   dispatcher @ `0xe40268`, vtable @ `0x18f49a0` (handlers `0xe3d1b0..0xe3d80e`)
// - Decompiled Java: `p199p/C2086nd.java`, `p199p/lw51.java`, `p199p/a0f1.java`, `p199p/a170.java`

#ifndef MUSIFY_CONNECT_CONNECT_VOLUME_SERVICE_IMPL_H_
#define MUSIFY_CONNECT_CONNECT_VOLUME_SERVICE_IMPL_H_

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "ConnectEsperantoProtos.h"
#include "ConnectServiceImpl.h"
#include "ConnectSubsystem.h"

namespace spotify::connectstate::esperanto {

// Stateless Esperanto volume adapter over ConnectSubsystem&.
class ConnectVolumeServiceImpl final {
public:
    explicit ConnectVolumeServiceImpl(ConnectSubsystem& subsystem);
    ~ConnectVolumeServiceImpl() = default;

    ConnectVolumeServiceImpl(const ConnectVolumeServiceImpl&) = delete;
    ConnectVolumeServiceImpl& operator=(const ConnectVolumeServiceImpl&) = delete;

    [[nodiscard]] EsperantoCallResult dispatch(
        std::string_view method,
        const uint8_t* payload,
        size_t len);

    [[nodiscard]] VolumeResponse build_volume_response(
        const ConnectVolumeSnapshot& snapshot) const;
    [[nodiscard]] std::vector<uint8_t> encode_volume_snapshot(
        const ConnectVolumeSnapshot& snapshot) const;
    [[nodiscard]] std::vector<uint8_t> encode_local_volume(
        uint32_t volume,
        spotify::connectstate::LocalVolumeReason reason) const;

    [[nodiscard]] EsperantoCallResult handle_volume(const uint8_t* payload, size_t len) const;
    [[nodiscard]] EsperantoCallResult handle_local_volume(const uint8_t* payload, size_t len) const;
    [[nodiscard]] EsperantoCallResult handle_volume_set(const uint8_t* payload, size_t len);
    [[nodiscard]] EsperantoCallResult handle_volume_up(const uint8_t* payload, size_t len);
    [[nodiscard]] EsperantoCallResult handle_volume_down(const uint8_t* payload, size_t len);

private:
    [[nodiscard]] uint32_t resolve_volume_step(const std::string& group_device_id) const;

    ConnectSubsystem& subsystem_;
};

}  // namespace spotify::connectstate::esperanto

#endif  // MUSIFY_CONNECT_CONNECT_VOLUME_SERVICE_IMPL_H_
