// ============================================================================
// 1:1 Replicated Spotify ContextResolveClient & Player JSON Codec
// Sources (`liborbit-jni-spotify.so` arm64):
// - ContextResolveSetupImpl @ 0xe02668..0xe04104
// - `hm://` normalization @ 0xe0340c
// - `context://` normalization @ 0xe02ad8
// - `context-page://` normalization @ 0xe03264
// - `Accept: application/json` header @ 0xe03488
// - Default fallback `https://spclient.wg.spotify.com/` (`0x350245` @ `0xb1d15c`)
// ============================================================================

#pragma once

#include "../ContextViewEntry.h"
#include "../network/NativeHttpClient.h"

#include <cstdint>
#include <functional>
#include <map>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>
#include <vector>

namespace spotify::player {

namespace json {

/// Lightweight RFC 8259 JSON DOM value with zero external or `connect/` dependencies.
struct JsonValue {
    enum class Type : uint8_t {
        kNull = 0,
        kBool = 1,
        kInt = 2,
        kDouble = 3,
        kString = 4,
        kArray = 5,
        kObject = 6,
    };

    Type type{Type::kNull};
    bool bool_value{false};
    int64_t int_value{0};
    double double_value{0.0};
    std::string string_value;
    std::vector<JsonValue> array_value;
    std::map<std::string, JsonValue> object_value;

    [[nodiscard]] bool is_null() const noexcept { return type == Type::kNull; }
    [[nodiscard]] bool is_bool() const noexcept { return type == Type::kBool; }
    [[nodiscard]] bool is_int() const noexcept { return type == Type::kInt; }
    [[nodiscard]] bool is_double() const noexcept { return type == Type::kDouble; }
    [[nodiscard]] bool is_number() const noexcept {
        return type == Type::kInt || type == Type::kDouble;
    }
    [[nodiscard]] bool is_string() const noexcept { return type == Type::kString; }
    [[nodiscard]] bool is_array() const noexcept { return type == Type::kArray; }
    [[nodiscard]] bool is_object() const noexcept { return type == Type::kObject; }

    [[nodiscard]] const JsonValue* find(std::string_view key) const noexcept;
    [[nodiscard]] std::optional<std::string> get_string(std::string_view key) const;
    [[nodiscard]] std::optional<bool> get_bool(std::string_view key) const noexcept;
    [[nodiscard]] std::optional<int64_t> get_int64(std::string_view key) const noexcept;
    [[nodiscard]] std::optional<double> get_double(std::string_view key) const noexcept;
};

/// Parses a complete UTF-8 JSON document strictly according to RFC 8259.
[[nodiscard]] std::optional<JsonValue> parse_json(std::string_view input);

/// Escapes a UTF-8 string for safe inclusion inside JSON double quotes.
[[nodiscard]] std::string escape_json_string(std::string_view input);

/// Appends a quoted, escaped JSON string literal to `out`.
void append_json_quoted(std::string& out, std::string_view input);

}  // namespace json

enum class ContextResolveErrorCode : uint8_t {
    kNone = 0,
    kInvalidUriOrUrl = 1,
    kTransportError = 2,
    kHttpError = 3,
    kEmptyResponse = 4,
    kParseError = 5,
};

struct ResolvedContextPage {
    std::string page_url;
    std::string next_page_url;
    std::unordered_map<std::string, std::string> metadata;
    std::vector<context_view::Entry> tracks;
};

struct ResolvedContext {
    std::string uri;
    std::string url;
    std::unordered_map<std::string, std::string> metadata;
    std::vector<ResolvedContextPage> pages;
    std::vector<context_view::Entry> all_tracks;
    std::vector<size_t> page_track_offsets;
    std::string first_page_url;
    std::string first_next_page_url;
};

struct ContextResolveResult {
    bool ok{false};
    ContextResolveErrorCode error_code{ContextResolveErrorCode::kNone};
    int32_t http_status{0};
    std::string resolved_url;
    std::string error_message;
    std::optional<ResolvedContext> context;
};

/// Resolves Spotify context URIs and URLs (`hm://`, `context://`, `context-page://`,
/// `spotify:...`, `http(s)://...`) against spclient `/context-resolve/v1/` into
/// strongly typed `ResolvedContext` pages and `context_view::Entry` track lists.
class ContextResolveClient {
public:
    static constexpr const char* kDefaultSpclientBaseUrl = "https://spclient.wg.spotify.com/";

    using TransportFn = std::function<network::HttpResponse(
        const std::string& url,
        const std::vector<std::pair<std::string, std::string>>& headers,
        const network::HttpRequestOptions& options)>;

    explicit ContextResolveClient(
        network::NativeHttpClient& http_client = network::NativeHttpClient::defaultInstance(),
        std::string spclient_base_url = kDefaultSpclientBaseUrl);

    explicit ContextResolveClient(
        TransportFn transport_fn,
        std::string spclient_base_url = kDefaultSpclientBaseUrl);

    ~ContextResolveClient() = default;

    ContextResolveClient(const ContextResolveClient&) = delete;
    ContextResolveClient& operator=(const ContextResolveClient&) = delete;

    void set_spclient_base_url(const std::string& base_url);
    [[nodiscard]] std::string spclient_base_url() const;

    void set_transport_fn(TransportFn transport_fn);

    /// Fetches and parses a Spotify context from any supported URI/URL form.
    /// Sends `Accept: application/json`, `include_spotify_auth = true`, `include_cookie = false`.
    [[nodiscard]] ContextResolveResult resolve(
        std::string_view uri_or_url,
        int connect_timeout_ms = 8000,
        int read_timeout_ms = 12000,
        const network::CancelPredicate& cancel_pred = nullptr) const;

    /// Normalizes a spclient base host or URL to `https://<host>/` (or `http://<host>/`).
    [[nodiscard]] static std::optional<std::string> normalize_spclient_base_url(
        std::string_view raw_base_url);

    /// Normalizes all Spotify context URI/URL forms (`hm://`, `context://`, `context-page://`,
    /// `spotify:...`, `http://`, `https://`) into a concrete HTTP(S) GET URL.
    [[nodiscard]] static std::optional<std::string> normalize_context_url(
        std::string_view raw_uri_or_url,
        std::string_view spclient_base_url = kDefaultSpclientBaseUrl);

    /// Parses a Spotify Context (or single ContextPage) JSON document into `ResolvedContext`.
    [[nodiscard]] static ContextResolveResult parse_context_json(
        std::string_view json_body,
        std::string_view request_url = {},
        int32_t http_status = 200);

private:
    mutable std::mutex mutex_;
    network::NativeHttpClient* http_client_{nullptr};
    TransportFn transport_fn_;
    std::string spclient_base_url_;
};

}  // namespace spotify::player
