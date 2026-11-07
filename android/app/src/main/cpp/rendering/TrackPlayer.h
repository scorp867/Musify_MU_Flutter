#pragma once

#include "../ContextViewEntry.h"
#include "../metadata/TrackInfoProvider.h"

#include <cstdint>
#include <functional>
#include <optional>
#include <string>

namespace spotify::player::rendering {

enum class StartReason : int32_t {
    PlayCommand = 0,
    TrackAdvance = 1,
    SkipNext = 2,
    SkipPrev = 3,
    PreparePlay = 4,
};

enum class StopReason : int32_t {
    ExplicitStop = 0,
    ReplacedTrack = 1,
    SessionDeleted = 2,
    ContextEnded = 3,
};

enum class AdvanceReason : int32_t {
    EndOfTrack = 0,
    Unplayable = 1,
    PlaybackError = 2,
};

enum class SeekOrigin : int32_t {
    User = 0,
    Internal = 1,
};

enum class TrackPlayerPhase : int32_t {
    Idle = 0,
    Buffering = 1,
    Playing = 2,
    Paused = 3,
    Stopped = 4,
    Faulted = 5,
};

struct TrackPlayerState {
    TrackPlayerPhase phase{TrackPlayerPhase::Idle};
    int64_t position_ms{0};
    int64_t duration_ms{0};
    double playback_speed{1.0};
    bool is_playing{false};
    bool is_paused{false};
    bool is_buffering{false};
};

struct TrackPlayerCallbacks {
    std::function<std::optional<context_view::Entry>(bool playable_only)> peek_track;
    std::function<void(AdvanceReason reason)> advance_track;
    std::function<void(const TrackPlayerState& state)> on_state_changed;
    std::function<void(const std::string& uri, const metadata::TrackInfo& info)> on_track_metadata_resolved;
    std::function<void(int32_t code, const std::string& message)> on_error;
};

/// 1:1 replica of liborbit's `spotify::player::rendering::TrackPlayer` vtable contract.
class TrackPlayer {
public:
    virtual ~TrackPlayer() = default;

    virtual void setCallbacks(TrackPlayerCallbacks callbacks) = 0;

    virtual bool start(const context_view::Entry& track,
                       StartReason reason,
                       int64_t start_position_ms,
                       bool start_paused) = 0;

    virtual bool advance(const context_view::Entry& next_track,
                         int64_t start_position_ms) = 0;

    virtual void stop(StopReason reason) = 0;
    virtual bool pause() = 0;
    [[nodiscard]] virtual bool canPause() const = 0;
    virtual bool resume() = 0;
    virtual bool seek(int64_t position_ms, SeekOrigin origin) = 0;
    virtual void setPlaybackSpeed(double speed) = 0;

    [[nodiscard]] virtual int64_t getPosition() const = 0;
    [[nodiscard]] virtual int64_t getDuration() const = 0;
    [[nodiscard]] virtual bool canPlay(const context_view::Entry& track) const = 0;
    [[nodiscard]] virtual TrackPlayerState getState() const = 0;
    [[nodiscard]] virtual std::optional<context_view::Entry> getCurrentTrack() const = 0;
    [[nodiscard]] virtual bool isPlaying() const = 0;
    [[nodiscard]] virtual StartReason getLastStartReason() const = 0;
    virtual void injectLastStartReason(StartReason reason) = 0;
};

} // namespace spotify::player::rendering
