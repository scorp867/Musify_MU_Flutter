import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// FFI bindings for libmusify_audio.so.
///
/// `isLeaf: true` is applied ONLY to pre-existing Phase 6/11 bindings with no
/// GC interaction, Dart callbacks, or blocking I/O. Connect port setters
/// (`_connectSet*Port`), client profile setters, and RPC dispatch functions
/// omit `isLeaf` (using `.asFunction()`) to remain safepoint-safe.
///
/// The shared library is loaded lazily only when [instance] is first accessed,
/// keeping host unit tests and mocked environments safe without requiring
/// `libmusify_audio.so` on disk.
class MusifyFfiBindings {
  factory MusifyFfiBindings._open() {
    final library = DynamicLibrary.open(_libName);
    return MusifyFfiBindings._fromLibrary(library);
  }

  @visibleForTesting
  factory MusifyFfiBindings.fromLibrary(DynamicLibrary lib) =>
      MusifyFfiBindings._fromLibrary(lib);

  MusifyFfiBindings._fromLibrary(this.lib)
      : _create = lib
            .lookup<NativeFunction<Pointer<Void> Function()>>(
              'musify_engine_create',
            )
            .asFunction(isLeaf: true),
        _destroy = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
              'musify_engine_destroy',
            )
            .asFunction(isLeaf: true),
        _loadLocal = lib
            .lookup<
                NativeFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>)>>(
              'musify_engine_load_local',
            )
            .asFunction(),
        _loadDualSource = lib
            .lookup<
                NativeFunction<
                    Int32 Function(
                      Pointer<Void>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Int64,
                    )>>('musify_engine_load_dual_source')
            .asFunction(),
        _loadEncrypted = lib
            .lookup<
                NativeFunction<
                    Int32 Function(
                      Pointer<Void>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                    )>>('musify_engine_load_encrypted')
            .asFunction(),
        _attachSecondaryStream = lib
            .lookup<
                NativeFunction<
                    Int32 Function(
                      Pointer<Void>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Int64,
                    )>>('musify_engine_attach_secondary_stream')
            .asFunction(),
        _loadTrackWithHead = lib
            .lookup<
                NativeFunction<
                    Int32 Function(
                      Pointer<Void>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Int64,
                    )>>('musify_engine_load_track_with_head')
            .asFunction(),
        _prefetchHead = lib
            .lookup<
                NativeFunction<
                    Void Function(
                      Pointer<Void>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                    )>>('musify_engine_prefetch_head')
            .asFunction(),
        _setDrmSession = lib
            .lookup<
                NativeFunction<
                    Int32 Function(Pointer<Void>, Pointer<Uint8>, Int32)>>(
              'musify_engine_set_drm_session',
            )
            .asFunction(isLeaf: true),
        _play = lib
            .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
              'musify_engine_play',
            )
            .asFunction(isLeaf: true),
        _pause = lib
            .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
              'musify_engine_pause',
            )
            .asFunction(isLeaf: true),
        _seekMs = lib
            .lookup<NativeFunction<Int32 Function(Pointer<Void>, Int64)>>(
              'musify_engine_seek_ms',
            )
            .asFunction(),
        _stop = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
              'musify_engine_stop',
            )
            .asFunction(isLeaf: true),
        _getPositionMs = lib
            .lookup<NativeFunction<Int64 Function(Pointer<Void>)>>(
              'musify_engine_get_position_ms',
            )
            .asFunction(isLeaf: true),
        _getDurationMs = lib
            .lookup<NativeFunction<Int64 Function(Pointer<Void>)>>(
              'musify_engine_get_duration_ms',
            )
            .asFunction(isLeaf: true),
        _getState = lib
            .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
              'musify_engine_get_state',
            )
            .asFunction(isLeaf: true),
        _getUnderrunCount = lib
            .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
              'musify_engine_get_underrun_count',
            )
            .asFunction(isLeaf: true),
        _isDualSource = lib
            .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
              'musify_engine_is_dual_source',
            )
            .asFunction(isLeaf: true),
        _isHandoffCompleted = lib
            .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
              'musify_engine_is_handoff_completed',
            )
            .asFunction(isLeaf: true),
        _freeString = lib
            .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>(
              'musify_free_string',
            )
            .asFunction(isLeaf: true),
        _freeBytes = lib
            .lookup<NativeFunction<Void Function(Pointer<Uint8>)>>(
              'musify_free_bytes',
            )
            .asFunction(isLeaf: true),
        _setAuthSession = lib
            .lookup<
                NativeFunction<
                    Void Function(
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                    )>>('musify_set_auth_session')
            .asFunction(),
        _setAuthRefreshPort = lib
            .lookup<NativeFunction<Void Function(Int64)>>(
              'musify_set_auth_refresh_port',
            )
            .asFunction(isLeaf: true),
        _setClientProfile = lib
            .lookup<
                NativeFunction<
                    Void Function(
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                      Int32,
                    )>>('musify_set_client_profile')
            .asFunction(),
        _metadataSeedExtension = lib
            .lookup<
                NativeFunction<
                    Void Function(
                      Int32,
                      Pointer<Utf8>,
                      Pointer<Uint8>,
                      Int32,
                    )>>('musify_metadata_seed_extension')
            .asFunction(),
        _cpCreate = lib
            .lookup<NativeFunction<Pointer<Void> Function()>>(
              'musify_context_processor_create',
            )
            .asFunction(isLeaf: true),
        _cpDestroy = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
              'musify_context_processor_destroy',
            )
            .asFunction(isLeaf: true),
        _cpIsDelimiter = lib
            .lookup<NativeFunction<Int32 Function(Pointer<Utf8>)>>(
              'musify_context_processor_is_delimiter',
            )
            .asFunction(isLeaf: true),
        _cpSetContextProto = lib
            .lookup<
                NativeFunction<
                    Int32 Function(
                      Pointer<Void>,
                      Pointer<Utf8>,
                      Pointer<Uint8>,
                      Int32,
                      Int32,
                    )>>('musify_context_processor_set_context_proto')
            .asFunction(),
        _cpParseLoadedPageProto = lib
            .lookup<
                NativeFunction<
                    Int32 Function(
                      Pointer<Void>,
                      Int32,
                      Pointer<Uint8>,
                      Int32,
                    )>>('musify_context_processor_parse_loaded_page_proto')
            .asFunction(),
        _cpGetQueueProto = lib
            .lookup<
                NativeFunction<
                    Pointer<Uint8> Function(
                      Pointer<Void>,
                      Int32,
                      Pointer<Int32>,
                    )>>('musify_context_processor_get_queue_proto')
            .asFunction(),
        _cpSkipNext = lib
            .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
              'musify_context_processor_skip_next',
            )
            .asFunction(isLeaf: true),
        _cpSkipPrev = lib
            .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
              'musify_context_processor_skip_prev',
            )
            .asFunction(isLeaf: true),
        _cpSkipToIndex = lib
            .lookup<NativeFunction<Int32 Function(Pointer<Void>, Int32)>>(
              'musify_context_processor_skip_to_index',
            )
            .asFunction(isLeaf: true),
        _cpSkipToUri = lib
            .lookup<
                NativeFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>)>>(
              'musify_context_processor_skip_to_uri',
            )
            .asFunction(isLeaf: true),
        _cpSkipToUid = lib
            .lookup<
                NativeFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>)>>(
              'musify_context_processor_skip_to_uid',
            )
            .asFunction(isLeaf: true),
        _cpSetShuffling = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>, Int32)>>(
              'musify_context_processor_set_shuffling',
            )
            .asFunction(isLeaf: true),
        _cpIsShuffling = lib
            .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
              'musify_context_processor_is_shuffling',
            )
            .asFunction(isLeaf: true),
        _cpNeedsNextPage = lib
            .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
              'musify_context_processor_needs_next_page',
            )
            .asFunction(isLeaf: true),
        _cpGetNextPageUrl = lib
            .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>)>>(
              'musify_context_processor_get_next_page_url',
            )
            .asFunction(),
        _cpGetCurrentIteration = lib
            .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
              'musify_context_processor_get_current_iteration',
            )
            .asFunction(isLeaf: true),
        _cpGetCurrentIndex = lib
            .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
              'musify_context_processor_get_current_index',
            )
            .asFunction(isLeaf: true),
        _initDartApiDl = lib
            .lookup<NativeFunction<IntPtr Function(Pointer<Void>)>>(
              'musify_init_dart_api_dl',
            )
            .asFunction(),
        _cpiCreate = lib
            .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
              'musify_cpi_create',
            )
            .asFunction(),
        _cpiDestroy = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
              'musify_cpi_destroy',
            )
            .asFunction(isLeaf: true),
        _cpiSetAudioEngine = lib
            .lookup<
                NativeFunction<Void Function(Pointer<Void>, Pointer<Void>)>>(
              'musify_cpi_set_audio_engine',
            )
            .asFunction(),
        _cpiHandleCommand = lib
            .lookup<
                NativeFunction<
                    Int32 Function(
                      Pointer<Void>,
                      Pointer<Utf8>,
                      Pointer<Uint8>,
                      Int32,
                    )>>('musify_cpi_handle_command')
            .asFunction(),
        _cpiAdvanceToNextTrack = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
              'musify_cpi_advance_to_next_track',
            )
            .asFunction(),
        _cpiGetState = lib
            .lookup<
                NativeFunction<
                    Pointer<Uint8> Function(Pointer<Void>, Pointer<Int32>)>>(
              'musify_cpi_get_state',
            )
            .asFunction(),
        _cpiGetQueue = lib
            .lookup<
                NativeFunction<
                    Pointer<Uint8> Function(Pointer<Void>, Pointer<Int32>)>>(
              'musify_cpi_get_queue',
            )
            .asFunction(),
        _cpiSetStateChangedPort = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>, Int64)>>(
              'musify_cpi_set_state_changed_port',
            )
            .asFunction(isLeaf: true),
        _cpiSetQueueChangedPort = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>, Int64)>>(
              'musify_cpi_set_queue_changed_port',
            )
            .asFunction(isLeaf: true),
        _cpiSetErrorPort = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>, Int64)>>(
              'musify_cpi_set_error_port',
            )
            .asFunction(isLeaf: true),
        _connectCreate = lib
            .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
              'musify_connect_create',
            )
            .asFunction(),
        _connectDestroy = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
              'musify_connect_destroy',
            )
            .asFunction(),
        _connectStart = lib
            .lookup<
                NativeFunction<
                    Int32 Function(Pointer<Void>, Pointer<Uint8>, Int32)>>(
              'musify_connect_start',
            )
            .asFunction(),
        _connectStop = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
              'musify_connect_stop',
            )
            .asFunction(),
        _connectCallAsync = lib
            .lookup<
                NativeFunction<
                    Int32 Function(
                      Pointer<Void>,
                      Int32,
                      Pointer<Utf8>,
                      Pointer<Uint8>,
                      Int32,
                      Int64,
                      Int64,
                    )>>('musify_connect_call_async')
            .asFunction(),
        _connectSetEndpoints = lib
            .lookup<
                NativeFunction<
                    Int32 Function(
                      Pointer<Void>,
                      Pointer<Utf8>,
                      Pointer<Utf8>,
                    )>>('musify_connect_set_endpoints')
            .asFunction(),
        _connectReconnect = lib
            .lookup<NativeFunction<Int32 Function(Pointer<Void>, Int32)>>(
              'musify_connect_reconnect',
            )
            .asFunction(),
        _connectSetNetworkAvailable = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>, Int32)>>(
              'musify_connect_set_network_available',
            )
            .asFunction(),
        _connectUpdateNsdServices = lib
            .lookup<
                NativeFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>)>>(
              'musify_connect_update_nsd_services',
            )
            .asFunction(),
        _connectSetLocalVolume = lib
            .lookup<
                NativeFunction<
                    Int32 Function(Pointer<Void>, Uint32, Int32, Int32)>>(
              'musify_connect_set_local_volume',
            )
            .asFunction(),
        _connectServiceCall = lib
            .lookup<
                NativeFunction<
                    Pointer<Uint8> Function(
                      Pointer<Void>,
                      Pointer<Utf8>,
                      Pointer<Uint8>,
                      Int32,
                      Pointer<Int32>,
                      Pointer<Int32>,
                    )>>('musify_connect_service_call')
            .asFunction(),
        _connectVolumeServiceCall = lib
            .lookup<
                NativeFunction<
                    Pointer<Uint8> Function(
                      Pointer<Void>,
                      Pointer<Utf8>,
                      Pointer<Uint8>,
                      Int32,
                      Pointer<Int32>,
                      Pointer<Int32>,
                    )>>('musify_connect_volume_service_call')
            .asFunction(),
        _dodoServiceCall = lib
            .lookup<
                NativeFunction<
                    Pointer<Uint8> Function(
                      Pointer<Void>,
                      Pointer<Utf8>,
                      Pointer<Uint8>,
                      Int32,
                      Pointer<Int32>,
                      Pointer<Int32>,
                    )>>('musify_dodo_service_call')
            .asFunction(),
        _connectSetStatePort = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>, Int64)>>(
              'musify_connect_set_state_port',
            )
            .asFunction(),
        _connectSetVolumePort = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>, Int64)>>(
              'musify_connect_set_volume_port',
            )
            .asFunction(),
        _connectSetLocalVolumePort = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>, Int64)>>(
              'musify_connect_set_local_volume_port',
            )
            .asFunction(),
        _connectSetDodoPort = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>, Int64)>>(
              'musify_connect_set_dodo_port',
            )
            .asFunction(),
        _connectSetInstallSpotifyPort = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>, Int64)>>(
              'musify_connect_set_install_spotify_port',
            )
            .asFunction(),
        _connectSetDiagnosticPort = lib
            .lookup<NativeFunction<Void Function(Pointer<Void>, Int64)>>(
              'musify_connect_set_diagnostic_port',
            )
            .asFunction();

  static const String _libName = 'libmusify_audio.so';

  static MusifyFfiBindings? _instance;

  static bool get isInitialized => _instance != null;

  static MusifyFfiBindings get instance {
    final current = _instance;
    if (current != null) return current;
    final created = MusifyFfiBindings._open();
    _instance = created;
    return created;
  }

  final DynamicLibrary lib;

  final Pointer<Void> Function() _create;
  final void Function(Pointer<Void>) _destroy;
  final int Function(Pointer<Void>, Pointer<Utf8>) _loadLocal;
  final int Function(
    Pointer<Void>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    int,
  ) _loadDualSource;
  final int Function(
    Pointer<Void>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
  ) _loadEncrypted;
  final int Function(
    Pointer<Void>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    int,
  ) _attachSecondaryStream;
  final int Function(
    Pointer<Void>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    int,
  ) _loadTrackWithHead;
  final void Function(
    Pointer<Void>,
    Pointer<Utf8>,
    Pointer<Utf8>,
  ) _prefetchHead;
  final int Function(Pointer<Void>, Pointer<Uint8>, int) _setDrmSession;
  final int Function(Pointer<Void>) _play;
  final int Function(Pointer<Void>) _pause;
  final int Function(Pointer<Void>, int) _seekMs;
  final void Function(Pointer<Void>) _stop;
  final int Function(Pointer<Void>) _getPositionMs;
  final int Function(Pointer<Void>) _getDurationMs;
  final int Function(Pointer<Void>) _getState;
  final int Function(Pointer<Void>) _getUnderrunCount;
  final int Function(Pointer<Void>) _isDualSource;
  final int Function(Pointer<Void>) _isHandoffCompleted;

  final void Function(Pointer<Utf8>) _freeString;
  final void Function(Pointer<Uint8>) _freeBytes;

  final void Function(
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
  ) _setAuthSession;
  final void Function(int) _setAuthRefreshPort;
  final void Function(
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    int,
  ) _setClientProfile;
  final void Function(int, Pointer<Utf8>, Pointer<Uint8>, int)
      _metadataSeedExtension;

  final Pointer<Void> Function() _cpCreate;
  final void Function(Pointer<Void>) _cpDestroy;
  final int Function(Pointer<Utf8>) _cpIsDelimiter;
  final int Function(
    Pointer<Void>,
    Pointer<Utf8>,
    Pointer<Uint8>,
    int,
    int,
  ) _cpSetContextProto;
  final int Function(
    Pointer<Void>,
    int,
    Pointer<Uint8>,
    int,
  ) _cpParseLoadedPageProto;
  final Pointer<Uint8> Function(
    Pointer<Void>,
    int,
    Pointer<Int32>,
  ) _cpGetQueueProto;
  final int Function(Pointer<Void>) _cpSkipNext;
  final int Function(Pointer<Void>) _cpSkipPrev;
  final int Function(Pointer<Void>, int) _cpSkipToIndex;
  final int Function(Pointer<Void>, Pointer<Utf8>) _cpSkipToUri;
  final int Function(Pointer<Void>, Pointer<Utf8>) _cpSkipToUid;
  final void Function(Pointer<Void>, int) _cpSetShuffling;
  final int Function(Pointer<Void>) _cpIsShuffling;
  final int Function(Pointer<Void>) _cpNeedsNextPage;
  final Pointer<Utf8> Function(Pointer<Void>) _cpGetNextPageUrl;
  final int Function(Pointer<Void>) _cpGetCurrentIteration;
  final int Function(Pointer<Void>) _cpGetCurrentIndex;

  final int Function(Pointer<Void>) _initDartApiDl;
  final Pointer<Void> Function(Pointer<Void>) _cpiCreate;
  final void Function(Pointer<Void>) _cpiDestroy;
  final void Function(Pointer<Void>, Pointer<Void>) _cpiSetAudioEngine;
  final int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Uint8>, int)
      _cpiHandleCommand;
  final void Function(Pointer<Void>) _cpiAdvanceToNextTrack;
  final Pointer<Uint8> Function(Pointer<Void>, Pointer<Int32>) _cpiGetState;
  final Pointer<Uint8> Function(Pointer<Void>, Pointer<Int32>) _cpiGetQueue;
  final void Function(Pointer<Void>, int) _cpiSetStateChangedPort;
  final void Function(Pointer<Void>, int) _cpiSetQueueChangedPort;
  final void Function(Pointer<Void>, int) _cpiSetErrorPort;

  final Pointer<Void> Function(Pointer<Void>) _connectCreate;
  final void Function(Pointer<Void>) _connectDestroy;
  final int Function(Pointer<Void>, Pointer<Uint8>, int) _connectStart;
  final void Function(Pointer<Void>) _connectStop;
  final int Function(
    Pointer<Void>,
    int,
    Pointer<Utf8>,
    Pointer<Uint8>,
    int,
    int,
    int,
  ) _connectCallAsync;
  final int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>)
      _connectSetEndpoints;
  final int Function(Pointer<Void>, int) _connectReconnect;
  final void Function(Pointer<Void>, int) _connectSetNetworkAvailable;
  final int Function(Pointer<Void>, Pointer<Utf8>) _connectUpdateNsdServices;
  final int Function(Pointer<Void>, int, int, int) _connectSetLocalVolume;
  final Pointer<Uint8> Function(
    Pointer<Void>,
    Pointer<Utf8>,
    Pointer<Uint8>,
    int,
    Pointer<Int32>,
    Pointer<Int32>,
  ) _connectServiceCall;
  final Pointer<Uint8> Function(
    Pointer<Void>,
    Pointer<Utf8>,
    Pointer<Uint8>,
    int,
    Pointer<Int32>,
    Pointer<Int32>,
  ) _connectVolumeServiceCall;
  final Pointer<Uint8> Function(
    Pointer<Void>,
    Pointer<Utf8>,
    Pointer<Uint8>,
    int,
    Pointer<Int32>,
    Pointer<Int32>,
  ) _dodoServiceCall;
  final void Function(Pointer<Void>, int) _connectSetStatePort;
  final void Function(Pointer<Void>, int) _connectSetVolumePort;
  final void Function(Pointer<Void>, int) _connectSetLocalVolumePort;
  final void Function(Pointer<Void>, int) _connectSetDodoPort;
  final void Function(Pointer<Void>, int) _connectSetInstallSpotifyPort;
  final void Function(Pointer<Void>, int) _connectSetDiagnosticPort;

  // --- Public API ---

  Pointer<Void> create() => _create();
  void destroy(Pointer<Void> h) => _destroy(h);
  int loadLocal(Pointer<Void> h, Pointer<Utf8> path) => _loadLocal(h, path);
  int loadDualSource(
    Pointer<Void> h,
    Pointer<Utf8> primaryPath,
    Pointer<Utf8> secondaryUrl,
    Pointer<Utf8> licenseServerUrl,
    Pointer<Utf8> authHeader,
    int handoffPositionMs,
  ) =>
      _loadDualSource(
        h,
        primaryPath,
        secondaryUrl,
        licenseServerUrl,
        authHeader,
        handoffPositionMs,
      );
  int loadEncrypted(
    Pointer<Void> h,
    Pointer<Utf8> url,
    Pointer<Utf8> licenseServerUrl,
    Pointer<Utf8> authHeader,
  ) =>
      _loadEncrypted(
        h,
        url,
        licenseServerUrl,
        authHeader,
      );
  int attachSecondaryStream(
    Pointer<Void> h,
    Pointer<Utf8> secondaryUrl,
    Pointer<Utf8> licenseServerUrl,
    Pointer<Utf8> authHeader,
    int handoffPositionMs,
  ) =>
      _attachSecondaryStream(
        h,
        secondaryUrl,
        licenseServerUrl,
        authHeader,
        handoffPositionMs,
      );
  int loadTrackWithHead(
    Pointer<Void> h,
    Pointer<Utf8> fileIdHex,
    Pointer<Utf8> fullTrackUrl,
    Pointer<Utf8> cacheDir,
    Pointer<Utf8> licenseServerUrl,
    Pointer<Utf8> authHeader,
    int trackDurationMs,
  ) =>
      _loadTrackWithHead(
        h,
        fileIdHex,
        fullTrackUrl,
        cacheDir,
        licenseServerUrl,
        authHeader,
        trackDurationMs,
      );
  void prefetchHead(
    Pointer<Void> h,
    Pointer<Utf8> fileIdHex,
    Pointer<Utf8> cacheDir,
  ) =>
      _prefetchHead(h, fileIdHex, cacheDir);
  int setDrmSession(
    Pointer<Void> h,
    Pointer<Uint8> sessionId,
    int sessionLen,
  ) =>
      _setDrmSession(h, sessionId, sessionLen);
  int play(Pointer<Void> h) => _play(h);
  int pause(Pointer<Void> h) => _pause(h);
  int seekMs(Pointer<Void> h, int positionMs) => _seekMs(h, positionMs);
  void stop(Pointer<Void> h) => _stop(h);
  int getPositionMs(Pointer<Void> h) => _getPositionMs(h);
  int getDurationMs(Pointer<Void> h) => _getDurationMs(h);
  int getState(Pointer<Void> h) => _getState(h);
  int getUnderrunCount(Pointer<Void> h) => _getUnderrunCount(h);
  bool isDualSource(Pointer<Void> h) => _isDualSource(h) != 0;
  bool isHandoffCompleted(Pointer<Void> h) => _isHandoffCompleted(h) != 0;

  void freeString(Pointer<Utf8> str) => _freeString(str);
  void freeBytes(Pointer<Uint8> bytes) => _freeBytes(bytes);

  void setAuthSession({
    required Pointer<Utf8> accessToken,
    required Pointer<Utf8> clientToken,
    required Pointer<Utf8> spDc,
    required Pointer<Utf8> country,
    required Pointer<Utf8> catalogue,
    required Pointer<Utf8> acceptLanguage,
    required Pointer<Utf8> cacheDir,
  }) =>
      _setAuthSession(
        accessToken,
        clientToken,
        spDc,
        country,
        catalogue,
        acceptLanguage,
        cacheDir,
      );

  void setAuthRefreshPort(int port) => _setAuthRefreshPort(port);

  void setClientProfile({
    required Pointer<Utf8> clientId,
    required Pointer<Utf8> appPlatform,
    required Pointer<Utf8> appVersion,
    required Pointer<Utf8> userAgent,
    required int sendOriginHeaders,
  }) =>
      _setClientProfile(
        clientId,
        appPlatform,
        appVersion,
        userAgent,
        sendOriginHeaders,
      );

  void metadataSeedExtension(
    int extensionKind,
    Pointer<Utf8> entityUri,
    Pointer<Uint8> payload,
    int payloadLen,
  ) =>
      _metadataSeedExtension(extensionKind, entityUri, payload, payloadLen);

  Pointer<Void> cpCreate() => _cpCreate();
  void cpDestroy(Pointer<Void> h) => _cpDestroy(h);
  bool cpIsDelimiter(Pointer<Utf8> uri) => _cpIsDelimiter(uri) != 0;
  int cpSetContextProto(
    Pointer<Void> h,
    Pointer<Utf8> contextUri,
    Pointer<Uint8> pageProtoBytes,
    int pageProtoLen,
    int initialIndex,
  ) =>
      _cpSetContextProto(
        h,
        contextUri,
        pageProtoBytes,
        pageProtoLen,
        initialIndex,
      );
  int cpParseLoadedPageProto(
    Pointer<Void> h,
    int iteration,
    Pointer<Uint8> pageProtoBytes,
    int pageProtoLen,
  ) =>
      _cpParseLoadedPageProto(
        h,
        iteration,
        pageProtoBytes,
        pageProtoLen,
      );
  Pointer<Uint8> cpGetQueueProto(
    Pointer<Void> h,
    int maxNextCount,
    Pointer<Int32> outLen,
  ) =>
      _cpGetQueueProto(h, maxNextCount, outLen);
  bool cpSkipNext(Pointer<Void> h) => _cpSkipNext(h) != 0;
  bool cpSkipPrev(Pointer<Void> h) => _cpSkipPrev(h) != 0;
  bool cpSkipToIndex(Pointer<Void> h, int index) =>
      _cpSkipToIndex(h, index) != 0;
  bool cpSkipToUri(Pointer<Void> h, Pointer<Utf8> uri) =>
      _cpSkipToUri(h, uri) != 0;
  bool cpSkipToUid(Pointer<Void> h, Pointer<Utf8> uid) =>
      _cpSkipToUid(h, uid) != 0;
  void cpSetShuffling(Pointer<Void> h, bool shuffle) =>
      _cpSetShuffling(h, shuffle ? 1 : 0);
  bool cpIsShuffling(Pointer<Void> h) => _cpIsShuffling(h) != 0;
  bool cpNeedsNextPage(Pointer<Void> h) => _cpNeedsNextPage(h) != 0;
  Pointer<Utf8> cpGetNextPageUrl(Pointer<Void> h) => _cpGetNextPageUrl(h);
  int cpGetCurrentIteration(Pointer<Void> h) => _cpGetCurrentIteration(h);
  int cpGetCurrentIndex(Pointer<Void> h) => _cpGetCurrentIndex(h);

  int initDartApiDl(Pointer<Void> data) => _initDartApiDl(data);
  Pointer<Void> cpiCreate(Pointer<Void> engineHandle) =>
      _cpiCreate(engineHandle);
  void cpiDestroy(Pointer<Void> h) => _cpiDestroy(h);
  void cpiSetAudioEngine(Pointer<Void> h, Pointer<Void> engineHandle) =>
      _cpiSetAudioEngine(h, engineHandle);
  int cpiHandleCommand(
    Pointer<Void> h,
    Pointer<Utf8> method,
    Pointer<Uint8> payload,
    int payloadLen,
  ) =>
      _cpiHandleCommand(h, method, payload, payloadLen);
  void cpiAdvanceToNextTrack(Pointer<Void> h) => _cpiAdvanceToNextTrack(h);
  Pointer<Uint8> cpiGetState(Pointer<Void> h, Pointer<Int32> outLen) =>
      _cpiGetState(h, outLen);
  Pointer<Uint8> cpiGetQueue(Pointer<Void> h, Pointer<Int32> outLen) =>
      _cpiGetQueue(h, outLen);
  void cpiSetStateChangedPort(Pointer<Void> h, int port) =>
      _cpiSetStateChangedPort(h, port);
  void cpiSetQueueChangedPort(Pointer<Void> h, int port) =>
      _cpiSetQueueChangedPort(h, port);
  void cpiSetErrorPort(Pointer<Void> h, int port) => _cpiSetErrorPort(h, port);

  Pointer<Void> connectCreate(Pointer<Void> cpiHandle) =>
      _connectCreate(cpiHandle);
  void connectDestroy(Pointer<Void> h) => _connectDestroy(h);
  int connectStart(
    Pointer<Void> h,
    Pointer<Uint8> deviceInfoBytes,
    int len,
  ) =>
      _connectStart(h, deviceInfoBytes, len);
  void connectStop(Pointer<Void> h) => _connectStop(h);
  int connectCallAsync(
    Pointer<Void> h,
    int serviceId,
    Pointer<Utf8> method,
    Pointer<Uint8> payload,
    int payloadLen,
    int requestId,
    int replyPort,
  ) =>
      _connectCallAsync(
        h,
        serviceId,
        method,
        payload,
        payloadLen,
        requestId,
        replyPort,
      );
  int connectSetEndpoints(
    Pointer<Void> h,
    Pointer<Utf8> spclientBaseUrl,
    Pointer<Utf8> dealerWsUrl,
  ) =>
      _connectSetEndpoints(h, spclientBaseUrl, dealerWsUrl);
  int connectReconnect(Pointer<Void> h, int reasonCode) =>
      _connectReconnect(h, reasonCode);
  void connectSetNetworkAvailable(Pointer<Void> h, int isAvailable) =>
      _connectSetNetworkAvailable(h, isAvailable);
  int connectUpdateNsdServices(
    Pointer<Void> h,
    Pointer<Utf8> servicesJsonUtf8,
  ) =>
      _connectUpdateNsdServices(h, servicesJsonUtf8);
  int connectSetLocalVolume(
    Pointer<Void> h,
    int volume0To65535,
    int volumeSteps,
    int reasonCode,
  ) =>
      _connectSetLocalVolume(h, volume0To65535, volumeSteps, reasonCode);
  Pointer<Uint8> connectServiceCall(
    Pointer<Void> h,
    Pointer<Utf8> method,
    Pointer<Uint8> payload,
    int payloadLen,
    Pointer<Int32> outLen,
    Pointer<Int32> outStatus,
  ) =>
      _connectServiceCall(h, method, payload, payloadLen, outLen, outStatus);
  Pointer<Uint8> connectVolumeServiceCall(
    Pointer<Void> h,
    Pointer<Utf8> method,
    Pointer<Uint8> payload,
    int payloadLen,
    Pointer<Int32> outLen,
    Pointer<Int32> outStatus,
  ) =>
      _connectVolumeServiceCall(
        h,
        method,
        payload,
        payloadLen,
        outLen,
        outStatus,
      );
  Pointer<Uint8> dodoServiceCall(
    Pointer<Void> h,
    Pointer<Utf8> method,
    Pointer<Uint8> payload,
    int payloadLen,
    Pointer<Int32> outLen,
    Pointer<Int32> outStatus,
  ) =>
      _dodoServiceCall(h, method, payload, payloadLen, outLen, outStatus);
  void connectSetStatePort(Pointer<Void> h, int port) =>
      _connectSetStatePort(h, port);
  void connectSetVolumePort(Pointer<Void> h, int port) =>
      _connectSetVolumePort(h, port);
  void connectSetLocalVolumePort(Pointer<Void> h, int port) =>
      _connectSetLocalVolumePort(h, port);
  void connectSetDodoPort(Pointer<Void> h, int port) =>
      _connectSetDodoPort(h, port);
  void connectSetInstallSpotifyPort(Pointer<Void> h, int port) =>
      _connectSetInstallSpotifyPort(h, port);
  void connectSetDiagnosticPort(Pointer<Void> h, int dartPort) =>
      _connectSetDiagnosticPort(h, dartPort);
}
