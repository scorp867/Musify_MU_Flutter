import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_memory_wiper.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';

void main() {
  group('VaultMemoryWiper: Allocation & Zeroing', () {
    test('allocateMutable creates zeroed mutable buffer', () {
      final buffer = VaultMemoryWiper.allocateMutable(16);
      expect(buffer.length, 16);
      expect(buffer.every((b) => b == 0), isTrue);

      buffer[0] = 0xAA;
      expect(buffer[0], 0xAA);
    });

    test('allocateMutable rejects negative length', () {
      expect(
        () => VaultMemoryWiper.allocateMutable(-1),
        throwsA(isA<VaultValidationFailure>()),
      );
    });

    test('copyToMutable creates detached mutable copy', () {
      final source = [1, 2, 3, 4, 5];
      final mutable = VaultMemoryWiper.copyToMutable(source);
      expect(mutable, source);

      mutable[0] = 99;
      expect(source[0], 1);
    });

    test('zeroBuffer wipes all bytes to 0', () {
      final buffer = Uint8List.fromList([10, 20, 30, 40, 50]);
      VaultMemoryWiper.zeroBuffer(buffer);
      expect(buffer.every((b) => b == 0), isTrue);
    });

    test('zeroBuffer handles empty buffer gracefully', () {
      final empty = Uint8List(0);
      expect(() => VaultMemoryWiper.zeroBuffer(empty), returnsNormally);
    });

    test('zeroBuffer throws VaultCryptoFailure on unmodifiable view', () {
      final original = Uint8List.fromList([1, 2, 3]);
      final unmodifiable = original.asUnmodifiableView();

      expect(
        () => VaultMemoryWiper.zeroBuffer(unmodifiable),
        throwsA(isA<VaultCryptoFailure>()),
      );
    });

    test('zeroBuffers wipes multiple buffers in sequence', () {
      final b1 = Uint8List.fromList([1, 2, 3]);
      final b2 = Uint8List.fromList([4, 5, 6]);

      VaultMemoryWiper.zeroBuffers([b1, b2]);
      expect(b1.every((b) => b == 0), isTrue);
      expect(b2.every((b) => b == 0), isTrue);
    });
  });

  group('VaultMemoryWiper: withPlaintextScope', () {
    test('executes action and wipes temporary buffer', () async {
      final plaintext = Uint8List.fromList([42, 43, 44]);
      late Uint8List capturedMutable;

      final result = await VaultMemoryWiper.withPlaintextScope<int>(
        plaintext: plaintext,
        action: (mutable) async {
          capturedMutable = mutable;
          expect(mutable[0], 42);
          return 999;
        },
      );

      expect(result, 999);
      expect(capturedMutable.every((b) => b == 0), isTrue);
    });

    test('guarantees temporary buffer is wiped even if action throws', () async {
      final plaintext = Uint8List.fromList([1, 2, 3]);
      late Uint8List capturedMutable;

      await expectLater(
        VaultMemoryWiper.withPlaintextScope<void>(
          plaintext: plaintext,
          action: (mutable) async {
            capturedMutable = mutable;
            throw Exception('Action failed');
          },
        ),
        throwsException,
      );

      expect(capturedMutable.every((b) => b == 0), isTrue);
    });

    test('wipes input buffer if wipeInputIfMutable is true', () async {
      final plaintext = Uint8List.fromList([7, 8, 9]);

      await VaultMemoryWiper.withPlaintextScope<void>(
        plaintext: plaintext,
        wipeInputIfMutable: true,
        action: (mutable) async {},
      );

      expect(plaintext.every((b) => b == 0), isTrue);
    });
  });

  group('VaultPlaintextBuffer: RAII Lifetime', () {
    test('allows reading bytes before zeroize', () {
      final holder = VaultPlaintextBuffer([1, 2, 3]);
      expect(holder.isZeroed, isFalse);
      expect(holder.bytes, [1, 2, 3]);
    });

    test('zeroize wipes buffer and prevents further access', () {
      final holder = VaultPlaintextBuffer([1, 2, 3]);
      holder.zeroize();
      expect(holder.isZeroed, isTrue);

      expect(
        () => holder.bytes,
        throwsA(isA<VaultCryptoFailure>()),
      );
    });
  });
}
