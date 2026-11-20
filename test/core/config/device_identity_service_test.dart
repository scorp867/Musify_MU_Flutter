import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/config/device_identity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('DeviceIdentityService', () {
    test('isValidCanonicalDeviceId validates exact 40-char lowercase hex', () {
      const validId = '0123456789abcdef0123456789abcdef01234567';
      expect(DeviceIdentityService.isValidCanonicalDeviceId(validId), isTrue);
      expect(DeviceIdentityService.isValidCanonicalDeviceId(''), isFalse);
      expect(
        DeviceIdentityService.isValidCanonicalDeviceId(
          '0123456789abcdef0123456789abcdef0123456',
        ),
        isFalse,
      );
      expect(
        DeviceIdentityService.isValidCanonicalDeviceId(
          '0123456789abcdef0123456789abcdef012345678',
        ),
        isFalse,
      );
      expect(
        DeviceIdentityService.isValidCanonicalDeviceId(
          '0123456789ABCDEF0123456789abcdef01234567',
        ),
        isFalse,
      );
      expect(
        DeviceIdentityService.isValidCanonicalDeviceId(
          '0123456789abcdef0123456789abcdef0123456g',
        ),
        isFalse,
      );
    });

    test('deriveFromAndroidId computes SHA-1(androidId:musify-connect-v1) and rejects sentinels', () {
      const androidId = 'pixel_8_pro_9928172';
      final expected = sha1
          .convert(utf8.encode('$androidId:musify-connect-v1'))
          .toString()
          .toLowerCase();

      final derived = DeviceIdentityService.deriveFromAndroidId('  $androidId  ');
      expect(derived, equals(expected));
      expect(DeviceIdentityService.isValidCanonicalDeviceId(derived), isTrue);

      expect(
        () => DeviceIdentityService.deriveFromAndroidId(''),
        throwsArgumentError,
      );
      expect(
        () => DeviceIdentityService.deriveFromAndroidId('   '),
        throwsArgumentError,
      );
      expect(
        () => DeviceIdentityService.deriveFromAndroidId('0'),
        throwsArgumentError,
      );
      expect(
        () => DeviceIdentityService.deriveFromAndroidId('9774d56d682e549c'),
        throwsArgumentError,
      );
      expect(
        () => DeviceIdentityService.deriveFromAndroidId('9774D56D682E549C'),
        throwsArgumentError,
      );
    });

    test('deriveFromCsprng produces valid 40-char lowercase hex deterministically with seeded Random', () {
      final first = DeviceIdentityService.deriveFromCsprng(Random(1337));
      final second = DeviceIdentityService.deriveFromCsprng(Random(1337));
      final secure = DeviceIdentityService.deriveFromCsprng();

      expect(DeviceIdentityService.isValidCanonicalDeviceId(first), isTrue);
      expect(first, equals(second));
      expect(DeviceIdentityService.isValidCanonicalDeviceId(secure), isTrue);
    });

    test('getOrCreateDeviceId returns persisted canonical ID without rotation', () async {
      const prePersisted = 'ABCDEF0123456789ABCDEF0123456789ABCDEF01';
      SharedPreferences.setMockInitialValues(<String, Object>{
        DeviceIdentityService.storageKey: '  $prePersisted  ',
      });
      final prefs = await SharedPreferences.getInstance();
      final service = DeviceIdentityService(preferences: prefs);

      expect(service.cachedDeviceId, isNull);

      final resolved = await service.getOrCreateDeviceId(
        androidId: 'different_android_id',
      );
      expect(resolved, equals(prePersisted.toLowerCase()));
      expect(service.cachedDeviceId, equals(prePersisted.toLowerCase()));

      final secondCall = await service.getOrCreateDeviceId(
        androidId: 'another_android_id',
      );
      expect(secondCall, equals(resolved));
    });

    test('getOrCreateDeviceId derives from usable androidId, persists, and caches when storage is empty or malformed', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        DeviceIdentityService.storageKey: 'not-a-valid-40-hex',
      });
      final prefs = await SharedPreferences.getInstance();
      final service = DeviceIdentityService(preferences: prefs);

      final resolved = await service.getOrCreateDeviceId(
        androidId: 'real_device_android_id_42',
      );
      final expected = DeviceIdentityService.deriveFromAndroidId(
        'real_device_android_id_42',
      );

      expect(resolved, equals(expected));
      expect(service.cachedDeviceId, equals(expected));
      expect(prefs.getString(DeviceIdentityService.storageKey), equals(expected));
    });

    test('getOrCreateDeviceId falls back to CSPRNG when androidId is sentinel and coalesces concurrent calls', () async {
      final service = DeviceIdentityService();

      final futures = <Future<String>>[
        service.getOrCreateDeviceId(androidId: '0'),
        service.getOrCreateDeviceId(androidId: '9774d56d682e549c'),
        service.getOrCreateDeviceId(),
      ];
      final results = await Future.wait<String>(futures);

      expect(
        DeviceIdentityService.isValidCanonicalDeviceId(results.first),
        isTrue,
      );
      expect(results[1], equals(results.first));
      expect(results[2], equals(results.first));

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(DeviceIdentityService.storageKey),
        equals(results.first),
      );
    });
  });
}
