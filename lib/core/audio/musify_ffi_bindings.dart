import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// Zero-overhead FFI bindings for libmusify_audio.so.
///
/// All telemetry getters use `isLeaf: true` because the C functions perform
/// only atomic reads with no GC interaction, heap allocation, or Dart callbacks.
class MusifyFfiBindings {
  MusifyFfiBindings._() {
    lib = DynamicLibrary.open(_libName);

    _create = lib
        .lookup<NativeFunction<Pointer<Void> Function()>>('musify_engine_create')
        .asFunction(isLeaf: true);

    _destroy = lib
        .lookup<NativeFunction<Void Function(Pointer<Void>)>>('musify_engine_destroy')
        .asFunction(isLeaf: true);

    _loadLocal = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>)>>(
            'musify_engine_load_local')
        .asFunction(isLeaf: true);

    _loadDualSource = lib
        .lookup<
            NativeFunction<
                Int32 Function(
                    Pointer<Void>,
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Int64)>>('musify_engine_load_dual_source')
        .asFunction(isLeaf: true);

    _loadEncrypted = lib
        .lookup<
            NativeFunction<
                Int32 Function(
                    Pointer<Void>,
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Pointer<Utf8>)>>('musify_engine_load_encrypted')
        .asFunction(isLeaf: true);

    _attachSecondaryStream = lib
        .lookup<
            NativeFunction<
                Int32 Function(
                    Pointer<Void>,
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Int64)>>('musify_engine_attach_secondary_stream')
        .asFunction(isLeaf: true);

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
                    Int64)>>('musify_engine_load_track_with_head')
        .asFunction(isLeaf: true);

    _prefetchHead = lib
        .lookup<
            NativeFunction<
                Void Function(
                    Pointer<Void>,
                    Pointer<Utf8>,
                    Pointer<Utf8>)>>('musify_engine_prefetch_head')
        .asFunction(isLeaf: true);

    _setDrmSession = lib
        .lookup<
            NativeFunction<
                Int32 Function(Pointer<Void>, Pointer<Uint8>, Int32)>>(
            'musify_engine_set_drm_session')
        .asFunction(isLeaf: true);

    _initEncryptedStream = lib
        .lookup<
            NativeFunction<
                Int32 Function(
                    Pointer<Void>, Int64, Pointer<Uint8>, Pointer<Uint8>)>>(
            'musify_engine_init_encrypted_stream')
        .asFunction(isLeaf: true);

    _pushStreamChunk = lib
        .lookup<
            NativeFunction<
                Int32 Function(Pointer<Void>, Int64, Pointer<Uint8>, Int32)>>(
            'musify_engine_push_stream_chunk')
        .asFunction(isLeaf: true);

    _play = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>('musify_engine_play')
        .asFunction(isLeaf: true);

    _pause = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>('musify_engine_pause')
        .asFunction(isLeaf: true);

    _seekMs = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>, Int64)>>(
            'musify_engine_seek_ms')
        .asFunction(isLeaf: true);

    _getPositionMs = lib
        .lookup<NativeFunction<Int64 Function(Pointer<Void>)>>(
            'musify_engine_get_position_ms')
        .asFunction(isLeaf: true);

    _getDurationMs = lib
        .lookup<NativeFunction<Int64 Function(Pointer<Void>)>>(
            'musify_engine_get_duration_ms')
        .asFunction(isLeaf: true);

    _getState = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>('musify_engine_get_state')
        .asFunction(isLeaf: true);

    _getUnderrunCount = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
            'musify_engine_get_underrun_count')
        .asFunction(isLeaf: true);

    _isDualSource = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
            'musify_engine_is_dual_source')
        .asFunction(isLeaf: true);

    _isHandoffCompleted = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
            'musify_engine_is_handoff_completed')
        .asFunction(isLeaf: true);

    _freeString = lib
        .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>('musify_free_string')
        .asFunction(isLeaf: true);

    _cpCreate = lib
        .lookup<NativeFunction<Pointer<Void> Function()>>(
            'musify_context_processor_create')
        .asFunction(isLeaf: true);

    _cpDestroy = lib
        .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
            'musify_context_processor_destroy')
        .asFunction(isLeaf: true);

    _cpIsDelimiter = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Utf8>)>>(
            'musify_context_processor_is_delimiter')
        .asFunction(isLeaf: true);

    _freeBytes = lib
        .lookup<NativeFunction<Void Function(Pointer<Uint8>)>>(
            'musify_free_bytes')
        .asFunction(isLeaf: true);

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
        .asFunction();

    _cpParseLoadedPageProto = lib
        .lookup<
            NativeFunction<
                Int32 Function(
                  Pointer<Void>,
                  Int32,
                  Pointer<Uint8>,
                  Int32,
                )>>('musify_context_processor_parse_loaded_page_proto')
        .asFunction();

    _cpGetQueueProto = lib
        .lookup<
            NativeFunction<
                Pointer<Uint8> Function(
                  Pointer<Void>,
                  Int32,
                  Pointer<Int32>,
                )>>('musify_context_processor_get_queue_proto')
        .asFunction();

    _cpSkipNext = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
            'musify_context_processor_skip_next')
        .asFunction(isLeaf: true);

    _cpSkipPrev = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
            'musify_context_processor_skip_prev')
        .asFunction(isLeaf: true);

    _cpSkipToIndex = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>, Int32)>>(
            'musify_context_processor_skip_to_index')
        .asFunction(isLeaf: true);

    _cpSkipToUri = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>)>>(
            'musify_context_processor_skip_to_uri')
        .asFunction(isLeaf: true);

    _cpSkipToUid = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>)>>(
            'musify_context_processor_skip_to_uid')
        .asFunction(isLeaf: true);

    _cpSetShuffling = lib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Int32)>>(
            'musify_context_processor_set_shuffling')
        .asFunction(isLeaf: true);

    _cpIsShuffling = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
            'musify_context_processor_is_shuffling')
        .asFunction(isLeaf: true);

    _cpNeedsNextPage = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
            'musify_context_processor_needs_next_page')
        .asFunction(isLeaf: true);

    _cpGetNextPageUrl = lib
        .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>)>>(
            'musify_context_processor_get_next_page_url')
        .asFunction();

    _cpGetCurrentIteration = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
            'musify_context_processor_get_current_iteration')
        .asFunction(isLeaf: true);

    _cpGetCurrentIndex = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
            'musify_context_processor_get_current_index')
        .asFunction(isLeaf: true);
  }

  static const String _libName = 'libmusify_audio.so';

  static MusifyFfiBindings? _instance;
  static MusifyFfiBindings get instance =>
      _instance ??= MusifyFfiBindings._();

  late final DynamicLibrary lib;

  late final Pointer<Void> Function() _create;
  late final void Function(Pointer<Void>) _destroy;
  late final int Function(Pointer<Void>, Pointer<Utf8>) _loadLocal;
  late final int Function(
    Pointer<Void>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    int,
  ) _loadDualSource;
  late final int Function(
    Pointer<Void>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
  ) _loadEncrypted;
  late final int Function(
    Pointer<Void>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    int,
  ) _attachSecondaryStream;
  late final int Function(
    Pointer<Void>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    int,
  ) _loadTrackWithHead;
  late final void Function(
      Pointer<Void>,
      Pointer<Utf8>,
      Pointer<Utf8>) _prefetchHead;
  late final int Function(Pointer<Void>, Pointer<Uint8>, int) _setDrmSession;
  late final int Function(Pointer<Void>, int, Pointer<Uint8>, Pointer<Uint8>)
      _initEncryptedStream;
  late final int Function(Pointer<Void>, int, Pointer<Uint8>, int)
      _pushStreamChunk;
  late final int Function(Pointer<Void>) _play;
  late final int Function(Pointer<Void>) _pause;
  late final int Function(Pointer<Void>, int) _seekMs;
  late final int Function(Pointer<Void>) _getPositionMs;
  late final int Function(Pointer<Void>) _getDurationMs;
  late final int Function(Pointer<Void>) _getState;
  late final int Function(Pointer<Void>) _getUnderrunCount;
  late final int Function(Pointer<Void>) _isDualSource;
  late final int Function(Pointer<Void>) _isHandoffCompleted;

  late final void Function(Pointer<Utf8>) _freeString;
  late final void Function(Pointer<Uint8>) _freeBytes;
  late final Pointer<Void> Function() _cpCreate;
  late final void Function(Pointer<Void>) _cpDestroy;
  late final int Function(Pointer<Utf8>) _cpIsDelimiter;
  late final int Function(
    Pointer<Void>,
    Pointer<Utf8>,
    Pointer<Uint8>,
    int,
    int,
  ) _cpSetContextProto;
  late final int Function(
    Pointer<Void>,
    int,
    Pointer<Uint8>,
    int,
  ) _cpParseLoadedPageProto;
  late final Pointer<Uint8> Function(
    Pointer<Void>,
    int,
    Pointer<Int32>,
  ) _cpGetQueueProto;
  late final int Function(Pointer<Void>) _cpSkipNext;
  late final int Function(Pointer<Void>) _cpSkipPrev;
  late final int Function(Pointer<Void>, int) _cpSkipToIndex;
  late final int Function(Pointer<Void>, Pointer<Utf8>) _cpSkipToUri;
  late final int Function(Pointer<Void>, Pointer<Utf8>) _cpSkipToUid;
  late final void Function(Pointer<Void>, int) _cpSetShuffling;
  late final int Function(Pointer<Void>) _cpIsShuffling;
  late final int Function(Pointer<Void>) _cpNeedsNextPage;
  late final Pointer<Utf8> Function(Pointer<Void>) _cpGetNextPageUrl;
  late final int Function(Pointer<Void>) _cpGetCurrentIteration;
  late final int Function(Pointer<Void>) _cpGetCurrentIndex;

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
  int setDrmSession(Pointer<Void> h, Pointer<Uint8> sessionId, int sessionLen) =>
      _setDrmSession(h, sessionId, sessionLen);
  int initEncryptedStream(
          Pointer<Void> h, int totalSize, Pointer<Uint8> key, Pointer<Uint8> iv) =>
      _initEncryptedStream(h, totalSize, key, iv);
  int pushStreamChunk(
          Pointer<Void> h, int offset, Pointer<Uint8> data, int length) =>
      _pushStreamChunk(h, offset, data, length);
  int play(Pointer<Void> h) => _play(h);
  int pause(Pointer<Void> h) => _pause(h);
  int seekMs(Pointer<Void> h, int positionMs) => _seekMs(h, positionMs);
  int getPositionMs(Pointer<Void> h) => _getPositionMs(h);
  int getDurationMs(Pointer<Void> h) => _getDurationMs(h);
  int getState(Pointer<Void> h) => _getState(h);
  int getUnderrunCount(Pointer<Void> h) => _getUnderrunCount(h);
  bool isDualSource(Pointer<Void> h) => _isDualSource(h) != 0;
  bool isHandoffCompleted(Pointer<Void> h) => _isHandoffCompleted(h) != 0;

  void freeString(Pointer<Utf8> str) => _freeString(str);
  void freeBytes(Pointer<Uint8> bytes) => _freeBytes(bytes);
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
  bool cpSkipToIndex(Pointer<Void> h, int index) => _cpSkipToIndex(h, index) != 0;
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
}
