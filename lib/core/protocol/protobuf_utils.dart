import 'dart:typed_data';
import 'dart:convert';

/// A minimal Protobuf reader for internal Spotify protocol parsing.
///
/// Handles raw wire format without generated code — needed because
/// Casita and other spclient endpoints return undocumented protobuf.
class SpotifyProtoReader {
  final Uint8List _buf;
  final ByteData _bd;
  int _pos = 0;

  SpotifyProtoReader(this._buf)
      : _bd = ByteData.view(_buf.buffer, _buf.offsetInBytes, _buf.length);

  void reset([int pos = 0]) => _pos = pos;
  int get pos => _pos;

  int peekTag() {
    final oldPos = _pos;
    final tag = readTag();
    _pos = oldPos;
    return tag;
  }

  bool hasMore() => _pos < _buf.length;

  int readTag() {
    if (!hasMore()) return 0;
    return readVarint();
  }

  int readVarint() {
    int result = 0;
    int shift = 0;
    while (_pos < _buf.length) {
      final b = _buf[_pos++];
      result |= (b & 0x7f) << shift;
      if ((b & 0x80) == 0) return result;
      shift += 7;
      if (shift >= 64) return 0;
    }
    return result;
  }

  /// ZigZag decoded varint.
  int readSint() {
    final n = readVarint();
    return (n >> 1) ^ -(n & 1);
  }

  int readFixed32() {
    final res = _bd.getUint32(_pos, Endian.little);
    _pos += 4;
    return res;
  }

  int readFixed64() {
    final res = _bd.getUint64(_pos, Endian.little);
    _pos += 8;
    return res;
  }

  Uint8List readBytes() {
    if (!hasMore()) return Uint8List(0);
    final len = readVarint();
    if (_pos + len > _buf.length) {
      final res = _buf.sublist(_pos);
      _pos = _buf.length;
      return res;
    }
    final res = _buf.sublist(_pos, _pos + len);
    _pos += len;
    return res;
  }

  String readString() {
    final b = readBytes();
    if (b.isEmpty) return '';
    return utf8.decode(b, allowMalformed: true);
  }

  void skipField(int wireType) {
    switch (wireType) {
      case 0: // Varint
        if (!hasMore()) return;
        readVarint();
        break;
      case 1: // 64-bit
        _pos += 8;
        if (_pos > _buf.length) _pos = _buf.length;
        break;
      case 2: // Length-delimited
        if (!hasMore()) return;
        final len = readVarint();
        _pos += len;
        if (_pos > _buf.length) _pos = _buf.length;
        break;
      case 3: // Start group (deprecated)
        while (hasMore()) {
          final tag = readTag();
          final innerWt = tag & 0x7;
          if (innerWt == 4) return;
          skipField(innerWt);
        }
        break;
      case 5: // 32-bit
        _pos += 4;
        if (_pos > _buf.length) _pos = _buf.length;
        break;
      case 4: // End group
        break;
    }
  }
}

/// A minimal Protobuf writer for internal Spotify protocol building.
class SpotifyProtoWriter {
  final List<int> _buf = [];

  Uint8List toBytes() => Uint8List.fromList(_buf);

  void _writeVarint(int value) {
    int v = value;
    if (v < 0) v = v.toUnsigned(64);
    while (v >= 0x80) {
      _buf.add((v & 0x7f) | 0x80);
      v >>= 7;
    }
    _buf.add(v);
  }

  void _writeTag(int field, int wireType) {
    _writeVarint((field << 3) | wireType);
  }

  void writeInt32(int field, int value) {
    if (value == 0) return;
    _writeTag(field, 0);
    _writeVarint(value);
  }

  void writeInt32Force(int field, int value) {
    _writeTag(field, 0);
    _writeVarint(value);
  }

  void writeBool(int field, bool value) {
    _writeTag(field, 0);
    _writeVarint(value ? 1 : 0);
  }

  void writeString(int field, String value) {
    if (value.isEmpty) return;
    final bytes = utf8.encode(value);
    _writeTag(field, 2);
    _writeVarint(bytes.length);
    _buf.addAll(bytes);
  }

  void writeBytes(int field, Uint8List value) {
    if (value.isEmpty) return;
    _writeTag(field, 2);
    _writeVarint(value.length);
    _buf.addAll(value);
  }

  /// Writes a nested submessage built by a callback.
  void writeSubmessage(
      int field, void Function(SpotifyProtoWriter sub) builder) {
    final sub = SpotifyProtoWriter();
    builder(sub);
    final bytes = sub.toBytes();
    _writeTag(field, 2);
    _writeVarint(bytes.length);
    _buf.addAll(bytes);
  }

  void writeVarint(int field, int value) {
    _writeTag(field, 0);
    _writeVarint(value);
  }
}

// ═══════════════════════════════════════════════════════════════════
// Navigation helpers (used by parsers like CasitaParser)
// ═══════════════════════════════════════════════════════════════════

/// Navigate into a specific field, returning its payload bytes (first match).
Uint8List? protoNavTo(Uint8List bytes, int targetField) {
  if (bytes.isEmpty) return null;
  final reader = SpotifyProtoReader(bytes);
  while (reader.hasMore()) {
    final tag = reader.readTag();
    if (tag == 0) break;
    final field = tag >> 3;
    final wt = tag & 0x7;

    if (field == targetField && wt == 2) {
      return reader.readBytes();
    }
    reader.skipField(wt);
  }
  return null;
}

/// Collect all repeated instances of a length-delimited field.
List<Uint8List> protoCollectField(Uint8List bytes, int targetField) {
  final results = <Uint8List>[];
  if (bytes.isEmpty) return results;
  final reader = SpotifyProtoReader(bytes);
  while (reader.hasMore()) {
    final tag = reader.readTag();
    if (tag == 0) break;
    final field = tag >> 3;
    final wt = tag & 0x7;

    if (field == targetField && wt == 2) {
      results.add(reader.readBytes());
    } else {
      reader.skipField(wt);
    }
  }
  return results;
}

/// Read a string from a specific field number (first match).
String? protoReadStringField(Uint8List bytes, int targetField) {
  if (bytes.isEmpty) return null;
  final reader = SpotifyProtoReader(bytes);
  while (reader.hasMore()) {
    final tag = reader.readTag();
    if (tag == 0) break;
    final field = tag >> 3;
    final wt = tag & 0x7;

    if (field == targetField && wt == 2) {
      return reader.readString();
    }
    reader.skipField(wt);
  }
  return null;
}
