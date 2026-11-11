import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

/// Service providing PBKDF2-HMAC-SHA256 key derivation offloaded to a background
/// Dart isolate via [Isolate.run] to ensure 60/120 FPS UI smoothness.
///
/// Strictly conforms to RFC 2898 / RFC 8018 and provides constant-time comparison
/// to eliminate timing side-channel attacks during PIN verification.
@immutable
class VaultPbkdf2Derivation {
  /// Default PBKDF2 iteration count (100,000 iterations per OWASP recommendations).
  static const int defaultIterations = 100000;

  /// Default derived key length in bytes (32 bytes = 256 bits).
  static const int defaultKeyLength = 32;

  /// Default salt length in bytes (32 bytes = 256 bits).
  static const int defaultSaltLength = 32;

  /// Constructs a [VaultPbkdf2Derivation] instance.
  const VaultPbkdf2Derivation();

  /// Derives an ephemeral cryptographic authentication token from a 6-digit [pin]
  /// and a unique [salt] using PBKDF2-HMAC-SHA256 offloaded to a background isolate.
  ///
  /// Throws [FormatException] if [pin] is not exactly 6 numeric digits, [salt] is empty,
  /// or [iterations] / [keyLength] are non-positive.
  Future<Uint8List> derive({
    required String pin,
    required Uint8List salt,
    int iterations = defaultIterations,
    int keyLength = defaultKeyLength,
  }) async {
    _validateInputs(
      pin: pin,
      salt: salt,
      iterations: iterations,
      keyLength: keyLength,
    );

    return Isolate.run<Uint8List>(() {
      final passwordBytes = utf8.encode(pin);
      return deriveSynchronous(
        passwordBytes: passwordBytes,
        saltBytes: salt,
        iterations: iterations,
        keyLength: keyLength,
      );
    });
  }

  /// Synchronous implementation of PBKDF2-HMAC-SHA256 conforming to RFC 2898 / RFC 8018.
  ///
  /// Intended for background isolate execution or direct synchronous evaluation in test harnesses.
  static Uint8List deriveSynchronous({
    required List<int> passwordBytes,
    required List<int> saltBytes,
    required int iterations,
    required int keyLength,
  }) {
    final hmac = Hmac(sha256, passwordBytes);
    const hLen = 32;
    final numBlocks = (keyLength + hLen - 1) ~/ hLen;
    final derivedKey = Uint8List(keyLength);
    var outputOffset = 0;

    for (var i = 1; i <= numBlocks; i++) {
      final blockInput = Uint8List(saltBytes.length + 4);
      blockInput.setRange(0, saltBytes.length, saltBytes);
      blockInput[saltBytes.length] = (i >> 24) & 0xFF;
      blockInput[saltBytes.length + 1] = (i >> 16) & 0xFF;
      blockInput[saltBytes.length + 2] = (i >> 8) & 0xFF;
      blockInput[saltBytes.length + 3] = i & 0xFF;

      var u = hmac.convert(blockInput).bytes;
      final t = Uint8List.fromList(u);

      for (var j = 1; j < iterations; j++) {
        u = hmac.convert(u).bytes;
        for (var k = 0; k < hLen; k++) {
          t[k] ^= u[k];
        }
      }

      final remaining = keyLength - outputOffset;
      final bytesToCopy = remaining < hLen ? remaining : hLen;
      derivedKey.setRange(outputOffset, outputOffset + bytesToCopy, t);
      outputOffset += bytesToCopy;
    }

    return derivedKey;
  }

  /// Performs constant-time equality comparison between two byte buffers [a] and [b].
  ///
  /// Prevents timing side-channel attacks by accumulating differences across all bytes
  /// regardless of where an inequality occurs.
  static bool constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Generates a cryptographically secure random salt of [length] bytes.
  static Uint8List generateSalt({int length = defaultSaltLength}) {
    if (length <= 0) {
      throw FormatException('Salt length must be positive: $length');
    }
    final random = Random.secure();
    final salt = Uint8List(length);
    for (var i = 0; i < length; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  static void _validateInputs({
    required String pin,
    required Uint8List salt,
    required int iterations,
    required int keyLength,
  }) {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw const FormatException('PIN must be exactly 6 numeric digits.');
    }
    if (salt.isEmpty) {
      throw const FormatException('Salt must not be empty.');
    }
    if (iterations <= 0) {
      throw FormatException('Iterations must be positive: $iterations');
    }
    if (keyLength <= 0) {
      throw FormatException('Key length must be positive: $keyLength');
    }
  }
}
