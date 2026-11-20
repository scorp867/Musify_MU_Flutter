// ============================================================================
// Replicated Spotify Connect LocalDeviceReporter & Zeroconf getInfo Prober
// Sources (`liborbit-jni-spotify.so` arm64):
// - LocalDeviceReporter & `PUT connect-state/v1/update_local_devices`
//   (`0xdc3b90..0xdc42bc`, `0xdedec0..0xdeffff`, application/x-protobuf uncompressed)
// - `ConnectZeroconfLoginProtocol` (`0xdcf304..0xdd232c`,
//   `?action=getInfo&version=2.12.0` @ `0xdcf3dc`)
// - `Cluster.needs_local_devices` tag 13 gating (`0xdb7060`)
// ============================================================================

#include "LocalDeviceReporter.h"

#include <algorithm>
#include <cctype>
#include <utility>

#include "../network/NativeLog.h"
#include "dealer/DealerMessageParser.h"

namespace spotify::connectstate {

namespace {

std::string to_upper_ascii(std::string_view input) {
    std::string out(input.size(), '\0');
    for (size_t i = 0; i < input.size(); ++i) {
        out[i] = static_cast<char>(
            std::toupper(static_cast<unsigned char>(input[i])));
    }
    return out;
}

bool contains_ci(std::string_view haystack, std::string_view needle) {
    if (needle.empty() || haystack.size() < needle.size()) {
        return false;
    }
    const std::string h = to_upper_ascii(haystack);
    const std::string n = to_upper_ascii(needle);
    return h.find(n) != std::string::npos;
}

std::string normalize_cpath(std::string_view raw) {
    if (raw.empty()) {
        return "/";
    }
    if (raw.front() == '/') {
        return std::string(raw);
    }
    std::string out;
    out.reserve(raw.size() + 1);
    out.push_back('/');
    out.append(raw);
    return out;
}

std::string format_host_for_url(std::string_view host) {
    if (host.find(':') != std::string_view::npos &&
        !host.empty() && host.front() != '[') {
        std::string wrapped;
        wrapped.reserve(host.size() + 2);
        wrapped.push_back('[');
        wrapped.append(host);
        wrapped.push_back(']');
        return wrapped;
    }
    return std::string(host);
}

std::string cache_key_for_record(const NsdServiceRecord& rec) {
    return rec.host + ":" + std::to_string(rec.port) + ":" + normalize_cpath(rec.cpath);
}

bool is_valid_host(std::string_view host) {
    if (host.empty() || host.size() > 255) {
        return false;
    }
    for (char c : host) {
        const unsigned char uc = static_cast<unsigned char>(c);
        if (uc <= 0x20 || c == '/' || c == '?' || c == '#' || c == '@') {
            return false;
        }
    }
    return true;
}

}  // namespace

LocalDeviceReporter::LocalDeviceReporter(
    ConnectStateClientImpl& client,
    ConnectDevicesImpl& devices,
    network::NativeHttpClient& http_client)
    : LocalDeviceReporter(
          client,
          devices,
          [&http_client](const std::string& url, const network::HttpRequestOptions& options) {
              return http_client.get(url, {}, options);
          }) {}

LocalDeviceReporter::LocalDeviceReporter(
    ConnectStateClientImpl& client,
    ConnectDevicesImpl& devices,
    ZeroconfGetFn zeroconf_get_fn)
    : client_(client),
      devices_(devices),
      zeroconf_get_fn_(std::move(zeroconf_get_fn)) {}

LocalDeviceReporter::~LocalDeviceReporter() {
    stop();
}

void LocalDeviceReporter::start() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (worker_running_) {
        return;
    }
    atomic_stop_.store(false, std::memory_order_release);
    stop_requested_ = false;
    worker_running_ = true;
    worker_thread_ = std::thread(&LocalDeviceReporter::worker_loop, this);
}

void LocalDeviceReporter::stop() {
    atomic_stop_.store(true, std::memory_order_release);
    nsd_epoch_.fetch_add(1, std::memory_order_acq_rel);
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!worker_running_ && !worker_thread_.joinable()) {
            return;
        }
        stop_requested_ = true;
        services_dirty_ = false;
        report_dirty_ = false;
    }
    cv_.notify_all();
    if (worker_thread_.joinable()) {
        worker_thread_.join();
    }
    {
        std::lock_guard<std::mutex> lock(mutex_);
        worker_running_ = false;
        stop_requested_ = false;
    }
}

void LocalDeviceReporter::reset() {
    nsd_epoch_.fetch_add(1, std::memory_order_acq_rel);
    {
        std::lock_guard<std::mutex> lock(mutex_);
        latest_records_.clear();
        probe_cache_.clear();
        services_dirty_ = false;
        report_dirty_ = false;
        needs_local_devices_ = false;
    }
    cv_.notify_all();
}

void LocalDeviceReporter::set_devices_changed_callback(DevicesChangedCallback callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    devices_changed_callback_ = std::move(callback);
}

void LocalDeviceReporter::notify_devices_changed() {
    DevicesChangedCallback cb;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        cb = devices_changed_callback_;
    }
    if (cb) {
        cb();
    }
}

DeviceType LocalDeviceReporter::parse_device_type_string(std::string_view raw) {
    const std::string upper = to_upper_ascii(raw);
    if (upper == "COMPUTER") return DeviceType::COMPUTER;
    if (upper == "TABLET") return DeviceType::TABLET;
    if (upper == "SMARTPHONE") return DeviceType::SMARTPHONE;
    if (upper == "SPEAKER") return DeviceType::SPEAKER;
    if (upper == "TV") return DeviceType::TV;
    if (upper == "AVR") return DeviceType::AVR;
    if (upper == "STB") return DeviceType::STB;
    if (upper == "AUDIO_DONGLE" || upper == "AUDIODONGLE") return DeviceType::AUDIO_DONGLE;
    if (upper == "GAME_CONSOLE" || upper == "GAMECONSOLE") return DeviceType::GAME_CONSOLE;
    if (upper == "CAST_VIDEO" || upper == "CASTVIDEO") return DeviceType::CAST_VIDEO;
    if (upper == "CAST_AUDIO" || upper == "CASTAUDIO") return DeviceType::CAST_AUDIO;
    if (upper == "AUTOMOBILE") return DeviceType::AUTOMOBILE;
    if (upper == "SMARTWATCH") return DeviceType::SMARTWATCH;
    if (upper == "CHROMEBOOK") return DeviceType::CHROMEBOOK;
    if (upper == "CAR_THING" || upper == "CARTHING") return DeviceType::CAR_THING;
    if (upper == "OBSERVER") return DeviceType::OBSERVER;
    if (upper == "HOME_THING" || upper == "HOMETHING") return DeviceType::HOME_THING;
    if (upper == "UNKNOWN_SPOTIFY") return DeviceType::UNKNOWN_SPOTIFY;
    return DeviceType::SPEAKER;
}

IncarnationType LocalDeviceReporter::infer_incarnation_type(
    const NsdServiceRecord& record,
    DeviceType device_type) {
    if (device_type == DeviceType::CAST_AUDIO ||
        device_type == DeviceType::CAST_VIDEO ||
        contains_ci(record.stack, "CAST") ||
        contains_ci(record.service_name, "CAST")) {
        return IncarnationType::CAST;
    }
    if (contains_ci(record.stack, "DIAL")) {
        return IncarnationType::DIAL;
    }
    return IncarnationType::ZEROCONF;
}

bool LocalDeviceReporter::parse_nsd_services_json(
    std::string_view json_utf8,
    std::vector<NsdServiceRecord>& out_records) {
    out_records.clear();
    if (json_utf8.empty()) {
        return false;
    }
    const auto parsed = json::parse_json(json_utf8);
    if (!parsed.has_value()) {
        return false;
    }

    const json::JsonValue::Array* items = nullptr;
    if (parsed->is_array()) {
        items = &parsed->array_value;
    } else if (parsed->is_object()) {
        if (const auto* services_val = parsed->find("services");
            services_val != nullptr && services_val->is_array()) {
            items = &services_val->array_value;
        } else {
            return false;
        }
    } else {
        return false;
    }

    out_records.reserve(items->size());
    for (const auto& item : *items) {
        if (!item.is_object()) {
            CONNECT_LOGW("LocalDeviceReporter: skipping non-object NSD service entry");
            continue;
        }
        NsdServiceRecord rec;
        if (const auto name = item.get_string("serviceName"); name.has_value()) {
            rec.service_name = *name;
        } else if (const auto alt_name = item.get_string("name"); alt_name.has_value()) {
            rec.service_name = *alt_name;
        }

        if (const auto host = item.get_string("host"); host.has_value()) {
            rec.host = *host;
        } else if (const auto ip = item.get_string("ip"); ip.has_value()) {
            rec.host = *ip;
        }

        int64_t port_raw = 0;
        if (const auto p = item.get_int64("port"); p.has_value()) {
            port_raw = *p;
        }
        if (!is_valid_host(rec.host) || port_raw <= 0 || port_raw > 65535) {
            CONNECT_LOGW(
                "LocalDeviceReporter: skipping invalid NSD entry service=%s port=%lld",
                rec.service_name.c_str(),
                static_cast<long long>(port_raw));
            continue;
        }
        rec.port = static_cast<uint16_t>(port_raw);

        if (const auto cp = item.get_string("cPath"); cp.has_value()) {
            rec.cpath = normalize_cpath(*cp);
        } else if (const auto cp_alt = item.get_string("cpath"); cp_alt.has_value()) {
            rec.cpath = normalize_cpath(*cp_alt);
        } else {
            rec.cpath = "/";
        }

        if (const auto ver = item.get_string("version"); ver.has_value()) {
            rec.version = *ver;
        }
        if (const auto stk = item.get_string("stack"); stk.has_value()) {
            rec.stack = *stk;
        }

        out_records.push_back(std::move(rec));
    }
    return true;
}

std::string LocalDeviceReporter::build_zeroconf_get_info_url(
    const NsdServiceRecord& record) {
    const std::string cpath = normalize_cpath(record.cpath);
    const std::string host = format_host_for_url(record.host);
    std::string url = "http://" + host + ":" + std::to_string(record.port) + cpath;
    if (cpath.find('?') != std::string::npos) {
        url += "&action=getInfo&version=2.12.0";
    } else {
        url += "?action=getInfo&version=2.12.0";
    }
    return url;
}

bool LocalDeviceReporter::parse_zeroconf_get_info_json(
    std::string_view response_body,
    const NsdServiceRecord& record,
    DiscoveredLocalEntry& out_entry) {
    const auto parsed = json::parse_json(response_body);
    if (!parsed.has_value() || !parsed->is_object()) {
        return false;
    }

    const auto device_id = parsed->get_string("deviceID");
    if (!device_id.has_value() || device_id->empty()) {
        return false;
    }

    DiscoveredLocalEntry entry;
    entry.device.device_id = *device_id;
    entry.device.local_ip = record.host;
    entry.port = record.port;

    if (const auto remote_name = parsed->get_string("remoteName");
        remote_name.has_value() && !remote_name->empty()) {
        entry.device.device_name = *remote_name;
    } else if (!record.service_name.empty()) {
        entry.device.device_name = record.service_name;
    } else {
        entry.device.device_name = *device_id;
    }

    if (const auto dtype = parsed->get_string("deviceType"); dtype.has_value()) {
        entry.device.device_type = parse_device_type_string(*dtype);
    } else {
        entry.device.device_type = DeviceType::SPEAKER;
    }

    if (const auto brand = parsed->get_string("brandDisplayName"); brand.has_value()) {
        entry.device.brand = *brand;
    }
    if (const auto model = parsed->get_string("modelDisplayName"); model.has_value()) {
        entry.device.model = *model;
    }
    if (const auto cid = parsed->get_string("clientID"); cid.has_value()) {
        entry.device.client_id = *cid;
    }
    if (const auto pid = parsed->get_string("productID"); pid.has_value()) {
        entry.device.product_id = *pid;
    }
    if (const auto dedup = parsed->get_string("deduplicationId"); dedup.has_value()) {
        entry.deduplication_id = *dedup;
    }
    if (const auto alias_id = parsed->get_uint32("aliasId"); alias_id.has_value()) {
        entry.device.alias_id = *alias_id;
    }
    if (const auto license = parsed->get_string("license"); license.has_value()) {
        entry.device.license = *license;
    }
    if (const auto voice = parsed->get_string("voiceSupport"); voice.has_value()) {
        entry.device.is_voice_enabled = (*voice == "YES" || *voice == "true" || *voice == "1");
    } else if (const auto voice_bool = parsed->get_bool("voiceSupport"); voice_bool.has_value()) {
        entry.device.is_voice_enabled = *voice_bool;
    }
    if (const auto caps = parsed->get_string("connectCapabilities"); caps.has_value()) {
        entry.device.connect_capabilities = *caps;
    }
    entry.device.supports_on_demand = true;
    entry.device.supported_media_types = {"audio/track", "audio/episode"};

    entry.incarnation_type = infer_incarnation_type(record, entry.device.device_type);
    out_entry = std::move(entry);
    return true;
}

int32_t LocalDeviceReporter::update_nsd_services(std::string_view services_json_utf8) {
    std::vector<NsdServiceRecord> parsed_records;
    if (!parse_nsd_services_json(services_json_utf8, parsed_records)) {
        CONNECT_LOGW(
            "LocalDeviceReporter::update_nsd_services: invalid NSD JSON (%zu bytes)",
            services_json_utf8.size());
        return -1;
    }

    const size_t record_count = parsed_records.size();
    nsd_epoch_.fetch_add(1, std::memory_order_acq_rel);
    {
        std::lock_guard<std::mutex> lock(mutex_);
        latest_records_ = std::move(parsed_records);
        services_dirty_ = true;
    }
    CONNECT_LOGI(
        "LocalDeviceReporter: queued NSD snapshot (%zu services)",
        record_count);
    cv_.notify_one();
    return 0;
}

void LocalDeviceReporter::set_needs_local_devices(bool needs_local_devices) {
    bool wake = false;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        const bool became_needed = needs_local_devices && !needs_local_devices_;
        needs_local_devices_ = needs_local_devices;
        if (became_needed) {
            report_dirty_ = true;
            wake = true;
        }
    }
    if (wake) {
        CONNECT_LOGI("LocalDeviceReporter: Cluster.needs_local_devices transitioned false -> true");
        cv_.notify_one();
    }
}

bool LocalDeviceReporter::needs_local_devices() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return needs_local_devices_;
}

void LocalDeviceReporter::trigger_report_if_needed() {
    bool wake = false;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (needs_local_devices_) {
            report_dirty_ = true;
            wake = true;
        }
    }
    if (wake) {
        cv_.notify_one();
    }
}

void LocalDeviceReporter::probe_and_apply_services(
    const std::vector<NsdServiceRecord>& records,
    uint64_t epoch) {
    std::vector<DiscoveredLocalEntry> discovered;
    discovered.reserve(records.size());
    const auto now_tp = std::chrono::steady_clock::now();

    for (const auto& rec : records) {
        if (atomic_stop_.load(std::memory_order_acquire) ||
            nsd_epoch_.load(std::memory_order_acquire) != epoch) {
            return;
        }

        const std::string key = cache_key_for_record(rec);
        {
            std::lock_guard<std::mutex> lock(mutex_);
            const auto cache_it = probe_cache_.find(key);
            if (cache_it != probe_cache_.end()) {
                const auto age_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                                        now_tp - cache_it->second.fetched_at)
                                        .count();
                if (age_ms >= 0 && age_ms < kGetInfoCacheTtlMs) {
                    discovered.push_back(cache_it->second.entry);
                    continue;
                }
            }
        }

        if (!zeroconf_get_fn_) {
            continue;
        }

        const std::string url = build_zeroconf_get_info_url(rec);
        network::HttpRequestOptions opts;
        opts.connect_timeout_ms = kZeroconfConnectTimeoutMs;
        opts.read_timeout_ms = kZeroconfReadTimeoutMs;
        opts.include_spotify_auth = false;
        opts.include_cookie = false;
        opts.cancel_pred = [this, epoch]() {
            return atomic_stop_.load(std::memory_order_acquire) ||
                   nsd_epoch_.load(std::memory_order_acquire) != epoch;
        };

        const network::HttpResponse resp = zeroconf_get_fn_(url, opts);
        if (atomic_stop_.load(std::memory_order_acquire) ||
            nsd_epoch_.load(std::memory_order_acquire) != epoch) {
            return;
        }

        if (!resp.isSuccess() || resp.body.empty()) {
            CONNECT_LOGW(
                "LocalDeviceReporter: Zeroconf getInfo failed url=%s transport_ok=%d http=%d",
                sanitize_url_for_log(url).c_str(),
                resp.transport_ok ? 1 : 0,
                resp.status_code);
            continue;
        }

        const std::string_view body_view(
            reinterpret_cast<const char*>(resp.body.data()),
            resp.body.size());
        DiscoveredLocalEntry entry;
        if (!parse_zeroconf_get_info_json(body_view, rec, entry)) {
            CONNECT_LOGW(
                "LocalDeviceReporter: Zeroconf getInfo parse failed url=%s",
                sanitize_url_for_log(url).c_str());
            continue;
        }

        {
            std::lock_guard<std::mutex> lock(mutex_);
            probe_cache_[key] = CachedProbeEntry{
                .entry = entry,
                .fetched_at = std::chrono::steady_clock::now(),
            };
        }
        discovered.push_back(std::move(entry));
    }

    devices_.apply_local_devices(std::move(discovered));
    notify_devices_changed();

    bool should_report = false;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (needs_local_devices_) {
            report_dirty_ = true;
            should_report = true;
        }
    }
    if (should_report) {
        report_local_devices_to_backend();
    }
}

void LocalDeviceReporter::report_local_devices_to_backend() {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!needs_local_devices_) {
            report_dirty_ = false;
            return;
        }
        report_dirty_ = false;
    }

    const std::string local_id = devices_.local_device_id();
    if (local_id.empty()) {
        CONNECT_LOGD("LocalDeviceReporter: skipping update_local_devices (local_device_id empty)");
        return;
    }
    if (client_.connection_id().empty()) {
        CONNECT_LOGD("LocalDeviceReporter: skipping update_local_devices (connection_id empty)");
        return;
    }

    UpdateLocalDevicesRequest req;
    req.reporting_device_id = local_id;
    req.local_devices = devices_.local_devices_snapshot();

    const SimpleHttpResult res = client_.update_local_devices(req);
    if (!res.ok) {
        CONNECT_LOGW(
            "LocalDeviceReporter: update_local_devices failed count=%zu http=%d err=%s",
            req.local_devices.size(),
            res.http_status,
            res.error_message.c_str());
    } else {
        CONNECT_LOGI(
            "LocalDeviceReporter: uploaded %zu local devices to backend (http=%d)",
            req.local_devices.size(),
            res.http_status);
    }
}

void LocalDeviceReporter::worker_loop() {
    while (true) {
        bool do_services = false;
        bool do_report = false;
        std::vector<NsdServiceRecord> records_snapshot;
        uint64_t epoch = 0;

        {
            std::unique_lock<std::mutex> lock(mutex_);
            cv_.wait(lock, [this]() {
                return stop_requested_ || services_dirty_ ||
                       (report_dirty_ && needs_local_devices_);
            });
            if (stop_requested_) {
                break;
            }
            if (services_dirty_) {
                do_services = true;
                services_dirty_ = false;
                records_snapshot = latest_records_;
                epoch = nsd_epoch_.load(std::memory_order_acquire);
            } else if (report_dirty_ && needs_local_devices_) {
                do_report = true;
            }
        }

        if (do_services) {
            probe_and_apply_services(records_snapshot, epoch);
        } else if (do_report) {
            report_local_devices_to_backend();
        }
    }
}

}  // namespace spotify::connectstate
