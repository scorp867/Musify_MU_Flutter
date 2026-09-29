// ConcatenatingAudioSource is required here for incremental queue window updates.
// ignore_for_file: deprecated_member_use

import 'dart:developer' as dev;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';

/// Maintains the application queue and the sliding window loaded by just_audio.
///
/// Design:
///   - The full track list (`_fullTracks`) represents the entire queue.
///   - A sliding window (`_windowStartIndex.._windowEndIndex`) is the subset
///     actually loaded into just_audio's `ConcatenatingAudioSource`.
///   - As playback approaches window edges, more tracks are loaded (append/prepend).
///   - `_isSettingQueue` guards against the `currentIndexStream` firing during
///     `setAudioSource`, which would corrupt the window via premature prepend/append.
class PlaybackQueueManager {
  static const _previousWindowSize = 10;
  static const _nextWindowSize = 50;
  static const _appendThreshold = 5;
  static const _prependThreshold = 2;

  final AudioPlayer _player;

  ConcatenatingAudioSource? _playlist;
  List<MediaItem> _fullTracks = const [];
  int _windowStartIndex = 0;
  int _windowEndIndex = 0;

  /// Guards against index-change events during setQueue/setAudioSource.
  bool _isSettingQueue = false;

  PlaybackQueueManager(this._player);

  int get windowStartIndex => _windowStartIndex;
  int get windowEndIndex => _windowEndIndex;

  int windowToAbsoluteIndex(int windowIndex) =>
      windowIndex + _windowStartIndex;

  int absoluteToWindowIndex(int absoluteIndex) =>
      absoluteIndex - _windowStartIndex;

  Future<void> setQueue(List<MediaItem> tracks, int initialIndex) async {
    if (tracks.isEmpty || initialIndex < 0 || initialIndex >= tracks.length) {
      return;
    }

    _isSettingQueue = true;

    try {
      _fullTracks = List<MediaItem>.of(tracks);
      _windowStartIndex = (initialIndex - _previousWindowSize).clamp(
        0,
        _fullTracks.length,
      );
      _windowEndIndex = (initialIndex + _nextWindowSize).clamp(
        0,
        _fullTracks.length,
      );

      final windowTracks = _fullTracks.sublist(
        _windowStartIndex,
        _windowEndIndex,
      );
      final playlist = ConcatenatingAudioSource(
        children: windowTracks.map(_createAudioSource).toList(),
      );
      _playlist = playlist;

      final windowIndex = initialIndex - _windowStartIndex;

      debugPrint('[QUEUE] setQueue: ${tracks.length} tracks, '
          'initial=$initialIndex, window=$_windowStartIndex..$_windowEndIndex, '
          'windowIndex=$windowIndex');

      await _player.setAudioSource(
        playlist,
        initialIndex: windowIndex,
        initialPosition: Duration.zero,
      );
    } catch (e) {
      dev.log('Set queue failed: $e');
      _playlist = null;
    } finally {
      _isSettingQueue = false;
    }
  }

  Future<void> seekToAbsoluteIndex(int absoluteIndex) async {
    if (absoluteIndex < 0 || absoluteIndex >= _fullTracks.length) return;

    final windowIndex = absoluteIndex - _windowStartIndex;
    final playlist = _playlist;

    if (playlist != null && windowIndex >= 0 && windowIndex < playlist.length) {
      await _player.seek(Duration.zero, index: windowIndex);
    } else {
      await setQueue(_fullTracks, absoluteIndex);
    }
  }

  List<MediaItem> get fullTracks => List.unmodifiable(_fullTracks);

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

    // Move within the ConcatenatingAudioSource if both indices are in window.
    final playlist = _playlist;
    if (playlist != null) {
      final fromWindow = fromAbsolute - _windowStartIndex;
      final toWindow = toAbsolute - _windowStartIndex;

      if (fromWindow >= 0 &&
          fromWindow < playlist.length &&
          toWindow >= 0 &&
          toWindow < playlist.length) {
        await playlist.move(fromWindow, toWindow);
      }
    }
  }

  /// Called by the currentIndexStream listener.
  /// Expands the sliding window when playback approaches the edges.
  Future<void> onIndexChanged(int? windowIndex) async {
    // Guard: ignore index events emitted during setAudioSource.
    // just_audio fires currentIndex=0 during source loading before seeking to
    // the requested initialIndex, which would trigger a premature prepend and
    // corrupt the window.
    if (_isSettingQueue) return;

    final playlist = _playlist;
    if (windowIndex == null || playlist == null || _fullTracks.isEmpty) {
      return;
    }

    // Append: approaching the end of the window
    if (windowIndex >= playlist.length - _appendThreshold &&
        _windowEndIndex < _fullTracks.length) {
      final nextEndIndex = (_windowEndIndex + _nextWindowSize).clamp(
        0,
        _fullTracks.length,
      );
      final nextBatch = _fullTracks.sublist(_windowEndIndex, nextEndIndex);

      await playlist.addAll(nextBatch.map(_createAudioSource).toList());
      _windowEndIndex = nextEndIndex;
      debugPrint('[QUEUE] appended ${nextBatch.length} tracks, '
          'window=$_windowStartIndex..$_windowEndIndex');
    }

    // Prepend: approaching the start of the window
    if (windowIndex <= _prependThreshold && _windowStartIndex > 0) {
      final nextStartIndex = (_windowStartIndex - _previousWindowSize).clamp(
        0,
        _fullTracks.length,
      );
      final previousBatch = _fullTracks.sublist(
        nextStartIndex,
        _windowStartIndex,
      );

      await playlist.insertAll(
        0,
        previousBatch.map(_createAudioSource).toList(),
      );
      _windowStartIndex = nextStartIndex;
      debugPrint('[QUEUE] prepended ${previousBatch.length} tracks, '
          'window=$_windowStartIndex..$_windowEndIndex');
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
