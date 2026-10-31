library;

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import '../../../../core/audio/musify_native_audio_engine.dart';
import '../../data/queue/context_track_extensions.dart';
import '../../data/queue/queue_add_handler.dart';
import '../../data/queue/queue_helpers.dart';
import '../../domain/models/context_track.dart';
import '../../domain/models/player_options.dart';
import '../../domain/models/player_queue.dart';
import '../../../../core/media/extended_metadata_service.dart';
import 'esperanto_transport.dart';
import 'proto/spotify_esperanto_proto.dart' as proto;
import '../services/spotify_head_resolver.dart';
import '../services/spotify_license_resolver.dart';
import '../services/spotify_storage_resolver.dart';
import '../../../../core/network/spotify/auth/auth_session_provider.dart';
import '../../../../core/network/spotify/auth/spotify_client_token.dart';
import 'queue_proto_mappers.dart';

/// Active Esperanto transport implementation backed by the native C++ audio engine.
///
/// Replaces InMemoryEsperantoTransport in the DI container. All Esperanto RPC
/// methods are intercepted and routed to MusifyNativeAudioEngine FFI calls.
///
/// State emission: polls the native engine and emits protobuf-binary ContextPlayerState
/// updates on state transitions, track completions, and periodic drift-correction ticks.
/// High-frequency telemetry is decoupled from structural domain state to prevent UI jank.
class NativeEsperantoTransport implements EsperantoTransport {
  final MusifyNativeAudioEngine _engine;
  final ExtendedMetadataService? _metadataService;
  final SpotifyStorageResolver? _storageResolver;
  final SpotifyLicenseResolver? _licenseResolver;
  final AuthSessionProvider? _authSessionProvider;
  final SpotifyClientTokenFetcher? _clientTokenFetcher;

  /// Internal state tracking for change-detection on polling.
  NativeEngineState _lastPolledState = NativeEngineState.idle;
  int _lastPolledPositionMs = 0;
  int _lastStateEmitTimeMs = 0;

  /// Track whether playback is explicitly active from user intent.
  bool _isExplicitlyPlaying = false;

  /// The currently active context URI and metadata (e.g. spotify:playlist:...).
  String _currentContextUri = '';
  Map<String, String> _currentContextMetadata = const {};

  /// Cached last emitted protobuf binary states for replay on new stream subscriptions.
  Uint8List? _lastStateBytes;
  Uint8List? _lastQueueBytes;

  /// The currently active track (set when Play is called).
  ContextTrack? _currentTrack;

  /// The current queue managed locally (mirrors Spotify queue contract).
  PlayerQueue _currentQueue = PlayerQueue.empty;

  /// Original sequentially ordered context tracks before shuffling
  List<ContextTrack> _originalContextTracks = const [];

  /// 1:1 Native ContextProcessor instance (backed by C++ libmusify_audio.so)
  NativeContextProcessor? _contextProcessor;
  int _currentIteration = 0;
  int _loadedContextOffset = 0;

  static const int kDefaultContextPageSize = 30;
  static const int kPageLookaheadThreshold = 3;

  /// Playback options (shuffle, repeat) managed locally.
  PlayerOptions _currentOptions = const PlayerOptions();

  /// Stream controllers for Esperanto subscription endpoints.
  final StreamController<Uint8List> _stateController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _queueController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _errorController =
      StreamController<Uint8List>.broadcast();

  /// Polling timer for engine state transitions and EOS detection.
  Timer? _pollTimer;

  /// Debounce timer for secondary stream and DRM resolution on track change.
  Timer? _secondaryStreamDebounceTimer;

  void _cancelSecondaryStreamDebounce() {
    _secondaryStreamDebounceTimer?.cancel();
    _secondaryStreamDebounceTimer = null;
  }

  NativeEsperantoTransport(
    this._engine, {
    ExtendedMetadataService? metadataService,
    SpotifyStorageResolver? storageResolver,
    SpotifyLicenseResolver? licenseResolver,
    AuthSessionProvider? authSessionProvider,
    SpotifyClientTokenFetcher? clientTokenFetcher,
  })  : _metadataService = metadataService,
        _storageResolver = storageResolver,
        _licenseResolver = licenseResolver,
        _authSessionProvider = authSessionProvider,
        _clientTokenFetcher = clientTokenFetcher {
    _startPolling();
    _emitQueueUpdate();
    _emitPlayerState();
    // Pre-warm head cache directory so it's ready before first playback
    unawaited(SpotifyHeadResolver.instance.getCacheParentDirectory());
  }

  // -----------------------------------------------------------------------
  // EsperantoTransport interface
  // -----------------------------------------------------------------------

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    return _handleCommand(method, payload);
  }

  @override
  Stream<Uint8List> callStream(
    String service,
    String method,
    Uint8List payload,
  ) {
    if (method == 'GetState') {
      return _createReplayingStream(_stateController.stream, () => _lastStateBytes);
    }
    if (method == 'GetQueue') {
      return _createReplayingStream(_queueController.stream, () => _lastQueueBytes);
    }
    if (method == 'GetError') return _errorController.stream;
    return const Stream<Uint8List>.empty();
  }

  Stream<Uint8List> _createReplayingStream(
    Stream<Uint8List> source,
    Uint8List? Function() getLatest,
  ) async* {
    final latest = getLatest();
    if (latest != null) {
      yield latest;
    }
    yield* source;
  }

  @override
  Uint8List callSync(
    String service,
    String method,
    Uint8List payload,
  ) {
    return Uint8List(0);
  }

  // -----------------------------------------------------------------------
  // Command dispatch
  // -----------------------------------------------------------------------

  Future<Uint8List> _handleCommand(String method, Uint8List payload) async {
    switch (method) {
      case 'Play':
        return await _handlePlay(payload);
      case 'Pause':
        return _handlePause();
      case 'Resume':
        return _handleResume();
      case 'Stop':
        return _handleStop();
      case 'SeekTo':
        return _handleSeekTo(payload);
      case 'SkipNext':
        return await _handleSkipNext(payload);
      case 'SkipPrev':
        return await _handleSkipPrev(payload);
      case 'SetOptions':
        return _handleSetOptions(payload);
      case 'SetShufflingContext':
        return _handleSetShufflingContext(payload);
      case 'SetRepeatingContext':
        return _handleSetRepeatingContext(payload);
      case 'SetRepeatingTrack':
        return _handleSetRepeatingTrack(payload);
      case 'AddToQueue':
        return _handleAddToQueue(payload);
      case 'SetQueue':
        return _handleSetQueue(payload);
      case 'PlayAsNextInQueue':
        return _handlePlayAsNextInQueue(payload);
      case 'PreparePlay':
        return _handlePreparePlay(payload);
      case 'PlaySession':
        return _handlePlaySession(payload);
      case 'UpdateContext':
        return _handleUpdateContext(payload);
      case 'UpdateTrack':
        return _handleUpdateTrack(payload);
      case 'UpdatePage':
        return _handleUpdatePage(payload);
      case 'UpdateViewUri':
        return _handleUpdateViewUri(payload);
      case 'Signal':
        return _handleSignal(payload);
      case 'SetSleepTimer':
        return _handleSetSleepTimer(payload);
      default:
        return Uint8List(0);
    }
  }

  Future<Uint8List> _handlePlay(Uint8List payload) async {
    ContextTrack? trackToPlay;
    final List<ContextTrack> contextTracks = [];
    String? skipToUri;
    String? skipToUid;
    int? skipToIndex;
    String contextUri = '';
    Map<String, String> contextMetadata = {};

    if (payload.isNotEmpty) {
      // 1. Try Protobuf decoding
      try {
        final req = proto.PlayRequest.fromBuffer(payload);
        if (req.hasPreparePlayRequest()) {
          final prep = req.preparePlayRequest;
          if (prep.hasContext()) {
            final ctx = prep.context;
            contextUri = ctx.uri;
            contextMetadata = Map<String, String>.from(ctx.metadata);
            for (final page in ctx.pages) {
              for (final protoTrack in page.tracks) {
                contextTracks.add(ContextTrack(
                  uri: protoTrack.uri,
                  uid: protoTrack.uid,
                  metadata: Map<String, String>.from(protoTrack.metadata),
                ));
              }
            }
          }
          if (prep.hasOptions()) {
            if (prep.options.hasSkipTo()) {
              final st = prep.options.skipTo;
              if (st.hasTrackUri() && st.trackUri.isNotEmpty) skipToUri = st.trackUri;
              if (st.hasTrackUid() && st.trackUid.isNotEmpty) skipToUid = st.trackUid;
              if (st.hasTrackIndex() && st.trackIndex.hasValue()) {
                skipToIndex = st.trackIndex.value.toInt();
              }
            }
            if (prep.options.hasPlayerOptionsOverride()) {
              final override = prep.options.playerOptionsOverride;
              if (override.hasShufflingContext()) {
                _currentOptions = _currentOptions.toBuilder()
                    .shufflingContext(override.shufflingContext.value)
                    .build();
              }
              if (override.hasRepeatingContext()) {
                _currentOptions = _currentOptions.toBuilder()
                    .repeatingContext(override.repeatingContext.value)
                    .build();
              }
            }
          }
        }
      } catch (_) {
        // 2. Try JSON decoding
        try {
          final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
          if (json.containsKey('prepare_play_request')) {
            final prep = json['prepare_play_request'] as Map<String, dynamic>;
            if (prep.containsKey('context')) {
              final ctx = prep['context'] as Map<String, dynamic>;
              contextUri = ctx['uri'] as String? ?? '';
              final meta = ctx['metadata'] as Map?;
              if (meta != null) {
                contextMetadata = meta.map((k, v) => MapEntry(k.toString(), v.toString()));
              }
              final pages = ctx['pages'] as List? ?? const [];
              for (final page in pages) {
                if (page is Map && page.containsKey('tracks')) {
                  final tracksList = page['tracks'] as List? ?? const [];
                  for (final item in tracksList) {
                    if (item is Map) {
                      final itemMap = item as Map<String, dynamic>;
                      final metaMap = (itemMap['metadata'] as Map?)?.map(
                            (k, v) => MapEntry(k.toString(), v.toString()),
                          ) ??
                          <String, String>{};
                      contextTracks.add(ContextTrack(
                        uri: itemMap['uri'] as String? ?? '',
                        uid: itemMap['uid'] as String? ?? '',
                        metadata: metaMap,
                      ));
                    }
                  }
                }
              }
            }
            if (prep.containsKey('options')) {
              final opts = prep['options'] as Map<String, dynamic>;
              if (opts.containsKey('skip_to')) {
                final st = opts['skip_to'] as Map<String, dynamic>;
                skipToUri = st['track_uri'] as String?;
                skipToUid = st['track_uid'] as String?;
                if (st.containsKey('track_index')) {
                  final ti = st['track_index'];
                  if (ti is Map && ti.containsKey('value')) {
                    skipToIndex = (ti['value'] as num).toInt();
                  } else if (ti is num) {
                    skipToIndex = ti.toInt();
                  }
                }
              }
              if (opts.containsKey('player_options_override')) {
                final override = opts['player_options_override'] as Map<String, dynamic>;
                if (override.containsKey('shuffling_context')) {
                  final sh = override['shuffling_context'];
                  final bool val = (sh is Map && sh.containsKey('value'))
                      ? (sh['value'] as bool? ?? false)
                      : (sh is bool ? sh : false);
                  _currentOptions = _currentOptions.toBuilder().shufflingContext(val).build();
                }
                if (override.containsKey('repeating_context')) {
                  final rep = override['repeating_context'];
                  final bool val = (rep is Map && rep.containsKey('value'))
                      ? (rep['value'] as bool? ?? false)
                      : (rep is bool ? rep : false);
                  _currentOptions = _currentOptions.toBuilder().repeatingContext(val).build();
                }
              }
            }
          }
        } catch (_) {}
      }
    }

    if (contextUri.isNotEmpty) {
      _currentContextUri = contextUri;
      _currentContextMetadata = contextMetadata;
    }

    if (contextTracks.isNotEmpty) {
      _originalContextTracks = List<ContextTrack>.from(contextTracks);
      _currentIteration = 0;

      int activeIndex = 0;
      if (skipToIndex != null && skipToIndex >= 0 && skipToIndex < contextTracks.length) {
        activeIndex = skipToIndex;
      } else if (skipToUid != null && skipToUid.isNotEmpty) {
        final idx = contextTracks.indexWhere((t) => t.uid == skipToUid);
        if (idx != -1) activeIndex = idx;
      } else if (skipToUri != null && skipToUri.isNotEmpty) {
        final idx = contextTracks.indexWhere((t) => t.uri == skipToUri);
        if (idx != -1) activeIndex = idx;
      }

      trackToPlay = contextTracks[activeIndex];

      // 1:1 Spotify ContextProcessor pagination & delimiter placement
      _loadedContextOffset = math.min(
        activeIndex + 1 + kDefaultContextPageSize,
        contextTracks.length,
      );
      final hasMorePages = _loadedContextOffset < contextTracks.length;
      final pageWindowTracks =
          contextTracks.sublist(activeIndex + 1, _loadedContextOffset);

      final prev = contextTracks
          .sublist(0, activeIndex)
          .reversed
          .toList(growable: false);

      final delimiterTrack = ContextTrack.builder('spotify:delimiter')
          .uid('$_currentIteration')
          .metadata(const {'is_delimiter': 'true'})
          .build();

      final nextWithDelimiter = <ContextTrack>[
        ...pageWindowTracks,
        if (hasMorePages) delimiterTrack,
      ];

      final userQueued =
          _currentQueue.nextTracks.where((t) => t.isQueued).toList(growable: false);

      _currentQueue = _currentQueue
          .toBuilder()
          .track(trackToPlay)
          .prevTracks(prev)
          .nextTracks([...userQueued, ...nextWithDelimiter])
          .build();

      if (_currentOptions.shufflingContext) {
        final remainingContext = List<ContextTrack>.from(pageWindowTracks);
        remainingContext.shuffle();
        _currentQueue = _currentQueue
            .toBuilder()
            .nextTracks([
              ...userQueued,
              ...remainingContext,
              if (hasMorePages) delimiterTrack,
            ])
            .build();
      }

      try {
        _contextProcessor ??= NativeContextProcessor();
        _contextProcessor?.setContext(
          contextUri: contextUri,
          pageUrl: 'context://$contextUri?page=0',
          tracks: contextTracks,
          nextPageUrl: hasMorePages ? 'context://$contextUri?page=1' : '',
          initialIndex: activeIndex,
        );
      } catch (_) {}
    } else if (contextUri.isNotEmpty) {
      if (contextMetadata.isNotEmpty) {
        trackToPlay = ContextTrack.builder(contextUri).metadata(contextMetadata).build();
      } else if (contextUri.startsWith('spotify:track:') || contextUri.startsWith('spotify:local:')) {
        trackToPlay = ContextTrack.create(contextUri);
      }
    }

    trackToPlay ??= _currentQueue.track;

    if (trackToPlay != null) {
      await _playTrack(trackToPlay);
    }

    return Uint8List(0);
  }

  Future<void> _playTrack(ContextTrack track) async {
    _cancelSecondaryStreamDebounce();
    _isExplicitlyPlaying = true;
    _currentTrack = track;

    // Update queue to reflect the new now-playing track immediately
    _currentQueue = _currentQueue.toBuilder().track(track).build();
    _emitQueueUpdate();

    final localPath = track.metadata[ContextTrackMetadata.keyLocalFilePath];
    final previewOgg = track.metadata[ContextTrackMetadata.keyPreviewOggUrl];

    // TTFA fast path: local files skip all network resolution
    if (localPath != null && localPath.isNotEmpty && track.uri.startsWith('spotify:local:')) {
      dev.log(
        'NativeEsperantoTransport: fast-path loadLocal for local track ${track.uri}',
        name: 'NativePlayer',
      );
      final status = _engine.loadLocal(localPath);
      if (status == NativeEngineStatus.ok) {
        _engine.play();
        final handoffStr = track.metadata[ContextTrackMetadata.keyHandoffPositionMs];
        if (handoffStr case final str?) {
          final parsed = int.tryParse(str);
          if (parsed case final validParsed? when validParsed > 0) {
            _engine.seekMs(validParsed);
          }
        }
      } else {
        _emitError('TRACK_UNAVAILABLE', track.uri);
      }
      _emitPlayerState(isBuffering: false);
      return;
    }

    String? fileId = track.metadata[ContextTrackMetadata.keyFileId] ??
        track.metadata['file_id'] ??
        track.metadata['audio.file_id'];
    String? aacFileId = track.metadata[ContextTrackMetadata.keyAacFileId] ??
        track.metadata['aac_file_id'];
    var headUrl = track.metadata[ContextTrackMetadata.keyHeadFileUrl] ??
        track.metadata['head_url'];

    // TTFA fast path: when head file is available, start playback IMMEDIATELY.
    // Check BEFORE JIT metadata resolve — the head only needs fileId + headUrl,
    // NOT aacFileId/duration/cdnUrl. The secondary stream resolver handles those.
    if (fileId != null && fileId.isNotEmpty && headUrl != null && headUrl.isNotEmpty) {
      // Pre-download head file via async Dart HTTP to ensure it's on disk
      // BEFORE the synchronous FFI call. This prevents loadTrackWithHead from
      // blocking the main thread with a network download on cache miss.
      await SpotifyHeadResolver.instance.resolveOrPrefetchHead(fileId);

      final headsCacheParentDir = await SpotifyHeadResolver.instance.getCacheParentDirectory();

      var cdnAac = track.metadata[ContextTrackMetadata.keyCdnAacUrl];
      var licenseUrl = track.metadata[ContextTrackMetadata.keyLicenseServerUrl];

      // Use cdnAac/license/auth only if already cached in metadata — no network waits
      String fullTrackUrl = '';
      if (cdnAac case final validAac? when validAac.isNotEmpty) {
        fullTrackUrl = validAac;
      }
      final cachedLicense = licenseUrl;
      final cachedAuth = track.metadata[ContextTrackMetadata.keyDrmAuthHeader];

      final handoffStr = track.metadata[ContextTrackMetadata.keyHandoffPositionMs];
      int handoffMs = -1;
      if (handoffStr case final str?) {
        final parsed = int.tryParse(str);
        if (parsed case final validParsed?) {
          handoffMs = validParsed;
        }
      }

      int trackDurationMs = -1;
      final metaDurationStr = track.metadata[ContextTrackMetadata.keyDuration];
      if (metaDurationStr != null && metaDurationStr.isNotEmpty) {
        final parsed = int.tryParse(metaDurationStr);
        if (parsed != null && parsed > 0) {
          trackDurationMs = parsed;
        }
      }

      dev.log(
        'NativeEsperantoTransport: TTFA fast-path loadTrackWithHead fileId=$fileId, fullUrl=$fullTrackUrl, cacheDir=$headsCacheParentDir, trackDurationMs=$trackDurationMs',
        name: 'NativePlayer',
      );
      var status = _engine.loadTrackWithHead(
        fileIdHex: fileId,
        fullTrackUrl: fullTrackUrl,
        cacheDir: headsCacheParentDir,
        licenseServerUrl: cachedLicense,
        authHeader: cachedAuth,
        trackDurationMs: trackDurationMs,
      );
      dev.log(
        'NativeEsperantoTransport: loadTrackWithHead returned $status',
        name: 'NativePlayer',
      );
      if (status == NativeEngineStatus.ok) {
        _engine.play();
        if (handoffMs > 0) {
          _engine.seekMs(handoffMs);
        }
        // Resolve full-track CDN stream asynchronously while head chunk plays
        if (fullTrackUrl.isEmpty) {
          _cancelSecondaryStreamDebounce();
          _secondaryStreamDebounceTimer = Timer(const Duration(milliseconds: 50), () {
            if (_currentTrack?.uri == track.uri) {
              _resolveAndAttachSecondaryStream(track, aacFileId);
            }
          });
        }
      } else {
        dev.log(
          'NativeEsperantoTransport: loadTrackWithHead failed ($status), falling through to standard pipeline',
          name: 'NativePlayer',
        );
        await _playTrackStandardPipeline(
          track: track,
          fileId: fileId,
          aacFileId: aacFileId,
          headUrl: headUrl,
          previewOgg: previewOgg,
          localPath: localPath,
        );
        return;
      }
      _emitPlayerState(isBuffering: false);

      // Prefetch next track's head file for seamless transitions
      final nextTrack = _currentQueue.nextTracks.firstOrNull;
      if (nextTrack != null) {
        final nextFileId = nextTrack.metadata[ContextTrackMetadata.keyFileId] ??
            nextTrack.metadata['file_id'];
        final nextHeadUrl = nextTrack.metadata[ContextTrackMetadata.keyHeadFileUrl] ??
            nextTrack.metadata['head_url'];
        if (nextFileId != null && nextFileId.isNotEmpty && nextHeadUrl != null && nextHeadUrl.isNotEmpty) {
          // Dart-side async download ensures head is on disk before next FFI call
          unawaited(SpotifyHeadResolver.instance.resolveOrPrefetchHead(nextFileId));
          _engine.prefetchHead(fileIdHex: nextFileId, cacheDir: headsCacheParentDir);
        }
      }
      return;
    }

    // No head file available — run JIT metadata resolve to populate fileId/headUrl/aacFileId
    final durationMeta = track.metadata[ContextTrackMetadata.keyDuration];
    final bool hasDuration = durationMeta != null && durationMeta.isNotEmpty;
    if ((fileId == null || fileId.isEmpty || aacFileId == null || aacFileId.isEmpty || !hasDuration) &&
        track.uri.startsWith('spotify:track:')) {
      final metadataService = _metadataService;
      if (metadataService != null) {
        try {
          final meta = await metadataService.resolve(track.uri).timeout(const Duration(seconds: 3));
          if (meta case final validMeta? when (validMeta.fileId.isNotEmpty || validMeta.aacFileId.isNotEmpty || validMeta.cdnUrl.isNotEmpty)) {
            fileId = validMeta.fileId;
            headUrl = validMeta.headUrl;
            if (validMeta.aacFileId.isNotEmpty) {
              aacFileId = validMeta.aacFileId;
            }
            final updatedMeta = Map<String, String>.from(track.metadata);
            if (validMeta.fileId.isNotEmpty) {
              updatedMeta[ContextTrackMetadata.keyFileId] = validMeta.fileId;
            } else {
              updatedMeta.remove(ContextTrackMetadata.keyFileId);
            }
            if (validMeta.aacFileId.isNotEmpty) {
              updatedMeta[ContextTrackMetadata.keyAacFileId] = validMeta.aacFileId;
            }
            if (validMeta.headUrl.isNotEmpty) {
              updatedMeta[ContextTrackMetadata.keyHeadFileUrl] = validMeta.headUrl;
            } else {
              updatedMeta.remove(ContextTrackMetadata.keyHeadFileUrl);
            }
            if (validMeta.cdnUrl.isNotEmpty) {
              updatedMeta[ContextTrackMetadata.keyCdnAacUrl] = validMeta.cdnUrl;
            }
            if (validMeta.durationMs > 0) {
              updatedMeta[ContextTrackMetadata.keyDuration] = validMeta.durationMs.toString();
            }
            track = track.toBuilder().metadata(updatedMeta).build();
            _currentTrack = track;
            _currentQueue = _currentQueue.toBuilder().track(track).build();
            _emitQueueUpdate();
          }
        } catch (_) {
          // Fast-fail on JIT network/timeout failure
        }
      }
    }

    // After JIT resolve, try head path again (JIT may have populated fileId+headUrl)
    headUrl = track.metadata[ContextTrackMetadata.keyHeadFileUrl] ?? track.metadata['head_url'];
    fileId = track.metadata[ContextTrackMetadata.keyFileId] ?? track.metadata['file_id'] ?? track.metadata['audio.file_id'];
    aacFileId = track.metadata[ContextTrackMetadata.keyAacFileId] ?? track.metadata['aac_file_id'];
    if (fileId != null && fileId.isNotEmpty && headUrl != null && headUrl.isNotEmpty) {
      await SpotifyHeadResolver.instance.resolveOrPrefetchHead(fileId);
      final headsCacheParentDir = await SpotifyHeadResolver.instance.getCacheParentDirectory();
      var cdnAac = track.metadata[ContextTrackMetadata.keyCdnAacUrl];
      var licenseUrl = track.metadata[ContextTrackMetadata.keyLicenseServerUrl];
      String fullTrackUrl = '';
      if (cdnAac case final validAac? when validAac.isNotEmpty) {
        fullTrackUrl = validAac;
      }

      int trackDurationMs = -1;
      final metaDurationStr = track.metadata[ContextTrackMetadata.keyDuration];
      if (metaDurationStr != null && metaDurationStr.isNotEmpty) {
        final parsed = int.tryParse(metaDurationStr);
        if (parsed != null && parsed > 0) {
          trackDurationMs = parsed;
        }
      }

      final handoffStr = track.metadata[ContextTrackMetadata.keyHandoffPositionMs];
      int handoffMs = -1;
      if (handoffStr case final str?) {
        final parsed = int.tryParse(str);
        if (parsed case final validParsed?) {
          handoffMs = validParsed;
        }
      }

      dev.log(
        'NativeEsperantoTransport: post-JIT loadTrackWithHead fileId=$fileId, fullUrl=$fullTrackUrl, cacheDir=$headsCacheParentDir, trackDurationMs=$trackDurationMs',
        name: 'NativePlayer',
      );
      var status = _engine.loadTrackWithHead(
        fileIdHex: fileId,
        fullTrackUrl: fullTrackUrl,
        cacheDir: headsCacheParentDir,
        licenseServerUrl: licenseUrl,
        authHeader: track.metadata[ContextTrackMetadata.keyDrmAuthHeader],
        trackDurationMs: trackDurationMs,
      );
      if (status == NativeEngineStatus.ok) {
        _engine.play();
        if (handoffMs > 0) {
          _engine.seekMs(handoffMs);
        }
        if (fullTrackUrl.isEmpty) {
          _cancelSecondaryStreamDebounce();
          _secondaryStreamDebounceTimer = Timer(const Duration(milliseconds: 50), () {
            if (_currentTrack?.uri == track.uri) {
              _resolveAndAttachSecondaryStream(track, aacFileId);
            }
          });
        }
        _emitPlayerState(isBuffering: false);

        final nextTrack = _currentQueue.nextTracks.firstOrNull;
        if (nextTrack != null) {
          final nextFileId = nextTrack.metadata[ContextTrackMetadata.keyFileId] ?? nextTrack.metadata['file_id'];
          final nextHeadUrl = nextTrack.metadata[ContextTrackMetadata.keyHeadFileUrl] ?? nextTrack.metadata['head_url'];
          if (nextFileId != null && nextFileId.isNotEmpty && nextHeadUrl != null && nextHeadUrl.isNotEmpty) {
            _engine.prefetchHead(fileIdHex: nextFileId, cacheDir: headsCacheParentDir);
          }
        }
        return;
      }
      // If head load failed after JIT, fall through to standard pipeline
    }

    // Standard pipeline: no head file available, resolve CDN/license/auth before playback
    await _playTrackStandardPipeline(
      track: track,
      fileId: fileId,
      aacFileId: aacFileId,
      headUrl: headUrl,
      previewOgg: previewOgg,
      localPath: localPath,
    );
  }

  /// Standard (non-fast-path) playback pipeline. Used when no head file is available,
  /// or as a fallback when loadTrackWithHead fails. Resolves CDN, license, and auth
  /// before calling loadEncrypted/loadLocal.
  Future<void> _playTrackStandardPipeline({
    required ContextTrack track,
    required String? fileId,
    required String? aacFileId,
    required String? headUrl,
    required String? previewOgg,
    required String? localPath,
  }) async {
    var cdnAac = track.metadata[ContextTrackMetadata.keyCdnAacUrl];
    var licenseUrl = track.metadata[ContextTrackMetadata.keyLicenseServerUrl];

    // Parallelize CDN + license resolution when both are missing
    final needsCdnResolve = (headUrl == null || headUrl.isEmpty) && (cdnAac == null || cdnAac.isEmpty) && aacFileId != null && aacFileId.isNotEmpty;
    final needsLicenseResolve = licenseUrl == null || licenseUrl.isEmpty;

    if (needsCdnResolve && needsLicenseResolve) {
      try {
        dev.log(
          'NativeEsperantoTransport: parallel-resolving CDN + license for MP4 file $aacFileId',
          name: 'NativePlayer',
        );
        final results = await Future.wait([
          _storageResolver?.resolveCdnUrl(aacFileId) ?? Future<String?>.value(null),
          _licenseResolver?.resolveLicenseUrl() ?? Future<String?>.value(null),
        ]);
        final resolvedCdn = results[0];
        final resolvedLicense = results[1];

        if (resolvedCdn != null && resolvedCdn.isNotEmpty) {
          cdnAac = resolvedCdn;
          final updatedMeta = Map<String, String>.from(track.metadata);
          updatedMeta[ContextTrackMetadata.keyCdnAacUrl] = resolvedCdn;
          if (resolvedLicense != null && resolvedLicense.isNotEmpty) {
            updatedMeta[ContextTrackMetadata.keyLicenseServerUrl] = resolvedLicense;
            licenseUrl = resolvedLicense;
          }
          track = track.toBuilder().metadata(updatedMeta).build();
          _currentTrack = track;
          _currentQueue = _currentQueue.toBuilder().track(track).build();
          _emitQueueUpdate();
        } else if (resolvedLicense != null && resolvedLicense.isNotEmpty) {
          licenseUrl = resolvedLicense;
          final updatedMeta = Map<String, String>.from(track.metadata);
          updatedMeta[ContextTrackMetadata.keyLicenseServerUrl] = resolvedLicense;
          track = track.toBuilder().metadata(updatedMeta).build();
          _currentTrack = track;
        }
      } catch (e) {
        dev.log(
          'NativeEsperantoTransport: parallel CDN+license resolve failed: $e',
          name: 'NativePlayer',
        );
      }
    } else if (needsCdnResolve) {
      try {
        dev.log(
          'NativeEsperantoTransport: resolving CDN URL upfront for MP4 file $aacFileId',
          name: 'NativePlayer',
        );
        final resolvedCdn = await _storageResolver?.resolveCdnUrl(aacFileId);
        if (resolvedCdn != null && resolvedCdn.isNotEmpty) {
          cdnAac = resolvedCdn;
          final updatedMeta = Map<String, String>.from(track.metadata);
          updatedMeta[ContextTrackMetadata.keyCdnAacUrl] = resolvedCdn;
          track = track.toBuilder().metadata(updatedMeta).build();
          _currentTrack = track;
          _currentQueue = _currentQueue.toBuilder().track(track).build();
          _emitQueueUpdate();
        }
      } catch (e) {
        dev.log(
          'NativeEsperantoTransport: upfront storage-resolve failed for $aacFileId: $e',
          name: 'NativePlayer',
        );
      }
    } else if (needsLicenseResolve && (cdnAac != null && cdnAac.isNotEmpty)) {
      try {
        final resolvedLicense = await _licenseResolver?.resolveLicenseUrl();
        if (resolvedLicense != null && resolvedLicense.isNotEmpty) {
          licenseUrl = resolvedLicense;
          final updatedMeta = Map<String, String>.from(track.metadata);
          updatedMeta[ContextTrackMetadata.keyLicenseServerUrl] = resolvedLicense;
          track = track.toBuilder().metadata(updatedMeta).build();
          _currentTrack = track;
        }
      } catch (e) {
        dev.log(
          'NativeEsperantoTransport: license-resolve failed: $e',
          name: 'NativePlayer',
        );
      }
    }

    var authHeader = track.metadata[ContextTrackMetadata.keyDrmAuthHeader];
    if (authHeader == null || authHeader.isEmpty) {
      final token = await _authSessionProvider?.getAccessToken();
      final clientToken = await _authSessionProvider?.getClientToken();
      final authHeaderBuffer = StringBuffer();
      if (token != null && token.isNotEmpty) {
        authHeaderBuffer.write('Bearer $token');
      }
      if (clientToken != null && clientToken.isNotEmpty) {
        if (authHeaderBuffer.isNotEmpty) authHeaderBuffer.write('\n');
        authHeaderBuffer.write('client-token: $clientToken');
      }
      if (authHeaderBuffer.isNotEmpty) {
        authHeader = authHeaderBuffer.toString();
      }
    }

    final handoffStr = track.metadata[ContextTrackMetadata.keyHandoffPositionMs];
    int handoffMs = -1;
    if (handoffStr case final str?) {
      final parsed = int.tryParse(str);
      if (parsed case final validParsed?) {
        handoffMs = validParsed;
      }
    }

    final primaryPath = (headUrl != null && headUrl.isNotEmpty)
        ? headUrl
        : ((previewOgg != null && previewOgg.isNotEmpty)
            ? previewOgg
            : localPath);

    final headsCacheParentDir = await SpotifyHeadResolver.instance.getCacheParentDirectory();

    dev.log(
      'NativeEsperantoTransport._playTrackStandard: uri=${track.uri}, fileId=$fileId, headUrl=$headUrl, primaryPath=$primaryPath, cdnAac=$cdnAac, cacheDir=$headsCacheParentDir',
      name: 'NativePlayer',
    );

    if (cdnAac != null && cdnAac.isNotEmpty) {
      // Direct AAC/MP4/pass-through stream (no Vorbis head chunk)
      dev.log(
        'NativeEsperantoTransport: streaming full CDN track directly: $cdnAac',
        name: 'NativePlayer',
      );
      final status = (licenseUrl != null && licenseUrl.isNotEmpty)
          ? _engine.loadEncrypted(
              url: cdnAac,
              licenseServerUrl: licenseUrl,
              authHeader: authHeader,
            )
          : _engine.loadLocal(cdnAac);
      if (status == NativeEngineStatus.ok) {
        _engine.play();
        if (handoffMs > 0) {
          _engine.seekMs(handoffMs);
        }
      } else {
        dev.log(
          'NativeEsperantoTransport: loadEncrypted failed with status $status for ${track.uri}',
          name: 'NativePlayer',
        );
        _clientTokenFetcher?.forceRefreshClientToken();
        _emitError('TRACK_UNAVAILABLE', track.uri);
      }
    } else if (primaryPath != null && primaryPath.isNotEmpty) {
      // Local file or standalone preview audio
      dev.log(
        'NativeEsperantoTransport: calling loadLocal primaryPath=$primaryPath',
        name: 'NativePlayer',
      );
      final status = _engine.loadLocal(primaryPath);
      if (status == NativeEngineStatus.ok) {
        _engine.play();
        if (handoffMs > 0) {
          _engine.seekMs(handoffMs);
        }
      } else {
        _emitError('TRACK_UNAVAILABLE', track.uri);
      }
    } else {
      dev.log(
        'NativeEsperantoTransport: no audio stream found for ${track.uri}',
        name: 'NativePlayer',
      );
      _emitError('TRACK_UNAVAILABLE', track.uri);
    }

    // Prefetch next track's head file natively in C++ for seamless transitions
    final nextTrack = _currentQueue.nextTracks.firstOrNull;
    if (nextTrack != null) {
      final nextFileId = nextTrack.metadata[ContextTrackMetadata.keyFileId] ??
          nextTrack.metadata['file_id'];
      final nextHeadUrl = nextTrack.metadata[ContextTrackMetadata.keyHeadFileUrl] ??
          nextTrack.metadata['head_url'];
      if (nextFileId != null && nextFileId.isNotEmpty && nextHeadUrl != null && nextHeadUrl.isNotEmpty) {
        _engine.prefetchHead(fileIdHex: nextFileId, cacheDir: headsCacheParentDir);
      }
    }

    _emitPlayerState(isBuffering: false);
  }

  void _resolveAndAttachSecondaryStream(ContextTrack track, String? aacFileId) {
    unawaited(() async {
      try {
        String? targetAacId = aacFileId;
        int trackDurationMs = -1;

        final existingDurationStr = track.metadata[ContextTrackMetadata.keyDuration];
        if (existingDurationStr != null && existingDurationStr.isNotEmpty) {
          final parsed = int.tryParse(existingDurationStr);
          if (parsed != null && parsed > 0) {
            trackDurationMs = parsed;
          }
        }

        final canonicalUri = track.metadata['canonical_uri'] ??
            track.metadata[ContextTrackMetadata.keyPointerUri];

        if (targetAacId == null || targetAacId.isEmpty || trackDurationMs <= 0) {
          final resolveUri = (canonicalUri != null && canonicalUri.isNotEmpty) ? canonicalUri : track.uri;
          final meta = await _metadataService?.resolve(resolveUri);
          if (meta != null) {
            if (targetAacId == null || targetAacId.isEmpty) {
              targetAacId = meta.aacFileId;
            }
            if (trackDurationMs <= 0 && meta.durationMs > 0) {
              trackDurationMs = meta.durationMs;
            }
          }
        }

        if (targetAacId == null || targetAacId.isEmpty) {
          dev.log(
            'NativePlayer: No AAC file ID available for secondary stream resolution (${track.uri})',
            name: 'NativePlayer',
          );
          return;
        }

        // Fetch storage resolve CDN URL, Melody license URL, and auth tokens concurrently
        final results = await Future.wait([
          _storageResolver?.resolveCdnUrl(targetAacId) ?? Future<String?>.value(null),
          _licenseResolver?.resolveLicenseUrl() ?? Future<String>.value(''),
          _authSessionProvider?.getAccessToken() ?? Future<String?>.value(null),
          _authSessionProvider?.getClientToken() ?? Future<String?>.value(null),
        ]);

        final cdnUrl = results[0];
        if (cdnUrl == null || cdnUrl.isEmpty) {
          dev.log(
            'NativePlayer: storage-resolve failed for AAC $targetAacId, playback will pause at chunk 0 boundary',
            name: 'NativePlayer',
          );
          return;
        }

        final licenseUrl = results[1];
        final token = results[2];
        final clientToken = results[3];

        final authHeaderBuffer = StringBuffer();
        if (token != null && token.isNotEmpty) {
          authHeaderBuffer.write('Bearer $token');
        }
        if (clientToken != null && clientToken.isNotEmpty) {
          if (authHeaderBuffer.isNotEmpty) authHeaderBuffer.write('\n');
          authHeaderBuffer.write('client-token: $clientToken');
        }
        final authHeader = authHeaderBuffer.isNotEmpty ? authHeaderBuffer.toString() : null;

        // Ensure user hasn't switched away while resolving
        if (_currentTrack?.uri != track.uri) {
          dev.log(
            'NativePlayer: Track changed while resolving secondary stream (${track.uri} -> ${_currentTrack?.uri}), discarding',
            name: 'NativePlayer',
          );
          return;
        }

        dev.log(
          'NativePlayer: Attaching secondary stream: url=$cdnUrl, license=$licenseUrl (hasToken=${token != null}, hasClientToken=${clientToken != null})',
          name: 'NativePlayer',
        );

        final attachStatus = _engine.attachSecondaryStream(
          secondaryUrl: cdnUrl,
          licenseServerUrl: licenseUrl,
          authHeader: authHeader,
          handoffPositionMs: -1,
        );

        dev.log(
          'NativePlayer: attachSecondaryStream returned $attachStatus',
          name: 'NativePlayer',
        );

        if (attachStatus == NativeEngineStatus.ok && _currentTrack != null) {
          final updatedMeta = Map<String, String>.from(_currentTrack!.metadata);
          updatedMeta[ContextTrackMetadata.keyCdnAacUrl] = cdnUrl;
          if (licenseUrl != null && licenseUrl.isNotEmpty) {
            updatedMeta[ContextTrackMetadata.keyLicenseServerUrl] = licenseUrl;
          }
          if (authHeader != null && authHeader.isNotEmpty) {
            updatedMeta[ContextTrackMetadata.keyDrmAuthHeader] = authHeader;
          }
          if (trackDurationMs > 0) {
            updatedMeta[ContextTrackMetadata.keyDuration] = trackDurationMs.toString();
          }
          _currentTrack = _currentTrack!.toBuilder().metadata(updatedMeta).build();
          _currentQueue = _currentQueue.toBuilder().track(_currentTrack!).build();
          _emitQueueUpdate();
          _emitPlayerState();
        }
      } catch (e, st) {
        dev.log(
          'NativePlayer: Error in _resolveAndAttachSecondaryStream: $e',
          name: 'NativePlayer',
          error: e,
          stackTrace: st,
        );
      }
    }());
  }

  Uint8List _handlePause() {
    _cancelSecondaryStreamDebounce();
    _isExplicitlyPlaying = false;
    _engine.pause();
    _emitPlayerState();
    return Uint8List(0);
  }

  Uint8List _handleResume() {
    _isExplicitlyPlaying = true;
    _engine.play();
    _emitPlayerState();
    return Uint8List(0);
  }

  Uint8List _handleStop() {
    _cancelSecondaryStreamDebounce();
    _isExplicitlyPlaying = false;
    _engine.pause();
    _emitPlayerState();
    return Uint8List(0);
  }

  Uint8List _handleSeekTo(Uint8List payload) {
    if (payload.isNotEmpty) {
      try {
        final req = proto.SeekToRequest.fromBuffer(payload);
        _engine.seekMs(req.position.toInt());
      } catch (_) {
        try {
          final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
          if (json.containsKey('position')) {
            _engine.seekMs((json['position'] as num).toInt());
          }
        } catch (_) {}
      }
    }
    _emitPlayerState();
    return Uint8List(0);
  }

  Future<Uint8List> _handleSkipNext([Uint8List? payload]) async {
    ContextTrack? targetTrack;
    if (payload != null && payload.isNotEmpty) {
      try {
        final req = proto.SkipNextRequest.fromBuffer(payload);
        if (req.hasTrack()) {
          targetTrack = QueueProtoMappers.fromContextTrackProto(req.track);
        }
      } catch (_) {
        try {
          final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
          if (json.containsKey('track')) {
            targetTrack = QueueProtoMappers.providedTrackToContextTrack(
              json['track'] as Map<String, dynamic>,
            );
          }
        } catch (_) {}
      }
    }

    final nextTracks = _currentQueue.nextTracks;
    if (nextTracks.isNotEmpty) {
      int targetIndex = 0;
      if (targetTrack case final target?) {
        final found = nextTracks.indexWhere(
          (t) => (t.uid.isNotEmpty && t.uid == target.uid) ||
                 (t.uri.isNotEmpty && t.uri == target.uri),
        );
        if (found != -1) {
          targetIndex = found;
        }
      }

      ContextTrack nextTrack = nextTracks[targetIndex];

      // 1:1 Spotify delimiter handling: if target is delimiter, load next page slice first
      if (nextTrack.isDelimiter()) {
        _loadNextPageSlice();
        final refreshedNext =
            _currentQueue.nextTracks.where((t) => !t.isDelimiter()).toList();
        if (refreshedNext.isNotEmpty) {
          nextTrack = refreshedNext.first;
        } else {
          return Uint8List(0);
        }
      }

      final isTargetQueued = nextTrack.isQueued;

      List<ContextTrack> newNextTracks;
      List<ContextTrack> newPrevTracks;

      // 1:1 Spotify Queue Lifecycle:
      // If _currentTrack was user-queued, it was consumed and does NOT go into prevTracks.
      // Only non-queued context tracks are pushed into prevTracks (playback history).
      final prevHistory = List<ContextTrack>.from(_currentQueue.prevTracks);
      if (_currentTrack case final currentTrack?) {
        if (!currentTrack.isQueued) {
          prevHistory.insert(0, currentTrack);
        }
      }

      if (isTargetQueued) {
        // Target is an explicitly queued track.
        // Preceding queued tracks before targetIndex were skipped and consumed.
        // Remaining tracks after targetIndex (both queued and context) continue as upcoming.
        newNextTracks = nextTracks.sublist(targetIndex + 1);
        newPrevTracks = prevHistory;
      } else {
        // Target is a context track.
        // 1:1 Spotify: All user-queued tracks in nextTracks MUST be preserved at the head of nextTracks!
        final preservedUserQueued =
            nextTracks.where((t) => t.isQueued).toList(growable: false);
        final contextTracks =
            nextTracks.where((t) => !t.isQueued).toList(growable: false);

        final ctxTargetIdx = contextTracks.indexWhere(
          (t) =>
              (t.uid.isNotEmpty && t.uid == nextTrack.uid) ||
              (t.uri.isNotEmpty && t.uri == nextTrack.uri),
        );

        final safeCtxIdx = ctxTargetIdx != -1 ? ctxTargetIdx : 0;
        final skippedContextTracks = contextTracks.sublist(0, safeCtxIdx);
        final remainingContextTracks = contextTracks.sublist(safeCtxIdx + 1);

        newNextTracks = [...preservedUserQueued, ...remainingContextTracks];
        newPrevTracks = [...skippedContextTracks.reversed, ...prevHistory];
      }

      _currentQueue = _currentQueue
          .toBuilder()
          .prevTracks(newPrevTracks)
          .nextTracks(newNextTracks)
          .build();

      // 1:1 Spotify Lookahead Page Preload: If remaining context tracks in nextTracks <= kPageLookaheadThreshold,
      // trigger parseLoadedContextPage for the next chunk ahead of time!
      final remainingContextCount = _currentQueue.nextTracks
          .where((t) => !t.isQueued && !t.isDelimiter())
          .length;
      if (remainingContextCount <= kPageLookaheadThreshold &&
          _loadedContextOffset < _originalContextTracks.length) {
        _loadNextPageSlice();
      }

      await _playTrack(nextTrack);
    } else if (_currentOptions.repeatingContext &&
        _currentQueue.prevTracks.isNotEmpty) {
      await _handleLoopContext();
    }
    return Uint8List(0);
  }

  /// 1:1 Spotify parseLoadedContextPage triggering on page boundary
  void _loadNextPageSlice() {
    if (_loadedContextOffset >= _originalContextTracks.length) return;

    final nextOffset = math.min(
      _loadedContextOffset + kDefaultContextPageSize,
      _originalContextTracks.length,
    );
    final newPageSlice =
        _originalContextTracks.sublist(_loadedContextOffset, nextOffset);
    _loadedContextOffset = nextOffset;
    _currentIteration++;

    final hasMorePages = _loadedContextOffset < _originalContextTracks.length;
    final newDelimiter = ContextTrack.builder('spotify:delimiter')
        .uid('$_currentIteration')
        .metadata(const {'is_delimiter': 'true'})
        .build();

    final existingWithoutDelimiter =
        _currentQueue.nextTracks.where((t) => !t.isDelimiter()).toList();

    _currentQueue = _currentQueue.toBuilder().nextTracks([
      ...existingWithoutDelimiter,
      ...newPageSlice,
      if (hasMorePages) newDelimiter,
    ]).build();

    try {
      _contextProcessor?.parseLoadedContextPage(
        iteration: _currentIteration,
        pageUrl: 'context://$_currentContextUri?page=$_currentIteration',
        tracks: newPageSlice,
        nextPageUrl: hasMorePages
            ? 'context://$_currentContextUri?page=${_currentIteration + 1}'
            : '',
      );
    } catch (_) {}
  }

  Future<Uint8List> _handleSkipPrev([Uint8List? payload]) async {
    final currentPos = _engine.positionMs;
    // 1:1 Spotify: If position > 3 seconds, seek to beginning of current track
    if (currentPos > 3000) {
      _engine.seekMs(0);
      _emitPlayerState();
      return Uint8List(0);
    }

    final prevTracks = _currentQueue.prevTracks;
    if (prevTracks.isNotEmpty) {
      final prevTrack = prevTracks.first;
      final remainingPrev = prevTracks.sublist(1);

      List<ContextTrack> nextTracks;
      if (_currentTrack case final currentTrack?) {
        if (currentTrack.isQueued) {
          nextTracks = [currentTrack, ..._currentQueue.nextTracks];
        } else {
          final userQueued = _currentQueue.nextTracks.where((t) => t.isQueued).toList(growable: false);
          final contextTracks = _currentQueue.nextTracks.where((t) => !t.isQueued).toList(growable: false);
          nextTracks = [...userQueued, currentTrack, ...contextTracks];
        }
      } else {
        nextTracks = _currentQueue.nextTracks;
      }

      _currentQueue = _currentQueue
          .toBuilder()
          .prevTracks(remainingPrev)
          .nextTracks(nextTracks)
          .build();

      await _playTrack(prevTrack);
    } else {
      _engine.seekMs(0);
      _emitPlayerState();
    }
    return Uint8List(0);
  }

  Future<void> _handleLoopContext() async {
    final allTracks = <ContextTrack>[
      ..._currentQueue.prevTracks.reversed,
      ?_currentTrack,
      ..._currentQueue.nextTracks,
    ];

    if (allTracks.isNotEmpty) {
      final firstTrack = allTracks.first;
      final remaining = allTracks.sublist(1);

      _currentQueue = _currentQueue
          .toBuilder()
          .prevTracks(const <ContextTrack>[])
          .nextTracks(remaining)
          .build();

      await _playTrack(firstTrack);
    }
  }

  void _applyShuffling(bool shuffling) {
    _currentOptions = _currentOptions
        .toBuilder()
        .shufflingContext(shuffling)
        .build();

    final userQueue = QueueHelpers.getUserQueuedTracks(_currentQueue);
    final hasMorePages = _loadedContextOffset < _originalContextTracks.length;
    final delimiter = ContextTrack.builder('spotify:delimiter')
        .uid('$_currentIteration')
        .metadata(const {'is_delimiter': 'true'})
        .build();

    if (shuffling) {
      final contextTracks = List<ContextTrack>.from(
          QueueHelpers.getContextTracks(_currentQueue)
              .where((t) => !t.isDelimiter()));
      contextTracks.shuffle();
      _currentQueue = _currentQueue.toBuilder().nextTracks([
        ...userQueue,
        ...contextTracks,
        if (hasMorePages) delimiter,
      ]).build();
    } else {
      // 1:1 Spotify Unshuffle: Restore original context tracks order
      final originalContext = List<ContextTrack>.from(_originalContextTracks);
      final activeTrack = _currentTrack;
      if (originalContext.isNotEmpty && activeTrack != null) {
        final activeIdx = originalContext.indexWhere((t) =>
            (t.uid.isNotEmpty && t.uid == activeTrack.uid) ||
            (t.uri.isNotEmpty && t.uri == activeTrack.uri));
        final List<ContextTrack> remainingContext;
        if (activeIdx != -1 && activeIdx + 1 < originalContext.length) {
          final windowEnd = math.min(
            activeIdx + 1 + kDefaultContextPageSize,
            originalContext.length,
          );
          remainingContext = originalContext.sublist(activeIdx + 1, windowEnd);
        } else {
          final playedUids =
              _currentQueue.prevTracks.map((p) => p.uid).toSet();
          remainingContext = originalContext
              .where((t) =>
                  t.uid != activeTrack.uid && !playedUids.contains(t.uid))
              .take(kDefaultContextPageSize)
              .toList();
        }
        _currentQueue = _currentQueue.toBuilder().nextTracks([
          ...userQueue,
          ...remainingContext,
          if (hasMorePages) delimiter,
        ]).build();
      } else {
        final currentContext = QueueHelpers.getContextTracks(_currentQueue)
            .where((t) => !t.isDelimiter())
            .toList();
        _currentQueue = _currentQueue.toBuilder().nextTracks([
          ...userQueue,
          ...currentContext,
          if (hasMorePages) delimiter,
        ]).build();
      }
    }

    try {
      _contextProcessor?.setShuffling(shuffling);
    } catch (_) {}

    _emitQueueUpdate();
    _emitPlayerState();
  }

  Uint8List _handleSetOptions(Uint8List payload) {
    final optBuilder = _currentOptions.toBuilder();
    bool updated = false;
    bool? shuffleChanged;

    try {
      final req = proto.SetOptionsRequest.fromBuffer(payload);
      if (req.hasShufflingContext()) {
        optBuilder.shufflingContext(req.shufflingContext.value);
        shuffleChanged = req.shufflingContext.value;
        updated = true;
      }
      if (req.hasRepeatingContext()) {
        optBuilder.repeatingContext(req.repeatingContext.value);
        updated = true;
      }
      if (req.hasRepeatingTrack()) {
        optBuilder.repeatingTrack(req.repeatingTrack.value);
        updated = true;
      }
    } catch (_) {
      if (payload.isNotEmpty) {
        try {
          final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
          if (json.containsKey('shuffling_context')) {
            final sc = json['shuffling_context'];
            final bool val = (sc is Map && sc.containsKey('value'))
                ? (sc['value'] as bool)
                : (sc as bool);
            optBuilder.shufflingContext(val);
            shuffleChanged = val;
            updated = true;
          }
          if (json.containsKey('repeating_context')) {
            final rc = json['repeating_context'];
            final bool val = (rc is Map && rc.containsKey('value'))
                ? (rc['value'] as bool)
                : (rc as bool);
            optBuilder.repeatingContext(val);
            updated = true;
          }
          if (json.containsKey('repeating_track')) {
            final rt = json['repeating_track'];
            final bool val = (rt is Map && rt.containsKey('value'))
                ? (rt['value'] as bool)
                : (rt as bool);
            optBuilder.repeatingTrack(val);
            updated = true;
          }
        } catch (_) {}
      }
    }

    if (updated) {
      _currentOptions = optBuilder.build();
      if (shuffleChanged != null) {
        _applyShuffling(shuffleChanged);
      } else {
        _emitPlayerState();
      }
    }
    return Uint8List(0);
  }

  Uint8List _handleSetShufflingContext(Uint8List payload) {
    bool shuffling = false;
    try {
      final req = proto.SetShufflingContextRequest.fromBuffer(payload);
      shuffling = req.shufflingContext;
    } catch (_) {
      if (payload.isNotEmpty) {
        try {
          final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
          if (json.containsKey('shuffling_context')) {
            final sc = json['shuffling_context'];
            shuffling = (sc is Map && sc.containsKey('value'))
                ? (sc['value'] as bool)
                : (sc as bool);
          }
        } catch (_) {}
      }
    }

    _applyShuffling(shuffling);
    return Uint8List(0);
  }

  Uint8List _handleSetRepeatingContext(Uint8List payload) {
    bool repeating = false;
    try {
      final req = proto.SetRepeatingContextRequest.fromBuffer(payload);
      repeating = req.repeatingContext;
    } catch (_) {
      if (payload.isNotEmpty) {
        try {
          final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
          if (json.containsKey('repeating_context')) {
            final rc = json['repeating_context'];
            repeating = (rc is Map && rc.containsKey('value'))
                ? (rc['value'] as bool)
                : (rc as bool);
          }
        } catch (_) {}
      }
    }

    _currentOptions = _currentOptions
        .toBuilder()
        .repeatingContext(repeating)
        .build();
    _emitPlayerState();
    return Uint8List(0);
  }

  Uint8List _handleSetRepeatingTrack(Uint8List payload) {
    bool repeating = false;
    try {
      final req = proto.SetRepeatingTrackRequest.fromBuffer(payload);
      repeating = req.repeatingTrack;
    } catch (_) {
      if (payload.isNotEmpty) {
        try {
          final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
          if (json.containsKey('repeating_track')) {
            final rt = json['repeating_track'];
            repeating = (rt is Map && rt.containsKey('value'))
                ? (rt['value'] as bool)
                : (rt as bool);
          }
        } catch (_) {}
      }
    }

    _currentOptions = _currentOptions
        .toBuilder()
        .repeatingTrack(repeating)
        .build();
    _emitPlayerState();
    return Uint8List(0);
  }

  Uint8List _handleAddToQueue(Uint8List payload) {
    if (payload.isNotEmpty) {
      ContextTrack? track;
      try {
        final req = proto.AddToQueueRequest.fromBuffer(payload);
        final meta = Map<String, String>.from(req.track.metadata);
        meta[ContextTrackMetadata.keyIsQueued] = 'true';
        track = ContextTrack(
          uri: req.track.uri,
          uid: req.track.uid.isNotEmpty
              ? req.track.uid
              : 'queued_${DateTime.now().microsecondsSinceEpoch}',
          metadata: meta,
        );
      } catch (_) {
        try {
          final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
          if (json.containsKey('track')) {
            final t = json['track'] as Map<String, dynamic>;
            final meta = (t['metadata'] as Map?)?.map(
                  (k, v) => MapEntry(k.toString(), v.toString()),
                ) ??
                <String, String>{};
            meta[ContextTrackMetadata.keyIsQueued] = 'true';
            track = ContextTrack(
              uri: t['uri'] as String? ?? '',
              uid: t['uid'] as String? ??
                  'queued_${DateTime.now().microsecondsSinceEpoch}',
              metadata: meta,
            );
          }
        } catch (_) {}
      }

      if (track != null) {
        _currentQueue = QueueAddHandler.addTracks(
          _currentQueue,
          [track],
          mode: QueueInsertMode.addToEndOfQueue,
        );
        _emitQueueUpdate();
        _emitPlayerState();
      }
    }
    return Uint8List(0);
  }

  Uint8List _handleSetQueue(Uint8List payload) {
    if (payload.isNotEmpty) {
      try {
        final req = proto.SetQueueRequest.fromBuffer(payload);
        final nextTracks = req.nextTracks
            .map(QueueProtoMappers.fromProvidedTrackProto)
            .toList();
        final prevTracks = req.prevTracks
            .map(QueueProtoMappers.fromProvidedTrackProto)
            .toList();

        _currentQueue = _currentQueue
            .toBuilder()
            .revision(req.queueRevision.toString())
            .prevTracks(prevTracks)
            .nextTracks(nextTracks)
            .build();
        _emitQueueUpdate();
        _emitPlayerState();
      } catch (_) {
        try {
          final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
          final nextList = json['next_tracks'] as List? ?? const [];
          final prevList = json['prev_tracks'] as List? ?? const [];

          final nextTracks = nextList
              .map((item) => QueueProtoMappers.providedTrackToContextTrack(
                  item as Map<String, dynamic>))
              .toList();
          final prevTracks = prevList
              .map((item) => QueueProtoMappers.providedTrackToContextTrack(
                  item as Map<String, dynamic>))
              .toList();

          _currentQueue = _currentQueue
              .toBuilder()
              .revision((json['queue_revision'] ?? '0').toString())
              .prevTracks(prevTracks)
              .nextTracks(nextTracks)
              .build();
          _emitQueueUpdate();
          _emitPlayerState();
        } catch (_) {}
      }
    }
    return Uint8List(0);
  }

  Uint8List _handlePlayAsNextInQueue(Uint8List payload) {
    if (payload.isNotEmpty) {
      try {
        final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
        if (json.containsKey('tracks')) {
          final tracksList = json['tracks'] as List;
          final newTracks = tracksList
              .map((t) => QueueProtoMappers.providedTrackToContextTrack(
                  t as Map<String, dynamic>))
              .map((track) {
                if (track.isQueued) return track;
                final meta = Map<String, String>.from(track.metadata);
                meta[ContextTrackMetadata.keyIsQueued] = 'true';
                return track.toBuilder().metadata(meta).build();
              })
              .toList();

          _currentQueue = QueueAddHandler.addTracks(
            _currentQueue,
            newTracks,
            mode: QueueInsertMode.playNext,
          );
          _emitQueueUpdate();
          _emitPlayerState();
        }
      } catch (_) {}
    }
    return Uint8List(0);
  }

  Uint8List _handlePreparePlay(Uint8List payload) {
    return Uint8List(0);
  }

  Uint8List _handlePlaySession(Uint8List payload) {
    return Uint8List(0);
  }

  Uint8List _handleUpdateContext(Uint8List payload) {
    return Uint8List(0);
  }

  Uint8List _handleUpdateTrack(Uint8List payload) {
    if (payload.isNotEmpty) {
      try {
        final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
        if (json.containsKey('track')) {
          final track = QueueProtoMappers.providedTrackToContextTrack(
              json['track'] as Map<String, dynamic>);
          _currentTrack = track;
          _emitPlayerState();
        }
      } catch (_) {}
    }
    return Uint8List(0);
  }

  Uint8List _handleUpdatePage(Uint8List payload) {
    return Uint8List(0);
  }

  Uint8List _handleUpdateViewUri(Uint8List payload) {
    return Uint8List(0);
  }

  Uint8List _handleSignal(Uint8List payload) {
    return Uint8List(0);
  }

  Uint8List _handleSetSleepTimer(Uint8List payload) {
    return Uint8List(0);
  }

  // -----------------------------------------------------------------------
  // State emission — protobuf binary via ContextPlayerState.writeToBuffer()
  // -----------------------------------------------------------------------

  void _emitPlayerState({bool isBuffering = false}) {
    final engineState = _engine.state;
    final positionMs = _engine.positionMs;
    int durationMs = _engine.durationMs;

    // Resolve track duration: prioritize track metadata duration
    if (_currentTrack?.metadata[ContextTrackMetadata.keyDuration] case final durationStr?
        when durationStr.isNotEmpty) {
      final parsed = int.tryParse(durationStr);
      if (parsed != null && parsed > 0) {
        durationMs = parsed;
      }
    }

    // Default to 0 (Duration.zero) only if duration could not be determined from metadata or engine
    if (durationMs < 0) {
      durationMs = 0;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final bool playing = (engineState == NativeEngineState.playing) ||
        (_isExplicitlyPlaying &&
            engineState != NativeEngineState.paused &&
            engineState != NativeEngineState.stopped);
    final bool paused = !_isExplicitlyPlaying || engineState == NativeEngineState.paused;
    final bool buffering =
        isBuffering || engineState == NativeEngineState.prebuffering;

    // Build ContextPlayerState protobuf message directly
    final stateProto = proto.ContextPlayerState()
      ..timestamp = Int64(nowMs)
      ..contextUri = _currentContextUri
      ..contextUrl = _currentContextUri.isNotEmpty ? 'context://$_currentContextUri' : ''
      ..isPlaying = playing
      ..isPaused = paused
      ..isBuffering = buffering
      ..positionAsOfTimestamp = (proto.OptionalInt64()
        ..value = Int64(positionMs))
      ..duration = (proto.OptionalInt64()
        ..value = Int64(durationMs))
      ..playbackSpeed = (proto.OptionalDouble()
        ..value = playing ? 1.0 : 0.0)
      ..options = (proto.ContextPlayerOptions()
        ..shufflingContext = _currentOptions.shufflingContext
        ..repeatingContext = _currentOptions.repeatingContext
        ..repeatingTrack = _currentOptions.repeatingTrack);

    if (_currentContextMetadata.isNotEmpty) {
      stateProto.contextMetadata.addAll(_currentContextMetadata);
    }

    // Set track as ProvidedTrack (wrapping ContextTrack)
    if (_currentTrack case final currentTrack?) {
      stateProto.track = QueueProtoMappers.toProvidedTrackProto(currentTrack);
    }

    // Set prev/next tracks
    if (_currentQueue.prevTracks.isNotEmpty) {
      stateProto.prevTracks.addAll(
        _currentQueue.prevTracks.map(QueueProtoMappers.toProvidedTrackProto),
      );
    }
    if (_currentQueue.nextTracks.isNotEmpty) {
      stateProto.nextTracks.addAll(
        _currentQueue.nextTracks.map(QueueProtoMappers.toProvidedTrackProto),
      );
    }

    final bytes = Uint8List.fromList(stateProto.writeToBuffer());
    _lastStateBytes = bytes;
    _stateController.add(bytes);
  }

  void _emitQueueUpdate() {
    final queueProto = QueueProtoMappers.toQueueProto(_currentQueue);
    final bytes = Uint8List.fromList(queueProto.writeToBuffer());
    _lastQueueBytes = bytes;
    _queueController.add(bytes);
  }

  void _emitError(String errorType, String trackUri) {
    final errorJson =
        '{"error":"$errorType","track_uri":"$trackUri"}';
    _errorController.add(Uint8List.fromList(errorJson.codeUnits));
  }

  // -----------------------------------------------------------------------
  // Polling loop: detects engine state changes & hardware position ticks
  // -----------------------------------------------------------------------

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _onPollTick();
    });
  }

  void _onPollTick() {
    final currentState = _engine.state;
    final currentPositionMs = _engine.positionMs;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final bool stateChanged = currentState != _lastPolledState;

    // Decouple high-frequency position ticks from structural state emissions.
    // Structural state is emitted on state transitions, track completions,
    // large seek jumps (> 1500ms), or as a 1000ms periodic drift-correction tick.
    final bool driftCorrectionNeeded =
        (currentPositionMs - _lastPolledPositionMs).abs() > 1500 ||
        (nowMs - _lastStateEmitTimeMs) >= 1000;

    if (stateChanged || (currentState == NativeEngineState.playing && driftCorrectionNeeded)) {
      final wasPlaying = _lastPolledState == NativeEngineState.playing;
      _lastPolledState = currentState;
      _lastPolledPositionMs = currentPositionMs;
      _lastStateEmitTimeMs = nowMs;

      _emitPlayerState();

      if (wasPlaying && currentState == NativeEngineState.paused) {
        _isExplicitlyPlaying = false;
      }

      // Detect End-Of-Stream track completion:
      // Engine transitioned from playing to stopped (completed).
      if (wasPlaying && currentState == NativeEngineState.stopped) {
        if (_currentOptions.repeatingTrack) {
          // 1:1 Spotify Repeat Track: seek to 0 and re-play
          _engine.seekMs(0);
          _engine.play();
          _emitPlayerState();
        } else if (_currentQueue.nextTracks.isNotEmpty) {
          // Auto-advance to next track in queue
          unawaited(_handleSkipNext());
        } else if (_currentOptions.repeatingContext &&
            _currentQueue.prevTracks.isNotEmpty) {
          // Repeat Context: wrap around to beginning of queue
          unawaited(_handleLoopContext());
        }
      }
    }
  }

  // -----------------------------------------------------------------------
  // Disposal
  // -----------------------------------------------------------------------

  void dispose() {
    _cancelSecondaryStreamDebounce();
    _pollTimer?.cancel();
    _pollTimer = null;
    _stateController.close();
    _queueController.close();
    _errorController.close();
    _engine.dispose();
  }
}
