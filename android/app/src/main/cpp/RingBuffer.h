#pragma once

#include <algorithm>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <cstring>

/// Lock-free Single-Producer Single-Consumer ring buffer for interleaved stereo float PCM.
///
/// Capacity is ~11.9 seconds of stereo audio at 44.1 kHz (524,288 stereo frames = 1,048,576 floats),
/// allowing chunk 0 Vorbis audio to be decoded into the jitter buffer upfront without stalling
/// and enabling seamless background secondary stream handoff.
///
/// Cache-line isolation (`alignas(64)`) on atomic indices prevents false sharing on ARM64,
/// and an atomic generation epoch (`mEpoch`) prevents stale pre-seek frames from being committed
/// after an asynchronous seek request.
class RingBuffer {
public:
    static constexpr size_t kChannelCount       = 2;
    static constexpr size_t kCapacityFrames     = 524288;   // 2^19 (~11.88s at 44.1kHz, 10.92s at 48kHz)
    static constexpr size_t kCapacitySamples    = kCapacityFrames * kChannelCount;
    static constexpr size_t kMask               = kCapacityFrames - 1;

    RingBuffer() = default;

    /// O(1) cursor reset and epoch bump. Does not memset 4 MiB on the real-time/UI path
    /// because `read()` only ever accesses committed frames in `[mReadIndex, mWriteIndex)`.
    uint64_t reset() noexcept {
        const uint64_t nextEpoch = mEpoch.fetch_add(1, std::memory_order_acq_rel) + 1;
        mWriteIndex.store(0, std::memory_order_release);
        mReadIndex.store(0, std::memory_order_release);
        return nextEpoch;
    }

    [[nodiscard]] uint64_t currentEpoch() const noexcept {
        return mEpoch.load(std::memory_order_acquire);
    }

    /// Producer: write up to `frames` stereo frames from `src` only if `expectedEpoch` matches
    /// the current ring buffer epoch. Returns 0 if superseded by a newer seek/reset epoch.
    size_t writeForEpoch(const float* src, size_t frames, uint64_t expectedEpoch) noexcept {
        if (mEpoch.load(std::memory_order_acquire) != expectedEpoch) {
            return 0;
        }
        const size_t writePos = mWriteIndex.load(std::memory_order_relaxed);
        const size_t readPos  = mReadIndex.load(std::memory_order_acquire);
        const size_t used     = (writePos >= readPos) ? (writePos - readPos) : 0;
        const size_t space    = (kCapacityFrames > used) ? (kCapacityFrames - used) : 0;
        if (space == 0 || frames == 0) {
            return 0;
        }

        const size_t toWrite     = std::min(frames, space);
        const size_t startIdx    = writePos & kMask;
        const size_t firstChunk  = std::min(toWrite, kCapacityFrames - startIdx);
        const size_t secondChunk = toWrite - firstChunk;

        std::memcpy(&mData[startIdx * kChannelCount],
                    src,
                    firstChunk * kChannelCount * sizeof(float));

        if (secondChunk > 0) {
            std::memcpy(&mData[0],
                        src + firstChunk * kChannelCount,
                        secondChunk * kChannelCount * sizeof(float));
        }

        if (mEpoch.load(std::memory_order_acquire) != expectedEpoch) {
            return 0;
        }
        mWriteIndex.store(writePos + toWrite, std::memory_order_release);
        return toWrite;
    }

    /// Producer: write up to `frames` stereo frames from `src` under the current epoch.
    size_t write(const float* src, size_t frames) noexcept {
        return writeForEpoch(src, frames, mEpoch.load(std::memory_order_acquire));
    }

    /// Consumer: read up to `frames` stereo frames into `dst`.
    /// Returns number of frames actually read.
    size_t read(float* dst, size_t frames) noexcept {
        const uint64_t epochBefore = mEpoch.load(std::memory_order_acquire);
        const size_t readPos       = mReadIndex.load(std::memory_order_relaxed);
        const size_t writePos      = mWriteIndex.load(std::memory_order_acquire);
        if (writePos <= readPos || frames == 0) {
            return 0;
        }

        const size_t available   = writePos - readPos;
        const size_t toRead      = std::min(frames, available);
        const size_t startIdx    = readPos & kMask;
        const size_t firstChunk  = std::min(toRead, kCapacityFrames - startIdx);
        const size_t secondChunk = toRead - firstChunk;

        std::memcpy(dst,
                    &mData[startIdx * kChannelCount],
                    firstChunk * kChannelCount * sizeof(float));

        if (secondChunk > 0) {
            std::memcpy(dst + firstChunk * kChannelCount,
                        &mData[0],
                        secondChunk * kChannelCount * sizeof(float));
        }

        if (mEpoch.load(std::memory_order_acquire) != epochBefore) {
            return 0;
        }
        mReadIndex.store(readPos + toRead, std::memory_order_release);
        return toRead;
    }

    /// Returns number of stereo frames available to read (consumer view).
    [[nodiscard]] size_t availableToRead() const noexcept {
        const size_t w = mWriteIndex.load(std::memory_order_acquire);
        const size_t r = mReadIndex.load(std::memory_order_acquire);
        return (w >= r) ? (w - r) : 0;
    }

    /// Returns number of stereo frames of free space available to write (producer view).
    [[nodiscard]] size_t availableToWrite() const noexcept {
        const size_t w = mWriteIndex.load(std::memory_order_acquire);
        const size_t r = mReadIndex.load(std::memory_order_acquire);
        const size_t used = (w >= r) ? (w - r) : 0;
        return (kCapacityFrames >= used) ? (kCapacityFrames - used) : 0;
    }

private:
    // --- Epoch cache line ---
    alignas(64) std::atomic<uint64_t> mEpoch{1};

    // --- Producer cache line ---
    alignas(64) std::atomic<size_t> mWriteIndex{0};

    // --- Consumer cache line ---
    alignas(64) std::atomic<size_t> mReadIndex{0};

    // --- Data buffer ---
    alignas(64) float mData[kCapacitySamples]{};
};
