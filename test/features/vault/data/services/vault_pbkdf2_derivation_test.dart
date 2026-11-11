import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/services/vault_pbkdf2_derivation.dart';

void main() {
  group('VaultPbkdf2Derivation RFC 6070 Test Vectors', () {
    test('Vector 1: c=1 dkLen=32 matches RFC 6070 test vector bitwise', () {
      final p = utf8.encode('password');
      final s = utf8.encode('salt');
      final result = VaultPbkdf2Derivation.deriveSynchronous(
        passwordBytes: p,
        saltBytes: s,
        iterations: 1,
        keyLength: 32,
      );
      final hex = result.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(hex, equals('120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b'));
    });

    test('Vector 2: c=2 dkLen=32 matches RFC 6070 test vector bitwise', () {
      final p = utf8.encode('password');
      final s = utf8.encode('salt');
      final result = VaultPbkdf2Derivation.deriveSynchronous(
        passwordBytes: p,
        saltBytes: s,
        iterations: 2,
        keyLength: 32,
      );
      final hex = result.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(hex, equals('ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43'));
    });

    test('Vector 3: c=4096 dkLen=32 matches RFC 6070 test vector bitwise', () {
      final p = utf8.encode('password');
      final s = utf8.encode('salt');
      final result = VaultPbkdf2Derivation.deriveSynchronous(
        passwordBytes: p,
        saltBytes: s,
        iterations: 4096,
        keyLength: 32,
      );
      final hex = result.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(hex, equals('c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a'));
    });
  });

  group('VaultPbkdf2Derivation Input Validation & Isolate Offloading', () {
    const derivation = VaultPbkdf2Derivation();
    final validSalt = Uint8List.fromList(List.generate(32, (i) => i));

    test('Throws FormatException on empty PIN', () async {
      expect(
        () => derivation.derive(pin: '', salt: validSalt, iterations: 1),
        throwsFormatException,
      );
    });

    test('Throws FormatException on non-6-digit PIN', () async {
      expect(
        () => derivation.derive(pin: '12345', salt: validSalt, iterations: 1),
        throwsFormatException,
      );
      expect(
        () => derivation.derive(pin: '1234567', salt: validSalt, iterations: 1),
        throwsFormatException,
      );
      expect(
        () => derivation.derive(pin: 'abcdef', salt: validSalt, iterations: 1),
        throwsFormatException,
      );
    });

    test('Throws FormatException on empty salt', () async {
      expect(
        () => derivation.derive(pin: '123456', salt: Uint8List(0), iterations: 1),
        throwsFormatException,
      );
    });

    test('Throws FormatException on zero or negative iterations', () async {
      expect(
        () => derivation.derive(pin: '123456', salt: validSalt, iterations: 0),
        throwsFormatException,
      );
      expect(
        () => derivation.derive(pin: '123456', salt: validSalt, iterations: -5),
        throwsFormatException,
      );
    });

    test('Derives 32-byte key via background isolate execution', () async {
      final derived = await derivation.derive(
        pin: '654321',
        salt: validSalt,
        iterations: 10,
        keyLength: 32,
      );
      expect(derived.length, equals(32));

      final syncDerived = VaultPbkdf2Derivation.deriveSynchronous(
        passwordBytes: utf8.encode('654321'),
        saltBytes: validSalt,
        iterations: 10,
        keyLength: 32,
      );
      expect(derived, equals(syncDerived));
    });
  });

  group('VaultPbkdf2Derivation Utility Functions', () {
    test('generateSalt produces non-zero length distinct random buffers', () {
      final s1 = VaultPbkdf2Derivation.generateSalt(length: 32);
      final s2 = VaultPbkdf2Derivation.generateSalt(length: 32);
      expect(s1.length, equals(32));
      expect(s2.length, equals(32));
      expect(s1, isNot(equals(s2)));
    });

    test('constantTimeEquals returns true for identical buffers', () {
      final b1 = Uint8List.fromList([1, 2, 3, 4, 5]);
      final b2 = Uint8List.fromList([1, 2, 3, 4, 5]);
      expect(VaultPbkdf2Derivation.constantTimeEquals(b1, b2), isTrue);
    });

    test('constantTimeEquals returns false for different buffers and lengths', () {
      final b1 = Uint8List.fromList([1, 2, 3, 4, 5]);
      final b2 = Uint8List.fromList([1, 2, 3, 4, 6]);
      final b3 = Uint8List.fromList([1, 2, 3, 4]);
      expect(VaultPbkdf2Derivation.constantTimeEquals(b1, b2), isFalse);
      expect(VaultPbkdf2Derivation.constantTimeEquals(b1, b3), isFalse);
    });
  });
}
