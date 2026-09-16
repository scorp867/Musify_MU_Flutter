import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';

class QueueState extends Equatable {
  final MediaItem? nowPlaying;
  final List<MediaItem> upcomingTracks;
  final int currentIndex;
  final int totalTracks;

  const QueueState({
    this.nowPlaying,
    this.upcomingTracks = const [],
    this.currentIndex = -1,
    this.totalTracks = 0,
  });

  bool get hasQueue => nowPlaying != null;

  bool get hasUpcoming => upcomingTracks.isNotEmpty;

  /// Lightweight fingerprint of upcoming track order.
  String get _upcomingFingerprint =>
      upcomingTracks.map((t) => t.id).join(',');

  @override
  List<Object?> get props => [
        nowPlaying?.id,
        _upcomingFingerprint,
        currentIndex,
        totalTracks,
      ];
}
