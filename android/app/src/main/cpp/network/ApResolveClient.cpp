// ============================================================================
// 1:1 Replicated Spotify APResolve v2 Host Resolution Client
// Sources (`liborbit-jni-spotify.so` arm64):
// - 0x3880fa @ 0x12f6eb4 ("https://apresolve.spotify.com/v2")
// - 0x34155b @ 0x12f6f0c ("time=%lld&type=accesspoint&type=spclient&type=dealer-g2")
// - 0x35f9ee @ 0x12f7c28 ("spclient.global"), 0x349147 @ 0x12f7c44 ("spclient.regional")
// - 0x446e09 @ 0x12f7cd4 ("dealer-g2")
// - 0x350245 @ 0xb1d15c ("https://spclient.wg.spotify.com")
// - 0x384919 @ 0xb1d148 ("wss://dealer.g2.spotify.com:443")
// ============================================================================

#include "ApResolveClient.h"

#include "NativeLog.h"

#include <cctype>
#include <chrono>
#include <cstdio>
#include <utility>

namespace spotify::network {

namespace {

std::string_view trim_ascii(std::string_view sv) noexcept {
    size_t start = 0;
    while (start < sv.size() && std::isspace(static_cast<unsigned char>(sv[start]))) {
        start++;
    }
    size_t end = sv.size();
    while (end > start && std::isspace(static_cast<unsigned char>(sv[end - 1]))) {
        end--;
    }
    return sv.substr(start, end - start);
}

class JsonCursor {
public:
    explicit JsonCursor(std::string_view src) noexcept : src_(src) {}

    void skip_ws() noexcept {
        while (pos_ < src_.size() && std::isspace(static_cast<unsigned char>(src_[pos_]))) {
            ++pos_;
        }
    }

    [[nodiscard]] bool eof() const noexcept { return pos_ >= src_.size(); }

    [[nodiscard]] char peek() const noexcept {
        return pos_ < src_.size() ? src_[pos_] : '\0';
    }

    bool consume_char(char expected) noexcept {
        skip_ws();
        if (pos_ < src_.size() && src_[pos_] == expected) {
            ++pos_;
            return true;
        }
        return false;
    }

    bool parse_string(std::string& out) {
        skip_ws();
        if (pos_ >= src_.size() || src_[pos_] != '"') {
            return false;
        }
        ++pos_;
        out.clear();
        while (pos_ < src_.size()) {
            const char c = src_[pos_++];
            if (c == '"') {
                return true;
            }
            if (c == '\\') {
                if (pos_ >= src_.size()) {
                    return false;
                }
                const char esc = src_[pos_++];
                switch (esc) {
                    case '"':
                    case '\\':
                    case '/':
                        out.push_back(esc);
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
                    case 'u':
                        if (pos_ + 4 > src_.size()) {
                            return false;
                        }
                        pos_ += 4;
                        break;
                    default:
                        out.push_back(esc);
                        break;
                }
            } else {
                out.push_back(c);
            }
        }
        return false;
    }

    bool parse_string_array(std::vector<std::string>& out) {
        if (!consume_char('[')) {
            return false;
        }
        out.clear();
        skip_ws();
        if (consume_char(']')) {
            return true;
        }
        while (!eof()) {
            skip_ws();
            if (peek() == '"') {
                std::string item;
                if (!parse_string(item)) {
                    return false;
                }
                if (!item.empty()) {
                    out.push_back(std::move(item));
                }
            } else {
                if (!skip_value()) {
                    return false;
                }
            }
            skip_ws();
            if (consume_char(']')) {
                return true;
            }
            if (!consume_char(',')) {
                return false;
            }
        }
        return false;
    }

    bool skip_value() {
        skip_ws();
        if (eof()) {
            return false;
        }
        const char c = peek();
        if (c == '"') {
            std::string dummy;
            return parse_string(dummy);
        }
        if (c == '{') {
            ++pos_;
            skip_ws();
            if (consume_char('}')) {
                return true;
            }
            while (!eof()) {
                std::string key;
                if (!parse_string(key) || !consume_char(':') || !skip_value()) {
                    return false;
                }
                skip_ws();
                if (consume_char('}')) {
                    return true;
                }
                if (!consume_char(',')) {
                    return false;
                }
            }
            return false;
        }
        if (c == '[') {
            ++pos_;
            skip_ws();
            if (consume_char(']')) {
                return true;
            }
            while (!eof()) {
                if (!skip_value()) {
                    return false;
                }
                skip_ws();
                if (consume_char(']')) {
                    return true;
                }
                if (!consume_char(',')) {
                    return false;
                }
            }
            return false;
        }
        const size_t start = pos_;
        while (pos_ < src_.size()) {
            const char ch = src_[pos_];
            if (ch == ',' || ch == '}' || ch == ']' ||
                std::isspace(static_cast<unsigned char>(ch))) {
                break;
            }
            ++pos_;
        }
        return pos_ > start;
    }

private:
    std::string_view src_;
    size_t pos_{0};
};

bool parse_spclient_field(
    JsonCursor& cursor,
    std::vector<std::string>& out_regional,
    std::vector<std::string>& out_global) {
    cursor.skip_ws();
    if (cursor.peek() == '[') {
        return cursor.parse_string_array(out_regional);
    }
    if (!cursor.consume_char('{')) {
        return cursor.skip_value();
    }
    cursor.skip_ws();
    if (cursor.consume_char('}')) {
        return true;
    }
    while (!cursor.eof()) {
        std::string key;
        if (!cursor.parse_string(key) || !cursor.consume_char(':')) {
            return false;
        }
        cursor.skip_ws();
        if (key == "regional") {
            if (!cursor.parse_string_array(out_regional)) {
                return false;
            }
        } else if (key == "global") {
            if (!cursor.parse_string_array(out_global)) {
                return false;
            }
        } else {
            if (!cursor.skip_value()) {
                return false;
            }
        }
        cursor.skip_ws();
        if (cursor.consume_char('}')) {
            return true;
        }
        if (!cursor.consume_char(',')) {
            return false;
        }
    }
    return false;
}

bool has_explicit_port(std::string_view authority) noexcept {
    if (authority.empty()) {
        return false;
    }
    if (authority.front() == '[') {
        const size_t close_bracket = authority.find(']');
        if (close_bracket == std::string_view::npos) {
            return false;
        }
        return close_bracket + 1 < authority.size() && authority[close_bracket + 1] == ':';
    }
    const size_t colon = authority.rfind(':');
    return colon != std::string_view::npos && colon + 1 < authority.size();
}

}  // namespace

ApResolveClient::ApResolveClient(NativeHttpClient& http_client)
    : http_client_(&http_client) {}

ApResolveClient::ApResolveClient(TransportFn transport_fn)
    : transport_fn_(std::move(transport_fn)) {}

std::string ApResolveClient::build_request_url(int64_t epoch_seconds) {
    char buf[256];
    std::snprintf(
        buf,
        sizeof(buf),
        "%s?time=%lld&type=accesspoint&type=spclient&type=dealer-g2",
        kApResolveEndpoint,
        static_cast<long long>(epoch_seconds));
    return std::string(buf);
}

std::string ApResolveClient::normalize_spclient_url(std::string_view raw_host_or_url) {
    std::string_view sv = trim_ascii(raw_host_or_url);
    while (!sv.empty() && sv.back() == '/') {
        sv.remove_suffix(1);
    }
    if (sv.empty()) {
        return {};
    }

    if (ascii_istarts_with(sv, "https://")) {
        sv.remove_prefix(8);
    } else if (ascii_istarts_with(sv, "http://")) {
        sv.remove_prefix(7);
    } else if (ascii_istarts_with(sv, "wss://")) {
        sv.remove_prefix(6);
    } else if (ascii_istarts_with(sv, "ws://")) {
        sv.remove_prefix(5);
    }

    const size_t slash = sv.find('/');
    if (slash != std::string_view::npos) {
        sv = sv.substr(0, slash);
    }
    sv = trim_ascii(sv);
    if (sv.empty()) {
        return {};
    }

    if (sv.size() > 4 && sv.substr(sv.size() - 4) == ":443") {
        sv.remove_suffix(4);
    } else if (sv.size() > 3 && sv.substr(sv.size() - 3) == ":80") {
        sv.remove_suffix(3);
    }
    if (sv.empty()) {
        return {};
    }

    std::string out("https://");
    out.append(sv);
    out.push_back('/');
    return out;
}

std::string ApResolveClient::normalize_dealer_ws_url(std::string_view raw_host_or_url) {
    std::string_view sv = trim_ascii(raw_host_or_url);
    while (!sv.empty() && sv.back() == '/') {
        sv.remove_suffix(1);
    }
    if (sv.empty()) {
        return {};
    }

    std::string scheme = "wss://";
    if (ascii_istarts_with(sv, "wss://")) {
        sv.remove_prefix(6);
    } else if (ascii_istarts_with(sv, "ws://")) {
        scheme = "ws://";
        sv.remove_prefix(5);
    } else if (ascii_istarts_with(sv, "https://")) {
        sv.remove_prefix(8);
    } else if (ascii_istarts_with(sv, "http://")) {
        scheme = "ws://";
        sv.remove_prefix(7);
    }

    const size_t slash = sv.find('/');
    if (slash != std::string_view::npos) {
        sv = sv.substr(0, slash);
    }
    sv = trim_ascii(sv);
    if (sv.empty()) {
        return {};
    }

    std::string out(scheme);
    out.append(sv);
    if (!has_explicit_port(sv)) {
        out.append(":443");
    }
    out.push_back('/');
    return out;
}

ApResolveResult ApResolveClient::fallback_result(std::string error_message, int32_t http_status) {
    ApResolveResult res;
    res.ok = false;
    res.used_fallback = true;
    res.http_status = http_status;
    res.spclient_base_url = kFallbackSpclientBaseUrl;
    res.spclient_global_url = kFallbackSpclientBaseUrl;
    res.dealer_ws_url = kFallbackDealerWsUrl;
    res.error_message = std::move(error_message);
    return res;
}

ApResolveResult ApResolveClient::parse_response_json(
    std::string_view json_body,
    int32_t http_status) {
    JsonCursor cursor(json_body);
    if (!cursor.consume_char('{')) {
        return fallback_result("Malformed APResolve v2 JSON: expected root object", http_status);
    }

    ApResolveResult res;
    res.http_status = http_status;
    res.spclient_base_url = kFallbackSpclientBaseUrl;
    res.spclient_global_url = kFallbackSpclientBaseUrl;
    res.dealer_ws_url = kFallbackDealerWsUrl;

    std::vector<std::string> legacy_dealer_hosts;

    cursor.skip_ws();
    if (!cursor.consume_char('}')) {
        while (!cursor.eof()) {
            std::string key;
            if (!cursor.parse_string(key) || !cursor.consume_char(':')) {
                return fallback_result("Malformed APResolve v2 JSON key/value pair", http_status);
            }
            if (key == "spclient") {
                if (!parse_spclient_field(
                        cursor,
                        res.spclient_regional_hosts,
                        res.spclient_global_hosts)) {
                    return fallback_result("Malformed APResolve v2 spclient field", http_status);
                }
            } else if (key == "dealer-g2") {
                if (!cursor.parse_string_array(res.dealer_g2_hosts)) {
                    return fallback_result("Malformed APResolve v2 dealer-g2 field", http_status);
                }
            } else if (key == "dealer") {
                if (!cursor.parse_string_array(legacy_dealer_hosts)) {
                    return fallback_result("Malformed APResolve v2 dealer field", http_status);
                }
            } else if (key == "accesspoint") {
                if (!cursor.parse_string_array(res.accesspoint_hosts)) {
                    return fallback_result("Malformed APResolve v2 accesspoint field", http_status);
                }
            } else {
                if (!cursor.skip_value()) {
                    return fallback_result("Malformed APResolve v2 value", http_status);
                }
            }

            cursor.skip_ws();
            if (cursor.consume_char('}')) {
                break;
            }
            if (!cursor.consume_char(',')) {
                return fallback_result("Malformed APResolve v2 JSON object delimiter", http_status);
            }
        }
    }

    if (res.dealer_g2_hosts.empty() && !legacy_dealer_hosts.empty()) {
        res.dealer_g2_hosts = std::move(legacy_dealer_hosts);
    }

    std::string resolved_regional_spclient;
    for (const auto& host : res.spclient_regional_hosts) {
        resolved_regional_spclient = normalize_spclient_url(host);
        if (!resolved_regional_spclient.empty()) {
            break;
        }
    }

    std::string resolved_global_spclient;
    for (const auto& host : res.spclient_global_hosts) {
        resolved_global_spclient = normalize_spclient_url(host);
        if (!resolved_global_spclient.empty()) {
            break;
        }
    }

    std::string resolved_dealer;
    for (const auto& host : res.dealer_g2_hosts) {
        resolved_dealer = normalize_dealer_ws_url(host);
        if (!resolved_dealer.empty()) {
            break;
        }
    }

    const bool has_spclient =
        !resolved_regional_spclient.empty() || !resolved_global_spclient.empty();
    const bool has_dealer = !resolved_dealer.empty();

    if (!resolved_global_spclient.empty()) {
        res.spclient_global_url = resolved_global_spclient;
    } else if (!resolved_regional_spclient.empty()) {
        res.spclient_global_url = resolved_regional_spclient;
    }

    if (!resolved_regional_spclient.empty()) {
        res.spclient_base_url = resolved_regional_spclient;
    } else if (!resolved_global_spclient.empty()) {
        res.spclient_base_url = resolved_global_spclient;
    }

    if (has_dealer) {
        res.dealer_ws_url = resolved_dealer;
    }

    res.ok = has_spclient && has_dealer;
    res.used_fallback = !res.ok;
    if (!res.ok) {
        res.error_message = "APResolve v2 response missing spclient or dealer-g2 endpoints; applied fallback";
    }
    return res;
}

ApResolveResult ApResolveClient::resolve(
    int connect_timeout_ms,
    int read_timeout_ms,
    const CancelPredicate& cancel_pred) const {
    const auto now_sec = std::chrono::duration_cast<std::chrono::seconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    const std::string url = build_request_url(static_cast<int64_t>(now_sec));

    HttpResponse resp;
    if (transport_fn_) {
        resp = transport_fn_(url);
    } else if (http_client_) {
        HttpRequestOptions opts;
        opts.connect_timeout_ms = connect_timeout_ms;
        opts.read_timeout_ms = read_timeout_ms;
        opts.include_spotify_auth = false;
        opts.include_cookie = false;
        opts.cancel_pred = cancel_pred;
        resp = http_client_->get(
            url,
            {{"Accept", "application/json"}},
            opts);
    } else {
        auto fb = fallback_result("ApResolveClient has no HTTP transport configured", 0);
        NET_LOGW("APResolve fallback (%s): spclient=%s dealer=%s",
                 fb.error_message.c_str(),
                 fb.spclient_base_url.c_str(),
                 fb.dealer_ws_url.c_str());
        return fb;
    }

    if (!resp.isSuccess() || resp.body.empty()) {
        auto fb = fallback_result(
            resp.transport_ok
                ? ("APResolve HTTP status " + std::to_string(resp.status_code))
                : "APResolve transport failure",
            resp.status_code);
        NET_LOGW("APResolve failed (%s) -> fallback spclient=%s dealer=%s",
                 fb.error_message.c_str(),
                 fb.spclient_base_url.c_str(),
                 fb.dealer_ws_url.c_str());
        return fb;
    }

    const std::string_view body_view(
        reinterpret_cast<const char*>(resp.body.data()),
        resp.body.size());
    ApResolveResult result = parse_response_json(body_view, resp.status_code);
    if (result.ok) {
        NET_LOGI("APResolve v2 resolved: spclient=%s (global=%s, regional_count=%zu) dealer=%s (count=%zu)",
                 result.spclient_base_url.c_str(),
                 result.spclient_global_url.c_str(),
                 result.spclient_regional_hosts.size(),
                 result.dealer_ws_url.c_str(),
                 result.dealer_g2_hosts.size());
    } else {
        NET_LOGW("APResolve v2 partial/fallback (%s): spclient=%s dealer=%s",
                 result.error_message.c_str(),
                 result.spclient_base_url.c_str(),
                 result.dealer_ws_url.c_str());
    }
    return result;
}

}  // namespace spotify::network
