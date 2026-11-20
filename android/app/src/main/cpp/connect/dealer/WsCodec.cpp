// ============================================================================
// Modular Dealer WebSocket Codec Implementation
// Replicated from `liborbit-jni-spotify.so` (arm64):
// - Base64 + zlib/gzip payload codec @ 0xdba108
// - WebSocket upgrade & auth status handling @ 0xb99358 (`p199p/l25.java`, `p199p/C1637b6.java`)
// ============================================================================

#include "WsCodec.h"

#include <fcntl.h>
#include <sys/random.h>
#include <unistd.h>
#include <zlib.h>

#include <algorithm>
#include <array>
#include <cctype>
#include <cerrno>
#include <cstdio>
#include <limits>
#include <utility>

namespace spotify::connectstate {

namespace {

constexpr uint32_t rol32(uint32_t value, uint32_t bits) noexcept {
    return (value << bits) | (value >> (32U - bits));
}

bool is_unreserved_url_char(unsigned char c) noexcept {
    return (c >= 'A' && c <= 'Z') ||
           (c >= 'a' && c <= 'z') ||
           (c >= '0' && c <= '9') ||
           c == '-' || c == '_' || c == '.' || c == '~';
}

bool parse_three_digit_status(std::string_view digits, int32_t& out_status) noexcept {
    if (digits.size() != 3U) {
        return false;
    }
    int32_t value = 0;
    for (char c : digits) {
        if (c < '0' || c > '9') {
            return false;
        }
        value = (value * 10) + static_cast<int32_t>(c - '0');
    }
    out_status = value;
    return true;
}

}  // namespace

std::string to_lower_ascii(std::string_view input) {
    std::string out(input);
    for (char& c : out) {
        c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    }
    return out;
}

std::string_view trim_ascii_ws(std::string_view input) noexcept {
    while (!input.empty() && (input.front() == ' ' || input.front() == '\t')) {
        input.remove_prefix(1);
    }
    while (!input.empty() && (input.back() == ' ' || input.back() == '\t')) {
        input.remove_suffix(1);
    }
    return input;
}

bool has_http_token_ci(std::string_view header_value, std::string_view expected_lower) {
    size_t pos = 0;
    while (pos <= header_value.size()) {
        const size_t comma = header_value.find(',', pos);
        const size_t end = (comma == std::string_view::npos) ? header_value.size() : comma;
        const std::string_view token = trim_ascii_ws(header_value.substr(pos, end - pos));
        if (to_lower_ascii(token) == expected_lower) {
            return true;
        }
        if (comma == std::string_view::npos) {
            break;
        }
        pos = comma + 1;
    }
    return false;
}

std::optional<std::string> find_header_ci(
    const std::map<std::string, std::string, std::less<>>& headers,
    std::string_view name) {
    const std::string needle = to_lower_ascii(name);
    for (const auto& [k, v] : headers) {
        if (to_lower_ascii(k) == needle) {
            return v;
        }
    }
    return std::nullopt;
}

std::optional<std::vector<uint8_t>> base64_decode(std::string_view input) {
    static constexpr std::array<int8_t, 256> kDecodeTable = []() {
        std::array<int8_t, 256> t{};
        t.fill(-1);
        for (int i = 0; i < 26; ++i) {
            t[static_cast<size_t>('A' + i)] = static_cast<int8_t>(i);
            t[static_cast<size_t>('a' + i)] = static_cast<int8_t>(26 + i);
        }
        for (int i = 0; i < 10; ++i) {
            t[static_cast<size_t>('0' + i)] = static_cast<int8_t>(52 + i);
        }
        t[static_cast<size_t>('+')] = 62;
        t[static_cast<size_t>('-')] = 62;
        t[static_cast<size_t>('/')] = 63;
        t[static_cast<size_t>('_')] = 63;
        return t;
    }();

    std::vector<uint8_t> out;
    out.reserve((input.size() * 3) / 4);

    uint32_t val = 0;
    int bits = -8;
    bool saw_padding = false;
    for (const unsigned char c : input) {
        if (c == ' ' || c == '\t' || c == '\r' || c == '\n') {
            continue;
        }
        if (c == '=') {
            saw_padding = true;
            continue;
        }
        if (saw_padding) {
            return std::nullopt;
        }
        const int8_t d = kDecodeTable[c];
        if (d < 0) {
            return std::nullopt;
        }
        val = (val << 6) + static_cast<uint32_t>(d);
        bits += 6;
        if (bits >= 0) {
            out.push_back(static_cast<uint8_t>((val >> bits) & 0xFFU));
            bits -= 8;
        }
    }
    return out;
}

std::string base64_encode(const uint8_t* data, size_t len) {
    static constexpr char kTable[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    std::string out;
    if (data == nullptr && len > 0U) {
        return out;
    }
    out.reserve(((len + 2) / 3) * 4);
    size_t i = 0;
    while (i + 3 <= len) {
        const uint32_t triple = (static_cast<uint32_t>(data[i]) << 16) |
                                (static_cast<uint32_t>(data[i + 1]) << 8) |
                                static_cast<uint32_t>(data[i + 2]);
        out.push_back(kTable[(triple >> 18) & 0x3FU]);
        out.push_back(kTable[(triple >> 12) & 0x3FU]);
        out.push_back(kTable[(triple >> 6) & 0x3FU]);
        out.push_back(kTable[triple & 0x3FU]);
        i += 3;
    }
    const size_t rem = len - i;
    if (rem == 1) {
        const uint32_t v = static_cast<uint32_t>(data[i]) << 16;
        out.push_back(kTable[(v >> 18) & 0x3FU]);
        out.push_back(kTable[(v >> 12) & 0x3FU]);
        out.push_back('=');
        out.push_back('=');
    } else if (rem == 2) {
        const uint32_t v =
            (static_cast<uint32_t>(data[i]) << 16) |
            (static_cast<uint32_t>(data[i + 1]) << 8);
        out.push_back(kTable[(v >> 18) & 0x3FU]);
        out.push_back(kTable[(v >> 12) & 0x3FU]);
        out.push_back(kTable[(v >> 6) & 0x3FU]);
        out.push_back('=');
    }
    return out;
}

std::optional<std::vector<uint8_t>> zlib_decompress(
    const uint8_t* data,
    size_t len,
    size_t max_output_bytes) {
    if ((data == nullptr && len > 0) || len > std::numeric_limits<uInt>::max()) {
        return std::nullopt;
    }
    if (len == 0) {
        return std::vector<uint8_t>{};
    }

    z_stream zs{};
    if (inflateInit2(&zs, 15 + 32) != Z_OK) {
        return std::nullopt;
    }

    zs.next_in = const_cast<Bytef*>(data);
    zs.avail_in = static_cast<uInt>(len);

    std::vector<uint8_t> out;
    std::array<uint8_t, 16384> chunk{};

    int ret = Z_OK;
    do {
        zs.next_out = chunk.data();
        zs.avail_out = static_cast<uInt>(chunk.size());
        ret = inflate(&zs, Z_NO_FLUSH);
        if (ret != Z_OK && ret != Z_STREAM_END) {
            inflateEnd(&zs);
            return std::nullopt;
        }
        const size_t have = chunk.size() - static_cast<size_t>(zs.avail_out);
        if (have > max_output_bytes || out.size() > max_output_bytes - have) {
            inflateEnd(&zs);
            return std::nullopt;
        }
        out.insert(out.end(), chunk.begin(), chunk.begin() + static_cast<std::ptrdiff_t>(have));
    } while (ret != Z_STREAM_END);

    inflateEnd(&zs);
    return out;
}

std::optional<std::vector<uint8_t>> gzip_compress(const uint8_t* data, size_t len) {
    if ((data == nullptr && len > 0) || len > std::numeric_limits<uInt>::max()) {
        return std::nullopt;
    }

    z_stream zs{};
    if (deflateInit2(
            &zs,
            Z_DEFAULT_COMPRESSION,
            Z_DEFLATED,
            15 + 16,
            8,
            Z_DEFAULT_STRATEGY) != Z_OK) {
        return std::nullopt;
    }

    static constexpr Bytef kEmptyDummy = 0;
    zs.next_in = (len == 0) ? const_cast<Bytef*>(&kEmptyDummy) : const_cast<Bytef*>(data);
    zs.avail_in = static_cast<uInt>(len);

    std::vector<uint8_t> out;
    std::array<uint8_t, 16384> chunk{};

    int ret = Z_OK;
    do {
        zs.next_out = chunk.data();
        zs.avail_out = static_cast<uInt>(chunk.size());
        ret = deflate(&zs, Z_FINISH);
        if (ret == Z_STREAM_ERROR) {
            deflateEnd(&zs);
            return std::nullopt;
        }
        const size_t have = chunk.size() - static_cast<size_t>(zs.avail_out);
        out.insert(out.end(), chunk.begin(), chunk.begin() + static_cast<std::ptrdiff_t>(have));
    } while (ret != Z_STREAM_END);

    deflateEnd(&zs);
    return out;
}

bool fill_csprng_bytes(uint8_t* out, size_t len) {
    if (out == nullptr && len > 0U) {
        return false;
    }
    size_t offset = 0;
    bool use_urandom = false;
    while (offset < len && !use_urandom) {
        const ssize_t rc = ::getrandom(out + offset, len - offset, 0);
        if (rc > 0) {
            offset += static_cast<size_t>(rc);
        } else if (rc == 0) {
            use_urandom = true;
        } else if (errno == EINTR) {
            continue;
        } else if (errno == ENOSYS) {
            use_urandom = true;
        } else {
            return false;
        }
    }
    if (offset == len) {
        return true;
    }
    const int fd = ::open("/dev/urandom", O_RDONLY | O_CLOEXEC);
    if (fd < 0) {
        return false;
    }
    while (offset < len) {
        const ssize_t rc = ::read(fd, out + offset, len - offset);
        if (rc > 0) {
            offset += static_cast<size_t>(rc);
        } else if (rc < 0 && errno == EINTR) {
            continue;
        } else {
            ::close(fd);
            return false;
        }
    }
    ::close(fd);
    return true;
}

std::string percent_encode_query_value(std::string_view input) {
    static constexpr char kHex[] = "0123456789ABCDEF";
    std::string out;
    out.reserve(input.size() + 16U);
    for (const unsigned char c : input) {
        if (is_unreserved_url_char(c)) {
            out.push_back(static_cast<char>(c));
        } else {
            out.push_back('%');
            out.push_back(kHex[(c >> 4U) & 0x0FU]);
            out.push_back(kHex[c & 0x0FU]);
        }
    }
    return out;
}

bool parse_ws_connect_params(
    std::string_view ws_url,
    std::string& out_connect_url,
    std::string& out_host_header,
    std::string& out_request_target) {
    out_connect_url.clear();
    out_host_header.clear();
    out_request_target.clear();

    bool is_tls = false;
    std::string_view rest;
    if (ws_url.size() >= 6U && to_lower_ascii(ws_url.substr(0, 6)) == "wss://") {
        is_tls = true;
        rest = ws_url.substr(6);
    } else if (ws_url.size() >= 5U && to_lower_ascii(ws_url.substr(0, 5)) == "ws://") {
        is_tls = false;
        rest = ws_url.substr(5);
    } else if (ws_url.size() >= 8U && to_lower_ascii(ws_url.substr(0, 8)) == "https://") {
        is_tls = true;
        rest = ws_url.substr(8);
    } else if (ws_url.size() >= 7U && to_lower_ascii(ws_url.substr(0, 7)) == "http://") {
        is_tls = false;
        rest = ws_url.substr(7);
    } else {
        return false;
    }

    // Strip any fragment (#...)
    const size_t hash_pos = rest.find('#');
    if (hash_pos != std::string_view::npos) {
        rest = rest.substr(0, hash_pos);
    }
    if (rest.empty()) {
        return false;
    }

    // Split authority vs path+query
    const size_t delim_pos = rest.find_first_of("/?");
    const std::string_view authority =
        (delim_pos == std::string_view::npos) ? rest : rest.substr(0, delim_pos);
    const std::string_view path_and_query =
        (delim_pos == std::string_view::npos) ? std::string_view{} : rest.substr(delim_pos);

    if (authority.empty()) {
        return false;
    }

    // Reject embedded userinfo or whitespace/control chars in authority
    for (unsigned char c : authority) {
        if (c <= 0x20U || c == '@') {
            return false;
        }
    }

    std::string host;
    std::string port;
    if (authority.front() == '[') {
        const size_t close_bracket = authority.find(']');
        if (close_bracket == std::string_view::npos || close_bracket <= 1U) {
            return false;
        }
        host.assign(authority.substr(1, close_bracket - 1));
        const std::string_view after = authority.substr(close_bracket + 1);
        if (!after.empty()) {
            if (after.front() != ':' || after.size() == 1U) {
                return false;
            }
            port.assign(after.substr(1));
        }
    } else {
        const size_t colon = authority.rfind(':');
        if (colon != std::string_view::npos) {
            host.assign(authority.substr(0, colon));
            port.assign(authority.substr(colon + 1));
            if (port.empty()) {
                return false;
            }
        } else {
            host.assign(authority);
        }
    }

    if (host.empty()) {
        return false;
    }
    if (!port.empty()) {
        uint32_t port_num = 0;
        for (char c : port) {
            if (c < '0' || c > '9') {
                return false;
            }
            port_num = (port_num * 10U) + static_cast<uint32_t>(c - '0');
            if (port_num > 65535U) {
                return false;
            }
        }
        if (port_num == 0U) {
            return false;
        }
    }

    std::string host_formatted =
        (host.find(':') != std::string::npos) ? ("[" + host + "]") : host;

    out_host_header = host_formatted;
    const std::string_view default_port = is_tls ? "443" : "80";
    if (!port.empty() && port != default_port) {
        out_host_header.push_back(':');
        out_host_header.append(port);
    }

    if (path_and_query.empty()) {
        out_request_target = "/";
    } else if (path_and_query.front() == '?') {
        out_request_target = "/";
        out_request_target.append(path_and_query);
    } else {
        out_request_target.assign(path_and_query);
    }

    out_connect_url = is_tls ? "https://" : "http://";
    out_connect_url.append(host_formatted);
    if (!port.empty()) {
        out_connect_url.push_back(':');
        out_connect_url.append(port);
    }
    out_connect_url.push_back('/');
    return true;
}

std::array<uint8_t, 20> sha1_digest(std::string_view input) {
    uint32_t h0 = 0x67452301U;
    uint32_t h1 = 0xEFCDAB89U;
    uint32_t h2 = 0x98BADCFEU;
    uint32_t h3 = 0x10325476U;
    uint32_t h4 = 0xC3D2E1F0U;

    const uint64_t total_bits = static_cast<uint64_t>(input.size()) * 8ULL;
    const size_t mod64 = input.size() % 64U;
    const size_t pad_zeros = (mod64 < 56U) ? (55U - mod64) : (119U - mod64);
    const size_t total_len = input.size() + 1U + pad_zeros + 8U;

    std::vector<uint8_t> padded;
    padded.reserve(total_len);
    if (!input.empty()) {
        const auto* raw = reinterpret_cast<const uint8_t*>(input.data());
        padded.insert(padded.end(), raw, raw + input.size());
    }
    padded.push_back(0x80U);
    padded.insert(padded.end(), pad_zeros, 0x00U);
    for (int shift = 56; shift >= 0; shift -= 8) {
        padded.push_back(static_cast<uint8_t>((total_bits >> shift) & 0xFFU));
    }

    for (size_t offset = 0; offset < padded.size(); offset += 64U) {
        std::array<uint32_t, 80> w{};
        for (size_t i = 0; i < 16U; ++i) {
            const size_t idx = offset + (i * 4U);
            w[i] = (static_cast<uint32_t>(padded[idx]) << 24U) |
                   (static_cast<uint32_t>(padded[idx + 1U]) << 16U) |
                   (static_cast<uint32_t>(padded[idx + 2U]) << 8U) |
                   static_cast<uint32_t>(padded[idx + 3U]);
        }
        for (size_t i = 16U; i < 80U; ++i) {
            w[i] = rol32(w[i - 3U] ^ w[i - 8U] ^ w[i - 14U] ^ w[i - 16U], 1U);
        }

        uint32_t a = h0;
        uint32_t b = h1;
        uint32_t c = h2;
        uint32_t d = h3;
        uint32_t e = h4;

        for (size_t i = 0; i < 80U; ++i) {
            uint32_t f = 0;
            uint32_t k = 0;
            if (i < 20U) {
                f = (b & c) | ((~b) & d);
                k = 0x5A827999U;
            } else if (i < 40U) {
                f = b ^ c ^ d;
                k = 0x6ED9EBA1U;
            } else if (i < 60U) {
                f = (b & c) | (b & d) | (c & d);
                k = 0x8F1BBCDCU;
            } else {
                f = b ^ c ^ d;
                k = 0xCA62C1D6U;
            }
            const uint32_t temp = rol32(a, 5U) + f + e + k + w[i];
            e = d;
            d = c;
            c = rol32(b, 30U);
            b = a;
            a = temp;
        }

        h0 += a;
        h1 += b;
        h2 += c;
        h3 += d;
        h4 += e;
    }

    std::array<uint8_t, 20> digest{};
    const std::array<uint32_t, 5> words{h0, h1, h2, h3, h4};
    for (size_t i = 0; i < words.size(); ++i) {
        digest[(i * 4U) + 0U] = static_cast<uint8_t>((words[i] >> 24U) & 0xFFU);
        digest[(i * 4U) + 1U] = static_cast<uint8_t>((words[i] >> 16U) & 0xFFU);
        digest[(i * 4U) + 2U] = static_cast<uint8_t>((words[i] >> 8U) & 0xFFU);
        digest[(i * 4U) + 3U] = static_cast<uint8_t>(words[i] & 0xFFU);
    }
    return digest;
}

std::string compute_websocket_accept(std::string_view sec_websocket_key) {
    static constexpr std::string_view kWsGuid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    std::string combined;
    combined.reserve(sec_websocket_key.size() + kWsGuid.size());
    combined.append(sec_websocket_key);
    combined.append(kWsGuid);
    const std::array<uint8_t, 20> digest = sha1_digest(combined);
    return base64_encode(digest.data(), digest.size());
}

HttpUpgradeParseResult parse_websocket_upgrade_response(
    std::string_view buffer,
    std::string_view expected_accept,
    HttpUpgradeResponseInfo& out_info) {
    out_info = HttpUpgradeResponseInfo{};
    const size_t hdr_end = buffer.find("\r\n\r\n");
    if (hdr_end == std::string_view::npos) {
        return buffer.size() > kMaxWsUpgradeHeaderBytes
                   ? HttpUpgradeParseResult::kProtocolError
                   : HttpUpgradeParseResult::kNeedMoreData;
    }
    out_info.header_bytes = hdr_end + 4U;
    if (out_info.header_bytes > kMaxWsUpgradeHeaderBytes) {
        return HttpUpgradeParseResult::kProtocolError;
    }

    const std::string_view block = buffer.substr(0, hdr_end);
    const size_t first_crlf = block.find("\r\n");
    const std::string_view status_line =
        (first_crlf == std::string_view::npos) ? block : block.substr(0, first_crlf);
    out_info.status_line.assign(status_line);

    if (status_line.size() < 12U ||
        (status_line.substr(0, 9) != "HTTP/1.1 " && status_line.substr(0, 9) != "HTTP/1.0 ") ||
        (status_line.size() > 12U && status_line[12] != ' ')) {
        return HttpUpgradeParseResult::kProtocolError;
    }

    int32_t status_code = 0;
    if (!parse_three_digit_status(status_line.substr(9, 3), status_code)) {
        return HttpUpgradeParseResult::kProtocolError;
    }
    out_info.http_status_code = status_code;

    bool has_upgrade = false;
    bool has_connection_upgrade = false;
    bool saw_accept = false;
    bool accept_matches = false;
    bool has_non_empty_extensions = false;

    if (first_crlf != std::string_view::npos) {
        size_t pos = first_crlf + 2U;
        while (pos <= block.size()) {
            const size_t next_crlf = block.find("\r\n", pos);
            const size_t line_end =
                (next_crlf == std::string_view::npos) ? block.size() : next_crlf;
            const std::string_view line = block.substr(pos, line_end - pos);
            if (!line.empty()) {
                const size_t colon = line.find(':');
                if (colon == std::string_view::npos) {
                    return HttpUpgradeParseResult::kProtocolError;
                }
                const std::string name = to_lower_ascii(trim_ascii_ws(line.substr(0, colon)));
                const std::string_view val = trim_ascii_ws(line.substr(colon + 1U));
                out_info.headers[name] = std::string(val);

                if (name == "upgrade") {
                    if (has_http_token_ci(val, "websocket")) {
                        has_upgrade = true;
                    }
                } else if (name == "connection") {
                    if (has_http_token_ci(val, "upgrade")) {
                        has_connection_upgrade = true;
                    }
                } else if (name == "sec-websocket-accept") {
                    if (saw_accept) {
                        return HttpUpgradeParseResult::kProtocolError;
                    }
                    saw_accept = true;
                    accept_matches = (!expected_accept.empty() && val == expected_accept);
                } else if (name == "sec-websocket-extensions") {
                    if (!val.empty()) {
                        has_non_empty_extensions = true;
                    }
                }
            }
            if (next_crlf == std::string_view::npos) {
                break;
            }
            pos = next_crlf + 2U;
        }
    }

    if (status_code != 101) {
        return HttpUpgradeParseResult::kHttpError;
    }
    if (first_crlf == std::string_view::npos) {
        return HttpUpgradeParseResult::kProtocolError;
    }
    if (!has_upgrade || !has_connection_upgrade || !accept_matches || has_non_empty_extensions) {
        return HttpUpgradeParseResult::kProtocolError;
    }
    return HttpUpgradeParseResult::kOk;
}

HttpUpgradeParseResult parse_websocket_upgrade_response(
    std::string_view buffer,
    std::string_view expected_accept,
    size_t& out_header_bytes) {
    HttpUpgradeResponseInfo info;
    const HttpUpgradeParseResult res =
        parse_websocket_upgrade_response(buffer, expected_accept, info);
    out_header_bytes = info.header_bytes;
    if (res == HttpUpgradeParseResult::kHttpError) {
        return HttpUpgradeParseResult::kProtocolError;
    }
    return res;
}

bool encode_rfc6455_client_frame(
    Rfc6455Opcode opcode,
    const uint8_t* payload,
    size_t payload_len,
    std::vector<uint8_t>& out_bytes) {
    if (payload == nullptr && payload_len > 0U) {
        return false;
    }
    const uint8_t raw_op = static_cast<uint8_t>(opcode);
    const bool valid_opcode = (raw_op == 0x0U || raw_op == 0x1U || raw_op == 0x2U ||
                               raw_op == 0x8U || raw_op == 0x9U || raw_op == 0xAU);
    if (!valid_opcode) {
        return false;
    }
    const bool is_control = (raw_op & 0x08U) != 0U;
    if (is_control && payload_len > 125U) {
        return false;
    }

    std::array<uint8_t, 4> mask_key{};
    if (!fill_csprng_bytes(mask_key.data(), mask_key.size())) {
        return false;
    }

    out_bytes.reserve(out_bytes.size() + 14U + payload_len);
    out_bytes.push_back(static_cast<uint8_t>(0x80U | raw_op));

    if (payload_len <= 125U) {
        out_bytes.push_back(static_cast<uint8_t>(0x80U | payload_len));
    } else if (payload_len <= 65535U) {
        out_bytes.push_back(static_cast<uint8_t>(0x80U | 126U));
        out_bytes.push_back(static_cast<uint8_t>((payload_len >> 8U) & 0xFFU));
        out_bytes.push_back(static_cast<uint8_t>(payload_len & 0xFFU));
    } else {
        out_bytes.push_back(static_cast<uint8_t>(0x80U | 127U));
        const uint64_t len64 = static_cast<uint64_t>(payload_len);
        for (int shift = 56; shift >= 0; shift -= 8) {
            out_bytes.push_back(static_cast<uint8_t>((len64 >> shift) & 0xFFU));
        }
    }

    out_bytes.insert(out_bytes.end(), mask_key.begin(), mask_key.end());
    for (size_t i = 0; i < payload_len; ++i) {
        out_bytes.push_back(static_cast<uint8_t>(payload[i] ^ mask_key[i & 3U]));
    }
    return true;
}

void Rfc6455FrameParser::reset() {
    rx_buf_.clear();
    rx_offset_ = 0;
    phase_ = Phase::kReadBaseHeader;
    protocol_error_ = false;
    current_fin_ = false;
    current_opcode_ = 0;
    current_is_control_ = false;
    current_payload_len_ = 0;
    current_frame_received_ = 0;
    control_payload_.clear();
    has_active_data_msg_ = false;
    active_data_opcode_ = 0;
    active_data_bytes_ = 0;
    data_msg_buffer_.clear();
}

void Rfc6455FrameParser::feed(const uint8_t* data, size_t len) {
    if (data == nullptr || len == 0U || protocol_error_) {
        return;
    }
    rx_buf_.insert(rx_buf_.end(), data, data + len);
}

size_t Rfc6455FrameParser::buffered_bytes() const noexcept {
    return available();
}

void Rfc6455FrameParser::compact_if_needed() {
    if (rx_offset_ == rx_buf_.size()) {
        rx_buf_.clear();
        rx_offset_ = 0;
    } else if (rx_offset_ >= 65536U) {
        rx_buf_.erase(
            rx_buf_.begin(),
            rx_buf_.begin() + static_cast<std::ptrdiff_t>(rx_offset_));
        rx_offset_ = 0;
    }
}

Rfc6455ParseResult Rfc6455FrameParser::validate_and_prepare_payload() {
    if (current_is_control_) {
        if (current_opcode_ == 0x8U && current_payload_len_ == 1ULL) {
            return Rfc6455ParseResult::kProtocolError;
        }
        control_payload_.clear();
        if (current_payload_len_ > 0ULL) {
            control_payload_.reserve(static_cast<size_t>(current_payload_len_));
        }
        return Rfc6455ParseResult::kFrameReady;
    }

    if (current_payload_len_ > static_cast<uint64_t>(kMaxMessageBytes)) {
        return Rfc6455ParseResult::kProtocolError;
    }
    const size_t frame_len = static_cast<size_t>(current_payload_len_);
    if (frame_len > kMaxMessageBytes - active_data_bytes_) {
        return Rfc6455ParseResult::kProtocolError;
    }
    if (current_opcode_ == 0x1U || current_opcode_ == 0x2U) {
        active_data_opcode_ = current_opcode_;
    }
    return Rfc6455ParseResult::kFrameReady;
}

Rfc6455ParseResult Rfc6455FrameParser::next_frame(Rfc6455Frame& out_frame) {
    if (protocol_error_) {
        return Rfc6455ParseResult::kProtocolError;
    }

    while (true) {
        switch (phase_) {
            case Phase::kReadBaseHeader: {
                if (available() < 2U) {
                    compact_if_needed();
                    return Rfc6455ParseResult::kNeedMoreData;
                }
                const uint8_t b0 = rx_buf_[rx_offset_];
                const uint8_t b1 = rx_buf_[rx_offset_ + 1U];
                rx_offset_ += 2U;

                const bool fin = (b0 & 0x80U) != 0U;
                const uint8_t rsv = static_cast<uint8_t>(b0 & 0x70U);
                const uint8_t opcode = static_cast<uint8_t>(b0 & 0x0FU);
                const bool masked = (b1 & 0x80U) != 0U;
                const uint8_t len7 = static_cast<uint8_t>(b1 & 0x7FU);

                if (rsv != 0U || masked) {
                    protocol_error_ = true;
                    return Rfc6455ParseResult::kProtocolError;
                }
                const bool valid_opcode =
                    (opcode == 0x0U || opcode == 0x1U || opcode == 0x2U ||
                     opcode == 0x8U || opcode == 0x9U || opcode == 0xAU);
                if (!valid_opcode) {
                    protocol_error_ = true;
                    return Rfc6455ParseResult::kProtocolError;
                }

                const bool is_control = (opcode & 0x08U) != 0U;
                if (is_control) {
                    if (!fin || len7 > 125U) {
                        protocol_error_ = true;
                        return Rfc6455ParseResult::kProtocolError;
                    }
                } else {
                    if (opcode == 0x0U) {
                        if (!has_active_data_msg_) {
                            protocol_error_ = true;
                            return Rfc6455ParseResult::kProtocolError;
                        }
                    } else {
                        if (has_active_data_msg_) {
                            protocol_error_ = true;
                            return Rfc6455ParseResult::kProtocolError;
                        }
                    }
                }

                current_fin_ = fin;
                current_opcode_ = opcode;
                current_is_control_ = is_control;
                current_frame_received_ = 0;

                if (len7 <= 125U) {
                    current_payload_len_ = len7;
                    if (validate_and_prepare_payload() == Rfc6455ParseResult::kProtocolError) {
                        protocol_error_ = true;
                        return Rfc6455ParseResult::kProtocolError;
                    }
                    phase_ = Phase::kReadPayload;
                } else if (len7 == 126U) {
                    phase_ = Phase::kReadExtendedLen16;
                } else {
                    phase_ = Phase::kReadExtendedLen64;
                }
                break;
            }

            case Phase::kReadExtendedLen16: {
                if (available() < 2U) {
                    compact_if_needed();
                    return Rfc6455ParseResult::kNeedMoreData;
                }
                const uint64_t ext =
                    (static_cast<uint64_t>(rx_buf_[rx_offset_]) << 8U) |
                    static_cast<uint64_t>(rx_buf_[rx_offset_ + 1U]);
                rx_offset_ += 2U;
                if (ext < 126ULL) {
                    protocol_error_ = true;
                    return Rfc6455ParseResult::kProtocolError;
                }
                current_payload_len_ = ext;
                if (validate_and_prepare_payload() == Rfc6455ParseResult::kProtocolError) {
                    protocol_error_ = true;
                    return Rfc6455ParseResult::kProtocolError;
                }
                phase_ = Phase::kReadPayload;
                break;
            }

            case Phase::kReadExtendedLen64: {
                if (available() < 8U) {
                    compact_if_needed();
                    return Rfc6455ParseResult::kNeedMoreData;
                }
                if ((rx_buf_[rx_offset_] & 0x80U) != 0U) {
                    protocol_error_ = true;
                    return Rfc6455ParseResult::kProtocolError;
                }
                uint64_t ext = 0;
                for (size_t i = 0; i < 8U; ++i) {
                    ext = (ext << 8U) | static_cast<uint64_t>(rx_buf_[rx_offset_ + i]);
                }
                rx_offset_ += 8U;
                if (ext < 65536ULL) {
                    protocol_error_ = true;
                    return Rfc6455ParseResult::kProtocolError;
                }
                current_payload_len_ = ext;
                if (validate_and_prepare_payload() == Rfc6455ParseResult::kProtocolError) {
                    protocol_error_ = true;
                    return Rfc6455ParseResult::kProtocolError;
                }
                phase_ = Phase::kReadPayload;
                break;
            }

            case Phase::kReadPayload: {
                if (current_frame_received_ < current_payload_len_) {
                    if (available() == 0U) {
                        compact_if_needed();
                        return Rfc6455ParseResult::kNeedMoreData;
                    }
                    const size_t need =
                        static_cast<size_t>(current_payload_len_) - current_frame_received_;
                    const size_t take = std::min(available(), need);
                    const char* ptr =
                        reinterpret_cast<const char*>(rx_buf_.data() + rx_offset_);
                    if (current_is_control_) {
                        control_payload_.append(ptr, take);
                    } else {
                        active_data_bytes_ += take;
                        if (active_data_opcode_ == 0x1U) {
                            data_msg_buffer_.append(ptr, take);
                        }
                    }
                    rx_offset_ += take;
                    current_frame_received_ += take;
                    if (current_frame_received_ < current_payload_len_) {
                        compact_if_needed();
                        return Rfc6455ParseResult::kNeedMoreData;
                    }
                }

                phase_ = Phase::kReadBaseHeader;
                if (current_is_control_) {
                    out_frame.opcode = static_cast<Rfc6455Opcode>(current_opcode_);
                    out_frame.payload = std::move(control_payload_);
                    control_payload_.clear();
                    compact_if_needed();
                    return Rfc6455ParseResult::kFrameReady;
                }

                if (!current_fin_) {
                    has_active_data_msg_ = true;
                    break;
                }

                out_frame.opcode = static_cast<Rfc6455Opcode>(active_data_opcode_);
                out_frame.payload =
                    (active_data_opcode_ == 0x1U) ? std::move(data_msg_buffer_) : std::string{};
                data_msg_buffer_.clear();
                has_active_data_msg_ = false;
                active_data_opcode_ = 0;
                active_data_bytes_ = 0;
                compact_if_needed();
                return Rfc6455ParseResult::kFrameReady;
            }
        }
    }
}

}  // namespace spotify::connectstate
