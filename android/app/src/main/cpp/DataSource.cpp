#include "DataSource.h"

#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <cstring>

#include <android/log.h>

#define LOG_TAG "MusifyDataSource"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// ===========================================================================
// LocalFileDataSource
// ===========================================================================

LocalFileDataSource::LocalFileDataSource(const char* filePath) {
    std::strncpy(mFilePath, filePath, sizeof(mFilePath) - 1);
    mFilePath[sizeof(mFilePath) - 1] = '\0';
}

LocalFileDataSource::~LocalFileDataSource() {
    close();
}

EngineStatus LocalFileDataSource::open() {
    close();

    mExtractor = AMediaExtractor_new();
    if (!mExtractor) {
        LOGE("AMediaExtractor_new failed");
        return EngineStatus::ErrorCodec;
    }

    int fd = ::open(mFilePath, O_RDONLY);
    if (fd < 0) {
        LOGE("Cannot open file: %s", mFilePath);
        AMediaExtractor_delete(mExtractor);
        mExtractor = nullptr;
        return EngineStatus::ErrorIO;
    }

    struct stat st{};
    if (::fstat(fd, &st) != 0) {
        LOGE("fstat failed: %s", mFilePath);
        ::close(fd);
        AMediaExtractor_delete(mExtractor);
        mExtractor = nullptr;
        return EngineStatus::ErrorIO;
    }

    media_status_t status = AMediaExtractor_setDataSourceFd(
        mExtractor, fd, 0, static_cast<off64_t>(st.st_size));
    ::close(fd);

    if (status != AMEDIA_OK) {
        LOGE("AMediaExtractor_setDataSourceFd failed: %d", static_cast<int>(status));
        AMediaExtractor_delete(mExtractor);
        mExtractor = nullptr;
        return EngineStatus::ErrorIO;
    }

    return selectAudioTrack();
}

EngineStatus LocalFileDataSource::selectAudioTrack() {
    const size_t trackCount = AMediaExtractor_getTrackCount(mExtractor);
    for (size_t i = 0; i < trackCount; ++i) {
        AMediaFormat* format = AMediaExtractor_getTrackFormat(mExtractor, i);
        const char* mime = nullptr;
        if (AMediaFormat_getString(format, AMEDIAFORMAT_KEY_MIME, &mime) && mime) {
            if (std::strncmp(mime, "audio/", 6) == 0) {
                mTrackIndex = i;
                mFormat = format;
                std::strncpy(mMimeType, mime, sizeof(mMimeType) - 1);
                mMimeType[sizeof(mMimeType) - 1] = '\0';

                int32_t sr = 0;
                AMediaFormat_getInt32(format, AMEDIAFORMAT_KEY_SAMPLE_RATE, &sr);
                mSampleRate = sr;

                int32_t cc = 0;
                AMediaFormat_getInt32(format, AMEDIAFORMAT_KEY_CHANNEL_COUNT, &cc);
                mChannelCount = cc;

                int64_t dur = 0;
                AMediaFormat_getInt64(format, AMEDIAFORMAT_KEY_DURATION, &dur);
                mDurationUs = dur;

                media_status_t selStatus = AMediaExtractor_selectTrack(mExtractor, i);
                if (selStatus != AMEDIA_OK) {
                    LOGE("AMediaExtractor_selectTrack failed: %d", static_cast<int>(selStatus));
                    AMediaFormat_delete(format);
                    mFormat = nullptr;
                    return EngineStatus::ErrorCodec;
                }
                return EngineStatus::Ok;
            }
        }
        AMediaFormat_delete(format);
    }

    LOGE("No audio track found in file: %s", mFilePath);
    return EngineStatus::ErrorIO;
}

AMediaExtractor* LocalFileDataSource::getExtractor() const { return mExtractor; }
size_t LocalFileDataSource::getSelectedTrack() const { return mTrackIndex; }
int32_t LocalFileDataSource::getSampleRate() const { return mSampleRate; }
int32_t LocalFileDataSource::getChannelCount() const { return mChannelCount; }
int64_t LocalFileDataSource::getDurationUs() const { return mDurationUs; }
const char* LocalFileDataSource::getMimeType() const { return mMimeType; }
AMediaFormat* LocalFileDataSource::getTrackFormat() const { return mFormat; }

void LocalFileDataSource::close() {
    if (mFormat) {
        AMediaFormat_delete(mFormat);
        mFormat = nullptr;
    }
    if (mExtractor) {
        AMediaExtractor_delete(mExtractor);
        mExtractor = nullptr;
    }
    mSampleRate = 0;
    mChannelCount = 0;
    mDurationUs = 0;
    mMimeType[0] = '\0';
}

// ===========================================================================
// EncryptedStreamDataSource — stub implementation (plug-and-play ready)
// ===========================================================================

EncryptedStreamDataSource::EncryptedStreamDataSource(int64_t totalSize,
                                                     const uint8_t* key16,
                                                     const uint8_t* iv16)
    : mTotalSize(totalSize) {
    std::memcpy(mKey, key16, 16);
    std::memcpy(mIv, iv16, 16);
}

EncryptedStreamDataSource::~EncryptedStreamDataSource() {
    close();
}

EngineStatus EncryptedStreamDataSource::open() {
    // Encrypted stream ingestion is not yet active.
    // When activated, this will create an AMediaDataSource with custom readAt
    // callback backed by an in-memory chunk ring and IStreamCipher, then
    // configure an AMediaExtractor on top of it.
    return EngineStatus::ErrorIO;
}

AMediaExtractor* EncryptedStreamDataSource::getExtractor() const { return mExtractor; }
size_t EncryptedStreamDataSource::getSelectedTrack() const { return mTrackIndex; }
int32_t EncryptedStreamDataSource::getSampleRate() const { return mSampleRate; }
int32_t EncryptedStreamDataSource::getChannelCount() const { return mChannelCount; }
int64_t EncryptedStreamDataSource::getDurationUs() const { return mDurationUs; }
const char* EncryptedStreamDataSource::getMimeType() const { return mMimeType; }
AMediaFormat* EncryptedStreamDataSource::getTrackFormat() const { return mFormat; }

EngineStatus EncryptedStreamDataSource::pushChunk(int64_t /*offset*/,
                                                   const uint8_t* /*data*/,
                                                   int32_t /*length*/) {
    return EngineStatus::ErrorIO;
}

void EncryptedStreamDataSource::close() {
    if (mFormat) {
        AMediaFormat_delete(mFormat);
        mFormat = nullptr;
    }
    if (mExtractor) {
        AMediaExtractor_delete(mExtractor);
        mExtractor = nullptr;
    }
    // AMediaDataSource_delete requires API 28+. The stub never allocates
    // mNdkDataSource (open() returns ErrorIO), so no resource is leaked.
    // When encrypted streaming is implemented, raise minSdk to 28+.
    if (mNdkDataSource) {
        mNdkDataSource = nullptr;
    }
    mSampleRate = 0;
    mChannelCount = 0;
    mDurationUs = 0;
    mMimeType[0] = '\0';
}
