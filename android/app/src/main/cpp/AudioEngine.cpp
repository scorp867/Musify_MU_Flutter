#include "AudioEngine.h"

#include <cstring>
#include <algorithm>
#include <chrono>

#include <android/log.h>

#define LOG_TAG "MusifyEngine"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

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

    if (mStream) {
        mStream->requestStop();
        mStream->close();
        mStream.reset();
    }

    if (mDecoder) {
        mDecoder->stop();
        mDecoder.reset();
    }

    if (mMonitorThread.joinable()) {
        mMonitorThread.join();
    }

    if (mDataSource) {
        mDataSource->close();
        mDataSource.reset();
    }

    mRingBuffer.reset();
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

    auto source = std::make_unique<LocalFileDataSource>(filePath);
    return loadSource(std::move(source));
}

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

    // Configure decoder
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

    // Open Oboe stream (but don't start it yet — watermark handoff below)
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

    // Reset telemetry
    mRingBuffer.reset();
    mFramesConsumedByHardware.store(0, std::memory_order_relaxed);
    mSeekPositionMs.store(0, std::memory_order_relaxed);
    mUnderrunCount.store(0, std::memory_order_relaxed);
    mDecoderEndOfStream.store(false, std::memory_order_relaxed);

    // Transition to Prebuffering
    mState.store(EngineState::Prebuffering, std::memory_order_release);

    // Start decoder thread — it fills the ring buffer
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

    // Start monitor thread — watches for watermark and EOS
    mMonitorShouldStop.store(false, std::memory_order_release);
    mMonitorThread = std::thread(&AudioEngine::decoderMonitorFunc, this);

    return EngineStatus::Ok;
}

// ===========================================================================
// Monitor thread: watermark detection and EOS propagation
// ===========================================================================

void AudioEngine::decoderMonitorFunc() {
    bool watermarkReached = false;

    while (!mMonitorShouldStop.load(std::memory_order_acquire)) {
        const EngineState currentState = mState.load(std::memory_order_acquire);

        if (!watermarkReached && currentState == EngineState::Prebuffering) {
            const size_t available = mRingBuffer.availableToRead();
            const bool eos = mDecoder && mDecoder->isEndOfStream();

            // Scale watermark to source sample rate (80 ms)
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

        // Propagate decoder EOS flag for the audio callback
        if (mDecoder && mDecoder->isEndOfStream()) {
            mDecoderEndOfStream.store(true, std::memory_order_release);
        }

        // Stop monitor thread only on terminal unrecoverable errors or shutdown
        if (currentState == EngineState::Faulted ||
            currentState == EngineState::Idle) {
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

    // Set burst size to 2x frames per burst for stability
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

    if (positionMs < 0 || positionMs > mDurationMs) {
        return EngineStatus::ErrorInvalidArg;
    }

    mSeekPositionMs.store(positionMs, std::memory_order_relaxed);
    mFramesConsumedByHardware.store(0, std::memory_order_relaxed);
    mDecoderEndOfStream.store(false, std::memory_order_relaxed);

    if (mDecoder) {
        mDecoder->requestSeek(positionMs * 1000); // ms → µs
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

    // Output silence if not in Playing state
    if (state != EngineState::Playing) {
        std::memset(output, 0, requestedFrames * RingBuffer::kChannelCount * sizeof(float));
        return oboe::DataCallbackResult::Continue;
    }

    const size_t framesRead = mRingBuffer.read(output, requestedFrames);

    if (framesRead < requestedFrames) {
        const bool eos = mDecoderEndOfStream.load(std::memory_order_acquire);

        if (eos && mRingBuffer.availableToRead() == 0) {
            // All decoded audio consumed — track complete.
            // Zero-fill remainder and transition to Stopped.
            std::memset(output + framesRead * RingBuffer::kChannelCount, 0,
                        (requestedFrames - framesRead) * RingBuffer::kChannelCount * sizeof(float));
            mFramesConsumedByHardware.fetch_add(
                static_cast<int64_t>(framesRead), std::memory_order_relaxed);
            mState.store(EngineState::Stopped, std::memory_order_release);
            return oboe::DataCallbackResult::Continue;
        }

        // Buffer underrun during active playback.
        // Apply 32-frame linear ramp-down to prevent click/pop artifacts.
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

        // Zero-fill the remaining frames
        std::memset(output + framesRead * RingBuffer::kChannelCount, 0,
                    (requestedFrames - framesRead) * RingBuffer::kChannelCount * sizeof(float));

        mUnderrunCount.fetch_add(1, std::memory_order_relaxed);
    }

    mFramesConsumedByHardware.fetch_add(
        static_cast<int64_t>(framesRead), std::memory_order_relaxed);

    return oboe::DataCallbackResult::Continue;
}

// ===========================================================================
// Oboe error callback — handles audio routing changes (BT disconnect etc.)
// ===========================================================================

void AudioEngine::onErrorAfterClose(
        oboe::AudioStream* /*stream*/,
        oboe::Result error) {

    if (error == oboe::Result::ErrorDisconnected) {
        LOGI("Audio route disconnected — re-opening stream");

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
