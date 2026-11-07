import 'package:flutter/services.dart';
import 'package:musify_mu/features/private_vault/domain/services/i_native_security_channel.dart';

export 'package:musify_mu/features/private_vault/domain/services/i_native_security_channel.dart';

/// Production implementation communicating with Android's WindowManager via MethodChannel.
final class NativeSecurityChannel implements INativeSecurityChannel {
  static const MethodChannel _channel = MethodChannel('com.musify.mu/security');

  const NativeSecurityChannel();

  @override
  Future<void> setFlagSecure({required bool enabled}) async {
    try {
      await _channel.invokeMethod<bool>('setFlagSecure', <String, dynamic>{
        'enabled': enabled,
      });
    } on PlatformException catch (e) {
      // In non-Android environments or test harnesses, log gracefully without throwing.
      assert(() {
        // ignore: avoid_print
        print('NativeSecurityChannel warning: setFlagSecure failed: ${e.message}');
        return true;
      }());
    }
  }
}
