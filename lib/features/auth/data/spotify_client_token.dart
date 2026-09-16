import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:musify_mu/core/protocol/protobuf_utils.dart';
import 'package:musify_mu/features/auth/data/spotify_token_store.dart';

/// Fetches and manages the Spotify Client Token via the protobuf API.
///
/// Endpoint: POST https://clienttoken.spotify.com/v1/clienttoken
/// Request/Response: application/x-protobuf
///
/// Proto schema (from clienttoken_http.proto + connectivity.proto):
///   ClientTokenRequest { F1=request_type, F2=ClientDataRequest }
///   ClientDataRequest  { F1=client_version, F2=client_id, F3=ConnectivitySdkData }
///   ConnectivitySdkData { F1=PlatformSpecificData, F2=device_id }
///   PlatformSpecificData { F4=NativeDesktopWindowsData }
///   NativeDesktopWindowsData { F1=os_version, F3=os_build, F4=platform_id }
///
///   ClientTokenResponse { F1=response_type, F2=GrantedTokenResponse }
///   GrantedTokenResponse { F1=token, F2=expires_after_seconds, F3=refresh_after_seconds }
class SpotifyClientTokenFetcher {
  static const _url = 'https://clienttoken.spotify.com/v1/clienttoken';
  static const _clientId = 'd8a5ed958d274c2e8ee717e6a4b0971d';
  static const _clientVersion = '1.2.52.442';

  // Proto enum: REQUEST_CLIENT_DATA_REQUEST = 1
  static const _requestTypeClientData = 1;
  // Proto enum: RESPONSE_GRANTED_TOKEN_RESPONSE = 1
  static const _responseTypeGranted = 1;

  final SpotifyTokenStore _tokenStore;
  String? _deviceId;

  SpotifyClientTokenFetcher(this._tokenStore);

  /// Returns a valid client token, fetching a new one if needed.
  Future<String?> getClientToken() async {
    final cached = await _tokenStore.getClientToken();
    if (cached != null) return cached;
    return fetchClientToken();
  }

  /// Fetches a fresh client token from the protobuf endpoint.
  Future<String?> fetchClientToken() async {
    try {
      _deviceId ??= _generateDeviceId();
      final requestBytes = _buildRequest();

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/x-protobuf',
          'Accept': 'application/x-protobuf',
        },
        body: requestBytes,
      );

      if (response.statusCode != 200) {
        print('❌ ClientToken: HTTP ${response.statusCode}');
        return null;
      }

      return await _parseResponse(Uint8List.fromList(response.bodyBytes));
    } catch (e) {
      print('❌ ClientToken fetch failed: $e');
      return null;
    }
  }

  /// Builds the ClientTokenRequest protobuf message.
  Uint8List _buildRequest() {
    final writer = SpotifyProtoWriter();

    // F1 = request_type (REQUEST_CLIENT_DATA_REQUEST = 1)
    writer.writeInt32(1, _requestTypeClientData);

    // F2 = ClientDataRequest
    writer.writeSubmessage(2, (clientData) {
      // F1 = client_version
      clientData.writeString(1, _clientVersion);
      // F2 = client_id
      clientData.writeString(2, _clientId);
      // F3 = ConnectivitySdkData
      clientData.writeSubmessage(3, (connectivity) {
        // F1 = PlatformSpecificData
        connectivity.writeSubmessage(1, (platform) {
          // F4 = NativeDesktopWindowsData (oneof field 4)
          platform.writeSubmessage(4, (windows) {
            // F1 = os_version (10)
            windows.writeInt32(1, 10);
            // F3 = os_build (22621)
            windows.writeInt32(3, 22621);
            // F4 = platform_id (2 = Win32NT)
            windows.writeInt32(4, 2);
          });
        });
        // F2 = device_id
        connectivity.writeString(2, _deviceId!);
      });
    });

    return writer.toBytes();
  }

  /// Parses ClientTokenResponse and extracts the granted token.
  Future<String?> _parseResponse(Uint8List bytes) async {
    final reader = SpotifyProtoReader(bytes);
    int responseType = 0;
    Uint8List? grantedBytes;

    while (reader.hasMore()) {
      final tag = reader.readTag();
      if (tag == 0) break;
      final field = tag >> 3;
      final wt = tag & 0x7;

      if (field == 1 && wt == 0) {
        responseType = reader.readVarint();
      } else if (field == 2 && wt == 2) {
        grantedBytes = reader.readBytes();
      } else {
        reader.skipField(wt);
      }
    }

    if (responseType != _responseTypeGranted || grantedBytes == null) {
      print('❌ ClientToken: Unexpected response type $responseType');
      return null;
    }

    // Parse GrantedTokenResponse { F1=token, F2=expires_after }
    final grantedReader = SpotifyProtoReader(grantedBytes);
    String? token;

    while (grantedReader.hasMore()) {
      final tag = grantedReader.readTag();
      if (tag == 0) break;
      final field = tag >> 3;
      final wt = tag & 0x7;

      if (field == 1 && wt == 2) {
        token = grantedReader.readString();
      } else {
        grantedReader.skipField(wt);
      }
    }

    if (token != null && token.isNotEmpty) {
      await _tokenStore.saveClientToken(token);
      print('✅ ClientToken obtained (${token.length} chars)');
      return token;
    }

    print('❌ ClientToken: No token in granted response');
    return null;
  }

  String _generateDeviceId() {
    final rng = Random.secure();
    return List.generate(16, (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}
