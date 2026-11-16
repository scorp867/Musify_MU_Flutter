// 1:1 Replicated Spotify Esperanto DodoService Native Adapter
// Sources:
// - `liborbit-jni-spotify.so`: `spotify::connect::esperanto::proto::DodoService`
//   dispatcher @ `0xe3fdb4`, vtable @ `0x18f4a08` (`0xe3de2e`, `0xe3def8`, `0xe3e0d2`)
// - `dodos_messages.proto` descriptor offset `5714450` / `0x5a1dd0`

#ifndef MUSIFY_CONNECT_DODO_SERVICE_IMPL_H_
#define MUSIFY_CONNECT_DODO_SERVICE_IMPL_H_

#include <cstddef>
#include <cstdint>
#include <string_view>
#include <vector>

#include "ConnectEsperantoProtos.h"
#include "ConnectServiceImpl.h"
#include "ConnectSubsystem.h"

namespace spotify::connectstate::esperanto {

// Stateless Esperanto DodoService adapter over ConnectSubsystem&.
class DodoServiceImpl final {
public:
    explicit DodoServiceImpl(ConnectSubsystem& subsystem);
    ~DodoServiceImpl() = default;

    DodoServiceImpl(const DodoServiceImpl&) = delete;
    DodoServiceImpl& operator=(const DodoServiceImpl&) = delete;

    [[nodiscard]] EsperantoCallResult dispatch(
        std::string_view method,
        const uint8_t* payload,
        size_t len);

    [[nodiscard]] std::vector<uint8_t> encode_dodos(
        const std::vector<spotify::connectstate::SingleDodo>& dodos) const;

    [[nodiscard]] EsperantoCallResult handle_dodo_sub(
        const uint8_t* payload,
        size_t len) const;
    [[nodiscard]] EsperantoCallResult handle_switch_to_dodo(
        const uint8_t* payload,
        size_t len);
    [[nodiscard]] EsperantoCallResult handle_create_new_dodo(
        const uint8_t* payload,
        size_t len);
    [[nodiscard]] EsperantoCallResult handle_end_dodo(
        const uint8_t* payload,
        size_t len);

private:
    ConnectSubsystem& subsystem_;
};

}  // namespace spotify::connectstate::esperanto

#endif  // MUSIFY_CONNECT_DODO_SERVICE_IMPL_H_
