import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/color/eased_gradient.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';

import '../../application/queue/player_queue_bloc.dart';
import '../../application/scroll/now_playing_scroll_bloc.dart';
import '../../data/queue/context_track_extensions.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/scroll_card_descriptor.dart';
import '../scroll/scroll_card_registry.dart';
import '../widgets/peek_scroll_view.dart';
import '../widgets/player_artwork.dart';
import '../widgets/player_controls.dart';
import '../widgets/player_header.dart';
import '../widgets/player_metadata.dart';
import '../widgets/player_sections.dart';
import '../widgets/player_sheets.dart';
import '../widgets/player_theme.dart';
import '../widgets/pull_to_dismiss_scaffold.dart';
import '../widgets/queue_controls_layout.dart';
import 'queue_sheet_screen.dart';
import '../../../../core/ubi/domain/logging/ubi_logger.dart';
import '../../../../core/ubi/domain/models/page_instance_id.dart';
import '../../../../core/ubi/data/lifecycle/page_instance_id_holder.dart';
import '../../../player/data/logging/player_logging_params_factory.dart';
import '../../../player/domain/commands/options/logging_params.dart';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String? imageUrl;
  final int? songId;
  final PlayerQueueBloc? queueBloc;
  final ContextTrack? currentTrack;

  const PlayerScreen({
    super.key,
    this.title = 'Starboy',
    this.artist = 'The Weeknd, Daft Punk',
    this.album = 'Starboy',
    this.duration = const Duration(minutes: 3, seconds: 50),
    this.imageUrl,
    this.songId,
    this.queueBloc,
    this.currentTrack,
  });

  static bool _isOpen = false;

  /// Launches the Now Playing view as a full-screen edge-to-edge window with
  /// native Spotify transition curves and single-top route guarding.
  static Future<void> show(
    BuildContext context, {
    String title = 'Starboy',
    String artist = 'The Weeknd, Daft Punk',
    String album = 'Starboy',
    Duration duration = const Duration(minutes: 3, seconds: 50),
    String? imageUrl,
    int? songId,
    PlayerQueueBloc? queueBloc,
    ContextTrack? currentTrack,
  }) async {
    if (_isOpen) return;
    _isOpen = true;

    final effectiveBloc = queueBloc ??
        (getIt.isRegistered<PlayerQueueBloc>() ? getIt<PlayerQueueBloc>() : null);

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
              title: title,
              artist: artist,
              album: album,
              duration: duration,
              imageUrl: imageUrl,
              songId: songId,
              queueBloc: effectiveBloc,
              currentTrack: currentTrack,
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
  final GlobalKey<PeekScrollViewState> _peekScrollKey =
      GlobalKey<PeekScrollViewState>();

  final ValueNotifier<Duration?> _dragNotifier = ValueNotifier<Duration?>(null);
  late final ValueNotifier<Duration> _positionNotifier;

  late final NowPlayingScrollBloc _scrollBloc;
  late final ScrollCardRegistry _cardRegistry;
  DataPool? _dataPool;
  String _currentTrackId = '';

  bool _isPlaying = false;
  bool _isFavorite = false;
  QueueShuffleMode _shuffleMode = QueueShuffleMode.none;
  QueueRepeatMode _repeatMode = QueueRepeatMode.none;

  Timer? _positionTimer;
  late final PageInstanceId _pageInstanceId;

  PageInstanceId get pageInstanceId => _pageInstanceId;

  static const Color _topGradientColor = Color(0xFF1E3264);

  // Memoized 16-step eased gradient decoration to achieve 120 FPS without per-frame rebuild overhead
  static final Decoration _tier1Decoration = BoxDecoration(
    gradient: EasedGradient.build(
      topColor: _topGradientColor,
      bottomColor: const Color(0xFF121212),
    ),
  );

  PlayerQueueBloc? get _effectiveBloc =>
      widget.queueBloc ??
      (getIt.isRegistered<PlayerQueueBloc>() ? getIt<PlayerQueueBloc>() : null);

  LoggingParams? _logPlayerInteraction(String elementPath, [String actionName = 'hit']) {
    try {
      if (getIt.isRegistered<UbiLogger>()) {
        final ubiLogger = getIt<UbiLogger>();
        final result = ubiLogger.logInteraction(
          UbiInteractionElement(
            elementPath: elementPath,
            actionName: actionName,
          ),
        );
        if (getIt.isRegistered<PlayerLoggingParamsFactory>()) {
          final factory = getIt<PlayerLoggingParamsFactory>();
          return factory.createFromInteractionResult(result);
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  void initState() {
    super.initState();
    final holder = getIt<PageInstanceIdHolder>();
    _pageInstanceId = PageInstanceIdHolder.generateNew();
    holder.update(_pageInstanceId);

    try {
      if (getIt.isRegistered<UbiLogger>()) {
        final ubiLogger = getIt<UbiLogger>();
        ubiLogger.logImpression(
          const UbiImpressionElement(
            elementPath: 'now_playing_screen',
          ),
        );
      }
    } catch (_) {}
    _positionNotifier = ValueNotifier<Duration>(Duration.zero);

    _scrollBloc = getIt<NowPlayingScrollBloc>();
    _dataPool = getIt.isRegistered<DataPool>() ? getIt<DataPool>() : null;
    _cardRegistry = ScrollCardRegistry(dataPool: _dataPool);

    final bloc = _effectiveBloc;
    if (bloc != null) {
      _isPlaying = bloc.state.isPlaying;
      _positionNotifier.value = bloc.state.currentPosition;
    }
    _updatePositionTicker(_isPlaying);

    final initialTrack = _effectiveBloc?.state.currentTrack ?? widget.currentTrack;
    _currentTrackId = _extractTrackId(initialTrack, _effectiveBloc?.state.songId ?? widget.songId);
    if (_currentTrackId.isNotEmpty) {
      _scrollBloc.add(FetchNowPlayingScroll(_currentTrackId));
    }
  }

  @override
  void dispose() {
    _scrollBloc.close();
    _positionTimer?.cancel();
    _positionTimer = null;
    _positionNotifier.dispose();
    _dragNotifier.dispose();
    super.dispose();
  }

  /// URI prefixes that must never trigger ScrollSita or lyrics fetches.
  /// Matches Spotify's wi21.java blocklist + ock1.m68144T episode filter.
  static const _nonMusicUriPrefixes = [
    'spotify:ad:',
    'spotify:interruption:',
    'spotify:delimiter',
    'spotify:local:',
    'spotify:meta:',
    'spotify:episode:',
    'spotify:podcast-chapter:',
    'spotify:clip:',
  ];

  String _extractTrackId(ContextTrack? track, int? songId) {
    if (track != null && track.uri.isNotEmpty) {
      // Block non-music URIs from triggering scroll/lyrics network calls
      for (final prefix in _nonMusicUriPrefixes) {
        if (track.uri.startsWith(prefix)) return '';
      }
      if (track.uri.startsWith('spotify:track:')) {
        return track.uri.substring('spotify:track:'.length);
      }
      return track.uri;
    }
    if (songId != null && songId > 0) {
      return songId.toString();
    }
    return '';
  }

  int _resolveActiveLyricsLine(
    ColorLyricsResponse? colorLyrics,
    Duration currentPos,
  ) {
    if (colorLyrics == null ||
        !colorLyrics.hasLyrics() ||
        colorLyrics.lyrics.lines.isEmpty) {
      return 0;
    }
    final posMs = currentPos.inMilliseconds;
    final lines = colorLyrics.lyrics.lines;
    int activeIndex = 0;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startTimeMs.toInt() <= posMs) {
        activeIndex = i;
      } else {
        break;
      }
    }
    return activeIndex;
  }

  void _updatePositionTicker(bool isPlaying) {
    if (isPlaying) {
      if (_positionTimer == null || !_positionTimer!.isActive) {
        _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
          if (_dragNotifier.value == null && mounted) {
            final bloc = _effectiveBloc;
            if (bloc != null) {
              _positionNotifier.value = bloc.state.currentPosition;
            }
          }
        });
      }
    } else {
      _positionTimer?.cancel();
      _positionTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _effectiveBloc;
    if (bloc != null) {
      return BlocConsumer<PlayerQueueBloc, PlayerQueueState>(
        bloc: bloc,
        listenWhen: (previous, current) {
          return previous.isPlaying != current.isPlaying ||
              previous.currentTrack != current.currentTrack ||
              previous.songId != current.songId;
        },
        listener: (context, state) {
          _updatePositionTicker(state.isPlaying);
          if (_dragNotifier.value == null) {
            _positionNotifier.value = state.currentPosition;
          }
          final newTrack = state.currentTrack;
          final newTrackId = _extractTrackId(newTrack, state.songId);
          if (newTrackId.isNotEmpty && newTrackId != _currentTrackId) {
            _currentTrackId = newTrackId;
            _scrollBloc.add(FetchNowPlayingScroll(newTrackId));
          }
        },
        buildWhen: (previous, current) {
          return previous.nowPlaying != current.nowPlaying ||
              previous.songId != current.songId ||
              previous.imageUrl != current.imageUrl ||
              previous.isPlaying != current.isPlaying ||
              previous.isBuffering != current.isBuffering ||
              previous.isShuffling != current.isShuffling ||
              previous.repeatMode != current.repeatMode ||
              previous.durationMs != current.durationMs;
        },
        builder: (context, queueState) {
          return _buildContent(context, queueState: queueState);
        },
      );
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context, {PlayerQueueState? queueState}) {
    final activeTrack = queueState?.currentTrack ?? widget.currentTrack;
    final track = activeTrack;
    final displayTitle = (track != null && track.title.isNotEmpty)
        ? track.title
        : (queueState != null && queueState.title.isNotEmpty ? queueState.title : widget.title);
    final displayArtist = (track != null && track.artist.isNotEmpty)
        ? track.artist
        : (queueState != null && queueState.artist.isNotEmpty ? queueState.artist : widget.artist);
    final displayAlbum = (track != null && track.album.isNotEmpty)
        ? track.album
        : (queueState != null && queueState.album.isNotEmpty ? queueState.album : widget.album);
    final displayDuration = (queueState != null && queueState.durationMs > 0)
        ? queueState.currentDuration
        : (track?.duration ?? widget.duration);
    final displayImageUrl = (track != null || queueState != null)
        ? (track?.imageUrl ?? queueState?.imageUrl)
        : widget.imageUrl;
    final displaySongId = (track != null || queueState != null)
        ? (track?.songId ?? queueState?.songId)
        : widget.songId;

    final isPlaying = queueState?.isPlaying ?? _isPlaying;
    final shuffleMode = queueState != null
        ? (queueState.isShuffling ? QueueShuffleMode.all : QueueShuffleMode.none)
        : _shuffleMode;
    final repeatMode = queueState != null
        ? (queueState.repeatTrack
            ? QueueRepeatMode.one
            : (queueState.repeatContext ? QueueRepeatMode.all : QueueRepeatMode.none))
        : _repeatMode;

    return BlocBuilder<NowPlayingScrollBloc, NowPlayingScrollState>(
      bloc: _scrollBloc,
      builder: (context, scrollState) {
        final activeTrackUri = (track != null && track.uri.isNotEmpty)
            ? track.uri
            : (_currentTrackId.isNotEmpty
                ? 'spotify:track:$_currentTrackId'
                : 'spotify:track:default');
        final activeArtistUri = track?.metadata[ContextTrackMetadata.keyArtistUri] ?? '';

        ColorLyricsResponse? colorLyrics;
        List<ScrollCardDescriptor> cards = const [];

        if (scrollState is NowPlayingScrollLoaded) {
          cards = scrollState.cards;
          colorLyrics = scrollState.lyrics;
        } else if (scrollState is NowPlayingScrollFailure) {
          cards = scrollState.fallbackCards;
        }

        if (cards.isEmpty) {
          cards = [
            LyricsCardDescriptor(entityUri: activeTrackUri),
            CreatorBioCardDescriptor(
              creatorUri: activeArtistUri,
              title: 'About the artist',
            ),
            CreditsCardDescriptor(
              entityUri: activeTrackUri,
              contributorUris: const [],
            ),
          ];
        }

        final activeLineIdx = _resolveActiveLyricsLine(
          colorLyrics,
          _positionNotifier.value,
        );

        _cardRegistry.registerDefaultCards(
          defaultArtistName: displayArtist,
          colorLyrics: colorLyrics,
          activeLineIndex: activeLineIdx,
          onTapLyrics: _onExpandLyrics,
          onShowAllCredits: () => _showCreditsDetailSheet(
            context,
            title: displayTitle,
            artist: displayArtist,
            album: displayAlbum,
            duration: displayDuration,
          ),
          onShowAllEvents: () {},
        );

        // 1:1 Spotify card promotion:
        // If track has valid lyrics, Lyrics is peeking card.
        // If no lyrics, CreatorBio promotes to peeking card.
        ScrollCardDescriptor peekingDesc;
        List<ScrollCardDescriptor> expandedDescs;

        final hasValidLyrics = colorLyrics != null &&
            colorLyrics.hasLyrics() &&
            colorLyrics.lyrics.lines.isNotEmpty;

        final lyricsDesc = cards.whereType<LyricsCardDescriptor>().firstOrNull;
        final creatorBioDesc = cards.whereType<CreatorBioCardDescriptor>().firstOrNull;

        if (hasValidLyrics && lyricsDesc != null) {
          peekingDesc = lyricsDesc;
          expandedDescs = cards.where((d) => d != lyricsDesc).toList();
        } else if (creatorBioDesc != null) {
          peekingDesc = creatorBioDesc;
          expandedDescs = cards.where((d) => d != creatorBioDesc).toList();
        } else {
          peekingDesc = cards.first;
          expandedDescs = cards.skip(1).toList();
        }

        final peekingWidget = _cardRegistry.buildCard(context, peekingDesc) ??
            PlayerAboutArtistSection(
              key: const ValueKey('bio_default'),
              artistName: displayArtist,
              dataPool: _dataPool,
              artistUri: activeArtistUri,
            );

        final expandedWidgets = expandedDescs
            .map((d) => _cardRegistry.buildCard(context, d))
            .whereType<Widget>()
            .toList();

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: PullToDismissScaffold(
            barrierBaseAlpha: 0.70,
            builder: (context, dismissController) {
              return PeekScrollView(
                key: _peekScrollKey,
                dismissController: dismissController,
                peekHeight: 64.0,
                tier1Decoration: _tier1Decoration,
                header: PlayerHeader(
                  onClose: dismissController.dismiss,
                  onMore: () => _showMoreOptions(
                    context,
                    title: displayTitle,
                    artist: displayArtist,
                    album: displayAlbum,
                    duration: displayDuration,
                    activeTrack: track,
                    isPlayingVal: isPlaying,
                    shuffleVal: shuffleMode,
                    repeatVal: repeatMode,
                  ),
                  contextTitle: 'PLAYING FROM ALBUM',
                  contextSubtitle: displayAlbum,
                ),
                mainContent: Column(
                  children: [
                    const Spacer(flex: 1),
                    Flexible(
                      flex: 16,
                      child: RepaintBoundary(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 380,
                            maxHeight: 380,
                          ),
                          child: PlayerAlbumArtwork(
                            key: ValueKey('artwork_${track?.uid ?? track?.uri ?? displaySongId ?? displayImageUrl}'),
                            imageUrl: displayImageUrl,
                            songId: displaySongId,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),
                    RepaintBoundary(
                      child: PlayerMetadata(
                        title: displayTitle,
                        artist: displayArtist,
                        isFavorite: _isFavorite,
                        onFavoriteChanged: _toggleFavorite,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RepaintBoundary(
                      child: ValueListenableBuilder<Duration?>(
                        valueListenable: _dragNotifier,
                        builder: (context, dragPos, _) {
                          return ValueListenableBuilder<Duration>(
                            valueListenable: _positionNotifier,
                            builder: (context, pos, _) {
                              return PlayerSeekBar(
                                duration: displayDuration,
                                position: dragPos ?? pos,
                                dragPosition: dragPos,
                                onDragPositionChanged: (newDragPos) {
                                  _dragNotifier.value = newDragPos;
                                  if (newDragPos != null) {
                                    _positionNotifier.value = newDragPos;
                                  }
                                },
                                onSeek: _handleSeek,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    RepaintBoundary(
                      child: PlayerPlaybackControls(
                        isPlaying: isPlaying,
                        isBuffering: queueState?.isBuffering ?? false,
                        shuffleMode: shuffleMode,
                        repeatMode: repeatMode,
                        onPlayPause: _handlePlayPause,
                        onShuffle: _handleShuffle,
                        onRepeat: _handleRepeat,
                        onNext: _handleNext,
                        onPrevious: _handlePrevious,
                      ),
                    ),
                    const SizedBox(height: 6),
                    PlayerUtilityRow(
                      onQueue: () => _showQueue(
                        context,
                        activeTrack: track,
                        isPlayingVal: isPlaying,
                        shuffleVal: shuffleMode,
                        repeatVal: repeatMode,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
                peekingCard: peekingWidget,
                expandedCards: expandedWidgets,
              );
            },
          ),
        );
      },
    );
  }

  void _handleSeek(Duration pos) {
    _dragNotifier.value = null;
    final lp = _logPlayerInteraction('seek_bar', 'drag');
    final bloc = _effectiveBloc;
    if (bloc != null) {
      bloc.add(SeekToTrackPosition(pos.inMilliseconds, loggingParams: lp));
    } else {
      _positionNotifier.value = pos;
    }
  }

  void _handlePlayPause() {
    final lp = _logPlayerInteraction('play_pause_button');
    final bloc = _effectiveBloc;
    if (bloc != null) {
      bloc.add(TogglePlayPause(loggingParams: lp));
    } else {
      setState(() {
        _isPlaying = !_isPlaying;
        _updatePositionTicker(_isPlaying);
      });
    }
  }

  void _handleShuffle() {
    final lp = _logPlayerInteraction('shuffle_button');
    final bloc = _effectiveBloc;
    if (bloc != null) {
      bloc.add(ToggleShuffle(loggingParams: lp));
    } else {
      setState(() {
        _shuffleMode = _shuffleMode == QueueShuffleMode.all
            ? QueueShuffleMode.none
            : QueueShuffleMode.all;
      });
    }
  }

  void _handleRepeat() {
    final lp = _logPlayerInteraction('repeat_button');
    final bloc = _effectiveBloc;
    if (bloc != null) {
      bloc.add(ToggleRepeat(loggingParams: lp));
    } else {
      setState(() {
        if (_repeatMode == QueueRepeatMode.none) {
          _repeatMode = QueueRepeatMode.all;
        } else if (_repeatMode == QueueRepeatMode.all) {
          _repeatMode = QueueRepeatMode.one;
        } else {
          _repeatMode = QueueRepeatMode.none;
        }
      });
    }
  }

  void _handleNext() {
    final lp = _logPlayerInteraction('skip_next_button');
    _effectiveBloc?.add(SkipToNextTrack(loggingParams: lp));
  }

  void _handlePrevious() {
    final lp = _logPlayerInteraction('skip_previous_button');
    _effectiveBloc?.add(SkipToPrevTrack(loggingParams: lp));
  }

  void _onExpandLyrics() {
    _peekScrollKey.currentState?.scrollToExpanded();
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _showQueue(
    BuildContext context, {
    ContextTrack? activeTrack,
    bool? isPlayingVal,
    QueueShuffleMode? shuffleVal,
    QueueRepeatMode? repeatVal,
  }) {
    _logPlayerInteraction('queue_button', 'hit');
    QueueSheetScreen.show(
      context,
      bloc: _effectiveBloc,
      nowPlayingContextTrack: activeTrack ?? widget.currentTrack,
      isPlaying: isPlayingVal ?? _isPlaying,
      shuffleMode: shuffleVal ?? _shuffleMode,
      repeatMode: repeatVal ?? _repeatMode,
      onPlayPause: _handlePlayPause,
      onShuffleTapped: _handleShuffle,
      onRepeatTapped: _handleRepeat,
    );
  }

  void _showCreditsDetailSheet(
    BuildContext context, {
    required String title,
    required String artist,
    required String album,
    required Duration duration,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PlayerColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (detailsContext) {
        return PlayerTrackDetailsSheet(
          title: title,
          artist: artist,
          album: album,
          duration: duration,
        );
      },
    );
  }

  void _showMoreOptions(
    BuildContext context, {
    required String title,
    required String artist,
    required String album,
    required Duration duration,
    ContextTrack? activeTrack,
    bool isPlayingVal = false,
    QueueShuffleMode shuffleVal = QueueShuffleMode.none,
    QueueRepeatMode repeatVal = QueueRepeatMode.none,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PlayerColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return PlayerOptionsSheet(
          onShowDetails: () => _showCreditsDetailSheet(
            context,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
          ),
          onShowQueue: () {
            _showQueue(
              context,
              activeTrack: activeTrack,
              isPlayingVal: isPlayingVal,
              shuffleVal: shuffleVal,
              repeatVal: repeatVal,
            );
          },
        );
      },
    );
  }
}
