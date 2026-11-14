library;

import 'package:flutter/foundation.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_state.dart';
import 'package:musify_mu/features/player/data/queue/context_track_extensions.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/presentation/widgets/queue_controls_layout.dart';

/// Explicit state machine representing the transport and stream readiness phase
/// of the Now Playing track.
enum NowPlayingTransportPhase {
  paused,
  playing,
  bufferingUnplayedSegment,
}

/// Strongly-typed, immutable view model representing the complete visual state of
/// Spotify's Now Playing View (NPV). Matches Spotify Android `com.spotify.nowplaying`
/// Component-Model architecture.
@immutable
class NowPlayingViewModel {
  final String trackUri;
  final String trackId;
  final String title;
  final String artist;
  final String album;
  final String? imageUrl;
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final NowPlayingTransportPhase transportPhase;
  final bool isFavorite;
  final QueueShuffleMode shuffleMode;
  final QueueRepeatMode repeatMode;
  final String artistUri;
  final bool canSeek;
  final bool canSkipNext;
  final bool canSkipPrev;

  const NowPlayingViewModel({
    required this.trackUri,
    required this.trackId,
    required this.title,
    required this.artist,
    required this.album,
    this.imageUrl,
    required this.duration,
    required this.position,
    required this.isPlaying,
    this.transportPhase = NowPlayingTransportPhase.paused,
    this.isFavorite = false,
    this.shuffleMode = QueueShuffleMode.none,
    this.repeatMode = QueueRepeatMode.none,
    this.artistUri = '',
    this.canSeek = true,
    this.canSkipNext = true,
    this.canSkipPrev = true,
  });

  /// URI prefixes that must never trigger ScrollSita or lyrics network fetches.
  /// Matches Spotify's wi21.java blocklist + ock1.m68144T episode filter.
  static const List<String> nonMusicUriPrefixes = [
    'spotify:ad:',
    'spotify:interruption:',
    'spotify:delimiter',
    'spotify:local:',
    'spotify:meta:',
    'spotify:episode:',
    'spotify:podcast-chapter:',
    'spotify:clip:',
  ];

  static String extractTrackId(ContextTrack? track) {
    if (track != null && track.uri.isNotEmpty) {
      for (final prefix in nonMusicUriPrefixes) {
        if (track.uri.startsWith(prefix)) return '';
      }
      if (track.uri.startsWith('spotify:track:')) {
        return track.uri.substring('spotify:track:'.length);
      }
      return track.uri;
    }
    return '';
  }

  factory NowPlayingViewModel.fromPlayerQueueState(
    PlayerQueueState? state, {
    ContextTrack? fallbackTrack,
    String? fallbackTitle,
    String? fallbackArtist,
    String? fallbackAlbum,
    Duration? fallbackDuration,
    String? fallbackImageUrl,
  }) {
    final track = switch (state?.nowPlaying) {
      final t? => t,
      null => switch (state?.currentTrack) {
        final t? => t,
        null => fallbackTrack,
      },
    };

    final isVaultMasked = track?.metadata['musify_vault_masked'] == 'true' ||
        state?.nowPlaying?.metadata['musify_vault_masked'] == 'true';

    final title = switch (track?.title) {
      final t? when t.isNotEmpty => t,
      _ => switch (state?.title) {
          final t? when t.isNotEmpty => t,
          _ => isVaultMasked
              ? ''
              : switch (fallbackTitle) {
                  final t? when t.isNotEmpty => t,
                  _ => '',
                },
        },
    };

    final artist = switch (track?.artist) {
      final a? when a.isNotEmpty => a,
      _ => switch (state?.artist) {
          final a? when a.isNotEmpty => a,
          _ => isVaultMasked
              ? ''
              : switch (fallbackArtist) {
                  final a? when a.isNotEmpty => a,
                  _ => '',
                },
        },
    };

    final album = switch (track?.album) {
      final a? when a.isNotEmpty => a,
      _ => switch (state?.album) {
          final a? when a.isNotEmpty => a,
          _ => isVaultMasked
              ? ''
              : switch (fallbackAlbum) {
                  final a? when a.isNotEmpty => a,
                  _ => '',
                },
        },
    };

    final duration = switch (state) {
      final q? when q.durationMs > 0 => q.currentDuration,
      _ => switch (track?.duration) {
          final dur? => dur,
          null => switch (fallbackDuration) {
              final dur? => dur,
              null => Duration.zero,
            },
        },
    };

    final imageUrl = isVaultMasked
        ? null
        : switch (track?.imageUrl) {
            final url? when url.isNotEmpty => url,
            _ => switch (state?.imageUrl) {
                final url? when url.isNotEmpty => url,
                _ => fallbackImageUrl,
              },
          };

    final isPlaying = switch (state?.isPlaying) {
      final playing? => playing,
      null => false,
    };

    final transportPhase = switch (state) {
      final q? when q.isBuffering =>
        NowPlayingTransportPhase.bufferingUnplayedSegment,
      final q? when q.isPlaying => NowPlayingTransportPhase.playing,
      _ => NowPlayingTransportPhase.paused,
    };

    final shuffleMode = switch (state?.isShuffling) {
      true => QueueShuffleMode.all,
      false => QueueShuffleMode.none,
      null => QueueShuffleMode.none,
    };

    final repeatMode = switch (state) {
      final q? when q.repeatTrack => QueueRepeatMode.one,
      final q? when q.repeatContext => QueueRepeatMode.all,
      _ => QueueRepeatMode.none,
    };

    final trackUri = switch (track?.uri) {
      final uri? when uri.isNotEmpty => uri,
      _ => '',
    };

    final artistUri = switch (track?.metadata[ContextTrackMetadata.keyArtistUri]) {
      final uri? => uri,
      null => '',
    };

    final trackId = extractTrackId(track);

    final canSkipNext = switch (state?.canSkipNext) {
      final can? => can,
      null => true,
    };
    final canSkipPrev = switch (state?.canSkipPrevious) {
      final can? => can,
      null => true,
    };

    return NowPlayingViewModel(
      trackUri: trackUri,
      trackId: trackId,
      title: title,
      artist: artist,
      album: album,
      imageUrl: imageUrl,
      duration: duration,
      position: switch (state?.currentPosition) {
        final pos? => pos,
        null => Duration.zero,
      },
      isPlaying: isPlaying,
      transportPhase: transportPhase,
      isFavorite: false,
      shuffleMode: shuffleMode,
      repeatMode: repeatMode,
      artistUri: artistUri,
      canSeek: true,
      canSkipNext: canSkipNext,
      canSkipPrev: canSkipPrev,
    );
  }

  NowPlayingViewModel copyWith({
    String? trackUri,
    String? trackId,
    String? title,
    String? artist,
    String? album,
    String? imageUrl,
    Duration? duration,
    Duration? position,
    bool? isPlaying,
    NowPlayingTransportPhase? transportPhase,
    bool? isFavorite,
    QueueShuffleMode? shuffleMode,
    QueueRepeatMode? repeatMode,
    String? artistUri,
    bool? canSeek,
    bool? canSkipNext,
    bool? canSkipPrev,
  }) {
    return NowPlayingViewModel(
      trackUri: switch (trackUri) {
        final u? => u,
        null => this.trackUri,
      },
      trackId: switch (trackId) {
        final id? => id,
        null => this.trackId,
      },
      title: switch (title) {
        final t? => t,
        null => this.title,
      },
      artist: switch (artist) {
        final a? => a,
        null => this.artist,
      },
      album: switch (album) {
        final al? => al,
        null => this.album,
      },
      imageUrl: switch (imageUrl) {
        final img? => img,
        null => this.imageUrl,
      },
      duration: switch (duration) {
        final d? => d,
        null => this.duration,
      },
      position: switch (position) {
        final p? => p,
        null => this.position,
      },
      isPlaying: switch (isPlaying) {
        final p? => p,
        null => this.isPlaying,
      },
      transportPhase: switch (transportPhase) {
        final tp? => tp,
        null => this.transportPhase,
      },
      isFavorite: switch (isFavorite) {
        final f? => f,
        null => this.isFavorite,
      },
      shuffleMode: switch (shuffleMode) {
        final s? => s,
        null => this.shuffleMode,
      },
      repeatMode: switch (repeatMode) {
        final r? => r,
        null => this.repeatMode,
      },
      artistUri: switch (artistUri) {
        final a? => a,
        null => this.artistUri,
      },
      canSeek: switch (canSeek) {
        final c? => c,
        null => this.canSeek,
      },
      canSkipNext: switch (canSkipNext) {
        final c? => c,
        null => this.canSkipNext,
      },
      canSkipPrev: switch (canSkipPrev) {
        final c? => c,
        null => this.canSkipPrev,
      },
    );
  }
}
