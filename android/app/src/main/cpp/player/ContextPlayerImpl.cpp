#include "ContextPlayerImpl.h"

#include <android/log.h>
#include <algorithm>
#include <chrono>
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

    // Check if wrapped in PlayRequest (field 1 = PreparePlayRequest)
    // EsPlay$PlayRequest.java: Field 1 is PREPARE_PLAY_REQUEST_FIELD_NUMBER
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

    // Direct PreparePlayRequest
    return decode_prepare_play_request_body(data, size, out);
}

inline bool decode_track_or_provided_track(const uint8_t* data, size_t size, context_view::Entry& out_entry) {
    if (!data || size == 0) return false;

    // Try decoding directly as ContextTrack
    context_view::Entry direct;
    if (decode_context_track(data, size, direct) && !direct.uri.empty()) {
        out_entry = std::move(direct);
        return true;
    }

    // Try decoding as ProvidedTrack (field 1 = ContextTrack)
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
            if (decode_context_track(ptr, static_cast<size_t>(len), out_entry)) {
                return true;
            }
            ptr += len;
        } else {
            if (!skip_field(ptr, end, w)) break;
        }
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

ContextPlayerImpl::ContextPlayerImpl(AudioEngine* engine)
    : audio_engine_(engine) {
    LOGI("ContextPlayerImpl initialized (engine=%p)", audio_engine_);
}

ContextPlayerImpl::~ContextPlayerImpl() {
    LOGI("ContextPlayerImpl destroying session_id=%s", session_id_.c_str());
}

void ContextPlayerImpl::set_audio_engine(AudioEngine* engine) noexcept {
    std::lock_guard<std::mutex> lock(mutex_);
    audio_engine_ = engine;
    LOGI("ContextPlayerImpl attached AudioEngine=%p", audio_engine_);
}

AudioEngine* ContextPlayerImpl::get_audio_engine() const noexcept {
    std::lock_guard<std::mutex> lock(mutex_);
    return audio_engine_;
}

void ContextPlayerImpl::set_play_track_callback(PlayTrackCallback cb) {
    std::lock_guard<std::mutex> lock(mutex_);
    play_track_callback_ = std::move(cb);
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
        if (is_paused_) return resume();
        return false;
    }

    DecodedPreparePlay parsed;
    if (!parse_prepare_play_request(payload, len, parsed)) {
        LOGE("ContextPlayerImpl.play: failed to parse PlayRequest wire format");
        last_error_ = "INVALID_PLAY_REQUEST";
        return false;
    }

    PlayTrackCallback cb;
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
        if (parsed.overrides.repeating_context.has_value()) {
            repeating_context_ = *parsed.overrides.repeating_context;
        }
        if (parsed.overrides.repeating_track.has_value()) {
            repeating_track_ = *parsed.overrides.repeating_track;
        }

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

        current_track_ = context_processor_.get_current_track();

        is_playing_ = true;
        is_paused_ = false;
        is_buffering_ = true;
        position_ms_ = 0;
        duration_ms_ = 0;

        LOGI("ContextPlayerImpl.play: context_uri=%s", context_uri_.c_str());
        if (current_track_.has_value()) {
            LOGI("ContextPlayerImpl.play: playing uri=%s uid=%s",
                 current_track_->uri.c_str(), current_track_->uid.c_str());
            track_to_play = *current_track_;
            cb = play_track_callback_;
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
    if (cb && !track_to_play.uri.empty()) {
        cb(track_to_play, true);
    }
    return true;
}

bool ContextPlayerImpl::pause() {
    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        LOGI("ContextPlayer RoutingTrackPlayer: PauseOrAwaitPause active");
        is_playing_ = false;
        is_paused_ = true;
        is_buffering_ = false;
        if (audio_engine_) {
            audio_engine_->pause();
            position_ms_ = audio_engine_->getPositionMs();
        }
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    return true;
}

bool ContextPlayerImpl::resume() {
    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        LOGI("ContextPlayer RoutingTrackPlayer: PauseOrAwaitPause not active");
        is_playing_ = true;
        is_paused_ = false;
        if (audio_engine_) {
            audio_engine_->play();
        }
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    return true;
}

bool ContextPlayerImpl::seek_to(int64_t position_ms) {
    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        LOGI("ContextPlayer RoutingTrackPlayer: Seeking to %lld ms", static_cast<long long>(position_ms));
        seek_to_locked(position_ms);
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
            if (f == 1 && w == 2) { // Field 1: CommandOptions options
                uint64_t l = 0;
                if (!decode_varint(p, end, l) || p + l > end) break;
                const uint8_t* opt_p = p;
                const uint8_t* opt_end = p + l;
                while (opt_p < opt_end) {
                    uint64_t opt_tag = 0;
                    if (!decode_varint(opt_p, opt_end, opt_tag)) break;
                    uint32_t opt_f = static_cast<uint32_t>(opt_tag >> 3);
                    uint32_t opt_w = static_cast<uint32_t>(opt_tag & 0x07);
                    if (opt_f == 1) { // Field 1: override_restrictions (bool)
                        decode_bool_value(opt_p, opt_end, opt_w, override_restrictions);
                    } else {
                        if (!skip_field(opt_p, opt_end, opt_w)) break;
                    }
                }
                p += l;
            } else if (f == 3 && w == 2) { // Field 3: ContextTrack track
                uint64_t l = 0;
                if (!decode_varint(p, end, l) || p + l > end) break;
                decode_context_track(p, static_cast<size_t>(l), target_track);
                p += l;
            } else {
                if (!skip_field(p, end, w)) break;
            }
        }
    }

    PlayTrackCallback cb;
    context_view::Entry next_track;
    bool should_play = false;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!override_restrictions && !restrictions_engine_.get_custom_disallow_skipping_next().empty()) {
            LOGW("ContextPlayer: SkipNext restricted by custom policy");
            last_error_ = "SKIP_TO_NEXT_RESTRICTED";
            if (error_callback_) {
                error_callback_("SKIP_TO_NEXT_RESTRICTED", "Skipping to next track is restricted");
            }
            return false;
        }

        LOGI("ContextPlayer RoutingTrackPlayer: pause/stop player while advancing");
        if (audio_engine_) {
            audio_engine_->pause();
        }

        if (current_track_.has_value()) {
            LOGI("advanced_past_track: %s", current_track_->uri.c_str());
        }

        // Target track requested (1:1 with Spotify x0j0 case 25 / kax0)
        bool handled_target = false;
        if (!target_track.uri.empty() || !target_track.uid.empty()) {
            auto it = std::find_if(user_queue_.begin(), user_queue_.end(), [&](const context_view::Entry& e) {
                return (!target_track.uid.empty() && e.uid == target_track.uid) ||
                       (!target_track.uri.empty() && e.uri == target_track.uri);
            });
            if (it != user_queue_.end()) {
                current_track_ = *it;
                user_queue_.erase(user_queue_.begin(), it + 1);
                queue_revision_++;
                is_playing_ = true;
                is_paused_ = false;
                is_buffering_ = true;
                position_ms_ = 0;
                next_track = *current_track_;
                should_play = true;
                cb = play_track_callback_;
                handled_target = true;
            } else {
                bool found = false;
                if (!target_track.uid.empty()) {
                    found = context_processor_.skip_to_uid(target_track.uid);
                } else if (!target_track.uri.empty()) {
                    found = context_processor_.skip_to_uri(target_track.uri);
                }
                if (found) {
                    auto track = context_processor_.get_current_track();
                    if (track.has_value()) {
                        current_track_ = *track;
                        is_playing_ = true;
                        is_paused_ = false;
                        is_buffering_ = true;
                        position_ms_ = 0;
                        next_track = *current_track_;
                        should_play = true;
                        cb = play_track_callback_;
                        handled_target = true;
                    }
                }
            }
        }

        if (!handled_target) {
            if (!user_queue_.empty()) {
                current_track_ = user_queue_.front();
                user_queue_.erase(user_queue_.begin());
                queue_revision_++;
                is_playing_ = true;
                is_paused_ = false;
                is_buffering_ = true;
                position_ms_ = 0;
                next_track = *current_track_;
                should_play = true;
                cb = play_track_callback_;
                LOGI("preroll_track_advance to user queue track: %s", next_track.uri.c_str());
            } else {
                bool advanced = context_processor_.skip_next();
                if (!advanced && repeating_context_) {
                    context_processor_.skip_to_index(0);
                    advanced = true;
                }
                if (advanced) {
                    auto track = context_processor_.get_current_track();
                    if (track.has_value()) {
                        current_track_ = *track;
                        is_playing_ = true;
                        is_paused_ = false;
                        is_buffering_ = true;
                        position_ms_ = 0;
                        next_track = *current_track_;
                        should_play = true;
                        cb = play_track_callback_;
                        LOGI("preroll_track_advance to context track: %s", next_track.uri.c_str());
                    }
                } else {
                    is_playing_ = false;
                    is_paused_ = false;
                    is_buffering_ = false;
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

    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    if (should_play && cb) {
        cb(next_track, true);
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
            if (f == 1 && w == 2) { // Field 1: CommandOptions options
                uint64_t l = 0;
                if (!decode_varint(p, end, l) || p + l > end) break;
                const uint8_t* opt_p = p;
                const uint8_t* opt_end = p + l;
                while (opt_p < opt_end) {
                    uint64_t opt_tag = 0;
                    if (!decode_varint(opt_p, opt_end, opt_tag)) break;
                    uint32_t opt_f = static_cast<uint32_t>(opt_tag >> 3);
                    uint32_t opt_w = static_cast<uint32_t>(opt_tag & 0x07);
                    if (opt_f == 1) { // Field 1: override_restrictions (bool)
                        decode_bool_value(opt_p, opt_end, opt_w, override_restrictions);
                    } else {
                        if (!skip_field(opt_p, opt_end, opt_w)) break;
                    }
                }
                p += l;
            } else if (f == 2) { // Field 2: allow_seeking (bool)
                decode_bool_value(p, end, w, allow_seeking);
            } else if (f == 4 && w == 2) { // Field 4: ContextTrack track
                uint64_t l = 0;
                if (!decode_varint(p, end, l) || p + l > end) break;
                decode_context_track(p, static_cast<size_t>(l), target_track);
                p += l;
            } else {
                if (!skip_field(p, end, w)) break;
            }
        }
    }

    PlayTrackCallback cb;
    context_view::Entry prev_track;
    bool should_play = false;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!override_restrictions && !restrictions_engine_.get_custom_disallow_skipping_prev().empty()) {
            LOGW("ContextPlayer: SkipPrev restricted by custom policy");
            last_error_ = "SKIP_TO_PREV_RESTRICTED";
            if (error_callback_) {
                error_callback_("SKIP_TO_PREV_RESTRICTED", "Skipping to previous track is restricted");
            }
            return false;
        }

        int64_t current_pos = audio_engine_ ? audio_engine_->getPositionMs() : position_ms_;
        if (allow_seeking && current_pos > 3000) {
            LOGI("ContextPlayer RoutingTrackPlayer: Seeking to 0 ms (skip_prev restart pos=%lld)",
                 static_cast<long long>(current_pos));
            seek_to_locked(0);
            emit_state_locked();
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
        } else {
            if (audio_engine_) {
                audio_engine_->pause();
            }

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
                    current_track_ = *track;
                    is_playing_ = true;
                    is_paused_ = false;
                    is_buffering_ = true;
                    position_ms_ = 0;
                    prev_track = *current_track_;
                    should_play = true;
                    cb = play_track_callback_;
                    LOGI("did_advance_to_track: %s", prev_track.uri.c_str());
                }
            } else if (repeating_context_) {
                seek_to_locked(0);
            }

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
    if (should_play && cb) {
        cb(prev_track, true);
    }
    return should_play;
}

void ContextPlayerImpl::advance_to_next_track() {
    PlayTrackCallback cb;
    context_view::Entry next_track;
    bool should_play = false;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        LOGI("ContextPlayer RoutingTrackPlayer: pause/stop player while advancing");
        LOGI("drain_on_end_of_stream: end-of-stream, track_finished_playing");
        LOGI("ContextPlayerImpl.advanceToNextTrack");

        if (repeating_track_) {
            seek_to_locked(0);
            if (audio_engine_) {
                audio_engine_->play();
            }
            is_playing_ = true;
            is_paused_ = false;
            emit_state_locked();
            sc_cb = state_changed_callback_;
            sc_bytes = cached_state_bytes_;
        } else {
            if (current_track_.has_value()) {
                LOGI("advanced_past_track: %s", current_track_->uri.c_str());
            }

            if (!user_queue_.empty()) {
                current_track_ = user_queue_.front();
                user_queue_.erase(user_queue_.begin());
                queue_revision_++;
                is_playing_ = true;
                is_paused_ = false;
                is_buffering_ = true;
                position_ms_ = 0;
                next_track = *current_track_;
                should_play = true;
                cb = play_track_callback_;
                LOGI("preroll_track_advance to user queue track: %s", next_track.uri.c_str());
            } else {
                bool advanced = context_processor_.skip_next();
                if (!advanced && repeating_context_) {
                    context_processor_.skip_to_index(0);
                    advanced = true;
                }
                if (advanced) {
                    auto track = context_processor_.get_current_track();
                    if (track.has_value()) {
                        current_track_ = *track;
                        is_playing_ = true;
                        is_paused_ = false;
                        is_buffering_ = true;
                        position_ms_ = 0;
                        next_track = *current_track_;
                        should_play = true;
                        cb = play_track_callback_;
                        LOGI("preroll_track_advance to context track: %s", next_track.uri.c_str());
                    }
                } else {
                    is_playing_ = false;
                    is_paused_ = false;
                    is_buffering_ = false;
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

    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
    if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
    if (should_play && cb) {
        cb(next_track, true);
    }
}

void ContextPlayerImpl::on_track_loaded(bool success) {
    ErrorCallback err_cb;
    std::string err_code, err_msg;
    StateChangedCallback sc_cb;
    QueueChangedCallback qc_cb;
    std::vector<uint8_t> sc_bytes, qc_bytes;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (success) {
            is_buffering_ = false;
            is_playing_ = true;
            is_paused_ = false;
            if (audio_engine_) {
                audio_engine_->play();
                int64_t dur = audio_engine_->getDurationMs();
                if (dur > 0) duration_ms_ = dur;
            }
            LOGI("did_advance_to_track: %s",
                 current_track_.has_value() ? current_track_->uri.c_str() : "unknown");
        } else {
            is_buffering_ = false;
            is_playing_ = false;
            is_paused_ = false;
            last_error_ = "LOAD_FAILED";
            err_code = "LOAD_FAILED";
            err_msg = "AudioEngine failed to load requested track";
            err_cb = error_callback_;
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
    if (err_cb) {
        err_cb(err_code, err_msg);
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
            if (overrides.repeating_context.has_value()) {
                repeating_context_ = *overrides.repeating_context;
            }
            if (overrides.repeating_track.has_value()) {
                repeating_track_ = *overrides.repeating_track;
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
        repeating_context_ = repeating;
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
        repeating_track_ = repeating;
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
        {
            std::lock_guard<std::mutex> lock(mutex_);
            user_queue_.push_back(std::move(entry));
            queue_revision_++;
            emit_queue_locked();
            qc_cb = queue_changed_callback_;
            qc_bytes = cached_queue_bytes_;
        }
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
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
        {
            std::lock_guard<std::mutex> lock(mutex_);
            user_queue_ = std::move(tracks);
            queue_revision_++;
            emit_queue_locked();
            qc_cb = queue_changed_callback_;
            qc_bytes = cached_queue_bytes_;
        }
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
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
        {
            std::lock_guard<std::mutex> lock(mutex_);
            user_queue_.insert(user_queue_.begin(), tracks.begin(), tracks.end());
            queue_revision_++;
            emit_queue_locked();
            qc_cb = queue_changed_callback_;
            qc_bytes = cached_queue_bytes_;
        }
        if (qc_cb && !qc_bytes.empty()) qc_cb(qc_bytes.data(), qc_bytes.size());
        return true;
    }
    return false;
}

bool ContextPlayerImpl::stop() {
    StateChangedCallback sc_cb;
    std::vector<uint8_t> sc_bytes;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        is_playing_ = false;
        is_paused_ = false;
        is_buffering_ = false;
        position_ms_ = 0;
        if (audio_engine_) {
            audio_engine_->pause();
            audio_engine_->seekMs(0);
        }
        emit_state_locked();
        sc_cb = state_changed_callback_;
        sc_bytes = cached_state_bytes_;
    }
    if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
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
        if (parsed.overrides.repeating_context.has_value()) {
            repeating_context_ = *parsed.overrides.repeating_context;
        }
        if (parsed.overrides.repeating_track.has_value()) {
            repeating_track_ = *parsed.overrides.repeating_track;
        }

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

        current_track_ = context_processor_.get_current_track();
        is_playing_ = false;
        is_paused_ = true;
        is_buffering_ = false;
        position_ms_ = 0;

        LOGI("ContextPlayerImpl.preparePlay: context_uri=%s (ready to play)", context_uri_.c_str());

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
        std::vector<uint8_t> sc_bytes;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (current_track_.has_value() &&
                (current_track_->uri == entry.uri || current_track_->uid == entry.uid)) {
                for (const auto& [k, v] : entry.metadata) {
                    current_track_->metadata[k] = v;
                }
                emit_state_locked();
                sc_cb = state_changed_callback_;
                sc_bytes = cached_state_bytes_;
            }
        }
        if (sc_cb && !sc_bytes.empty()) sc_cb(sc_bytes.data(), sc_bytes.size());
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

    std::lock_guard<std::mutex> lock(mutex_);
    if (!target_session_id.empty()) {
        LOGI("ContextPlayerImpl.deleteSession target=%s current=%s",
             target_session_id.c_str(), session_id_.c_str());
    } else {
        LOGI("ContextPlayerImpl.deleteSession session_id=%s", session_id_.c_str());
    }
    session_id_.clear();
    session_command_id_.clear();
    signals_.clear();
    stop();
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

void ContextPlayerImpl::seek_to_locked(int64_t position_ms) {
    position_ms_ = position_ms;
    if (audio_engine_) {
        audio_engine_->seekMs(position_ms);
    }
}

void ContextPlayerImpl::update_position_and_duration_locked() {
    if (audio_engine_) {
        int64_t engine_pos = audio_engine_->getPositionMs();
        if (engine_pos >= 0) position_ms_ = engine_pos;
        int64_t engine_dur = audio_engine_->getDurationMs();
        if (engine_dur > 0) duration_ms_ = engine_dur;
    }
}

void ContextPlayerImpl::emit_state_locked() {
    update_position_and_duration_locked();

    const auto next_tracks = context_processor_.get_next_tracks(1);
    const bool has_next = !next_tracks.empty();
    const auto prev_tracks = context_processor_.get_prev_tracks();
    const bool has_prev = !prev_tracks.empty();
    const bool has_queue = !user_queue_.empty();

    const auto restrictions_bytes = restrictions_engine_.evaluate(
        is_playing_,
        is_paused_,
        has_prev,
        has_next,
        shuffling_,
        repeating_context_,
        repeating_track_,
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
    data.is_playing = is_playing_;
    data.is_paused = is_paused_;
    data.playback_speed = playback_speed_;
    data.position_as_of_timestamp = position_ms_;
    data.shuffling_context = shuffling_;
    data.repeating_context = repeating_context_;
    data.repeating_track = repeating_track_;
    data.is_buffering = is_buffering_;
    data.context_metadata = context_metadata_;
    data.page_metadata = page_metadata_;
    data.session_id = session_id_;
    data.signals = signals_;
    data.session_command_id = session_command_id_;
    data.play_origin = play_origin_;
    data.page_index = 0;
    data.track_index = context_processor_.get_current_index();

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
