import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/player/application/scroll/now_playing_scroll_bloc.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';
import 'package:musify_mu/features/player/presentation/scroll/scroll_card_registry.dart';
import 'package:musify_mu/features/player/presentation/widgets/sections/lyrics_card.dart';
import 'package:musify_mu/features/player/presentation/widgets/sections/lyrics_color_parser.dart';
import 'package:musify_mu/features/player/presentation/widgets/sections/about_artist_card.dart';
import 'package:musify_mu/features/player/presentation/widgets/sections/credits_card.dart';
import 'package:musify_mu/features/player/presentation/widgets/sections/events_card.dart';
import 'package:musify_mu/features/player/presentation/widgets/sections/merch_card.dart';

/// Debug screen for testing the NowPlaying scroll cards + lyrics pipeline
/// without requiring actual audio playback.
///
/// Feeds a hardcoded Spotify MediaItem into the BLoC and renders
/// the resulting scroll cards and lyrics exactly as the real player would.
class DebugNowPlayingScreen extends StatefulWidget {
  const DebugNowPlayingScreen({super.key});

  @override
  State<DebugNowPlayingScreen> createState() => _DebugNowPlayingScreenState();
}

class _DebugNowPlayingScreenState extends State<DebugNowPlayingScreen> {
  late final NowPlayingScrollBloc _bloc;
  ScrollCardRegistry? _registry;
  DataPool? _pool;

  // Test track: spotify:track:3ySVdXje5nm31d7vL3jNV3
  static final _testItem = MediaItem(
    id: 'spotify:track:3ySVdXje5nm31d7vL3jNV3',
    title: 'Saiyaara',
    artist: 'Sohail Sen, Mohit Chauhan, Tarannum Malik Jain',
    album: 'Ek Tha Tiger',
    artUri: Uri.parse(
      'https://i.scdn.co/image/ab67616d0000b273e8b066f70c206551210d902b',
    ),
    extras: const {
      'uri': 'spotify:track:3ySVdXje5nm31d7vL3jNV3',
      'trackId': '3ySVdXje5nm31d7vL3jNV3',
      'artistUri': 'spotify:artist:1bTROl5p3rGTpvKeWnGgrw',
      'monthlyListeners': 11400000,
      'isVerified': true,
      'artistBio':
          'Sohail Sen is a film composer and independent artist creating music across major Hindi films including What’s Your Raashee?, Mere Brother Ki Dulhan, Ek Tha Tiger, and Gunday.',
    },
  );

  @override
  void initState() {
    super.initState();
    _bloc = getIt<NowPlayingScrollBloc>();
    _resolveDataPool();
    _initRegistry();
  }

  void _resolveDataPool() {
    try {
      _pool = context.read<DataPool>();
    } catch (_) {
      try {
        _pool = getIt<DataPool>();
      } catch (_) {}
    }
  }

  void _initRegistry() {
    _registry = ScrollCardRegistry(dataPool: _pool)
      ..register<CreatorBioCardDescriptor>((context, desc) {
        return PlayerAboutArtistSection(
          item: _testItem,
          dataPool: _pool,
          artistUri: desc.creatorUri,
        );
      })
      ..register<CreditsCardDescriptor>((context, desc) {
        return PlayerCreditsSection(
          item: _testItem,
          dataPool: _pool,
          trackUri: desc.entityUri,
          contributorUris: desc.contributorUris,
        );
      })
      ..register<LiveEventsCardDescriptor>((context, desc) {
        return PlayerEventsSection(
          artistName: _testItem.artist ?? 'Artist',
          artistUri: desc.artistUri,
          dataPool: _pool,
          onShowAll: () {},
        );
      })
      ..register<MerchCardDescriptor>((context, desc) {
        return PlayerMerchSection(
          items: const [],
          onShowAll: () {},
        );
      });
  }

  void _fetchData() {
    _bloc.add(FetchNowPlayingScroll(_testItem));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'Debug: NowPlaying Pipeline',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Trigger button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _fetchData,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Fetch: 3ySVdXje5nm31d7vL3jNV3'),
              ),
            ),
          ),

          // Results
          Expanded(
            child: BlocBuilder<NowPlayingScrollBloc, NowPlayingScrollState>(
              bloc: _bloc,
              builder: (context, state) {
                if (state is NowPlayingScrollInitial) {
                  return const Center(
                    child: Text(
                      'Tap the button to fetch scrollsita + lyrics',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  );
                }

                if (state is NowPlayingScrollLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1DB954)),
                  );
                }

                if (state is NowPlayingScrollFailure) {
                  return _buildFailureView(state);
                }

                if (state is NowPlayingScrollLoaded) {
                  return _buildLoadedView(state);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureView(NowPlayingScrollFailure state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FAILURE',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Text(
            'Fallback cards: ${state.fallbackCards.length}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedView(NowPlayingScrollLoaded state) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Status header
        _sectionHeader('PIPELINE STATUS'),
        _statusRow('Scroll cards', '${state.cards.length} received'),
        _statusRow('Lyrics', state.lyrics != null ? 'received' : 'null'),
        if (state.lyrics != null) ...[
          _statusRow(
            'Lyrics lines',
            state.lyrics!.hasLyrics()
                ? '${state.lyrics!.lyrics.lines.length} lines'
                : 'no lyrics payload',
          ),
          _statusRow(
            'Colors',
            state.lyrics!.hasColors() ? 'has colors' : 'no colors',
          ),
          if (state.lyrics!.hasColors()) ...[
            _colorSwatch(
              'Background',
              parseProtoColor(state.lyrics!.colors.background),
            ),
            _colorSwatch(
              'Text',
              parseProtoColor(state.lyrics!.colors.text),
            ),
            _colorSwatch(
              'Highlight',
              parseProtoColor(state.lyrics!.colors.highlightText),
            ),
          ],
        ],

        const Divider(color: Colors.white12, height: 32),

        // Card descriptors debug info
        _sectionHeader('SCROLL CARD DESCRIPTORS'),
        for (final desc in state.cards) _cardDescriptorInfo(desc),

        const Divider(color: Colors.white12, height: 32),

        // Rendered cards (actual UI widgets)
        _sectionHeader('RENDERED CARDS'),
        _buildLyricsCard(state),
        ...state.cards
            .where((d) => d is! LyricsCardDescriptor)
            .map((desc) {
          final widget = _registry?.buildCard(context, desc);
          if (widget != null) return widget;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'No renderer for ${desc.runtimeType}',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
          );
        }),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildLyricsCard(NowPlayingScrollLoaded state) {
    final colorLyrics = state.lyrics;
    final bg = colorLyrics != null && colorLyrics.hasColors()
        ? parseProtoColor(colorLyrics.colors.background)
        : const Color(0xFF121212);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PlayerLyricsSection(
        onTapHeader: () {},
        backgroundColor: bg,
        colorLyrics: colorLyrics,
        dataPool: _pool,
        trackUri: state.item.id,
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorSwatch(String label, Color color) {
    final hex =
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.white24),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $hex',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _cardDescriptorInfo(ScrollCardDescriptor desc) {
    String info;
    if (desc is LyricsCardDescriptor) {
      info = 'LyricsCard (entity: ${desc.entityUri})';
    } else if (desc is CreatorBioCardDescriptor) {
      info = 'CreatorBio (creator: ${desc.creatorUri})';
    } else if (desc is CreditsCardDescriptor) {
      info = 'Credits (entity: ${desc.entityUri})';
    } else if (desc is LiveEventsCardDescriptor) {
      info = 'LiveEvents (artist: ${desc.artistUri})';
    } else if (desc is MerchCardDescriptor) {
      info = 'Merch (entity: ${desc.entityUri})';
    } else {
      info = desc.runtimeType.toString();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '\u2022 ',
            style: TextStyle(color: Color(0xFF1DB954), fontSize: 13),
          ),
          Flexible(
            child: Text(
              info,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
