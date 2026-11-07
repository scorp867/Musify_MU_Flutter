import 'dart:typed_data';

/// 1:1 implementation of Spotify Android's Base62 GID codec (`p199p/rr9.java`).
abstract final class SpotifyBase62 {
  static const String _alphabet =
      '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// Encodes a 16-byte Spotify GID into a 22-character Base62 ID (`rr9.m76912a`).
  static String encode16ByteGid(List<int> gidBytes) {
    if (gidBytes.length != 16) {
      throw FormatException(
        'Invalid Spotify GID length: expected 16 bytes, got ${gidBytes.length}',
      );
    }

    BigInt value = BigInt.zero;
    for (int i = 0; i < 16; i++) {
      value = (value << 8) | BigInt.from(gidBytes[i] & 0xFF);
    }

    final BigInt base = BigInt.from(62);
    final List<int> codeUnits = List<int>.filled(22, 48);
    for (int i = 21; i >= 0; i--) {
      final int remainder = (value % base).toInt();
      value = value ~/ base;
      codeUnits[i] = _alphabet.codeUnitAt(remainder);
    }

    return String.fromCharCodes(codeUnits);
  }

  /// Decodes a 22-character Base62 Spotify ID into its 16-byte GID.
  static Uint8List decode22CharId(String base62Id) {
    if (base62Id.length != 22) {
      throw FormatException(
        'Invalid Spotify Base62 ID length: expected 22 chars, got ${base62Id.length}',
      );
    }

    BigInt value = BigInt.zero;
    final BigInt base = BigInt.from(62);

    for (int i = 0; i < 22; i++) {
      final int cu = base62Id.codeUnitAt(i);
      final int digit;
      if (cu >= 48 && cu <= 57) {
        digit = cu - 48;
      } else if (cu >= 97 && cu <= 122) {
        digit = cu - 97 + 10;
      } else if (cu >= 65 && cu <= 90) {
        digit = cu - 65 + 36;
      } else {
        throw FormatException(
          'Invalid character in Spotify Base62 ID at index $i',
        );
      }
      value = (value * base) + BigInt.from(digit);
    }

    final Uint8List out = Uint8List(16);
    for (int i = 15; i >= 0; i--) {
      out[i] = (value & BigInt.from(0xFF)).toInt();
      value = value >> 8;
    }
    return out;
  }

  /// Converts a 22-character Base62 Spotify ID into a 32-character lowercase hex GID.
  static String base62ToHexGid(String base62Id) {
    final bytes = decode22CharId(base62Id);
    final sb = StringBuffer();
    for (int i = 0; i < bytes.length; i++) {
      sb.write(bytes[i].toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}
