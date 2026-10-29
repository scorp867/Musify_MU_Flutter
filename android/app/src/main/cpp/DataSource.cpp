#include "DataSource.h"

#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <cstring>
#include <thread>
#include <chrono>
#include <dlfcn.h>

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
// ProgressiveFileDataSource
// ===========================================================================

typedef ssize_t (*FnAMediaDataSourceReadAt)(void* userdata, off64_t offset, void* buffer, size_t size);
typedef off64_t (*FnAMediaDataSourceGetSize)(void* userdata);

typedef AMediaDataSource* (*FnAMediaDataSource_new)();
typedef void (*FnAMediaDataSource_delete)(AMediaDataSource*);
typedef void (*FnAMediaDataSource_setUserdata)(AMediaDataSource*, void*);
typedef void (*FnAMediaDataSource_setReadAt)(AMediaDataSource*, FnAMediaDataSourceReadAt);
typedef void (*FnAMediaDataSource_setGetSize)(AMediaDataSource*, FnAMediaDataSourceGetSize);
typedef media_status_t (*FnAMediaExtractor_setDataSourceCustom)(AMediaExtractor*, AMediaDataSource*);

struct NdkMediaDataSourceApi {
    FnAMediaDataSource_new dsNew{nullptr};
    FnAMediaDataSource_delete dsDelete{nullptr};
    FnAMediaDataSource_setUserdata dsSetUserdata{nullptr};
    FnAMediaDataSource_setReadAt dsSetReadAt{nullptr};
    FnAMediaDataSource_setGetSize dsSetGetSize{nullptr};
    FnAMediaExtractor_setDataSourceCustom exSetCustom{nullptr};
    bool isAvailable{false};

    NdkMediaDataSourceApi() {
        void* handle = dlopen("libmediandk.so", RTLD_NOW);
        if (handle) {
            dsNew = reinterpret_cast<FnAMediaDataSource_new>(dlsym(handle, "AMediaDataSource_new"));
            dsDelete = reinterpret_cast<FnAMediaDataSource_delete>(dlsym(handle, "AMediaDataSource_delete"));
            dsSetUserdata = reinterpret_cast<FnAMediaDataSource_setUserdata>(dlsym(handle, "AMediaDataSource_setUserdata"));
            dsSetReadAt = reinterpret_cast<FnAMediaDataSource_setReadAt>(dlsym(handle, "AMediaDataSource_setReadAt"));
            dsSetGetSize = reinterpret_cast<FnAMediaDataSource_setGetSize>(dlsym(handle, "AMediaDataSource_setGetSize"));
            exSetCustom = reinterpret_cast<FnAMediaExtractor_setDataSourceCustom>(dlsym(handle, "AMediaExtractor_setDataSourceCustom"));
            isAvailable = (dsNew && dsDelete && dsSetUserdata && dsSetReadAt && dsSetGetSize && exSetCustom);
        }
    }

    static const NdkMediaDataSourceApi& get() {
        static NdkMediaDataSourceApi instance;
        return instance;
    }
};

static ssize_t progressiveReadAtCallback(void* userdata, off64_t offset, void* buffer, size_t size) {
    if (!userdata) return 0;
    auto* source = static_cast<ProgressiveFileDataSource*>(userdata);
    return source->readAt(offset, buffer, size);
}

static off64_t progressiveGetSizeCallback(void* userdata) {
    if (!userdata) return 0;
    auto* source = static_cast<ProgressiveFileDataSource*>(userdata);
    return source->getSize();
}

ProgressiveFileDataSource::ProgressiveFileDataSource(const char* filePath, int64_t expectedTotalSize)
    : mExpectedTotalSize(expectedTotalSize > 0 ? expectedTotalSize : 131072) {
    if (filePath) {
        std::strncpy(mFilePath, filePath, sizeof(mFilePath) - 1);
        mFilePath[sizeof(mFilePath) - 1] = '\0';
    }
}

ProgressiveFileDataSource::~ProgressiveFileDataSource() {
    close();
}

EngineStatus ProgressiveFileDataSource::open() {
    close();

    // Check if streaming file exists. If it is currently being created, wait briefly for initial bytes (up to 500ms)
    int attempts = 0;
    while (attempts < 50) {
        mFd = ::open(mFilePath, O_RDONLY);
        if (mFd >= 0) {
            struct stat st{};
            if (::fstat(mFd, &st) == 0 && st.st_size >= 512) {
                break;
            }
            ::close(mFd);
            mFd = -1;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        attempts++;
    }

    if (mFd < 0) {
        LOGE("ProgressiveFileDataSource: Cannot open streaming file %s", mFilePath);
        return EngineStatus::ErrorIO;
    }

    // Detect Spotify ~167-byte wrapper page
    uint8_t headerBuf[512];
    ssize_t bytesRead = ::pread(mFd, headerBuf, sizeof(headerBuf), 0);
    if (bytesRead >= 35) {
        if (headerBuf[0] == 'O' && headerBuf[1] == 'g' && headerBuf[2] == 'g' && headerBuf[3] == 'S') {
            bool isDirectVorbis = (headerBuf[5] == 0x02 &&
                                   std::memcmp(&headerBuf[28], "\x01vorbis", 7) == 0);
            if (!isDirectVorbis) {
                for (ssize_t i = 4; i + 35 <= bytesRead; ++i) {
                    if (headerBuf[i] == 'O' && headerBuf[i + 1] == 'g' &&
                        headerBuf[i + 2] == 'g' && headerBuf[i + 3] == 'S') {
                        if (headerBuf[i + 5] == 0x02 &&
                            std::memcmp(&headerBuf[i + 28], "\x01vorbis", 7) == 0) {
                            LOGI("Detected Spotify Vorbis head stream offset at %zd bytes in streaming file %s",
                                 i, mFilePath);
                            mStreamOffset = i;
                            break;
                        }
                    }
                }
            }
        }
    }

    mExtractor = AMediaExtractor_new();
    if (!mExtractor) {
        LOGE("AMediaExtractor_new failed for progressive data source");
        ::close(mFd);
        mFd = -1;
        return EngineStatus::ErrorCodec;
    }

    const auto& api = NdkMediaDataSourceApi::get();
    if (api.isAvailable) {
        mNdkDataSource = api.dsNew();
        if (mNdkDataSource) {
            api.dsSetUserdata(mNdkDataSource, this);
            api.dsSetReadAt(mNdkDataSource, progressiveReadAtCallback);
            api.dsSetGetSize(mNdkDataSource, progressiveGetSizeCallback);
            media_status_t status = api.exSetCustom(mExtractor, mNdkDataSource);
            if (status == AMEDIA_OK) {
                return selectAudioTrack();
            }
            api.dsDelete(mNdkDataSource);
            mNdkDataSource = nullptr;
        }
    }

    // Fallback if AMediaDataSource is unavailable on older API levels
    struct stat st{};
    off64_t streamLength = 131072;
    if (::fstat(mFd, &st) == 0 && st.st_size > mStreamOffset) {
        streamLength = st.st_size - mStreamOffset;
    }
    media_status_t status = AMediaExtractor_setDataSourceFd(mExtractor, mFd, mStreamOffset, streamLength);
    if (status != AMEDIA_OK) {
        LOGE("AMediaExtractor_setDataSourceFd fallback failed: %d", static_cast<int>(status));
        AMediaExtractor_delete(mExtractor);
        mExtractor = nullptr;
        ::close(mFd);
        mFd = -1;
        return EngineStatus::ErrorIO;
    }

    return selectAudioTrack();
}

EngineStatus ProgressiveFileDataSource::selectAudioTrack() {
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
                    LOGE("AMediaExtractor_selectTrack failed for progressive stream: %d", static_cast<int>(selStatus));
                    AMediaFormat_delete(format);
                    mFormat = nullptr;
                    return EngineStatus::ErrorCodec;
                }
                return EngineStatus::Ok;
            }
        }
        AMediaFormat_delete(format);
    }

    LOGE("No audio track found in progressive file: %s", mFilePath);
    return EngineStatus::ErrorIO;
}

ssize_t ProgressiveFileDataSource::readAt(off64_t offset, void* buffer, size_t size) {
    if (mFd < 0 || !buffer || size == 0) return 0;

    const off64_t actualOffset = offset + mStreamOffset;

    // Up to 3.0 seconds wait in 10ms intervals for bytes streaming to disk
    int attempts = 0;
    while (attempts < 300) {
        struct stat st{};
        if (::fstat(mFd, &st) == 0) {
            if (actualOffset < st.st_size) {
                size_t available = static_cast<size_t>(st.st_size - actualOffset);
                size_t toRead = (size < available) ? size : available;
                ssize_t bytesRead = ::pread(mFd, buffer, toRead, actualOffset);
                return bytesRead >= 0 ? bytesRead : 0;
            }
        }

        // Check if stream finished and file was renamed from .part to final .ogg
        char finalPath[4096]{};
        std::strncpy(finalPath, mFilePath, sizeof(finalPath) - 1);
        size_t len = std::strlen(finalPath);
        if (len > 5 && std::strcmp(finalPath + len - 5, ".part") == 0) {
            finalPath[len - 5] = '\0';
            struct stat finalSt{};
            if (::stat(finalPath, &finalSt) == 0 && finalSt.st_size >= 512) {
                if (::fstat(mFd, &st) == 0 && actualOffset >= st.st_size) {
                    return 0; // Natural EOF
                }
            }
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        attempts++;
    }

    return 0;
}

off64_t ProgressiveFileDataSource::getSize() {
    return (mExpectedTotalSize > mStreamOffset) ? (mExpectedTotalSize - mStreamOffset) : 0;
}

AMediaExtractor* ProgressiveFileDataSource::getExtractor() const { return mExtractor; }
size_t ProgressiveFileDataSource::getSelectedTrack() const { return mTrackIndex; }
int32_t ProgressiveFileDataSource::getSampleRate() const { return mSampleRate; }
int32_t ProgressiveFileDataSource::getChannelCount() const { return mChannelCount; }
int64_t ProgressiveFileDataSource::getDurationUs() const { return mDurationUs; }
const char* ProgressiveFileDataSource::getMimeType() const { return mMimeType; }
AMediaFormat* ProgressiveFileDataSource::getTrackFormat() const { return mFormat; }

void ProgressiveFileDataSource::close() {
    if (mFormat) {
        AMediaFormat_delete(mFormat);
        mFormat = nullptr;
    }
    if (mExtractor) {
        AMediaExtractor_delete(mExtractor);
        mExtractor = nullptr;
    }
    if (mNdkDataSource) {
        const auto& api = NdkMediaDataSourceApi::get();
        if (api.dsDelete) {
            api.dsDelete(mNdkDataSource);
        }
        mNdkDataSource = nullptr;
    }
    if (mFd >= 0) {
        ::close(mFd);
        mFd = -1;
    }
    mSampleRate = 0;
    mChannelCount = 0;
    mDurationUs = 0;
    mMimeType[0] = '\0';
    mStreamOffset = 0;
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

void HttpMediaDataSource::buildWidevinePsshBox(const uint8_t* kidBytes, size_t kidLen,
                                              const uint8_t* contentIdBytes, size_t contentIdLen,
                                              uint32_t protectionScheme) {
    mPsshData.clear();
    if (!kidBytes || kidLen == 0) return;

    // Build WidevineCencHeader protobuf matching Spotify's 1:1 schema:
    // field 1 (algorithm = AES_CTR = 1): tag = (1 << 3) | 0 = 0x08, val = 1
    // field 2 (key_id): tag = (2 << 3) | 2 = 0x12, len = kidLen, kidBytes
    // field 3 (provider = "spotify"): tag = (3 << 3) | 2 = 0x1a, len = 7, "spotify"
    // field 4 (content_id): tag = (4 << 3) | 2 = 0x22, len = contentIdLen, contentIdBytes
    // field 9 (protection_scheme = 4CC varint, 0x63626373 for 'cbcs', 0x63656e63 for 'cenc'): tag = (9 << 3) | 0 = 0x48, varint
    std::vector<uint8_t> payload;

    // Field 1: algorithm = 1 (AES_CTR)
    payload.push_back(0x08);
    payload.push_back(0x01);

    // Field 2: key_id
    payload.push_back(0x12);
    payload.push_back(static_cast<uint8_t>(kidLen));
    payload.insert(payload.end(), kidBytes, kidBytes + kidLen);

    // Field 3: provider = "spotify"
    const char* provider = "spotify";
    payload.push_back(0x1a);
    payload.push_back(static_cast<uint8_t>(std::strlen(provider)));
    payload.insert(payload.end(), provider, provider + std::strlen(provider));

    // Field 4: content_id
    if (contentIdBytes && contentIdLen > 0) {
        payload.push_back(0x22);
        payload.push_back(static_cast<uint8_t>(contentIdLen));
        payload.insert(payload.end(), contentIdBytes, contentIdBytes + contentIdLen);
    }

    // Field 9: protection_scheme (0x63656e63 for 'cenc')
    if (protectionScheme != 0) {
        payload.push_back(0x48); // (9 << 3) | 0
        uint32_t val = protectionScheme;
        while (val > 0x7F) {
            payload.push_back(static_cast<uint8_t>((val & 0x7F) | 0x80));
            val >>= 7;
        }
        payload.push_back(static_cast<uint8_t>(val & 0x7F));
    }

    // Full PSSH box (Version 0):
    // [4B size][4B 'pssh'][4B version/flags][16B UUID][4B dataSize][payload]
    uint32_t totalSize = 32 + static_cast<uint32_t>(payload.size());
    mPsshData.reserve(totalSize);

    mPsshData.push_back((totalSize >> 24) & 0xFF);
    mPsshData.push_back((totalSize >> 16) & 0xFF);
    mPsshData.push_back((totalSize >> 8) & 0xFF);
    mPsshData.push_back(totalSize & 0xFF);

    mPsshData.push_back('p');
    mPsshData.push_back('s');
    mPsshData.push_back('s');
    mPsshData.push_back('h');

    // Version 0, Flags 0
    mPsshData.push_back(0x00);
    mPsshData.push_back(0x00);
    mPsshData.push_back(0x00);
    mPsshData.push_back(0x00);

    // Widevine UUID: edef8ba9-79d6-4ace-a3c8-27dcd51d21ed
    mPsshData.insert(mPsshData.end(), kWidevineUuid, kWidevineUuid + 16);

    // Data length (big-endian)
    uint32_t dataLen = static_cast<uint32_t>(payload.size());
    mPsshData.push_back((dataLen >> 24) & 0xFF);
    mPsshData.push_back((dataLen >> 16) & 0xFF);
    mPsshData.push_back((dataLen >> 8) & 0xFF);
    mPsshData.push_back(dataLen & 0xFF);

    // Data payload
    mPsshData.insert(mPsshData.end(), payload.begin(), payload.end());
    mHasPssh = true;
}

void HttpMediaDataSource::extractWidevinePssh() {
    mHasPssh = false;
    mPsshData.clear();

    // 1. Try AMediaExtractor_getPsshInfo - ONLY match Widevine UUID.
    // Never extract or treat non-Widevine entries (such as PlayReady XML headers) as KIDs.
    PsshInfo* psshInfo = AMediaExtractor_getPsshInfo(mExtractor);
    if (psshInfo) {
        for (size_t i = 0; i < psshInfo->numentries; ++i) {
            const PsshEntry& entry = psshInfo->entries[i];
            if (std::memcmp(entry.uuid, kWidevineUuid, 16) == 0) {
                if (entry.data && entry.datalen > 0) {
                    const auto* bytes = static_cast<const uint8_t*>(entry.data);
                    mPsshData.assign(bytes, bytes + entry.datalen);
                    mHasPssh = true;
                    LOGI("Found Widevine PSSH box via AMediaExtractor (%zu bytes)", entry.datalen);
                    return;
                }
            }
        }
    }

    // 2. If no Widevine PSSH in container (standard for remote HTTP streaming on Android),
    // derive the 16-byte Key ID and 20-byte Content ID directly from the Spotify stream URL.
    // Spotify stream URLs are in the format:
    // .../audio/{40-hex-file-id}?__token__=... or .../head/{40-hex-file-id}
    const char* audioPattern = "/audio/";
    const char* match = std::strstr(mUrl, audioPattern);
    if (!match) {
        audioPattern = "/head/";
        match = std::strstr(mUrl, audioPattern);
    }

    if (match) {
        const char* hexStart = match + std::strlen(audioPattern);
        bool isHex = true;
        for (int i = 0; i < 40; ++i) {
            char c = hexStart[i];
            if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'))) {
                isHex = false;
                break;
            }
        }
        if (isHex) {
            uint8_t fileId[20];
            for (int i = 0; i < 20; ++i) {
                char byteHex[3] = { hexStart[i * 2], hexStart[i * 2 + 1], '\0' };
                fileId[i] = static_cast<uint8_t>(std::strtoul(byteHex, nullptr, 16));
            }
            // Dynamically detect protection scheme from track format crypto-mode:
            // In Android Stagefright, kCryptoModeAesCtr = 1 ('cenc'), kCryptoModeAesCbc = 2 ('cbcs').
            // Spotify remote AAC audio streams in MP4 containers use 'cbcs' (0x63626373).
            uint32_t protectionScheme = 0x63626373; // Default 'cbcs'
            int32_t cryptoMode = 0;
            if (mFormat && AMediaFormat_getInt32(mFormat, "crypto-mode", &cryptoMode)) {
                if (cryptoMode == 1) {
                    protectionScheme = 0x63656e63; // 'cenc'
                } else if (cryptoMode == 2) {
                    protectionScheme = 0x63626373; // 'cbcs'
                }
            }

            buildWidevinePsshBox(fileId, 16, fileId, 20, protectionScheme);
            LOGI("Derived Spotify Widevine PSSH box from URL file ID (%zu bytes, kid=16, content_id=20, scheme=%s)",
                 mPsshData.size(), protectionScheme == 0x63626373 ? "cbcs" : "cenc");
            return;
        }
    }

    LOGI("No PSSH info found in media container or URL");
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
