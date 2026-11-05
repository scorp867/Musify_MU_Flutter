#include "ContextProcessor.h"

#include <algorithm>
#include <android/log.h>
#include <random>
#include <unordered_set>

#define TAG "ContextProcessor"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)

namespace spotify::player {

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
    loaded_tracks_ = tracks;
    for (auto& t : loaded_tracks_) {
        if (t.uid.empty()) {
            t.uid = generate_track_uid();
        }
        if (t.provider.empty()) {
            t.provider = "context";
        }
        t.metadata["provider"] = t.provider;
    }

    if (initial_index >= 0 && initial_index < static_cast<int32_t>(loaded_tracks_.size())) {
        index_ = initial_index;
    } else {
        index_ = 0;
    }

    rebuild_cyclic_list_locked();
    LOGI("set_context: uri=%s (%zu tracks, initial_index=%d, next_page=%s)",
         context_uri_.c_str(), loaded_tracks_.size(), index_, next_page_url_.c_str());
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

    // Append newly resolved page tracks ensuring unique UIDs and context provider
    for (const auto& track : tracks) {
        auto t = track;
        if (t.uid.empty()) {
            t.uid = generate_track_uid();
        }
        if (t.provider.empty()) {
            t.provider = "context";
        }
        t.metadata["provider"] = t.provider;
        loaded_tracks_.push_back(std::move(t));
    }

    rebuild_cyclic_list_locked();
}

void ContextProcessor::rebuild_cyclic_list_locked() {
    auto& cyclic = context_view_.cyclic_list;
    cyclic.items.clear();

    const auto& source_list = (shuffling_ && !shuffled_order_.empty()) ? shuffled_order_ : loaded_tracks_;
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
    const auto& list = (shuffling_ && !shuffled_order_.empty()) ? shuffled_order_ : loaded_tracks_;
    if (index_ >= 0 && index_ < static_cast<int32_t>(list.size())) {
        return list[index_];
    }
    return std::nullopt;
}

// 1:1 match with liborbit.so 0xf5529c - 0xf552cd
std::vector<context_view::Entry> ContextProcessor::get_next_tracks(int32_t max_count) const {
    std::lock_guard<std::mutex> lock(mutex_);
    std::vector<context_view::Entry> result;
    const auto& items = context_view_.cyclic_list.items;

    if (items.empty() || index_ < 0) {
        return result;
    }

    result.reserve(static_cast<size_t>(max_count));

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
    const auto& list = (shuffling_ && !shuffled_order_.empty()) ? shuffled_order_ : loaded_tracks_;

    if (list.empty() || index_ <= 0) {
        return result;
    }

    int32_t start = std::min(index_ - 1, static_cast<int32_t>(list.size()) - 1);
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
        valid_keys.insert(e.uid.empty() ? e.uri : e.uid);
    }

    auto filter_list = [&](std::vector<context_view::Entry>& list) {
        if (index_ + 1 >= static_cast<int32_t>(list.size())) return;
        auto it = list.begin() + (index_ + 1);
        while (it != list.end()) {
            std::string key = it->uid.empty() ? it->uri : it->uid;
            if (it->is_delimiter() || it->is_placeholder()) {
                ++it;
            } else if (valid_keys.find(key) == valid_keys.end()) {
                it = list.erase(it);
            } else {
                ++it;
            }
        }
    };

    filter_list(loaded_tracks_);
    if (!shuffled_order_.empty()) {
        filter_list(shuffled_order_);
    }
    rebuild_cyclic_list_locked();
}

void ContextProcessor::set_next_tracks_slice(const std::vector<context_view::Entry>& reordered_next) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (index_ < 0) return;

    auto update_list = [&](std::vector<context_view::Entry>& list) {
        if (index_ + 1 >= static_cast<int32_t>(list.size())) {
            for (const auto& req : reordered_next) {
                auto track = req;
                if (track.uid.empty()) {
                    track.uid = generate_track_uid();
                }
                if (track.provider.empty()) {
                    track.provider = "context";
                }
                track.metadata["provider"] = track.provider;
                list.push_back(std::move(track));
            }
            return;
        }

        std::vector<context_view::Entry> tail(list.begin() + (index_ + 1), list.end());
        list.erase(list.begin() + (index_ + 1), list.end());

        // Index incoming UIDs for fast lookup of lookahead slice items
        std::unordered_set<std::string> incoming_uids;
        incoming_uids.reserve(reordered_next.size());
        for (const auto& req : reordered_next) {
            if (!req.uid.empty()) {
                incoming_uids.insert(req.uid);
            }
        }

        // 1. Directly adopt the client's resolved reordered slice
        for (const auto& req : reordered_next) {
            auto track = req;
            if (track.uid.empty()) {
                track.uid = generate_track_uid();
            }
            track.provider = "context";
            track.metadata["provider"] = "context";
            track.metadata["is_queued"] = "false";
            list.push_back(std::move(track));
        }

        // 2. Preserve unexposed trailing tail items (delimiters, placeholders, and tracks beyond lookahead)
        for (auto& item : tail) {
            if (item.is_delimiter() || item.is_placeholder()) {
                list.push_back(std::move(item));
            } else if (!item.uid.empty() && incoming_uids.find(item.uid) == incoming_uids.end()) {
                list.push_back(std::move(item));
            }
        }
    };

    update_list(loaded_tracks_);
    if (!shuffled_order_.empty()) {
        update_list(shuffled_order_);
    }
    rebuild_cyclic_list_locked();
}

bool ContextProcessor::skip_next() {
    std::lock_guard<std::mutex> lock(mutex_);
    const auto& list = (shuffling_ && !shuffled_order_.empty()) ? shuffled_order_ : loaded_tracks_;
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
    const auto& list = (shuffling_ && !shuffled_order_.empty()) ? shuffled_order_ : loaded_tracks_;
    if (index >= 0 && index < static_cast<int32_t>(list.size())) {
        index_ = index;
        return true;
    }
    return false;
}

bool ContextProcessor::skip_to_uri(const std::string& uri) {
    std::lock_guard<std::mutex> lock(mutex_);
    const auto& list = (shuffling_ && !shuffled_order_.empty()) ? shuffled_order_ : loaded_tracks_;
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
    const auto& list = (shuffling_ && !shuffled_order_.empty()) ? shuffled_order_ : loaded_tracks_;
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
        shuffled_order_ = loaded_tracks_;
        if (!shuffled_order_.empty() && index_ >= 0 && index_ < static_cast<int32_t>(shuffled_order_.size())) {
            auto current = shuffled_order_[static_cast<size_t>(index_)];
            shuffled_order_.erase(shuffled_order_.begin() + index_);
            std::random_device rd;
            std::mt19937 g(rd());
            std::shuffle(shuffled_order_.begin(), shuffled_order_.end(), g);
            shuffled_order_.insert(shuffled_order_.begin(), current);
            index_ = 0;
        }
    } else {
        if (!shuffled_order_.empty() && index_ >= 0 && index_ < static_cast<int32_t>(shuffled_order_.size())) {
            const auto& current_uid = shuffled_order_[static_cast<size_t>(index_)].uid;
            for (size_t i = 0; i < loaded_tracks_.size(); ++i) {
                if (loaded_tracks_[i].uid == current_uid) {
                    index_ = static_cast<int32_t>(i);
                    break;
                }
            }
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
    const auto& list = (shuffling_ && !shuffled_order_.empty()) ? shuffled_order_ : loaded_tracks_;
    int32_t remaining = static_cast<int32_t>(list.size()) - 1 - index_;
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

std::string ContextProcessor::get_context_uri() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return context_uri_;
}

} // namespace spotify::player
