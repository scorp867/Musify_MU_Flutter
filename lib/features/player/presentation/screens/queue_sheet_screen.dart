import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';

import '../../application/queue/player_queue_bloc.dart';
import '../../data/esperanto/context_player_options_client.dart';
import '../../data/mock/mock_queue_seeder.dart';
import '../../data/queue/context_track_extensions.dart';
import '../../domain/models/context_track.dart';
import '../widgets/peek_scroll_view.dart';
import '../widgets/player_theme.dart';
import '../widgets/pull_to_dismiss_scaffold.dart';
import '../widgets/queue_controls_layout.dart';
import '../widgets/queue_now_playing_row.dart';
import '../widgets/queue_track_row.dart';
import '../widgets/spotify_scroll_physics.dart';

/// Lightweight mock track model for Queue Sheet preview & testing.
class MockQueueTrack {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final bool isQueued;
  final String? imageUrl;
  final int? songId;
  final String? uri;
  final ContextTrack? contextTrack;

  const MockQueueTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.album = 'Starboy',
    this.duration = const Duration(minutes: 3, seconds: 30),
    this.isQueued = false,
    this.imageUrl,
    this.songId,
    this.uri,
    this.contextTrack,
  });

  MockQueueTrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    bool? isQueued,
    String? imageUrl,
    int? songId,
    String? uri,
    ContextTrack? contextTrack,
  }) {
    final nextId = id ?? this.id;
    final nextIsQueued = isQueued ?? this.isQueued;
    final nextCt = contextTrack ??
        this.contextTrack?.toBuilder()
            .uid(nextId)
            .metadata({
              ...this.contextTrack!.metadata,
              ContextTrackMetadata.keyIsQueued: nextIsQueued.toString(),
            }).build();

    return MockQueueTrack(
      id: nextId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      isQueued: nextIsQueued,
      imageUrl: imageUrl ?? this.imageUrl,
      songId: songId ?? this.songId,
      uri: uri ?? this.uri,
      contextTrack: nextCt,
    );
  }
}

/// Bidirectional conversion extensions between MockQueueTrack and ContextTrack
extension MockQueueTrackToContextTrack on MockQueueTrack {
  ContextTrack toContextTrack() {
    if (contextTrack != null) {
      return contextTrack!;
    }
    final effectiveUri = (uri != null && uri!.isNotEmpty)
        ? uri!
        : (id.startsWith('spotify:') ? id : 'spotify:track:$id');
    return ContextTrack.builder(effectiveUri)
        .uid(id)
        .metadata({
          ContextTrackMetadata.keyTitle: title,
          ContextTrackMetadata.keyArtistName: artist,
          ContextTrackMetadata.keyAlbumTitle: album,
          ContextTrackMetadata.keyImageLargeUrl: ?imageUrl,
          ContextTrackMetadata.keyImageUrl: ?imageUrl,
          ContextTrackMetadata.keyIsQueued: isQueued.toString(),
          ContextTrackMetadata.keyDuration: duration.inMilliseconds.toString(),
        })
        .build();
  }
}

extension ContextTrackToMockQueueTrack on ContextTrack {
  MockQueueTrack toMockQueueTrack() {
    return MockQueueTrack(
      id: uid.isNotEmpty ? uid : uri,
      uri: uri,
      title: title.isNotEmpty ? title : 'Untitled',
      artist: artist.isNotEmpty ? artist : 'Unknown Artist',
      album: album.isNotEmpty ? album : '',
      duration: duration,
      isQueued: isQueued,
      imageUrl: imageUrl,
      contextTrack: this,
    );
  }
}

const MockQueueTrack _defaultNowPlaying = MockQueueTrack(
  id: 'np-1',
  title: 'Starboy',
  artist: 'The Weeknd, Daft Punk',
  album: 'Starboy',
  duration: Duration(minutes: 3, seconds: 50),
);

const List<MockQueueTrack> _defaultMockTracks = [
  MockQueueTrack(
    id: 'track-1',
    title: 'Blinding Lights',
    artist: 'The Weeknd',
    album: 'After Hours',
    duration: Duration(minutes: 3, seconds: 20),
    isQueued: true,
  ),
  MockQueueTrack(
    id: 'track-2',
    title: 'Save Your Tears',
    artist: 'The Weeknd',
    album: 'After Hours',
    duration: Duration(minutes: 3, seconds: 35),
    isQueued: true,
  ),
  MockQueueTrack(
    id: 'track-3',
    title: 'Party Monster',
    artist: 'The Weeknd',
    album: 'Starboy',
    duration: Duration(minutes: 4, seconds: 9),
    isQueued: false,
  ),
  MockQueueTrack(
    id: 'track-4',
    title: 'False Alarm',
    artist: 'The Weeknd',
    album: 'Starboy',
    duration: Duration(minutes: 3, seconds: 40),
    isQueued: false,
  ),
  MockQueueTrack(
    id: 'track-5',
    title: 'Reminder',
    artist: 'The Weeknd',
    album: 'Starboy',
    duration: Duration(minutes: 3, seconds: 38),
    isQueued: false,
  ),
  MockQueueTrack(
    id: 'track-6',
    title: 'Rockin\'',
    artist: 'The Weeknd',
    album: 'Starboy',
    duration: Duration(minutes: 3, seconds: 52),
    isQueued: false,
  ),
  MockQueueTrack(
    id: 'track-7',
    title: 'Secrets',
    artist: 'The Weeknd',
    album: 'Starboy',
    duration: Duration(minutes: 4, seconds: 25),
    isQueued: false,
  ),
];

/// 1:1 Replica of Spotify Android Queue Sheet
class QueueSheetScreen extends StatelessWidget {
  final PlayerQueueBloc? bloc;
  final ContextTrack? nowPlayingContextTrack;
  final List<ContextTrack>? contextTracks;

  final MockQueueTrack? nowPlaying;
  final List<MockQueueTrack> tracks;
  final bool isPlaying;
  final QueueShuffleMode shuffleMode;
  final QueueRepeatMode repeatMode;
  final bool isTimerActive;
  final VoidCallback? onPlayPause;
  final VoidCallback? onShuffleTapped;
  final VoidCallback? onRepeatTapped;
  final VoidCallback? onTimerTapped;
  final VoidCallback? onClearQueue;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(MockQueueTrack track)? onTrackTapped;
  final void Function(MockQueueTrack track)? onTrackRemoved;
  final void Function(MockQueueTrack track)? onAddToQueue;

  const QueueSheetScreen({
    super.key,
    this.bloc,
    this.nowPlayingContextTrack,
    this.contextTracks,
    this.nowPlaying,
    this.tracks = const [],
    this.isPlaying = false,
    this.shuffleMode = QueueShuffleMode.none,
    this.repeatMode = QueueRepeatMode.none,
    this.isTimerActive = false,
    this.onPlayPause,
    this.onShuffleTapped,
    this.onRepeatTapped,
    this.onTimerTapped,
    this.onClearQueue,
    this.onReorder,
    this.onTrackTapped,
    this.onTrackRemoved,
    this.onAddToQueue,
  });

  static bool _isOpen = false;
  static final ValueNotifier<bool> isOpenNotifier = ValueNotifier<bool>(false);

  static void show(
    BuildContext context, {
    PlayerQueueBloc? bloc,
    ContextTrack? nowPlayingContextTrack,
    List<ContextTrack>? contextTracks,
    MockQueueTrack? nowPlaying,
    List<MockQueueTrack> tracks = const [],
    bool isPlaying = false,
    QueueShuffleMode shuffleMode = QueueShuffleMode.none,
    QueueRepeatMode repeatMode = QueueRepeatMode.none,
    bool isTimerActive = false,
    VoidCallback? onPlayPause,
    VoidCallback? onShuffleTapped,
    VoidCallback? onRepeatTapped,
    VoidCallback? onTimerTapped,
    VoidCallback? onClearQueue,
    void Function(int oldIndex, int newIndex)? onReorder,
    void Function(MockQueueTrack track)? onTrackTapped,
    void Function(MockQueueTrack track)? onTrackRemoved,
    void Function(MockQueueTrack track)? onAddToQueue,
  }) {
    if (_isOpen) return;
    _isOpen = true;
    isOpenNotifier.value = true;

    final effectiveBloc = bloc ??
        (getIt.isRegistered<PlayerQueueBloc>() ? getIt<PlayerQueueBloc>() : null);
    Navigator.of(context, rootNavigator: true)
        .push(
          PageRouteBuilder<void>(
            opaque: false,
            barrierDismissible: false,
            barrierColor: Colors.transparent,
            transitionDuration: const Duration(milliseconds: 420),
            reverseTransitionDuration: const Duration(milliseconds: 380),
            pageBuilder: (modalContext, _, _) {
              return QueueSheetScreen(
                bloc: effectiveBloc,
                nowPlayingContextTrack: nowPlayingContextTrack,
                contextTracks: contextTracks,
                nowPlaying: nowPlaying,
                tracks: tracks,
                isPlaying: isPlaying,
                shuffleMode: shuffleMode,
                repeatMode: repeatMode,
                isTimerActive: isTimerActive,
                onPlayPause: onPlayPause,
                onShuffleTapped: onShuffleTapped,
                onRepeatTapped: onRepeatTapped,
                onTimerTapped: onTimerTapped,
                onClearQueue: onClearQueue,
                onReorder: onReorder,
                onTrackTapped: onTrackTapped,
                onTrackRemoved: onTrackRemoved,
                onAddToQueue: onAddToQueue,
              );
            },
            transitionsBuilder: (context, animation, _, child) {
              const curve = Cubic(0.3, 0.0, 0.0, 1.0);
              final curved = CurvedAnimation(
                parent: animation,
                curve: curve,
                reverseCurve: curve,
              );
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              );
            },
          ),
        )
        .whenComplete(() {
          _isOpen = false;
          isOpenNotifier.value = false;
        });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBloc = bloc ??
        (getIt.isRegistered<PlayerQueueBloc>() ? getIt<PlayerQueueBloc>() : null);

    if (effectiveBloc != null) {
      return BlocBuilder<PlayerQueueBloc, PlayerQueueState>(
        bloc: effectiveBloc,
        builder: (context, state) {
          final liveNowPlaying = state.nowPlaying?.toMockQueueTrack() ??
              nowPlayingContextTrack?.toMockQueueTrack() ??
              nowPlaying;
          final liveTracks = state.visibleTracks.map((t) => t.toMockQueueTrack()).toList();
          final liveShuffle = state.isShuffling
              ? QueueShuffleMode.all
              : QueueShuffleMode.none;
          final QueueRepeatMode liveRepeat;
          switch (state.repeatMode) {
            case RepeatMode.none:
              liveRepeat = QueueRepeatMode.none;
              break;
            case RepeatMode.context:
              liveRepeat = QueueRepeatMode.all;
              break;
            case RepeatMode.track:
              liveRepeat = QueueRepeatMode.one;
              break;
          }

          return PullToDismissScaffold(
            barrierBaseAlpha: 0.72,
            builder: (scaffoldContext, dismissController) {
              final activeBloc = effectiveBloc;
              return _QueueSheetBody(
                dismissController: dismissController,
                nowPlaying: liveNowPlaying,
                tracks: liveTracks,
                isPlaying: state.isPlaying,
                shuffleMode: liveShuffle,
                repeatMode: liveRepeat,
                isTimerActive: isTimerActive,
                onPlayPause: () => activeBloc.add(const TogglePlayPause()),
                onShuffleTapped: () => activeBloc.add(const ToggleShuffle()),
                onRepeatTapped: () => activeBloc.add(const ToggleRepeat()),
                onTimerTapped: onTimerTapped,
                onClearQueue: () => activeBloc.add(const ClearQueue()),
                onResetQueue: () => MockQueueSeeder.resetQueue(activeBloc),
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex < state.visibleTracks.length && state.visibleTracks.isNotEmpty) {
                    final track = state.visibleTracks[oldIndex];
                    final destIndex = newIndex.clamp(0, state.visibleTracks.length - 1);
                    activeBloc.add(ReorderQueueTrack(
                      track: track,
                      destinationVisibleIndex: destIndex,
                    ));
                  }
                },
                onTrackTapped: (mockTrack) {
                  activeBloc.add(PlayTrackFromQueue(mockTrack.toContextTrack()));
                },
                onTrackRemoved: (mockTrack) {
                  activeBloc.add(RemoveTracksFromQueue([mockTrack.toContextTrack()]));
                },
                onAddToQueue: (mockTrack) {
                  activeBloc.add(AddTracksToQueue([mockTrack.toContextTrack()]));
                },
              );
            },
          );
        },
      );
    }

    final currentContextTrack = nowPlayingContextTrack;
    final providedContextTracks = contextTracks;

    final initialNowPlaying = currentContextTrack != null
        ? currentContextTrack.toMockQueueTrack()
        : nowPlaying;
    final initialTracks =
        (providedContextTracks != null && providedContextTracks.isNotEmpty)
            ? providedContextTracks.map((t) => t.toMockQueueTrack()).toList()
            : tracks;

    return PullToDismissScaffold(
      barrierBaseAlpha: 0.72,
      builder: (context, dismissController) {
        return _QueueSheetBody(
          dismissController: dismissController,
          nowPlaying: initialNowPlaying,
          tracks: initialTracks,
          isPlaying: isPlaying,
          shuffleMode: shuffleMode,
          repeatMode: repeatMode,
          isTimerActive: isTimerActive,
          onPlayPause: onPlayPause,
          onShuffleTapped: onShuffleTapped,
          onRepeatTapped: onRepeatTapped,
          onTimerTapped: onTimerTapped,
          onClearQueue: onClearQueue,
          onReorder: onReorder,
          onTrackTapped: onTrackTapped,
          onTrackRemoved: onTrackRemoved,
          onAddToQueue: onAddToQueue,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet Body
// ---------------------------------------------------------------------------

class _QueueSheetBody extends StatefulWidget {
  const _QueueSheetBody({
    required this.dismissController,
    this.nowPlaying,
    this.tracks = const [],
    this.isPlaying = false,
    this.shuffleMode = QueueShuffleMode.none,
    this.repeatMode = QueueRepeatMode.none,
    this.isTimerActive = false,
    this.onPlayPause,
    this.onShuffleTapped,
    this.onRepeatTapped,
    this.onTimerTapped,
    this.onClearQueue,
    this.onReorder,
    this.onTrackTapped,
    this.onTrackRemoved,
    this.onAddToQueue,
    this.onResetQueue,
  });

  final PullToDismissController dismissController;
  final MockQueueTrack? nowPlaying;
  final List<MockQueueTrack> tracks;
  final bool isPlaying;
  final QueueShuffleMode shuffleMode;
  final QueueRepeatMode repeatMode;
  final bool isTimerActive;
  final VoidCallback? onPlayPause;
  final VoidCallback? onShuffleTapped;
  final VoidCallback? onRepeatTapped;
  final VoidCallback? onTimerTapped;
  final VoidCallback? onClearQueue;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(MockQueueTrack track)? onTrackTapped;
  final void Function(MockQueueTrack track)? onTrackRemoved;
  final void Function(MockQueueTrack track)? onAddToQueue;
  final VoidCallback? onResetQueue;

  @override
  State<_QueueSheetBody> createState() => _QueueSheetBodyState();
}

class _QueueSheetBodyState extends State<_QueueSheetBody>
    with TickerProviderStateMixin {
  late final SpotifyStretchController _stretchController;
  late final SpotifyPeekScrollController _scrollController;
  late final String _sheetSessionId = UniqueKey().toString();

  late List<MockQueueTrack> _tracks;
  late MockQueueTrack _nowPlaying;
  late bool _isPlaying;
  late QueueShuffleMode _shuffleMode;
  late QueueRepeatMode _repeatMode;

  final Set<String> _animatedInsertUids = {};
  final Set<String> _slideDownUids = {};
  final Set<String> _clearingUids = {};

  static List<MockQueueTrack> _sanitizeTracks(List<MockQueueTrack> rawTracks) {
    final seen = <String, int>{};
    return rawTracks.map((t) {
      final baseId = t.id.isNotEmpty ? t.id : (t.uri ?? 'track');
      final count = seen[baseId] ?? 0;
      seen[baseId] = count + 1;
      if (count > 0) {
        return t.copyWith(id: '${baseId}_dup_$count');
      }
      return t.id.isNotEmpty ? t : t.copyWith(id: baseId);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _stretchController = SpotifyStretchController(vsync: this);
    _scrollController = SpotifyPeekScrollController(
      dismissController: widget.dismissController,
      stretchController: _stretchController,
    );

    final rawTracks = widget.tracks.isNotEmpty || widget.onResetQueue != null
        ? widget.tracks
        : _defaultMockTracks;
    _tracks = _sanitizeTracks(rawTracks);
    _nowPlaying = widget.nowPlaying ?? _defaultNowPlaying;
    _isPlaying = widget.isPlaying;
    _shuffleMode = widget.shuffleMode;
    _repeatMode = widget.repeatMode;
  }

  @override
  void didUpdateWidget(_QueueSheetBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tracks != oldWidget.tracks) {
      setState(() {
        final rawTracks = widget.tracks.isNotEmpty || widget.onResetQueue != null
            ? widget.tracks
            : _defaultMockTracks;
        _tracks = _sanitizeTracks(rawTracks);
      });
    }
    if (widget.nowPlaying != oldWidget.nowPlaying) {
      setState(() {
        _nowPlaying = widget.nowPlaying ?? _defaultNowPlaying;
      });
    }
    if (widget.isPlaying != oldWidget.isPlaying) {
      setState(() {
        _isPlaying = widget.isPlaying;
      });
    }
    if (widget.shuffleMode != oldWidget.shuffleMode) {
      setState(() {
        _shuffleMode = widget.shuffleMode;
      });
    }
    if (widget.repeatMode != oldWidget.repeatMode) {
      setState(() {
        _repeatMode = widget.repeatMode;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _stretchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      margin: EdgeInsets.only(top: topInset),
      decoration: const BoxDecoration(
        color: PlayerColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Sticky Top Area: Grapple + Queue Header + Sticky First Song
              // Coordinated with PullToDismissController just like PlayerScreen.
              RepaintBoundary(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: (details) {
                    final delta = details.primaryDelta ?? 0;
                    if (delta > 0 ||
                        widget.dismissController.dragOffsetY > 0) {
                      widget.dismissController.onPullDelta(delta);
                    }
                  },
                  onVerticalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    widget.dismissController.onPullEnd(velocity);
                  },
                  child: Container(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    decoration: const BoxDecoration(
                      color: PlayerColors.background,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Grapple(),
                        _QueueHeader(
                          nowPlayingAlbum: _nowPlaying.album,
                          nowPlayingArtist: _nowPlaying.artist,
                          hasUserQueue: _tracks.any((t) => t.isQueued),
                          onClearTapped: () {
                            final userQueueCount =
                                _tracks.where((t) => t.isQueued).length;
                            if (userQueueCount == 0) return;

                            final scrollOffset = _scrollController.hasClients
                                ? _scrollController.offset
                                : 0.0;
                            final firstVisibleIndex = (scrollOffset / 64.0)
                                .floor()
                                .clamp(0, _tracks.length);
                            final offScreenClearedCount =
                                firstVisibleIndex.clamp(0, userQueueCount);

                            if (offScreenClearedCount > 0 &&
                                _scrollController.hasClients) {
                              final targetOffset = (scrollOffset -
                                      offScreenClearedCount * 64.0)
                                  .clamp(0.0, double.infinity);
                              _scrollController.jumpTo(targetOffset);
                            }

                            setState(() {
                              _tracks.removeWhere((t) => t.isQueued);
                            });
                            widget.onClearQueue?.call();
                          },
                        ),
                        QueueNowPlayingRow(
                          title: _nowPlaying.title,
                          artist: _nowPlaying.artist,
                          imageUrl: _nowPlaying.imageUrl,
                          songId: _nowPlaying.songId,
                          isPlaying: _isPlaying,
                          onTap: widget.dismissController.dismiss,
                          onPlayPause: () {
                            setState(() {
                              _isPlaying = !_isPlaying;
                            });
                            widget.onPlayPause?.call();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RepaintBoundary(
                  child: _buildList(context),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: PlayerColors.background,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: QueueControlsLayout(
                    shuffleMode: _shuffleMode,
                    repeatMode: _repeatMode,
                    isTimerActive: widget.isTimerActive,
                    onShuffleTapped: () {
                      setState(() {
                        _shuffleMode = _shuffleMode == QueueShuffleMode.all
                            ? QueueShuffleMode.none
                            : QueueShuffleMode.all;
                      });
                      widget.onShuffleTapped?.call();
                    },
                    onRepeatTapped: () {
                      setState(() {
                        if (_repeatMode == QueueRepeatMode.none) {
                          _repeatMode = QueueRepeatMode.all;
                        } else if (_repeatMode == QueueRepeatMode.all) {
                          _repeatMode = QueueRepeatMode.one;
                        } else {
                          _repeatMode = QueueRepeatMode.none;
                        }
                      });
                      widget.onRepeatTapped?.call();
                    },
                    onTimerTapped: () => widget.onTimerTapped?.call(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_tracks.isEmpty) {
      return _buildPlaceholder();
    }

    final bottomPad = MediaQuery.paddingOf(context).bottom + 104;

    return SpotifyStretchOverscrollIndicator(
      controller: _stretchController,
      axisDirection: AxisDirection.down,
      child: ReorderableListView.builder(
        scrollController: _scrollController,
        physics: const ClampingScrollPhysics(),
        buildDefaultDragHandles: false,
        scrollCacheExtent: const ScrollCacheExtent.pixels(400.0),
        padding: EdgeInsets.only(bottom: bottomPad),
        proxyDecorator: _proxyDecorator,
        itemCount: _tracks.length,
        onReorderItem: (oldIndex, newIndex) {
          if (oldIndex < _tracks.length && _tracks.isNotEmpty) {
            final destIndex = newIndex.clamp(0, _tracks.length - 1);
            setState(() {
              final item = _tracks.removeAt(oldIndex);

              // Spotify lr5.java lines 580-596: determine if destination is within user queue section
              int lastQueuedIdx = -1;
              for (int i = _tracks.length - 1; i >= 0; i--) {
                if (_tracks[i].isQueued) {
                  lastQueuedIdx = i;
                  break;
                }
              }

              final bool targetIsQueued;
              if (lastQueuedIdx == -1) {
                targetIsQueued = destIndex == 0 && item.isQueued;
              } else {
                targetIsQueued = destIndex <= (lastQueuedIdx + 1);
              }

              _tracks.insert(destIndex, item.copyWith(isQueued: targetIsQueued));
            });
            widget.onReorder?.call(oldIndex, destIndex);
          }
        },
        itemBuilder: (context, index) {
          final track = _tracks[index];
          final shouldAnimateInsert =
              _animatedInsertUids.contains(track.id);
          final shouldAnimateSlideDown =
              _slideDownUids.contains(track.id);
          final isClearingRow = _clearingUids.contains(track.id);

          return QueueTrackRow(
            key: ValueKey('track_${_sheetSessionId}_${track.id}'),
            title: track.title,
            artist: track.artist,
            isQueued: track.isQueued,
            imageUrl: track.imageUrl,
            songId: track.songId,
            index: index,
            animateInsert: shouldAnimateInsert,
            animateSlideDown: shouldAnimateSlideDown,
            isClearing: isClearingRow,
            onTap: () {
              setState(() {
                _nowPlaying = track;
                _isPlaying = true;
              });
              widget.onTrackTapped?.call(track);
            },
            onRemove: () {
              setState(() {
                final removeIndex = _tracks.indexOf(track);
                if (removeIndex != -1) {
                  _tracks.removeAt(removeIndex);
                }
              });
              widget.onTrackRemoved?.call(track);
            },
            onAddToQueue: () {
              final userQueueCount = _tracks.where((t) => t.isQueued).length;
              final scrollOffset = _scrollController.hasClients
                  ? _scrollController.offset
                  : 0.0;
              if (_scrollController.hasClients &&
                  userQueueCount * 64.0 < scrollOffset - 4.0) {
                _scrollController.jumpTo(scrollOffset + 64.0);
              }
              final queuedCopy = track.copyWith(
                id: '${track.id}_queued_${DateTime.now().microsecondsSinceEpoch}',
                isQueued: true,
              );
              setState(() {
                _tracks.insert(userQueueCount, queuedCopy);
              });
              widget.onAddToQueue?.call(queuedCopy);
            },
          );
        },
      ),
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        child: RepaintBoundary(child: child),
        builder: (context, proxyChild) {
          const curve = Cubic(0.3, 0.0, 0.0, 1.0);
          final t = curve.transform(animation.value);
          final bgColor = Color.lerp(
            PlayerColors.background,
            const Color(0xFF262626),
            t,
          )!;

          return ColoredBox(
            color: bgColor,
            child: proxyChild,
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpotifyIcon.addToQueue(size: 48, color: PlayerColors.muted),
            const SizedBox(height: 16),
            const Text(
              'Queue is empty',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add tracks from playlists or albums to keep the music playing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PlayerColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (widget.onResetQueue != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: PlayerColors.muted),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: widget.onResetQueue,
                child: const Text(
                  'Restore Test Queue',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grapple
// ---------------------------------------------------------------------------

class _Grapple extends StatelessWidget {
  const _Grapple();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Queue Header
// ---------------------------------------------------------------------------

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({
    required this.nowPlayingAlbum,
    required this.nowPlayingArtist,
    required this.hasUserQueue,
    required this.onClearTapped,
  });

  final String nowPlayingAlbum;
  final String nowPlayingArtist;
  final bool hasUserQueue;
  final VoidCallback onClearTapped;

  static const Duration _headerAnimDuration = Duration(milliseconds: 300);
  static final Tween<double> _clearScaleTween =
      Tween<double>(begin: 0.88, end: 1.0);

  @override
  Widget build(BuildContext context) {
    final contextTitle = nowPlayingAlbum.isNotEmpty && nowPlayingAlbum != 'Unknown Album'
        ? nowPlayingAlbum
        : (nowPlayingArtist.isNotEmpty ? nowPlayingArtist : null);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 2, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Queue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (contextTitle != null) ...[
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Playing ',
                          style: TextStyle(
                            color: PlayerColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: contextTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          AnimatedSize(
            duration: _headerAnimDuration,
            curve: Curves.decelerate,
            child: AnimatedSwitcher(
              duration: _headerAnimDuration,
              switchInCurve: Curves.decelerate,
              switchOutCurve: Curves.decelerate,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: _clearScaleTween.animate(anim),
                  child: child,
                ),
              ),
              child: hasUserQueue
                  ? Padding(
                      key: const ValueKey('clear_btn'),
                      padding: const EdgeInsets.only(right: 8),
                      child: _HeaderActionButton(
                        label: 'Clear',
                        onTap: onClearTapped,
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no_clear_btn')),
            ),
          ),
          _HeaderActionButton(
            label: 'Edit',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatefulWidget {
  const _HeaderActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_HeaderActionButton> createState() => _HeaderActionButtonState();
}

class _HeaderActionButtonState extends State<_HeaderActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
