import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';

class QueueState extends Equatable {
  final PlayerQueue queue;
  final int currentIndex;
  final int totalTracks;
  final bool isPlaying;
  final AudioServiceShuffleMode shuffleMode;
  final AudioServiceRepeatMode repeatMode;

  const QueueState({
    this.queue = const PlayerQueue(revision: '0'),
    this.currentIndex = -1,
    this.totalTracks = 0,
    this.isPlaying = true,
    this.shuffleMode = AudioServiceShuffleMode.none,
    this.repeatMode = AudioServiceRepeatMode.none,
  });

  ContextTrack? get nowPlaying => queue.currentTrack;
  List<ContextTrack> get userQueue => queue.userQueue;
  List<ContextTrack> get contextTracks => queue.contextTracks;
  List<ContextTrack> get nextTracks => queue.nextTracks;

  bool get hasQueue => nowPlaying != null;
  bool get hasUpcoming => nextTracks.isNotEmpty;
  bool get hasUserQueue => userQueue.isNotEmpty;
  bool get hasContextTracks => contextTracks.isNotEmpty;

  QueueState copyWith({
    PlayerQueue? queue,
    int? currentIndex,
    int? totalTracks,
    bool? isPlaying,
    AudioServiceShuffleMode? shuffleMode,
    AudioServiceRepeatMode? repeatMode,
  }) {
    return QueueState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      totalTracks: totalTracks ?? this.totalTracks,
      isPlaying: isPlaying ?? this.isPlaying,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }

  @override
  List<Object?> get props => [
        queue,
        currentIndex,
        totalTracks,
        isPlaying,
        shuffleMode,
        repeatMode,
      ];
}
