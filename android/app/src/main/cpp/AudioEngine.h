#pragma once

#include <atomic>
#include <cstdint>
#include <memory>

#include <oboe/Oboe.h>

#include "DataSource.h"
#include "NativeDecoder.h"
#include "RingBuffer.h"

/// Top-level native audio engine orchestrating the full pipeline:
///   DataSource → NativeDecoder → RingBuffer → Oboe real-time output
///
/// State machine: Uninitialized → Idle → Loading → Prebuffering → Playing ⇄ Paused → Stopped
///                                                                  ↓ (on fault)
///                                                               Faulted
///
/// Thread model:
///   - Main/FFI thread: loadLocal, play, pause, seekMs, getters
///   - Decoder thread (NativeDecoder): fills RingBuffer from AMediaCodec
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

    /// Load a local audio file. Transitions: * → Loading → Prebuffering.
    EngineStatus loadLocal(const char* filePath);

    /// Initialise an encrypted stream source. Currently returns ErrorIO.
    EngineStatus initEncryptedStream(int64_t totalSize,
                                     const uint8_t* key16,
                                     const uint8_t* iv16);

    /// Push an encrypted chunk into the stream data source.
    EngineStatus pushStreamChunk(int64_t offset,
                                 const uint8_t* data,
                                 int32_t length);

    /// Resume / start playback. Transitions: Paused → Playing.
    EngineStatus play();

    /// Pause playback. Transitions: Playing → Paused.
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

    // --- State ---
    std::atomic<EngineState> mState{EngineState::Uninitialized};

    // --- Audio pipeline components ---
    RingBuffer mRingBuffer;
    std::unique_ptr<IAudioDataSource> mDataSource;
    std::unique_ptr<NativeDecoder> mDecoder;
    std::shared_ptr<oboe::AudioStream> mStream;

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
