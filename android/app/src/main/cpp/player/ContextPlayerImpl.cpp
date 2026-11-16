// ============================================================================
// 1:1 Replicated Spotify ContextPlayerImpl & Connect Bidirectional Hooks
// Sources:
// - `liborbit-jni-spotify.so` ContextPlayerImpl command/state dispatcher & Connect state sync
// - `liborbit-jni-spotify.so` ELF FileDescriptorProto `player.proto` (`0x635f80`)
// ============================================================================

#include "ContextPlayerImpl.h"

#ifdef __ANDROID__
#include <android/log.h>
#define LOG_TAG "ContextPlayer"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#else
#define LOGI(...) ((void)0)
#define LOGE(...) ((void)0)
#define LOGW(...) ((void)0)
#endif

#include <algorithm>
#include <chrono>
#include <climits>
#include <cstdlib>
#include <cstring>
#include <iterator>

#include "../connect/DealerWebSocketClient.h"

namespace spotify::player {

namespace {

inline int64_t get_current_timestamp_ms() noexcept {
    const auto now = std::chrono::system_clock::now();
    return std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count();
}

struct SkipToOptions {
    std::string track_uri;
    std::string track_uid;
    std::optional<int64_t> page_index;
    int64_t track_index{-1};
};

struct OptionOverrides {
    std::optional<bool> shuffling_context;
    std::optional<bool> repeating_context;
    std::optional<bool> repeating_track;
};

struct DecodedPreparePlay {
    std::string context_uri;
    std::string context_url;
    std::unordered_map<std::string, std::string> context_metadata;
    std::vector<context_view::Entry> tracks;
    std::vector<size_t> page_track_offsets;
    std::string page_url;
    std::string next_page_url;
    SkipToOptions skip_to;
    OptionOverrides overrides;
    std::string session_id;
    PlayOriginData play_origin;
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
            uint32_t f = static_cast<uint32_t>(tag >> 3);
            uint32_t w = static_cast<uint32_t>(tag & 0x07);
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
            uint32_t f = static_cast<uint32_t>(tag >> 3);
            uint32_t w = static_cast<uint32_t>(tag & 0x07);
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
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
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

// Field numbers verified 1:1 against Spotify EsSkipToTrack$SkipToTrack.java:
// Field 1: page_url, Field 2: page_index, Field 3: track_uid, Field 4: track_uri, Field 5: track_index
inline bool decode_skip_to(const uint8_t* ptr, size_t len, SkipToOptions& skip_to) {
    if (ptr == nullptr) return len == 0;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1) {
            if (w != 2) return false;
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            const size_t n = static_cast<size_t>(l);
            std::string page_url(reinterpret_cast<const char*>(p), n);
            if (!is_valid_utf8_string(page_url)) return false;
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

// Field numbers verified 1:1 against Spotify EsContextPlayerOptions$ContextPlayerOptionOverrides.java:
// Field 1: shuffling_context, Field 2: repeating_context, Field 3: repeating_track, Field 4: playback_speed, Field 5: modes
inline bool decode_option_overrides(const uint8_t* ptr, size_t len, OptionOverrides& overrides) {
    if (ptr == nullptr) return len == 0;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
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
            if (w != 2 && w != 1) return false;
            if (!skip_field(p, end, w)) return false;
        } else if (f == 5) {
            if (w != 2) return false;
            if (!skip_field(p, end, w)) return false;
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

// Field numbers verified 1:1 against Spotify EsPlayOrigin$PlayOrigin.java:
// Field 1: feature_identifier, Field 2: feature_version, Field 3: view_uri, Field 4: external_referrer,
// Field 5: referrer_identifier, Field 6: device_identifier, Field 7: feature_classes, Field 8: restriction_identifier
inline bool decode_play_origin(const uint8_t* ptr, size_t len, PlayOriginData& out) {
    if (ptr == nullptr) return len == 0;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
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

// Field numbers verified 1:1 against Spotify EsPreparePlayOptions$PreparePlayOptions.java:
// Field 1: playback_id, Field 2: always_play_something, Field 3: skip_to (SkipToTrack),
// Field 4: seek_to, Field 5: initially_paused, Field 6: system_initiated,
// Field 7: player_options_override (ContextPlayerOptionOverrides), Field 8: suppressions,
// Field 9: prefetch_level, Field 10: audio_stream, Field 11: session_id (string),
// Field 12: license, Field 13: configuration_override, Field 14: seek_to_creator_timestamp
inline bool decode_prepare_play_options(const uint8_t* ptr, size_t len, DecodedPreparePlay& out) {
    if (ptr == nullptr) return len == 0;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 || f == 3 || f == 4 || f == 7 || f == 8 ||
            f == 11 || f == 12 || f == 13 || f == 14) {
            if (w != 2) return false;
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) return false;
            const size_t n = static_cast<size_t>(l);
            if (f == 3) {
                if (!decode_skip_to(p, n, out.skip_to)) return false;
            } else if (f == 7) {
                if (!decode_option_overrides(p, n, out.overrides)) return false;
            } else if (f == 11) {
                out.session_id.assign(reinterpret_cast<const char*>(p), n);
                if (!is_valid_utf8_string(out.session_id)) return false;
            }
            p += n;
        } else if (f == 2 || f == 5 || f == 6 || f == 9 || f == 10) {
            if (w != 0) return false;
            uint64_t dummy = 0;
            if (!decode_varint(p, end, dummy)) return false;
        } else {
            if (!skip_field(p, end, w)) return false;
        }
    }
    return true;
}

// Field numbers verified 1:1 against Spotify EsContext$Context.java:
// Field 1: pages (repeated ContextPage), Field 2: metadata (map), Field 3: uri (string),
// Field 4: url (string), Field 5: is_loading (bool), Field 6: restrictions (Restrictions)
inline bool decode_context_submessage(const uint8_t* ptr, size_t len, DecodedPreparePlay& out) {
    if (ptr == nullptr) return len == 0;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 || f == 2 || f == 3 || f == 4 || f == 6) {
            if (w != 2) return false;
            uint64_t sub_len = 0;
            if (!decode_varint(p, end, sub_len) || !has_bytes(p, end, sub_len)) return false;
            const size_t n = static_cast<size_t>(sub_len);
            if (f == 1) { // Field 1: pages (repeated ContextPage)
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
                    out.page_url = std::move(page_url);
                    out.next_page_url = std::move(next_page_url);
                }
                out.page_track_offsets.push_back(out.tracks.size());
                out.tracks.insert(
                    out.tracks.end(),
                    std::make_move_iterator(valid_tracks.begin()),
                    std::make_move_iterator(valid_tracks.end()));
            } else if (f == 2) { // Field 2: metadata (map<string,string>)
                if (!decode_map_entries(p, n, out.context_metadata)) return false;
            } else if (f == 3) { // Field 3: uri (string)
                out.context_uri.assign(reinterpret_cast<const char*>(p), n);
                if (!out.context_uri.empty() && !is_valid_utf8_uri(out.context_uri)) {
                    return false;
                }
            } else if (f == 4) { // Field 4: url (string)
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

// Field numbers verified 1:1 against Spotify EsPreparePlay$PreparePlayRequest.java:
// Field 1: context (Context), Field 2: options (PreparePlayOptions), Field 3: play_origin (PlayOrigin)
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
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f >= 1 && f <= 3) {
            if (w != 2) return false;
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || !has_bytes(ptr, end, len)) return false;
            const size_t n = static_cast<size_t>(len);
            if (f == 1) { // Field 1: Context
                if (!decode_context_submessage(ptr, n, out)) return false;
            } else if (f == 2) { // Field 2: PreparePlayOptions
                if (!decode_prepare_play_options(ptr, n, out)) return false;
            } else if (f == 3) { // Field 3: PlayOrigin
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

inline bool validate_play_options_submessage(const uint8_t* ptr, size_t len) noexcept {
    if (ptr == nullptr) return len == 0;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f >= 1 && f <= 3) {
            if (w != 0) return false;
        } else if (f == 4) {
            if (w != 5) return false;
        }
        if (!skip_field(p, end, w)) return false;
    }
    return true;
}

inline bool validate_command_options_submessage(const uint8_t* ptr, size_t len) noexcept {
    if (ptr == nullptr) return len == 0;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f >= 1 && f <= 3) {
            if (w != 0) return false;
        } else if (f == 4) {
            if (w != 2) return false;
        }
        if (!skip_field(p, end, w)) return false;
    }
    return true;
}

inline bool validate_logging_params_submessage(const uint8_t* ptr, size_t len) noexcept {
    if (ptr == nullptr) return len == 0;
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) return false;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f >= 1 && f <= 6 && w != 2) {
            return false;
        }
        if (!skip_field(p, end, w)) return false;
    }
    return true;
}

// Unwraps PlayRequest (Field 1 = PreparePlayRequest) or decodes PreparePlayRequest directly
inline bool parse_prepare_play_request(const uint8_t* data, size_t size, DecodedPreparePlay& out) {
    if (!data || size == 0) return false;

    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    const uint8_t* f1_ptr = nullptr;
    size_t f1_len = 0;
    bool outer_valid_play_request = true;
    bool has_play_request_logging_params = false;

    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) {
            outer_valid_play_request = false;
            break;
        }
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
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
                if (!validate_play_options_submessage(ptr, n)) {
                    outer_valid_play_request = false;
                    break;
                }
            } else if (f == 3) {
                if (!validate_command_options_submessage(ptr, n)) {
                    outer_valid_play_request = false;
                    break;
                }
            } else if (f == 4) {
                if (validate_logging_params_submessage(ptr, n)) {
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

    DecodedPreparePlay direct;
    bool dir_has_extra = false;
    const bool ok_direct = decode_prepare_play_request_body(data, size, direct, dir_has_extra);

    if (ok_candidate && has_play_request_logging_params) {
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
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
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
        } else if (!inner.metadata["provider"].empty()) {
            inner.provider = inner.metadata["provider"];
        }
        out_entry = std::move(inner);
        return true;
    }

    // 2. Try decoding directly as bare ContextTrack
    context_view::Entry direct;
    if (decode_context_track(data, size, direct) && is_valid_utf8_uri(direct.uri)) {
        if (!direct.metadata["provider"].empty()) {
            direct.provider = direct.metadata["provider"];
        }
        out_entry = std::move(direct);
        return true;
    }

    return false;
}

// Field numbers verified 1:1 against Spotify EsSetQueueRequest$SetQueueRequest.java:
// Field 1: next_tracks (repeated ProvidedTrack/ContextTrack), Field 2: prev_tracks, Field 3: queue_revision (int64)
inline bool decode_set_queue_request(
        const uint8_t* data,
        size_t size,
        std::vector<context_view::Entry>& out_tracks,
        int64_t& out_rev) {
    if (data == nullptr) return size == 0;
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 2) {
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || !has_bytes(ptr, end, len)) break;
            const size_t n = static_cast<size_t>(len);
            context_view::Entry entry;
            if (decode_track_or_provided_track(ptr, n, entry)) {
                out_tracks.push_back(std::move(entry));
            }
            ptr += n;
        } else if (f == 3) {
            decode_int64_value(ptr, end, w, out_rev);
        } else {
            if (!skip_field(ptr, end, w)) break;
        }
    }
    return true;
}

// Field numbers verified 1:1 against Spotify EsSetOptions$SetOptionsRequest.java:
// Field 1: repeating_track (OptionalBoolean), Field 2: repeating_context (OptionalBoolean), Field 3: shuffling_context (OptionalBoolean)
inline bool decode_set_options_request(const uint8_t* data, size_t size, OptionOverrides& out_opts) {
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1) {
            bool v = false;
            if (decode_bool_value(ptr, end, w, v)) out_opts.repeating_track = v;
        } else if (f == 2) {
            bool v = false;
            if (decode_bool_value(ptr, end, w, v)) out_opts.repeating_context = v;
        } else if (f == 3) {
            bool v = false;
            if (decode_bool_value(ptr, end, w, v)) out_opts.shuffling_context = v;
        } else {
            if (!skip_field(ptr, end, w)) break;
        }
    }
    return true;
}

// Field numbers verified 1:1 against es_delete_session.pb.dart (DeleteSessionRequest):
// Field 1: session_id (string)
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

inline bool decode_single_bool(const uint8_t* data, size_t size, bool& out_val) {
    if (!data || size == 0) return false;
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;

    uint64_t tag_or_val = 0;
    if (!decode_varint(ptr, end, tag_or_val)) return false;
    if (ptr == end) {
        out_val = (tag_or_val != 0);
        return true;
    }

    ptr = data;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1) {
            return decode_bool_value(ptr, end, w, out_val);
        }
        if (!skip_field(ptr, end, w)) break;
    }
    return false;
}

inline bool decode_single_int64(const uint8_t* data, size_t size, int64_t& out_val) {
    if (!data || size == 0) return false;
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;

    uint64_t tag_or_val = 0;
    if (!decode_varint(ptr, end, tag_or_val)) return false;
    if (ptr == end) {
        out_val = static_cast<int64_t>(tag_or_val);
        return true;
    }

    ptr = data;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1) {
            return decode_int64_value(ptr, end, w, out_val);
        }
        if (!skip_field(ptr, end, w)) break;
    }
    return false;
}

// Field numbers verified 1:1 against Spotify EsSeekTo$SeekToRequest.java:
// Field 1: options (CommandOptions), Field 2: logging_params (LoggingParams), Field 3: position (int64)
inline bool decode_seek_to_request(const uint8_t* data, size_t size, int64_t& out_val) {
    if (!data || size == 0) return false;
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;

    uint64_t tag_or_val = 0;
    if (!decode_varint(ptr, end, tag_or_val)) return false;
    if (ptr == end) {
        out_val = static_cast<int64_t>(tag_or_val);
        return true;
    }

    ptr = data;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 3) { // Field 3: position (int64)
            return decode_int64_value(ptr, end, w, out_val);
        }
        if (f == 1 && w == 0) { // Direct int64 value fallback
            return decode_int64_value(ptr, end, w, out_val);
        }
        if (!skip_field(ptr, end, w)) break;
    }
    return false;
}

inline bool decode_single_string(const uint8_t* data, size_t size, std::string& out_str) {
    if (!data || size == 0) return false;
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
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

} // anonymous namespace

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
}

ContextPlayerImpl::ContextPlayerImpl(std::shared_ptr<rendering::TrackPlayer> track_player)
    : track_player_(std::move(track_player)) {
    LOGI("ContextPlayerImpl initialized (track_player=%p)", track_player_.get());
    if (track_player_) {
        bind_track_player_callbacks(track_player_);
    }
}

ContextPlayerImpl::~ContextPlayerImpl() {
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

void ContextPlayerImpl::bind_track_player_callbacks(
    const std::shared_ptr<rendering::TrackPlayer>& tp) {
    rendering::TrackPlayerCallbacks cbs;
    cbs.peek_track = [this](bool /*playable_only*/) -> std::optional<context_view::Entry> {
        std::lock_guard<std::mutex> lock(mutex_);
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
        if (pending_player_sync_token_ != 0) {
            return;
        }
        playback_phase_ = map_track_player_state_to_phase(state);
        if (state.position_ms >= 0) {
            position_ms_ = state.position_ms;
        }
        if (state.duration_ms > 0) {
            duration_ms_ = state.duration_ms;
        }
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
}

void ContextPlayerImpl::apply_track_info_locked(
    context_view::Entry& track,
    const metadata::TrackInfo& info) {
    auto set_if_missing = [&track](const char* key, const std::string& val) {
        if (val.empty()) return;
        auto it = track.metadata.find(key);
        if (it == track.metadata.end() || it->second.empty()) {
            track.metadata[key] = val;
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
}

void ContextPlayerImpl::on_track_metadata_resolved(
    const std::string& uri,
    const metadata::TrackInfo& info) {
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes;
    std::vector<uint8_t> qc_bytes;
    ConnectDispatchBundle connect_bundle;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (resolved_track_info_cache_.size() >= 128 &&
            resolved_track_info_cache_.find(uri) == resolved_track_info_cache_.end()) {
            resolved_track_info_cache_.erase(resolved_track_info_cache_.begin());
        }
        resolved_track_info_cache_[uri] = info;

        if (!current_track_.has_value() || current_track_->uri != uri) {
            return;
        }
        const auto masked_it = current_track_->metadata.find("musify_vault_masked");
        const bool is_vault_masked =
            (masked_it != current_track_->metadata.end() && masked_it->second == "true");

        if (!is_vault_masked) {
            apply_track_info_locked(*current_track_, info);
        }
        if (info.duration_ms > 0) {
            if (duration_ms_ <= 0) {
                duration_ms_ = info.duration_ms;
            }
            auto dur_it = current_track_->metadata.find("duration");
            if (dur_it == current_track_->metadata.end() || dur_it->second.empty()) {
                current_track_->metadata["duration"] = std::to_string(info.duration_ms);
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

    std::shared_ptr<rendering::TrackPlayer> tp;
    context_view::Entry track_to_play;
    bool should_stop_player = false;
    uint64_t sync_token = 0;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;
    ConnectDispatchBundle connect_bundle;

    {
        std::lock_guard<std::mutex> lock(mutex_);

        context_uri_ = parsed.context_uri;
        context_url_ = parsed.context_url;
        context_metadata_ = parsed.context_metadata;
        play_origin_ = parsed.play_origin;
        if (!parsed.session_id.empty()) {
            session_id_ = parsed.session_id;
        }

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

        if (const auto resolved_cur = context_processor_.get_current_track();
            resolved_cur.has_value() && !resolved_cur->uri.empty()) {
            begin_track_transition_locked(*resolved_cur, SessionPlaybackPhase::BufferingPlay);
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
            playback_id_.clear();
            playback_phase_ = SessionPlaybackPhase::Idle;
            position_ms_ = 0;
            duration_ms_ = 0;
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

    if (tp && should_stop_player) {
        tp->stop(rendering::StopReason::ContextEnded);
        clear_pending_player_sync(sync_token);
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
    if (tp && !should_stop_player && !track_to_play.uri.empty()) {
        tp->start(track_to_play, rendering::StartReason::PlayCommand, 0, false);
        clear_pending_player_sync(sync_token);
    }
    return true;
}

bool ContextPlayerImpl::pause() {
    std::shared_ptr<rendering::TrackPlayer> tp;
    {
        std::lock_guard<std::mutex> lock(mutex_);
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
        decode_seek_to_request(payload, len, pos);
    }
    return seek_to(pos);
}

bool ContextPlayerImpl::skip_next(const uint8_t* payload, size_t len) {
    bool override_restrictions = false;
    context_view::Entry target_track;
    if (payload && len > 0) {
        LOGI("ContextPlayerImpl.skipNext: payload_len=%zu", len);
        const uint8_t* p = payload;
        const uint8_t* end = payload + len;
        while (p < end) {
            uint64_t tag = 0;
            if (!decode_varint(p, end, tag)) break;
            uint32_t f = static_cast<uint32_t>(tag >> 3);
            uint32_t w = static_cast<uint32_t>(tag & 0x07);
            if (f == 1 && w == 2) {
                uint64_t l = 0;
                if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) break;
                const size_t n = static_cast<size_t>(l);
                const uint8_t* opt_p = p;
                const uint8_t* opt_end = p + n;
                while (opt_p < opt_end) {
                    uint64_t opt_tag = 0;
                    if (!decode_varint(opt_p, opt_end, opt_tag)) break;
                    uint32_t opt_f = static_cast<uint32_t>(opt_tag >> 3);
                    uint32_t opt_w = static_cast<uint32_t>(opt_tag & 0x07);
                    if (opt_f == 1) {
                        decode_bool_value(opt_p, opt_end, opt_w, override_restrictions);
                    } else {
                        if (!skip_field(opt_p, opt_end, opt_w)) break;
                    }
                }
                p += n;
            } else if (f == 3 && w == 2) {
                uint64_t l = 0;
                if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) break;
                const size_t n = static_cast<size_t>(l);
                decode_context_track(p, n, target_track);
                p += n;
            } else {
                if (!skip_field(p, end, w)) break;
            }
        }
    }

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

    {
        std::lock_guard<std::mutex> lock(mutex_);
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
                    queue_revision_++;
                    begin_track_transition_locked(selected, SessionPlaybackPhase::BufferingPlay);
                    next_track = *current_track_;
                    should_play = true;
                    handled_target = true;
                } else {
                    bool found = false;
                    if (!target_track.uid.empty()) {
                        found = context_processor_.skip_to_uid(target_track.uid);
                    } else if (!target_track.uri.empty() && target_track.provider != "queue") {
                        found = context_processor_.skip_to_uri(target_track.uri);
                    }
                    if (found) {
                        auto track = context_processor_.get_current_track();
                        if (track.has_value()) {
                            queue_revision_++;
                            begin_track_transition_locked(*track, SessionPlaybackPhase::BufferingPlay);
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
                    queue_revision_++;
                    begin_track_transition_locked(queued_front, SessionPlaybackPhase::BufferingPlay);
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
                            begin_track_transition_locked(*track, SessionPlaybackPhase::BufferingPlay);
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

bool ContextPlayerImpl::skip_prev(const uint8_t* payload, size_t len) {
    bool override_restrictions = false;
    bool allow_seeking = true;
    context_view::Entry target_track;
    if (payload && len > 0) {
        LOGI("ContextPlayerImpl.skipPrev: payload_len=%zu", len);
        const uint8_t* p = payload;
        const uint8_t* end = payload + len;
        while (p < end) {
            uint64_t tag = 0;
            if (!decode_varint(p, end, tag)) break;
            uint32_t f = static_cast<uint32_t>(tag >> 3);
            uint32_t w = static_cast<uint32_t>(tag & 0x07);
            if (f == 1 && w == 2) {
                uint64_t l = 0;
                if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) break;
                const size_t n = static_cast<size_t>(l);
                const uint8_t* opt_p = p;
                const uint8_t* opt_end = p + n;
                while (opt_p < opt_end) {
                    uint64_t opt_tag = 0;
                    if (!decode_varint(opt_p, opt_end, opt_tag)) break;
                    uint32_t opt_f = static_cast<uint32_t>(opt_tag >> 3);
                    uint32_t opt_w = static_cast<uint32_t>(opt_tag & 0x07);
                    if (opt_f == 1) {
                        decode_bool_value(opt_p, opt_end, opt_w, override_restrictions);
                    } else {
                        if (!skip_field(opt_p, opt_end, opt_w)) break;
                    }
                }
                p += n;
            } else if (f == 2) {
                decode_bool_value(p, end, w, allow_seeking);
            } else if (f == 4 && w == 2) {
                uint64_t l = 0;
                if (!decode_varint(p, end, l) || !has_bytes(p, end, l)) break;
                const size_t n = static_cast<size_t>(l);
                decode_context_track(p, n, target_track);
                p += n;
            } else {
                if (!skip_field(p, end, w)) break;
            }
        }
    }

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

    bool restart_track_only = false;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!override_restrictions && !restrictions_engine_.get_custom_disallow_skipping_prev().empty()) {
            LOGW("ContextPlayer: SkipPrev restricted by custom policy");
            last_error_ = "SKIP_TO_PREV_RESTRICTED";
            err_cb = error_callback_;
        } else {
            tp = track_player_;
            const int64_t current_pos =
                (tp && pending_player_sync_token_ == 0) ? tp->getPosition() : position_ms_;
            if (allow_seeking && current_track_.has_value() && current_pos > 3000) {
                LOGI("ContextPlayer RoutingTrackPlayer: Seeking to 0 ms (skip_prev restart pos=%lld)",
                     static_cast<long long>(current_pos));
                should_seek_zero = true;
                restart_track_only = true;
            } else {
                bool advanced = false;
                if (!target_track.uid.empty()) {
                    advanced = context_processor_.skip_to_uid(target_track.uid);
                } else if (!target_track.uri.empty()) {
                    advanced = context_processor_.skip_to_uri(target_track.uri);
                } else {
                    advanced = context_processor_.skip_prev();
                }

                if (advanced) {
                    auto track = context_processor_.get_current_track();
                    if (track.has_value()) {
                        begin_track_transition_locked(*track, SessionPlaybackPhase::BufferingPlay);
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

void ContextPlayerImpl::advance_to_next_track(rendering::AdvanceReason reason) {
    std::shared_ptr<rendering::TrackPlayer> tp;
    context_view::Entry next_track;
    bool should_play = false;
    bool should_repeat_current = false;
    bool should_stop_context = false;
    uint64_t sync_token = 0;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;
    ConnectDispatchBundle connect_bundle;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        tp = track_player_;
        LOGI("drain_on_end_of_stream: end-of-stream, track_finished_playing");
        LOGI("ContextPlayerImpl.advanceToNextTrack (reason=%d)", static_cast<int>(reason));

        if (repeat_mode_ == SessionRepeatMode::Track &&
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
                queue_revision_++;
                begin_track_transition_locked(queued_front, SessionPlaybackPhase::BufferingPlay);
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
                        begin_track_transition_locked(*track, SessionPlaybackPhase::BufferingPlay);
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
    OptionOverrides overrides;
    if (decode_set_options_request(payload, len, overrides)) {
        StateChangedCallback sc_cb;
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> sc_bytes, qc_bytes;
        ConnectDispatchBundle connect_bundle;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (overrides.shuffling_context.has_value()) {
                shuffling_ = *overrides.shuffling_context;
                context_processor_.set_shuffling(shuffling_);
            }
            apply_repeat_overrides_locked(
                overrides.repeating_context,
                overrides.repeating_track);
            emit_state_locked();
            emit_queue_locked();
            sc_cb = state_changed_callback_;
            qc_cb = queue_changed_callback_;
            sc_bytes = cached_state_bytes_;
            qc_bytes = cached_queue_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    return false;
}

bool ContextPlayerImpl::set_shuffling_context(const uint8_t* payload, size_t len) {
    bool val = false;
    if (decode_single_bool(payload, len, val)) {
        set_shuffling_context(val);
        return true;
    }
    return false;
}

void ContextPlayerImpl::set_shuffling_context(bool shuffling) {
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;
    ConnectDispatchBundle connect_bundle;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        shuffling_ = shuffling;
        context_processor_.set_shuffling(shuffling);
        emit_state_locked();
        emit_queue_locked();
        sc_cb = state_changed_callback_;
        qc_cb = queue_changed_callback_;
        sc_bytes = cached_state_bytes_;
        qc_bytes = cached_queue_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
}

bool ContextPlayerImpl::set_repeating_context(const uint8_t* payload, size_t len) {
    bool val = false;
    if (decode_single_bool(payload, len, val)) {
        set_repeating_context(val);
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
    bool val = false;
    if (decode_single_bool(payload, len, val)) {
        set_repeating_track(val);
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
    context_view::Entry entry;
    if (decode_track_or_provided_track(payload, len, entry)) {
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> qc_bytes;
        StateChangedCallback sc_cb;
        std::vector<uint8_t> sc_bytes;
        ConnectDispatchBundle connect_bundle;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            entry.uid = generate_track_uid();
            entry.metadata["is_queued"] = "true";
            entry.provider = "queue";
            entry.metadata["provider"] = "queue";
            user_queue_.push_back(std::move(entry));
            queue_revision_++;
            emit_queue_locked();
            emit_state_locked();
            qc_cb = queue_changed_callback_;
            qc_bytes = cached_queue_bytes_;
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    return false;
}

bool ContextPlayerImpl::set_queue(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    std::vector<context_view::Entry> tracks;
    int64_t rev = 0;
    if (decode_set_queue_request(payload, len, tracks, rev)) {
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> qc_bytes;
        StateChangedCallback sc_cb;
        std::vector<uint8_t> sc_bytes;
        ConnectDispatchBundle connect_bundle;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            user_queue_.clear();
            std::vector<context_view::Entry> remaining_context;
            for (auto& t : tracks) {
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
            queue_revision_++;
            emit_queue_locked();
            emit_state_locked();
            qc_cb = queue_changed_callback_;
            qc_bytes = cached_queue_bytes_;
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    return false;
}

bool ContextPlayerImpl::play_as_next_in_queue(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    std::vector<context_view::Entry> tracks;
    const uint8_t* ptr = payload;
    const uint8_t* end = payload + len;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(ptr, end, l) || !has_bytes(ptr, end, l)) break;
            const size_t n = static_cast<size_t>(l);
            context_view::Entry entry;
            if (decode_track_or_provided_track(ptr, n, entry)) {
                tracks.push_back(std::move(entry));
            }
            ptr += n;
        } else {
            if (!skip_field(ptr, end, w)) break;
        }
    }
    if (tracks.empty()) {
        context_view::Entry direct;
        if (decode_track_or_provided_track(payload, len, direct)) {
            tracks.push_back(std::move(direct));
        }
    }
    if (!tracks.empty()) {
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> qc_bytes;
        StateChangedCallback sc_cb;
        std::vector<uint8_t> sc_bytes;
        ConnectDispatchBundle connect_bundle;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            for (auto& t : tracks) {
                t.uid = generate_track_uid();
                t.metadata["is_queued"] = "true";
                t.provider = "queue";
                t.metadata["provider"] = "queue";
            }
            user_queue_.insert(user_queue_.begin(), tracks.begin(), tracks.end());
            queue_revision_++;
            emit_queue_locked();
            emit_state_locked();
            qc_cb = queue_changed_callback_;
            qc_bytes = cached_queue_bytes_;
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
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
        tp = track_player_;
        playback_phase_ = SessionPlaybackPhase::Idle;
        position_ms_ = 0;
        duration_ms_ = 0;
        playback_id_.clear();
        current_track_.reset();
        user_queue_.clear();
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
        queue_revision_++;
        emit_state_locked(false);
        emit_queue_locked();
        sc_cb = state_changed_callback_;
        qc_cb = queue_changed_callback_;
        sc_bytes = cached_state_bytes_;
        qc_bytes = cached_queue_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }
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

    std::shared_ptr<rendering::TrackPlayer> tp;
    std::optional<context_view::Entry> track_to_prepare;
    bool should_stop_player = false;
    uint64_t sync_token = 0;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;
    ConnectDispatchBundle connect_bundle;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        tp = track_player_;
        context_uri_ = parsed.context_uri;
        context_url_ = parsed.context_url;
        context_metadata_ = parsed.context_metadata;
        play_origin_ = parsed.play_origin;
        if (!parsed.session_id.empty()) {
            session_id_ = parsed.session_id;
        }

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

        if (const auto resolved_cur = context_processor_.get_current_track();
            resolved_cur.has_value() && !resolved_cur->uri.empty()) {
            begin_track_transition_locked(*resolved_cur, SessionPlaybackPhase::Paused);
            track_to_prepare = current_track_;
            auto dur_it = current_track_->metadata.find("duration");
            if (dur_it != current_track_->metadata.end() && !dur_it->second.empty()) {
                char* end = nullptr;
                int64_t d = std::strtoll(dur_it->second.c_str(), &end, 10);
                if (end != dur_it->second.c_str() && d > 0) duration_ms_ = d;
            }
            if (tp) {
                sync_token = ++next_player_sync_token_;
                pending_player_sync_token_ = sync_token;
            }
        } else {
            current_track_.reset();
            playback_id_.clear();
            playback_phase_ = SessionPlaybackPhase::Idle;
            position_ms_ = 0;
            duration_ms_ = 0;
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

    if (tp && should_stop_player) {
        tp->stop(rendering::StopReason::ContextEnded);
        clear_pending_player_sync(sync_token);
    }

    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    dispatch_connect_listeners(connect_bundle);

    if (tp && track_to_prepare.has_value()) {
        tp->start(*track_to_prepare, rendering::StartReason::PreparePlay, 0, true);
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
        {
            std::lock_guard<std::mutex> lock(mutex_);
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
            emit_state_locked();
            emit_queue_locked();
            sc_cb = state_changed_callback_;
            qc_cb = queue_changed_callback_;
            sc_bytes = cached_state_bytes_;
            qc_bytes = cached_queue_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
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
                    const auto masked_it = current_track_->metadata.find("musify_vault_masked");
                    const bool is_masked =
                        (masked_it != current_track_->metadata.end() && masked_it->second == "true");
                    if (!is_masked) {
                        const auto info_it = resolved_track_info_cache_.find(current_track_->uri);
                        if (info_it != resolved_track_info_cache_.end()) {
                            apply_track_info_locked(*current_track_, info_it->second);
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
                    int64_t d = std::strtoll(it->second.c_str(), &end, 10);
                    if (end != it->second.c_str() && d > 0) duration_ms_ = d;
                }
                updated = true;
            }

            if (has_vault_mask_flag) {
                for (auto& queued : user_queue_) {
                    if (queued.uri == entry.uri || queued.uid == entry.uid) {
                        queued.metadata = entry.metadata;
                        const auto masked_it = queued.metadata.find("musify_vault_masked");
                        const bool is_masked =
                            (masked_it != queued.metadata.end() && masked_it->second == "true");
                        if (!is_masked) {
                            const auto info_it = resolved_track_info_cache_.find(queued.uri);
                            if (info_it != resolved_track_info_cache_.end()) {
                                apply_track_info_locked(queued, info_it->second);
                            }
                        }
                        updated = true;
                    }
                }
            }

            if (updated) {
                queue_revision_++;
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
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> qc_bytes;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            int32_t iteration = context_processor_.get_current_iteration();
            context_processor_.parseLoadedContextPage(iteration, page_url, tracks, next_page_url);
            emit_queue_locked();
            qc_cb = queue_changed_callback_;
            qc_bytes = cached_queue_bytes_;
        }
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
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
            emit_state_locked();
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    return false;
}

bool ContextPlayerImpl::signal(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    std::string sig(reinterpret_cast<const char*>(payload), len);
    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    ConnectDispatchBundle connect_bundle;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        signals_.push_back(std::move(sig));
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    dispatch_connect_listeners(connect_bundle);
    return true;
}

bool ContextPlayerImpl::set_sleep_timer(const uint8_t* payload, size_t len) {
    int64_t timer_val = 0;
    if (decode_single_int64(payload, len, timer_val)) {
        LOGI("ContextPlayerImpl: sleep timer set to %lld", static_cast<long long>(timer_val));
        return true;
    }
    return false;
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
        playback_phase_ = SessionPlaybackPhase::Idle;
        position_ms_ = 0;
        duration_ms_ = 0;
        current_track_.reset();
        user_queue_.clear();
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
        resolved_track_info_cache_.clear();
        queue_revision_++;
        emit_state_locked(false);
        emit_queue_locked();
        sc_cb = state_changed_callback_;
        qc_cb = queue_changed_callback_;
        sc_bytes = cached_state_bytes_;
        qc_bytes = cached_queue_bytes_;
        capture_connect_dispatch_locked(connect_bundle);
    }

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
            int64_t d = std::strtoll(it->second.c_str(), &end, 10);
            if (end != it->second.c_str() && d > 0) duration_ms_ = d;
        }
        if (duration_ms_ <= 0) {
            const auto cached_it = resolved_track_info_cache_.find(current_track_->uri);
            if (cached_it != resolved_track_info_cache_.end() && cached_it->second.duration_ms > 0) {
                duration_ms_ = cached_it->second.duration_ms;
            }
        }
    }
}

void ContextPlayerImpl::emit_state_locked(bool sync_player_position) {
    update_position_and_duration_locked(sync_player_position);

    const auto next_tracks = context_processor_.get_next_tracks(1);
    const bool has_next = !next_tracks.empty();
    const auto prev_tracks = context_processor_.get_prev_tracks();
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

    const int64_t now_ms = get_current_timestamp_ms();
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
    return latest_connect_snapshot_;
}

void ContextPlayerImpl::set_session_command_id(const std::string& command_id) {
    std::lock_guard<std::mutex> lock(mutex_);
    session_command_id_ = command_id;
}

void ContextPlayerImpl::capture_connect_dispatch_locked(ConnectDispatchBundle& out) {
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

bool ContextPlayerImpl::apply_connect_remote_command(
    const std::string& endpoint,
    const std::string& command_json,
    const std::string& sent_by_device_id,
    uint32_t message_id) {
    const auto parsed = connectstate::json::parse_json(command_json);
    const std::string resolved_endpoint =
        !endpoint.empty()
            ? endpoint
            : (parsed.has_value() ? parsed->get_string("endpoint").value_or(std::string{})
                                  : std::string{});

    auto record_command_meta_locked = [&]() {
        last_command_sent_by_device_id_ = sent_by_device_id;
        last_command_message_id_ = message_id;
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
        record_command_meta();
        return skip_next(nullptr, 0);
    }
    if (resolved_endpoint == "skip_prev") {
        record_command_meta();
        return skip_prev(nullptr, 0);
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
        record_command_meta();
        return seek_to(*pos);
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
        StateChangedCallback sc_cb;
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> sc_bytes, qc_bytes;
        ConnectDispatchBundle connect_bundle;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            record_command_meta_locked();
            if (const auto sh = parsed->get_bool("shuffling_context")) {
                shuffling_ = *sh;
                context_processor_.set_shuffling(shuffling_);
            }
            apply_repeat_overrides_locked(
                parsed->get_bool("repeating_context"),
                parsed->get_bool("repeating_track"));
            if (const auto spd = parsed->get_double("playback_speed");
                spd.has_value() && *spd > 0.0) {
                playback_speed_ = *spd;
            }
            emit_state_locked();
            emit_queue_locked();
            sc_cb = state_changed_callback_;
            qc_cb = queue_changed_callback_;
            sc_bytes = cached_state_bytes_;
            qc_bytes = cached_queue_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
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
        const auto uri = track_obj->get_string("uri");
        if (!uri.has_value() || uri->empty()) {
            return false;
        }
        context_view::Entry entry;
        entry.uri = *uri;
        const auto uid_opt = track_obj->get_string("uid");
        entry.uid = (uid_opt.has_value() && !uid_opt->empty()) ? *uid_opt : generate_track_uid();
        entry.provider = "queue";
        if (const auto* md = track_obj->find("metadata");
            md != nullptr && md->is_object()) {
            for (const auto& [k, v] : md->object_value) {
                if (v.is_string()) {
                    entry.metadata[k] = v.string_value;
                }
            }
        }
        entry.metadata["is_queued"] = "true";
        entry.metadata["provider"] = "queue";

        QueueChangedCallback qc_cb;
        StateChangedCallback sc_cb;
        std::vector<uint8_t> qc_bytes, sc_bytes;
        ConnectDispatchBundle connect_bundle;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            record_command_meta_locked();
            user_queue_.push_back(std::move(entry));
            queue_revision_++;
            emit_queue_locked();
            emit_state_locked();
            qc_cb = queue_changed_callback_;
            qc_bytes = cached_queue_bytes_;
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
            capture_connect_dispatch_locked(connect_bundle);
        }
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        return true;
    }
    if (resolved_endpoint == "play") {
        if (!parsed.has_value()) {
            return false;
        }
        const auto* ctx_node = parsed->find("context");
        if (ctx_node != nullptr && !ctx_node->is_object() && !ctx_node->is_null()) {
            return false;
        }
        const bool has_context_obj = (ctx_node != nullptr && ctx_node->is_object());
        std::string ctx_uri;
        std::string ctx_url;
        std::unordered_map<std::string, std::string> ctx_md;
        std::vector<context_view::Entry> tracks;
        std::vector<size_t> page_track_offsets;
        std::string page_url;
        std::string next_page_url;
        if (has_context_obj) {
            ctx_uri = ctx_node->get_string("uri").value_or(std::string{});
            ctx_url = ctx_node->get_string("url").value_or(std::string{});
            if (const auto* md = ctx_node->find("metadata");
                md != nullptr && md->is_object()) {
                for (const auto& [k, v] : md->object_value) {
                    if (v.is_string()) {
                        ctx_md[k] = v.string_value;
                    }
                }
            }

            if (const auto* pages = ctx_node->find("pages");
                pages != nullptr && pages->is_array()) {
                for (const auto& page : pages->array_value) {
                    if (!page.is_object()) {
                        continue;
                    }
                    page_track_offsets.push_back(tracks.size());
                    if (page_url.empty()) {
                        page_url = page.get_string("page_url").value_or(std::string{});
                        next_page_url = page.get_string("next_page_url").value_or(std::string{});
                    }
                    if (const auto* trks = page.find("tracks");
                        trks != nullptr && trks->is_array()) {
                        for (const auto& tnode : trks->array_value) {
                            if (!tnode.is_object()) {
                                continue;
                            }
                            auto turi = tnode.get_string("uri");
                            if (!turi.has_value() || turi->empty()) {
                                continue;
                            }
                            context_view::Entry entry;
                            entry.uri = *turi;
                            const auto uid_opt = tnode.get_string("uid");
                            entry.uid = (uid_opt.has_value() && !uid_opt->empty())
                                            ? *uid_opt
                                            : generate_track_uid();
                            const auto prov_opt = tnode.get_string("provider");
                            entry.provider = (prov_opt.has_value() && !prov_opt->empty())
                                                 ? *prov_opt
                                                 : "context";
                            if (const auto* tmd = tnode.find("metadata");
                                tmd != nullptr && tmd->is_object()) {
                                for (const auto& [mk, mv] : tmd->object_value) {
                                    if (mv.is_string()) {
                                        entry.metadata[mk] = mv.string_value;
                                    }
                                }
                            }
                            tracks.push_back(std::move(entry));
                        }
                    }
                }
            }
        }

        if (tracks.empty()) {
            if (const auto* top_track = parsed->find("track");
                top_track != nullptr && top_track->is_object()) {
                if (const auto turi = top_track->get_string("uri");
                    turi.has_value() && !turi->empty()) {
                    context_view::Entry entry;
                    entry.uri = *turi;
                    const auto uid_opt = top_track->get_string("uid");
                    entry.uid = (uid_opt.has_value() && !uid_opt->empty())
                                    ? *uid_opt
                                    : generate_track_uid();
                    const auto prov_opt = top_track->get_string("provider");
                    entry.provider = (prov_opt.has_value() && !prov_opt->empty())
                                         ? *prov_opt
                                         : "context";
                    if (const auto* tmd = top_track->find("metadata");
                        tmd != nullptr && tmd->is_object()) {
                        for (const auto& [mk, mv] : tmd->object_value) {
                            if (mv.is_string()) {
                                entry.metadata[mk] = mv.string_value;
                            }
                        }
                    }
                    tracks.push_back(std::move(entry));
                }
            }
        }

        bool initially_paused = false;
        int64_t seek_to_ms = parsed->get_int64("seek_to").value_or(0);
        std::string skip_to_uri;
        std::string skip_to_uid;
        std::optional<int64_t> skip_to_page_index;
        int64_t skip_to_index = -1;
        std::optional<bool> shuf_override;
        std::optional<bool> rep_ctx_override;
        std::optional<bool> rep_trk_override;

        if (const auto* opts = parsed->find("options");
            opts != nullptr && opts->is_object()) {
            initially_paused = opts->get_bool("initially_paused").value_or(false);
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
            }
        }
        if (seek_to_ms < 0) {
            seek_to_ms = 0;
        }
        if (tracks.empty() && !skip_to_uri.empty()) {
            context_view::Entry entry;
            entry.uri = skip_to_uri;
            entry.uid = !skip_to_uid.empty() ? skip_to_uid : generate_track_uid();
            entry.provider = "context";
            tracks.push_back(std::move(entry));
        }

        if (tracks.empty() && !has_context_obj) {
            const auto* top_track = parsed->find("track");
            if (top_track != nullptr) {
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
        {
            std::lock_guard<std::mutex> lock(mutex_);
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
            } else {
                if (!ctx_url.empty()) {
                    context_url_ = std::move(ctx_url);
                }
                if (!ctx_md.empty()) {
                    context_metadata_ = std::move(ctx_md);
                }
            }
            if (const auto* po = parsed->find("play_origin");
                po != nullptr && po->is_object()) {
                play_origin_.feature_identifier =
                    po->get_string("feature_identifier").value_or(std::string{});
                play_origin_.feature_version =
                    po->get_string("feature_version").value_or(std::string{});
                play_origin_.view_uri =
                    po->get_string("view_uri").value_or(std::string{});
                play_origin_.external_referrer =
                    po->get_string("external_referrer").value_or(std::string{});
                play_origin_.referrer_identifier =
                    po->get_string("referrer_identifier").value_or(std::string{});
                play_origin_.device_identifier =
                    po->get_string("device_identifier").value_or(std::string{});
            }
            apply_repeat_overrides_locked(rep_ctx_override, rep_trk_override);
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
            if (const auto resolved_cur = context_processor_.get_current_track();
                resolved_cur.has_value() && !resolved_cur->uri.empty()) {
                begin_track_transition_locked(
                    *resolved_cur,
                    initially_paused ? SessionPlaybackPhase::Paused
                                     : SessionPlaybackPhase::BufferingPlay);
                position_ms_ = seek_to_ms;
                track_to_play = *current_track_;
                tp = track_player_;
                if (tp) {
                    sync_token = ++next_player_sync_token_;
                    pending_player_sync_token_ = sync_token;
                }
            } else {
                current_track_.reset();
                playback_id_.clear();
                playback_phase_ = SessionPlaybackPhase::Idle;
                position_ms_ = 0;
                duration_ms_ = 0;
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
        if (tp && should_stop_player) {
            tp->stop(rendering::StopReason::ContextEnded);
            clear_pending_player_sync(sync_token);
        }
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        dispatch_connect_listeners(connect_bundle);
        if (tp && !should_stop_player && !track_to_play.uri.empty()) {
            tp->start(track_to_play, rendering::StartReason::PlayCommand, seek_to_ms, initially_paused);
            clear_pending_player_sync(sync_token);
        }
        return true;
    }

    return false;
}

void ContextPlayerImpl::emit_queue_locked() {
    std::vector<context_view::Entry> combined_next;
    combined_next.reserve(user_queue_.size() + 50);

    // User-enqueued tracks precede context tracks in Spotify queue semantics
    combined_next.insert(combined_next.end(), user_queue_.begin(), user_queue_.end());

    // Context lookahead tracks
    const auto ctx_next = context_processor_.get_next_tracks(50);
    combined_next.insert(combined_next.end(), ctx_next.begin(), ctx_next.end());

    const auto prev_tracks = context_processor_.get_prev_tracks();
    const context_view::Entry* cur_ptr = current_track_.has_value() ? &current_track_.value() : nullptr;

    cached_queue_bytes_ = StateEmitter::encode_queue(
        cur_ptr,
        combined_next,
        prev_tracks,
        queue_revision_);
}

} // namespace spotify::player
