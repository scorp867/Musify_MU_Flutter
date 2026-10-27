#include "AudioEngine.h"

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
static jclass sHeadDownloaderClass = nullptr;
static jmethodID sDownloadHeadMethod = nullptr;
static jclass sDrmBridgeClass = nullptr;
static jmethodID sAcquireSessionMethod = nullptr;
static jmethodID sCloseSessionMethod = nullptr;
static jobject sClassLoader = nullptr;
static jmethodID sLoadClassMethod = nullptr;

extern "C" JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* /*reserved*/) {
    sJavaVm = vm;
    LOGI("AudioEngine JNI_OnLoad registered");

    JNIEnv* env = nullptr;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK || !env) {
        LOGE("JNI_OnLoad: failed to get JNIEnv");
        return JNI_VERSION_1_6;
    }

    // 1. Cache NativeHeadDownloader class and method
    jclass localHead = env->FindClass("um/musify/mu/musify_mu/NativeHeadDownloader");
    if (localHead) {
        sHeadDownloaderClass = reinterpret_cast<jclass>(env->NewGlobalRef(localHead));
        sDownloadHeadMethod = env->GetStaticMethodID(
            sHeadDownloaderClass,
            "downloadHeadFile",
            "(Ljava/lang/String;Ljava/lang/String;)Z");
        env->DeleteLocalRef(localHead);
        LOGI("NativeHeadDownloader cached (cls=%p, method=%p)", sHeadDownloaderClass, sDownloadHeadMethod);
    } else {
        LOGE("Failed to find NativeHeadDownloader in JNI_OnLoad");
        if (env->ExceptionCheck()) env->ExceptionClear();
    }

    // 2. Cache NativeDrmBridge class and methods
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

    // 3. Cache Application ClassLoader as universal fallback for background threads
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
        if (sHeadDownloaderClass) env->DeleteGlobalRef(sHeadDownloaderClass);
        if (sDrmBridgeClass) env->DeleteGlobalRef(sDrmBridgeClass);
        if (sClassLoader) env->DeleteGlobalRef(sClassLoader);
    }
}

// ===========================================================================
// Construction / Destruction
// ===========================================================================

AudioEngine::AudioEngine() {
    mState.store(EngineState::Idle, std::memory_order_release);
}

AudioEngine::~AudioEngine() {
    stopPlayback();
}

// ===========================================================================
// Internal: stop all playback components
// ===========================================================================

void AudioEngine::stopPlayback() {
    mMonitorShouldStop.store(true, std::memory_order_release);
    mSecondaryWorkerShouldStop.store(true, std::memory_order_release);

    if (mSecondaryWorkerThread.joinable()) {
        mSecondaryWorkerThread.join();
    }

    if (mStream) {
        mStream->requestStop();
        mStream->close();
        mStream.reset();
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

    if (mSecondaryCrypto) {
        AMediaCrypto_delete(mSecondaryCrypto);
        mSecondaryCrypto = nullptr;
    }

    if (mMonitorThread.joinable()) {
        mMonitorThread.join();
    }

    if (mDataSource) {
        mDataSource->close();
        mDataSource.reset();
    }

    if (mPrimarySource) {
        mPrimarySource->close();
        mPrimarySource.reset();
    }

    if (mSecondarySource) {
        mSecondarySource->close();
        mSecondarySource.reset();
    }

    mRingBuffer.reset();

    mIsDualSource.store(false, std::memory_order_release);
    mSecondaryReady.store(false, std::memory_order_release);
    mSecondaryFailed.store(false, std::memory_order_release);
    mHandoffCompleted.store(false, std::memory_order_release);
    mHandoffTargetMs.store(-1, std::memory_order_release);
    mHandoffActualMs.store(0, std::memory_order_release);
}

// ===========================================================================
// Control: loadLocal
// ===========================================================================

EngineStatus AudioEngine::loadLocal(const char* filePath) {
    if (!filePath || filePath[0] == '\0') {
        return EngineStatus::ErrorInvalidArg;
    }

    stopPlayback();
    mIsEncryptedSource = false;
    mIsDualSource.store(false, std::memory_order_release);

    std::unique_ptr<IAudioDataSource> source;
    if (std::strncmp(filePath, "http://", 7) == 0 || std::strncmp(filePath, "https://", 8) == 0) {
        source = std::make_unique<HttpMediaDataSource>(filePath);
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
                                            const char* authHeader) {
    if (!fileIdHex || fileIdHex[0] == '\0') {
        return EngineStatus::ErrorInvalidArg;
    }

    std::string headPath;
    if (cacheDir && cacheDir[0] != '\0') {
        headPath = std::string(cacheDir) + "/heads/" + std::string(fileIdHex) + ".ogg";
    } else {
        headPath = std::string("/data/data/um.musify.mu.musify_mu/cache/heads/") + std::string(fileIdHex) + ".ogg";
    }

    // 1. Ensure head file is cached or downloaded natively in C++
    bool downloaded = downloadHeadFileNative(fileIdHex, headPath.c_str());
    if (!downloaded) {
        LOGE("Native head file download failed for %s", fileIdHex);
        if (fullTrackUrl && fullTrackUrl[0] != '\0') {
            LOGI("Falling back to full track stream: %s", fullTrackUrl);
            if (licenseServerUrl && licenseServerUrl[0] != '\0') {
                return loadDualSource(fullTrackUrl, fullTrackUrl, licenseServerUrl, authHeader, -1);
            }
            return loadLocal(fullTrackUrl);
        }
        return EngineStatus::ErrorIO;
    }

    // If no full track URL is provided, play the head file chunk directly
    if (!fullTrackUrl || fullTrackUrl[0] == '\0') {
        LOGI("Head chunk ready at %s. No secondary track URL provided; playing head chunk directly.", headPath.c_str());
        return loadLocal(headPath.c_str());
    }

    LOGI("Head chunk ready at %s. Starting dual-decoder handoff with full stream: %s",
         headPath.c_str(), fullTrackUrl);

    // 2. Start dual source:
    // Primary = headPath (128 KB OGG chunk 0, decoded via AMediaCodec/libvorbis for < 30ms TTFA)
    // Secondary = fullTrackUrl (AAC/MP4 stream pre-buffered via AMediaCodec in background worker)
    // handoffPositionMs = -1 (natural EOF of chunk 0, executing seamless sample-accurate PCM handoff)
    return loadDualSource(headPath.c_str(), fullTrackUrl, licenseServerUrl, authHeader, -1);
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
    if (!fileIdHex || !targetFilePath) return false;

    // Ensure parent directory exists
    std::string dirPath = targetFilePath;
    size_t lastSlash = dirPath.find_last_of('/');
    if (lastSlash != std::string::npos) {
        std::string dir = dirPath.substr(0, lastSlash);
        mkdir(dir.c_str(), 0755);
    }

    // Check if target file already exists and has valid header size (>= 512 bytes)
    struct stat st;
    if (stat(targetFilePath, &st) == 0) {
        if (st.st_size >= 512) {
            LOGI("Head file cache HIT for %s (%s, size=%lld)", fileIdHex, targetFilePath, (long long)st.st_size);
            return true;
        } else {
            LOGW("Head file corrupt (size=%lld < 512), purging: %s", (long long)st.st_size, targetFilePath);
            unlink(targetFilePath);
        }
    }

    if (!sJavaVm) {
        LOGE("Cannot download head file: sJavaVm is null");
        return false;
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
        LOGE("Failed to obtain JNIEnv for head download");
        return false;
    }

    jclass bridgeClass = sHeadDownloaderClass;
    jmethodID downloadMethod = sDownloadHeadMethod;
    bool needsDeleteLocal = false;

    // Fallback: if not cached in JNI_OnLoad, resolve via Application ClassLoader
    if (!bridgeClass && sClassLoader && sLoadClassMethod) {
        jstring jclassName = env->NewStringUTF("um.musify.mu.musify_mu.NativeHeadDownloader");
        jclass loadedClass = static_cast<jclass>(env->CallObjectMethod(sClassLoader, sLoadClassMethod, jclassName));
        env->DeleteLocalRef(jclassName);
        if (env->ExceptionCheck()) {
            env->ExceptionClear();
        } else if (loadedClass) {
            bridgeClass = loadedClass;
            downloadMethod = env->GetStaticMethodID(
                bridgeClass,
                "downloadHeadFile",
                "(Ljava/lang/String;Ljava/lang/String;)Z");
            if (env->ExceptionCheck()) {
                env->ExceptionClear();
            }
            needsDeleteLocal = true;
        }
    }

    if (!bridgeClass || !downloadMethod) {
        LOGE("NativeHeadDownloader class or method not found (cls=%p, method=%p)", bridgeClass, downloadMethod);
        if (didAttach) sJavaVm->DetachCurrentThread();
        return false;
    }

    jstring jFileId = env->NewStringUTF(fileIdHex);
    jstring jPath = env->NewStringUTF(targetFilePath);

    jboolean success = env->CallStaticBooleanMethod(bridgeClass, downloadMethod, jFileId, jPath);
    if (env->ExceptionCheck()) {
        LOGE("Java exception occurred during downloadHeadFile for %s", fileIdHex);
        env->ExceptionClear();
        success = JNI_FALSE;
    }

    env->DeleteLocalRef(jFileId);
    env->DeleteLocalRef(jPath);
    if (needsDeleteLocal) {
        env->DeleteLocalRef(bridgeClass);
    }

    if (didAttach) {
        sJavaVm->DetachCurrentThread();
    }

    return static_cast<bool>(success);
}

// ===========================================================================
// Control: loadDualSource
// ===========================================================================

EngineStatus AudioEngine::loadDualSource(const char* primaryPath,
                                        const char* secondaryUrl,
                                        const char* licenseServerUrl,
                                        const char* authHeader,
                                        int64_t handoffPositionMs) {
    if (!primaryPath || primaryPath[0] == '\0' || !secondaryUrl || secondaryUrl[0] == '\0') {
        return EngineStatus::ErrorInvalidArg;
    }

    stopPlayback();
    mIsEncryptedSource = false;
    mIsDualSource.store(true, std::memory_order_release);
    mSecondaryReady.store(false, std::memory_order_release);
    mSecondaryFailed.store(false, std::memory_order_release);
    mHandoffCompleted.store(false, std::memory_order_release);
    mHandoffTargetMs.store(handoffPositionMs, std::memory_order_release);

    mState.store(EngineState::Loading, std::memory_order_release);

    // 1. Open Primary source (Clear OGG)
    std::unique_ptr<IAudioDataSource> primarySource;
    if (std::strncmp(primaryPath, "http://", 7) == 0 || std::strncmp(primaryPath, "https://", 8) == 0) {
        primarySource = std::make_unique<HttpMediaDataSource>(primaryPath);
    } else {
        primarySource = std::make_unique<LocalFileDataSource>(primaryPath);
    }

    EngineStatus status = primarySource->open();
    if (status != EngineStatus::Ok) {
        LOGE("Primary source open failed: %d", static_cast<int>(status));
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    mSampleRate = primarySource->getSampleRate();
    mSourceChannelCount = primarySource->getChannelCount();
    mDurationMs = primarySource->getDurationUs() / 1000;

    int64_t maxFramesToDecode = -1;
    if (handoffPositionMs > 0 && mSampleRate > 0) {
        maxFramesToDecode = (handoffPositionMs * mSampleRate) / 1000;
    }

    LOGI("Primary source opened: sr=%d cc=%d dur=%lldms handoffTargetMs=%lld maxFrames=%lld",
         mSampleRate, mSourceChannelCount, static_cast<long long>(mDurationMs),
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

    mPrimarySource = std::move(primarySource);
    mPrimaryDecoder = std::move(primaryDecoder);

    // 3. Open Oboe Stream
    status = openOboeStream();
    if (status != EngineStatus::Ok) {
        LOGE("Oboe stream open failed: %d", static_cast<int>(status));
        mPrimaryDecoder->stop();
        mPrimaryDecoder.reset();
        mPrimarySource->close();
        mPrimarySource.reset();
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
        mStream->close();
        mStream.reset();
        mPrimaryDecoder.reset();
        mPrimarySource->close();
        mPrimarySource.reset();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    // 5. Start background worker for Secondary (AAC DRM CDN stream)
    mSecondaryWorkerShouldStop.store(false, std::memory_order_release);
    mSecondaryWorkerThread = std::thread(
        &AudioEngine::secondaryWorkerFunc,
        this,
        std::string(secondaryUrl),
        licenseServerUrl ? std::string(licenseServerUrl) : std::string(),
        authHeader ? std::string(authHeader) : std::string(),
        handoffPositionMs
    );

    // 6. Start monitor thread
    mMonitorShouldStop.store(false, std::memory_order_release);
    mMonitorThread = std::thread(&AudioEngine::decoderMonitorFunc, this);

    return EngineStatus::Ok;
}

// ===========================================================================
// Background Secondary Loader & DRM Negotiator
// ===========================================================================

void AudioEngine::secondaryWorkerFunc(std::string secondaryUrl,
                                      std::string licenseServerUrl,
                                      std::string authHeader,
                                      int64_t handoffMs) {
    LOGI("Secondary worker started for URL: %s", secondaryUrl.c_str());

    auto secSource = std::make_unique<HttpMediaDataSource>(secondaryUrl.c_str(), authHeader.c_str());
    EngineStatus status = secSource->open();
    if (status != EngineStatus::Ok) {
        LOGE("Secondary remote source open failed: %d", static_cast<int>(status));
        mSecondaryFailed.store(true, std::memory_order_release);
        return;
    }

    if (mSecondaryWorkerShouldStop.load(std::memory_order_acquire)) {
        secSource->close();
        return;
    }

    // Update total track duration if secondary provides the full track duration
    int64_t secDurMs = secSource->getDurationUs() / 1000;
    if (secDurMs > mDurationMs) {
        mDurationMs = secDurMs;
    }

    AMediaCrypto* crypto = nullptr;
    if (secSource->hasWidevinePssh()) {
        LOGI("Secondary source requires Widevine DRM key exchange");
        crypto = acquireWidevineCrypto(secSource->getPsshBytes(), licenseServerUrl, authHeader);
        if (!crypto) {
            LOGE("Failed to acquire Widevine crypto session after retries");
            mSecondaryFailed.store(true, std::memory_order_release);
            secSource->close();
            return;
        }
        mSecondaryCrypto = crypto;
    }

    if (mSecondaryWorkerShouldStop.load(std::memory_order_acquire)) {
        secSource->close();
        return;
    }

    // Prepare Secondary Decoder (standing by in memory)
    auto secDecoder = std::make_unique<NativeDecoder>(
        mRingBuffer,
        secSource->getExtractor(),
        secSource->getMimeType(),
        secSource->getTrackFormat(),
        secSource->getChannelCount(),
        mSecondaryCrypto,
        -1 // Secondary plays until EOF
    );

    status = secDecoder->configure();
    if (status != EngineStatus::Ok) {
        LOGE("Secondary decoder configure failed: %d", static_cast<int>(status));
        mSecondaryFailed.store(true, std::memory_order_release);
        secSource->close();
        return;
    }

    if (handoffMs > 0) {
        secDecoder->requestSeek(handoffMs * 1000);
    }

    mSecondarySource = std::move(secSource);
    mSecondaryDecoder = std::move(secDecoder);
    mSecondaryReady.store(true, std::memory_order_release);
    LOGI("Secondary decoder ready and primed for handoff");
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
    mState.store(EngineState::Loading, std::memory_order_release);

    EngineStatus status = source->open();
    if (status != EngineStatus::Ok) {
        LOGE("Data source open failed: %d", static_cast<int>(status));
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    mSampleRate = source->getSampleRate();
    mSourceChannelCount = source->getChannelCount();
    mDurationMs = source->getDurationUs() / 1000;

    if (mSampleRate <= 0 || mSourceChannelCount <= 0) {
        LOGE("Invalid format: sr=%d cc=%d", mSampleRate, mSourceChannelCount);
        source->close();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return EngineStatus::ErrorCodec;
    }

    LOGI("Source opened: sr=%d cc=%d dur=%lldms mime=%s",
         mSampleRate, mSourceChannelCount,
         static_cast<long long>(mDurationMs), source->getMimeType());

    auto decoder = std::make_unique<NativeDecoder>(
        mRingBuffer,
        source->getExtractor(),
        source->getMimeType(),
        source->getTrackFormat(),
        mSourceChannelCount);

    status = decoder->configure();
    if (status != EngineStatus::Ok) {
        LOGE("Decoder configure failed: %d", static_cast<int>(status));
        source->close();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    mDataSource = std::move(source);
    mDecoder = std::move(decoder);

    status = openOboeStream();
    if (status != EngineStatus::Ok) {
        LOGE("Oboe stream open failed: %d", static_cast<int>(status));
        mDecoder->stop();
        mDecoder.reset();
        mDataSource->close();
        mDataSource.reset();
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
        mStream->close();
        mStream.reset();
        mDecoder.reset();
        mDataSource->close();
        mDataSource.reset();
        mState.store(EngineState::Faulted, std::memory_order_release);
        return status;
    }

    mMonitorShouldStop.store(false, std::memory_order_release);
    mMonitorThread = std::thread(&AudioEngine::decoderMonitorFunc, this);

    return EngineStatus::Ok;
}

// ===========================================================================
// Monitor thread: watermark detection, dual-decoder handoff, and faulting
// ===========================================================================

void AudioEngine::decoderMonitorFunc() {
    bool watermarkReached = false;

    while (!mMonitorShouldStop.load(std::memory_order_acquire)) {
        const EngineState currentState = mState.load(std::memory_order_acquire);

        // Prebuffering watermark detection
        if (!watermarkReached && currentState == EngineState::Prebuffering) {
            const size_t available = mRingBuffer.availableToRead();
            bool eos = false;
            if (mIsDualSource.load(std::memory_order_relaxed)) {
                eos = mPrimaryDecoder && mPrimaryDecoder->isEndOfStream();
            } else {
                eos = mDecoder && mDecoder->isEndOfStream();
            }

            const size_t watermark = static_cast<size_t>(mSampleRate) * 80 / 1000;

            if (available >= watermark || (eos && available > 0)) {
                watermarkReached = true;
                mState.store(EngineState::Playing, std::memory_order_release);

                if (mStream) {
                    oboe::Result result = mStream->requestStart();
                    if (result != oboe::Result::OK) {
                        LOGE("Oboe requestStart failed: %d", static_cast<int>(result));
                        mState.store(EngineState::Faulted, std::memory_order_release);
                    } else {
                        LOGI("Playback started (watermark reached: %zu frames)", available);
                    }
                }
            }
        }

        // Dual-source handoff monitoring
        if (mIsDualSource.load(std::memory_order_acquire) &&
            !mHandoffCompleted.load(std::memory_order_acquire)) {

            if (mPrimaryDecoder && mPrimaryDecoder->isEndOfStream()) {
                // Primary decoder finished its segment. Check if secondary is ready.
                if (mSecondaryReady.load(std::memory_order_acquire)) {
                    int64_t primaryFrames = mPrimaryDecoder->getDecodedFrames();
                    int64_t actualHandoffMs = 0;
                    if (mSampleRate > 0) {
                        actualHandoffMs = (primaryFrames * 1000) / mSampleRate;
                    }
                    mHandoffActualMs.store(actualHandoffMs, std::memory_order_release);

                    if (mHandoffTargetMs.load(std::memory_order_relaxed) <= 0) {
                        // Natural EOF handoff: seek secondary to actual ending point of primary
                        mSecondaryDecoder->requestSeek(actualHandoffMs * 1000);
                    }

                    EngineStatus startStatus = mSecondaryDecoder->start();
                    if (startStatus == EngineStatus::Ok) {
                        mHandoffCompleted.store(true, std::memory_order_release);
                        LOGI("Seamless dual-source handoff executed at %lld ms (frames=%lld)",
                             static_cast<long long>(actualHandoffMs), static_cast<long long>(primaryFrames));

                        // Safely release primary decoder resources
                        mPrimaryDecoder->stop();
                        mPrimaryDecoder.reset();
                        if (mPrimarySource) {
                            mPrimarySource->close();
                            mPrimarySource.reset();
                        }
                    } else {
                        LOGE("Secondary decoder failed to start during handoff");
                        mSecondaryFailed.store(true, std::memory_order_release);
                    }
                } else if (mSecondaryFailed.load(std::memory_order_acquire)) {
                    // Secondary source / DRM failed after retries.
                    // Let RingBuffer drain existing frames, then pause safely at boundary.
                    if (mRingBuffer.availableToRead() == 0) {
                        LOGE("Pausing at handoff boundary due to secondary source/DRM failure");
                        if (mStream) mStream->requestPause();
                        mState.store(EngineState::Faulted, std::memory_order_release);
                        break;
                    }
                }
            }
        }

        // Propagate EOS for terminal audio callback
        if (mIsDualSource.load(std::memory_order_relaxed)) {
            if (mHandoffCompleted.load(std::memory_order_relaxed) &&
                mSecondaryDecoder && mSecondaryDecoder->isEndOfStream()) {
                mDecoderEndOfStream.store(true, std::memory_order_release);
            }
        } else {
            if (mDecoder && mDecoder->isEndOfStream()) {
                mDecoderEndOfStream.store(true, std::memory_order_release);
            }
        }

        if (currentState == EngineState::Faulted || currentState == EngineState::Idle) {
            break;
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(2));
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

    oboe::Result result = builder.openStream(mStream);
    if (result != oboe::Result::OK) {
        LOGE("openStream failed: %d", static_cast<int>(result));
        return EngineStatus::ErrorStream;
    }

    mStream->setBufferSizeInFrames(mStream->getFramesPerBurst() * 2);

    LOGI("Oboe stream opened: sr=%d burst=%d bufSize=%d",
         mStream->getSampleRate(),
         mStream->getFramesPerBurst(),
         mStream->getBufferSizeInFrames());

    return EngineStatus::Ok;
}

// ===========================================================================
// Control: play / pause / seekMs
// ===========================================================================

EngineStatus AudioEngine::play() {
    const EngineState current = mState.load(std::memory_order_acquire);
    if (current == EngineState::Paused || current == EngineState::Stopped) {
        mState.store(EngineState::Playing, std::memory_order_release);
        if (mStream) {
            mStream->requestStart();
        }
        return EngineStatus::Ok;
    }
    if (current == EngineState::Playing) {
        return EngineStatus::Ok;
    }
    return EngineStatus::ErrorInvalidState;
}

EngineStatus AudioEngine::pause() {
    const EngineState current = mState.load(std::memory_order_acquire);
    if (current == EngineState::Playing) {
        mState.store(EngineState::Paused, std::memory_order_release);
        if (mStream) {
            mStream->requestPause();
        }
        return EngineStatus::Ok;
    }
    if (current == EngineState::Paused || current == EngineState::Stopped) {
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

    // In dual-source mode, primary duration may only reflect the 128 KiB head file (~6.5s).
    // Allow seeking across full duration if secondary stream is active or duration is unknown.
    if (!mIsDualSource.load(std::memory_order_relaxed) && mDurationMs > 0 && positionMs > mDurationMs) {
        return EngineStatus::ErrorInvalidArg;
    }

    mSeekPositionMs.store(positionMs, std::memory_order_relaxed);
    mFramesConsumedByHardware.store(0, std::memory_order_relaxed);
    mDecoderEndOfStream.store(false, std::memory_order_relaxed);

    if (mIsDualSource.load(std::memory_order_acquire)) {
        int64_t actualHandoff = mHandoffActualMs.load(std::memory_order_relaxed);
        if (mHandoffCompleted.load(std::memory_order_relaxed) || positionMs >= actualHandoff) {
            if (mSecondaryDecoder) {
                mSecondaryDecoder->requestSeek(positionMs * 1000);
            }
        } else {
            if (mPrimaryDecoder) {
                mPrimaryDecoder->requestSeek(positionMs * 1000);
            } else if (mSecondaryDecoder) {
                mSecondaryDecoder->requestSeek(positionMs * 1000);
            }
        }
    } else {
        if (mDecoder) {
            mDecoder->requestSeek(positionMs * 1000);
        }
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
    const int64_t consumed = mFramesConsumedByHardware.load(std::memory_order_relaxed);
    const int64_t seekBase = mSeekPositionMs.load(std::memory_order_relaxed);
    if (mSampleRate <= 0) return seekBase;
    return seekBase + (consumed * 1000 / mSampleRate);
}

int64_t AudioEngine::getDurationMs() const {
    return mDurationMs;
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

    if (framesRead < requestedFrames) {
        const bool eos = mDecoderEndOfStream.load(std::memory_order_acquire);

        if (eos && mRingBuffer.availableToRead() == 0) {
            std::memset(output + framesRead * RingBuffer::kChannelCount, 0,
                        (requestedFrames - framesRead) * RingBuffer::kChannelCount * sizeof(float));
            mFramesConsumedByHardware.fetch_add(
                static_cast<int64_t>(framesRead), std::memory_order_relaxed);
            mState.store(EngineState::Stopped, std::memory_order_release);
            return oboe::DataCallbackResult::Continue;
        }

        // Apply 32-frame linear ramp-down on underrun to prevent click/pop
        constexpr size_t kRampFrames = 32;
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

        mUnderrunCount.fetch_add(1, std::memory_order_relaxed);
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
            mStream->requestStart();
        }
    }
}
