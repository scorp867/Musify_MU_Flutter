import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';
import 'package:musify_mu/features/player/domain/repositories/lyrics_repository.dart';
import 'package:musify_mu/features/player/domain/repositories/scrollsita_repository.dart';

import 'now_playing_scroll_event.dart';
import 'now_playing_scroll_state.dart';

export 'now_playing_scroll_event.dart';
export 'now_playing_scroll_state.dart';

/// BLoC coordinating the Now Playing scroll cards and color-synced lyrics pipeline.
class NowPlayingScrollBloc
    extends Bloc<NowPlayingScrollEvent, NowPlayingScrollState> {
  final ScrollSitaRepository? _scrollSitaRepository;
  final LyricsRepository? _lyricsRepository;

  NowPlayingScrollBloc({
    ScrollSitaRepository? scrollSitaRepository,
    LyricsRepository? lyricsRepository,
  })  : _scrollSitaRepository = scrollSitaRepository,
        _lyricsRepository = lyricsRepository,
        super(const NowPlayingScrollInitial()) {
    on<FetchNowPlayingScroll>(_onFetchNowPlayingScroll);
  }

  Future<void> _onFetchNowPlayingScroll(
    FetchNowPlayingScroll event,
    Emitter<NowPlayingScrollState> emit,
  ) async {
    final trackId = event.trackId;

    emit(NowPlayingScrollLoading(
      trackId: trackId,
      currentCards: const [],
    ));

    try {
      final results = await Future.wait([
        _scrollSitaRepository?.getScrollCards(trackId) ??
            Future.value(const <ScrollCardDescriptor>[]),
        (trackId != null && _lyricsRepository != null)
            ? _lyricsRepository.getLyrics(trackId)
            : Future<ColorLyricsResponse?>.value(null),
      ]);

      final cards = results[0] as List<ScrollCardDescriptor>;
      final lyrics = results[1] as ColorLyricsResponse?;

      emit(NowPlayingScrollLoaded(
        trackId: trackId,
        cards: cards,
        lyrics: lyrics,
      ));
    } catch (e) {
      emit(NowPlayingScrollFailure(
        trackId: trackId,
        message: e.toString(),
        fallbackCards: const [],
      ));
    }
  }
}
