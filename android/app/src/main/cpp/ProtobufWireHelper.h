#pragma once

#include "ContextViewEntry.h"

#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

namespace spotify::player {

using context_view::Entry;
using context_view::EntryType;

// ============================================================================
// Zero-dependency Google Protobuf wire-format encoder / decoder
// Conforms 1:1 to Spotify's com.spotify.player.esperanto.proto schema
// ============================================================================

inline void encode_varint(std::vector<uint8_t>& buf, uint64_t val) {
    while (val >= 0x80) {
        buf.push_back(static_cast<uint8_t>((val & 0x7F) | 0x80));
        val >>= 7;
    }
    buf.push_back(static_cast<uint8_t>(val & 0x7F));
}

inline bool decode_varint(const uint8_t*& ptr, const uint8_t* end, uint64_t& val) {
    val = 0;
    int shift = 0;
    while (ptr < end && shift < 64) {
        uint8_t byte = *ptr++;
        val |= (static_cast<uint64_t>(byte & 0x7F) << shift);
        if ((byte & 0x80) == 0) return true;
        shift += 7;
    }
    return false;
}

inline bool skip_field(const uint8_t*& ptr, const uint8_t* end, uint32_t wire_type) {
    switch (wire_type) {
        case 0: { // Varint
            uint64_t dummy;
            return decode_varint(ptr, end, dummy);
        }
        case 1: { // 64-bit
            if (ptr + 8 > end) return false;
            ptr += 8;
            return true;
        }
        case 2: { // Length-delimited
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len)) return false;
            if (ptr + len > end) return false;
            ptr += len;
            return true;
        }
        case 5: { // 32-bit
            if (ptr + 4 > end) return false;
            ptr += 4;
            return true;
        }
        default:
            return false;
    }
}

inline void encode_string_field(std::vector<uint8_t>& buf, uint32_t field_num, const std::string& str) {
    if (str.empty()) return;
    encode_varint(buf, (field_num << 3) | 2);
    encode_varint(buf, str.size());
    buf.insert(buf.end(), str.begin(), str.end());
}

inline void encode_submessage_field(std::vector<uint8_t>& buf, uint32_t field_num, const std::vector<uint8_t>& sub) {
    encode_varint(buf, (field_num << 3) | 2);
    encode_varint(buf, sub.size());
    buf.insert(buf.end(), sub.begin(), sub.end());
}

// ----------------------------------------------------------------------------
// ContextTrack:
// tag 1 (string): uri
// tag 2 (string): uid
// tag 3 (map<string, string>): metadata
// ----------------------------------------------------------------------------

inline std::vector<uint8_t> encode_context_track(const Entry& entry) {
    std::vector<uint8_t> buf;
    if (!entry.uri.empty()) {
        encode_string_field(buf, 1, entry.uri);
    }
    if (!entry.uid.empty()) {
        encode_string_field(buf, 2, entry.uid);
    }
    for (const auto& [k, v] : entry.metadata) {
        std::vector<uint8_t> map_entry;
        encode_string_field(map_entry, 1, k);
        encode_string_field(map_entry, 2, v);
        encode_submessage_field(buf, 3, map_entry);
    }
    return buf;
}

inline bool decode_context_track(const uint8_t* data, size_t size, Entry& out_entry) {
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) return false;
        uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);

        if (wire_type == 2) {
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || ptr + len > end) return false;
            const uint8_t* sub_ptr = ptr;
            ptr += len;

            if (field_num == 1) { // uri
                out_entry.uri.assign(reinterpret_cast<const char*>(sub_ptr), len);
            } else if (field_num == 2) { // uid
                out_entry.uid.assign(reinterpret_cast<const char*>(sub_ptr), len);
            } else if (field_num == 3) { // metadata
                const uint8_t* m_ptr = sub_ptr;
                const uint8_t* m_end = sub_ptr + len;
                std::string key, val;
                while (m_ptr < m_end) {
                    uint64_t m_tag = 0;
                    if (!decode_varint(m_ptr, m_end, m_tag)) break;
                    uint32_t m_field = static_cast<uint32_t>(m_tag >> 3);
                    uint32_t m_wire = static_cast<uint32_t>(m_tag & 0x07);
                    if (m_wire == 2) {
                        uint64_t m_len = 0;
                        if (!decode_varint(m_ptr, m_end, m_len) || m_ptr + m_len > m_end) break;
                        if (m_field == 1) {
                            key.assign(reinterpret_cast<const char*>(m_ptr), m_len);
                        } else if (m_field == 2) {
                            val.assign(reinterpret_cast<const char*>(m_ptr), m_len);
                        }
                        m_ptr += m_len;
                    } else {
                        if (!skip_field(m_ptr, m_end, m_wire)) break;
                    }
                }
                if (!key.empty()) {
                    out_entry.metadata[key] = val;
                }
            }
        } else {
            if (!skip_field(ptr, end, wire_type)) return false;
        }
    }

    if (out_entry.uri == "spotify:delimiter" || out_entry.uri == "spotify:meta:delimiter") {
        out_entry.type = EntryType::DELIMITER;
    } else {
        out_entry.type = EntryType::TRACK;
    }
    return true;
}

// ----------------------------------------------------------------------------
// ProvidedTrack:
// tag 1: ContextTrack
// tag 4: provider ("context")
// ----------------------------------------------------------------------------

inline std::vector<uint8_t> encode_provided_track(const Entry& entry) {
    std::vector<uint8_t> buf;
    auto track_buf = encode_context_track(entry);
    encode_submessage_field(buf, 1, track_buf);
    encode_string_field(buf, 4, "context");
    return buf;
}

// ----------------------------------------------------------------------------
// Queue:
// tag 1 (int64): queue_revision
// tag 2 (ProvidedTrack): track
// tag 3 (repeated ProvidedTrack): next_tracks
// tag 4 (repeated ProvidedTrack): prev_tracks
// ----------------------------------------------------------------------------

inline std::vector<uint8_t> encode_queue(
        const Entry* current_track,
        const std::vector<Entry>& next_tracks,
        const std::vector<Entry>& prev_tracks,
        int64_t queue_revision) {
    std::vector<uint8_t> buf;

    if (queue_revision != 0) {
        encode_varint(buf, (1 << 3) | 0);
        encode_varint(buf, static_cast<uint64_t>(queue_revision));
    }
    if (current_track) {
        auto cur_buf = encode_provided_track(*current_track);
        encode_submessage_field(buf, 2, cur_buf);
    }
    for (const auto& next : next_tracks) {
        auto next_buf = encode_provided_track(next);
        encode_submessage_field(buf, 3, next_buf);
    }
    for (const auto& prev : prev_tracks) {
        auto prev_buf = encode_provided_track(prev);
        encode_submessage_field(buf, 4, prev_buf);
    }
    return buf;
}

// ----------------------------------------------------------------------------
// ContextPage:
// tag 1: repeated ContextTrack tracks
// tag 2: map<string, string> metadata
// tag 3: string page_url
// tag 4: string next_page_url
// tag 5: bool is_loading
// ----------------------------------------------------------------------------

inline bool decode_context_page(
        const uint8_t* data,
        size_t size,
        std::string& out_page_url,
        std::string& out_next_page_url,
        std::vector<Entry>& out_tracks) {
    const uint8_t* ptr = data;
    const uint8_t* end = data + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!decode_varint(ptr, end, tag)) return false;
        uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);

        if (wire_type == 2) {
            uint64_t len = 0;
            if (!decode_varint(ptr, end, len) || ptr + len > end) return false;
            const uint8_t* sub_ptr = ptr;
            ptr += len;

            if (field_num == 1) { // tracks: repeated ContextTrack
                Entry entry;
                if (decode_context_track(sub_ptr, len, entry)) {
                    out_tracks.push_back(std::move(entry));
                }
            } else if (field_num == 3) { // page_url
                out_page_url.assign(reinterpret_cast<const char*>(sub_ptr), len);
            } else if (field_num == 4) { // next_page_url
                out_next_page_url.assign(reinterpret_cast<const char*>(sub_ptr), len);
            }
        } else {
            if (!skip_field(ptr, end, wire_type)) return false;
        }
    }
    return true;
}

} // namespace spotify::player
