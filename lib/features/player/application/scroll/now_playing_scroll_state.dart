import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';

/// States for [NowPlayingScrollBloc].
sealed class NowPlayingScrollState extends Equatable {
  const NowPlayingScrollState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any media item is resolved.
final class NowPlayingScrollInitial extends NowPlayingScrollState {
  const NowPlayingScrollInitial();
}

/// State emitted while loading cards or lyrics for a media item.
final class NowPlayingScrollLoading extends NowPlayingScrollState {
  final MediaItem item;
  final List<ScrollCardDescriptor> currentCards;
  final ColorLyricsResponse? currentLyrics;

  const NowPlayingScrollLoading({
    required this.item,
    this.currentCards = const [],
    this.currentLyrics,
  });

  @override
  List<Object?> get props => [item.id, currentCards, currentLyrics];
}

/// State emitted when card descriptors and lyrics have been fetched.
final class NowPlayingScrollLoaded extends NowPlayingScrollState {
  final MediaItem item;
  final List<ScrollCardDescriptor> cards;
  final ColorLyricsResponse? lyrics;

  const NowPlayingScrollLoaded({
    required this.item,
    required this.cards,
    this.lyrics,
  });

  bool get hasLyrics => lyrics != null && lyrics!.hasLyrics();

  @override
  List<Object?> get props => [item.id, cards, lyrics];
}

/// State emitted on failure to load scroll cards or lyrics.
final class NowPlayingScrollFailure extends NowPlayingScrollState {
  final MediaItem item;
  final String message;
  final List<ScrollCardDescriptor> fallbackCards;

  const NowPlayingScrollFailure({
    required this.item,
    required this.message,
    this.fallbackCards = const [],
  });

  @override
  List<Object?> get props => [item.id, message, fallbackCards];
}
