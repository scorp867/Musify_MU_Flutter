#pragma once

#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

#include "../ContextProcessor.h"
#include "../ContextViewEntry.h"
#include "../ProtobufWireHelper.h"
#include "../metadata/TrackInfoProvider.h"
#include "../rendering/TrackPlayer.h"
#include "RestrictionsEngine.h"
#include "StateEmitter.h"

namespace spotify::player {

/// 1:1 replica of spotify.player.esperanto.proto.ContextPlayer / ContextPlayerImpl
/// Command dispatcher and session/queue orchestrator in liborbit-jni-spotify.so.
/// Delegates all audio playback rendering to `rendering::TrackPlayer` (`RoutingTrackPlayer`).
class ContextPlayerImpl {
public:
    /// Callback invoked when ContextPlayerState changes, sending protobuf-encoded bytes
    using StateChangedCallback = std::function<void(const uint8_t* data, size_t len)>;

    /// Callback invoked when the Queue changes, sending protobuf-encoded bytes
    using QueueChangedCallback = std::function<void(const uint8_t* data, size_t len)>;

    /// Callback invoked when an error occurs
    using ErrorCallback = std::function<void(const std::string& error_code, const std::string& message)>;

    explicit ContextPlayerImpl(std::shared_ptr<rendering::TrackPlayer> track_player = nullptr);
    ~ContextPlayerImpl();

    ContextPlayerImpl(const ContextPlayerImpl&) = delete;
    ContextPlayerImpl& operator=(const ContextPlayerImpl&) = delete;
    ContextPlayerImpl(ContextPlayerImpl&&) = delete;
    ContextPlayerImpl& operator=(ContextPlayerImpl&&) = delete;

    void set_track_player(std::shared_ptr<rendering::TrackPlayer> track_player);
    [[nodiscard]] std::shared_ptr<rendering::TrackPlayer> get_track_player() const;

    /// Callback registration
    void set_state_changed_callback(StateChangedCallback cb);
    void set_queue_changed_callback(QueueChangedCallback cb);
    void set_error_callback(ErrorCallback cb);

    /// Main Esperanto RPC command dispatcher matching Spotify method routing
    bool handle_command(const std::string& method, const uint8_t* payload, size_t payload_len);

    /// 1:1 Spotify command entry points
    bool play(const uint8_t* payload, size_t len);
    bool pause();
    bool resume();
    bool seek_to(int64_t position_ms);
    bool seek_to(const uint8_t* payload, size_t len);
    bool skip_next(const uint8_t* payload = nullptr, size_t len = 0);
    bool skip_prev(const uint8_t* payload = nullptr, size_t len = 0);

    bool set_options(const uint8_t* payload, size_t len);
    bool set_shuffling_context(const uint8_t* payload, size_t len);
    bool set_repeating_context(const uint8_t* payload, size_t len);
    bool set_repeating_track(const uint8_t* payload, size_t len);

    void set_shuffling_context(bool shuffling);
    void set_repeating_context(bool repeating);
    void set_repeating_track(bool repeating);

    bool add_to_queue(const uint8_t* payload, size_t len);
    bool set_queue(const uint8_t* payload, size_t len);
    bool play_as_next_in_queue(const uint8_t* payload, size_t len);

    bool stop();
    bool prepare_play(const uint8_t* payload, size_t len);
    bool play_prepared(const uint8_t* payload, size_t len);

    bool update_context(const uint8_t* payload, size_t len);
    bool update_track(const uint8_t* payload, size_t len);
    bool update_page(const uint8_t* payload, size_t len);
    bool update_view_uri(const uint8_t* payload, size_t len);

    bool signal(const uint8_t* payload, size_t len);
    bool set_sleep_timer(const uint8_t* payload, size_t len);
    bool delete_session(const uint8_t* payload, size_t len);

    /// ContextPlayerImpl.advanceToNextTrack - called on TrackPlayer AdvanceCallback
    void advance_to_next_track(rendering::AdvanceReason reason = rendering::AdvanceReason::EndOfTrack);

    /// State and Queue query methods returning cached binary protobuf bytes
    [[nodiscard]] const uint8_t* get_state(size_t* out_len) const;
    [[nodiscard]] std::vector<uint8_t> get_state() const;
    [[nodiscard]] const uint8_t* get_queue(size_t* out_len) const;
    [[nodiscard]] std::vector<uint8_t> get_queue() const;
    [[nodiscard]] std::string get_error() const;

    /// Direct access to owned ContextProcessor
    [[nodiscard]] ContextProcessor& get_context_processor() noexcept { return context_processor_; }
    [[nodiscard]] const ContextProcessor& get_context_processor() const noexcept { return context_processor_; }

    /// Direct access to RestrictionsEngine
    [[nodiscard]] RestrictionsEngine& get_restrictions_engine() noexcept { return restrictions_engine_; }
    [[nodiscard]] const RestrictionsEngine& get_restrictions_engine() const noexcept { return restrictions_engine_; }

private:
    void bind_track_player_callbacks(const std::shared_ptr<rendering::TrackPlayer>& tp);
    void on_track_player_state_changed(const rendering::TrackPlayerState& state);
    void on_track_metadata_resolved(const std::string& uri, const metadata::TrackInfo& info);
    void on_track_player_error(int32_t code, const std::string& message);

    void emit_state_locked();
    void emit_queue_locked();
    void update_position_and_duration_locked();

    mutable std::mutex mutex_;

    std::shared_ptr<rendering::TrackPlayer> track_player_;
    ContextProcessor context_processor_;
    RestrictionsEngine restrictions_engine_;

    std::string context_uri_;
    std::string context_url_;
    std::unordered_map<std::string, std::string> context_metadata_;
    std::unordered_map<std::string, std::string> page_metadata_;
    PlayOriginData play_origin_;

    bool is_playing_{false};
    bool is_paused_{false};
    bool is_buffering_{false};
    bool shuffling_{false};
    bool repeating_context_{false};
    bool repeating_track_{false};
    double playback_speed_{1.0};

    int64_t position_ms_{0};
    int64_t duration_ms_{0};

    std::optional<context_view::Entry> current_track_;
    std::vector<context_view::Entry> user_queue_;
    int64_t queue_revision_{1};

    std::string session_id_;
    std::string session_command_id_;
    std::string view_uri_;
    std::vector<std::string> signals_;
    std::string last_error_;

    std::vector<uint8_t> cached_state_bytes_;
    std::vector<uint8_t> cached_queue_bytes_;

    StateChangedCallback state_changed_callback_;
    QueueChangedCallback queue_changed_callback_;
    ErrorCallback error_callback_;
};

} // namespace spotify::player
