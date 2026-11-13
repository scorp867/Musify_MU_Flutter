#include "DataSource.h"

#include <android/log.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

#include <chrono>
#include <cstdlib>
#include <cstring>
#include <limits>

#define LOG_TAG "MusifyDataSource"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace {

const uint8_t kWidevineUuid[16] = {
    0xed, 0xef, 0x8b, 0xa9, 0x79, 0xd6, 0x4a, 0xce,
    0xa3, 0xc8, 0x27, 0xdc, 0xd5, 0x1d, 0x21, 0xed
};

/// Shared audio track selector across Local, Progressive, and HTTP extractors.
EngineStatus selectFirstAudioTrack(
    AMediaExtractor* extractor,
    size_t& outTrackIndex,
    AMediaFormat*& outFormat,
    char (&outMimeType)[128],
    int32_t& outSampleRate,
    int32_t& outChannelCount,
    int64_t& outDurationUs,
    const char* contextLabel) {
    const size_t trackCount = AMediaExtractor_getTrackCount(extractor);
    for (size_t i = 0; i < trackCount; ++i) {
        AMediaFormat* format = AMediaExtractor_getTrackFormat(extractor, i);
        const char* mime = nullptr;
        if (AMediaFormat_getString(format, AMEDIAFORMAT_KEY_MIME, &mime) && mime) {
            if (std::strncmp(mime, "audio/", 6) == 0) {
                outTrackIndex = i;
                outFormat = format;
                std::strncpy(outMimeType, mime, sizeof(outMimeType) - 1);
                outMimeType[sizeof(outMimeType) - 1] = '\0';

                int32_t sr = 0;
                AMediaFormat_getInt32(format, AMEDIAFORMAT_KEY_SAMPLE_RATE, &sr);
                outSampleRate = sr;

                int32_t cc = 0;
                AMediaFormat_getInt32(format, AMEDIAFORMAT_KEY_CHANNEL_COUNT, &cc);
                outChannelCount = cc;

                int64_t dur = 0;
                AMediaFormat_getInt64(format, AMEDIAFORMAT_KEY_DURATION, &dur);
                outDurationUs = dur;

                media_status_t selStatus = AMediaExtractor_selectTrack(extractor, i);
                if (selStatus != AMEDIA_OK) {
                    LOGE("AMediaExtractor_selectTrack failed (%s): %d",
                         contextLabel, static_cast<int>(selStatus));
                    AMediaFormat_delete(format);
                    outFormat = nullptr;
                    return EngineStatus::ErrorCodec;
                }
                return EngineStatus::Ok;
            }
        }
        AMediaFormat_delete(format);
    }

    LOGE("No audio track found (%s)", contextLabel);
    return EngineStatus::ErrorIO;
}

/// Scans the leading header bytes for Spotify's proprietary ~167-byte wrapper page so
/// AMediaExtractor starts cleanly on the canonical Vorbis BOS OggS page.
off64_t detectVorbisStreamOffset(int fd, const char* label) {
    uint8_t headerBuf[512];
    ssize_t bytesRead = ::pread(fd, headerBuf, sizeof(headerBuf), 0);
    if (bytesRead >= 35 &&
        headerBuf[0] == 'O' && headerBuf[1] == 'g' &&
        headerBuf[2] == 'g' && headerBuf[3] == 'S') {
        const bool isDirectVorbis = (headerBuf[5] == 0x02 &&
                                     std::memcmp(&headerBuf[28], "\x01vorbis", 7) == 0);
        if (!isDirectVorbis) {
            for (ssize_t i = 4; i + 35 <= bytesRead; ++i) {
                if (headerBuf[i] == 'O' && headerBuf[i + 1] == 'g' &&
                    headerBuf[i + 2] == 'g' && headerBuf[i + 3] == 'S' &&
                    headerBuf[i + 5] == 0x02 &&
                    std::memcmp(&headerBuf[i + 28], "\x01vorbis", 7) == 0) {
                    LOGI("Detected Spotify Vorbis head stream offset at %zd bytes (%s)",
                         i, label);
                    return static_cast<off64_t>(i);
                }
            }
        }
    }
    return 0;
}

ssize_t toNdkDataSourceSize(off64_t size) {
    if (size < 0 || size > static_cast<off64_t>(std::numeric_limits<ssize_t>::max())) {
        return -1;
    }
    return static_cast<ssize_t>(size);
}

ssize_t progressiveReadAtCallback(void* userdata, off64_t offset, void* buffer, size_t size) {
    if (!userdata) return -1;
    return static_cast<ProgressiveFileDataSource*>(userdata)->readAt(offset, buffer, size);
}

ssize_t progressiveGetSizeCallback(void* userdata) {
    if (!userdata) return -1;
    return toNdkDataSourceSize(static_cast<ProgressiveFileDataSource*>(userdata)->getSize());
}

void progressiveCloseCallback(void* userdata) {
    if (userdata) {
        static_cast<ProgressiveFileDataSource*>(userdata)->cancel();
    }
}

ssize_t httpReadAtCallback(void* userdata, off64_t offset, void* buffer, size_t size) {
    if (!userdata) return -1;
    return static_cast<HttpMediaDataSource*>(userdata)->readAt(offset, buffer, size);
}

ssize_t httpGetSizeCallback(void* userdata) {
    if (!userdata) return -1;
    return toNdkDataSourceSize(static_cast<HttpMediaDataSource*>(userdata)->getSize());
}

void httpCloseCallback(void* userdata) {
    if (userdata) {
        static_cast<HttpMediaDataSource*>(userdata)->onDataSourceClose();
    }
}

} // namespace

// ===========================================================================
// LocalFileDataSource
// ===========================================================================

LocalFileDataSource::LocalFileDataSource(const char* filePath) {
    if (filePath) {
        std::strncpy(mFilePath, filePath, sizeof(mFilePath) - 1);
        mFilePath[sizeof(mFilePath) - 1] = '\0';
    }
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

    const off64_t streamOffset = detectVorbisStreamOffset(fd, mFilePath);
    const off64_t streamLength = (st.st_size > streamOffset)
                                     ? (static_cast<off64_t>(st.st_size) - streamOffset)
                                     : 0;

    media_status_t status = AMediaExtractor_setDataSourceFd(
        mExtractor, fd, streamOffset, streamLength);
    ::close(fd);

    if (status != AMEDIA_OK) {
        LOGE("AMediaExtractor_setDataSourceFd failed: %d", static_cast<int>(status));
        AMediaExtractor_delete(mExtractor);
        mExtractor = nullptr;
        return EngineStatus::ErrorIO;
    }

    return selectFirstAudioTrack(
        mExtractor, mTrackIndex, mFormat, mMimeType,
        mSampleRate, mChannelCount, mDurationUs, mFilePath);
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

void ProgressiveFileDataSource::cancel() {
    mCanceled.store(true, std::memory_order_release);
    std::lock_guard<std::mutex> lock(mCancelMutex);
    mCancelCv.notify_all();
}

EngineStatus ProgressiveFileDataSource::open() {
    close();
    mCanceled.store(false, std::memory_order_release);

    // Wait up to 500ms (abortable immediately via cancel()) for initial 512 bytes.
    for (int attempt = 0; attempt < 50; ++attempt) {
        if (mCanceled.load(std::memory_order_acquire)) {
            return EngineStatus::ErrorIO;
        }
        mFd = ::open(mFilePath, O_RDONLY);
        if (mFd >= 0) {
            struct stat st{};
            if (::fstat(mFd, &st) == 0 && st.st_size >= 512) {
                break;
            }
            ::close(mFd);
            mFd = -1;
        }
        std::unique_lock<std::mutex> lock(mCancelMutex);
        mCancelCv.wait_for(lock, std::chrono::milliseconds(2), [this]() {
            return mCanceled.load(std::memory_order_acquire);
        });
    }

    if (mFd < 0) {
        LOGE("ProgressiveFileDataSource: Cannot open streaming file %s", mFilePath);
        return EngineStatus::ErrorIO;
    }

    mStreamOffset = detectVorbisStreamOffset(mFd, mFilePath);

    mExtractor = AMediaExtractor_new();
    if (!mExtractor) {
        LOGE("AMediaExtractor_new failed for progressive data source");
        close();
        return EngineStatus::ErrorCodec;
    }

    mNdkDataSource = AMediaDataSource_new();
    if (!mNdkDataSource) {
        LOGE("AMediaDataSource_new failed for progressive data source");
        close();
        return EngineStatus::ErrorCodec;
    }

    AMediaDataSource_setUserdata(mNdkDataSource, this);
    AMediaDataSource_setReadAt(mNdkDataSource, progressiveReadAtCallback);
    AMediaDataSource_setGetSize(mNdkDataSource, progressiveGetSizeCallback);
    AMediaDataSource_setClose(mNdkDataSource, progressiveCloseCallback);

    media_status_t status = AMediaExtractor_setDataSourceCustom(mExtractor, mNdkDataSource);
    if (status != AMEDIA_OK) {
        LOGE("AMediaExtractor_setDataSourceCustom failed for progressive file: %d",
             static_cast<int>(status));
        close();
        return EngineStatus::ErrorIO;
    }

    return selectFirstAudioTrack(
        mExtractor, mTrackIndex, mFormat, mMimeType,
        mSampleRate, mChannelCount, mDurationUs, mFilePath);
}

ssize_t ProgressiveFileDataSource::readAt(off64_t offset, void* buffer, size_t size) {
    if (mCanceled.load(std::memory_order_acquire) || mFd < 0 || !buffer) {
        return -1;
    }
    if (size == 0) {
        return 0;
    }

    const off64_t actualOffset = offset + mStreamOffset;

    for (int attempt = 0; attempt < 300; ++attempt) {
        if (mCanceled.load(std::memory_order_acquire)) {
            return -1;
        }

        struct stat st{};
        if (::fstat(mFd, &st) == 0) {
            if (actualOffset < st.st_size) {
                const size_t available = static_cast<size_t>(st.st_size - actualOffset);
                const size_t toRead = (size < available) ? size : available;
                const ssize_t bytesRead = ::pread(mFd, buffer, toRead, actualOffset);
                return bytesRead >= 0 ? bytesRead : -1;
            }
        }

        // Check if download finished and atomic rename moved .part -> final .ogg
        char finalPath[4096]{};
        std::strncpy(finalPath, mFilePath, sizeof(finalPath) - 1);
        const size_t len = std::strlen(finalPath);
        if (len > 5 && std::strcmp(finalPath + len - 5, ".part") == 0) {
            finalPath[len - 5] = '\0';
            struct stat finalSt{};
            if (::stat(finalPath, &finalSt) == 0 && finalSt.st_size >= 512) {
                if (::fstat(mFd, &st) == 0 && actualOffset >= st.st_size) {
                    return 0; // Natural EOF
                }
            }
        }

        std::unique_lock<std::mutex> lock(mCancelMutex);
        mCancelCv.wait_for(lock, std::chrono::milliseconds(2), [this]() {
            return mCanceled.load(std::memory_order_acquire);
        });
    }

    return -1;
}

off64_t ProgressiveFileDataSource::getSize() {
    // Unknown/streaming length lets AMediaExtractor read cleanly until readAt returns 0 at EOF.
    // Check if final renamed .ogg exists first so natural EOF matches exact size.
    char finalPath[4096]{};
    std::strncpy(finalPath, mFilePath, sizeof(finalPath) - 1);
    const size_t len = std::strlen(finalPath);
    if (len > 5 && std::strcmp(finalPath + len - 5, ".part") == 0) {
        finalPath[len - 5] = '\0';
        struct stat finalSt{};
        if (::stat(finalPath, &finalSt) == 0 && finalSt.st_size > mStreamOffset) {
            return static_cast<off64_t>(finalSt.st_size) - mStreamOffset;
        }
    }
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
    cancel();
    if (mFormat) {
        AMediaFormat_delete(mFormat);
        mFormat = nullptr;
    }
    if (mExtractor) {
        AMediaExtractor_delete(mExtractor);
        mExtractor = nullptr;
    }
    if (mNdkDataSource) {
        AMediaDataSource_delete(mNdkDataSource);
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
// HttpMediaDataSource (Pure C++ libcurl + mbedTLS AMediaDataSource)
// ===========================================================================

HttpMediaDataSource::HttpMediaDataSource(const char* url, const char* authHeader) {
    if (url && url[0] != '\0') {
        std::strncpy(mUrl, url, sizeof(mUrl) - 1);
        mUrl[sizeof(mUrl) - 1] = '\0';
        mUrls.emplace_back(mUrl);
    }
    if (authHeader) {
        std::strncpy(mAuthHeader, authHeader, sizeof(mAuthHeader) - 1);
        mAuthHeader[sizeof(mAuthHeader) - 1] = '\0';
    }
}

HttpMediaDataSource::HttpMediaDataSource(
    std::vector<std::string> urls,
    const char* authHeader,
    spotify::network::UrlRefreshCallback urlRefreshCb)
    : mUrls(std::move(urls)),
      mUrlRefreshCb(std::move(urlRefreshCb)) {
    if (!mUrls.empty()) {
        std::strncpy(mUrl, mUrls.front().c_str(), sizeof(mUrl) - 1);
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

void HttpMediaDataSource::cancel() {
    mCanceled.store(true, std::memory_order_release);
    std::shared_ptr<spotify::network::HttpRangeStreamCache> cacheSnapshot;
    {
        std::lock_guard<std::mutex> lock(mCacheMutex);
        cacheSnapshot = mCache;
    }
    if (cacheSnapshot) {
        cacheSnapshot->cancel();
    }
}

void HttpMediaDataSource::preemptPrefetch() {
    std::shared_ptr<spotify::network::HttpRangeStreamCache> cacheSnapshot;
    {
        std::lock_guard<std::mutex> lock(mCacheMutex);
        cacheSnapshot = mCache;
    }
    if (cacheSnapshot) {
        cacheSnapshot->preemptPrefetch();
    }
}

EngineStatus HttpMediaDataSource::open() {
    close();
    mCanceled.store(false, std::memory_order_release);

    if (mUrls.empty()) {
        LOGE("HttpMediaDataSource::open called with empty CDN URL list");
        return EngineStatus::ErrorInvalidArg;
    }

    auto cache = std::make_shared<spotify::network::HttpRangeStreamCache>(
        mUrls,
        std::vector<std::pair<std::string, std::string>>{},
        mUrlRefreshCb);

    {
        std::lock_guard<std::mutex> lock(mCacheMutex);
        mCache = cache;
    }

    if (mCanceled.load(std::memory_order_acquire) || !cache->open()) {
        LOGE("HttpRangeStreamCache::open failed for %s", mUrl);
        close();
        return EngineStatus::ErrorIO;
    }

    mExtractor = AMediaExtractor_new();
    if (!mExtractor) {
        LOGE("AMediaExtractor_new failed for HTTP data source");
        close();
        return EngineStatus::ErrorCodec;
    }

    mNdkDataSource = AMediaDataSource_new();
    if (!mNdkDataSource) {
        LOGE("AMediaDataSource_new failed for HTTP data source");
        close();
        return EngineStatus::ErrorCodec;
    }

    AMediaDataSource_setUserdata(mNdkDataSource, this);
    AMediaDataSource_setReadAt(mNdkDataSource, httpReadAtCallback);
    AMediaDataSource_setGetSize(mNdkDataSource, httpGetSizeCallback);
    AMediaDataSource_setClose(mNdkDataSource, httpCloseCallback);

    media_status_t status = AMediaExtractor_setDataSourceCustom(mExtractor, mNdkDataSource);
    if (status != AMEDIA_OK) {
        LOGE("AMediaExtractor_setDataSourceCustom failed for URL %s: %d",
             mUrl, static_cast<int>(status));
        close();
        return EngineStatus::ErrorIO;
    }

    EngineStatus trackStatus = selectFirstAudioTrack(
        mExtractor, mTrackIndex, mFormat, mMimeType,
        mSampleRate, mChannelCount, mDurationUs, mUrl);
    if (trackStatus != EngineStatus::Ok) {
        return trackStatus;
    }

    LOGI("Selected remote audio track %zu: mime=%s sr=%d cc=%d dur=%lldus",
         mTrackIndex, mMimeType, mSampleRate, mChannelCount, static_cast<long long>(mDurationUs));
    extractWidevinePssh();
    return EngineStatus::Ok;
}

ssize_t HttpMediaDataSource::readAt(off64_t offset, void* buffer, size_t size) {
    if (mCanceled.load(std::memory_order_acquire)) {
        return -1;
    }
    std::shared_ptr<spotify::network::HttpRangeStreamCache> cacheSnapshot;
    {
        std::lock_guard<std::mutex> lock(mCacheMutex);
        cacheSnapshot = mCache;
    }
    if (!cacheSnapshot) {
        return -1;
    }
    return cacheSnapshot->readAt(static_cast<int64_t>(offset), buffer, size);
}

off64_t HttpMediaDataSource::getSize() {
    std::shared_ptr<spotify::network::HttpRangeStreamCache> cacheSnapshot;
    {
        std::lock_guard<std::mutex> lock(mCacheMutex);
        cacheSnapshot = mCache;
    }
    if (!cacheSnapshot) {
        return -1;
    }
    return static_cast<off64_t>(cacheSnapshot->getSize());
}

void HttpMediaDataSource::onDataSourceClose() {
    cancel();
}

void HttpMediaDataSource::buildWidevinePsshBox(const uint8_t* kidBytes, size_t kidLen,
                                                const uint8_t* contentIdBytes, size_t contentIdLen,
                                                uint32_t protectionScheme) {
    mPsshData.clear();
    if (!kidBytes || kidLen == 0) return;

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

    // Field 9: protection_scheme ('cbcs' = 0x63626373 or 'cenc' = 0x63656e63)
    if (protectionScheme != 0) {
        payload.push_back(0x48);
        uint32_t val = protectionScheme;
        while (val > 0x7F) {
            payload.push_back(static_cast<uint8_t>((val & 0x7F) | 0x80));
            val >>= 7;
        }
        payload.push_back(static_cast<uint8_t>(val & 0x7F));
    }

    const uint32_t totalSize = 32 + static_cast<uint32_t>(payload.size());
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

    // Widevine UUID
    mPsshData.insert(mPsshData.end(), kWidevineUuid, kWidevineUuid + 16);

    const uint32_t dataLen = static_cast<uint32_t>(payload.size());
    mPsshData.push_back((dataLen >> 24) & 0xFF);
    mPsshData.push_back((dataLen >> 16) & 0xFF);
    mPsshData.push_back((dataLen >> 8) & 0xFF);
    mPsshData.push_back(dataLen & 0xFF);

    mPsshData.insert(mPsshData.end(), payload.begin(), payload.end());
    mHasPssh = true;
}

void HttpMediaDataSource::extractWidevinePssh() {
    mHasPssh = false;
    mPsshData.clear();

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
            const char c = hexStart[i];
            if (c == '\0' || !((c >= '0' && c <= '9') ||
                               (c >= 'a' && c <= 'f') ||
                               (c >= 'A' && c <= 'F'))) {
                isHex = false;
                break;
            }
        }
        if (isHex) {
            uint8_t fileId[20];
            for (int i = 0; i < 20; ++i) {
                const char byteHex[3] = {hexStart[i * 2], hexStart[i * 2 + 1], '\0'};
                fileId[i] = static_cast<uint8_t>(std::strtoul(byteHex, nullptr, 16));
            }

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
            LOGI("Derived Spotify Widevine PSSH box from URL file ID (%zu bytes, scheme=%s)",
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
    cancel();

    // Destroy extractor and NDK DataSource BEFORE releasing mCache so NuMediaExtractor's
    // destructor callbacks observe a valid object and zero Java Binder dependencies.
    if (mFormat) {
        AMediaFormat_delete(mFormat);
        mFormat = nullptr;
    }
    if (mExtractor) {
        AMediaExtractor_delete(mExtractor);
        mExtractor = nullptr;
    }
    if (mNdkDataSource) {
        AMediaDataSource_delete(mNdkDataSource);
        mNdkDataSource = nullptr;
    }

    std::shared_ptr<spotify::network::HttpRangeStreamCache> cacheToClose;
    {
        std::lock_guard<std::mutex> lock(mCacheMutex);
        cacheToClose = std::move(mCache);
    }
    if (cacheToClose) {
        cacheToClose->close();
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
        AMediaDataSource_delete(mNdkDataSource);
        mNdkDataSource = nullptr;
    }
    mSampleRate = 0;
    mChannelCount = 0;
    mDurationUs = 0;
    mMimeType[0] = '\0';
}
