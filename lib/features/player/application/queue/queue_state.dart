import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:musify_mu/core/audio/queue_differ.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';

/// Sealed Dart 3 type hierarchy representing the deterministic states of the playback queue.
///
/// Strict invariants guarantee that invalid states (e.g. active playback with null track
/// or empty queue) are strictly unrepresentable at compile time.
sealed class QueueState extends Equatable {
  const QueueState();

  ContextTrack? get nowPlaying => switch (this) {
        QueueActive(:final currentTrack) => currentTrack,
        _ => null,
      };

  PlayerQueue get queue => switch (this) {
        QueueActive(:final queue) => queue,
        _ => const PlayerQueue(revision: '0'),
      };

  int get currentIndex => switch (this) {
        QueueActive(:final currentIndex) => currentIndex,
        _ => -1,
      };

  int get totalTracks => switch (this) {
        QueueActive(:final totalTracks) => totalTracks,
        _ => 0,
      };

  bool get isPlaying => switch (this) {
        QueueActive(:final isPlaying) => isPlaying,
        _ => false,
      };

  AudioServiceShuffleMode get shuffleMode => switch (this) {
        QueueActive(:final shuffleMode) => shuffleMode,
        _ => AudioServiceShuffleMode.none,
      };

  AudioServiceRepeatMode get repeatMode => switch (this) {
        QueueActive(:final repeatMode) => repeatMode,
        _ => AudioServiceRepeatMode.none,
      };

  String? get lastAddedUid => switch (this) {
        QueueActive(:final lastAddedUid) => lastAddedUid,
        _ => null,
      };

  List<QueueEdit> get edits => switch (this) {
        QueueActive(:final edits) => edits,
        _ => const [],
      };

  bool get hasQueue => this is QueueActive;
  bool get hasUpcoming => switch (this) {
        QueueActive(:final queue) => queue.nextTracks.isNotEmpty,
        _ => false,
      };
  bool get hasUserQueue => switch (this) {
        QueueActive(:final queue) => queue.userQueue.isNotEmpty,
        _ => false,
      };
  bool get hasContextTracks => switch (this) {
        QueueActive(:final queue) => queue.contextTracks.isNotEmpty,
        _ => false,
      };

  List<ContextTrack> get userQueue => queue.userQueue;
  List<ContextTrack> get contextTracks => queue.contextTracks;
  List<ContextTrack> get nextTracks => queue.nextTracks;

  QueueState copyWith({
    PlayerQueue? queue,
    ContextTrack? currentTrack,
    int? currentIndex,
    int? totalTracks,
    bool? isPlaying,
    AudioServiceShuffleMode? shuffleMode,
    AudioServiceRepeatMode? repeatMode,
    String? lastAddedUid,
    List<QueueEdit>? edits,
    bool preserveLastAddedUid = false,
  }) {
    return switch (this) {
      final QueueActive active => active.copyWith(
          queue: queue,
          currentTrack: currentTrack,
          currentIndex: currentIndex,
          totalTracks: totalTracks,
          isPlaying: isPlaying,
          shuffleMode: shuffleMode,
          repeatMode: repeatMode,
          lastAddedUid: lastAddedUid,
          edits: edits,
          preserveLastAddedUid: preserveLastAddedUid,
        ),
      _ => this,
    };
  }
}

/// Initial or empty state when no audio source or queue is active.
final class QueueInitial extends QueueState {
  const QueueInitial();

  @override
  List<Object?> get props => const [];
}

/// Active queue state guaranteed to contain an active playing track and valid queue invariants.
final class QueueActive extends QueueState {
  @override
  final PlayerQueue queue;
  final ContextTrack currentTrack;
  @override
  final int currentIndex;
  @override
  final int totalTracks;
  @override
  final bool isPlaying;
  @override
  final AudioServiceShuffleMode shuffleMode;
  @override
  final AudioServiceRepeatMode repeatMode;
  @override
  final String? lastAddedUid;
  @override
  final List<QueueEdit> edits;

  const QueueActive({
    required this.queue,
    required this.currentTrack,
    required this.currentIndex,
    required this.totalTracks,
    required this.isPlaying,
    this.shuffleMode = AudioServiceShuffleMode.none,
    this.repeatMode = AudioServiceRepeatMode.none,
    this.lastAddedUid,
    this.edits = const [],
  })  : assert(currentIndex >= 0 && currentIndex < totalTracks,
            'currentIndex ($currentIndex) must be within [0, $totalTracks)'),
        assert(totalTracks > 0, 'totalTracks ($totalTracks) must be positive');

  @override
  ContextTrack get nowPlaying => currentTrack;

  @override
  QueueActive copyWith({
    PlayerQueue? queue,
    ContextTrack? currentTrack,
    int? currentIndex,
    int? totalTracks,
    bool? isPlaying,
    AudioServiceShuffleMode? shuffleMode,
    AudioServiceRepeatMode? repeatMode,
    String? lastAddedUid,
    List<QueueEdit>? edits,
    bool preserveLastAddedUid = false,
  }) {
    final nextQueue = queue ?? this.queue;
    final nextCurrentTrack = currentTrack ?? this.currentTrack;
    final nextIndex = currentIndex ?? this.currentIndex;
    final nextTotalTracks = totalTracks ?? this.totalTracks;
    final nextIsPlaying = isPlaying ?? this.isPlaying;
    final nextShuffleMode = shuffleMode ?? this.shuffleMode;
    final nextRepeatMode = repeatMode ?? this.repeatMode;
    final nextLastAddedUid =
        lastAddedUid ?? (preserveLastAddedUid ? this.lastAddedUid : null);
    final nextEdits = edits ?? this.edits;

    return QueueActive(
      queue: nextQueue,
      currentTrack: nextCurrentTrack,
      currentIndex: nextIndex,
      totalTracks: nextTotalTracks,
      isPlaying: nextIsPlaying,
      shuffleMode: nextShuffleMode,
      repeatMode: nextRepeatMode,
      lastAddedUid: nextLastAddedUid,
      edits: nextEdits,
    );
  }

  @override
  List<Object?> get props => [
        queue,
        currentTrack,
        currentIndex,
        totalTracks,
        isPlaying,
        shuffleMode,
        repeatMode,
        lastAddedUid,
        edits,
      ];
}

/// Explicit error state when playback or queue operations encounter an unrecoverable failure.
final class QueueError extends QueueState {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const QueueError({
    required this.message,
    this.error,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, error?.toString()];
}
