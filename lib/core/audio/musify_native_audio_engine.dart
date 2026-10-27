import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

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

  /// Loads a Spotify track with native chunk 0 head file resolution & download in C++.
  ///
  /// C++ checks the disk cache at `$cacheDir/heads/{fileIdHex}.ogg` (131,072 bytes),
  /// downloads it over native HTTP if missing, starts playback immediately via the primary
  /// decoder (< 30ms TTFA), and seamlessly hands off to the full track MP4 stream
  /// via Android AMediaCodec without any audio glitch or container mismatch.
  NativeEngineStatus loadTrackWithHead({
    required String fileIdHex,
    required String fullTrackUrl,
    String? cacheDir,
    String? licenseServerUrl,
    String? authHeader,
  }) {
    _ensureAlive();
    final fileIdPtr = fileIdHex.toNativeUtf8();
    final urlPtr = fullTrackUrl.toNativeUtf8();
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
        urlPtr.cast(),
        cachePtr != nullptr ? cachePtr.cast() : nullptr,
        licensePtr != nullptr ? licensePtr.cast() : nullptr,
        authPtr != nullptr ? authPtr.cast() : nullptr,
      );
      return NativeEngineStatus.fromInt(code);
    } finally {
      calloc.free(fileIdPtr);
      calloc.free(urlPtr);
      if (cachePtr != nullptr) calloc.free(cachePtr);
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
