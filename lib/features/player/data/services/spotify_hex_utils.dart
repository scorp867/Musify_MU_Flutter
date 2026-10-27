import 'dart:typed_data';

/// 1:1 replica of Spotify's internal hexadecimal conversion utility (`p199p/xel1.java` / `p/qnt0.java`).
///
/// Converts between raw 20-byte SHA-1 digests (`file_id`) and standard 40-character lowercase hex strings.
abstract final class SpotifyHexUtils {
  /// 1:1 replica of `xel1.f273706a` lowercase lookup table.
  static const List<String> _hexDigits = <String>[
    '0', '1', '2', '3', '4', '5', '6', '7',
    '8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
  ];

  /// 1:1 replica of `xel1.m91041z(byte[] bArr)` and `qnt0.r(byte[] bArr)`.
  ///
  /// Converts an audio file's 20-byte SHA-1 digest into a 40-character lowercase hexadecimal string.
  static String formatFileId(List<int>? bytes) {
    if (bytes == null || bytes.isEmpty) {
      return '';
    }

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < bytes.length; i++) {
      final int b = bytes[i] & 0xFF;
      buffer.write(_hexDigits[b >> 4]);
      buffer.write(_hexDigits[b & 0x0F]);
    }
    return buffer.toString();
  }

  /// Parses a 40-character hex string back into a 20-byte Uint8List.
  static Uint8List? parseFileId(String? hex) {
    if (hex == null || hex.length != 40) {
      return null;
    }

    final Uint8List result = Uint8List(20);
    for (int i = 0; i < 20; i++) {
      final int high = _charToNibble(hex.codeUnitAt(i * 2));
      final int low = _charToNibble(hex.codeUnitAt(i * 2 + 1));
      if (high == -1 || low == -1) {
        return null;
      }
      result[i] = (high << 4) | low;
    }
    return result;
  }

  static int _charToNibble(int charCode) {
    if (charCode >= 48 && charCode <= 57) {
      // '0' - '9'
      return charCode - 48;
    }
    if (charCode >= 97 && charCode <= 102) {
      // 'a' - 'f'
      return charCode - 97 + 10;
    }
    if (charCode >= 65 && charCode <= 70) {
      // 'A' - 'F'
      return charCode - 65 + 10;
    }
    return -1;
  }
}
