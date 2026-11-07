#pragma once

#include "../metadata/TrackInfoProvider.h"
#include "CoreAudioTrackPlayer.h"
#include "TrackPlayer.h"

#include <cstdint>
#include <memory>
#include <mutex>
#include <optional>
#include <string>

namespace spotify::player::rendering {

/// 1:1 replica of liborbit's `AudioTrackPlayer`:
/// Coordinates `TrackInfoProvider` metadata/file-ID availability, pending track start on cache miss,
/// and `CoreAudioTrackPlayer` execution.
class AudioTrackPlayer final : public TrackPlayer {
public:
    AudioTrackPlayer(std::shared_ptr<CoreAudioTrackPlayer> core_player,
                     metadata::TrackInfoProvider& track_info_provider);
    ~AudioTrackPlayer() override;

    AudioTrackPlayer(const AudioTrackPlayer&) = delete;
    AudioTrackPlayer& operator=(const AudioTrackPlayer&) = delete;

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
    struct PendingStart {
        context_view::Entry track;
        StartReason reason{StartReason::PlayCommand};
        int64_t position_ms{0};
        bool paused{false};
    };

    void onMetadataUpdated(const std::string& uri, const metadata::TrackInfo& info);
    void emitStateChanged();

    static bool isLocalEntry(const context_view::Entry& track);
    static std::string extractLocalPath(const context_view::Entry& track);
    static int64_t extractDurationHintMs(const context_view::Entry& track);

    std::shared_ptr<CoreAudioTrackPlayer> core_player_;
    metadata::TrackInfoProvider& track_info_provider_;
    int32_t metadata_listener_id_{0};

    mutable std::mutex mutex_;
    TrackPlayerCallbacks callbacks_;
    std::optional<context_view::Entry> current_track_;
    std::optional<PendingStart> pending_start_;
    StartReason last_start_reason_{StartReason::PlayCommand};
    double playback_speed_{1.0};
};

} // namespace spotify::player::rendering
