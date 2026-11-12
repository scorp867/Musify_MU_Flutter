#include "CoreAudioTrackPlayer.h"
#include "../JniHelper.h"

#include <android/log.h>

#define CATP_LOG_TAG "MusifyCoreAudioPlayer"
#define CATP_LOGI(...) __android_log_print(ANDROID_LOG_INFO, CATP_LOG_TAG, __VA_ARGS__)
#define CATP_LOGW(...) __android_log_print(ANDROID_LOG_WARN, CATP_LOG_TAG, __VA_ARGS__)
#define CATP_LOGE(...) __android_log_print(ANDROID_LOG_ERROR, CATP_LOG_TAG, __VA_ARGS__)

namespace spotify::player::rendering {

CoreAudioTrackPlayer::CoreAudioTrackPlayer(
    AudioEngine* engine,
    streamer::FileStreamerImpl& file_streamer,
    metadata::TrackInfoProvider& track_info_provider)
    : engine_(engine),
      file_streamer_(file_streamer),
      track_info_provider_(track_info_provider) {
    if (engine_) {
        engine_->setEosCallback([this]() {
            const auto prev = phase_.exchange(
                TrackPlayerPhase::Stopped, std::memory_order_acq_rel);
            if (prev == TrackPlayerPhase::Stopped || prev == TrackPlayerPhase::Idle) {
                return;
            }
            EosHandler cb;
            {
                std::lock_guard<std::mutex> lock(mutex_);
                cb = on_eos_;
            }
            if (cb) {
                cb();
            }
        });
        engine_->setSecondaryFailureCallback([this](const std::string& reason) {
            phase_.store(TrackPlayerPhase::Faulted, std::memory_order_release);
            engine_->pause();
            ErrorHandler err_cb;
            {
                std::lock_guard<std::mutex> lock(mutex_);
                err_cb = on_error_;
            }
            if (err_cb) {
                err_cb(-2, reason);
            }
        });
    }
}

CoreAudioTrackPlayer::~CoreAudioTrackPlayer() {
    if (engine_) {
        engine_->setEosCallback(nullptr);
        engine_->setSecondaryFailureCallback(nullptr);
    }
    stop();
}

void CoreAudioTrackPlayer::setHandlers(EosHandler on_eos,
                                       StateNotifyHandler on_phase_changed,
                                       ErrorHandler on_error,
                                       PrefetchPeekHandler peek_next) {
    std::lock_guard<std::mutex> lock(mutex_);
    on_eos_ = std::move(on_eos);
    on_phase_changed_ = std::move(on_phase_changed);
    on_error_ = std::move(on_error);
    peek_next_ = std::move(peek_next);
}

void CoreAudioTrackPlayer::cancelWorker() {
    session_gen_.fetch_add(1, std::memory_order_acq_rel);
    std::lock_guard<std::mutex> wlock(worker_mutex_);
    if (stream_worker_.joinable()) {
        stream_worker_.join();
    }
}

bool CoreAudioTrackPlayer::startLocalFile(const std::string& file_path,
                                          int64_t duration_hint_ms,
                                          int64_t start_position_ms,
                                          bool start_paused) {
    if (!engine_ || file_path.empty()) return false;

    cancelWorker();
    const uint64_t gen = session_gen_.fetch_add(1, std::memory_order_acq_rel) + 1;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        current_info_.reset();
    }
    desired_paused_.store(start_paused, std::memory_order_release);
    duration_hint_ms_.store(duration_hint_ms > 0 ? duration_hint_ms : 0, std::memory_order_release);
    phase_.store(TrackPlayerPhase::Buffering, std::memory_order_release);

    std::lock_guard<std::mutex> wlock(worker_mutex_);
    stream_worker_ = std::thread([this, gen, file_path, start_position_ms, start_paused]() {
        JniThreadAttacher jniAttacher(getMusifyJavaVm(), "MusifyLocalWorker");

        if (session_gen_.load(std::memory_order_acquire) != gen) {
            return;
        }

        engine_->setAutoPlay(!start_paused);
        const EngineStatus st = engine_->loadLocal(file_path.c_str());

        if (session_gen_.load(std::memory_order_acquire) != gen) {
            return;
        }

        if (st != EngineStatus::Ok) {
            CATP_LOGE("loadLocal failed (%d) for %s", static_cast<int>(st), file_path.c_str());
            phase_.store(TrackPlayerPhase::Faulted, std::memory_order_release);
            ErrorHandler err_cb;
            {
                std::lock_guard<std::mutex> lock(mutex_);
                err_cb = on_error_;
            }
            if (err_cb) {
                err_cb(static_cast<int32_t>(st), "Failed to load local audio file: " + file_path);
            }
            return;
        }

        if (start_position_ms > 0) {
            engine_->seekMs(start_position_ms);
        }

        const TrackPlayerPhase next_phase =
            start_paused ? TrackPlayerPhase::Paused : TrackPlayerPhase::Playing;
        phase_.store(next_phase, std::memory_order_release);

        StateNotifyHandler phase_cb;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            phase_cb = on_phase_changed_;
        }
        if (phase_cb) {
            phase_cb(next_phase);
        }

        if (session_gen_.load(std::memory_order_acquire) == gen) {
            prefetchUpcomingTrack();
        }
    });

    return true;
}

bool CoreAudioTrackPlayer::startRemoteTrack(const metadata::TrackInfo& info,
                                            int64_t start_position_ms,
                                            bool start_paused) {
    if (!engine_) return false;

    cancelWorker();
    const uint64_t gen = session_gen_.fetch_add(1, std::memory_order_acq_rel) + 1;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        current_info_ = info;
    }
    desired_paused_.store(start_paused, std::memory_order_release);
    duration_hint_ms_.store(info.duration_ms > 0 ? info.duration_ms : 0, std::memory_order_release);

    const std::string ogg_head_id =
        (start_position_ms <= 0) ? streamer::FileStreamerImpl::selectOggHeadFileId(info.files) : std::string{};

    bool head_started = false;
    if (!ogg_head_id.empty()) {
        const std::string cache_dir = file_streamer_.currentCacheDir();
        engine_->setAutoPlay(!start_paused);
        const EngineStatus head_st = engine_->loadTrackWithHead(
            ogg_head_id.c_str(),
            nullptr,
            cache_dir.c_str(),
            nullptr,
            nullptr,
            info.duration_ms > 0 ? info.duration_ms : -1);
        if (head_st == EngineStatus::Ok) {
            head_started = true;
            const TrackPlayerPhase next_phase =
                start_paused ? TrackPlayerPhase::Paused : TrackPlayerPhase::Playing;
            phase_.store(next_phase, std::memory_order_release);
            CATP_LOGI("Started Chunk 0 Ogg head playback immediately for %s (headId=%s)",
                      info.uri.c_str(), ogg_head_id.c_str());
        } else {
            CATP_LOGW("Head playback unavailable (%d) for %s; falling back to direct stream",
                      static_cast<int>(head_st), info.uri.c_str());
        }
    }

    if (!head_started) {
        engine_->stop();
        phase_.store(TrackPlayerPhase::Buffering, std::memory_order_release);
    }

    std::lock_guard<std::mutex> wlock(worker_mutex_);
    stream_worker_ = std::thread([this, gen, info, start_position_ms, head_started]() {
        JniThreadAttacher jniAttacher(getMusifyJavaVm(), "MusifyStreamWorker");
        const auto resolved = file_streamer_.resolveFullTrackStream(info);

        if (session_gen_.load(std::memory_order_acquire) != gen) {
            return;
        }

        if (!resolved.has_value() || resolved->cdn_url.empty()) {
            CATP_LOGE("Failed to resolve full stream for %s", info.uri.c_str());
            if (!head_started) {
                phase_.store(TrackPlayerPhase::Faulted, std::memory_order_release);
                ErrorHandler err_cb;
                {
                    std::lock_guard<std::mutex> lock(mutex_);
                    err_cb = on_error_;
                }
                if (err_cb) {
                    err_cb(-1, "Failed to resolve audio stream for " + info.uri);
                }
            }
            return;
        }

        if (session_gen_.load(std::memory_order_acquire) != gen) {
            return;
        }

        if (head_started) {
            const EngineStatus attach_st = engine_->attachSecondaryStream(
                resolved->cdn_url.c_str(),
                resolved->is_encrypted ? resolved->license_url.c_str() : nullptr,
                resolved->is_encrypted ? resolved->auth_header.c_str() : nullptr,
                -1);
            if (attach_st != EngineStatus::Ok) {
                CATP_LOGW("attachSecondaryStream returned %d for %s",
                          static_cast<int>(attach_st), info.uri.c_str());
            }
        } else {
            const bool paused_now = desired_paused_.load(std::memory_order_acquire);
            engine_->setAutoPlay(!paused_now);

            EngineStatus load_st = EngineStatus::ErrorIO;
            if (resolved->is_encrypted) {
                load_st = engine_->loadEncryptedStream(
                    resolved->cdn_url.c_str(),
                    resolved->license_url.c_str(),
                    resolved->auth_header.c_str());
            } else {
                load_st = engine_->loadLocal(resolved->cdn_url.c_str());
            }

            if (session_gen_.load(std::memory_order_acquire) != gen) {
                return;
            }

            if (load_st != EngineStatus::Ok) {
                CATP_LOGE("Direct stream load failed (%d) for %s",
                          static_cast<int>(load_st), info.uri.c_str());
                phase_.store(TrackPlayerPhase::Faulted, std::memory_order_release);
                ErrorHandler err_cb;
                {
                    std::lock_guard<std::mutex> lock(mutex_);
                    err_cb = on_error_;
                }
                if (err_cb) {
                    err_cb(static_cast<int32_t>(load_st), "Audio decoder failed for " + info.uri);
                }
                return;
            }

            if (start_position_ms > 0) {
                engine_->seekMs(start_position_ms);
            }

            const TrackPlayerPhase ready_phase =
                paused_now ? TrackPlayerPhase::Paused : TrackPlayerPhase::Playing;
            phase_.store(ready_phase, std::memory_order_release);

            StateNotifyHandler phase_cb;
            {
                std::lock_guard<std::mutex> lock(mutex_);
                phase_cb = on_phase_changed_;
            }
            if (phase_cb) {
                phase_cb(ready_phase);
            }
        }

        if (session_gen_.load(std::memory_order_acquire) == gen) {
            prefetchUpcomingTrack();
        }
    });

    return true;
}

void CoreAudioTrackPlayer::prefetchUpcomingTrack() {
    PrefetchPeekHandler peek_cb;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        peek_cb = peek_next_;
    }
    if (!peek_cb) return;

    const auto next_entry = peek_cb();
    if (!next_entry.has_value() || next_entry->uri.empty()) return;
    if (next_entry->uri.rfind("spotify:track:", 0) != 0) return;

    if (const auto cached = track_info_provider_.getCached(next_entry->uri);
        cached.has_value() && cached->hasPlayableSource()) {
        file_streamer_.prefetchTrackHead(*cached);
    } else {
        track_info_provider_.requestResolution(next_entry->uri);
    }
}

void CoreAudioTrackPlayer::stop() {
    cancelWorker();
    if (engine_) {
        engine_->stop();
    }
    {
        std::lock_guard<std::mutex> lock(mutex_);
        current_info_.reset();
    }
    duration_hint_ms_.store(0, std::memory_order_release);
    phase_.store(TrackPlayerPhase::Idle, std::memory_order_release);
}

bool CoreAudioTrackPlayer::pause() {
    desired_paused_.store(true, std::memory_order_release);
    if (!engine_) return false;
    engine_->pause();
    phase_.store(TrackPlayerPhase::Paused, std::memory_order_release);
    return true;
}

bool CoreAudioTrackPlayer::resume() {
    desired_paused_.store(false, std::memory_order_release);
    if (!engine_) return false;
    engine_->play();
    const auto cur = phase_.load(std::memory_order_acquire);
    if (cur != TrackPlayerPhase::Buffering) {
        phase_.store(TrackPlayerPhase::Playing, std::memory_order_release);
    }
    return true;
}

bool CoreAudioTrackPlayer::seek(int64_t position_ms) {
    if (!engine_) return false;

    std::optional<metadata::TrackInfo> info;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        info = current_info_;
    }
    if (info.has_value() && engine_->isDualSource() && !engine_->isHandoffCompleted()) {
        return startRemoteTrack(*info, position_ms, desired_paused_.load(std::memory_order_acquire));
    }
    return engine_->seekMs(position_ms) == EngineStatus::Ok;
}

int64_t CoreAudioTrackPlayer::getPositionMs() const {
    if (!engine_) return 0;
    const auto ph = phase_.load(std::memory_order_acquire);
    if (ph == TrackPlayerPhase::Idle || ph == TrackPlayerPhase::Buffering) {
        return 0;
    }
    return engine_->getPositionMs();
}

int64_t CoreAudioTrackPlayer::getDurationMs() const {
    if (engine_) {
        const int64_t eng_dur = engine_->getDurationMs();
        const int64_t hint_dur = duration_hint_ms_.load(std::memory_order_acquire);
        if (hint_dur > eng_dur) return hint_dur;
        if (eng_dur > 0) return eng_dur;
    }
    return duration_hint_ms_.load(std::memory_order_acquire);
}

TrackPlayerPhase CoreAudioTrackPlayer::getPhase() const {
    return phase_.load(std::memory_order_acquire);
}

} // namespace spotify::player::rendering
