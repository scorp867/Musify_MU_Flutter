#include "AudioEngine.h"
#include "JniHelper.h"
#include "content_delivery/HeadFileManager.h"
#include "network/NativeHttpClient.h"

#include <cstring>
#include <algorithm>
#include <chrono>
#include <sys/stat.h>

#include <jni.h>
#include <android/log.h>

#define LOG_TAG "MusifyEngine"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN,  LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static const uint8_t kWidevineUuid[16] = {
    0xed, 0xef, 0x8b, 0xa9, 0x79, 0xd6, 0x4a, 0xce,
    0xa3, 0xc8, 0x27, 0xdc, 0xd5, 0x1d, 0x21, 0xed
};

static JavaVM* sJavaVm = nullptr;
static jclass sDrmBridgeClass = nullptr;
static jmethodID sAcquireSessionMethod = nullptr;
static jmethodID sCloseSessionMethod = nullptr;
static jobject sClassLoader = nullptr;
static jmethodID sLoadClassMethod = nullptr;

JavaVM* getMusifyJavaVm() noexcept { return sJavaVm; }
jobject getMusifyClassLoader() noexcept { return sClassLoader; }
jmethodID getMusifyLoadClassMethod() noexcept { return sLoadClassMethod; }

extern "C" JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* /*reserved*/) {
    sJavaVm = vm;
    LOGI("AudioEngine JNI_OnLoad registered");

    JNIEnv* env = nullptr;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK || !env) {
        LOGE("JNI_OnLoad: failed to get JNIEnv");
        return JNI_VERSION_1_6;
    }

    // 1. Cache NativeDrmBridge class and methods (Widevine MediaDrm platform API)
    jclass localDrm = env->FindClass("um/musify/mu/musify_mu/NativeDrmBridge");
    if (localDrm) {
        sDrmBridgeClass = reinterpret_cast<jclass>(env->NewGlobalRef(localDrm));
        sAcquireSessionMethod = env->GetStaticMethodID(
            sDrmBridgeClass,
            "acquireSession",
            "([BLjava/lang/String;Ljava/lang/String;)[B");
        sCloseSessionMethod = env->GetStaticMethodID(
            sDrmBridgeClass,
            "closeSession",
            "([B)V");
        env->DeleteLocalRef(localDrm);
        LOGI("NativeDrmBridge cached (cls=%p, acquire=%p, close=%p)", sDrmBridgeClass, sAcquireSessionMethod, sCloseSessionMethod);
    } else {
        LOGE("Failed to find NativeDrmBridge in JNI_OnLoad");
        if (env->ExceptionCheck()) env->ExceptionClear();
    }

    // 2. Cache Application ClassLoader as fallback for DRM calls on detached workers
    jclass mainActivityClass = env->FindClass("um/musify/mu/musify_mu/MainActivity");
    if (mainActivityClass) {
        jclass classClass = env->GetObjectClass(mainActivityClass);
        jmethodID getClassLoaderMethod = env->GetMethodID(classClass, "getClassLoader", "()Ljava/lang/ClassLoader;");
        jobject classLoader = env->CallObjectMethod(mainActivityClass, getClassLoaderMethod);
        if (classLoader) {
            sClassLoader = env->NewGlobalRef(classLoader);
            jclass classLoaderClass = env->FindClass("java/lang/ClassLoader");
            sLoadClassMethod = env->GetMethodID(classLoaderClass, "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;");
            env->DeleteLocalRef(classLoaderClass);
            env->DeleteLocalRef(classLoader);
            LOGI("Application ClassLoader cached (loader=%p, loadMethod=%p)", sClassLoader, sLoadClassMethod);
        }
        env->DeleteLocalRef(classClass);
        env->DeleteLocalRef(mainActivityClass);
    } else {
        if (env->ExceptionCheck()) env->ExceptionClear();
    }

    return JNI_VERSION_1_6;
}

extern "C" JNIEXPORT void JNI_OnUnload(JavaVM* vm, void* /*reserved*/) {
    JNIEnv* env = nullptr;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) == JNI_OK && env) {
        if (sDrmBridgeClass) env->DeleteGlobalRef(sDrmBridgeClass);
        if (sClassLoader) env->DeleteGlobalRef(sClassLoader);
    }
}

// ===========================================================================
// Construction / Destruction
// ===========================================================================

AudioEngine::AudioEngine() {
    mState.store(EngineState::Idle, std::memory_order_release);
    mEosDispatcherThread = std::thread(&AudioEngine::eosDispatcherFunc, this);
}

AudioEngine::~AudioEngine() {
    mMonitorShouldStop.store(true, std::memory_order_release);
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

void AudioEngine::failSecondary(const std::string& reason) {
    LOGE("Secondary stream failed: %s", reason.c_str());
    mSecondaryFailed.store(true, std::memory_order_release);
    mSecondaryPending.store(false, std::memory_order_release);
    if (mSecondaryWorkerShouldStop.load(std::memory_order_acquire)) {
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
    mAutoPlay.store(autoPlay, std::memory_order_release);
}

void AudioEngine::stop() {
    stopPlayback();
    mFramesConsumedByHardware.store(0, std::memory_order_relaxed);
    mSeekPositionMs.store(0, std::memory_order_relaxed);
    mDurationMs.store(0, std::memory_order_release);
    mDurationAuthoritative.store(false, std::memory_order_release);
    mState.store(EngineState::Idle, std::memory_order_release);
}

void AudioEngine::cancelAllActiveSources() {
    std::lock_guard<std::mutex> lock(mSourceCancelMutex);
    if (mDataSource) mDataSource->cancel();
    if (mPrimarySource) mPrimarySource->cancel();
    if (mSecondarySource) mSecondarySource->cancel();
    if (mOpeningSecondarySource) mOpeningSecondarySource->cancel();
}

// ===========================================================================
// Internal: stop all playback components
// ===========================================================================

void AudioEngine::stopPlayback() {
    mMonitorShouldStop.store(true, std::memory_order_release);
    mSecondaryWorkerShouldStop.store(true, std::memory_order_release);

    // 1. Cancel all I/O data sources FIRST so any blocking open()/readAt()/libcurl transfers
    // return immediately instead of stalling worker/decoder thread joins for network timeouts.
    cancelAllActiveSources();

    if (mSecondaryWorkerThread.joinable()) {
        mSecondaryWorkerThread.join();
    }

    std::shared_ptr<oboe::AudioStream> streamToClose;
    {
        std::lock_guard<std::mutex> lock(mStreamMutex);
        streamToClose = std::move(mStream);
    }
    if (streamToClose) {
        streamToClose->requestStop();
        streamToClose->close();
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
        mOpeningSecondarySource = nullptr;
    }

    if (dataSrc) dataSrc->close();
    if (primarySrc) primarySrc->close();
    if (secondarySrc) secondarySrc->close();

    if (mSecondaryCrypto) {
        AMediaCrypto_delete(mSecondaryCrypto);
        mSecondaryCrypto = nullptr;
    }
    closeActiveDrmSession();

    mRingBuffer.reset();

    mIsDualSource.store(false, std::memory_order_release);
    mSecondaryPending.store(false, std::memory_order_release);
    mSecondaryReady.store(false, std::memory_order_release);
    mSecondaryFailed.store(false, std::memory_order_release);
    mHandoffCompleted.store(false, std::memory_order_release);
    mHandoffTargetMs.store(-1, std::memory_order_release);
    mHandoffActualMs.store(0, std::memory_order_release);
    mPrimaryDurationMs.store(0, std::memory_order_release);
    mPendingSeekOverrideMs.store(-1, std::memory_order_release);
    mPrimarySeekInvalidated.store(false, std::memory_order_release);
    mDurationAuthoritative.store(false, std::memory_order_release);
    mEosNotified.store(false, std::memory_order_relaxed);
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
    mIsEncryptedSource = false;
    mIsDualSource.store(false, std::memory_order_release);

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
    mIsEncryptedSource = false;
    mIsDualSource.store(false, std::memory_order_release);
    mSecondaryPending.store(true, std::memory_order_release);
    mSecondaryReady.store(false, std::memory_order_release);
    mSecondaryFailed.store(false, std::memory_order_release);
    mHandoffCompleted.store(false, std::memory_order_release);
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
    bool isCached = (::stat(headPath.c_str(), &st) == 0 && st.st_size >= 512);

    std::unique_ptr<IAudioDataSource> primarySource;

    if (isCached) {
        LOGI("Head file cache HIT for %s (%s, size=%lld)", fileIdHex, headPath.c_str(), (long long)st.st_size);
        primarySource = std::make_unique<LocalFileDataSource>(headPath.c_str());
    } else {
        LOGI("Head file cache MISS for %s - initiating progressive stream to %s", fileIdHex, partPath.c_str());
        // Start streaming download in background worker and wait only for initial chunk (~8KB)
        bool streamStarted = downloadHeadFileNative(fileIdHex, headPath.c_str());
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

        // If file finished immediately, use LocalFileDataSource, else ProgressiveFileDataSource
        if (::stat(headPath.c_str(), &st) == 0 && st.st_size >= 512) {
            primarySource = std::make_unique<LocalFileDataSource>(headPath.c_str());
        } else {
            primarySource = std::make_unique<ProgressiveFileDataSource>(partPath.c_str());
        }
    }

    // Load primary head source via dual-source architecture.
    // If fullTrackUrl is not yet resolved, primary plays immediately (< 30ms TTFA)
    // while attachSecondaryStream can be invoked concurrently.
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
            mSecondaryPending.store(true, std::memory_order_release);
        }
        mDecoderEndOfStream.store(false, std::memory_order_release);
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
    mIsEncryptedSource = false;
    mIsDualSource.store(true, std::memory_order_release);
    if (secondaryUrl && secondaryUrl[0] != '\0') {
        mSecondaryPending.store(true, std::memory_order_release);
    }
    mSecondaryReady.store(false, std::memory_order_release);
    mSecondaryFailed.store(false, std::memory_order_release);
    mHandoffCompleted.store(false, std::memory_order_release);
    mHandoffTargetMs.store(handoffPositionMs, std::memory_order_release);

    mState.store(EngineState::Loading, std::memory_order_release);

    EngineStatus status = primarySource->open();
    if (status != EngineStatus::Ok) {
        LOGE("Primary source open failed: %d", static_cast<int>(status));
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    mSampleRate = primarySource->getSampleRate();
    mSourceChannelCount = primarySource->getChannelCount();
    // Chunk 0 Ogg head only spans ~6.5s; keep track duration un-authoritative until MP4 opens.
    const int64_t primaryHeadDurMs = std::max<int64_t>(0, primarySource->getDurationUs() / 1000);
    mPrimaryDurationMs.store(primaryHeadDurMs, std::memory_order_release);
    mPendingSeekOverrideMs.store(-1, std::memory_order_release);
    mPrimarySeekInvalidated.store(false, std::memory_order_release);
    mDurationMs.store(trackDurationMs > 0 ? trackDurationMs : 0, std::memory_order_release);
    mDurationAuthoritative.store(false, std::memory_order_release);

    int64_t maxFramesToDecode = -1;
    if (handoffPositionMs > 0 && mSampleRate > 0) {
        maxFramesToDecode = (handoffPositionMs * mSampleRate) / 1000;
    }

    LOGI("Primary source opened: sr=%d cc=%d headDurMs=%lld handoffTargetMs=%lld maxFrames=%lld",
         mSampleRate, mSourceChannelCount, static_cast<long long>(primarySource->getDurationUs() / 1000),
         static_cast<long long>(handoffPositionMs), static_cast<long long>(maxFramesToDecode));

    // 2. Configure Primary Decoder
    auto primaryDecoder = std::make_unique<NativeDecoder>(
        mRingBuffer,
        primarySource->getExtractor(),
        primarySource->getMimeType(),
        primarySource->getTrackFormat(),
        mSourceChannelCount,
        nullptr,
        maxFramesToDecode);

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

    // 3. Open Oboe Stream
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
    mDecoderEndOfStream.store(false, std::memory_order_relaxed);

    mState.store(EngineState::Prebuffering, std::memory_order_release);

    // 4. Start primary decoder immediately for ultra-low TTFA (< 50ms)
    status = mPrimaryDecoder->start();
    if (status != EngineStatus::Ok) {
        LOGE("Primary decoder start failed: %d", static_cast<int>(status));
        std::shared_ptr<oboe::AudioStream> streamToClose;
        {
            std::lock_guard<std::mutex> lock(mStreamMutex);
            streamToClose = std::move(mStream);
        }
        if (streamToClose) streamToClose->close();
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
            mSecondaryWorkerShouldStop.store(true, std::memory_order_release);
            mSecondaryWorkerThread.join();
        }
        mSecondaryWorkerShouldStop.store(false, std::memory_order_release);
        mSecondaryWorkerThread = std::thread(
            &AudioEngine::secondaryWorkerFunc,
            this,
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
    mIsEncryptedSource = true;
    mIsDualSource.store(false, std::memory_order_release);
    mSecondaryPending.store(false, std::memory_order_release);
    mSecondaryReady.store(false, std::memory_order_release);
    mSecondaryFailed.store(false, std::memory_order_release);
    mHandoffCompleted.store(false, std::memory_order_release);
    mHandoffTargetMs.store(-1, std::memory_order_release);
    mHandoffActualMs.store(0, std::memory_order_release);

    mState.store(EngineState::Loading, std::memory_order_release);

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

    EngineStatus status = source->open();
    if (status != EngineStatus::Ok) {
        LOGE("Encrypted stream data source open failed: %d", static_cast<int>(status));
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    mSampleRate = source->getSampleRate();
    mSourceChannelCount = source->getChannelCount();
    const int64_t durMs = source->getDurationUs() / 1000;
    mDurationMs.store(durMs, std::memory_order_release);
    mDurationAuthoritative.store(durMs > 0, std::memory_order_release);

    if (mSampleRate <= 0 || mSourceChannelCount <= 0) {
        LOGE("Invalid format for encrypted stream: sr=%d cc=%d", mSampleRate, mSourceChannelCount);
        source->close();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return EngineStatus::ErrorCodec;
    }

    LOGI("Encrypted source opened: sr=%d cc=%d dur=%lldms mime=%s",
         mSampleRate, mSourceChannelCount, static_cast<long long>(durMs), source->getMimeType());

    AMediaCrypto* crypto = nullptr;
    if (source->hasWidevinePssh() || (licenseServerUrl && licenseServerUrl[0] != '\0')) {
        LOGI("Encrypted stream requires Widevine DRM key exchange (licenseUrl=%s)",
             licenseServerUrl ? licenseServerUrl : "null");
        std::vector<uint8_t> psshData = source->getPsshBytes();
        if (psshData.empty()) {
            const char* audioPattern = "/audio/";
            const char* match = std::strstr(url, audioPattern);
            if (!match) {
                audioPattern = "/head/";
                match = std::strstr(url, audioPattern);
            }
            if (match) {
                const char* hexStart = match + std::strlen(audioPattern);
                bool isHex = true;
                for (int i = 0; i < 40; ++i) {
                    char c = hexStart[i];
                    if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'))) {
                        isHex = false;
                        break;
                    }
                }
                if (isHex) {
                    uint8_t fileId[20];
                    for (int i = 0; i < 20; ++i) {
                        char byteHex[3] = { hexStart[i * 2], hexStart[i * 2 + 1], '\0' };
                        fileId[i] = static_cast<uint8_t>(std::strtoul(byteHex, nullptr, 16));
                    }
                    std::vector<uint8_t> payload;
                    payload.push_back(0x08);
                    payload.push_back(0x01);
                    payload.push_back(0x12);
                    payload.push_back(16);
                    payload.insert(payload.end(), fileId, fileId + 16);
                    const char* provider = "spotify";
                    payload.push_back(0x1a);
                    payload.push_back(static_cast<uint8_t>(std::strlen(provider)));
                    payload.insert(payload.end(), provider, provider + std::strlen(provider));
                    payload.push_back(0x22);
                    payload.push_back(20);
                    payload.insert(payload.end(), fileId, fileId + 20);

                    uint32_t protectionScheme = 0x63626373;
                    int32_t cryptoMode = 0;
                    if (source->getTrackFormat() && AMediaFormat_getInt32(source->getTrackFormat(), "crypto-mode", &cryptoMode)) {
                        if (cryptoMode == 1) protectionScheme = 0x63656e63;
                        else if (cryptoMode == 2) protectionScheme = 0x63626373;
                    }
                    payload.push_back(0x48);
                    uint32_t val = protectionScheme;
                    while (val > 0x7F) {
                        payload.push_back(static_cast<uint8_t>((val & 0x7F) | 0x80));
                        val >>= 7;
                    }
                    payload.push_back(static_cast<uint8_t>(val & 0x7F));

                    uint32_t totalSize = 32 + static_cast<uint32_t>(payload.size());
                    psshData.reserve(totalSize);
                    psshData.push_back((totalSize >> 24) & 0xFF);
                    psshData.push_back((totalSize >> 16) & 0xFF);
                    psshData.push_back((totalSize >> 8) & 0xFF);
                    psshData.push_back(totalSize & 0xFF);
                    psshData.push_back('p'); psshData.push_back('s'); psshData.push_back('s'); psshData.push_back('h');
                    psshData.push_back(0x00); psshData.push_back(0x00); psshData.push_back(0x00); psshData.push_back(0x00);
                    psshData.insert(psshData.end(), kWidevineUuid, kWidevineUuid + 16);
                    uint32_t dataLen = static_cast<uint32_t>(payload.size());
                    psshData.push_back((dataLen >> 24) & 0xFF);
                    psshData.push_back((dataLen >> 16) & 0xFF);
                    psshData.push_back((dataLen >> 8) & 0xFF);
                    psshData.push_back(dataLen & 0xFF);
                    psshData.insert(psshData.end(), payload.begin(), payload.end());
                }
            }
        }

        crypto = acquireWidevineCrypto(psshData,
                                       licenseServerUrl ? std::string(licenseServerUrl) : std::string(),
                                       authHeader ? std::string(authHeader) : std::string());
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
        -1);

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
    mDecoderEndOfStream.store(false, std::memory_order_relaxed);

    mState.store(EngineState::Prebuffering, std::memory_order_release);

    status = mDecoder->start();
    if (status != EngineStatus::Ok) {
        LOGE("Encrypted stream decoder start failed: %d", static_cast<int>(status));
        std::shared_ptr<oboe::AudioStream> streamToClose;
        {
            std::lock_guard<std::mutex> lock(mStreamMutex);
            streamToClose = std::move(mStream);
        }
        if (streamToClose) streamToClose->close();
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

    if (!mIsDualSource.load(std::memory_order_acquire)) {
        LOGW("attachSecondaryStream: not in dual source mode");
        return EngineStatus::ErrorInvalidState;
    }

    if (mHandoffCompleted.load(std::memory_order_acquire)) {
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
        mSecondaryWorkerShouldStop.store(true, std::memory_order_release);
        cancelAllActiveSources();
        mSecondaryWorkerThread.join();
    }

    mSecondaryPending.store(true, std::memory_order_release);
    mSecondaryReady.store(false, std::memory_order_release);
    mSecondaryFailed.store(false, std::memory_order_release);
    mSecondaryWorkerShouldStop.store(false, std::memory_order_release);
    mDecoderEndOfStream.store(false, std::memory_order_release);

    mSecondaryWorkerThread = std::thread(
        &AudioEngine::secondaryWorkerFunc,
        this,
        std::move(urls),
        licenseServerUrl ? std::string(licenseServerUrl) : std::string(),
        authHeader ? std::string(authHeader) : std::string(),
        handoffPositionMs,
        std::move(urlRefreshCb)
    );

    // If monitor thread exited or is not running, ensure it is active
    if (!mMonitorThread.joinable()) {
        mMonitorShouldStop.store(false, std::memory_order_release);
        mMonitorThread = std::thread(&AudioEngine::decoderMonitorFunc, this);
    }

    return EngineStatus::Ok;
}

// ===========================================================================
// Background Secondary Loader & DRM Negotiator
// ===========================================================================

void AudioEngine::secondaryWorkerFunc(std::vector<std::string> secondaryUrls,
                                      std::string licenseServerUrl,
                                      std::string authHeader,
                                      int64_t handoffMs,
                                      spotify::network::UrlRefreshCallback urlRefreshCb) {
    if (secondaryUrls.empty()) {
        failSecondary("Secondary URL list is empty");
        return;
    }
    const std::string& secondaryUrl = secondaryUrls.front();
    LOGI("Secondary worker started for URL: %s", secondaryUrl.c_str());

    auto secSource = std::make_unique<HttpMediaDataSource>(
        std::move(secondaryUrls), authHeader.c_str(), std::move(urlRefreshCb));

    {
        std::lock_guard<std::mutex> lock(mSourceCancelMutex);
        mOpeningSecondarySource = secSource.get();
    }
    EngineStatus status = secSource->open();
    {
        std::lock_guard<std::mutex> lock(mSourceCancelMutex);
        mOpeningSecondarySource = nullptr;
    }

    if (mSecondaryWorkerShouldStop.load(std::memory_order_acquire)) {
        secSource->close();
        mSecondaryPending.store(false, std::memory_order_release);
        return;
    }
    if (status != EngineStatus::Ok) {
        failSecondary("Secondary remote source open failed: " + std::to_string(static_cast<int>(status)));
        secSource->close();
        return;
    }

    // Update authoritative container duration (both up and down vs metadata hint).
    const int64_t secDurUs = secSource->getDurationUs();
    if (secDurUs > 0) {
        const int64_t secDurMs = secDurUs / 1000;
        mDurationMs.store(secDurMs, std::memory_order_release);
        mDurationAuthoritative.store(true, std::memory_order_release);
        LOGI("Authoritative container duration from secondary MP4: %lld ms",
             static_cast<long long>(secDurMs));
        notifyStateChanged(mState.load(std::memory_order_acquire));
    }

    AMediaCrypto* crypto = nullptr;
    if (secSource->hasWidevinePssh() || !licenseServerUrl.empty()) {
        LOGI("Secondary source requires Widevine DRM key exchange (licenseUrl=%s)", licenseServerUrl.c_str());
        std::vector<uint8_t> psshData = secSource->getPsshBytes();
        if (psshData.empty()) {
            LOGW("secSource returned empty PSSH bytes, attempting fallback derivation from secondaryUrl");
            const char* audioPattern = "/audio/";
            const char* match = std::strstr(secondaryUrl.c_str(), audioPattern);
            if (!match) {
                audioPattern = "/head/";
                match = std::strstr(secondaryUrl.c_str(), audioPattern);
            }
            if (match) {
                const char* hexStart = match + std::strlen(audioPattern);
                bool isHex = true;
                for (int i = 0; i < 40; ++i) {
                    char c = hexStart[i];
                    if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'))) {
                        isHex = false;
                        break;
                    }
                }
                if (isHex) {
                    uint8_t fileId[20];
                    for (int i = 0; i < 20; ++i) {
                        char byteHex[3] = { hexStart[i * 2], hexStart[i * 2 + 1], '\0' };
                        fileId[i] = static_cast<uint8_t>(std::strtoul(byteHex, nullptr, 16));
                    }
                    std::vector<uint8_t> payload;
                    // Field 1: algorithm = 1 (AES_CTR)
                    payload.push_back(0x08);
                    payload.push_back(0x01);

                    // Field 2: key_id
                    payload.push_back(0x12);
                    payload.push_back(16);
                    payload.insert(payload.end(), fileId, fileId + 16);

                    // Field 3: provider = "spotify"
                    const char* provider = "spotify";
                    payload.push_back(0x1a);
                    payload.push_back(static_cast<uint8_t>(std::strlen(provider)));
                    payload.insert(payload.end(), provider, provider + std::strlen(provider));

                    // Field 4: content_id
                    payload.push_back(0x22);
                    payload.push_back(20);
                    payload.insert(payload.end(), fileId, fileId + 20);

                    // Dynamically detect protection scheme from secondary source track format:
                    uint32_t protectionScheme = 0x63626373; // Default 'cbcs'
                    int32_t cryptoMode = 0;
                    if (secSource->getTrackFormat() && AMediaFormat_getInt32(secSource->getTrackFormat(), "crypto-mode", &cryptoMode)) {
                        if (cryptoMode == 1) {
                            protectionScheme = 0x63656e63; // 'cenc'
                        } else if (cryptoMode == 2) {
                            protectionScheme = 0x63626373; // 'cbcs'
                        }
                    }

                    // Field 9: protection_scheme (0x63626373 for 'cbcs', 0x63656e63 for 'cenc')
                    payload.push_back(0x48); // (9 << 3) | 0
                    uint32_t val = protectionScheme;
                    while (val > 0x7F) {
                        payload.push_back(static_cast<uint8_t>((val & 0x7F) | 0x80));
                        val >>= 7;
                    }
                    payload.push_back(static_cast<uint8_t>(val & 0x7F));

                    uint32_t totalSize = 32 + static_cast<uint32_t>(payload.size());
                    psshData.reserve(totalSize);
                    psshData.push_back((totalSize >> 24) & 0xFF);
                    psshData.push_back((totalSize >> 16) & 0xFF);
                    psshData.push_back((totalSize >> 8) & 0xFF);
                    psshData.push_back(totalSize & 0xFF);
                    psshData.push_back('p'); psshData.push_back('s'); psshData.push_back('s'); psshData.push_back('h');
                    psshData.push_back(0x00); psshData.push_back(0x00); psshData.push_back(0x00); psshData.push_back(0x00);
                    psshData.insert(psshData.end(), kWidevineUuid, kWidevineUuid + 16);
                    uint32_t dataLen = static_cast<uint32_t>(payload.size());
                    psshData.push_back((dataLen >> 24) & 0xFF);
                    psshData.push_back((dataLen >> 16) & 0xFF);
                    psshData.push_back((dataLen >> 8) & 0xFF);
                    psshData.push_back(dataLen & 0xFF);
                    psshData.insert(psshData.end(), payload.begin(), payload.end());
                }
            }
        }

        crypto = acquireWidevineCrypto(psshData, licenseServerUrl, authHeader);
        if (!crypto) {
            failSecondary("Widevine license acquisition failed (see MusifyDrmManager logs)");
            secSource->close();
            return;
        }
        mSecondaryCrypto = crypto;
        LOGI("Widevine crypto successfully acquired and attached to secondary decoder: %p", crypto);
    }

    if (mSecondaryWorkerShouldStop.load(std::memory_order_acquire)) {
        secSource->close();
        mSecondaryPending.store(false, std::memory_order_release);
        return;
    }

    if (secSource->getSampleRate() != mSampleRate) {
        failSecondary("Secondary sample rate " + std::to_string(secSource->getSampleRate()) +
                      " differs from primary " + std::to_string(mSampleRate) +
                      "; ring buffer has no resampler");
        secSource->close();
        return;
    }

    const int64_t seekOverride = mPendingSeekOverrideMs.load(std::memory_order_acquire);
    int64_t handoffUs = handoffMs * 1000LL;
    if (seekOverride >= 0 || mPrimarySeekInvalidated.load(std::memory_order_acquire)) {
        // Wait until decoderMonitorFunc stops mPrimaryDecoder and resets mRingBuffer.
        while (mPrimarySeekInvalidated.load(std::memory_order_acquire)) {
            if (mSecondaryWorkerShouldStop.load(std::memory_order_acquire)) {
                secSource->close();
                mSecondaryPending.store(false, std::memory_order_release);
                return;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        const int64_t latestOverride = mPendingSeekOverrideMs.load(std::memory_order_acquire);
        handoffUs = (latestOverride >= 0 ? latestOverride : 0) * 1000LL;
    } else if (handoffMs <= 0 && mPrimaryDecoder) {
        // RingBuffer is single-producer: the secondary decoder must not start until the
        // primary has committed its final frame or a user seek supersedes Chunk 0.
        while (!mPrimaryDecoder->isEndOfStream() &&
               !mPrimarySeekInvalidated.load(std::memory_order_acquire) &&
               mPendingSeekOverrideMs.load(std::memory_order_acquire) < 0) {
            if (mSecondaryWorkerShouldStop.load(std::memory_order_acquire)) {
                secSource->close();
                mSecondaryPending.store(false, std::memory_order_release);
                return;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        while (mPrimarySeekInvalidated.load(std::memory_order_acquire)) {
            if (mSecondaryWorkerShouldStop.load(std::memory_order_acquire)) {
                secSource->close();
                mSecondaryPending.store(false, std::memory_order_release);
                return;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(2));
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
    const int64_t targetSeekMs = handoffUs / 1000LL;

    const int64_t secOriginUs = AMediaExtractor_getSampleTime(secSource->getExtractor());
    const int64_t adjustedHandoffUs =
        (handoffUs > 0 && secOriginUs > 0 && secOriginUs < 1000000LL)
            ? (handoffUs + secOriginUs)
            : handoffUs;

    if (adjustedHandoffUs > 0) {
        // Use AMEDIAEXTRACTOR_SEEK_PREVIOUS_SYNC to ensure seek lands at or before target.
        // NativeDecoder trims exact pre-roll frames up to adjustedHandoffUs.
        media_status_t seekStatus = AMediaExtractor_seekTo(
            secSource->getExtractor(), adjustedHandoffUs, AMEDIAEXTRACTOR_SEEK_PREVIOUS_SYNC);
        int64_t actualPtsUs = AMediaExtractor_getSampleTime(secSource->getExtractor());
        LOGI("Secondary extractor pre-seeked: target=%lld us (origin=%lld us), actualPts=%lld us (status=%d)",
             static_cast<long long>(adjustedHandoffUs),
             static_cast<long long>(secOriginUs),
             static_cast<long long>(actualPtsUs),
             static_cast<int>(seekStatus));
    }

    // Prepare Secondary Decoder (standing by in memory) with exact handoff boundary pre-roll discard
    auto secDecoder = std::make_unique<NativeDecoder>(
        mRingBuffer,
        secSource->getExtractor(),
        secSource->getMimeType(),
        secSource->getTrackFormat(),
        secSource->getChannelCount(),
        mSecondaryCrypto,
        -1, // Secondary plays until EOF
        adjustedHandoffUs // Discard pre-roll prior to handoff boundary
    );

    status = secDecoder->configure();
    if (status != EngineStatus::Ok) {
        failSecondary("Secondary decoder configure failed: " + std::to_string(static_cast<int>(status)));
        secSource->close();
        return;
    }

    // Start secondary decoder immediately in worker thread so it fills mRingBuffer ahead of time.
    // Since mPrimaryDecoder has finished decoding chunk 0, there is zero contention on mRingBuffer.
    EngineStatus startStatus = secDecoder->start();
    if (startStatus != EngineStatus::Ok) {
        failSecondary("Secondary decoder failed to start: " + std::to_string(static_cast<int>(startStatus)));
        secSource->close();
        return;
    }

    mHandoffActualMs.store(targetSeekMs, std::memory_order_release);
    {
        std::lock_guard<std::mutex> lock(mSourceCancelMutex);
        mSecondarySource = std::move(secSource);
    }
    mSecondaryDecoder = std::move(secDecoder);
    mSecondaryReady.store(true, std::memory_order_release);
    mSecondaryPending.store(false, std::memory_order_release);
    mHandoffCompleted.store(true, std::memory_order_release);
    mDecoderEndOfStream.store(false, std::memory_order_release);
    LOGI("Seamless dual-source handoff initiated: secondary decoder actively buffering ahead at %lld ms",
         static_cast<long long>(targetSeekMs));
}

AMediaCrypto* AudioEngine::acquireWidevineCrypto(const std::vector<uint8_t>& psshData,
                                                const std::string& licenseServerUrl,
                                                const std::string& authHeader) {
    if (!sJavaVm || psshData.empty() || licenseServerUrl.empty()) {
        LOGE("Cannot acquire Widevine crypto: sJavaVm=%p psshLen=%zu licenseUrlEmpty=%d",
             sJavaVm, psshData.size(), licenseServerUrl.empty() ? 1 : 0);
        return nullptr;
    }

    JNIEnv* env = nullptr;
    bool didAttach = false;
    jint getEnvRes = sJavaVm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
    if (getEnvRes == JNI_EDETACHED) {
        if (sJavaVm->AttachCurrentThread(&env, nullptr) == JNI_OK) {
            didAttach = true;
        }
    }

    if (!env) {
        LOGE("Failed to obtain JNIEnv for DRM negotiation");
        return nullptr;
    }

    jclass bridgeClass = sDrmBridgeClass;
    jmethodID acquireMethod = sAcquireSessionMethod;
    bool needsDeleteLocal = false;

    // Fallback: if not cached in JNI_OnLoad, resolve via Application ClassLoader
    if (!bridgeClass && sClassLoader && sLoadClassMethod) {
        jstring jclassName = env->NewStringUTF("um.musify.mu.musify_mu.NativeDrmBridge");
        jclass loadedClass = static_cast<jclass>(env->CallObjectMethod(sClassLoader, sLoadClassMethod, jclassName));
        env->DeleteLocalRef(jclassName);
        if (env->ExceptionCheck()) {
            env->ExceptionClear();
        } else if (loadedClass) {
            bridgeClass = loadedClass;
            acquireMethod = env->GetStaticMethodID(
                bridgeClass,
                "acquireSession",
                "([BLjava/lang/String;Ljava/lang/String;)[B");
            if (env->ExceptionCheck()) {
                env->ExceptionClear();
            }
            needsDeleteLocal = true;
        }
    }

    if (!bridgeClass || !acquireMethod) {
        LOGE("NativeDrmBridge class or method not found (cls=%p, method=%p)", bridgeClass, acquireMethod);
        if (didAttach) sJavaVm->DetachCurrentThread();
        return nullptr;
    }

    jbyteArray jpssh = env->NewByteArray(static_cast<jsize>(psshData.size()));
    env->SetByteArrayRegion(jpssh, 0, static_cast<jsize>(psshData.size()),
                            reinterpret_cast<const jbyte*>(psshData.data()));
    jstring jurl = env->NewStringUTF(licenseServerUrl.c_str());
    jstring jauth = authHeader.empty() ? nullptr : env->NewStringUTF(authHeader.c_str());

    jbyteArray jSessionId = static_cast<jbyteArray>(
        env->CallStaticObjectMethod(bridgeClass, acquireMethod, jpssh, jurl, jauth));
    if (env->ExceptionCheck()) {
        LOGE("Java exception occurred during acquireSession");
        env->ExceptionClear();
        jSessionId = nullptr;
    }

    AMediaCrypto* crypto = nullptr;
    if (jSessionId) {
        jsize sessionLen = env->GetArrayLength(jSessionId);
        jbyte* sessionBytes = env->GetByteArrayElements(jSessionId, nullptr);
        if (sessionBytes && sessionLen > 0) {
            mActiveDrmSessionId.assign(reinterpret_cast<const uint8_t*>(sessionBytes),
                                       reinterpret_cast<const uint8_t*>(sessionBytes) + sessionLen);
            crypto = AMediaCrypto_new(
                kWidevineUuid,
                reinterpret_cast<const void*>(sessionBytes),
                static_cast<size_t>(sessionLen));
            LOGI("AMediaCrypto_new created crypto instance: %p", crypto);
            env->ReleaseByteArrayElements(jSessionId, sessionBytes, JNI_ABORT);
        }
        env->DeleteLocalRef(jSessionId);
    } else {
        LOGE("NativeDrmBridge.acquireSession returned null sessionId");
    }

    env->DeleteLocalRef(jpssh);
    env->DeleteLocalRef(jurl);
    if (jauth) env->DeleteLocalRef(jauth);
    if (needsDeleteLocal) {
        env->DeleteLocalRef(bridgeClass);
    }

    if (didAttach) {
        sJavaVm->DetachCurrentThread();
    }

    return crypto;
}

void AudioEngine::closeActiveDrmSession() {
    if (mActiveDrmSessionId.empty()) {
        return;
    }

    if (!sJavaVm) {
        mActiveDrmSessionId.clear();
        return;
    }

    JNIEnv* env = nullptr;
    bool didAttach = false;
    jint getEnvRes = sJavaVm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
    if (getEnvRes == JNI_EDETACHED) {
        if (sJavaVm->AttachCurrentThread(&env, nullptr) == JNI_OK) {
            didAttach = true;
        }
    }

    if (env) {
        jclass bridgeClass = sDrmBridgeClass;
        jmethodID closeMethod = sCloseSessionMethod;
        bool needsDeleteLocal = false;

        if (!bridgeClass && sClassLoader && sLoadClassMethod) {
            jstring jclassName = env->NewStringUTF("um.musify.mu.musify_mu.NativeDrmBridge");
            jclass loadedClass = static_cast<jclass>(env->CallObjectMethod(sClassLoader, sLoadClassMethod, jclassName));
            env->DeleteLocalRef(jclassName);
            if (env->ExceptionCheck()) {
                env->ExceptionClear();
            } else if (loadedClass) {
                bridgeClass = loadedClass;
                closeMethod = env->GetStaticMethodID(bridgeClass, "closeSession", "([B)V");
                if (env->ExceptionCheck()) env->ExceptionClear();
                needsDeleteLocal = true;
            }
        }

        if (bridgeClass && closeMethod) {
            jbyteArray jSession = env->NewByteArray(static_cast<jsize>(mActiveDrmSessionId.size()));
            env->SetByteArrayRegion(jSession, 0, static_cast<jsize>(mActiveDrmSessionId.size()),
                                   reinterpret_cast<const jbyte*>(mActiveDrmSessionId.data()));
            env->CallStaticVoidMethod(bridgeClass, closeMethod, jSession);
            if (env->ExceptionCheck()) {
                env->ExceptionClear();
            }
            env->DeleteLocalRef(jSession);
            LOGI("NativeDrmBridge.closeSession successfully executed from C++ AudioEngine");
        }

        if (needsDeleteLocal) {
            env->DeleteLocalRef(bridgeClass);
        }
        if (didAttach) {
            sJavaVm->DetachCurrentThread();
        }
    }

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
    mIsEncryptedSource = false;
    mIsDualSource.store(false, std::memory_order_release);
    mSecondaryReady.store(false, std::memory_order_release);
    mSecondaryFailed.store(false, std::memory_order_release);
    mHandoffCompleted.store(false, std::memory_order_release);
    mHandoffTargetMs.store(-1, std::memory_order_release);
    mHandoffActualMs.store(0, std::memory_order_release);

    mState.store(EngineState::Loading, std::memory_order_release);

    EngineStatus status = source->open();
    if (status != EngineStatus::Ok) {
        LOGE("Data source open failed: %d", static_cast<int>(status));
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    mSampleRate = source->getSampleRate();
    mSourceChannelCount = source->getChannelCount();
    const int64_t durMs = source->getDurationUs() / 1000;
    mDurationMs.store(durMs, std::memory_order_release);
    mDurationAuthoritative.store(durMs > 0, std::memory_order_release);

    if (mSampleRate <= 0 || mSourceChannelCount <= 0) {
        LOGE("Invalid format: sr=%d cc=%d", mSampleRate, mSourceChannelCount);
        source->close();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return EngineStatus::ErrorCodec;
    }

    LOGI("Source opened: sr=%d cc=%d dur=%lldms mime=%s",
         mSampleRate, mSourceChannelCount,
         static_cast<long long>(durMs), source->getMimeType());

    auto decoder = std::make_unique<NativeDecoder>(
        mRingBuffer,
        source->getExtractor(),
        source->getMimeType(),
        source->getTrackFormat(),
        mSourceChannelCount,
        nullptr,
        -1);

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
    mDecoderEndOfStream.store(false, std::memory_order_relaxed);

    mState.store(EngineState::Prebuffering, std::memory_order_release);

    status = mDecoder->start();
    if (status != EngineStatus::Ok) {
        LOGE("Decoder start failed: %d", static_cast<int>(status));
        std::shared_ptr<oboe::AudioStream> streamToClose;
        {
            std::lock_guard<std::mutex> lock(mStreamMutex);
            streamToClose = std::move(mStream);
        }
        if (streamToClose) streamToClose->close();
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
        const EngineState currentState = mState.load(std::memory_order_acquire);

        // 1. Prebuffering watermark detection (initial load, seek, or stall recovery)
        if (currentState == EngineState::Prebuffering) {
            emptyRingTicks = 0;
            const bool waitingForPendingSeekSecondary =
                mIsDualSource.load(std::memory_order_acquire) &&
                !mHandoffCompleted.load(std::memory_order_acquire) &&
                (mPrimarySeekInvalidated.load(std::memory_order_acquire) ||
                 mPendingSeekOverrideMs.load(std::memory_order_acquire) >= 0);
            const size_t available = mRingBuffer.availableToRead();
            bool eos = false;
            if (mIsDualSource.load(std::memory_order_relaxed)) {
                if (mHandoffCompleted.load(std::memory_order_relaxed)) {
                    eos = mSecondaryDecoder && mSecondaryDecoder->isEndOfStream();
                } else {
                    eos = mPrimaryDecoder && mPrimaryDecoder->isEndOfStream() &&
                          !mSecondaryPending.load(std::memory_order_acquire) &&
                          !mSecondaryWorkerThread.joinable();
                }
            } else {
                eos = mDecoder && mDecoder->isEndOfStream();
            }

            const size_t watermark = static_cast<size_t>(mSampleRate) * 25 / 1000;

            if (!waitingForPendingSeekSecondary &&
                (available >= watermark || (eos && available > 0))) {
                NativeDecoder* activeDec = mIsDualSource.load(std::memory_order_relaxed)
                    ? (mHandoffCompleted.load(std::memory_order_relaxed)
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
                const bool shouldAutoPlay = mAutoPlay.load(std::memory_order_acquire);
                const EngineState targetState =
                    shouldAutoPlay ? EngineState::Playing : EngineState::Paused;
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
        if (mIsDualSource.load(std::memory_order_acquire)) {
            const bool dropPrimaryForSeek = mPrimarySeekInvalidated.load(std::memory_order_acquire);
            if (mSecondaryReady.load(std::memory_order_acquire) || dropPrimaryForSeek) {
                bool releasedPrimary = false;
                if (mPrimaryDecoder) {
                    mPrimaryDecoder->stop();
                    mPrimaryDecoder.reset();
                    std::unique_ptr<IAudioDataSource> primaryToClose;
                    {
                        std::lock_guard<std::mutex> lock(mSourceCancelMutex);
                        primaryToClose = std::move(mPrimarySource);
                    }
                    if (primaryToClose) primaryToClose->close();
                    releasedPrimary = true;
                }
                if (dropPrimaryForSeek) {
                    mRingBuffer.reset();
                    mPrimarySeekInvalidated.store(false, std::memory_order_release);
                    LOGI("Invalidated Chunk 0 primary decoder for pre-handoff seek");
                } else if (releasedPrimary) {
                    LOGI("Primary decoder resources safely released after handoff to secondary");
                }
            } else if (mSecondaryFailed.load(std::memory_order_acquire)) {
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
                    std::this_thread::sleep_for(std::chrono::milliseconds(10));
                    continue;
                }
            } else if (mPrimaryDecoder && mPrimaryDecoder->isEndOfStream() &&
                       !mSecondaryWorkerThread.joinable() &&
                       !mSecondaryPending.load(std::memory_order_acquire)) {
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
                    std::this_thread::sleep_for(std::chrono::milliseconds(10));
                    continue;
                }
            }
        }

        // 3. Propagate EOS flag to Oboe callback
        if (mIsDualSource.load(std::memory_order_relaxed)) {
            if (mHandoffCompleted.load(std::memory_order_relaxed)) {
                const bool secEos = mSecondaryDecoder && mSecondaryDecoder->isEndOfStream();
                mDecoderEndOfStream.store(secEos, std::memory_order_release);
            } else if (!mSecondaryPending.load(std::memory_order_acquire) &&
                       !mSecondaryWorkerThread.joinable() &&
                       mPrimaryDecoder && mPrimaryDecoder->isEndOfStream()) {
                mDecoderEndOfStream.store(true, std::memory_order_release);
            } else {
                mDecoderEndOfStream.store(false, std::memory_order_release);
            }
        } else {
            const bool singleEos = mDecoder && mDecoder->isEndOfStream();
            mDecoderEndOfStream.store(singleEos, std::memory_order_release);
        }

        // 4. Mid-stream stall detection: freeze hardware clock cleanly instead of spinning underruns
        //    so UI playback_speed drops to 0.0 during network stalls or Chunk-0->MP4 gaps.
        if (mState.load(std::memory_order_acquire) == EngineState::Playing) {
            if (mRingBuffer.availableToRead() == 0 &&
                !mDecoderEndOfStream.load(std::memory_order_acquire)) {
                if (++emptyRingTicks >= 15) {
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
            if (!mEosNotified.exchange(true, std::memory_order_acq_rel)) {
                LOGI("AudioEngine: EOS reached, scheduling EOS dispatcher");
                bool hasEosCallback = false;
                {
                    std::lock_guard<std::mutex> lock(mEosMutex);
                    hasEosCallback = static_cast<bool>(mEosCallback);
                    mEosPending = true;
                }
                // Only broadcast Stopped to observers immediately when no EOS owner is
                // attached; otherwise the EOS handler decides between advancing vs stopping
                // without flashing an intermediate Stopped state to UI.
                if (!hasEosCallback) {
                    notifyStateChanged(EngineState::Stopped);
                }
                mEosCv.notify_one();
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(20));
            continue;
        }

        if (afterState == EngineState::Faulted || afterState == EngineState::Idle) {
            break;
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(
            afterState == EngineState::Prebuffering ? 1 : 2));
    }
}

// ===========================================================================
// Oboe stream setup
// ===========================================================================

EngineStatus AudioEngine::openOboeStream() {
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
    mAutoPlay.store(true, std::memory_order_release);
    const EngineState current = mState.load(std::memory_order_acquire);
    if (current == EngineState::Paused || current == EngineState::Stopped) {
        mState.store(EngineState::Playing, std::memory_order_release);
        startOrReopenOboeStream();
        notifyStateChanged(EngineState::Playing);
        return EngineStatus::Ok;
    }
    if (current == EngineState::Playing ||
        current == EngineState::Prebuffering ||
        current == EngineState::Loading) {
        return EngineStatus::Ok;
    }
    return EngineStatus::ErrorInvalidState;
}

EngineStatus AudioEngine::pause() {
    mAutoPlay.store(false, std::memory_order_release);
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
    if (!mIsDualSource.load(std::memory_order_relaxed) && knownDurMs > 0 && positionMs > knownDurMs) {
        return EngineStatus::ErrorInvalidArg;
    }

    // Abort stale background read-ahead transfers immediately so seek range requests
    // own the pooled HTTP/2 connection and bandwidth without head-of-line stalling.
    {
        std::lock_guard<std::mutex> lock(mSourceCancelMutex);
        if (mDataSource) mDataSource->preemptPrefetch();
        if (mPrimarySource) mPrimarySource->preemptPrefetch();
        if (mSecondarySource) mSecondarySource->preemptPrefetch();
    }

    // Move Playing -> Prebuffering before resetting mRingBuffer so Oboe outputs clean
    // digital silence without hitting emptyRingTicks + requestPause()/requestStart() HAL latency.
    if (current == EngineState::Playing) {
        mState.store(EngineState::Prebuffering, std::memory_order_release);
    }

    mSeekPositionMs.store(positionMs, std::memory_order_release);
    mFramesConsumedByHardware.store(0, std::memory_order_release);
    mDecoderEndOfStream.store(false, std::memory_order_release);
    mEosNotified.store(false, std::memory_order_release);
    mRingBuffer.reset();

    bool waitingForPendingSecondary = false;
    if (mIsDualSource.load(std::memory_order_acquire)) {
        const int64_t primaryDurMs = mPrimaryDurationMs.load(std::memory_order_acquire);
        if (mHandoffCompleted.load(std::memory_order_acquire)) {
            if (mSecondaryDecoder) {
                mSecondaryDecoder->requestSeek(positionMs * 1000);
            }
        } else if (primaryDurMs > 0 && positionMs < primaryDurMs && mPrimaryDecoder) {
            mPendingSeekOverrideMs.store(-1, std::memory_order_release);
            mPrimaryDecoder->requestSeek(positionMs * 1000);
        } else if (mSecondaryDecoder) {
            mSecondaryDecoder->requestSeek(positionMs * 1000);
        } else {
            // Seek landed past Chunk 0 while secondary MP4 is still opening:
            // steer secondaryWorkerFunc to open directly at positionMs and pause audio until buffered.
            mPendingSeekOverrideMs.store(positionMs, std::memory_order_release);
            mPrimarySeekInvalidated.store(true, std::memory_order_release);
            {
                std::lock_guard<std::mutex> lock(mSourceCancelMutex);
                if (mPrimarySource) {
                    mPrimarySource->cancel();
                }
            }
            waitingForPendingSecondary = mSecondaryPending.load(std::memory_order_acquire) ||
                                         mSecondaryWorkerThread.joinable();
        }
    } else {
        if (mDecoder) {
            mDecoder->requestSeek(positionMs * 1000);
        }
    }

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
            mAutoPlay.load(std::memory_order_acquire) ? EngineState::Prebuffering : EngineState::Paused;
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
    mIsEncryptedSource = true;
    mIsDualSource.store(false, std::memory_order_release);

    auto source = std::make_unique<EncryptedStreamDataSource>(totalSize, key16, iv16);
    return loadSource(std::move(source));
}

EngineStatus AudioEngine::pushStreamChunk(int64_t offset,
                                           const uint8_t* data,
                                           int32_t length) {
    if (!mIsEncryptedSource || !mDataSource) {
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
    if (mDurationAuthoritative.load(std::memory_order_acquire) && durMs > 0 && posMs > durMs) {
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
    if (mWasUnderrun && framesRead > 0) {
        constexpr size_t kRampUpFrames = 64;
        const size_t ramp = std::min(kRampUpFrames, framesRead);
        for (size_t i = 0; i < ramp; ++i) {
            const float gain = static_cast<float>(i + 1) / static_cast<float>(ramp);
            const size_t idx = i * RingBuffer::kChannelCount;
            output[idx]     *= gain;
            output[idx + 1] *= gain;
        }
        mWasUnderrun = false;
    }

    if (framesRead < requestedFrames) {
        const bool eos = mDecoderEndOfStream.load(std::memory_order_acquire);

        if (eos && mRingBuffer.availableToRead() == 0) {
            std::memset(output + framesRead * RingBuffer::kChannelCount, 0,
                        (requestedFrames - framesRead) * RingBuffer::kChannelCount * sizeof(float));
            mFramesConsumedByHardware.fetch_add(
                static_cast<int64_t>(framesRead), std::memory_order_relaxed);
            mState.store(EngineState::Stopped, std::memory_order_release);
            return oboe::DataCallbackResult::Stop;
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

        mWasUnderrun = true;
        int32_t count = mUnderrunCount.fetch_add(1, std::memory_order_relaxed) + 1;
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
