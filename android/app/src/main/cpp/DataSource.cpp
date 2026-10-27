#include "DataSource.h"

#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <cstring>

#include <android/log.h>

#define LOG_TAG "MusifyDataSource"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static const uint8_t kWidevineUuid[16] = {
    0xed, 0xef, 0x8b, 0xa9, 0x79, 0xd6, 0x4a, 0xce,
    0xa3, 0xc8, 0x27, 0xdc, 0xd5, 0x1d, 0x21, 0xed
};

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

    off64_t streamOffset = 0;
    off64_t streamLength = static_cast<off64_t>(st.st_size);

    uint8_t headerBuf[512];
    ssize_t bytesRead = ::pread(fd, headerBuf, sizeof(headerBuf), 0);
    if (bytesRead >= 35) {
        if (headerBuf[0] == 'O' && headerBuf[1] == 'g' && headerBuf[2] == 'g' && headerBuf[3] == 'S') {
            // Check if offset 0 is already a standard Vorbis BOS page (starts with OggS, flag 0x02, and packet \x01vorbis)
            bool isDirectVorbis = (headerBuf[5] == 0x02 &&
                                   std::memcmp(&headerBuf[28], "\x01vorbis", 7) == 0);

            if (!isDirectVorbis) {
                // Spotify head files begin with a proprietary ~167-byte wrapper page (header_type_flag == 0x06).
                // The actual Vorbis bitstream begins at the second OggS header (~offset 167) where flag == 0x02
                // and packet payload is "\x01vorbis".
                for (ssize_t i = 4; i + 35 <= bytesRead; ++i) {
                    if (headerBuf[i] == 'O' && headerBuf[i + 1] == 'g' &&
                        headerBuf[i + 2] == 'g' && headerBuf[i + 3] == 'S') {
                        if (headerBuf[i + 5] == 0x02 &&
                            std::memcmp(&headerBuf[i + 28], "\x01vorbis", 7) == 0) {
                            LOGI("Detected Spotify Vorbis head stream offset at %zd bytes (file: %s, total size: %lld)",
                                 i, mFilePath, static_cast<long long>(st.st_size));
                            streamOffset = i;
                            streamLength = static_cast<off64_t>(st.st_size) - streamOffset;
                            break;
                        }
                    }
                }
            }
        }
    }

    media_status_t status = AMediaExtractor_setDataSourceFd(
        mExtractor, fd, streamOffset, streamLength);
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
// HttpMediaDataSource
// ===========================================================================

HttpMediaDataSource::HttpMediaDataSource(const char* url, const char* authHeader) {
    if (url) {
        std::strncpy(mUrl, url, sizeof(mUrl) - 1);
        mUrl[sizeof(mUrl) - 1] = '\0';
    }
    if (authHeader) {
        std::strncpy(mAuthHeader, authHeader, sizeof(mAuthHeader) - 1);
        mAuthHeader[sizeof(mAuthHeader) - 1] = '\0';
    }
}

HttpMediaDataSource::~HttpMediaDataSource() {
    close();
}

EngineStatus HttpMediaDataSource::open() {
    close();

    mExtractor = AMediaExtractor_new();
    if (!mExtractor) {
        LOGE("AMediaExtractor_new failed for remote URL");
        return EngineStatus::ErrorCodec;
    }

    media_status_t status = AMediaExtractor_setDataSource(mExtractor, mUrl);
    if (status != AMEDIA_OK) {
        LOGE("AMediaExtractor_setDataSource failed for URL %s: %d", mUrl, static_cast<int>(status));
        AMediaExtractor_delete(mExtractor);
        mExtractor = nullptr;
        return EngineStatus::ErrorIO;
    }

    EngineStatus trackStatus = selectAudioTrack();
    if (trackStatus != EngineStatus::Ok) {
        return trackStatus;
    }

    extractWidevinePssh();
    return EngineStatus::Ok;
}

EngineStatus HttpMediaDataSource::selectAudioTrack() {
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
                    LOGE("AMediaExtractor_selectTrack failed for remote: %d", static_cast<int>(selStatus));
                    AMediaFormat_delete(format);
                    mFormat = nullptr;
                    return EngineStatus::ErrorCodec;
                }
                LOGI("Selected remote audio track %zu: mime=%s sr=%d cc=%d dur=%lldus",
                     i, mMimeType, mSampleRate, mChannelCount, static_cast<long long>(mDurationUs));
                return EngineStatus::Ok;
            }
        }
        AMediaFormat_delete(format);
    }

    LOGE("No audio track found in remote URL: %s", mUrl);
    return EngineStatus::ErrorIO;
}

void HttpMediaDataSource::extractWidevinePssh() {
    mHasPssh = false;
    mPsshData.clear();

    PsshInfo* psshInfo = AMediaExtractor_getPsshInfo(mExtractor);
    if (!psshInfo) {
        LOGI("No PSSH info found in media container");
        return;
    }

    for (size_t i = 0; i < psshInfo->numentries; ++i) {
        const PsshEntry& entry = psshInfo->entries[i];
        if (std::memcmp(entry.uuid, kWidevineUuid, 16) == 0) {
            if (entry.data && entry.datalen > 0) {
                const auto* bytes = static_cast<const uint8_t*>(entry.data);
                mPsshData.assign(bytes, bytes + entry.datalen);
                mHasPssh = true;
                LOGI("Found Widevine PSSH box (%zu bytes)", entry.datalen);
                break;
            }
        }
    }
}

AMediaExtractor* HttpMediaDataSource::getExtractor() const { return mExtractor; }
size_t HttpMediaDataSource::getSelectedTrack() const { return mTrackIndex; }
int32_t HttpMediaDataSource::getSampleRate() const { return mSampleRate; }
int32_t HttpMediaDataSource::getChannelCount() const { return mChannelCount; }
int64_t HttpMediaDataSource::getDurationUs() const { return mDurationUs; }
const char* HttpMediaDataSource::getMimeType() const { return mMimeType; }
AMediaFormat* HttpMediaDataSource::getTrackFormat() const { return mFormat; }

void HttpMediaDataSource::close() {
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
    mHasPssh = false;
    mPsshData.clear();
}

// ===========================================================================
// EncryptedStreamDataSource
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
    if (mNdkDataSource) {
        mNdkDataSource = nullptr;
    }
    mSampleRate = 0;
    mChannelCount = 0;
    mDurationUs = 0;
    mMimeType[0] = '\0';
}
