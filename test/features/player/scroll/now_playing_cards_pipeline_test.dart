import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:musify_mu/app/app.dart';
import 'package:musify_mu/app/theme/app_theme.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool_impl.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_data_source.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/plugins/artist_v4_plugin.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/metadata.pb.dart'
    as meta_pb;
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';
import 'package:musify_mu/features/player/application/scroll/now_playing_scroll_bloc.dart';
import 'package:musify_mu/features/player/data/repositories/scrollsita_repository.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';
import 'package:musify_mu/features/player/domain/repositories/lyrics_repository.dart';
import 'package:musify_mu/features/player/domain/repositories/scrollsita_repository.dart';
import 'package:musify_mu/features/player/presentation/screens/player_screen.dart';
import 'package:musify_mu/features/player/presentation/widgets/sections/about_artist_card.dart';
import 'package:musify_mu/features/player/presentation/widgets/sections/credits_card.dart';
import 'package:musify_mu/features/player/presentation/widgets/sections/events_card.dart';

import '../../vault/integration/integration_test_helpers.dart';

final class _RecordingScrollSitaRepository implements ScrollSitaRepository {
  final List<(String?, String?)> calls = <(String?, String?)>[];
  List<ScrollCardDescriptor> responseCards;

  _RecordingScrollSitaRepository({this.responseCards = const []});

  @override
  Future<List<ScrollCardDescriptor>> getScrollCards([
    String? trackId,
    String? artistUri,
  ]) async {
    calls.add((trackId, artistUri));
    return responseCards;
  }
}

final class _RecordingLyricsRepository implements LyricsRepository {
  final List<String> calls = <String>[];
  ColorLyricsResponse? response;

  _RecordingLyricsRepository({this.response});

  @override
  Future<ColorLyricsResponse?> getLyrics(String trackId) async {
    calls.add(trackId);
    return response;
  }
}

final class _RecordingDataPool implements DataPool {
  final List<(List<String>, DataStatement)> batchCalls =
      <(List<String>, DataStatement)>[];
  final DataPoolImpl _delegate = DataPoolImpl(
    dataSource: ExtendedMetadataDataSourceImpl(),
  );

  @override
  Future<void> ensureDiskLoaded() => _delegate.ensureDiskLoaded();

  @override
  T? getTrait<T extends Trait>(String uri) => _delegate.getTrait<T>(uri);

  @override
  Map<String, Trait>? getTraits(String uri) => _delegate.getTraits(uri);

  @override
  bool hasRequiredTraits(String uri, DataStatement statement) =>
      _delegate.hasRequiredTraits(uri, statement);

  @override
  bool isKindResolved(String uri, int kind) =>
      _delegate.isKindResolved(uri, kind);

  @override
  Stream<Map<String, Trait>> watchEntity(String uri) =>
      _delegate.watchEntity(uri);

  @override
  void ingestTraits(String uri, Map<String, Trait> traits) =>
      _delegate.ingestTraits(uri, traits);

  @override
  void ingestBatch(Map<String, Map<String, Trait>> batch) =>
      _delegate.ingestBatch(batch);

  @override
  void ingestCells(Map<CellKey, Trait> cells) => _delegate.ingestCells(cells);

  @override
  void ingestRawPayloads(Map<(int, String), Uint8List> rawPayloads) =>
      _delegate.ingestRawPayloads(rawPayloads);

  @override
  Future<void> loadBatch({
    required List<String> uris,
    required DataStatement statement,
  }) async {
    batchCalls.add((List<String>.of(uris), statement));
  }

  @override
  void dispose() => _delegate.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MusifyApp DI Provisioning for Now Playing Repositories', () {
    testWidgets(
      'provides ScrollSitaRepository and LyricsRepository from GetIt into the widget tree',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final harness = TestVaultHarness();
        await tester.runAsync(harness.setup);
        final scrollRepo = _RecordingScrollSitaRepository();
        final lyricsRepo = _RecordingLyricsRepository();
        GetIt.instance.registerSingleton<ScrollSitaRepository>(scrollRepo);
        GetIt.instance.registerSingleton<LyricsRepository>(lyricsRepo);

        addTearDown(() async {
          await tester.runAsync(harness.tearDown);
        });

        await tester.pumpWidget(
          MusifyApp(
            createAuthBloc: () => FakeAuthBloc(),
            createLocalMusicBloc: () => FakeLocalMusicBloc(),
          ),
        );
        await tester.pump();

        final materialAppElement = tester.element(find.byType(MaterialApp));
        expect(
          identical(
            materialAppElement.read<ScrollSitaRepository>(),
            scrollRepo,
          ),
          isTrue,
        );
        expect(
          identical(materialAppElement.read<LyricsRepository>(), lyricsRepo),
          isTrue,
        );
      },
    );
  });

  group('PlayerScreen Now Playing Cards & Spotify-Only Network Guard', () {
    testWidgets(
      'fetches ScrollSita + Lyrics from provided repositories for eligible Spotify songs',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final pool = _RecordingDataPool();
        addTearDown(pool.dispose);

        const trackUri = 'spotify:track:3ySVdXje5nm31d7vL3jNV3';
        const artistUri = 'spotify:artist:1wRPtKGflJrBx9BmLsSwlU';

        final scrollRepo = _RecordingScrollSitaRepository(
          responseCards: const [
            LyricsCardDescriptor(entityUri: trackUri),
            CreatorBioCardDescriptor(creatorUri: artistUri),
            CreditsCardDescriptor(entityUri: trackUri),
          ],
        );
        final lyricsRepo = _RecordingLyricsRepository(
          response: ColorLyricsResponse(
            lyrics: LyricsResponse(
              lines: [LyricsLine(words: 'First Spotify lyric line')],
            ),
          ),
        );

        final spotifyTrack = ContextTrack.builder(trackUri).metadata({
          ContextTrackMetadata.keyTitle: 'Spotify Song',
          ContextTrackMetadata.keyArtistName: 'Spotify Artist',
          ContextTrackMetadata.keyArtistUri: artistUri,
        }).build();

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<DataPool>.value(value: pool),
              RepositoryProvider<ScrollSitaRepository>.value(value: scrollRepo),
              RepositoryProvider<LyricsRepository>.value(value: lyricsRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: PlayerScreen(
                title: 'Spotify Song',
                artist: 'Spotify Artist',
                currentTrack: spotifyTrack,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(scrollRepo.calls, hasLength(1));
        expect(scrollRepo.calls.single.$1, equals('3ySVdXje5nm31d7vL3jNV3'));
        expect(scrollRepo.calls.single.$2, equals(artistUri));
        expect(lyricsRepo.calls, equals(['3ySVdXje5nm31d7vL3jNV3']));
        expect(find.text('First Spotify lyric line'), findsOneWidget);
      },
    );

    testWidgets(
      'triggers ZERO Spotify network calls for local songs and Spotify-sourced Vault songs',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final pool = _RecordingDataPool();
        addTearDown(pool.dispose);
        final scrollRepo = _RecordingScrollSitaRepository();
        final lyricsRepo = _RecordingLyricsRepository();

        final localTrack = ContextTrack.builder(
          'spotify:local:Local+Artist:Local+Album:Local+Song:210',
        ).metadata({
          ContextTrackMetadata.keyIsLocal: 'true',
          ContextTrackMetadata.keyLocalFilePath: '/music/local_song.mp3',
          ContextTrackMetadata.keyTitle: 'Local Song',
          ContextTrackMetadata.keyArtistName: 'Local Artist',
        }).build();

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<DataPool>.value(value: pool),
              RepositoryProvider<ScrollSitaRepository>.value(value: scrollRepo),
              RepositoryProvider<LyricsRepository>.value(value: lyricsRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: PlayerScreen(
                title: 'Local Song',
                artist: 'Local Artist',
                currentTrack: localTrack,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(scrollRepo.calls, isEmpty);
        expect(lyricsRepo.calls, isEmpty);
        expect(pool.batchCalls, isEmpty);

        // Now open with a Spotify-sourced Private Vault track (unmasked)
        final vaultTrack = const ContextTrack(
          uri: 'spotify:track:3ySVdXje5nm31d7vL3jNV3',
          uid: 'vault_secret1',
          provider: 'musify_vault',
          metadata: {
            'is_vault_track': 'true',
            'vault_track_id': 'secret1',
            ContextTrackMetadata.keyTitle: 'Private Vault Song',
            ContextTrackMetadata.keyArtistName: 'Vault Artist',
            ContextTrackMetadata.keyArtistUri:
                'spotify:artist:1wRPtKGflJrBx9BmLsSwlU',
          },
        );

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<DataPool>.value(value: pool),
              RepositoryProvider<ScrollSitaRepository>.value(value: scrollRepo),
              RepositoryProvider<LyricsRepository>.value(value: lyricsRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: PlayerScreen(
                key: const ValueKey('vault_player'),
                title: 'Private Vault Song',
                artist: 'Vault Artist',
                currentTrack: vaultTrack,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(scrollRepo.calls, isEmpty);
        expect(lyricsRepo.calls, isEmpty);
        expect(pool.batchCalls, isEmpty);
      },
    );
  });

  group('ScrollSitaRepositoryImpl targeted batching & fallback', () {
    test(
      'returns empty and performs zero DataPool calls for vault and local tracks',
      () async {
        final pool = _RecordingDataPool();
        addTearDown(pool.dispose);
        final repo = ScrollSitaRepositoryImpl(client: null, dataPool: pool);

        expect(
          await repo.getScrollCards('spotify:local:a:b:c:100'),
          isEmpty,
        );
        expect(await repo.getScrollCards('vault:12345'), isEmpty);
        expect(await repo.getScrollCards('file:///sdcard/song.mp3'), isEmpty);
        expect(pool.batchCalls, isEmpty);
      },
    );

    test(
      'fallback preserves artistUri and preloads targeted Kodiak statements without kind mismatches',
      () async {
        final pool = _RecordingDataPool();
        addTearDown(pool.dispose);
        final repo = ScrollSitaRepositoryImpl(client: null, dataPool: pool);

        const artistUri = 'spotify:artist:1wRPtKGflJrBx9BmLsSwlU';
        final cards = await repo.getScrollCards(
          '3ySVdXje5nm31d7vL3jNV3',
          artistUri,
        );

        expect(cards, hasLength(3));
        final bioCard = cards.whereType<CreatorBioCardDescriptor>().single;
        expect(bioCard.creatorUri, equals(artistUri));

        // Verify targeted DataPool batches were issued for track + artist
        expect(pool.batchCalls, hasLength(3));

        final artistBatch = pool.batchCalls.singleWhere(
          (call) => call.$1.contains(artistUri),
        );
        final artistKinds = artistBatch.$2.requirements
            .map((r) => (r.extensionKindValue, r.traitType))
            .toSet();
        expect(
          artistKinds,
          containsAll(<(int, Type)>[
            (178, IdentityTrait),
            (8, ArtistV4),
            (179, VisualIdentityTrait),
            (185, OnPlatformReputationTrait),
          ]),
        );

        final creditsBatch = pool.batchCalls.singleWhere(
          (call) => call.$2.requirements.any((r) => r.traitType == CreditsTrait),
        );
        expect(creditsBatch.$1, equals(['spotify:track:3ySVdXje5nm31d7vL3jNV3']));
        expect(
          creditsBatch.$2.requirements.map((r) => r.extensionKindValue),
          containsAll(<int>[10, 186]),
        );
      },
    );

    test(
      'NowPlayingScrollController clears state and cancels stale responses on ClearNowPlayingScroll',
      () async {
        final completer = Completer<List<ScrollCardDescriptor>>();
        final slowRepo = _CompleterScrollSitaRepository(completer);
        final controller = NowPlayingScrollController(
          scrollSitaRepository: slowRepo,
        );
        addTearDown(controller.close);

        controller.add(
          const FetchNowPlayingScroll(
            '3ySVdXje5nm31d7vL3jNV3',
            'spotify:artist:1wRPtKGflJrBx9BmLsSwlU',
          ),
        );
        expect(controller.state, isA<NowPlayingScrollLoading>());

        // Switch to a local/vault track while request is in-flight
        controller.add(const ClearNowPlayingScroll());
        expect(controller.state, isA<NowPlayingScrollInitial>());

        // Complete stale Spotify response; must be ignored
        completer.complete(const [
          LyricsCardDescriptor(entityUri: 'spotify:track:3ySVdXje5nm31d7vL3jNV3'),
        ]);
        await Future<void>.delayed(Duration.zero);

        expect(controller.state, isA<NowPlayingScrollInitial>());
      },
    );
  });

  group('Reactive Now Playing Card Widgets & ArtistV4Plugin', () {
    test('ArtistV4Plugin decodes biography (sanitized) and portraitGroup', () {
      final protoArtist = meta_pb.Artist(
        name: 'The Weeknd',
        popularity: 95,
        biography: [
          meta_pb.Biography(
            text:
                'Known for <a href="spotify:album:abc">After Hours</a> &amp; Starboy.',
          ),
        ],
        portraitGroup: meta_pb.ImageGroup(
          image: [
            meta_pb.Image(
              fileId: const <int>[0xab, 0xcd, 0xef, 0x01],
              size: meta_pb.Image_Size.LARGE,
            ),
          ],
        ),
      );

      final parsed = const ArtistV4Plugin().parse(
        Uint8List.fromList(protoArtist.writeToBuffer()),
      );

      expect(parsed.name, equals('The Weeknd'));
      expect(parsed.popularity, equals(95));
      expect(parsed.biography, equals('Known for After Hours & Starboy.'));
      expect(
        parsed.portrait.largeUrl,
        equals('https://i.scdn.co/image/abcdef01'),
      );
    });

    testWidgets(
      'PlayerCreditsSection rebuilds reactively when CreditsTrait arrives in DataPool',
      (tester) async {
        final pool = DataPoolImpl(dataSource: ExtendedMetadataDataSourceImpl());
        addTearDown(pool.dispose);
        const trackUri = 'spotify:track:creditsReactive1';

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: PlayerCreditsSection(
                artistName: 'Fallback Artist',
                dataPool: pool,
                trackUri: trackUri,
              ),
            ),
          ),
        );

        expect(find.text('Fallback Artist'), findsOneWidget);

        pool.ingestTraits(trackUri, {
          '$CreditsTrait': CreditsTrait(
            contributors: const [
              CreditContributor(
                name: 'Max Martin',
                role: 'Producer',
                uri: 'spotify:artist:max',
              ),
              CreditContributor(
                name: 'Max Martin',
                role: 'Writer',
                uri: 'spotify:artist:max',
              ),
            ],
          ),
        });
        await tester.pump();

        expect(find.text('Max Martin'), findsOneWidget);
        expect(find.text('Producer \u2022 Writer'), findsOneWidget);
      },
    );

    testWidgets(
      'PlayerAboutArtistSection displays ArtistV4 biography and OnPlatformReputationTrait metrics',
      (tester) async {
        final pool = DataPoolImpl(dataSource: ExtendedMetadataDataSourceImpl());
        addTearDown(pool.dispose);
        const artistUri = 'spotify:artist:aboutReactive1';

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: PlayerAboutArtistSection(
                artistName: 'Placeholder Artist',
                dataPool: pool,
                artistUri: artistUri,
              ),
            ),
          ),
        );

        pool.ingestTraits(artistUri, {
          '$ArtistV4': const ArtistV4(
            name: 'Daft Punk',
            biography: 'French electronic duo formed in Paris.',
          ),
          '$OnPlatformReputationTrait': const OnPlatformReputationTrait(
            monthlyListeners: 24500000,
            isVerified: true,
          ),
        });
        await tester.pump();

        expect(find.text('Daft Punk'), findsOneWidget);
        expect(find.text('24.5M monthly listeners'), findsOneWidget);
        expect(
          find.textContaining('French electronic duo formed in Paris.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'PlayerEventsSection watches concertUris for ConcertTrait and ConcertLocationTrait',
      (tester) async {
        final pool = DataPoolImpl(dataSource: ExtendedMetadataDataSourceImpl());
        addTearDown(pool.dispose);
        const artistUri = 'spotify:artist:tourArtist1';
        const concertUri = 'spotify:concert:tourStop1';

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: SingleChildScrollView(
                child: PlayerEventsSection(
                  artistName: 'Tour Artist',
                  dataPool: pool,
                  artistUri: artistUri,
                  concertUris: const [concertUri],
                ),
              ),
            ),
          ),
        );

        pool.ingestTraits(concertUri, {
          '$ConcertTrait': const ConcertTrait(
            title: 'World Tour 2026',
            artistName: 'Tour Artist Live',
            eventDateTimestamp: 1795132800,
          ),
          '$ConcertLocationTrait': const ConcertLocationTrait(
            venue: 'Wembley Stadium',
            city: 'London',
          ),
        });
        await tester.pump();

        expect(find.text('World Tour 2026'), findsOneWidget);
        expect(find.text('Tour Artist Live'), findsOneWidget);
        expect(find.text('Wembley Stadium \u00B7 London'), findsOneWidget);
      },
    );
  });
}

final class _CompleterScrollSitaRepository implements ScrollSitaRepository {
  final Completer<List<ScrollCardDescriptor>> completer;

  _CompleterScrollSitaRepository(this.completer);

  @override
  Future<List<ScrollCardDescriptor>> getScrollCards([
    String? trackId,
    String? artistUri,
  ]) => completer.future;
}
