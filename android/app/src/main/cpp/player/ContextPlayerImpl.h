// ============================================================================
// 1:1 Replicated Spotify ContextPlayerImpl & Connect Bidirectional Hooks
// Sources (`liborbit-jni-spotify.so` arm64):
// - ContextPlayerImpl command/state dispatcher & Connect state sync
// - ELF FileDescriptorProto `player.proto` (`0x635f80`)
// - `transfer_state.proto` (`0x60c1c4`), `playback.proto` (`0x60a6c0`),
//   `session.proto` (`0x60ba78`), `queue.proto` (`0x60a8d4`),
//   `sleep_timer.proto` (`0x60be60`)
// - LocalPlaybackIntentContextPlayer (`0x1090200..0x10924a8`)
// - ConnectApiImpl (`0xda66f0..0xda96ac`, `&not_playing_locally` @ `0xdaa0bc`)
// - ConnectStateImpl::onClusterChanged (`0xdb6740..0xdb7060`)
// ============================================================================

#pragma once

#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "../ContextProcessor.h"
#include "../ContextViewEntry.h"
#include "../ProtobufWireHelper.h"
#include "../metadata/TrackInfoProvider.h"
#include "../rendering/TrackPlayer.h"
#include "ContextResolveClient.h"
#include "RemotePlaybackDelegate.h"
#include "RestrictionsEngine.h"
#include "StateEmitter.h"

namespace spotify::player {

/// Single source of truth for whether `ContextPlayerImpl` is driving local audio
/// rendering (`kLocal`) or mirroring a remote Spotify Connect cluster's active
/// `PlayerState` into Dart UI streams (`kRemoteMirrored`).
enum class PlaybackOrigin : uint8_t {
    kLocal = 0,
    kRemoteMirrored = 1,
};

/// 1:1 replica of spotify.player.esperanto.proto.ContextPlayer / ContextPlayerImpl
/// Command dispatcher and session/queue orchestrator in liborbit-jni-spotify.so.
/// Delegates all local audio playback rendering to `rendering::TrackPlayer` (`RoutingTrackPlayer`),
/// and delegates outbound remote player commands to `IRemotePlaybackDelegate` when a remote
/// Spotify Connect device is active and `CommandOptions.only_for_local_device` is false.
class ContextPlayerImpl {
public:
    /// Exhaustive session playback state machine replacing loose booleans
    /// (`is_playing_`, `is_paused_`, `is_buffering_`).
    enum class SessionPlaybackPhase : uint8_t {
        Idle = 0,
        BufferingPlay = 1,
        BufferingPaused = 2,
        Playing = 3,
        Paused = 4,
        Halted = 5
    };

    /// Exhaustive session repeat mode replacing loose booleans
    /// (`repeating_context_`, `repeating_track_`).
    enum class SessionRepeatMode : uint8_t {
        Off = 0,
        Context = 1,
        Track = 2
    };

    /// Exhaustive sleep timer mode matching `es_set_sleep_timer_request.proto`
    /// and `spotify.player.proto.transfer.SleepTimer`.
    enum class SleepTimerMode : uint8_t {
        kOff = 0,
        kDuration = 1,
        kEndOfTrack = 2
    };

    struct SleepTimerState {
        SleepTimerMode mode{SleepTimerMode::kOff};
        int64_t expires_at_ms{0};
    };

    /// Callback invoked when ContextPlayerState changes, sending protobuf-encoded bytes
    using StateChangedCallback = std::function<void(const uint8_t* data, size_t len)>;

    /// Callback invoked when the Queue changes, sending protobuf-encoded bytes
    using QueueChangedCallback = std::function<void(const uint8_t* data, size_t len)>;

    /// Callback invoked when an error occurs
    using ErrorCallback = std::function<void(const std::string& error_code, const std::string& message)>;

    /// Owning snapshot of local player state formatted for Connect PutState translation.
    struct ConnectPlayerSnapshot {
        int64_t timestamp_ms{0};
        std::string context_uri;
        std::string context_url;
        std::string playback_id;
        std::string session_id;
        std::string session_command_id;
        std::string last_command_sent_by_device_id;
        uint32_t last_command_message_id{0};
        uint64_t queue_revision{1};

        SessionPlaybackPhase playback_phase{SessionPlaybackPhase::Idle};
        SessionRepeatMode repeat_mode{SessionRepeatMode::Off};
        bool shuffling{false};
        double playback_speed{1.0};
        int64_t position_ms{0};
        int64_t duration_ms{0};
        uint32_t page_index{0};
        int32_t track_index{0};

        std::optional<context_view::Entry> current_track;
        std::vector<context_view::Entry> prev_tracks;
        std::vector<context_view::Entry> next_tracks;
        std::vector<uint8_t> restrictions_bytes;
        PlayOriginData play_origin;
        std::unordered_map<std::string, std::string> context_metadata;
        std::unordered_map<std::string, std::string> page_metadata;
        std::vector<std::string> signals;
        bool has_player_state{false};
    };

    class PlayerStateListener {
    public:
        virtual ~PlayerStateListener() = default;
        virtual void on_player_state_changed(
            const ConnectPlayerSnapshot& snapshot,
            bool track_changed) = 0;
    };

    explicit ContextPlayerImpl(
        std::shared_ptr<rendering::TrackPlayer> track_player = nullptr,
        metadata::TrackInfoProvider* track_info_provider = nullptr);
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

    /// Connect subsystem bidirectional hooks (listener/delegate must outlive registration
    /// or detach before destruction).
    void add_player_state_listener(PlayerStateListener* listener);
    void remove_player_state_listener(PlayerStateListener* listener);
    [[nodiscard]] ConnectPlayerSnapshot snapshot_for_connect() const;
    bool apply_connect_remote_command(
        const std::string& endpoint,
        const std::string& command_json,
        const std::string& sent_by_device_id,
        uint32_t message_id,
        uint32_t target_alias_id = 0);
    void set_session_command_id(const std::string& command_id);

    /// Frozen Wave 1/Wave 2 remote playback mirroring and delegation contract (#47 sec 3)
    void set_remote_playback_delegate(IRemotePlaybackDelegate* delegate);
    void apply_remote_mirrored_state(const MirroredRemotePlaybackState& state);
    void clear_remote_mirrored_state();
    void pause_for_remote_takeover();

    /// Dynamic spclient base URL forwarded to owned ContextResolveClient
    void set_spclient_base_url(const std::string& url);
    [[nodiscard]] std::string spclient_base_url() const;

    /// Current playback origin SSOT (`kLocal` vs `kRemoteMirrored`)
    [[nodiscard]] PlaybackOrigin playback_origin() const;

    /// Current sleep timer state
    [[nodiscard]] SleepTimerState sleep_timer_state() const;

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

    /// Direct access to ContextResolveClient
    [[nodiscard]] ContextResolveClient& get_context_resolve_client() noexcept {
        return context_resolve_client_;
    }
    [[nodiscard]] const ContextResolveClient& get_context_resolve_client() const noexcept {
        return context_resolve_client_;
    }

private:
    static constexpr bool is_phase_playing(SessionPlaybackPhase phase) noexcept {
        return phase == SessionPlaybackPhase::Playing ||
               phase == SessionPlaybackPhase::BufferingPlay;
    }

    static constexpr bool is_phase_paused(SessionPlaybackPhase phase) noexcept {
        return phase == SessionPlaybackPhase::Paused ||
               phase == SessionPlaybackPhase::BufferingPaused;
    }

    static constexpr bool is_phase_buffering(SessionPlaybackPhase phase) noexcept {
        return phase == SessionPlaybackPhase::BufferingPlay ||
               phase == SessionPlaybackPhase::BufferingPaused;
    }

    static SessionPlaybackPhase map_track_player_state_to_phase(
        const rendering::TrackPlayerState& state) noexcept;
    void apply_repeat_overrides_locked(
        std::optional<bool> repeating_context,
        std::optional<bool> repeating_track) noexcept;
    void begin_track_transition_locked(
        const context_view::Entry& track,
        SessionPlaybackPhase initial_phase);
    void transition_to_local_locked() noexcept;

    bool skip_next_impl(bool override_restrictions, const context_view::Entry& target_track);
    bool skip_prev_impl(
        bool override_restrictions,
        bool allow_seeking,
        const context_view::Entry& target_track);
    bool apply_signal_value(const std::string& signal_id, const std::string& parameters);
    void apply_sleep_timer_state(const SleepTimerState& next_timer);
    void ensure_sleep_timer_thread_locked();
    void stop_sleep_timer_thread();
    void sleep_timer_worker_loop();

    struct OutboundForwardOutcome {
        bool intercepted{false};
        bool ok{false};
    };

    OutboundForwardOutcome try_forward_remote_command(
        const std::string& method_name,
        const uint8_t* payload,
        size_t payload_len);

    bool handle_connect_transfer_command(
        const json::JsonValue& parsed,
        const std::string& sent_by_device_id,
        uint32_t message_id,
        uint32_t target_alias_id);

    void bind_track_player_callbacks(const std::shared_ptr<rendering::TrackPlayer>& tp);
    void on_track_player_state_changed(const rendering::TrackPlayerState& state);
    void on_track_metadata_resolved(const std::string& uri, const metadata::TrackInfo& info);
    void on_track_player_error(int32_t code, const std::string& message);

    void emit_state_locked(bool sync_player_position = true);
    void emit_queue_locked();
    void update_position_and_duration_locked(bool sync_position = true);
    void clear_pending_player_sync(uint64_t sync_token);
    void bump_queue_revision_locked() noexcept;
    static bool apply_track_info_locked(
        context_view::Entry& track,
        const metadata::TrackInfo& info);

    struct PendingMetadataRequest {
        std::string uri;
        network::AcquisitionIntent intent{network::AcquisitionIntent::BackgroundPrefetch};
    };

    bool decorate_entry_locked(
        context_view::Entry& entry,
        network::AcquisitionIntent intent,
        std::unordered_set<std::string>& seen_uris,
        std::vector<PendingMetadataRequest>& out_misses);
    void decorate_mirrored_state_locked(std::vector<PendingMetadataRequest>& out_misses);
    void decorate_local_queue_locked(std::vector<PendingMetadataRequest>& out_misses);
    void dispatch_metadata_requests(const std::vector<PendingMetadataRequest>& requests) const;

    struct ConnectDispatchBundle {
        std::vector<PlayerStateListener*> listeners;
        ConnectPlayerSnapshot snapshot;
        bool track_changed{false};
    };

    void capture_connect_dispatch_locked(ConnectDispatchBundle& out);
    static void dispatch_connect_listeners(const ConnectDispatchBundle& bundle);

    mutable std::mutex mutex_;

    std::shared_ptr<rendering::TrackPlayer> track_player_;
    metadata::TrackInfoProvider* track_info_provider_{nullptr};
    int32_t metadata_listener_id_{0};
    std::shared_ptr<std::atomic<bool>> alive_flag_{std::make_shared<std::atomic<bool>>(true)};
    ContextProcessor context_processor_;
    RestrictionsEngine restrictions_engine_;
    ContextResolveClient context_resolve_client_;

    PlaybackOrigin origin_{PlaybackOrigin::kLocal};
    bool paused_for_remote_takeover_{false};
    IRemotePlaybackDelegate* remote_delegate_{nullptr};
    MirroredRemotePlaybackState mirrored_state_;

    std::string context_uri_;
    std::string context_url_;
    std::unordered_map<std::string, std::string> context_metadata_;
    std::unordered_map<std::string, std::string> page_metadata_;
    PlayOriginData play_origin_;

    SessionPlaybackPhase playback_phase_{SessionPlaybackPhase::Idle};
    SessionRepeatMode repeat_mode_{SessionRepeatMode::Off};
    bool shuffling_{false};
    double playback_speed_{1.0};

    int64_t position_ms_{0};
    int64_t duration_ms_{0};
    uint64_t next_player_sync_token_{0};
    uint64_t pending_player_sync_token_{0};

    std::optional<context_view::Entry> current_track_;
    std::vector<context_view::Entry> user_queue_;
    std::optional<std::vector<context_view::Entry>> explicit_prev_tracks_;
    uint64_t queue_revision_{1};

    std::string playback_id_;
    std::string last_emitted_playback_id_;
    std::string session_id_;
    std::string session_command_id_;
    std::string last_command_sent_by_device_id_;
    uint32_t last_command_message_id_{0};
    uint32_t last_command_target_alias_id_{0};
    std::string view_uri_;
    std::vector<std::string> signals_;
    std::unordered_map<std::string, std::string> modes_;
    std::string last_error_;

    SleepTimerState sleep_timer_;
    std::mutex sleep_timer_mutex_;
    std::condition_variable sleep_timer_cv_;
    bool sleep_timer_stop_{false};
    uint64_t sleep_timer_epoch_{0};
    std::thread sleep_timer_thread_;

    std::vector<uint8_t> cached_state_bytes_;
    std::vector<uint8_t> cached_queue_bytes_;
    ConnectPlayerSnapshot latest_connect_snapshot_;

    StateChangedCallback state_changed_callback_;
    QueueChangedCallback queue_changed_callback_;
    ErrorCallback error_callback_;
    std::vector<PlayerStateListener*> player_state_listeners_;
};

}  // namespace spotify::player
