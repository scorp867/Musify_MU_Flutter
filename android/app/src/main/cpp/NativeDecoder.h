#pragma once

#include <atomic>
#include <cstdint>
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
/// the SPSC RingBuffer.
///
/// Supports Widevine DRM playback via optional AMediaCrypto and bounded frame decoding
/// for seamless dual-decoder handoff.
class NativeDecoder {
public:
    NativeDecoder(RingBuffer& ringBuffer,
                  AMediaExtractor* extractor,
                  const char* mimeType,
                  AMediaFormat* trackFormat,
                  int32_t sourceChannelCount,
                  AMediaCrypto* crypto = nullptr,
                  int64_t maxFramesToDecode = -1);

    ~NativeDecoder();

    NativeDecoder(const NativeDecoder&) = delete;
    NativeDecoder& operator=(const NativeDecoder&) = delete;

    /// Configure and start the AMediaCodec. Does not start the thread.
    EngineStatus configure();

    /// Start the decoder thread. Returns immediately.
    EngineStatus start();

    /// Request the decoder thread to stop and join it.
    void stop();

    /// Request a seek. The decoder thread will execute it on its next iteration.
    void requestSeek(int64_t positionUs);

    /// True after the decoder has consumed all input and flushed all output.
    bool isEndOfStream() const;

    /// Total number of PCM frames successfully decoded and committed.
    int64_t getDecodedFrames() const {
        return mTotalFramesDecoded.load(std::memory_order_relaxed);
    }

private:
    void threadFunc();
    bool feedInputBuffer();
    bool drainOutputBuffer();
    void executeSeek();

    RingBuffer& mRingBuffer;

    AMediaExtractor* mExtractor;    // Borrowed - owned by the data source
    AMediaCodec* mCodec{nullptr};
    AMediaFormat* mTrackFormat;     // Borrowed - owned by the data source
    AMediaCrypto* mCrypto{nullptr};  // Borrowed or managed
    char mMimeType[128]{};
    int32_t mSourceChannelCount;
    int64_t mMaxFramesToDecode{-1};

    bool mOutputIsFloat{false};

    std::thread mThread;
    std::atomic<bool> mShouldStop{false};
    std::atomic<bool> mEndOfStream{false};
    std::atomic<bool> mInputEos{false};
    std::atomic<int64_t> mTotalFramesDecoded{0};

    std::atomic<bool> mSeekRequested{false};
    std::atomic<int64_t> mSeekTargetUs{0};

    // Intermediate conversion buffer (worst case: 1 MB decoded chunk)
    static constexpr size_t kConversionBufferFrames = 8192;
    float mConversionBuffer[kConversionBufferFrames * RingBuffer::kChannelCount]{};
};
