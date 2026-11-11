import 'dart:typed_data';

import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';

/// Cryptographic memory management and zeroing utility for the Secure Vault.
///
/// Guarantees that sensitive plaintext buffers, decrypted database rows, and intermediate
/// serializations residing in Dart RAM are zeroized immediately upon vault lock or after
/// transient cryptographic processing.
///
/// Defensively validates `Uint8List` mutability so that calling `fillRange(0, length, 0)`
/// does not crash on unmodifiable views, while detecting illegal unmodifiable allocations.
abstract final class VaultMemoryWiper {
  /// Allocates a new, guaranteed-mutable [Uint8List] initialized to all zeros.
  ///
  /// Throws [VaultValidationFailure] if [length] is negative.
  static Uint8List allocateMutable(int length) {
    if (length < 0) {
      throw VaultValidationFailure(
        'Cannot allocate negative buffer length: $length',
      );
    }
    return Uint8List(length);
  }

  /// Copies an arbitrary [source] byte sequence into a dedicated, guaranteed-mutable [Uint8List].
  static Uint8List copyToMutable(List<int> source) {
    return Uint8List.fromList(source);
  }

  /// Immediately zeros all bytes within [buffer] from index 0 to length - 1.
  ///
  /// Uses native [Uint8List.fillRange] to overwrite memory with zero bytes.
  /// Throws [VaultCryptoFailure] if [buffer] is an unmodifiable view, ensuring memory
  /// security violations are surfaced rather than silently ignored.
  static void zeroBuffer(Uint8List buffer) {
    if (buffer.isEmpty) {
      return;
    }

    try {
      buffer.fillRange(0, buffer.length, 0);
    } on UnsupportedError catch (error) {
      throw VaultCryptoFailure(
        'Critical Memory Security Violation: Attempted to zero an unmodifiable Uint8List buffer view in RAM.',
        cause: error,
      );
    }
  }

  /// Attempts to zero [buffer] if non-null and non-empty.
  static void tryZeroBuffer(Uint8List? buffer) {
    if (buffer != null) {
      zeroBuffer(buffer);
    }
  }

  /// Wipes all byte buffers in [buffers] in sequence.
  static void zeroBuffers(Iterable<Uint8List> buffers) {
    for (final buffer in buffers) {
      zeroBuffer(buffer);
    }
  }

  /// Executes [action] within a protected plaintext scope, guaranteeing that the temporary
  /// mutable buffer is zeroized in a `finally` block even if an exception is thrown.
  ///
  /// If [wipeInputIfMutable] is `true`, also attempts to wipe the input [plaintext] buffer.
  static Future<T> withPlaintextScope<T>({
    required Uint8List plaintext,
    required Future<T> Function(Uint8List mutableBuffer) action,
    bool wipeInputIfMutable = false,
  }) async {
    final mutableBuffer = copyToMutable(plaintext);
    try {
      return await action(mutableBuffer);
    } finally {
      zeroBuffer(mutableBuffer);
      if (wipeInputIfMutable) {
        try {
          zeroBuffer(plaintext);
        } on VaultCryptoFailure {
          // Input was an unmodifiable view; temporary mutable copy was already wiped
        }
      }
    }
  }

  /// Synchronous variant of [withPlaintextScope].
  static T withPlaintextScopeSync<T>({
    required Uint8List plaintext,
    required T Function(Uint8List mutableBuffer) action,
    bool wipeInputIfMutable = false,
  }) {
    final mutableBuffer = copyToMutable(plaintext);
    try {
      return action(mutableBuffer);
    } finally {
      zeroBuffer(mutableBuffer);
      if (wipeInputIfMutable) {
        try {
          zeroBuffer(plaintext);
        } on VaultCryptoFailure {
          // Input was an unmodifiable view; temporary mutable copy was already wiped
        }
      }
    }
  }
}

/// An ephemeral RAII wrapper holding a transient plaintext buffer.
///
/// Prevents reading buffer bytes after [zeroize] has been invoked.
final class VaultPlaintextBuffer {
  final Uint8List _bytes;
  bool _isZeroed = false;

  /// Creates a [VaultPlaintextBuffer] with a guaranteed-mutable copy of [bytes].
  VaultPlaintextBuffer(List<int> bytes) : _bytes = Uint8List.fromList(bytes);

  /// Accesses the underlying byte buffer.
  ///
  /// Throws [VaultCryptoFailure] if the buffer has already been zeroized.
  Uint8List get bytes {
    if (_isZeroed) {
      throw const VaultCryptoFailure(
        'Illegal access: VaultPlaintextBuffer has already been zeroized.',
      );
    }
    return _bytes;
  }

  /// Returns whether the buffer has been wiped.
  bool get isZeroed => _isZeroed;

  /// Length of the held byte buffer.
  int get length => _bytes.length;

  /// Immediately zeroes the held buffer and marks it as invalidated.
  void zeroize() {
    if (!_isZeroed) {
      VaultMemoryWiper.zeroBuffer(_bytes);
      _isZeroed = true;
    }
  }
}
