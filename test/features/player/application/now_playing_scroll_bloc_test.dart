import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/features/player/application/scroll/now_playing_scroll_bloc.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';
import 'package:musify_mu/features/player/domain/repositories/lyrics_repository.dart';
import 'package:musify_mu/features/player/domain/repositories/scrollsita_repository.dart';

class FakeScrollSitaRepository implements ScrollSitaRepository {
  List<ScrollCardDescriptor> cardsToReturn = const [];
  bool shouldThrow = false;

  @override
  Future<List<ScrollCardDescriptor>> getScrollCards(MediaItem item) async {
    if (shouldThrow) {
      throw Exception('Network error');
    }
    return cardsToReturn;
  }
}

class FakeLyricsRepository implements LyricsRepository {
  ColorLyricsResponse? lyricsToReturn;
  bool shouldThrow = false;

  @override
  Future<ColorLyricsResponse?> getLyrics(String trackId) async {
    if (shouldThrow) {
      throw Exception('Lyrics error');
    }
    return lyricsToReturn;
  }
}

void main() {
  group('NowPlayingScrollBloc', () {
    late FakeScrollSitaRepository scrollSitaRepo;
    late FakeLyricsRepository lyricsRepo;
    late NowPlayingScrollBloc bloc;

    const testItem = MediaItem(
      id: 'spotify:track:test1234',
      title: 'Starboy',
      artist: 'The Weeknd',
    );

    setUp(() {
      scrollSitaRepo = FakeScrollSitaRepository();
      lyricsRepo = FakeLyricsRepository();
      bloc = NowPlayingScrollBloc(
        scrollSitaRepository: scrollSitaRepo,
        lyricsRepository: lyricsRepo,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is NowPlayingScrollInitial', () {
      // Assert
      expect(bloc.state, isA<NowPlayingScrollInitial>());
    });

    test('emits [Loading, Loaded] when repositories return data successfully', () async {
      // Arrange
      final expectedCards = [
        const LyricsCardDescriptor(entityUri: 'spotify:track:test1234'),
        const CreatorBioCardDescriptor(creatorUri: 'spotify:artist:theweeknd'),
      ];
      final expectedLyrics = ColorLyricsResponse();
      scrollSitaRepo.cardsToReturn = expectedCards;
      lyricsRepo.lyricsToReturn = expectedLyrics;

      // Act & Assert
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<NowPlayingScrollLoading>(),
          isA<NowPlayingScrollLoaded>()
              .having((s) => s.item.id, 'item.id', 'spotify:track:test1234')
              .having((s) => s.cards.length, 'cards.length', 2)
              .having((s) => s.lyrics, 'lyrics', expectedLyrics),
        ]),
      );

      bloc.add(const FetchNowPlayingScroll(testItem));
    });

    test('emits [Loading, Failure] when repository throws error', () async {
      // Arrange
      scrollSitaRepo.shouldThrow = true;

      // Act & Assert
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<NowPlayingScrollLoading>(),
          isA<NowPlayingScrollFailure>()
              .having((s) => s.item.id, 'item.id', 'spotify:track:test1234'),
        ]),
      );

      bloc.add(const FetchNowPlayingScroll(testItem));
    });
  });
}
