#pragma once

#include "TrackPlayer.h"

#include <memory>
#include <mutex>
#include <vector>

namespace spotify::player::rendering {

/// 1:1 replica of liborbit's `RoutingTrackPlayer` (0x7da650 - 0x7db374):
/// Selects the first registered child `TrackPlayer` where `canPlay(track)` returns `true`,
/// cleanly stopping the previously active player when switching player types.
class RoutingTrackPlayer final : public TrackPlayer {
public:
    RoutingTrackPlayer(std::vector<std::shared_ptr<TrackPlayer>> players,
                       std::shared_ptr<TrackPlayer> fallback_player);
    ~RoutingTrackPlayer() override = default;

    RoutingTrackPlayer(const RoutingTrackPlayer&) = delete;
    RoutingTrackPlayer& operator=(const RoutingTrackPlayer&) = delete;

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
    [[nodiscard]] std::shared_ptr<TrackPlayer> selectPlayer(const context_view::Entry& track) const;
    [[nodiscard]] std::shared_ptr<TrackPlayer> activePlayer() const;

    std::vector<std::shared_ptr<TrackPlayer>> players_;
    std::shared_ptr<TrackPlayer> fallback_player_;
    mutable std::mutex mutex_;
    std::shared_ptr<TrackPlayer> active_player_;
    StartReason last_start_reason_{StartReason::PlayCommand};
};

} // namespace spotify::player::rendering
