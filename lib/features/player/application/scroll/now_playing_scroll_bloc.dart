import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show StateStreamableSource;
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';
import 'package:musify_mu/features/player/domain/repositories/lyrics_repository.dart';
import 'package:musify_mu/features/player/domain/repositories/scrollsita_repository.dart';

import 'now_playing_scroll_event.dart';
import 'now_playing_scroll_state.dart';

export 'now_playing_scroll_event.dart';
export 'now_playing_scroll_state.dart';

/// Pure reactive controller coordinating Now Playing scroll cards and color-synced lyrics pipeline.
///
/// Implements [ValueListenable] and [StateStreamableSource] without extending BLoC internals,
/// driving deterministic unidirectional state flow.
class NowPlayingScrollController extends ChangeNotifier
    implements
        ValueListenable<NowPlayingScrollState>,
        StateStreamableSource<NowPlayingScrollState> {
  final ScrollSitaRepository? _scrollSitaRepository;
  final LyricsRepository? _lyricsRepository;

  NowPlayingScrollState _state = const NowPlayingScrollInitial();
  final StreamController<NowPlayingScrollState> _stateController =
      StreamController<NowPlayingScrollState>.broadcast();

  String? _lastTrackId;

  NowPlayingScrollController({
    ScrollSitaRepository? scrollSitaRepository,
    LyricsRepository? lyricsRepository,
  })  : _scrollSitaRepository = scrollSitaRepository,
        _lyricsRepository = lyricsRepository;

  @override
  NowPlayingScrollState get state => _state;

  @override
  NowPlayingScrollState get value => _state;

  @override
  Stream<NowPlayingScrollState> get stream async* {
    yield _state;
    yield* _stateController.stream;
  }

  @override
  bool get isClosed => _stateController.isClosed;

  /// Dispatches an event to the controller.
  void add(NowPlayingScrollEvent event) {
    if (isClosed) return;
    switch (event) {
      case FetchNowPlayingScroll(:final trackId):
        unawaited(_fetchScroll(trackId));
    }
  }

  Future<void> _fetchScroll(String? trackId) async {
    // Skip duplicate requests for the identical trackId
    if (trackId == _lastTrackId && _state is NowPlayingScrollLoaded) {
      return;
    }
    _lastTrackId = trackId;

    // Skip network calls entirely for missing or empty track IDs
    if (trackId == null || trackId.isEmpty) {
      _emitState(NowPlayingScrollLoaded(
        trackId: trackId,
        cards: const [],
        lyrics: null,
      ));
      return;
    }

    _emitState(NowPlayingScrollLoading(
      trackId: trackId,
      currentCards: const [],
    ));

    try {
      final scrollCardsFuture = switch (_scrollSitaRepository) {
        final repo? => repo.getScrollCards(trackId),
        null => Future<List<ScrollCardDescriptor>>.value(const []),
      };

      final lyricsFuture = switch (_lyricsRepository) {
        final repo? => repo.getLyrics(trackId),
        null => Future<ColorLyricsResponse?>.value(null),
      };

      final results = await Future.wait([
        scrollCardsFuture,
        lyricsFuture,
      ]);

      final cards = results[0] as List<ScrollCardDescriptor>;
      final lyrics = results[1] as ColorLyricsResponse?;

      _emitState(NowPlayingScrollLoaded(
        trackId: trackId,
        cards: cards,
        lyrics: lyrics,
      ));
    } catch (e) {
      _emitState(NowPlayingScrollFailure(
        trackId: trackId,
        message: e.toString(),
        fallbackCards: const [],
      ));
    }
  }

  void _emitState(NowPlayingScrollState nextState) {
    if (isClosed) return;
    _state = nextState;
    _stateController.add(nextState);
    notifyListeners();
  }

  @override
  Future<void> close() async {
    if (isClosed) return;
    await _stateController.close();
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }
}

/// Backward compatibility alias mapping NowPlayingScrollBloc directly to
/// the pure reactive [NowPlayingScrollController].
typedef NowPlayingScrollBloc = NowPlayingScrollController;
