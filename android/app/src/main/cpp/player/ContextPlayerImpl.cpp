// ============================================================================
// 1:1 Replicated Spotify ContextPlayerImpl & Connect Bidirectional Hooks
// Sources (`liborbit-jni-spotify.so` arm64):
// - ContextPlayerImpl command/state dispatcher & Connect state sync
// - ELF FileDescriptorProto `player.proto` (`0x635f80`)
// - `transfer_state.proto` (`0x60c1c4`), `playback.proto` (`0x60a6c0`),
//   `session.proto` (`0x60ba78`), `queue.proto` (`0x60a8d4`),
//   `context.proto` (`0x6094fc`), `context_page.proto` (`0x609700`),
//   `context_track.proto` (`0x609c74`), `context_player_options.proto` (`0x609924`),
//   `play_origin.proto` (`0x60a4d8`), `sleep_timer.proto` (`0x60be60`)
// - LocalPlaybackIntentContextPlayer (`0x1090200..0x10924a8`)
// - ConnectApiImpl (`0xda66f0..0xda96ac`, `&not_playing_locally` @ `0xdaa0bc`)
// - ConnectStateImpl::onClusterChanged (`0xdb6740..0xdb7060`)
// ============================================================================

#include "ContextPlayerImpl.h"

#include "SpotifyPlaybackPolicy.h"
#include "../network/NativeLog.h"

#ifdef __ANDROID__
#include <android/log.h>
#define LOG_TAG "ContextPlayer"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#else
#define LOGI(...) do {} while (false)
#define LOGE(...) do {} while (false)
#define LOGW(...) do {} while (false)
#endif

#include <algorithm>
#include <array>
#include <cctype>
#include <charconv>
#include <chrono>
#include <climits>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iterator>
#include <utility>

namespace spotify::player {

namespace {

inline int64_t get_current_timestamp_ms() noexcept {
    const auto now = std::chrono::system_clock::now();
    return std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count();
}

struct DecodedCommandOptions {
    bool override_restrictions{false};
    bool only_for_local_device{false};
    bool system_initiated{false};
    std::string only_for_playback_id;
    bool present{false};
};

struct DecodedLoggingParams {
    std::optional<int64_t> command_initiated_time;
    std::optional<int64_t> command_received_time;
    std::vector<std::string> page_instance_ids;
    std::vector<std::string> interaction_ids;
    std::string device_identifier;
    std::string command_id;
    bool present{false};
};

struct DecodedPlayOptions {
    std::optional<int32_t> reason;
    std::optional<int32_t> operation;
    std::optional<int32_t> trigger;
    std::optional<double> playback_speed;
    bool present{false};
};

struct SkipToOptions {
    std::string page_url;
    std::string track_uri;
    std::string track_uid;
    std::optional<int64_t> page_index;
    int64_t track_index{-1};
};

struct OptionOverrides {
    std::optional<bool> shuffling_context;
    std::optional<bool> repeating_context;
    std::optional<bool> repeating_track;
    std::optional<double> playback_speed;
    std::unordered_map<std::string, std::string> modes;
};

struct DecodedContextPage {
    std::string page_url;
    std::string next_page_url;
    std::unordered_map<std::string, std::string> metadata;
    std::vector<context_view::Entry> tracks;
};

struct DecodedPreparePlay {
    std::string context_uri;
    std::string context_url;
    std::unordered_map<std::string, std::string> context_metadata;
    std::vector<DecodedContextPage> pages;
    std::vector<context_view::Entry> tracks;
    std::vector<size_t> page_track_offsets;
    std::string page_url;
    std::string next_page_url;
    SkipToOptions skip_to;
    OptionOverrides overrides;
    std::optional<int64_t> seek_to_ms;
    std::optional<bool> initially_paused;
    std::optional<bool> always_play_something;
    std::optional<bool> system_initiated;
    std::string session_id;
    std::string license;
    std::vector<std::string> suppressions;
    PlayOriginData play_origin;
    DecodedPlayOptions play_options;
    DecodedCommandOptions command_options;
    DecodedLoggingParams logging_params;
};

struct DecodedPauseResumeRequest {
    DecodedCommandOptions options;
    DecodedLoggingParams logging_params;
    std::string origin_feature_identifier;
};

struct DecodedSeekToRequest {
    DecodedCommandOptions options;
    DecodedLoggingParams logging_params;
    int64_t position_ms{0};
    bool has_position{false};
    std::optional<int32_t> relative;
};

struct DecodedSkipNextRequest {
    DecodedCommandOptions options;
    DecodedLoggingParams logging_params;
    context_view::Entry target_track;
};

struct DecodedSkipPrevRequest {
    DecodedCommandOptions options;
    DecodedLoggingParams logging_params;
    bool allow_seeking{true};
    bool has_allow_seeking{false};
    context_view::Entry target_track;
};

struct DecodedSetOptionsRequest {
    OptionOverrides overrides;
    DecodedCommandOptions options;
    DecodedLoggingParams logging_params;
};

struct DecodedBoolCommandRequest {
    bool value{false};
    bool has_value{false};
    DecodedCommandOptions options;
    DecodedLoggingParams logging_params;
};

struct DecodedAddToQueueRequest {
    context_view::Entry track;
    bool has_track{false};
    DecodedCommandOptions options;
    DecodedLoggingParams logging_params;
};

struct DecodedSetQueueRequest {
    std::vector<context_view::Entry> next_tracks;
    std::vector<context_view::Entry> prev_tracks;
    bool has_prev_tracks{false};
    uint64_t queue_revision{0};
    bool has_queue_revision{false};
    DecodedCommandOptions options;
    DecodedLoggingParams logging_params;
};

struct DecodedPlayAsNextRequest {
    std::vector<context_view::Entry> tracks;
    DecodedCommandOptions options;
    DecodedLoggingParams logging_params;
};

struct DecodedSignalRequest {
    std::string signal_id;
    std::string parameters;
    DecodedCommandOptions options;
    DecodedLoggingParams logging_params;
};

struct DecodedSleepTimerRequest {
    enum class Action : uint8_t {
        kUnset = 0,
        kClear = 1,
        kDurationSeconds = 2,
        kEndOfTrack = 3,
    };
    Action action{Action::kUnset};
    int64_t duration_seconds{0};
    DecodedCommandOptions options;
    DecodedLoggingParams logging_params;
};

struct DecodedPlayPreparedRequest {
    std::string session_id;
    DecodedPlayOptions play_options;
    DecodedCommandOptions options;
    DecodedLoggingParams logging_params;
};

// ============================================================================
// Self-contained `spotify.player.proto.transfer.TransferState` structures
// Exact field numbers verified from `liborbit-jni-spotify.so` FileDescriptorProtos:
// - `transfer_state.proto` @ 0x60c1c4
// - `playback.proto` @ 0x60a6c0
// - `session.proto` @ 0x60ba78
// - `queue.proto` @ 0x60a8d4
// - `context.proto` @ 0x6094fc
// - `context_page.proto` @ 0x609700
// - `context_track.proto` @ 0x609c74
// - `context_player_options.proto` @ 0x609924
// - `play_origin.proto` @ 0x60a4d8
// - `sleep_timer.proto` @ 0x60be60
// ============================================================================

struct TransferPlaybackProto {
    int64_t timestamp_ms{0};
    int32_t position_as_of_timestamp_ms{0};
    double playback_speed{1.0};
    bool has_playback_speed{false};
    bool is_paused{false};
    std::optional<context_view::Entry> current_track;
};

struct TransferContextProto {
    std::string uri;
    std::string url;
    std::unordered_map<std::string, std::string> metadata;
    std::vector<DecodedContextPage> pages;
    std::vector<context_view::Entry> all_tracks;
    std::vector<size_t> page_track_offsets;
    std::string first_page_url;
    std::string first_next_page_url;
};

struct TransferSessionProto {
    PlayOriginData play_origin;
    TransferContextProto context;
    TransferContextProto main_context;
    std::string current_uid;
    OptionOverrides option_overrides;
    std::string shuffle_seed;
    std::string original_session_id;
};

struct TransferQueueProto {
    std::vector<context_view::Entry> tracks;
    bool is_playing_queue{false};
};

struct TransferSleepTimerProto {
    enum class Kind : uint8_t {
        kUnset = 0,
        kNone = 1,
        kTimestamp = 2,
        kEndOfTrack = 3,
    };
    Kind kind{Kind::kUnset};
    int64_t timestamp_ms{0};
};

struct TransferStateProto {
    OptionOverrides options;
    TransferPlaybackProto playback;
    TransferSessionProto current_session;
    TransferQueueProto queue;
    TransferSleepTimerProto sleep_timer;
};

inline bool is_valid_rfc3629_utf8(const uint8_t* bytes, size_t len) noexcept {
    if (bytes == nullptr) {
        return len == 0;
    }
    size_t i = 0;
    while (i < len) {
        const uint8_t b0 = bytes[i];
        if (b0 <= 0x7F) {
            ++i;
            continue;
        }
        if (b0 >= 0xC2 && b0 <= 0xDF) {
            if (i + 1 >= len) return false;
            const uint8_t b1 = bytes[i + 1];
            if (b1 < 0x80 || b1 > 0xBF) return false;
            i += 2;
            continue;
        }
        if (b0 == 0xE0) {
            if (i + 2 >= len) return false;
            const uint8_t b1 = bytes[i + 1];
            const uint8_t b2 = bytes[i + 2];
            if (b1 < 0xA0 || b1 > 0xBF || b2 < 0x80 || b2 > 0xBF) return false;
            i += 3;
            continue;
        }
        if ((b0 >= 0xE1 && b0 <= 0xEC) || (b0 >= 0xEE && b0 <= 0xEF)) {
            if (i + 2 >= len) return false;
            const uint8_t b1 = bytes[i + 1];
            const uint8_t b2 = bytes[i + 2];
            if (b1 < 0x80 || b1 > 0xBF || b2 < 0x80 || b2 > 0xBF) return false;
            i += 3;
            continue;
        }
        if (b0 == 0xED) {
            if (i + 2 >= len) return false;
            const uint8_t b1 = bytes[i + 1];
            const uint8_t b2 = bytes[i + 2];
            if (b1 < 0x80 || b1 > 0x9F || b2 < 0x80 || b2 > 0xBF) return false;
            i += 3;
            continue;
        }
        if (b0 == 0xF0) {
            if (i + 3 >= len) return false;
            const uint8_t b1 = bytes[i + 1];
            const uint8_t b2 = bytes[i + 2];
            const uint8_t b3 = bytes[i + 3];
            if (b1 < 0x90 || b1 > 0xBF || b2 < 0x80 || b2 > 0xBF || b3 < 0x80 || b3 > 0xBF) return false;
            i += 4;
            continue;
        }
        if (b0 >= 0xF1 && b0 <= 0xF3) {
            if (i + 3 >= len) return false;
            const uint8_t b1 = bytes[i + 1];
            const uint8_t b2 = bytes[i + 2];
            const uint8_t b3 = bytes[i + 3];
            if (b1 < 0x80 || b1 > 0xBF || b2 < 0x80 || b2 > 0xBF || b3 < 0x80 || b3 > 0xBF) return false;
            i += 4;
            continue;
        }
        if (b0 == 0xF4) {
            if (i + 3 >= len) return false;
            const uint8_t b1 = bytes[i + 1];
            const uint8_t b2 = bytes[i + 2];
            const uint8_t b3 = bytes[i + 3];
            if (b1 < 0x80 || b1 > 0x8F || b2 < 0x80 || b2 > 0xBF || b3 < 0x80 || b3 > 0xBF) return false;
            i += 4;
            continue;
        }
        return false;
    }
    return true;
}

inline bool is_valid_utf8_string(const std::string& s) noexcept {
    for (unsigned char c : s) {
        if (c == 0x00) {
            return false;
        }
    }
    return is_valid_rfc3629_utf8(reinterpret_cast<const uint8_t*>(s.data()), s.size());
}

inline bool is_valid_utf8_uri(const std::string& uri) noexcept {
    if (uri.empty()) {
        return false;
    }
    const auto* bytes = reinterpret_cast<const uint8_t*>(uri.data());
    if (!is_valid_rfc3629_utf8(bytes, uri.size())) {
        return false;
    }
    size_t i = 0;
    while (i < uri.size()) {
        const uint8_t b0 = bytes[i];
        if (b0 < 0x20 || b0 == 0x7F) {
            return false;
        }
        if (b0 <= 0x7F) {
            ++i;
        } else if (b0 <= 0xDF) {
            if (b0 == 0xC2 && i + 1 < uri.size() &&
                bytes[i + 1] >= 0x80 && bytes[i + 1] <= 0x9F) {
                return false;
            }
            i += 2;
        } else if (b0 <= 0xEF) {
            i += 3;
        } else {
            i += 4;
        }
    }
    return true;
}

std::optional<std::vector<uint8_t>> decode_base64(std::string_view input) {
    static constexpr auto kDecodeTable = []() {
        std::array<int8_t, 256> tbl{};
        tbl.fill(-1);
        for (int c = 'A'; c <= 'Z'; ++c) tbl[static_cast<size_t>(c)] = static_cast<int8_t>(c - 'A');
        for (int c = 'a'; c <= 'z'; ++c) tbl[static_cast<size_t>(c)] = static_cast<int8_t>(26 + c - 'a');
        for (int c = '0'; c <= '9'; ++c) tbl[static_cast<size_t>(c)] = static_cast<int8_t>(52 + c - '0');
        tbl[static_cast<size_t>('+')] = 62;
        tbl[static_cast<size_t>('-')] = 62;  // URL-safe base64
        tbl[static_cast<size_t>('/')] = 63;
        tbl[static_cast<size_t>('_')] = 63;  // URL-safe base64
        return tbl;
    }();

    std::vector<uint8_t> out;
    out.reserve((input.size() * 3) / 4 + 3);
    uint32_t acc = 0;
    int bits = 0;
    bool seen_padding = false;

    for (const char ch : input) {
        const unsigned char c = static_cast<unsigned char>(ch);
        if (c == ' ' || c == '\t' || c == '\r' || c == '\n') {
            continue;
        }
        if (c == '=') {
            seen_padding = true;
            continue;
        }
        if (seen_padding) {
            return std::nullopt;
        }
        const int8_t val = kDecodeTable[c];
        if (val < 0) {
            return std::nullopt;
        }
        acc = (acc << 6) | static_cast<uint32_t>(val);
        bits += 6;
        if (bits >= 8) {
            bits -= 8;
            out.push_back(static_cast<uint8_t>((acc >> bits) & 0xFFU));
        }
    }
    if (bits >= 6) {
        return std::nullopt;
    }
    return out;
}

std::string gid_to_spotify_track_uri(const std::vector<uint8_t>& gid) {
    if (gid.size() != 16) {
        return {};
    }
    static constexpr const char kBase62[] =
        "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    std::array<uint8_t, 16> num{};
    std::copy(gid.begin(), gid.end(), num.begin());

    std::string encoded;
    encoded.reserve(22);
    for (int step = 0; step < 22; ++step) {
        uint32_t remainder = 0;
        for (size_t i = 0; i < 16; ++i) {
            const uint32_t cur = (remainder << 8) | static_cast<uint32_t>(num[i]);
            num[i] = static_cast<uint8_t>(cur / 62U);
            remainder = cur % 62U;
        }
        encoded.push_back(kBase62[remainder]);
    }
    std::reverse(encoded.begin(), encoded.end());
    return "spotify:track:" + encoded;
}

std::vector<uint8_t> playback_id_to_proto_bytes(std::string_view playback_id) {
    if (playback_id.empty()) {
        return {};
    }
    auto hex_nibble = [](char ch) noexcept -> int {
        if (ch >= '0' && ch <= '9') return ch - '0';
        if (ch >= 'a' && ch <= 'f') return 10 + (ch - 'a');
        if (ch >= 'A' && ch <= 'F') return 10 + (ch - 'A');
        return -1;
    };
    if ((playback_id.size() % 2) == 0) {
        bool all_hex = true;
        std::vector<uint8_t> decoded;
        decoded.reserve(playback_id.size() / 2);
        for (size_t i = 0; i < playback_id.size(); i += 2) {
            const int hi = hex_nibble(playback_id[i]);
            const int lo = hex_nibble(playback_id[i + 1]);
            if (hi < 0 || lo < 0) {
                all_hex = false;
                break;
            }
            decoded.push_back(static_cast<uint8_t>((hi << 4) | lo));
        }
        if (all_hex) {
            return decoded;
        }
    }
    return std::vector<uint8_t>(playback_id.begin(), playback_id.end());
}

std::vector<std::string> decode_suppressions_providers(const std::vector<uint8_t>& bytes) {
    std::vector<std::string> providers;
    if (bytes.empty()) {
        return providers;
    }
    const uint8_t* ptr = bytes.data();
    const uint8_t* end = bytes.data() + bytes.size();
    bool ok = true;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) {
            ok = false;
            break;
        }
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 2) {
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || !has_bytes(ptr, end, len)) {
                ok = false;
                break;
            }
            const size_t n = static_cast<size_t>(len);
            std::string prov(reinterpret_cast<const char*>(ptr), n);
            ptr += n;
            if (!prov.empty() && is_valid_utf8_string(prov)) {
                providers.push_back(std::move(prov));
            }
        } else {
            if (!skip_field(ptr, end, w)) {
                ok = false;
                break;
            }
        }
    }
    if (!ok) {
        providers.clear();
    }
    return providers;
}

inline int32_t resolve_initial_track_index(
        const std::vector<context_view::Entry>& tracks,
        const std::string& skip_to_uid,
        const std::string& skip_to_uri,
        std::optional<int64_t> skip_to_page_index,
        int64_t skip_to_track_index,
        const std::vector<size_t>& page_track_offsets) noexcept {
    if (tracks.empty()) {
        return 0;
    }
    if (!skip_to_uid.empty()) {
        for (size_t i = 0; i < tracks.size(); ++i) {
            if (tracks[i].uid == skip_to_uid) {
                return static_cast<int32_t>(i);
            }
        }
    }
    if (!skip_to_uri.empty()) {
        for (size_t i = 0; i < tracks.size(); ++i) {
            if (tracks[i].uri == skip_to_uri) {
                return static_cast<int32_t>(i);
            }
        }
    }
    if (skip_to_track_index >= 0) {
        size_t base_offset = 0;
        size_t page_end = tracks.size();
        if (skip_to_page_index.has_value()) {
            if (*skip_to_page_index < 0 ||
                static_cast<size_t>(*skip_to_page_index) >= page_track_offsets.size()) {
                return 0;
            }
            const size_t page_idx = static_cast<size_t>(*skip_to_page_index);
            base_offset = page_track_offsets[page_idx];
            if (page_idx + 1 < page_track_offsets.size()) {
                page_end = page_track_offsets[page_idx + 1];
            }
        }
        if (page_end >= base_offset) {
            const uint64_t page_span = static_cast<uint64_t>(page_end - base_offset);
            const uint64_t track_idx_u64 = static_cast<uint64_t>(skip_to_track_index);
            if (track_idx_u64 < page_span) {
                const uint64_t raw_idx = static_cast<uint64_t>(base_offset) + track_idx_u64;
                if (raw_idx <= static_cast<uint64_t>(INT32_MAX)) {
                    return static_cast<int32_t>(raw_idx);
                }
            }
        }
    }
    return 0;
}

inline bool decode_bool_value(const uint8_t*& ptr, const uint8_t* end, uint32_t wire_type, bool& out) {
    if (wire_type == 0) {
        uint64_t val = 0;
        if (!decode_varint(ptr, end, val)) return false;
        out = (val != 0);
        return true;
    }
    if (wire_type == 2) {
        uint64_t len = 0;
        if (!decode_varint(ptr, end, len) || !has_bytes(ptr, end, len)) return false;
        const size_t n = static_cast<size_t>(len);
        const uint8_t* sub_ptr = ptr;
        const uint8_t* sub_end = ptr + n;
        ptr += n;
        out = false;
        while (sub_ptr < sub_end) {
            uint64_t tag = 0;
            if (!decode_varint(sub_ptr, sub_end, tag)) return false;
            const uint32_t f = static_cast<uint32_t>(tag >> 3);
            const uint32_t w = static_cast<uint32_t>(tag & 0x07);
            if (f == 1) {
                if (w != 0) return false;
                uint64_t v = 0;
                if (!decode_varint(sub_ptr, sub_end, v)) return false;
                out = (v != 0);
            } else {
                if (!skip_field(sub_ptr, sub_end, w)) return false;
            }
        }
        return true;
    }
    return false;
}

inline bool decode_int64_value(const uint8_t*& ptr, const uint8_t* end, uint32_t wire_type, int64_t& out) {
    if (wire_type == 0) {
        uint64_t val = 0;
        if (!decode_varint(ptr, end, val)) return false;
        out = static_cast<int64_t>(val);
        return true;
    }
    if (wire_type == 2) {
        uint64_t len = 0;
        if (!decode_varint(ptr, end, len) || !has_bytes(ptr, end, len)) return false;
        const size_t n = static_cast<size_t>(len);
        const uint8_t* sub_ptr = ptr;
        const uint8_t* sub_end = ptr + n;
        ptr += n;
        out = 0;
        while (sub_ptr < sub_end) {
            uint64_t tag = 0;
            if (!decode_varint(sub_ptr, sub_end, tag)) return false;
            const uint32_t f = static_cast<uint32_t>(tag >> 3);
            const uint32_t w = static_cast<uint32_t>(tag & 0x07);
            if (f == 1) {
                if (w != 0) return false;
                uint64_t v = 0;
                if (!decode_varint(sub_ptr, sub_end, v)) return false;
                out = static_cast<int64_t>(v);
            } else {
                if (!skip_field(sub_ptr, sub_end, w)) return false;
            }
        }
        return true;
    }
    return false;
}

inline bool decode_uint64_value(const uint8_t*& ptr, const uint8_t* end, uint32_t wire_type, uint64_t& out) {
    if (wire_type == 0) {
        uint64_t val = 0;
        if (!decode_varint(ptr, end, val)) return false;
        out = val;
        return true;
    }
    if (wire_type == 2) {
        uint64_t len = 0;
        if (!decode_varint(ptr, end, len) || !has_bytes(ptr, end, len)) return false;
        const size_t n = static_cast<size_t>(len);
        const uint8_t* sub_ptr = ptr;
        const uint8_t* sub_end = ptr + n;
        ptr += n;
        out = 0;
        while (sub_ptr < sub_end) {
            uint64_t tag = 0;
            if (!decode_varint(sub_ptr, sub_end, tag)) return false;
            const uint32_t f = static_cast<uint32_t>(tag >> 3);
            const uint32_t w = static_cast<uint32_t>(tag & 0x07);
            if (f == 1) {
                if (w != 0) return false;
                uint64_t v = 0;
                if (!decode_varint(sub_ptr, sub_end, v)) return false;
                out = v;
            } else {
                if (!skip_field(sub_ptr, sub_end, w)) return false;
            }
        }
        return true;
    }
    return false;
}

inline bool decode_fixed64_double(const uint8_t*& ptr, const uint8_t* end, double& out) noexcept {
    if (!has_bytes(ptr, end, 8)) return false;
    uint64_t raw = 0;
    for (int i = 0; i < 8; ++i) {
        raw |= (static_cast<uint64_t>(ptr[i]) << (i * 8));
    }
    ptr += 8;
    std::memcpy(&out, &raw, sizeof(double));
    return std::isfinite(out);
}

inline bool decode_fixed32_float(const uint8_t*& ptr, const uint8_t* end, float& out) noexcept {
    if (!has_bytes(ptr, end, 4)) return false;
    uint32_t raw = 0;
    for (int i = 0; i < 4; ++i) {
        raw |= (static_cast<uint32_t>(ptr[i]) << (i * 8));
    }
    ptr += 4;
    std::memcpy(&out, &raw, sizeof(float));
    return std::isfinite(out);
}

inline bool decode_double_value(const uint8_t*& ptr, const uint8_t* end, uint32_t wire_type, double& out) {
    if (wire_type == 1) {
        return decode_fixed64_double(ptr, end, out);
    }
    if (wire_type == 5) {
        float fval = 0.0f;
        if (!decode_fixed32_float(ptr, end, fval)) return false;
        out = static_cast<double>(fval);
        return true;
    }
    if (wire_type == 2) {
        uint64_t len = 0;
        if (!decode_varint(ptr, end, len) || !has_bytes(ptr, end, len)) return false;
        const size_t n = static_cast<size_t>(len);
        const uint8_t* sub_ptr = ptr;
        const uint8_t* sub_end = ptr + n;
        ptr += n;
        out = 0.0;
        while (sub_ptr < sub_end) {
            uint64_t tag = 0;
            if (!decode_varint(sub_ptr, sub_end, tag)) return false;
            const uint32_t f = static_cast<uint32_t>(tag >> 3);
            const uint32_t w = static_cast<uint32_t>(tag & 0x07);
            if (f == 1 && w == 1) {
                if (!decode_fixed64_double(sub_ptr, sub_end, out)) return false;
            } else if (f == 1 && w == 5) {
                float fv = 0.0f;
                if (!decode_fixed32_float(sub_ptr, sub_end, fv)) return false;
                out = static_cast<double>(fv);
            } else {
                if (!skip_field(sub_ptr, sub_end, w)) return false;
            }
        }
        return true;
    }
    return false;
}

inline bool decode_map_entries(
        const uint8_t* ptr,
        size_t len,
        std::unordered_map<std::string, std::string>& out_map) {
    if (ptr == nullptr) return len == 0;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    std::string key;
    std::string val;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 || f == 2) {
            if (w != 2) return false;
            uint64_t entry_len = 0;
            if (!decode_varint(p, end, entry_len) || !has_bytes(p, end, entry_len)) return false;
            const size_t n = static_cast<size_t>(entry_len);
            if (f == 1) {
                key.assign(reinterpret_cast<const char*>(p), n);
            } else {
                val.assign(reinterpret_cast<const char*>(p), n);
            }
            p += n;
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    if (!is_valid_utf8_string(key) || !is_valid_utf8_string(val)) {
        return false;
    }
    if (!key.empty()) {
        out_map[key] = val;
    }
    return true;
}

// Field numbers verified 1:1 against es_command_options.pb.dart:
// 1: override_restrictions (bool), 2: only_for_local_device (bool),
// 3: system_initiated (bool), 4: only_for_playback_id (bytes)
inline bool decode_command_options(
        const uint8_t* ptr,
        size_t len,
        DecodedCommandOptions& out) {
    if (ptr == nullptr) return len == 0;
    out.present = true;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1) {
            if (w != 0) return false;
            if (!decode_bool_value(p, end, w, out.override_restrictions)) return false;
        } else if (f == 2) {
            if (w != 0) return false;
            if (!decode_bool_value(p, end, w, out.only_for_local_device)) return false;
        } else if (f == 3) {
            if (w != 0) return false;
            if (!decode_bool_value(p, end, w, out.system_initiated)) return false;
        } else if (f == 4) {
            if (w != 2) return false;
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            const size_t n = static_cast<size_t>(l);
            out.only_for_playback_id.assign(reinterpret_cast<const char*>(p), n);
            p += n;
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

// Field numbers verified 1:1 against es_logging_params.pb.dart:
// 1: command_initiated_time (OptionalInt64), 2: command_received_time (OptionalInt64),
// 3: page_instance_ids (repeated string), 4: interaction_ids (repeated string),
// 5: device_identifier (string), 6: command_id (string)
inline bool decode_logging_params(
        const uint8_t* ptr,
        size_t len,
        DecodedLoggingParams& out) {
    if (ptr == nullptr) return len == 0;
    out.present = true;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1) {
            if (w != 2 && w != 0) return false;
            int64_t v = 0;
            if (!decode_int64_value(p, end, w, v)) return false;
            out.command_initiated_time = v;
        } else if (f == 2) {
            if (w != 2 && w != 0) return false;
            int64_t v = 0;
            if (!decode_int64_value(p, end, w, v)) return false;
            out.command_received_time = v;
        } else if (f >= 3 && f <= 6) {
            if (w != 2) return false;
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            const size_t n = static_cast<size_t>(l);
            std::string s(reinterpret_cast<const char*>(p), n);
            p += n;
            if (!is_valid_utf8_string(s)) return false;
            if (f == 3) out.page_instance_ids.push_back(std::move(s));
            else if (f == 4) out.interaction_ids.push_back(std::move(s));
            else if (f == 5) out.device_identifier = std::move(s);
            else if (f == 6) out.command_id = std::move(s);
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

// Field numbers verified 1:1 against es_play_options.pb.dart:
// 1: reason (enum), 2: operation (enum), 3: trigger (enum), 4: playback_speed (double)
inline bool decode_play_options(
        const uint8_t* ptr,
        size_t len,
        DecodedPlayOptions& out) {
    if (ptr == nullptr) return len == 0;
    out.present = true;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f >= 1 && f <= 3) {
            if (w != 0) return false;
            uint64_t v = 0;
            if (!decode_varint(p, end, v)) return false;
            if (f == 1) out.reason = static_cast<int32_t>(v);
            else if (f == 2) out.operation = static_cast<int32_t>(v);
            else if (f == 3) out.trigger = static_cast<int32_t>(v);
        } else if (f == 4) {
            if (w != 1 && w != 5) return false;
            double spd = 0.0;
            if (!decode_double_value(p, end, w, spd)) return false;
            out.playback_speed = spd;
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

inline std::string extract_intent_id(const DecodedLoggingParams& lp) {
    if (!lp.command_id.empty()) {
        return lp.command_id;
    }
    if (!lp.interaction_ids.empty()) {
        return lp.interaction_ids.front();
    }
    return {};
}

// Field numbers verified 1:1 against Spotify EsSkipToTrack$SkipToTrack.java:
// 1: page_url, 2: page_index, 3: track_uid, 4: track_uri, 5: track_index
inline bool decode_skip_to(const uint8_t* ptr, size_t len, SkipToOptions& skip_to) {
    if (ptr == nullptr) return len == 0;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1) {
            if (w != 2) return false;
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            const size_t n = static_cast<size_t>(l);
            skip_to.page_url.assign(reinterpret_cast<const char*>(p), n);
            if (!is_valid_utf8_string(skip_to.page_url)) return false;
            p += n;
        } else if (f == 2) {
            int64_t pi = 0;
            if (!decode_int64_value(p, end, w, pi)) return false;
            skip_to.page_index = pi;
        } else if (f == 3) {
            if (w != 2) return false;
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            const size_t n = static_cast<size_t>(l);
            skip_to.track_uid.assign(reinterpret_cast<const char*>(p), n);
            if (!is_valid_utf8_string(skip_to.track_uid)) return false;
            p += n;
        } else if (f == 4) {
            if (w != 2) return false;
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            const size_t n = static_cast<size_t>(l);
            skip_to.track_uri.assign(reinterpret_cast<const char*>(p), n);
            if (!skip_to.track_uri.empty() && !is_valid_utf8_uri(skip_to.track_uri)) return false;
            p += n;
        } else if (f == 5) {
            if (!decode_int64_value(p, end, w, skip_to.track_index)) return false;
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

// Field numbers verified 1:1 against EsContextPlayerOptions$ContextPlayerOptionOverrides.java
// and spotify.player.proto.ContextPlayerOptions (@ 0x609924):
// 1: shuffling_context, 2: repeating_context, 3: repeating_track, 4: playback_speed, 5: modes
inline bool decode_option_overrides(const uint8_t* ptr, size_t len, OptionOverrides& overrides) {
    if (ptr == nullptr) return len == 0;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1) {
            bool v = false;
            if (!decode_bool_value(p, end, w, v)) return false;
            overrides.shuffling_context = v;
        } else if (f == 2) {
            bool v = false;
            if (!decode_bool_value(p, end, w, v)) return false;
            overrides.repeating_context = v;
        } else if (f == 3) {
            bool v = false;
            if (!decode_bool_value(p, end, w, v)) return false;
            overrides.repeating_track = v;
        } else if (f == 4) {
            double spd = 0.0;
            if (!decode_double_value(p, end, w, spd)) return false;
            if (spd > 0.0) {
                overrides.playback_speed = spd;
            }
        } else if (f == 5) {
            if (w != 2) return false;
            uint64_t ml = 0;
            if (!decode_varint(p, end, ml) || !has_bytes(p, end, ml)) return false;
            const size_t mn = static_cast<size_t>(ml);
            if (!decode_map_entries(p, mn, overrides.modes)) return false;
            p += mn;
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

// Field numbers verified 1:1 against EsPlayOrigin$PlayOrigin.java & play_origin.proto (@ 0x60a4d8):
// 1: feature_identifier, 2: feature_version, 3: view_uri, 4: external_referrer,
// 5: referrer_identifier, 6: device_identifier, 7: feature_classes, 8: restriction_identifier
inline bool decode_play_origin(const uint8_t* ptr, size_t len, PlayOriginData& out) {
    if (ptr == nullptr) return len == 0;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f >= 1 && f <= 8) {
            if (w != 2) return false;
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            const size_t n = static_cast<size_t>(l);
            std::string str(reinterpret_cast<const char*>(p), n);
            if (!is_valid_utf8_string(str)) return false;
            if (f == 1) out.feature_identifier = std::move(str);
            else if (f == 2) out.feature_version = std::move(str);
            else if (f == 3) out.view_uri = std::move(str);
            else if (f == 4) out.external_referrer = std::move(str);
            else if (f == 5) out.referrer_identifier = std::move(str);
            else if (f == 6) out.device_identifier = std::move(str);
            else if (f == 7) out.feature_classes.push_back(std::move(str));
            else if (f == 8) out.restriction_identifier = std::move(str);
            p += n;
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

// Field numbers verified 1:1 against EsPreparePlayOptions$PreparePlayOptions.java:
// 1: playback_id, 2: always_play_something, 3: skip_to, 4: seek_to,
// 5: initially_paused, 6: system_initiated, 7: player_options_override,
// 8: suppressions, 9: prefetch_level, 10: audio_stream, 11: session_id,
// 12: license, 13: configuration_override, 14: seek_to_creator_timestamp
inline bool decode_prepare_play_options(const uint8_t* ptr, size_t len, DecodedPreparePlay& out) {
    if (ptr == nullptr) return len == 0;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 || f == 3 || f == 4 || f == 7 || f == 8 ||
            f == 11 || f == 12 || f == 13 || f == 14) {
            if (w != 2) return false;
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            const size_t n = static_cast<size_t>(l);
            if (f == 3) {
                if (!decode_skip_to(p, n, out.skip_to)) return false;
            } else if (f == 4) {
                const uint8_t* sp = p;
                const uint8_t* se = p + n;
                int64_t seek_val = 0;
                while (sp < se) {
                    uint64_t stag = 0;
                    if (!decode_varint(sp, se, stag)) return false;
                    const uint32_t sf = static_cast<uint32_t>(stag >> 3);
                    const uint32_t sw = static_cast<uint32_t>(stag & 0x07);
                    if (sf == 1 && sw == 0) {
                        uint64_t v = 0;
                        if (!decode_varint(sp, se, v)) return false;
                        seek_val = static_cast<int64_t>(v);
                    } else {
                        if (!skip_field(sp, se, sw)) return false;
                    }
                }
                out.seek_to_ms = seek_val;
            } else if (f == 7) {
                if (!decode_option_overrides(p, n, out.overrides)) return false;
            } else if (f == 8) {
                std::string sup(reinterpret_cast<const char*>(p), n);
                if (!is_valid_utf8_string(sup)) return false;
                out.suppressions.push_back(std::move(sup));
            } else if (f == 11) {
                out.session_id.assign(reinterpret_cast<const char*>(p), n);
                if (!is_valid_utf8_string(out.session_id)) return false;
            } else if (f == 12) {
                out.license.assign(reinterpret_cast<const char*>(p), n);
                if (!is_valid_utf8_string(out.license)) return false;
            }
            p += n;
        } else if (f == 2 || f == 5 || f == 6 || f == 9 || f == 10) {
            if (w != 0) return false;
            uint64_t v = 0;
            if (!decode_varint(p, end, v)) return false;
            if (f == 2) out.always_play_something = (v != 0);
            else if (f == 5) out.initially_paused = (v != 0);
            else if (f == 6) out.system_initiated = (v != 0);
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

// Field numbers verified 1:1 against Spotify EsContext$Context.java:
// 1: pages (repeated ContextPage), 2: metadata (map), 3: uri (string),
// 4: url (string), 5: is_loading (bool), 6: restrictions (Restrictions)
inline bool decode_context_submessage(const uint8_t* ptr, size_t len, DecodedPreparePlay& out) {
    if (ptr == nullptr) return len == 0;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 || f == 2 || f == 3 || f == 4 || f == 6) {
            if (w != 2) return false;
            uint64_t sub_len = 0;
            if (!decode_varint(p, end, sub_len) || !has_bytes(p, end, sub_len)) return false;
            const size_t n = static_cast<size_t>(sub_len);
            if (f == 1) {
                std::string page_url, next_page_url;
                std::vector<context_view::Entry> page_tracks;
                if (!decode_context_page(p, n, page_url, next_page_url, page_tracks)) {
                    return false;
                }
                if (!page_url.empty() && !is_valid_utf8_string(page_url)) {
                    return false;
                }
                if (!next_page_url.empty() && !is_valid_utf8_string(next_page_url)) {
                    return false;
                }
                std::vector<context_view::Entry> valid_tracks;
                valid_tracks.reserve(page_tracks.size());
                for (auto& entry : page_tracks) {
                    if (!entry.uri.empty()) {
                        if (!is_valid_utf8_uri(entry.uri)) {
                            return false;
                        }
                        valid_tracks.push_back(std::move(entry));
                    }
                }
                if (out.page_url.empty()) {
                    out.page_url = page_url;
                    out.next_page_url = next_page_url;
                }
                DecodedContextPage dpage;
                dpage.page_url = std::move(page_url);
                dpage.next_page_url = std::move(next_page_url);
                dpage.tracks = valid_tracks;
                out.pages.push_back(std::move(dpage));

                out.page_track_offsets.push_back(out.tracks.size());
                out.tracks.insert(
                    out.tracks.end(),
                    std::make_move_iterator(valid_tracks.begin()),
                    std::make_move_iterator(valid_tracks.end()));
            } else if (f == 2) {
                if (!decode_map_entries(p, n, out.context_metadata)) return false;
            } else if (f == 3) {
                out.context_uri.assign(reinterpret_cast<const char*>(p), n);
                if (!out.context_uri.empty() && !is_valid_utf8_uri(out.context_uri)) {
                    return false;
                }
            } else if (f == 4) {
                out.context_url.assign(reinterpret_cast<const char*>(p), n);
                if (!out.context_url.empty() && !is_valid_utf8_uri(out.context_url)) {
                    return false;
                }
            }
            p += n;
        } else if (f == 5) {
            if (w != 0) return false;
            uint64_t dummy = 0;
            if (!decode_varint(p, end, dummy)) return false;
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

inline bool decode_prepare_play_request_body(
        const uint8_t* data,
        size_t size,
        DecodedPreparePlay& out,
        bool& has_extra_fields) {
    has_extra_fields = false;
    if (!data || size == 0) return false;
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f >= 1 && f <= 3) {
            if (w != 2) return false;
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || !has_bytes(ptr, end, len)) return false;
            const size_t n = static_cast<size_t>(len);
            if (f == 1) {
                if (!decode_context_submessage(ptr, n, out)) return false;
            } else if (f == 2) {
                if (!decode_prepare_play_options(ptr, n, out)) return false;
            } else if (f == 3) {
                if (!decode_play_origin(ptr, n, out.play_origin)) return false;
            }
            ptr += n;
        } else {
            has_extra_fields = true;
            if (!skip_field(ptr, end, w)) return false;
        }
    }
    return !out.tracks.empty() ||
           is_valid_utf8_uri(out.context_uri) ||
           is_valid_utf8_uri(out.context_url);
}

// Unwraps PlayRequest (1=PreparePlayRequest, 2=PlayOptions, 3=CommandOptions, 4=LoggingParams)
// or decodes PreparePlayRequest directly.
inline bool parse_prepare_play_request(const uint8_t* data, size_t size, DecodedPreparePlay& out) {
    if (!data || size == 0) return false;

    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    const uint8_t* f1_ptr = nullptr;
    size_t f1_len = 0;
    DecodedPlayOptions outer_play_opts;
    DecodedCommandOptions outer_cmd_opts;
    DecodedLoggingParams outer_log_params;
    bool outer_valid_play_request = true;
    bool has_play_request_logging_params = false;

    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) {
            outer_valid_play_request = false;
            break;
        }
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f >= 1 && f <= 4) {
            if (w != 2) {
                outer_valid_play_request = false;
                break;
            }
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || !has_bytes(ptr, end, len)) {
                outer_valid_play_request = false;
                break;
            }
            const size_t n = static_cast<size_t>(len);
            if (f == 1) {
                f1_ptr = ptr;
                f1_len = n;
            } else if (f == 2) {
                if (!decode_play_options(ptr, n, outer_play_opts)) {
                    outer_valid_play_request = false;
                    break;
                }
            } else if (f == 3) {
                if (!decode_command_options(ptr, n, outer_cmd_opts)) {
                    outer_valid_play_request = false;
                    break;
                }
            } else if (f == 4) {
                if (decode_logging_params(ptr, n, outer_log_params)) {
                    has_play_request_logging_params = true;
                } else {
                    outer_valid_play_request = false;
                    break;
                }
            }
            ptr += n;
        } else {
            outer_valid_play_request = false;
            break;
        }
    }

    DecodedPreparePlay candidate;
    bool cand_has_extra = false;
    const bool ok_candidate =
        outer_valid_play_request &&
        f1_ptr != nullptr &&
        f1_len > 0 &&
        decode_prepare_play_request_body(f1_ptr, f1_len, candidate, cand_has_extra);
    if (ok_candidate) {
        candidate.play_options = std::move(outer_play_opts);
        candidate.command_options = std::move(outer_cmd_opts);
        candidate.logging_params = std::move(outer_log_params);
    }

    DecodedPreparePlay direct;
    bool dir_has_extra = false;
    const bool ok_direct = decode_prepare_play_request_body(data, size, direct, dir_has_extra);

    if (ok_candidate && (has_play_request_logging_params || candidate.command_options.present)) {
        out = std::move(candidate);
        return true;
    }
    if (ok_candidate && !ok_direct) {
        out = std::move(candidate);
        return true;
    }
    if (ok_direct && !ok_candidate) {
        out = std::move(direct);
        return true;
    }
    if (ok_candidate && ok_direct) {
        if (!candidate.tracks.empty() != !direct.tracks.empty()) {
            out = !candidate.tracks.empty() ? std::move(candidate) : std::move(direct);
            return true;
        }
        if (cand_has_extra != dir_has_extra) {
            out = !cand_has_extra ? std::move(candidate) : std::move(direct);
            return true;
        }
        const bool cand_has_uri = is_valid_utf8_uri(candidate.context_uri);
        const bool dir_has_uri = is_valid_utf8_uri(direct.context_uri);
        if (cand_has_uri != dir_has_uri) {
            out = cand_has_uri ? std::move(candidate) : std::move(direct);
            return true;
        }
        out = std::move(direct);
        return true;
    }
    return false;
}

inline bool decode_track_or_provided_track(const uint8_t* data, size_t size, context_view::Entry& out_entry) {
    if (!data || size == 0) return false;

    // 1. Try decoding as wrapped request/ProvidedTrack (field 1 = ContextTrack, field 4 = provider)
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    bool found_track = false;
    context_view::Entry inner;
    std::string provider;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 2) {
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || !has_bytes(ptr, end, len)) break;
            const size_t n = static_cast<size_t>(len);
            if (decode_context_track(ptr, n, inner) && is_valid_utf8_uri(inner.uri)) {
                found_track = true;
            }
            ptr += n;
        } else if (f == 4 && w == 2) {
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || !has_bytes(ptr, end, len)) break;
            const size_t n = static_cast<size_t>(len);
            provider.assign(reinterpret_cast<const char*>(ptr), n);
            ptr += n;
        } else {
            if (!skip_field(ptr, end, w)) break;
        }
    }
    if (found_track) {
        if (!provider.empty()) {
            inner.provider = provider;
            inner.metadata["provider"] = provider;
        } else if (const auto it = inner.metadata.find("provider");
                   it != inner.metadata.end() && !it->second.empty()) {
            inner.provider = it->second;
        }
        out_entry = std::move(inner);
        return true;
    }

    // 2. Try decoding directly as bare ContextTrack
    context_view::Entry direct;
    if (decode_context_track(data, size, direct) && is_valid_utf8_uri(direct.uri)) {
        if (const auto it = direct.metadata.find("provider");
            it != direct.metadata.end() && !it->second.empty()) {
            direct.provider = it->second;
        }
        out_entry = std::move(direct);
        return true;
    }

    return false;
}

inline bool decode_pause_or_resume_request(
        const uint8_t* data,
        size_t size,
        DecodedPauseResumeRequest& out) {
    if (!data || size == 0) return true;
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if ((f == 1 || f == 2 || f == 3) && w == 2) {
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || !has_bytes(ptr, end, len)) return false;
            const size_t n = static_cast<size_t>(len);
            if (f == 1) {
                if (!decode_command_options(ptr, n, out.options)) return false;
            } else if (f == 2) {
                if (!decode_logging_params(ptr, n, out.logging_params)) return false;
            } else if (f == 3) {
                const uint8_t* op = ptr;
                const uint8_t* oe = ptr + n;
                while (op < oe) {
                    uint64_t otag = 0;
                    if (!decode_varint(op, oe, otag)) return false;
                    const uint32_t of = static_cast<uint32_t>(otag >> 3);
                    const uint32_t ow = static_cast<uint32_t>(otag & 0x07);
                    if (of == 1 && ow == 2) {
                        uint64_t sl = 0;
                        if (!decode_varint(op, oe, sl) || !has_bytes(op, oe, sl)) return false;
                        out.origin_feature_identifier.assign(
                            reinterpret_cast<const char*>(op), static_cast<size_t>(sl));
                        op += static_cast<size_t>(sl);
                    } else {
                        if (!skip_field(op, oe, ow)) return false;
                    }
                }
            }
            ptr += n;
        } else {
            if (!skip_field(ptr, end, w)) return false;
        }
    }
    return true;
}

// Field numbers verified 1:1 against es_seek_to.pb.dart:
// 1: options (CommandOptions), 2: logging_params (LoggingParams),
// 3: position (int64), 4: relative (enum), 5: creator_timestamp (OptionalInt64)
inline bool decode_seek_to_request_full(
        const uint8_t* data,
        size_t size,
        DecodedSeekToRequest& out) {
    if (!data || size == 0) return false;
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;

    uint64_t tag_or_val = 0;
    if (!decode_varint(ptr, end, tag_or_val)) return false;
    if (ptr == end) {
        out.position_ms = static_cast<int64_t>(tag_or_val);
        out.has_position = true;
        return true;
    }

    ptr = data;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) break;
            decode_command_options(ptr, static_cast<size_t>(l), out.options);
            ptr += static_cast<size_t>(l);
        } else if (f == 1 && w == 0) {
            if (decode_int64_value(ptr, end, w, out.position_ms)) {
                out.has_position = true;
            }
        } else if (f == 2 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) break;
            decode_logging_params(ptr, static_cast<size_t>(l), out.logging_params);
            ptr += static_cast<size_t>(l);
        } else if (f == 3) {
            if (decode_int64_value(ptr, end, w, out.position_ms)) {
                out.has_position = true;
            }
        } else if (f == 4 && w == 0) {
            uint64_t rv = 0;
            if (!decode_varint(ptr, end, rv)) break;
            out.relative = static_cast<int32_t>(rv);
        } else {
            if (!skip_field(ptr, end, w)) break;
        }
    }
    return out.has_position || out.options.present || out.logging_params.present;
}

inline bool decode_skip_next_request_full(
        const uint8_t* data,
        size_t size,
        DecodedSkipNextRequest& out) {
    if (!data || size == 0) return true;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) break;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) break;
            decode_command_options(p, static_cast<size_t>(l), out.options);
            p += static_cast<size_t>(l);
        } else if (f == 2 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) break;
            decode_logging_params(p, static_cast<size_t>(l), out.logging_params);
            p += static_cast<size_t>(l);
        } else if (f == 3 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) break;
            decode_context_track(p, static_cast<size_t>(l), out.target_track);
            p += static_cast<size_t>(l);
        } else {
            if (!skip_field(p, end, w)) break;
        }
    }
    return true;
}

inline bool decode_skip_prev_request_full(
        const uint8_t* data,
        size_t size,
        DecodedSkipPrevRequest& out) {
    if (!data || size == 0) return true;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) break;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) break;
            decode_command_options(p, static_cast<size_t>(l), out.options);
            p += static_cast<size_t>(l);
        } else if (f == 2) {
            if (decode_bool_value(p, end, w, out.allow_seeking)) {
                out.has_allow_seeking = true;
            }
        } else if (f == 3 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) break;
            decode_logging_params(p, static_cast<size_t>(l), out.logging_params);
            p += static_cast<size_t>(l);
        } else if (f == 4 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) break;
            decode_context_track(p, static_cast<size_t>(l), out.target_track);
            p += static_cast<size_t>(l);
        } else {
            if (!skip_field(p, end, w)) break;
        }
    }
    return true;
}

// Field numbers verified 1:1 against es_set_options.pb.dart:
// 1: repeating_track (OptionalBoolean), 2: repeating_context (OptionalBoolean),
// 3: shuffling_context (OptionalBoolean), 4: options (CommandOptions),
// 5: logging_params (LoggingParams), 6: playback_speed (double), 7: modes (map)
inline bool decode_set_options_request_full(
        const uint8_t* data,
        size_t size,
        DecodedSetOptionsRequest& out) {
    if (!data || size == 0) return false;
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1) {
            bool v = false;
            if (decode_bool_value(ptr, end, w, v)) out.overrides.repeating_track = v;
        } else if (f == 2) {
            bool v = false;
            if (decode_bool_value(ptr, end, w, v)) out.overrides.repeating_context = v;
        } else if (f == 3) {
            bool v = false;
            if (decode_bool_value(ptr, end, w, v)) out.overrides.shuffling_context = v;
        } else if (f == 4 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) break;
            decode_command_options(ptr, static_cast<size_t>(l), out.options);
            ptr += static_cast<size_t>(l);
        } else if (f == 5 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) break;
            decode_logging_params(ptr, static_cast<size_t>(l), out.logging_params);
            ptr += static_cast<size_t>(l);
        } else if (f == 6) {
            double spd = 0.0;
            if (decode_double_value(ptr, end, w, spd) && spd > 0.0) {
                out.overrides.playback_speed = spd;
            }
        } else if (f == 7 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) break;
            decode_map_entries(ptr, static_cast<size_t>(l), out.overrides.modes);
            ptr += static_cast<size_t>(l);
        } else {
            if (!skip_field(ptr, end, w)) break;
        }
    }
    return true;
}

// Field numbers verified 1:1 against es_set_shuffling_context.pb.dart,
// es_set_repeating_context.pb.dart, es_set_repeating_track.pb.dart:
// 1: bool value, 2: CommandOptions, 3: LoggingParams
inline bool decode_bool_command_request(
        const uint8_t* data,
        size_t size,
        DecodedBoolCommandRequest& out) {
    if (!data || size == 0) return false;
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;

    uint64_t tag_or_val = 0;
    if (!decode_varint(ptr, end, tag_or_val)) return false;
    if (ptr == end) {
        out.value = (tag_or_val != 0);
        out.has_value = true;
        return true;
    }

    ptr = data;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1) {
            if (decode_bool_value(ptr, end, w, out.value)) {
                out.has_value = true;
            }
        } else if (f == 2 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) break;
            decode_command_options(ptr, static_cast<size_t>(l), out.options);
            ptr += static_cast<size_t>(l);
        } else if (f == 3 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) break;
            decode_logging_params(ptr, static_cast<size_t>(l), out.logging_params);
            ptr += static_cast<size_t>(l);
        } else {
            if (!skip_field(ptr, end, w)) break;
        }
    }
    // Proto3 omits `false` bool values when serialized alongside options/logging_params.
    if (!out.has_value && (out.options.present || out.logging_params.present)) {
        out.value = false;
        out.has_value = true;
    }
    return out.has_value;
}

// Field numbers verified 1:1 against es_add_to_queue_request.pb.dart:
// 1: track (ContextTrack), 2: options (CommandOptions), 3: logging_params (LoggingParams)
inline bool decode_add_to_queue_request_full(
        const uint8_t* data,
        size_t size,
        DecodedAddToQueueRequest& out) {
    if (!data || size == 0) return false;

    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) break;
            const size_t n = static_cast<size_t>(l);
            context_view::Entry candidate;
            if (decode_context_track(ptr, n, candidate) && is_valid_utf8_uri(candidate.uri)) {
                out.track = std::move(candidate);
                out.has_track = true;
            }
            ptr += n;
        } else if (f == 2 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) break;
            decode_command_options(ptr, static_cast<size_t>(l), out.options);
            ptr += static_cast<size_t>(l);
        } else if (f == 3 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) break;
            decode_logging_params(ptr, static_cast<size_t>(l), out.logging_params);
            ptr += static_cast<size_t>(l);
        } else {
            if (!skip_field(ptr, end, w)) break;
        }
    }
    if (!out.has_track) {
        context_view::Entry direct;
        if (decode_track_or_provided_track(data, size, direct)) {
            out.track = std::move(direct);
            out.has_track = true;
            out.options = DecodedCommandOptions{};
            out.logging_params = DecodedLoggingParams{};
        }
    }
    return out.has_track;
}

// Field numbers verified 1:1 against es_set_queue_request.pb.dart:
// 1: next_tracks (repeated ProvidedTrack), 2: prev_tracks (repeated ProvidedTrack),
// 3: queue_revision (uint64), 4: options (CommandOptions), 5: logging_params (LoggingParams)
inline bool decode_set_queue_request_full(
        const uint8_t* data,
        size_t size,
        DecodedSetQueueRequest& out) {
    if (data == nullptr) return size == 0;
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 2) {
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || !has_bytes(ptr, end, len)) break;
            const size_t n = static_cast<size_t>(len);
            context_view::Entry entry;
            if (decode_track_or_provided_track(ptr, n, entry)) {
                out.next_tracks.push_back(std::move(entry));
            }
            ptr += n;
        } else if (f == 2 && w == 2) {
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || !has_bytes(ptr, end, len)) break;
            const size_t n = static_cast<size_t>(len);
            context_view::Entry entry;
            if (decode_track_or_provided_track(ptr, n, entry)) {
                out.prev_tracks.push_back(std::move(entry));
                out.has_prev_tracks = true;
            }
            ptr += n;
        } else if (f == 3) {
            if (decode_uint64_value(ptr, end, w, out.queue_revision)) {
                out.has_queue_revision = true;
            }
        } else if (f == 4 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) break;
            decode_command_options(ptr, static_cast<size_t>(l), out.options);
            ptr += static_cast<size_t>(l);
        } else if (f == 5 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) break;
            decode_logging_params(ptr, static_cast<size_t>(l), out.logging_params);
            ptr += static_cast<size_t>(l);
        } else {
            if (!skip_field(ptr, end, w)) break;
        }
    }
    return true;
}

// Field numbers verified 1:1 against es_play_as_next_in_queue_request.pb.dart:
// 1: tracks (repeated ContextTrack), 2: options (CommandOptions), 3: logging_params (LoggingParams)
inline bool decode_play_as_next_request_full(
        const uint8_t* data,
        size_t size,
        DecodedPlayAsNextRequest& out) {
    if (!data || size == 0) return false;
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) break;
            const size_t n = static_cast<size_t>(l);
            context_view::Entry entry;
            if (decode_track_or_provided_track(ptr, n, entry)) {
                out.tracks.push_back(std::move(entry));
            }
            ptr += n;
        } else if (f == 2 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) break;
            decode_command_options(ptr, static_cast<size_t>(l), out.options);
            ptr += static_cast<size_t>(l);
        } else if (f == 3 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) break;
            decode_logging_params(ptr, static_cast<size_t>(l), out.logging_params);
            ptr += static_cast<size_t>(l);
        } else {
            if (!skip_field(ptr, end, w)) break;
        }
    }
    if (out.tracks.empty()) {
        context_view::Entry direct;
        if (decode_track_or_provided_track(data, size, direct)) {
            out.tracks.push_back(std::move(direct));
            out.options = DecodedCommandOptions{};
            out.logging_params = DecodedLoggingParams{};
        }
    }
    return !out.tracks.empty();
}

// Field numbers verified 1:1 against es_signal_request.pb.dart:
// 1: signal_id (string), 2: parameters (string), 3: options (CommandOptions), 4: logging_params (LoggingParams)
inline bool decode_signal_request_full(
        const uint8_t* data,
        size_t size,
        DecodedSignalRequest& out) {
    if (!data || size == 0) return false;
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    bool valid_proto = true;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) {
            valid_proto = false;
            break;
        }
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if ((f == 1 || f == 2) && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) {
                valid_proto = false;
                break;
            }
            const size_t n = static_cast<size_t>(l);
            std::string str(reinterpret_cast<const char*>(ptr), n);
            ptr += n;
            if (!is_valid_utf8_string(str)) {
                valid_proto = false;
                break;
            }
            if (f == 1) out.signal_id = std::move(str);
            else out.parameters = std::move(str);
        } else if (f == 3 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) {
                valid_proto = false;
                break;
            }
            if (!decode_command_options(ptr, static_cast<size_t>(l), out.options)) {
                valid_proto = false;
                break;
            }
            ptr += static_cast<size_t>(l);
        } else if (f == 4 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) {
                valid_proto = false;
                break;
            }
            if (!decode_logging_params(ptr, static_cast<size_t>(l), out.logging_params)) {
                valid_proto = false;
                break;
            }
            ptr += static_cast<size_t>(l);
        } else {
            if (!skip_field(ptr, end, w)) {
                valid_proto = false;
                break;
            }
        }
    }
    if (valid_proto && !out.signal_id.empty()) {
        return true;
    }
    // Compatibility fallback for legacy raw UTF-8 signal payloads.
    std::string raw(reinterpret_cast<const char*>(data), size);
    if (!raw.empty() && is_valid_utf8_string(raw)) {
        out = DecodedSignalRequest{};
        out.signal_id = std::move(raw);
        return true;
    }
    return false;
}

// Field numbers verified 1:1 against es_set_sleep_timer_request.pb.dart:
// 1: options (CommandOptions), 2: logging_params (LoggingParams),
// 3: clear (SetSleepTimerRequest_Clear),
// 4: duration (SetSleepTimerRequest_Duration { 1: int64 seconds }),
// 5: end_of_track (SetSleepTimerRequest_EndOfTrack)
inline bool decode_set_sleep_timer_request_full(
        const uint8_t* data,
        size_t size,
        DecodedSleepTimerRequest& out) {
    if (!data || size == 0) return false;

    // Legacy single-varint compatibility (seconds > 0 -> duration, 0 -> clear).
    {
        const uint8_t* p = data;
        const uint8_t* end = data + size;
        uint64_t single_val = 0;
        if (decode_varint(p, end, single_val) && p == end) {
            if (single_val == 0) {
                out.action = DecodedSleepTimerRequest::Action::kClear;
            } else {
                out.action = DecodedSleepTimerRequest::Action::kDurationSeconds;
                out.duration_seconds = static_cast<int64_t>(single_val);
            }
            return true;
        }
    }

    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) return false;
            if (!decode_command_options(ptr, static_cast<size_t>(l), out.options)) return false;
            ptr += static_cast<size_t>(l);
        } else if (f == 1 && w == 0) {
            // Legacy tag-1 int64 seconds compatibility.
            uint64_t sec = 0;
            if (!decode_varint(ptr, end, sec)) return false;
            if (sec == 0) {
                out.action = DecodedSleepTimerRequest::Action::kClear;
            } else {
                out.action = DecodedSleepTimerRequest::Action::kDurationSeconds;
                out.duration_seconds = static_cast<int64_t>(sec);
            }
        } else if (f == 2 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) return false;
            if (!decode_logging_params(ptr, static_cast<size_t>(l), out.logging_params)) return false;
            ptr += static_cast<size_t>(l);
        } else if (f == 3 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) return false;
            out.action = DecodedSleepTimerRequest::Action::kClear;
            out.duration_seconds = 0;
            ptr += static_cast<size_t>(l);
        } else if (f == 4 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) return false;
            const uint8_t* dp = ptr;
            const uint8_t* de = ptr + static_cast<size_t>(l);
            int64_t seconds = 0;
            while (dp < de) {
                uint64_t dtag = 0;
                if (!decode_varint(dp, de, dtag)) return false;
                const uint32_t df = static_cast<uint32_t>(dtag >> 3);
                const uint32_t dw = static_cast<uint32_t>(dtag & 0x07);
                if (df == 1) {
                    if (!decode_int64_value(dp, de, dw, seconds)) return false;
                } else {
                    if (!skip_field(dp, de, dw)) return false;
                }
            }
            out.action = DecodedSleepTimerRequest::Action::kDurationSeconds;
            out.duration_seconds = seconds;
            ptr += static_cast<size_t>(l);
        } else if (f == 5 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) return false;
            out.action = DecodedSleepTimerRequest::Action::kEndOfTrack;
            out.duration_seconds = 0;
            ptr += static_cast<size_t>(l);
        } else {
            if (!skip_field(ptr, end, w)) return false;
        }
    }
    return out.action != DecodedSleepTimerRequest::Action::kUnset;
}

// Field numbers verified 1:1 against es_play.pb.dart (PlayPreparedRequest):
// 1: session_id (string), 2: play_options (PlayOptions), 3: options (CommandOptions), 4: logging_params
inline bool decode_play_prepared_request_full(
        const uint8_t* data,
        size_t size,
        DecodedPlayPreparedRequest& out) {
    if (!data || size == 0) return true;
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f >= 1 && f <= 4 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) return false;
            const size_t n = static_cast<size_t>(l);
            if (f == 1) {
                out.session_id.assign(reinterpret_cast<const char*>(ptr), n);
            } else if (f == 2) {
                if (!decode_play_options(ptr, n, out.play_options)) return false;
            } else if (f == 3) {
                if (!decode_command_options(ptr, n, out.options)) return false;
            } else if (f == 4) {
                if (!decode_logging_params(ptr, n, out.logging_params)) return false;
            }
            ptr += n;
        } else {
            if (!skip_field(ptr, end, w)) return false;
        }
    }
    return true;
}

inline bool decode_delete_session_request(
    const uint8_t* data, size_t size, std::string& out_session_id) {
    if (data == nullptr) {
        return size == 0;
    }
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) {
            return false;
        }
        const uint64_t field_number_64 = tag >> 3;
        if (field_number_64 == 0 || field_number_64 > 0x1FFFFFFFULL) {
            return false;
        }
        const uint32_t field_number = static_cast<uint32_t>(field_number_64);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);

        if (field_number == 1) {
            if (wire_type != 2) {
                return false;
            }
            uint64_t str_len = 0;
            if (!decode_varint(ptr, end, str_len) || !has_bytes(ptr, end, str_len)) {
                return false;
            }
            const size_t safe_len = static_cast<size_t>(str_len);
            out_session_id.assign(reinterpret_cast<const char*>(ptr), safe_len);
            ptr += safe_len;
        } else {
            if (!skip_field(ptr, end, wire_type)) {
                return false;
            }
        }
    }
    return true;
}

inline bool decode_single_string(const uint8_t* data, size_t size, std::string& out_str) {
    if (!data || size == 0) return false;
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 2) {
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || !has_bytes(ptr, end, len)) break;
            out_str.assign(reinterpret_cast<const char*>(ptr), static_cast<size_t>(len));
            return true;
        }
        if (!skip_field(ptr, end, w)) break;
    }
    return false;
}

// ============================================================================
// Self-contained `spotify.player.proto.transfer.TransferState` Protobuf Decoders
// ============================================================================

inline bool decode_transfer_context_track(
        const uint8_t* data,
        size_t size,
        context_view::Entry& out_entry) {
    if (!data) return size == 0;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    std::vector<uint8_t> gid;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (w == 2 && (f == 1 || f == 2 || f == 3 || f == 4)) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            const size_t n = static_cast<size_t>(l);
            if (f == 1) {
                out_entry.uri.assign(reinterpret_cast<const char*>(p), n);
            } else if (f == 2) {
                out_entry.uid.assign(reinterpret_cast<const char*>(p), n);
            } else if (f == 3) {
                gid.assign(p, p + n);
            } else if (f == 4) {
                if (!decode_map_entries(p, n, out_entry.metadata)) return false;
            }
            p += n;
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    if (out_entry.uri.empty() && gid.size() == 16) {
        out_entry.uri = gid_to_spotify_track_uri(gid);
    }
    if (out_entry.uri == "spotify:delimiter" || out_entry.uri == "spotify:meta:delimiter") {
        out_entry.type = context_view::EntryType::DELIMITER;
    } else {
        out_entry.type = context_view::EntryType::TRACK;
    }
    if (const auto it_p = out_entry.metadata.find("provider");
        it_p != out_entry.metadata.end() && !it_p->second.empty()) {
        out_entry.provider = it_p->second;
    } else if (const auto it_q = out_entry.metadata.find("is_queued");
               it_q != out_entry.metadata.end() &&
               (it_q->second == "true" || it_q->second == "True")) {
        out_entry.provider = "queue";
    } else {
        out_entry.provider = "context";
    }
    return true;
}

inline bool decode_transfer_context_page(
        const uint8_t* data,
        size_t size,
        DecodedContextPage& out_page) {
    if (!data) return size == 0;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (w == 2 && (f == 1 || f == 2 || f == 3 || f == 4)) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            const size_t n = static_cast<size_t>(l);
            if (f == 1) {
                out_page.page_url.assign(reinterpret_cast<const char*>(p), n);
            } else if (f == 2) {
                out_page.next_page_url.assign(reinterpret_cast<const char*>(p), n);
            } else if (f == 3) {
                if (!decode_map_entries(p, n, out_page.metadata)) return false;
            } else if (f == 4) {
                context_view::Entry entry;
                if (!decode_transfer_context_track(p, n, entry)) return false;
                if (!entry.uri.empty() && !entry.is_delimiter()) {
                    if (entry.uid.empty()) {
                        entry.uid = generate_track_uid();
                    }
                    out_page.tracks.push_back(std::move(entry));
                }
            }
            p += n;
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

inline bool decode_transfer_context(
        const uint8_t* data,
        size_t size,
        TransferContextProto& out_ctx) {
    if (!data) return size == 0;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (w == 2 && (f == 1 || f == 2 || f == 3 || f == 5)) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            const size_t n = static_cast<size_t>(l);
            if (f == 1) {
                out_ctx.uri.assign(reinterpret_cast<const char*>(p), n);
            } else if (f == 2) {
                out_ctx.url.assign(reinterpret_cast<const char*>(p), n);
            } else if (f == 3) {
                if (!decode_map_entries(p, n, out_ctx.metadata)) return false;
            } else if (f == 5) {
                DecodedContextPage page;
                if (!decode_transfer_context_page(p, n, page)) return false;
                out_ctx.page_track_offsets.push_back(out_ctx.all_tracks.size());
                if (out_ctx.first_page_url.empty() && !page.page_url.empty()) {
                    out_ctx.first_page_url = page.page_url;
                }
                if (out_ctx.first_next_page_url.empty() && !page.next_page_url.empty()) {
                    out_ctx.first_next_page_url = page.next_page_url;
                }
                out_ctx.all_tracks.insert(
                    out_ctx.all_tracks.end(),
                    page.tracks.begin(),
                    page.tracks.end());
                out_ctx.pages.push_back(std::move(page));
            }
            p += n;
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

inline bool decode_transfer_playback(
        const uint8_t* data,
        size_t size,
        TransferPlaybackProto& out_pb) {
    if (!data) return size == 0;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 0) {
            uint64_t v = 0;
            if (!decode_varint(p, end, v)) return false;
            out_pb.timestamp_ms = static_cast<int64_t>(v);
        } else if (f == 2 && w == 0) {
            uint64_t v = 0;
            if (!decode_varint(p, end, v)) return false;
            out_pb.position_as_of_timestamp_ms = static_cast<int32_t>(v);
        } else if (f == 3 && (w == 1 || w == 5)) {
            double spd = 0.0;
            if (!decode_double_value(p, end, w, spd)) return false;
            out_pb.playback_speed = spd;
            out_pb.has_playback_speed = true;
        } else if (f == 4 && w == 0) {
            uint64_t v = 0;
            if (!decode_varint(p, end, v)) return false;
            out_pb.is_paused = (v != 0);
        } else if (f == 5 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            context_view::Entry track;
            if (!decode_transfer_context_track(p, static_cast<size_t>(l), track)) return false;
            if (!track.uri.empty()) {
                out_pb.current_track = std::move(track);
            }
            p += static_cast<size_t>(l);
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

inline bool decode_transfer_session(
        const uint8_t* data,
        size_t size,
        TransferSessionProto& out_sess) {
    if (!data) return size == 0;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (w == 2 && (f == 1 || f == 2 || f == 3 || f == 4 || f == 7 || f == 8 || f == 9)) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            const size_t n = static_cast<size_t>(l);
            if (f == 1) {
                if (!decode_play_origin(p, n, out_sess.play_origin)) return false;
            } else if (f == 2) {
                if (!decode_transfer_context(p, n, out_sess.context)) return false;
            } else if (f == 3) {
                out_sess.current_uid.assign(reinterpret_cast<const char*>(p), n);
            } else if (f == 4) {
                if (!decode_option_overrides(p, n, out_sess.option_overrides)) return false;
            } else if (f == 7) {
                out_sess.shuffle_seed.assign(reinterpret_cast<const char*>(p), n);
            } else if (f == 8) {
                if (!decode_transfer_context(p, n, out_sess.main_context)) return false;
            } else if (f == 9) {
                out_sess.original_session_id.assign(reinterpret_cast<const char*>(p), n);
            }
            p += n;
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

inline bool decode_transfer_queue(
        const uint8_t* data,
        size_t size,
        TransferQueueProto& out_q) {
    if (!data) return size == 0;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            context_view::Entry entry;
            if (!decode_transfer_context_track(p, static_cast<size_t>(l), entry)) return false;
            if (!entry.uri.empty() && !entry.is_delimiter()) {
                if (entry.uid.empty()) {
                    entry.uid = generate_track_uid();
                }
                entry.provider = "queue";
                entry.metadata["is_queued"] = "true";
                entry.metadata["provider"] = "queue";
                out_q.tracks.push_back(std::move(entry));
            }
            p += static_cast<size_t>(l);
        } else if (f == 2 && w == 0) {
            uint64_t v = 0;
            if (!decode_varint(p, end, v)) return false;
            out_q.is_playing_queue = (v != 0);
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

inline bool decode_transfer_sleep_timer(
        const uint8_t* data,
        size_t size,
        TransferSleepTimerProto& out_st) {
    if (!data) return size == 0;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            out_st.kind = TransferSleepTimerProto::Kind::kNone;
            p += static_cast<size_t>(l);
        } else if (f == 2 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            const uint8_t* tp = p;
            const uint8_t* te = p + static_cast<size_t>(l);
            int64_t ts = 0;
            while (tp < te) {
                uint64_t ttag = 0;
                if (!decode_varint(tp, te, ttag)) return false;
                const uint32_t tf = static_cast<uint32_t>(ttag >> 3);
                const uint32_t tw = static_cast<uint32_t>(ttag & 0x07);
                if (tf == 1 && tw == 0) {
                    uint64_t tv = 0;
                    if (!decode_varint(tp, te, tv)) return false;
                    ts = static_cast<int64_t>(tv);
                } else {
                    if (!skip_field(tp, te, tw)) return false;
                }
            }
            out_st.kind = TransferSleepTimerProto::Kind::kTimestamp;
            out_st.timestamp_ms = ts;
            p += static_cast<size_t>(l);
        } else if (f == 3 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            out_st.kind = TransferSleepTimerProto::Kind::kEndOfTrack;
            p += static_cast<size_t>(l);
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

inline bool decode_transfer_state_proto(
        const uint8_t* data,
        size_t size,
        TransferStateProto& out_ts) {
    if (!data || size == 0) return false;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        const uint32_t f = static_cast<uint32_t>(tag >> 3);
        const uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (w == 2 && (f == 1 || f == 2 || f == 3 || f == 4 || f == 7)) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            const size_t n = static_cast<size_t>(l);
            if (f == 1) {
                if (!decode_option_overrides(p, n, out_ts.options)) return false;
            } else if (f == 2) {
                if (!decode_transfer_playback(p, n, out_ts.playback)) return false;
            } else if (f == 3) {
                if (!decode_transfer_session(p, n, out_ts.current_session)) return false;
            } else if (f == 4) {
                if (!decode_transfer_queue(p, n, out_ts.queue)) return false;
            } else if (f == 7) {
                if (!decode_transfer_sleep_timer(p, n, out_ts.sleep_timer)) return false;
            }
            p += n;
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

// ============================================================================
// Outbound Connect Command JSON Serialization Helpers
// ============================================================================

void append_json_double(std::string& out, double value) {
    if (!std::isfinite(value)) {
        out.append("1.0");
        return;
    }
    char buf[48];
    std::snprintf(buf, sizeof(buf), "%.6g", value);
    out.append(buf);
}

void append_json_string_map(
        std::string& out,
        const std::unordered_map<std::string, std::string>& map) {
    out.push_back('{');
    bool first = true;
    for (const auto& [k, v] : map) {
        if (!first) out.push_back(',');
        first = false;
        json::append_json_quoted(out, k);
        out.push_back(':');
        json::append_json_quoted(out, v);
    }
    out.push_back('}');
}

void append_json_string_array(
        std::string& out,
        const std::vector<std::string>& arr) {
    out.push_back('[');
    for (size_t i = 0; i < arr.size(); ++i) {
        if (i > 0) out.push_back(',');
        json::append_json_quoted(out, arr[i]);
    }
    out.push_back(']');
}

void append_json_track(std::string& out, const context_view::Entry& track) {
    out.push_back('{');
    bool first = true;
    auto sep = [&]() {
        if (!first) out.push_back(',');
        first = false;
    };
    if (!track.uri.empty()) {
        sep();
        out.append("\"uri\":");
        json::append_json_quoted(out, track.uri);
    }
    if (!track.uid.empty()) {
        sep();
        out.append("\"uid\":");
        json::append_json_quoted(out, track.uid);
    }
    if (!track.provider.empty()) {
        sep();
        out.append("\"provider\":");
        json::append_json_quoted(out, track.provider);
    }
    if (!track.metadata.empty()) {
        sep();
        out.append("\"metadata\":");
        append_json_string_map(out, track.metadata);
    }
    out.push_back('}');
}

void append_json_play_origin(std::string& out, const PlayOriginData& po) {
    out.push_back('{');
    bool first = true;
    auto field = [&](std::string_view key, const std::string& val) {
        if (val.empty()) return;
        if (!first) out.push_back(',');
        first = false;
        json::append_json_quoted(out, key);
        out.push_back(':');
        json::append_json_quoted(out, val);
    };
    field("feature_identifier", po.feature_identifier);
    field("feature_version", po.feature_version);
    field("view_uri", po.view_uri);
    field("external_referrer", po.external_referrer);
    field("referrer_identifier", po.referrer_identifier);
    field("device_identifier", po.device_identifier);
    if (!po.feature_classes.empty()) {
        if (!first) out.push_back(',');
        first = false;
        out.append("\"feature_classes\":");
        append_json_string_array(out, po.feature_classes);
    }
    field("restriction_identifier", po.restriction_identifier);
    out.push_back('}');
}

bool has_play_origin_data(const PlayOriginData& po) noexcept {
    return !po.feature_identifier.empty() ||
           !po.feature_version.empty() ||
           !po.view_uri.empty() ||
           !po.external_referrer.empty() ||
           !po.referrer_identifier.empty() ||
           !po.device_identifier.empty() ||
           !po.feature_classes.empty() ||
           !po.restriction_identifier.empty();
}

void append_json_logging_params_field(std::string& out, const DecodedLoggingParams& lp) {
    if (!lp.present) {
        return;
    }
    std::string inner;
    bool first = true;
    auto sep = [&]() {
        if (!first) inner.push_back(',');
        first = false;
    };
    if (lp.command_initiated_time.has_value()) {
        sep();
        inner.append("\"command_initiated_time\":");
        inner.append(std::to_string(*lp.command_initiated_time));
    }
    if (lp.command_received_time.has_value()) {
        sep();
        inner.append("\"command_received_time\":");
        inner.append(std::to_string(*lp.command_received_time));
    }
    if (!lp.page_instance_ids.empty()) {
        sep();
        inner.append("\"page_instance_ids\":");
        append_json_string_array(inner, lp.page_instance_ids);
    }
    if (!lp.interaction_ids.empty()) {
        sep();
        inner.append("\"interaction_ids\":");
        append_json_string_array(inner, lp.interaction_ids);
    }
    if (!lp.device_identifier.empty()) {
        sep();
        inner.append("\"device_identifier\":");
        json::append_json_quoted(inner, lp.device_identifier);
    }
    if (!lp.command_id.empty()) {
        sep();
        inner.append("\"command_id\":");
        json::append_json_quoted(inner, lp.command_id);
    }
    if (!inner.empty()) {
        out.append(",\"logging_params\":{");
        out.append(inner);
        out.push_back('}');
    }
}

void append_json_context_object(std::string& out, const DecodedPreparePlay& parsed) {
    out.push_back('{');
    bool first = true;
    auto sep = [&]() {
        if (!first) out.push_back(',');
        first = false;
    };
    if (!parsed.context_uri.empty()) {
        sep();
        out.append("\"uri\":");
        json::append_json_quoted(out, parsed.context_uri);
    }
    const std::string effective_context_url =
        !parsed.context_url.empty()
            ? parsed.context_url
            : (!parsed.context_uri.empty() ? ("context://" + parsed.context_uri) : std::string{});
    if (!effective_context_url.empty()) {
        sep();
        out.append("\"url\":");
        json::append_json_quoted(out, effective_context_url);
    }
    if (!parsed.context_metadata.empty()) {
        sep();
        out.append("\"metadata\":");
        append_json_string_map(out, parsed.context_metadata);
    }
    if (!parsed.pages.empty()) {
        sep();
        out.append("\"pages\":[");
        for (size_t pi = 0; pi < parsed.pages.size(); ++pi) {
            if (pi > 0) out.push_back(',');
            const auto& page = parsed.pages[pi];
            out.push_back('{');
            bool pfirst = true;
            auto psep = [&]() {
                if (!pfirst) out.push_back(',');
                pfirst = false;
            };
            if (!page.page_url.empty()) {
                psep();
                out.append("\"page_url\":");
                json::append_json_quoted(out, page.page_url);
            }
            if (!page.next_page_url.empty()) {
                psep();
                out.append("\"next_page_url\":");
                json::append_json_quoted(out, page.next_page_url);
            }
            if (!page.metadata.empty()) {
                psep();
                out.append("\"metadata\":");
                append_json_string_map(out, page.metadata);
            }
            psep();
            out.append("\"tracks\":[");
            for (size_t ti = 0; ti < page.tracks.size(); ++ti) {
                if (ti > 0) out.push_back(',');
                append_json_track(out, page.tracks[ti]);
            }
            out.push_back(']');
            out.push_back('}');
        }
        out.push_back(']');
    } else if (!parsed.tracks.empty()) {
        sep();
        out.append("\"pages\":[{\"tracks\":[");
        for (size_t ti = 0; ti < parsed.tracks.size(); ++ti) {
            if (ti > 0) out.push_back(',');
            append_json_track(out, parsed.tracks[ti]);
        }
        out.append("]}]");
    }
    out.push_back('}');
}

std::string build_play_command_json(
        std::string_view endpoint,
        const DecodedPreparePlay& parsed,
        bool force_initially_paused) {
    std::string out;
    out.reserve(512);
    out.append("{\"endpoint\":");
    json::append_json_quoted(out, endpoint);

    if (!parsed.context_uri.empty() || !parsed.context_url.empty() ||
        !parsed.tracks.empty() || !parsed.context_metadata.empty()) {
        out.append(",\"context\":");
        append_json_context_object(out, parsed);
    }

    // Build `options` object
    std::string opts_inner;
    bool ofirst = true;
    auto osep = [&]() {
        if (!ofirst) opts_inner.push_back(',');
        ofirst = false;
    };

    const bool has_skip_to =
        !parsed.skip_to.page_url.empty() ||
        parsed.skip_to.page_index.has_value() ||
        !parsed.skip_to.track_uid.empty() ||
        !parsed.skip_to.track_uri.empty() ||
        parsed.skip_to.track_index >= 0;
    if (has_skip_to) {
        osep();
        opts_inner.append("\"skip_to\":{");
        bool sfirst = true;
        auto ssep = [&]() {
            if (!sfirst) opts_inner.push_back(',');
            sfirst = false;
        };
        if (!parsed.skip_to.page_url.empty()) {
            ssep();
            opts_inner.append("\"page_url\":");
            json::append_json_quoted(opts_inner, parsed.skip_to.page_url);
        }
        if (parsed.skip_to.page_index.has_value()) {
            ssep();
            opts_inner.append("\"page_index\":");
            opts_inner.append(std::to_string(*parsed.skip_to.page_index));
        }
        if (!parsed.skip_to.track_uid.empty()) {
            ssep();
            opts_inner.append("\"track_uid\":");
            json::append_json_quoted(opts_inner, parsed.skip_to.track_uid);
        }
        if (!parsed.skip_to.track_uri.empty()) {
            ssep();
            opts_inner.append("\"track_uri\":");
            json::append_json_quoted(opts_inner, parsed.skip_to.track_uri);
        }
        if (parsed.skip_to.track_index >= 0) {
            ssep();
            opts_inner.append("\"track_index\":");
            opts_inner.append(std::to_string(parsed.skip_to.track_index));
        }
        opts_inner.push_back('}');
    }

    if (parsed.seek_to_ms.has_value()) {
        osep();
        opts_inner.append("\"seek_to\":");
        opts_inner.append(std::to_string(std::max<int64_t>(0, *parsed.seek_to_ms)));
    }
    if (force_initially_paused || parsed.initially_paused.has_value()) {
        osep();
        const bool paused = force_initially_paused ? true : *parsed.initially_paused;
        opts_inner.append("\"initially_paused\":");
        opts_inner.append(paused ? "true" : "false");
    }
    if (parsed.always_play_something.has_value()) {
        osep();
        opts_inner.append("\"always_play_something\":");
        opts_inner.append(*parsed.always_play_something ? "true" : "false");
    }
    if (parsed.system_initiated.has_value()) {
        osep();
        opts_inner.append("\"system_initiated\":");
        opts_inner.append(*parsed.system_initiated ? "true" : "false");
    }
    if (!parsed.session_id.empty()) {
        osep();
        opts_inner.append("\"session_id\":");
        json::append_json_quoted(opts_inner, parsed.session_id);
    }
    if (!parsed.license.empty()) {
        osep();
        opts_inner.append("\"license\":");
        json::append_json_quoted(opts_inner, parsed.license);
    }
    if (!parsed.suppressions.empty()) {
        osep();
        opts_inner.append("\"suppressions\":{\"providers\":");
        append_json_string_array(opts_inner, parsed.suppressions);
        opts_inner.push_back('}');
    }
    if (parsed.overrides.shuffling_context.has_value() ||
        parsed.overrides.repeating_context.has_value() ||
        parsed.overrides.repeating_track.has_value() ||
        parsed.overrides.playback_speed.has_value() ||
        !parsed.overrides.modes.empty()) {
        osep();
        opts_inner.append("\"player_options_override\":{");
        bool pofirst = true;
        auto posep = [&]() {
            if (!pofirst) opts_inner.push_back(',');
            pofirst = false;
        };
        if (parsed.overrides.shuffling_context.has_value()) {
            posep();
            opts_inner.append("\"shuffling_context\":");
            opts_inner.append(*parsed.overrides.shuffling_context ? "true" : "false");
        }
        if (parsed.overrides.repeating_context.has_value()) {
            posep();
            opts_inner.append("\"repeating_context\":");
            opts_inner.append(*parsed.overrides.repeating_context ? "true" : "false");
        }
        if (parsed.overrides.repeating_track.has_value()) {
            posep();
            opts_inner.append("\"repeating_track\":");
            opts_inner.append(*parsed.overrides.repeating_track ? "true" : "false");
        }
        if (parsed.overrides.playback_speed.has_value()) {
            posep();
            opts_inner.append("\"playback_speed\":");
            append_json_double(opts_inner, *parsed.overrides.playback_speed);
        }
        if (!parsed.overrides.modes.empty()) {
            posep();
            opts_inner.append("\"modes\":");
            append_json_string_map(opts_inner, parsed.overrides.modes);
        }
        opts_inner.push_back('}');
    }

    if (!opts_inner.empty()) {
        out.append(",\"options\":{");
        out.append(opts_inner);
        out.push_back('}');
    }

    if (has_play_origin_data(parsed.play_origin)) {
        out.append(",\"play_origin\":");
        append_json_play_origin(out, parsed.play_origin);
    }

    if (parsed.play_options.present) {
        std::string po_inner;
        bool first = true;
        auto sep = [&]() {
            if (!first) po_inner.push_back(',');
            first = false;
        };
        if (parsed.play_options.operation.has_value()) {
            sep();
            po_inner.append("\"operation\":");
            const int32_t op = *parsed.play_options.operation;
            if (op == 1) po_inner.append("\"enqueue\"");
            else if (op == 2) po_inner.append("\"push\"");
            else po_inner.append("\"replace\"");
        } else {
            sep();
            po_inner.append("\"operation\":\"replace\"");
        }
        if (parsed.play_options.trigger.has_value()) {
            sep();
            po_inner.append("\"trigger\":");
            const int32_t tr = *parsed.play_options.trigger;
            if (tr == 1) po_inner.append("\"advanced_past_track\"");
            else if (tr == 2) po_inner.append("\"advanced_past_context\"");
            else po_inner.append("\"immediately\"");
        } else {
            sep();
            po_inner.append("\"trigger\":\"immediately\"");
        }
        if (parsed.play_options.playback_speed.has_value() &&
            *parsed.play_options.playback_speed > 0.0) {
            sep();
            po_inner.append("\"playback_speed\":");
            append_json_double(po_inner, *parsed.play_options.playback_speed);
        }
        if (!po_inner.empty()) {
            out.append(",\"play_options\":{");
            out.append(po_inner);
            out.push_back('}');
        }
    } else {
        out.append(",\"play_options\":{\"operation\":\"replace\",\"trigger\":\"immediately\"}");
    }

    append_json_logging_params_field(out, parsed.logging_params);
    out.push_back('}');
    return out;
}

// ============================================================================
// Inbound Connect Command JSON Parsing Helpers
// ============================================================================

bool parse_connect_json_track(
        const json::JsonValue& node,
        context_view::Entry& out_entry,
        std::string_view default_provider = "context") {
    if (!node.is_object()) {
        return false;
    }
    const auto uri_opt = node.get_string("uri");
    const auto uid_opt = node.get_string("uid");
    if ((!uri_opt.has_value() || uri_opt->empty()) &&
        (!uid_opt.has_value() || uid_opt->empty())) {
        return false;
    }
    context_view::Entry entry;
    entry.uri = uri_opt.value_or(std::string{});
    entry.uid = (uid_opt.has_value() && !uid_opt->empty()) ? *uid_opt : generate_track_uid();
    if (entry.uri == "spotify:delimiter" || entry.uri == "spotify:meta:delimiter") {
        entry.type = context_view::EntryType::DELIMITER;
    } else {
        entry.type = context_view::EntryType::TRACK;
    }
    if (const auto* md = node.find("metadata"); md != nullptr && md->is_object()) {
        for (const auto& [k, v] : md->object_value) {
            if (k.empty()) continue;
            if (v.is_string()) entry.metadata[k] = v.string_value;
            else if (v.is_bool()) entry.metadata[k] = v.bool_value ? "true" : "false";
            else if (v.is_int()) entry.metadata[k] = std::to_string(v.int_value);
        }
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
        entry.provider.assign(default_provider);
    }
    entry.metadata["provider"] = entry.provider;
    out_entry = std::move(entry);
    return true;
}

void parse_connect_json_play_origin(
        const json::JsonValue& po,
        PlayOriginData& out) {
    if (!po.is_object()) {
        return;
    }
    out.feature_identifier = po.get_string("feature_identifier").value_or(std::string{});
    out.feature_version = po.get_string("feature_version").value_or(std::string{});
    out.view_uri = po.get_string("view_uri").value_or(std::string{});
    out.external_referrer = po.get_string("external_referrer").value_or(std::string{});
    out.referrer_identifier = po.get_string("referrer_identifier").value_or(std::string{});
    out.device_identifier = po.get_string("device_identifier").value_or(std::string{});
    out.restriction_identifier = po.get_string("restriction_identifier").value_or(std::string{});
    out.feature_classes.clear();
    if (const auto* fcs = po.find("feature_classes"); fcs != nullptr && fcs->is_array()) {
        for (const auto& fc : fcs->array_value) {
            if (fc.is_string() && !fc.string_value.empty()) {
                out.feature_classes.push_back(fc.string_value);
            }
        }
    }
}

void parse_connect_json_context_node(
        const json::JsonValue& ctx_node,
        std::string& ctx_uri,
        std::string& ctx_url,
        std::unordered_map<std::string, std::string>& ctx_md,
        std::unordered_map<std::string, std::string>& page_md,
        std::vector<context_view::Entry>& tracks,
        std::vector<size_t>& page_track_offsets,
        std::string& page_url,
        std::string& next_page_url) {
    if (!ctx_node.is_object()) {
        return;
    }
    ctx_uri = ctx_node.get_string("uri").value_or(std::string{});
    ctx_url = ctx_node.get_string("url").value_or(std::string{});
    if (const auto* md = ctx_node.find("metadata"); md != nullptr && md->is_object()) {
        for (const auto& [k, v] : md->object_value) {
            if (k.empty()) continue;
            if (v.is_string()) ctx_md[k] = v.string_value;
            else if (v.is_bool()) ctx_md[k] = v.bool_value ? "true" : "false";
            else if (v.is_int()) ctx_md[k] = std::to_string(v.int_value);
        }
    }
    if (const auto* pages = ctx_node.find("pages"); pages != nullptr && pages->is_array()) {
        for (const auto& page : pages->array_value) {
            if (!page.is_object()) {
                continue;
            }
            page_track_offsets.push_back(tracks.size());
            if (page_url.empty()) {
                page_url = page.get_string("page_url").value_or(std::string{});
                next_page_url = page.get_string("next_page_url").value_or(std::string{});
            }
            if (const auto* pmd = page.find("metadata"); pmd != nullptr && pmd->is_object()) {
                for (const auto& [k, v] : pmd->object_value) {
                    if (k.empty()) continue;
                    if (v.is_string()) page_md[k] = v.string_value;
                }
            }
            if (const auto* trks = page.find("tracks"); trks != nullptr && trks->is_array()) {
                for (const auto& tnode : trks->array_value) {
                    context_view::Entry entry;
                    if (parse_connect_json_track(tnode, entry, "context") &&
                        !entry.uri.empty() &&
                        !entry.is_delimiter()) {
                        tracks.push_back(std::move(entry));
                    }
                }
            }
        }
    }
}

std::optional<uint64_t> parse_json_uint64_or_string(const json::JsonValue& obj, std::string_view key) {
    if (const auto iv = obj.get_int64(key); iv.has_value() && *iv >= 0) {
        return static_cast<uint64_t>(*iv);
    }
    if (const auto sv = obj.get_string(key); sv.has_value() && !sv->empty()) {
        uint64_t parsed = 0;
        const auto res = std::from_chars(sv->data(), sv->data() + sv->size(), parsed);
        if (res.ec == std::errc{} && res.ptr == sv->data() + sv->size()) {
            return parsed;
        }
    }
    return std::nullopt;
}

constexpr size_t kDecoratePrevWindowSize = 5;
constexpr size_t kDecorateNextWindowSize = 25;

bool is_vault_masked_entry(const context_view::Entry& entry) noexcept {
    return SpotifyPlaybackPolicy::is_vault_masked_entry(entry);
}

bool has_non_empty_meta(const context_view::Entry& entry, const char* key) noexcept {
    const auto it = entry.metadata.find(key);
    return it != entry.metadata.end() && !it->second.empty();
}

bool is_decoratable_spotify_entry(const context_view::Entry& entry) noexcept {
    return SpotifyPlaybackPolicy::is_decoratable_spotify_entry(entry);
}

bool has_complete_display_metadata(const context_view::Entry& entry) noexcept {
    const bool has_title = has_non_empty_meta(entry, "title");
    const bool has_image =
        has_non_empty_meta(entry, "image_url") ||
        has_non_empty_meta(entry, "image_large_url") ||
        has_non_empty_meta(entry, "image_small_url") ||
        has_non_empty_meta(entry, "image_xlarge_url");
    if (entry.uri.rfind("spotify:episode:", 0) == 0) {
        const bool has_show_or_publisher =
            has_non_empty_meta(entry, "artist_name") ||
            has_non_empty_meta(entry, "album_title");
        return has_title && has_show_or_publisher && has_image;
    }
    const bool has_artist = has_non_empty_meta(entry, "artist_name");
    return has_title && has_artist && has_image;
}

uint32_t resolve_target_alias_id(const json::JsonValue* parsed, uint32_t explicit_alias_id) noexcept {
    if (explicit_alias_id != 0) {
        return explicit_alias_id;
    }
    if (parsed == nullptr || !parsed->is_object()) {
        return 0;
    }
    if (const auto top = parsed->get_int64("target_alias_id"); top.has_value() && *top > 0) {
        return static_cast<uint32_t>(*top);
    }
    if (const auto* opts = parsed->find("options"); opts != nullptr && opts->is_object()) {
        if (const auto nested = opts->get_int64("target_alias_id");
            nested.has_value() && *nested > 0) {
            return static_cast<uint32_t>(*nested);
        }
    }
    return 0;
}

}  // anonymous namespace

ContextPlayerImpl::SessionPlaybackPhase ContextPlayerImpl::map_track_player_state_to_phase(
    const rendering::TrackPlayerState& state) noexcept {
    switch (state.phase) {
        case rendering::TrackPlayerPhase::Idle:
            return SessionPlaybackPhase::Idle;
        case rendering::TrackPlayerPhase::Buffering:
            return SessionPlaybackPhase::BufferingPlay;
        case rendering::TrackPlayerPhase::Playing:
            return SessionPlaybackPhase::Playing;
        case rendering::TrackPlayerPhase::Paused:
            return SessionPlaybackPhase::Paused;
        case rendering::TrackPlayerPhase::Stopped:
            return SessionPlaybackPhase::Idle;
        case rendering::TrackPlayerPhase::Faulted:
            return SessionPlaybackPhase::Halted;
    }
    return SessionPlaybackPhase::Idle;
}

void ContextPlayerImpl::apply_repeat_overrides_locked(
    std::optional<bool> repeating_context,
    std::optional<bool> repeating_track) noexcept {
    bool next_ctx = (repeat_mode_ == SessionRepeatMode::Context ||
                     repeat_mode_ == SessionRepeatMode::Track);
    bool next_trk = (repeat_mode_ == SessionRepeatMode::Track);

    if (repeating_context.has_value()) {
        next_ctx = *repeating_context;
    }
    if (repeating_track.has_value()) {
        next_trk = *repeating_track;
    }

    if (next_trk) {
        repeat_mode_ = SessionRepeatMode::Track;
    } else if (next_ctx) {
        repeat_mode_ = SessionRepeatMode::Context;
    } else {
        repeat_mode_ = SessionRepeatMode::Off;
    }
}

void ContextPlayerImpl::begin_track_transition_locked(
    const context_view::Entry& track,
    SessionPlaybackPhase initial_phase) {
    current_track_ = track;
    playback_phase_ = initial_phase;
    playback_id_ = generate_track_uid();
    position_ms_ = 0;
    duration_ms_ = 0;
    explicit_prev_tracks_.reset();
}

void ContextPlayerImpl::bump_queue_revision_locked() noexcept {
    ++queue_revision_;
    if (queue_revision_ == 0) {
        queue_revision_ = 1;
    }
}

void ContextPlayerImpl::transition_to_local_locked() noexcept {
    if (origin_ == PlaybackOrigin::kRemoteMirrored) {
        origin_ = PlaybackOrigin::kLocal;
        mirrored_state_ = MirroredRemotePlaybackState{};
    }
    paused_for_remote_takeover_ = false;
}

ContextPlayerImpl::ContextPlayerImpl(
    std::shared_ptr<rendering::TrackPlayer> track_player,
    metadata::TrackInfoProvider* track_info_provider)
    : track_player_(std::move(track_player)),
      track_info_provider_(track_info_provider) {
    LOGI("ContextPlayerImpl initialized (track_player=%p track_info_provider=%p)",
         track_player_.get(),
         static_cast<void*>(track_info_provider_));
    if (track_player_) {
        bind_track_player_callbacks(track_player_);
    }
    if (track_info_provider_ != nullptr) {
        auto alive = alive_flag_;
        metadata_listener_id_ = track_info_provider_->addListener(
            [this, alive = std::move(alive)](const std::string& uri, const metadata::TrackInfo& info) {
                if (!alive->load(std::memory_order_acquire)) {
                    return;
                }
                on_track_metadata_resolved(uri, info);
            });
    }
}

ContextPlayerImpl::~ContextPlayerImpl() {
    alive_flag_->store(false, std::memory_order_release);
    if (track_info_provider_ != nullptr && metadata_listener_id_ != 0) {
        track_info_provider_->removeListener(metadata_listener_id_);
        metadata_listener_id_ = 0;
    }
    stop_sleep_timer_thread();
    if (track_player_) {
        track_player_->setCallbacks(rendering::TrackPlayerCallbacks{});
        track_player_->stop(rendering::StopReason::SessionDeleted);
    }
    LOGI("ContextPlayerImpl destroying session_id=%s", session_id_.c_str());
}

void ContextPlayerImpl::set_track_player(std::shared_ptr<rendering::TrackPlayer> track_player) {
    std::shared_ptr<rendering::TrackPlayer> previous;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        previous = std::move(track_player_);
        track_player_ = track_player;
        pending_player_sync_token_ = 0;
    }
    if (previous) {
        previous->setCallbacks(rendering::TrackPlayerCallbacks{});
        previous->stop(rendering::StopReason::SessionDeleted);
    }
    if (track_player) {
        bind_track_player_callbacks(track_player);
    }
}

std::shared_ptr<rendering::TrackPlayer> ContextPlayerImpl::get_track_player() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return track_player_;
}

void ContextPlayerImpl::set_remote_playback_delegate(IRemotePlaybackDelegate* delegate) {
    std::lock_guard<std::mutex> lock(mutex_);
    remote_delegate_ = delegate;
    PLAYER_REMOTE_LOGI(
        "Remote playback delegate %s",
        delegate != nullptr ? "attached" : "detached");
}

void ContextPlayerImpl::apply_remote_mirrored_state(const MirroredRemotePlaybackState& state) {
    if (state.active_device_id.empty()) {
        clear_remote_mirrored_state();
        return;
    }

    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes;
    std::vector<uint8_t> qc_bytes;
    std::vector<PendingMetadataRequest> pending_metadata;
    bool log_transition = false;
    std::string track_uri;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        const bool device_changed =
            (origin_ != PlaybackOrigin::kRemoteMirrored) ||
            (mirrored_state_.active_device_id != state.active_device_id);
        const std::string prev_track_uri =
            mirrored_state_.current_track.has_value() ? mirrored_state_.current_track->uri : std::string{};
        track_uri = state.current_track.has_value() ? state.current_track->uri : std::string{};
        log_transition = device_changed || (prev_track_uri != track_uri);

        origin_ = PlaybackOrigin::kRemoteMirrored;
        mirrored_state_ = state;
        decorate_mirrored_state_locked(pending_metadata);
        emit_state_locked(false);
        emit_queue_locked();
        sc_cb = state_changed_callback_;
        qc_cb = queue_changed_callback_;
        sc_bytes = cached_state_bytes_;
        qc_bytes = cached_queue_bytes_;
    }

    dispatch_metadata_requests(pending_metadata);

    if (log_transition) {
        PLAYER_REMOTE_LOGI(
            "Mirrored remote playback active_device=%s playing=%d paused=%d track=%s pos=%lldms",
            state.active_device_id.c_str(),
            state.is_playing ? 1 : 0,
            state.is_paused ? 1 : 0,
            track_uri.c_str(),
            static_cast<long long>(state.position_as_of_timestamp_ms));
    }

    // Emit strictly to Dart UI subscribers; NEVER dispatch PlayerStateListener (prevents PutState echo).
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
}

void ContextPlayerImpl::clear_remote_mirrored_state() {
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes;
    std::vector<uint8_t> qc_bytes;
    bool was_mirrored = false;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (origin_ != PlaybackOrigin::kRemoteMirrored) {
            return;
        }
        was_mirrored = true;
        origin_ = PlaybackOrigin::kLocal;
        mirrored_state_ = MirroredRemotePlaybackState{};
        emit_state_locked(false);
        emit_queue_locked();
        sc_cb = state_changed_callback_;
        qc_cb = queue_changed_callback_;
        sc_bytes = cached_state_bytes_;
        qc_bytes = cached_queue_bytes_;
    }

    if (was_mirrored) {
        PLAYER_REMOTE_LOGI("Cleared remote mirrored playback state -> origin=kLocal");
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    }
}

void ContextPlayerImpl::pause_for_remote_takeover() {
    std::shared_ptr<rendering::TrackPlayer> tp;
    uint64_t sync_token = 0;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        paused_for_remote_takeover_ = true;
        tp = track_player_;
        if (tp) {
            sync_token = ++next_player_sync_token_;
            pending_player_sync_token_ = sync_token;
        }
    }

    if (tp) {
        tp->pause();
    }

    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    bool should_emit_ui = false;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (pending_player_sync_token_ == sync_token) {
            pending_player_sync_token_ = 0;
        }
        if (track_player_) {
            const int64_t pos = track_player_->getPosition();
            if (pos >= 0) {
                position_ms_ = pos;
            }
        }
        if (is_phase_playing(playback_phase_) ||
            playback_phase_ == SessionPlaybackPhase::BufferingPaused) {
            playback_phase_ = SessionPlaybackPhase::Paused;
        }
        if (origin_ == PlaybackOrigin::kLocal) {
            emit_state_locked(false);
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
            should_emit_ui = true;
        }
    }

    PLAYER_REMOTE_LOGI("Paused local audio playback for remote takeover (PutState listeners suppressed)");
    if (should_emit_ui && sc_cb && !sc_bytes.empty()) {
        sc_cb(sc_bytes.data(), sc_bytes.size());
    }
}

void ContextPlayerImpl::set_spclient_base_url(const std::string& url) {
    context_resolve_client_.set_spclient_base_url(url);
    if (track_info_provider_ != nullptr) {
        track_info_provider_->set_spclient_base_url(url);
    }
}

std::string ContextPlayerImpl::spclient_base_url() const {
    return context_resolve_client_.spclient_base_url();
}

PlaybackOrigin ContextPlayerImpl::playback_origin() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return origin_;
}

ContextPlayerImpl::SleepTimerState ContextPlayerImpl::sleep_timer_state() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return sleep_timer_;
}

void ContextPlayerImpl::ensure_sleep_timer_thread_locked() {
    if (!sleep_timer_thread_.joinable() && !sleep_timer_stop_) {
        sleep_timer_thread_ = std::thread(&ContextPlayerImpl::sleep_timer_worker_loop, this);
    }
}

void ContextPlayerImpl::stop_sleep_timer_thread() {
    std::thread to_join;
    {
        std::lock_guard<std::mutex> lock(sleep_timer_mutex_);
        sleep_timer_stop_ = true;
        ++sleep_timer_epoch_;
    }
    sleep_timer_cv_.notify_all();
    {
        std::lock_guard<std::mutex> lock(sleep_timer_mutex_);
        if (sleep_timer_thread_.joinable() &&
            sleep_timer_thread_.get_id() != std::this_thread::get_id()) {
            to_join = std::move(sleep_timer_thread_);
        }
    }
    if (to_join.joinable()) {
        to_join.join();
    }
}

void ContextPlayerImpl::sleep_timer_worker_loop() {
    while (true) {
        int64_t target_ms = 0;
        uint64_t observed_epoch = 0;
        {
            std::unique_lock<std::mutex> slock(sleep_timer_mutex_);
            sleep_timer_cv_.wait(slock, [this]() {
                if (sleep_timer_stop_) return true;
                std::lock_guard<std::mutex> plock(mutex_);
                return sleep_timer_.mode == SleepTimerMode::kDuration &&
                       sleep_timer_.expires_at_ms > 0;
            });
            if (sleep_timer_stop_) {
                break;
            }
            observed_epoch = sleep_timer_epoch_;
            {
                std::lock_guard<std::mutex> plock(mutex_);
                if (sleep_timer_.mode != SleepTimerMode::kDuration ||
                    sleep_timer_.expires_at_ms <= 0) {
                    continue;
                }
                target_ms = sleep_timer_.expires_at_ms;
            }

            const auto deadline =
                std::chrono::system_clock::time_point(std::chrono::milliseconds(target_ms));
            sleep_timer_cv_.wait_until(slock, deadline, [this, observed_epoch]() {
                return sleep_timer_stop_ || sleep_timer_epoch_ != observed_epoch;
            });
            if (sleep_timer_stop_) {
                break;
            }
            if (sleep_timer_epoch_ != observed_epoch) {
                continue;
            }
        }

        bool should_pause_local = false;
        {
            std::lock_guard<std::mutex> plock(mutex_);
            if (sleep_timer_.mode == SleepTimerMode::kDuration &&
                sleep_timer_.expires_at_ms == target_ms &&
                get_current_timestamp_ms() >= target_ms) {
                sleep_timer_ = SleepTimerState{};
                should_pause_local =
                    (origin_ == PlaybackOrigin::kLocal) &&
                    is_phase_playing(playback_phase_);
            }
        }
        if (should_pause_local) {
            PLAYER_REMOTE_LOGI("Sleep timer expired -> pausing local playback");
            if (!pause()) {
                PLAYER_REMOTE_LOGW("Sleep timer expired: pause() returned false");
            }
        }
    }
}

void ContextPlayerImpl::apply_sleep_timer_state(const SleepTimerState& next_timer) {
    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    ConnectDispatchBundle connect_bundle;
    {
        std::lock_guard<std::mutex> plock(mutex_);
        transition_to_local_locked();
        sleep_timer_ = next_timer;
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }
    {
        std::lock_guard<std::mutex> slock(sleep_timer_mutex_);
        ++sleep_timer_epoch_;
        if (next_timer.mode == SleepTimerMode::kDuration && next_timer.expires_at_ms > 0) {
            ensure_sleep_timer_thread_locked();
        }
    }
    sleep_timer_cv_.notify_all();

    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
}

void ContextPlayerImpl::bind_track_player_callbacks(
    const std::shared_ptr<rendering::TrackPlayer>& tp) {
    rendering::TrackPlayerCallbacks cbs;
    cbs.peek_track = [this](bool /*playable_only*/) -> std::optional<context_view::Entry> {
        std::lock_guard<std::mutex> lock(mutex_);
        if (origin_ == PlaybackOrigin::kRemoteMirrored) {
            return std::nullopt;
        }
        if (!user_queue_.empty()) {
            return user_queue_.front();
        }
        const auto next = context_processor_.get_next_tracks(1);
        if (!next.empty()) {
            return next.front();
        }
        return std::nullopt;
    };
    cbs.advance_track = [this](rendering::AdvanceReason reason) {
        advance_to_next_track(reason);
    };
    cbs.on_state_changed = [this](const rendering::TrackPlayerState& state) {
        on_track_player_state_changed(state);
    };
    cbs.on_track_metadata_resolved = [this](const std::string& uri, const metadata::TrackInfo& info) {
        on_track_metadata_resolved(uri, info);
    };
    cbs.on_error = [this](int32_t code, const std::string& message) {
        on_track_player_error(code, message);
    };
    tp->setCallbacks(std::move(cbs));
}

void ContextPlayerImpl::on_track_player_state_changed(const rendering::TrackPlayerState& state) {
    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    ConnectDispatchBundle connect_bundle;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (origin_ == PlaybackOrigin::kRemoteMirrored || pending_player_sync_token_ != 0) {
            return;
        }
        const SessionPlaybackPhase mapped = map_track_player_state_to_phase(state);
        playback_phase_ = mapped;
        if (state.position_ms >= 0) {
            position_ms_ = state.position_ms;
        }
        if (state.duration_ms > 0) {
            duration_ms_ = state.duration_ms;
        }
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
        if (!(paused_for_remote_takeover_ &&
              (mapped == SessionPlaybackPhase::Paused || mapped == SessionPlaybackPhase::Idle))) {
            capture_connect_dispatch_locked(connect_bundle);
        }
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
}

bool ContextPlayerImpl::apply_track_info_locked(
    context_view::Entry& track,
    const metadata::TrackInfo& info) {
    bool changed = false;
    auto set_if_missing = [&track, &changed](const char* key, const std::string& val) {
        if (val.empty()) return;
        auto it = track.metadata.find(key);
        if (it == track.metadata.end() || it->second.empty()) {
            track.metadata[key] = val;
            changed = true;
        }
    };
    set_if_missing("title", info.title);
    set_if_missing("artist_name", info.artist_name);
    set_if_missing("artist_uri", info.artist_uri);
    set_if_missing("album_title", info.album_title);
    set_if_missing("album_uri", info.album_uri);
    set_if_missing("image_small_url", info.image_small_url);
    set_if_missing("image_url", info.image_url);
    set_if_missing("image_large_url", info.image_large_url);
    set_if_missing("image_xlarge_url", info.image_xlarge_url);
    if (info.is_explicit) {
        set_if_missing("is_explicit", "true");
    }
    if (info.duration_ms > 0) {
        set_if_missing("duration", std::to_string(info.duration_ms));
    }
    return changed;
}

bool ContextPlayerImpl::decorate_entry_locked(
    context_view::Entry& entry,
    network::AcquisitionIntent intent,
    std::unordered_set<std::string>& seen_uris,
    std::vector<PendingMetadataRequest>& out_misses) {
    if (track_info_provider_ == nullptr) {
        return false;
    }
    if (!is_decoratable_spotify_entry(entry) || has_complete_display_metadata(entry)) {
        return false;
    }
    const auto cached = track_info_provider_->getCached(entry.uri);
    bool changed = false;
    if (cached.has_value()) {
        changed = apply_track_info_locked(entry, *cached);
    }
    if (!cached.has_value() || !cached->hasDisplayMetadata()) {
        if (seen_uris.insert(entry.uri).second) {
            out_misses.push_back(PendingMetadataRequest{entry.uri, intent});
        }
    }
    return changed;
}

void ContextPlayerImpl::decorate_mirrored_state_locked(
    std::vector<PendingMetadataRequest>& out_misses) {
    if (track_info_provider_ == nullptr) {
        return;
    }
    std::unordered_set<std::string> seen_uris;

    if (mirrored_state_.current_track.has_value()) {
        decorate_entry_locked(
            *mirrored_state_.current_track,
            network::AcquisitionIntent::InteractivePlayback,
            seen_uris,
            out_misses);
        if (mirrored_state_.duration_ms <= 0) {
            const auto dur_it = mirrored_state_.current_track->metadata.find("duration");
            if (dur_it != mirrored_state_.current_track->metadata.end() && !dur_it->second.empty()) {
                int64_t parsed_dur = 0;
                const auto res = std::from_chars(
                    dur_it->second.data(),
                    dur_it->second.data() + dur_it->second.size(),
                    parsed_dur);
                if (res.ec == std::errc{} &&
                    res.ptr == dur_it->second.data() + dur_it->second.size() &&
                    parsed_dur > 0) {
                    mirrored_state_.duration_ms = parsed_dur;
                }
            }
        }
    }

    const size_t prev_count = mirrored_state_.prev_tracks.size();
    const size_t prev_start =
        prev_count > kDecoratePrevWindowSize ? (prev_count - kDecoratePrevWindowSize) : 0;
    for (size_t i = prev_start; i < prev_count; ++i) {
        decorate_entry_locked(
            mirrored_state_.prev_tracks[i],
            network::AcquisitionIntent::BackgroundPrefetch,
            seen_uris,
            out_misses);
    }

    const size_t next_limit = std::min(mirrored_state_.next_tracks.size(), kDecorateNextWindowSize);
    for (size_t i = 0; i < next_limit; ++i) {
        decorate_entry_locked(
            mirrored_state_.next_tracks[i],
            network::AcquisitionIntent::BackgroundPrefetch,
            seen_uris,
            out_misses);
    }
}

void ContextPlayerImpl::decorate_local_queue_locked(
    std::vector<PendingMetadataRequest>& out_misses) {
    if (track_info_provider_ == nullptr) {
        return;
    }
    if (SpotifyPlaybackPolicy::is_vault_context(
            context_uri_, context_url_, context_metadata_, play_origin_) ||
        SpotifyPlaybackPolicy::is_local_context(
            context_uri_, context_url_, play_origin_)) {
        return;
    }
    std::unordered_set<std::string> seen_uris;

    if (current_track_.has_value()) {
        if (decorate_entry_locked(
                *current_track_,
                network::AcquisitionIntent::InteractivePlayback,
                seen_uris,
                out_misses)) {
            if (const auto cached = track_info_provider_->getCached(current_track_->uri);
                cached.has_value()) {
                if (duration_ms_ <= 0 && cached->duration_ms > 0) {
                    duration_ms_ = cached->duration_ms;
                }
                context_processor_.apply_metadata_for_uri(
                    current_track_->uri, [&cached](context_view::Entry& e) -> bool {
                        return !SpotifyPlaybackPolicy::is_vault_entry(e) &&
                               !SpotifyPlaybackPolicy::is_local_entry(e) &&
                               apply_track_info_locked(e, *cached);
                    });
            }
        }
    }

    const size_t user_queue_limit = std::min(user_queue_.size(), kDecorateNextWindowSize);
    for (size_t i = 0; i < user_queue_limit; ++i) {
        decorate_entry_locked(
            user_queue_[i],
            network::AcquisitionIntent::BackgroundPrefetch,
            seen_uris,
            out_misses);
    }

    const size_t remaining_next =
        kDecorateNextWindowSize > user_queue_limit ? (kDecorateNextWindowSize - user_queue_limit) : 0;
    if (remaining_next > 0) {
        const auto ctx_next = context_processor_.get_next_tracks(static_cast<int32_t>(remaining_next));
        for (const auto& entry : ctx_next) {
            if (!is_decoratable_spotify_entry(entry) || has_complete_display_metadata(entry)) {
                continue;
            }
            const auto cached = track_info_provider_->getCached(entry.uri);
            if (cached.has_value()) {
                context_processor_.apply_metadata_for_uri(
                    entry.uri, [&cached](context_view::Entry& e) -> bool {
                        return !SpotifyPlaybackPolicy::is_vault_entry(e) &&
                               !SpotifyPlaybackPolicy::is_local_entry(e) &&
                               apply_track_info_locked(e, *cached);
                    });
            }
            if (!cached.has_value() || !cached->hasDisplayMetadata()) {
                if (seen_uris.insert(entry.uri).second) {
                    out_misses.push_back(PendingMetadataRequest{
                        entry.uri, network::AcquisitionIntent::BackgroundPrefetch});
                }
            }
        }
    }

    if (explicit_prev_tracks_.has_value()) {
        const size_t prev_limit = std::min(explicit_prev_tracks_->size(), kDecoratePrevWindowSize);
        for (size_t i = 0; i < prev_limit; ++i) {
            decorate_entry_locked(
                (*explicit_prev_tracks_)[i],
                network::AcquisitionIntent::BackgroundPrefetch,
                seen_uris,
                out_misses);
        }
    } else {
        const auto ctx_prev = context_processor_.get_prev_tracks();
        const size_t prev_limit = std::min(ctx_prev.size(), kDecoratePrevWindowSize);
        for (size_t i = 0; i < prev_limit; ++i) {
            const auto& entry = ctx_prev[i];
            if (!is_decoratable_spotify_entry(entry) || has_complete_display_metadata(entry)) {
                continue;
            }
            const auto cached = track_info_provider_->getCached(entry.uri);
            if (cached.has_value()) {
                context_processor_.apply_metadata_for_uri(
                    entry.uri, [&cached](context_view::Entry& e) -> bool {
                        return !SpotifyPlaybackPolicy::is_vault_entry(e) &&
                               !SpotifyPlaybackPolicy::is_local_entry(e) &&
                               apply_track_info_locked(e, *cached);
                    });
            }
            if (!cached.has_value() || !cached->hasDisplayMetadata()) {
                if (seen_uris.insert(entry.uri).second) {
                    out_misses.push_back(PendingMetadataRequest{
                        entry.uri, network::AcquisitionIntent::BackgroundPrefetch});
                }
            }
        }
    }
}

void ContextPlayerImpl::dispatch_metadata_requests(
    const std::vector<PendingMetadataRequest>& requests) const {
    if (track_info_provider_ == nullptr || requests.empty()) {
        return;
    }
    for (const auto& req : requests) {
        track_info_provider_->requestResolution(req.uri, req.intent);
    }
}

void ContextPlayerImpl::on_track_metadata_resolved(
    const std::string& uri,
    const metadata::TrackInfo& info) {
    if (uri.empty()) {
        return;
    }

    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes;
    std::vector<uint8_t> qc_bytes;
    ConnectDispatchBundle connect_bundle;
    {
        std::lock_guard<std::mutex> lock(mutex_);

        if (origin_ == PlaybackOrigin::kRemoteMirrored) {
            bool any_changed = false;
            if (mirrored_state_.current_track.has_value() &&
                mirrored_state_.current_track->uri == uri) {
                if (!is_vault_masked_entry(*mirrored_state_.current_track)) {
                    if (apply_track_info_locked(*mirrored_state_.current_track, info)) {
                        any_changed = true;
                    }
                }
                if (info.duration_ms > 0) {
                    if (mirrored_state_.duration_ms <= 0) {
                        mirrored_state_.duration_ms = info.duration_ms;
                        any_changed = true;
                    }
                    auto dur_it = mirrored_state_.current_track->metadata.find("duration");
                    if (dur_it == mirrored_state_.current_track->metadata.end() ||
                        dur_it->second.empty()) {
                        mirrored_state_.current_track->metadata["duration"] =
                            std::to_string(info.duration_ms);
                        any_changed = true;
                    }
                }
            }
            for (auto& pt : mirrored_state_.prev_tracks) {
                if (pt.uri == uri && !is_vault_masked_entry(pt)) {
                    if (apply_track_info_locked(pt, info)) {
                        any_changed = true;
                    }
                }
            }
            for (auto& nt : mirrored_state_.next_tracks) {
                if (nt.uri == uri && !is_vault_masked_entry(nt)) {
                    if (apply_track_info_locked(nt, info)) {
                        any_changed = true;
                    }
                }
            }
            if (!any_changed) {
                return;
            }
            emit_state_locked(false);
            emit_queue_locked();
            sc_cb = state_changed_callback_;
            qc_cb = queue_changed_callback_;
            sc_bytes = cached_state_bytes_;
            qc_bytes = cached_queue_bytes_;
            // Strictly DO NOT notify Connect PlayerStateListener / PutState while mirroring remote.
        } else {
            bool current_changed = false;
            bool queue_changed = false;

            if (current_track_.has_value() && current_track_->uri == uri &&
                !SpotifyPlaybackPolicy::is_vault_entry(*current_track_) &&
                !SpotifyPlaybackPolicy::is_local_entry(*current_track_)) {
                if (apply_track_info_locked(*current_track_, info)) {
                    current_changed = true;
                }
                if (info.duration_ms > 0) {
                    if (duration_ms_ <= 0) {
                        duration_ms_ = info.duration_ms;
                        current_changed = true;
                    }
                    auto dur_it = current_track_->metadata.find("duration");
                    if (dur_it == current_track_->metadata.end() || dur_it->second.empty()) {
                        current_track_->metadata["duration"] = std::to_string(info.duration_ms);
                        current_changed = true;
                    }
                }
            }

            for (auto& queued : user_queue_) {
                if (queued.uri == uri &&
                    !SpotifyPlaybackPolicy::is_vault_entry(queued) &&
                    !SpotifyPlaybackPolicy::is_local_entry(queued)) {
                    if (apply_track_info_locked(queued, info)) {
                        queue_changed = true;
                    }
                }
            }

            if (context_processor_.apply_metadata_for_uri(
                    uri, [&info](context_view::Entry& entry) -> bool {
                        if (SpotifyPlaybackPolicy::is_vault_entry(entry) ||
                            SpotifyPlaybackPolicy::is_local_entry(entry)) {
                            return false;
                        }
                        return apply_track_info_locked(entry, info);
                    })) {
                queue_changed = true;
            }

            if (explicit_prev_tracks_.has_value()) {
                for (auto& prev : *explicit_prev_tracks_) {
                    if (prev.uri == uri &&
                        !SpotifyPlaybackPolicy::is_vault_entry(prev) &&
                        !SpotifyPlaybackPolicy::is_local_entry(prev)) {
                        if (apply_track_info_locked(prev, info)) {
                            queue_changed = true;
                        }
                    }
                }
            }

            if (!current_changed && !queue_changed) {
                return;
            }

            emit_state_locked();
            emit_queue_locked();
            sc_cb = state_changed_callback_;
            qc_cb = queue_changed_callback_;
            sc_bytes = cached_state_bytes_;
            qc_bytes = cached_queue_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
}

void ContextPlayerImpl::on_track_player_error(int32_t /*code*/, const std::string& message) {
    ErrorCallback err_cb;
    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    ConnectDispatchBundle connect_bundle;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (origin_ == PlaybackOrigin::kRemoteMirrored) {
            return;
        }
        playback_phase_ = SessionPlaybackPhase::Halted;
        last_error_ = "LOAD_FAILED";
        err_cb = error_callback_;
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
    if (err_cb) err_cb("LOAD_FAILED", message);
}

void ContextPlayerImpl::set_state_changed_callback(StateChangedCallback cb) {
    std::lock_guard<std::mutex> lock(mutex_);
    state_changed_callback_ = std::move(cb);
}

void ContextPlayerImpl::set_queue_changed_callback(QueueChangedCallback cb) {
    std::lock_guard<std::mutex> lock(mutex_);
    queue_changed_callback_ = std::move(cb);
}

void ContextPlayerImpl::set_error_callback(ErrorCallback cb) {
    std::lock_guard<std::mutex> lock(mutex_);
    error_callback_ = std::move(cb);
}

ContextPlayerImpl::OutboundForwardOutcome ContextPlayerImpl::try_forward_remote_command(
        const std::string& method_name,
        const uint8_t* payload,
        size_t payload_len) {
    IRemotePlaybackDelegate* delegate = nullptr;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        delegate = remote_delegate_;
    }
    if (delegate == nullptr || !delegate->is_remote_active()) {
        return OutboundForwardOutcome{.intercepted = false, .ok = false};
    }

    std::string endpoint;
    std::string payload_json;
    std::string intent_id;
    bool only_for_local = false;

    if (method_name == "Play") {
        if (!payload || payload_len == 0) {
            endpoint = "resume";
            payload_json = "{\"endpoint\":\"resume\"}";
        } else {
            DecodedPreparePlay parsed;
            if (!parse_prepare_play_request(payload, payload_len, parsed)) {
                PLAYER_REMOTE_LOGE("Outbound Play: malformed PlayRequest protobuf len=%zu", payload_len);
                {
                    std::lock_guard<std::mutex> lock(mutex_);
                    last_error_ = "INVALID_PLAY_REQUEST";
                }
                return OutboundForwardOutcome{.intercepted = true, .ok = false};
            }
            only_for_local = parsed.command_options.only_for_local_device;
            if (!only_for_local) {
                endpoint = "play";
                payload_json = build_play_command_json(endpoint, parsed, false);
                intent_id = extract_intent_id(parsed.logging_params);
            }
        }
    } else if (method_name == "PreparePlay") {
        DecodedPreparePlay parsed;
        if (!parse_prepare_play_request(payload, payload_len, parsed)) {
            PLAYER_REMOTE_LOGE("Outbound PreparePlay: malformed PreparePlayRequest len=%zu", payload_len);
            {
                std::lock_guard<std::mutex> lock(mutex_);
                last_error_ = "INVALID_PREPARE_PLAY_REQUEST";
            }
            return OutboundForwardOutcome{.intercepted = true, .ok = false};
        }
        only_for_local = parsed.command_options.only_for_local_device;
        if (!only_for_local) {
            endpoint = "prepare_play";
            payload_json = build_play_command_json(endpoint, parsed, true);
            intent_id = extract_intent_id(parsed.logging_params);
        }
    } else if (method_name == "PlayPrepared") {
        DecodedPlayPreparedRequest req;
        if (payload != nullptr && payload_len > 0 &&
            !decode_play_prepared_request_full(payload, payload_len, req)) {
            PLAYER_REMOTE_LOGW("Outbound PlayPrepared: failed to decode payload len=%zu", payload_len);
        }
        only_for_local = req.options.only_for_local_device;
        if (!only_for_local) {
            endpoint = "resume";
            payload_json = "{\"endpoint\":\"resume\"";
            if (!req.session_id.empty()) {
                payload_json.append(",\"session_id\":");
                json::append_json_quoted(payload_json, req.session_id);
            }
            append_json_logging_params_field(payload_json, req.logging_params);
            payload_json.push_back('}');
            intent_id = extract_intent_id(req.logging_params);
        }
    } else if (method_name == "Pause") {
        DecodedPauseResumeRequest req;
        if (payload != nullptr && payload_len > 0 &&
            !decode_pause_or_resume_request(payload, payload_len, req)) {
            PLAYER_REMOTE_LOGW("Outbound Pause: failed to decode payload len=%zu", payload_len);
        }
        only_for_local = req.options.only_for_local_device;
        if (!only_for_local) {
            endpoint = "pause";
            payload_json = "{\"endpoint\":\"pause\"";
            if (!req.origin_feature_identifier.empty()) {
                payload_json.append(",\"pause_origin\":{\"feature_identifier\":");
                json::append_json_quoted(payload_json, req.origin_feature_identifier);
                payload_json.push_back('}');
            }
            append_json_logging_params_field(payload_json, req.logging_params);
            payload_json.push_back('}');
            intent_id = extract_intent_id(req.logging_params);
        }
    } else if (method_name == "Resume") {
        DecodedPauseResumeRequest req;
        if (payload != nullptr && payload_len > 0 &&
            !decode_pause_or_resume_request(payload, payload_len, req)) {
            PLAYER_REMOTE_LOGW("Outbound Resume: failed to decode payload len=%zu", payload_len);
        }
        only_for_local = req.options.only_for_local_device;
        if (!only_for_local) {
            endpoint = "resume";
            payload_json = "{\"endpoint\":\"resume\"";
            if (!req.origin_feature_identifier.empty()) {
                payload_json.append(",\"resume_origin\":{\"feature_identifier\":");
                json::append_json_quoted(payload_json, req.origin_feature_identifier);
                payload_json.push_back('}');
            }
            append_json_logging_params_field(payload_json, req.logging_params);
            payload_json.push_back('}');
            intent_id = extract_intent_id(req.logging_params);
        }
    } else if (method_name == "SeekTo") {
        DecodedSeekToRequest req;
        if (!decode_seek_to_request_full(payload, payload_len, req)) {
            return OutboundForwardOutcome{.intercepted = true, .ok = false};
        }
        only_for_local = req.options.only_for_local_device;
        if (!only_for_local) {
            endpoint = "seek_to";
            payload_json = "{\"endpoint\":\"seek_to\",\"value\":";
            payload_json.append(std::to_string(std::max<int64_t>(0, req.position_ms)));
            if (req.relative.has_value()) {
                payload_json.append(",\"relative\":");
                if (*req.relative == 1) payload_json.append("\"current\"");
                else if (*req.relative == 2) payload_json.append("\"end\"");
                else payload_json.append("\"beginning\"");
            }
            append_json_logging_params_field(payload_json, req.logging_params);
            payload_json.push_back('}');
            intent_id = extract_intent_id(req.logging_params);
        }
    } else if (method_name == "SkipNext") {
        DecodedSkipNextRequest req;
        if (payload != nullptr && payload_len > 0 &&
            !decode_skip_next_request_full(payload, payload_len, req)) {
            PLAYER_REMOTE_LOGW("Outbound SkipNext: failed to decode payload len=%zu", payload_len);
        }
        only_for_local = req.options.only_for_local_device;
        if (!only_for_local) {
            endpoint = "skip_next";
            payload_json = "{\"endpoint\":\"skip_next\"";
            if (!req.target_track.uri.empty() || !req.target_track.uid.empty()) {
                payload_json.append(",\"track\":");
                append_json_track(payload_json, req.target_track);
            }
            append_json_logging_params_field(payload_json, req.logging_params);
            payload_json.push_back('}');
            intent_id = extract_intent_id(req.logging_params);
        }
    } else if (method_name == "SkipPrev") {
        DecodedSkipPrevRequest req;
        if (payload != nullptr && payload_len > 0 &&
            !decode_skip_prev_request_full(payload, payload_len, req)) {
            PLAYER_REMOTE_LOGW("Outbound SkipPrev: failed to decode payload len=%zu", payload_len);
        }
        only_for_local = req.options.only_for_local_device;
        if (!only_for_local) {
            endpoint = "skip_prev";
            payload_json = "{\"endpoint\":\"skip_prev\"";
            if (req.has_allow_seeking) {
                payload_json.append(",\"options\":{\"allow_seeking\":");
                payload_json.append(req.allow_seeking ? "true" : "false");
                payload_json.push_back('}');
            }
            if (!req.target_track.uri.empty() || !req.target_track.uid.empty()) {
                payload_json.append(",\"track\":");
                append_json_track(payload_json, req.target_track);
            }
            append_json_logging_params_field(payload_json, req.logging_params);
            payload_json.push_back('}');
            intent_id = extract_intent_id(req.logging_params);
        }
    } else if (method_name == "SetOptions") {
        DecodedSetOptionsRequest req;
        if (!decode_set_options_request_full(payload, payload_len, req)) {
            return OutboundForwardOutcome{.intercepted = true, .ok = false};
        }
        only_for_local = req.options.only_for_local_device;
        if (!only_for_local) {
            endpoint = "set_options";
            payload_json = "{\"endpoint\":\"set_options\"";
            if (req.overrides.repeating_track.has_value()) {
                payload_json.append(",\"repeating_track\":");
                payload_json.append(*req.overrides.repeating_track ? "true" : "false");
            }
            if (req.overrides.repeating_context.has_value()) {
                payload_json.append(",\"repeating_context\":");
                payload_json.append(*req.overrides.repeating_context ? "true" : "false");
            }
            if (req.overrides.shuffling_context.has_value()) {
                payload_json.append(",\"shuffling_context\":");
                payload_json.append(*req.overrides.shuffling_context ? "true" : "false");
            }
            if (req.overrides.playback_speed.has_value()) {
                payload_json.append(",\"playback_speed\":");
                append_json_double(payload_json, *req.overrides.playback_speed);
            }
            if (!req.overrides.modes.empty()) {
                payload_json.append(",\"modes\":");
                append_json_string_map(payload_json, req.overrides.modes);
            }
            append_json_logging_params_field(payload_json, req.logging_params);
            payload_json.push_back('}');
            intent_id = extract_intent_id(req.logging_params);
        }
    } else if (method_name == "SetShufflingContext" ||
               method_name == "SetRepeatingContext" ||
               method_name == "SetRepeatingTrack") {
        DecodedBoolCommandRequest req;
        if (!decode_bool_command_request(payload, payload_len, req)) {
            return OutboundForwardOutcome{.intercepted = true, .ok = false};
        }
        only_for_local = req.options.only_for_local_device;
        if (!only_for_local) {
            if (method_name == "SetShufflingContext") endpoint = "set_shuffling_context";
            else if (method_name == "SetRepeatingContext") endpoint = "set_repeating_context";
            else endpoint = "set_repeating_track";
            payload_json = "{\"endpoint\":";
            json::append_json_quoted(payload_json, endpoint);
            payload_json.append(",\"value\":");
            payload_json.append(req.value ? "true" : "false");
            append_json_logging_params_field(payload_json, req.logging_params);
            payload_json.push_back('}');
            intent_id = extract_intent_id(req.logging_params);
        }
    } else if (method_name == "AddToQueue") {
        DecodedAddToQueueRequest req;
        if (!decode_add_to_queue_request_full(payload, payload_len, req)) {
            return OutboundForwardOutcome{.intercepted = true, .ok = false};
        }
        only_for_local = req.options.only_for_local_device;
        if (!only_for_local) {
            endpoint = "add_to_queue";
            payload_json = "{\"endpoint\":\"add_to_queue\",\"track\":";
            append_json_track(payload_json, req.track);
            append_json_logging_params_field(payload_json, req.logging_params);
            payload_json.push_back('}');
            intent_id = extract_intent_id(req.logging_params);
        }
    } else if (method_name == "SetQueue") {
        DecodedSetQueueRequest req;
        if (!decode_set_queue_request_full(payload, payload_len, req)) {
            return OutboundForwardOutcome{.intercepted = true, .ok = false};
        }
        only_for_local = req.options.only_for_local_device;
        if (!only_for_local) {
            endpoint = "set_queue";
            payload_json = "{\"endpoint\":\"set_queue\",\"next_tracks\":[";
            for (size_t i = 0; i < req.next_tracks.size(); ++i) {
                if (i > 0) payload_json.push_back(',');
                append_json_track(payload_json, req.next_tracks[i]);
            }
            payload_json.append("],\"prev_tracks\":[");
            for (size_t i = 0; i < req.prev_tracks.size(); ++i) {
                if (i > 0) payload_json.push_back(',');
                append_json_track(payload_json, req.prev_tracks[i]);
            }
            payload_json.push_back(']');
            std::string mirrored_raw_rev;
            uint64_t mirrored_num_rev = 0;
            {
                std::lock_guard<std::mutex> lock(mutex_);
                if (origin_ == PlaybackOrigin::kRemoteMirrored) {
                    mirrored_raw_rev = mirrored_state_.raw_queue_revision;
                    mirrored_num_rev = mirrored_state_.queue_revision;
                }
            }
            std::string rev_to_send;
            if (!mirrored_raw_rev.empty() &&
                (!req.has_queue_revision ||
                 req.queue_revision == 0 ||
                 req.queue_revision == mirrored_num_rev)) {
                rev_to_send = mirrored_raw_rev;
            } else if (req.has_queue_revision) {
                rev_to_send = std::to_string(req.queue_revision);
            }
            if (!rev_to_send.empty()) {
                payload_json.append(",\"queue_revision\":");
                json::append_json_quoted(payload_json, rev_to_send);
            }
            append_json_logging_params_field(payload_json, req.logging_params);
            payload_json.push_back('}');
            intent_id = extract_intent_id(req.logging_params);
        }
    } else if (method_name == "PlayAsNextInQueue") {
        DecodedPlayAsNextRequest req;
        if (!decode_play_as_next_request_full(payload, payload_len, req)) {
            return OutboundForwardOutcome{.intercepted = true, .ok = false};
        }
        only_for_local = req.options.only_for_local_device;
        if (!only_for_local) {
            endpoint = "play_as_next_in_queue";
            payload_json = "{\"endpoint\":\"play_as_next_in_queue\",\"tracks\":[";
            for (size_t i = 0; i < req.tracks.size(); ++i) {
                if (i > 0) payload_json.push_back(',');
                append_json_track(payload_json, req.tracks[i]);
            }
            payload_json.push_back(']');
            append_json_logging_params_field(payload_json, req.logging_params);
            payload_json.push_back('}');
            intent_id = extract_intent_id(req.logging_params);
        }
    } else if (method_name == "UpdateContext") {
        DecodedPreparePlay parsed;
        if (!payload || payload_len == 0 ||
            !decode_context_submessage(payload, payload_len, parsed)) {
            return OutboundForwardOutcome{.intercepted = true, .ok = false};
        }
        endpoint = "update_context";
        payload_json = "{\"endpoint\":\"update_context\",\"context\":";
        append_json_context_object(payload_json, parsed);
        payload_json.push_back('}');
    } else if (method_name == "Signal") {
        DecodedSignalRequest req;
        if (!decode_signal_request_full(payload, payload_len, req)) {
            return OutboundForwardOutcome{.intercepted = true, .ok = false};
        }
        only_for_local = req.options.only_for_local_device;
        if (!only_for_local) {
            endpoint = "signal";
            payload_json = "{\"endpoint\":\"signal\",\"signal_id\":";
            json::append_json_quoted(payload_json, req.signal_id);
            if (!req.parameters.empty()) {
                payload_json.append(",\"parameters\":");
                json::append_json_quoted(payload_json, req.parameters);
            }
            append_json_logging_params_field(payload_json, req.logging_params);
            payload_json.push_back('}');
            intent_id = extract_intent_id(req.logging_params);
        }
    } else if (method_name == "SetSleepTimer") {
        DecodedSleepTimerRequest req;
        if (!decode_set_sleep_timer_request_full(payload, payload_len, req)) {
            return OutboundForwardOutcome{.intercepted = true, .ok = false};
        }
        only_for_local = req.options.only_for_local_device;
        if (!only_for_local) {
            endpoint = "set_sleep_timer";
            payload_json = "{\"endpoint\":\"set_sleep_timer\"";
            switch (req.action) {
                case DecodedSleepTimerRequest::Action::kClear:
                    payload_json.append(",\"clear\":{}");
                    break;
                case DecodedSleepTimerRequest::Action::kDurationSeconds:
                    payload_json.append(",\"duration\":{\"seconds\":");
                    payload_json.append(std::to_string(std::max<int64_t>(0, req.duration_seconds)));
                    payload_json.push_back('}');
                    break;
                case DecodedSleepTimerRequest::Action::kEndOfTrack:
                    payload_json.append(",\"end_of_track\":{}");
                    break;
                case DecodedSleepTimerRequest::Action::kUnset:
                    break;
            }
            append_json_logging_params_field(payload_json, req.logging_params);
            payload_json.push_back('}');
            intent_id = extract_intent_id(req.logging_params);
        }
    } else {
        return OutboundForwardOutcome{.intercepted = false, .ok = false};
    }

    if (only_for_local) {
        PLAYER_REMOTE_LOGI(
            "Command %s marked only_for_local_device=true; executing locally",
            method_name.c_str());
        return OutboundForwardOutcome{.intercepted = false, .ok = false};
    }

    const std::string target_device_id = delegate->active_remote_device_id();
    PLAYER_REMOTE_LOGI(
        "Forwarding %s -> endpoint=%s target_device=%s intent_id=%s",
        method_name.c_str(),
        endpoint.c_str(),
        target_device_id.c_str(),
        intent_id.c_str());

    const bool ok = delegate->forward_player_command(endpoint, payload_json, intent_id);
    if (!ok) {
        PLAYER_REMOTE_LOGE(
            "Remote forward FAILED endpoint=%s target_device=%s",
            endpoint.c_str(),
            target_device_id.c_str());
        ErrorCallback err_cb;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            last_error_ = "REMOTE_COMMAND_FAILED";
            err_cb = error_callback_;
        }
        if (err_cb) {
            err_cb(
                "REMOTE_COMMAND_FAILED",
                "Failed to forward " + endpoint + " to remote Connect device");
        }
    }
    return OutboundForwardOutcome{.intercepted = true, .ok = ok};
}

bool ContextPlayerImpl::handle_command(
        const std::string& method,
        const uint8_t* payload,
        size_t payload_len) {
    std::string method_name = method;
    const auto slash = method_name.rfind('/');
    if (slash != std::string::npos) {
        method_name = method_name.substr(slash + 1);
    } else {
        const auto dot = method_name.rfind('.');
        if (dot != std::string::npos) {
            method_name = method_name.substr(dot + 1);
        }
    }

    // Outbound Connect routing: when a remote device is active and CommandOptions does not
    // force `only_for_local_device = true`, forward directly to the active remote device.
    const OutboundForwardOutcome remote_outcome =
        try_forward_remote_command(method_name, payload, payload_len);
    if (remote_outcome.intercepted) {
        return remote_outcome.ok;
    }

    if (method_name == "Play") return play(payload, payload_len);
    if (method_name == "Pause") return pause();
    if (method_name == "Resume") return resume();
    if (method_name == "SeekTo") return seek_to(payload, payload_len);
    if (method_name == "SkipNext") return skip_next(payload, payload_len);
    if (method_name == "SkipPrev") return skip_prev(payload, payload_len);
    if (method_name == "SetOptions") return set_options(payload, payload_len);
    if (method_name == "SetShufflingContext") return set_shuffling_context(payload, payload_len);
    if (method_name == "SetRepeatingContext") return set_repeating_context(payload, payload_len);
    if (method_name == "SetRepeatingTrack") return set_repeating_track(payload, payload_len);
    if (method_name == "AddToQueue") return add_to_queue(payload, payload_len);
    if (method_name == "SetQueue") return set_queue(payload, payload_len);
    if (method_name == "PlayAsNextInQueue") return play_as_next_in_queue(payload, payload_len);
    if (method_name == "Stop") return stop();
    if (method_name == "PreparePlay") return prepare_play(payload, payload_len);
    if (method_name == "PlayPrepared") return play_prepared(payload, payload_len);
    if (method_name == "UpdateContext") return update_context(payload, payload_len);
    if (method_name == "UpdateTrack") return update_track(payload, payload_len);
    if (method_name == "UpdatePage") return update_page(payload, payload_len);
    if (method_name == "UpdateViewUri") return update_view_uri(payload, payload_len);
    if (method_name == "Signal") return signal(payload, payload_len);
    if (method_name == "SetSleepTimer") return set_sleep_timer(payload, payload_len);
    if (method_name == "DeleteSession") return delete_session(payload, payload_len);
    if (method_name == "GetState") {
        StateChangedCallback sc_cb;
        std::vector<uint8_t> sc_bytes;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            emit_state_locked();
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
        }
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        return true;
    }
    if (method_name == "GetQueue") {
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> qc_bytes;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            emit_queue_locked();
            qc_cb = queue_changed_callback_;
            qc_bytes = cached_queue_bytes_;
        }
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        return true;
    }
    if (method_name == "GetError") return true;

    LOGW("ContextPlayer: unhandled command method=%s", method.c_str());
    {
        std::lock_guard<std::mutex> lock(mutex_);
        last_error_ = "UNHANDLED_METHOD";
    }
    return false;
}

bool ContextPlayerImpl::play(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) {
        bool paused = false;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            paused = is_phase_paused(playback_phase_);
        }
        if (paused) return resume();
        return false;
    }

    DecodedPreparePlay parsed;
    if (!parse_prepare_play_request(payload, len, parsed)) {
        LOGE("ContextPlayerImpl.play: failed to parse PlayRequest wire format");
        std::lock_guard<std::mutex> lock(mutex_);
        last_error_ = "INVALID_PLAY_REQUEST";
        return false;
    }

    const int64_t seek_to_ms = parsed.seek_to_ms.has_value()
                                   ? std::max<int64_t>(0, *parsed.seek_to_ms)
                                   : 0;
    const bool start_paused = parsed.initially_paused.value_or(false);

    std::shared_ptr<rendering::TrackPlayer> tp;
    context_view::Entry track_to_play;
    bool should_stop_player = false;
    std::optional<double> updated_speed;
    uint64_t sync_token = 0;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;
    ConnectDispatchBundle connect_bundle;
    std::vector<PendingMetadataRequest> pending_metadata;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        transition_to_local_locked();

        context_uri_ = parsed.context_uri;
        context_url_ = parsed.context_url;
        context_metadata_ = parsed.context_metadata;
        play_origin_ = parsed.play_origin;
        session_id_ = !parsed.session_id.empty() ? parsed.session_id : generate_track_uid();

        if (parsed.overrides.shuffling_context.has_value()) {
            shuffling_ = *parsed.overrides.shuffling_context;
        }
        apply_repeat_overrides_locked(
            parsed.overrides.repeating_context,
            parsed.overrides.repeating_track);
        if (parsed.overrides.playback_speed.has_value() && *parsed.overrides.playback_speed > 0.0) {
            playback_speed_ = *parsed.overrides.playback_speed;
            updated_speed = playback_speed_;
        } else if (parsed.play_options.playback_speed.has_value() &&
                   *parsed.play_options.playback_speed > 0.0) {
            playback_speed_ = *parsed.play_options.playback_speed;
            updated_speed = playback_speed_;
        }
        for (const auto& [mk, mv] : parsed.overrides.modes) {
            modes_[mk] = mv;
        }

        const int32_t initial_index = resolve_initial_track_index(
            parsed.tracks,
            parsed.skip_to.track_uid,
            parsed.skip_to.track_uri,
            parsed.skip_to.page_index,
            parsed.skip_to.track_index,
            parsed.page_track_offsets);

        if (!shuffling_) {
            context_processor_.set_shuffling(false);
        }
        context_processor_.set_context(
            parsed.context_uri,
            parsed.page_url,
            parsed.tracks,
            parsed.next_page_url,
            initial_index);
        context_processor_.set_shuffling(shuffling_);
        bump_queue_revision_locked();

        if (const auto resolved_cur = context_processor_.get_current_track();
            resolved_cur.has_value() && !resolved_cur->uri.empty()) {
            begin_track_transition_locked(
                *resolved_cur,
                start_paused ? SessionPlaybackPhase::Paused
                             : SessionPlaybackPhase::BufferingPlay);
            position_ms_ = seek_to_ms;
            decorate_local_queue_locked(pending_metadata);
            LOGI("ContextPlayerImpl.play: context_uri=%s playing uri=%s uid=%s",
                 context_uri_.c_str(),
                 current_track_->uri.c_str(),
                 current_track_->uid.c_str());
            track_to_play = *current_track_;
            tp = track_player_;
            if (tp) {
                sync_token = ++next_player_sync_token_;
                pending_player_sync_token_ = sync_token;
            }
        } else {
            current_track_.reset();
            explicit_prev_tracks_.reset();
            playback_id_.clear();
            playback_phase_ = SessionPlaybackPhase::Idle;
            position_ms_ = 0;
            duration_ms_ = 0;
            decorate_local_queue_locked(pending_metadata);
            tp = track_player_;
            should_stop_player = true;
            if (tp) {
                sync_token = ++next_player_sync_token_;
                pending_player_sync_token_ = sync_token;
            }
        }

        emit_state_locked(false);
        emit_queue_locked();
        sc_cb = state_changed_callback_;
        qc_cb = queue_changed_callback_;
        sc_bytes = cached_state_bytes_;
        qc_bytes = cached_queue_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }

    dispatch_metadata_requests(pending_metadata);

    if (tp && should_stop_player) {
        tp->stop(rendering::StopReason::ContextEnded);
        clear_pending_player_sync(sync_token);
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
    if (tp && !should_stop_player && !track_to_play.uri.empty()) {
        if (updated_speed.has_value()) {
            tp->setPlaybackSpeed(*updated_speed);
        }
        tp->start(track_to_play, rendering::StartReason::PlayCommand, seek_to_ms, start_paused);
        clear_pending_player_sync(sync_token);
    }
    return true;
}

bool ContextPlayerImpl::pause() {
    std::shared_ptr<rendering::TrackPlayer> tp;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        transition_to_local_locked();
        tp = track_player_;
    }
    if (tp) {
        tp->pause();
    }

    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    ConnectDispatchBundle connect_bundle;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        LOGI("ContextPlayer RoutingTrackPlayer: PauseOrAwaitPause active");
        playback_phase_ = SessionPlaybackPhase::Paused;
        if (track_player_ && pending_player_sync_token_ == 0) {
            const int64_t pos = track_player_->getPosition();
            if (pos >= 0) {
                position_ms_ = pos;
            }
        }
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
    return true;
}

bool ContextPlayerImpl::resume() {
    std::shared_ptr<rendering::TrackPlayer> tp;
    std::optional<context_view::Entry> fallback_track;
    int64_t resume_pos = 0;
    uint64_t sync_token = 0;
    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    ConnectDispatchBundle connect_bundle;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        transition_to_local_locked();
        tp = track_player_;
        fallback_track = current_track_;
        if (position_ms_ < 0) {
            position_ms_ = 0;
        }
        resume_pos = position_ms_;
        LOGI("ContextPlayer RoutingTrackPlayer: PauseOrAwaitPause not active");
        playback_phase_ = (playback_phase_ == SessionPlaybackPhase::BufferingPaused)
            ? SessionPlaybackPhase::BufferingPlay
            : SessionPlaybackPhase::Playing;
        if (tp) {
            sync_token = ++next_player_sync_token_;
            pending_player_sync_token_ = sync_token;
        }
        emit_state_locked(false);
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }

    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
    if (tp) {
        if (!tp->getCurrentTrack().has_value() && fallback_track.has_value()) {
            tp->start(*fallback_track, rendering::StartReason::PlayCommand, resume_pos, false);
        } else {
            tp->resume();
        }
        clear_pending_player_sync(sync_token);
    }
    return true;
}

bool ContextPlayerImpl::seek_to(int64_t position_ms) {
    if (position_ms < 0) {
        position_ms = 0;
    }

    std::shared_ptr<rendering::TrackPlayer> tp;
    uint64_t sync_token = 0;
    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    ConnectDispatchBundle connect_bundle;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        transition_to_local_locked();
        tp = track_player_;
        LOGI("ContextPlayer RoutingTrackPlayer: Seeking to %lld ms", static_cast<long long>(position_ms));
        position_ms_ = position_ms;
        if (tp) {
            sync_token = ++next_player_sync_token_;
            pending_player_sync_token_ = sync_token;
        }
        emit_state_locked(false);
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
    if (tp) {
        tp->seek(position_ms, rendering::SeekOrigin::User);
        clear_pending_player_sync(sync_token);
    }
    return true;
}

bool ContextPlayerImpl::seek_to(const uint8_t* payload, size_t len) {
    int64_t pos = 0;
    if (payload && len > 0) {
        DecodedSeekToRequest req;
        if (decode_seek_to_request_full(payload, len, req) && req.has_position) {
            if (req.relative.has_value() && *req.relative == 1) {
                std::lock_guard<std::mutex> lock(mutex_);
                const int64_t base =
                    (track_player_ && pending_player_sync_token_ == 0)
                        ? std::max<int64_t>(0, track_player_->getPosition())
                        : position_ms_;
                pos = std::max<int64_t>(0, base + req.position_ms);
            } else if (req.relative.has_value() && *req.relative == 2) {
                std::lock_guard<std::mutex> lock(mutex_);
                pos = std::max<int64_t>(0, duration_ms_ + req.position_ms);
            } else {
                pos = req.position_ms;
            }
        }
    }
    return seek_to(pos);
}

bool ContextPlayerImpl::skip_next_impl(
        bool override_restrictions,
        const context_view::Entry& target_track) {
    std::shared_ptr<rendering::TrackPlayer> tp;
    context_view::Entry next_track;
    bool should_play = false;
    bool should_stop_context = false;
    uint64_t sync_token = 0;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    ErrorCallback err_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;
    ConnectDispatchBundle connect_bundle;
    std::vector<PendingMetadataRequest> pending_metadata;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        transition_to_local_locked();
        if (!override_restrictions && !restrictions_engine_.get_custom_disallow_skipping_next().empty()) {
            LOGW("ContextPlayer: SkipNext restricted by custom policy");
            last_error_ = "SKIP_TO_NEXT_RESTRICTED";
            err_cb = error_callback_;
        } else {
            LOGI("ContextPlayer RoutingTrackPlayer: pause/stop player while advancing");
            tp = track_player_;

            if (current_track_.has_value()) {
                LOGI("advanced_past_track: %s", current_track_->uri.c_str());
            }

            bool handled_target = false;
            if (!target_track.uri.empty() || !target_track.uid.empty()) {
                bool found_in_user_queue = false;
                auto it = user_queue_.end();

                if (!target_track.uid.empty()) {
                    if (target_track.provider != "context") {
                        it = std::find_if(user_queue_.begin(), user_queue_.end(), [&](const context_view::Entry& e) {
                            return e.uid == target_track.uid;
                        });
                        found_in_user_queue = (it != user_queue_.end());
                    }
                } else if (!target_track.uri.empty() &&
                           (target_track.provider == "queue" || target_track.provider.empty())) {
                    it = std::find_if(user_queue_.begin(), user_queue_.end(), [&](const context_view::Entry& e) {
                        return e.uri == target_track.uri;
                    });
                    found_in_user_queue = (it != user_queue_.end());
                }

                if (found_in_user_queue) {
                    const context_view::Entry selected = *it;
                    user_queue_.erase(user_queue_.begin(), it + 1);
                    bump_queue_revision_locked();
                    begin_track_transition_locked(selected, SessionPlaybackPhase::BufferingPlay);
                    decorate_local_queue_locked(pending_metadata);
                    next_track = *current_track_;
                    should_play = true;
                    handled_target = true;
                } else {
                    bool found = false;
                    if (!target_track.uid.empty()) {
                        found = context_processor_.skip_to_uid(target_track.uid);
                    }
                    if (!found && !target_track.uri.empty() && target_track.provider != "queue") {
                        found = context_processor_.skip_to_uri(target_track.uri);
                    }
                    if (found) {
                        auto track = context_processor_.get_current_track();
                        if (track.has_value()) {
                            bump_queue_revision_locked();
                            begin_track_transition_locked(*track, SessionPlaybackPhase::BufferingPlay);
                            decorate_local_queue_locked(pending_metadata);
                            next_track = *current_track_;
                            should_play = true;
                            handled_target = true;
                        }
                    }
                }
            }

            if (!handled_target) {
                if (!user_queue_.empty()) {
                    const context_view::Entry queued_front = user_queue_.front();
                    user_queue_.erase(user_queue_.begin());
                    bump_queue_revision_locked();
                    begin_track_transition_locked(queued_front, SessionPlaybackPhase::BufferingPlay);
                    decorate_local_queue_locked(pending_metadata);
                    next_track = *current_track_;
                    should_play = true;
                    LOGI("preroll_track_advance to user queue track: %s", next_track.uri.c_str());
                } else {
                    bool advanced = context_processor_.skip_next();
                    if (!advanced && repeat_mode_ != SessionRepeatMode::Off) {
                        advanced = context_processor_.skip_to_index(0);
                    }
                    if (advanced) {
                        auto track = context_processor_.get_current_track();
                        if (track.has_value()) {
                            bump_queue_revision_locked();
                            begin_track_transition_locked(*track, SessionPlaybackPhase::BufferingPlay);
                            decorate_local_queue_locked(pending_metadata);
                            next_track = *current_track_;
                            should_play = true;
                            LOGI("preroll_track_advance to context track: %s", next_track.uri.c_str());
                        }
                    } else {
                        if (!context_processor_.get_current_track().has_value()) {
                            current_track_.reset();
                            playback_id_.clear();
                            duration_ms_ = 0;
                        }
                        bump_queue_revision_locked();
                        playback_phase_ = SessionPlaybackPhase::Idle;
                        position_ms_ = 0;
                        should_stop_context = true;
                    }
                }
            }

            if (tp && (should_play || should_stop_context)) {
                sync_token = ++next_player_sync_token_;
                pending_player_sync_token_ = sync_token;
            }
            emit_state_locked(false);
            emit_queue_locked();
            sc_cb = state_changed_callback_;
            qc_cb = queue_changed_callback_;
            sc_bytes = cached_state_bytes_;
            qc_bytes = cached_queue_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
    }

    dispatch_metadata_requests(pending_metadata);

    if (err_cb) {
        err_cb("SKIP_TO_NEXT_RESTRICTED", "Skipping to next track is restricted");
        return false;
    }

    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
    if (tp) {
        if (should_play) {
            tp->start(next_track, rendering::StartReason::SkipNext, 0, false);
        } else if (should_stop_context) {
            tp->stop(rendering::StopReason::ContextEnded);
        }
        clear_pending_player_sync(sync_token);
    }
    return should_play;
}

bool ContextPlayerImpl::skip_next(const uint8_t* payload, size_t len) {
    DecodedSkipNextRequest req;
    if (payload && len > 0) {
        LOGI("ContextPlayerImpl.skipNext: payload_len=%zu", len);
        if (!decode_skip_next_request_full(payload, len, req)) {
            LOGW("ContextPlayerImpl.skipNext: failed to decode payload len=%zu", len);
        }
    }
    return skip_next_impl(req.options.override_restrictions, req.target_track);
}

bool ContextPlayerImpl::skip_prev_impl(
        bool override_restrictions,
        bool allow_seeking,
        const context_view::Entry& target_track) {
    std::shared_ptr<rendering::TrackPlayer> tp;
    context_view::Entry prev_track;
    bool should_play = false;
    bool should_seek_zero = false;
    uint64_t sync_token = 0;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    ErrorCallback err_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;
    ConnectDispatchBundle connect_bundle;
    std::vector<PendingMetadataRequest> pending_metadata;

    bool restart_track_only = false;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        transition_to_local_locked();
        if (!override_restrictions && !restrictions_engine_.get_custom_disallow_skipping_prev().empty()) {
            LOGW("ContextPlayer: SkipPrev restricted by custom policy");
            last_error_ = "SKIP_TO_PREV_RESTRICTED";
            err_cb = error_callback_;
        } else {
            tp = track_player_;
            const bool has_explicit_target =
                !target_track.uid.empty() || !target_track.uri.empty();
            const int64_t current_pos =
                (tp && pending_player_sync_token_ == 0) ? tp->getPosition() : position_ms_;
            if (!has_explicit_target && allow_seeking && current_track_.has_value() && current_pos > 3000) {
                LOGI("ContextPlayer RoutingTrackPlayer: Seeking to 0 ms (skip_prev restart pos=%lld)",
                     static_cast<long long>(current_pos));
                should_seek_zero = true;
                restart_track_only = true;
            } else {
                bool advanced = false;
                if (!target_track.uid.empty()) {
                    advanced = context_processor_.skip_to_uid(target_track.uid);
                }
                if (!advanced && !target_track.uri.empty()) {
                    advanced = context_processor_.skip_to_uri(target_track.uri);
                }
                if (!advanced && !has_explicit_target) {
                    advanced = context_processor_.skip_prev();
                }

                if (advanced) {
                    auto track = context_processor_.get_current_track();
                    if (track.has_value()) {
                        bump_queue_revision_locked();
                        begin_track_transition_locked(*track, SessionPlaybackPhase::BufferingPlay);
                        decorate_local_queue_locked(pending_metadata);
                        prev_track = *current_track_;
                        should_play = true;
                        LOGI("did_advance_to_track: %s", prev_track.uri.c_str());
                    }
                } else if (repeat_mode_ != SessionRepeatMode::Off && current_track_.has_value()) {
                    should_seek_zero = true;
                }
            }

            if (should_seek_zero) {
                position_ms_ = 0;
            }
            if (tp && (should_seek_zero || should_play)) {
                sync_token = ++next_player_sync_token_;
                pending_player_sync_token_ = sync_token;
            }
            emit_state_locked(false);
            if (!restart_track_only) {
                emit_queue_locked();
                qc_cb = queue_changed_callback_;
                qc_bytes = cached_queue_bytes_;
            }
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
    }

    dispatch_metadata_requests(pending_metadata);

    if (err_cb) {
        err_cb("SKIP_TO_PREV_RESTRICTED", "Skipping to previous track is restricted");
        return false;
    }

    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
    if (tp) {
        if (should_seek_zero) {
            tp->seek(0, rendering::SeekOrigin::User);
            clear_pending_player_sync(sync_token);
        } else if (should_play) {
            tp->start(prev_track, rendering::StartReason::SkipPrev, 0, false);
            clear_pending_player_sync(sync_token);
        }
    }
    return should_play || should_seek_zero;
}

bool ContextPlayerImpl::skip_prev(const uint8_t* payload, size_t len) {
    DecodedSkipPrevRequest req;
    if (payload && len > 0) {
        LOGI("ContextPlayerImpl.skipPrev: payload_len=%zu", len);
        if (!decode_skip_prev_request_full(payload, len, req)) {
            LOGW("ContextPlayerImpl.skipPrev: failed to decode payload len=%zu", len);
        }
    }
    return skip_prev_impl(
        req.options.override_restrictions,
        req.allow_seeking,
        req.target_track);
}

void ContextPlayerImpl::advance_to_next_track(rendering::AdvanceReason reason) {
    std::shared_ptr<rendering::TrackPlayer> tp;
    context_view::Entry next_track;
    bool should_play = false;
    bool should_repeat_current = false;
    bool should_stop_context = false;
    bool sleep_timer_end_of_track_fired = false;
    uint64_t sync_token = 0;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;
    ConnectDispatchBundle connect_bundle;
    std::vector<PendingMetadataRequest> pending_metadata;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (origin_ == PlaybackOrigin::kRemoteMirrored) {
            return;
        }
        tp = track_player_;
        LOGI("drain_on_end_of_stream: end-of-stream, track_finished_playing");
        LOGI("ContextPlayerImpl.advanceToNextTrack (reason=%d)", static_cast<int>(reason));

        if (reason == rendering::AdvanceReason::EndOfTrack &&
            sleep_timer_.mode == SleepTimerMode::kEndOfTrack) {
            sleep_timer_ = SleepTimerState{};
            playback_phase_ = SessionPlaybackPhase::Paused;
            position_ms_ = 0;
            sleep_timer_end_of_track_fired = true;
            if (tp) {
                sync_token = ++next_player_sync_token_;
                pending_player_sync_token_ = sync_token;
            }
            emit_state_locked(false);
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        } else if (repeat_mode_ == SessionRepeatMode::Track &&
                   reason == rendering::AdvanceReason::EndOfTrack &&
                   current_track_.has_value()) {
            position_ms_ = 0;
            playback_phase_ = SessionPlaybackPhase::Playing;
            should_repeat_current = true;
            if (tp) {
                sync_token = ++next_player_sync_token_;
                pending_player_sync_token_ = sync_token;
            }
            emit_state_locked(false);
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        } else {
            if (current_track_.has_value()) {
                LOGI("advanced_past_track: %s", current_track_->uri.c_str());
            }

            if (!user_queue_.empty()) {
                const context_view::Entry queued_front = user_queue_.front();
                user_queue_.erase(user_queue_.begin());
                bump_queue_revision_locked();
                begin_track_transition_locked(queued_front, SessionPlaybackPhase::BufferingPlay);
                decorate_local_queue_locked(pending_metadata);
                next_track = *current_track_;
                should_play = true;
                LOGI("preroll_track_advance to user queue track: %s", next_track.uri.c_str());
            } else {
                bool advanced = context_processor_.skip_next();
                if (!advanced && repeat_mode_ != SessionRepeatMode::Off) {
                    advanced = context_processor_.skip_to_index(0);
                }
                if (advanced) {
                    auto track = context_processor_.get_current_track();
                    if (track.has_value()) {
                        bump_queue_revision_locked();
                        begin_track_transition_locked(*track, SessionPlaybackPhase::BufferingPlay);
                        decorate_local_queue_locked(pending_metadata);
                        next_track = *current_track_;
                        should_play = true;
                        LOGI("preroll_track_advance to context track: %s", next_track.uri.c_str());
                    }
                } else {
                    if (!context_processor_.get_current_track().has_value()) {
                        current_track_.reset();
                        playback_id_.clear();
                        duration_ms_ = 0;
                    }
                    bump_queue_revision_locked();
                    playback_phase_ = SessionPlaybackPhase::Idle;
                    position_ms_ = 0;
                    should_stop_context = true;
                }
            }

            if (tp && (should_play || should_stop_context)) {
                sync_token = ++next_player_sync_token_;
                pending_player_sync_token_ = sync_token;
            }
            emit_state_locked(false);
            emit_queue_locked();
            sc_cb = state_changed_callback_;
            qc_cb = queue_changed_callback_;
            sc_bytes = cached_state_bytes_;
            qc_bytes = cached_queue_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
    }

    dispatch_metadata_requests(pending_metadata);

    if (sleep_timer_end_of_track_fired) {
        PLAYER_REMOTE_LOGI("End-of-track sleep timer triggered -> pausing playback");
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        if (tp) {
            tp->pause();
            clear_pending_player_sync(sync_token);
        }
        return;
    }

    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
    if (tp && should_repeat_current) {
        tp->seek(0, rendering::SeekOrigin::Internal);
        tp->resume();
        clear_pending_player_sync(sync_token);
    } else if (tp && !should_repeat_current) {
        if (should_play) {
            tp->advance(next_track, 0);
        } else if (should_stop_context) {
            tp->stop(rendering::StopReason::ContextEnded);
        }
        clear_pending_player_sync(sync_token);
    }
}

bool ContextPlayerImpl::set_options(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    DecodedSetOptionsRequest req;
    if (decode_set_options_request_full(payload, len, req)) {
        std::shared_ptr<rendering::TrackPlayer> tp;
        std::optional<double> updated_speed;
        StateChangedCallback sc_cb;
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> sc_bytes, qc_bytes;
        ConnectDispatchBundle connect_bundle;
        std::vector<PendingMetadataRequest> pending_metadata;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            transition_to_local_locked();
            if (req.overrides.shuffling_context.has_value()) {
                const bool shuffle_changed = (shuffling_ != *req.overrides.shuffling_context);
                shuffling_ = *req.overrides.shuffling_context;
                context_processor_.set_shuffling(shuffling_);
                if (shuffle_changed) {
                    bump_queue_revision_locked();
                    decorate_local_queue_locked(pending_metadata);
                }
            }
            apply_repeat_overrides_locked(
                req.overrides.repeating_context,
                req.overrides.repeating_track);
            if (req.overrides.playback_speed.has_value() && *req.overrides.playback_speed > 0.0) {
                playback_speed_ = *req.overrides.playback_speed;
                updated_speed = playback_speed_;
                tp = track_player_;
            }
            for (const auto& [mk, mv] : req.overrides.modes) {
                modes_[mk] = mv;
            }
            emit_state_locked();
            emit_queue_locked();
            sc_cb = state_changed_callback_;
            qc_cb = queue_changed_callback_;
            sc_bytes = cached_state_bytes_;
            qc_bytes = cached_queue_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
        dispatch_metadata_requests(pending_metadata);
        if (tp && updated_speed.has_value()) {
            tp->setPlaybackSpeed(*updated_speed);
        }
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    return false;
}

bool ContextPlayerImpl::set_shuffling_context(const uint8_t* payload, size_t len) {
    DecodedBoolCommandRequest req;
    if (decode_bool_command_request(payload, len, req)) {
        set_shuffling_context(req.value);
        return true;
    }
    return false;
}

void ContextPlayerImpl::set_shuffling_context(bool shuffling) {
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;
    ConnectDispatchBundle connect_bundle;
    std::vector<PendingMetadataRequest> pending_metadata;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        transition_to_local_locked();
        const bool shuffle_changed = (shuffling_ != shuffling);
        shuffling_ = shuffling;
        context_processor_.set_shuffling(shuffling);
        if (shuffle_changed) {
            bump_queue_revision_locked();
            decorate_local_queue_locked(pending_metadata);
        }
        emit_state_locked();
        emit_queue_locked();
        sc_cb = state_changed_callback_;
        qc_cb = queue_changed_callback_;
        sc_bytes = cached_state_bytes_;
        qc_bytes = cached_queue_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }
    dispatch_metadata_requests(pending_metadata);
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
}

bool ContextPlayerImpl::set_repeating_context(const uint8_t* payload, size_t len) {
    DecodedBoolCommandRequest req;
    if (decode_bool_command_request(payload, len, req)) {
        set_repeating_context(req.value);
        return true;
    }
    return false;
}

void ContextPlayerImpl::set_repeating_context(bool repeating) {
    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    ConnectDispatchBundle connect_bundle;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        transition_to_local_locked();
        apply_repeat_overrides_locked(repeating, std::nullopt);
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
}

bool ContextPlayerImpl::set_repeating_track(const uint8_t* payload, size_t len) {
    DecodedBoolCommandRequest req;
    if (decode_bool_command_request(payload, len, req)) {
        set_repeating_track(req.value);
        return true;
    }
    return false;
}

void ContextPlayerImpl::set_repeating_track(bool repeating) {
    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    ConnectDispatchBundle connect_bundle;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        transition_to_local_locked();
        apply_repeat_overrides_locked(std::nullopt, repeating);
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
}

bool ContextPlayerImpl::add_to_queue(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    DecodedAddToQueueRequest req;
    if (decode_add_to_queue_request_full(payload, len, req)) {
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> qc_bytes;
        StateChangedCallback sc_cb;
        std::vector<uint8_t> sc_bytes;
        ConnectDispatchBundle connect_bundle;
        std::vector<PendingMetadataRequest> pending_metadata;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            transition_to_local_locked();
            req.track.uid = generate_track_uid();
            req.track.metadata["is_queued"] = "true";
            req.track.provider = "queue";
            req.track.metadata["provider"] = "queue";
            user_queue_.push_back(std::move(req.track));
            bump_queue_revision_locked();
            decorate_local_queue_locked(pending_metadata);
            emit_queue_locked();
            emit_state_locked();
            qc_cb = queue_changed_callback_;
            qc_bytes = cached_queue_bytes_;
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
        dispatch_metadata_requests(pending_metadata);
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    return false;
}

bool ContextPlayerImpl::set_queue(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    DecodedSetQueueRequest req;
    if (decode_set_queue_request_full(payload, len, req)) {
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> qc_bytes;
        StateChangedCallback sc_cb;
        std::vector<uint8_t> sc_bytes;
        ConnectDispatchBundle connect_bundle;
        std::vector<PendingMetadataRequest> pending_metadata;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            transition_to_local_locked();
            user_queue_.clear();
            std::vector<context_view::Entry> remaining_context;
            for (auto& t : req.next_tracks) {
                if (t.uid.empty()) {
                    t.uid = generate_track_uid();
                }
                auto it = t.metadata.find("is_queued");
                if ((it != t.metadata.end() && (it->second == "true" || it->second == "True")) ||
                    t.provider == "queue") {
                    t.provider = "queue";
                    t.metadata["is_queued"] = "true";
                    t.metadata["provider"] = "queue";
                    user_queue_.push_back(std::move(t));
                } else {
                    t.provider = "context";
                    t.metadata["is_queued"] = "false";
                    t.metadata["provider"] = "context";
                    remaining_context.push_back(std::move(t));
                }
            }
            context_processor_.set_next_tracks_slice(remaining_context);
            if (req.has_prev_tracks) {
                explicit_prev_tracks_ = std::move(req.prev_tracks);
            }
            bump_queue_revision_locked();
            decorate_local_queue_locked(pending_metadata);
            emit_queue_locked();
            emit_state_locked();
            qc_cb = queue_changed_callback_;
            qc_bytes = cached_queue_bytes_;
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
        dispatch_metadata_requests(pending_metadata);
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    return false;
}

bool ContextPlayerImpl::play_as_next_in_queue(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    DecodedPlayAsNextRequest req;
    if (decode_play_as_next_request_full(payload, len, req)) {
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> qc_bytes;
        StateChangedCallback sc_cb;
        std::vector<uint8_t> sc_bytes;
        ConnectDispatchBundle connect_bundle;
        std::vector<PendingMetadataRequest> pending_metadata;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            transition_to_local_locked();
            for (auto& t : req.tracks) {
                t.uid = generate_track_uid();
                t.metadata["is_queued"] = "true";
                t.provider = "queue";
                t.metadata["provider"] = "queue";
            }
            user_queue_.insert(user_queue_.begin(), req.tracks.begin(), req.tracks.end());
            bump_queue_revision_locked();
            decorate_local_queue_locked(pending_metadata);
            emit_queue_locked();
            emit_state_locked();
            qc_cb = queue_changed_callback_;
            qc_bytes = cached_queue_bytes_;
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
        dispatch_metadata_requests(pending_metadata);
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    return false;
}

bool ContextPlayerImpl::stop() {
    std::shared_ptr<rendering::TrackPlayer> tp;
    uint64_t sync_token = 0;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes;
    std::vector<uint8_t> qc_bytes;
    ConnectDispatchBundle connect_bundle;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        transition_to_local_locked();
        tp = track_player_;
        playback_phase_ = SessionPlaybackPhase::Idle;
        position_ms_ = 0;
        duration_ms_ = 0;
        playback_id_.clear();
        current_track_.reset();
        user_queue_.clear();
        explicit_prev_tracks_.reset();
        context_processor_.clear();
        context_processor_.set_shuffling(shuffling_);
        if (tp) {
            sync_token = ++next_player_sync_token_;
            pending_player_sync_token_ = sync_token;
        } else {
            pending_player_sync_token_ = 0;
        }
        context_uri_.clear();
        context_url_.clear();
        context_metadata_.clear();
        page_metadata_.clear();
        session_id_.clear();
        session_command_id_.clear();
        signals_.clear();
        sleep_timer_ = SleepTimerState{};
        bump_queue_revision_locked();
        emit_state_locked(false);
        emit_queue_locked();
        sc_cb = state_changed_callback_;
        qc_cb = queue_changed_callback_;
        sc_bytes = cached_state_bytes_;
        qc_bytes = cached_queue_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }
    {
        std::lock_guard<std::mutex> slock(sleep_timer_mutex_);
        ++sleep_timer_epoch_;
    }
    sleep_timer_cv_.notify_all();
    if (tp) {
        tp->stop(rendering::StopReason::ExplicitStop);
        clear_pending_player_sync(sync_token);
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
    return true;
}

bool ContextPlayerImpl::prepare_play(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    DecodedPreparePlay parsed;
    if (!parse_prepare_play_request(payload, len, parsed)) {
        LOGE("ContextPlayerImpl.preparePlay: failed to parse wire format");
        {
            std::lock_guard<std::mutex> lock(mutex_);
            last_error_ = "INVALID_PREPARE_PLAY_REQUEST";
        }
        return false;
    }

    const int64_t seek_to_ms = parsed.seek_to_ms.has_value()
                                   ? std::max<int64_t>(0, *parsed.seek_to_ms)
                                   : 0;

    std::shared_ptr<rendering::TrackPlayer> tp;
    std::optional<context_view::Entry> track_to_prepare;
    bool should_stop_player = false;
    uint64_t sync_token = 0;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;
    ConnectDispatchBundle connect_bundle;
    std::vector<PendingMetadataRequest> pending_metadata;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        transition_to_local_locked();
        tp = track_player_;
        context_uri_ = parsed.context_uri;
        context_url_ = parsed.context_url;
        context_metadata_ = parsed.context_metadata;
        play_origin_ = parsed.play_origin;
        session_id_ = !parsed.session_id.empty() ? parsed.session_id : generate_track_uid();

        if (parsed.overrides.shuffling_context.has_value()) {
            shuffling_ = *parsed.overrides.shuffling_context;
        }
        apply_repeat_overrides_locked(
            parsed.overrides.repeating_context,
            parsed.overrides.repeating_track);

        const int32_t initial_index = resolve_initial_track_index(
            parsed.tracks,
            parsed.skip_to.track_uid,
            parsed.skip_to.track_uri,
            parsed.skip_to.page_index,
            parsed.skip_to.track_index,
            parsed.page_track_offsets);

        if (!shuffling_) {
            context_processor_.set_shuffling(false);
        }
        context_processor_.set_context(
            parsed.context_uri,
            parsed.page_url,
            parsed.tracks,
            parsed.next_page_url,
            initial_index);
        context_processor_.set_shuffling(shuffling_);
        bump_queue_revision_locked();

        if (const auto resolved_cur = context_processor_.get_current_track();
            resolved_cur.has_value() && !resolved_cur->uri.empty()) {
            begin_track_transition_locked(*resolved_cur, SessionPlaybackPhase::Paused);
            position_ms_ = seek_to_ms;
            decorate_local_queue_locked(pending_metadata);
            track_to_prepare = current_track_;
            auto dur_it = current_track_->metadata.find("duration");
            if (dur_it != current_track_->metadata.end() && !dur_it->second.empty()) {
                char* end = nullptr;
                const int64_t d = std::strtoll(dur_it->second.c_str(), &end, 10);
                if (end != dur_it->second.c_str() && d > 0) duration_ms_ = d;
            }
            if (tp) {
                sync_token = ++next_player_sync_token_;
                pending_player_sync_token_ = sync_token;
            }
        } else {
            current_track_.reset();
            explicit_prev_tracks_.reset();
            playback_id_.clear();
            playback_phase_ = SessionPlaybackPhase::Idle;
            position_ms_ = 0;
            duration_ms_ = 0;
            decorate_local_queue_locked(pending_metadata);
            should_stop_player = true;
            if (tp) {
                sync_token = ++next_player_sync_token_;
                pending_player_sync_token_ = sync_token;
            }
        }

        LOGI("ContextPlayerImpl.preparePlay: context_uri=%s (ready to play)", context_uri_.c_str());

        emit_state_locked(false);
        emit_queue_locked();
        sc_cb = state_changed_callback_;
        qc_cb = queue_changed_callback_;
        sc_bytes = cached_state_bytes_;
        qc_bytes = cached_queue_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }

    dispatch_metadata_requests(pending_metadata);

    if (tp && should_stop_player) {
        tp->stop(rendering::StopReason::ContextEnded);
        clear_pending_player_sync(sync_token);
    }

    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    dispatch_connect_listeners(connect_bundle);

    if (tp && track_to_prepare.has_value()) {
        tp->start(*track_to_prepare, rendering::StartReason::PreparePlay, seek_to_ms, true);
        clear_pending_player_sync(sync_token);
    }
    return true;
}

bool ContextPlayerImpl::play_prepared(const uint8_t* payload, size_t len) {
    if (payload && len > 0) {
        LOGI("ContextPlayerImpl.playPrepared: payload_len=%zu", len);
    }
    LOGI("ContextPlayerImpl.playPrepared");
    return resume();
}

bool ContextPlayerImpl::update_context(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    DecodedPreparePlay parsed;
    if (decode_context_submessage(payload, len, parsed) &&
        (!parsed.context_uri.empty() || !parsed.context_url.empty() ||
         !parsed.tracks.empty() || !parsed.context_metadata.empty())) {
        StateChangedCallback sc_cb;
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> sc_bytes, qc_bytes;
        ConnectDispatchBundle connect_bundle;
        std::vector<PendingMetadataRequest> pending_metadata;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            transition_to_local_locked();
            context_uri_ = parsed.context_uri;
            context_url_ = parsed.context_url;
            for (const auto& [k, v] : parsed.context_metadata) {
                context_metadata_[k] = v;
            }
            if (!parsed.tracks.empty()) {
                context_processor_.set_context(
                    context_uri_,
                    parsed.page_url,
                    parsed.tracks,
                    parsed.next_page_url,
                    0);
            }
            bump_queue_revision_locked();
            decorate_local_queue_locked(pending_metadata);
            emit_state_locked();
            emit_queue_locked();
            sc_cb = state_changed_callback_;
            qc_cb = queue_changed_callback_;
            sc_bytes = cached_state_bytes_;
            qc_bytes = cached_queue_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
        dispatch_metadata_requests(pending_metadata);
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    return false;
}

bool ContextPlayerImpl::update_track(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    context_view::Entry entry;
    if (decode_track_or_provided_track(payload, len, entry)) {
        StateChangedCallback sc_cb;
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> sc_bytes;
        std::vector<uint8_t> qc_bytes;
        ConnectDispatchBundle connect_bundle;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            const auto vault_it = entry.metadata.find("is_vault_track");
            const bool has_vault_mask_flag =
                entry.metadata.find("musify_vault_masked") != entry.metadata.end() ||
                (vault_it != entry.metadata.end() && vault_it->second == "true");
            bool updated = false;

            if (current_track_.has_value() &&
                (current_track_->uri == entry.uri || current_track_->uid == entry.uid)) {
                if (has_vault_mask_flag) {
                    current_track_->metadata = entry.metadata;
                    if (!is_vault_masked_entry(*current_track_) &&
                        track_info_provider_ != nullptr) {
                        if (const auto cached = track_info_provider_->getCached(current_track_->uri);
                            cached.has_value()) {
                            apply_track_info_locked(*current_track_, *cached);
                        }
                    }
                } else {
                    for (const auto& [k, v] : entry.metadata) {
                        current_track_->metadata[k] = v;
                    }
                }
                auto it = current_track_->metadata.find("duration");
                if (it != current_track_->metadata.end() && !it->second.empty()) {
                    char* end = nullptr;
                    const int64_t d = std::strtoll(it->second.c_str(), &end, 10);
                    if (end != it->second.c_str() && d > 0) duration_ms_ = d;
                }
                updated = true;
            }

            if (has_vault_mask_flag) {
                for (auto& queued : user_queue_) {
                    if (queued.uri == entry.uri || queued.uid == entry.uid) {
                        queued.metadata = entry.metadata;
                        if (!is_vault_masked_entry(queued) &&
                            track_info_provider_ != nullptr) {
                            if (const auto cached = track_info_provider_->getCached(queued.uri);
                                cached.has_value()) {
                                apply_track_info_locked(queued, *cached);
                            }
                        }
                        updated = true;
                    }
                }
            }

            if (updated && origin_ == PlaybackOrigin::kLocal) {
                bump_queue_revision_locked();
                emit_state_locked();
                emit_queue_locked();
                sc_cb = state_changed_callback_;
                qc_cb = queue_changed_callback_;
                sc_bytes = cached_state_bytes_;
                qc_bytes = cached_queue_bytes_;
                capture_connect_dispatch_locked(connect_bundle);
            }
        }
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    return false;
}

bool ContextPlayerImpl::update_page(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    std::string page_url, next_page_url;
    std::vector<context_view::Entry> tracks;
    if (decode_context_page(payload, len, page_url, next_page_url, tracks)) {
        StateChangedCallback sc_cb;
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> sc_bytes;
        std::vector<uint8_t> qc_bytes;
        ConnectDispatchBundle connect_bundle;
        std::vector<PendingMetadataRequest> pending_metadata;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            const int32_t iteration = context_processor_.get_current_iteration();
            context_processor_.parseLoadedContextPage(iteration, page_url, tracks, next_page_url);
            bump_queue_revision_locked();
            if (origin_ == PlaybackOrigin::kLocal) {
                decorate_local_queue_locked(pending_metadata);
                emit_state_locked();
                emit_queue_locked();
                sc_cb = state_changed_callback_;
                qc_cb = queue_changed_callback_;
                sc_bytes = cached_state_bytes_;
                qc_bytes = cached_queue_bytes_;
                capture_connect_dispatch_locked(connect_bundle);
            }
        }
        dispatch_metadata_requests(pending_metadata);
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    return false;
}

bool ContextPlayerImpl::update_view_uri(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    std::string uri;
    if (decode_single_string(payload, len, uri)) {
        StateChangedCallback sc_cb;
        std::vector<uint8_t> sc_bytes;
        ConnectDispatchBundle connect_bundle;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            view_uri_ = uri;
            if (origin_ == PlaybackOrigin::kLocal) {
                emit_state_locked();
                sc_cb = state_changed_callback_;
                sc_bytes = cached_state_bytes_;
                capture_connect_dispatch_locked(connect_bundle);
            }
        }
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    return false;
}

bool ContextPlayerImpl::apply_signal_value(
        const std::string& signal_id,
        const std::string& parameters) {
    if (signal_id.empty()) {
        return false;
    }
    PLAYER_REMOTE_LOGI(
        "Applying signal signal_id=%s has_params=%d",
        signal_id.c_str(),
        parameters.empty() ? 0 : 1);

    // Handle well-known playback control signals cleanly while recording signal metadata.
    if (signal_id == "pause" || signal_id == "interrupt" || signal_id == "fade-out") {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            transition_to_local_locked();
            if (std::find(signals_.begin(), signals_.end(), signal_id) == signals_.end()) {
                if (signals_.size() >= 32) {
                    signals_.erase(signals_.begin());
                }
                signals_.push_back(signal_id);
            }
        }
        return pause();
    }
    if (signal_id == "resume") {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            transition_to_local_locked();
            if (std::find(signals_.begin(), signals_.end(), signal_id) == signals_.end()) {
                if (signals_.size() >= 32) {
                    signals_.erase(signals_.begin());
                }
                signals_.push_back(signal_id);
            }
        }
        return resume();
    }

    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    ConnectDispatchBundle connect_bundle;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        transition_to_local_locked();
        if (std::find(signals_.begin(), signals_.end(), signal_id) == signals_.end()) {
            if (signals_.size() >= 32) {
                signals_.erase(signals_.begin());
            }
            signals_.push_back(signal_id);
        }
        if (!parameters.empty()) {
            context_metadata_["signal." + signal_id] = parameters;
        }
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
    return true;
}

bool ContextPlayerImpl::signal(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    DecodedSignalRequest req;
    if (!decode_signal_request_full(payload, len, req)) {
        return false;
    }
    return apply_signal_value(req.signal_id, req.parameters);
}

bool ContextPlayerImpl::set_sleep_timer(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    DecodedSleepTimerRequest req;
    if (!decode_set_sleep_timer_request_full(payload, len, req)) {
        return false;
    }
    SleepTimerState next_timer;
    switch (req.action) {
        case DecodedSleepTimerRequest::Action::kClear:
            next_timer.mode = SleepTimerMode::kOff;
            next_timer.expires_at_ms = 0;
            PLAYER_REMOTE_LOGI("Sleep timer cleared");
            break;
        case DecodedSleepTimerRequest::Action::kDurationSeconds: {
            if (req.duration_seconds <= 0) {
                next_timer.mode = SleepTimerMode::kOff;
                next_timer.expires_at_ms = 0;
                PLAYER_REMOTE_LOGI("Sleep timer cleared (duration_seconds<=0)");
            } else {
                const int64_t now_ms = get_current_timestamp_ms();
                next_timer.mode = SleepTimerMode::kDuration;
                next_timer.expires_at_ms = now_ms + (req.duration_seconds * 1000LL);
                PLAYER_REMOTE_LOGI(
                    "Sleep timer set to duration=%lld s (expires_at=%lld)",
                    static_cast<long long>(req.duration_seconds),
                    static_cast<long long>(next_timer.expires_at_ms));
            }
            break;
        }
        case DecodedSleepTimerRequest::Action::kEndOfTrack:
            next_timer.mode = SleepTimerMode::kEndOfTrack;
            next_timer.expires_at_ms = 0;
            PLAYER_REMOTE_LOGI("Sleep timer set to end_of_track");
            break;
        case DecodedSleepTimerRequest::Action::kUnset:
            return false;
    }
    apply_sleep_timer_state(next_timer);
    return true;
}

bool ContextPlayerImpl::delete_session(const uint8_t* payload, size_t len) {
    std::string target_session_id;
    if (!decode_delete_session_request(payload, len, target_session_id)) {
        LOGW("ContextPlayerImpl.deleteSession rejected malformed payload len=%zu", len);
        return false;
    }

    std::shared_ptr<rendering::TrackPlayer> tp;
    uint64_t sync_token = 0;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes;
    std::vector<uint8_t> qc_bytes;
    ConnectDispatchBundle connect_bundle;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        transition_to_local_locked();
        if (!target_session_id.empty()) {
            LOGI("ContextPlayerImpl.deleteSession target=%s current=%s",
                 target_session_id.c_str(), session_id_.c_str());
        } else {
            LOGI("ContextPlayerImpl.deleteSession session_id=%s", session_id_.c_str());
        }
        tp = track_player_;
        session_id_.clear();
        session_command_id_.clear();
        playback_id_.clear();
        signals_.clear();
        modes_.clear();
        sleep_timer_ = SleepTimerState{};
        playback_phase_ = SessionPlaybackPhase::Idle;
        position_ms_ = 0;
        duration_ms_ = 0;
        current_track_.reset();
        user_queue_.clear();
        explicit_prev_tracks_.reset();
        context_processor_.clear();
        context_processor_.set_shuffling(shuffling_);
        if (tp) {
            sync_token = ++next_player_sync_token_;
            pending_player_sync_token_ = sync_token;
        } else {
            pending_player_sync_token_ = 0;
        }
        context_uri_.clear();
        context_url_.clear();
        context_metadata_.clear();
        page_metadata_.clear();
        bump_queue_revision_locked();
        emit_state_locked(false);
        emit_queue_locked();
        sc_cb = state_changed_callback_;
        qc_cb = queue_changed_callback_;
        sc_bytes = cached_state_bytes_;
        qc_bytes = cached_queue_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }
    {
        std::lock_guard<std::mutex> slock(sleep_timer_mutex_);
        ++sleep_timer_epoch_;
    }
    sleep_timer_cv_.notify_all();

    if (tp) {
        tp->stop(rendering::StopReason::SessionDeleted);
        clear_pending_player_sync(sync_token);
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
    return true;
}

const uint8_t* ContextPlayerImpl::get_state(size_t* out_len) const {
    std::lock_guard<std::mutex> lock(mutex_);
    if (out_len) *out_len = cached_state_bytes_.size();
    return cached_state_bytes_.data();
}

std::vector<uint8_t> ContextPlayerImpl::get_state() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return cached_state_bytes_;
}

const uint8_t* ContextPlayerImpl::get_queue(size_t* out_len) const {
    std::lock_guard<std::mutex> lock(mutex_);
    if (out_len) *out_len = cached_queue_bytes_.size();
    return cached_queue_bytes_.data();
}

std::vector<uint8_t> ContextPlayerImpl::get_queue() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return cached_queue_bytes_;
}

std::string ContextPlayerImpl::get_error() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return last_error_;
}

void ContextPlayerImpl::clear_pending_player_sync(uint64_t sync_token) {
    if (sync_token == 0) {
        return;
    }
    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    ConnectDispatchBundle connect_bundle;
    bool should_emit = false;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (pending_player_sync_token_ != sync_token) {
            return;
        }
        pending_player_sync_token_ = 0;
        if (origin_ == PlaybackOrigin::kRemoteMirrored) {
            return;
        }

        if (track_player_ && current_track_.has_value()) {
            const auto tp_track = track_player_->getCurrentTrack();
            const bool player_matches_current =
                tp_track.has_value() &&
                tp_track->uri == current_track_->uri &&
                (tp_track->uid.empty() || current_track_->uid.empty() ||
                 tp_track->uid == current_track_->uid);
            if (player_matches_current) {
                const rendering::TrackPlayerState tp_state = track_player_->getState();
                const bool should_reconcile =
                    (is_phase_buffering(playback_phase_) &&
                     tp_state.phase == rendering::TrackPlayerPhase::Playing) ||
                    tp_state.phase == rendering::TrackPlayerPhase::Faulted;
                if (should_reconcile) {
                    const SessionPlaybackPhase mapped =
                        map_track_player_state_to_phase(tp_state);
                    if (tp_state.duration_ms > 0 && duration_ms_ <= 0) {
                        duration_ms_ = tp_state.duration_ms;
                    }
                    if (mapped != playback_phase_) {
                        playback_phase_ = mapped;
                        emit_state_locked(false);
                        sc_cb = state_changed_callback_;
                        sc_bytes = cached_state_bytes_;
                        capture_connect_dispatch_locked(connect_bundle);
                        should_emit = true;
                    }
                }
            }
        }
    }
    if (should_emit) {
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
    }
}

void ContextPlayerImpl::update_position_and_duration_locked(bool sync_position) {
    bool player_matches_current = false;
    if (track_player_ && current_track_.has_value()) {
        const auto tp_track = track_player_->getCurrentTrack();
        if (tp_track.has_value() && tp_track->uri == current_track_->uri) {
            player_matches_current =
                tp_track->uid.empty() || current_track_->uid.empty() ||
                tp_track->uid == current_track_->uid;
        }
    }

    if (player_matches_current) {
        if (sync_position && pending_player_sync_token_ == 0) {
            const int64_t player_pos = track_player_->getPosition();
            if (player_pos >= 0) position_ms_ = player_pos;
        }
        const int64_t player_dur = track_player_->getDuration();
        if (player_dur > 0) duration_ms_ = player_dur;
    }
    if (duration_ms_ <= 0 && current_track_.has_value()) {
        auto it = current_track_->metadata.find("duration");
        if (it != current_track_->metadata.end() && !it->second.empty()) {
            char* end = nullptr;
            const int64_t d = std::strtoll(it->second.c_str(), &end, 10);
            if (end != it->second.c_str() && d > 0) duration_ms_ = d;
        }
        if (duration_ms_ <= 0 && track_info_provider_ != nullptr) {
            if (const auto cached = track_info_provider_->getCached(current_track_->uri);
                cached.has_value() && cached->duration_ms > 0) {
                duration_ms_ = cached->duration_ms;
            }
        }
    }
}

void ContextPlayerImpl::emit_state_locked(bool sync_player_position) {
    const int64_t now_ms = get_current_timestamp_ms();

    if (origin_ == PlaybackOrigin::kRemoteMirrored) {
        int64_t remote_duration = mirrored_state_.duration_ms;
        if (remote_duration <= 0 && mirrored_state_.current_track.has_value()) {
            const auto it = mirrored_state_.current_track->metadata.find("duration");
            if (it != mirrored_state_.current_track->metadata.end() && !it->second.empty()) {
                char* end = nullptr;
                const int64_t d = std::strtoll(it->second.c_str(), &end, 10);
                if (end != it->second.c_str() && d > 0) {
                    remote_duration = d;
                }
            }
        }

        const int64_t extrapolated_pos = mirrored_state_.extrapolated_position_ms(now_ms);
        const bool actively_playing =
            mirrored_state_.is_playing &&
            !mirrored_state_.is_paused &&
            !mirrored_state_.is_buffering;
        const double active_speed =
            actively_playing
                ? (mirrored_state_.playback_speed > 0.0 ? mirrored_state_.playback_speed : 1.0)
                : 0.0;

        PlayerStateData data;
        data.timestamp = now_ms;
        data.context_uri = mirrored_state_.context_uri;
        data.context_url = mirrored_state_.context_url;
        data.restrictions = mirrored_state_.restrictions_bytes;
        data.play_origin = mirrored_state_.play_origin;
        data.page_index = mirrored_state_.page_index;
        data.track_index = mirrored_state_.track_index;
        data.track = mirrored_state_.current_track.has_value()
                         ? &mirrored_state_.current_track.value()
                         : nullptr;
        data.duration_ms = remote_duration;
        data.is_playing = mirrored_state_.is_playing;
        data.is_paused = mirrored_state_.is_paused;
        data.playback_speed = active_speed;
        data.position_as_of_timestamp = extrapolated_pos;
        data.shuffling_context = mirrored_state_.shuffling;
        data.repeating_context = mirrored_state_.repeating_context;
        data.repeating_track = mirrored_state_.repeating_track;
        data.is_buffering = mirrored_state_.is_buffering;
        data.context_metadata = mirrored_state_.context_metadata;
        data.page_metadata = mirrored_state_.page_metadata;
        data.session_id = mirrored_state_.session_id;
        data.signals = mirrored_state_.signals;
        data.session_command_id = mirrored_state_.session_command_id;
        data.queue_revision = mirrored_state_.queue_revision;

        cached_state_bytes_ = StateEmitter::encode_player_state(data);

        // Field 8: playback_id (bytes)
        if (!mirrored_state_.playback_id.empty()) {
            const auto pid_bytes = playback_id_to_proto_bytes(mirrored_state_.playback_id);
            if (!pid_bytes.empty()) {
                encode_submessage_field(cached_state_bytes_, 8, pid_bytes);
            }
        }
        // Field 17 (merge fragment): ContextPlayerOptions.modes (field 5)
        if (!mirrored_state_.modes.empty()) {
            std::vector<uint8_t> opt_modes;
            StateEmitter::encode_context_metadata(opt_modes, 5, mirrored_state_.modes);
            if (!opt_modes.empty()) {
                encode_submessage_field(cached_state_bytes_, 17, opt_modes);
            }
        }
        // Field 19: suppressions (repeated string) decoded from Suppressions proto
        for (const auto& provider : decode_suppressions_providers(mirrored_state_.suppressions_bytes)) {
            encode_string_field(cached_state_bytes_, 19, provider);
        }
        // Field 20: prev_tracks (repeated ProvidedTrack)
        for (const auto& pt : mirrored_state_.prev_tracks) {
            encode_submessage_field(cached_state_bytes_, 20, StateEmitter::encode_provided_track(pt));
        }
        // Field 21: next_tracks (repeated ProvidedTrack)
        for (const auto& nt : mirrored_state_.next_tracks) {
            encode_submessage_field(cached_state_bytes_, 21, StateEmitter::encode_provided_track(nt));
        }

        // Strict echo prevention: mirrored remote state NEVER populates Connect PutState snapshot.
        latest_connect_snapshot_ = ConnectPlayerSnapshot{};
        return;
    }

    update_position_and_duration_locked(sync_player_position);

    const auto next_tracks = context_processor_.get_next_tracks(1);
    const bool has_next = !next_tracks.empty();
    const auto prev_tracks = explicit_prev_tracks_.has_value()
                                 ? *explicit_prev_tracks_
                                 : context_processor_.get_prev_tracks();
    const bool has_prev = !prev_tracks.empty();
    const bool has_queue = !user_queue_.empty();

    const bool playing_flag = is_phase_playing(playback_phase_);
    const bool paused_flag = is_phase_paused(playback_phase_);
    const bool buffering_flag = is_phase_buffering(playback_phase_);
    const bool repeating_ctx_flag =
        repeat_mode_ == SessionRepeatMode::Context ||
        repeat_mode_ == SessionRepeatMode::Track;
    const bool repeating_trk_flag =
        repeat_mode_ == SessionRepeatMode::Track;

    const auto restrictions_bytes = restrictions_engine_.evaluate(
        playing_flag,
        paused_flag,
        has_prev,
        has_next,
        shuffling_,
        repeating_ctx_flag,
        repeating_trk_flag,
        has_queue);

    const context_view::Entry* track_ptr = current_track_.has_value() ? &current_track_.value() : nullptr;

    PlayerStateData data;
    data.timestamp = now_ms;
    data.context_uri = context_uri_;
    data.context_url = context_url_;
    data.restrictions = restrictions_bytes;
    data.track = track_ptr;
    data.duration_ms = duration_ms_;
    data.is_playing = playing_flag;
    data.is_paused = paused_flag;
    data.playback_speed = (playback_phase_ == SessionPlaybackPhase::Playing) ? playback_speed_ : 0.0;
    data.position_as_of_timestamp = position_ms_;
    data.shuffling_context = shuffling_;
    data.repeating_context = repeating_ctx_flag;
    data.repeating_track = repeating_trk_flag;
    data.is_buffering = buffering_flag;
    data.context_metadata = context_metadata_;
    data.page_metadata = page_metadata_;
    data.session_id = session_id_;
    data.signals = signals_;
    data.session_command_id = session_command_id_;
    data.play_origin = play_origin_;
    data.page_index = 0;
    data.track_index = context_processor_.get_current_index();
    data.queue_revision = queue_revision_;

    cached_state_bytes_ = StateEmitter::encode_player_state(data);
    if (!playback_id_.empty()) {
        const auto pid_bytes = playback_id_to_proto_bytes(playback_id_);
        if (!pid_bytes.empty()) {
            encode_submessage_field(cached_state_bytes_, 8, pid_bytes);
        }
    }
    if (!modes_.empty()) {
        std::vector<uint8_t> opt_modes;
        StateEmitter::encode_context_metadata(opt_modes, 5, modes_);
        if (!opt_modes.empty()) {
            encode_submessage_field(cached_state_bytes_, 17, opt_modes);
        }
    }

    latest_connect_snapshot_.timestamp_ms = now_ms;
    latest_connect_snapshot_.context_uri = context_uri_;
    latest_connect_snapshot_.context_url = context_url_;
    latest_connect_snapshot_.playback_id = playback_id_;
    latest_connect_snapshot_.session_id = session_id_;
    latest_connect_snapshot_.session_command_id = session_command_id_;
    latest_connect_snapshot_.last_command_sent_by_device_id = last_command_sent_by_device_id_;
    latest_connect_snapshot_.last_command_message_id = last_command_message_id_;
    latest_connect_snapshot_.queue_revision = queue_revision_;
    latest_connect_snapshot_.playback_phase = playback_phase_;
    latest_connect_snapshot_.repeat_mode = repeat_mode_;
    latest_connect_snapshot_.shuffling = shuffling_;
    latest_connect_snapshot_.playback_speed = playback_speed_;
    latest_connect_snapshot_.position_ms = position_ms_;
    latest_connect_snapshot_.duration_ms = duration_ms_;
    latest_connect_snapshot_.page_index = 0;
    latest_connect_snapshot_.track_index = data.track_index;
    latest_connect_snapshot_.current_track = current_track_;
    latest_connect_snapshot_.prev_tracks = prev_tracks;
    latest_connect_snapshot_.next_tracks.clear();
    latest_connect_snapshot_.next_tracks.reserve(user_queue_.size() + 10);
    latest_connect_snapshot_.next_tracks.insert(
        latest_connect_snapshot_.next_tracks.end(),
        user_queue_.begin(),
        user_queue_.end());
    const auto lookahead = context_processor_.get_next_tracks(10);
    latest_connect_snapshot_.next_tracks.insert(
        latest_connect_snapshot_.next_tracks.end(),
        lookahead.begin(),
        lookahead.end());
    latest_connect_snapshot_.restrictions_bytes = restrictions_bytes;
    latest_connect_snapshot_.play_origin = play_origin_;
    latest_connect_snapshot_.context_metadata = context_metadata_;
    latest_connect_snapshot_.page_metadata = page_metadata_;
    latest_connect_snapshot_.signals = signals_;
    latest_connect_snapshot_.has_player_state =
        !context_uri_.empty() || !context_url_.empty() || current_track_.has_value();
}

void ContextPlayerImpl::add_player_state_listener(PlayerStateListener* listener) {
    if (listener == nullptr) {
        return;
    }
    std::lock_guard<std::mutex> lock(mutex_);
    if (std::find(player_state_listeners_.begin(), player_state_listeners_.end(), listener) ==
        player_state_listeners_.end()) {
        player_state_listeners_.push_back(listener);
    }
}

void ContextPlayerImpl::remove_player_state_listener(PlayerStateListener* listener) {
    std::lock_guard<std::mutex> lock(mutex_);
    player_state_listeners_.erase(
        std::remove(player_state_listeners_.begin(), player_state_listeners_.end(), listener),
        player_state_listeners_.end());
}

ContextPlayerImpl::ConnectPlayerSnapshot ContextPlayerImpl::snapshot_for_connect() const {
    std::lock_guard<std::mutex> lock(mutex_);
    if (origin_ == PlaybackOrigin::kRemoteMirrored) {
        return ConnectPlayerSnapshot{};
    }
    return latest_connect_snapshot_;
}

void ContextPlayerImpl::set_session_command_id(const std::string& command_id) {
    std::lock_guard<std::mutex> lock(mutex_);
    session_command_id_ = command_id;
}

void ContextPlayerImpl::capture_connect_dispatch_locked(ConnectDispatchBundle& out) {
    if (origin_ == PlaybackOrigin::kRemoteMirrored) {
        out.listeners.clear();
        out.snapshot = ConnectPlayerSnapshot{};
        out.track_changed = false;
        return;
    }
    out.listeners = player_state_listeners_;
    out.snapshot = latest_connect_snapshot_;
    out.track_changed = (playback_id_ != last_emitted_playback_id_);
    last_emitted_playback_id_ = playback_id_;
}

void ContextPlayerImpl::dispatch_connect_listeners(const ConnectDispatchBundle& bundle) {
    for (auto* listener : bundle.listeners) {
        if (listener != nullptr) {
            listener->on_player_state_changed(bundle.snapshot, bundle.track_changed);
        }
    }
}

bool ContextPlayerImpl::handle_connect_transfer_command(
        const json::JsonValue& parsed,
        const std::string& sent_by_device_id,
        uint32_t message_id,
        uint32_t target_alias_id) {
    std::string b64_data = parsed.get_string("data").value_or(std::string{});
    if (b64_data.empty()) {
        b64_data = parsed.get_string("transfer_state").value_or(std::string{});
    }
    if (b64_data.empty()) {
        PLAYER_REMOTE_LOGE("Connect transfer missing base64 `data` payload");
        std::lock_guard<std::mutex> lock(mutex_);
        last_error_ = "TRANSFER_MISSING_DATA";
        return false;
    }

    const auto decoded_bytes = decode_base64(b64_data);
    if (!decoded_bytes.has_value() || decoded_bytes->empty()) {
        PLAYER_REMOTE_LOGE("Connect transfer invalid base64 payload len=%zu", b64_data.size());
        std::lock_guard<std::mutex> lock(mutex_);
        last_error_ = "TRANSFER_INVALID_BASE64";
        return false;
    }

    TransferStateProto ts;
    if (!decode_transfer_state_proto(decoded_bytes->data(), decoded_bytes->size(), ts)) {
        PLAYER_REMOTE_LOGE(
            "Connect transfer failed to decode TransferState protobuf bytes=%zu",
            decoded_bytes->size());
        std::lock_guard<std::mutex> lock(mutex_);
        last_error_ = "TRANSFER_INVALID_PROTO";
        return false;
    }

    const std::string from_device_id =
        parsed.get_string("from_device_identifier").value_or(std::string{});
    const std::string effective_sender =
        !sent_by_device_id.empty() ? sent_by_device_id : from_device_id;

    // Resolve `options.restore_paused` ("restore" | "resume" | "pause", `liborbit` 0x13b84ec..0x13b8550)
    std::string restore_paused_mode =
        parsed.get_string("restore_paused").value_or(std::string{});
    if (const auto* opts = parsed.find("options"); opts != nullptr && opts->is_object()) {
        if (const auto rp = opts->get_string("restore_paused"); rp.has_value() && !rp->empty()) {
            restore_paused_mode = *rp;
        }
    }

    bool start_paused = ts.playback.is_paused;
    if (restore_paused_mode == "pause") {
        start_paused = true;
    } else if (restore_paused_mode == "resume") {
        start_paused = false;
    } else if (restore_paused_mode == "restore" || restore_paused_mode.empty()) {
        start_paused = ts.playback.is_paused;
    }

    // Extrapolate playback position when source was actively playing.
    int64_t seek_pos_ms = std::max<int64_t>(0, static_cast<int64_t>(ts.playback.position_as_of_timestamp_ms));
    const double transfer_speed =
        (ts.playback.has_playback_speed && ts.playback.playback_speed > 0.0)
            ? ts.playback.playback_speed
            : (ts.options.playback_speed.has_value() && *ts.options.playback_speed > 0.0
                   ? *ts.options.playback_speed
                   : 1.0);
    if (!ts.playback.is_paused && ts.playback.timestamp_ms > 0) {
        const int64_t now_ms = get_current_timestamp_ms();
        if (now_ms > ts.playback.timestamp_ms) {
            const double elapsed = static_cast<double>(now_ms - ts.playback.timestamp_ms) * transfer_speed;
            seek_pos_ms += static_cast<int64_t>(std::llround(elapsed));
        }
    }

    // Select context from session (primary `context`, fallback `main_context`).
    TransferContextProto& active_ctx =
        (!ts.current_session.context.uri.empty() ||
         !ts.current_session.context.url.empty() ||
         !ts.current_session.context.all_tracks.empty())
            ? ts.current_session.context
            : ts.current_session.main_context;

    std::string ctx_uri = active_ctx.uri;
    std::string ctx_url = active_ctx.url;
    std::unordered_map<std::string, std::string> ctx_md = active_ctx.metadata;
    std::unordered_map<std::string, std::string> page_md;
    std::vector<context_view::Entry> tracks = active_ctx.all_tracks;
    std::vector<size_t> page_track_offsets = active_ctx.page_track_offsets;
    std::string page_url = active_ctx.first_page_url;
    std::string next_page_url = active_ctx.first_next_page_url;

    // Resolve missing context tracks via ContextResolveClient OUTSIDE mutex_.
    if (tracks.empty() && (!ctx_url.empty() || !ctx_uri.empty())) {
        const std::string& resolve_target = !ctx_url.empty() ? ctx_url : ctx_uri;
        PLAYER_REMOTE_LOGI(
            "Connect transfer resolving context target=%s from_device=%s restore_paused=%s",
            sanitize_url_for_log(resolve_target).c_str(),
            from_device_id.c_str(),
            restore_paused_mode.c_str());
        const ContextResolveResult resolved = context_resolve_client_.resolve(resolve_target);
        if (resolved.ok && resolved.context.has_value()) {
            const auto& rctx = *resolved.context;
            if (ctx_uri.empty() && !rctx.uri.empty()) ctx_uri = rctx.uri;
            if (ctx_url.empty() && !rctx.url.empty()) ctx_url = rctx.url;
            for (const auto& [k, v] : rctx.metadata) {
                if (ctx_md.find(k) == ctx_md.end()) {
                    ctx_md[k] = v;
                }
            }
            if (!rctx.pages.empty()) {
                page_md = rctx.pages.front().metadata;
            }
            tracks = rctx.all_tracks;
            page_track_offsets = rctx.page_track_offsets;
            page_url = rctx.first_page_url;
            next_page_url = rctx.first_next_page_url;
        } else {
            PLAYER_REMOTE_LOGW(
                "Connect transfer context resolve failed (%s); falling back to current_track if present",
                resolved.error_message.c_str());
        }
    }

    if (tracks.empty() && ts.playback.current_track.has_value() &&
        !ts.playback.current_track->uri.empty()) {
        context_view::Entry cur = *ts.playback.current_track;
        if (cur.uid.empty()) {
            cur.uid = !ts.current_session.current_uid.empty()
                          ? ts.current_session.current_uid
                          : generate_track_uid();
        }
        tracks.push_back(std::move(cur));
    }

    if (tracks.empty() && ts.queue.tracks.empty()) {
        PLAYER_REMOTE_LOGE(
            "Connect transfer has zero playable tracks (context_uri=%s)",
            ctx_uri.c_str());
        std::lock_guard<std::mutex> lock(mutex_);
        last_error_ = "TRANSFER_NO_PLAYABLE_TRACKS";
        return false;
    }

    // Merge base options + session option_overrides.
    OptionOverrides merged_opts = ts.options;
    if (ts.current_session.option_overrides.shuffling_context.has_value()) {
        merged_opts.shuffling_context = ts.current_session.option_overrides.shuffling_context;
    }
    if (ts.current_session.option_overrides.repeating_context.has_value()) {
        merged_opts.repeating_context = ts.current_session.option_overrides.repeating_context;
    }
    if (ts.current_session.option_overrides.repeating_track.has_value()) {
        merged_opts.repeating_track = ts.current_session.option_overrides.repeating_track;
    }
    if (ts.current_session.option_overrides.playback_speed.has_value()) {
        merged_opts.playback_speed = ts.current_session.option_overrides.playback_speed;
    }
    for (const auto& [mk, mv] : ts.current_session.option_overrides.modes) {
        merged_opts.modes[mk] = mv;
    }

    const std::string target_uid =
        !ts.current_session.current_uid.empty()
            ? ts.current_session.current_uid
            : (ts.playback.current_track.has_value() ? ts.playback.current_track->uid : std::string{});
    const std::string target_uri =
        ts.playback.current_track.has_value() ? ts.playback.current_track->uri : std::string{};

    std::shared_ptr<rendering::TrackPlayer> tp;
    context_view::Entry track_to_play;
    uint64_t sync_token = 0;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;
    ConnectDispatchBundle connect_bundle;
    std::vector<PendingMetadataRequest> pending_metadata;
    bool update_sleep_timer_thread = false;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        transition_to_local_locked();
        last_command_sent_by_device_id_ = effective_sender;
        last_command_message_id_ = message_id;
        last_command_target_alias_id_ = target_alias_id;
        if (auto scid = parsed.get_string("session_command_id"); scid.has_value() && !scid->empty()) {
            session_command_id_ = *scid;
        } else if (message_id > 0) {
            session_command_id_ = "connect-" + std::to_string(message_id);
        }

        context_uri_ = ctx_uri;
        context_url_ = ctx_url;
        context_metadata_ = std::move(ctx_md);
        page_metadata_ = std::move(page_md);
        play_origin_ = ts.current_session.play_origin;
        if (!ts.current_session.original_session_id.empty()) {
            session_id_ = ts.current_session.original_session_id;
        } else {
            session_id_ = generate_track_uid();
        }

        if (merged_opts.shuffling_context.has_value()) {
            shuffling_ = *merged_opts.shuffling_context;
        }
        apply_repeat_overrides_locked(
            merged_opts.repeating_context,
            merged_opts.repeating_track);
        playback_speed_ = transfer_speed;
        modes_ = merged_opts.modes;

        user_queue_ = ts.queue.tracks;
        bump_queue_revision_locked();

        const int32_t init_idx = resolve_initial_track_index(
            tracks,
            target_uid,
            target_uri,
            std::nullopt,
            -1,
            page_track_offsets);

        if (!shuffling_) {
            context_processor_.set_shuffling(false);
        }
        context_processor_.set_context(
            context_uri_,
            page_url,
            tracks,
            next_page_url,
            init_idx);
        context_processor_.set_shuffling(shuffling_);

        std::optional<context_view::Entry> chosen_track;
        if (ts.queue.is_playing_queue && ts.playback.current_track.has_value() &&
            !ts.playback.current_track->uri.empty()) {
            chosen_track = ts.playback.current_track;
            if (chosen_track->uid.empty()) {
                chosen_track->uid = generate_track_uid();
            }
            chosen_track->provider = "queue";
            chosen_track->metadata["is_queued"] = "true";
            chosen_track->metadata["provider"] = "queue";
            if (!user_queue_.empty() &&
                (user_queue_.front().uid == chosen_track->uid ||
                 user_queue_.front().uri == chosen_track->uri)) {
                user_queue_.erase(user_queue_.begin());
            }
        } else {
            chosen_track = context_processor_.get_current_track();
            if (ts.playback.current_track.has_value() &&
                !ts.playback.current_track->uri.empty() &&
                (!chosen_track.has_value() ||
                 chosen_track->uri != ts.playback.current_track->uri)) {
                chosen_track = ts.playback.current_track;
                if (chosen_track->uid.empty()) {
                    chosen_track->uid = generate_track_uid();
                }
            }
        }

        if (ts.sleep_timer.kind == TransferSleepTimerProto::Kind::kNone) {
            sleep_timer_ = SleepTimerState{};
            update_sleep_timer_thread = true;
        } else if (ts.sleep_timer.kind == TransferSleepTimerProto::Kind::kTimestamp &&
                   ts.sleep_timer.timestamp_ms > 0) {
            sleep_timer_.mode = SleepTimerMode::kDuration;
            sleep_timer_.expires_at_ms = ts.sleep_timer.timestamp_ms;
            update_sleep_timer_thread = true;
        } else if (ts.sleep_timer.kind == TransferSleepTimerProto::Kind::kEndOfTrack) {
            sleep_timer_.mode = SleepTimerMode::kEndOfTrack;
            sleep_timer_.expires_at_ms = 0;
            update_sleep_timer_thread = true;
        }

        if (chosen_track.has_value() && !chosen_track->uri.empty()) {
            begin_track_transition_locked(
                *chosen_track,
                start_paused ? SessionPlaybackPhase::Paused
                             : SessionPlaybackPhase::BufferingPlay);
            position_ms_ = seek_pos_ms;
            decorate_local_queue_locked(pending_metadata);
            track_to_play = *current_track_;
            tp = track_player_;
            if (tp) {
                sync_token = ++next_player_sync_token_;
                pending_player_sync_token_ = sync_token;
            }
        } else {
            current_track_.reset();
            explicit_prev_tracks_.reset();
            playback_id_.clear();
            playback_phase_ = SessionPlaybackPhase::Idle;
            position_ms_ = 0;
            duration_ms_ = 0;
            decorate_local_queue_locked(pending_metadata);
        }

        emit_state_locked(false);
        emit_queue_locked();
        sc_cb = state_changed_callback_;
        qc_cb = queue_changed_callback_;
        sc_bytes = cached_state_bytes_;
        qc_bytes = cached_queue_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }

    dispatch_metadata_requests(pending_metadata);

    if (update_sleep_timer_thread) {
        SleepTimerState st_copy;
        {
            std::lock_guard<std::mutex> plock(mutex_);
            st_copy = sleep_timer_;
        }
        {
            std::lock_guard<std::mutex> slock(sleep_timer_mutex_);
            ++sleep_timer_epoch_;
            if (st_copy.mode == SleepTimerMode::kDuration && st_copy.expires_at_ms > 0) {
                ensure_sleep_timer_thread_locked();
            }
        }
        sleep_timer_cv_.notify_all();
    }

    PLAYER_REMOTE_LOGI(
        "Connect transfer applied: uri=%s track=%s pos=%lldms paused=%d queue=%zu from=%s alias=%u",
        ctx_uri.c_str(),
        track_to_play.uri.c_str(),
        static_cast<long long>(seek_pos_ms),
        start_paused ? 1 : 0,
        ts.queue.tracks.size(),
        effective_sender.c_str(),
        target_alias_id);

    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
    if (tp && !track_to_play.uri.empty()) {
        tp->setPlaybackSpeed(transfer_speed);
        tp->start(track_to_play, rendering::StartReason::PlayCommand, seek_pos_ms, start_paused);
        clear_pending_player_sync(sync_token);
    }
    return !track_to_play.uri.empty();
}

bool ContextPlayerImpl::apply_connect_remote_command(
    const std::string& endpoint,
    const std::string& command_json,
    const std::string& sent_by_device_id,
    uint32_t message_id,
    uint32_t target_alias_id) {
    const auto parsed = json::parse_json(command_json);
    const std::string resolved_endpoint =
        !endpoint.empty()
            ? endpoint
            : (parsed.has_value() ? parsed->get_string("endpoint").value_or(std::string{})
                                  : std::string{});
    const uint32_t effective_alias_id =
        resolve_target_alias_id(parsed.has_value() ? &*parsed : nullptr, target_alias_id);

    PLAYER_REMOTE_LOGI(
        "Inbound Connect command endpoint=%s sent_by=%s msg_id=%u alias=%u",
        resolved_endpoint.c_str(),
        sent_by_device_id.c_str(),
        message_id,
        effective_alias_id);

    auto record_command_meta_locked = [&]() {
        last_command_sent_by_device_id_ = sent_by_device_id;
        last_command_message_id_ = message_id;
        last_command_target_alias_id_ = effective_alias_id;
        if (parsed.has_value()) {
            if (auto scid = parsed->get_string("session_command_id");
                scid.has_value() && !scid->empty()) {
                session_command_id_ = std::move(*scid);
            } else if (message_id > 0) {
                session_command_id_ = "connect-" + std::to_string(message_id);
            }
        }
    };

    auto record_command_meta = [&]() {
        std::lock_guard<std::mutex> lock(mutex_);
        record_command_meta_locked();
    };

    if (resolved_endpoint == "transfer") {
        if (!parsed.has_value() || !parsed->is_object()) {
            PLAYER_REMOTE_LOGE("Connect transfer rejected: malformed JSON");
            return false;
        }
        return handle_connect_transfer_command(
            *parsed, sent_by_device_id, message_id, effective_alias_id);
    }
    if (resolved_endpoint == "pause") {
        record_command_meta();
        return pause();
    }
    if (resolved_endpoint == "resume") {
        record_command_meta();
        return resume();
    }
    if (resolved_endpoint == "stop") {
        record_command_meta();
        return stop();
    }
    if (resolved_endpoint == "skip_next") {
        bool override_restrictions = false;
        context_view::Entry target_track;
        if (parsed.has_value() && parsed->is_object()) {
            if (const auto* opts = parsed->find("options"); opts != nullptr && opts->is_object()) {
                override_restrictions = opts->get_bool("override_restrictions").value_or(false);
            }
            if (const auto* track_obj = parsed->find("track");
                track_obj != nullptr && track_obj->is_object()) {
                if (!parse_connect_json_track(*track_obj, target_track, "")) {
                    PLAYER_REMOTE_LOGW("Inbound skip_next: ignoring malformed target track JSON");
                }
            }
        }
        record_command_meta();
        return skip_next_impl(override_restrictions, target_track);
    }
    if (resolved_endpoint == "skip_prev") {
        bool override_restrictions = false;
        bool allow_seeking = true;
        context_view::Entry target_track;
        if (parsed.has_value() && parsed->is_object()) {
            if (const auto top_allow = parsed->get_bool("allow_seeking"); top_allow.has_value()) {
                allow_seeking = *top_allow;
            }
            if (const auto* opts = parsed->find("options"); opts != nullptr && opts->is_object()) {
                override_restrictions = opts->get_bool("override_restrictions").value_or(false);
                if (const auto opt_allow = opts->get_bool("allow_seeking"); opt_allow.has_value()) {
                    allow_seeking = *opt_allow;
                }
            }
            if (const auto* track_obj = parsed->find("track");
                track_obj != nullptr && track_obj->is_object()) {
                if (!parse_connect_json_track(*track_obj, target_track, "")) {
                    PLAYER_REMOTE_LOGW("Inbound skip_prev: ignoring malformed target track JSON");
                }
            }
        }
        record_command_meta();
        return skip_prev_impl(override_restrictions, allow_seeking, target_track);
    }
    if (resolved_endpoint == "seek_to") {
        if (!parsed.has_value()) {
            return false;
        }
        auto pos = parsed->get_int64("value");
        if (!pos.has_value()) {
            pos = parsed->get_int64("position");
        }
        if (!pos.has_value()) {
            return false;
        }
        int64_t target_pos = *pos;
        if (const auto rel = parsed->get_string("relative"); rel.has_value()) {
            if (*rel == "current") {
                std::lock_guard<std::mutex> lock(mutex_);
                const int64_t base =
                    (track_player_ && pending_player_sync_token_ == 0)
                        ? std::max<int64_t>(0, track_player_->getPosition())
                        : position_ms_;
                target_pos = std::max<int64_t>(0, base + target_pos);
            } else if (*rel == "end") {
                std::lock_guard<std::mutex> lock(mutex_);
                target_pos = std::max<int64_t>(0, duration_ms_ + target_pos);
            }
        }
        record_command_meta();
        return seek_to(target_pos);
    }
    if (resolved_endpoint == "set_shuffling_context") {
        if (!parsed.has_value()) {
            return false;
        }
        const auto val = parsed->get_bool("value");
        if (!val.has_value()) {
            return false;
        }
        record_command_meta();
        set_shuffling_context(*val);
        return true;
    }
    if (resolved_endpoint == "set_repeating_context") {
        if (!parsed.has_value()) {
            return false;
        }
        const auto val = parsed->get_bool("value");
        if (!val.has_value()) {
            return false;
        }
        record_command_meta();
        set_repeating_context(*val);
        return true;
    }
    if (resolved_endpoint == "set_repeating_track") {
        if (!parsed.has_value()) {
            return false;
        }
        const auto val = parsed->get_bool("value");
        if (!val.has_value()) {
            return false;
        }
        record_command_meta();
        set_repeating_track(*val);
        return true;
    }
    if (resolved_endpoint == "set_options") {
        if (!parsed.has_value()) {
            return false;
        }
        std::shared_ptr<rendering::TrackPlayer> tp;
        std::optional<double> updated_speed;
        StateChangedCallback sc_cb;
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> sc_bytes, qc_bytes;
        ConnectDispatchBundle connect_bundle;
        std::vector<PendingMetadataRequest> pending_metadata;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            transition_to_local_locked();
            record_command_meta_locked();
            if (const auto sh = parsed->get_bool("shuffling_context")) {
                const bool shuffle_changed = (shuffling_ != *sh);
                shuffling_ = *sh;
                context_processor_.set_shuffling(shuffling_);
                if (shuffle_changed) {
                    bump_queue_revision_locked();
                    decorate_local_queue_locked(pending_metadata);
                }
            }
            apply_repeat_overrides_locked(
                parsed->get_bool("repeating_context"),
                parsed->get_bool("repeating_track"));
            if (const auto spd = parsed->get_double("playback_speed");
                spd.has_value() && *spd > 0.0) {
                playback_speed_ = *spd;
                updated_speed = playback_speed_;
                tp = track_player_;
            }
            if (const auto* modes_obj = parsed->find("modes");
                modes_obj != nullptr && modes_obj->is_object()) {
                for (const auto& [mk, mv] : modes_obj->object_value) {
                    if (mv.is_string()) {
                        modes_[mk] = mv.string_value;
                    }
                }
            }
            emit_state_locked();
            emit_queue_locked();
            sc_cb = state_changed_callback_;
            qc_cb = queue_changed_callback_;
            sc_bytes = cached_state_bytes_;
            qc_bytes = cached_queue_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
        dispatch_metadata_requests(pending_metadata);
        if (tp && updated_speed.has_value()) {
            tp->setPlaybackSpeed(*updated_speed);
        }
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    if (resolved_endpoint == "add_to_queue") {
        if (!parsed.has_value()) {
            return false;
        }
        const auto* track_obj = parsed->find("track");
        if (track_obj == nullptr || !track_obj->is_object()) {
            return false;
        }
        context_view::Entry entry;
        if (!parse_connect_json_track(*track_obj, entry, "queue") || entry.uri.empty()) {
            return false;
        }
        entry.provider = "queue";
        entry.metadata["is_queued"] = "true";
        entry.metadata["provider"] = "queue";

        QueueChangedCallback qc_cb;
        StateChangedCallback sc_cb;
        std::vector<uint8_t> qc_bytes, sc_bytes;
        ConnectDispatchBundle connect_bundle;
        std::vector<PendingMetadataRequest> pending_metadata;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            transition_to_local_locked();
            record_command_meta_locked();
            user_queue_.push_back(std::move(entry));
            bump_queue_revision_locked();
            decorate_local_queue_locked(pending_metadata);
            emit_queue_locked();
            emit_state_locked();
            qc_cb = queue_changed_callback_;
            qc_bytes = cached_queue_bytes_;
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
        dispatch_metadata_requests(pending_metadata);
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    if (resolved_endpoint == "set_queue") {
        if (!parsed.has_value() || !parsed->is_object()) {
            return false;
        }
        const auto* next_arr = parsed->find("next_tracks");
        const auto* prev_arr = parsed->find("prev_tracks");
        if ((next_arr == nullptr || !next_arr->is_array()) &&
            (prev_arr == nullptr || !prev_arr->is_array())) {
            return false;
        }

        std::vector<context_view::Entry> next_tracks;
        if (next_arr != nullptr && next_arr->is_array()) {
            for (const auto& item : next_arr->array_value) {
                context_view::Entry entry;
                if (parse_connect_json_track(item, entry, "context") &&
                    !entry.uri.empty() && !entry.is_delimiter()) {
                    next_tracks.push_back(std::move(entry));
                }
            }
        }
        std::vector<context_view::Entry> prev_tracks;
        const bool has_prev_arr = (prev_arr != nullptr && prev_arr->is_array());
        if (has_prev_arr) {
            for (const auto& item : prev_arr->array_value) {
                context_view::Entry entry;
                if (parse_connect_json_track(item, entry, "context") &&
                    !entry.uri.empty() && !entry.is_delimiter()) {
                    prev_tracks.push_back(std::move(entry));
                }
            }
        }
        const auto incoming_rev = parse_json_uint64_or_string(*parsed, "queue_revision");

        QueueChangedCallback qc_cb;
        StateChangedCallback sc_cb;
        std::vector<uint8_t> qc_bytes, sc_bytes;
        ConnectDispatchBundle connect_bundle;
        std::vector<PendingMetadataRequest> pending_metadata;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            transition_to_local_locked();
            record_command_meta_locked();
            if (next_arr != nullptr && next_arr->is_array()) {
                user_queue_.clear();
                std::vector<context_view::Entry> remaining_context;
                for (auto& t : next_tracks) {
                    const auto it = t.metadata.find("is_queued");
                    if ((it != t.metadata.end() && (it->second == "true" || it->second == "True")) ||
                        t.provider == "queue") {
                        t.provider = "queue";
                        t.metadata["is_queued"] = "true";
                        t.metadata["provider"] = "queue";
                        user_queue_.push_back(std::move(t));
                    } else {
                        t.provider = "context";
                        t.metadata["is_queued"] = "false";
                        t.metadata["provider"] = "context";
                        remaining_context.push_back(std::move(t));
                    }
                }
                context_processor_.set_next_tracks_slice(remaining_context);
            }
            if (has_prev_arr) {
                explicit_prev_tracks_ = std::move(prev_tracks);
            }
            if (incoming_rev.has_value() && *incoming_rev > queue_revision_) {
                queue_revision_ = *incoming_rev;
            } else {
                bump_queue_revision_locked();
            }
            decorate_local_queue_locked(pending_metadata);
            emit_queue_locked();
            emit_state_locked();
            qc_cb = queue_changed_callback_;
            qc_bytes = cached_queue_bytes_;
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
        dispatch_metadata_requests(pending_metadata);
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    if (resolved_endpoint == "play_as_next_in_queue") {
        if (!parsed.has_value() || !parsed->is_object()) {
            return false;
        }
        std::vector<context_view::Entry> incoming;
        if (const auto* arr = parsed->find("tracks"); arr != nullptr && arr->is_array()) {
            for (const auto& item : arr->array_value) {
                context_view::Entry entry;
                if (parse_connect_json_track(item, entry, "queue") && !entry.uri.empty()) {
                    entry.provider = "queue";
                    entry.metadata["is_queued"] = "true";
                    entry.metadata["provider"] = "queue";
                    incoming.push_back(std::move(entry));
                }
            }
        } else if (const auto* single = parsed->find("track");
                   single != nullptr && single->is_object()) {
            context_view::Entry entry;
            if (parse_connect_json_track(*single, entry, "queue") && !entry.uri.empty()) {
                entry.provider = "queue";
                entry.metadata["is_queued"] = "true";
                entry.metadata["provider"] = "queue";
                incoming.push_back(std::move(entry));
            }
        }
        if (incoming.empty()) {
            return false;
        }

        QueueChangedCallback qc_cb;
        StateChangedCallback sc_cb;
        std::vector<uint8_t> qc_bytes, sc_bytes;
        ConnectDispatchBundle connect_bundle;
        std::vector<PendingMetadataRequest> pending_metadata;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            transition_to_local_locked();
            record_command_meta_locked();
            user_queue_.insert(user_queue_.begin(), incoming.begin(), incoming.end());
            bump_queue_revision_locked();
            decorate_local_queue_locked(pending_metadata);
            emit_queue_locked();
            emit_state_locked();
            qc_cb = queue_changed_callback_;
            qc_bytes = cached_queue_bytes_;
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
        dispatch_metadata_requests(pending_metadata);
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    if (resolved_endpoint == "update_context") {
        if (!parsed.has_value() || !parsed->is_object()) {
            return false;
        }
        const json::JsonValue* ctx_node = parsed->find("context");
        if (ctx_node == nullptr || !ctx_node->is_object()) {
            ctx_node = &*parsed;
        }
        std::string ctx_uri;
        std::string ctx_url;
        std::unordered_map<std::string, std::string> ctx_md;
        std::unordered_map<std::string, std::string> page_md;
        std::vector<context_view::Entry> tracks;
        std::vector<size_t> page_track_offsets;
        std::string page_url;
        std::string next_page_url;
        parse_connect_json_context_node(
            *ctx_node,
            ctx_uri,
            ctx_url,
            ctx_md,
            page_md,
            tracks,
            page_track_offsets,
            page_url,
            next_page_url);
        if (ctx_uri.empty() && ctx_url.empty() && ctx_md.empty() && page_md.empty() && tracks.empty()) {
            return false;
        }

        StateChangedCallback sc_cb;
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> sc_bytes, qc_bytes;
        ConnectDispatchBundle connect_bundle;
        std::vector<PendingMetadataRequest> pending_metadata;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (!ctx_uri.empty() && !context_uri_.empty() && ctx_uri != context_uri_) {
                PLAYER_REMOTE_LOGW(
                    "Connect update_context URI mismatch (incoming=%s current=%s)",
                    ctx_uri.c_str(),
                    context_uri_.c_str());
                return false;
            }
            transition_to_local_locked();
            record_command_meta_locked();
            if (!ctx_uri.empty()) context_uri_ = std::move(ctx_uri);
            if (!ctx_url.empty()) context_url_ = std::move(ctx_url);
            for (const auto& [k, v] : ctx_md) {
                context_metadata_[k] = v;
            }
            for (const auto& [k, v] : page_md) {
                page_metadata_[k] = v;
            }
            if (!tracks.empty()) {
                int32_t preserve_idx = 0;
                if (current_track_.has_value()) {
                    preserve_idx = resolve_initial_track_index(
                        tracks,
                        current_track_->uid,
                        current_track_->uri,
                        std::nullopt,
                        -1,
                        page_track_offsets);
                }
                context_processor_.set_context(
                    context_uri_, page_url, tracks, next_page_url, preserve_idx);
                context_processor_.set_shuffling(shuffling_);
            }
            bump_queue_revision_locked();
            decorate_local_queue_locked(pending_metadata);
            emit_state_locked();
            emit_queue_locked();
            sc_cb = state_changed_callback_;
            qc_cb = queue_changed_callback_;
            sc_bytes = cached_state_bytes_;
            qc_bytes = cached_queue_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
        dispatch_metadata_requests(pending_metadata);
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    if (resolved_endpoint == "signal") {
        if (!parsed.has_value() || !parsed->is_object()) {
            return false;
        }
        std::string sig_id = parsed->get_string("signal_id").value_or(std::string{});
        if (sig_id.empty()) {
            sig_id = parsed->get_string("signal").value_or(std::string{});
        }
        if (sig_id.empty()) {
            return false;
        }
        const std::string params = parsed->get_string("parameters").value_or(std::string{});
        record_command_meta();
        return apply_signal_value(sig_id, params);
    }
    if (resolved_endpoint == "set_sleep_timer") {
        if (!parsed.has_value() || !parsed->is_object()) {
            return false;
        }
        SleepTimerState next_timer;
        bool valid = false;
        if (parsed->find("clear") != nullptr ||
            parsed->get_string("timer_type").value_or(std::string{}) == "clear") {
            next_timer.mode = SleepTimerMode::kOff;
            next_timer.expires_at_ms = 0;
            valid = true;
        } else if (parsed->find("end_of_track") != nullptr ||
                   parsed->get_string("timer_type").value_or(std::string{}) == "end_of_track") {
            const auto* eot = parsed->find("end_of_track");
            if (eot != nullptr && eot->is_bool() && !eot->bool_value) {
                next_timer.mode = SleepTimerMode::kOff;
                next_timer.expires_at_ms = 0;
            } else {
                next_timer.mode = SleepTimerMode::kEndOfTrack;
                next_timer.expires_at_ms = 0;
            }
            valid = true;
        } else if (const auto* dur_obj = parsed->find("duration");
                   dur_obj != nullptr && dur_obj->is_object()) {
            if (const auto secs = dur_obj->get_int64("seconds"); secs.has_value()) {
                if (*secs <= 0) {
                    next_timer.mode = SleepTimerMode::kOff;
                    next_timer.expires_at_ms = 0;
                } else {
                    next_timer.mode = SleepTimerMode::kDuration;
                    next_timer.expires_at_ms = get_current_timestamp_ms() + (*secs * 1000LL);
                }
                valid = true;
            }
        } else if (const auto secs = parsed->get_int64("duration_seconds"); secs.has_value()) {
            if (*secs <= 0) {
                next_timer.mode = SleepTimerMode::kOff;
                next_timer.expires_at_ms = 0;
            } else {
                next_timer.mode = SleepTimerMode::kDuration;
                next_timer.expires_at_ms = get_current_timestamp_ms() + (*secs * 1000LL);
            }
            valid = true;
        } else if (const auto secs = parsed->get_int64("seconds"); secs.has_value()) {
            if (*secs <= 0) {
                next_timer.mode = SleepTimerMode::kOff;
                next_timer.expires_at_ms = 0;
            } else {
                next_timer.mode = SleepTimerMode::kDuration;
                next_timer.expires_at_ms = get_current_timestamp_ms() + (*secs * 1000LL);
            }
            valid = true;
        } else if (const auto ts_ms = parsed->get_int64("timestamp"); ts_ms.has_value()) {
            if (*ts_ms <= 0) {
                next_timer.mode = SleepTimerMode::kOff;
                next_timer.expires_at_ms = 0;
            } else {
                next_timer.mode = SleepTimerMode::kDuration;
                next_timer.expires_at_ms = *ts_ms;
            }
            valid = true;
        }
        if (!valid) {
            return false;
        }
        record_command_meta();
        apply_sleep_timer_state(next_timer);
        return true;
    }
    if (resolved_endpoint == "play" || resolved_endpoint == "prepare_play") {
        if (!parsed.has_value()) {
            return false;
        }
        const bool is_prepare_play = (resolved_endpoint == "prepare_play");
        const auto* ctx_node = parsed->find("context");
        if (ctx_node != nullptr && !ctx_node->is_object() && !ctx_node->is_null()) {
            return false;
        }
        const bool has_context_obj = (ctx_node != nullptr && ctx_node->is_object());
        std::string ctx_uri;
        std::string ctx_url;
        std::unordered_map<std::string, std::string> ctx_md;
        std::unordered_map<std::string, std::string> page_md;
        std::vector<context_view::Entry> tracks;
        std::vector<size_t> page_track_offsets;
        std::string page_url;
        std::string next_page_url;
        if (has_context_obj) {
            parse_connect_json_context_node(
                *ctx_node,
                ctx_uri,
                ctx_url,
                ctx_md,
                page_md,
                tracks,
                page_track_offsets,
                page_url,
                next_page_url);
        }

        if (tracks.empty()) {
            if (const auto* top_track = parsed->find("track");
                top_track != nullptr && top_track->is_object()) {
                context_view::Entry entry;
                if (parse_connect_json_track(*top_track, entry, "context") && !entry.uri.empty()) {
                    tracks.push_back(std::move(entry));
                }
            }
        }

        bool initially_paused = is_prepare_play;
        int64_t seek_to_ms = parsed->get_int64("seek_to").value_or(0);
        std::string skip_to_uri;
        std::string skip_to_uid;
        std::optional<int64_t> skip_to_page_index;
        int64_t skip_to_index = -1;
        std::optional<bool> shuf_override;
        std::optional<bool> rep_ctx_override;
        std::optional<bool> rep_trk_override;
        std::optional<double> speed_override;

        if (const auto* opts = parsed->find("options");
            opts != nullptr && opts->is_object()) {
            if (!is_prepare_play) {
                initially_paused = opts->get_bool("initially_paused").value_or(false);
            }
            if (const auto opt_seek = opts->get_int64("seek_to"); opt_seek.has_value()) {
                seek_to_ms = *opt_seek;
            }
            if (const auto* skip_to = opts->find("skip_to");
                skip_to != nullptr && skip_to->is_object()) {
                skip_to_uri = skip_to->get_string("track_uri").value_or(std::string{});
                skip_to_uid = skip_to->get_string("track_uid").value_or(std::string{});
                if (const auto pi = skip_to->get_int64("page_index"); pi.has_value()) {
                    skip_to_page_index = *pi;
                }
                if (const auto ti = skip_to->get_int64("track_index"); ti.has_value()) {
                    skip_to_index = *ti;
                }
            }
            if (const auto* ov = opts->find("player_options_override");
                ov != nullptr && ov->is_object()) {
                shuf_override = ov->get_bool("shuffling_context");
                rep_ctx_override = ov->get_bool("repeating_context");
                rep_trk_override = ov->get_bool("repeating_track");
                if (const auto spd = ov->get_double("playback_speed");
                    spd.has_value() && *spd > 0.0) {
                    speed_override = *spd;
                }
            }
        }
        if (seek_to_ms < 0) {
            seek_to_ms = 0;
        }

        // URI-only play / prepare_play: resolve context tracks via ContextResolveClient OUTSIDE mutex_.
        bool same_loaded_context = false;
        if (tracks.empty() && has_context_obj && (!ctx_uri.empty() || !ctx_url.empty())) {
            {
                std::lock_guard<std::mutex> lock(mutex_);
                const bool uri_matches =
                    (!ctx_uri.empty() && ctx_uri == context_uri_) ||
                    (ctx_uri.empty() && !ctx_url.empty() && ctx_url == context_url_);
                same_loaded_context =
                    uri_matches && context_processor_.get_current_track().has_value();
            }
            if (!same_loaded_context) {
                const std::string& resolve_target = !ctx_url.empty() ? ctx_url : ctx_uri;
                PLAYER_REMOTE_LOGI(
                    "Connect %s resolving URI-only context target=%s",
                    resolved_endpoint.c_str(),
                    sanitize_url_for_log(resolve_target).c_str());
                const ContextResolveResult resolved = context_resolve_client_.resolve(resolve_target);
                if (resolved.ok && resolved.context.has_value()) {
                    const auto& rctx = *resolved.context;
                    if (ctx_uri.empty() && !rctx.uri.empty()) ctx_uri = rctx.uri;
                    if (ctx_url.empty() && !rctx.url.empty()) ctx_url = rctx.url;
                    for (const auto& [k, v] : rctx.metadata) {
                        if (ctx_md.find(k) == ctx_md.end()) {
                            ctx_md[k] = v;
                        }
                    }
                    if (!rctx.pages.empty() && page_md.empty()) {
                        page_md = rctx.pages.front().metadata;
                    }
                    tracks = rctx.all_tracks;
                    page_track_offsets = rctx.page_track_offsets;
                    page_url = rctx.first_page_url;
                    next_page_url = rctx.first_next_page_url;
                } else {
                    PLAYER_REMOTE_LOGW(
                        "Connect %s context resolve failed (%s) target=%s",
                        resolved_endpoint.c_str(),
                        resolved.error_message.c_str(),
                        sanitize_url_for_log(resolve_target).c_str());
                    if (skip_to_uri.empty()) {
                        std::lock_guard<std::mutex> lock(mutex_);
                        last_error_ = "CONTEXT_RESOLVE_FAILED";
                        return false;
                    }
                }
            }
        }

        if (tracks.empty() && !same_loaded_context && !skip_to_uri.empty()) {
            context_view::Entry entry;
            entry.uri = skip_to_uri;
            entry.uid = !skip_to_uid.empty() ? skip_to_uid : generate_track_uid();
            entry.provider = "context";
            tracks.push_back(std::move(entry));
        }

        if (tracks.empty() && !has_context_obj) {
            const auto* top_track = parsed->find("track");
            if (top_track != nullptr || is_prepare_play) {
                return false;
            }
            record_command_meta();
            return resume();
        }
        if (has_context_obj && tracks.empty() && ctx_uri.empty() && ctx_url.empty()) {
            return false;
        }

        std::shared_ptr<rendering::TrackPlayer> tp;
        context_view::Entry track_to_play;
        bool should_stop_player = false;
        uint64_t sync_token = 0;
        StateChangedCallback sc_cb;
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> sc_bytes, qc_bytes;
        ConnectDispatchBundle connect_bundle;
        std::vector<PendingMetadataRequest> pending_metadata;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            transition_to_local_locked();
            record_command_meta_locked();
            const std::string prev_context_uri = context_uri_;
            const std::string prev_context_url = context_url_;
            const bool context_changed =
                (ctx_uri != prev_context_uri) ||
                ((ctx_uri.empty() || (!ctx_url.empty() && !prev_context_url.empty())) &&
                 ctx_url != prev_context_url);
            if (!tracks.empty() || context_changed) {
                context_uri_ = std::move(ctx_uri);
                context_url_ = std::move(ctx_url);
                context_metadata_ = std::move(ctx_md);
                page_metadata_ = std::move(page_md);
            } else {
                if (!ctx_url.empty()) {
                    context_url_ = std::move(ctx_url);
                }
                if (!ctx_md.empty()) {
                    context_metadata_ = std::move(ctx_md);
                }
                if (!page_md.empty()) {
                    page_metadata_ = std::move(page_md);
                }
            }
            if (const auto* po = parsed->find("play_origin");
                po != nullptr && po->is_object()) {
                parse_connect_json_play_origin(*po, play_origin_);
            }
            std::string incoming_session_id;
            if (const auto* opts = parsed->find("options"); opts != nullptr && opts->is_object()) {
                if (const auto sid = opts->get_string("session_id");
                    sid.has_value() && !sid->empty()) {
                    incoming_session_id = *sid;
                }
            }
            session_id_ = !incoming_session_id.empty()
                              ? std::move(incoming_session_id)
                              : generate_track_uid();
            apply_repeat_overrides_locked(rep_ctx_override, rep_trk_override);
            if (speed_override.has_value()) {
                playback_speed_ = *speed_override;
            }
            if (!tracks.empty()) {
                const int32_t init_idx = resolve_initial_track_index(
                    tracks,
                    skip_to_uid,
                    skip_to_uri,
                    skip_to_page_index,
                    skip_to_index,
                    page_track_offsets);
                if (shuf_override.has_value()) {
                    shuffling_ = *shuf_override;
                }
                if (!shuffling_) {
                    context_processor_.set_shuffling(false);
                }
                context_processor_.set_context(
                    context_uri_, page_url, tracks, next_page_url, init_idx);
                context_processor_.set_shuffling(shuffling_);
            } else if (has_context_obj) {
                if (context_changed) {
                    context_processor_.clear();
                    if (shuf_override.has_value()) {
                        shuffling_ = *shuf_override;
                    }
                    context_processor_.set_shuffling(shuffling_);
                } else {
                    if (shuf_override.has_value() && !*shuf_override) {
                        shuffling_ = false;
                        context_processor_.set_shuffling(false);
                    }
                    if (!skip_to_uid.empty()) {
                        context_processor_.skip_to_uid(skip_to_uid);
                    } else if (!skip_to_uri.empty()) {
                        context_processor_.skip_to_uri(skip_to_uri);
                    } else if (skip_to_index >= 0 &&
                               skip_to_index <= static_cast<int64_t>(INT32_MAX) &&
                               (!skip_to_page_index.has_value() || *skip_to_page_index == 0)) {
                        context_processor_.skip_to_index(static_cast<int32_t>(skip_to_index));
                    }
                    if (shuf_override.has_value() && *shuf_override) {
                        shuffling_ = true;
                        context_processor_.set_shuffling(true);
                    }
                }
            }
            bump_queue_revision_locked();
            if (const auto resolved_cur = context_processor_.get_current_track();
                resolved_cur.has_value() && !resolved_cur->uri.empty()) {
                begin_track_transition_locked(
                    *resolved_cur,
                    initially_paused ? SessionPlaybackPhase::Paused
                                     : SessionPlaybackPhase::BufferingPlay);
                position_ms_ = seek_to_ms;
                decorate_local_queue_locked(pending_metadata);
                track_to_play = *current_track_;
                tp = track_player_;
                if (tp) {
                    sync_token = ++next_player_sync_token_;
                    pending_player_sync_token_ = sync_token;
                }
            } else {
                current_track_.reset();
                explicit_prev_tracks_.reset();
                playback_id_.clear();
                playback_phase_ = SessionPlaybackPhase::Idle;
                position_ms_ = 0;
                duration_ms_ = 0;
                decorate_local_queue_locked(pending_metadata);
                tp = track_player_;
                should_stop_player = true;
                if (tp) {
                    sync_token = ++next_player_sync_token_;
                    pending_player_sync_token_ = sync_token;
                }
            }
            emit_state_locked(false);
            emit_queue_locked();
            sc_cb = state_changed_callback_;
            qc_cb = queue_changed_callback_;
            sc_bytes = cached_state_bytes_;
            qc_bytes = cached_queue_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
        dispatch_metadata_requests(pending_metadata);
        if (tp && should_stop_player) {
            tp->stop(rendering::StopReason::ContextEnded);
            clear_pending_player_sync(sync_token);
        }
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        if (tp && !should_stop_player && !track_to_play.uri.empty()) {
            if (speed_override.has_value()) {
                tp->setPlaybackSpeed(*speed_override);
            }
            tp->start(
                track_to_play,
                is_prepare_play ? rendering::StartReason::PreparePlay
                                : rendering::StartReason::PlayCommand,
                seek_to_ms,
                initially_paused);
            clear_pending_player_sync(sync_token);
        }
        return true;
    }

    PLAYER_REMOTE_LOGW("Unhandled inbound Connect command endpoint=%s", resolved_endpoint.c_str());
    return false;
}

void ContextPlayerImpl::emit_queue_locked() {
    if (origin_ == PlaybackOrigin::kRemoteMirrored) {
        const context_view::Entry* cur_ptr =
            mirrored_state_.current_track.has_value()
                ? &mirrored_state_.current_track.value()
                : nullptr;
        cached_queue_bytes_ = StateEmitter::encode_queue(
            cur_ptr,
            mirrored_state_.next_tracks,
            mirrored_state_.prev_tracks,
            mirrored_state_.queue_revision);
        return;
    }

    std::vector<context_view::Entry> combined_next;
    combined_next.reserve(user_queue_.size() + 50);

    // User-enqueued tracks precede context tracks in Spotify queue semantics
    combined_next.insert(combined_next.end(), user_queue_.begin(), user_queue_.end());

    // Context lookahead tracks
    const auto ctx_next = context_processor_.get_next_tracks(50);
    combined_next.insert(combined_next.end(), ctx_next.begin(), ctx_next.end());

    const auto prev_tracks = explicit_prev_tracks_.has_value()
                                 ? *explicit_prev_tracks_
                                 : context_processor_.get_prev_tracks();
    const context_view::Entry* cur_ptr = current_track_.has_value() ? &current_track_.value() : nullptr;

    cached_queue_bytes_ = StateEmitter::encode_queue(
        cur_ptr,
        combined_next,
        prev_tracks,
        queue_revision_);
}

}  // namespace spotify::player
