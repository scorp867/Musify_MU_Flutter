// ============================================================================
// 1:1 Replicated Spotify ContextResolveClient & Player JSON Codec
// Sources (`liborbit-jni-spotify.so` arm64):
// - ContextResolveSetupImpl @ 0xe02668..0xe04104
// - `hm://` normalization @ 0xe0340c
// - `context://` normalization @ 0xe02ad8
// - `context-page://` normalization @ 0xe03264
// - `Accept: application/json` header @ 0xe03488
// - Default fallback `https://spclient.wg.spotify.com/` (`0x350245` @ `0xb1d15c`)
// ============================================================================

#include "ContextResolveClient.h"

#include "../network/NativeLog.h"

#include <algorithm>
#include <cctype>
#include <charconv>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <utility>

namespace spotify::player {

namespace json {

namespace {

constexpr int kMaxJsonNestingDepth = 96;

void append_utf8_codepoint(std::string& out, uint32_t cp) {
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

class JsonParser {
public:
    explicit JsonParser(std::string_view input) noexcept : input_(input) {}

    [[nodiscard]] std::optional<JsonValue> parse_root() {
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
    void skip_ws() noexcept {
        while (pos_ < input_.size()) {
            const char c = input_[pos_];
            if (c == ' ' || c == '\t' || c == '\r' || c == '\n') {
                ++pos_;
            } else {
                break;
            }
        }
    }

    [[nodiscard]] bool consume_literal(std::string_view lit) noexcept {
        if (input_.size() - pos_ < lit.size()) {
            return false;
        }
        if (input_.substr(pos_, lit.size()) != lit) {
            return false;
        }
        pos_ += lit.size();
        return true;
    }

    [[nodiscard]] bool parse_hex4(uint16_t& out) noexcept {
        if (input_.size() - pos_ < 4) {
            return false;
        }
        uint16_t val = 0;
        for (size_t i = 0; i < 4; ++i) {
            const char c = input_[pos_++];
            uint16_t nibble = 0;
            if (c >= '0' && c <= '9') {
                nibble = static_cast<uint16_t>(c - '0');
            } else if (c >= 'a' && c <= 'f') {
                nibble = static_cast<uint16_t>(10 + (c - 'a'));
            } else if (c >= 'A' && c <= 'F') {
                nibble = static_cast<uint16_t>(10 + (c - 'A'));
            } else {
                return false;
            }
            val = static_cast<uint16_t>((val << 4) | nibble);
        }
        out = val;
        return true;
    }

    [[nodiscard]] std::optional<std::string> parse_string() {
        if (pos_ >= input_.size() || input_[pos_] != '"') {
            return std::nullopt;
        }
        ++pos_;
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
                case '"':
                    out.push_back('"');
                    break;
                case '\\':
                    out.push_back('\\');
                    break;
                case '/':
                    out.push_back('/');
                    break;
                case 'b':
                    out.push_back('\b');
                    break;
                case 'f':
                    out.push_back('\f');
                    break;
                case 'n':
                    out.push_back('\n');
                    break;
                case 'r':
                    out.push_back('\r');
                    break;
                case 't':
                    out.push_back('\t');
                    break;
                case 'u': {
                    uint16_t u1 = 0;
                    if (!parse_hex4(u1)) {
                        return std::nullopt;
                    }
                    if (u1 >= 0xD800U && u1 <= 0xDBFFU) {
                        if (input_.size() - pos_ < 2 ||
                            input_[pos_] != '\\' ||
                            input_[pos_ + 1] != 'u') {
                            return std::nullopt;
                        }
                        pos_ += 2;
                        uint16_t u2 = 0;
                        if (!parse_hex4(u2) || u2 < 0xDC00U || u2 > 0xDFFFU) {
                            return std::nullopt;
                        }
                        const uint32_t cp =
                            0x10000U +
                            ((static_cast<uint32_t>(u1 - 0xD800U) << 10) |
                             static_cast<uint32_t>(u2 - 0xDC00U));
                        append_utf8_codepoint(out, cp);
                    } else if (u1 >= 0xDC00U && u1 <= 0xDFFFU) {
                        return std::nullopt;
                    } else {
                        append_utf8_codepoint(out, u1);
                    }
                    break;
                }
                default:
                    return std::nullopt;
            }
        }
        return std::nullopt;
    }

    [[nodiscard]] std::optional<JsonValue> parse_number() {
        const size_t start = pos_;
        if (pos_ < input_.size() && input_[pos_] == '-') {
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

        const std::string_view token = input_.substr(start, pos_ - start);
        if (!is_float) {
            int64_t ival = 0;
            const auto res = std::from_chars(token.data(), token.data() + token.size(), ival);
            if (res.ec == std::errc() && res.ptr == token.data() + token.size()) {
                JsonValue v;
                v.type = JsonValue::Type::kInt;
                v.int_value = ival;
                v.double_value = static_cast<double>(ival);
                return v;
            }
        }

        std::string null_terminated(token);
        char* endptr = nullptr;
        const double dval = std::strtod(null_terminated.c_str(), &endptr);
        if (endptr != null_terminated.c_str() + null_terminated.size() ||
            !std::isfinite(dval)) {
            return std::nullopt;
        }
        JsonValue v;
        v.type = JsonValue::Type::kDouble;
        v.double_value = dval;
        return v;
    }

    [[nodiscard]] std::optional<JsonValue> parse_array(int depth) {
        if (depth >= kMaxJsonNestingDepth) {
            return std::nullopt;
        }
        ++pos_;  // '['
        JsonValue arr;
        arr.type = JsonValue::Type::kArray;
        skip_ws();
        if (pos_ < input_.size() && input_[pos_] == ']') {
            ++pos_;
            return arr;
        }
        while (pos_ < input_.size()) {
            skip_ws();
            auto elem = parse_value(depth + 1);
            if (!elem.has_value()) {
                return std::nullopt;
            }
            arr.array_value.push_back(std::move(*elem));
            skip_ws();
            if (pos_ >= input_.size()) {
                return std::nullopt;
            }
            if (input_[pos_] == ']') {
                ++pos_;
                return arr;
            }
            if (input_[pos_] != ',') {
                return std::nullopt;
            }
            ++pos_;
        }
        return std::nullopt;
    }

    [[nodiscard]] std::optional<JsonValue> parse_object(int depth) {
        if (depth >= kMaxJsonNestingDepth) {
            return std::nullopt;
        }
        ++pos_;  // '{'
        JsonValue obj;
        obj.type = JsonValue::Type::kObject;
        skip_ws();
        if (pos_ < input_.size() && input_[pos_] == '}') {
            ++pos_;
            return obj;
        }
        while (pos_ < input_.size()) {
            skip_ws();
            auto key = parse_string();
            if (!key.has_value()) {
                return std::nullopt;
            }
            skip_ws();
            if (pos_ >= input_.size() || input_[pos_] != ':') {
                return std::nullopt;
            }
            ++pos_;
            skip_ws();
            auto val = parse_value(depth + 1);
            if (!val.has_value()) {
                return std::nullopt;
            }
            obj.object_value[std::move(*key)] = std::move(*val);
            skip_ws();
            if (pos_ >= input_.size()) {
                return std::nullopt;
            }
            if (input_[pos_] == '}') {
                ++pos_;
                return obj;
            }
            if (input_[pos_] != ',') {
                return std::nullopt;
            }
            ++pos_;
        }
        return std::nullopt;
    }

    [[nodiscard]] std::optional<JsonValue> parse_value(int depth) {
        skip_ws();
        if (pos_ >= input_.size()) {
            return std::nullopt;
        }
        const char c = input_[pos_];
        if (c == '{') {
            return parse_object(depth);
        }
        if (c == '[') {
            return parse_array(depth);
        }
        if (c == '"') {
            auto s = parse_string();
            if (!s.has_value()) {
                return std::nullopt;
            }
            JsonValue v;
            v.type = JsonValue::Type::kString;
            v.string_value = std::move(*s);
            return v;
        }
        if (c == 't') {
            if (!consume_literal("true")) {
                return std::nullopt;
            }
            JsonValue v;
            v.type = JsonValue::Type::kBool;
            v.bool_value = true;
            return v;
        }
        if (c == 'f') {
            if (!consume_literal("false")) {
                return std::nullopt;
            }
            JsonValue v;
            v.type = JsonValue::Type::kBool;
            v.bool_value = false;
            return v;
        }
        if (c == 'n') {
            if (!consume_literal("null")) {
                return std::nullopt;
            }
            JsonValue v;
            v.type = JsonValue::Type::kNull;
            return v;
        }
        if (c == '-' || (c >= '0' && c <= '9')) {
            return parse_number();
        }
        return std::nullopt;
    }

    std::string_view input_;
    size_t pos_{0};
};

}  // namespace

const JsonValue* JsonValue::find(std::string_view key) const noexcept {
    if (type != Type::kObject) {
        return nullptr;
    }
    const auto it = object_value.find(std::string(key));
    if (it == object_value.end()) {
        return nullptr;
    }
    return &it->second;
}

std::optional<std::string> JsonValue::get_string(std::string_view key) const {
    const JsonValue* node = find(key);
    if (node == nullptr || !node->is_string()) {
        return std::nullopt;
    }
    return node->string_value;
}

std::optional<bool> JsonValue::get_bool(std::string_view key) const noexcept {
    const JsonValue* node = find(key);
    if (node == nullptr || !node->is_bool()) {
        return std::nullopt;
    }
    return node->bool_value;
}

std::optional<int64_t> JsonValue::get_int64(std::string_view key) const noexcept {
    const JsonValue* node = find(key);
    if (node == nullptr) {
        return std::nullopt;
    }
    if (node->is_int()) {
        return node->int_value;
    }
    if (node->is_double() &&
        std::isfinite(node->double_value) &&
        node->double_value >= static_cast<double>(std::numeric_limits<int64_t>::min()) &&
        node->double_value < static_cast<double>(std::numeric_limits<int64_t>::max())) {
        const double truncated = std::trunc(node->double_value);
        if (truncated == node->double_value) {
            return static_cast<int64_t>(truncated);
        }
    }
    return std::nullopt;
}

std::optional<double> JsonValue::get_double(std::string_view key) const noexcept {
    const JsonValue* node = find(key);
    if (node == nullptr) {
        return std::nullopt;
    }
    if (node->is_double()) {
        return node->double_value;
    }
    if (node->is_int()) {
        return static_cast<double>(node->int_value);
    }
    return std::nullopt;
}

std::optional<JsonValue> parse_json(std::string_view input) {
    JsonParser parser(input);
    return parser.parse_root();
}

std::string escape_json_string(std::string_view input) {
    std::string out;
    out.reserve(input.size() + 8);
    for (const char ch : input) {
        const unsigned char c = static_cast<unsigned char>(ch);
        switch (c) {
            case '"':
                out.append("\\\"");
                break;
            case '\\':
                out.append("\\\\");
                break;
            case '\b':
                out.append("\\b");
                break;
            case '\f':
                out.append("\\f");
                break;
            case '\n':
                out.append("\\n");
                break;
            case '\r':
                out.append("\\r");
                break;
            case '\t':
                out.append("\\t");
                break;
            default:
                if (c < 0x20U) {
                    char buf[7];
                    std::snprintf(buf, sizeof(buf), "\\u%04x", static_cast<unsigned int>(c));
                    out.append(buf, 6);
                } else {
                    out.push_back(ch);
                }
                break;
        }
    }
    return out;
}

void append_json_quoted(std::string& out, std::string_view input) {
    out.push_back('"');
    out.append(escape_json_string(input));
    out.push_back('"');
}

}  // namespace json

namespace {

std::string_view trim_ascii(std::string_view s) noexcept {
    size_t start = 0;
    while (start < s.size() && std::isspace(static_cast<unsigned char>(s[start]))) {
        ++start;
    }
    size_t end = s.size();
    while (end > start && std::isspace(static_cast<unsigned char>(s[end - 1]))) {
        --end;
    }
    return s.substr(start, end - start);
}

bool istarts_with(std::string_view s, std::string_view prefix) noexcept {
    if (s.size() < prefix.size()) {
        return false;
    }
    for (size_t i = 0; i < prefix.size(); ++i) {
        if (std::tolower(static_cast<unsigned char>(s[i])) !=
            std::tolower(static_cast<unsigned char>(prefix[i]))) {
            return false;
        }
    }
    return true;
}

bool contains_control_or_space(std::string_view s) noexcept {
    for (const char ch : s) {
        const unsigned char c = static_cast<unsigned char>(ch);
        if (c <= 0x20U || c == 0x7FU) {
            return true;
        }
    }
    return false;
}

std::string_view strip_leading_slashes(std::string_view s) noexcept {
    while (!s.empty() && s.front() == '/') {
        s.remove_prefix(1);
    }
    return s;
}

void parse_string_metadata_map(
    const json::JsonValue& node,
    std::unordered_map<std::string, std::string>& out_map) {
    if (!node.is_object()) {
        return;
    }
    for (const auto& [k, v] : node.object_value) {
        if (k.empty()) {
            continue;
        }
        if (v.is_string()) {
            out_map[k] = v.string_value;
        } else if (v.is_bool()) {
            out_map[k] = v.bool_value ? "true" : "false";
        } else if (v.is_int()) {
            out_map[k] = std::to_string(v.int_value);
        }
    }
}

bool parse_json_track_entry(
    const json::JsonValue& node,
    int32_t page_index,
    int32_t absolute_index,
    context_view::Entry& out_entry) {
    if (!node.is_object()) {
        return false;
    }
    const auto uri_opt = node.get_string("uri");
    if (!uri_opt.has_value() || uri_opt->empty()) {
        return false;
    }

    context_view::Entry entry;
    entry.uri = *uri_opt;
    if (entry.uri == "spotify:delimiter" || entry.uri == "spotify:meta:delimiter") {
        entry.type = context_view::EntryType::DELIMITER;
    } else {
        entry.type = context_view::EntryType::TRACK;
    }

    const auto uid_opt = node.get_string("uid");
    entry.uid = (uid_opt.has_value() && !uid_opt->empty())
                    ? *uid_opt
                    : generate_track_uid();

    if (const auto* md = node.find("metadata"); md != nullptr && md->is_object()) {
        parse_string_metadata_map(*md, entry.metadata);
    }

    const auto prov_opt = node.get_string("provider");
    if (prov_opt.has_value() && !prov_opt->empty()) {
        entry.provider = *prov_opt;
    } else if (const auto it = entry.metadata.find("provider");
               it != entry.metadata.end() && !it->second.empty()) {
        entry.provider = it->second;
    } else if (const auto itq = entry.metadata.find("is_queued");
               itq != entry.metadata.end() &&
               (itq->second == "true" || itq->second == "True")) {
        entry.provider = "queue";
    } else {
        entry.provider = "context";
    }
    entry.metadata["provider"] = entry.provider;
    entry.page_index = page_index;
    entry.absolute_index = absolute_index;
    out_entry = std::move(entry);
    return true;
}

void parse_json_page_node(
    const json::JsonValue& page_node,
    int32_t page_index,
    ResolvedContext& out_ctx) {
    if (!page_node.is_object()) {
        return;
    }
    ResolvedContextPage page;
    page.page_url = page_node.get_string("page_url").value_or(std::string{});
    page.next_page_url = page_node.get_string("next_page_url").value_or(std::string{});
    if (const auto* pmd = page_node.find("metadata"); pmd != nullptr && pmd->is_object()) {
        parse_string_metadata_map(*pmd, page.metadata);
    }

    out_ctx.page_track_offsets.push_back(out_ctx.all_tracks.size());
    if (const auto* tracks_arr = page_node.find("tracks");
        tracks_arr != nullptr && tracks_arr->is_array()) {
        page.tracks.reserve(tracks_arr->array_value.size());
        for (const auto& tnode : tracks_arr->array_value) {
            context_view::Entry entry;
            if (!parse_json_track_entry(
                    tnode,
                    page_index,
                    static_cast<int32_t>(out_ctx.all_tracks.size()),
                    entry)) {
                continue;
            }
            if (entry.is_delimiter()) {
                continue;
            }
            page.tracks.push_back(entry);
            out_ctx.all_tracks.push_back(std::move(entry));
        }
    }

    if (out_ctx.first_page_url.empty() && !page.page_url.empty()) {
        out_ctx.first_page_url = page.page_url;
    }
    if (out_ctx.first_next_page_url.empty() && !page.next_page_url.empty()) {
        out_ctx.first_next_page_url = page.next_page_url;
    }
    out_ctx.pages.push_back(std::move(page));
}

}  // namespace

ContextResolveClient::ContextResolveClient(
    network::NativeHttpClient& http_client,
    std::string spclient_base_url)
    : http_client_(&http_client),
      spclient_base_url_(
          normalize_spclient_base_url(spclient_base_url)
              .value_or(std::string(kDefaultSpclientBaseUrl))) {}

ContextResolveClient::ContextResolveClient(
    TransportFn transport_fn,
    std::string spclient_base_url)
    : http_client_(nullptr),
      transport_fn_(std::move(transport_fn)),
      spclient_base_url_(
          normalize_spclient_base_url(spclient_base_url)
              .value_or(std::string(kDefaultSpclientBaseUrl))) {}

void ContextResolveClient::set_spclient_base_url(const std::string& base_url) {
    const auto normalized = normalize_spclient_base_url(base_url);
    if (!normalized.has_value()) {
        PLAYER_REMOTE_LOGW(
            "ContextResolveClient: ignoring invalid spclient base URL '%s'",
            sanitize_url_for_log(base_url).c_str());
        return;
    }
    std::lock_guard<std::mutex> lock(mutex_);
    spclient_base_url_ = *normalized;
    PLAYER_REMOTE_LOGI(
        "ContextResolveClient: spclient base URL set to %s",
        sanitize_url_for_log(spclient_base_url_).c_str());
}

std::string ContextResolveClient::spclient_base_url() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return spclient_base_url_;
}

void ContextResolveClient::set_transport_fn(TransportFn transport_fn) {
    std::lock_guard<std::mutex> lock(mutex_);
    transport_fn_ = std::move(transport_fn);
}

std::optional<std::string> ContextResolveClient::normalize_spclient_base_url(
    std::string_view raw_base_url) {
    const std::string_view trimmed = trim_ascii(raw_base_url);
    if (trimmed.empty() || contains_control_or_space(trimmed)) {
        return std::nullopt;
    }

    std::string result;
    if (istarts_with(trimmed, "https://") || istarts_with(trimmed, "http://")) {
        const size_t scheme_end = trimmed.find("://");
        if (scheme_end == std::string_view::npos || scheme_end + 3 >= trimmed.size()) {
            return std::nullopt;
        }
        result.assign(trimmed);
    } else if (trimmed.find("://") != std::string_view::npos) {
        return std::nullopt;
    } else {
        result = "https://";
        result.append(trimmed);
    }

    if (result.back() != '/') {
        result.push_back('/');
    }
    return result;
}

std::optional<std::string> ContextResolveClient::normalize_context_url(
    std::string_view raw_uri_or_url,
    std::string_view spclient_base_url) {
    const std::string_view trimmed = trim_ascii(raw_uri_or_url);
    if (trimmed.empty() || contains_control_or_space(trimmed)) {
        return std::nullopt;
    }

    // 1. Direct HTTP(S) URL
    if (istarts_with(trimmed, "https://") || istarts_with(trimmed, "http://")) {
        const size_t scheme_end = trimmed.find("://");
        if (scheme_end == std::string_view::npos || scheme_end + 3 >= trimmed.size()) {
            return std::nullopt;
        }
        return std::string(trimmed);
    }

    const auto base_opt = normalize_spclient_base_url(
        spclient_base_url.empty() ? std::string_view(kDefaultSpclientBaseUrl) : spclient_base_url);
    if (!base_opt.has_value()) {
        return std::nullopt;
    }
    const std::string& base = *base_opt;

    // 2. hm://<path> -> GET <spclient_base_url>/<path> (`0xe0340c`)
    if (istarts_with(trimmed, "hm://")) {
        const std::string_view path = strip_leading_slashes(trimmed.substr(5));
        if (path.empty()) {
            return std::nullopt;
        }
        return base + std::string(path);
    }

    // 3. context://<uri_or_path> -> GET <spclient_base_url>/context-resolve/v1/<uri_or_path> (`0xe02ad8`)
    if (istarts_with(trimmed, "context://")) {
        const std::string_view rest = strip_leading_slashes(trimmed.substr(10));
        if (rest.empty()) {
            return std::nullopt;
        }
        if (istarts_with(rest, "context-resolve/v1/")) {
            return base + std::string(rest);
        }
        return base + "context-resolve/v1/" + std::string(rest);
    }

    // 4. context-page://<uri_or_path> -> GET <spclient_base_url>/context-resolve/v1/<uri_or_path> (`0xe03264`)
    if (istarts_with(trimmed, "context-page://")) {
        const std::string_view rest = strip_leading_slashes(trimmed.substr(15));
        if (rest.empty()) {
            return std::nullopt;
        }
        if (istarts_with(rest, "context-resolve/v1/")) {
            return base + std::string(rest);
        }
        return base + "context-resolve/v1/" + std::string(rest);
    }

    // 5. spotify:<uri> -> GET <spclient_base_url>/context-resolve/v1/spotify:<uri>
    if (istarts_with(trimmed, "spotify:")) {
        if (trimmed.size() <= 8) {
            return std::nullopt;
        }
        return base + "context-resolve/v1/" + std::string(trimmed);
    }

    return std::nullopt;
}

ContextResolveResult ContextResolveClient::parse_context_json(
    std::string_view json_body,
    std::string_view request_url,
    int32_t http_status) {
    ContextResolveResult result;
    result.http_status = http_status;
    result.resolved_url.assign(request_url);

    if (json_body.empty()) {
        result.error_code = ContextResolveErrorCode::kEmptyResponse;
        result.error_message = "Context resolve response body is empty";
        return result;
    }

    const auto root = json::parse_json(json_body);
    if (!root.has_value() || !root->is_object()) {
        result.error_code = ContextResolveErrorCode::kParseError;
        result.error_message = "Context resolve response is not a valid JSON object";
        return result;
    }

    ResolvedContext ctx;
    ctx.uri = root->get_string("uri").value_or(std::string{});
    ctx.url = root->get_string("url").value_or(std::string{});
    if (const auto* md = root->find("metadata"); md != nullptr && md->is_object()) {
        parse_string_metadata_map(*md, ctx.metadata);
    }

    bool found_pages_or_tracks = false;
    if (const auto* pages = root->find("pages"); pages != nullptr && pages->is_array()) {
        found_pages_or_tracks = true;
        int32_t page_idx = 0;
        for (const auto& page_node : pages->array_value) {
            parse_json_page_node(page_node, page_idx++, ctx);
        }
    } else if (const auto* top_tracks = root->find("tracks");
               top_tracks != nullptr && top_tracks->is_array()) {
        found_pages_or_tracks = true;
        parse_json_page_node(*root, 0, ctx);
    }

    if (!found_pages_or_tracks && ctx.uri.empty() && ctx.url.empty()) {
        result.error_code = ContextResolveErrorCode::kParseError;
        result.error_message =
            "Context resolve JSON missing uri, url, pages, and tracks fields";
        return result;
    }

    result.ok = true;
    result.error_code = ContextResolveErrorCode::kNone;
    result.context = std::move(ctx);
    return result;
}

ContextResolveResult ContextResolveClient::resolve(
    std::string_view uri_or_url,
    int connect_timeout_ms,
    int read_timeout_ms,
    const network::CancelPredicate& cancel_pred) const {
    std::string base_url;
    TransportFn transport_fn;
    network::NativeHttpClient* http_client = nullptr;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        base_url = spclient_base_url_;
        transport_fn = transport_fn_;
        http_client = http_client_;
    }

    const auto url_opt = normalize_context_url(uri_or_url, base_url);
    if (!url_opt.has_value()) {
        PLAYER_REMOTE_LOGW(
            "ContextResolveClient: cannot normalize context URI/URL '%s'",
            sanitize_url_for_log(uri_or_url).c_str());
        ContextResolveResult err;
        err.ok = false;
        err.error_code = ContextResolveErrorCode::kInvalidUriOrUrl;
        err.error_message = "Unsupported or malformed Spotify context URI/URL";
        return err;
    }

    const std::string& resolved_url = *url_opt;
    const std::string safe_url = sanitize_url_for_log(resolved_url);
    PLAYER_REMOTE_LOGI("ContextResolveClient: GET %s", safe_url.c_str());

    const std::vector<std::pair<std::string, std::string>> headers = {
        {"Accept", "application/json"},
    };
    network::HttpRequestOptions options;
    options.connect_timeout_ms = connect_timeout_ms;
    options.read_timeout_ms = read_timeout_ms;
    options.include_spotify_auth = true;
    options.include_cookie = false;
    options.cancel_pred = cancel_pred;

    network::HttpResponse resp;
    if (transport_fn) {
        resp = transport_fn(resolved_url, headers, options);
    } else if (http_client != nullptr) {
        resp = http_client->get(resolved_url, headers, options);
    } else {
        PLAYER_REMOTE_LOGE(
            "ContextResolveClient: no HTTP transport configured for %s",
            safe_url.c_str());
        ContextResolveResult err;
        err.ok = false;
        err.error_code = ContextResolveErrorCode::kTransportError;
        err.resolved_url = resolved_url;
        err.error_message = "ContextResolveClient has no HTTP transport configured";
        return err;
    }

    if (!resp.transport_ok) {
        PLAYER_REMOTE_LOGE(
            "ContextResolveClient: transport error status=%d url=%s",
            resp.status_code,
            safe_url.c_str());
        ContextResolveResult err;
        err.ok = false;
        err.error_code = ContextResolveErrorCode::kTransportError;
        err.http_status = resp.status_code;
        err.resolved_url = resolved_url;
        err.error_message = "HTTP transport failure resolving Spotify context";
        return err;
    }

    if (!resp.isSuccess()) {
        PLAYER_REMOTE_LOGW(
            "ContextResolveClient: HTTP %d bytes=%zu url=%s",
            resp.status_code,
            resp.body.size(),
            safe_url.c_str());
        ContextResolveResult err;
        err.ok = false;
        err.error_code = ContextResolveErrorCode::kHttpError;
        err.http_status = resp.status_code;
        err.resolved_url = resolved_url;
        err.error_message =
            "Context resolve returned HTTP " + std::to_string(resp.status_code);
        return err;
    }

    if (resp.body.empty()) {
        PLAYER_REMOTE_LOGW(
            "ContextResolveClient: empty 2xx body status=%d url=%s",
            resp.status_code,
            safe_url.c_str());
        ContextResolveResult err;
        err.ok = false;
        err.error_code = ContextResolveErrorCode::kEmptyResponse;
        err.http_status = resp.status_code;
        err.resolved_url = resolved_url;
        err.error_message = "Context resolve returned empty HTTP body";
        return err;
    }

    const std::string_view body_view(
        reinterpret_cast<const char*>(resp.body.data()),
        resp.body.size());
    ContextResolveResult parsed =
        parse_context_json(body_view, resolved_url, resp.status_code);
    if (!parsed.ok) {
        PLAYER_REMOTE_LOGE(
            "ContextResolveClient: parse failed (%s) url=%s",
            parsed.error_message.c_str(),
            safe_url.c_str());
    } else if (parsed.context.has_value()) {
        PLAYER_REMOTE_LOGI(
            "ContextResolveClient: resolved uri=%s pages=%zu tracks=%zu url=%s",
            parsed.context->uri.c_str(),
            parsed.context->pages.size(),
            parsed.context->all_tracks.size(),
            safe_url.c_str());
    }
    return parsed;
}

}  // namespace spotify::player
