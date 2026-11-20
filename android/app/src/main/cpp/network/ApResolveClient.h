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

#pragma once

#include "NativeHttpClient.h"

#include <cstdint>
#include <functional>
#include <string>
#include <string_view>
#include <vector>

namespace spotify::network {

struct ApResolveResult {
    bool ok{false};
    bool used_fallback{true};
    int32_t http_status{0};
    std::string spclient_base_url{"https://spclient.wg.spotify.com/"};
    std::string spclient_global_url{"https://spclient.wg.spotify.com/"};
    std::string dealer_ws_url{"wss://dealer.g2.spotify.com:443/"};
    std::vector<std::string> spclient_regional_hosts;
    std::vector<std::string> spclient_global_hosts;
    std::vector<std::string> dealer_g2_hosts;
    std::vector<std::string> accesspoint_hosts;
    std::string error_message;
};

class ApResolveClient {
public:
    static constexpr const char* kApResolveEndpoint = "https://apresolve.spotify.com/v2";
    static constexpr const char* kFallbackSpclientBaseUrl = "https://spclient.wg.spotify.com/";
    static constexpr const char* kFallbackDealerWsUrl = "wss://dealer.g2.spotify.com:443/";

    using TransportFn = std::function<HttpResponse(const std::string& url)>;

    explicit ApResolveClient(NativeHttpClient& http_client = NativeHttpClient::defaultInstance());
    explicit ApResolveClient(TransportFn transport_fn);
    ~ApResolveClient() = default;

    ApResolveClient(const ApResolveClient&) = delete;
    ApResolveClient& operator=(const ApResolveClient&) = delete;

    /// Executes `GET https://apresolve.spotify.com/v2?time=<epoch>&type=accesspoint&type=spclient&type=dealer-g2`
    /// (unauthenticated, no cookies) and normalizes `spclient` (`https://.../`) and `dealer-g2`
    /// (`wss://...:443/`), falling back to `https://spclient.wg.spotify.com/` and
    /// `wss://dealer.g2.spotify.com:443/` if offline or malformed.
    [[nodiscard]] ApResolveResult resolve(
        int connect_timeout_ms = 5000,
        int read_timeout_ms = 5000,
        const CancelPredicate& cancel_pred = nullptr) const;

    [[nodiscard]] static std::string build_request_url(int64_t epoch_seconds);

    [[nodiscard]] static std::string normalize_spclient_url(std::string_view raw_host_or_url);
    [[nodiscard]] static std::string normalize_dealer_ws_url(std::string_view raw_host_or_url);

    [[nodiscard]] static ApResolveResult parse_response_json(
        std::string_view json_body,
        int32_t http_status = 200);

    [[nodiscard]] static ApResolveResult fallback_result(
        std::string error_message = {},
        int32_t http_status = 0);

private:
    NativeHttpClient* http_client_{nullptr};
    TransportFn transport_fn_;
};

}  // namespace spotify::network
