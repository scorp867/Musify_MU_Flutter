import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../../features/player/data/esperanto/proto/es_context_page.pb.dart' as es_page;
import '../../features/player/data/esperanto/proto/es_context_track.pb.dart' as es_track;
import '../../features/player/data/esperanto/proto/es_queue.pb.dart' as es_queue;
import '../../features/player/domain/models/context_track.dart';
import 'musify_ffi_bindings.dart';

/// Mirrors C++ EngineState enum values exactly.
enum NativeEngineState {
  uninitialized(0),
  idle(1),
  loading(2),
  prebuffering(3),
  playing(4),
  paused(5),
  stopped(6),
  faulted(7);

  const NativeEngineState(this.value);
  final int value;

  static NativeEngineState fromInt(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return uninitialized;
  }
}

/// Mirrors C++ EngineStatus enum values exactly.
enum NativeEngineStatus {
  ok(0),
  errorInvalidState(-1),
  errorCodec(-2),
  errorStream(-3),
  errorIO(-4),
  errorInvalidArg(-5);

  const NativeEngineStatus(this.value);
  final int value;

  static NativeEngineStatus fromInt(int v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return errorInvalidState;
  }
}

/// Dart wrapper around the native C++ AudioEngine, with NativeFinalizer to
/// prevent resource leaks on isolate teardown.
///
/// This class is consumed exclusively by NativeEsperantoTransport - it is
/// never called directly from BLoCs or UI.
class MusifyNativeAudioEngine implements Finalizable {
  MusifyNativeAudioEngine() {
    _handle = _ffi.create();
    if (_handle == nullptr) {
      throw StateError('musify_engine_create returned null');
    }
    _destructor.attach(this, _handle.cast(), detach: this);
  }

  static final MusifyFfiBindings _ffi = MusifyFfiBindings.instance;

  static final NativeFinalizer _destructor = NativeFinalizer(
    _ffi.lib
        .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
            'musify_engine_destroy')
        .cast(),
  );

  late final Pointer<Void> _handle;
  bool _disposed = false;

  /// Exposes the native engine pointer for C++ ContextPlayerImpl binding.
  /// Only used by NativeEsperantoTransport to pass to musify_cpi_set_audio_engine.
  Pointer<Void> get handle {
    _ensureAlive();
    return _handle;
  }

  // -----------------------------------------------------------------------
  // Control
  // -----------------------------------------------------------------------

  NativeEngineStatus loadLocal(String filePath) {
    _ensureAlive();
    final pathPtr = filePath.toNativeUtf8();
    try {
      final code = _ffi.loadLocal(_handle, pathPtr.cast());
      return NativeEngineStatus.fromInt(code);
    } finally {
      calloc.free(pathPtr);
    }
  }

  /// Loads dual sources: fast local/preview OGG followed by remote DRM AAC.
  /// handoffPositionMs: Target handoff in ms, or -1 for natural stream EOF (Option C).
  NativeEngineStatus loadDualSource({
    required String primaryPath,
    required String secondaryUrl,
    String? licenseServerUrl,
    String? authHeader,
    int handoffPositionMs = -1,
  }) {
    _ensureAlive();
    final primaryPtr = primaryPath.toNativeUtf8();
    final secondaryPtr = secondaryUrl.toNativeUtf8();
    final licensePtr = (licenseServerUrl != null && licenseServerUrl.isNotEmpty)
        ? licenseServerUrl.toNativeUtf8()
        : nullptr;
    final authPtr = (authHeader != null && authHeader.isNotEmpty)
        ? authHeader.toNativeUtf8()
        : nullptr;

    try {
      final code = _ffi.loadDualSource(
        _handle,
        primaryPtr.cast(),
        secondaryPtr.cast(),
        licensePtr != nullptr ? licensePtr.cast() : nullptr,
        authPtr != nullptr ? authPtr.cast() : nullptr,
        handoffPositionMs,
      );
      return NativeEngineStatus.fromInt(code);
    } finally {
      calloc.free(primaryPtr);
      calloc.free(secondaryPtr);
      if (licensePtr != nullptr) calloc.free(licensePtr);
      if (authPtr != nullptr) calloc.free(authPtr);
    }
  }

  /// Loads a single encrypted stream directly (e.g. Widevine AAC track without Vorbis head chunk).
  NativeEngineStatus loadEncrypted({
    required String url,
    required String licenseServerUrl,
    String? authHeader,
  }) {
    _ensureAlive();
    final urlPtr = url.toNativeUtf8();
    final licensePtr = licenseServerUrl.toNativeUtf8();
    final authPtr = (authHeader != null && authHeader.isNotEmpty)
        ? authHeader.toNativeUtf8()
        : nullptr;

    try {
      final code = _ffi.loadEncrypted(
        _handle,
        urlPtr.cast(),
        licensePtr.cast(),
        authPtr != nullptr ? authPtr.cast() : nullptr,
      );
      return NativeEngineStatus.fromInt(code);
    } finally {
      calloc.free(urlPtr);
      calloc.free(licensePtr);
      if (authPtr != nullptr) calloc.free(authPtr);
    }
  }

  /// Loads a Spotify track with native chunk 0 head file resolution & download in C++.
  ///
  /// C++ checks the disk cache at `$cacheDir/heads/{fileIdHex}.ogg` (131,072 bytes),
  /// downloads it over native HTTP if missing, starts playback immediately via the primary
  /// decoder (< 30ms TTFA), and seamlessly hands off to the full track MP4 stream
  /// via Android AMediaCodec without any audio glitch or container mismatch.
  NativeEngineStatus loadTrackWithHead({
    required String fileIdHex,
    String? fullTrackUrl,
    String? cacheDir,
    String? licenseServerUrl,
    String? authHeader,
    int trackDurationMs = -1,
  }) {
    _ensureAlive();
    final fileIdPtr = fileIdHex.toNativeUtf8();
    final urlPtr = (fullTrackUrl != null && fullTrackUrl.isNotEmpty)
        ? fullTrackUrl.toNativeUtf8()
        : nullptr;
    final cachePtr = (cacheDir != null && cacheDir.isNotEmpty)
        ? cacheDir.toNativeUtf8()
        : nullptr;
    final licensePtr = (licenseServerUrl != null && licenseServerUrl.isNotEmpty)
        ? licenseServerUrl.toNativeUtf8()
        : nullptr;
    final authPtr = (authHeader != null && authHeader.isNotEmpty)
        ? authHeader.toNativeUtf8()
        : nullptr;

    try {
      final code = _ffi.loadTrackWithHead(
        _handle,
        fileIdPtr.cast(),
        urlPtr != nullptr ? urlPtr.cast() : nullptr,
        cachePtr != nullptr ? cachePtr.cast() : nullptr,
        licensePtr != nullptr ? licensePtr.cast() : nullptr,
        authPtr != nullptr ? authPtr.cast() : nullptr,
        trackDurationMs,
      );
      return NativeEngineStatus.fromInt(code);
    } finally {
      calloc.free(fileIdPtr);
      if (urlPtr != nullptr) calloc.free(urlPtr);
      if (cachePtr != nullptr) calloc.free(cachePtr);
      if (licensePtr != nullptr) calloc.free(licensePtr);
      if (authPtr != nullptr) calloc.free(authPtr);
    }
  }

  /// Asynchronously attaches or starts the secondary full-track stream
  /// while the primary head stream is already playing.
  NativeEngineStatus attachSecondaryStream({
    required String secondaryUrl,
    String? licenseServerUrl,
    String? authHeader,
    int handoffPositionMs = -1,
  }) {
    _ensureAlive();
    final urlPtr = secondaryUrl.toNativeUtf8();
    final licensePtr = (licenseServerUrl != null && licenseServerUrl.isNotEmpty)
        ? licenseServerUrl.toNativeUtf8()
        : nullptr;
    final authPtr = (authHeader != null && authHeader.isNotEmpty)
        ? authHeader.toNativeUtf8()
        : nullptr;

    try {
      final code = _ffi.attachSecondaryStream(
        _handle,
        urlPtr.cast(),
        licensePtr != nullptr ? licensePtr.cast() : nullptr,
        authPtr != nullptr ? authPtr.cast() : nullptr,
        handoffPositionMs,
      );
      return NativeEngineStatus.fromInt(code);
    } finally {
      calloc.free(urlPtr);
      if (licensePtr != nullptr) calloc.free(licensePtr);
      if (authPtr != nullptr) calloc.free(authPtr);
    }
  }

  /// Asynchronously prefetches the 128 KiB chunk 0 head file in native C++
  /// matching Spotify's `Prefetch: start prefetching head file for track %s : %s`.
  void prefetchHead({
    required String fileIdHex,
    String? cacheDir,
  }) {
    _ensureAlive();
    final fileIdPtr = fileIdHex.toNativeUtf8();
    final cachePtr = (cacheDir != null && cacheDir.isNotEmpty)
        ? cacheDir.toNativeUtf8()
        : nullptr;

    try {
      _ffi.prefetchHead(
        _handle,
        fileIdPtr.cast(),
        cachePtr != nullptr ? cachePtr.cast() : nullptr,
      );
    } finally {
      calloc.free(fileIdPtr);
      if (cachePtr != nullptr) calloc.free(cachePtr);
    }
  }

  NativeEngineStatus setDrmSession(Uint8List sessionId) {
    _ensureAlive();
    final sessionPtr = calloc<Uint8>(sessionId.length);
    try {
      sessionPtr.asTypedList(sessionId.length).setAll(0, sessionId);
      final code = _ffi.setDrmSession(_handle, sessionPtr, sessionId.length);
      return NativeEngineStatus.fromInt(code);
    } finally {
      calloc.free(sessionPtr);
    }
  }

  NativeEngineStatus play() {
    _ensureAlive();
    return NativeEngineStatus.fromInt(_ffi.play(_handle));
  }

  NativeEngineStatus pause() {
    _ensureAlive();
    return NativeEngineStatus.fromInt(_ffi.pause(_handle));
  }

  NativeEngineStatus seekMs(int positionMs) {
    _ensureAlive();
    return NativeEngineStatus.fromInt(_ffi.seekMs(_handle, positionMs));
  }

  // -----------------------------------------------------------------------
  // Telemetry
  // -----------------------------------------------------------------------

  int get positionMs {
    _ensureAlive();
    return _ffi.getPositionMs(_handle);
  }

  int get durationMs {
    _ensureAlive();
    return _ffi.getDurationMs(_handle);
  }

  NativeEngineState get state {
    _ensureAlive();
    return NativeEngineState.fromInt(_ffi.getState(_handle));
  }

  int get underrunCount {
    _ensureAlive();
    return _ffi.getUnderrunCount(_handle);
  }

  bool get isDualSource {
    _ensureAlive();
    return _ffi.isDualSource(_handle);
  }

  bool get isHandoffCompleted {
    _ensureAlive();
    return _ffi.isHandoffCompleted(_handle);
  }

  // -----------------------------------------------------------------------
  // Lifecycle
  // -----------------------------------------------------------------------

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _destructor.detach(this);
    _ffi.destroy(_handle);
  }

  void _ensureAlive() {
    if (_disposed) {
      throw StateError('MusifyNativeAudioEngine already disposed');
    }
  }
}

/// Native C++ ContextProcessor wrapper (1:1 with liborbit.so ContextProcessor & ContextView).
///
/// Implements deterministic queue windowing, delimiter generation, and page-boundary slicing
/// directly in the native C++ player engine.
class NativeContextProcessor implements Finalizable {
  NativeContextProcessor() {
    _handle = _ffi.cpCreate();
    if (_handle == nullptr) {
      throw StateError('musify_context_processor_create returned null');
    }
    _destructor.attach(this, _handle.cast(), detach: this);
  }

  static final NativeFinalizer _destructor = NativeFinalizer(
    MusifyFfiBindings.instance.lib
        .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
            'musify_context_processor_destroy')
        .cast(),
  );

  final MusifyFfiBindings _ffi = MusifyFfiBindings.instance;
  late final Pointer<Void> _handle;
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _destructor.detach(this);
    _ffi.cpDestroy(_handle);
  }

  void _ensureAlive() {
    if (_disposed) {
      throw StateError('NativeContextProcessor already disposed');
    }
  }

  /// 1:1 delimiter check with liborbit.so 0x16b81d4
  bool isDelimiter(String uri) {
    final uriPtr = uri.toNativeUtf8();
    try {
      return _ffi.cpIsDelimiter(uriPtr);
    } finally {
      calloc.free(uriPtr);
    }
  }

  /// Sets context and initial tracks via 1:1 binary Protobuf wire format.
  void setContextProto({
    required String contextUri,
    required Uint8List pageProtoBytes,
    int initialIndex = 0,
  }) {
    _ensureAlive();
    final cUriPtr = contextUri.toNativeUtf8();
    final bytesPtr = calloc<Uint8>(pageProtoBytes.length);
    bytesPtr.asTypedList(pageProtoBytes.length).setAll(0, pageProtoBytes);

    try {
      _ffi.cpSetContextProto(
        _handle,
        cUriPtr,
        bytesPtr,
        pageProtoBytes.length,
        initialIndex,
      );
    } finally {
      calloc.free(cUriPtr);
      calloc.free(bytesPtr);
    }
  }

  /// Sets context using Domain/Protobuf ContextPage.
  void setContext({
    required String contextUri,
    required String pageUrl,
    required List<ContextTrack> tracks,
    required String nextPageUrl,
    int initialIndex = 0,
  }) {
    final page = es_page.ContextPage(
      pageUrl: pageUrl,
      nextPageUrl: nextPageUrl,
      tracks: tracks.map((t) => es_track.ContextTrack(
            uri: t.uri,
            uid: t.uid,
            metadata: t.metadata.entries,
          )),
    );
    setContextProto(
      contextUri: contextUri,
      pageProtoBytes: page.writeToBuffer(),
      initialIndex: initialIndex,
    );
  }

  /// 1:1 with liborbit.so 0x16a7530 parseLoadedContextPage via binary Protobuf.
  void parseLoadedContextPageProto({
    required int iteration,
    required Uint8List pageProtoBytes,
  }) {
    _ensureAlive();
    final bytesPtr = calloc<Uint8>(pageProtoBytes.length);
    bytesPtr.asTypedList(pageProtoBytes.length).setAll(0, pageProtoBytes);

    try {
      _ffi.cpParseLoadedPageProto(
        _handle,
        iteration,
        bytesPtr,
        pageProtoBytes.length,
      );
    } finally {
      calloc.free(bytesPtr);
    }
  }

  /// 1:1 with liborbit.so 0x16a7530 parseLoadedContextPage.
  void parseLoadedContextPage({
    required int iteration,
    required String pageUrl,
    required List<ContextTrack> tracks,
    required String nextPageUrl,
  }) {
    final page = es_page.ContextPage(
      pageUrl: pageUrl,
      nextPageUrl: nextPageUrl,
      tracks: tracks.map((t) => es_track.ContextTrack(
            uri: t.uri,
            uid: t.uid,
            metadata: t.metadata.entries,
          )),
    );
    parseLoadedContextPageProto(
      iteration: iteration,
      pageProtoBytes: page.writeToBuffer(),
    );
  }

  /// Returns the raw binary wire buffer of the active queue (1:1 with EsQueue$Queue).
  Uint8List? getQueueProto({int maxNextCount = 50}) {
    _ensureAlive();
    final outLenPtr = calloc<Int32>();
    try {
      final bytesPtr = _ffi.cpGetQueueProto(_handle, maxNextCount, outLenPtr);
      final len = outLenPtr.value;
      if (bytesPtr == nullptr || len <= 0) return null;
      try {
        final list = Uint8List(len);
        list.setAll(0, bytesPtr.asTypedList(len));
        return list;
      } finally {
        _ffi.freeBytes(bytesPtr);
      }
    } finally {
      calloc.free(outLenPtr);
    }
  }

  /// Returns the deserialized Spotify esperanto Queue proto (1:1 with EsQueue$Queue).
  es_queue.Queue? getQueue({int maxNextCount = 50}) {
    final bytes = getQueueProto(maxNextCount: maxNextCount);
    if (bytes == null || bytes.isEmpty) return null;
    return es_queue.Queue.fromBuffer(bytes);
  }

  bool skipNext() {
    _ensureAlive();
    return _ffi.cpSkipNext(_handle);
  }

  bool skipPrev() {
    _ensureAlive();
    return _ffi.cpSkipPrev(_handle);
  }

  bool skipToIndex(int index) {
    _ensureAlive();
    return _ffi.cpSkipToIndex(_handle, index);
  }

  bool skipToUri(String uri) {
    _ensureAlive();
    final uriPtr = uri.toNativeUtf8();
    try {
      return _ffi.cpSkipToUri(_handle, uriPtr);
    } finally {
      calloc.free(uriPtr);
    }
  }

  bool skipToUid(String uid) {
    _ensureAlive();
    final uidPtr = uid.toNativeUtf8();
    try {
      return _ffi.cpSkipToUid(_handle, uidPtr);
    } finally {
      calloc.free(uidPtr);
    }
  }

  void setShuffling(bool shuffle) {
    _ensureAlive();
    _ffi.cpSetShuffling(_handle, shuffle);
  }

  bool get isShuffling {
    _ensureAlive();
    return _ffi.cpIsShuffling(_handle);
  }

  bool get needsNextPage {
    _ensureAlive();
    return _ffi.cpNeedsNextPage(_handle);
  }

  String get nextPageUrl {
    _ensureAlive();
    final urlPtr = _ffi.cpGetNextPageUrl(_handle);
    if (urlPtr == nullptr) return '';
    try {
      return urlPtr.toDartString();
    } finally {
      _ffi.freeString(urlPtr);
    }
  }

  int get currentIteration {
    _ensureAlive();
    return _ffi.cpGetCurrentIteration(_handle);
  }

  int get currentIndex {
    _ensureAlive();
    return _ffi.cpGetCurrentIndex(_handle);
  }
}

