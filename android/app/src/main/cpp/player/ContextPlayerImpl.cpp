#include "ContextPlayerImpl.h"

#include <android/log.h>
#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <cstring>

#define LOG_TAG "ContextPlayer"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)

namespace spotify::player {

namespace {

inline int64_t get_current_timestamp_ms() noexcept {
    const auto now = std::chrono::system_clock::now();
    return std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count();
}

struct SkipToOptions {
    std::string track_uri;
    std::string track_uid;
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
    std::string page_url;
    std::string next_page_url;
    SkipToOptions skip_to;
    OptionOverrides overrides;
    std::string session_id;
    PlayOriginData play_origin;
};

inline bool decode_bool_value(const uint8_t*& ptr, const uint8_t* end, uint32_t wire_type, bool& out) {
    if (wire_type == 0) {
        uint64_t val = 0;
        if (!decode_varint(ptr, end, val)) return false;
        out = (val != 0);
        return true;
    }
    if (wire_type == 2) {
        uint64_t len = 0;
        if (!decode_varint(ptr, end, len) || ptr + len > end) return false;
        const uint8_t* sub_ptr = ptr;
        const uint8_t* sub_end = ptr + len;
        ptr += len;
        while (sub_ptr < sub_end) {
            uint64_t tag = 0;
            if (!decode_varint(sub_ptr, sub_end, tag)) break;
            uint32_t f = static_cast<uint32_t>(tag >> 3);
            uint32_t w = static_cast<uint32_t>(tag & 0x07);
            if (f == 1 && w == 0) {
                uint64_t v = 0;
                if (decode_varint(sub_ptr, sub_end, v)) {
                    out = (v != 0);
                    return true;
                }
            } else {
                if (!skip_field(sub_ptr, sub_end, w)) break;
            }
        }
        return true;
    }
    return skip_field(ptr, end, wire_type);
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
        if (!decode_varint(ptr, end, len) || ptr + len > end) return false;
        const uint8_t* sub_ptr = ptr;
        const uint8_t* sub_end = ptr + len;
        ptr += len;
        while (sub_ptr < sub_end) {
            uint64_t tag = 0;
            if (!decode_varint(sub_ptr, sub_end, tag)) break;
            uint32_t f = static_cast<uint32_t>(tag >> 3);
            uint32_t w = static_cast<uint32_t>(tag & 0x07);
            if (f == 1 && w == 0) {
                uint64_t v = 0;
                if (decode_varint(sub_ptr, sub_end, v)) {
                    out = static_cast<int64_t>(v);
                    return true;
                }
            } else {
                if (!skip_field(sub_ptr, sub_end, w)) break;
            }
        }
        return true;
    }
    return skip_field(ptr, end, wire_type);
}

inline void decode_map_entries(
        const uint8_t* ptr,
        size_t len,
        std::unordered_map<std::string, std::string>& out_map) {
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    std::string key;
    std::string val;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) break;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (w == 2) {
            uint64_t entry_len = 0;
            if (!decode_varint(p, end, entry_len) || p + entry_len > end) break;
            if (f == 1) {
                key.assign(reinterpret_cast<const char*>(p), entry_len);
            } else if (f == 2) {
                val.assign(reinterpret_cast<const char*>(p), entry_len);
            }
            p += entry_len;
        } else {
            if (!skip_field(p, end, w)) break;
        }
    }
    if (!key.empty()) {
        out_map[key] = val;
    }
}

// Field numbers verified 1:1 against Spotify EsSkipToTrack$SkipToTrack.java:
// Field 1: page_url, Field 2: page_index, Field 3: track_uid, Field 4: track_uri, Field 5: track_index
inline void decode_skip_to(const uint8_t* ptr, size_t len, SkipToOptions& skip_to) {
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) break;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 3 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || p + l > end) break;
            skip_to.track_uid.assign(reinterpret_cast<const char*>(p), l);
            p += l;
        } else if (f == 4 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || p + l > end) break;
            skip_to.track_uri.assign(reinterpret_cast<const char*>(p), l);
            p += l;
        } else if (f == 5) {
            decode_int64_value(p, end, w, skip_to.track_index);
        } else {
            if (!skip_field(p, end, w)) break;
        }
    }
}

// Field numbers verified 1:1 against Spotify EsContextPlayerOptions$ContextPlayerOptionOverrides.java:
// Field 1: shuffling_context, Field 2: repeating_context, Field 3: repeating_track, Field 4: playback_speed, Field 5: modes
inline void decode_option_overrides(const uint8_t* ptr, size_t len, OptionOverrides& overrides) {
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) break;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1) {
            bool v = false;
            if (decode_bool_value(p, end, w, v)) overrides.shuffling_context = v;
        } else if (f == 2) {
            bool v = false;
            if (decode_bool_value(p, end, w, v)) overrides.repeating_context = v;
        } else if (f == 3) {
            bool v = false;
            if (decode_bool_value(p, end, w, v)) overrides.repeating_track = v;
        } else {
            if (!skip_field(p, end, w)) break;
        }
    }
}

// Field numbers verified 1:1 against Spotify EsPlayOrigin$PlayOrigin.java:
// Field 1: feature_identifier, Field 2: feature_version, Field 3: view_uri, Field 4: external_referrer,
// Field 5: referrer_identifier, Field 6: device_identifier, Field 7: feature_classes, Field 8: restriction_identifier
inline void decode_play_origin(const uint8_t* ptr, size_t len, PlayOriginData& out) {
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) break;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || p + l > end) break;
            std::string str(reinterpret_cast<const char*>(p), l);
            if (f == 1) out.feature_identifier = std::move(str);
            else if (f == 2) out.feature_version = std::move(str);
            else if (f == 3) out.view_uri = std::move(str);
            else if (f == 4) out.external_referrer = std::move(str);
            else if (f == 5) out.referrer_identifier = std::move(str);
            else if (f == 6) out.device_identifier = std::move(str);
            else if (f == 7) out.feature_classes.push_back(std::move(str));
            else if (f == 8) out.restriction_identifier = std::move(str);
            p += l;
        } else {
            if (!skip_field(p, end, w)) break;
        }
    }
}

// Field numbers verified 1:1 against Spotify EsPreparePlayOptions$PreparePlayOptions.java:
// Field 3: skip_to (SkipToTrack), Field 7: player_options_override (ContextPlayerOptionOverrides), Field 11: session_id (string)
inline void decode_prepare_play_options(const uint8_t* ptr, size_t len, DecodedPreparePlay& out) {
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) break;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 3 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || p + l > end) break;
            decode_skip_to(p, l, out.skip_to);
            p += l;
        } else if (f == 7 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || p + l > end) break;
            decode_option_overrides(p, l, out.overrides);
            p += l;
        } else if (f == 11 && w == 2) {
            uint64_t l = 0;
            if (!decode_varint(p, end, l) || p + l > end) break;
            out.session_id.assign(reinterpret_cast<const char*>(p), l);
            p += l;
        } else {
            if (!skip_field(p, end, w)) break;
        }
    }
}

// Field numbers verified 1:1 against Spotify EsContext$Context.java:
// Field 1: pages (repeated ContextPage), Field 2: metadata (map), Field 3: uri (string), Field 4: url (string)
inline void decode_context_submessage(const uint8_t* ptr, size_t len, DecodedPreparePlay& out) {
    const uint8_t* p = ptr;
    const uint8_t* end = ptr + len;
    while (p < end) {
        uint64_t tag = 0;
        if (!decode_varint(p, end, tag)) break;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (w == 2) {
            uint64_t sub_len = 0;
            if (!decode_varint(p, end, sub_len) || p + sub_len > end) break;
            if (f == 1) { // Field 1: pages (repeated ContextPage)
                std::string page_url, next_page_url;
                std::vector<context_view::Entry> page_tracks;
                if (decode_context_page(p, sub_len, page_url, next_page_url, page_tracks)) {
                    if (out.page_url.empty()) {
                        out.page_url = std::move(page_url);
                        out.next_page_url = std::move(next_page_url);
                    }
                    out.tracks.insert(out.tracks.end(), page_tracks.begin(), page_tracks.end());
                }
            } else if (f == 2) { // Field 2: metadata (map<string,string>)
                decode_map_entries(p, sub_len, out.context_metadata);
            } else if (f == 3) { // Field 3: uri (string)
                out.context_uri.assign(reinterpret_cast<const char*>(p), sub_len);
            } else if (f == 4) { // Field 4: url (string)
                out.context_url.assign(reinterpret_cast<const char*>(p), sub_len);
            }
            p += sub_len;
        } else {
            if (!skip_field(p, end, w)) break;
        }
    }
}

// Field numbers verified 1:1 against Spotify EsPreparePlay$PreparePlayRequest.java:
// Field 1: context (Context), Field 2: options (PreparePlayOptions), Field 3: play_origin (PlayOrigin)
inline bool decode_prepare_play_request_body(const uint8_t* data, size_t size, DecodedPreparePlay& out) {
    if (!data || size == 0) return false;
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (w == 2) {
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || ptr + len > end) break;
            if (f == 1) { // Field 1: Context
                decode_context_submessage(ptr, static_cast<size_t>(len), out);
            } else if (f == 2) { // Field 2: PreparePlayOptions
                decode_prepare_play_options(ptr, static_cast<size_t>(len), out);
            } else if (f == 3) { // Field 3: PlayOrigin
                decode_play_origin(ptr, static_cast<size_t>(len), out.play_origin);
            }
            ptr += len;
        } else {
            if (!skip_field(ptr, end, w)) break;
        }
    }
    return !out.context_uri.empty() || !out.tracks.empty();
}

// Unwraps PlayRequest (Field 1 = PreparePlayRequest) or decodes PreparePlayRequest directly
inline bool parse_prepare_play_request(const uint8_t* data, size_t size, DecodedPreparePlay& out) {
    if (!data || size == 0) return false;

    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    const uint8_t* f1_ptr = nullptr;
    size_t f1_len = 0;

    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 2) {
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || ptr + len > end) break;
            f1_ptr = ptr;
            f1_len = static_cast<size_t>(len);
            ptr += len;
        } else {
            if (!skip_field(ptr, end, w)) break;
        }
    }

    if (f1_ptr && f1_len > 0) {
        DecodedPreparePlay candidate;
        if (decode_prepare_play_request_body(f1_ptr, f1_len, candidate)) {
            if (!candidate.context_uri.empty() || !candidate.tracks.empty()) {
                out = std::move(candidate);
                return true;
            }
        }
    }

    return decode_prepare_play_request_body(data, size, out);
}

inline bool is_ascii_printable_uri(const std::string& uri) {
    if (uri.empty()) return false;
    for (unsigned char c : uri) {
        if (c < 32 || c >= 127) return false;
    }
    return true;
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
            if (!decode_varint(ptr, end, len) || ptr + len > end) break;
            if (decode_context_track(ptr, static_cast<size_t>(len), inner) && is_ascii_printable_uri(inner.uri)) {
                found_track = true;
            }
            ptr += len;
        } else if (f == 4 && w == 2) {
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || ptr + len > end) break;
            provider.assign(reinterpret_cast<const char*>(ptr), static_cast<size_t>(len));
            ptr += len;
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
    if (decode_context_track(data, size, direct) && is_ascii_printable_uri(direct.uri)) {
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
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) break;
        uint32_t f = static_cast<uint32_t>(tag >> 3);
        uint32_t w = static_cast<uint32_t>(tag & 0x07);
        if (f == 1 && w == 2) {
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || ptr + len > end) break;
            context_view::Entry entry;
            if (decode_track_or_provided_track(ptr, static_cast<size_t>(len), entry)) {
                out_tracks.push_back(std::move(entry));
            }
            ptr += len;
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
            if (!decode_varint(ptr, end, len) || ptr + len > end) break;
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
    {
        std::lock_guard<std::mutex> lock(mutex_);
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
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
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
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
}

void ContextPlayerImpl::on_track_player_error(int32_t /*code*/, const std::string& message) {
    ErrorCallback err_cb;
    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        playback_phase_ = SessionPlaybackPhase::Halted;
        last_error_ = "LOAD_FAILED";
        err_cb = error_callback_;
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
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
    last_error_ = "UNHANDLED_METHOD";
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
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;

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
            context_processor_.set_shuffling(shuffling_);
        }
        apply_repeat_overrides_locked(
            parsed.overrides.repeating_context,
            parsed.overrides.repeating_track);

        int32_t initial_index = 0;
        if (parsed.skip_to.track_index >= 0) {
            initial_index = static_cast<int32_t>(parsed.skip_to.track_index);
        } else if (!parsed.skip_to.track_uid.empty()) {
            for (size_t i = 0; i < parsed.tracks.size(); ++i) {
                if (parsed.tracks[i].uid == parsed.skip_to.track_uid) {
                    initial_index = static_cast<int32_t>(i);
                    break;
                }
            }
        } else if (!parsed.skip_to.track_uri.empty()) {
            for (size_t i = 0; i < parsed.tracks.size(); ++i) {
                if (parsed.tracks[i].uri == parsed.skip_to.track_uri) {
                    initial_index = static_cast<int32_t>(i);
                    break;
                }
            }
        }

        context_processor_.set_context(
            parsed.context_uri,
            parsed.page_url,
            parsed.tracks,
            parsed.next_page_url,
            initial_index);

        if (!parsed.skip_to.track_uid.empty()) {
            context_processor_.skip_to_uid(parsed.skip_to.track_uid);
        } else if (!parsed.skip_to.track_uri.empty()) {
            context_processor_.skip_to_uri(parsed.skip_to.track_uri);
        } else if (parsed.skip_to.track_index > 0) {
            context_processor_.skip_to_index(static_cast<int32_t>(parsed.skip_to.track_index));
        }

        if (const auto resolved_cur = context_processor_.get_current_track();
            resolved_cur.has_value()) {
            begin_track_transition_locked(*resolved_cur, SessionPlaybackPhase::BufferingPlay);
            LOGI("ContextPlayerImpl.play: context_uri=%s playing uri=%s uid=%s",
                 context_uri_.c_str(),
                 current_track_->uri.c_str(),
                 current_track_->uid.c_str());
            track_to_play = *current_track_;
            tp = track_player_;
        } else {
            current_track_.reset();
            playback_phase_ = SessionPlaybackPhase::Idle;
            position_ms_ = 0;
            duration_ms_ = 0;
        }

        emit_state_locked();
        emit_queue_locked();
        sc_cb = state_changed_callback_;
        qc_cb = queue_changed_callback_;
        sc_bytes = cached_state_bytes_;
        qc_bytes = cached_queue_bytes_;
    }

    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    if (tp && !track_to_play.uri.empty()) {
        tp->start(track_to_play, rendering::StartReason::PlayCommand, 0, false);
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
    {
        std::lock_guard<std::mutex> lock(mutex_);
        LOGI("ContextPlayer RoutingTrackPlayer: PauseOrAwaitPause active");
        playback_phase_ = SessionPlaybackPhase::Paused;
        if (track_player_) {
            position_ms_ = track_player_->getPosition();
        }
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    return true;
}

bool ContextPlayerImpl::resume() {
    std::shared_ptr<rendering::TrackPlayer> tp;
    std::optional<context_view::Entry> fallback_track;
    int64_t resume_pos = 0;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        tp = track_player_;
        fallback_track = current_track_;
        resume_pos = position_ms_;
    }

    if (tp) {
        if (!tp->getCurrentTrack().has_value() && fallback_track.has_value()) {
            tp->start(*fallback_track, rendering::StartReason::PlayCommand, resume_pos, false);
        } else {
            tp->resume();
        }
    }

    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        LOGI("ContextPlayer RoutingTrackPlayer: PauseOrAwaitPause not active");
        playback_phase_ = (playback_phase_ == SessionPlaybackPhase::BufferingPaused)
            ? SessionPlaybackPhase::BufferingPlay
            : SessionPlaybackPhase::Playing;
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    return true;
}

bool ContextPlayerImpl::seek_to(int64_t position_ms) {
    std::shared_ptr<rendering::TrackPlayer> tp;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        tp = track_player_;
    }
    if (tp) {
        tp->seek(position_ms, rendering::SeekOrigin::User);
    }

    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        LOGI("ContextPlayer RoutingTrackPlayer: Seeking to %lld ms", static_cast<long long>(position_ms));
        position_ms_ = position_ms;
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
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
                if (!decode_varint(p, end, l) || p + l > end) break;
                const uint8_t* opt_p = p;
                const uint8_t* opt_end = p + l;
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
                p += l;
            } else if (f == 3 && w == 2) {
                uint64_t l = 0;
                if (!decode_varint(p, end, l) || p + l > end) break;
                decode_context_track(p, static_cast<size_t>(l), target_track);
                p += l;
            } else {
                if (!skip_field(p, end, w)) break;
            }
        }
    }

    std::shared_ptr<rendering::TrackPlayer> tp;
    context_view::Entry next_track;
    bool should_play = false;
    bool should_stop_context = false;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    ErrorCallback err_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;

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
                        context_processor_.skip_to_index(0);
                        advanced = true;
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
                        playback_phase_ = SessionPlaybackPhase::Idle;
                        position_ms_ = 0;
                        should_stop_context = true;
                    }
                }
            }

            emit_state_locked();
            emit_queue_locked();
            sc_cb = state_changed_callback_;
            qc_cb = queue_changed_callback_;
            sc_bytes = cached_state_bytes_;
            qc_bytes = cached_queue_bytes_;
        }
    }

    if (err_cb) {
        err_cb("SKIP_TO_NEXT_RESTRICTED", "Skipping to next track is restricted");
        return false;
    }

    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    if (tp) {
        if (should_play) {
            tp->start(next_track, rendering::StartReason::SkipNext, 0, false);
        } else if (should_stop_context) {
            tp->stop(rendering::StopReason::ContextEnded);
        }
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
                if (!decode_varint(p, end, l) || p + l > end) break;
                const uint8_t* opt_p = p;
                const uint8_t* opt_end = p + l;
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
                p += l;
            } else if (f == 2) {
                decode_bool_value(p, end, w, allow_seeking);
            } else if (f == 4 && w == 2) {
                uint64_t l = 0;
                if (!decode_varint(p, end, l) || p + l > end) break;
                decode_context_track(p, static_cast<size_t>(l), target_track);
                p += l;
            } else {
                if (!skip_field(p, end, w)) break;
            }
        }
    }

    std::shared_ptr<rendering::TrackPlayer> tp;
    context_view::Entry prev_track;
    bool should_play = false;
    bool should_seek_zero = false;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    ErrorCallback err_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!override_restrictions && !restrictions_engine_.get_custom_disallow_skipping_prev().empty()) {
            LOGW("ContextPlayer: SkipPrev restricted by custom policy");
            last_error_ = "SKIP_TO_PREV_RESTRICTED";
            err_cb = error_callback_;
        } else {
            tp = track_player_;
            const int64_t current_pos = tp ? tp->getPosition() : position_ms_;
            if (allow_seeking && current_pos > 3000) {
                LOGI("ContextPlayer RoutingTrackPlayer: Seeking to 0 ms (skip_prev restart pos=%lld)",
                     static_cast<long long>(current_pos));
                position_ms_ = 0;
                should_seek_zero = true;
                emit_state_locked();
                sc_cb = state_changed_callback_;
                sc_bytes = cached_state_bytes_;
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
                } else if (repeat_mode_ != SessionRepeatMode::Off) {
                    position_ms_ = 0;
                    should_seek_zero = true;
                }

                emit_state_locked();
                emit_queue_locked();
                sc_cb = state_changed_callback_;
                qc_cb = queue_changed_callback_;
                sc_bytes = cached_state_bytes_;
                qc_bytes = cached_queue_bytes_;
            }
        }
    }

    if (err_cb) {
        err_cb("SKIP_TO_PREV_RESTRICTED", "Skipping to previous track is restricted");
        return false;
    }

    if (tp && should_seek_zero) {
        tp->seek(0, rendering::SeekOrigin::User);
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    if (tp && should_play) {
        tp->start(prev_track, rendering::StartReason::SkipPrev, 0, false);
    }
    return should_play || should_seek_zero;
}

void ContextPlayerImpl::advance_to_next_track(rendering::AdvanceReason reason) {
    std::shared_ptr<rendering::TrackPlayer> tp;
    context_view::Entry next_track;
    bool should_play = false;
    bool should_repeat_current = false;
    bool should_stop_context = false;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;

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
            emit_state_locked();
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
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
                    context_processor_.skip_to_index(0);
                    advanced = true;
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
                    playback_phase_ = SessionPlaybackPhase::Idle;
                    position_ms_ = 0;
                    should_stop_context = true;
                }
            }

            emit_state_locked();
            emit_queue_locked();
            sc_cb = state_changed_callback_;
            qc_cb = queue_changed_callback_;
            sc_bytes = cached_state_bytes_;
            qc_bytes = cached_queue_bytes_;
        }
    }

    if (tp && should_repeat_current) {
        tp->seek(0, rendering::SeekOrigin::Internal);
        tp->resume();
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    if (tp) {
        if (should_play) {
            tp->advance(next_track, 0);
        } else if (should_stop_context) {
            tp->stop(rendering::StopReason::ContextEnded);
        }
    }
}

bool ContextPlayerImpl::set_options(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    OptionOverrides overrides;
    if (decode_set_options_request(payload, len, overrides)) {
        StateChangedCallback sc_cb;
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> sc_bytes, qc_bytes;
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
        }
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
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
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
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
    {
        std::lock_guard<std::mutex> lock(mutex_);
        apply_repeat_overrides_locked(repeating, std::nullopt);
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
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
    {
        std::lock_guard<std::mutex> lock(mutex_);
        apply_repeat_overrides_locked(std::nullopt, repeating);
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
}

bool ContextPlayerImpl::add_to_queue(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    context_view::Entry entry;
    if (decode_track_or_provided_track(payload, len, entry)) {
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> qc_bytes;
        StateChangedCallback sc_cb;
        std::vector<uint8_t> sc_bytes;
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
        }
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
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
        }
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
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
            if (!decode_varint(ptr, end, l) || ptr + l > end) break;
            context_view::Entry entry;
            if (decode_track_or_provided_track(ptr, static_cast<size_t>(l), entry)) {
                tracks.push_back(std::move(entry));
            }
            ptr += l;
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
        }
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        return true;
    }
    return false;
}

bool ContextPlayerImpl::stop() {
    std::shared_ptr<rendering::TrackPlayer> tp;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes;
    std::vector<uint8_t> qc_bytes;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        tp = track_player_;
        playback_phase_ = SessionPlaybackPhase::Idle;
        position_ms_ = 0;
        duration_ms_ = 0;
        current_track_.reset();
        user_queue_.clear();
        context_processor_.clear();
        context_uri_.clear();
        context_url_.clear();
        context_metadata_.clear();
        page_metadata_.clear();
        session_id_.clear();
        session_command_id_.clear();
        signals_.clear();
        queue_revision_++;
        emit_state_locked();
        emit_queue_locked();
        sc_cb = state_changed_callback_;
        qc_cb = queue_changed_callback_;
        sc_bytes = cached_state_bytes_;
        qc_bytes = cached_queue_bytes_;
    }
    if (tp) {
        tp->stop(rendering::StopReason::ExplicitStop);
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    return true;
}

bool ContextPlayerImpl::prepare_play(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    DecodedPreparePlay parsed;
    if (!parse_prepare_play_request(payload, len, parsed)) {
        LOGE("ContextPlayerImpl.preparePlay: failed to parse wire format");
        last_error_ = "INVALID_PREPARE_PLAY_REQUEST";
        return false;
    }

    std::shared_ptr<rendering::TrackPlayer> tp;
    std::optional<context_view::Entry> track_to_prepare;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;

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
            context_processor_.set_shuffling(shuffling_);
        }
        apply_repeat_overrides_locked(
            parsed.overrides.repeating_context,
            parsed.overrides.repeating_track);

        int32_t initial_index = 0;
        if (parsed.skip_to.track_index >= 0) {
            initial_index = static_cast<int32_t>(parsed.skip_to.track_index);
        } else if (!parsed.skip_to.track_uid.empty()) {
            for (size_t i = 0; i < parsed.tracks.size(); ++i) {
                if (parsed.tracks[i].uid == parsed.skip_to.track_uid) {
                    initial_index = static_cast<int32_t>(i);
                    break;
                }
            }
        } else if (!parsed.skip_to.track_uri.empty()) {
            for (size_t i = 0; i < parsed.tracks.size(); ++i) {
                if (parsed.tracks[i].uri == parsed.skip_to.track_uri) {
                    initial_index = static_cast<int32_t>(i);
                    break;
                }
            }
        }

        context_processor_.set_context(
            parsed.context_uri,
            parsed.page_url,
            parsed.tracks,
            parsed.next_page_url,
            initial_index);

        if (!parsed.skip_to.track_uid.empty()) {
            context_processor_.skip_to_uid(parsed.skip_to.track_uid);
        } else if (!parsed.skip_to.track_uri.empty()) {
            context_processor_.skip_to_uri(parsed.skip_to.track_uri);
        } else if (parsed.skip_to.track_index > 0) {
            context_processor_.skip_to_index(static_cast<int32_t>(parsed.skip_to.track_index));
        }

        if (const auto resolved_cur = context_processor_.get_current_track();
            resolved_cur.has_value()) {
            begin_track_transition_locked(*resolved_cur, SessionPlaybackPhase::Paused);
            track_to_prepare = current_track_;
            auto dur_it = current_track_->metadata.find("duration");
            if (dur_it != current_track_->metadata.end() && !dur_it->second.empty()) {
                char* end = nullptr;
                int64_t d = std::strtoll(dur_it->second.c_str(), &end, 10);
                if (end != dur_it->second.c_str() && d > 0) duration_ms_ = d;
            }
        } else {
            current_track_.reset();
            playback_phase_ = SessionPlaybackPhase::Idle;
            position_ms_ = 0;
            duration_ms_ = 0;
        }

        LOGI("ContextPlayerImpl.preparePlay: context_uri=%s (ready to play)", context_uri_.c_str());

        emit_state_locked();
        emit_queue_locked();
        sc_cb = state_changed_callback_;
        qc_cb = queue_changed_callback_;
        sc_bytes = cached_state_bytes_;
        qc_bytes = cached_queue_bytes_;
    }

    if (tp && track_to_prepare.has_value()) {
        tp->start(*track_to_prepare, rendering::StartReason::PreparePlay, 0, true);
    }

    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
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
    if (parse_prepare_play_request(payload, len, parsed)) {
        StateChangedCallback sc_cb;
        QueueChangedCallback qc_cb;
        std::vector<uint8_t> sc_bytes, qc_bytes;
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
        }
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
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
            }
        }
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
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
        {
            std::lock_guard<std::mutex> lock(mutex_);
            view_uri_ = uri;
            emit_state_locked();
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
        }
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
        return true;
    }
    return false;
}

bool ContextPlayerImpl::signal(const uint8_t* payload, size_t len) {
    if (!payload || len == 0) return false;
    std::string sig(reinterpret_cast<const char*>(payload), len);
    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        signals_.push_back(std::move(sig));
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
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
    if (payload && len > 0) {
        size_t offset = 0;
        while (offset < len) {
            uint32_t tag = 0;
            size_t shift = 0;
            while (offset < len && (payload[offset] & 0x80)) {
                tag |= (static_cast<uint32_t>(payload[offset] & 0x7F) << shift);
                shift += 7;
                offset++;
            }
            if (offset < len) {
                tag |= (static_cast<uint32_t>(payload[offset] & 0x7F) << shift);
                offset++;
            }
            uint32_t field_number = tag >> 3;
            uint32_t wire_type = tag & 0x07;

            if (field_number == 1 && wire_type == 2) {
                uint32_t str_len = 0;
                shift = 0;
                while (offset < len && (payload[offset] & 0x80)) {
                    str_len |= (static_cast<uint32_t>(payload[offset] & 0x7F) << shift);
                    shift += 7;
                    offset++;
                }
                if (offset < len) {
                    str_len |= (static_cast<uint32_t>(payload[offset] & 0x7F) << shift);
                    offset++;
                }
                if (offset + str_len <= len) {
                    target_session_id.assign(
                        reinterpret_cast<const char*>(payload + offset), str_len);
                    offset += str_len;
                }
            } else {
                break;
            }
        }
    }

    std::shared_ptr<rendering::TrackPlayer> tp;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes;
    std::vector<uint8_t> qc_bytes;
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
        signals_.clear();
        playback_phase_ = SessionPlaybackPhase::Idle;
        position_ms_ = 0;
        duration_ms_ = 0;
        current_track_.reset();
        user_queue_.clear();
        context_processor_.clear();
        context_uri_.clear();
        context_url_.clear();
        context_metadata_.clear();
        page_metadata_.clear();
        resolved_track_info_cache_.clear();
        queue_revision_++;
        emit_state_locked();
        emit_queue_locked();
        sc_cb = state_changed_callback_;
        qc_cb = queue_changed_callback_;
        sc_bytes = cached_state_bytes_;
        qc_bytes = cached_queue_bytes_;
    }

    if (tp) {
        tp->stop(rendering::StopReason::SessionDeleted);
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
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

void ContextPlayerImpl::update_position_and_duration_locked() {
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
        const int64_t player_pos = track_player_->getPosition();
        if (player_pos >= 0) position_ms_ = player_pos;
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

void ContextPlayerImpl::emit_state_locked() {
    update_position_and_duration_locked();

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
