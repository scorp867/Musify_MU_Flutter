#pragma once

#include <atomic>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <string>
#include <unordered_map>
#include <vector>

namespace spotify::player::context_view {

inline std::string generate_track_uid() {
    static std::atomic<uint64_t> counter{1};
    uint64_t cnt = counter.fetch_add(1, std::memory_order_relaxed);
    auto now = std::chrono::steady_clock::now().time_since_epoch().count();
    uint64_t val = (static_cast<uint64_t>(now) ^ (cnt * 0x9e3779b97f4a7c15ULL));
    char buf[17];
    std::snprintf(buf, sizeof(buf), "%016llx", static_cast<unsigned long long>(val));
    return std::string(buf, 16);
}

/// 1:1 replica of spotify.player.context_view.proto.Entry.Type (decoded from liborbit.so 0x3cf28c)
enum class EntryType : int32_t {
    TRACK = 0,               // Normal playable song
    DELIMITER = 1,           // Page / loop boundary marker
    PAGE_PLACEHOLDER = 2,    // Unloaded / un-fetched context page
    CONTEXT_PLACEHOLDER = 3  // Unloaded context
};

/// 1:1 replica of spotify.player.context_view.proto.Entry (decoded from liborbit.so 0x3cf0f8)
struct Entry {
    EntryType type{EntryType::TRACK};
    std::string uri;
    std::string uid;
    std::string provider;
    std::unordered_map<std::string, std::string> metadata;
    int32_t page_index{0};
    int32_t absolute_index{0};

    [[nodiscard]] bool is_delimiter() const noexcept {
        return type == EntryType::DELIMITER ||
               uri == "spotify:meta:delimiter" ||
               uri == "spotify:delimiter";
    }

    [[nodiscard]] bool is_placeholder() const noexcept {
        return type == EntryType::PAGE_PLACEHOLDER ||
               type == EntryType::CONTEXT_PLACEHOLDER;
    }
};

namespace cyclic_list {

/// 1:1 replica of spotify.player.context_view.cyclic_list.proto.Instance (decoded from liborbit.so 0x3cee54)
struct Instance {
    Entry item;
    int32_t iteration{0};
};

/// 1:1 replica of spotify.player.context_view.cyclic_list.proto.Patch
struct Patch {
    int32_t start{0};
    int32_t end{0};
    std::vector<Instance> instances;
};

/// 1:1 replica of spotify.player.context_view.cyclic_list.proto.CyclicEntryKeyList
struct CyclicEntryKeyList {
    Entry delimiter;
    std::vector<Entry> items;
    Patch patch;
};

} // namespace cyclic_list

/// 1:1 replica of spotify.player.context_view.proto.ContextView (decoded from liborbit.so 0x3cec10)
struct ContextView {
    std::unordered_map<std::string, Entry> patch_map;
    int32_t iteration_size{0};
    cyclic_list::CyclicEntryKeyList cyclic_list;
};

} // namespace spotify::player::context_view

namespace spotify::player {
using context_view::generate_track_uid;
}
