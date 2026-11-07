#include "UnplayableTrackPlayer.h"

#include <android/log.h>

#define UTP_LOG_TAG "MusifyUnplayablePlayer"
#define UTP_LOGI(...) __android_log_print(ANDROID_LOG_INFO, UTP_LOG_TAG, __VA_ARGS__)

namespace spotify::player::rendering {

void UnplayableTrackPlayer::setCallbacks(TrackPlayerCallbacks callbacks) {
    std::lock_guard<std::mutex> lock(mutex_);
    callbacks_ = std::move(callbacks);
}

bool UnplayableTrackPlayer::start(const context_view::Entry& track,
                                  StartReason reason,
                                  int64_t /*start_position_ms*/,
                                  bool start_paused) {
    std::function<void(AdvanceReason)> adv;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        current_track_ = track;
        last_start_reason_ = reason;
        adv = callbacks_.advance_track;
    }

    UTP_LOGI("UnplayableTrackPlayer handling non-audio item: %s (paused=%d)",
             track.uri.c_str(), start_paused ? 1 : 0);

    if (!start_paused && adv) {
        adv(AdvanceReason::Unplayable);
    }
    return true;
}

bool UnplayableTrackPlayer::advance(const context_view::Entry& next_track,
                                    int64_t start_position_ms) {
    return start(next_track, StartReason::TrackAdvance, start_position_ms, false);
}

void UnplayableTrackPlayer::stop(StopReason /*reason*/) {
    std::lock_guard<std::mutex> lock(mutex_);
    current_track_.reset();
}

bool UnplayableTrackPlayer::pause() { return false; }

bool UnplayableTrackPlayer::canPause() const { return false; }

bool UnplayableTrackPlayer::resume() {
    std::function<void(AdvanceReason)> adv;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!current_track_.has_value()) return false;
        adv = callbacks_.advance_track;
    }
    if (adv) {
        adv(AdvanceReason::Unplayable);
    }
    return true;
}

bool UnplayableTrackPlayer::seek(int64_t /*position_ms*/, SeekOrigin /*origin*/) {
    return false;
}

void UnplayableTrackPlayer::setPlaybackSpeed(double /*speed*/) {}

int64_t UnplayableTrackPlayer::getPosition() const { return 0; }

int64_t UnplayableTrackPlayer::getDuration() const { return 0; }

bool UnplayableTrackPlayer::canPlay(const context_view::Entry& /*track*/) const {
    return true;
}

TrackPlayerState UnplayableTrackPlayer::getState() const {
    TrackPlayerState st;
    st.phase = TrackPlayerPhase::Stopped;
    return st;
}

std::optional<context_view::Entry> UnplayableTrackPlayer::getCurrentTrack() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return current_track_;
}

bool UnplayableTrackPlayer::isPlaying() const { return false; }

StartReason UnplayableTrackPlayer::getLastStartReason() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return last_start_reason_;
}

void UnplayableTrackPlayer::injectLastStartReason(StartReason reason) {
    std::lock_guard<std::mutex> lock(mutex_);
    last_start_reason_ = reason;
}

} // namespace spotify::player::rendering
