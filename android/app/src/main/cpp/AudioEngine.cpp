#include "AudioEngine.h"
#include "content_delivery/HeadFileManager.h"
#include "drm/WidevineLicenseClient.h"
#include "network/NativeHttpClient.h"

#include <algorithm>
#include <chrono>
#include <cstring>
#include <future>
#include <sys/stat.h>

#include <android/log.h>

#define LOG_TAG "MusifyEngine"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN,  LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static const uint8_t kWidevineUuid[16] = {
    0xed, 0xef, 0x8b, 0xa9, 0x79, 0xd6, 0x4a, 0xce,
    0xa3, 0xc8, 0x27, 0xdc, 0xd5, 0x1d, 0x21, 0xed
};

// ===========================================================================
// Construction / Destruction
// ===========================================================================

AudioEngine::AudioEngine() {
    mState.store(EngineState::Idle, std::memory_order_release);
    mEosDispatcherThread = std::thread(&AudioEngine::eosDispatcherFunc, this);
}

AudioEngine::~AudioEngine() {
    mMonitorShouldStop.store(true, std::memory_order_release);
    wakeMonitor();
    {
        std::lock_guard<std::mutex> lock(mEosMutex);
        mEosCallback = nullptr;
        mSecondaryFailureCallback = nullptr;
        mStateCallback = nullptr;
        mEosPending = false;
        mEosWorkerStop = true;
    }
    mEosCv.notify_all();
    if (mEosDispatcherThread.joinable()) {
        if (mEosDispatcherThread.get_id() != std::this_thread::get_id()) {
            mEosDispatcherThread.join();
        } else {
            LOGE("AudioEngine: Refusing self-join on mEosDispatcherThread in destructor");
        }
    }
    stopPlayback();
    closeOboeStream();
    closeActiveDrmSession();
}

std::shared_ptr<AudioEngine::LoadSessionToken> AudioEngine::beginNewLoadSession() {
    std::shared_ptr<LoadSessionToken> prev;
    auto next = std::make_shared<LoadSessionToken>();
    {
        std::lock_guard<std::mutex> lock(mSourceCancelMutex);
        prev = std::move(mActiveLoadSession);
        mActiveLoadSession = next;
    }
    if (prev) {
        prev->cancel();
    }
    return next;
}

void AudioEngine::cancelActiveLoadSession() {
    std::shared_ptr<LoadSessionToken> active;
    {
        std::lock_guard<std::mutex> lock(mSourceCancelMutex);
        active = mActiveLoadSession;
    }
    if (active) {
        active->cancel();
    }
}

void AudioEngine::wakeMonitor() noexcept {
    mMonitorCv.notify_all();
}

void AudioEngine::eosDispatcherFunc() {
    while (true) {
        EosCallback cb;
        {
            std::unique_lock<std::mutex> lock(mEosMutex);
            mEosCv.wait(lock, [this]() { return mEosPending || mEosWorkerStop; });
            if (mEosWorkerStop && !mEosPending) {
                break;
            }
            mEosPending = false;
            cb = mEosCallback;
        }
        if (cb) {
            cb();
        }
    }
}

void AudioEngine::joinMonitorThread() {
    mMonitorShouldStop.store(true, std::memory_order_release);
    wakeMonitor();
    if (mMonitorThread.joinable()) {
        if (mMonitorThread.get_id() == std::this_thread::get_id()) {
            LOGE("AudioEngine: Refusing self-join on mMonitorThread");
        } else {
            mMonitorThread.join();
        }
    }
}

void AudioEngine::setEosCallback(EosCallback cb) {
    std::lock_guard<std::mutex> lock(mEosMutex);
    mEosCallback = std::move(cb);
}

void AudioEngine::setSecondaryFailureCallback(SecondaryFailureCallback cb) {
    std::lock_guard<std::mutex> lock(mEosMutex);
    mSecondaryFailureCallback = std::move(cb);
}

void AudioEngine::setStateCallback(StateCallback cb) {
    std::lock_guard<std::mutex> lock(mEosMutex);
    mStateCallback = std::move(cb);
}

void AudioEngine::notifyStateChanged(EngineState state) {
    StateCallback cb;
    {
        std::lock_guard<std::mutex> lock(mEosMutex);
        cb = mStateCallback;
    }
    if (cb) {
        cb(state);
    }
}

void AudioEngine::failSecondary(const std::shared_ptr<LoadSessionToken>& sessionToken,
                                const std::string& reason) {
    LOGE("Secondary stream failed: %s", reason.c_str());
    mSecondaryPhase.store(SecondaryStreamPhase::Failed, std::memory_order_release);
    wakeMonitor();
    if (sessionToken && sessionToken->isCancelled()) {
        return;
    }
    SecondaryFailureCallback cb;
    {
        std::lock_guard<std::mutex> lock(mEosMutex);
        cb = mSecondaryFailureCallback;
    }
    if (cb) {
        cb(reason);
    }
}

void AudioEngine::setAutoPlay(bool autoPlay) {
    mStartPolicy.store(
        autoPlay ? StartPolicy::AutoPlayOnWatermark : StartPolicy::HoldPausedOnWatermark,
        std::memory_order_release);
}

void AudioEngine::stop() {
    stopPlayback();
    mFramesConsumedByHardware.store(0, std::memory_order_release);
    mSeekPositionMs.store(0, std::memory_order_release);
    mDurationMs.store(0, std::memory_order_release);
    mDurationAuthority.store(DurationAuthority::Estimated, std::memory_order_release);
    mState.store(EngineState::Idle, std::memory_order_release);
}

void AudioEngine::cancelPendingLoads() {
    cancelActiveLoadSession();
    cancelAllActiveSources();
    spotify::network::NativeTrafficController::instance().notifyAllWaiters();
}

void AudioEngine::cancelAllActiveSources() {
    std::shared_ptr<LoadSessionToken> activeSession;
    {
        std::lock_guard<std::mutex> lock(mSourceCancelMutex);
        activeSession = mActiveLoadSession;
        if (mDataSource) mDataSource->cancel();
        if (mPrimarySource) mPrimarySource->cancel();
        if (mSecondarySource) mSecondarySource->cancel();
    }
    if (activeSession) {
        activeSession->cancel();
    }
}

void AudioEngine::closeOboeStream() {
    std::shared_ptr<oboe::AudioStream> streamToClose;
    {
        std::lock_guard<std::mutex> lock(mStreamMutex);
        streamToClose = std::move(mStream);
        mStreamSampleRate = 0;
    }
    if (streamToClose) {
        streamToClose->requestStop();
        streamToClose->close();
    }
}

// ===========================================================================
// Internal: stop all playback components (preserving warm Oboe stream & DRM LRU)
// ===========================================================================

void AudioEngine::stopPlayback() {
    mMonitorShouldStop.store(true, std::memory_order_release);
    cancelActiveLoadSession();
    wakeMonitor();

    // 1. Cancel all I/O data sources and wake NativeTrafficController waiters FIRST so any blocking
    // open()/readAt()/Widevine/libcurl transfers return in <1ms without stalling thread joins.
    cancelAllActiveSources();
    spotify::network::NativeTrafficController::instance().notifyAllWaiters();

    if (mSecondaryWorkerThread.joinable()) {
        mSecondaryWorkerThread.join();
    }

    // Pause and flush the Oboe stream rather than destroying the hardware audio sink on every
    // track transition. The warm stream is reused immediately when the next track matches sample rate.
    std::shared_ptr<oboe::AudioStream> streamSnapshot;
    {
        std::lock_guard<std::mutex> lock(mStreamMutex);
        streamSnapshot = mStream;
    }
    if (streamSnapshot) {
        const auto st = streamSnapshot->getState();
        if (st != oboe::StreamState::Closed && st != oboe::StreamState::Disconnected) {
            streamSnapshot->requestPause();
            streamSnapshot->requestFlush();
        }
    }

    if (mDecoder) {
        mDecoder->stop();
        mDecoder.reset();
    }

    if (mPrimaryDecoder) {
        mPrimaryDecoder->stop();
        mPrimaryDecoder.reset();
    }

    if (mSecondaryDecoder) {
        mSecondaryDecoder->stop();
        mSecondaryDecoder.reset();
    }

    joinMonitorThread();
    {
        std::lock_guard<std::mutex> lock(mEosMutex);
        mEosPending = false;
    }

    std::unique_ptr<IAudioDataSource> dataSrc;
    std::unique_ptr<IAudioDataSource> primarySrc;
    std::unique_ptr<HttpMediaDataSource> secondarySrc;
    {
        std::lock_guard<std::mutex> lock(mSourceCancelMutex);
        dataSrc = std::move(mDataSource);
        primarySrc = std::move(mPrimarySource);
        secondarySrc = std::move(mSecondarySource);
    }

    if (dataSrc) dataSrc->close();
    if (primarySrc) primarySrc->close();
    if (secondarySrc) secondarySrc->close();

    if (mSecondaryCrypto) {
        AMediaCrypto_delete(mSecondaryCrypto);
        mSecondaryCrypto = nullptr;
    }
    // Keep the underlying Widevine AMediaDrm session active in WidevineLicenseClient's LRU cache
    // so replaying or switching between cached tracks incurs 0 license network calls.

    mRingBuffer.reset();

    mFramesConsumedByHardware.store(0, std::memory_order_release);
    mSeekPositionMs.store(0, std::memory_order_release);
    mDurationMs.store(0, std::memory_order_release);
    mDecoderStreamState.store(DecoderStreamState::Decoding, std::memory_order_release);
    mSourceTopology.store(SourceTopology::SingleStream, std::memory_order_release);
    mSecondaryPhase.store(SecondaryStreamPhase::Inactive, std::memory_order_release);
    mHandoffTargetMs.store(-1, std::memory_order_release);
    mHandoffActualMs.store(0, std::memory_order_release);
    mPrimaryDurationMs.store(0, std::memory_order_release);
    mPendingSeekOverrideMs.store(-1, std::memory_order_release);
    mPrimaryHeadState.store(PrimaryHeadState::Released, std::memory_order_release);
    mDurationAuthority.store(DurationAuthority::Estimated, std::memory_order_release);
    mEosNotificationState.store(EosNotificationState::Pending, std::memory_order_relaxed);
}

// ===========================================================================
// Control: loadLocal
// ===========================================================================

EngineStatus AudioEngine::loadLocal(const char* filePath,
                                    std::vector<std::string> fallbackUrls,
                                    spotify::network::UrlRefreshCallback urlRefreshCb) {
    if (!filePath || filePath[0] == '\0') {
        return EngineStatus::ErrorInvalidArg;
    }

    stopPlayback();
    mEncryptionMode = SourceEncryptionMode::Cleartext;
    mSourceTopology.store(SourceTopology::SingleStream, std::memory_order_release);

    std::unique_ptr<IAudioDataSource> source;
    if (std::strncmp(filePath, "http://", 7) == 0 || std::strncmp(filePath, "https://", 8) == 0) {
        std::vector<std::string> urls;
        urls.reserve(1 + fallbackUrls.size());
        urls.emplace_back(filePath);
        for (auto& u : fallbackUrls) {
            if (!u.empty() && u != urls.front()) {
                urls.push_back(std::move(u));
            }
        }
        source = std::make_unique<HttpMediaDataSource>(
            std::move(urls), nullptr, std::move(urlRefreshCb));
    } else {
        source = std::make_unique<LocalFileDataSource>(filePath);
    }
    return loadSource(std::move(source));
}

// ===========================================================================
// Control: loadTrackWithHead
// ===========================================================================

EngineStatus AudioEngine::loadTrackWithHead(const char* fileIdHex,
                                            const char* fullTrackUrl,
                                            const char* cacheDir,
                                            const char* licenseServerUrl,
                                            const char* authHeader,
                                            int64_t trackDurationMs) {
    if (!fileIdHex || fileIdHex[0] == '\0') {
        return EngineStatus::ErrorInvalidArg;
    }

    stopPlayback();
    mEncryptionMode = SourceEncryptionMode::Cleartext;
    mSourceTopology.store(SourceTopology::SingleStream, std::memory_order_release);
    mSecondaryPhase.store(SecondaryStreamPhase::Attaching, std::memory_order_release);
    mHandoffTargetMs.store(-1, std::memory_order_release);
    mHandoffActualMs.store(0, std::memory_order_release);

    std::string headPath;
    if (cacheDir && cacheDir[0] != '\0') {
        headPath = std::string(cacheDir) + "/heads/" + std::string(fileIdHex) + ".ogg";
    } else {
        headPath = std::string("/data/data/um.musify.mu.musify_mu/cache/heads/") + std::string(fileIdHex) + ".ogg";
    }

    std::string partPath = headPath + ".part";

    // 1. Check if complete cached head file exists (size >= 512 bytes)
    struct stat st{};
    const bool isCached = (::stat(headPath.c_str(), &st) == 0 && st.st_size >= 512);

    std::unique_ptr<IAudioDataSource> primarySource;

    if (isCached) {
        LOGI("Head file cache HIT for %s (%s, size=%lld)", fileIdHex, headPath.c_str(), (long long)st.st_size);
        primarySource = std::make_unique<LocalFileDataSource>(headPath.c_str());
    } else {
        LOGI("Head file cache MISS for %s - initiating progressive stream to %s", fileIdHex, partPath.c_str());
        const bool streamStarted = downloadHeadFileNative(fileIdHex, headPath.c_str());
        if (!streamStarted) {
            LOGE("Native head file streaming failed for %s", fileIdHex);
            if (fullTrackUrl && fullTrackUrl[0] != '\0') {
                LOGI("Falling back to full track stream: %s", fullTrackUrl);
                if (licenseServerUrl && licenseServerUrl[0] != '\0') {
                    return loadEncryptedStream(fullTrackUrl, licenseServerUrl, authHeader);
                }
                return loadLocal(fullTrackUrl);
            }
            return EngineStatus::ErrorIO;
        }

        if (::stat(headPath.c_str(), &st) == 0 && st.st_size >= 512) {
            primarySource = std::make_unique<LocalFileDataSource>(headPath.c_str());
        } else {
            primarySource = std::make_unique<ProgressiveFileDataSource>(partPath.c_str());
        }
    }

    LOGI("Head chunk ready. Loading primary decoder (full stream: %s)", (fullTrackUrl && fullTrackUrl[0] != '\0') ? fullTrackUrl : "none");
    EngineStatus status = loadDualSource(
        std::move(primarySource),
        fullTrackUrl,
        licenseServerUrl,
        authHeader,
        -1,
        trackDurationMs);
    if (status == EngineStatus::Ok) {
        if (!fullTrackUrl || fullTrackUrl[0] == '\0') {
            mSecondaryPhase.store(SecondaryStreamPhase::Attaching, std::memory_order_release);
        }
        mDecoderStreamState.store(DecoderStreamState::Decoding, std::memory_order_release);
    }
    return status;
}

void AudioEngine::prefetchHead(const char* fileIdHex, const char* cacheDir) {
    if (!fileIdHex || fileIdHex[0] == '\0') return;
    std::string fid(fileIdHex);
    std::string dir(cacheDir ? cacheDir : "");
    std::thread([fid, dir]() {
        std::string headPath = (!dir.empty() ? dir : "/data/data/um.musify.mu.musify_mu/cache") + "/heads/" + fid + ".ogg";
        LOGI("Prefetch: start prefetching head file for track %s : %s", fid.c_str(), headPath.c_str());
        downloadHeadFileNative(fid.c_str(), headPath.c_str());
    }).detach();
}

bool AudioEngine::downloadHeadFileNative(const char* fileIdHex, const char* targetFilePath) {
    if (!fileIdHex || fileIdHex[0] == '\0' || !targetFilePath || targetFilePath[0] == '\0') {
        return false;
    }

    return spotify::content_delivery::HeadFileManager::streamHeadFile(
        spotify::network::NativeHttpClient::defaultInstance(),
        fileIdHex,
        targetFilePath);
}

// ===========================================================================
// Control: loadDualSource
// ===========================================================================

EngineStatus AudioEngine::loadDualSource(const char* primaryPath,
                                        const char* secondaryUrl,
                                        const char* licenseServerUrl,
                                        const char* authHeader,
                                        int64_t handoffPositionMs,
                                        int64_t trackDurationMs) {
    if (!primaryPath || primaryPath[0] == '\0') {
        return EngineStatus::ErrorInvalidArg;
    }

    std::unique_ptr<IAudioDataSource> primarySource;
    if (std::strncmp(primaryPath, "http://", 7) == 0 || std::strncmp(primaryPath, "https://", 8) == 0) {
        primarySource = std::make_unique<HttpMediaDataSource>(primaryPath);
    } else {
        primarySource = std::make_unique<LocalFileDataSource>(primaryPath);
    }

    return loadDualSource(
        std::move(primarySource),
        secondaryUrl,
        licenseServerUrl,
        authHeader,
        handoffPositionMs,
        trackDurationMs);
}

EngineStatus AudioEngine::loadDualSource(std::unique_ptr<IAudioDataSource> primarySource,
                                        const char* secondaryUrl,
                                        const char* licenseServerUrl,
                                        const char* authHeader,
                                        int64_t handoffPositionMs,
                                        int64_t trackDurationMs) {
    if (!primarySource) {
        return EngineStatus::ErrorInvalidArg;
    }

    stopPlayback();
    auto sessionToken = beginNewLoadSession();

    mEncryptionMode = SourceEncryptionMode::Cleartext;
    mSourceTopology.store(SourceTopology::DualHeadAndCdn, std::memory_order_release);
    if (secondaryUrl && secondaryUrl[0] != '\0') {
        mSecondaryPhase.store(SecondaryStreamPhase::Attaching, std::memory_order_release);
    } else {
        mSecondaryPhase.store(SecondaryStreamPhase::Inactive, std::memory_order_release);
    }
    mHandoffTargetMs.store(handoffPositionMs, std::memory_order_release);

    mState.store(EngineState::Loading, std::memory_order_release);

    sessionToken->bindOpeningSource(primarySource.get());
    EngineStatus status = primarySource->open();
    sessionToken->bindOpeningSource(nullptr);

    if (sessionToken->isCancelled()) {
        primarySource->close();
        mState.store(EngineState::Idle, std::memory_order_release);
        return EngineStatus::ErrorIO;
    }
    if (status != EngineStatus::Ok) {
        LOGE("Primary source open failed: %d", static_cast<int>(status));
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    mSampleRate = primarySource->getSampleRate();
    mSourceChannelCount = primarySource->getChannelCount();
    const int64_t primaryHeadDurMs = std::max<int64_t>(0, primarySource->getDurationUs() / 1000);
    mPrimaryDurationMs.store(primaryHeadDurMs, std::memory_order_release);
    mPendingSeekOverrideMs.store(-1, std::memory_order_release);
    mPrimaryHeadState.store(PrimaryHeadState::Active, std::memory_order_release);
    mDurationMs.store(trackDurationMs > 0 ? trackDurationMs : 0, std::memory_order_release);
    mDurationAuthority.store(DurationAuthority::Estimated, std::memory_order_release);

    int64_t maxFramesToDecode = -1;
    if (handoffPositionMs > 0 && mSampleRate > 0) {
        maxFramesToDecode = (handoffPositionMs * mSampleRate) / 1000;
    }

    LOGI("Primary source opened: sr=%d cc=%d headDurMs=%lld handoffTargetMs=%lld maxFrames=%lld",
         mSampleRate, mSourceChannelCount, static_cast<long long>(primarySource->getDurationUs() / 1000),
         static_cast<long long>(handoffPositionMs), static_cast<long long>(maxFramesToDecode));

    // 2. Configure Primary Decoder with event-driven monitor wakeup callback
    auto primaryDecoder = std::make_unique<NativeDecoder>(
        mRingBuffer,
        primarySource->getExtractor(),
        primarySource->getMimeType(),
        primarySource->getTrackFormat(),
        mSourceChannelCount,
        nullptr,
        maxFramesToDecode,
        0,
        [this]() { wakeMonitor(); });

    status = primaryDecoder->configure();
    if (status != EngineStatus::Ok) {
        LOGE("Primary decoder configure failed: %d", static_cast<int>(status));
        primarySource->close();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    {
        std::lock_guard<std::mutex> lock(mSourceCancelMutex);
        mPrimarySource = std::move(primarySource);
    }
    mPrimaryDecoder = std::move(primaryDecoder);

    // 3. Open or reuse warm Oboe Stream
    status = openOboeStream();
    if (status != EngineStatus::Ok) {
        LOGE("Oboe stream open failed: %d", static_cast<int>(status));
        mPrimaryDecoder->stop();
        mPrimaryDecoder.reset();
        std::unique_ptr<IAudioDataSource> primaryToClose;
        {
            std::lock_guard<std::mutex> lock(mSourceCancelMutex);
            primaryToClose = std::move(mPrimarySource);
        }
        if (primaryToClose) primaryToClose->close();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    // Reset telemetry
    mRingBuffer.reset();
    mFramesConsumedByHardware.store(0, std::memory_order_relaxed);
    mSeekPositionMs.store(0, std::memory_order_relaxed);
    mUnderrunCount.store(0, std::memory_order_relaxed);
    mDecoderStreamState.store(DecoderStreamState::Decoding, std::memory_order_relaxed);

    mState.store(EngineState::Prebuffering, std::memory_order_release);

    // 4. Start primary decoder immediately for ultra-low TTFA
    status = mPrimaryDecoder->start();
    if (status != EngineStatus::Ok) {
        LOGE("Primary decoder start failed: %d", static_cast<int>(status));
        closeOboeStream();
        mPrimaryDecoder.reset();
        std::unique_ptr<IAudioDataSource> primaryToClose;
        {
            std::lock_guard<std::mutex> lock(mSourceCancelMutex);
            primaryToClose = std::move(mPrimarySource);
        }
        if (primaryToClose) primaryToClose->close();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    // 5. Start background worker for Secondary (AAC DRM CDN stream) if provided
    if (secondaryUrl && secondaryUrl[0] != '\0') {
        if (mSecondaryWorkerThread.joinable()) {
            cancelActiveLoadSession();
            wakeMonitor();
            mSecondaryWorkerThread.join();
            sessionToken = beginNewLoadSession();
        }
        mSecondaryWorkerThread = std::thread(
            &AudioEngine::secondaryWorkerFunc,
            this,
            sessionToken,
            std::vector<std::string>{std::string(secondaryUrl)},
            licenseServerUrl ? std::string(licenseServerUrl) : std::string(),
            authHeader ? std::string(authHeader) : std::string(),
            handoffPositionMs,
            nullptr
        );
    }

    // 6. Start monitor thread
    joinMonitorThread();
    mMonitorShouldStop.store(false, std::memory_order_release);
    mMonitorThread = std::thread(&AudioEngine::decoderMonitorFunc, this);

    return EngineStatus::Ok;
}

// ===========================================================================
// Control: loadEncryptedStream (direct single-stream encrypted playback)
// ===========================================================================

EngineStatus AudioEngine::loadEncryptedStream(const char* url,
                                             const char* licenseServerUrl,
                                             const char* authHeader,
                                             std::vector<std::string> fallbackUrls,
                                             spotify::network::UrlRefreshCallback urlRefreshCb) {
    if (!url || url[0] == '\0') {
        return EngineStatus::ErrorInvalidArg;
    }

    stopPlayback();
    const auto sessionToken = beginNewLoadSession();
    const auto cancelPred = sessionToken->asCancelPredicate();

    mEncryptionMode = SourceEncryptionMode::Encrypted;
    mSourceTopology.store(SourceTopology::SingleStream, std::memory_order_release);
    mSecondaryPhase.store(SecondaryStreamPhase::Inactive, std::memory_order_release);
    mHandoffTargetMs.store(-1, std::memory_order_release);
    mHandoffActualMs.store(0, std::memory_order_release);

    mState.store(EngineState::Loading, std::memory_order_release);

    const std::string primaryUrlStr(url);
    const std::string licenseUrlStr = licenseServerUrl ? std::string(licenseServerUrl) : std::string();
    const std::string authHeaderStr = authHeader ? std::string(authHeader) : std::string();

    // Launch Widevine license acquisition concurrently with MP4 header fetch when URL carries a 40-hex fileId.
    std::future<AMediaCrypto*> parallelCryptoFuture;
    {
        std::vector<uint8_t> derivedPssh;
        if (HttpMediaDataSource::deriveWidevinePsshFromUrl(primaryUrlStr.c_str(), derivedPssh, 0x63626373) &&
            !derivedPssh.empty()) {
            parallelCryptoFuture = std::async(
                std::launch::async,
                [this, derivedPssh = std::move(derivedPssh), licenseUrlStr, authHeaderStr, cancelPred]() {
                    return acquireWidevineCrypto(derivedPssh, licenseUrlStr, authHeaderStr, cancelPred);
                });
        }
    }

    std::unique_ptr<IAudioDataSource> source;
    if (std::strncmp(url, "http://", 7) == 0 || std::strncmp(url, "https://", 8) == 0) {
        std::vector<std::string> urls;
        urls.reserve(1 + fallbackUrls.size());
        urls.emplace_back(url);
        for (auto& u : fallbackUrls) {
            if (!u.empty() && u != urls.front()) {
                urls.push_back(std::move(u));
            }
        }
        source = std::make_unique<HttpMediaDataSource>(
            std::move(urls), authHeader, std::move(urlRefreshCb));
    } else {
        source = std::make_unique<LocalFileDataSource>(url);
    }

    sessionToken->bindOpeningSource(source.get());
    EngineStatus status = source->open();
    sessionToken->bindOpeningSource(nullptr);

    if (sessionToken->isCancelled()) {
        if (parallelCryptoFuture.valid()) {
            if (AMediaCrypto* unusedCrypto = parallelCryptoFuture.get()) {
                AMediaCrypto_delete(unusedCrypto);
            }
        }
        source->close();
        mState.store(EngineState::Idle, std::memory_order_release);
        return EngineStatus::ErrorIO;
    }

    if (status != EngineStatus::Ok) {
        if (parallelCryptoFuture.valid()) {
            if (AMediaCrypto* unusedCrypto = parallelCryptoFuture.get()) {
                AMediaCrypto_delete(unusedCrypto);
            }
        }
        LOGE("Encrypted stream data source open failed: %d", static_cast<int>(status));
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    mSampleRate = source->getSampleRate();
    mSourceChannelCount = source->getChannelCount();
    const int64_t durMs = source->getDurationUs() / 1000;
    mDurationMs.store(durMs, std::memory_order_release);
    mDurationAuthority.store(
        durMs > 0 ? DurationAuthority::ContainerVerified : DurationAuthority::Estimated,
        std::memory_order_release);

    if (mSampleRate <= 0 || mSourceChannelCount <= 0) {
        if (parallelCryptoFuture.valid()) {
            if (AMediaCrypto* unusedCrypto = parallelCryptoFuture.get()) {
                AMediaCrypto_delete(unusedCrypto);
            }
        }
        LOGE("Invalid format for encrypted stream: sr=%d cc=%d", mSampleRate, mSourceChannelCount);
        source->close();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return EngineStatus::ErrorCodec;
    }

    LOGI("Encrypted source opened: sr=%d cc=%d dur=%lldms mime=%s",
         mSampleRate, mSourceChannelCount, static_cast<long long>(durMs), source->getMimeType());
    notifyStateChanged(mState.load(std::memory_order_acquire));

    AMediaCrypto* crypto = nullptr;
    if (parallelCryptoFuture.valid()) {
        crypto = parallelCryptoFuture.get();
    }

    if (sessionToken->isCancelled()) {
        if (crypto) {
            AMediaCrypto_delete(crypto);
        }
        source->close();
        mState.store(EngineState::Idle, std::memory_order_release);
        return EngineStatus::ErrorIO;
    }

    if (!crypto && (source->hasWidevinePssh() || !licenseUrlStr.empty())) {
        LOGI("Encrypted stream requires Widevine DRM key exchange (licenseUrl=%s)",
             licenseServerUrl ? licenseServerUrl : "null");
        std::vector<uint8_t> psshData = source->getPsshBytes();
        if (psshData.empty()) {
            uint32_t protectionScheme = 0x63626373;
            int32_t cryptoMode = 0;
            if (source->getTrackFormat() &&
                AMediaFormat_getInt32(source->getTrackFormat(), "crypto-mode", &cryptoMode)) {
                if (cryptoMode == 1) protectionScheme = 0x63656e63;
                else if (cryptoMode == 2) protectionScheme = 0x63626373;
            }
            (void)HttpMediaDataSource::deriveWidevinePsshFromUrl(primaryUrlStr.c_str(), psshData, protectionScheme);
        }

        crypto = acquireWidevineCrypto(psshData, licenseUrlStr, authHeaderStr, cancelPred);
    }

    if (sessionToken->isCancelled()) {
        if (crypto) {
            AMediaCrypto_delete(crypto);
        }
        source->close();
        mState.store(EngineState::Idle, std::memory_order_release);
        return EngineStatus::ErrorIO;
    }

    if (source->hasWidevinePssh() || !licenseUrlStr.empty()) {
        if (!crypto) {
            LOGE("Failed to acquire Widevine crypto session for encrypted stream");
            source->close();
            mState.store(EngineState::Faulted, std::memory_order_release);
            return EngineStatus::ErrorCodec;
        }
        mSecondaryCrypto = crypto;
    }

    auto decoder = std::make_unique<NativeDecoder>(
        mRingBuffer,
        source->getExtractor(),
        source->getMimeType(),
        source->getTrackFormat(),
        mSourceChannelCount,
        crypto,
        -1,
        0,
        [this]() { wakeMonitor(); });

    status = decoder->configure();
    if (status != EngineStatus::Ok) {
        LOGE("Encrypted stream decoder configure failed: %d", static_cast<int>(status));
        source->close();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    {
        std::lock_guard<std::mutex> lock(mSourceCancelMutex);
        mDataSource = std::move(source);
    }
    mDecoder = std::move(decoder);

    status = openOboeStream();
    if (status != EngineStatus::Ok) {
        LOGE("Encrypted stream Oboe stream open failed: %d", static_cast<int>(status));
        mDecoder->stop();
        mDecoder.reset();
        std::unique_ptr<IAudioDataSource> dataToClose;
        {
            std::lock_guard<std::mutex> lock(mSourceCancelMutex);
            dataToClose = std::move(mDataSource);
        }
        if (dataToClose) dataToClose->close();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    mRingBuffer.reset();
    mFramesConsumedByHardware.store(0, std::memory_order_relaxed);
    mSeekPositionMs.store(0, std::memory_order_relaxed);
    mUnderrunCount.store(0, std::memory_order_relaxed);
    mDecoderStreamState.store(DecoderStreamState::Decoding, std::memory_order_relaxed);

    mState.store(EngineState::Prebuffering, std::memory_order_release);

    status = mDecoder->start();
    if (status != EngineStatus::Ok) {
        LOGE("Encrypted stream decoder start failed: %d", static_cast<int>(status));
        closeOboeStream();
        mDecoder.reset();
        std::unique_ptr<IAudioDataSource> dataToClose;
        {
            std::lock_guard<std::mutex> lock(mSourceCancelMutex);
            dataToClose = std::move(mDataSource);
        }
        if (dataToClose) dataToClose->close();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    joinMonitorThread();
    mMonitorShouldStop.store(false, std::memory_order_release);
    mMonitorThread = std::thread(&AudioEngine::decoderMonitorFunc, this);

    LOGI("Encrypted stream started successfully: mime=%s dur=%lldms",
         mDataSource->getMimeType(), static_cast<long long>(mDurationMs.load(std::memory_order_acquire)));
    return EngineStatus::Ok;
}

EngineStatus AudioEngine::attachSecondaryStream(const char* secondaryUrl,
                                                const char* licenseServerUrl,
                                                const char* authHeader,
                                                int64_t handoffPositionMs,
                                                std::vector<std::string> fallbackUrls,
                                                spotify::network::UrlRefreshCallback urlRefreshCb) {
    if (!secondaryUrl || secondaryUrl[0] == '\0') {
        return EngineStatus::ErrorInvalidArg;
    }

    if (mSourceTopology.load(std::memory_order_acquire) != SourceTopology::DualHeadAndCdn) {
        LOGW("attachSecondaryStream: not in dual source mode");
        return EngineStatus::ErrorInvalidState;
    }

    if (mSecondaryPhase.load(std::memory_order_acquire) == SecondaryStreamPhase::HandedOff) {
        LOGW("attachSecondaryStream: handoff already completed");
        return EngineStatus::ErrorInvalidState;
    }

    std::vector<std::string> urls;
    urls.reserve(1 + fallbackUrls.size());
    urls.emplace_back(secondaryUrl);
    for (auto& u : fallbackUrls) {
        if (!u.empty() && u != urls.front()) {
            urls.push_back(std::move(u));
        }
    }

    LOGI("Attaching secondary stream (%zu CDN URLs): %s", urls.size(), secondaryUrl);
    if (mSecondaryWorkerThread.joinable()) {
        cancelActiveLoadSession();
        wakeMonitor();
        cancelAllActiveSources();
        mSecondaryWorkerThread.join();
    }

    const auto sessionToken = beginNewLoadSession();
    mSecondaryPhase.store(SecondaryStreamPhase::Attaching, std::memory_order_release);
    mDecoderStreamState.store(DecoderStreamState::Decoding, std::memory_order_release);

    mSecondaryWorkerThread = std::thread(
        &AudioEngine::secondaryWorkerFunc,
        this,
        sessionToken,
        std::move(urls),
        licenseServerUrl ? std::string(licenseServerUrl) : std::string(),
        authHeader ? std::string(authHeader) : std::string(),
        handoffPositionMs,
        std::move(urlRefreshCb)
    );

    if (!mMonitorThread.joinable()) {
        mMonitorShouldStop.store(false, std::memory_order_release);
        mMonitorThread = std::thread(&AudioEngine::decoderMonitorFunc, this);
    }

    return EngineStatus::Ok;
}

// ===========================================================================
// Background Secondary Loader & DRM Negotiator
// ===========================================================================

void AudioEngine::secondaryWorkerFunc(std::shared_ptr<LoadSessionToken> sessionToken,
                                      std::vector<std::string> secondaryUrls,
                                      std::string licenseServerUrl,
                                      std::string authHeader,
                                      int64_t handoffMs,
                                      spotify::network::UrlRefreshCallback urlRefreshCb) {
    if (secondaryUrls.empty()) {
        failSecondary(sessionToken, "Secondary URL list is empty");
        return;
    }
    const std::string secondaryUrl = secondaryUrls.front();
    LOGI("Secondary worker started for URL: %s", secondaryUrl.c_str());

    const auto cancelPred = sessionToken->asCancelPredicate();

    // Launch Widevine license exchange in parallel with MP4 header download when PSSH is derivable from URL.
    std::future<AMediaCrypto*> parallelCryptoFuture;
    if (!licenseServerUrl.empty() || !authHeader.empty()) {
        std::vector<uint8_t> derivedPssh;
        if (HttpMediaDataSource::deriveWidevinePsshFromUrl(secondaryUrl.c_str(), derivedPssh, 0x63626373) &&
            !derivedPssh.empty()) {
            parallelCryptoFuture = std::async(
                std::launch::async,
                [this, derivedPssh = std::move(derivedPssh), licenseServerUrl, authHeader, cancelPred]() {
                    return acquireWidevineCrypto(derivedPssh, licenseServerUrl, authHeader, cancelPred);
                });
        }
    }

    auto secSource = std::make_unique<HttpMediaDataSource>(
        std::move(secondaryUrls), authHeader.c_str(), std::move(urlRefreshCb));

    sessionToken->bindOpeningSource(secSource.get());
    EngineStatus status = secSource->open();
    sessionToken->bindOpeningSource(nullptr);

    AMediaCrypto* crypto = nullptr;
    if (parallelCryptoFuture.valid()) {
        crypto = parallelCryptoFuture.get();
    }

    if (sessionToken->isCancelled()) {
        if (crypto) {
            AMediaCrypto_delete(crypto);
        }
        secSource->close();
        mSecondaryPhase.store(SecondaryStreamPhase::Inactive, std::memory_order_release);
        return;
    }
    if (status != EngineStatus::Ok) {
        if (crypto) {
            AMediaCrypto_delete(crypto);
        }
        failSecondary(sessionToken, "Secondary remote source open failed: " + std::to_string(static_cast<int>(status)));
        secSource->close();
        return;
    }

    // Update authoritative container duration (both up and down vs metadata hint).
    const int64_t secDurUs = secSource->getDurationUs();
    if (secDurUs > 0) {
        const int64_t secDurMs = secDurUs / 1000;
        mDurationMs.store(secDurMs, std::memory_order_release);
        mDurationAuthority.store(DurationAuthority::ContainerVerified, std::memory_order_release);
        LOGI("Authoritative container duration from secondary MP4: %lld ms",
             static_cast<long long>(secDurMs));
        notifyStateChanged(mState.load(std::memory_order_acquire));
    }

    if (!crypto && (secSource->hasWidevinePssh() || !licenseServerUrl.empty())) {
        LOGI("Secondary source requires Widevine DRM key exchange (licenseUrl=%s)", licenseServerUrl.c_str());
        std::vector<uint8_t> psshData = secSource->getPsshBytes();
        if (psshData.empty()) {
            uint32_t protectionScheme = 0x63626373;
            int32_t cryptoMode = 0;
            if (secSource->getTrackFormat() &&
                AMediaFormat_getInt32(secSource->getTrackFormat(), "crypto-mode", &cryptoMode)) {
                if (cryptoMode == 1) {
                    protectionScheme = 0x63656e63;
                } else if (cryptoMode == 2) {
                    protectionScheme = 0x63626373;
                }
            }
            (void)HttpMediaDataSource::deriveWidevinePsshFromUrl(secondaryUrl.c_str(), psshData, protectionScheme);
        }

        crypto = acquireWidevineCrypto(psshData, licenseServerUrl, authHeader, cancelPred);
    }

    if (secSource->hasWidevinePssh() || !licenseServerUrl.empty()) {
        if (!crypto) {
            failSecondary(sessionToken, "Widevine license acquisition failed (see MusifyWidevineClient logs)");
            secSource->close();
            return;
        }
        mSecondaryCrypto = crypto;
        LOGI("Widevine crypto successfully acquired and attached to secondary decoder: %p", crypto);
    }

    if (sessionToken->isCancelled()) {
        secSource->close();
        mSecondaryPhase.store(SecondaryStreamPhase::Inactive, std::memory_order_release);
        return;
    }

    if (secSource->getSampleRate() != mSampleRate) {
        failSecondary(sessionToken,
                      "Secondary sample rate " + std::to_string(secSource->getSampleRate()) +
                      " differs from primary " + std::to_string(mSampleRate) +
                      "; ring buffer has no resampler");
        secSource->close();
        return;
    }

    const int64_t seekOverride = mPendingSeekOverrideMs.load(std::memory_order_acquire);
    int64_t handoffUs = handoffMs * 1000LL;
    if (seekOverride >= 0 ||
        mPrimaryHeadState.load(std::memory_order_acquire) == PrimaryHeadState::SuspendedForOutOfRangeSeek) {
        const int64_t latestOverride = mPendingSeekOverrideMs.load(std::memory_order_acquire);
        handoffUs = (latestOverride >= 0 ? latestOverride : 0) * 1000LL;
    } else if (handoffMs <= 0 && mPrimaryDecoder) {
        while (!mPrimaryDecoder->isEndOfStream() &&
               mPrimaryHeadState.load(std::memory_order_acquire) == PrimaryHeadState::Active &&
               mPendingSeekOverrideMs.load(std::memory_order_acquire) < 0) {
            if (sessionToken->isCancelled()) {
                secSource->close();
                mSecondaryPhase.store(SecondaryStreamPhase::Inactive, std::memory_order_release);
                return;
            }
            std::unique_lock<std::mutex> lock(mMonitorMutex);
            mMonitorCv.wait_for(lock, std::chrono::milliseconds(2));
        }
        const int64_t overrideAfterWait =
            mPendingSeekOverrideMs.load(std::memory_order_acquire);
        if (overrideAfterWait >= 0) {
            handoffUs = overrideAfterWait * 1000LL;
        } else if (mPrimaryDecoder) {
            handoffUs = (mPrimaryDecoder->getDecodedFrames() * 1000000LL) / mSampleRate;
        }
    }
    const int64_t consumedOverride = mPendingSeekOverrideMs.exchange(-1, std::memory_order_acq_rel);
    if (consumedOverride >= 0) {
        handoffUs = consumedOverride * 1000LL;
    }
    int64_t targetSeekMs = handoffUs / 1000LL;

    const int64_t secOriginUs = AMediaExtractor_getSampleTime(secSource->getExtractor());
    const int64_t adjustedHandoffUs =
        (handoffUs > 0 && secOriginUs > 0 && secOriginUs < 1000000LL)
            ? (handoffUs + secOriginUs)
            : handoffUs;

    if (adjustedHandoffUs > 0) {
        media_status_t seekStatus = AMediaExtractor_seekTo(
            secSource->getExtractor(), adjustedHandoffUs, AMEDIAEXTRACTOR_SEEK_PREVIOUS_SYNC);
        int64_t actualPtsUs = AMediaExtractor_getSampleTime(secSource->getExtractor());
        LOGI("Secondary extractor pre-seeked: target=%lld us (origin=%lld us), actualPts=%lld us (status=%d)",
             static_cast<long long>(adjustedHandoffUs),
             static_cast<long long>(secOriginUs),
             static_cast<long long>(actualPtsUs),
             static_cast<int>(seekStatus));
    }

    auto secDecoder = std::make_unique<NativeDecoder>(
        mRingBuffer,
        secSource->getExtractor(),
        secSource->getMimeType(),
        secSource->getTrackFormat(),
        secSource->getChannelCount(),
        mSecondaryCrypto,
        -1,
        adjustedHandoffUs,
        [this]() { wakeMonitor(); }
    );

    status = secDecoder->configure();
    if (status != EngineStatus::Ok) {
        failSecondary(sessionToken, "Secondary decoder configure failed: " + std::to_string(static_cast<int>(status)));
        secSource->close();
        return;
    }

    EngineStatus startStatus = secDecoder->start();
    if (startStatus != EngineStatus::Ok) {
        failSecondary(sessionToken, "Secondary decoder failed to start: " + std::to_string(static_cast<int>(startStatus)));
        secSource->close();
        return;
    }

    // If a seek arrived while secDecoder was configuring/starting, dispatch it directly to secDecoder.
    const int64_t lateOverride = mPendingSeekOverrideMs.exchange(-1, std::memory_order_acq_rel);
    if (lateOverride >= 0) {
        targetSeekMs = lateOverride;
        secDecoder->requestSeek(lateOverride * 1000LL);
    }

    mHandoffActualMs.store(targetSeekMs, std::memory_order_release);
    {
        std::lock_guard<std::mutex> lock(mSourceCancelMutex);
        mSecondarySource = std::move(secSource);
    }
    mSecondaryDecoder = std::move(secDecoder);
    mSecondaryPhase.store(SecondaryStreamPhase::HandedOff, std::memory_order_release);
    mDecoderStreamState.store(DecoderStreamState::Decoding, std::memory_order_release);
    wakeMonitor();
    LOGI("Seamless dual-source handoff initiated: secondary decoder actively buffering ahead at %lld ms",
         static_cast<long long>(targetSeekMs));
}

AMediaCrypto* AudioEngine::acquireWidevineCrypto(
    const std::vector<uint8_t>& psshData,
    const std::string& licenseServerUrl,
    const std::string& authHeader,
    const spotify::network::CancelPredicate& cancelPred) {
    if (psshData.empty()) {
        LOGE("Cannot acquire Widevine crypto: empty PSSH data");
        return nullptr;
    }

    const std::vector<uint8_t> sessionId =
        spotify::drm::WidevineLicenseClient::defaultInstance().acquireStreamingSession(
            psshData,
            licenseServerUrl,
            authHeader,
            3,
            cancelPred);
    if (sessionId.empty()) {
        LOGE("WidevineLicenseClient::acquireStreamingSession returned empty sessionId");
        return nullptr;
    }

    mActiveDrmSessionId = sessionId;
    AMediaCrypto* crypto = AMediaCrypto_new(
        kWidevineUuid,
        reinterpret_cast<const void*>(sessionId.data()),
        sessionId.size());
    if (!crypto) {
        LOGE("AMediaCrypto_new failed for Widevine session (%zu bytes)", sessionId.size());
        return nullptr;
    }

    LOGI("AMediaCrypto_new created native crypto instance: %p", crypto);
    return crypto;
}

void AudioEngine::closeActiveDrmSession() {
    if (mActiveDrmSessionId.empty()) {
        return;
    }
    spotify::drm::WidevineLicenseClient::defaultInstance().closeSession(mActiveDrmSessionId);
    mActiveDrmSessionId.clear();
}

EngineStatus AudioEngine::setDrmSessionId(const uint8_t* sessionId, int32_t sessionLen) {
    if (!sessionId || sessionLen <= 0) {
        return EngineStatus::ErrorInvalidArg;
    }

    if (mSecondaryCrypto) {
        AMediaCrypto_delete(mSecondaryCrypto);
        mSecondaryCrypto = nullptr;
    }

    mSecondaryCrypto = AMediaCrypto_new(kWidevineUuid, sessionId, static_cast<size_t>(sessionLen));
    if (!mSecondaryCrypto) {
        LOGE("AMediaCrypto_new failed in setDrmSessionId");
        return EngineStatus::ErrorCodec;
    }

    LOGI("AMediaCrypto manually initialized via setDrmSessionId: %p", mSecondaryCrypto);
    return EngineStatus::Ok;
}

// ===========================================================================
// Control: loadSource (single source legacy path)
// ===========================================================================

EngineStatus AudioEngine::loadSource(std::unique_ptr<IAudioDataSource> source) {
    if (!source) {
        return EngineStatus::ErrorInvalidArg;
    }

    stopPlayback();
    const auto sessionToken = beginNewLoadSession();

    mEncryptionMode = SourceEncryptionMode::Cleartext;
    mSourceTopology.store(SourceTopology::SingleStream, std::memory_order_release);
    mSecondaryPhase.store(SecondaryStreamPhase::Inactive, std::memory_order_release);
    mHandoffTargetMs.store(-1, std::memory_order_release);
    mHandoffActualMs.store(0, std::memory_order_release);

    mState.store(EngineState::Loading, std::memory_order_release);

    sessionToken->bindOpeningSource(source.get());
    EngineStatus status = source->open();
    sessionToken->bindOpeningSource(nullptr);

    if (sessionToken->isCancelled()) {
        source->close();
        mState.store(EngineState::Idle, std::memory_order_release);
        return EngineStatus::ErrorIO;
    }

    if (status != EngineStatus::Ok) {
        LOGE("Data source open failed: %d", static_cast<int>(status));
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    mSampleRate = source->getSampleRate();
    mSourceChannelCount = source->getChannelCount();
    const int64_t durMs = source->getDurationUs() / 1000;
    mDurationMs.store(durMs, std::memory_order_release);
    mDurationAuthority.store(
        durMs > 0 ? DurationAuthority::ContainerVerified : DurationAuthority::Estimated,
        std::memory_order_release);

    if (mSampleRate <= 0 || mSourceChannelCount <= 0) {
        LOGE("Invalid format: sr=%d cc=%d", mSampleRate, mSourceChannelCount);
        source->close();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return EngineStatus::ErrorCodec;
    }

    LOGI("Source opened: sr=%d cc=%d dur=%lldms mime=%s",
         mSampleRate, mSourceChannelCount,
         static_cast<long long>(durMs), source->getMimeType());
    notifyStateChanged(mState.load(std::memory_order_acquire));

    auto decoder = std::make_unique<NativeDecoder>(
        mRingBuffer,
        source->getExtractor(),
        source->getMimeType(),
        source->getTrackFormat(),
        mSourceChannelCount,
        nullptr,
        -1,
        0,
        [this]() { wakeMonitor(); });

    status = decoder->configure();
    if (status != EngineStatus::Ok) {
        LOGE("Decoder configure failed: %d", static_cast<int>(status));
        source->close();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    {
        std::lock_guard<std::mutex> lock(mSourceCancelMutex);
        mDataSource = std::move(source);
    }
    mDecoder = std::move(decoder);

    status = openOboeStream();
    if (status != EngineStatus::Ok) {
        LOGE("Oboe stream open failed: %d", static_cast<int>(status));
        mDecoder->stop();
        mDecoder.reset();
        std::unique_ptr<IAudioDataSource> dataToClose;
        {
            std::lock_guard<std::mutex> lock(mSourceCancelMutex);
            dataToClose = std::move(mDataSource);
        }
        if (dataToClose) dataToClose->close();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    mRingBuffer.reset();
    mFramesConsumedByHardware.store(0, std::memory_order_relaxed);
    mSeekPositionMs.store(0, std::memory_order_relaxed);
    mUnderrunCount.store(0, std::memory_order_relaxed);
    mDecoderStreamState.store(DecoderStreamState::Decoding, std::memory_order_relaxed);

    mState.store(EngineState::Prebuffering, std::memory_order_release);

    status = mDecoder->start();
    if (status != EngineStatus::Ok) {
        LOGE("Decoder start failed: %d", static_cast<int>(status));
        closeOboeStream();
        mDecoder.reset();
        std::unique_ptr<IAudioDataSource> dataToClose;
        {
            std::lock_guard<std::mutex> lock(mSourceCancelMutex);
            dataToClose = std::move(mDataSource);
        }
        if (dataToClose) dataToClose->close();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    joinMonitorThread();
    mMonitorShouldStop.store(false, std::memory_order_release);
    mMonitorThread = std::thread(&AudioEngine::decoderMonitorFunc, this);

    return EngineStatus::Ok;
}

// ===========================================================================
// Monitor thread: watermark detection, stall/resume sync, handoff & EOS
// ===========================================================================

void AudioEngine::decoderMonitorFunc() {
    size_t emptyRingTicks = 0;

    while (!mMonitorShouldStop.load(std::memory_order_acquire)) {
        if (mRingBuffer.availableToWrite() > 0) {
            if (mDecoder) mDecoder->notifyRingSpaceAvailable();
            if (mPrimaryDecoder) mPrimaryDecoder->notifyRingSpaceAvailable();
            if (mSecondaryDecoder) mSecondaryDecoder->notifyRingSpaceAvailable();
        }

        const EngineState currentState = mState.load(std::memory_order_acquire);
        const bool isDual =
            mSourceTopology.load(std::memory_order_acquire) == SourceTopology::DualHeadAndCdn;
        const SecondaryStreamPhase secPhase = mSecondaryPhase.load(std::memory_order_acquire);

        // 1. Prebuffering watermark detection (initial load, seek, or stall recovery)
        if (currentState == EngineState::Prebuffering) {
            emptyRingTicks = 0;
            const bool waitingForPendingSeekSecondary =
                isDual &&
                secPhase != SecondaryStreamPhase::HandedOff &&
                (mPrimaryHeadState.load(std::memory_order_acquire) ==
                     PrimaryHeadState::SuspendedForOutOfRangeSeek ||
                 mPendingSeekOverrideMs.load(std::memory_order_acquire) >= 0);
            const size_t available = mRingBuffer.availableToRead();
            bool eos = false;
            if (isDual) {
                if (secPhase == SecondaryStreamPhase::HandedOff) {
                    eos = mSecondaryDecoder && mSecondaryDecoder->isEndOfStream();
                } else {
                    eos = mPrimaryDecoder && mPrimaryDecoder->isEndOfStream() &&
                          secPhase != SecondaryStreamPhase::Attaching &&
                          !mSecondaryWorkerThread.joinable();
                }
            } else {
                eos = mDecoder && mDecoder->isEndOfStream();
            }

            const size_t watermark = static_cast<size_t>(mSampleRate) * 25 / 1000;

            if (!waitingForPendingSeekSecondary &&
                (available >= watermark || (eos && available > 0))) {
                NativeDecoder* activeDec = isDual
                    ? (secPhase == SecondaryStreamPhase::HandedOff
                           ? mSecondaryDecoder.get()
                           : mPrimaryDecoder.get())
                    : mDecoder.get();
                if (activeDec) {
                    const int64_t landedSeekMs = activeDec->consumeActualSeekMs();
                    if (landedSeekMs >= 0) {
                        const int64_t requestedMs = mSeekPositionMs.load(std::memory_order_acquire);
                        if (std::abs(landedSeekMs - requestedMs) > 120) {
                            mSeekPositionMs.store(landedSeekMs, std::memory_order_release);
                        }
                    }
                }
                const StartPolicy policy = mStartPolicy.load(std::memory_order_acquire);
                const EngineState targetState =
                    (policy == StartPolicy::AutoPlayOnWatermark)
                        ? EngineState::Playing
                        : EngineState::Paused;
                EngineState expected = EngineState::Prebuffering;
                if (mState.compare_exchange_strong(expected, targetState, std::memory_order_acq_rel)) {
                    if (targetState == EngineState::Playing) {
                        const oboe::Result result = startOrReopenOboeStream();
                        if (result != oboe::Result::OK) {
                            LOGE("Oboe startOrReopenOboeStream failed: %d", static_cast<int>(result));
                            mState.store(EngineState::Faulted, std::memory_order_release);
                            notifyStateChanged(EngineState::Faulted);
                        } else {
                            LOGI("Playback started/resumed (buffered=%zu frames)", available);
                            notifyStateChanged(EngineState::Playing);
                        }
                    } else {
                        LOGI("Prebuffer watermark reached in paused state (%zu frames)", available);
                        notifyStateChanged(EngineState::Paused);
                    }
                }
            }
        }

        // 2. Dual-source handoff cleanup / boundary handling
        if (isDual) {
            if (secPhase == SecondaryStreamPhase::HandedOff) {
                if (mPrimaryDecoder) {
                    mPrimaryDecoder->stop();
                    mPrimaryDecoder.reset();
                    std::unique_ptr<IAudioDataSource> primaryToClose;
                    {
                        std::lock_guard<std::mutex> lock(mSourceCancelMutex);
                        primaryToClose = std::move(mPrimarySource);
                    }
                    if (primaryToClose) primaryToClose->close();
                    mPrimaryHeadState.store(PrimaryHeadState::Released, std::memory_order_release);
                    LOGI("Primary decoder resources safely released after handoff to secondary");
                }
            } else if (secPhase == SecondaryStreamPhase::Failed) {
                if (mRingBuffer.availableToRead() == 0) {
                    LOGI("Pausing at handoff boundary due to secondary source/DRM failure");
                    std::shared_ptr<oboe::AudioStream> streamSnapshot;
                    {
                        std::lock_guard<std::mutex> lock(mStreamMutex);
                        streamSnapshot = mStream;
                    }
                    if (streamSnapshot) streamSnapshot->requestPause();
                    if (mState.exchange(EngineState::Paused, std::memory_order_acq_rel) != EngineState::Paused) {
                        notifyStateChanged(EngineState::Paused);
                    }
                    std::unique_lock<std::mutex> lock(mMonitorMutex);
                    mMonitorCv.wait_for(lock, std::chrono::milliseconds(10));
                    continue;
                }
            } else if (mPrimaryDecoder && mPrimaryDecoder->isEndOfStream() &&
                       !mSecondaryWorkerThread.joinable() &&
                       secPhase != SecondaryStreamPhase::Attaching) {
                if (mRingBuffer.availableToRead() == 0) {
                    LOGI("Pausing cleanly at chunk 0 EOF (no secondary stream attached or pending)");
                    std::shared_ptr<oboe::AudioStream> streamSnapshot;
                    {
                        std::lock_guard<std::mutex> lock(mStreamMutex);
                        streamSnapshot = mStream;
                    }
                    if (streamSnapshot) streamSnapshot->requestPause();
                    if (mState.exchange(EngineState::Paused, std::memory_order_acq_rel) != EngineState::Paused) {
                        notifyStateChanged(EngineState::Paused);
                    }
                    std::unique_lock<std::mutex> lock(mMonitorMutex);
                    mMonitorCv.wait_for(lock, std::chrono::milliseconds(10));
                    continue;
                }
            }
        }

        // 3. Propagate EOS state to Oboe callback
        if (isDual) {
            if (secPhase == SecondaryStreamPhase::HandedOff) {
                const bool secEos = mSecondaryDecoder && mSecondaryDecoder->isEndOfStream();
                mDecoderStreamState.store(
                    secEos ? DecoderStreamState::EndOfStreamReached : DecoderStreamState::Decoding,
                    std::memory_order_release);
            } else if (secPhase != SecondaryStreamPhase::Attaching &&
                       !mSecondaryWorkerThread.joinable() &&
                       mPrimaryDecoder && mPrimaryDecoder->isEndOfStream()) {
                mDecoderStreamState.store(
                    DecoderStreamState::EndOfStreamReached, std::memory_order_release);
            } else {
                mDecoderStreamState.store(
                    DecoderStreamState::Decoding, std::memory_order_release);
            }
        } else {
            const bool singleEos = mDecoder && mDecoder->isEndOfStream();
            mDecoderStreamState.store(
                singleEos ? DecoderStreamState::EndOfStreamReached : DecoderStreamState::Decoding,
                std::memory_order_release);
        }

        // 4. Mid-stream stall detection: freeze hardware clock cleanly instead of spinning underruns
        if (mState.load(std::memory_order_acquire) == EngineState::Playing) {
            if (mRingBuffer.availableToRead() == 0 &&
                mDecoderStreamState.load(std::memory_order_acquire) !=
                    DecoderStreamState::EndOfStreamReached) {
                if (++emptyRingTicks >= 8) {
                    EngineState expected = EngineState::Playing;
                    if (mState.compare_exchange_strong(
                            expected, EngineState::Prebuffering, std::memory_order_acq_rel)) {
                        std::shared_ptr<oboe::AudioStream> streamSnapshot;
                        {
                            std::lock_guard<std::mutex> lock(mStreamMutex);
                            streamSnapshot = mStream;
                        }
                        if (streamSnapshot) {
                            streamSnapshot->requestPause();
                        }
                        LOGW("Playback stalled waiting on buffered frames -> Prebuffering");
                        notifyStateChanged(EngineState::Prebuffering);
                    }
                    emptyRingTicks = 0;
                }
            } else {
                emptyRingTicks = 0;
            }
        }

        // 5. Handle EOS hardware drain completion
        const EngineState afterState = mState.load(std::memory_order_acquire);
        if (afterState == EngineState::Stopped) {
            if (mEosNotificationState.exchange(
                    EosNotificationState::Dispatched, std::memory_order_acq_rel) ==
                EosNotificationState::Pending) {
                std::shared_ptr<oboe::AudioStream> streamSnapshot;
                {
                    std::lock_guard<std::mutex> lock(mStreamMutex);
                    streamSnapshot = mStream;
                }
                if (streamSnapshot) {
                    streamSnapshot->requestPause();
                }

                LOGI("AudioEngine: EOS reached, scheduling EOS dispatcher");
                bool hasEosCallback = false;
                {
                    std::lock_guard<std::mutex> lock(mEosMutex);
                    hasEosCallback = static_cast<bool>(mEosCallback);
                    mEosPending = true;
                }
                if (!hasEosCallback) {
                    notifyStateChanged(EngineState::Stopped);
                }
                mEosCv.notify_one();
            }
            std::unique_lock<std::mutex> lock(mMonitorMutex);
            mMonitorCv.wait_for(lock, std::chrono::milliseconds(20));
            continue;
        }

        if (afterState == EngineState::Faulted || afterState == EngineState::Idle) {
            break;
        }

        std::unique_lock<std::mutex> lock(mMonitorMutex);
        mMonitorCv.wait_for(
            lock,
            std::chrono::milliseconds(afterState == EngineState::Prebuffering ? 2 : 4));
    }
}

// ===========================================================================
// Oboe stream setup & warm reuse
// ===========================================================================

EngineStatus AudioEngine::openOboeStream() {
    std::shared_ptr<oboe::AudioStream> staleStream;
    {
        std::lock_guard<std::mutex> lock(mStreamMutex);
        if (mStream) {
            const auto st = mStream->getState();
            if (st != oboe::StreamState::Closed &&
                st != oboe::StreamState::Disconnected &&
                mStreamSampleRate == mSampleRate) {
                if (st == oboe::StreamState::Started || st == oboe::StreamState::Starting) {
                    mStream->requestPause();
                }
                mStream->requestFlush();
                return EngineStatus::Ok;
            }
            staleStream = std::move(mStream);
            mStreamSampleRate = 0;
        }
    }
    if (staleStream) {
        staleStream->requestStop();
        staleStream->close();
    }

    oboe::AudioStreamBuilder builder;
    builder.setDirection(oboe::Direction::Output)
           ->setPerformanceMode(oboe::PerformanceMode::LowLatency)
           ->setSharingMode(oboe::SharingMode::Exclusive)
           ->setFormat(oboe::AudioFormat::Float)
           ->setChannelCount(oboe::ChannelCount::Stereo)
           ->setSampleRate(mSampleRate)
           ->setUsage(oboe::Usage::Media)
           ->setContentType(oboe::ContentType::Music)
           ->setSampleRateConversionQuality(oboe::SampleRateConversionQuality::Medium)
           ->setFormatConversionAllowed(true)
           ->setDataCallback(this)
           ->setErrorCallback(this);

    std::shared_ptr<oboe::AudioStream> newStream;
    oboe::Result result = builder.openStream(newStream);
    if (result != oboe::Result::OK) {
        LOGE("openStream failed: %d", static_cast<int>(result));
        return EngineStatus::ErrorStream;
    }

    newStream->setBufferSizeInFrames(newStream->getFramesPerBurst() * 2);

    LOGI("Oboe stream opened: sr=%d burst=%d bufSize=%d",
         newStream->getSampleRate(),
         newStream->getFramesPerBurst(),
         newStream->getBufferSizeInFrames());

    {
        std::lock_guard<std::mutex> lock(mStreamMutex);
        mStream = std::move(newStream);
        mStreamSampleRate = mSampleRate;
    }
    return EngineStatus::Ok;
}

oboe::Result AudioEngine::startOrReopenOboeStream(std::shared_ptr<oboe::AudioStream>* outStream) {
    std::shared_ptr<oboe::AudioStream> streamSnapshot;
    {
        std::lock_guard<std::mutex> lock(mStreamMutex);
        streamSnapshot = mStream;
    }

    if (!streamSnapshot ||
        streamSnapshot->getState() == oboe::StreamState::Closed ||
        streamSnapshot->getState() == oboe::StreamState::Disconnected) {
        if (openOboeStream() != EngineStatus::Ok) {
            return oboe::Result::ErrorClosed;
        }
        std::lock_guard<std::mutex> lock(mStreamMutex);
        streamSnapshot = mStream;
    }

    if (!streamSnapshot) {
        return oboe::Result::ErrorClosed;
    }

    if (streamSnapshot->getState() == oboe::StreamState::Started) {
        if (outStream) {
            *outStream = std::move(streamSnapshot);
        }
        return oboe::Result::OK;
    }

    oboe::Result result = streamSnapshot->requestStart();
    if (result == oboe::Result::ErrorClosed || result == oboe::Result::ErrorDisconnected) {
        closeOboeStream();
        if (openOboeStream() == EngineStatus::Ok) {
            std::lock_guard<std::mutex> lock(mStreamMutex);
            streamSnapshot = mStream;
            if (streamSnapshot) {
                result = streamSnapshot->requestStart();
            }
        }
    }

    if (outStream) {
        *outStream = std::move(streamSnapshot);
    }
    return result;
}

// ===========================================================================
// Control: play / pause / seekMs
// ===========================================================================

EngineStatus AudioEngine::play() {
    mStartPolicy.store(StartPolicy::AutoPlayOnWatermark, std::memory_order_release);
    const EngineState current = mState.load(std::memory_order_acquire);
    if (current == EngineState::Paused || current == EngineState::Stopped) {
        mState.store(EngineState::Playing, std::memory_order_release);
        startOrReopenOboeStream();
        wakeMonitor();
        notifyStateChanged(EngineState::Playing);
        return EngineStatus::Ok;
    }
    if (current == EngineState::Playing ||
        current == EngineState::Prebuffering ||
        current == EngineState::Loading) {
        wakeMonitor();
        return EngineStatus::Ok;
    }
    return EngineStatus::ErrorInvalidState;
}

EngineStatus AudioEngine::pause() {
    mStartPolicy.store(StartPolicy::HoldPausedOnWatermark, std::memory_order_release);
    const EngineState current = mState.load(std::memory_order_acquire);
    if (current == EngineState::Playing) {
        mState.store(EngineState::Paused, std::memory_order_release);
        std::shared_ptr<oboe::AudioStream> streamSnapshot;
        {
            std::lock_guard<std::mutex> lock(mStreamMutex);
            streamSnapshot = mStream;
        }
        if (streamSnapshot) {
            streamSnapshot->requestPause();
        }
        wakeMonitor();
        notifyStateChanged(EngineState::Paused);
        return EngineStatus::Ok;
    }
    if (current == EngineState::Paused ||
        current == EngineState::Stopped ||
        current == EngineState::Prebuffering ||
        current == EngineState::Loading) {
        return EngineStatus::Ok;
    }
    return EngineStatus::ErrorInvalidState;
}

EngineStatus AudioEngine::seekMs(int64_t positionMs) {
    const EngineState current = mState.load(std::memory_order_acquire);
    if (current != EngineState::Playing &&
        current != EngineState::Paused &&
        current != EngineState::Stopped &&
        current != EngineState::Prebuffering) {
        return EngineStatus::ErrorInvalidState;
    }

    if (positionMs < 0) {
        return EngineStatus::ErrorInvalidArg;
    }

    const int64_t knownDurMs = mDurationMs.load(std::memory_order_acquire);
    const bool isDual =
        mSourceTopology.load(std::memory_order_relaxed) == SourceTopology::DualHeadAndCdn;
    if (!isDual && knownDurMs > 0 && positionMs > knownDurMs) {
        return EngineStatus::ErrorInvalidArg;
    }

    mSeekGeneration.fetch_add(1, std::memory_order_acq_rel);

    // Move Playing -> Prebuffering before resetting mRingBuffer so Oboe outputs clean
    // digital silence without hitting emptyRingTicks + requestPause()/requestStart() HAL latency.
    if (current == EngineState::Playing) {
        mState.store(EngineState::Prebuffering, std::memory_order_release);
    }

    mSeekPositionMs.store(positionMs, std::memory_order_release);
    mFramesConsumedByHardware.store(0, std::memory_order_release);
    mDecoderStreamState.store(DecoderStreamState::Decoding, std::memory_order_release);
    mEosNotificationState.store(EosNotificationState::Pending, std::memory_order_release);

    // CRITICAL ORDERING: Arm mSeekRequested on the active NativeDecoder(s) BEFORE calling
    // onSeek() on the data sources. If the decoder is currently parked in AMediaExtractor_readSampleData
    // waiting on an uncached block while offline, onSeek() will unblock readAt() with -1; having
    // mSeekRequested == true beforehand guarantees NativeDecoder::feedInputBuffer() never mistakes
    // the seek interruption for End-Of-Stream.
    bool waitingForPendingSecondary = false;
    if (isDual) {
        const int64_t primaryDurMs = mPrimaryDurationMs.load(std::memory_order_acquire);
        const SecondaryStreamPhase secPhase = mSecondaryPhase.load(std::memory_order_acquire);
        if (secPhase == SecondaryStreamPhase::HandedOff) {
            if (mSecondaryDecoder) {
                mSecondaryDecoder->requestSeek(positionMs * 1000);
            }
        } else if (primaryDurMs > 0 && positionMs < primaryDurMs && mPrimaryDecoder) {
            mPendingSeekOverrideMs.store(-1, std::memory_order_release);
            mPrimaryHeadState.store(PrimaryHeadState::Active, std::memory_order_release);
            mPrimaryDecoder->requestSeek(positionMs * 1000);
        } else if (mSecondaryDecoder) {
            mSecondaryDecoder->requestSeek(positionMs * 1000);
        } else {
            // Seek landed past Chunk 0 while secondary MP4 is still opening (or waiting for online):
            // suspend mPrimaryDecoder without destroying it so seeking back into Chunk 0 offline
            // still works, and steer secondaryWorkerFunc to open directly at positionMs.
            mPendingSeekOverrideMs.store(positionMs, std::memory_order_release);
            mPrimaryHeadState.store(
                PrimaryHeadState::SuspendedForOutOfRangeSeek, std::memory_order_release);
            if (mPrimaryDecoder) {
                mPrimaryDecoder->suspend();
            }
            waitingForPendingSecondary = (secPhase == SecondaryStreamPhase::Attaching) ||
                                         mSecondaryWorkerThread.joinable();
        }
    } else {
        if (mDecoder) {
            mDecoder->requestSeek(positionMs * 1000);
        }
    }

    mRingBuffer.reset();

    // Advance data source seek epoch so any stale foreground download or offline P0 queue wait
    // from an earlier position is immediately aborted and the HTTP/2 connection is freed.
    {
        std::lock_guard<std::mutex> lock(mSourceCancelMutex);
        if (mDataSource) mDataSource->onSeek();
        if (mPrimarySource) mPrimarySource->onSeek();
        if (mSecondarySource) mSecondarySource->onSeek();
    }

    wakeMonitor();

    if (waitingForPendingSecondary) {
        std::shared_ptr<oboe::AudioStream> streamSnapshot;
        {
            std::lock_guard<std::mutex> lock(mStreamMutex);
            streamSnapshot = mStream;
        }
        if (streamSnapshot) {
            streamSnapshot->requestPause();
        }
        mState.store(EngineState::Prebuffering, std::memory_order_release);
        notifyStateChanged(EngineState::Prebuffering);
    } else if (current == EngineState::Stopped) {
        const EngineState next =
            (mStartPolicy.load(std::memory_order_acquire) == StartPolicy::AutoPlayOnWatermark)
                ? EngineState::Prebuffering
                : EngineState::Paused;
        mState.store(next, std::memory_order_release);
        notifyStateChanged(next);
    } else if (current == EngineState::Playing) {
        notifyStateChanged(EngineState::Prebuffering);
    } else {
        notifyStateChanged(current);
    }

    return EngineStatus::Ok;
}

// ===========================================================================
// Control: encrypted stream (stub)
// ===========================================================================

EngineStatus AudioEngine::initEncryptedStream(int64_t totalSize,
                                               const uint8_t* key16,
                                               const uint8_t* iv16) {
    if (!key16 || !iv16 || totalSize <= 0) {
        return EngineStatus::ErrorInvalidArg;
    }

    stopPlayback();
    mEncryptionMode = SourceEncryptionMode::Encrypted;
    mSourceTopology.store(SourceTopology::SingleStream, std::memory_order_release);

    auto source = std::make_unique<EncryptedStreamDataSource>(totalSize, key16, iv16);
    return loadSource(std::move(source));
}

EngineStatus AudioEngine::pushStreamChunk(int64_t offset,
                                           const uint8_t* data,
                                           int32_t length) {
    if (mEncryptionMode != SourceEncryptionMode::Encrypted || !mDataSource) {
        return EngineStatus::ErrorInvalidState;
    }
    auto* encrypted = static_cast<EncryptedStreamDataSource*>(mDataSource.get());
    return encrypted->pushChunk(offset, data, length);
}

// ===========================================================================
// Telemetry
// ===========================================================================

int64_t AudioEngine::getPositionMs() const {
    const int64_t consumed = mFramesConsumedByHardware.load(std::memory_order_acquire);
    const int64_t seekBase = mSeekPositionMs.load(std::memory_order_acquire);
    if (mSampleRate <= 0) return seekBase;

    const int64_t playedSinceSeekMs = (consumed * 1000) / mSampleRate;
    int64_t posMs = seekBase + playedSinceSeekMs;

    if (mState.load(std::memory_order_acquire) == EngineState::Playing) {
        std::shared_ptr<oboe::AudioStream> streamSnapshot;
        {
            std::lock_guard<std::mutex> lock(mStreamMutex);
            streamSnapshot = mStream;
        }
        if (streamSnapshot) {
            const auto latency = streamSnapshot->calculateLatencyMillis();
            if (latency && latency.value() > 0.0 && latency.value() < 2000.0) {
                const int64_t latencyMs = static_cast<int64_t>(latency.value());
                posMs = seekBase + std::max<int64_t>(0, playedSinceSeekMs - latencyMs);
            }
        }
    }

    const int64_t durMs = mDurationMs.load(std::memory_order_acquire);
    if (mDurationAuthority.load(std::memory_order_acquire) == DurationAuthority::ContainerVerified &&
        durMs > 0 && posMs > durMs) {
        posMs = durMs;
    }
    return posMs;
}

int64_t AudioEngine::getDurationMs() const {
    return mDurationMs.load(std::memory_order_acquire);
}

int32_t AudioEngine::getState() const {
    return static_cast<int32_t>(mState.load(std::memory_order_acquire));
}

int32_t AudioEngine::getUnderrunCount() const {
    return mUnderrunCount.load(std::memory_order_relaxed);
}

// ===========================================================================
// Oboe real-time audio callback
// ===========================================================================

oboe::DataCallbackResult AudioEngine::onAudioReady(
        oboe::AudioStream* /*stream*/,
        void* audioData,
        int32_t numFrames) {

    auto* output = static_cast<float*>(audioData);
    const size_t requestedFrames = static_cast<size_t>(numFrames);

    const EngineState state = mState.load(std::memory_order_acquire);

    if (state != EngineState::Playing) {
        std::memset(output, 0, requestedFrames * RingBuffer::kChannelCount * sizeof(float));
        return oboe::DataCallbackResult::Continue;
    }

    const size_t framesRead = mRingBuffer.read(output, requestedFrames);

    // Symmetric ramp-up after underrun recovery: prevent zero-to-full click
    if (mUnderrunRecovery == UnderrunRecoveryState::NeedsRampUp && framesRead > 0) {
        constexpr size_t kRampUpFrames = 64;
        const size_t ramp = std::min(kRampUpFrames, framesRead);
        for (size_t i = 0; i < ramp; ++i) {
            const float gain = static_cast<float>(i + 1) / static_cast<float>(ramp);
            const size_t idx = i * RingBuffer::kChannelCount;
            output[idx]     *= gain;
            output[idx + 1] *= gain;
        }
        mUnderrunRecovery = UnderrunRecoveryState::Normal;
    }

    if (framesRead < requestedFrames) {
        const bool eos =
            mDecoderStreamState.load(std::memory_order_acquire) ==
            DecoderStreamState::EndOfStreamReached;

        if (eos && mRingBuffer.availableToRead() == 0) {
            std::memset(output + framesRead * RingBuffer::kChannelCount, 0,
                        (requestedFrames - framesRead) * RingBuffer::kChannelCount * sizeof(float));
            mFramesConsumedByHardware.fetch_add(
                static_cast<int64_t>(framesRead), std::memory_order_relaxed);
            mState.store(EngineState::Stopped, std::memory_order_release);
            mMonitorCv.notify_one();
            return oboe::DataCallbackResult::Continue;
        }

        // Apply linear ramp-down on underrun trailing edge to prevent click/pop
        constexpr size_t kRampFrames = 64;
        if (framesRead > kRampFrames) {
            const size_t rampStart = framesRead - kRampFrames;
            for (size_t i = 0; i < kRampFrames; ++i) {
                const float gain = 1.0f - static_cast<float>(i + 1)
                                        / static_cast<float>(kRampFrames);
                const size_t idx = (rampStart + i) * RingBuffer::kChannelCount;
                output[idx]     *= gain;
                output[idx + 1] *= gain;
            }
        } else if (framesRead > 0) {
            for (size_t i = 0; i < framesRead; ++i) {
                const float gain = 1.0f - static_cast<float>(i + 1)
                                        / static_cast<float>(framesRead);
                const size_t idx = i * RingBuffer::kChannelCount;
                output[idx]     *= gain;
                output[idx + 1] *= gain;
            }
        }

        std::memset(output + framesRead * RingBuffer::kChannelCount, 0,
                    (requestedFrames - framesRead) * RingBuffer::kChannelCount * sizeof(float));

        mUnderrunRecovery = UnderrunRecoveryState::NeedsRampUp;
        int32_t count = mUnderrunCount.fetch_add(1, std::memory_order_relaxed) + 1;
        mMonitorCv.notify_one();
        LOGW("AudioEngine underrun #%d: read only %zu of %zu frames (avail=%zu, eos=%d)",
             count, framesRead, requestedFrames, mRingBuffer.availableToRead(), eos ? 1 : 0);
    }

    mFramesConsumedByHardware.fetch_add(
        static_cast<int64_t>(framesRead), std::memory_order_relaxed);

    return oboe::DataCallbackResult::Continue;
}

// ===========================================================================
// Oboe error callback
// ===========================================================================

void AudioEngine::onErrorAfterClose(
        oboe::AudioStream* /*stream*/,
        oboe::Result error) {

    if (error == oboe::Result::ErrorDisconnected) {
        LOGI("Audio route disconnected - re-opening stream");

        const EngineState current = mState.load(std::memory_order_acquire);

        closeOboeStream();
        EngineStatus status = openOboeStream();
        if (status != EngineStatus::Ok) {
            LOGE("Stream re-open failed: %d", static_cast<int>(status));
            mState.store(EngineState::Faulted, std::memory_order_release);
            return;
        }

        if (current == EngineState::Playing) {
            std::shared_ptr<oboe::AudioStream> streamSnapshot;
            {
                std::lock_guard<std::mutex> lock(mStreamMutex);
                streamSnapshot = mStream;
            }
            if (streamSnapshot) {
                streamSnapshot->requestStart();
            }
        }
    }
}
