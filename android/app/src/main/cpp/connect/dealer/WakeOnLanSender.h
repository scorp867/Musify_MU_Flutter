// ============================================================================
// Modular Wake-on-LAN Magic Packet Validator & UDP Broadcaster
// Replicated from `liborbit-jni-spotify.so` (arm64):
// - ProxyTransferCommand @ 0xdb9424, ProxyWakeCommand @ 0xdb9828
// - WakeOnLanInfo validation (mac.size() == 6, port < 65536) & 102-byte UDP packet
// ============================================================================

#ifndef MUSIFY_CONNECT_DEALER_WAKE_ON_LAN_SENDER_H_
#define MUSIFY_CONNECT_DEALER_WAKE_ON_LAN_SENDER_H_

#include <cstdint>
#include <optional>
#include <vector>

#include "../ConnectStateProtos.h"

namespace spotify::connectstate {

class WakeOnLanSender {
public:
    static constexpr size_t kMacAddressLength = 6U;
    static constexpr size_t kMagicPacketLength = 102U;
    static constexpr uint16_t kDefaultWolPort = 9U;
    static constexpr uint32_t kMaxRetries = 5U;

    [[nodiscard]] static bool validate_wol_info(const WakeOnLanInfo& info) noexcept;
    [[nodiscard]] static std::optional<std::vector<uint8_t>> build_wol_magic_packet(
        const WakeOnLanInfo& info);
    [[nodiscard]] static bool send_wol_magic_packet(const WakeOnLanInfo& info);
};

}  // namespace spotify::connectstate

#endif  // MUSIFY_CONNECT_DEALER_WAKE_ON_LAN_SENDER_H_
