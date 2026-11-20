// ============================================================================
// Sanitized Native Logcat Diagnostics for Network, Connect, Dealer & Player
// Tags: [NET-NATIVE], [CONNECT], [DEALER], [PLAYER-REMOTE]
// Security invariant: Never log Authorization, client-token, Cookie, or raw
//                     ?access_token= query parameters.
// ============================================================================

#pragma once

#ifdef __ANDROID__
#include <android/log.h>
#else
#define ANDROID_LOG_DEBUG 3
#define ANDROID_LOG_INFO 4
#define ANDROID_LOG_WARN 5
#define ANDROID_LOG_ERROR 6
#endif

#include <cctype>
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <string>
#include <string_view>

namespace spotify::network {

#if defined(__GNUC__) || defined(__clang__)
__attribute__((format(printf, 4, 5)))
#endif
inline void native_log_print(
    int priority,
    const char* android_tag,
    const char* bracket_prefix,
    const char* fmt,
    ...) noexcept {
    if (!fmt) {
        return;
    }

    char message_buf[2048];
    va_list args;
    va_start(args, fmt);
    const int written = std::vsnprintf(message_buf, sizeof(message_buf), fmt, args);
    va_end(args);

    if (written < 0) {
        return;
    }

    const char* safe_tag = (android_tag && android_tag[0] != '\0') ? android_tag : "MusifyNative";
    const char* safe_prefix = bracket_prefix ? bracket_prefix : "";

#ifdef __ANDROID__
    __android_log_print(priority, safe_tag, "%s%s", safe_prefix, message_buf);
#else
    std::fprintf(stderr, "[%s/%d] %s%s\n", safe_tag, priority, safe_prefix, message_buf);
#endif
}

[[nodiscard]] inline bool ascii_iequals(std::string_view a, std::string_view b) noexcept {
    if (a.size() != b.size()) {
        return false;
    }
    for (size_t i = 0; i < a.size(); ++i) {
        if (std::tolower(static_cast<unsigned char>(a[i])) !=
            std::tolower(static_cast<unsigned char>(b[i]))) {
            return false;
        }
    }
    return true;
}

[[nodiscard]] inline bool ascii_istarts_with(
    std::string_view str,
    std::string_view prefix) noexcept {
    if (str.size() < prefix.size()) {
        return false;
    }
    return ascii_iequals(str.substr(0, prefix.size()), prefix);
}

[[nodiscard]] inline bool is_sensitive_header_name(std::string_view header_name) noexcept {
    return ascii_iequals(header_name, "authorization") ||
           ascii_iequals(header_name, "client-token") ||
           ascii_iequals(header_name, "cookie") ||
           ascii_iequals(header_name, "set-cookie") ||
           ascii_iequals(header_name, "proxy-authorization") ||
           ascii_iequals(header_name, "x-spotify-access-token");
}

[[nodiscard]] inline std::string sanitize_header_value_for_log(
    std::string_view header_name,
    std::string_view header_value) {
    if (is_sensitive_header_name(header_name)) {
        return header_value.empty() ? "<empty>" : "<redacted>";
    }
    return std::string(header_value);
}

/// Redacts sensitive query string parameters (`access_token`, `client_token`,
/// `sp_dc`, `token`) from URLs before emitting to Android logcat.
[[nodiscard]] inline std::string sanitize_url_for_log(std::string_view url) {
    if (url.empty()) {
        return {};
    }

    const size_t query_pos = url.find('?');
    if (query_pos == std::string_view::npos) {
        return std::string(url);
    }

    std::string out(url.substr(0, query_pos + 1));
    out.reserve(url.size());

    std::string_view rest = url.substr(query_pos + 1);
    std::string_view fragment;
    const size_t hash_pos = rest.find('#');
    if (hash_pos != std::string_view::npos) {
        fragment = rest.substr(hash_pos);
        rest = rest.substr(0, hash_pos);
    }

    bool first_param = true;
    size_t cursor = 0;
    while (cursor <= rest.size()) {
        const size_t amp = rest.find('&', cursor);
        const std::string_view pair =
            (amp == std::string_view::npos)
                ? rest.substr(cursor)
                : rest.substr(cursor, amp - cursor);

        if (!first_param) {
            out.push_back('&');
        }
        first_param = false;

        const size_t eq = pair.find('=');
        if (eq == std::string_view::npos) {
            out.append(pair);
        } else {
            const std::string_view key = pair.substr(0, eq);
            if (ascii_iequals(key, "access_token") ||
                ascii_iequals(key, "client_token") ||
                ascii_iequals(key, "client-token") ||
                ascii_iequals(key, "sp_dc") ||
                ascii_iequals(key, "token")) {
                out.append(key);
                out.append("=<redacted>");
            } else {
                out.append(pair);
            }
        }

        if (amp == std::string_view::npos) {
            break;
        }
        cursor = amp + 1;
    }

    if (!fragment.empty()) {
        out.append(fragment);
    }
    return out;
}

}  // namespace spotify::network

namespace spotify::connectstate {
using ::spotify::network::is_sensitive_header_name;
using ::spotify::network::sanitize_header_value_for_log;
using ::spotify::network::sanitize_url_for_log;
}  // namespace spotify::connectstate

namespace spotify::player {
using ::spotify::network::is_sensitive_header_name;
using ::spotify::network::sanitize_header_value_for_log;
using ::spotify::network::sanitize_url_for_log;
}  // namespace spotify::player

// [NET-NATIVE] macros
#define NET_LOGD(...) \
    ::spotify::network::native_log_print(ANDROID_LOG_DEBUG, "MusifyNetNative", "[NET-NATIVE] ", __VA_ARGS__)
#define NET_LOGI(...) \
    ::spotify::network::native_log_print(ANDROID_LOG_INFO, "MusifyNetNative", "[NET-NATIVE] ", __VA_ARGS__)
#define NET_LOGW(...) \
    ::spotify::network::native_log_print(ANDROID_LOG_WARN, "MusifyNetNative", "[NET-NATIVE] ", __VA_ARGS__)
#define NET_LOGE(...) \
    ::spotify::network::native_log_print(ANDROID_LOG_ERROR, "MusifyNetNative", "[NET-NATIVE] ", __VA_ARGS__)

#define NATIVE_NET_LOGD(...) NET_LOGD(__VA_ARGS__)
#define NATIVE_NET_LOGI(...) NET_LOGI(__VA_ARGS__)
#define NATIVE_NET_LOGW(...) NET_LOGW(__VA_ARGS__)
#define NATIVE_NET_LOGE(...) NET_LOGE(__VA_ARGS__)

// [CONNECT] macros
#define CONNECT_LOGD(...) \
    ::spotify::network::native_log_print(ANDROID_LOG_DEBUG, "MusifyConnect", "[CONNECT] ", __VA_ARGS__)
#define CONNECT_LOGI(...) \
    ::spotify::network::native_log_print(ANDROID_LOG_INFO, "MusifyConnect", "[CONNECT] ", __VA_ARGS__)
#define CONNECT_LOGW(...) \
    ::spotify::network::native_log_print(ANDROID_LOG_WARN, "MusifyConnect", "[CONNECT] ", __VA_ARGS__)
#define CONNECT_LOGE(...) \
    ::spotify::network::native_log_print(ANDROID_LOG_ERROR, "MusifyConnect", "[CONNECT] ", __VA_ARGS__)

#define NATIVE_CONNECT_LOGD(...) CONNECT_LOGD(__VA_ARGS__)
#define NATIVE_CONNECT_LOGI(...) CONNECT_LOGI(__VA_ARGS__)
#define NATIVE_CONNECT_LOGW(...) CONNECT_LOGW(__VA_ARGS__)
#define NATIVE_CONNECT_LOGE(...) CONNECT_LOGE(__VA_ARGS__)

// [DEALER] macros
#define DEALER_LOGD(...) \
    ::spotify::network::native_log_print(ANDROID_LOG_DEBUG, "MusifyDealer", "[DEALER] ", __VA_ARGS__)
#define DEALER_LOGI(...) \
    ::spotify::network::native_log_print(ANDROID_LOG_INFO, "MusifyDealer", "[DEALER] ", __VA_ARGS__)
#define DEALER_LOGW(...) \
    ::spotify::network::native_log_print(ANDROID_LOG_WARN, "MusifyDealer", "[DEALER] ", __VA_ARGS__)
#define DEALER_LOGE(...) \
    ::spotify::network::native_log_print(ANDROID_LOG_ERROR, "MusifyDealer", "[DEALER] ", __VA_ARGS__)

#define NATIVE_DEALER_LOGD(...) DEALER_LOGD(__VA_ARGS__)
#define NATIVE_DEALER_LOGI(...) DEALER_LOGI(__VA_ARGS__)
#define NATIVE_DEALER_LOGW(...) DEALER_LOGW(__VA_ARGS__)
#define NATIVE_DEALER_LOGE(...) DEALER_LOGE(__VA_ARGS__)

// [PLAYER-REMOTE] macros
#define PLAYER_REMOTE_LOGD(...) \
    ::spotify::network::native_log_print(ANDROID_LOG_DEBUG, "MusifyPlayerRemote", "[PLAYER-REMOTE] ", __VA_ARGS__)
#define PLAYER_REMOTE_LOGI(...) \
    ::spotify::network::native_log_print(ANDROID_LOG_INFO, "MusifyPlayerRemote", "[PLAYER-REMOTE] ", __VA_ARGS__)
#define PLAYER_REMOTE_LOGW(...) \
    ::spotify::network::native_log_print(ANDROID_LOG_WARN, "MusifyPlayerRemote", "[PLAYER-REMOTE] ", __VA_ARGS__)
#define PLAYER_REMOTE_LOGE(...) \
    ::spotify::network::native_log_print(ANDROID_LOG_ERROR, "MusifyPlayerRemote", "[PLAYER-REMOTE] ", __VA_ARGS__)

#define NATIVE_PLAYER_REMOTE_LOGD(...) PLAYER_REMOTE_LOGD(__VA_ARGS__)
#define NATIVE_PLAYER_REMOTE_LOGI(...) PLAYER_REMOTE_LOGI(__VA_ARGS__)
#define NATIVE_PLAYER_REMOTE_LOGW(...) PLAYER_REMOTE_LOGW(__VA_ARGS__)
#define NATIVE_PLAYER_REMOTE_LOGE(...) PLAYER_REMOTE_LOGE(__VA_ARGS__)
