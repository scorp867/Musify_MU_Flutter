import 'package:equatable/equatable.dart';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';

/// States for [NowPlayingScrollBloc].
sealed class NowPlayingScrollState extends Equatable {
  const NowPlayingScrollState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any track is resolved.
final class NowPlayingScrollInitial extends NowPlayingScrollState {
  const NowPlayingScrollInitial();
}

/// State emitted while loading cards or lyrics for a track.
final class NowPlayingScrollLoading extends NowPlayingScrollState {
  final String? trackId;
  final List<ScrollCardDescriptor> currentCards;
  final ColorLyricsResponse? currentLyrics;

  const NowPlayingScrollLoading({
    this.trackId,
    this.currentCards = const [],
    this.currentLyrics,
  });

  @override
  List<Object?> get props => [trackId, currentCards, currentLyrics];
}

/// State emitted when card descriptors and lyrics have been fetched.
final class NowPlayingScrollLoaded extends NowPlayingScrollState {
  final String? trackId;
  final List<ScrollCardDescriptor> cards;
  final ColorLyricsResponse? lyrics;

  const NowPlayingScrollLoaded({
    this.trackId,
    required this.cards,
    this.lyrics,
  });

  bool get hasLyrics => lyrics != null && lyrics!.hasLyrics();

  @override
  List<Object?> get props => [trackId, cards, lyrics];
}

/// State emitted on failure to load scroll cards or lyrics.
final class NowPlayingScrollFailure extends NowPlayingScrollState {
  final String? trackId;
  final String message;
  final List<ScrollCardDescriptor> fallbackCards;

  const NowPlayingScrollFailure({
    this.trackId,
    required this.message,
    this.fallbackCards = const [],
  });

  @override
  List<Object?> get props => [trackId, message, fallbackCards];
}
