import 'dart:typed_data';

/// Abstract HTTP transport for Spotify spclient endpoints.
///
/// Consumers depend on this interface and never interact with auth tokens,
/// refresh mechanics, or platform identity headers. Implementations handle
/// all of that transparently.
///
/// Two concrete implementations exist:
///   - [WebPlayerTransport]: Chrome/WebPlayer identity headers
///   - [AndroidTransport]: Android app identity headers
abstract class SpotifyTransport {
  /// GET request to spclient, returns raw response bytes or null on failure.
  Future<Uint8List?> get(
    String path, {
    Map<String, String>? extraHeaders,
  });

  /// POST request to spclient, returns raw response bytes or null on failure.
  Future<Uint8List?> post(
    String path,
    Uint8List body, {
    Map<String, String>? extraHeaders,
    String contentType = 'application/x-protobuf',
  });
}
