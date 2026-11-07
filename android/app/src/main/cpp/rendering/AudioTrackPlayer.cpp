#include "AudioTrackPlayer.h"

#include <android/log.h>
#include <cstdlib>

#define ATP_LOG_TAG "MusifyAudioTrackPlayer"
#define ATP_LOGI(...) __android_log_print(ANDROID_LOG_INFO, ATP_LOG_TAG, __VA_ARGS__)
#define ATP_LOGW(...) __android_log_print(ANDROID_LOG_WARN, ATP_LOG_TAG, __VA_ARGS__)

namespace spotify::player::rendering {

AudioTrackPlayer::AudioTrackPlayer(
    std::shared_ptr<CoreAudioTrackPlayer> core_player,
    metadata::TrackInfoProvider& track_info_provider)
    : core_player_(std::move(core_player)),
      track_info_provider_(track_info_provider) {
    metadata_listener_id_ = track_info_provider_.addListener(
        [this](const std::string& uri, const metadata::TrackInfo& info) {
            onMetadataUpdated(uri, info);
        });

    if (core_player_) {
        core_player_->setHandlers(
            [this]() {
                std::function<void(AdvanceReason)> adv;
                {
                    std::lock_guard<std::mutex> lock(mutex_);
                    adv = callbacks_.advance_track;
                }
                if (adv) {
                    adv(AdvanceReason::EndOfTrack);
                }
            },
            [this](TrackPlayerPhase /*phase*/) {
                emitStateChanged();
            },
            [this](int32_t code, const std::string& msg) {
                std::function<void(int32_t, const std::string&)> err_cb;
                {
                    std::lock_guard<std::mutex> lock(mutex_);
                    err_cb = callbacks_.on_error;
                }
                if (err_cb) {
                    err_cb(code, msg);
                }
                emitStateChanged();
            },
            [this]() -> std::optional<context_view::Entry> {
                std::function<std::optional<context_view::Entry>(bool)> peek_cb;
                {
                    std::lock_guard<std::mutex> lock(mutex_);
                    peek_cb = callbacks_.peek_track;
                }
                if (peek_cb) {
                    return peek_cb(true);
                }
                return std::nullopt;
            });
    }
}

AudioTrackPlayer::~AudioTrackPlayer() {
    if (metadata_listener_id_ != 0) {
        track_info_provider_.removeListener(metadata_listener_id_);
        metadata_listener_id_ = 0;
    }
    if (core_player_) {
        core_player_->setHandlers(nullptr, nullptr, nullptr, nullptr);
        core_player_->stop();
    }
}

void AudioTrackPlayer::setCallbacks(TrackPlayerCallbacks callbacks) {
    std::lock_guard<std::mutex> lock(mutex_);
    callbacks_ = std::move(callbacks);
}

bool AudioTrackPlayer::isLocalEntry(const context_view::Entry& track) {
    if (track.uri.rfind("spotify:local:", 0) == 0 ||
        track.uri.rfind("file://", 0) == 0 ||
        (!track.uri.empty() && track.uri[0] == '/')) {
        return true;
    }
    auto it_local = track.metadata.find("is_local");
    if (it_local != track.metadata.end() &&
        (it_local->second == "true" || it_local->second == "True" || it_local->second == "1")) {
        return true;
    }
    auto it_path = track.metadata.find("local_file_path");
    return it_path != track.metadata.end() && !it_path->second.empty();
}

std::string AudioTrackPlayer::extractLocalPath(const context_view::Entry& track) {
    auto it = track.metadata.find("local_file_path");
    if (it != track.metadata.end() && !it->second.empty()) {
        if (it->second.rfind("file://", 0) == 0) {
            return it->second.substr(7);
        }
        return it->second;
    }
    if (track.uri.rfind("file://", 0) == 0) {
        return track.uri.substr(7);
    }
    if (!track.uri.empty() && track.uri[0] == '/') {
        return track.uri;
    }
    return {};
}

int64_t AudioTrackPlayer::extractDurationHintMs(const context_view::Entry& track) {
    auto it = track.metadata.find("duration");
    if (it == track.metadata.end() || it->second.empty()) return 0;
    char* end_ptr = nullptr;
    const long long val = std::strtoll(it->second.c_str(), &end_ptr, 10);
    if (end_ptr == it->second.c_str() || val <= 0) return 0;
    return static_cast<int64_t>(val);
}

bool AudioTrackPlayer::canPlay(const context_view::Entry& track) const {
    if (track.is_delimiter() || track.is_placeholder() || track.uri.empty()) {
        return false;
    }
    if (isLocalEntry(track)) {
        return !extractLocalPath(track).empty();
    }
    return track.uri.rfind("spotify:track:", 0) == 0 ||
           track.uri.rfind("spotify:episode:", 0) == 0;
}

bool AudioTrackPlayer::start(const context_view::Entry& track,
                             StartReason reason,
                             int64_t start_position_ms,
                             bool start_paused) {
    if (!core_player_) return false;

    std::function<void(const std::string&, const metadata::TrackInfo&)> meta_cb;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        current_track_ = track;
        last_start_reason_ = reason;
        pending_start_.reset();
        meta_cb = callbacks_.on_track_metadata_resolved;
    }

    if (isLocalEntry(track)) {
        const std::string local_path = extractLocalPath(track);
        const int64_t dur_hint = extractDurationHintMs(track);
        const bool ok = core_player_->startLocalFile(
            local_path, dur_hint, start_position_ms, start_paused);
        emitStateChanged();
        return ok;
    }

    const auto cached = track_info_provider_.getCached(track.uri);
    if (cached.has_value() && meta_cb) {
        meta_cb(track.uri, *cached);
    }

    if (cached.has_value() && cached->hasPlayableSource()) {
        const bool ok = core_player_->startRemoteTrack(*cached, start_position_ms, start_paused);
        emitStateChanged();
        return ok;
    }

    ATP_LOGI("AudioTrackPlayer: metadata pending for %s; requesting native resolution",
             track.uri.c_str());
    core_player_->stop();
    {
        std::lock_guard<std::mutex> lock(mutex_);
        pending_start_ = PendingStart{track, reason, start_position_ms, start_paused};
    }
    track_info_provider_.requestResolution(track.uri);
    emitStateChanged();
    return true;
}

bool AudioTrackPlayer::advance(const context_view::Entry& next_track,
                               int64_t start_position_ms) {
    return start(next_track, StartReason::TrackAdvance, start_position_ms, false);
}

void AudioTrackPlayer::onMetadataUpdated(const std::string& uri,
                                         const metadata::TrackInfo& info) {
    std::optional<PendingStart> ready_pending;
    std::function<void(const std::string&, const metadata::TrackInfo&)> meta_cb;
    bool matches_current = false;

    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (current_track_.has_value() && current_track_->uri == uri) {
            matches_current = true;
            meta_cb = callbacks_.on_track_metadata_resolved;
        }
        if (pending_start_.has_value() &&
            pending_start_->track.uri == uri &&
            info.hasPlayableSource()) {
            ready_pending = pending_start_;
            pending_start_.reset();
        }
    }

    if (matches_current && meta_cb) {
        meta_cb(uri, info);
    }

    if (ready_pending.has_value() && core_player_) {
        ATP_LOGI("AudioTrackPlayer: play pending track due to metadata changed (%s)",
                 uri.c_str());
        core_player_->startRemoteTrack(
            info, ready_pending->position_ms, ready_pending->paused);
        emitStateChanged();
    }
}

void AudioTrackPlayer::stop(StopReason /*reason*/) {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        pending_start_.reset();
        current_track_.reset();
    }
    if (core_player_) {
        core_player_->stop();
    }
}

bool AudioTrackPlayer::pause() {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (pending_start_.has_value()) {
            pending_start_->paused = true;
            return true;
        }
    }
    return core_player_ ? core_player_->pause() : false;
}

bool AudioTrackPlayer::canPause() const {
    return true;
}

bool AudioTrackPlayer::resume() {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (pending_start_.has_value()) {
            pending_start_->paused = false;
            return true;
        }
    }
    return core_player_ ? core_player_->resume() : false;
}

bool AudioTrackPlayer::seek(int64_t position_ms, SeekOrigin /*origin*/) {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (pending_start_.has_value()) {
            pending_start_->position_ms = position_ms;
            return true;
        }
    }
    return core_player_ ? core_player_->seek(position_ms) : false;
}

void AudioTrackPlayer::setPlaybackSpeed(double speed) {
    std::lock_guard<std::mutex> lock(mutex_);
    playback_speed_ = speed > 0.0 ? speed : 1.0;
}

int64_t AudioTrackPlayer::getPosition() const {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (pending_start_.has_value()) {
            return pending_start_->position_ms;
        }
    }
    return core_player_ ? core_player_->getPositionMs() : 0;
}

int64_t AudioTrackPlayer::getDuration() const {
    if (core_player_) {
        const int64_t dur = core_player_->getDurationMs();
        if (dur > 0) return dur;
    }
    std::lock_guard<std::mutex> lock(mutex_);
    if (current_track_.has_value()) {
        return extractDurationHintMs(*current_track_);
    }
    return 0;
}

TrackPlayerState AudioTrackPlayer::getState() const {
    TrackPlayerState st;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        st.playback_speed = playback_speed_;
        if (pending_start_.has_value()) {
            st.phase = pending_start_->paused ? TrackPlayerPhase::Paused : TrackPlayerPhase::Buffering;
            st.position_ms = pending_start_->position_ms;
            st.duration_ms = current_track_.has_value() ? extractDurationHintMs(*current_track_) : 0;
            st.is_playing = !pending_start_->paused;
            st.is_paused = pending_start_->paused;
            st.is_buffering = !pending_start_->paused;
            return st;
        }
    }

    if (core_player_) {
        st.phase = core_player_->getPhase();
        st.position_ms = core_player_->getPositionMs();
        st.duration_ms = core_player_->getDurationMs();
        st.is_playing = (st.phase == TrackPlayerPhase::Playing || st.phase == TrackPlayerPhase::Buffering);
        st.is_paused = (st.phase == TrackPlayerPhase::Paused);
        st.is_buffering = (st.phase == TrackPlayerPhase::Buffering);
    }
    return st;
}

std::optional<context_view::Entry> AudioTrackPlayer::getCurrentTrack() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return current_track_;
}

bool AudioTrackPlayer::isPlaying() const {
    const auto st = getState();
    return st.is_playing && !st.is_paused;
}

StartReason AudioTrackPlayer::getLastStartReason() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return last_start_reason_;
}

void AudioTrackPlayer::injectLastStartReason(StartReason reason) {
    std::lock_guard<std::mutex> lock(mutex_);
    last_start_reason_ = reason;
}

void AudioTrackPlayer::emitStateChanged() {
    std::function<void(const TrackPlayerState&)> cb;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        cb = callbacks_.on_state_changed;
    }
    if (cb) {
        cb(getState());
    }
}

} // namespace spotify::player::rendering
