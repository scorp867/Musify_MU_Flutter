#pragma once

#include <atomic>
#include <cstdint>
#include <memory>
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
///
/// Thread model:
///   - Main/FFI thread: loadLocal, loadDualSource, play, pause, seekMs, getters
///   - Decoder thread(s): fills RingBuffer from AMediaCodec (Primary & Secondary)
///   - Background worker: negotiates Widevine DRM and primes SecondaryDecoder
///   - Audio callback thread (Oboe): drains RingBuffer to hardware
class AudioEngine : public oboe::AudioStreamDataCallback,
                    public oboe::AudioStreamErrorCallback {
public:
    AudioEngine();
    ~AudioEngine();

    AudioEngine(const AudioEngine&) = delete;
    AudioEngine& operator=(const AudioEngine&) = delete;

    // -----------------------------------------------------------------------
    // Control API (called from Dart FFI / main thread)
    // -----------------------------------------------------------------------

    /// Load a local audio file. Transitions: * -> Loading -> Prebuffering.
    EngineStatus loadLocal(const char* filePath);

    /// Load Spotify track with native chunk 0 head file resolution & download in C++.
    /// Downloads/caches the 128 KiB head file directly, begins playback immediately (< 30ms TTFA),
    /// and seamlessly hands over to the full track MP4 stream via AMediaCodec without audio glitch.
    EngineStatus loadTrackWithHead(const char* fileIdHex,
                                   const char* fullTrackUrl,
                                   const char* cacheDir,
                                   const char* licenseServerUrl = nullptr,
                                   const char* authHeader = nullptr);

    /// Asynchronously prefetch the 128 KiB chunk 0 head file into local storage.
    void prefetchHead(const char* fileIdHex, const char* cacheDir);

    /// Load dual sources: fast preview (OGG) + background DRM CDN track (AAC).
    /// handoffPositionMs: Target handoff in ms, or -1 for natural stream EOF (Option C).
    EngineStatus loadDualSource(const char* primaryPath,
                                const char* secondaryUrl,
                                const char* licenseServerUrl,
                                const char* authHeader,
                                int64_t handoffPositionMs);

    /// Set DRM session ID directly from Dart/Kotlin if negotiated externally.
    EngineStatus setDrmSessionId(const uint8_t* sessionId, int32_t sessionLen);

    /// Initialise an encrypted stream source. Currently returns ErrorIO.
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
    // Telemetry API (called from Dart FFI polling timer)
    // -----------------------------------------------------------------------

    int64_t getPositionMs() const;
    int64_t getDurationMs() const;
    int32_t getState() const;
    int32_t getUnderrunCount() const;
    bool isDualSource() const { return mIsDualSource.load(std::memory_order_relaxed); }
    bool isHandoffCompleted() const { return mHandoffCompleted.load(std::memory_order_relaxed); }

    // -----------------------------------------------------------------------
    // Oboe callbacks (called from real-time audio thread)
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
    static bool downloadHeadFileNative(const char* fileIdHex, const char* targetFilePath);

    // --- State ---
    std::atomic<EngineState> mState{EngineState::Uninitialized};

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

    std::atomic<bool> mIsDualSource{false};
    std::atomic<bool> mSecondaryReady{false};
    std::atomic<bool> mSecondaryFailed{false};
    std::atomic<bool> mHandoffCompleted{false};
    std::atomic<int64_t> mHandoffTargetMs{-1};
    std::atomic<int64_t> mHandoffActualMs{0};

    std::thread mSecondaryWorkerThread;
    std::atomic<bool> mSecondaryWorkerShouldStop{false};

    // --- Format info (set during loadSource, immutable afterwards) ---
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
};
