import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show StateStreamableSource;
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';
import 'package:musify_mu/features/player/domain/policies/spotify_track_eligibility_policy.dart';
import 'package:musify_mu/features/player/domain/repositories/lyrics_repository.dart';
import 'package:musify_mu/features/player/domain/repositories/scrollsita_repository.dart';

import 'now_playing_scroll_event.dart';
import 'now_playing_scroll_state.dart';

export 'now_playing_scroll_event.dart';
export 'now_playing_scroll_state.dart';

/// Pure reactive controller coordinating Now Playing scroll cards and color-synced lyrics pipeline.
///
/// Implements [ValueListenable] and [StateStreamableSource] without extending BLoC internals,
/// driving deterministic unidirectional state flow with restartable generation guards.
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
  String? _lastArtistUri;
  int _requestGeneration = 0;

  NowPlayingScrollController({
    ScrollSitaRepository? scrollSitaRepository,
    LyricsRepository? lyricsRepository,
  }) : _scrollSitaRepository = scrollSitaRepository,
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
      case FetchNowPlayingScroll(:final trackId, :final artistUri):
        unawaited(_fetchScroll(trackId, artistUri: artistUri));
      case ClearNowPlayingScroll():
        _clearScroll();
    }
  }

  void _clearScroll() {
    _requestGeneration++;
    _lastTrackId = null;
    _lastArtistUri = null;
    if (_state is! NowPlayingScrollInitial) {
      _emitState(const NowPlayingScrollInitial());
    }
  }

  Future<void> _fetchScroll(String? trackId, {String? artistUri}) async {
    final canonicalId =
        SpotifyTrackEligibilityPolicy.extractCanonicalSpotifyTrackId(trackId);

    // Strictly skip all network calls for missing, local, vault, or non-track IDs.
    if (canonicalId == null) {
      _clearScroll();
      return;
    }

    final normalizedArtistUri =
        SpotifyTrackEligibilityPolicy.resolveCanonicalSpotifyArtistUri(
          artistUri,
        );

    // Skip duplicate requests when already loaded for the identical track & artist.
    if (canonicalId == _lastTrackId &&
        normalizedArtistUri == _lastArtistUri &&
        _state is NowPlayingScrollLoaded) {
      return;
    }

    final generation = ++_requestGeneration;
    _lastTrackId = canonicalId;
    _lastArtistUri = normalizedArtistUri;

    _emitState(
      NowPlayingScrollLoading(
        trackId: canonicalId,
        currentCards: const [],
      ),
    );

    Object? scrollError;
    Object? lyricsError;

    final scrollCardsFuture = switch (_scrollSitaRepository) {
      final repo? => repo
          .getScrollCards(canonicalId, normalizedArtistUri)
          .catchError((Object e, StackTrace st) {
            scrollError = e;
            dev.log(
              'NowPlayingScrollController: ScrollSita fetch failed for $canonicalId',
              error: e,
              stackTrace: st,
              name: 'NowPlayingScroll',
            );
            return const <ScrollCardDescriptor>[];
          }),
      null => Future<List<ScrollCardDescriptor>>.value(const []),
    };

    final lyricsFuture = switch (_lyricsRepository) {
      final repo? => repo
          .getLyrics(canonicalId)
          .catchError((Object e, StackTrace st) {
            lyricsError = e;
            dev.log(
              'NowPlayingScrollController: Lyrics fetch failed for $canonicalId',
              error: e,
              stackTrace: st,
              name: 'NowPlayingScroll',
            );
            return null;
          }),
      null => Future<ColorLyricsResponse?>.value(null),
    };

    final cards = await scrollCardsFuture;
    final lyrics = await lyricsFuture;

    // Ignore superseded or cleared track responses deterministically.
    if (generation != _requestGeneration || isClosed) {
      return;
    }

    if (scrollError != null && lyricsError != null) {
      _emitState(
        NowPlayingScrollFailure(
          trackId: canonicalId,
          message: scrollError.toString(),
          fallbackCards: const [],
        ),
      );
      return;
    }

    _emitState(
      NowPlayingScrollLoaded(
        trackId: canonicalId,
        cards: cards,
        lyrics: lyrics,
      ),
    );
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
    _requestGeneration++;
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
