import 'dart:ffi';

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
/// This class is consumed exclusively by NativeEsperantoTransport — it is
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
