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
  int _currentIndex = 0;
  bool _isTransitioning = false;
  PrefetchLevel _prefetchLevel = PrefetchLevel.media;
  void Function(List<MediaItem> tracks)? onQueueChanged;

  PlaybackQueueManager(this._player);

  PrefetchLevel get prefetchLevel => _prefetchLevel;
  set prefetchLevel(PrefetchLevel level) {
    _prefetchLevel = level;
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

  Future<void> setQueue(List<MediaItem> tracks, int initialIndex) async {
    if (tracks.isEmpty || initialIndex < 0 || initialIndex >= tracks.length) {
      return;
    }

    _isTransitioning = true;
    try {
      _fullTracks = List<MediaItem>.of(tracks);
      _currentIndex = initialIndex;

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
    if (index == 1 && _currentIndex + 1 < _fullTracks.length) {
      _isTransitioning = true;
      try {
        _currentIndex++;
        debugPrint('[SPOTIFY-QUEUE] Gapless transition to track $_currentIndex: '
            '${_fullTracks[_currentIndex].title}');

        // Remove the played track at Slot 0. Slot 1 becomes the new Slot 0.
        await playlist.removeAt(0);

        // Preload the new next track into Slot 1
        if (_prefetchLevel == PrefetchLevel.media && _currentIndex + 1 < _fullTracks.length) {
          final nextSource = _createAudioSource(_fullTracks[_currentIndex + 1]);
          await playlist.add(nextSource);
          debugPrint('[SPOTIFY-QUEUE] Prefetched next track into Slot 1: '
              '${_fullTracks[_currentIndex + 1].title}');
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
      final shouldHavePrefetch =
          _prefetchLevel == PrefetchLevel.media && _currentIndex + 1 < _fullTracks.length;

      if (!shouldHavePrefetch) {
        if (playlist.length > 1) {
          await playlist.removeAt(1);
        }
        return;
      }

      final expectedNextTrack = _fullTracks[_currentIndex + 1];
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
    final uri = pathOrUrl.startsWith('http')
        ? Uri.parse(pathOrUrl)
        : Uri.file(pathOrUrl);

    return AudioSource.uri(uri, tag: item);
  }
}
