#pragma once

#include "../network/AuthSessionStore.h"
#include "../network/NativeHttpClient.h"
#include "../network/NativeTrafficController.h"

#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <functional>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace spotify::metadata {

struct AudioFileDescriptor {
    std::string file_id_hex;
    int32_t format{0};
};

struct TrackInfo {
    std::string uri;
    std::string title;
    std::string artist_name;
    std::string artist_uri;
    std::string album_title;
    std::string album_uri;
    std::string image_small_url;
    std::string image_url;
    std::string image_large_url;
    std::string image_xlarge_url;
    int64_t duration_ms{0};
    bool is_explicit{false};
    std::vector<AudioFileDescriptor> files;
    std::vector<std::string> alternative_uris;
    std::string pass_through_url;
    bool track_v4_resolved{false};
    bool episode_v4_resolved{false};
    bool playback_trait_resolved{false};

    [[nodiscard]] bool hasPlayableSource() const noexcept {
        return !files.empty() || !pass_through_url.empty();
    }

    [[nodiscard]] bool hasDisplayMetadata() const noexcept {
        return (track_v4_resolved || episode_v4_resolved) && !title.empty();
    }
};

/// 1:1 equivalent of liborbit's `TrackInfoProvider`:
/// - Receives raw binary Kodiak extension payloads (`10`, `12`, `212`) from Dart via FFI
/// - Fetches `/extended-metadata/v0/extended-metadata` natively on cache misses (including relinking)
/// - Notifies `AudioTrackPlayer` and `ContextPlayerImpl` subscribers when metadata or audio file IDs arrive.
class TrackInfoProvider {
public:
    static constexpr const char* kDefaultSpclientBaseUrl = "https://spclient.wg.spotify.com";

    using MetadataChangedCallback = std::function<void(const std::string& uri, const TrackInfo& info)>;
    using PostTransportFn = std::function<network::HttpResponse(
        const std::string& url,
        const std::vector<uint8_t>& body,
        const std::string& content_type,
        const std::vector<std::pair<std::string, std::string>>& extra_headers)>;

    TrackInfoProvider(network::AuthSessionStore& auth_store,
                      network::NativeHttpClient& http_client);
    TrackInfoProvider(network::AuthSessionStore& auth_store,
                      PostTransportFn post_transport_fn);
    ~TrackInfoProvider();

    TrackInfoProvider(const TrackInfoProvider&) = delete;
    TrackInfoProvider& operator=(const TrackInfoProvider&) = delete;

    void set_spclient_base_url(const std::string& base_url);
    [[nodiscard]] std::string spclient_base_url() const;

    void seedExtensionPayload(int32_t extension_kind,
                              const std::string& entity_uri,
                              const uint8_t* payload,
                              size_t payload_len);

    [[nodiscard]] std::optional<TrackInfo> getCached(const std::string& entity_uri) const;

    /// Requests asynchronous native resolution if `entity_uri` lacks playable audio or display metadata.
    /// InteractivePlayback requests are placed at the front of the pending queue;
    /// BackgroundPrefetch requests are skipped while offline and placed at the back when online.
    void requestResolution(
        const std::string& entity_uri,
        network::AcquisitionIntent intent = network::AcquisitionIntent::InteractivePlayback);

    /// Cancels a queued (not yet in-flight) metadata resolution request when superseded by a track switch.
    void cancelResolution(const std::string& entity_uri);

    int32_t addListener(MetadataChangedCallback callback);
    void removeListener(int32_t listener_id);

private:
    enum class BatchFetchResult : uint8_t {
        Completed = 0,
        TransientNetworkFailure = 1,
    };

    void workerLoop();
    [[nodiscard]] network::HttpResponse executePost(
        const std::string& url,
        const std::vector<uint8_t>& body) const;
    BatchFetchResult fetchBatch(const std::vector<std::string>& uris,
                                network::TrafficPermit& permit);
    bool applyExtensionLocked(int32_t extension_kind,
                              const std::string& entity_uri,
                              const uint8_t* payload,
                              size_t payload_len,
                              TrackInfo& out_snapshot);
    void notifyListeners(const std::string& uri, const TrackInfo& info);

    static bool parseTrackV4Wire(const uint8_t* data, size_t len, TrackInfo& target);
    static bool parseEpisodeV4Wire(const uint8_t* data, size_t len, TrackInfo& target);
    static bool parsePlaybackTraitWire(const uint8_t* data, size_t len, TrackInfo& target);

    network::AuthSessionStore& auth_store_;
    network::NativeHttpClient* http_client_{nullptr};
    PostTransportFn post_transport_fn_;

    mutable std::mutex mutex_;
    std::string spclient_base_url_{kDefaultSpclientBaseUrl};
    std::unordered_map<std::string, TrackInfo> store_;
    std::deque<std::string> pending_queue_;
    std::unordered_set<std::string> queued_or_inflight_;
    std::condition_variable worker_cv_;
    std::atomic<bool> stop_worker_{false};
    std::thread worker_thread_;

    std::mutex listener_mutex_;
    int32_t next_listener_id_{1};
    std::unordered_map<int32_t, MetadataChangedCallback> listeners_;
};

} // namespace spotify::metadata
