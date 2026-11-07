#include "TrackInfoProvider.h"

#include "../ProtobufWireHelper.h"

#include <android/log.h>
#include <cstring>

#define TIP_LOG_TAG "MusifyTrackInfo"
#define TIP_LOGI(...) __android_log_print(ANDROID_LOG_INFO, TIP_LOG_TAG, __VA_ARGS__)
#define TIP_LOGW(...) __android_log_print(ANDROID_LOG_WARN, TIP_LOG_TAG, __VA_ARGS__)

namespace spotify::metadata {

namespace {
constexpr const char* kPrimarySpclient = "https://gae2-spclient.spotify.com";
constexpr const char* kFallbackSpclient = "https://spclient.wg.spotify.com";
constexpr const char* kExtendedMetadataPath = "/extended-metadata/v0/extended-metadata";

constexpr int32_t kKindTrackV4 = 10;
constexpr int32_t kKindEpisodeV4 = 12;
constexpr int32_t kKindPlaybackTrait = 212;

int32_t decodeZigZag32(uint64_t raw) noexcept {
    const auto n = static_cast<uint32_t>(raw);
    return static_cast<int32_t>((n >> 1) ^ (~(n & 1U) + 1U));
}

std::string bytesToLowerHex(const uint8_t* bytes, size_t len) {
    static constexpr const char kHex[] = "0123456789abcdef";
    std::string out;
    out.resize(len * 2);
    for (size_t i = 0; i < len; ++i) {
        out[i * 2] = kHex[(bytes[i] >> 4) & 0x0F];
        out[i * 2 + 1] = kHex[bytes[i] & 0x0F];
    }
    return out;
}

std::string encode16ByteGidBase62(const uint8_t* gid16) {
    static constexpr const char kAlphabet[] =
        "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    uint8_t acc[16];
    std::memcpy(acc, gid16, 16);
    char out[22];
    for (int pos = 21; pos >= 0; --pos) {
        uint32_t rem = 0;
        for (int b = 0; b < 16; ++b) {
            const uint32_t cur = (rem << 8) | acc[b];
            acc[b] = static_cast<uint8_t>(cur / 62U);
            rem = cur % 62U;
        }
        out[pos] = kAlphabet[rem];
    }
    return std::string(out, 22);
}

void parseImageMessage(const uint8_t* data,
                       size_t len,
                       std::string& default_url,
                       std::string& small_url,
                       std::string& large_url,
                       std::string& xlarge_url) {
    const uint8_t* ptr = data;
    const uint8_t* end = data + len;
    std::string hex_id;
    uint64_t size_enum = 0;

    while (ptr < end) {
        uint64_t tag = 0;
        if (!player::decode_varint(ptr, end, tag)) return;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);

        if (field_num == 1 && wire_type == 2) {
            uint64_t blen = 0;
            if (!player::decode_varint(ptr, end, blen) || ptr + blen > end) return;
            if (blen > 0) {
                hex_id = bytesToLowerHex(ptr, static_cast<size_t>(blen));
            }
            ptr += blen;
        } else if (field_num == 2 && wire_type == 0) {
            if (!player::decode_varint(ptr, end, size_enum)) return;
        } else {
            if (!player::skip_field(ptr, end, wire_type)) return;
        }
    }

    if (hex_id.empty()) return;
    const std::string url = "https://i.scdn.co/image/" + hex_id;
    switch (size_enum) {
        case 0:
            if (default_url.empty()) default_url = url;
            break;
        case 1:
            if (small_url.empty()) small_url = url;
            break;
        case 2:
            if (large_url.empty()) large_url = url;
            break;
        case 3:
            if (xlarge_url.empty()) xlarge_url = url;
            break;
        default:
            if (default_url.empty()) default_url = url;
            break;
    }
}

void parseImageGroupMessage(const uint8_t* data,
                            size_t len,
                            TrackInfo& target) {
    const uint8_t* ptr = data;
    const uint8_t* end = data + len;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!player::decode_varint(ptr, end, tag)) return;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);

        if (field_num == 1 && wire_type == 2) {
            uint64_t ilen = 0;
            if (!player::decode_varint(ptr, end, ilen) || ptr + ilen > end) return;
            parseImageMessage(
                ptr,
                static_cast<size_t>(ilen),
                target.image_url,
                target.image_small_url,
                target.image_large_url,
                target.image_xlarge_url);
            ptr += ilen;
        } else {
            if (!player::skip_field(ptr, end, wire_type)) return;
        }
    }
    if (target.image_url.empty()) {
        if (!target.image_large_url.empty()) target.image_url = target.image_large_url;
        else if (!target.image_small_url.empty()) target.image_url = target.image_small_url;
        else if (!target.image_xlarge_url.empty()) target.image_url = target.image_xlarge_url;
    }
}

bool parseAudioFileMsg(const uint8_t* data, size_t len, AudioFileDescriptor& out_file) {
    const uint8_t* ptr = data;
    const uint8_t* end = data + len;
    bool has_id = false;
    bool has_fmt = false;

    while (ptr < end) {
        uint64_t tag = 0;
        if (!player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);

        if (field_num == 1 && wire_type == 2) {
            uint64_t blen = 0;
            if (!player::decode_varint(ptr, end, blen) || ptr + blen > end) return false;
            if (blen > 0) {
                out_file.file_id_hex = bytesToLowerHex(ptr, static_cast<size_t>(blen));
                has_id = !out_file.file_id_hex.empty();
            }
            ptr += blen;
        } else if (field_num == 2 && wire_type == 0) {
            uint64_t fmt = 0;
            if (!player::decode_varint(ptr, end, fmt)) return false;
            out_file.format = static_cast<int32_t>(fmt);
            has_fmt = true;
        } else {
            if (!player::skip_field(ptr, end, wire_type)) return false;
        }
    }
    return has_id && has_fmt;
}

std::vector<uint8_t> buildBatchedExtendedMetadataRequest(
    const std::string& country,
    const std::string& catalogue,
    const std::vector<std::string>& uris) {
    std::vector<uint8_t> req;

    std::vector<uint8_t> header;
    player::encode_string_field(header, 1, country.empty() ? "US" : country);
    player::encode_string_field(header, 2, catalogue.empty() ? "free" : catalogue);
    player::encode_submessage_field(req, 1, header);

    for (const auto& uri : uris) {
        std::vector<uint8_t> entity_req;
        player::encode_string_field(entity_req, 1, uri);

        auto append_query = [&entity_req](uint32_t kind) {
            std::vector<uint8_t> q;
            player::encode_varint(q, (1U << 3) | 0U);
            player::encode_varint(q, kind);
            player::encode_submessage_field(entity_req, 2, q);
        };

        if (uri.rfind("spotify:episode:", 0) == 0) {
            append_query(static_cast<uint32_t>(kKindEpisodeV4));
            append_query(static_cast<uint32_t>(kKindPlaybackTrait));
        } else {
            append_query(static_cast<uint32_t>(kKindTrackV4));
            append_query(static_cast<uint32_t>(kKindPlaybackTrait));
        }

        player::encode_submessage_field(req, 2, entity_req);
    }

    return req;
}

} // namespace

TrackInfoProvider::TrackInfoProvider(network::AuthSessionStore& auth_store,
                                     network::NativeHttpClient& http_client)
    : auth_store_(auth_store),
      http_client_(http_client),
      worker_thread_(&TrackInfoProvider::workerLoop, this) {}

TrackInfoProvider::~TrackInfoProvider() {
    stop_worker_.store(true, std::memory_order_release);
    worker_cv_.notify_all();
    if (worker_thread_.joinable()) {
        worker_thread_.join();
    }
}

void TrackInfoProvider::seedExtensionPayload(int32_t extension_kind,
                                             const std::string& entity_uri,
                                             const uint8_t* payload,
                                             size_t payload_len) {
    if (entity_uri.empty() || !payload || payload_len == 0) return;

    TrackInfo snapshot;
    bool changed = false;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        changed = applyExtensionLocked(extension_kind, entity_uri, payload, payload_len, snapshot);
    }
    if (changed) {
        notifyListeners(entity_uri, snapshot);
    }
}

std::optional<TrackInfo> TrackInfoProvider::getCached(const std::string& entity_uri) const {
    if (entity_uri.empty()) return std::nullopt;
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = store_.find(entity_uri);
    if (it == store_.end()) return std::nullopt;
    return it->second;
}

void TrackInfoProvider::requestResolution(const std::string& entity_uri) {
    if (entity_uri.empty()) return;
    const bool is_track = entity_uri.rfind("spotify:track:", 0) == 0;
    const bool is_episode = entity_uri.rfind("spotify:episode:", 0) == 0;
    if (!is_track && !is_episode) return;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        auto it = store_.find(entity_uri);
        if (it != store_.end() && it->second.hasPlayableSource()) {
            return;
        }
        if (queued_or_inflight_.find(entity_uri) != queued_or_inflight_.end()) {
            return;
        }
        queued_or_inflight_.insert(entity_uri);
        pending_queue_.push_back(entity_uri);
    }
    worker_cv_.notify_one();
}

int32_t TrackInfoProvider::addListener(MetadataChangedCallback callback) {
    std::lock_guard<std::mutex> lock(listener_mutex_);
    const int32_t id = next_listener_id_++;
    listeners_[id] = std::move(callback);
    return id;
}

void TrackInfoProvider::removeListener(int32_t listener_id) {
    std::lock_guard<std::mutex> lock(listener_mutex_);
    listeners_.erase(listener_id);
}

void TrackInfoProvider::notifyListeners(const std::string& uri, const TrackInfo& info) {
    std::vector<MetadataChangedCallback> copy;
    {
        std::lock_guard<std::mutex> lock(listener_mutex_);
        copy.reserve(listeners_.size());
        for (const auto& kv : listeners_) {
            if (kv.second) copy.push_back(kv.second);
        }
    }
    for (const auto& cb : copy) {
        cb(uri, info);
    }
}

void TrackInfoProvider::workerLoop() {
    while (!stop_worker_.load(std::memory_order_acquire)) {
        std::vector<std::string> batch;
        {
            std::unique_lock<std::mutex> lock(mutex_);
            worker_cv_.wait(lock, [this]() {
                return stop_worker_.load(std::memory_order_acquire) || !pending_queue_.empty();
            });
            if (stop_worker_.load(std::memory_order_acquire)) break;

            while (!pending_queue_.empty() && batch.size() < 25) {
                batch.push_back(std::move(pending_queue_.front()));
                pending_queue_.pop_front();
            }
        }

        if (!batch.empty()) {
            fetchBatch(batch);
            {
                std::lock_guard<std::mutex> lock(mutex_);
                for (const auto& u : batch) {
                    queued_or_inflight_.erase(u);
                }
            }
        }
    }
}

void TrackInfoProvider::fetchBatch(const std::vector<std::string>& uris) {
    const auto creds = auth_store_.snapshot();
    const std::vector<uint8_t> req_bytes =
        buildBatchedExtendedMetadataRequest(creds.country, creds.catalogue, uris);

    const char* hosts[2] = {kPrimarySpclient, kFallbackSpclient};
    network::HttpResponse resp;
    for (const char* host : hosts) {
        resp = http_client_.post(
            std::string(host) + kExtendedMetadataPath,
            req_bytes,
            "application/x-protobuf",
            {{"Accept", "application/x-protobuf"}},
            8000,
            12000,
            true);
        if (resp.isSuccess() && !resp.body.empty()) break;
    }

    if (!resp.isSuccess() || resp.body.empty()) {
        TIP_LOGW("Native extended-metadata POST failed (status=%d)", resp.status_code);
        return;
    }

    struct ParsedCell {
        int32_t kind{0};
        std::string uri;
        const uint8_t* value_ptr{nullptr};
        size_t value_len{0};
    };
    std::vector<ParsedCell> cells;

    const uint8_t* ptr = resp.body.data();
    const uint8_t* end = ptr + resp.body.size();
    while (ptr < end) {
        uint64_t tag = 0;
        if (!player::decode_varint(ptr, end, tag)) break;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);

        if (field_num == 2 && wire_type == 2) {
            uint64_t arr_len = 0;
            if (!player::decode_varint(ptr, end, arr_len) || ptr + arr_len > end) break;
            const uint8_t* a_ptr = ptr;
            const uint8_t* a_end = ptr + arr_len;
            ptr += arr_len;

            uint64_t ext_kind = 0;
            struct RawItem {
                const uint8_t* ptr;
                size_t len;
            };
            std::vector<RawItem> raw_items;

            while (a_ptr < a_end) {
                uint64_t a_tag = 0;
                if (!player::decode_varint(a_ptr, a_end, a_tag)) break;
                const uint32_t a_field = static_cast<uint32_t>(a_tag >> 3);
                const uint32_t a_wire = static_cast<uint32_t>(a_tag & 0x07);
                if (a_field == 2 && a_wire == 0) {
                    if (!player::decode_varint(a_ptr, a_end, ext_kind)) break;
                } else if (a_field == 3 && a_wire == 2) {
                    uint64_t d_len = 0;
                    if (!player::decode_varint(a_ptr, a_end, d_len) || a_ptr + d_len > a_end) break;
                    raw_items.push_back(RawItem{a_ptr, static_cast<size_t>(d_len)});
                    a_ptr += d_len;
                } else {
                    if (!player::skip_field(a_ptr, a_end, a_wire)) break;
                }
            }

            for (const auto& item : raw_items) {
                const uint8_t* d_ptr = item.ptr;
                const uint8_t* d_end = item.ptr + item.len;
                int32_t status_code = 200;
                std::string entity_uri;
                const uint8_t* any_val_ptr = nullptr;
                size_t any_val_len = 0;

                while (d_ptr < d_end) {
                    uint64_t d_tag = 0;
                    if (!player::decode_varint(d_ptr, d_end, d_tag)) break;
                    const uint32_t d_field = static_cast<uint32_t>(d_tag >> 3);
                    const uint32_t d_wire = static_cast<uint32_t>(d_tag & 0x07);

                    if (d_field == 1 && d_wire == 2) {
                        uint64_t h_len = 0;
                        if (!player::decode_varint(d_ptr, d_end, h_len) || d_ptr + h_len > d_end) break;
                        const uint8_t* h_ptr = d_ptr;
                        const uint8_t* h_end = d_ptr + h_len;
                        d_ptr += h_len;
                        while (h_ptr < h_end) {
                            uint64_t h_tag = 0;
                            if (!player::decode_varint(h_ptr, h_end, h_tag)) break;
                            if ((h_tag >> 3) == 1 && (h_tag & 0x07) == 0) {
                                uint64_t sc = 0;
                                if (!player::decode_varint(h_ptr, h_end, sc)) break;
                                status_code = static_cast<int32_t>(sc);
                            } else {
                                if (!player::skip_field(h_ptr, h_end, static_cast<uint32_t>(h_tag & 0x07))) break;
                            }
                        }
                    } else if (d_field == 2 && d_wire == 2) {
                        uint64_t u_len = 0;
                        if (!player::decode_varint(d_ptr, d_end, u_len) || d_ptr + u_len > d_end) break;
                        entity_uri.assign(reinterpret_cast<const char*>(d_ptr), u_len);
                        d_ptr += u_len;
                    } else if (d_field == 3 && d_wire == 2) {
                        uint64_t any_len = 0;
                        if (!player::decode_varint(d_ptr, d_end, any_len) || d_ptr + any_len > d_end) break;
                        const uint8_t* y_ptr = d_ptr;
                        const uint8_t* y_end = d_ptr + any_len;
                        d_ptr += any_len;
                        while (y_ptr < y_end) {
                            uint64_t y_tag = 0;
                            if (!player::decode_varint(y_ptr, y_end, y_tag)) break;
                            if ((y_tag >> 3) == 2 && (y_tag & 0x07) == 2) {
                                uint64_t v_len = 0;
                                if (!player::decode_varint(y_ptr, y_end, v_len) || y_ptr + v_len > y_end) break;
                                any_val_ptr = y_ptr;
                                any_val_len = static_cast<size_t>(v_len);
                                y_ptr += v_len;
                            } else {
                                if (!player::skip_field(y_ptr, y_end, static_cast<uint32_t>(y_tag & 0x07))) break;
                            }
                        }
                    } else {
                        if (!player::skip_field(d_ptr, d_end, d_wire)) break;
                    }
                }

                if (status_code == 200 && !entity_uri.empty() && any_val_ptr && any_val_len > 0) {
                    cells.push_back(ParsedCell{
                        static_cast<int32_t>(ext_kind),
                        std::move(entity_uri),
                        any_val_ptr,
                        any_val_len,
                    });
                }
            }
        } else {
            if (!player::skip_field(ptr, end, wire_type)) break;
        }
    }

    std::vector<std::pair<std::string, TrackInfo>> notifications;
    std::unordered_map<std::string, std::string> relink_map; // original_uri -> alt_uri

    {
        std::lock_guard<std::mutex> lock(mutex_);
        for (const auto& cell : cells) {
            TrackInfo snap;
            if (applyExtensionLocked(cell.kind, cell.uri, cell.value_ptr, cell.value_len, snap)) {
                notifications.emplace_back(cell.uri, snap);
                if (cell.kind == kKindTrackV4 && snap.files.empty() && !snap.alternative_uris.empty()) {
                    const std::string& alt = snap.alternative_uris.front();
                    if (!alt.empty() && alt != cell.uri) {
                        relink_map[cell.uri] = alt;
                    }
                }
            }
        }
    }

    // Relink fallback: fetch alternative track metadata if primary TrackV4 had empty files
    if (!relink_map.empty()) {
        std::vector<std::string> alt_uris;
        alt_uris.reserve(relink_map.size());
        for (const auto& kv : relink_map) {
            alt_uris.push_back(kv.second);
        }

        const std::vector<uint8_t> alt_req =
            buildBatchedExtendedMetadataRequest(creds.country, creds.catalogue, alt_uris);
        const auto alt_resp = http_client_.post(
            std::string(kPrimarySpclient) + kExtendedMetadataPath,
            alt_req,
            "application/x-protobuf",
            {{"Accept", "application/x-protobuf"}},
            8000,
            12000,
            true);

        if (alt_resp.isSuccess() && !alt_resp.body.empty()) {
            const uint8_t* aptr = alt_resp.body.data();
            const uint8_t* aend = aptr + alt_resp.body.size();
            std::unordered_map<std::string, TrackInfo> alt_infos;

            while (aptr < aend) {
                uint64_t tag = 0;
                if (!player::decode_varint(aptr, aend, tag)) break;
                if ((tag >> 3) == 2 && (tag & 0x07) == 2) {
                    uint64_t arr_len = 0;
                    if (!player::decode_varint(aptr, aend, arr_len) || aptr + arr_len > aend) break;
                    const uint8_t* sub_p = aptr;
                    const uint8_t* sub_e = aptr + arr_len;
                    aptr += arr_len;

                    while (sub_p < sub_e) {
                        uint64_t stag = 0;
                        if (!player::decode_varint(sub_p, sub_e, stag)) break;
                        if ((stag >> 3) == 3 && (stag & 0x07) == 2) {
                            uint64_t dlen = 0;
                            if (!player::decode_varint(sub_p, sub_e, dlen) || sub_p + dlen > sub_e) break;
                            const uint8_t* dp = sub_p;
                            const uint8_t* de = sub_p + dlen;
                            sub_p += dlen;
                            std::string e_uri;
                            const uint8_t* vp = nullptr;
                            size_t vl = 0;
                            while (dp < de) {
                                uint64_t dtag = 0;
                                if (!player::decode_varint(dp, de, dtag)) break;
                                if ((dtag >> 3) == 2 && (dtag & 0x07) == 2) {
                                    uint64_t ul = 0;
                                    if (!player::decode_varint(dp, de, ul) || dp + ul > de) break;
                                    e_uri.assign(reinterpret_cast<const char*>(dp), ul);
                                    dp += ul;
                                } else if ((dtag >> 3) == 3 && (dtag & 0x07) == 2) {
                                    uint64_t al = 0;
                                    if (!player::decode_varint(dp, de, al) || dp + al > de) break;
                                    const uint8_t* yp = dp;
                                    const uint8_t* ye = dp + al;
                                    dp += al;
                                    while (yp < ye) {
                                        uint64_t ytag = 0;
                                        if (!player::decode_varint(yp, ye, ytag)) break;
                                        if ((ytag >> 3) == 2 && (ytag & 0x07) == 2) {
                                            uint64_t vlen = 0;
                                            if (!player::decode_varint(yp, ye, vlen) || yp + vlen > ye) break;
                                            vp = yp;
                                            vl = static_cast<size_t>(vlen);
                                            yp += vlen;
                                        } else {
                                            if (!player::skip_field(yp, ye, static_cast<uint32_t>(ytag & 0x07))) break;
                                        }
                                    }
                                } else {
                                    if (!player::skip_field(dp, de, static_cast<uint32_t>(dtag & 0x07))) break;
                                }
                            }
                            if (!e_uri.empty() && vp && vl > 0) {
                                TrackInfo alt_ti;
                                alt_ti.uri = e_uri;
                                if (parseTrackV4Wire(vp, vl, alt_ti)) {
                                    alt_infos[e_uri] = std::move(alt_ti);
                                }
                            }
                        } else {
                            if (!player::skip_field(sub_p, sub_e, static_cast<uint32_t>(stag & 0x07))) break;
                        }
                    }
                } else {
                    if (!player::skip_field(aptr, aend, static_cast<uint32_t>(tag & 0x07))) break;
                }
            }

            {
                std::lock_guard<std::mutex> lock(mutex_);
                for (const auto& [orig_uri, alt_uri] : relink_map) {
                    auto it_alt = alt_infos.find(alt_uri);
                    if (it_alt != alt_infos.end() && !it_alt->second.files.empty()) {
                        auto& target = store_[orig_uri];
                        for (const auto& af : it_alt->second.files) {
                            bool exists = false;
                            for (const auto& existing : target.files) {
                                if (existing.format == af.format && existing.file_id_hex == af.file_id_hex) {
                                    exists = true;
                                    break;
                                }
                            }
                            if (!exists) {
                                target.files.push_back(af);
                            }
                        }
                        if (target.title.empty()) target.title = it_alt->second.title;
                        if (target.duration_ms <= 0) target.duration_ms = it_alt->second.duration_ms;
                        notifications.emplace_back(orig_uri, target);
                    }
                }
            }
        }
    }

    for (const auto& [uri, info] : notifications) {
        notifyListeners(uri, info);
    }
}

bool TrackInfoProvider::applyExtensionLocked(int32_t extension_kind,
                                             const std::string& entity_uri,
                                             const uint8_t* payload,
                                             size_t payload_len,
                                             TrackInfo& out_snapshot) {
    TrackInfo& entry = store_[entity_uri];
    entry.uri = entity_uri;

    bool ok = false;
    if (extension_kind == kKindTrackV4) {
        ok = parseTrackV4Wire(payload, payload_len, entry);
    } else if (extension_kind == kKindEpisodeV4) {
        ok = parseEpisodeV4Wire(payload, payload_len, entry);
    } else if (extension_kind == kKindPlaybackTrait) {
        ok = parsePlaybackTraitWire(payload, payload_len, entry);
    }

    if (ok) {
        out_snapshot = entry;
    }
    return ok;
}

bool TrackInfoProvider::parseTrackV4Wire(const uint8_t* data, size_t len, TrackInfo& target) {
    const uint8_t* ptr = data;
    const uint8_t* end = data + len;

    std::vector<AudioFileDescriptor> direct_files;
    std::vector<AudioFileDescriptor> alt_embedded_files;
    std::vector<std::string> alt_uris;
    std::string artist_joined;
    std::string first_artist_uri;

    while (ptr < end) {
        uint64_t tag = 0;
        if (!player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);

        if (field_num == 2 && wire_type == 2) { // name
            uint64_t slen = 0;
            if (!player::decode_varint(ptr, end, slen) || ptr + slen > end) return false;
            target.title.assign(reinterpret_cast<const char*>(ptr), slen);
            ptr += slen;
        } else if (field_num == 3 && wire_type == 2) { // album
            uint64_t alen = 0;
            if (!player::decode_varint(ptr, end, alen) || ptr + alen > end) return false;
            const uint8_t* ap = ptr;
            const uint8_t* ae = ptr + alen;
            ptr += alen;
            while (ap < ae) {
                uint64_t atag = 0;
                if (!player::decode_varint(ap, ae, atag)) break;
                const uint32_t afield = static_cast<uint32_t>(atag >> 3);
                const uint32_t awire = static_cast<uint32_t>(atag & 0x07);
                if (afield == 1 && awire == 2) {
                    uint64_t glen = 0;
                    if (!player::decode_varint(ap, ae, glen) || ap + glen > ae) break;
                    if (glen == 16) {
                        target.album_uri = "spotify:album:" + encode16ByteGidBase62(ap);
                    }
                    ap += glen;
                } else if (afield == 2 && awire == 2) {
                    uint64_t nlen = 0;
                    if (!player::decode_varint(ap, ae, nlen) || ap + nlen > ae) break;
                    target.album_title.assign(reinterpret_cast<const char*>(ap), nlen);
                    ap += nlen;
                } else if (afield == 9 && awire == 2) {
                    uint64_t ilen = 0;
                    if (!player::decode_varint(ap, ae, ilen) || ap + ilen > ae) break;
                    parseImageMessage(
                        ap,
                        static_cast<size_t>(ilen),
                        target.image_url,
                        target.image_small_url,
                        target.image_large_url,
                        target.image_xlarge_url);
                    ap += ilen;
                } else if (afield == 17 && awire == 2) {
                    uint64_t iglen = 0;
                    if (!player::decode_varint(ap, ae, iglen) || ap + iglen > ae) break;
                    parseImageGroupMessage(ap, static_cast<size_t>(iglen), target);
                    ap += iglen;
                } else {
                    if (!player::skip_field(ap, ae, awire)) break;
                }
            }
        } else if (field_num == 4 && wire_type == 2) { // artist
            uint64_t arlen = 0;
            if (!player::decode_varint(ptr, end, arlen) || ptr + arlen > end) return false;
            const uint8_t* arp = ptr;
            const uint8_t* are = ptr + arlen;
            ptr += arlen;
            std::string ar_name;
            std::string ar_uri;
            while (arp < are) {
                uint64_t artag = 0;
                if (!player::decode_varint(arp, are, artag)) break;
                const uint32_t arf = static_cast<uint32_t>(artag >> 3);
                const uint32_t arw = static_cast<uint32_t>(artag & 0x07);
                if (arf == 1 && arw == 2) {
                    uint64_t glen = 0;
                    if (!player::decode_varint(arp, are, glen) || arp + glen > are) break;
                    if (glen == 16) {
                        ar_uri = "spotify:artist:" + encode16ByteGidBase62(arp);
                    }
                    arp += glen;
                } else if (arf == 2 && arw == 2) {
                    uint64_t nlen = 0;
                    if (!player::decode_varint(arp, are, nlen) || arp + nlen > are) break;
                    ar_name.assign(reinterpret_cast<const char*>(arp), nlen);
                    arp += nlen;
                } else {
                    if (!player::skip_field(arp, are, arw)) break;
                }
            }
            if (!ar_name.empty()) {
                if (!artist_joined.empty()) artist_joined += ", ";
                artist_joined += ar_name;
            }
            if (first_artist_uri.empty() && !ar_uri.empty()) {
                first_artist_uri = std::move(ar_uri);
            }
        } else if (field_num == 7 && wire_type == 0) { // sint32 duration (ZigZag!)
            uint64_t raw_dur = 0;
            if (!player::decode_varint(ptr, end, raw_dur)) return false;
            const int32_t dur_ms = decodeZigZag32(raw_dur);
            if (dur_ms > 0) target.duration_ms = static_cast<int64_t>(dur_ms);
        } else if (field_num == 9 && wire_type == 0) { // bool explicit
            uint64_t exp_val = 0;
            if (!player::decode_varint(ptr, end, exp_val)) return false;
            target.is_explicit = (exp_val != 0);
        } else if (field_num == 12 && wire_type == 2) { // repeated AudioFile file
            uint64_t flen = 0;
            if (!player::decode_varint(ptr, end, flen) || ptr + flen > end) return false;
            AudioFileDescriptor desc;
            if (parseAudioFileMsg(ptr, static_cast<size_t>(flen), desc)) {
                direct_files.push_back(std::move(desc));
            }
            ptr += flen;
        } else if (field_num == 13 && wire_type == 2) { // repeated Track alternative
            uint64_t alt_len = 0;
            if (!player::decode_varint(ptr, end, alt_len) || ptr + alt_len > end) return false;
            const uint8_t* alt_p = ptr;
            const uint8_t* alt_e = ptr + alt_len;
            ptr += alt_len;
            while (alt_p < alt_e) {
                uint64_t atag = 0;
                if (!player::decode_varint(alt_p, alt_e, atag)) break;
                const uint32_t af = static_cast<uint32_t>(atag >> 3);
                const uint32_t aw = static_cast<uint32_t>(atag & 0x07);
                if (af == 1 && aw == 2) {
                    uint64_t glen = 0;
                    if (!player::decode_varint(alt_p, alt_e, glen) || alt_p + glen > alt_e) break;
                    if (glen == 16) {
                        alt_uris.push_back("spotify:track:" + encode16ByteGidBase62(alt_p));
                    }
                    alt_p += glen;
                } else if (af == 12 && aw == 2) {
                    uint64_t flen = 0;
                    if (!player::decode_varint(alt_p, alt_e, flen) || alt_p + flen > alt_e) break;
                    AudioFileDescriptor desc;
                    if (alt_embedded_files.empty() &&
                        parseAudioFileMsg(alt_p, static_cast<size_t>(flen), desc)) {
                        alt_embedded_files.push_back(std::move(desc));
                    } else if (!alt_embedded_files.empty()) {
                        AudioFileDescriptor extra_desc;
                        if (parseAudioFileMsg(alt_p, static_cast<size_t>(flen), extra_desc)) {
                            alt_embedded_files.push_back(std::move(extra_desc));
                        }
                    }
                    alt_p += flen;
                } else {
                    if (!player::skip_field(alt_p, alt_e, aw)) break;
                }
            }
        } else {
            if (!player::skip_field(ptr, end, wire_type)) return false;
        }
    }

    if (!artist_joined.empty()) target.artist_name = std::move(artist_joined);
    if (!first_artist_uri.empty()) target.artist_uri = std::move(first_artist_uri);

    // Merge incoming Vorbis / alternative files into target.files without discarding any existing hosted MP4 files
    const auto& incoming = !direct_files.empty() ? direct_files : alt_embedded_files;
    for (const auto& inf : incoming) {
        bool exists = false;
        for (const auto& existing : target.files) {
            if (existing.format == inf.format && existing.file_id_hex == inf.file_id_hex) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            target.files.push_back(inf);
        }
    }

    if (!alt_uris.empty()) {
        target.alternative_uris = std::move(alt_uris);
    }
    target.track_v4_resolved = true;
    return true;
}

bool TrackInfoProvider::parseEpisodeV4Wire(const uint8_t* data, size_t len, TrackInfo& target) {
    const uint8_t* ptr = data;
    const uint8_t* end = data + len;

    while (ptr < end) {
        uint64_t tag = 0;
        if (!player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);

        if (field_num == 2 && wire_type == 2) { // name
            uint64_t slen = 0;
            if (!player::decode_varint(ptr, end, slen) || ptr + slen > end) return false;
            target.title.assign(reinterpret_cast<const char*>(ptr), slen);
            ptr += slen;
        } else if (field_num == 7 && wire_type == 0) { // sint32 duration
            uint64_t raw_dur = 0;
            if (!player::decode_varint(ptr, end, raw_dur)) return false;
            const int32_t dur_ms = decodeZigZag32(raw_dur);
            if (dur_ms > 0) target.duration_ms = static_cast<int64_t>(dur_ms);
        } else if (field_num == 70 && wire_type == 0) { // bool explicit
            uint64_t exp_val = 0;
            if (!player::decode_varint(ptr, end, exp_val)) return false;
            target.is_explicit = (exp_val != 0);
        } else if (field_num == 68 && wire_type == 2) { // ImageGroup cover_image
            uint64_t ilen = 0;
            if (!player::decode_varint(ptr, end, ilen) || ptr + ilen > end) return false;
            parseImageGroupMessage(ptr, static_cast<size_t>(ilen), target);
            ptr += ilen;
        } else if (field_num == 71 && wire_type == 2) { // Show show
            uint64_t slen = 0;
            if (!player::decode_varint(ptr, end, slen) || ptr + slen > end) return false;
            const uint8_t* sp = ptr;
            const uint8_t* se = ptr + slen;
            ptr += slen;
            while (sp < se) {
                uint64_t stag = 0;
                if (!player::decode_varint(sp, se, stag)) break;
                const uint32_t sf = static_cast<uint32_t>(stag >> 3);
                const uint32_t sw = static_cast<uint32_t>(stag & 0x07);
                if (sf == 1 && sw == 2) {
                    uint64_t glen = 0;
                    if (!player::decode_varint(sp, se, glen) || sp + glen > se) break;
                    if (glen == 16) {
                        target.album_uri = "spotify:show:" + encode16ByteGidBase62(sp);
                    }
                    sp += glen;
                } else if (sf == 2 && sw == 2) {
                    uint64_t nlen = 0;
                    if (!player::decode_varint(sp, se, nlen) || sp + nlen > se) break;
                    target.album_title.assign(reinterpret_cast<const char*>(sp), nlen);
                    sp += nlen;
                } else if (sf == 66 && sw == 2) { // publisher
                    uint64_t plen = 0;
                    if (!player::decode_varint(sp, se, plen) || sp + plen > se) break;
                    target.artist_name.assign(reinterpret_cast<const char*>(sp), plen);
                    sp += plen;
                } else {
                    if (!player::skip_field(sp, se, sw)) break;
                }
            }
        } else {
            if (!player::skip_field(ptr, end, wire_type)) return false;
        }
    }

    target.episode_v4_resolved = true;
    return true;
}

bool TrackInfoProvider::parsePlaybackTraitWire(const uint8_t* data, size_t len, TrackInfo& target) {
    const uint8_t* ptr = data;
    const uint8_t* end = data + len;

    std::vector<AudioFileDescriptor> hosted_files;
    std::string pass_through;

    while (ptr < end) {
        uint64_t tag = 0;
        if (!player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);

        if (field_num == 1 && wire_type == 2) { // repeated AudioMapEntry audio
            uint64_t elen = 0;
            if (!player::decode_varint(ptr, end, elen) || ptr + elen > end) return false;
            const uint8_t* ep = ptr;
            const uint8_t* ee = ptr + elen;
            ptr += elen;

            while (ep < ee) {
                uint64_t etag = 0;
                if (!player::decode_varint(ep, ee, etag)) break;
                const uint32_t ef = static_cast<uint32_t>(etag >> 3);
                const uint32_t ew = static_cast<uint32_t>(etag & 0x07);

                if (ef == 2 && ew == 2) { // AudioPlayback value
                    uint64_t vlen = 0;
                    if (!player::decode_varint(ep, ee, vlen) || ep + vlen > ee) break;
                    const uint8_t* vp = ep;
                    const uint8_t* ve = ep + vlen;
                    ep += vlen;

                    while (vp < ve) {
                        uint64_t vtag = 0;
                        if (!player::decode_varint(vp, ve, vtag)) break;
                        const uint32_t vf = static_cast<uint32_t>(vtag >> 3);
                        const uint32_t vw = static_cast<uint32_t>(vtag & 0x07);

                        if (vf == 1 && vw == 2) { // AudioPassThrough
                            uint64_t plen = 0;
                            if (!player::decode_varint(vp, ve, plen) || vp + plen > ve) break;
                            const uint8_t* pp = vp;
                            const uint8_t* pe = vp + plen;
                            vp += plen;
                            while (pp < pe) {
                                uint64_t ptag = 0;
                                if (!player::decode_varint(pp, pe, ptag)) break;
                                if ((ptag >> 3) == 1 && (ptag & 0x07) == 2) { // FlatFile
                                    uint64_t flen = 0;
                                    if (!player::decode_varint(pp, pe, flen) || pp + flen > pe) break;
                                    const uint8_t* fp = pp;
                                    const uint8_t* fe = pp + flen;
                                    pp += flen;
                                    while (fp < fe) {
                                        uint64_t ftag = 0;
                                        if (!player::decode_varint(fp, fe, ftag)) break;
                                        if ((ftag >> 3) == 1 && (ftag & 0x07) == 2) {
                                            uint64_t ulen = 0;
                                            if (!player::decode_varint(fp, fe, ulen) || fp + ulen > fe) break;
                                            if (pass_through.empty() && ulen > 0) {
                                                pass_through.assign(reinterpret_cast<const char*>(fp), ulen);
                                            }
                                            fp += ulen;
                                        } else {
                                            if (!player::skip_field(fp, fe, static_cast<uint32_t>(ftag & 0x07))) break;
                                        }
                                    }
                                } else {
                                    if (!player::skip_field(pp, pe, static_cast<uint32_t>(ptag & 0x07))) break;
                                }
                            }
                        } else if (vf == 2 && vw == 2) { // AudioHosted
                            uint64_t hlen = 0;
                            if (!player::decode_varint(vp, ve, hlen) || vp + hlen > ve) break;
                            const uint8_t* hp = vp;
                            const uint8_t* he = vp + hlen;
                            vp += hlen;
                            while (hp < he) {
                                uint64_t htag = 0;
                                if (!player::decode_varint(hp, he, htag)) break;
                                const uint32_t hf = static_cast<uint32_t>(htag >> 3);
                                const uint32_t hw = static_cast<uint32_t>(htag & 0x07);
                                if (hf == 1 && hw == 2) { // repeated AudioFile files
                                    uint64_t aflen = 0;
                                    if (!player::decode_varint(hp, he, aflen) || hp + aflen > he) break;
                                    AudioFileDescriptor desc;
                                    if (parseAudioFileMsg(hp, static_cast<size_t>(aflen), desc)) {
                                        hosted_files.push_back(std::move(desc));
                                    }
                                    hp += aflen;
                                } else {
                                    if (!player::skip_field(hp, he, hw)) break;
                                }
                            }
                        } else {
                            if (!player::skip_field(vp, ve, vw)) break;
                        }
                    }
                } else {
                    if (!player::skip_field(ep, ee, ew)) break;
                }
            }
        } else {
            if (!player::skip_field(ptr, end, wire_type)) return false;
        }
    }

    // Merge hosted MP4 files into target.files without discarding existing Ogg Vorbis files
    if (!hosted_files.empty()) {
        for (auto& hf : hosted_files) {
            bool exists = false;
            for (const auto& existing : target.files) {
                if (existing.format == hf.format && existing.file_id_hex == hf.file_id_hex) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                target.files.push_back(std::move(hf));
            }
        }
    }
    if (!pass_through.empty()) {
        target.pass_through_url = std::move(pass_through);
    }
    target.playback_trait_resolved = true;
    TIP_LOGI("Seeded PlaybackTrait for %s (hostedFiles=%zu, passThrough=%d, totalFiles=%zu)",
             target.uri.c_str(),
             hosted_files.size(),
             target.pass_through_url.empty() ? 0 : 1,
             target.files.size());
    return true;
}

} // namespace spotify::metadata
