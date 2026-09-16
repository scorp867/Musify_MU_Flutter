// ConcatenatingAudioSource is required here for incremental queue window updates.
// ignore_for_file: deprecated_member_use

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';

/// Maintains the application queue and the sliding window loaded by just_audio.
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

  PlaybackQueueManager(this._player);

  int get windowStartIndex => _windowStartIndex;

  int get windowEndIndex => _windowEndIndex;

  int windowToAbsoluteIndex(int windowIndex) =>
      windowIndex + _windowStartIndex;

  Future<void> setQueue(List<MediaItem> tracks, int initialIndex) async {
    if (tracks.isEmpty || initialIndex < 0 || initialIndex >= tracks.length) {
      return;
    }

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

      await _player.setAudioSource(
        playlist,
        initialIndex: initialIndex - _windowStartIndex,
        initialPosition: Duration.zero,
      );
    } catch (_) {
      _playlist = null;
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

  Future<void> onIndexChanged(int? windowIndex) async {
    final playlist = _playlist;
    if (windowIndex == null || playlist == null || _fullTracks.isEmpty) {
      return;
    }

    if (windowIndex >= playlist.length - _appendThreshold &&
        _windowEndIndex < _fullTracks.length) {
      final nextEndIndex = (_windowEndIndex + _nextWindowSize).clamp(
        0,
        _fullTracks.length,
      );
      final nextBatch = _fullTracks.sublist(_windowEndIndex, nextEndIndex);

      await playlist.addAll(nextBatch.map(_createAudioSource).toList());
      _windowEndIndex = nextEndIndex;
    }

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
