library;

import 'dart:async';

import 'package:musify_mu/features/player/application/queue/mobius/mobius_loop.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_state_client.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_screen_state.dart';
import 'package:musify_mu/features/playlist/domain/models/sort_order.dart';
import 'package:musify_mu/features/playlist/domain/repositories/playlist_repository.dart';
import 'playlist_effect_handler.dart';
import 'playlist_mobius_types.dart';

/// Concrete controller driving the Spotify Mobius unidirectional state loop for Playlists.
class PlaylistMobiusLoop {
  final String playlistUri;
  final PlaylistRepository _repository;
  final ContextPlayerStateClient _playerStateClient;
  late final MobiusLoop<PlaylistScreenState, PlaylistEvent, PlaylistEffect> _loop;

  StreamSubscription? _repoSub;
  StreamSubscription? _playerSub;

  PlaylistMobiusLoop({
    required this.playlistUri,
    required PlaylistRepository repository,
    required PlaylistMobiusEffectHandler effectHandler,
    required ContextPlayerStateClient playerStateClient,
  })  : _repository = repository,
        _playerStateClient = playerStateClient {
    _loop = MobiusLoop<PlaylistScreenState, PlaylistEvent, PlaylistEffect>(
      initialModel: PlaylistLoadingState(playlistUri: playlistUri),
      update: playlistMobiusUpdate,
      effectHandler: effectHandler,
    );

    _bindEventSources();
  }

  void _bindEventSources() {
    // 1. Data subscription from repository
    _repoSub = _repository.subscribe(playlistUri).listen(
      (playlist) {
        _loop.dispatchEvent(PlaylistLoadedEvent(playlist));
      },
      onError: (err) {
        _loop.dispatchEvent(PlaylistErrorEvent(err.toString()));
      },
    );

    // 2. Playback state telemetry
    _playerSub = _playerStateClient.getStateStream().listen(
      (playerState) {
        _loop.dispatchEvent(
          PlaylistTrackPlaybackStateChangedEvent(
            activeTrackUri: playerState.track?.uri,
            isPlaying: playerState.isPlaying,
            isShuffleEnabled: playerState.options.shufflingContext,
          ),
        );
      },
      onError: (_) {},
    );
  }

  /// Observable stream of state changes.
  Stream<PlaylistScreenState> get stateStream => _loop.models;

  /// Current snapshot of state.
  PlaylistScreenState get currentState => _loop.currentModel;

  // UI Event Dispatchers
  void onRetryTapped() {
    _repoSub?.cancel();
    _loop.dispatchEvent(const PlaylistRetryTappedEvent());
    _repoSub = _repository.subscribe(playlistUri).listen(
      (playlist) {
        _loop.dispatchEvent(PlaylistLoadedEvent(playlist));
      },
      onError: (err) {
        _loop.dispatchEvent(PlaylistErrorEvent(err.toString()));
      },
    );
  }

  void onPlayTapped({String? trackUri}) {
    _loop.dispatchEvent(PlaylistPlayTappedEvent(trackUri: trackUri));
  }

  void onShuffleTapped() {
    _loop.dispatchEvent(const PlaylistShuffleTappedEvent());
  }

  void onFollowTapped() {
    _loop.dispatchEvent(const PlaylistFollowTappedEvent());
  }

  void onDownloadTapped() {
    _loop.dispatchEvent(const PlaylistDownloadTappedEvent());
  }

  void onSortChanged(ProvidedSortOrder sortOrder) {
    _loop.dispatchEvent(PlaylistSortChangedEvent(sortOrder));
  }

  void onSearchChanged(String query) {
    _loop.dispatchEvent(PlaylistSearchChangedEvent(query));
  }

  void onHeaderOffsetChanged(double alpha) {
    _loop.dispatchEvent(PlaylistHeaderOffsetChangedEvent(alpha));
  }

  void onAddTracks(List<String> trackUris) {
    _loop.dispatchEvent(PlaylistAddTracksEvent(trackUris));
  }

  void onRemoveTrack(String trackUri) {
    _loop.dispatchEvent(PlaylistRemoveTrackEvent(trackUri));
  }

  void dispose() {
    _repoSub?.cancel();
    _playerSub?.cancel();
    _loop.dispose();
  }
}
