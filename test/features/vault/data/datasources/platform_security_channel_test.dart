import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/datasources/platform_security_channel.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(PlatformSecurityChannel.channelName);
  late PlatformSecurityChannel securityChannel;

  setUp(() {
    securityChannel = PlatformSecurityChannel(channel: channel);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await securityChannel.dispose();
  });

  group('PlatformSecurityChannel Tests', () {
    test('initial state defaults to publicUnrestricted', () {
      expect(
        securityChannel.currentState,
        equals(ScreenPrivacyStateEnum.publicUnrestricted),
      );
    });

    test('enableSecureFlag invokes native channel and updates state to secureFlagEngaged', () async {
      var callCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'enableSecureFlag') {
          callCount++;
          return true;
        }
        return null;
      });

      final emittedStates = <ScreenPrivacyStateEnum>[];
      final subscription = securityChannel.stateStream.listen(emittedStates.add);

      await securityChannel.enableSecureFlag();
      await pumpEventQueue();

      expect(callCount, equals(1));
      expect(
        securityChannel.currentState,
        equals(ScreenPrivacyStateEnum.secureFlagEngaged),
      );
      expect(emittedStates, equals([ScreenPrivacyStateEnum.secureFlagEngaged]));

      await subscription.cancel();
    });

    test('disableSecureFlag invokes native channel and updates state to publicUnrestricted', () async {
      var callCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'enableSecureFlag') {
          return true;
        }
        if (call.method == 'disableSecureFlag') {
          callCount++;
          return true;
        }
        return null;
      });

      // First engage so disable represents an actual transition
      await securityChannel.enableSecureFlag();

      final emittedStates = <ScreenPrivacyStateEnum>[];
      final subscription = securityChannel.stateStream.listen(emittedStates.add);

      await securityChannel.disableSecureFlag();
      await pumpEventQueue();

      expect(callCount, equals(1));
      expect(
        securityChannel.currentState,
        equals(ScreenPrivacyStateEnum.publicUnrestricted),
      );
      expect(emittedStates, equals([ScreenPrivacyStateEnum.publicUnrestricted]));

      await subscription.cancel();
    });

    test('isSecureFlagEngaged returns boolean status from native platform', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'isSecureFlagEngaged') {
          return true;
        }
        return false;
      });

      final engaged = await securityChannel.isSecureFlagEngaged();
      expect(engaged, isTrue);
    });

    test('enableSecureFlag throws PlatformException on invalid return payload', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return 'unexpected_string_payload';
      });

      expect(
        () => securityChannel.enableSecureFlag(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('disableSecureFlag throws PlatformException on invalid return payload', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return null;
      });

      expect(
        () => securityChannel.disableSecureFlag(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('isSecureFlagEngaged throws PlatformException on invalid payload', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        return 12345;
      });

      expect(
        () => securityChannel.isSecureFlagEngaged(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('rethrows PlatformException when native channel errors', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(
          code: 'WINDOW_NULL',
          message: 'Activity window is null',
        );
      });

      expect(
        () => securityChannel.enableSecureFlag(),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            equals('WINDOW_NULL'),
          ),
        ),
      );
    });

    test('throws StateError when methods invoked after dispose', () async {
      await securityChannel.dispose();

      expect(
        () => securityChannel.enableSecureFlag(),
        throwsA(isA<StateError>()),
      );
      expect(
        () => securityChannel.disableSecureFlag(),
        throwsA(isA<StateError>()),
      );
      expect(
        () => securityChannel.isSecureFlagEngaged(),
        throwsA(isA<StateError>()),
      );
    });

    test('dispose is idempotent and safe to call multiple times', () async {
      await securityChannel.dispose();
      await securityChannel.dispose();
    });
  });
}
