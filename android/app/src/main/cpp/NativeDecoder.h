#pragma once

#include <atomic>
#include <cstdint>
#include <thread>

#include <media/NdkMediaCodec.h>
#include <media/NdkMediaExtractor.h>
#include <media/NdkMediaFormat.h>

#include "DataSource.h"
#include "RingBuffer.h"

/// Native hardware/software audio decoder running on a dedicated high-priority thread.
///
/// Reads compressed audio from AMediaExtractor, decodes via AMediaCodec configured
/// for PCM output, converts int16→float (the standard Android decoder output format),
/// up-mixes mono→stereo if needed, and pushes interleaved stereo float frames into
/// the SPSC RingBuffer.
///
/// Supports deterministic sample-accurate seeking via AMediaExtractor_seekTo +
/// AMediaCodec_flush + ring buffer reset.
class NativeDecoder {
public:
    NativeDecoder(RingBuffer& ringBuffer,
                  AMediaExtractor* extractor,
                  const char* mimeType,
                  AMediaFormat* trackFormat,
                  int32_t sourceChannelCount);

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

private:
    void threadFunc();
    bool feedInputBuffer();
    bool drainOutputBuffer();
    void executeSeek();

    RingBuffer& mRingBuffer;

    AMediaExtractor* mExtractor;    // Borrowed — owned by the data source
    AMediaCodec* mCodec{nullptr};
    AMediaFormat* mTrackFormat;     // Borrowed — owned by the data source
    char mMimeType[128]{};
    int32_t mSourceChannelCount;

    bool mOutputIsFloat{false};

    std::thread mThread;
    std::atomic<bool> mShouldStop{false};
    std::atomic<bool> mEndOfStream{false};
    std::atomic<bool> mInputEos{false};

    std::atomic<bool> mSeekRequested{false};
    std::atomic<int64_t> mSeekTargetUs{0};

    // Intermediate conversion buffer (worst case: 1 MB decoded chunk)
    static constexpr size_t kConversionBufferFrames = 8192;
    float mConversionBuffer[kConversionBufferFrames * RingBuffer::kChannelCount]{};
};
