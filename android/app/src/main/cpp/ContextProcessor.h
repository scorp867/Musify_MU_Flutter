#pragma once

#include <cstdint>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

#include "ContextViewEntry.h"

namespace spotify::player {

/// Page size used by Spotify context resolution (30 tracks per page window)
inline constexpr int32_t kDefaultContextPageSize = 30;

/// Number of remaining tracks before delimiter at which next page fetch is triggered (lookahead threshold)
inline constexpr int32_t kPageLookaheadThreshold = 3;

/// 1:1 replica of spotify.player.proto.ContextProcessor (decoded from liborbit.so 0x3cea34)
class ContextProcessor {
public:
    ContextProcessor();
    ~ContextProcessor() = default;

    ContextProcessor(const ContextProcessor&) = delete;
    ContextProcessor& operator=(const ContextProcessor&) = delete;

    /// Delimiter validator - 1:1 match with liborbit.so 0x16b81d4
    [[nodiscard]] static bool is_delimiter(const std::string& uri) noexcept;

    /// Delimiter generator - 1:1 match with liborbit.so 0xf564d6 & 0xfb85bc
    [[nodiscard]] static context_view::Entry create_delimiter(int32_t iteration) noexcept;

    /// Set initial context with page 0 tracks
    void set_context(
        const std::string& context_uri,
        const std::string& page_url,
        const std::vector<context_view::Entry>& tracks,
        const std::string& next_page_url,
        int32_t initial_index = 0);

    /// 1:1 replica of liborbit.so 0x16a7530: parseLoadedContextPage done: %d %s (%d tracks) next_page_url = %s
    void parseLoadedContextPage(
        int32_t iteration,
        const std::string& page_url,
        const std::vector<context_view::Entry>& tracks,
        const std::string& next_page_url);

    /// Returns the currently active playable track
    [[nodiscard]] std::optional<context_view::Entry> get_current_track() const;

    /// 1:1 replica of liborbit.so 0xf5529c - 0xf552cd lookahead queue loop
    /// Scans forward from active index, terminating lookahead at is_delimiter
    [[nodiscard]] std::vector<context_view::Entry> get_next_tracks(int32_t max_count = 50) const;

    /// Returns previous tracks up to active index in reverse order
    [[nodiscard]] std::vector<context_view::Entry> get_prev_tracks() const;

    /// Filters lookahead context tracks following active index to sync with queue deletions
    void filter_next_tracks(const std::vector<context_view::Entry>& valid_next);

    /// Synchronizes and reorders lookahead context tracks following active index (1:1 with liborbit.so QueueImpl::setQueueWithinSlice)
    void set_next_tracks_slice(const std::vector<context_view::Entry>& reordered_next);

    /// Navigation controls
    bool skip_next();
    bool skip_prev();
    bool skip_to_index(int32_t index);
    bool skip_to_uri(const std::string& uri);
    bool skip_to_uid(const std::string& uid);

    /// Shuffling controls
    void set_shuffling(bool shuffle);
    [[nodiscard]] bool is_shuffling() const noexcept;

    /// Checks if playback is nearing the delimiter and needs next page
    [[nodiscard]] bool needs_next_page() const;
    [[nodiscard]] std::string get_next_page_url() const;
    [[nodiscard]] int32_t get_current_iteration() const noexcept;
    [[nodiscard]] int32_t get_current_index() const noexcept;
    [[nodiscard]] std::string get_context_uri() const;

private:
    void rebuild_cyclic_list_locked();

    mutable std::mutex mutex_;
    std::string context_uri_;
    std::string current_page_url_;
    std::string next_page_url_;
    std::string shuffle_seed_;

    int32_t index_{0};
    int32_t iteration_{0};
    bool shuffling_{false};

    context_view::ContextView context_view_;
    std::vector<context_view::Entry> loaded_tracks_;
    std::vector<context_view::Entry> shuffled_order_;
};

} // namespace spotify::player
