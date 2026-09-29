import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer';
import 'package:webview_flutter/webview_flutter.dart';

/// Inline WebView that loads Spotify's login page.
///
/// Captures the `sp_dc` cookie and Bearer token after successful login.
/// Embedded as a widget — NOT a full-screen route.
class SpotifyLoginWebView extends StatefulWidget {
  /// Called when both sp_dc cookie and Bearer token have been captured.
  final void Function(String spDcCookie, String bearerToken) onLoginSuccess;

  /// Called when the user cancels or an error occurs.
  final VoidCallback onCancel;

  const SpotifyLoginWebView({
    super.key,
    required this.onLoginSuccess,
    required this.onCancel,
  });

  @override
  State<SpotifyLoginWebView> createState() => _SpotifyLoginWebViewState();
}

class _SpotifyLoginWebViewState extends State<SpotifyLoginWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _capturedSpDc;
  String? _capturedToken;
  bool _loginCompleted = false;

  static const _loginUrl =
      'https://accounts.spotify.com/en/login?continue=https://open.spotify.com/';

  /// JS fetch interceptor — captures the first Bearer token from network calls.
  static const _fetchInterceptorJs = '''
    (function() {
      if (window._muIntercept) return;
      window._muIntercept = true;
      window._muTokenSent = false;

      const origFetch = window.fetch;
      window.fetch = async function(...args) {
        try {
          if (!window._muTokenSent) {
            const opts = args[1] || {};
            let token = null;

            const check = (h) => {
              if (!h) return;
              if (h instanceof Headers) {
                token = h.get('Authorization');
              } else if (typeof h === 'object') {
                for (const k of Object.keys(h)) {
                  if (k.toLowerCase() === 'authorization') token = h[k];
                }
              }
            };

            check(opts.headers);
            if (!token && args[0] instanceof Request) {
              check(args[0].headers);
            }

            if (token && token.startsWith('Bearer ') && !window._muTokenSent) {
              window._muTokenSent = true;
              MuBridge.postMessage(JSON.stringify({
                type: 'token',
                value: token.substring(7),
              }));
            }
          }
        } catch (_) {}
        return origFetch.apply(this, args);
      };
    })();
  ''';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/146.0.0.0 Safari/537.36',
      )
      ..addJavaScriptChannel(
        'MuBridge',
        onMessageReceived: _onJsBridgeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
            _controller.runJavaScript(_fetchInterceptorJs);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
            _controller.runJavaScript(_fetchInterceptorJs);
            _checkForLoginRedirect(url);
          },
        ),
      )
      ..loadRequest(Uri.parse(_loginUrl));
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  void _onJsBridgeMessage(JavaScriptMessage message) {
    if (_loginCompleted) return;
    try {
      final body = message.message;
      if (body.contains('"token"')) {
        final start = body.indexOf('"value":"') + 9;
        final end = body.indexOf('"', start);
        if (start > 8 && end > start) {
          _capturedToken = body.substring(start, end);
          _tryComplete();
        }
      }
    } catch (e) {
      log('WebView error: $e');
    }
  }

  /// Detects when Spotify redirects to open.spotify.com after login.
  /// Then extracts the sp_dc cookie from the native cookie store.
  Future<void> _checkForLoginRedirect(String url) async {
    if (_loginCompleted) return;
    if (!url.startsWith('https://open.spotify.com')) return;

    // The WebView has navigated to open.spotify.com — login succeeded.
    // sp_dc is HttpOnly so JS can't read it.
    // Use the native WebViewCookieManager to read it from the platform cookie store.
    await _extractSpDcCookie();
    
    if (!mounted) return;

    // Also call /api/token via XHR to get a fresh bearer token.
    _controller.runJavaScript('''
      (function() {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', 'https://open.spotify.com/api/token?reason=init&productType=web-player', true);
        xhr.withCredentials = true;
        xhr.onload = function() {
          if (xhr.status === 200) {
            try {
              var data = JSON.parse(xhr.responseText);
              MuBridge.postMessage(JSON.stringify({
                type: 'session',
                token: data.accessToken || '',
                isAnonymous: data.isAnonymous || true,
              }));
            } catch(e) {}
          }
        };
        xhr.send();
      })();
    ''');
  }

  /// Reads the sp_dc cookie from the platform's native cookie store.
  /// On Android, CookieManager.getInstance().getCookie() returns ALL cookies
  /// including HttpOnly ones (unlike document.cookie in JS).
  Future<void> _extractSpDcCookie() async {
    try {
      // On Android, we can use the platform's native CookieManager.
      // webview_flutter_android exposes this through the platform interface.
      // However, the simplest cross-platform approach is to use a JS trick:
      // make a fetch to /api/token and read the response which proves the
      // cookie is set. But we need the actual cookie VALUE for later refresh.
      //
      // Use Android's CookieManager via a method channel.
      final cookieStr = await _getNativeCookies('https://open.spotify.com');
      if (!mounted) return;
      if (cookieStr != null) {
        for (final part in cookieStr.split(';')) {
          final trimmed = part.trim();
          if (trimmed.startsWith('sp_dc=')) {
            final value = trimmed.substring(6);
            if (value.isNotEmpty && value.length > 10) {
              _capturedSpDc = 'sp_dc=$value';
              _tryComplete();
              return;
            }
          }
        }
      }

      // Fallback: try document.cookie (works if sp_dc is not HttpOnly
      // in some WebView configurations).
      final allCookiesJs = await _controller
          .runJavaScriptReturningResult('document.cookie') as String;
      if (!mounted) return;
      final allCookies = allCookiesJs.replaceAll('"', '');
      for (final part in allCookies.split(';')) {
        final trimmed = part.trim();
        if (trimmed.startsWith('sp_dc=')) {
          final value = trimmed.substring(6);
          if (value.isNotEmpty && value.length > 10) {
            _capturedSpDc = 'sp_dc=$value';
            _tryComplete();
            return;
          }
        }
      }
    } catch (e) {
      log('WebView error: $e');
    }
  }

  /// Uses Android's native CookieManager to get all cookies for a URL.
  /// This includes HttpOnly cookies that JS can't access.
  Future<String?> _getNativeCookies(String url) async {
    try {
      // webview_flutter_android's underlying Android CookieManager
      // is accessible through the platform controller.
      // On Android, we use a JS XMLHttpRequest to read the cookies
      // from a same-origin request's getAllResponseHeaders().
      //
      // Better approach: use the platform-specific Android CookieManager.
      const channel = MethodChannel('com.musify.mu/cookies');
      final result = await channel.invokeMethod<String>('getCookies', url);
      return result;
    } catch (e) {
      // Method channel not registered — try alternative.
      log('WebView error: $e');
      return null;
    }
  }

  void _tryComplete() {
    if (_loginCompleted) return;

    if (_capturedToken != null && _capturedSpDc != null) {
      _loginCompleted = true;
      widget.onLoginSuccess(_capturedSpDc!, _capturedToken!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cancel bar
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close, color: Colors.white70, size: 22),
              ),
              const Expanded(
                child: Text(
                  'Connect to Spotify',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),

        // WebView in a rounded card
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1DB954),
                      strokeWidth: 2.5,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
