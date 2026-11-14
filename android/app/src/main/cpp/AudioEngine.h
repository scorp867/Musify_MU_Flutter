#pragma once

#include <atomic>
#include <condition_variable>
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
    using StateCallback = std::function<void(EngineState state)>;

    /// Scoped, reference-counted cancellation token per track/secondary load session.
    /// Eliminates shared boolean flags across overlapping track transitions and closes
    /// the TOCTOU window between cancelPendingLoads() and source->open().
    class LoadSessionToken final : public std::enable_shared_from_this<LoadSessionToken> {
    public:
        void cancel() noexcept {
            mCancelled.store(true, std::memory_order_release);
            std::lock_guard<std::mutex> lock(mMutex);
            if (mOpeningSource) {
                mOpeningSource->cancel();
            }
        }

        [[nodiscard]] bool isCancelled() const noexcept {
            return mCancelled.load(std::memory_order_acquire);
        }

        void bindOpeningSource(IAudioDataSource* source) noexcept {
            std::lock_guard<std::mutex> lock(mMutex);
            mOpeningSource = source;
            if (source && mCancelled.load(std::memory_order_acquire)) {
                source->cancel();
            }
        }

        [[nodiscard]] spotify::network::CancelPredicate asCancelPredicate() {
            auto self = shared_from_this();
            return [self]() -> bool {
                return self->isCancelled();
            };
        }

    private:
        std::atomic<bool> mCancelled{false};
        std::mutex mMutex;
        IAudioDataSource* mOpeningSource{nullptr};
    };

    enum class StartPolicy : uint8_t {
        AutoPlayOnWatermark = 0,
        HoldPausedOnWatermark = 1,
    };

    enum class SourceTopology : uint8_t {
        SingleStream = 0,
        DualHeadAndCdn = 1,
    };

    enum class SecondaryStreamPhase : uint8_t {
        Inactive = 0,
        Attaching = 1,
        HandedOff = 2,
        Failed = 3,
    };

    enum class PrimaryHeadState : uint8_t {
        Active = 0,
        SuspendedForOutOfRangeSeek = 1,
        Released = 2,
    };

    enum class DurationAuthority : uint8_t {
        Estimated = 0,
        ContainerVerified = 1,
    };

    enum class DecoderStreamState : uint8_t {
        Decoding = 0,
        EndOfStreamReached = 1,
    };

    enum class SourceEncryptionMode : uint8_t {
        Cleartext = 0,
        Encrypted = 1,
    };

    enum class UnderrunRecoveryState : uint8_t {
        Normal = 0,
        NeedsRampUp = 1,
    };

    enum class EosNotificationState : uint8_t {
        Pending = 0,
        Dispatched = 1,
    };

    AudioEngine();
    ~AudioEngine();

    AudioEngine(const AudioEngine&) = delete;
    AudioEngine& operator=(const AudioEngine&) = delete;

    /// Register callback invoked when playback naturally finishes and ring buffer drains (EOS).
    void setEosCallback(EosCallback cb);

    /// Register callback invoked when the background full-track stream fails to attach
    /// (storage open, Widevine license exchange, sample-rate mismatch, decoder start).
    void setSecondaryFailureCallback(SecondaryFailureCallback cb);

    /// Register callback invoked on phase/duration transitions so upper player layers sync without polling lag.
    void setStateCallback(StateCallback cb);

    /// Configure whether reaching the prebuffer watermark automatically starts Oboe output.
    void setAutoPlay(bool autoPlay);

    /// Stop active decoders, pause/flush Oboe stream, and reset state to Idle.
    void stop();

    /// Signal any in-flight source open or Widevine exchange to abort immediately so caller worker threads can join.
    void cancelPendingLoads();

    /// Load a local audio file or direct HTTP URL (with optional CDN fallbacks & URL refresh callback).
    EngineStatus loadLocal(const char* filePath,
                           std::vector<std::string> fallbackUrls = {},
                           spotify::network::UrlRefreshCallback urlRefreshCb = nullptr);

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
                                int64_t handoffPositionMs,
                                int64_t trackDurationMs = -1);

    EngineStatus loadDualSource(std::unique_ptr<IAudioDataSource> primarySource,
                                const char* secondaryUrl,
                                const char* licenseServerUrl,
                                const char* authHeader,
                                int64_t handoffPositionMs,
                                int64_t trackDurationMs = -1);

    /// Load a single encrypted audio stream directly (Widevine AAC/FLAC without Vorbis head chunk).
    EngineStatus loadEncryptedStream(const char* url,
                                     const char* licenseServerUrl,
                                     const char* authHeader,
                                     std::vector<std::string> fallbackUrls = {},
                                     spotify::network::UrlRefreshCallback urlRefreshCb = nullptr);

    /// Asynchronously attaches or starts the secondary full-track stream while primary is already playing.
    EngineStatus attachSecondaryStream(const char* secondaryUrl,
                                       const char* licenseServerUrl,
                                       const char* authHeader,
                                       int64_t handoffPositionMs = -1,
                                       std::vector<std::string> fallbackUrls = {},
                                       spotify::network::UrlRefreshCallback urlRefreshCb = nullptr);

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
    bool hasAuthoritativeDuration() const {
        return mDurationAuthority.load(std::memory_order_acquire) ==
               DurationAuthority::ContainerVerified;
    }
    int32_t getState() const;
    int32_t getUnderrunCount() const;
    bool isDualSource() const {
        return mSourceTopology.load(std::memory_order_relaxed) ==
               SourceTopology::DualHeadAndCdn;
    }
    bool isHandoffCompleted() const {
        return mSecondaryPhase.load(std::memory_order_relaxed) ==
               SecondaryStreamPhase::HandedOff;
    }

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
    std::shared_ptr<LoadSessionToken> beginNewLoadSession();
    void cancelActiveLoadSession();
    void stopPlayback();
    void closeOboeStream();
    void wakeMonitor() noexcept;
    void cancelAllActiveSources();
    void joinMonitorThread();
    void eosDispatcherFunc();
    void notifyStateChanged(EngineState state);
    EngineStatus loadSource(std::unique_ptr<IAudioDataSource> source);
    EngineStatus openOboeStream();
    oboe::Result startOrReopenOboeStream(std::shared_ptr<oboe::AudioStream>* outStream = nullptr);
    void decoderMonitorFunc();
    void secondaryWorkerFunc(std::shared_ptr<LoadSessionToken> sessionToken,
                             std::vector<std::string> secondaryUrls,
                             std::string licenseServerUrl,
                             std::string authHeader,
                             int64_t handoffMs,
                             spotify::network::UrlRefreshCallback urlRefreshCb);
    AMediaCrypto* acquireWidevineCrypto(
        const std::vector<uint8_t>& psshData,
        const std::string& licenseServerUrl,
        const std::string& authHeader,
        const spotify::network::CancelPredicate& cancelPred = nullptr);
    void closeActiveDrmSession();
    void failSecondary(const std::shared_ptr<LoadSessionToken>& sessionToken,
                       const std::string& reason);

    // --- State ---
    std::atomic<EngineState> mState{EngineState::Uninitialized};
    std::atomic<StartPolicy> mStartPolicy{StartPolicy::AutoPlayOnWatermark};

    // --- Audio pipeline components ---
    RingBuffer mRingBuffer;
    std::mutex mSourceCancelMutex;
    std::shared_ptr<LoadSessionToken> mActiveLoadSession;
    std::unique_ptr<IAudioDataSource> mDataSource;
    mutable std::mutex mStreamMutex;
    std::shared_ptr<oboe::AudioStream> mStream;
    int32_t mStreamSampleRate{0};
    std::unique_ptr<NativeDecoder> mDecoder;

    // --- Dual-decoder components ---
    std::unique_ptr<IAudioDataSource> mPrimarySource;
    std::unique_ptr<NativeDecoder> mPrimaryDecoder;
    std::unique_ptr<HttpMediaDataSource> mSecondarySource;
    std::unique_ptr<NativeDecoder> mSecondaryDecoder;
    AMediaCrypto* mSecondaryCrypto{nullptr};
    std::vector<uint8_t> mActiveDrmSessionId;

    std::atomic<SourceTopology> mSourceTopology{SourceTopology::SingleStream};
    std::atomic<SecondaryStreamPhase> mSecondaryPhase{SecondaryStreamPhase::Inactive};
    std::atomic<int64_t> mHandoffTargetMs{-1};
    std::atomic<int64_t> mHandoffActualMs{0};
    std::atomic<int64_t> mPrimaryDurationMs{0};
    std::atomic<int64_t> mPendingSeekOverrideMs{-1};
    std::atomic<PrimaryHeadState> mPrimaryHeadState{PrimaryHeadState::Released};
    std::atomic<uint64_t> mSeekGeneration{0};

    std::thread mSecondaryWorkerThread;

    // --- Format info ---
    int32_t mSampleRate{48000};
    int32_t mSourceChannelCount{2};
    std::atomic<int64_t> mDurationMs{0};
    std::atomic<DurationAuthority> mDurationAuthority{DurationAuthority::Estimated};

    // --- Position tracking ---
    std::atomic<int64_t> mFramesConsumedByHardware{0};
    std::atomic<int64_t> mSeekPositionMs{0};

    // --- Telemetry ---
    std::atomic<int32_t> mUnderrunCount{0};

    // --- Decoder-to-Oboe watermark handoff ---
    static constexpr size_t kStartWatermarkFrames = 3840; // 80 ms @ 48 kHz
    std::atomic<DecoderStreamState> mDecoderStreamState{DecoderStreamState::Decoding};
    std::mutex mMonitorMutex;
    std::condition_variable mMonitorCv;
    std::thread mMonitorThread;
    std::atomic<bool> mMonitorShouldStop{false};
    SourceEncryptionMode mEncryptionMode{SourceEncryptionMode::Cleartext};
    UnderrunRecoveryState mUnderrunRecovery{UnderrunRecoveryState::Normal};

    // --- EOS & State Notification Callbacks ---
    std::mutex mEosMutex;
    std::condition_variable mEosCv;
    std::thread mEosDispatcherThread;
    EosCallback mEosCallback;
    SecondaryFailureCallback mSecondaryFailureCallback;
    StateCallback mStateCallback;
    std::atomic<EosNotificationState> mEosNotificationState{EosNotificationState::Pending};
    bool mEosPending{false};
    bool mEosWorkerStop{false};
};
