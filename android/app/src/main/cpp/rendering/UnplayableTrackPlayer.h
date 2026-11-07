#pragma once

#include "TrackPlayer.h"

#include <mutex>

namespace spotify::player::rendering {

/// 1:1 replica of liborbit's `UnplayableTrackPlayer`:
/// Handles delimiters, placeholders, and unsupported URI schemes by immediately signalling
/// `AdvanceReason::Unplayable` to `ContextPlayerImpl`.
class UnplayableTrackPlayer final : public TrackPlayer {
public:
    UnplayableTrackPlayer() = default;
    ~UnplayableTrackPlayer() override = default;

    void setCallbacks(TrackPlayerCallbacks callbacks) override;

    bool start(const context_view::Entry& track,
               StartReason reason,
               int64_t start_position_ms,
               bool start_paused) override;

    bool advance(const context_view::Entry& next_track,
                 int64_t start_position_ms) override;

    void stop(StopReason reason) override;
    bool pause() override;
    [[nodiscard]] bool canPause() const override;
    bool resume() override;
    bool seek(int64_t position_ms, SeekOrigin origin) override;
    void setPlaybackSpeed(double speed) override;

    [[nodiscard]] int64_t getPosition() const override;
    [[nodiscard]] int64_t getDuration() const override;
    [[nodiscard]] bool canPlay(const context_view::Entry& track) const override;
    [[nodiscard]] TrackPlayerState getState() const override;
    [[nodiscard]] std::optional<context_view::Entry> getCurrentTrack() const override;
    [[nodiscard]] bool isPlaying() const override;
    [[nodiscard]] StartReason getLastStartReason() const override;
    void injectLastStartReason(StartReason reason) override;

private:
    mutable std::mutex mutex_;
    TrackPlayerCallbacks callbacks_;
    std::optional<context_view::Entry> current_track_;
    StartReason last_start_reason_{StartReason::PlayCommand};
};

} // namespace spotify::player::rendering
