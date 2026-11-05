import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/rendering.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/ui/icons/spotify_encore_icons.dart';
import '../../../../core/ubi/domain/logging/ubi_logger.dart';

import '../../application/queue/player_queue_bloc.dart';
import '../../data/esperanto/context_player_options_client.dart';
import '../../data/queue/context_track_extensions.dart';
import '../../domain/models/context_track.dart';
import '../widgets/peek_scroll_view.dart';
import '../widgets/player_theme.dart';
import '../widgets/pull_to_dismiss_scaffold.dart';
import '../widgets/queue_controls_layout.dart';
import '../widgets/queue_now_playing_row.dart';
import '../widgets/queue_track_row.dart';
import '../widgets/spotify_scroll_physics.dart';

/// 1:1 Lightweight track representation for Queue Sheet UI
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
    required this.album,
    required this.duration,
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
    final nextId = switch (id) {
      final val? => val,
      null => this.id,
    };
    final nextIsQueued = switch (isQueued) {
      final val? => val,
      null => this.isQueued,
    };
    final nextTitle = switch (title) { final val? => val, null => this.title };
    final nextArtist = switch (artist) { final val? => val, null => this.artist };
    final nextAlbum = switch (album) { final val? => val, null => this.album };
    final nextDuration = switch (duration) { final val? => val, null => this.duration };
    final nextImageUrl = switch (imageUrl) { final val? => val, null => this.imageUrl };
    final nextSongId = switch (songId) { final val? => val, null => this.songId };
    final nextUri = switch (uri) { final val? => val, null => this.uri };

    final nextCt = switch (contextTrack) {
      final ct? => ct,
      null => switch (this.contextTrack) {
        final existingCt? => existingCt.toBuilder()
            .uid(nextId)
            .provider(nextIsQueued ? 'queue' : 'context')
            .metadata({
              ...existingCt.metadata,
              ContextTrackMetadata.keyIsQueued: nextIsQueued.toString(),
              'provider': nextIsQueued ? 'queue' : 'context',
            }).build(),
        null => toContextTrack().toBuilder()
            .uid(nextId)
            .provider(nextIsQueued ? 'queue' : 'context')
            .metadata({
              ContextTrackMetadata.keyTitle: nextTitle,
              ContextTrackMetadata.keyArtistName: nextArtist,
              ContextTrackMetadata.keyAlbumTitle: nextAlbum,
              if (nextImageUrl case final img? when img.isNotEmpty) ...{
                ContextTrackMetadata.keyImageLargeUrl: img,
                ContextTrackMetadata.keyImageUrl: img,
                ContextTrackMetadata.keyThumbnailImageUrl: img,
              },
              ContextTrackMetadata.keyIsQueued: nextIsQueued.toString(),
              ContextTrackMetadata.keyDuration: nextDuration.inMilliseconds.toString(),
              if (nextSongId case final sId?) ContextTrackMetadata.keySongId: sId.toString(),
              'provider': nextIsQueued ? 'queue' : 'context',
            }).build(),
      },
    };

    return MockQueueTrack(
      id: nextId,
      title: nextTitle,
      artist: nextArtist,
      album: nextAlbum,
      duration: nextDuration,
      isQueued: nextIsQueued,
      imageUrl: nextImageUrl,
      songId: nextSongId,
      uri: nextUri,
      contextTrack: nextCt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MockQueueTrack &&
        other.id == id &&
        other.uri == uri &&
        other.isQueued == isQueued &&
        other.title == title &&
        other.artist == artist &&
        other.album == album &&
        other.songId == songId;
  }

  @override
  int get hashCode => Object.hash(id, uri, isQueued, title, artist, album, songId);
}

/// Bidirectional conversion extensions between MockQueueTrack and ContextTrack
extension MockQueueTrackToContextTrack on MockQueueTrack {
  ContextTrack toContextTrack() {
    if (contextTrack case final ct?) {
      return ct;
    }
    final effectiveUri = switch (uri) {
      final u? when u.isNotEmpty => u,
      _ => id.startsWith('spotify:') ? id : 'spotify:track:$id',
    };
    final effectiveProvider = isQueued ? 'queue' : 'context';
    return ContextTrack.builder(effectiveUri)
        .uid(id)
        .provider(effectiveProvider)
        .metadata({
          ContextTrackMetadata.keyTitle: title,
          ContextTrackMetadata.keyArtistName: artist,
          ContextTrackMetadata.keyAlbumTitle: album,
          if (imageUrl case final img? when img.isNotEmpty) ...{
            ContextTrackMetadata.keyImageLargeUrl: img,
            ContextTrackMetadata.keyImageUrl: img,
          },
          ContextTrackMetadata.keyIsQueued: isQueued.toString(),
          ContextTrackMetadata.keyDuration: duration.inMilliseconds.toString(),
          if (songId case final sId?) ContextTrackMetadata.keySongId: sId.toString(),
          'provider': effectiveProvider,
        })
        .build();
  }
}

extension ContextTrackToMockQueueTrack on ContextTrack {
  MockQueueTrack toMockQueueTrack() {
    final image = switch (thumbnailImageUrl) {
      final t? when t.isNotEmpty => t,
      _ => imageUrl,
    };
    final resolvedId = switch (uid) {
      final u when u.isNotEmpty => u,
      _ => '$uri${identityHashCode(this).toRadixString(16)}',
    };
    final effectiveCt = uid.isNotEmpty
        ? this
        : toBuilder().uid(resolvedId).build();
    return MockQueueTrack(
      id: resolvedId,
      uri: uri,
      title: title.isNotEmpty ? title : 'Untitled',
      artist: artist.isNotEmpty ? artist : 'Unknown Artist',
      album: album.isNotEmpty ? album : '',
      duration: duration,
      isQueued: isQueued,
      imageUrl: image,
      songId: songId,
      contextTrack: effectiveCt,
    );
  }
}

const _defaultNowPlaying = MockQueueTrack(
  id: 'now-playing',
  title: 'Starboy',
  artist: 'The Weeknd, Daft Punk',
  album: 'Starboy',
  duration: Duration(minutes: 3, seconds: 50),
);


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

    if (getIt.isRegistered<UbiLogger>()) {
      getIt<UbiLogger>().logImpression(
        const UbiImpressionElement(
          elementPath: 'nowplaying/queue',
          uri: 'spotify:internal:queue',
        ),
      );
    }

    final effectiveBloc = switch (bloc) {
      final b? => b,
      null => getIt.isRegistered<PlayerQueueBloc>()
          ? getIt<PlayerQueueBloc>()
          : null,
    };

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
    final effectiveBloc = switch (bloc) {
      final b? => b,
      null => getIt.isRegistered<PlayerQueueBloc>()
          ? getIt<PlayerQueueBloc>()
          : null,
    };

    if (effectiveBloc != null) {
      return ValueListenableBuilder<PlayerQueueState>(
        valueListenable: effectiveBloc,
        builder: (context, state, _) {
          final liveNowPlaying = switch (state.nowPlaying) {
            final np? => np.toMockQueueTrack(),
            null => switch (nowPlayingContextTrack) {
              final ct? => ct.toMockQueueTrack(),
              null => nowPlaying,
            },
          };
          final liveTracks = state.visibleTracks.map((t) => t.toMockQueueTrack()).toList();
          final liveShuffle = state.isShuffling
              ? QueueShuffleMode.all
              : QueueShuffleMode.none;
          final liveRepeat = switch (state.repeatMode) {
            RepeatMode.none => QueueRepeatMode.none,
            RepeatMode.context => QueueRepeatMode.all,
            RepeatMode.track => QueueRepeatMode.one,
          };
          final liveIsPlaying = state.isPlaying;

          return _QueueSheetScaffold(
            nowPlaying: liveNowPlaying,
            tracks: liveTracks,
            isPlaying: liveIsPlaying,
            shuffleMode: liveShuffle,
            repeatMode: liveRepeat,
            isTimerActive: isTimerActive,
            onPlayPause: () => effectiveBloc.add(const TogglePlayPauseEvent()),
            onShuffleTapped: () => effectiveBloc.add(const ToggleShuffleEvent()),
            onRepeatTapped: () => effectiveBloc.add(const ToggleRepeatEvent()),
            onTimerTapped: onTimerTapped,
            onClearQueue: () => effectiveBloc.add(const ClearQueueEvent()),
            onResetQueue: () => effectiveBloc.add(const ResetQueueEvent()),
            onReorder: (oldIndex, newIndex) {
              if (oldIndex >= 0 && oldIndex < state.visibleTracks.length) {
                final track = state.visibleTracks[oldIndex];
                effectiveBloc.add(ReorderTrackEvent(
                  track: track,
                  destinationVisibleIndex: newIndex,
                ));
              }
            },
            onTrackTapped: (mockTrack) {
              final ct = switch (mockTrack.contextTrack) {
                final track? => track,
                null => mockTrack.toContextTrack(),
              };
              effectiveBloc.add(TrackTappedEvent(ct));
            },
            onTrackRemoved: (mockTrack) {
              final ct = switch (mockTrack.contextTrack) {
                final track? => track,
                null => mockTrack.toContextTrack(),
              };
              effectiveBloc.add(RemoveTrackEvent(ct));
            },
            onAddToQueue: (mockTrack) {
              final ct = switch (mockTrack.contextTrack) {
                final track? => track,
                null => mockTrack.toContextTrack(),
              };
              effectiveBloc.add(AddToQueueEvent(track: ct, playNext: false));
            },
          );
        },
      );
    }

    return _QueueSheetScaffold(
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
  }
}

class _QueueSheetScaffold extends StatelessWidget {
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
  final VoidCallback? onResetQueue;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(MockQueueTrack track)? onTrackTapped;
  final void Function(MockQueueTrack track)? onTrackRemoved;
  final void Function(MockQueueTrack track)? onAddToQueue;

  const _QueueSheetScaffold({
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
    this.onResetQueue,
    this.onReorder,
    this.onTrackTapped,
    this.onTrackRemoved,
    this.onAddToQueue,
  });

  @override
  Widget build(BuildContext context) {
    return PullToDismissScaffold(
      builder: (context, dismissController) {
        return _QueueSheetBody(
          dismissController: dismissController,
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
          onResetQueue: onResetQueue,
          onReorder: onReorder,
          onTrackTapped: onTrackTapped,
          onTrackRemoved: onTrackRemoved,
          onAddToQueue: onAddToQueue,
        );
      },
    );
  }
}

class _QueueSheetBody extends StatefulWidget {
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
  final VoidCallback? onResetQueue;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(MockQueueTrack track)? onTrackTapped;
  final void Function(MockQueueTrack track)? onTrackRemoved;
  final void Function(MockQueueTrack track)? onAddToQueue;

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
    this.onResetQueue,
    this.onReorder,
    this.onTrackTapped,
    this.onTrackRemoved,
    this.onAddToQueue,
  });

  @override
  State<_QueueSheetBody> createState() => _QueueSheetBodyState();
}

class _QueueSheetBodyState extends State<_QueueSheetBody>
    with TickerProviderStateMixin {
  static int _boundInt(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static double _boundDouble(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  final String _sheetSessionId = UniqueKey().toString();
  late final SpotifyStretchController _stretchController;
  late final SpotifyPeekScrollController _scrollController;

  List<MockQueueTrack> _tracks = const [];
  MockQueueTrack _nowPlaying = _defaultNowPlaying;
  bool _isPlaying = false;
  QueueShuffleMode _shuffleMode = QueueShuffleMode.none;
  QueueRepeatMode _repeatMode = QueueRepeatMode.none;

  int _tapAnimationGeneration = 0;
  List<MockQueueTrack>? _tapTransitionTracks;
  String? _tappedTrackUid;
  bool _isClearingQueue = false;

  final Set<String> _animatedInsertUids = {};
  final Set<String> _slideDownUids = {};
  final Set<String> _clearingUids = {};
  List<MockQueueTrack>? _pendingTracks;

  static List<MockQueueTrack> _sanitizeTracks(List<MockQueueTrack> rawTracks) {
    return rawTracks.map((t) {
      if (t.id.isNotEmpty) return t;
      final fallbackId = switch (t.uri) {
        final u? when u.isNotEmpty => u,
        _ => 'track',
      };
      return t.copyWith(id: fallbackId);
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

    final rawTracks = widget.tracks;
    _tracks = _sanitizeTracks(rawTracks);
    _nowPlaying = switch (widget.nowPlaying) {
      final np? => np,
      null => _defaultNowPlaying,
    };
    _isPlaying = widget.isPlaying;
    _shuffleMode = widget.shuffleMode;
    _repeatMode = widget.repeatMode;
  }

  @override
  void didUpdateWidget(_QueueSheetBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.tracks, oldWidget.tracks)) {
      if (_tapTransitionTracks != null || _clearingUids.isNotEmpty || _isClearingQueue) {
        _pendingTracks = widget.tracks;
      } else {
        setState(() {
          _tracks = _sanitizeTracks(widget.tracks);
        });
      }
    }
    if (widget.nowPlaying != oldWidget.nowPlaying) {
      if (_tapTransitionTracks == null) {
        setState(() {
          _nowPlaying = switch (widget.nowPlaying) {
            final np? => np,
            null => _defaultNowPlaying,
          };
        });
      }
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

  void _handleTrackTapped(MockQueueTrack track) {
    if (_tapTransitionTracks != null || _clearingUids.isNotEmpty || _isClearingQueue) {
      return;
    }

    final currentTracks = List<MockQueueTrack>.from(_tracks);
    final tapIdx = currentTracks.indexWhere((t) => t.id == track.id);
    if (tapIdx == -1) return;

    final tappedTrack = currentTracks[tapIdx];
    final userQueueCount = currentTracks.where((t) => t.isQueued).length;
    final scrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    final firstVisibleIndex =
        _boundInt((scrollOffset / 64.0).floor(), 0, currentTracks.length);
    final subRowOffset =
        _boundDouble(scrollOffset - firstVisibleIndex * 64.0, 0.0, 64.0);

    final gen = ++_tapAnimationGeneration;

    setState(() {
      _nowPlaying = tappedTrack;
      _isPlaying = true;
      _tappedTrackUid = tappedTrack.id;
    });

    widget.onTrackTapped?.call(tappedTrack);

    final isTappingQueuedOrNoQueuedExist =
        tapIdx < userQueueCount || userQueueCount == 0;

    if (isTappingQueuedOrNoQueuedExist) {
      final startVisibleIdx = _boundInt(firstVisibleIndex, 0, tapIdx);
      final visibleSkipped = currentTracks.sublist(startVisibleIdx, tapIdx + 1);
      final remainingAfterTap = currentTracks.sublist(tapIdx + 1);
      final transitionTracks = <MockQueueTrack>[
        ...visibleSkipped,
        ...remainingAfterTap,
      ];
      final skippedUids = visibleSkipped.map((t) => t.id).toSet();

      setState(() {
        _tapTransitionTracks = transitionTracks;
        _slideDownUids.clear();
        _clearingUids
          ..clear()
          ..addAll(skippedUids);
      });

      if (_scrollController.hasClients && _scrollController.offset > 0.0) {
        final initialOffset = startVisibleIdx == firstVisibleIndex
            ? subRowOffset
            : 0.0;
        _scrollController.jumpTo(initialOffset);
        if (initialOffset > 0.5) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutSine,
          );
        }
      }

      Future<void>.delayed(const Duration(milliseconds: 375), () {
        if (!mounted || _tapAnimationGeneration != gen) return;
        setState(() {
          _tapTransitionTracks = null;
          _tappedTrackUid = null;
          _slideDownUids.clear();
          _clearingUids.clear();
          if (_pendingTracks case final pending?) {
            _tracks = _sanitizeTracks(pending);
            _pendingTracks = null;
          } else {
            _tracks = currentTracks.sublist(tapIdx + 1);
          }
        });
      });
    } else {
      final offScreenQueuedCount = _boundInt(firstVisibleIndex, 0, userQueueCount);
      final firstVisibleRemovedContextIdx = firstVisibleIndex > userQueueCount
          ? _boundInt(firstVisibleIndex, userQueueCount, tapIdx)
          : userQueueCount;

      final animatedOffScreenQueued = currentTracks
          .take(_boundInt(offScreenQueuedCount, 0, 10))
          .toList();
      final visibleQueued = currentTracks.sublist(
        offScreenQueuedCount,
        userQueueCount,
      );
      final visibleRemovedContext = currentTracks.sublist(
        firstVisibleRemovedContextIdx,
        tapIdx + 1,
      );
      final remainingContext = currentTracks.sublist(tapIdx + 1);

      final transitionTracks = <MockQueueTrack>[
        ...animatedOffScreenQueued,
        ...visibleQueued,
        ...visibleRemovedContext,
        ...remainingContext,
      ];

      final slideDownUids = animatedOffScreenQueued.map((t) => t.id).toSet();
      final skippedUids = visibleRemovedContext.map((t) => t.id).toSet();

      setState(() {
        _tapTransitionTracks = transitionTracks;
        _slideDownUids
          ..clear()
          ..addAll(slideDownUids);
        _clearingUids
          ..clear()
          ..addAll(skippedUids);
      });

      if (_scrollController.hasClients && _scrollController.offset > 0.0) {
        _scrollController.jumpTo(subRowOffset);
        if (subRowOffset > 0.5) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutSine,
          );
        }
      }

      Future<void>.delayed(const Duration(milliseconds: 375), () {
        if (!mounted || _tapAnimationGeneration != gen) return;
        setState(() {
          _tapTransitionTracks = null;
          _tappedTrackUid = null;
          _slideDownUids.clear();
          _clearingUids.clear();
          if (_pendingTracks case final pending?) {
            _tracks = _sanitizeTracks(pending);
            _pendingTracks = null;
          } else {
            final preservedQueued = currentTracks.sublist(0, userQueueCount);
            final remainingCtx = currentTracks.sublist(tapIdx + 1);
            _tracks = [...preservedQueued, ...remainingCtx];
          }
        });
      });
    }
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
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (details) {
                  final delta = switch (details.primaryDelta) {
                    final d? => d,
                    null => 0.0,
                  };
                  if (delta > 0 || widget.dismissController.dragOffsetY > 0) {
                    widget.dismissController.onPullDelta(delta);
                  }
                },
                onVerticalDragEnd: (details) {
                  final velocity = switch (details.primaryVelocity) {
                    final v? => v,
                    null => 0.0,
                  };
                  widget.dismissController.onPullEnd(velocity);
                },
                child: RepaintBoundary(
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Grapple(),
                        _QueueHeader(
                          nowPlayingAlbum: _nowPlaying.album,
                          nowPlayingArtist: _nowPlaying.artist,
                          hasUserQueue: _tracks.any((t) => t.isQueued),
                          onClearTapped: () {
                            if (_tapTransitionTracks != null || _isClearingQueue || _clearingUids.isNotEmpty) return;
                            final userQueuedTracks =
                                _tracks.where((t) => t.isQueued).toList();
                            if (userQueuedTracks.isEmpty) return;

                            final userQueueCount = userQueuedTracks.length;
                            final currentTracks = List<MockQueueTrack>.from(_tracks);
                            final scrollOffset = _scrollController.hasClients
                                ? _scrollController.offset
                                : 0.0;
                            final firstVisibleIndex = _boundInt(
                                (scrollOffset / 64.0).floor(),
                                0,
                                currentTracks.length);
                            final offScreenClearedCount =
                                _boundInt(firstVisibleIndex, 0, userQueueCount);

                            final gen = ++_tapAnimationGeneration;
                            _isClearingQueue = true;

                            if (offScreenClearedCount >= userQueueCount) {
                              if (_scrollController.hasClients) {
                                final targetOffset = _boundDouble(
                                    scrollOffset - userQueueCount * 64.0,
                                    0.0,
                                    double.infinity);
                                _scrollController.jumpTo(targetOffset);
                              }
                              setState(() {
                                _tracks.removeWhere((t) => t.isQueued);
                                _isClearingQueue = false;
                                _clearingUids.clear();
                                _tapTransitionTracks = null;
                              });
                              widget.onClearQueue?.call();
                              return;
                            }

                            final visibleQueuedUids = userQueuedTracks
                                .sublist(offScreenClearedCount)
                                .map((t) => t.id)
                                .toList();

                            setState(() {
                              _slideDownUids.clear();
                              _clearingUids
                                ..clear()
                                ..addAll(visibleQueuedUids);
                              if (offScreenClearedCount > 0) {
                                _tapTransitionTracks = currentTracks.sublist(offScreenClearedCount);
                              }
                            });

                            if (offScreenClearedCount > 0 &&
                                _scrollController.hasClients) {
                              final targetOffset = _boundDouble(
                                  scrollOffset - offScreenClearedCount * 64.0,
                                  0.0,
                                  double.infinity);
                              _scrollController.jumpTo(targetOffset);
                            }

                            Future<void>.delayed(const Duration(milliseconds: 375), () {
                              if (!mounted || _tapAnimationGeneration != gen) return;
                              setState(() {
                                _isClearingQueue = false;
                                _tracks.removeWhere((t) => t.isQueued);
                                _clearingUids.clear();
                                _tapTransitionTracks = null;
                                if (_pendingTracks case final pending?) {
                                  _tracks = _sanitizeTracks(pending);
                                  _pendingTracks = null;
                                }
                              });
                              widget.onClearQueue?.call();
                            });
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
    final effectiveTracks = switch (_tapTransitionTracks) {
      final transitionTracks? => transitionTracks,
      null => _tracks,
    };
    if (effectiveTracks.isEmpty) {
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
        itemCount: effectiveTracks.length,
        onReorderItem: (oldIndex, newIndex) {
          if (_tapTransitionTracks != null || _clearingUids.isNotEmpty || _isClearingQueue) return;
          if (oldIndex >= 0 && oldIndex < _tracks.length && _tracks.isNotEmpty) {
            final maxIdx = _tracks.length - 1;
            final destIndex = newIndex < 0 ? 0 : (newIndex > maxIdx ? maxIdx : newIndex);
            setState(() {
              final item = _tracks.removeAt(oldIndex);

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
          final track = effectiveTracks[index];
          final shouldAnimateInsert =
              _animatedInsertUids.contains(track.id);
          final shouldAnimateSlideDown =
              _slideDownUids.contains(track.id);
          final isClearingRow = _clearingUids.contains(track.id);
          final isTappedRow = _tappedTrackUid == track.id;

          final itemKey = shouldAnimateSlideDown
              ? ValueKey('track_${_sheetSessionId}_slidedown_${track.id}_$index')
              : ValueKey('track_${_sheetSessionId}_${track.id}_$index');

          return QueueTrackRow(
            key: itemKey,
            title: track.title,
            artist: track.artist,
            isQueued: track.isQueued,
            imageUrl: track.imageUrl,
            songId: track.songId,
            index: index,
            animateInsert: shouldAnimateInsert,
            animateSlideDown: shouldAnimateSlideDown,
            isClearing: isClearingRow,
            isTappedPlaying: isTappedRow,
            onTap: () => _handleTrackTapped(track),
            onRemove: () {
              if (_tapTransitionTracks != null || _clearingUids.isNotEmpty || _isClearingQueue) return;
              setState(() {
                if (index >= 0 && index < _tracks.length && _tracks[index].id == track.id) {
                  _tracks.removeAt(index);
                } else {
                  final removeIndex = _tracks.indexWhere((t) => t.id == track.id);
                  if (removeIndex != -1) {
                    _tracks.removeAt(removeIndex);
                  }
                }
              });
              widget.onTrackRemoved?.call(track);
            },
            onAddToQueue: () {
              if (_tapTransitionTracks != null || _clearingUids.isNotEmpty || _isClearingQueue) return;
              widget.onAddToQueue?.call(track);
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
          final lerped = Color.lerp(
            PlayerColors.background,
            const Color(0xFF262626),
            t,
          );
          final bgColor = switch (lerped) {
            final color? => color,
            null => const Color(0xFF262626),
          };

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
              'Add songs to your queue using swipe gestures or search for tracks to play next.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.60),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (widget.onResetQueue != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
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
