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

    _initEncryptedStream = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>, Int64, Pointer<Uint8>, Pointer<Uint8>)>>(
            'musify_engine_init_encrypted_stream')
        .asFunction(isLeaf: true);

    _pushStreamChunk = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>, Int64, Pointer<Uint8>, Int32)>>(
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
        .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
            'musify_engine_get_state')
        .asFunction(isLeaf: true);

    _getUnderrunCount = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(
            'musify_engine_get_underrun_count')
        .asFunction(isLeaf: true);
  }

  static final MusifyFfiBindings instance = MusifyFfiBindings._();

  static const String _libName = 'libmusify_audio.so';
  late final DynamicLibrary lib;

  // --- Function pointers ---

  late final Pointer<Void> Function() _create;
  late final void Function(Pointer<Void>) _destroy;
  late final int Function(Pointer<Void>, Pointer<Utf8>) _loadLocal;
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

  // --- Public API ---

  Pointer<Void> create() => _create();
  void destroy(Pointer<Void> h) => _destroy(h);
  int loadLocal(Pointer<Void> h, Pointer<Utf8> path) => _loadLocal(h, path);
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
}
