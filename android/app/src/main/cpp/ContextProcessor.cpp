// ============================================================================
// 1:1 Replicated Spotify ContextProcessor & ContextView State Machine
// Sources:
// - `liborbit-jni-spotify.so` `spotify.player.proto.ContextProcessor` (`0x3cea34`)
// - `liborbit-jni-spotify.so` `is_delimiter` (`0x16b81d4`), `create_delimiter` (`0xf564d6`, `0xfb85bc`)
// - `liborbit-jni-spotify.so` `get_next_tracks` (`0xf5529c`-`0xf552cd`), `parseLoadedContextPage` (`0x16a7530`)
// ============================================================================

#include "ContextProcessor.h"

#include <algorithm>
#include <android/log.h>
#include <iterator>
#include <random>
#include <unordered_set>

#define TAG "ContextProcessor"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, TAG, __VA_ARGS__)

namespace spotify::player {

namespace {

std::string entry_identity_key(const context_view::Entry& entry) {
    return entry.uid.empty() ? entry.uri : entry.uid;
}

void normalize_context_entry(context_view::Entry& entry) {
    if (entry.uid.empty()) {
        entry.uid = generate_track_uid();
    }
    if (entry.provider.empty()) {
        entry.provider = "context";
    }
    entry.metadata["provider"] = entry.provider;
}

} // namespace

ContextProcessor::ContextProcessor() = default;

// 1:1 match with liborbit.so 0x16b81d4
bool ContextProcessor::is_delimiter(const std::string& uri) noexcept {
    return uri == "spotify:meta:delimiter" || uri == "spotify:delimiter";
}

// 1:1 match with liborbit.so 0xf564d6 & 0xfb85bc
context_view::Entry ContextProcessor::create_delimiter(int32_t iteration) noexcept {
    context_view::Entry delimiter;
    delimiter.type = context_view::EntryType::DELIMITER;
    delimiter.uri = "spotify:delimiter";
    delimiter.uid = std::to_string(iteration);
    delimiter.metadata["is_delimiter"] = "true";
    return delimiter;
}

const std::vector<context_view::Entry>& ContextProcessor::active_list_locked() const noexcept {
    return shuffling_ ? shuffled_order_ : loaded_tracks_;
}

void ContextProcessor::build_shuffled_order_locked() {
    shuffled_order_ = loaded_tracks_;
    if (shuffled_order_.empty()) {
        index_ = 0;
        return;
    }

    if (index_ < 0 || index_ >= static_cast<int32_t>(shuffled_order_.size())) {
        LOGW("build_shuffled_order_locked: index=%d out of range [0, %zu), resetting to 0",
             index_, shuffled_order_.size());
        index_ = 0;
    }

    auto current = std::move(shuffled_order_[static_cast<size_t>(index_)]);
    shuffled_order_.erase(shuffled_order_.begin() + index_);
    std::random_device rd;
    std::mt19937 g(rd());
    std::shuffle(shuffled_order_.begin(), shuffled_order_.end(), g);
    shuffled_order_.insert(shuffled_order_.begin(), std::move(current));
    index_ = 0;
}

void ContextProcessor::set_context(
        const std::string& context_uri,
        const std::string& page_url,
        const std::vector<context_view::Entry>& tracks,
        const std::string& next_page_url,
        int32_t initial_index) {
    std::lock_guard<std::mutex> lock(mutex_);
    context_uri_ = context_uri;
    current_page_url_ = page_url;
    next_page_url_ = next_page_url;
    iteration_ = 0;

    shuffled_order_.clear();
    loaded_tracks_ = tracks;
    for (auto& t : loaded_tracks_) {
        normalize_context_entry(t);
    }

    if (loaded_tracks_.empty()) {
        index_ = 0;
    } else if (initial_index >= 0 && initial_index < static_cast<int32_t>(loaded_tracks_.size())) {
        index_ = initial_index;
    } else {
        LOGW("set_context: initial_index=%d out of range [0, %zu), resetting to 0",
             initial_index, loaded_tracks_.size());
        index_ = 0;
    }

    if (shuffling_) {
        build_shuffled_order_locked();
    }

    rebuild_cyclic_list_locked();
    LOGI("set_context: uri=%s (%zu tracks, shuffling=%d, index=%d, next_page=%s)",
         context_uri_.c_str(), loaded_tracks_.size(), shuffling_ ? 1 : 0, index_, next_page_url_.c_str());
}

// 1:1 match with liborbit.so 0x16a7530
void ContextProcessor::parseLoadedContextPage(
        int32_t iteration,
        const std::string& page_url,
        const std::vector<context_view::Entry>& tracks,
        const std::string& next_page_url) {
    std::lock_guard<std::mutex> lock(mutex_);
    LOGI("parseLoadedContextPage done: %d %s (%zu tracks) next_page_url = %s",
         iteration, page_url.c_str(), tracks.size(), next_page_url.c_str());

    iteration_ = iteration;
    current_page_url_ = page_url;
    next_page_url_ = next_page_url;

    std::vector<context_view::Entry> normalized_tracks;
    normalized_tracks.reserve(tracks.size());
    for (const auto& track : tracks) {
        auto t = track;
        normalize_context_entry(t);
        normalized_tracks.push_back(std::move(t));
    }

    loaded_tracks_.insert(
        loaded_tracks_.end(),
        normalized_tracks.begin(),
        normalized_tracks.end());

    if (shuffling_) {
        if (shuffled_order_.empty()) {
            build_shuffled_order_locked();
        } else if (!normalized_tracks.empty()) {
            std::random_device rd;
            std::mt19937 g(rd());
            std::shuffle(normalized_tracks.begin(), normalized_tracks.end(), g);
            shuffled_order_.insert(
                shuffled_order_.end(),
                std::make_move_iterator(normalized_tracks.begin()),
                std::make_move_iterator(normalized_tracks.end()));
        }
    }

    rebuild_cyclic_list_locked();
}

void ContextProcessor::rebuild_cyclic_list_locked() {
    auto& cyclic = context_view_.cyclic_list;
    cyclic.items.clear();

    const auto& source_list = active_list_locked();
    cyclic.items.reserve(source_list.size() + 2);

    for (const auto& track : source_list) {
        cyclic.items.push_back(track);
    }

    // 1:1 Delimiter placement: Append delimiter if there are more pages
    if (!next_page_url_.empty()) {
        cyclic.delimiter = create_delimiter(iteration_);
        cyclic.items.push_back(cyclic.delimiter);

        // Append page placeholder representing the next page
        context_view::Entry placeholder;
        placeholder.type = context_view::EntryType::PAGE_PLACEHOLDER;
        placeholder.uri = next_page_url_;
        placeholder.uid = std::to_string(iteration_ + 1);
        cyclic.items.push_back(placeholder);
    } else {
        cyclic.delimiter = {};
    }

    context_view_.iteration_size = static_cast<int32_t>(loaded_tracks_.size());
}

std::optional<context_view::Entry> ContextProcessor::get_current_track() const {
    std::lock_guard<std::mutex> lock(mutex_);
    const auto& list = active_list_locked();
    if (index_ >= 0 && index_ < static_cast<int32_t>(list.size())) {
        return list[static_cast<size_t>(index_)];
    }
    return std::nullopt;
}

// 1:1 match with liborbit.so 0xf5529c - 0xf552cd
std::vector<context_view::Entry> ContextProcessor::get_next_tracks(int32_t max_count) const {
    std::lock_guard<std::mutex> lock(mutex_);
    std::vector<context_view::Entry> result;
    if (max_count <= 0) {
        return result;
    }

    const auto& active = active_list_locked();
    const auto& items = context_view_.cyclic_list.items;
    if (active.empty() || items.empty() || index_ < 0) {
        return result;
    }

    result.reserve(std::min(static_cast<size_t>(max_count), items.size()));

    for (size_t i = static_cast<size_t>(index_ + 1); i < items.size(); ++i) {
        const auto& item = items[i];

        // ⚠️ Exact assembly check: call 0x16b81d4; test %al, %al; jne break_loop;
        if (item.is_delimiter() || is_delimiter(item.uri)) {
            // Include delimiter at the tail so UI / QueueTrackFilter can detect boundary
            result.push_back(item);
            break;
        }

        if (item.is_placeholder()) {
            break;
        }

        result.push_back(item);
        if (static_cast<int32_t>(result.size()) >= max_count) {
            break;
        }
    }

    return result;
}

std::vector<context_view::Entry> ContextProcessor::get_prev_tracks() const {
    std::lock_guard<std::mutex> lock(mutex_);
    std::vector<context_view::Entry> result;
    const auto& list = active_list_locked();

    if (list.empty() || index_ <= 0) {
        return result;
    }

    const int32_t start = std::min(index_ - 1, static_cast<int32_t>(list.size()) - 1);
    for (int32_t i = start; i >= 0; --i) {
        result.push_back(list[static_cast<size_t>(i)]);
    }

    return result;
}

void ContextProcessor::filter_next_tracks(const std::vector<context_view::Entry>& valid_next) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (index_ < 0 || valid_next.empty()) return;

    std::unordered_set<std::string> valid_keys;
    valid_keys.reserve(valid_next.size());
    for (const auto& e : valid_next) {
        valid_keys.insert(entry_identity_key(e));
    }

    if (!shuffling_) {
        if (index_ + 1 >= static_cast<int32_t>(loaded_tracks_.size())) return;
        auto it = loaded_tracks_.begin() + (index_ + 1);
        while (it != loaded_tracks_.end()) {
            if (it->is_delimiter() || it->is_placeholder()) {
                ++it;
            } else if (valid_keys.find(entry_identity_key(*it)) == valid_keys.end()) {
                it = loaded_tracks_.erase(it);
            } else {
                ++it;
            }
        }
    } else {
        if (index_ + 1 >= static_cast<int32_t>(shuffled_order_.size())) return;
        std::unordered_set<std::string> prefix_keys;
        for (int32_t i = 0; i <= index_; ++i) {
            prefix_keys.insert(entry_identity_key(shuffled_order_[static_cast<size_t>(i)]));
        }

        std::unordered_set<std::string> erased_keys;
        auto it = shuffled_order_.begin() + (index_ + 1);
        while (it != shuffled_order_.end()) {
            const std::string key = entry_identity_key(*it);
            if (it->is_delimiter() || it->is_placeholder()) {
                ++it;
            } else if (valid_keys.find(key) == valid_keys.end()) {
                erased_keys.insert(key);
                it = shuffled_order_.erase(it);
            } else {
                ++it;
            }
        }

        if (!erased_keys.empty()) {
            auto lit = loaded_tracks_.begin();
            while (lit != loaded_tracks_.end()) {
                const std::string key = entry_identity_key(*lit);
                if (!lit->is_delimiter() &&
                    !lit->is_placeholder() &&
                    prefix_keys.find(key) == prefix_keys.end() &&
                    erased_keys.find(key) != erased_keys.end()) {
                    lit = loaded_tracks_.erase(lit);
                } else {
                    ++lit;
                }
            }
        }
    }

    rebuild_cyclic_list_locked();
}

void ContextProcessor::set_next_tracks_slice(const std::vector<context_view::Entry>& reordered_next) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (index_ < 0) return;

    std::vector<context_view::Entry> normalized_next;
    normalized_next.reserve(reordered_next.size());
    std::unordered_set<std::string> incoming_uids;
    incoming_uids.reserve(reordered_next.size());
    for (const auto& req : reordered_next) {
        auto track = req;
        if (track.uid.empty()) {
            track.uid = generate_track_uid();
        }
        track.provider = "context";
        track.metadata["provider"] = "context";
        track.metadata["is_queued"] = "false";
        incoming_uids.insert(track.uid);
        normalized_next.push_back(std::move(track));
    }

    auto apply_slice_to_list = [&](std::vector<context_view::Entry>& list,
                                   std::unordered_set<std::string>* removed_keys_out) {
        if (index_ + 1 >= static_cast<int32_t>(list.size())) {
            for (const auto& track : normalized_next) {
                list.push_back(track);
            }
            return;
        }

        std::vector<context_view::Entry> tail(list.begin() + (index_ + 1), list.end());
        list.erase(list.begin() + (index_ + 1), list.end());

        // 1. Directly adopt the client's resolved reordered slice
        for (const auto& track : normalized_next) {
            list.push_back(track);
        }

        // 2. Preserve unexposed trailing tail items (delimiters, placeholders, and tracks beyond lookahead)
        for (auto& item : tail) {
            if (item.is_delimiter() || item.is_placeholder()) {
                list.push_back(std::move(item));
            } else if (!item.uid.empty() && incoming_uids.find(item.uid) == incoming_uids.end()) {
                list.push_back(std::move(item));
            } else if (removed_keys_out != nullptr && !item.uid.empty()) {
                removed_keys_out->insert(item.uid);
            }
        }
    };

    if (!shuffling_) {
        apply_slice_to_list(loaded_tracks_, nullptr);
    } else if (shuffled_order_.empty()) {
        for (const auto& track : normalized_next) {
            loaded_tracks_.push_back(track);
        }
        build_shuffled_order_locked();
    } else {
        std::unordered_set<std::string> prefix_uids;
        const int32_t prefix_end = std::min(index_, static_cast<int32_t>(shuffled_order_.size()) - 1);
        for (int32_t i = 0; i <= prefix_end; ++i) {
            if (!shuffled_order_[static_cast<size_t>(i)].uid.empty()) {
                prefix_uids.insert(shuffled_order_[static_cast<size_t>(i)].uid);
            }
        }

        std::unordered_set<std::string> removed_uids;
        apply_slice_to_list(shuffled_order_, &removed_uids);
        for (const auto& uid : incoming_uids) {
            removed_uids.erase(uid);
        }

        if (!removed_uids.empty()) {
            auto lit = loaded_tracks_.begin();
            while (lit != loaded_tracks_.end()) {
                if (!lit->uid.empty() &&
                    prefix_uids.find(lit->uid) == prefix_uids.end() &&
                    removed_uids.find(lit->uid) != removed_uids.end()) {
                    lit = loaded_tracks_.erase(lit);
                } else {
                    ++lit;
                }
            }
        }

        std::unordered_set<std::string> existing_loaded_uids;
        existing_loaded_uids.reserve(loaded_tracks_.size());
        for (const auto& item : loaded_tracks_) {
            if (!item.uid.empty()) {
                existing_loaded_uids.insert(item.uid);
            }
        }
        for (const auto& track : normalized_next) {
            if (existing_loaded_uids.find(track.uid) == existing_loaded_uids.end()) {
                existing_loaded_uids.insert(track.uid);
                loaded_tracks_.push_back(track);
            }
        }
    }

    rebuild_cyclic_list_locked();
}

bool ContextProcessor::skip_next() {
    std::lock_guard<std::mutex> lock(mutex_);
    const auto& list = active_list_locked();
    if (index_ + 1 < static_cast<int32_t>(list.size())) {
        ++index_;
        return true;
    }
    return false;
}

bool ContextProcessor::skip_prev() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (index_ > 0) {
        --index_;
        return true;
    }
    return false;
}

bool ContextProcessor::skip_to_index(int32_t index) {
    std::lock_guard<std::mutex> lock(mutex_);
    const auto& list = active_list_locked();
    if (index >= 0 && index < static_cast<int32_t>(list.size())) {
        index_ = index;
        return true;
    }
    return false;
}

bool ContextProcessor::skip_to_uri(const std::string& uri) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (uri.empty()) return false;
    const auto& list = active_list_locked();
    for (size_t i = 0; i < list.size(); ++i) {
        if (list[i].uri == uri) {
            index_ = static_cast<int32_t>(i);
            return true;
        }
    }
    return false;
}

bool ContextProcessor::skip_to_uid(const std::string& uid) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (uid.empty()) return false;
    const auto& list = active_list_locked();
    for (size_t i = 0; i < list.size(); ++i) {
        if (list[i].uid == uid) {
            index_ = static_cast<int32_t>(i);
            return true;
        }
    }
    return false;
}

void ContextProcessor::set_shuffling(bool shuffle) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (shuffling_ == shuffle) return;
    shuffling_ = shuffle;

    if (shuffling_) {
        build_shuffled_order_locked();
    } else {
        if (!shuffled_order_.empty() &&
            index_ >= 0 &&
            index_ < static_cast<int32_t>(shuffled_order_.size())) {
            const std::string current_uid = shuffled_order_[static_cast<size_t>(index_)].uid;
            bool found = false;
            for (size_t i = 0; i < loaded_tracks_.size(); ++i) {
                if (loaded_tracks_[i].uid == current_uid) {
                    index_ = static_cast<int32_t>(i);
                    found = true;
                    break;
                }
            }
            if (!found) {
                index_ = 0;
            }
        } else {
            index_ = 0;
        }
        shuffled_order_.clear();
    }

    rebuild_cyclic_list_locked();
}

bool ContextProcessor::is_shuffling() const noexcept {
    std::lock_guard<std::mutex> lock(mutex_);
    return shuffling_;
}

bool ContextProcessor::needs_next_page() const {
    std::lock_guard<std::mutex> lock(mutex_);
    if (next_page_url_.empty()) {
        return false;
    }
    const auto& list = active_list_locked();
    const int32_t remaining = static_cast<int32_t>(list.size()) - 1 - index_;
    return remaining <= kPageLookaheadThreshold;
}

std::string ContextProcessor::get_next_page_url() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return next_page_url_;
}

int32_t ContextProcessor::get_current_iteration() const noexcept {
    std::lock_guard<std::mutex> lock(mutex_);
    return iteration_;
}

int32_t ContextProcessor::get_current_index() const noexcept {
    std::lock_guard<std::mutex> lock(mutex_);
    return index_;
}

void ContextProcessor::clear() {
    std::lock_guard<std::mutex> lock(mutex_);
    context_uri_.clear();
    current_page_url_.clear();
    next_page_url_.clear();
    shuffle_seed_.clear();
    index_ = 0;
    iteration_ = 0;
    shuffling_ = false;
    loaded_tracks_.clear();
    shuffled_order_.clear();
    context_view_.patch_map.clear();
    context_view_.cyclic_list.items.clear();
    context_view_.cyclic_list.delimiter = {};
    context_view_.cyclic_list.patch = {};
    context_view_.iteration_size = 0;
}

std::string ContextProcessor::get_context_uri() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return context_uri_;
}

} // namespace spotify::player
