#include "RoutingTrackPlayer.h"

namespace spotify::player::rendering {

RoutingTrackPlayer::RoutingTrackPlayer(
    std::vector<std::shared_ptr<TrackPlayer>> players,
    std::shared_ptr<TrackPlayer> fallback_player)
    : players_(std::move(players)),
      fallback_player_(std::move(fallback_player)) {}

void RoutingTrackPlayer::setCallbacks(TrackPlayerCallbacks callbacks) {
    for (const auto& player : players_) {
        if (player) {
            player->setCallbacks(callbacks);
        }
    }
    if (fallback_player_) {
        fallback_player_->setCallbacks(std::move(callbacks));
    }
}

std::shared_ptr<TrackPlayer> RoutingTrackPlayer::selectPlayer(
    const context_view::Entry& track) const {
    for (const auto& player : players_) {
        if (player && player->canPlay(track)) {
            return player;
        }
    }
    return fallback_player_;
}

std::shared_ptr<TrackPlayer> RoutingTrackPlayer::activePlayer() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return active_player_;
}

bool RoutingTrackPlayer::start(const context_view::Entry& track,
                               StartReason reason,
                               int64_t start_position_ms,
                               bool start_paused) {
    auto selected = selectPlayer(track);
    std::shared_ptr<TrackPlayer> previous;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        last_start_reason_ = reason;
        if (active_player_ && active_player_ != selected) {
            previous = active_player_;
        }
        active_player_ = selected;
    }

    if (previous) {
        previous->stop(StopReason::ReplacedTrack);
    }

    if (!selected) return false;
    return selected->start(track, reason, start_position_ms, start_paused);
}

bool RoutingTrackPlayer::advance(const context_view::Entry& next_track,
                                 int64_t start_position_ms) {
    auto selected = selectPlayer(next_track);
    std::shared_ptr<TrackPlayer> previous;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        last_start_reason_ = StartReason::TrackAdvance;
        if (active_player_ && active_player_ != selected) {
            previous = active_player_;
        }
        active_player_ = selected;
    }

    if (previous) {
        previous->stop(StopReason::ReplacedTrack);
    }

    if (!selected) return false;
    return selected->advance(next_track, start_position_ms);
}

void RoutingTrackPlayer::stop(StopReason reason) {
    std::shared_ptr<TrackPlayer> cur;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        cur = std::move(active_player_);
    }
    if (cur) {
        cur->stop(reason);
    }
}

bool RoutingTrackPlayer::pause() {
    auto cur = activePlayer();
    return cur ? cur->pause() : false;
}

bool RoutingTrackPlayer::canPause() const {
    auto cur = activePlayer();
    return cur ? cur->canPause() : false;
}

bool RoutingTrackPlayer::resume() {
    auto cur = activePlayer();
    return cur ? cur->resume() : false;
}

bool RoutingTrackPlayer::seek(int64_t position_ms, SeekOrigin origin) {
    auto cur = activePlayer();
    return cur ? cur->seek(position_ms, origin) : false;
}

void RoutingTrackPlayer::setPlaybackSpeed(double speed) {
    for (const auto& player : players_) {
        if (player) player->setPlaybackSpeed(speed);
    }
    if (fallback_player_) fallback_player_->setPlaybackSpeed(speed);
}

int64_t RoutingTrackPlayer::getPosition() const {
    auto cur = activePlayer();
    return cur ? cur->getPosition() : 0;
}

int64_t RoutingTrackPlayer::getDuration() const {
    auto cur = activePlayer();
    return cur ? cur->getDuration() : 0;
}

bool RoutingTrackPlayer::canPlay(const context_view::Entry& track) const {
    for (const auto& player : players_) {
        if (player && player->canPlay(track)) {
            return true;
        }
    }
    return fallback_player_ ? fallback_player_->canPlay(track) : false;
}

TrackPlayerState RoutingTrackPlayer::getState() const {
    auto cur = activePlayer();
    return cur ? cur->getState() : TrackPlayerState{};
}

std::optional<context_view::Entry> RoutingTrackPlayer::getCurrentTrack() const {
    auto cur = activePlayer();
    return cur ? cur->getCurrentTrack() : std::nullopt;
}

bool RoutingTrackPlayer::isPlaying() const {
    auto cur = activePlayer();
    return cur ? cur->isPlaying() : false;
}

StartReason RoutingTrackPlayer::getLastStartReason() const {
    auto cur = activePlayer();
    if (cur) return cur->getLastStartReason();
    std::lock_guard<std::mutex> lock(mutex_);
    return last_start_reason_;
}

void RoutingTrackPlayer::injectLastStartReason(StartReason reason) {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        last_start_reason_ = reason;
    }
    auto cur = activePlayer();
    if (cur) cur->injectLastStartReason(reason);
}

} // namespace spotify::player::rendering
