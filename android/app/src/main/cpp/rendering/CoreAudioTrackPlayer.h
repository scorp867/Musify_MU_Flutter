#pragma once

#include "../AudioEngine.h"
#include "../metadata/TrackInfoProvider.h"
#include "../streamer/FileStreamerImpl.h"
#include "TrackPlayer.h"

#include <atomic>
#include <cstdint>
#include <functional>
#include <mutex>
#include <optional>
#include <string>
#include <thread>

namespace spotify::player::rendering {

/// 1:1 equivalent of liborbit's `CoreAudioTrackPlayer`:
/// Bridges `FileStreamerImpl` (Ogg Vorbis head + storage-resolve CDN + Widevine) to `AudioEngine`.
class CoreAudioTrackPlayer {
public:
    using EosHandler = std::function<void()>;
    using StateNotifyHandler = std::function<void(TrackPlayerPhase phase)>;
    using ErrorHandler = std::function<void(int32_t code, const std::string& message)>;
    using PrefetchPeekHandler = std::function<std::optional<context_view::Entry>()>;

    CoreAudioTrackPlayer(AudioEngine* engine,
                         streamer::FileStreamerImpl& file_streamer,
                         metadata::TrackInfoProvider& track_info_provider);
    ~CoreAudioTrackPlayer();

    CoreAudioTrackPlayer(const CoreAudioTrackPlayer&) = delete;
    CoreAudioTrackPlayer& operator=(const CoreAudioTrackPlayer&) = delete;

    void setHandlers(EosHandler on_eos,
                     StateNotifyHandler on_phase_changed,
                     ErrorHandler on_error,
                     PrefetchPeekHandler peek_next);

    bool startLocalFile(const std::string& file_path,
                        int64_t duration_hint_ms,
                        int64_t start_position_ms,
                        bool start_paused);

    bool startRemoteTrack(const metadata::TrackInfo& info,
                          int64_t start_position_ms,
                          bool start_paused);

    void stop();
    bool pause();
    bool resume();
    bool seek(int64_t position_ms);

    [[nodiscard]] int64_t getPositionMs() const;
    [[nodiscard]] int64_t getDurationMs() const;
    [[nodiscard]] TrackPlayerPhase getPhase() const;

private:
    void cancelWorker();
    void prefetchUpcomingTrack();

    AudioEngine* engine_;
    streamer::FileStreamerImpl& file_streamer_;
    metadata::TrackInfoProvider& track_info_provider_;

    mutable std::mutex mutex_;
    std::mutex worker_mutex_;
    std::thread stream_worker_;
    std::atomic<uint64_t> session_gen_{0};
    std::atomic<TrackPlayerPhase> phase_{TrackPlayerPhase::Idle};
    std::atomic<int64_t> duration_hint_ms_{0};
    std::atomic<bool> desired_paused_{false};
    std::optional<metadata::TrackInfo> current_info_;

    EosHandler on_eos_;
    StateNotifyHandler on_phase_changed_;
    ErrorHandler on_error_;
    PrefetchPeekHandler peek_next_;
};

} // namespace spotify::player::rendering
