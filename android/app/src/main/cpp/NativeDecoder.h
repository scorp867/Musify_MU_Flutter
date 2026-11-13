#pragma once

#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <functional>
#include <mutex>
#include <thread>

#include <media/NdkMediaCodec.h>
#include <media/NdkMediaCrypto.h>
#include <media/NdkMediaExtractor.h>
#include <media/NdkMediaFormat.h>

#include "DataSource.h"
#include "RingBuffer.h"

/// Native hardware/software audio decoder running on a dedicated high-priority thread.
///
/// Reads compressed audio from AMediaExtractor, decodes via AMediaCodec configured
/// for PCM output, converts int16->float (the standard Android decoder output format),
/// up-mixes mono->stereo if needed, and pushes interleaved stereo float frames into
/// the SPSC RingBuffer under strict seek-epoch isolation.
///
/// Supports Widevine DRM playback via optional AMediaCrypto and bounded frame decoding
/// for seamless dual-decoder handoff.
class NativeDecoder {
public:
    using ProgressCallback = std::function<void()>;

    NativeDecoder(RingBuffer& ringBuffer,
                  AMediaExtractor* extractor,
                  const char* mimeType,
                  AMediaFormat* trackFormat,
                  int32_t sourceChannelCount,
                  AMediaCrypto* crypto = nullptr,
                  int64_t maxFramesToDecode = -1,
                  int64_t discardPriorToUs = -1,
                  ProgressCallback progressCb = nullptr);

    ~NativeDecoder();

    NativeDecoder(const NativeDecoder&) = delete;
    NativeDecoder& operator=(const NativeDecoder&) = delete;

    /// Configure and start the AMediaCodec. Does not start the thread.
    EngineStatus configure();

    /// Start the decoder thread. Returns immediately.
    EngineStatus start();

    /// Request the decoder thread to stop and join it.
    void stop();

    /// Request a seek. Wakes the decoder thread immediately to execute it.
    void requestSeek(int64_t positionUs);

    /// Wake the decoder thread when ring buffer space becomes available.
    void notifyRingSpaceAvailable() noexcept;

    /// True after the decoder has consumed all input and flushed all output.
    bool isEndOfStream() const;

    /// Total number of PCM frames successfully decoded and committed.
    int64_t getDecodedFrames() const {
        return mTotalFramesDecoded.load(std::memory_order_relaxed);
    }

    /// True if decoder thread is actively running.
    bool isRunning() const {
        return mThread.joinable() && !mShouldStop.load(std::memory_order_relaxed);
    }

    void setDiscardPriorToUs(int64_t us) {
        mDiscardPriorToUs.store(us, std::memory_order_release);
        if (us > 0) mNeedsMicroFadeIn.store(true, std::memory_order_release);
    }

    /// Consumes and clears the landed post-seek timestamp (ms), or returns -1 if none pending.
    int64_t consumeActualSeekMs() {
        return mActualSeekMs.exchange(-1, std::memory_order_acq_rel);
    }

private:
    void threadFunc();
    bool feedInputBuffer();
    bool drainOutputBuffer();
    void executeSeek();

    RingBuffer& mRingBuffer;
    ProgressCallback mProgressCallback;

    AMediaExtractor* mExtractor;    // Borrowed - owned by the data source
    AMediaCodec* mCodec{nullptr};
    AMediaFormat* mTrackFormat;     // Borrowed - owned by the data source
    AMediaCrypto* mCrypto{nullptr};  // Borrowed or managed
    char mMimeType[128]{};
    int32_t mSourceChannelCount;
    int32_t mSampleRate{44100};
    int64_t mMaxFramesToDecode{-1};

    bool mOutputIsFloat{false};

    std::thread mThread;
    mutable std::mutex mWakeMutex;
    std::condition_variable mWakeCv;
    uint64_t mActiveRingEpoch{1};

    std::atomic<bool> mShouldStop{false};
    std::atomic<bool> mEndOfStream{false};
    std::atomic<bool> mInputEos{false};
    std::atomic<int64_t> mTotalFramesDecoded{0};
    std::atomic<int64_t> mDiscardPriorToUs{-1};
    std::atomic<bool> mNeedsMicroFadeIn{false};

    std::atomic<bool> mSeekRequested{false};
    std::atomic<int64_t> mSeekTargetUs{0};
    std::atomic<int64_t> mActualSeekMs{-1};

    // Intermediate conversion buffer (worst case: 8192 stereo frames)
    static constexpr size_t kConversionBufferFrames = 8192;
    float mConversionBuffer[kConversionBufferFrames * RingBuffer::kChannelCount]{};
};
