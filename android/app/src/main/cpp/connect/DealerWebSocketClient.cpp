// Replicated from liborbit-jni-spotify.so (Dealer WebSocket client & Connect-State dispatcher):
// - Binary symbols / offsets:
//   - Connect-State 12 dealer topics @ 0xdb4d9c..0xdb50c0 (liborbit-jni-spotify.so):
//     hm://connect-state/v1/cluster (0x37818e -> 0xdb7870),
//     hm://connect-state/v1/connect/volume (0x3475c7 -> 0xdb7b3c),
//     hm://connect-state/v1/connect/logout (0x33fdab -> 0xdb7e88),
//     hm://connect-state/v1/connect/set_backend_metadata (0x390dbd -> 0xdb7f88),
//     hm://connect-state/v1/group/add-device (0x360f80 -> 0xdb8394),
//     hm://connect-state/v1/group/remove-device (0x36def9 -> 0xdb85ec),
//     hm://connect-state/v1/group/delete (0x394683 -> 0xdb8844),
//     hm://connect-state/v1/group/resync (0x37be33 -> 0xdb8a98),
//     hm://connect-state/v1/player/command (0x374ed7 -> 0xdb8ccc),
//     hm://connect-state/v1/ping (0x39e37a -> 0xdb93cc -> {"success": true }),
//     hm://connect-state/v1/connect/proxy_transfer (0x35a05a -> 0xdb9424),
//     hm://connect-state/v1/connect/proxy_wake (0x33fdd0 -> 0xdb9828)
//   - dealerPingTime = 30000ms (0x7530)
//   - Spotify-Connection-Id / X-Spotify-Connection-Id header extraction (0x3af6a4, 0x39c1c3)
//   - Base64 + zlib "compressed" player command envelope & gzip protobuf decompression (0xdba108)
//   - WakeOnLanInfo validation (mac.size() == 6, port < 65536) & 102-byte UDP magic packet
//   - WebSocketConnectRequestUrlAccessToken proto string @ 0x16e9168
// - Java counterparts:
//   - com/spotify/connectivity/AuthenticatedScopeConfiguration.java (dealerPingTime)
//   - com/comscore/util/log/LogLevel.java (NONE = 30000)
//   - com/spotify/connectivity/NativeAuthenticatedScope.java
//   - com/spotify/connectivity/websocket/esperanto/proto/EsWebsocketConnectRequest$WebSocketConnectRequest.java
//   - p199p/l25.java, p199p/C1637b6.java

#include "DealerWebSocketClient.h"

#include <arpa/inet.h>
#include <curl/curl.h>
#include <dirent.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <poll.h>
#include <sys/eventfd.h>
#include <sys/random.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <unistd.h>
#include <zlib.h>

#ifdef __ANDROID__
#include <android/log.h>
#define DEALER_LOGI(...) __android_log_print(ANDROID_LOG_INFO, "MusifyDealerWS", __VA_ARGS__)
#define DEALER_LOGW(...) __android_log_print(ANDROID_LOG_WARN, "MusifyDealerWS", __VA_ARGS__)
#define DEALER_LOGE(...) __android_log_print(ANDROID_LOG_ERROR, "MusifyDealerWS", __VA_ARGS__)
#else
#include <cstdio>
#define DEALER_LOGI(...) ((void)0)
#define DEALER_LOGW(...) ((void)0)
#define DEALER_LOGE(...) ((void)0)
#endif

#include <algorithm>
#include <array>
#include <cctype>
#include <cerrno>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <limits>
#include <utility>

namespace spotify::connectstate {

namespace json {

namespace {

constexpr int kMaxJsonDepth = 64;

class JsonParser {
public:
    explicit JsonParser(std::string_view input) : input_(input) {}

    std::optional<JsonValue> parse() {
        skip_ws();
        auto value = parse_value(0);
        if (!value.has_value()) {
            return std::nullopt;
        }
        skip_ws();
        if (pos_ != input_.size()) {
            return std::nullopt;
        }
        return value;
    }

private:
    void skip_ws() {
        while (pos_ < input_.size()) {
            const char c = input_[pos_];
            if (c == ' ' || c == '\t' || c == '\r' || c == '\n') {
                ++pos_;
            } else {
                break;
            }
        }
    }

    bool consume(char expected) {
        if (pos_ < input_.size() && input_[pos_] == expected) {
            ++pos_;
            return true;
        }
        return false;
    }

    static void append_utf8(uint32_t cp, std::string& out) {
        if (cp <= 0x7FU) {
            out.push_back(static_cast<char>(cp));
        } else if (cp <= 0x7FFU) {
            out.push_back(static_cast<char>(0xC0U | ((cp >> 6) & 0x1FU)));
            out.push_back(static_cast<char>(0x80U | (cp & 0x3FU)));
        } else if (cp <= 0xFFFFU) {
            out.push_back(static_cast<char>(0xE0U | ((cp >> 12) & 0x0FU)));
            out.push_back(static_cast<char>(0x80U | ((cp >> 6) & 0x3FU)));
            out.push_back(static_cast<char>(0x80U | (cp & 0x3FU)));
        } else if (cp <= 0x10FFFFU) {
            out.push_back(static_cast<char>(0xF0U | ((cp >> 18) & 0x07U)));
            out.push_back(static_cast<char>(0x80U | ((cp >> 12) & 0x3FU)));
            out.push_back(static_cast<char>(0x80U | ((cp >> 6) & 0x3FU)));
            out.push_back(static_cast<char>(0x80U | (cp & 0x3FU)));
        }
    }

    bool parse_hex4(uint32_t& out) {
        if (pos_ + 4 > input_.size()) {
            return false;
        }
        uint32_t val = 0;
        for (int i = 0; i < 4; ++i) {
            const unsigned char c = static_cast<unsigned char>(input_[pos_++]);
            val <<= 4;
            if (c >= '0' && c <= '9') {
                val |= static_cast<uint32_t>(c - '0');
            } else if (c >= 'a' && c <= 'f') {
                val |= static_cast<uint32_t>(c - 'a' + 10);
            } else if (c >= 'A' && c <= 'F') {
                val |= static_cast<uint32_t>(c - 'A' + 10);
            } else {
                return false;
            }
        }
        out = val;
        return true;
    }

    std::optional<std::string> parse_string_literal() {
        if (!consume('"')) {
            return std::nullopt;
        }
        std::string out;
        while (pos_ < input_.size()) {
            const unsigned char c = static_cast<unsigned char>(input_[pos_++]);
            if (c == '"') {
                return out;
            }
            if (c < 0x20U) {
                return std::nullopt;
            }
            if (c != '\\') {
                out.push_back(static_cast<char>(c));
                continue;
            }
            if (pos_ >= input_.size()) {
                return std::nullopt;
            }
            const char esc = input_[pos_++];
            switch (esc) {
                case '"': out.push_back('"'); break;
                case '\\': out.push_back('\\'); break;
                case '/': out.push_back('/'); break;
                case 'b': out.push_back('\b'); break;
                case 'f': out.push_back('\f'); break;
                case 'n': out.push_back('\n'); break;
                case 'r': out.push_back('\r'); break;
                case 't': out.push_back('\t'); break;
                case 'u': {
                    uint32_t cp = 0;
                    if (!parse_hex4(cp)) {
                        return std::nullopt;
                    }
                    if (cp >= 0xD800U && cp <= 0xDBFFU) {
                        if (pos_ + 2 <= input_.size() &&
                            input_[pos_] == '\\' && input_[pos_ + 1] == 'u') {
                            pos_ += 2;
                            uint32_t low = 0;
                            if (!parse_hex4(low)) {
                                return std::nullopt;
                            }
                            if (low >= 0xDC00U && low <= 0xDFFFU) {
                                cp = 0x10000U + (((cp - 0xD800U) << 10) | (low - 0xDC00U));
                            } else {
                                return std::nullopt;
                            }
                        } else {
                            return std::nullopt;
                        }
                    }
                    append_utf8(cp, out);
                    break;
                }
                default:
                    return std::nullopt;
            }
        }
        return std::nullopt;
    }

    std::optional<JsonValue> parse_number() {
        const size_t start = pos_;
        if (input_[pos_] == '-') {
            ++pos_;
        }
        if (pos_ >= input_.size()) {
            return std::nullopt;
        }
        if (input_[pos_] == '0') {
            ++pos_;
        } else if (input_[pos_] >= '1' && input_[pos_] <= '9') {
            while (pos_ < input_.size() &&
                   input_[pos_] >= '0' && input_[pos_] <= '9') {
                ++pos_;
            }
        } else {
            return std::nullopt;
        }

        bool is_float = false;
        if (pos_ < input_.size() && input_[pos_] == '.') {
            is_float = true;
            ++pos_;
            if (pos_ >= input_.size() ||
                input_[pos_] < '0' || input_[pos_] > '9') {
                return std::nullopt;
            }
            while (pos_ < input_.size() &&
                   input_[pos_] >= '0' && input_[pos_] <= '9') {
                ++pos_;
            }
        }
        if (pos_ < input_.size() && (input_[pos_] == 'e' || input_[pos_] == 'E')) {
            is_float = true;
            ++pos_;
            if (pos_ < input_.size() && (input_[pos_] == '+' || input_[pos_] == '-')) {
                ++pos_;
            }
            if (pos_ >= input_.size() ||
                input_[pos_] < '0' || input_[pos_] > '9') {
                return std::nullopt;
            }
            while (pos_ < input_.size() &&
                   input_[pos_] >= '0' && input_[pos_] <= '9') {
                ++pos_;
            }
        }

        std::string token(input_.substr(start, pos_ - start));
        JsonValue val;
        val.type = JsonValue::Type::kNumber;

        char* endptr = nullptr;
        errno = 0;
        const double d = std::strtod(token.c_str(), &endptr);
        if (endptr != token.c_str() + token.size() || !std::isfinite(d)) {
            return std::nullopt;
        }
        val.number_value = d;

        if (!is_float) {
            char* iend = nullptr;
            errno = 0;
            const long long iv = std::strtoll(token.c_str(), &iend, 10);
            if (errno == 0 && iend == token.c_str() + token.size()) {
                val.int_value = static_cast<int64_t>(iv);
                val.is_integer = true;
            }
        }
        return val;
    }

    std::optional<JsonValue> parse_value(int depth) {
        if (depth > kMaxJsonDepth) {
            return std::nullopt;
        }
        skip_ws();
        if (pos_ >= input_.size()) {
            return std::nullopt;
        }
        const char c = input_[pos_];
        if (c == 'n') {
            if (input_.substr(pos_, 4) == "null") {
                pos_ += 4;
                JsonValue v;
                v.type = JsonValue::Type::kNull;
                return v;
            }
            return std::nullopt;
        }
        if (c == 't') {
            if (input_.substr(pos_, 4) == "true") {
                pos_ += 4;
                JsonValue v;
                v.type = JsonValue::Type::kBool;
                v.bool_value = true;
                return v;
            }
            return std::nullopt;
        }
        if (c == 'f') {
            if (input_.substr(pos_, 5) == "false") {
                pos_ += 5;
                JsonValue v;
                v.type = JsonValue::Type::kBool;
                v.bool_value = false;
                return v;
            }
            return std::nullopt;
        }
        if (c == '"') {
            auto s = parse_string_literal();
            if (!s.has_value()) {
                return std::nullopt;
            }
            JsonValue v;
            v.type = JsonValue::Type::kString;
            v.string_value = std::move(*s);
            return v;
        }
        if (c == '-' || (c >= '0' && c <= '9')) {
            return parse_number();
        }
        if (c == '[') {
            ++pos_;
            JsonValue arr;
            arr.type = JsonValue::Type::kArray;
            skip_ws();
            if (consume(']')) {
                return arr;
            }
            while (true) {
                auto elem = parse_value(depth + 1);
                if (!elem.has_value()) {
                    return std::nullopt;
                }
                arr.array_value.push_back(std::move(*elem));
                skip_ws();
                if (consume(']')) {
                    return arr;
                }
                if (!consume(',')) {
                    return std::nullopt;
                }
            }
        }
        if (c == '{') {
            ++pos_;
            JsonValue obj;
            obj.type = JsonValue::Type::kObject;
            skip_ws();
            if (consume('}')) {
                return obj;
            }
            while (true) {
                skip_ws();
                auto key = parse_string_literal();
                if (!key.has_value()) {
                    return std::nullopt;
                }
                skip_ws();
                if (!consume(':')) {
                    return std::nullopt;
                }
                auto elem = parse_value(depth + 1);
                if (!elem.has_value()) {
                    return std::nullopt;
                }
                obj.object_value.insert_or_assign(std::move(*key), std::move(*elem));
                skip_ws();
                if (consume('}')) {
                    return obj;
                }
                if (!consume(',')) {
                    return std::nullopt;
                }
            }
        }
        return std::nullopt;
    }

    std::string_view input_;
    size_t pos_{0};
};

}  // namespace

const JsonValue* JsonValue::find(std::string_view key) const {
    if (type != Type::kObject) {
        return nullptr;
    }
    const auto it = object_value.find(key);
    if (it == object_value.end()) {
        return nullptr;
    }
    return &it->second;
}

std::optional<std::string> JsonValue::get_string(std::string_view key) const {
    const JsonValue* child = find(key);
    if (child == nullptr || !child->is_string()) {
        return std::nullopt;
    }
    return child->string_value;
}

std::optional<int64_t> JsonValue::get_int64(std::string_view key) const {
    const JsonValue* child = find(key);
    if (child == nullptr || !child->is_number()) {
        return std::nullopt;
    }
    if (child->is_integer) {
        return child->int_value;
    }
    if (!std::isfinite(child->number_value) ||
        child->number_value < static_cast<double>(std::numeric_limits<int64_t>::min()) ||
        child->number_value >= static_cast<double>(std::numeric_limits<int64_t>::max())) {
        return std::nullopt;
    }
    return static_cast<int64_t>(child->number_value);
}

std::optional<uint32_t> JsonValue::get_uint32(std::string_view key) const {
    const auto iv = get_int64(key);
    if (!iv.has_value() || *iv < 0 ||
        *iv > static_cast<int64_t>(std::numeric_limits<uint32_t>::max())) {
        return std::nullopt;
    }
    return static_cast<uint32_t>(*iv);
}

std::optional<double> JsonValue::get_double(std::string_view key) const {
    const JsonValue* child = find(key);
    if (child == nullptr || !child->is_number()) {
        return std::nullopt;
    }
    return child->number_value;
}

std::optional<bool> JsonValue::get_bool(std::string_view key) const {
    const JsonValue* child = find(key);
    if (child == nullptr || !child->is_bool()) {
        return std::nullopt;
    }
    return child->bool_value;
}

std::optional<JsonValue> parse_json(std::string_view text) {
    JsonParser parser(text);
    return parser.parse();
}

std::string json_escape(std::string_view text) {
    std::string out;
    out.reserve(text.size() + 8);
    for (const unsigned char c : text) {
        switch (c) {
            case '"': out.append("\\\""); break;
            case '\\': out.append("\\\\"); break;
            case '\b': out.append("\\b"); break;
            case '\f': out.append("\\f"); break;
            case '\n': out.append("\\n"); break;
            case '\r': out.append("\\r"); break;
            case '\t': out.append("\\t"); break;
            default:
                if (c < 0x20U) {
                    char buf[8];
                    std::snprintf(buf, sizeof(buf), "\\u%04x", static_cast<unsigned int>(c));
                    out.append(buf);
                } else {
                    out.push_back(static_cast<char>(c));
                }
                break;
        }
    }
    return out;
}

std::string serialize_json(const JsonValue& value) {
    switch (value.type) {
        case JsonValue::Type::kNull:
            return "null";
        case JsonValue::Type::kBool:
            return value.bool_value ? "true" : "false";
        case JsonValue::Type::kNumber: {
            if (value.is_integer) {
                return std::to_string(value.int_value);
            }
            char buf[64];
            std::snprintf(buf, sizeof(buf), "%.15g", value.number_value);
            return std::string(buf);
        }
        case JsonValue::Type::kString:
            return "\"" + json_escape(value.string_value) + "\"";
        case JsonValue::Type::kArray: {
            std::string out = "[";
            for (size_t i = 0; i < value.array_value.size(); ++i) {
                if (i > 0) {
                    out.push_back(',');
                }
                out.append(serialize_json(value.array_value[i]));
            }
            out.push_back(']');
            return out;
        }
        case JsonValue::Type::kObject: {
            std::string out = "{";
            bool first = true;
            for (const auto& [k, v] : value.object_value) {
                if (!first) {
                    out.push_back(',');
                }
                first = false;
                out.push_back('"');
                out.append(json_escape(k));
                out.append("\":");
                out.append(serialize_json(v));
            }
            out.push_back('}');
            return out;
        }
    }
    return "null";
}

}  // namespace json

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

namespace {

std::string to_lower_ascii(std::string_view input) {
    std::string out(input);
    for (char& c : out) {
        c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    }
    return out;
}

std::string_view trim_ascii_ws(std::string_view input) {
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

constexpr uint32_t rol32(uint32_t value, uint32_t bits) noexcept {
    return (value << bits) | (value >> (32U - bits));
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

bool build_ws_connect_params(
    std::string_view ws_url,
    std::string& out_connect_url,
    std::string& out_host_header,
    std::string& out_request_target) {
    bool is_tls = false;
    if (ws_url.size() >= 6 && to_lower_ascii(ws_url.substr(0, 6)) == "wss://") {
        is_tls = true;
        out_connect_url = "https://";
        out_connect_url.append(ws_url.substr(6));
    } else if (ws_url.size() >= 5 && to_lower_ascii(ws_url.substr(0, 5)) == "ws://") {
        is_tls = false;
        out_connect_url = "http://";
        out_connect_url.append(ws_url.substr(5));
    } else if (ws_url.size() >= 8 && to_lower_ascii(ws_url.substr(0, 8)) == "https://") {
        is_tls = true;
        out_connect_url.assign(ws_url);
    } else if (ws_url.size() >= 7 && to_lower_ascii(ws_url.substr(0, 7)) == "http://") {
        is_tls = false;
        out_connect_url.assign(ws_url);
    } else {
        return false;
    }

    CURLU* cu = curl_url();
    if (cu == nullptr) {
        return false;
    }
    if (curl_url_set(cu, CURLUPART_URL, out_connect_url.c_str(), 0) != CURLUE_OK) {
        curl_url_cleanup(cu);
        return false;
    }

    char* host_cstr = nullptr;
    if (curl_url_get(cu, CURLUPART_HOST, &host_cstr, 0) != CURLUE_OK || host_cstr == nullptr) {
        if (host_cstr != nullptr) {
            curl_free(host_cstr);
        }
        curl_url_cleanup(cu);
        return false;
    }
    std::string host(host_cstr);
    curl_free(host_cstr);

    char* port_cstr = nullptr;
    std::string port;
    if (curl_url_get(cu, CURLUPART_PORT, &port_cstr, 0) == CURLUE_OK && port_cstr != nullptr) {
        port.assign(port_cstr);
        curl_free(port_cstr);
    } else if (port_cstr != nullptr) {
        curl_free(port_cstr);
    }

    char* path_cstr = nullptr;
    std::string path = "/";
    if (curl_url_get(cu, CURLUPART_PATH, &path_cstr, 0) == CURLUE_OK && path_cstr != nullptr) {
        if (path_cstr[0] != '\0') {
            path.assign(path_cstr);
        }
        curl_free(path_cstr);
    } else if (path_cstr != nullptr) {
        curl_free(path_cstr);
    }

    char* query_cstr = nullptr;
    std::string query;
    if (curl_url_get(cu, CURLUPART_QUERY, &query_cstr, 0) == CURLUE_OK && query_cstr != nullptr) {
        query.assign(query_cstr);
        curl_free(query_cstr);
    } else if (query_cstr != nullptr) {
        curl_free(query_cstr);
    }

    curl_url_cleanup(cu);

    if (host.empty()) {
        return false;
    }
    if (host.find(':') != std::string::npos && host.front() != '[') {
        out_host_header = "[" + host + "]";
    } else {
        out_host_header = std::move(host);
    }
    const std::string_view default_port = is_tls ? "443" : "80";
    if (!port.empty() && port != default_port) {
        out_host_header.push_back(':');
        out_host_header.append(port);
    }

    out_request_target = std::move(path);
    if (!query.empty()) {
        out_request_target.push_back('?');
        out_request_target.append(query);
    }
    return true;
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

void extract_pem_certs_from_file(
    const std::string& path,
    std::string& out_bundle) {
    const int fd = ::open(path.c_str(), O_RDONLY | O_CLOEXEC);
    if (fd < 0) {
        return;
    }
    struct stat st{};
    if (::fstat(fd, &st) != 0 || !S_ISREG(st.st_mode) || st.st_size <= 0 || st.st_size > 262144) {
        ::close(fd);
        return;
    }
    std::string raw(static_cast<size_t>(st.st_size), '\0');
    size_t total_read = 0;
    while (total_read < raw.size()) {
        const ssize_t n = ::read(fd, raw.data() + total_read, raw.size() - total_read);
        if (n <= 0) {
            break;
        }
        total_read += static_cast<size_t>(n);
    }
    ::close(fd);
    raw.resize(total_read);

    static constexpr const char kBegin[] = "-----BEGIN CERTIFICATE-----";
    static constexpr const char kEnd[] = "-----END CERTIFICATE-----";
    size_t pos = 0;
    while (true) {
        const size_t b = raw.find(kBegin, pos);
        if (b == std::string::npos) {
            break;
        }
        const size_t e = raw.find(kEnd, b);
        if (e == std::string::npos) {
            break;
        }
        const size_t block_end = e + sizeof(kEnd) - 1;
        out_bundle.append(raw, b, block_end - b);
        out_bundle.push_back('\n');
        pos = block_end;
    }
}

std::string load_android_ca_bundle() {
    std::string bundle;
    static constexpr const char* kDirs[] = {
        "/apex/com.android.conscrypt/cacerts",
        "/system/etc/security/cacerts",
        "/data/misc/user/0/cacerts-added",
    };
    for (const char* dir_path : kDirs) {
        DIR* dir = ::opendir(dir_path);
        if (dir == nullptr) {
            continue;
        }
        while (struct dirent* entry = ::readdir(dir)) {
            if (entry->d_name[0] == '\0' || entry->d_name[0] == '.') {
                continue;
            }
            std::string full_path(dir_path);
            full_path.push_back('/');
            full_path.append(entry->d_name);
            extract_pem_certs_from_file(full_path, bundle);
        }
        ::closedir(dir);
    }
    return bundle;
}

}  // namespace

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
    size_t& out_header_bytes) {
    out_header_bytes = 0;
    const size_t hdr_end = buffer.find("\r\n\r\n");
    if (hdr_end == std::string_view::npos) {
        return buffer.size() > kMaxWsUpgradeHeaderBytes
                   ? HttpUpgradeParseResult::kProtocolError
                   : HttpUpgradeParseResult::kNeedMoreData;
    }
    out_header_bytes = hdr_end + 4U;
    if (out_header_bytes > kMaxWsUpgradeHeaderBytes) {
        return HttpUpgradeParseResult::kProtocolError;
    }

    const std::string_view block = buffer.substr(0, hdr_end);
    const size_t first_crlf = block.find("\r\n");
    const std::string_view status_line =
        (first_crlf == std::string_view::npos) ? block : block.substr(0, first_crlf);

    if (status_line.size() < 12U ||
        (status_line.substr(0, 9) != "HTTP/1.1 " && status_line.substr(0, 9) != "HTTP/1.0 ") ||
        status_line.substr(9, 3) != "101" ||
        (status_line.size() > 12U && status_line[12] != ' ')) {
        return HttpUpgradeParseResult::kProtocolError;
    }

    if (first_crlf == std::string_view::npos) {
        return HttpUpgradeParseResult::kProtocolError;
    }

    bool has_upgrade = false;
    bool has_connection_upgrade = false;
    bool saw_accept = false;
    bool accept_matches = false;
    bool has_non_empty_extensions = false;

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

    if (!has_upgrade || !has_connection_upgrade || !accept_matches || has_non_empty_extensions) {
        return HttpUpgradeParseResult::kProtocolError;
    }
    return HttpUpgradeParseResult::kOk;
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

DealerWebSocketClient::DealerWebSocketClient(
    network::AuthSessionStore& auth_store,
    std::string dealer_base_url)
    : auth_store_(auth_store),
      dealer_base_url_(std::move(dealer_base_url)) {}

DealerWebSocketClient::~DealerWebSocketClient() {
    stop();
    close_wakeup_fd();
}

void DealerWebSocketClient::set_callbacks(DealerCallbacks callbacks) {
    std::lock_guard<std::mutex> lock(callbacks_mutex_);
    callbacks_ = std::move(callbacks);
}

void DealerWebSocketClient::start() {
    if (is_on_worker_thread()) {
        return;
    }

    std::lock_guard<std::mutex> lifecycle_lock(lifecycle_mutex_);
    std::thread stale_thread;
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (running_) {
            return;
        }
        if (worker_thread_.joinable()) {
            stale_thread = std::move(worker_thread_);
        }
    }
    if (stale_thread.joinable()) {
        stale_thread.join();
    }

    {
        std::lock_guard<std::mutex> lock(outbound_mutex_);
        outbound_queue_.clear();
    }
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        stop_requested_ = false;
        reconnect_requested_ = false;
        connection_id_.clear();
        running_ = true;
    }

    open_wakeup_fd();
    worker_thread_ = std::thread(&DealerWebSocketClient::worker_loop, this);
}

void DealerWebSocketClient::stop() {
    if (is_on_worker_thread()) {
        {
            std::lock_guard<std::mutex> lock(state_mutex_);
            if (!running_) {
                return;
            }
            stop_requested_ = true;
            connection_id_.clear();
        }
        state_cv_.notify_all();
        wake_io_loop();
        return;
    }

    std::lock_guard<std::mutex> lifecycle_lock(lifecycle_mutex_);
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (!running_ && !worker_thread_.joinable()) {
            return;
        }
        stop_requested_ = true;
        connection_id_.clear();
    }
    state_cv_.notify_all();
    wake_io_loop();

    if (worker_thread_.joinable()) {
        worker_thread_.join();
    }

    {
        std::lock_guard<std::mutex> lock(outbound_mutex_);
        outbound_queue_.clear();
    }
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        running_ = false;
        stop_requested_ = false;
        reconnect_requested_ = false;
        connection_id_.clear();
        state_ = DealerConnectionState::kDisconnected;
    }
    close_wakeup_fd();
}

void DealerWebSocketClient::reconnect_now() {
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (!running_ || stop_requested_) {
            return;
        }
        reconnect_requested_ = true;
    }
    state_cv_.notify_all();
    wake_io_loop();
}

DealerConnectionState DealerWebSocketClient::connection_state() const {
    std::lock_guard<std::mutex> lock(state_mutex_);
    return state_;
}

std::string DealerWebSocketClient::connection_id() const {
    std::lock_guard<std::mutex> lock(state_mutex_);
    return connection_id_;
}

bool DealerWebSocketClient::is_running() const {
    std::lock_guard<std::mutex> lock(state_mutex_);
    return running_;
}

bool DealerWebSocketClient::is_on_worker_thread() const noexcept {
    const auto tid = worker_thread_id_.load(std::memory_order_acquire);
    return tid != std::thread::id{} && tid == std::this_thread::get_id();
}

bool DealerWebSocketClient::send_text(std::string text) {
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (!running_ || stop_requested_) {
            return false;
        }
    }
    {
        std::lock_guard<std::mutex> lock(outbound_mutex_);
        outbound_queue_.push_back(std::move(text));
    }
    wake_io_loop();
    return true;
}

bool DealerWebSocketClient::send_reply(std::string_view key, bool success) {
    if (key.empty()) {
        return false;
    }
    // Exact ping/reply JSON expected by Spotify Dealer: {"success": true }
    std::string body = "{\"type\":\"reply\",\"key\":\"";
    body.append(json::json_escape(key));
    body.append("\",\"payload\":{\"success\": ");
    body.append(success ? "true" : "false");
    body.append(" }}");
    return send_text(std::move(body));
}

void DealerWebSocketClient::open_wakeup_fd() {
    std::lock_guard<std::mutex> lock(wakeup_mutex_);
    const int existing = wakeup_fd_.load(std::memory_order_relaxed);
    if (existing >= 0) {
        uint64_t drained = 0;
        while (true) {
            const ssize_t rc = ::read(existing, &drained, sizeof(drained));
            if (rc > 0) {
                continue;
            }
            if (rc < 0 && errno == EINTR) {
                continue;
            }
            break;
        }
        return;
    }
    const int fd = ::eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    wakeup_fd_.store(fd, std::memory_order_release);
}

void DealerWebSocketClient::wake_io_loop() {
    std::lock_guard<std::mutex> lock(wakeup_mutex_);
    const int fd = wakeup_fd_.load(std::memory_order_acquire);
    if (fd >= 0) {
        const uint64_t val = 1;
        const ssize_t ignored = ::write(fd, &val, sizeof(val));
        (void)ignored;
    }
}

void DealerWebSocketClient::close_wakeup_fd() {
    std::lock_guard<std::mutex> lock(wakeup_mutex_);
    const int fd = wakeup_fd_.exchange(-1, std::memory_order_acq_rel);
    if (fd >= 0) {
        ::close(fd);
    }
}

void DealerWebSocketClient::set_state(DealerConnectionState state) {
    DealerCallbacks cb_copy;
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        if (state_ == state) {
            return;
        }
        state_ = state;
        if (state != DealerConnectionState::kConnected) {
            connection_id_.clear();
        }
    }
    {
        std::lock_guard<std::mutex> lock(callbacks_mutex_);
        cb_copy = callbacks_;
    }
    if (cb_copy.on_connection_state_changed) {
        cb_copy.on_connection_state_changed(state);
    }
}

std::string DealerWebSocketClient::build_connection_url(
    std::string_view base_url,
    std::string_view access_token) {
    std::string url(base_url);
    if (url.empty()) {
        url = kDefaultDealerWsUrl;
    }

    char* escaped = curl_easy_escape(
        nullptr,
        access_token.data(),
        static_cast<int>(access_token.size()));
    std::string encoded_token;
    if (escaped != nullptr) {
        encoded_token.assign(escaped);
        curl_free(escaped);
    } else {
        encoded_token.assign(access_token);
    }

    if (url.find('?') != std::string::npos) {
        if (url.back() != '&' && url.back() != '?') {
            url.push_back('&');
        }
    } else {
        if (url.back() != '/') {
            url.push_back('/');
        }
        url.push_back('?');
    }
    url.append("access_token=");
    url.append(encoded_token);
    return url;
}

std::optional<DealerEnvelope> DealerWebSocketClient::parse_dealer_envelope(
    std::string_view text) {
    auto parsed = json::parse_json(text);
    if (!parsed.has_value() || !parsed->is_object()) {
        return std::nullopt;
    }

    DealerEnvelope env;
    if (auto t = parsed->get_string("type")) {
        env.type = std::move(*t);
    }
    if (auto u = parsed->get_string("uri")) {
        env.uri = std::move(*u);
    }
    if (auto mi = parsed->get_string("message_ident")) {
        env.message_ident = std::move(*mi);
    }
    if (auto k = parsed->get_string("key")) {
        env.key = std::move(*k);
    }
    if (auto m = parsed->get_string("method")) {
        env.method = std::move(*m);
    }

    if (const json::JsonValue* hdrs = parsed->find("headers");
        hdrs != nullptr && hdrs->is_object()) {
        for (const auto& [hk, hv] : hdrs->object_value) {
            if (hv.is_string()) {
                env.headers.emplace(hk, hv.string_value);
            }
        }
    }

    if (const json::JsonValue* payloads = parsed->find("payloads");
        payloads != nullptr && payloads->is_array()) {
        for (const auto& elem : payloads->array_value) {
            if (elem.is_string()) {
                env.payload_strings.push_back(elem.string_value);
            } else if (elem.is_object() || elem.is_array()) {
                env.payload_strings.push_back(json::serialize_json(elem));
            }
        }
    }

    if (const json::JsonValue* payload = parsed->find("payload"); payload != nullptr) {
        if (payload->is_object()) {
            env.payload_json = *payload;
        } else if (payload->is_string()) {
            env.payload_strings.push_back(payload->string_value);
            if (auto sub = json::parse_json(payload->string_value);
                sub.has_value() && sub->is_object()) {
                env.payload_json = std::move(*sub);
            }
        }
    }

    return env;
}

std::optional<std::vector<uint8_t>> DealerWebSocketClient::decode_protobuf_payload(
    const DealerEnvelope& envelope) {
    if (envelope.payload_strings.empty()) {
        return std::nullopt;
    }
    const std::string& encoded = envelope.payload_strings.front();
    if (encoded.empty()) {
        return std::vector<uint8_t>{};
    }

    auto decoded = base64_decode(encoded);
    if (!decoded.has_value()) {
        return std::nullopt;
    }

    const auto te = find_header_ci(envelope.headers, "Transfer-Encoding");
    const auto ce = find_header_ci(envelope.headers, "Content-Encoding");
    const bool header_gzip =
        (te.has_value() && to_lower_ascii(*te).find("gzip") != std::string::npos) ||
        (ce.has_value() && to_lower_ascii(*ce).find("gzip") != std::string::npos);
    const bool magic_gzip =
        decoded->size() >= 2 && (*decoded)[0] == 0x1FU && (*decoded)[1] == 0x8BU;

    if (header_gzip || magic_gzip) {
        return zlib_decompress(decoded->data(), decoded->size());
    }
    return decoded;
}

std::optional<DealerPlayerCommand> DealerWebSocketClient::parse_player_command_envelope(
    const DealerEnvelope& envelope) {
    std::optional<json::JsonValue> payload_obj = envelope.payload_json;
    if (!payload_obj.has_value() && !envelope.payload_strings.empty()) {
        payload_obj = json::parse_json(envelope.payload_strings.front());
    }
    if (!payload_obj.has_value() || !payload_obj->is_object()) {
        return std::nullopt;
    }

    if (auto compressed_b64 = payload_obj->get_string("compressed")) {
        auto raw_bytes = base64_decode(*compressed_b64);
        if (!raw_bytes.has_value()) {
            return std::nullopt;
        }
        auto inflated = zlib_decompress(raw_bytes->data(), raw_bytes->size());
        if (!inflated.has_value()) {
            return std::nullopt;
        }
        const std::string_view inflated_sv(
            reinterpret_cast<const char*>(inflated->data()),
            inflated->size());
        auto parsed_inner = json::parse_json(inflated_sv);
        if (!parsed_inner.has_value() || !parsed_inner->is_object()) {
            return std::nullopt;
        }
        payload_obj = std::move(*parsed_inner);
    }

    DealerPlayerCommand cmd;
    cmd.message_ident = envelope.message_ident.empty() ? envelope.uri : envelope.message_ident;
    cmd.key = envelope.key;
    if (auto mid = payload_obj->get_uint32("message_id")) {
        cmd.message_id = *mid;
    }
    if (auto sender = payload_obj->get_string("sent_by_device_id")) {
        cmd.sent_by_device_id = std::move(*sender);
    }

    const json::JsonValue* command_node = payload_obj->find("command");
    if (command_node != nullptr && command_node->is_object()) {
        if (auto ep = command_node->get_string("endpoint")) {
            cmd.endpoint = std::move(*ep);
        }
        cmd.command_json = json::serialize_json(*command_node);
    } else {
        if (auto ep = payload_obj->get_string("endpoint")) {
            cmd.endpoint = std::move(*ep);
        }
        cmd.command_json = json::serialize_json(*payload_obj);
    }
    return cmd;
}

bool DealerWebSocketClient::validate_wol_info(const WakeOnLanInfo& info) {
    if (info.mac_address.size() != 6) {
        return false;
    }
    if (info.port >= 65536U) {
        return false;
    }
    return true;
}

std::optional<std::vector<uint8_t>> DealerWebSocketClient::build_wol_magic_packet(
    const WakeOnLanInfo& info) {
    if (!validate_wol_info(info)) {
        return std::nullopt;
    }
    std::vector<uint8_t> packet;
    packet.reserve(102);
    for (int i = 0; i < 6; ++i) {
        packet.push_back(0xFFU);
    }
    for (int rep = 0; rep < 16; ++rep) {
        for (const uint8_t b : info.mac_address) {
            packet.push_back(b);
        }
    }
    return packet;
}

bool DealerWebSocketClient::send_wol_magic_packet(const WakeOnLanInfo& info) {
    auto packet = build_wol_magic_packet(info);
    if (!packet.has_value()) {
        return false;
    }
    const uint16_t target_port = info.port > 0 ? static_cast<uint16_t>(info.port) : 9U;

    const int sock = ::socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC, IPPROTO_UDP);
    if (sock < 0) {
        return false;
    }

    int broadcast = 1;
    (void)::setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcast, sizeof(broadcast));

    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(target_port);
    addr.sin_addr.s_addr = htonl(INADDR_BROADCAST);

    const uint32_t attempts = std::max<uint32_t>(1U, std::min<uint32_t>(info.retries, 5U));
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
        }
    }
    ::close(sock);
    return any_sent;
}

bool DealerWebSocketClient::handle_incoming_text_message(std::string_view text) {
    return process_inbound_text_frame(text, nullptr);
}

bool DealerWebSocketClient::process_inbound_text_frame(
    std::string_view text,
    bool* out_received_pong) {
    if (text.empty()) {
        return true;
    }
    auto env = parse_dealer_envelope(text);
    if (!env.has_value()) {
        return false;
    }
    if (env->type == "pong") {
        if (out_received_pong != nullptr) {
            *out_received_pong = true;
        }
        return true;
    }
    dispatch_dealer_envelope(*env);
    return true;
}

void DealerWebSocketClient::dispatch_dealer_envelope(const DealerEnvelope& envelope) {
    DealerCallbacks cb_copy;
    {
        std::lock_guard<std::mutex> lock(callbacks_mutex_);
        cb_copy = callbacks_;
    }

    if (envelope.type == "pong" || envelope.type == "ping") {
        if (envelope.type == "ping") {
            (void)send_text("{\"type\":\"pong\"}");
        }
        return;
    }

    // Check connection ID in hm://pusher/v1/connections/... or header.
    auto conn_id_hdr = find_header_ci(envelope.headers, "Spotify-Connection-Id");
    if (!conn_id_hdr.has_value()) {
        conn_id_hdr = find_header_ci(envelope.headers, "X-Spotify-Connection-Id");
    }
    if (conn_id_hdr.has_value() && !conn_id_hdr->empty()) {
        bool changed = false;
        {
            std::lock_guard<std::mutex> lock(state_mutex_);
            if (connection_id_ != *conn_id_hdr) {
                connection_id_ = *conn_id_hdr;
                changed = true;
            }
        }
        if (changed && cb_copy.on_connection_id) {
            cb_copy.on_connection_id(*conn_id_hdr);
        }
    }

    const std::string_view topic =
        !envelope.message_ident.empty() ? std::string_view(envelope.message_ident)
                                        : std::string_view(envelope.uri);

    if (topic.rfind(kPusherConnectionsPrefix, 0) == 0 && conn_id_hdr.has_value()) {
        return;
    }

    if (topic == kTopicPing) {
        (void)send_reply(envelope.key, true);
        return;
    }

    if (topic == kTopicPlayerCommand) {
        auto cmd = parse_player_command_envelope(envelope);
        bool ok = false;
        if (cmd.has_value() && cb_copy.on_player_command) {
            ok = cb_copy.on_player_command(*cmd);
        }
        if (!envelope.key.empty()) {
            (void)send_reply(envelope.key, ok);
        }
        return;
    }

    auto raw_pb = decode_protobuf_payload(envelope);
    if (!raw_pb.has_value()) {
        if (!envelope.key.empty()) {
            (void)send_reply(envelope.key, false);
        }
        return;
    }

    bool known_topic = true;
    bool decode_ok = false;

    if (topic == kTopicCluster) {
        ClusterUpdate update;
        decode_ok = decode_cluster_update(raw_pb->data(), raw_pb->size(), update);
        if (decode_ok && cb_copy.on_cluster_update) {
            cb_copy.on_cluster_update(update);
        }
    } else if (topic == kTopicVolume) {
        SetVolumeCommand cmd;
        decode_ok = decode_set_volume_command(raw_pb->data(), raw_pb->size(), cmd);
        if (decode_ok && cb_copy.on_set_volume) {
            cb_copy.on_set_volume(cmd);
        }
    } else if (topic == kTopicLogout) {
        LogoutCommand cmd;
        decode_ok = decode_logout_command(raw_pb->data(), raw_pb->size(), cmd);
        if (!envelope.key.empty()) {
            (void)send_reply(envelope.key, decode_ok);
        }
        if (decode_ok && cb_copy.on_logout) {
            cb_copy.on_logout(cmd);
        }
        return;
    } else if (topic == kTopicBackendMetadata) {
        SetBackendMetadataCommand cmd;
        decode_ok = decode_set_backend_metadata_command(raw_pb->data(), raw_pb->size(), cmd);
        if (decode_ok && cb_copy.on_set_backend_metadata) {
            cb_copy.on_set_backend_metadata(cmd);
        }
    } else if (topic == kTopicProxyTransfer) {
        ProxyTransferCommand cmd;
        decode_ok = decode_proxy_transfer_command(raw_pb->data(), raw_pb->size(), cmd);
        if (decode_ok) {
            if (cmd.wol_info.has_value() && validate_wol_info(*cmd.wol_info)) {
                (void)send_wol_magic_packet(*cmd.wol_info);
            }
            if (cb_copy.on_proxy_transfer) {
                cb_copy.on_proxy_transfer(cmd);
            }
        }
    } else if (topic == kTopicProxyWake) {
        ProxyWakeCommand cmd;
        decode_ok = decode_proxy_wake_command(raw_pb->data(), raw_pb->size(), cmd);
        if (decode_ok) {
            if (cmd.wol_info.has_value() && validate_wol_info(*cmd.wol_info)) {
                (void)send_wol_magic_packet(*cmd.wol_info);
            }
            if (cb_copy.on_proxy_wake) {
                cb_copy.on_proxy_wake(cmd);
            }
        }
    } else if (topic == kTopicGroupAddDevice) {
        AddDeviceToGroupCommand cmd;
        decode_ok = decode_add_device_to_group_command(raw_pb->data(), raw_pb->size(), cmd);
        if (decode_ok && cb_copy.on_add_device_to_group) {
            cb_copy.on_add_device_to_group(cmd);
        }
    } else if (topic == kTopicGroupRemoveDevice) {
        RemoveDeviceFromGroupCommand cmd;
        decode_ok = decode_remove_device_from_group_command(raw_pb->data(), raw_pb->size(), cmd);
        if (decode_ok && cb_copy.on_remove_device_from_group) {
            cb_copy.on_remove_device_from_group(cmd);
        }
    } else if (topic == kTopicGroupDelete) {
        DeleteGroupCommand cmd;
        decode_ok = decode_delete_group_command(raw_pb->data(), raw_pb->size(), cmd);
        if (decode_ok && cb_copy.on_delete_group) {
            cb_copy.on_delete_group(cmd);
        }
    } else if (topic == kTopicGroupResync) {
        ResyncGroupDataCommand cmd;
        decode_ok = decode_resync_group_data_command(raw_pb->data(), raw_pb->size(), cmd);
        if (decode_ok && cb_copy.on_resync_group_data) {
            cb_copy.on_resync_group_data(cmd);
        }
    } else {
        known_topic = false;
    }

    if (!envelope.key.empty()) {
        (void)send_reply(envelope.key, known_topic && decode_ok);
    }
}

void DealerWebSocketClient::worker_loop() {
    struct WorkerThreadIdGuard {
        explicit WorkerThreadIdGuard(std::atomic<std::thread::id>& slot) : slot_(slot) {
            slot_.store(std::this_thread::get_id(), std::memory_order_release);
        }
        ~WorkerThreadIdGuard() {
            slot_.store(std::thread::id{}, std::memory_order_release);
        }
        std::atomic<std::thread::id>& slot_;
    } thread_id_guard(worker_thread_id_);

    const std::string ca_bundle = load_android_ca_bundle();
    int64_t reconnect_delay_ms = kInitialReconnectDelayMs;

    while (true) {
        {
            std::lock_guard<std::mutex> lock(state_mutex_);
            if (stop_requested_) {
                break;
            }
            reconnect_requested_ = false;
        }

        const auto creds = auth_store_.snapshot();
        if (creds.access_token.empty()) {
            set_state(DealerConnectionState::kReconnecting);
            std::unique_lock<std::mutex> lock(state_mutex_);
            state_cv_.wait_for(
                lock,
                std::chrono::milliseconds(reconnect_delay_ms),
                [this]() { return stop_requested_ || reconnect_requested_; });
            reconnect_delay_ms = std::min(reconnect_delay_ms * 2, kMaxReconnectDelayMs);
            continue;
        }

        set_state(DealerConnectionState::kConnecting);

        CURL* curl = curl_easy_init();
        if (curl == nullptr) {
            set_state(DealerConnectionState::kReconnecting);
            std::unique_lock<std::mutex> lock(state_mutex_);
            state_cv_.wait_for(
                lock,
                std::chrono::milliseconds(reconnect_delay_ms),
                [this]() { return stop_requested_ || reconnect_requested_; });
            reconnect_delay_ms = std::min(reconnect_delay_ms * 2, kMaxReconnectDelayMs);
            continue;
        }

        const std::string ws_url = build_connection_url(dealer_base_url_, creds.access_token);
        std::string connect_url;
        std::string host_header;
        std::string request_target;
        if (!build_ws_connect_params(ws_url, connect_url, host_header, request_target)) {
            curl_easy_cleanup(curl);
            set_state(DealerConnectionState::kReconnecting);
            std::unique_lock<std::mutex> lock(state_mutex_);
            state_cv_.wait_for(
                lock,
                std::chrono::milliseconds(reconnect_delay_ms),
                [this]() { return stop_requested_ || reconnect_requested_; });
            reconnect_delay_ms = std::min(reconnect_delay_ms * 2, kMaxReconnectDelayMs);
            continue;
        }

        curl_easy_setopt(curl, CURLOPT_URL, connect_url.c_str());
        curl_easy_setopt(curl, CURLOPT_CONNECT_ONLY, 1L);
        curl_easy_setopt(curl, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_1_1);
        curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
        curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT_MS, 15000L);
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1L);
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 2L);

        curl_blob ca_blob{};
        if (!ca_bundle.empty()) {
            ca_blob.data = const_cast<char*>(ca_bundle.data());
            ca_blob.len = ca_bundle.size();
            ca_blob.flags = CURL_BLOB_NOCOPY;
            curl_easy_setopt(curl, CURLOPT_CAINFO_BLOB, &ca_blob);
        }

        const CURLcode connect_rc = curl_easy_perform(curl);
        curl_socket_t sockfd = CURL_SOCKET_BAD;
        if (connect_rc == CURLE_OK) {
            curl_easy_getinfo(curl, CURLINFO_ACTIVESOCKET, &sockfd);
        }

        if (connect_rc != CURLE_OK || sockfd == CURL_SOCKET_BAD) {
            DEALER_LOGW("Dealer WS connect failed: curl=%d (%s)",
                        static_cast<int>(connect_rc),
                        curl_easy_strerror(connect_rc));
            curl_easy_cleanup(curl);
            set_state(DealerConnectionState::kReconnecting);
            std::unique_lock<std::mutex> lock(state_mutex_);
            state_cv_.wait_for(
                lock,
                std::chrono::milliseconds(reconnect_delay_ms),
                [this]() { return stop_requested_ || reconnect_requested_; });
            reconnect_delay_ms = std::min(reconnect_delay_ms * 2, kMaxReconnectDelayMs);
            continue;
        }

        // Perform explicit non-blocking RFC 6455 §4.1 HTTP/1.1 Upgrade over curl_easy_send/recv.
        Rfc6455FrameParser parser;
        bool upgrade_ok = false;
        {
            std::array<uint8_t, 16> nonce{};
            if (fill_csprng_bytes(nonce.data(), nonce.size())) {
                const std::string sec_ws_key = base64_encode(nonce.data(), nonce.size());
                const std::string expected_accept = compute_websocket_accept(sec_ws_key);

                std::string upgrade_req;
                upgrade_req.reserve(256U + request_target.size() + host_header.size());
                upgrade_req.append("GET ");
                upgrade_req.append(request_target);
                upgrade_req.append(" HTTP/1.1\r\nHost: ");
                upgrade_req.append(host_header);
                upgrade_req.append("\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: ");
                upgrade_req.append(sec_ws_key);
                upgrade_req.append("\r\nSec-WebSocket-Version: 13\r\n\r\n");

                size_t req_sent = 0;
                std::string upgrade_rx;
                const auto upgrade_deadline =
                    std::chrono::steady_clock::now() + std::chrono::milliseconds(15000);
                bool handshake_failed = false;

                while (!handshake_failed && !upgrade_ok) {
                    {
                        std::lock_guard<std::mutex> lock(state_mutex_);
                        if (stop_requested_ || reconnect_requested_) {
                            handshake_failed = true;
                            break;
                        }
                    }

                    while (req_sent < upgrade_req.size()) {
                        size_t sent = 0;
                        const CURLcode send_rc = curl_easy_send(
                            curl,
                            upgrade_req.data() + req_sent,
                            upgrade_req.size() - req_sent,
                            &sent);
                        if (send_rc == CURLE_AGAIN) {
                            break;
                        }
                        if (send_rc != CURLE_OK || sent == 0U) {
                            handshake_failed = true;
                            break;
                        }
                        req_sent += sent;
                    }
                    if (handshake_failed) {
                        break;
                    }

                    if (req_sent == upgrade_req.size()) {
                        while (!handshake_failed && !upgrade_ok) {
                            std::array<char, 4096> rx_tmp{};
                            size_t rlen = 0;
                            const CURLcode recv_rc =
                                curl_easy_recv(curl, rx_tmp.data(), rx_tmp.size(), &rlen);
                            if (recv_rc == CURLE_AGAIN) {
                                break;
                            }
                            if (recv_rc != CURLE_OK || rlen == 0U) {
                                handshake_failed = true;
                                break;
                            }
                            upgrade_rx.append(rx_tmp.data(), rlen);
                            size_t header_bytes = 0;
                            const HttpUpgradeParseResult hres = parse_websocket_upgrade_response(
                                upgrade_rx, expected_accept, header_bytes);
                            if (hres == HttpUpgradeParseResult::kProtocolError) {
                                handshake_failed = true;
                                break;
                            }
                            if (hres == HttpUpgradeParseResult::kOk) {
                                if (header_bytes < upgrade_rx.size()) {
                                    parser.feed(
                                        reinterpret_cast<const uint8_t*>(
                                            upgrade_rx.data() + header_bytes),
                                        upgrade_rx.size() - header_bytes);
                                }
                                upgrade_ok = true;
                                break;
                            }
                        }
                    }

                    if (handshake_failed || upgrade_ok) {
                        break;
                    }

                    const auto now_hs = std::chrono::steady_clock::now();
                    if (now_hs >= upgrade_deadline) {
                        handshake_failed = true;
                        break;
                    }
                    const auto rem_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                                            upgrade_deadline - now_hs)
                                            .count();
                    const int poll_ms = static_cast<int>(std::min<int64_t>(rem_ms, 500));

                    struct pollfd hs_fds[2]{};
                    nfds_t hs_nfds = 1;
                    hs_fds[0].fd = static_cast<int>(sockfd);
                    hs_fds[0].events =
                        POLLIN | POLLERR | POLLHUP | (req_sent < upgrade_req.size() ? POLLOUT : 0);
                    const int wfd = wakeup_fd_.load();
                    if (wfd >= 0) {
                        hs_fds[1].fd = wfd;
                        hs_fds[1].events = POLLIN;
                        hs_nfds = 2;
                    }
                    const int hs_poll_rc = ::poll(hs_fds, hs_nfds, std::max(1, poll_ms));
                    if (hs_poll_rc < 0 && errno != EINTR) {
                        handshake_failed = true;
                        break;
                    }
                    if (hs_nfds == 2 && (hs_fds[1].revents & POLLIN) != 0) {
                        uint64_t drained = 0;
                        const ssize_t ignored = ::read(wfd, &drained, sizeof(drained));
                        (void)ignored;
                    }
                    if ((hs_fds[0].revents & (POLLERR | POLLNVAL)) != 0 ||
                        ((hs_fds[0].revents & POLLHUP) != 0 &&
                         (hs_fds[0].revents & POLLIN) == 0)) {
                        handshake_failed = true;
                        break;
                    }
                }
            }
        }

        if (!upgrade_ok) {
            DEALER_LOGW("Dealer WS HTTP/1.1 Upgrade failed");
            curl_easy_cleanup(curl);
            {
                std::lock_guard<std::mutex> lock(state_mutex_);
                if (stop_requested_) {
                    break;
                }
                if (reconnect_requested_) {
                    reconnect_delay_ms = kInitialReconnectDelayMs;
                    continue;
                }
            }
            set_state(DealerConnectionState::kReconnecting);
            std::unique_lock<std::mutex> lock(state_mutex_);
            state_cv_.wait_for(
                lock,
                std::chrono::milliseconds(reconnect_delay_ms),
                [this]() { return stop_requested_ || reconnect_requested_; });
            reconnect_delay_ms = std::min(reconnect_delay_ms * 2, kMaxReconnectDelayMs);
            continue;
        }

        DEALER_LOGI("Dealer WebSocket connected");
        set_state(DealerConnectionState::kConnected);
        reconnect_delay_ms = kInitialReconnectDelayMs;

        auto last_ping_sent_at = std::chrono::steady_clock::now();
        auto last_pong_at = last_ping_sent_at;
        bool awaiting_pong = false;

        std::vector<uint8_t> raw_tx_buffer;
        size_t raw_tx_offset = 0;
        bool session_alive = true;

        auto compact_tx = [&]() {
            if (raw_tx_offset == raw_tx_buffer.size()) {
                raw_tx_buffer.clear();
                raw_tx_offset = 0;
            } else if (raw_tx_offset >= 65536U) {
                raw_tx_buffer.erase(
                    raw_tx_buffer.begin(),
                    raw_tx_buffer.begin() + static_cast<std::ptrdiff_t>(raw_tx_offset));
                raw_tx_offset = 0;
            }
        };

        auto enqueue_frame = [&](Rfc6455Opcode op, const uint8_t* data, size_t len) -> bool {
            if (!encode_rfc6455_client_frame(op, data, len, raw_tx_buffer)) {
                session_alive = false;
                return false;
            }
            return true;
        };

        auto flush_raw_tx = [&]() {
            while (session_alive && raw_tx_offset < raw_tx_buffer.size()) {
                size_t sent = 0;
                const CURLcode send_rc = curl_easy_send(
                    curl,
                    raw_tx_buffer.data() + raw_tx_offset,
                    raw_tx_buffer.size() - raw_tx_offset,
                    &sent);
                if (send_rc == CURLE_AGAIN) {
                    break;
                }
                if (send_rc != CURLE_OK || sent == 0U) {
                    session_alive = false;
                    break;
                }
                raw_tx_offset += sent;
            }
            compact_tx();
        };

        auto drain_outbound = [&]() {
            std::deque<std::string> pending;
            {
                std::lock_guard<std::mutex> lock(outbound_mutex_);
                pending.swap(outbound_queue_);
            }
            while (!pending.empty() && session_alive) {
                const std::string& msg = pending.front();
                (void)enqueue_frame(
                    Rfc6455Opcode::kText,
                    reinterpret_cast<const uint8_t*>(msg.data()),
                    msg.size());
                pending.pop_front();
            }
            flush_raw_tx();
        };

        auto should_stop_or_reconnect = [&]() -> bool {
            std::lock_guard<std::mutex> lock(state_mutex_);
            return stop_requested_ || reconnect_requested_;
        };

        auto flush_pending_tx_bounded = [&]() {
            if (!session_alive || raw_tx_offset >= raw_tx_buffer.size()) {
                return;
            }
            const auto flush_deadline =
                std::chrono::steady_clock::now() + std::chrono::milliseconds(250);
            while (session_alive && raw_tx_offset < raw_tx_buffer.size()) {
                flush_raw_tx();
                if (!session_alive || raw_tx_offset >= raw_tx_buffer.size()) {
                    break;
                }
                const auto now_flush = std::chrono::steady_clock::now();
                if (now_flush >= flush_deadline) {
                    break;
                }
                const auto rem_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                                        flush_deadline - now_flush)
                                        .count();
                struct pollfd pfd{};
                pfd.fd = static_cast<int>(sockfd);
                pfd.events = POLLOUT | POLLERR | POLLHUP;
                const int prc = ::poll(&pfd, 1, static_cast<int>(std::max<int64_t>(1, rem_ms)));
                if (prc <= 0 || (pfd.revents & (POLLERR | POLLHUP | POLLNVAL)) != 0) {
                    break;
                }
            }
        };

        auto process_parser_frames = [&]() {
            while (session_alive) {
                Rfc6455Frame frame;
                const Rfc6455ParseResult pres = parser.next_frame(frame);
                if (pres == Rfc6455ParseResult::kNeedMoreData) {
                    break;
                }
                if (pres == Rfc6455ParseResult::kProtocolError) {
                    session_alive = false;
                    break;
                }
                switch (frame.opcode) {
                    case Rfc6455Opcode::kClose: {
                        const size_t close_len = frame.payload.size() >= 2U ? 2U : 0U;
                        const uint8_t* close_ptr =
                            close_len > 0U
                                ? reinterpret_cast<const uint8_t*>(frame.payload.data())
                                : nullptr;
                        (void)enqueue_frame(Rfc6455Opcode::kClose, close_ptr, close_len);
                        flush_raw_tx();
                        session_alive = false;
                        break;
                    }
                    case Rfc6455Opcode::kPing: {
                        const uint8_t* ping_ptr =
                            frame.payload.empty()
                                ? nullptr
                                : reinterpret_cast<const uint8_t*>(frame.payload.data());
                        if (enqueue_frame(Rfc6455Opcode::kPong, ping_ptr, frame.payload.size())) {
                            flush_raw_tx();
                        }
                        break;
                    }
                    case Rfc6455Opcode::kPong: {
                        awaiting_pong = false;
                        last_pong_at = std::chrono::steady_clock::now();
                        (void)last_pong_at;
                        break;
                    }
                    case Rfc6455Opcode::kText: {
                        bool got_pong = false;
                        (void)process_inbound_text_frame(frame.payload, &got_pong);
                        if (got_pong) {
                            awaiting_pong = false;
                            last_pong_at = std::chrono::steady_clock::now();
                        }
                        break;
                    }
                    case Rfc6455Opcode::kBinary:
                    case Rfc6455Opcode::kContinuation:
                        break;
                }
                if (!session_alive || should_stop_or_reconnect()) {
                    break;
                }
            }
        };

        while (session_alive) {
            // Drain any outbound frames queued prior to stop/reconnect checks.
            drain_outbound();
            if (!session_alive) {
                break;
            }
            if (should_stop_or_reconnect()) {
                flush_pending_tx_bounded();
                session_alive = false;
                break;
            }

            // Process any WebSocket frames already buffered (e.g. coalesced with HTTP 101).
            if (parser.buffered_bytes() > 0U) {
                process_parser_frames();
                drain_outbound();
                if (!session_alive) {
                    break;
                }
                if (should_stop_or_reconnect()) {
                    flush_pending_tx_bounded();
                    session_alive = false;
                    break;
                }
            }

            // Keepalive ping every 30000ms (dealerPingTime).
            const auto now = std::chrono::steady_clock::now();
            if (awaiting_pong &&
                std::chrono::duration_cast<std::chrono::milliseconds>(now - last_ping_sent_at)
                        .count() >= kDealerPongTimeoutMs) {
                DEALER_LOGW("Dealer WS pong timeout; reconnecting");
                session_alive = false;
                break;
            }
            if (!awaiting_pong &&
                std::chrono::duration_cast<std::chrono::milliseconds>(now - last_ping_sent_at)
                        .count() >= kDealerPingIntervalMs) {
                static constexpr const char kPingFrame[] = "{\"type\":\"ping\"}";
                if (enqueue_frame(
                        Rfc6455Opcode::kText,
                        reinterpret_cast<const uint8_t*>(kPingFrame),
                        sizeof(kPingFrame) - 1U)) {
                    flush_raw_tx();
                    if (session_alive) {
                        last_ping_sent_at = now;
                        awaiting_pong = true;
                    }
                }
                if (!session_alive) {
                    break;
                }
            }

            // Drain all readable raw WebSocket bytes from libcurl until CURLE_AGAIN.
            while (session_alive) {
                std::array<uint8_t, 32768> buf{};
                size_t rlen = 0;
                const CURLcode recv_rc = curl_easy_recv(curl, buf.data(), buf.size(), &rlen);
                if (recv_rc == CURLE_AGAIN) {
                    break;
                }
                if (recv_rc != CURLE_OK || rlen == 0U) {
                    session_alive = false;
                    break;
                }
                parser.feed(buf.data(), rlen);
                process_parser_frames();
                if (should_stop_or_reconnect()) {
                    break;
                }
            }

            // Flush any replies (including kTopicLogout) queued during frame dispatch.
            drain_outbound();
            if (!session_alive) {
                break;
            }
            if (should_stop_or_reconnect()) {
                flush_pending_tx_bounded();
                session_alive = false;
                break;
            }

            // Wait for socket readiness or wakeup eventfd.
            struct pollfd fds[2]{};
            nfds_t nfds = 1;
            fds[0].fd = static_cast<int>(sockfd);
            fds[0].events =
                POLLIN | POLLERR | POLLHUP | (raw_tx_offset < raw_tx_buffer.size() ? POLLOUT : 0);
            const int wfd = wakeup_fd_.load();
            if (wfd >= 0) {
                fds[1].fd = wfd;
                fds[1].events = POLLIN;
                nfds = 2;
            }
            const int poll_rc = ::poll(fds, nfds, 500);
            if (poll_rc < 0 && errno != EINTR) {
                session_alive = false;
                break;
            }
            if (nfds == 2 && (fds[1].revents & POLLIN) != 0) {
                uint64_t drained = 0;
                const ssize_t ignored = ::read(wfd, &drained, sizeof(drained));
                (void)ignored;
            }
            if ((fds[0].revents & (POLLERR | POLLNVAL)) != 0 ||
                ((fds[0].revents & POLLHUP) != 0 && (fds[0].revents & POLLIN) == 0)) {
                session_alive = false;
                break;
            }
        }

        curl_easy_cleanup(curl);

        {
            std::lock_guard<std::mutex> lock(state_mutex_);
            if (stop_requested_) {
                break;
            }
            if (reconnect_requested_) {
                reconnect_delay_ms = kInitialReconnectDelayMs;
                continue;
            }
        }

        set_state(DealerConnectionState::kReconnecting);
        std::unique_lock<std::mutex> lock(state_mutex_);
        state_cv_.wait_for(
            lock,
            std::chrono::milliseconds(reconnect_delay_ms),
            [this]() { return stop_requested_ || reconnect_requested_; });
        reconnect_delay_ms = std::min(reconnect_delay_ms * 2, kMaxReconnectDelayMs);
    }

    close_wakeup_fd();
    {
        std::lock_guard<std::mutex> lock(outbound_mutex_);
        outbound_queue_.clear();
    }
    bool notify_disconnected = false;
    {
        std::lock_guard<std::mutex> lock(state_mutex_);
        running_ = false;
        stop_requested_ = false;
        reconnect_requested_ = false;
        connection_id_.clear();
        if (state_ != DealerConnectionState::kDisconnected) {
            state_ = DealerConnectionState::kDisconnected;
            notify_disconnected = true;
        }
    }
    state_cv_.notify_all();
    if (notify_disconnected) {
        DealerCallbacks cb_copy;
        {
            std::lock_guard<std::mutex> lock(callbacks_mutex_);
            cb_copy = callbacks_;
        }
        if (cb_copy.on_connection_state_changed) {
            cb_copy.on_connection_state_changed(DealerConnectionState::kDisconnected);
        }
    }
}

}  // namespace spotify::connectstate
