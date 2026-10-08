import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

/// Creates the lowest-latency, platform-native HTTP client adapter.
///
/// - Android: Google Cronet (Chromium network stack with HTTP/3, QUIC 0-RTT, and Brotli)
/// - iOS / macOS: Apple NSURLSession (Native connection pooling, background URLSession)
/// - Windows / Linux: Persistent IOHttpClientAdapter with TCP Keep-Alive and connection reuse
HttpClientAdapter createPlatformAdapter() {
  if (kIsWeb) {
    return HttpClientAdapter();
  }

  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    try {
      return NativeAdapter();
    } catch (e) {
      debugPrint('[NET] NativeAdapter unavailable ($e), falling back to IOHttpClientAdapter');
    }
  }

  // Windows Desktop / Linux / Fallback:
  final adapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.idleTimeout = const Duration(seconds: 30);
      client.connectionTimeout = const Duration(seconds: 15);
      client.maxConnectionsPerHost = 12;
      return client;
    },
  );

  return adapter;
}
