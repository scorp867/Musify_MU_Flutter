import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/color/artwork_color_scheme.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/color/eased_gradient.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';
import 'package:musify_mu/features/player/application/scroll/now_playing_scroll_bloc.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';

import '../scroll/scroll_card_registry.dart';
import '../widgets/sections/lyrics_color_parser.dart';

import '../widgets/peek_scroll_view.dart';
import '../widgets/player_artwork.dart';
import '../widgets/player_controls.dart';
import '../widgets/player_header.dart';
import '../widgets/player_metadata.dart';
import '../widgets/player_sections.dart';
import '../widgets/player_sheets.dart';
import '../widgets/player_theme.dart';
import '../widgets/pull_to_dismiss_scaffold.dart';
import 'queue_sheet_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.playbackController,
  });

  final PlaybackController playbackController;

  static bool _isOpen = false;

  /// Launches the Now Playing view as a full-screen edge-to-edge window with
  /// native Spotify transition curves and single-top route guarding.
  static Future<void> show(
    BuildContext context,
    PlaybackController playbackController,
  ) async {
    if (_isOpen) return;
    _isOpen = true;

    try {
      await Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder<void>(
          opaque: false,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.70),
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (context, animation, secondaryAnimation) {
            return PlayerScreen(
              playbackController: playbackController,
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Cubic(0.3, 0.0, 0.0, 1.0);
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: curve,
                reverseCurve: curve,
              ),
            );
            return SlideTransition(
              position: slideAnimation,
              child: child,
            );
          },
        ),
      );
    } finally {
      _isOpen = false;
    }
  }

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  PlaybackController get _playbackController => widget.playbackController;

  final GlobalKey<PeekScrollViewState> _peekScrollKey =
      GlobalKey<PeekScrollViewState>();
  final GlobalKey _lyricsKey = GlobalKey();

  Duration? _dragPosition;
  bool _isFavorite = false;
  bool _shuffleEnabled = false;
  bool _repeatEnabled = false;

  ArtworkColorScheme _currentScheme = ArtworkColorScheme.neutral;
  String? _lastTrackId;

  MediaItem? _displayedItem;
  MediaItem? _pendingQueueItem;
  bool _hasPendingQueueItem = false;
  StreamSubscription<MediaItem?>? _mediaItemSubscription;
  Timer? _deferredQueueSyncTimer;

  ColorExtractionService? _resolveColorService() {
    try {
      return context.read<ColorExtractionService>();
    } catch (_) {
      try {
        return getIt<ColorExtractionService>();
      } catch (_) {
        return null;
      }
    }
  }

  ScrollCardRegistry? _registry;
  late final NowPlayingScrollBloc _scrollBloc;
  bool _ownsBloc = false;

  @override
  void initState() {
    super.initState();
    _initRegistry();
    try {
      _scrollBloc = context.read<NowPlayingScrollBloc>();
    } catch (_) {
      _scrollBloc = getIt<NowPlayingScrollBloc>();
      _ownsBloc = true;
    }
    _displayedItem = _playbackController.currentMediaItem;
    QueueSheetScreen.isOpenNotifier.addListener(_onQueueSheetOpenChanged);
    _mediaItemSubscription =
        _playbackController.mediaItem.listen(_onMediaItemChanged);
  }

  @override
  void dispose() {
    _deferredQueueSyncTimer?.cancel();
    _mediaItemSubscription?.cancel();
    QueueSheetScreen.isOpenNotifier.removeListener(_onQueueSheetOpenChanged);
    if (_ownsBloc) {
      _scrollBloc.close();
    }
    super.dispose();
  }

  void _onQueueSheetOpenChanged() {
    if (!QueueSheetScreen.isOpenNotifier.value && _hasPendingQueueItem) {
      _deferredQueueSyncTimer?.cancel();
      _flushPendingMediaItem();
    }
  }

  void _onMediaItemChanged(MediaItem? item) {
    if (!mounted) return;
    if (QueueSheetScreen.isOpenNotifier.value) {
      // While the Queue Sheet is open on top of PlayerScreen, defer rebuilding
      // PlayerScreen, decoding 720x720 artwork textures, and running 200x200
      // GPU readbacks for palette extraction until the Queue Sheet animation
      // and ExoPlayer codec transition are completely finished.
      _pendingQueueItem = item;
      _hasPendingQueueItem = true;
      _deferredQueueSyncTimer?.cancel();
      _deferredQueueSyncTimer = Timer(
        const Duration(milliseconds: 900),
        _flushPendingMediaItem,
      );
      return;
    }

    _deferredQueueSyncTimer?.cancel();
    _hasPendingQueueItem = false;
    if (_displayedItem != item) {
      setState(() {
        _displayedItem = item;
      });
    }
  }

  void _flushPendingMediaItem() {
    if (!mounted || !_hasPendingQueueItem) return;
    final nextItem = _pendingQueueItem;
    _hasPendingQueueItem = false;
    _pendingQueueItem = null;
    if (_displayedItem != nextItem) {
      setState(() {
        _displayedItem = nextItem;
      });
    }
  }

  DataPool? _resolveDataPool() {
    try {
      return context.read<DataPool>();
    } catch (_) {
      try {
        return getIt<DataPool>();
      } catch (_) {
        return null;
      }
    }
  }

  void _initRegistry() {
    final pool = _resolveDataPool();
    _registry = ScrollCardRegistry(dataPool: pool)
      ..register<CreatorBioCardDescriptor>((context, desc) {
        final current = _playbackController.currentMediaItem;
        if (current == null) return const SizedBox.shrink();
        return PlayerAboutArtistSection(
          item: current,
          dataPool: pool,
          artistUri: desc.creatorUri,
        );
      })
      ..register<CreditsCardDescriptor>((context, desc) {
        final current = _playbackController.currentMediaItem;
        if (current == null) return const SizedBox.shrink();
        return PlayerCreditsSection(
          item: current,
          dataPool: pool,
          trackUri: desc.entityUri,
          contributorUris: desc.contributorUris,
        );
      })
      ..register<LiveEventsCardDescriptor>((context, desc) {
        final current = _playbackController.currentMediaItem;
        return PlayerEventsSection(
          artistName: current?.artist ?? 'Artist',
          artistUri: desc.artistUri,
          dataPool: pool,
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

  void _updateScheme(MediaItem? item) async {
    if (item == null) return;
    if (_lastTrackId == item.id) return;
    _lastTrackId = item.id;

    _scrollBloc.add(FetchNowPlayingScroll(item));

    final service = _resolveColorService();
    if (service == null) return;

    final artUriString = item.artUri?.toString();
    final cached = service.getCached(item.id) ??
        (artUriString != null ? service.getCached(artUriString) : null);

    if (cached != null) {
      if (mounted && _currentScheme != cached) {
        setState(() => _currentScheme = cached);
      }
      return;
    }

    ArtworkColorScheme? scheme;
    final artUri = item.artUri;
    if (artUri != null && (artUri.scheme == 'http' || artUri.scheme == 'https')) {
      try {
        scheme = await service.extract(
          imageUrl: artUri.toString(),
          cacheKey: item.id,
        );
      } catch (_) {}
    }

    if (scheme == null) {
      final songId = MediaItemMapper.songId(item);
      if (songId != null) {
        try {
          scheme = await service.extract(
            songId: songId,
            cacheKey: item.id,
          );
        } catch (_) {}
      }
    }

    if (mounted && scheme != null && _currentScheme != scheme) {
      final nonNullScheme = scheme;
      setState(() => _currentScheme = nonNullScheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _displayedItem;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: PullToDismissScaffold(
        builder: (context, dismissController) {
          if (item == null) {
            return PlayerEmptyState(
              onClose: dismissController.dismiss,
              onMore: () => _showMoreOptions(context),
            );
          }

          return _buildPlayer(context, item, dismissController);
        },
      ),
    );
  }

  Widget _buildPlayer(
    BuildContext context,
    MediaItem item,
    PullToDismissController dismissController,
  ) {
    _updateScheme(item);

    // Spotify's OverlayHidingGradientBackgroundView formula:
    // Blend 32% of #121212 over the extracted color at the top (PorterDuff DST_OVER)
    // to eliminate specular glare and prevent any light gradient at the top edge.
    final topGradientColor = Color.lerp(
      _currentScheme.primary,
      const Color(0xFF121212),
      0.32,
    )!;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Solid opaque base layer (#121212)
        const ColoredBox(color: Color(0xFF121212)),

        // 2. Player content scroll view with Tier 1 viewport gradient
        // The gradient is applied strictly to Tier 1 so it scrolls UP with the player
        // and does NOT persist behind the Tier 2 cards stream.
        BlocBuilder<NowPlayingScrollBloc, NowPlayingScrollState>(
          bloc: _scrollBloc,
          builder: (context, scrollState) {
            final colorLyrics = scrollState is NowPlayingScrollLoaded
                ? scrollState.lyrics
                : null;
            final bg = colorLyrics != null && colorLyrics.hasColors()
                ? parseProtoColor(colorLyrics.colors.background)
                : _currentScheme.surface;
            final cards = scrollState is NowPlayingScrollLoaded
                ? scrollState.cards
                : (scrollState is NowPlayingScrollFailure
                    ? scrollState.fallbackCards
                    : const <ScrollCardDescriptor>[]);

            return PeekScrollView(
              key: _peekScrollKey,
              dismissController: dismissController,
              peekHeight: 64.0,
              tier1Decoration: BoxDecoration(
                gradient: EasedGradient.build(
                  topColor: topGradientColor,
                  bottomColor: const Color(0xFF121212),
                ),
              ),
              header: PlayerHeader(
                onClose: dismissController.dismiss,
                onMore: () => _showMoreOptions(context),
                contextTitle: 'PLAYING FROM ALBUM',
                contextSubtitle: item.album,
              ),
              mainContent: Column(
                children: [
                  const Spacer(flex: 1),
                  Flexible(
                    flex: 16,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 380,
                        maxHeight: 380,
                      ),
                      child: PlayerAlbumArtwork(item: item),
                    ),
                  ),
                  const Spacer(flex: 1),
                  PlayerMetadata(
                    item: item,
                    isFavorite: _isFavorite,
                    onFavoriteChanged: _toggleFavorite,
                  ),
                  const SizedBox(height: 10),
                  PlayerSeekBar(
                    item: item,
                    playbackController: _playbackController,
                    dragPosition: _dragPosition,
                    onDragPositionChanged: _setDragPosition,
                  ),
                  const SizedBox(height: 8),
                  PlayerPlaybackControls(
                    item: item,
                    playbackController: _playbackController,
                    shuffleEnabled: _shuffleEnabled,
                    repeatEnabled: _repeatEnabled,
                    onShuffle: _toggleShuffle,
                    onRepeat: _toggleRepeat,
                  ),
                  const SizedBox(height: 6),
                  PlayerUtilityRow(
                    onQueue: () => _showQueue(context),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              peekingCard: PlayerLyricsSection(
                key: _lyricsKey,
                onTapHeader: _onExpandLyrics,
                backgroundColor: bg,
                colorLyrics: colorLyrics,
                dataPool: _resolveDataPool(),
                trackUri: (item.extras?['trackUri'] as String?) ?? item.id,
              ),
              expandedCards: _buildExpandedCards(item, _resolveDataPool(), cards),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildExpandedCards(
    MediaItem item,
    DataPool? pool,
    List<ScrollCardDescriptor> scrollCards,
  ) {
    if (scrollCards.isEmpty) {
      return [
        PlayerAboutArtistSection(item: item, dataPool: pool),
        PlayerCreditsSection(item: item, dataPool: pool),
      ];
    }

    final widgets = <Widget>[];
    for (final desc in scrollCards) {
      if (desc is LyricsCardDescriptor) continue;
      final cardWidget = _registry?.buildCard(context, desc);
      if (cardWidget != null) {
        widgets.add(cardWidget);
      }
    }

    if (widgets.isEmpty) {
      return [
        PlayerAboutArtistSection(item: item, dataPool: pool),
        PlayerCreditsSection(item: item, dataPool: pool),
      ];
    }
    return widgets;
  }

  void _onExpandLyrics() {
    _peekScrollKey.currentState?.scrollToExpanded();
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _setDragPosition(Duration? position) {
    setState(() {
      _dragPosition = position;
    });
  }

  void _toggleShuffle() {
    setState(() {
      _shuffleEnabled = !_shuffleEnabled;
    });

    _playbackController.setShuffleMode(
      _shuffleEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    );
  }

  void _toggleRepeat() {
    setState(() {
      _repeatEnabled = !_repeatEnabled;
    });

    _playbackController.setRepeatMode(
      _repeatEnabled ? AudioServiceRepeatMode.one : AudioServiceRepeatMode.none,
    );
  }

  void _showQueue(BuildContext context) {
    QueueSheetScreen.show(context, _playbackController);
  }

  void _showMoreOptions(BuildContext context) {
    final item = _playbackController.currentMediaItem;

    if (item == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PlayerColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return PlayerOptionsSheet(
          onShowDetails: () => _showTrackDetails(context, item),
          onShowQueue: () => _showQueue(context),
        );
      },
    );
  }

  void _showTrackDetails(BuildContext context, MediaItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PlayerColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => PlayerTrackDetailsSheet(item: item),
    );
  }
}
