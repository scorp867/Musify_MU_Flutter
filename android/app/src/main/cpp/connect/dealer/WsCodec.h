// ============================================================================
// Modular Dealer WebSocket Codec (RFC 6455 Framing, HTTP/1.1 Upgrade, SHA-1,
// Base64, zlib/gzip, RFC 3986 URL Normalization)
// Replicated from `liborbit-jni-spotify.so` (arm64):
// - Base64 + zlib/gzip payload codec @ 0xdba108
// - WebSocket upgrade & auth status handling @ 0xb99358 (`p199p/l25.java`, `p199p/C1637b6.java`)
// ============================================================================

#ifndef MUSIFY_CONNECT_DEALER_WS_CODEC_H_
#define MUSIFY_CONNECT_DEALER_WS_CODEC_H_

#include <array>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace spotify::connectstate {

inline constexpr size_t kMaxInboundWebSocketBytes = 16U * 1024U * 1024U;
inline constexpr size_t kMaxWsUpgradeHeaderBytes = 65536U;

// Shared ASCII & HTTP header utilities.
[[nodiscard]] std::string to_lower_ascii(std::string_view input);
[[nodiscard]] std::string_view trim_ascii_ws(std::string_view input) noexcept;
[[nodiscard]] bool has_http_token_ci(
    std::string_view header_value,
    std::string_view expected_lower);
[[nodiscard]] std::optional<std::string> find_header_ci(
    const std::map<std::string, std::string, std::less<>>& headers,
    std::string_view name);

// Shared Base64 / zlib / gzip helpers (used across Dealer, ConnectStateClient, StateRestore).
[[nodiscard]] std::optional<std::vector<uint8_t>> base64_decode(std::string_view input);
[[nodiscard]] std::string base64_encode(const uint8_t* data, size_t len);
[[nodiscard]] std::optional<std::vector<uint8_t>> zlib_decompress(
    const uint8_t* data,
    size_t len,
    size_t max_output_bytes = kMaxInboundWebSocketBytes);
[[nodiscard]] std::optional<std::vector<uint8_t>> gzip_compress(
    const uint8_t* data,
    size_t len);

// CSPRNG bytes for RFC 6455 nonces & client masking keys.
[[nodiscard]] bool fill_csprng_bytes(uint8_t* out, size_t len);

// URL helpers (RFC 3986 percent-encoding & WebSocket URL decomposition).
[[nodiscard]] std::string percent_encode_query_value(std::string_view input);
[[nodiscard]] bool parse_ws_connect_params(
    std::string_view ws_url,
    std::string& out_connect_url,
    std::string& out_host_header,
    std::string& out_request_target);

// RFC 6455 §4.1 / §5.1-5.8 framing & SHA-1 Sec-WebSocket-Accept verification.
enum class Rfc6455Opcode : uint8_t {
    kContinuation = 0x0U,
    kText = 0x1U,
    kBinary = 0x2U,
    kClose = 0x8U,
    kPing = 0x9U,
    kPong = 0xAU,
};

struct Rfc6455Frame {
    Rfc6455Opcode opcode{Rfc6455Opcode::kText};
    std::string payload;
};

enum class Rfc6455ParseResult : uint8_t {
    kNeedMoreData = 0,
    kFrameReady = 1,
    kProtocolError = 2,
};

enum class HttpUpgradeParseResult : uint8_t {
    kNeedMoreData = 0,
    kOk = 1,
    kHttpError = 2,
    kProtocolError = 3,
};

struct HttpUpgradeResponseInfo {
    int32_t http_status_code{0};
    std::string status_line;
    std::map<std::string, std::string, std::less<>> headers;
    size_t header_bytes{0};
};

class Rfc6455FrameParser {
public:
    static constexpr size_t kMaxMessageBytes = kMaxInboundWebSocketBytes;

    void reset();
    void feed(const uint8_t* data, size_t len);
    [[nodiscard]] Rfc6455ParseResult next_frame(Rfc6455Frame& out_frame);
    [[nodiscard]] size_t buffered_bytes() const noexcept;

private:
    enum class Phase : uint8_t {
        kReadBaseHeader = 0,
        kReadExtendedLen16 = 1,
        kReadExtendedLen64 = 2,
        kReadPayload = 3,
    };

    [[nodiscard]] size_t available() const noexcept { return rx_buf_.size() - rx_offset_; }
    void compact_if_needed();
    [[nodiscard]] Rfc6455ParseResult validate_and_prepare_payload();

    std::vector<uint8_t> rx_buf_;
    size_t rx_offset_{0};

    Phase phase_{Phase::kReadBaseHeader};
    bool protocol_error_{false};
    bool current_fin_{false};
    uint8_t current_opcode_{0};
    bool current_is_control_{false};
    uint64_t current_payload_len_{0};
    size_t current_frame_received_{0};

    std::string control_payload_;

    bool has_active_data_msg_{false};
    uint8_t active_data_opcode_{0};
    size_t active_data_bytes_{0};
    std::string data_msg_buffer_;
};

[[nodiscard]] std::array<uint8_t, 20> sha1_digest(std::string_view input);
[[nodiscard]] std::string compute_websocket_accept(std::string_view sec_websocket_key);

[[nodiscard]] HttpUpgradeParseResult parse_websocket_upgrade_response(
    std::string_view buffer,
    std::string_view expected_accept,
    HttpUpgradeResponseInfo& out_info);

[[nodiscard]] HttpUpgradeParseResult parse_websocket_upgrade_response(
    std::string_view buffer,
    std::string_view expected_accept,
    size_t& out_header_bytes);

[[nodiscard]] bool encode_rfc6455_client_frame(
    Rfc6455Opcode opcode,
    const uint8_t* payload,
    size_t payload_len,
    std::vector<uint8_t>& out_bytes);

}  // namespace spotify::connectstate

#endif  // MUSIFY_CONNECT_DEALER_WS_CODEC_H_
