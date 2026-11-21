import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/color/eased_gradient.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/core/ubi/data/lifecycle/page_instance_id_holder.dart';
import 'package:musify_mu/core/ubi/domain/logging/ubi_logger.dart';
import 'package:musify_mu/core/ubi/domain/models/page_instance_id.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/track_v4/track_v4.dart';
import 'package:musify_mu/features/player/domain/policies/spotify_track_eligibility_policy.dart';
import 'package:musify_mu/features/player/domain/repositories/lyrics_repository.dart';
import 'package:musify_mu/features/player/domain/repositories/scrollsita_repository.dart';

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
  final NowPlayingScrollController? scrollController;
  final ScrollSitaRepository? scrollSitaRepository;
  final LyricsRepository? lyricsRepository;
  final DataPool? dataPool;
  final ConnectOutputStatusPolicy? outputStatusPolicy;
  final UbiLogger? ubiLogger;
  final PlayerLoggingParamsFactory? loggingParamsFactory;
  final PageInstanceIdHolder? pageInstanceIdHolder;

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
    this.scrollController,
    this.scrollSitaRepository,
    this.lyricsRepository,
    this.dataPool,
    this.outputStatusPolicy,
    this.ubiLogger,
    this.loggingParamsFactory,
    this.pageInstanceIdHolder,
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
    NowPlayingScrollController? scrollController,
    ScrollSitaRepository? scrollSitaRepository,
    LyricsRepository? lyricsRepository,
    DataPool? dataPool,
    ConnectOutputStatusPolicy? outputStatusPolicy,
    UbiLogger? ubiLogger,
    PlayerLoggingParamsFactory? loggingParamsFactory,
    PageInstanceIdHolder? pageInstanceIdHolder,
  }) async {
    if (_isOpen) return;
    _isOpen = true;

    final effectiveBloc = switch (queueBloc) {
      final b? => b,
      null => context.read<PlayerQueueBloc?>(),
    };
    final effectiveConnectController = switch (connectController) {
      final c? => c,
      null => context.read<ConnectMobiusController?>(),
    };
    final effectiveScrollController = switch (scrollController) {
      final s? => s,
      null => context.read<NowPlayingScrollController?>(),
    };
    final effectiveScrollSitaRepository = switch (scrollSitaRepository) {
      final r? => r,
      null => context.read<ScrollSitaRepository?>(),
    };
    final effectiveLyricsRepository = switch (lyricsRepository) {
      final r? => r,
      null => context.read<LyricsRepository?>(),
    };
    final effectiveDataPool = switch (dataPool) {
      final d? => d,
      null => context.read<DataPool?>(),
    };
    final effectivePolicy = switch (outputStatusPolicy) {
      final p? => p,
      null => context.read<ConnectOutputStatusPolicy?>(),
    };
    final effectiveUbiLogger = switch (ubiLogger) {
      final l? => l,
      null => context.read<UbiLogger?>(),
    };
    final effectiveLoggingFactory = switch (loggingParamsFactory) {
      final f? => f,
      null => context.read<PlayerLoggingParamsFactory?>(),
    };
    final effectivePageHolder = switch (pageInstanceIdHolder) {
      final h? => h,
      null => context.read<PageInstanceIdHolder?>(),
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
              connectController: effectiveConnectController,
              scrollController: effectiveScrollController,
              scrollSitaRepository: effectiveScrollSitaRepository,
              lyricsRepository: effectiveLyricsRepository,
              dataPool: effectiveDataPool,
              outputStatusPolicy: effectivePolicy,
              ubiLogger: effectiveUbiLogger,
              loggingParamsFactory: effectiveLoggingFactory,
              pageInstanceIdHolder: effectivePageHolder,
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
  final ValueNotifier<Duration> _positionNotifier =
      ValueNotifier<Duration>(Duration.zero);
  Ticker? _positionTicker;
  Duration _lastTick = Duration.zero;

  PlayerQueueMobiusController? _boundQueueBloc;
  NowPlayingScrollController? _scrollBloc;
  NowPlayingScrollController? _ownedScrollBloc;
  ScrollCardRegistry _cardRegistry = ScrollCardRegistry();
  DataPool? _dataPool;
  String _currentTrackId = '';
  String _currentArtistUri = '';
  int _lastRegisteredActiveLineIndex = 0;

  NowPlayingTransportPhase _transportPhase = NowPlayingTransportPhase.paused;
  bool _isFavorite = false;
  QueueShuffleMode _shuffleMode = QueueShuffleMode.none;
  QueueRepeatMode _repeatMode = QueueRepeatMode.none;

  PageInstanceId _pageInstanceId = PageInstanceIdHolder.generateNew();

  PageInstanceId get pageInstanceId => _pageInstanceId;

  static const Color _topGradientColor = Color(0xFF1E3264);

  static final Decoration _tier1Decoration = BoxDecoration(
    gradient: EasedGradient.build(
      topColor: _topGradientColor,
      bottomColor: const Color(0xFF121212),
    ),
  );

  PlayerQueueMobiusController? _resolveQueueBloc() {
    if (widget.queueBloc case final explicit?) {
      return explicit;
    }
    return context.read<PlayerQueueBloc?>();
  }

  ConnectMobiusController? _resolveConnectController() {
    if (widget.connectController case final explicit?) {
      return explicit;
    }
    return context.read<ConnectMobiusController?>();
  }

  ConnectOutputStatusPolicy _resolveOutputStatusPolicy() {
    if (widget.outputStatusPolicy case final explicit?) {
      return explicit;
    }
    if (context.read<ConnectOutputStatusPolicy?>() case final provided?) {
      return provided;
    }
    return ConnectOutputStatusPolicy.instance;
  }

  UbiLogger? _resolveUbiLogger() {
    if (widget.ubiLogger case final explicit?) {
      return explicit;
    }
    return context.read<UbiLogger?>();
  }

  PlayerLoggingParamsFactory? _resolveLoggingParamsFactory() {
    if (widget.loggingParamsFactory case final explicit?) {
      return explicit;
    }
    return context.read<PlayerLoggingParamsFactory?>();
  }

  PageInstanceIdHolder? _resolvePageInstanceIdHolder() {
    if (widget.pageInstanceIdHolder case final explicit?) {
      return explicit;
    }
    return context.read<PageInstanceIdHolder?>();
  }

  DataPool? _resolveDataPool() {
    if (widget.dataPool case final explicit?) {
      return explicit;
    }
    return context.read<DataPool?>();
  }

  ScrollSitaRepository? _resolveScrollSitaRepository() {
    if (widget.scrollSitaRepository case final explicit?) {
      return explicit;
    }
    return context.read<ScrollSitaRepository?>();
  }

  LyricsRepository? _resolveLyricsRepository() {
    if (widget.lyricsRepository case final explicit?) {
      return explicit;
    }
    return context.read<LyricsRepository?>();
  }

  NowPlayingScrollController _resolveOrAllocateScrollController() {
    if (widget.scrollController case final explicit?) {
      return explicit;
    }
    if (context.read<NowPlayingScrollController?>() case final provided?) {
      return provided;
    }
    if (_ownedScrollBloc case final existingOwned?) {
      return existingOwned;
    }
    final created = NowPlayingScrollController(
      scrollSitaRepository: _resolveScrollSitaRepository(),
      lyricsRepository: _resolveLyricsRepository(),
    );
    _ownedScrollBloc = created;
    return created;
  }

  NowPlayingScrollController get _requireScrollBloc {
    if (_scrollBloc case final active?) {
      return active;
    }
    throw StateError('PlayerScreen NowPlayingScrollController is not bound');
  }

  LoggingParams? _logPlayerInteraction(
    String elementPath, [
    String actionName = 'hit',
  ]) {
    if (_resolveUbiLogger() case final ubiLogger?) {
      final result = ubiLogger.logInteraction(
        UbiInteractionElement(
          elementPath: elementPath,
          actionName: actionName,
        ),
      );
      if (_resolveLoggingParamsFactory() case final factory?) {
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

  /// Resolves the canonical Spotify artist URI for an eligible Spotify song,
  /// checking track metadata first and falling back to cached [TrackV4] in
  /// [_dataPool]. Always returns `''` for local and Private Vault tracks.
  String _resolveEffectiveArtistUri(NowPlayingViewModel vm) {
    if (!vm.isSpotifySong) {
      return '';
    }
    if (vm.artistUri.isNotEmpty) {
      return vm.artistUri;
    }
    final pool = _dataPool;
    if (pool == null || vm.trackId.isEmpty) {
      return '';
    }
    final canonicalTrackUri = 'spotify:track:${vm.trackId}';
    final trackV4 = pool.getTrait<TrackV4>(canonicalTrackUri);
    if (trackV4 != null && trackV4.artists.isNotEmpty) {
      if (SpotifyTrackEligibilityPolicy.resolveCanonicalSpotifyArtistUri(
            trackV4.artists.first.uri,
          )
          case final resolved?) {
        return resolved;
      }
    }
    return '';
  }

  void _dispatchScrollIntentForViewModel(
    NowPlayingViewModel vm, {
    required NowPlayingScrollController scrollCtrl,
    bool forceRetry = false,
  }) {
    if (!vm.isSpotifySong || vm.trackId.isEmpty) {
      _currentTrackId = '';
      _currentArtistUri = '';
      scrollCtrl.add(const ClearNowPlayingScroll());
      return;
    }

    final resolvedArtistUri = _resolveEffectiveArtistUri(vm);
    final trackChanged = vm.trackId != _currentTrackId;
    final artistEnriched =
        resolvedArtistUri.isNotEmpty && resolvedArtistUri != _currentArtistUri;

    if (trackChanged || artistEnriched || forceRetry) {
      _currentTrackId = vm.trackId;
      _currentArtistUri = resolvedArtistUri;
      scrollCtrl.add(
        FetchNowPlayingScroll(_currentTrackId, _currentArtistUri),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _pageInstanceId = PageInstanceIdHolder.generateNew();
    if (_resolvePageInstanceIdHolder() case final holder?) {
      holder.update(_pageInstanceId);
    }

    if (_resolveUbiLogger() case final ubiLogger?) {
      ubiLogger.logImpression(
        const UbiImpressionElement(
          elementPath: 'now_playing_screen',
        ),
      );
    }

    final effectiveQueueBloc = _resolveQueueBloc();
    _boundQueueBloc = effectiveQueueBloc;

    final initialVm = _computeViewModel(effectiveQueueBloc?.state);
    _positionNotifier.value = initialVm.position;
    _transportPhase = initialVm.transportPhase;

    _dataPool = _resolveDataPool();
    _cardRegistry = ScrollCardRegistry(dataPool: _dataPool);

    final scrollCtrl = _resolveOrAllocateScrollController();
    _scrollBloc = scrollCtrl;
    scrollCtrl.addListener(_onScrollStateChanged);
    _positionNotifier.addListener(_onPositionChanged);

    _syncCardRegistry();

    final ticker = createTicker((elapsed) {
      if (elapsed - _lastTick > const Duration(milliseconds: 250)) {
        _lastTick = elapsed;
        if (_dragNotifier.value == null && mounted) {
          if (_boundQueueBloc case final activeBloc?) {
            _positionNotifier.value = activeBloc.state.currentPosition;
          }
        }
      }
    });
    _positionTicker = ticker;
    _syncTickerForTransportPhase(_transportPhase);

    _dispatchScrollIntentForViewModel(
      initialVm,
      scrollCtrl: scrollCtrl,
      forceRetry: initialVm.isSpotifySong && initialVm.trackId.isNotEmpty,
    );

    effectiveQueueBloc?.addListener(_onQueueStateChanged);
  }

  @override
  void didUpdateWidget(covariant PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextQueueBloc = _resolveQueueBloc();
    if (!identical(_boundQueueBloc, nextQueueBloc)) {
      _boundQueueBloc?.removeListener(_onQueueStateChanged);
      _boundQueueBloc = nextQueueBloc;
      nextQueueBloc?.addListener(_onQueueStateChanged);
    }

    final nextDataPool = _resolveDataPool();
    if (!identical(_dataPool, nextDataPool)) {
      _dataPool = nextDataPool;
      _cardRegistry = ScrollCardRegistry(dataPool: _dataPool);
    }

    final repositoriesChangedForOwned =
        widget.scrollController == null &&
        (widget.scrollSitaRepository != oldWidget.scrollSitaRepository ||
            widget.lyricsRepository != oldWidget.lyricsRepository);

    if (widget.scrollController != oldWidget.scrollController ||
        repositoriesChangedForOwned) {
      _scrollBloc?.removeListener(_onScrollStateChanged);
      if (widget.scrollController != null || repositoriesChangedForOwned) {
        if (_ownedScrollBloc case final owned?) {
          unawaited(owned.close());
          _ownedScrollBloc = null;
        }
      }
      final nextScroll = _resolveOrAllocateScrollController();
      _scrollBloc = nextScroll;
      nextScroll.addListener(_onScrollStateChanged);
      final vm = _computeViewModel(_boundQueueBloc?.state);
      _dispatchScrollIntentForViewModel(
        vm,
        scrollCtrl: nextScroll,
        forceRetry: vm.isSpotifySong && vm.trackId.isNotEmpty,
      );
    } else if (widget.currentTrack != oldWidget.currentTrack) {
      final vm = _computeViewModel(_boundQueueBloc?.state);
      _dispatchScrollIntentForViewModel(vm, scrollCtrl: _requireScrollBloc);
    }

    _syncCardRegistry();
  }

  @override
  void dispose() {
    _boundQueueBloc?.removeListener(_onQueueStateChanged);
    _boundQueueBloc = null;
    _scrollBloc?.removeListener(_onScrollStateChanged);
    _scrollBloc = null;
    if (_ownedScrollBloc case final owned?) {
      _ownedScrollBloc = null;
      unawaited(owned.close());
    }
    _positionNotifier.removeListener(_onPositionChanged);
    _positionTicker?.dispose();
    _positionTicker = null;
    _positionNotifier.dispose();
    _dragNotifier.dispose();
    super.dispose();
  }

  ColorLyricsResponse? _currentColorLyrics() {
    final scrollState = _scrollBloc?.state;
    if (scrollState is NowPlayingScrollLoaded) {
      return scrollState.lyrics;
    }
    return null;
  }

  void _syncCardRegistry() {
    final vm = _computeViewModel(_boundQueueBloc?.state);
    final colorLyrics = vm.isSpotifySong ? _currentColorLyrics() : null;
    final activeLineIdx = _resolveActiveLyricsLine(
      colorLyrics,
      _positionNotifier.value,
    );
    _lastRegisteredActiveLineIndex = activeLineIdx;

    _cardRegistry.registerDefaultCards(
      defaultArtistName: vm.artist,
      colorLyrics: colorLyrics,
      activeLineIndex: activeLineIdx,
      enableSpotifyDataPool: vm.isSpotifySong,
      onTapLyrics: _onExpandLyrics,
      onShowAllCredits: _onShowAllCreditsFromCard,
      onShowAllEvents: _noopCallback,
    );
  }

  static void _noopCallback() {}

  void _onShowAllCreditsFromCard() {
    if (!mounted) {
      return;
    }
    final vm = _computeViewModel(_boundQueueBloc?.state);
    _showCreditsDetailSheet(
      context,
      title: vm.title,
      artist: vm.artist,
      album: vm.album,
      duration: vm.duration,
    );
  }

  void _onScrollStateChanged() {
    _syncCardRegistry();
  }

  void _onPositionChanged() {
    final colorLyrics = _currentColorLyrics();
    if (colorLyrics == null ||
        !colorLyrics.hasLyrics() ||
        colorLyrics.lyrics.lines.isEmpty) {
      return;
    }
    final nextLineIndex = _resolveActiveLyricsLine(
      colorLyrics,
      _positionNotifier.value,
    );
    if (nextLineIndex != _lastRegisteredActiveLineIndex) {
      _syncCardRegistry();
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onQueueStateChanged() {
    if (_boundQueueBloc case final bloc?) {
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
      if (_scrollBloc case final scrollCtrl?) {
        final bufferingJustFinished =
            previousPhase ==
                NowPlayingTransportPhase.bufferingUnplayedSegment &&
            vm.transportPhase == NowPlayingTransportPhase.playing &&
            scrollCtrl.state is! NowPlayingScrollLoaded;
        _dispatchScrollIntentForViewModel(
          vm,
          scrollCtrl: scrollCtrl,
          forceRetry: bufferingJustFinished,
        );
      }
      _syncCardRegistry();
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
    final ticker = _positionTicker;
    if (ticker == null) {
      return;
    }
    switch (phase) {
      case NowPlayingTransportPhase.playing:
        if (!ticker.isActive) {
          ticker.start();
        }
      case NowPlayingTransportPhase.paused:
      case NowPlayingTransportPhase.bufferingUnplayedSegment:
        if (ticker.isActive) {
          ticker.stop();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _boundQueueBloc;
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

    final effectiveConnectController = _resolveConnectController();
    final policy = _resolveOutputStatusPolicy();

    return ValueListenableBuilder<NowPlayingScrollState>(
      valueListenable: _requireScrollBloc,
      builder: (context, scrollState, _) {
        final isSpotifySong = vm.isSpotifySong;
        final activeTrackUri = isSpotifySong
            ? (vm.trackUri.isNotEmpty
                  ? vm.trackUri
                  : (_currentTrackId.isNotEmpty
                        ? 'spotify:track:$_currentTrackId'
                        : ''))
            : '';
        final activeArtistUri = _resolveEffectiveArtistUri(vm);

        ColorLyricsResponse? colorLyrics;
        List<ScrollCardDescriptor> cards = const [];

        if (isSpotifySong) {
          if (scrollState is NowPlayingScrollLoaded) {
            cards = scrollState.cards
                .map((desc) {
                  if (desc is CreatorBioCardDescriptor &&
                      desc.creatorUri.isEmpty &&
                      activeArtistUri.isNotEmpty) {
                    return CreatorBioCardDescriptor(
                      creatorUri: activeArtistUri,
                      title: desc.title,
                    );
                  }
                  return desc;
                })
                .toList(growable: false);
            colorLyrics = scrollState.lyrics;
          } else if (scrollState is NowPlayingScrollFailure) {
            cards = scrollState.fallbackCards;
          }
        }

        if (cards.isEmpty) {
          cards = <ScrollCardDescriptor>[
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

        final visibleCards = cards
            .where((d) => d is! MerchCardDescriptor)
            .toList(growable: false);
        final effectiveCards = visibleCards.isNotEmpty ? visibleCards : cards;

        final ScrollCardDescriptor peekingDesc;
        final List<ScrollCardDescriptor> expandedDescs;

        final hasValidLyrics = isSpotifySong &&
            colorLyrics != null &&
            colorLyrics.hasLyrics() &&
            colorLyrics.lyrics.lines.isNotEmpty;

        final lyricsDesc =
            effectiveCards.whereType<LyricsCardDescriptor>().firstOrNull;
        final creatorBioDesc =
            effectiveCards.whereType<CreatorBioCardDescriptor>().firstOrNull;

        if (hasValidLyrics && lyricsDesc != null) {
          peekingDesc = lyricsDesc;
          expandedDescs = effectiveCards
              .where((d) => !identical(d, lyricsDesc))
              .toList(growable: false);
        } else if (creatorBioDesc != null) {
          peekingDesc = creatorBioDesc;
          expandedDescs = effectiveCards
              .where((d) => !identical(d, creatorBioDesc))
              .toList(growable: false);
        } else {
          peekingDesc = effectiveCards.first;
          expandedDescs = effectiveCards.skip(1).toList(growable: false);
        }

        final resolvedPeeking = _cardRegistry.buildCard(context, peekingDesc);
        final peekingWidget = switch (resolvedPeeking) {
          final w? => w,
          null => PlayerAboutArtistSection(
              key: const ValueKey('bio_default'),
              artistName: displayArtist,
              dataPool: isSpotifySong ? _dataPool : null,
              artistUri: activeArtistUri,
            ),
        };

        final expandedWidgets = expandedDescs
            .map((d) => _cardRegistry.buildCard(context, d))
            .whereType<Widget>()
            .toList(growable: false);

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
                      connectController: effectiveConnectController,
                      outputStatusPolicy: policy,
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
    if (_boundQueueBloc case final bloc?) {
      bloc.dispatch(SeekToPositionEvent(pos, loggingParams: lp));
    } else {
      _positionNotifier.value = pos;
    }
  }

  void _handlePlayPause() {
    final lp = _logPlayerInteraction('play_pause_button');
    if (_boundQueueBloc case final bloc?) {
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
    if (_boundQueueBloc case final bloc?) {
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
    if (_boundQueueBloc case final bloc?) {
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
    if (_boundQueueBloc?.state case final qState? when !qState.canSkipNext) {
      return;
    }
    final lp = _logPlayerInteraction('skip_next_button');
    _boundQueueBloc?.dispatch(SkipToNextTrackEvent(loggingParams: lp));
  }

  void _handlePrevious() {
    if (_boundQueueBloc?.state case final qState?
        when !qState.canSkipPrevious) {
      return;
    }
    final lp = _logPlayerInteraction('skip_previous_button');
    _boundQueueBloc?.dispatch(SkipToPrevTrackEvent(loggingParams: lp));
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
      bloc: _boundQueueBloc,
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
