#include "NativeDecoder.h"
#include "JniHelper.h"

#include <cstring>
#include <algorithm>
#include <chrono>
#include <vector>

#include <android/log.h>
#include <sys/resource.h>
#include <unistd.h>

#define LOG_TAG "MusifyDecoder"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static constexpr int64_t kCodecTimeoutUs = 5000;   // 5 ms dequeue timeout
static constexpr int     kAudioThreadPriority = -4; // THREAD_PRIORITY_AUDIO

NativeDecoder::NativeDecoder(RingBuffer& ringBuffer,
                             AMediaExtractor* extractor,
                             const char* mimeType,
                             AMediaFormat* trackFormat,
                             int32_t sourceChannelCount,
                             AMediaCrypto* crypto,
                             int64_t maxFramesToDecode,
                             JavaVM* javaVm,
                             int64_t discardPriorToUs)
    : mRingBuffer(ringBuffer)
    , mExtractor(extractor)
    , mTrackFormat(trackFormat)
    , mCrypto(crypto)
    , mSourceChannelCount(sourceChannelCount > 0 ? sourceChannelCount : 2)
    , mMaxFramesToDecode(maxFramesToDecode)
    , mJavaVm(javaVm)
    , mDiscardPriorToUs(discardPriorToUs)
    , mNeedsMicroFadeIn(discardPriorToUs > 0) {
    if (mimeType) {
        std::strncpy(mMimeType, mimeType, sizeof(mMimeType) - 1);
        mMimeType[sizeof(mMimeType) - 1] = '\0';
    } else {
        mMimeType[0] = '\0';
    }
}

NativeDecoder::~NativeDecoder() {
    stop();
}

EngineStatus NativeDecoder::configure() {
    mCodec = AMediaCodec_createDecoderByType(mMimeType);
    if (!mCodec) {
        LOGE("AMediaCodec_createDecoderByType failed for %s", mMimeType);
        return EngineStatus::ErrorCodec;
    }

    // AMediaFormat_copy requires API 29+. Manually transfer the fields the codec needs.
    AMediaFormat* configFormat = AMediaFormat_new();

    const char* mime = nullptr;
    if (AMediaFormat_getString(mTrackFormat, AMEDIAFORMAT_KEY_MIME, &mime) && mime) {
        AMediaFormat_setString(configFormat, AMEDIAFORMAT_KEY_MIME, mime);
    }
    int32_t sr = 0;
    if (AMediaFormat_getInt32(mTrackFormat, AMEDIAFORMAT_KEY_SAMPLE_RATE, &sr)) {
        mSampleRate = sr;
        AMediaFormat_setInt32(configFormat, AMEDIAFORMAT_KEY_SAMPLE_RATE, sr);
    }
    int32_t cc = 0;
    if (AMediaFormat_getInt32(mTrackFormat, AMEDIAFORMAT_KEY_CHANNEL_COUNT, &cc)) {
        AMediaFormat_setInt32(configFormat, AMEDIAFORMAT_KEY_CHANNEL_COUNT, cc);
    }
    int64_t dur = 0;
    if (AMediaFormat_getInt64(mTrackFormat, AMEDIAFORMAT_KEY_DURATION, &dur)) {
        AMediaFormat_setInt64(configFormat, AMEDIAFORMAT_KEY_DURATION, dur);
    }
    // Copy codec-specific data buffers (CSD-0, CSD-1) required for AAC/Opus/etc.
    void* csd = nullptr;
    size_t csdSize = 0;
    if (AMediaFormat_getBuffer(mTrackFormat, "csd-0", &csd, &csdSize) && csd && csdSize > 0) {
        AMediaFormat_setBuffer(configFormat, "csd-0", csd, csdSize);
    }
    if (AMediaFormat_getBuffer(mTrackFormat, "csd-1", &csd, &csdSize) && csd && csdSize > 0) {
        AMediaFormat_setBuffer(configFormat, "csd-1", csd, csdSize);
    }
    int32_t aacProfile = 0;
    if (AMediaFormat_getInt32(mTrackFormat, "aac-profile", &aacProfile)) {
        AMediaFormat_setInt32(configFormat, "aac-profile", aacProfile);
    }

    media_status_t status = AMediaCodec_configure(
        mCodec, configFormat, nullptr, mCrypto, 0);
    AMediaFormat_delete(configFormat);

    if (status != AMEDIA_OK) {
        LOGE("AMediaCodec_configure failed: %d (crypto=%p)", static_cast<int>(status), mCrypto);
        AMediaCodec_delete(mCodec);
        mCodec = nullptr;
        return EngineStatus::ErrorCodec;
    }

    status = AMediaCodec_start(mCodec);
    if (status != AMEDIA_OK) {
        LOGE("AMediaCodec_start failed: %d", static_cast<int>(status));
        AMediaCodec_delete(mCodec);
        mCodec = nullptr;
        return EngineStatus::ErrorCodec;
    }

    // Default to 16-bit signed PCM (ENCODING_PCM_16BIT = 2), the universal Android format.
    mOutputIsFloat = false;
    AMediaFormat* outputFormat = AMediaCodec_getOutputFormat(mCodec);
    if (outputFormat) {
        int32_t pcmEncoding = 2;
        if (AMediaFormat_getInt32(outputFormat, "pcm-encoding", &pcmEncoding)) {
            mOutputIsFloat = (pcmEncoding == 4);
        } else {
            mOutputIsFloat = false;
        }

        int32_t outChannels = 0;
        if (AMediaFormat_getInt32(outputFormat, AMEDIAFORMAT_KEY_CHANNEL_COUNT, &outChannels) && outChannels > 0) {
            mSourceChannelCount = outChannels;
        }

        AMediaFormat_delete(outputFormat);
    }

    LOGI("AMediaCodec configured: mime=%s sr=%d cc=%d isFloat=%d crypto=%p",
         mMimeType, sr, mSourceChannelCount, mOutputIsFloat ? 1 : 0, mCrypto);
    return EngineStatus::Ok;
}

EngineStatus NativeDecoder::start() {
    if (!mCodec) {
        LOGE("NativeDecoder::start called before configure()");
        return EngineStatus::ErrorInvalidState;
    }

    if (mThread.joinable()) {
        mShouldStop.store(true, std::memory_order_release);
        mThread.join();
    }

    mShouldStop.store(false, std::memory_order_release);
    mEndOfStream.store(false, std::memory_order_release);
    mInputEos.store(false, std::memory_order_release);

    mThread = std::thread(&NativeDecoder::threadFunc, this);
    return EngineStatus::Ok;
}

void NativeDecoder::stop() {
    mShouldStop.store(true, std::memory_order_release);
    if (mThread.joinable()) {
        mThread.join();
    }
    if (mCodec) {
        AMediaCodec_stop(mCodec);
        AMediaCodec_delete(mCodec);
        mCodec = nullptr;
    }
}

void NativeDecoder::requestSeek(int64_t positionUs) {
    mSeekTargetUs.store(positionUs, std::memory_order_relaxed);
    mSeekRequested.store(true, std::memory_order_release);
}

bool NativeDecoder::isEndOfStream() const {
    return mEndOfStream.load(std::memory_order_acquire);
}

// ---------------------------------------------------------------------------
// Decoder thread
// ---------------------------------------------------------------------------

void NativeDecoder::threadFunc() {
    setpriority(PRIO_PROCESS, 0, kAudioThreadPriority);

    // CRITICAL: Attach this decoding thread to JavaVM so AMediaExtractor remote HTTP streaming functions correctly
    JniThreadAttacher jniAttacher(mJavaVm, "MusifyDecoderWorker");

    while (!mShouldStop.load(std::memory_order_acquire)) {
        if (mSeekRequested.load(std::memory_order_acquire)) {
            executeSeek();
        }

        if (mEndOfStream.load(std::memory_order_relaxed)) {
            // Wait for seek or stop without terminating the thread
            std::this_thread::sleep_for(std::chrono::milliseconds(5));
            continue;
        }

        bool didWork = false;

        if (!mInputEos.load(std::memory_order_relaxed)) {
            didWork |= feedInputBuffer();
        }

        didWork |= drainOutputBuffer();

        if (!didWork) {
            // Buffer full or codec busy - yield briefly without spinning.
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
    }
}

bool NativeDecoder::feedInputBuffer() {
    if (mMaxFramesToDecode > 0 && mTotalFramesDecoded.load(std::memory_order_relaxed) >= mMaxFramesToDecode) {
        // Target handoff boundary reached on decoded frames - queue EOS.
        ssize_t inputIdx = AMediaCodec_dequeueInputBuffer(mCodec, kCodecTimeoutUs);
        if (inputIdx >= 0) {
            AMediaCodec_queueInputBuffer(
                mCodec, static_cast<size_t>(inputIdx),
                0, 0, 0, AMEDIACODEC_BUFFER_FLAG_END_OF_STREAM);
            mInputEos.store(true, std::memory_order_release);
        }
        return true;
    }

    ssize_t inputIdx = AMediaCodec_dequeueInputBuffer(mCodec, kCodecTimeoutUs);
    if (inputIdx < 0) return false;

    size_t inputCapacity = 0;
    uint8_t* inputBuf = AMediaCodec_getInputBuffer(
        mCodec, static_cast<size_t>(inputIdx), &inputCapacity);
    if (!inputBuf) return false;

    ssize_t sampleSize = AMediaExtractor_readSampleData(
        mExtractor, inputBuf, inputCapacity);

    if (sampleSize > 0) {
        int64_t pts = AMediaExtractor_getSampleTime(mExtractor);
        uint64_t safePts = static_cast<uint64_t>(std::max<int64_t>(0, pts));
        AMediaCodecCryptoInfo* cryptoInfo = AMediaExtractor_getSampleCryptoInfo(mExtractor);
        if (cryptoInfo) {
            cryptoinfo_mode_t m = AMediaCodecCryptoInfo_getMode(cryptoInfo);
            AMediaCodecCryptoInfo* targetCryptoInfo = cryptoInfo;
            AMediaCodecCryptoInfo* allocatedFixedCryptoInfo = nullptr;

            // CRITICAL AOSP NDK FIX:
            // In Android Stagefright's internal MetaDataBase.h, kCryptoModeAesCbc = 2.
            // But in NdkMediaCodec.h cryptoinfo_mode_t (and Stagefright CryptoPlugin::Mode):
            //   0 = CLEAR, 1 = AES_CTR, 2 = AES_WV (legacy Widevine mode), 3 = AES_CBC.
            // NdkMediaExtractor blindly casts kCryptoModeAesCbc (2) to cryptoinfo_mode_t (2 = AES_WV).
            // When passed to AMediaCodec_queueSecureInputBuffer, NDK passes Mode 2 (kMode_AES_WV)
            // to CCodecBufferChannel and Widevine OEMCrypto HAL. Widevine rejects kMode_AES_WV
            // on cbcs streams with result = -22 (-EINVAL).
            // When mode is AMEDIACODECRYPTOINFO_MODE_AES_WV (2), we reconstruct the crypto info
            // with AMEDIACODECRYPTOINFO_MODE_AES_CBC (3) and apply the track pattern.
            if (m == AMEDIACODECRYPTOINFO_MODE_AES_WV) {
                size_t numSub = AMediaCodecCryptoInfo_getNumSubSamples(cryptoInfo);
                if (numSub > 0) {
                    uint8_t k[16]{};
                    uint8_t iv[16]{};
                    AMediaCodecCryptoInfo_getKey(cryptoInfo, k);
                    AMediaCodecCryptoInfo_getIV(cryptoInfo, iv);
                    std::vector<size_t> clearBytes(numSub);
                    std::vector<size_t> encBytes(numSub);
                    AMediaCodecCryptoInfo_getClearBytes(cryptoInfo, clearBytes.data());
                    AMediaCodecCryptoInfo_getEncryptedBytes(cryptoInfo, encBytes.data());

                    allocatedFixedCryptoInfo = AMediaCodecCryptoInfo_new(
                        static_cast<int>(numSub),
                        k,
                        iv,
                        AMEDIACODECRYPTOINFO_MODE_AES_CBC,
                        clearBytes.data(),
                        encBytes.data()
                    );

                    if (allocatedFixedCryptoInfo) {
                        int32_t encBlocks = 0;
                        int32_t skipBlocks = 0;
                        if (mTrackFormat) {
                            AMediaFormat_getInt32(mTrackFormat, "crypto-encrypted-byte-block", &encBlocks);
                            AMediaFormat_getInt32(mTrackFormat, "crypto-skip-byte-block", &skipBlocks);
                        }
                        if (encBlocks > 0 || skipBlocks > 0) {
                            cryptoinfo_pattern_t pattern{encBlocks, skipBlocks};
                            AMediaCodecCryptoInfo_setPattern(allocatedFixedCryptoInfo, &pattern);
                        }
                        targetCryptoInfo = allocatedFixedCryptoInfo;
                    }
                }
            }

            static std::atomic<int> sSecureLogCount{0};
            if (sSecureLogCount.fetch_add(1, std::memory_order_relaxed) < 3) {
                uint8_t k[16]{};
                uint8_t iv[16]{};
                AMediaCodecCryptoInfo_getKey(targetCryptoInfo, k);
                AMediaCodecCryptoInfo_getIV(targetCryptoInfo, iv);
                cryptoinfo_mode_t logMode = AMediaCodecCryptoInfo_getMode(targetCryptoInfo);
                size_t subCount = AMediaCodecCryptoInfo_getNumSubSamples(targetCryptoInfo);
                LOGI("Queue secure sample: pts=%lld size=%zd origMode=%d effectiveMode=%d numSub=%zu kid=%02x%02x%02x%02x... iv=%02x%02x%02x%02x...",
                     static_cast<long long>(pts), sampleSize, static_cast<int>(m), static_cast<int>(logMode), subCount,
                     k[0], k[1], k[2], k[3], iv[0], iv[1], iv[2], iv[3]);
            }

            media_status_t qStatus = AMediaCodec_queueSecureInputBuffer(
                mCodec, static_cast<size_t>(inputIdx),
                0, targetCryptoInfo, safePts, 0);

            if (qStatus != AMEDIA_OK) {
                uint8_t k[16]{};
                uint8_t iv[16]{};
                AMediaCodecCryptoInfo_getKey(targetCryptoInfo, k);
                AMediaCodecCryptoInfo_getIV(targetCryptoInfo, iv);
                cryptoinfo_mode_t logMode = AMediaCodecCryptoInfo_getMode(targetCryptoInfo);
                size_t subCount = AMediaCodecCryptoInfo_getNumSubSamples(targetCryptoInfo);
                LOGE("AMediaCodec_queueSecureInputBuffer failed: %d (pts=%lld, size=%zd, mode=%d, numSub=%zu, kid=%02x%02x%02x%02x..., iv=%02x%02x%02x%02x...)",
                     static_cast<int>(qStatus), static_cast<long long>(pts), sampleSize,
                     static_cast<int>(logMode), subCount,
                     k[0], k[1], k[2], k[3], iv[0], iv[1], iv[2], iv[3]);
            }

            if (allocatedFixedCryptoInfo) {
                AMediaCodecCryptoInfo_delete(allocatedFixedCryptoInfo);
            }
            AMediaCodecCryptoInfo_delete(cryptoInfo);
        } else {
            media_status_t qStatus = AMediaCodec_queueInputBuffer(
                mCodec, static_cast<size_t>(inputIdx),
                0, static_cast<size_t>(sampleSize), safePts, 0);
            if (qStatus != AMEDIA_OK) {
                LOGE("AMediaCodec_queueInputBuffer failed: %d (pts=%lld, size=%zd)",
                     static_cast<int>(qStatus), static_cast<long long>(pts), sampleSize);
            }
        }
        AMediaExtractor_advance(mExtractor);
    } else {
        LOGI("NativeDecoder input reached EOS or completed (sampleSize=%zd)", sampleSize);
        // End of input stream.
        AMediaCodec_queueInputBuffer(
            mCodec, static_cast<size_t>(inputIdx),
            0, 0, 0, AMEDIACODEC_BUFFER_FLAG_END_OF_STREAM);
        mInputEos.store(true, std::memory_order_release);
    }

    return true;
}

bool NativeDecoder::drainOutputBuffer() {
    AMediaCodecBufferInfo info{};
    ssize_t outputIdx = AMediaCodec_dequeueOutputBuffer(mCodec, &info, kCodecTimeoutUs);

    if (outputIdx == AMEDIACODEC_INFO_OUTPUT_FORMAT_CHANGED) {
        AMediaFormat* newFormat = AMediaCodec_getOutputFormat(mCodec);
        if (newFormat) {
            int32_t pcmEncoding = 2; // Default: ENCODING_PCM_16BIT
            if (AMediaFormat_getInt32(newFormat, "pcm-encoding", &pcmEncoding)) {
                mOutputIsFloat = (pcmEncoding == 4);
            } else {
                mOutputIsFloat = false;
            }

            int32_t cc = 0;
            if (AMediaFormat_getInt32(newFormat, AMEDIAFORMAT_KEY_CHANNEL_COUNT, &cc) && cc > 0) {
                mSourceChannelCount = cc;
            }

            int32_t sr = 0;
            if (AMediaFormat_getInt32(newFormat, AMEDIAFORMAT_KEY_SAMPLE_RATE, &sr) && sr > 0) {
                mSampleRate = sr;
            }

            LOGI("Output format changed: sr=%d cc=%d pcmEncoding=%d isFloat=%d",
                 mSampleRate, mSourceChannelCount, pcmEncoding, mOutputIsFloat ? 1 : 0);

            AMediaFormat_delete(newFormat);
        }
        return true;
    }

    if (outputIdx < 0) return false;

    if (info.size > 0) {
        size_t outBufSize = 0;
        uint8_t* outBuf = AMediaCodec_getOutputBuffer(
            mCodec, static_cast<size_t>(outputIdx), &outBufSize);

        if (outBuf) {
            const size_t bytesPerSample = mOutputIsFloat ? sizeof(float) : sizeof(int16_t);
            const size_t totalSamples = static_cast<size_t>(info.size) / bytesPerSample;
            const size_t channelCount = static_cast<size_t>(mSourceChannelCount > 0 ? mSourceChannelCount : 2);
            size_t totalFrames = totalSamples / channelCount;

            // Sample-accurate pre-roll discard for seamless dual-source handoff
            const int64_t discardUs = mDiscardPriorToUs.load(std::memory_order_relaxed);
            size_t discardLeadingFrames = 0;
            if (discardUs > 0 && mSampleRate > 0) {
                const int64_t ptsUs = info.presentationTimeUs;
                const int64_t bufferDurUs = (static_cast<int64_t>(totalFrames) * 1000000LL) / mSampleRate;
                if (ptsUs + bufferDurUs <= discardUs) {
                    // Whole buffer is pre-roll prior to handoff boundary - release without committing to RingBuffer
                    AMediaCodec_releaseOutputBuffer(mCodec, static_cast<size_t>(outputIdx), false);
                    return true;
                } else if (ptsUs < discardUs) {
                    // Buffer spans the handoff boundary: skip leading frames up to exact discardUs timestamp
                    const int64_t framesToSkip = ((discardUs - ptsUs) * mSampleRate) / 1000000LL;
                    if (framesToSkip > 0 && static_cast<size_t>(framesToSkip) < totalFrames) {
                        discardLeadingFrames = static_cast<size_t>(framesToSkip);
                        totalFrames -= discardLeadingFrames;
                        LOGI("Trimming %zu pre-roll frames from boundary buffer (pts=%lld us, discard=%lld us)",
                             discardLeadingFrames, static_cast<long long>(ptsUs), static_cast<long long>(discardUs));
                    }
                    mDiscardPriorToUs.store(-1, std::memory_order_relaxed);
                } else {
                    mDiscardPriorToUs.store(-1, std::memory_order_relaxed);
                }
            }

            // If bounded frame decoding is enabled, clamp total frames
            if (mMaxFramesToDecode > 0) {
                int64_t currentDecoded = mTotalFramesDecoded.load(std::memory_order_relaxed);
                int64_t remainingAllowed = mMaxFramesToDecode - currentDecoded;
                if (remainingAllowed <= 0) {
                    totalFrames = 0;
                    mEndOfStream.store(true, std::memory_order_release);
                } else if (static_cast<int64_t>(totalFrames) > remainingAllowed) {
                    totalFrames = static_cast<size_t>(remainingAllowed);
                }
            }

            size_t framesRemaining = totalFrames;
            size_t frameOffset = discardLeadingFrames;

            while (framesRemaining > 0 && !mShouldStop.load(std::memory_order_relaxed)) {
                if (mSeekRequested.load(std::memory_order_relaxed)) {
                    break;
                }

                const size_t chunkFrames = std::min(framesRemaining, kConversionBufferFrames);
                const float* stereoSrc = nullptr;

                if (mOutputIsFloat) {
                    const auto* floatBuf = reinterpret_cast<const float*>(outBuf + info.offset);
                    if (channelCount == 1) {
                        // Mono float -> Stereo float
                        for (size_t i = 0; i < chunkFrames; ++i) {
                            const float val = floatBuf[frameOffset + i];
                            mConversionBuffer[i * 2]     = val;
                            mConversionBuffer[i * 2 + 1] = val;
                        }
                        stereoSrc = mConversionBuffer;
                    } else if (channelCount == 2) {
                        if (mNeedsMicroFadeIn.exchange(false, std::memory_order_relaxed)) {
                            std::memcpy(mConversionBuffer, floatBuf + (frameOffset * 2), chunkFrames * RingBuffer::kChannelCount * sizeof(float));
                            const size_t ramp = std::min<size_t>(32, chunkFrames);
                            for (size_t i = 0; i < ramp; ++i) {
                                const float gain = static_cast<float>(i + 1) / static_cast<float>(ramp);
                                mConversionBuffer[i * 2]     *= gain;
                                mConversionBuffer[i * 2 + 1] *= gain;
                            }
                            stereoSrc = mConversionBuffer;
                        } else {
                            stereoSrc = floatBuf + (frameOffset * 2);
                        }
                    } else {
                        // Multi-channel downmix -> Stereo (L, R)
                        for (size_t i = 0; i < chunkFrames; ++i) {
                            const size_t sampleIdx = (frameOffset + i) * channelCount;
                            mConversionBuffer[i * 2]     = floatBuf[sampleIdx];
                            mConversionBuffer[i * 2 + 1] = floatBuf[sampleIdx + 1];
                        }
                        stereoSrc = mConversionBuffer;
                    }
                } else {
                    // int16_t -> float conversion (standard Android audio decoding path)
                    const auto* i16Buf = reinterpret_cast<const int16_t*>(outBuf + info.offset);
                    constexpr float kInv32768 = 1.0f / 32768.0f;

                    if (channelCount == 1) {
                        // Mono int16 -> Stereo float
                        for (size_t i = 0; i < chunkFrames; ++i) {
                            const float val = static_cast<float>(i16Buf[frameOffset + i]) * kInv32768;
                            mConversionBuffer[i * 2]     = val;
                            mConversionBuffer[i * 2 + 1] = val;
                        }
                        stereoSrc = mConversionBuffer;
                    } else if (channelCount == 2) {
                        // Stereo int16 -> Stereo float
                        const size_t sampleStart = frameOffset * 2;
                        const size_t sampleCount = chunkFrames * 2;
                        for (size_t i = 0; i < sampleCount; ++i) {
                            mConversionBuffer[i] = static_cast<float>(i16Buf[sampleStart + i]) * kInv32768;
                        }
                        stereoSrc = mConversionBuffer;
                    } else {
                        // Multi-channel int16 downmix -> Stereo float (L, R)
                        for (size_t i = 0; i < chunkFrames; ++i) {
                            const size_t sampleIdx = (frameOffset + i) * channelCount;
                            mConversionBuffer[i * 2]     = static_cast<float>(i16Buf[sampleIdx]) * kInv32768;
                            mConversionBuffer[i * 2 + 1] = static_cast<float>(i16Buf[sampleIdx + 1]) * kInv32768;
                        }
                        stereoSrc = mConversionBuffer;
                    }

                    if (mNeedsMicroFadeIn.exchange(false, std::memory_order_relaxed)) {
                        const size_t ramp = std::min<size_t>(32, chunkFrames);
                        for (size_t i = 0; i < ramp; ++i) {
                            const float gain = static_cast<float>(i + 1) / static_cast<float>(ramp);
                            mConversionBuffer[i * 2]     *= gain;
                            mConversionBuffer[i * 2 + 1] *= gain;
                        }
                    }
                }

                // Push chunk to the lock-free SPSC RingBuffer
                size_t written = 0;
                while (written < chunkFrames &&
                       !mShouldStop.load(std::memory_order_relaxed) &&
                       !mSeekRequested.load(std::memory_order_relaxed)) {
                    const size_t w = mRingBuffer.write(
                        stereoSrc + (written * RingBuffer::kChannelCount),
                        chunkFrames - written);
                    written += w;
                    if (written < chunkFrames) {
                        std::this_thread::sleep_for(std::chrono::microseconds(500));
                    }
                }

                mTotalFramesDecoded.fetch_add(written, std::memory_order_relaxed);
                frameOffset += chunkFrames;
                framesRemaining -= chunkFrames;
            }
        }
    }

    AMediaCodec_releaseOutputBuffer(mCodec, static_cast<size_t>(outputIdx), false);

    if (info.flags & AMEDIACODEC_BUFFER_FLAG_END_OF_STREAM) {
        mEndOfStream.store(true, std::memory_order_release);
    } else if (mMaxFramesToDecode > 0 && mTotalFramesDecoded.load(std::memory_order_relaxed) >= mMaxFramesToDecode) {
        mEndOfStream.store(true, std::memory_order_release);
    }

    return true;
}

void NativeDecoder::executeSeek() {
    int64_t targetUs = mSeekTargetUs.load(std::memory_order_relaxed);
    mSeekRequested.store(false, std::memory_order_release);

    AMediaExtractor_seekTo(mExtractor, targetUs, AMEDIAEXTRACTOR_SEEK_CLOSEST_SYNC);
    AMediaCodec_flush(mCodec);

    // Note: Do NOT reset mRingBuffer here! Ring buffer resetting during seeking
    // is reserved for user-initiated seeks in AudioEngine::seekMs().
    // During seamless dual-source handoff, mRingBuffer holds the head chunk audio
    // currently being heard by the user, and secondary frames append seamlessly.
    mInputEos.store(false, std::memory_order_release);
    mEndOfStream.store(false, std::memory_order_release);
}
