// ignore_for_file: deprecated_member_use
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify_mu/core/audio/queue_differ.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';

/// Manages native queue operations directly on [ConcatenatingAudioSource].
///
/// Operates with [ConcatenatingAudioSource] as the single source of truth:
/// - Zero secondary in-memory track lists to prevent state drift.
/// - All queue mutations (move, remove, insert, setNextTracks) execute natively and atomically.
/// - In-place diffing via [QueueDiffer] prevents empty queue flashes and maintains gapless playback.
/// - Indices, shuffle order, and gapless transitions are managed natively by just_audio.
class PlaybackQueueManager {
  final AudioPlayer _player;
  ConcatenatingAudioSource? _playlist;

  void Function(List<MediaItem> tracks)? onQueueChanged;

  PlaybackQueueManager(this._player);

  ConcatenatingAudioSource? get playlist => _playlist;

  bool get isShuffleEnabled => _player.shuffleModeEnabled;
  LoopMode get loopMode => _player.loopMode;

  int get currentAbsoluteIndex => _player.currentIndex ?? 0;
  int get windowEndIndex => _playlist?.length ?? 0;
  int windowToAbsoluteIndex(int windowIndex) => windowIndex;

  List<MediaItem> get fullTracks {
    final playlist = _playlist;
    if (playlist == null || playlist.length == 0) return const [];
    return playlist.children
        .map((source) => (source as IndexedAudioSource).tag as MediaItem)
        .toList(growable: false);
  }

  void reset() {
    _playlist = null;
  }

  Future<void> setQueue(List<MediaItem> tracks, int initialIndex) async {
    if (tracks.isEmpty) {
      throw ArgumentError('Queue tracks cannot be empty.');
    }
    if (initialIndex < 0 || initialIndex >= tracks.length) {
      throw RangeError.range(initialIndex, 0, tracks.length - 1, 'initialIndex');
    }

    final sources = tracks.map(_createAudioSource).toList();
    final playlist = ConcatenatingAudioSource(children: sources);
    _playlist = playlist;

    await _player.setAudioSource(
      playlist,
      initialIndex: initialIndex,
      initialPosition: Duration.zero,
    );

    onQueueChanged?.call(fullTracks);
  }

  Future<void> seekToAbsoluteIndex(int absoluteIndex) async {
    final playlist = _playlist;
    if (playlist == null) {
      throw StateError('Cannot seek: no active playlist is set.');
    }
    if (absoluteIndex < 0 || absoluteIndex >= playlist.length) {
      throw RangeError.range(absoluteIndex, 0, playlist.length - 1, 'absoluteIndex');
    }

    await _player.seek(Duration.zero, index: absoluteIndex);
  }

  Future<void> reorderTrack(int fromAbsolute, int toAbsolute) async {
    final playlist = _playlist;
    if (playlist == null) {
      throw StateError('Cannot reorder: no active playlist is set.');
    }
    if (fromAbsolute < 0 || fromAbsolute >= playlist.length) {
      throw RangeError.range(fromAbsolute, 0, playlist.length - 1, 'fromAbsolute');
    }
    if (toAbsolute < 0 || toAbsolute >= playlist.length) {
      throw RangeError.range(toAbsolute, 0, playlist.length - 1, 'toAbsolute');
    }
    if (fromAbsolute == toAbsolute) return;

    await playlist.move(fromAbsolute, toAbsolute);
    onQueueChanged?.call(fullTracks);
  }

  Future<void> removeTrack(int absoluteIndex) async {
    await removeTrackRange(absoluteIndex, absoluteIndex + 1);
  }

  Future<void> removeTrackRange(int startAbsolute, int endAbsolute) async {
    final playlist = _playlist;
    if (playlist == null) {
      throw StateError('Cannot remove tracks: no active playlist is set.');
    }
    if (startAbsolute < 0 || startAbsolute > playlist.length) {
      throw RangeError.range(startAbsolute, 0, playlist.length, 'startAbsolute');
    }
    if (endAbsolute < startAbsolute || endAbsolute > playlist.length) {
      throw RangeError.range(endAbsolute, startAbsolute, playlist.length, 'endAbsolute');
    }
    if (startAbsolute == endAbsolute) return;

    await playlist.removeRange(startAbsolute, endAbsolute);
    onQueueChanged?.call(fullTracks);
  }

  Future<void> insertTrack(int absoluteIndex, MediaItem track) async {
    final playlist = _playlist;
    if (playlist == null) {
      throw StateError('Cannot insert track: no active playlist is set.');
    }
    if (absoluteIndex < 0 || absoluteIndex > playlist.length) {
      throw RangeError.range(absoluteIndex, 0, playlist.length, 'absoluteIndex');
    }

    await playlist.insert(absoluteIndex, _createAudioSource(track));
    onQueueChanged?.call(fullTracks);
  }

  Future<void> setNextTracks(List<MediaItem> upcomingTracks) async {
    final playlist = _playlist;
    if (playlist == null) {
      throw StateError('Cannot set upcoming tracks: no active playlist is set.');
    }

    final currentIndex = _player.currentIndex ?? -1;
    final upcomingStart = currentIndex >= 0 ? currentIndex + 1 : 0;

    final currentChildren = playlist.children;
    final currentUpcomingSources = upcomingStart < currentChildren.length
        ? currentChildren.sublist(upcomingStart)
        : const <AudioSource>[];
    final currentUpcomingItems = currentUpcomingSources
        .map((source) => (source as IndexedAudioSource).tag as MediaItem)
        .toList(growable: false);

    final currentKeys = QueueDiffer.computeKeys(
      currentUpcomingItems.map((item) => KeySource(
        uri: item.id,
        uid: item.extras?['uid']?.toString(),
      )).toList(growable: false),
    );

    final targetKeys = QueueDiffer.computeKeys(
      upcomingTracks.map((item) => KeySource(
        uri: item.id,
        uid: item.extras?['uid']?.toString(),
      )).toList(growable: false),
    );

    final edits = QueueDiffer.diff(currentKeys, targetKeys);
    if (edits.isEmpty) return;

    if (!QueueDiffer.validate(currentKeys, targetKeys, edits)) {
      // Fallback: safe authoritative rebuild if diff validation fails
      if (playlist.length > upcomingStart) {
        await playlist.removeRange(upcomingStart, playlist.length);
      }
      if (upcomingTracks.isNotEmpty) {
        final newSources = upcomingTracks.map(_createAudioSource).toList();
        await playlist.addAll(newSources);
      }
      onQueueChanged?.call(fullTracks);
      return;
    }

    // Apply minimal edit script sequentially onto playlist
    var i = 0;
    while (i < edits.length) {
      switch (edits[i]) {
        case QueueEditRemove(:final index):
          var j = i;
          while (j < edits.length) {
            final e = edits[j];
            if (e is! QueueEditRemove || e.index != index) break;
            j++;
          }
          final count = j - i;
          final realStart = upcomingStart + index;
          await playlist.removeRange(realStart, realStart + count);
          i = j;

        case QueueEditInsert(:final index):
          final block = <AudioSource>[];
          var j = i;
          while (j < edits.length) {
            final e = edits[j];
            if (e is! QueueEditInsert || e.index != index) break;
            block.add(_createAudioSource(upcomingTracks[e.targetIndex]));
            j++;
          }
          final realAt = upcomingStart + index;
          final inOrderBlock = block.reversed.toList();
          if (realAt >= playlist.length) {
            await playlist.addAll(inOrderBlock);
          } else {
            await playlist.insertAll(realAt, inOrderBlock);
          }
          i = j;

        case QueueEditMove(:final from, :final to):
          final realFrom = upcomingStart + from;
          final realTo = upcomingStart + to;
          await playlist.move(realFrom, realTo);
          i++;
      }
    }

    onQueueChanged?.call(fullTracks);
  }

  Future<void> setShuffleModeEnabled(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
  }

  Future<void> setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
  }

  AudioSource _createAudioSource(MediaItem item) {
    final pathOrUrl = MediaItemMapper.dataPath(item) ?? '';
    if (pathOrUrl.isEmpty) {
      return AudioSource.uri(Uri.parse('about:blank'), tag: item);
    }

    final uri = pathOrUrl.contains('://')
        ? Uri.parse(pathOrUrl)
        : Uri.file(pathOrUrl);

    return AudioSource.uri(uri, tag: item);
  }

  Future<void> dispose() async {
    _playlist = null;
  }
}
