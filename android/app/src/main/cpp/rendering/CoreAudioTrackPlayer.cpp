#include "CoreAudioTrackPlayer.h"

#include "../content_delivery/HeadFileManager.h"
#include "../network/NativeTrafficController.h"

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
            if (eos_state_.exchange(EosTriggerState::Disarmed, std::memory_order_acq_rel) !=
                EosTriggerState::Armed) {
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
            eos_state_.store(EosTriggerState::Disarmed, std::memory_order_release);
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

uint64_t CoreAudioTrackPlayer::cancelWorker(std::optional<EngineState> quiesce_state) {
    const uint64_t next_gen = session_gen_.fetch_add(1, std::memory_order_acq_rel) + 1;
    // Silence hardware output BEFORE waking/joining stream_worker_ so any active previous
    // track cannot keep playing during metadata/head-cache checks or worker teardown.
    if (engine_) {
        if (quiesce_state.has_value()) {
            engine_->quiesceOutputForTransition(*quiesce_state);
        } else {
            engine_->cancelPendingLoads();
        }
    }
    network::NativeTrafficController::instance().notifyAllWaiters();
    content_delivery::HeadFileManager::wakeAllWaiters();
    std::lock_guard<std::mutex> wlock(worker_mutex_);
    if (stream_worker_.joinable()) {
        stream_worker_.join();
    }
    return next_gen;
}

uint64_t CoreAudioTrackPlayer::beginTrackSession(std::optional<metadata::TrackInfo> info,
                                                 int64_t duration_hint_ms,
                                                 int64_t start_position_ms,
                                                 PlaybackIntent intent) {
    eos_state_.store(EosTriggerState::Disarmed, std::memory_order_release);
    const uint64_t gen = cancelWorker(EngineState::Loading);
    {
        std::lock_guard<std::mutex> lock(mutex_);
        current_info_ = std::move(info);
    }
    playback_intent_.store(intent, std::memory_order_release);
    duration_hint_ms_.store(duration_hint_ms > 0 ? duration_hint_ms : 0, std::memory_order_release);
    pending_position_ms_.store(start_position_ms > 0 ? start_position_ms : 0, std::memory_order_release);
    eos_state_.store(EosTriggerState::Armed, std::memory_order_release);
    return gen;
}

bool CoreAudioTrackPlayer::startLocalFile(const std::string& file_path,
                                          int64_t duration_hint_ms,
                                          int64_t start_position_ms,
                                          bool start_paused) {
    if (!engine_ || file_path.empty()) return false;

    const PlaybackIntent intent =
        start_paused ? PlaybackIntent::HoldPaused : PlaybackIntent::AutoPlay;
    const uint64_t gen = beginTrackSession(
        std::nullopt, duration_hint_ms, start_position_ms, intent);

    engine_->stop();
    const TrackPlayerPhase wait_phase =
        start_paused ? TrackPlayerPhase::Paused : TrackPlayerPhase::Buffering;
    phase_.store(wait_phase, std::memory_order_release);
    notifyPhaseChanged(wait_phase);

    std::shared_ptr<std::atomic<bool>> alive_guard = alive_flag_;
    std::lock_guard<std::mutex> wlock(worker_mutex_);
    stream_worker_ = std::thread([this, gen, file_path, alive_guard]() {
        const network::CancelPredicate cancel_pred = [this, gen, alive_guard]() -> bool {
            return !alive_guard->load(std::memory_order_acquire) ||
                   session_gen_.load(std::memory_order_acquire) != gen;
        };
        if (cancel_pred()) {
            return;
        }

        const bool paused_now =
            playback_intent_.load(std::memory_order_acquire) == PlaybackIntent::HoldPaused;
        engine_->setAutoPlay(!paused_now);
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

        const int64_t target_pos_ms = pending_position_ms_.exchange(0, std::memory_order_acq_rel);
        if (target_pos_ms > 0) {
            engine_->seekMs(target_pos_ms);
        }

        const bool paused_after =
            playback_intent_.load(std::memory_order_acquire) == PlaybackIntent::HoldPaused;
        const TrackPlayerPhase next_phase = paused_after
            ? TrackPlayerPhase::Paused
            : mapEngineStateToPhase(static_cast<EngineState>(engine_->getState()));
        phase_.store(next_phase, std::memory_order_release);
        notifyPhaseChanged(next_phase);

        if (!cancel_pred()) {
            prefetchUpcomingTrack(cancel_pred);
        }
    });

    return true;
}

bool CoreAudioTrackPlayer::startRemoteTrack(const metadata::TrackInfo& info,
                                            int64_t start_position_ms,
                                            bool start_paused) {
    if (!engine_) return false;

    const PlaybackIntent intent =
        start_paused ? PlaybackIntent::HoldPaused : PlaybackIntent::AutoPlay;
    const uint64_t gen = beginTrackSession(
        info, info.duration_ms, start_position_ms, intent);

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
            const TrackPlayerPhase initial_phase = start_paused
                ? TrackPlayerPhase::Paused
                : mapEngineStateToPhase(static_cast<EngineState>(engine_->getState()));
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
        // Stop the previous track's decoder/Oboe stream immediately so old audio stops
        // and the seekbar position resets to 0:00 (or start_position_ms) even while offline.
        engine_->stop();
        const TrackPlayerPhase wait_phase =
            start_paused ? TrackPlayerPhase::Paused : TrackPlayerPhase::Buffering;
        phase_.store(wait_phase, std::memory_order_release);
        notifyPhaseChanged(wait_phase);
    }

    std::shared_ptr<std::atomic<bool>> alive_guard = alive_flag_;
    std::lock_guard<std::mutex> wlock(worker_mutex_);
    stream_worker_ = std::thread([this, gen, info,
                                  ogg_head_id, cache_dir, head_started, alive_guard]() {
        const network::CancelPredicate cancel_pred = [this, gen, alive_guard]() -> bool {
            return !alive_guard->load(std::memory_order_acquire) ||
                   session_gen_.load(std::memory_order_acquire) != gen;
        };

        bool local_head_started = head_started;
        std::optional<streamer::ResolvedFullStream> resolved;

        const bool can_stream_remote_head =
            !local_head_started &&
            !ogg_head_id.empty() &&
            network::NativeTrafficController::instance().isOnline() &&
            !file_streamer_.hasCachedFullTrackStream(info);

        if (can_stream_remote_head) {
            // Overlap Chunk 0 head streaming with /storage-resolve instead of running them serially.
            auto resolve_future = std::async(
                std::launch::async,
                [this, info, cancel_pred]() {
                    return file_streamer_.resolveFullTrackStream(
                        info,
                        cancel_pred,
                        network::AcquisitionIntent::InteractivePlayback);
                });

            if (!cancel_pred()) {
                const bool paused_now =
                    playback_intent_.load(std::memory_order_acquire) == PlaybackIntent::HoldPaused;
                engine_->setAutoPlay(!paused_now);
                const EngineStatus head_st = engine_->loadTrackWithHead(
                    ogg_head_id.c_str(),
                    nullptr,
                    cache_dir.c_str(),
                    nullptr,
                    nullptr,
                    info.duration_ms > 0 ? info.duration_ms : -1);
                if (head_st == EngineStatus::Ok && !cancel_pred()) {
                    local_head_started = true;
                    const int64_t target_pos_ms =
                        pending_position_ms_.exchange(0, std::memory_order_acq_rel);
                    if (target_pos_ms > 0) {
                        engine_->seekMs(target_pos_ms);
                    }
                    const bool paused_after =
                        playback_intent_.load(std::memory_order_acquire) == PlaybackIntent::HoldPaused;
                    const TrackPlayerPhase initial_phase = paused_after
                        ? TrackPlayerPhase::Paused
                        : mapEngineStateToPhase(static_cast<EngineState>(engine_->getState()));
                    phase_.store(initial_phase, std::memory_order_release);
                    notifyPhaseChanged(initial_phase);
                    CATP_LOGI("Started streamed Chunk 0 Ogg head for %s (headId=%s)",
                              info.uri.c_str(), ogg_head_id.c_str());
                }
            }

            resolved = resolve_future.get();
        } else {
            resolved = file_streamer_.resolveFullTrackStream(
                info,
                cancel_pred,
                network::AcquisitionIntent::InteractivePlayback);
        }

        if (cancel_pred()) {
            return;
        }

        if (!resolved.has_value() || resolved->cdn_url.empty()) {
            CATP_LOGE("Failed to resolve full stream for %s", info.uri.c_str());
            if (local_head_started) {
                if (!cancel_pred()) {
                    engine_->abortSecondaryAttachment(
                        "Failed to resolve audio stream for " + info.uri);
                }
            } else {
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

        if (cancel_pred()) {
            return;
        }

        spotify::network::UrlRefreshCallback refresh_cb =
            [this, info, cancel_pred]() -> std::vector<std::string> {
                if (cancel_pred()) {
                    return {};
                }
                const auto refreshed = file_streamer_.resolveFullTrackStream(
                    info,
                    cancel_pred,
                    network::AcquisitionIntent::InteractivePlayback);
                if (!refreshed.has_value()) return {};
                if (!refreshed->cdn_urls.empty()) return refreshed->cdn_urls;
                if (!refreshed->cdn_url.empty()) return {refreshed->cdn_url};
                return {};
            };

        if (local_head_started) {
            const EngineStatus attach_st = engine_->attachSecondaryStream(
                resolved->cdn_url.c_str(),
                resolved->usesWidevine() ? resolved->license_url.c_str() : nullptr,
                resolved->usesWidevine() ? resolved->auth_header.c_str() : nullptr,
                -1,
                resolved->cdn_urls,
                std::move(refresh_cb));
            if (attach_st != EngineStatus::Ok) {
                CATP_LOGW("attachSecondaryStream returned %d for %s",
                          static_cast<int>(attach_st), info.uri.c_str());
                if (!cancel_pred()) {
                    engine_->abortSecondaryAttachment(
                        "attachSecondaryStream rejected (" +
                        std::to_string(static_cast<int>(attach_st)) + ")");
                }
            }
        } else {
            const bool paused_now =
                playback_intent_.load(std::memory_order_acquire) == PlaybackIntent::HoldPaused;
            engine_->setAutoPlay(!paused_now);

            EngineStatus load_st = EngineStatus::ErrorIO;
            if (resolved->usesWidevine()) {
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

            if (cancel_pred()) {
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

            const int64_t target_pos_ms =
                pending_position_ms_.exchange(0, std::memory_order_acq_rel);
            if (target_pos_ms > 0) {
                engine_->seekMs(target_pos_ms);
            }

            const bool paused_after =
                playback_intent_.load(std::memory_order_acquire) == PlaybackIntent::HoldPaused;
            const TrackPlayerPhase ready_phase = paused_after
                ? TrackPlayerPhase::Paused
                : mapEngineStateToPhase(static_cast<EngineState>(engine_->getState()));
            phase_.store(ready_phase, std::memory_order_release);
            notifyPhaseChanged(ready_phase);
        }

        if (!cancel_pred()) {
            prefetchUpcomingTrack(cancel_pred);
        }
    });

    return true;
}

void CoreAudioTrackPlayer::prefetchUpcomingTrack(
    const network::CancelPredicate& cancel_pred) {
    if (cancel_pred && cancel_pred()) return;

    PrefetchPeekHandler peek_cb;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        peek_cb = peek_next_;
    }
    if (!peek_cb) return;

    const auto next_entry = peek_cb();
    if (!next_entry.has_value() || next_entry->uri.empty()) return;
    const bool is_prefetchable =
        next_entry->uri.rfind("spotify:track:", 0) == 0 ||
        next_entry->uri.rfind("spotify:episode:", 0) == 0;
    if (!is_prefetchable) return;

    if (const auto cached = track_info_provider_.getCached(next_entry->uri);
        cached.has_value() && cached->hasPlayableSource()) {
        file_streamer_.prefetchTrackHead(*cached);
        // Pre-warm /storage-resolve CDN URLs on P3_BackgroundBatch (FailFastOffline).
        (void)file_streamer_.resolveFullTrackStream(
            *cached,
            cancel_pred,
            network::AcquisitionIntent::BackgroundPrefetch);
    } else {
        track_info_provider_.requestResolution(
            next_entry->uri,
            network::AcquisitionIntent::BackgroundPrefetch);
    }
}

void CoreAudioTrackPlayer::stop() {
    eos_state_.store(EosTriggerState::Disarmed, std::memory_order_release);
    (void)cancelWorker(EngineState::Idle);
    if (engine_) {
        engine_->stop();
    }
    {
        std::lock_guard<std::mutex> lock(mutex_);
        current_info_.reset();
    }
    duration_hint_ms_.store(0, std::memory_order_release);
    pending_position_ms_.store(0, std::memory_order_release);
    phase_.store(TrackPlayerPhase::Idle, std::memory_order_release);
}

bool CoreAudioTrackPlayer::pause() {
    playback_intent_.store(PlaybackIntent::HoldPaused, std::memory_order_release);
    if (!engine_) return false;
    engine_->pause();
    phase_.store(TrackPlayerPhase::Paused, std::memory_order_release);
    notifyPhaseChanged(TrackPlayerPhase::Paused);
    return true;
}

bool CoreAudioTrackPlayer::resume() {
    playback_intent_.store(PlaybackIntent::AutoPlay, std::memory_order_release);
    if (!engine_) return false;
    eos_state_.store(EosTriggerState::Armed, std::memory_order_release);
    const EngineState eng_state = static_cast<EngineState>(engine_->getState());
    if (eng_state == EngineState::Idle || eng_state == EngineState::Loading) {
        phase_.store(TrackPlayerPhase::Buffering, std::memory_order_release);
        notifyPhaseChanged(TrackPlayerPhase::Buffering);
        return true;
    }
    engine_->play();
    const auto mapped = mapEngineStateToPhase(static_cast<EngineState>(engine_->getState()));
    phase_.store(mapped, std::memory_order_release);
    notifyPhaseChanged(mapped);
    return true;
}

bool CoreAudioTrackPlayer::seek(int64_t position_ms) {
    if (!engine_) return false;
    const int64_t clamped_pos = position_ms >= 0 ? position_ms : 0;
    const EngineState eng_state = static_cast<EngineState>(engine_->getState());
    if (eng_state == EngineState::Idle || eng_state == EngineState::Loading) {
        pending_position_ms_.store(clamped_pos, std::memory_order_release);
        eos_state_.store(EosTriggerState::Armed, std::memory_order_release);
        return true;
    }
    const bool ok = engine_->seekMs(clamped_pos) == EngineStatus::Ok;
    if (ok) {
        pending_position_ms_.store(0, std::memory_order_release);
        eos_state_.store(EosTriggerState::Armed, std::memory_order_release);
    }
    return ok;
}

int64_t CoreAudioTrackPlayer::getPositionMs() const {
    if (!engine_) return 0;
    const auto ph = phase_.load(std::memory_order_acquire);
    if (ph == TrackPlayerPhase::Idle) {
        return 0;
    }
    const EngineState eng_state = static_cast<EngineState>(engine_->getState());
    if (eng_state == EngineState::Idle || eng_state == EngineState::Loading) {
        return pending_position_ms_.load(std::memory_order_acquire);
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
