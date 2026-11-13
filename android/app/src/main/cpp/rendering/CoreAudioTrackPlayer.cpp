#include "CoreAudioTrackPlayer.h"

#include <android/log.h>
#include <future>
#include <sys/stat.h>

#define CATP_LOG_TAG "MusifyCoreAudioPlayer"
#define CATP_LOGI(...) __android_log_print(ANDROID_LOG_INFO, CATP_LOG_TAG, __VA_ARGS__)
#define CATP_LOGW(...) __android_log_print(ANDROID_LOG_WARN, CATP_LOG_TAG, __VA_ARGS__)
#define CATP_LOGE(...) __android_log_print(ANDROID_LOG_ERROR, CATP_LOG_TAG, __VA_ARGS__)

namespace spotify::player::rendering {

namespace {

TrackPlayerPhase mapEngineStateToPhase(EngineState eng_state) noexcept {
    switch (eng_state) {
        case EngineState::Uninitialized:
        case EngineState::Idle:
            return TrackPlayerPhase::Idle;
        case EngineState::Loading:
        case EngineState::Prebuffering:
            return TrackPlayerPhase::Buffering;
        case EngineState::Playing:
            return TrackPlayerPhase::Playing;
        case EngineState::Paused:
            return TrackPlayerPhase::Paused;
        case EngineState::Stopped:
            return TrackPlayerPhase::Stopped;
        case EngineState::Faulted:
            return TrackPlayerPhase::Faulted;
    }
    return TrackPlayerPhase::Idle;
}

} // namespace

CoreAudioTrackPlayer::CoreAudioTrackPlayer(
    AudioEngine* engine,
    streamer::FileStreamerImpl& file_streamer,
    metadata::TrackInfoProvider& track_info_provider)
    : engine_(engine),
      file_streamer_(file_streamer),
      track_info_provider_(track_info_provider) {
    if (engine_) {
        engine_->setEosCallback([this, alive_guard = alive_flag_]() {
            if (!alive_guard->load(std::memory_order_acquire)) return;
            // Gate EOS on a session-scoped latch rather than phase_ == Stopped,
            // because EngineState::Stopped state callbacks run independently and
            // must not silence EndOfTrack advancement.
            if (!eos_armed_.exchange(false, std::memory_order_acq_rel)) {
                return;
            }
            phase_.store(TrackPlayerPhase::Stopped, std::memory_order_release);
            EosHandler cb;
            {
                std::lock_guard<std::mutex> lock(mutex_);
                cb = on_eos_;
            }
            if (cb) {
                cb();
            } else {
                notifyPhaseChanged(TrackPlayerPhase::Stopped);
            }
        });
        engine_->setSecondaryFailureCallback([this, alive_guard = alive_flag_](const std::string& reason) {
            if (!alive_guard->load(std::memory_order_acquire)) return;
            eos_armed_.store(false, std::memory_order_release);
            engine_->pause();
            phase_.store(TrackPlayerPhase::Faulted, std::memory_order_release);
            ErrorHandler err_cb;
            {
                std::lock_guard<std::mutex> lock(mutex_);
                err_cb = on_error_;
            }
            if (err_cb) {
                err_cb(-2, reason);
            }
            notifyPhaseChanged(TrackPlayerPhase::Faulted);
        });
        engine_->setStateCallback([this](EngineState eng_state) {
            if (!alive_flag_->load(std::memory_order_acquire)) return;
            const TrackPlayerPhase mapped = mapEngineStateToPhase(eng_state);
            phase_.store(mapped, std::memory_order_release);
            notifyPhaseChanged(mapped);
        });
    }
}

CoreAudioTrackPlayer::~CoreAudioTrackPlayer() {
    alive_flag_->store(false, std::memory_order_release);
    if (engine_) {
        engine_->setStateCallback(nullptr);
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

void CoreAudioTrackPlayer::notifyPhaseChanged(TrackPlayerPhase phase) {
    StateNotifyHandler phase_cb;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        phase_cb = on_phase_changed_;
    }
    if (phase_cb) {
        phase_cb(phase);
    }
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

    eos_armed_.store(false, std::memory_order_release);
    cancelWorker();
    const uint64_t gen = session_gen_.fetch_add(1, std::memory_order_acq_rel) + 1;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        current_info_.reset();
    }
    desired_paused_.store(start_paused, std::memory_order_release);
    duration_hint_ms_.store(duration_hint_ms > 0 ? duration_hint_ms : 0, std::memory_order_release);
    eos_armed_.store(true, std::memory_order_release);
    phase_.store(TrackPlayerPhase::Buffering, std::memory_order_release);

    std::lock_guard<std::mutex> wlock(worker_mutex_);
    stream_worker_ = std::thread([this, gen, file_path, start_position_ms, start_paused]() {
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
        notifyPhaseChanged(next_phase);

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

    eos_armed_.store(false, std::memory_order_release);
    cancelWorker();
    const uint64_t gen = session_gen_.fetch_add(1, std::memory_order_acq_rel) + 1;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        current_info_ = info;
    }
    desired_paused_.store(start_paused, std::memory_order_release);
    duration_hint_ms_.store(info.duration_ms > 0 ? info.duration_ms : 0, std::memory_order_release);
    eos_armed_.store(true, std::memory_order_release);

    const std::string ogg_head_id =
        (start_position_ms <= 0) ? streamer::FileStreamerImpl::selectOggHeadFileId(info.files) : std::string{};
    const std::string cache_dir = file_streamer_.currentCacheDir();

    bool head_cached_on_disk = false;
    if (!ogg_head_id.empty()) {
        const std::string cached_head_path = cache_dir + "/heads/" + ogg_head_id + ".ogg";
        struct stat st{};
        head_cached_on_disk = (::stat(cached_head_path.c_str(), &st) == 0 && st.st_size >= 512);
    }

    bool head_started = false;
    if (head_cached_on_disk) {
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
            const TrackPlayerPhase initial_phase =
                start_paused ? TrackPlayerPhase::Paused : TrackPlayerPhase::Buffering;
            phase_.store(initial_phase, std::memory_order_release);
            notifyPhaseChanged(initial_phase);
            CATP_LOGI("Started cached Chunk 0 Ogg head immediately for %s (headId=%s)",
                      info.uri.c_str(), ogg_head_id.c_str());
        } else {
            CATP_LOGW("Cached head load failed (%d) for %s; falling back to stream",
                      static_cast<int>(head_st), info.uri.c_str());
        }
    }

    if (!head_started) {
        engine_->stop();
        phase_.store(TrackPlayerPhase::Buffering, std::memory_order_release);
        notifyPhaseChanged(TrackPlayerPhase::Buffering);
    }

    std::shared_ptr<std::atomic<bool>> alive_guard = alive_flag_;
    std::lock_guard<std::mutex> wlock(worker_mutex_);
    stream_worker_ = std::thread([this, gen, info, start_position_ms, start_paused,
                                  ogg_head_id, cache_dir, head_started, alive_guard]() {
        bool local_head_started = head_started;
        std::optional<streamer::ResolvedFullStream> resolved;

        if (!local_head_started && !ogg_head_id.empty()) {
            // Overlap Chunk 0 head streaming with /storage-resolve instead of running them serially.
            auto resolve_future = std::async(std::launch::async, [this, info]() {
                return file_streamer_.resolveFullTrackStream(info);
            });

            if (session_gen_.load(std::memory_order_acquire) == gen) {
                engine_->setAutoPlay(!start_paused);
                const EngineStatus head_st = engine_->loadTrackWithHead(
                    ogg_head_id.c_str(),
                    nullptr,
                    cache_dir.c_str(),
                    nullptr,
                    nullptr,
                    info.duration_ms > 0 ? info.duration_ms : -1);
                if (head_st == EngineStatus::Ok &&
                    session_gen_.load(std::memory_order_acquire) == gen) {
                    local_head_started = true;
                    const TrackPlayerPhase initial_phase =
                        start_paused ? TrackPlayerPhase::Paused : TrackPlayerPhase::Buffering;
                    phase_.store(initial_phase, std::memory_order_release);
                    notifyPhaseChanged(initial_phase);
                    CATP_LOGI("Started streamed Chunk 0 Ogg head for %s (headId=%s)",
                              info.uri.c_str(), ogg_head_id.c_str());
                }
            }

            resolved = resolve_future.get();
        } else {
            resolved = file_streamer_.resolveFullTrackStream(info);
        }

        if (session_gen_.load(std::memory_order_acquire) != gen) {
            return;
        }

        if (!resolved.has_value() || resolved->cdn_url.empty()) {
            CATP_LOGE("Failed to resolve full stream for %s", info.uri.c_str());
            if (!local_head_started) {
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

        spotify::network::UrlRefreshCallback refresh_cb =
            [this, gen, info, alive_guard]() -> std::vector<std::string> {
                if (!alive_guard->load(std::memory_order_acquire) ||
                    session_gen_.load(std::memory_order_acquire) != gen) {
                    return {};
                }
                const auto refreshed = file_streamer_.resolveFullTrackStream(info);
                if (!refreshed.has_value()) return {};
                if (!refreshed->cdn_urls.empty()) return refreshed->cdn_urls;
                if (!refreshed->cdn_url.empty()) return {refreshed->cdn_url};
                return {};
            };

        if (local_head_started) {
            const EngineStatus attach_st = engine_->attachSecondaryStream(
                resolved->cdn_url.c_str(),
                resolved->is_encrypted ? resolved->license_url.c_str() : nullptr,
                resolved->is_encrypted ? resolved->auth_header.c_str() : nullptr,
                -1,
                resolved->cdn_urls,
                std::move(refresh_cb));
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
                    resolved->auth_header.c_str(),
                    resolved->cdn_urls,
                    std::move(refresh_cb));
            } else {
                load_st = engine_->loadLocal(
                    resolved->cdn_url.c_str(),
                    resolved->cdn_urls,
                    std::move(refresh_cb));
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
                paused_now ? TrackPlayerPhase::Paused : TrackPlayerPhase::Buffering;
            phase_.store(ready_phase, std::memory_order_release);
            notifyPhaseChanged(ready_phase);
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
        // Pre-warm /storage-resolve CDN URLs & Widevine context so queue advances skip lookup RTT.
        (void)file_streamer_.resolveFullTrackStream(*cached);
    } else {
        track_info_provider_.requestResolution(next_entry->uri);
    }
}

void CoreAudioTrackPlayer::stop() {
    eos_armed_.store(false, std::memory_order_release);
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
    notifyPhaseChanged(TrackPlayerPhase::Paused);
    return true;
}

bool CoreAudioTrackPlayer::resume() {
    desired_paused_.store(false, std::memory_order_release);
    if (!engine_) return false;
    eos_armed_.store(true, std::memory_order_release);
    engine_->play();
    const auto mapped = mapEngineStateToPhase(static_cast<EngineState>(engine_->getState()));
    phase_.store(mapped, std::memory_order_release);
    notifyPhaseChanged(mapped);
    return true;
}

bool CoreAudioTrackPlayer::seek(int64_t position_ms) {
    if (!engine_) return false;
    const bool ok = engine_->seekMs(position_ms) == EngineStatus::Ok;
    if (ok) {
        eos_armed_.store(true, std::memory_order_release);
    }
    return ok;
}

int64_t CoreAudioTrackPlayer::getPositionMs() const {
    if (!engine_) return 0;
    const auto ph = phase_.load(std::memory_order_acquire);
    if (ph == TrackPlayerPhase::Idle) {
        return 0;
    }
    return engine_->getPositionMs();
}

int64_t CoreAudioTrackPlayer::getDurationMs() const {
    if (engine_) {
        if (engine_->hasAuthoritativeDuration()) {
            const int64_t auth_dur = engine_->getDurationMs();
            if (auth_dur > 0) return auth_dur;
        }
        const int64_t hint_dur = duration_hint_ms_.load(std::memory_order_acquire);
        if (hint_dur > 0) return hint_dur;
        const int64_t eng_dur = engine_->getDurationMs();
        if (eng_dur > 0) return eng_dur;
    }
    return duration_hint_ms_.load(std::memory_order_acquire);
}

TrackPlayerPhase CoreAudioTrackPlayer::getPhase() const {
    return phase_.load(std::memory_order_acquire);
}

} // namespace spotify::player::rendering
