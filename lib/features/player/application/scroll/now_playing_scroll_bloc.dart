import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';
import 'package:musify_mu/features/player/domain/repositories/lyrics_repository.dart';
import 'package:musify_mu/features/player/domain/repositories/scrollsita_repository.dart';

import 'now_playing_scroll_event.dart';
import 'now_playing_scroll_state.dart';

export 'now_playing_scroll_event.dart';
export 'now_playing_scroll_state.dart';

/// BLoC coordinating the Now Playing scroll cards and color-synced lyrics pipeline.
///
/// Follows Spotify Android's SDUI orchestration:
/// 1. Dispatches parallel requests to [ScrollSitaRepository] and [LyricsRepository].
/// 2. Emits [NowPlayingScrollLoaded] with ordered descriptors and color lyrics payload.
class NowPlayingScrollBloc
    extends Bloc<NowPlayingScrollEvent, NowPlayingScrollState> {
  final ScrollSitaRepository _scrollSitaRepository;
  final LyricsRepository _lyricsRepository;

  NowPlayingScrollBloc({
    required ScrollSitaRepository scrollSitaRepository,
    required LyricsRepository lyricsRepository,
  })  : _scrollSitaRepository = scrollSitaRepository,
        _lyricsRepository = lyricsRepository,
        super(const NowPlayingScrollInitial()) {
    on<FetchNowPlayingScroll>(_onFetchNowPlayingScroll);
  }

  Future<void> _onFetchNowPlayingScroll(
    FetchNowPlayingScroll event,
    Emitter<NowPlayingScrollState> emit,
  ) async {
    final item = event.item;

    List<ScrollCardDescriptor> previousCards = const [];
    if (state is NowPlayingScrollLoaded) {
      final loaded = state as NowPlayingScrollLoaded;
      if (loaded.item.id == item.id) {
        return;
      }
      previousCards = loaded.cards;
    }

    emit(NowPlayingScrollLoading(
      item: item,
      currentCards: previousCards,
    ));

    final songId = MediaItemMapper.songId(item)?.toString();
    final trackId = (item.extras?['trackId'] as String?) ?? songId ?? item.id;

    // Local songs have no Spotify track URI; skip the lyrics network call entirely.
    final hasSpotifyUri =
        (item.extras?['uri'] as String?)?.startsWith('spotify:track:') == true ||
        item.id.startsWith('spotify:track:');

    try {
      final results = await Future.wait([
        _scrollSitaRepository.getScrollCards(item),
        hasSpotifyUri
            ? _lyricsRepository.getLyrics(trackId)
            : Future<ColorLyricsResponse?>.value(null),
      ]);

      final cards = results[0] as List<ScrollCardDescriptor>;
      final lyrics = results[1] as ColorLyricsResponse?;

      emit(NowPlayingScrollLoaded(
        item: item,
        cards: cards,
        lyrics: lyrics,
      ));
    } catch (e) {
      List<ScrollCardDescriptor> fallbackCards = const [];
      try {
        fallbackCards = await _scrollSitaRepository.getScrollCards(item);
      } catch (_) {}

      emit(NowPlayingScrollFailure(
        item: item,
        message: e.toString(),
        fallbackCards: fallbackCards,
      ));
    }
  }
}
