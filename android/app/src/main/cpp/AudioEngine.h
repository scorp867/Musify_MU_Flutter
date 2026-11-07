#pragma once

#include <atomic>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include <media/NdkMediaCrypto.h>
#include <oboe/Oboe.h>

#include "DataSource.h"
#include "NativeDecoder.h"
#include "RingBuffer.h"

/// Top-level native audio engine orchestrating the full pipeline:
///   DataSource -> NativeDecoder -> RingBuffer -> Oboe real-time output
///
/// State machine: Uninitialized -> Idle -> Loading -> Prebuffering -> Playing <-> Paused -> Stopped
///                                                                  | (on fault)
///                                                                  v
///                                                               Faulted
class AudioEngine : public oboe::AudioStreamDataCallback,
                    public oboe::AudioStreamErrorCallback {
public:
    using EosCallback = std::function<void()>;
    using SecondaryFailureCallback = std::function<void(const std::string& reason)>;

    AudioEngine();
    ~AudioEngine();

    AudioEngine(const AudioEngine&) = delete;
    AudioEngine& operator=(const AudioEngine&) = delete;

    /// Register callback invoked when playback naturally finishes and ring buffer drains (EOS).
    void setEosCallback(EosCallback cb);

    /// Register callback invoked when the background full-track stream fails to attach
    /// (storage open, Widevine license exchange, sample-rate mismatch, decoder start).
    void setSecondaryFailureCallback(SecondaryFailureCallback cb);

    /// Configure whether reaching the prebuffer watermark automatically starts Oboe output.
    void setAutoPlay(bool autoPlay);

    /// Stop active decoders, Oboe stream, and worker threads and reset state to Idle.
    void stop();

    /// Load a local audio file or direct HTTP URL. Transitions: * -> Loading -> Prebuffering.
    EngineStatus loadLocal(const char* filePath);

    /// Load Spotify track with native chunk 0 head file resolution and download in C++.
    EngineStatus loadTrackWithHead(const char* fileIdHex,
                                   const char* fullTrackUrl,
                                   const char* cacheDir,
                                   const char* licenseServerUrl = nullptr,
                                   const char* authHeader = nullptr,
                                   int64_t trackDurationMs = -1);

    /// Asynchronously prefetch the 128 KiB chunk 0 head file into local storage.
    void prefetchHead(const char* fileIdHex, const char* cacheDir);

    /// Download or verify a Chunk 0 head file synchronously (unblocking once initial 8 KiB is ready).
    static bool downloadHeadFileNative(const char* fileIdHex, const char* targetFilePath);

    /// Load dual sources: fast preview (OGG) + background DRM CDN track (AAC).
    EngineStatus loadDualSource(const char* primaryPath,
                                const char* secondaryUrl,
                                const char* licenseServerUrl,
                                const char* authHeader,
                                int64_t handoffPositionMs);

    EngineStatus loadDualSource(std::unique_ptr<IAudioDataSource> primarySource,
                                const char* secondaryUrl,
                                const char* licenseServerUrl,
                                const char* authHeader,
                                int64_t handoffPositionMs);

    /// Load a single encrypted audio stream directly (Widevine AAC/FLAC without Vorbis head chunk).
    EngineStatus loadEncryptedStream(const char* url,
                                    const char* licenseServerUrl,
                                    const char* authHeader);

    /// Asynchronously attaches or starts the secondary full-track stream while primary is already playing.
    EngineStatus attachSecondaryStream(const char* secondaryUrl,
                                       const char* licenseServerUrl,
                                       const char* authHeader,
                                       int64_t handoffPositionMs = -1);

    /// Set DRM session ID directly if negotiated externally.
    EngineStatus setDrmSessionId(const uint8_t* sessionId, int32_t sessionLen);

    /// Initialise an encrypted stream source.
    EngineStatus initEncryptedStream(int64_t totalSize,
                                     const uint8_t* key16,
                                     const uint8_t* iv16);

    /// Push an encrypted chunk into the stream data source.
    EngineStatus pushStreamChunk(int64_t offset,
                                 const uint8_t* data,
                                 int32_t length);

    /// Resume / start playback. Transitions: Paused -> Playing.
    EngineStatus play();

    /// Pause playback. Transitions: Playing -> Paused.
    EngineStatus pause();

    /// Seek to an absolute position in milliseconds.
    EngineStatus seekMs(int64_t positionMs);

    // -----------------------------------------------------------------------
    // Telemetry API
    // -----------------------------------------------------------------------

    int64_t getPositionMs() const;
    int64_t getDurationMs() const;
    int32_t getState() const;
    int32_t getUnderrunCount() const;
    bool isDualSource() const { return mIsDualSource.load(std::memory_order_relaxed); }
    bool isHandoffCompleted() const { return mHandoffCompleted.load(std::memory_order_relaxed); }

    // -----------------------------------------------------------------------
    // Oboe callbacks
    // -----------------------------------------------------------------------

    oboe::DataCallbackResult onAudioReady(
        oboe::AudioStream* stream,
        void* audioData,
        int32_t numFrames) override;

    void onErrorAfterClose(
        oboe::AudioStream* stream,
        oboe::Result error) override;

private:
    void stopPlayback();
    EngineStatus loadSource(std::unique_ptr<IAudioDataSource> source);
    EngineStatus openOboeStream();
    void decoderMonitorFunc();
    void secondaryWorkerFunc(std::string secondaryUrl,
                             std::string licenseServerUrl,
                             std::string authHeader,
                             int64_t handoffMs);
    AMediaCrypto* acquireWidevineCrypto(const std::vector<uint8_t>& psshData,
                                        const std::string& licenseServerUrl,
                                        const std::string& authHeader);
    void closeActiveDrmSession();
    void failSecondary(const std::string& reason);

    // --- State ---
    std::atomic<EngineState> mState{EngineState::Uninitialized};
    std::atomic<bool> mAutoPlay{true};

    // --- Audio pipeline components ---
    RingBuffer mRingBuffer;
    std::unique_ptr<IAudioDataSource> mDataSource;
    std::unique_ptr<NativeDecoder> mDecoder;
    std::shared_ptr<oboe::AudioStream> mStream;

    // --- Dual-decoder components ---
    std::unique_ptr<IAudioDataSource> mPrimarySource;
    std::unique_ptr<NativeDecoder> mPrimaryDecoder;
    std::unique_ptr<HttpMediaDataSource> mSecondarySource;
    std::unique_ptr<NativeDecoder> mSecondaryDecoder;
    AMediaCrypto* mSecondaryCrypto{nullptr};
    std::vector<uint8_t> mActiveDrmSessionId;

    std::atomic<bool> mIsDualSource{false};
    std::atomic<bool> mSecondaryPending{false};
    std::atomic<bool> mSecondaryReady{false};
    std::atomic<bool> mSecondaryFailed{false};
    std::atomic<bool> mHandoffCompleted{false};
    std::atomic<int64_t> mHandoffTargetMs{-1};
    std::atomic<int64_t> mHandoffActualMs{0};

    std::thread mSecondaryWorkerThread;
    std::atomic<bool> mSecondaryWorkerShouldStop{false};

    // --- Format info ---
    int32_t mSampleRate{48000};
    int32_t mSourceChannelCount{2};
    int64_t mDurationMs{0};

    // --- Position tracking ---
    std::atomic<int64_t> mFramesConsumedByHardware{0};
    std::atomic<int64_t> mSeekPositionMs{0};

    // --- Telemetry ---
    std::atomic<int32_t> mUnderrunCount{0};

    // --- Decoder-to-Oboe watermark handoff ---
    static constexpr size_t kStartWatermarkFrames = 3840; // 80 ms @ 48 kHz
    std::atomic<bool> mDecoderEndOfStream{false};
    std::thread mMonitorThread;
    std::atomic<bool> mMonitorShouldStop{false};
    bool mIsEncryptedSource{false};
    bool mWasUnderrun{false};  // Tracks underrun state for symmetric ramp-up on recovery

    // --- EOS Notification Callback ---
    std::mutex mEosMutex;
    EosCallback mEosCallback;
    SecondaryFailureCallback mSecondaryFailureCallback;
    std::atomic<bool> mEosNotified{false};
};
