import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/color/eased_gradient.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/core/ubi/data/lifecycle/page_instance_id_holder.dart';
import 'package:musify_mu/core/ubi/domain/logging/ubi_logger.dart';
import 'package:musify_mu/core/ubi/domain/models/page_instance_id.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';
import 'package:musify_mu/features/connect/presentation/screens/device_picker_sheet.dart';
import 'package:musify_mu/features/connect/presentation/widgets/active_device_banner.dart';

import '../../application/queue/player_queue_bloc.dart';
import '../../application/scroll/now_playing_scroll_bloc.dart';
import '../../data/logging/player_logging_params_factory.dart';
import '../../domain/commands/options/logging_params.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/now_playing_view_model.dart';
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

/// Full-screen edge-to-edge Now Playing screen replicating Spotify NowPlaying
/// 1:1 with pure Mobius loop state controller and reactive cards pipeline.
///
/// Citations:
/// - Decompiled Java: `p199p/nhr.java` (lines 501-507: `connect_entry_point_stub`; lines 513-567: `accessory_row`)
/// - Decompiled Java: `p199p/ac0.java` (lines 51-53: `device_picker_button` -> `devicepicker view`)
/// - Decompiled Java: `p199p/es81.java` (lines 1678-1682: `spotify:connect-device-picker`, `spotify:internal:gaia-picker`)
class PlayerScreen extends StatefulWidget {
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String? imageUrl;
  final PlayerQueueMobiusController? queueBloc;
  final ContextTrack? currentTrack;
  final ConnectMobiusController? connectController;

  const PlayerScreen({
    super.key,
    this.title = '',
    this.artist = '',
    this.album = '',
    this.duration = Duration.zero,
    this.imageUrl,
    this.queueBloc,
    this.currentTrack,
    this.connectController,
  });

  static bool _isOpen = false;

  /// Launches the Now Playing view as a full-screen edge-to-edge window with
  /// native Spotify transition curves and single-top route guarding.
  static Future<void> show(
    BuildContext context, {
    String title = '',
    String artist = '',
    String album = '',
    Duration duration = Duration.zero,
    String? imageUrl,
    PlayerQueueMobiusController? queueBloc,
    ContextTrack? currentTrack,
    ConnectMobiusController? connectController,
  }) async {
    if (_isOpen) return;
    _isOpen = true;

    final effectiveBloc = switch (queueBloc) {
      final b? => b,
      null => getIt.isRegistered<PlayerQueueMobiusController>()
          ? getIt<PlayerQueueMobiusController>()
          : null,
    };

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
              queueBloc: effectiveBloc,
              currentTrack: currentTrack,
              connectController: connectController,
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

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<PeekScrollViewState> _peekScrollKey =
      GlobalKey<PeekScrollViewState>();

  final ValueNotifier<Duration?> _dragNotifier = ValueNotifier<Duration?>(null);
  late final ValueNotifier<Duration> _positionNotifier;
  late final Ticker _positionTicker;
  Duration _lastTick = Duration.zero;

  late final NowPlayingScrollController _scrollBloc;
  late final ScrollCardRegistry _cardRegistry;
  DataPool? _dataPool;
  String _currentTrackId = '';

  NowPlayingTransportPhase _transportPhase = NowPlayingTransportPhase.paused;
  bool _isFavorite = false;
  QueueShuffleMode _shuffleMode = QueueShuffleMode.none;
  QueueRepeatMode _repeatMode = QueueRepeatMode.none;

  late final PageInstanceId _pageInstanceId;

  PageInstanceId get pageInstanceId => _pageInstanceId;

  static const Color _topGradientColor = Color(0xFF1E3264);

  static final Decoration _tier1Decoration = BoxDecoration(
    gradient: EasedGradient.build(
      topColor: _topGradientColor,
      bottomColor: const Color(0xFF121212),
    ),
  );

  static bool _shouldShowConnectBanner(ConnectState state) {
    if (state.transferState is TransferInProgress) {
      return true;
    }
    final ConnectDevice? currentActive = state.activeDevice;
    if (currentActive != null && !currentActive.isSelf) {
      return true;
    }
    final LocalAudioPeripheral? peripheral = state.activeSelfPeripheral;
    if (peripheral != null &&
        peripheral.id != kBuiltInSpeakerPeripheralId &&
        peripheral.connectionType !=
            OutputPeripheralConnectionType.builtInSpeaker) {
      return true;
    }
    return false;
  }

  PlayerQueueMobiusController? get _effectiveBloc => switch (widget.queueBloc) {
    final b? => b,
    null => getIt.isRegistered<PlayerQueueMobiusController>()
        ? getIt<PlayerQueueMobiusController>()
        : null,
  };

  LoggingParams? _logPlayerInteraction(
    String elementPath, [
    String actionName = 'hit',
  ]) {
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
    return null;
  }

  NowPlayingViewModel _computeViewModel(PlayerQueueState? queueState) {
    return NowPlayingViewModel.fromPlayerQueueState(
      queueState,
      fallbackTrack: widget.currentTrack,
      fallbackTitle: widget.title,
      fallbackArtist: widget.artist,
      fallbackAlbum: widget.album,
      fallbackDuration: widget.duration,
      fallbackImageUrl: widget.imageUrl,
    );
  }

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<PageInstanceIdHolder>()) {
      final holder = getIt<PageInstanceIdHolder>();
      _pageInstanceId = PageInstanceIdHolder.generateNew();
      holder.update(_pageInstanceId);
    } else {
      _pageInstanceId = PageInstanceIdHolder.generateNew();
    }

    if (getIt.isRegistered<UbiLogger>()) {
      final ubiLogger = getIt<UbiLogger>();
      ubiLogger.logImpression(
        const UbiImpressionElement(
          elementPath: 'now_playing_screen',
        ),
      );
    }

    final initialVm = _computeViewModel(_effectiveBloc?.state);
    _positionNotifier = ValueNotifier<Duration>(initialVm.position);
    _transportPhase = initialVm.transportPhase;

    _scrollBloc = getIt<NowPlayingScrollController>();
    _dataPool = getIt.isRegistered<DataPool>() ? getIt<DataPool>() : null;
    _cardRegistry = ScrollCardRegistry(dataPool: _dataPool);

    _positionTicker = createTicker((elapsed) {
      if (elapsed - _lastTick > const Duration(milliseconds: 250)) {
        _lastTick = elapsed;
        if (_dragNotifier.value == null && mounted) {
          if (_effectiveBloc case final activeBloc?) {
            _positionNotifier.value = activeBloc.state.currentPosition;
          }
        }
      }
    });
    _syncTickerForTransportPhase(_transportPhase);

    _currentTrackId = initialVm.trackId;
    if (_currentTrackId.isNotEmpty) {
      _scrollBloc.add(FetchNowPlayingScroll(_currentTrackId));
    }

    _effectiveBloc?.addListener(_onQueueStateChanged);
  }

  @override
  void dispose() {
    _effectiveBloc?.removeListener(_onQueueStateChanged);
    _scrollBloc.close();
    _positionTicker.dispose();
    _positionNotifier.dispose();
    _dragNotifier.dispose();
    super.dispose();
  }

  void _onQueueStateChanged() {
    if (_effectiveBloc case final bloc?) {
      final vm = _computeViewModel(bloc.state);
      final previousPhase = _transportPhase;
      if (vm.transportPhase != _transportPhase) {
        setState(() {
          _transportPhase = vm.transportPhase;
        });
        _syncTickerForTransportPhase(vm.transportPhase);
      }
      if (_dragNotifier.value == null) {
        _positionNotifier.value = vm.position;
      }
      if (vm.trackId.isNotEmpty && vm.trackId != _currentTrackId) {
        _currentTrackId = vm.trackId;
        _scrollBloc.add(FetchNowPlayingScroll(vm.trackId));
      } else if (_currentTrackId.isNotEmpty &&
          previousPhase == NowPlayingTransportPhase.bufferingUnplayedSegment &&
          vm.transportPhase == NowPlayingTransportPhase.playing &&
          _scrollBloc.state is! NowPlayingScrollLoaded) {
        _scrollBloc.add(FetchNowPlayingScroll(_currentTrackId));
      }
    }
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

  void _syncTickerForTransportPhase(NowPlayingTransportPhase phase) {
    switch (phase) {
      case NowPlayingTransportPhase.playing:
        if (!_positionTicker.isActive) {
          _positionTicker.start();
        }
      case NowPlayingTransportPhase.paused:
      case NowPlayingTransportPhase.bufferingUnplayedSegment:
        if (_positionTicker.isActive) {
          _positionTicker.stop();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _effectiveBloc;
    if (bloc != null) {
      return ValueListenableBuilder<PlayerQueueState>(
        valueListenable: bloc,
        builder: (context, queueState, _) {
          return _buildContent(context, queueState: queueState);
        },
      );
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context, {PlayerQueueState? queueState}) {
    final vm = _computeViewModel(queueState);
    final activeTrack = switch (queueState?.currentTrack) {
      final track? => track,
      null => widget.currentTrack,
    };
    final track = activeTrack;
    final displayTitle = vm.title;
    final displayArtist = vm.artist;
    final displayAlbum = vm.album;
    final displayDuration = vm.duration;
    final displayImageUrl = vm.imageUrl;

    final isPlaying = vm.isPlaying;
    final transportPhase = vm.transportPhase;
    final shuffleMode = vm.shuffleMode;
    final repeatMode = vm.repeatMode;

    return ValueListenableBuilder<NowPlayingScrollState>(
      valueListenable: _scrollBloc,
      builder: (context, scrollState, _) {
        final activeTrackUri = vm.trackUri.isNotEmpty
            ? vm.trackUri
            : (_currentTrackId.isNotEmpty
                ? 'spotify:track:$_currentTrackId'
                : 'spotify:track:default');
        final activeArtistUri = vm.artistUri;

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

        final resolvedPeeking = _cardRegistry.buildCard(context, peekingDesc);
        final peekingWidget = switch (resolvedPeeking) {
          final w? => w,
          null => PlayerAboutArtistSection(
            key: const ValueKey('bio_default'),
            artistName: displayArtist,
            dataPool: _dataPool,
            artistUri: activeArtistUri,
          ),
        };

        final expandedWidgets = expandedDescs
            .map((d) => _cardRegistry.buildCard(context, d))
            .whereType<Widget>()
            .toList();

        final artworkKeyString = switch (track?.uid) {
          final uid? when uid.isNotEmpty => uid,
          _ => switch (track?.uri) {
            final uri? when uri.isNotEmpty => uri,
            _ => switch (displayImageUrl) {
              final url? => url,
              null => 'default',
            },
          },
        };

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
                            key: ValueKey('artwork_$artworkKeyString'),
                            imageUrl: displayImageUrl,
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
                              final currentPos = switch (dragPos) {
                                final d? => d,
                                null => pos,
                              };
                              return PlayerSeekBar(
                                duration: displayDuration,
                                position: currentPos,
                                dragPosition: dragPos,
                                transportPhase: transportPhase,
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
                        transportPhase: transportPhase,
                        canSkipNext: vm.canSkipNext,
                        canSkipPrevious: vm.canSkipPrev,
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
                      connectController: widget.connectController,
                      onQueue: () => _showQueue(
                        context,
                        activeTrack: track,
                        isPlayingVal: isPlaying,
                        shuffleVal: shuffleMode,
                        repeatVal: repeatMode,
                      ),
                    ),
                    if (widget.connectController case final controller?)
                      ValueListenableBuilder<ConnectState>(
                        valueListenable: controller,
                        builder: (context, connectState, _) {
                          if (!_shouldShowConnectBanner(connectState)) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: ActiveDeviceBanner(
                              controller: controller,
                              compact: false,
                              showWhenLocalBuiltIn: false,
                              onTap: () => DevicePickerSheet.show(
                                context,
                                controller: controller,
                              ),
                            ),
                          );
                        },
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
    if (_effectiveBloc case final bloc?) {
      bloc.dispatch(SeekToPositionEvent(pos, loggingParams: lp));
    } else {
      _positionNotifier.value = pos;
    }
  }

  void _handlePlayPause() {
    final lp = _logPlayerInteraction('play_pause_button');
    if (_effectiveBloc case final bloc?) {
      bloc.dispatch(TogglePlayPauseEvent(loggingParams: lp));
    } else {
      setState(() {
        _transportPhase = switch (_transportPhase) {
          NowPlayingTransportPhase.playing ||
          NowPlayingTransportPhase.bufferingUnplayedSegment =>
            NowPlayingTransportPhase.paused,
          NowPlayingTransportPhase.paused => NowPlayingTransportPhase.playing,
        };
        _syncTickerForTransportPhase(_transportPhase);
      });
    }
  }

  void _handleShuffle() {
    final lp = _logPlayerInteraction('shuffle_button');
    if (_effectiveBloc case final bloc?) {
      bloc.dispatch(ToggleShuffleEvent(loggingParams: lp));
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
    if (_effectiveBloc case final bloc?) {
      bloc.dispatch(ToggleRepeatEvent(loggingParams: lp));
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
    if (_effectiveBloc?.state case final qState? when !qState.canSkipNext) {
      return;
    }
    final lp = _logPlayerInteraction('skip_next_button');
    _effectiveBloc?.dispatch(SkipToNextTrackEvent(loggingParams: lp));
  }

  void _handlePrevious() {
    if (_effectiveBloc?.state case final qState? when !qState.canSkipPrevious) {
      return;
    }
    final lp = _logPlayerInteraction('skip_previous_button');
    _effectiveBloc?.dispatch(SkipToPrevTrackEvent(loggingParams: lp));
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
    final resolvedTrack = switch (activeTrack) {
      final t? => t,
      null => widget.currentTrack,
    };
    final resolvedIsPlaying = switch (isPlayingVal) {
      final p? => p,
      null => _transportPhase != NowPlayingTransportPhase.paused,
    };
    final resolvedShuffle = switch (shuffleVal) {
      final s? => s,
      null => _shuffleMode,
    };
    final resolvedRepeat = switch (repeatVal) {
      final r? => r,
      null => _repeatMode,
    };
    QueueSheetScreen.show(
      context,
      bloc: _effectiveBloc,
      nowPlayingContextTrack: resolvedTrack,
      isPlaying: resolvedIsPlaying,
      shuffleMode: resolvedShuffle,
      repeatMode: resolvedRepeat,
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
