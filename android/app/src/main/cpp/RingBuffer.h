#pragma once

#include <atomic>
#include <cstddef>
#include <cstring>
#include <algorithm>

/// Lock-free Single-Producer Single-Consumer ring buffer for interleaved stereo float PCM.
///
/// Capacity is 2.0 seconds of stereo audio at 48 kHz, rounded to the next power of two
/// (131,072 stereo frames = 262,144 floats). Index wrapping uses bitwise AND.
///
/// Cache-line isolation (alignas(64)) on atomic indices prevents false sharing on ARM64.
/// Shadow cursor caching minimises atomic acquire loads on the hot path.
class RingBuffer {
public:
    static constexpr size_t kChannelCount       = 2;
    static constexpr size_t kCapacityFrames     = 131072;   // 2^17
    static constexpr size_t kCapacitySamples    = kCapacityFrames * kChannelCount;
    static constexpr size_t kMask               = kCapacityFrames - 1;

    RingBuffer() { reset(); }

    /// Resets both cursors and zeroes the data buffer.
    void reset() {
        mWriteIndex.store(0, std::memory_order_relaxed);
        mReadIndex.store(0, std::memory_order_relaxed);
        mCachedReadIndex  = 0;
        mCachedWriteIndex = 0;
        std::memset(mData, 0, sizeof(mData));
    }

    /// Producer: write up to `frames` stereo frames from `src`.
    /// Returns number of frames actually written.
    size_t write(const float* src, size_t frames) {
        const size_t writePos = mWriteIndex.load(std::memory_order_relaxed);

        size_t space = kCapacityFrames - (writePos - mCachedReadIndex);
        if (space == 0) {
            mCachedReadIndex = mReadIndex.load(std::memory_order_acquire);
            space = kCapacityFrames - (writePos - mCachedReadIndex);
            if (space == 0) return 0;
        }

        const size_t toWrite    = std::min(frames, space);
        const size_t startIdx   = writePos & kMask;
        const size_t firstChunk = std::min(toWrite, kCapacityFrames - startIdx);
        const size_t secondChunk = toWrite - firstChunk;

        std::memcpy(&mData[startIdx * kChannelCount],
                     src,
                     firstChunk * kChannelCount * sizeof(float));

        if (secondChunk > 0) {
            std::memcpy(&mData[0],
                         src + firstChunk * kChannelCount,
                         secondChunk * kChannelCount * sizeof(float));
        }

        mWriteIndex.store(writePos + toWrite, std::memory_order_release);
        return toWrite;
    }

    /// Consumer: read up to `frames` stereo frames into `dst`.
    /// Returns number of frames actually read.
    size_t read(float* dst, size_t frames) {
        const size_t readPos = mReadIndex.load(std::memory_order_relaxed);

        size_t available = mCachedWriteIndex - readPos;
        if (available == 0) {
            mCachedWriteIndex = mWriteIndex.load(std::memory_order_acquire);
            available = mCachedWriteIndex - readPos;
            if (available == 0) return 0;
        }

        const size_t toRead     = std::min(frames, available);
        const size_t startIdx   = readPos & kMask;
        const size_t firstChunk = std::min(toRead, kCapacityFrames - startIdx);
        const size_t secondChunk = toRead - firstChunk;

        std::memcpy(dst,
                     &mData[startIdx * kChannelCount],
                     firstChunk * kChannelCount * sizeof(float));

        if (secondChunk > 0) {
            std::memcpy(dst + firstChunk * kChannelCount,
                         &mData[0],
                         secondChunk * kChannelCount * sizeof(float));
        }

        mReadIndex.store(readPos + toRead, std::memory_order_release);
        return toRead;
    }

    /// Returns number of stereo frames available to read (consumer view).
    size_t availableToRead() const {
        return mWriteIndex.load(std::memory_order_acquire)
             - mReadIndex.load(std::memory_order_relaxed);
    }

    /// Returns number of stereo frames of free space available to write (producer view).
    size_t availableToWrite() const {
        return kCapacityFrames
             - (mWriteIndex.load(std::memory_order_relaxed)
              - mReadIndex.load(std::memory_order_acquire));
    }

private:
    // --- Producer cache line ---
    alignas(64) std::atomic<size_t> mWriteIndex{0};
    size_t mCachedReadIndex{0};

    // --- Consumer cache line ---
    alignas(64) std::atomic<size_t> mReadIndex{0};
    size_t mCachedWriteIndex{0};

    // --- Data buffer ---
    alignas(64) float mData[kCapacitySamples]{};
};
