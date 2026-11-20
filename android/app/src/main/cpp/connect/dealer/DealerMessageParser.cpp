// ============================================================================
// Modular Dealer JSON & Message Envelope Parser Implementation
// Replicated from `liborbit-jni-spotify.so` (arm64):
// - Connect-State 12 dealer topics @ 0xdb4d9c..0xdb50c0
// - Connect-Group 2 dealer topics @ 0xd9f810, 0xd9f85c
// - `target_alias_id` extraction (0x3476f4 @ 0xdb8ff0)
// - Base64 + zlib "compressed" command envelope & gzip protobuf decompression (0xdba108)
// ============================================================================

#include "DealerMessageParser.h"

#include "WsCodec.h"

#include <cerrno>
#include <cmath>
#include <cstdio>
#include <cstdlib>
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

namespace {

std::optional<uint32_t> extract_uint32_flexible(
    const json::JsonValue& obj,
    std::string_view key) {
    if (auto num = obj.get_uint32(key)) {
        return num;
    }
    if (auto str = obj.get_string(key); str.has_value() && !str->empty()) {
        char* endptr = nullptr;
        errno = 0;
        const unsigned long long parsed = std::strtoull(str->c_str(), &endptr, 10);
        if (errno == 0 && endptr == str->c_str() + str->size() &&
            parsed <= std::numeric_limits<uint32_t>::max()) {
            return static_cast<uint32_t>(parsed);
        }
    }
    return std::nullopt;
}

}  // namespace

std::optional<DealerEnvelope> DealerMessageParser::parse_dealer_envelope(std::string_view text) {
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

std::optional<std::string> DealerMessageParser::extract_connection_id(
    const DealerEnvelope& envelope) {
    auto conn_id = find_header_ci(envelope.headers, "Spotify-Connection-Id");
    if (!conn_id.has_value() || conn_id->empty()) {
        conn_id = find_header_ci(envelope.headers, "X-Spotify-Connection-Id");
    }
    if (conn_id.has_value() && !conn_id->empty()) {
        return conn_id;
    }

    // Some Dealer deployments also embed the connection ID in the pusher URI suffix.
    const std::string_view uri(envelope.uri);
    const std::string_view prefix(kPusherConnectionsPrefix);
    if (uri.size() > prefix.size() && uri.substr(0, prefix.size()) == prefix) {
        std::string_view tail = uri.substr(prefix.size());
        const size_t q = tail.find('?');
        if (q != std::string_view::npos) {
            tail = tail.substr(0, q);
        }
        if (!tail.empty()) {
            return std::string(tail);
        }
    }
    return std::nullopt;
}

std::optional<std::vector<uint8_t>> DealerMessageParser::decode_protobuf_payload(
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
        decoded->size() >= 2U && (*decoded)[0] == 0x1FU && (*decoded)[1] == 0x8BU;

    if (header_gzip || magic_gzip) {
        return zlib_decompress(decoded->data(), decoded->size());
    }
    return decoded;
}

std::optional<DealerPlayerCommand> DealerMessageParser::parse_player_command_envelope(
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
    if (auto mid = extract_uint32_flexible(*payload_obj, "message_id")) {
        cmd.message_id = *mid;
    }
    if (auto sender = payload_obj->get_string("sent_by_device_id")) {
        cmd.sent_by_device_id = std::move(*sender);
    }
    if (auto alias = extract_uint32_flexible(*payload_obj, "target_alias_id")) {
        cmd.target_alias_id = *alias;
        cmd.has_target_alias_id = true;
    }

    const json::JsonValue* command_node = payload_obj->find("command");
    if (command_node != nullptr && command_node->is_object()) {
        if (auto ep = command_node->get_string("endpoint")) {
            cmd.endpoint = std::move(*ep);
        }
        if (!cmd.has_target_alias_id) {
            if (auto alias = extract_uint32_flexible(*command_node, "target_alias_id")) {
                cmd.target_alias_id = *alias;
                cmd.has_target_alias_id = true;
            }
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

bool DealerMessageParser::decode_group_data_event_payload(
    const DealerEnvelope& envelope,
    GroupDataEvent& out_event) {
    auto raw = decode_protobuf_payload(envelope);
    if (!raw.has_value()) {
        return false;
    }
    return decode_group_data_event(raw->data(), raw->size(), out_event);
}

bool DealerMessageParser::decode_group_device_volume_event_payload(
    const DealerEnvelope& envelope,
    GroupDeviceVolumeEvent& out_event) {
    auto raw = decode_protobuf_payload(envelope);
    if (!raw.has_value()) {
        return false;
    }
    return decode_group_device_volume_event(raw->data(), raw->size(), out_event);
}

}  // namespace spotify::connectstate
