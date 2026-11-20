// ============================================================================
// Modular Wake-on-LAN Magic Packet Validator & UDP Broadcaster Implementation
// Replicated from `liborbit-jni-spotify.so` (arm64):
// - ProxyTransferCommand @ 0xdb9424, ProxyWakeCommand @ 0xdb9828
// - WakeOnLanInfo validation (mac.size() == 6, port < 65536) & 102-byte UDP packet
// ============================================================================

#include "WakeOnLanSender.h"

#include "../../network/NativeLog.h"

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

#include <algorithm>
#include <cerrno>
#include <chrono>
#include <cstring>
#include <thread>

namespace spotify::connectstate {

bool WakeOnLanSender::validate_wol_info(const WakeOnLanInfo& info) noexcept {
    if (info.mac_address.size() != kMacAddressLength) {
        return false;
    }
    if (info.port >= 65536U) {
        return false;
    }
    return true;
}

std::optional<std::vector<uint8_t>> WakeOnLanSender::build_wol_magic_packet(
    const WakeOnLanInfo& info) {
    if (!validate_wol_info(info)) {
        return std::nullopt;
    }
    std::vector<uint8_t> packet;
    packet.reserve(kMagicPacketLength);
    for (size_t i = 0; i < 6U; ++i) {
        packet.push_back(0xFFU);
    }
    for (size_t rep = 0; rep < 16U; ++rep) {
        for (const uint8_t b : info.mac_address) {
            packet.push_back(b);
        }
    }
    return packet;
}

bool WakeOnLanSender::send_wol_magic_packet(const WakeOnLanInfo& info) {
    const auto packet = build_wol_magic_packet(info);
    if (!packet.has_value()) {
        DEALER_LOGW("WakeOnLan rejected invalid WakeOnLanInfo (mac_len=%zu, port=%u)",
                    info.mac_address.size(),
                    info.port);
        return false;
    }
    const uint16_t target_port =
        info.port > 0U ? static_cast<uint16_t>(info.port) : kDefaultWolPort;

    const int sock = ::socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC, IPPROTO_UDP);
    if (sock < 0) {
        DEALER_LOGW("WakeOnLan socket creation failed: errno=%d (%s)",
                    errno,
                    std::strerror(errno));
        return false;
    }

    int broadcast = 1;
    if (::setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcast, sizeof(broadcast)) != 0) {
        DEALER_LOGW("WakeOnLan setsockopt(SO_BROADCAST) failed: errno=%d (%s)",
                    errno,
                    std::strerror(errno));
        ::close(sock);
        return false;
    }

    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(target_port);
    addr.sin_addr.s_addr = htonl(INADDR_BROADCAST);

    const uint32_t attempts = std::max<uint32_t>(1U, std::min<uint32_t>(info.retries, kMaxRetries));
    const uint32_t clamped_delay_ms = std::min<uint32_t>(info.delay_ms, 500U);
    bool any_sent = false;

    for (uint32_t attempt = 0; attempt < attempts; ++attempt) {
        const ssize_t sent = ::sendto(
            sock,
            packet->data(),
            packet->size(),
            0,
            reinterpret_cast<const sockaddr*>(&addr),
            sizeof(addr));
        if (sent == static_cast<ssize_t>(packet->size())) {
            any_sent = true;
        } else {
            DEALER_LOGW("WakeOnLan sendto attempt %u/%u failed: sent=%zd errno=%d (%s)",
                        attempt + 1U,
                        attempts,
                        sent,
                        errno,
                        std::strerror(errno));
        }
        if (attempt + 1U < attempts && clamped_delay_ms > 0U) {
            std::this_thread::sleep_for(std::chrono::milliseconds(clamped_delay_ms));
        }
    }

    ::close(sock);
    if (any_sent) {
        DEALER_LOGI("WakeOnLan magic packet broadcast succeeded (port=%u, attempts=%u)",
                    static_cast<unsigned int>(target_port),
                    attempts);
    }
    return any_sent;
}

}  // namespace spotify::connectstate
