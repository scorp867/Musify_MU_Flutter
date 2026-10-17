// ConcatenatingAudioSource is required for gapless prefetching.
// ignore_for_file: deprecated_member_use

import 'dart:developer' as dev;
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';
import 'package:musify_mu/features/local_music/domain/local_context_resolver.dart';
import 'package:musify_mu/features/player/domain/models/prefetch_level.dart';

/// 1:1 with Spotify's C++ ContextPlayer & EsMediaPrefetch audio feeding architecture.
///
/// Instead of complex sliding-window math over large playlists, this manager maintains:
///   1. A full linear track list (`_fullTracks`) as pure metadata.
///   2. A 2-slot gapless audio source pipeline in just_audio:
///      - Slot 0: Active playing track
///      - Slot 1: Next upcoming track (prefetched via PrefetchLevel.media)
///
/// When Slot 0 finishes, just_audio transitions into Slot 1 gaplessly (0ms delay).
/// The manager shifts Slot 1 to Slot 0 and buffers the new next track into Slot 1.
/// This completely eliminates sliding-window math and index drift bugs.
class PlaybackQueueManager {
  final AudioPlayer _player;

  ConcatenatingAudioSource? _playlist;
  List<MediaItem> _fullTracks = const [];
  List<MediaItem> _unshuffledTracks = const [];
  int _currentIndex = 0;
  bool _isTransitioning = false;
  bool _shuffleEnabled = false;
  LoopMode _loopMode = LoopMode.off;
  PrefetchLevel _prefetchLevel = PrefetchLevel.media;
  void Function(List<MediaItem> tracks)? onQueueChanged;

  PlaybackQueueManager(this._player);

  PrefetchLevel get prefetchLevel => _prefetchLevel;
  set prefetchLevel(PrefetchLevel level) {
    _prefetchLevel = level;
    _refreshPrefetchSlot();
  }

  bool get isShuffleEnabled => _shuffleEnabled;
  LoopMode get loopMode => _loopMode;

  void setShuffleModeEnabled(bool enabled) {
    if (_shuffleEnabled == enabled) return;
    _shuffleEnabled = enabled;

    if (_fullTracks.isEmpty || _currentIndex + 1 >= _fullTracks.length) return;

    if (enabled) {
      if (_unshuffledTracks.isEmpty) {
        _unshuffledTracks = List<MediaItem>.of(_fullTracks);
      }
      _applyShuffleToUpcoming();
    } else {
      if (_unshuffledTracks.isNotEmpty) {
        final playedAndCurrent = _fullTracks.sublist(0, _currentIndex + 1);
        final upcoming = _fullTracks.sublist(_currentIndex + 1);

        final userQueued = <MediaItem>[];
        final upcomingContextIds = <String>{};

        for (final track in upcoming) {
          final isQueued = track.extras?['is_queued'] == true ||
              track.extras?['is_queued'] == 'true';
          if (isQueued) {
            userQueued.add(track);
          } else {
            upcomingContextIds.add(track.id);
          }
        }

        final restoredContext = _unshuffledTracks
            .where((t) => upcomingContextIds.contains(t.id))
            .toList();

        _fullTracks = [
          ...playedAndCurrent,
          ...userQueued,
          ...restoredContext,
        ];
      }
    }

    _refreshPrefetchSlot();
    onQueueChanged?.call(List.unmodifiable(_fullTracks));
  }

  void _applyShuffleToUpcoming() {
    if (_fullTracks.isEmpty || _currentIndex + 1 >= _fullTracks.length) return;

    final playedAndCurrent = _fullTracks.sublist(0, _currentIndex + 1);
    final upcoming = _fullTracks.sublist(_currentIndex + 1);

    final userQueued = <MediaItem>[];
    final contextTracks = <MediaItem>[];

    for (final track in upcoming) {
      final isQueued = track.extras?['is_queued'] == true ||
          track.extras?['is_queued'] == 'true';
      if (isQueued) {
        userQueued.add(track);
      } else {
        contextTracks.add(track);
      }
    }

    contextTracks.shuffle();

    _fullTracks = [
      ...playedAndCurrent,
      ...userQueued,
      ...contextTracks,
    ];
  }

  void setLoopMode(LoopMode mode) {
    _loopMode = mode;
    _refreshPrefetchSlot();
  }

  int get currentAbsoluteIndex => _currentIndex;
  int get windowStartIndex => _currentIndex;
  int get windowEndIndex => _fullTracks.length;

  int windowToAbsoluteIndex(int windowIndex) =>
      (_currentIndex + windowIndex).clamp(0, _fullTracks.isEmpty ? 0 : _fullTracks.length - 1);

  int absoluteToWindowIndex(int absoluteIndex) =>
      absoluteIndex - _currentIndex;

  List<MediaItem> get fullTracks => List.unmodifiable(_fullTracks);

  /// Bug 2.17 fix: Clears all queue state so that single-track playback via
  /// setAudioSource doesn't leave dangling playlist references and index
  /// listeners operating on an obsolete queue.
  void reset() {
    _playlist = null;
    _fullTracks = const [];
    _unshuffledTracks = const [];
    _currentIndex = 0;
    _isTransitioning = false;
  }

  Future<void> setQueue(List<MediaItem> tracks, int initialIndex) async {
    if (tracks.isEmpty || initialIndex < 0 || initialIndex >= tracks.length) {
      return;
    }

    _isTransitioning = true;
    try {
      // Bug 2.7 fix: Preserve playback state across queue rebuilds so that
      // seeking outside the prefetch window doesn't silently pause audio.
      final wasPlaying = _player.playing;

      _unshuffledTracks = List<MediaItem>.of(tracks);
      _fullTracks = List<MediaItem>.of(tracks);
      _currentIndex = initialIndex;

      if (_shuffleEnabled && _currentIndex + 1 < _fullTracks.length) {
        _applyShuffleToUpcoming();
      }

      final sources = <AudioSource>[
        _createAudioSource(_fullTracks[_currentIndex]),
      ];

      // Prefetch immediate next track if enabled (1:1 with PrefetchLevel.MEDIA)
      if (_prefetchLevel == PrefetchLevel.media && _currentIndex + 1 < _fullTracks.length) {
        sources.add(_createAudioSource(_fullTracks[_currentIndex + 1]));
      }

      final playlist = ConcatenatingAudioSource(children: sources);
      _playlist = playlist;

      debugPrint('[SPOTIFY-QUEUE] setQueue: ${_fullTracks.length} tracks, '
          'current=$_currentIndex (${_fullTracks[_currentIndex].title}), '
          'prefetched=${sources.length > 1}');

      await _player.setAudioSource(
        playlist,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );

      // Restore playback if it was active before the queue rebuild
      if (wasPlaying) {
        await _player.play();
      }

      _checkAndLoadNextPage();
    } catch (e) {
      dev.log('Set queue failed: $e');
      _playlist = null;
    } finally {
      _isTransitioning = false;
    }
  }

  /// Checks if playback has approached the end of the loaded window,
  /// and automatically resolves and appends the next page 1:1 with Spotify's Cosmos ContextPlayer.
  void _checkAndLoadNextPage() {
    if (_fullTracks.isEmpty) return;
    final remaining = _fullTracks.length - (_currentIndex + 1);
    if (remaining <= 8) {
      final lastTrack = _fullTracks.last;
      final nextPageUrl = lastTrack.extras?['next_page_url']?.toString();
      if (nextPageUrl != null && nextPageUrl.isNotEmpty) {
        final page = LocalContextResolver.resolvePage(nextPageUrl);
        if (page != null && page.tracks != null && page.tracks!.isNotEmpty) {
          final newMediaItems = page.tracks!
              .map((t) => t.toMediaItem())
              .toList(growable: false);
          _fullTracks.addAll(newMediaItems);
          _refreshPrefetchSlot();
          onQueueChanged?.call(List.unmodifiable(_fullTracks));
        }
      }
    }
  }

  Future<void> seekToAbsoluteIndex(int absoluteIndex) async {
    if (absoluteIndex < 0 || absoluteIndex >= _fullTracks.length) return;

    // If seeking to the already prefetched next track in slot 1:
    final playlist = _playlist;
    if (playlist != null &&
        absoluteIndex == _currentIndex + 1 &&
        playlist.length > 1 &&
        _player.currentIndex == 0) {
      await _player.seek(Duration.zero, index: 1);
      _checkAndLoadNextPage();
      return;
    }

    // Otherwise, rebuild the 2-slot pipeline at the requested index
    await setQueue(_fullTracks, absoluteIndex);
    _checkAndLoadNextPage();
  }

  /// Called by the currentIndexStream listener on track completion/skip.
  Future<void> onIndexChanged(int? index) async {
    if (_isTransitioning || index == null || _fullTracks.isEmpty) return;

    final playlist = _playlist;
    if (playlist == null) return;

    // Natural advance to Slot 1 (prefetched next track)
    final hasNext = _currentIndex + 1 < _fullTracks.length;
    final canLoop = _loopMode == LoopMode.all && _fullTracks.isNotEmpty;

    if (index == 1 && (hasNext || canLoop)) {
      _isTransitioning = true;
      try {
        if (hasNext) {
          _currentIndex++;
        } else if (canLoop) {
          _currentIndex = 0;
        }

        debugPrint('[SPOTIFY-QUEUE] Gapless transition to track $_currentIndex: '
            '${_fullTracks[_currentIndex].title}');

        // Remove the played track at Slot 0. Slot 1 becomes the new Slot 0.
        await playlist.removeAt(0);

        // Preload the new next track into Slot 1
        if (_prefetchLevel == PrefetchLevel.media) {
          MediaItem? nextTrack;
          if (_currentIndex + 1 < _fullTracks.length) {
            nextTrack = _fullTracks[_currentIndex + 1];
          } else if (_loopMode == LoopMode.all && _fullTracks.isNotEmpty) {
            nextTrack = _fullTracks[0];
          }

          if (nextTrack != null) {
            final nextSource = _createAudioSource(nextTrack);
            await playlist.add(nextSource);
            debugPrint('[SPOTIFY-QUEUE] Prefetched next track into Slot 1: '
                '${nextTrack.title}');
          }
        }

        _checkAndLoadNextPage();
      } catch (e) {
        dev.log('Error advancing prefetch pipeline: $e');
      } finally {
        _isTransitioning = false;
      }
    }
  }

  Future<void> reorderTrack(int fromAbsolute, int toAbsolute) async {
    if (fromAbsolute < 0 ||
        fromAbsolute >= _fullTracks.length ||
        toAbsolute < 0 ||
        toAbsolute >= _fullTracks.length ||
        fromAbsolute == toAbsolute) {
      return;
    }

    final item = _fullTracks.removeAt(fromAbsolute);
    _fullTracks.insert(toAbsolute, item);

    // Adjust current index if the moving item affected it
    if (fromAbsolute == _currentIndex) {
      _currentIndex = toAbsolute;
    } else if (fromAbsolute < _currentIndex && toAbsolute >= _currentIndex) {
      _currentIndex--;
    } else if (fromAbsolute > _currentIndex && toAbsolute <= _currentIndex) {
      _currentIndex++;
    }

    _refreshPrefetchSlot();
    onQueueChanged?.call(List.unmodifiable(_fullTracks));
  }

  Future<void> removeTrack(int absoluteIndex) async {
    await removeTrackRange(absoluteIndex, absoluteIndex + 1);
  }

  Future<void> removeTrackRange(int startAbsolute, int endAbsolute) async {
    final start = startAbsolute.clamp(0, _fullTracks.length);
    final end = endAbsolute.clamp(start, _fullTracks.length);
    if (end <= start) return;

    final removingCurrent = _currentIndex >= start && _currentIndex < end;
    _fullTracks.removeRange(start, end);

    if (removingCurrent) {
      if (_fullTracks.isNotEmpty) {
        final newIndex = start.clamp(0, _fullTracks.length - 1);
        await setQueue(_fullTracks, newIndex);
      } else {
        _currentIndex = 0;
        _playlist = null;
        await _player.stop();
      }
      onQueueChanged?.call(List.unmodifiable(_fullTracks));
      return;
    }

    if (end <= _currentIndex) {
      _currentIndex -= (end - start);
    }

    _refreshPrefetchSlot();
    onQueueChanged?.call(List.unmodifiable(_fullTracks));
  }

  Future<void> insertTrack(int absoluteIndex, MediaItem track) async {
    final clampedIndex = absoluteIndex.clamp(0, _fullTracks.length);
    _fullTracks.insert(clampedIndex, track);

    if (clampedIndex <= _currentIndex) {
      _currentIndex++;
    }

    _refreshPrefetchSlot();
  }

  /// 1:1 with SetQueueCommand: Replaces upcoming tracks starting at _currentIndex + 1
  /// with the new list of tracks, updating all metadata (including is_queued and uid),
  /// and refreshing prefetch Slot 1.
  Future<void> setNextTracks(List<MediaItem> upcomingTracks) async {
    final playedTracks = _fullTracks.sublist(
      0,
      (_currentIndex + 1).clamp(0, _fullTracks.length),
    );
    _fullTracks
      ..clear()
      ..addAll(playedTracks)
      ..addAll(upcomingTracks);

    await _refreshPrefetchSlot();
  }

  /// Ensures Slot 1 in ConcatenatingAudioSource reflects the current next track in _fullTracks
  Future<void> _refreshPrefetchSlot() async {
    final playlist = _playlist;
    if (playlist == null || _isTransitioning) return;

    try {
      final hasNextInList = _currentIndex + 1 < _fullTracks.length;
      final canLoopAll = _loopMode == LoopMode.all && _fullTracks.isNotEmpty;
      final shouldHavePrefetch =
          _prefetchLevel == PrefetchLevel.media && (hasNextInList || canLoopAll);

      if (!shouldHavePrefetch) {
        if (playlist.length > 1) {
          await playlist.removeAt(1);
        }
        return;
      }

      final expectedNextTrack = hasNextInList
          ? _fullTracks[_currentIndex + 1]
          : _fullTracks[0];

      if (playlist.length > 1) {
        final currentSlot1Tag = playlist.children[1].sequence.firstOrNull?.tag as MediaItem?;
        if (currentSlot1Tag?.id == expectedNextTrack.id) {
          return; // Already up to date
        }
        await playlist.removeAt(1);
      }

      await playlist.add(_createAudioSource(expectedNextTrack));
      debugPrint('[SPOTIFY-QUEUE] Updated prefetch Slot 1 to: ${expectedNextTrack.title}');
    } catch (e) {
      dev.log('Error refreshing prefetch slot: $e');
    }
  }

  AudioSource _createAudioSource(MediaItem item) {
    final pathOrUrl = MediaItemMapper.dataPath(item) ?? '';

    // Bug 2.13 fix: Detect URI scheme properly instead of only checking 'http'.
    // Android content:// URIs, Spotify stream URLs, and other schemes must use
    // Uri.parse, while only bare filesystem paths use Uri.file.
    if (pathOrUrl.isEmpty) {
      dev.log('Empty audio path for item ${item.id}, using placeholder');
      return AudioSource.uri(Uri.parse('about:blank'), tag: item);
    }

    final uri = pathOrUrl.contains('://')
        ? Uri.parse(pathOrUrl)
        : Uri.file(pathOrUrl);

    return AudioSource.uri(uri, tag: item);
  }
}
