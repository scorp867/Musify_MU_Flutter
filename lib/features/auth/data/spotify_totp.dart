import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Generates TOTP codes for Spotify's internal token endpoint.
///
/// The TOTP cipher is scraped from Spotify's web-player JS bundle at runtime,
/// cached in SharedPreferences, and used to produce 6-digit HMAC-SHA1 codes.
///
/// If the cipher has been rotated by Spotify, call [refreshCipher] to re-fetch.
/// No app update is ever required.
class SpotifyTotp {
  // ── TOTP parameters (RFC 6238) ─────────────────────────────────────────
  static const _period = 30; // seconds per window
  static const _digits = 6;

  // ── Cache settings ─────────────────────────────────────────────────────
  static const _cacheMaxAgeMs = 6 * 60 * 60 * 1000; // 6 hours
  static const _keySecret = 'cipher_secret';
  static const _keyVersion = 'cipher_version';
  static const _keyFetchedAt = 'cipher_fetched_at';

  // ── Hardcoded fallback (v61, confirmed Feb 2026) ───────────────────────
  static const _fallbackSecret = ''',7/*F("rLJ2oxaKL^f+E1xvP@N''';
  static const _fallbackVersion = 61;

  // ── Active cipher (in-memory) ──────────────────────────────────────────
  int _activeVersion = _fallbackVersion;
  late Uint8List _secretBytes;

  static final SpotifyTotp _instance = SpotifyTotp._();

  SpotifyTotp._() {
    _secretBytes = _deriveSecret(_fallbackSecret);
  }

  factory SpotifyTotp() => _instance;

  /// The version of the currently active cipher (used in `totpVer` param).
  int get version => _activeVersion;

  // ── Public API ─────────────────────────────────────────────────────────

  /// Generates a 6-digit TOTP code for the given [timestampMs].
  String generate(int timestampMs) {
    final counter = (timestampMs / 1000 / _period).floor();

    // Counter → 8-byte big-endian.
    final counterBytes = Uint8List(8);
    var c = counter;
    for (var i = 7; i >= 0; i--) {
      counterBytes[i] = c & 0xFF;
      c >>= 8;
    }

    // HMAC-SHA1.
    final hmacResult =
        Hmac(sha1, _secretBytes).convert(counterBytes).bytes;

    // Dynamic truncation (RFC 4226).
    final offset = hmacResult.last & 0x0F;
    final binary = ((hmacResult[offset] & 0x7F) << 24) |
        ((hmacResult[offset + 1] & 0xFF) << 16) |
        ((hmacResult[offset + 2] & 0xFF) << 8) |
        (hmacResult[offset + 3] & 0xFF);

    return (binary % pow(10, _digits).toInt()).toString().padLeft(_digits, '0');
  }

  /// Loads the cached cipher from SharedPreferences on app start.
  Future<void> loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final secret = prefs.getString(_keySecret);
    final version = prefs.getInt(_keyVersion);
    if (secret != null && secret.isNotEmpty && version != null && version > 0) {
      _setActiveCipher(secret, version);
    }
  }

  /// Ensures the cipher is fresh. Call before each token refresh attempt.
  /// If the cached cipher is recent (<6 hours), this is a no-op.
  Future<void> ensureFreshCipher() async {
    final prefs = await SharedPreferences.getInstance();
    final fetchedAt = prefs.getInt(_keyFetchedAt) ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - fetchedAt;
    if (age < _cacheMaxAgeMs) return;

    await _fetchAndCacheCipher();
  }

  /// Force-refresh the cipher. Call after a 401/403 on token refresh.
  Future<void> refreshCipher() async {
    await _fetchAndCacheCipher();
  }

  // ── Internal ───────────────────────────────────────────────────────────

  void _setActiveCipher(String secret, int version) {
    _activeVersion = version;
    _secretBytes = _deriveSecret(secret);
  }

  /// Derives the HMAC key bytes from a Spotify cipher string.
  ///
  /// Algorithm (from Spotify's JS):
  /// ```
  /// secretBytes[i] = secret[i].charCode XOR ((i % 33) + 9)
  /// ```
  /// Then join all resulting ints as digit strings → UTF-8 bytes.
  static Uint8List _deriveSecret(String secret) {
    final transformed = <int>[];
    for (var i = 0; i < secret.length; i++) {
      transformed.add(secret.codeUnitAt(i) ^ ((i % 33) + 9));
    }
    final keyString = transformed.map((v) => v.toString()).join();
    return Uint8List.fromList(utf8.encode(keyString));
  }

  /// Fetches the latest cipher from Spotify's web-player JS bundle.
  Future<void> _fetchAndCacheCipher() async {
    try {
      // Step 1: Find the web-player JS URL.
      final jsUrl = await _findWebPlayerJsUrl();
      if (jsUrl == null) return;

      // Step 2: Download the JS.
      final jsContent = await _fetchUrl(jsUrl);
      if (jsContent == null) return;

      // Step 3: Parse cipher entries.
      final entries = _parseCipherEntries(jsContent);
      if (entries.isEmpty) return;

      // Step 4: Use the highest version.
      entries.sort((a, b) => b.version.compareTo(a.version));
      final best = entries.first;

      // Step 5: Activate and persist.
      _setActiveCipher(best.secret, best.version);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySecret, best.secret);
      await prefs.setInt(_keyVersion, best.version);
      await prefs.setInt(
          _keyFetchedAt, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Keep current cipher on any failure.
    }
  }

  /// Finds the web-player.*.js URL from Spotify's HTML.
  Future<String?> _findWebPlayerJsUrl() async {
    const urls = [
      'https://open.spotify.com/collection/tracks',
      'https://open.spotify.com/browse/featured',
      'https://open.spotify.com/',
    ];
    final regex = RegExp(
        r'https://open\.spotifycdn\.com/cdn/build/web-player/web-player\.[a-f0-9]+\.js');

    for (final url in urls) {
      final html = await _fetchUrl(url, acceptHtml: true);
      if (html == null) continue;
      final match = regex.firstMatch(html);
      if (match != null) return match.group(0);
    }
    return null;
  }

  /// Parses {secret:'...',version:NN} entries from Spotify's minified JS.
  List<_CipherEntry> _parseCipherEntries(String js) {
    final results = <_CipherEntry>[];
    final regex = RegExp(
        r"""\{secret:(['"])((?:[^'"\\]|\\.)*)\1,version:(\d+)\}""");

    for (final match in regex.allMatches(js)) {
      final rawSecret = match
          .group(2)!
          .replaceAll("\\'", "'")
          .replaceAll('\\"', '"')
          .replaceAll('\\\\', '\\');
      final version = int.tryParse(match.group(3)!);
      if (version != null) {
        results.add(_CipherEntry(rawSecret, version));
      }
    }
    return results;
  }

  /// Simple HTTP GET with browser User-Agent.
  Future<String?> _fetchUrl(String urlString,
      {bool acceptHtml = false}) async {
    try {
      final headers = <String, String>{
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
      };
      if (acceptHtml) {
        headers['Accept'] = 'text/html,application/xhtml+xml';
      }

      final response =
          await http.get(Uri.parse(urlString), headers: headers);
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (_) {}
    return null;
  }
}

class _CipherEntry {
  final String secret;
  final int version;
  _CipherEntry(this.secret, this.version);
}
