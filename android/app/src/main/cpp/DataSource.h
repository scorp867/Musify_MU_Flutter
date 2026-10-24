#pragma once

#include <cstdint>
#include <cstddef>

#include <media/NdkMediaExtractor.h>
#include <media/NdkMediaFormat.h>
#include <media/NdkMediaDataSource.h>

// ---------------------------------------------------------------------------
// Engine-wide status and state enums, shared across all native components.
// Integer values are stable across FFI and must match the Dart mirror exactly.
// ---------------------------------------------------------------------------

enum class EngineStatus : int32_t {
    Ok              =  0,
    ErrorInvalidState = -1,
    ErrorCodec      = -2,
    ErrorStream     = -3,
    ErrorIO         = -4,
    ErrorInvalidArg = -5,
};

enum class EngineState : int32_t {
    Uninitialized   = 0,
    Idle            = 1,
    Loading         = 2,
    Prebuffering    = 3,
    Playing         = 4,
    Paused          = 5,
    Stopped         = 6,
    Faulted         = 7,
};

// ---------------------------------------------------------------------------
// Abstract audio data source interface.
// Provides a configured AMediaExtractor to the decoder pipeline.
// ---------------------------------------------------------------------------

class IAudioDataSource {
public:
    virtual ~IAudioDataSource() = default;

    /// Open the data source and configure the internal AMediaExtractor.
    virtual EngineStatus open() = 0;

    /// Returns the configured AMediaExtractor (borrowed pointer, owned by this source).
    virtual AMediaExtractor* getExtractor() const = 0;

    /// Audio track index selected within the extractor.
    virtual size_t getSelectedTrack() const = 0;

    /// Sample rate of the selected audio track (Hz).
    virtual int32_t getSampleRate() const = 0;

    /// Channel count of the selected audio track.
    virtual int32_t getChannelCount() const = 0;

    /// Total duration in microseconds.
    virtual int64_t getDurationUs() const = 0;

    /// MIME type of the compressed audio (e.g. "audio/mp4a-latm").
    virtual const char* getMimeType() const = 0;

    /// The AMediaFormat for the selected audio track (borrowed pointer).
    virtual AMediaFormat* getTrackFormat() const = 0;

    /// Release all native resources.
    virtual void close() = 0;
};

// ---------------------------------------------------------------------------
// Local file data source — Active implementation for device audio playback.
// Uses AMediaExtractor with a POSIX file descriptor.
// ---------------------------------------------------------------------------

class LocalFileDataSource final : public IAudioDataSource {
public:
    explicit LocalFileDataSource(const char* filePath);
    ~LocalFileDataSource() override;

    LocalFileDataSource(const LocalFileDataSource&) = delete;
    LocalFileDataSource& operator=(const LocalFileDataSource&) = delete;

    EngineStatus open() override;
    AMediaExtractor* getExtractor() const override;
    size_t getSelectedTrack() const override;
    int32_t getSampleRate() const override;
    int32_t getChannelCount() const override;
    int64_t getDurationUs() const override;
    const char* getMimeType() const override;
    AMediaFormat* getTrackFormat() const override;
    void close() override;

private:
    EngineStatus selectAudioTrack();

    char mFilePath[4096]{};
    AMediaExtractor* mExtractor{nullptr};
    AMediaFormat* mFormat{nullptr};
    size_t mTrackIndex{0};
    int32_t mSampleRate{0};
    int32_t mChannelCount{0};
    int64_t mDurationUs{0};
    char mMimeType[128]{};
};

// ---------------------------------------------------------------------------
// Encrypted stream data source — Plug-and-play interface for online streaming.
// Wraps AMediaDataSource with an IStreamCipher hook for AES-128-CTR decryption.
// Currently returns ErrorIO; implementation will be activated for online streams.
// ---------------------------------------------------------------------------

class IStreamCipher {
public:
    virtual ~IStreamCipher() = default;
    virtual void decryptRange(uint64_t byteOffset, uint8_t* data, size_t len) = 0;
};

class EncryptedStreamDataSource final : public IAudioDataSource {
public:
    EncryptedStreamDataSource(int64_t totalSize,
                              const uint8_t* key16,
                              const uint8_t* iv16);
    ~EncryptedStreamDataSource() override;

    EncryptedStreamDataSource(const EncryptedStreamDataSource&) = delete;
    EncryptedStreamDataSource& operator=(const EncryptedStreamDataSource&) = delete;

    EngineStatus open() override;
    AMediaExtractor* getExtractor() const override;
    size_t getSelectedTrack() const override;
    int32_t getSampleRate() const override;
    int32_t getChannelCount() const override;
    int64_t getDurationUs() const override;
    const char* getMimeType() const override;
    AMediaFormat* getTrackFormat() const override;
    void close() override;

    /// Push an encrypted chunk from Dart into the internal buffer.
    EngineStatus pushChunk(int64_t offset, const uint8_t* data, int32_t length);

private:
    [[maybe_unused]] int64_t mTotalSize{0};
    uint8_t mKey[16]{};
    uint8_t mIv[16]{};
    AMediaExtractor* mExtractor{nullptr};
    AMediaDataSource* mNdkDataSource{nullptr};
    AMediaFormat* mFormat{nullptr};
    size_t mTrackIndex{0};
    int32_t mSampleRate{0};
    int32_t mChannelCount{0};
    int64_t mDurationUs{0};
    char mMimeType[128]{};
};
