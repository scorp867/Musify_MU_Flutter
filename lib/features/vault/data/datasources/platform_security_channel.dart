import 'dart:async';

import 'package:flutter/services.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_screen_privacy_controller.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';

/// Production implementation of [IScreenPrivacyController] interfacing with Android's
/// native window manager via [MethodChannel] to govern WindowManager.LayoutParams.FLAG_SECURE.
final class PlatformSecurityChannel implements IScreenPrivacyController {
  /// Canonical platform channel name matching Android MainActivity registration.
  static const String channelName = 'um.musify.mu/screen_privacy';

  final MethodChannel _channel;
  final StreamController<ScreenPrivacyStateEnum> _stateController;
  ScreenPrivacyStateEnum _currentState;
  bool _isDisposed = false;

  /// Creates a [PlatformSecurityChannel] with optional injected [MethodChannel] for testing.
  PlatformSecurityChannel({
    MethodChannel channel = const MethodChannel(channelName),
  })  : _channel = channel,
        _stateController = StreamController<ScreenPrivacyStateEnum>.broadcast(),
        _currentState = ScreenPrivacyStateEnum.publicUnrestricted;

  @override
  ScreenPrivacyStateEnum get currentState => _currentState;

  @override
  Stream<ScreenPrivacyStateEnum> get stateStream => _stateController.stream;

  @override
  Future<void> enableSecureFlag() async {
    _ensureNotDisposed();
    try {
      final Object? result = await _channel.invokeMethod<Object?>('enableSecureFlag');
      if (result is bool && result) {
        _currentState = ScreenPrivacyStateEnum.secureFlagEngaged;
        if (!_stateController.isClosed) {
          _stateController.add(_currentState);
        }
        return;
      }
      throw PlatformException(
        code: 'UNEXPECTED_PAYLOAD',
        message: 'Native enableSecureFlag returned invalid payload: $result',
      );
    } on PlatformException {
      rethrow;
    }
  }

  @override
  Future<void> disableSecureFlag() async {
    _ensureNotDisposed();
    try {
      final Object? result = await _channel.invokeMethod<Object?>('disableSecureFlag');
      if (result is bool && result) {
        _currentState = ScreenPrivacyStateEnum.publicUnrestricted;
        if (!_stateController.isClosed) {
          _stateController.add(_currentState);
        }
        return;
      }
      throw PlatformException(
        code: 'UNEXPECTED_PAYLOAD',
        message: 'Native disableSecureFlag returned invalid payload: $result',
      );
    } on PlatformException {
      rethrow;
    }
  }

  /// Synchronously or asynchronously queries native window flag engagement without mutation.
  Future<bool> isSecureFlagEngaged() async {
    _ensureNotDisposed();
    final Object? result = await _channel.invokeMethod<Object?>('isSecureFlagEngaged');
    if (result is bool) {
      return result;
    }
    throw PlatformException(
      code: 'UNEXPECTED_PAYLOAD',
      message: 'Native isSecureFlagEngaged returned invalid payload: $result',
    );
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError('Cannot invoke methods on a disposed PlatformSecurityChannel.');
    }
  }

  /// Closes state streams and marks the channel as disposed.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await _stateController.close();
  }
}

/// Type alias providing dual-naming compatibility across domain references.
typedef PlatformScreenPrivacyController = PlatformSecurityChannel;
