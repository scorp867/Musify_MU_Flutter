import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show immutable, visibleForTesting;
import 'package:path_provider/path_provider.dart';

import '../config/runtime_context.dart';
import '../kodiak/dataloader/data_pool.dart';
import '../kodiak/dataloader/data_pool_impl.dart';
import '../network/auth/token_refresh_mutex.dart';
import '../network/spotify/auth/auth_session_provider.dart';
import '../network/spotify/auth/spotify_token_store.dart';
import 'musify_ffi_bindings.dart';

/// Structured native auth refresh reason codes posted on `auth_refresh_port_`
/// by C++ `AuthSessionStore::requestTokenRefreshAndWait` (`#47 §1`, `#57`).
enum NativeAuthRefreshReason {
  /// Standard HTTP 401 access token rejection (`1`).
  accessToken401(1),

  /// `client-token-error` response header requiring forced client-token refresh (`2`).
  clientTokenError(2),

  /// Dealer WebSocket HTTP 401/403 upgrade rejection (`3`).
  dealerWs401(3);

  final int code;

  const NativeAuthRefreshReason(this.code);

  static NativeAuthRefreshReason? tryFromCode(int code) {
    if (code == 1) return NativeAuthRefreshReason.accessToken401;
    if (code == 2) return NativeAuthRefreshReason.clientTokenError;
    if (code == 3) return NativeAuthRefreshReason.dealerWs401;
    return null;
  }
}

/// Typed failure emitted when a native-initiated auth refresh cannot complete.
@immutable
final class NativeAuthRefreshFailure {
  final NativeAuthRefreshReason reason;
  final Object error;
  final StackTrace stackTrace;
  final DateTime timestamp;

  const NativeAuthRefreshFailure({
    required this.reason,
    required this.error,
    required this.stackTrace,
    required this.timestamp,
  });
}

enum _BridgeLifecycle {
  uninitialized,
  initializing,
  active,
  disposed,
}

/// Bridges Dart authentication, active client header profile, market context,
/// cache directory, and Kodiak binary metadata extensions (`10`, `12`, `212`)
/// into `libmusify_audio.so`.
///
/// Responsibilities:
/// 1. Pushes active [AuthClientProfileConfig] via `musify_set_client_profile`
///    strictly before `(accessToken, clientToken, spDc, country, catalogue,
///    acceptLanguage, cacheDir)` via `musify_set_auth_session` so native
///    listeners woken by session updates always observe the coherent profile.
/// 2. Listens on a Dart `ReceivePort` registered with `musify_set_auth_refresh_port`
///    and dispatches structured reason codes (`1 = access_token_401`,
///    `2 = client_token_error`, `3 = dealer_ws_401`) through a coalesced
///    sequential queue.
/// 3. Attaches a `RawPayloadObserver` on `DataPoolImpl` so playback-relevant
///    Kodiak protobuf payloads (`TrackV4` = 10, `EpisodeV4` = 12, `PlaybackTrait` = 212)
///    are seeded directly into C++ `TrackInfoProvider` for instant `< 30ms` head
///    chunk hits without polluting `ContextTrack.metadata`.
class NativePlaybackSessionBridge {
  final AuthSessionProvider _authSessionProvider;
  final SpotifyTokenStore _tokenStore;
  final RuntimeContext _runtimeContext;
  final TokenRefreshMutex _refreshMutex;
  final DataPool _dataPool;
  final Future<String> Function()? _cacheDirResolver;

  MusifyFfiBindings? _ffi;
  ReceivePort? _authRefreshPort;
  StreamSubscription<Object?>? _authRefreshSub;
  String _resolvedCacheDir = '';
  _BridgeLifecycle _lifecycle = _BridgeLifecycle.uninitialized;

  Future<void> _syncTail = Future<void>.value();
  Future<void> _refreshTail = Future<void>.value();
  Future<void>? _inFlightAccessTokenRefresh;
  Future<void>? _inFlightClientTokenRefresh;
  Future<void>? _kodiakDiskWarmFuture;

  final StreamController<NativeAuthRefreshFailure> _refreshFailureController =
      StreamController<NativeAuthRefreshFailure>.broadcast();

  NativePlaybackSessionBridge({
    required AuthSessionProvider authSessionProvider,
    required SpotifyTokenStore tokenStore,
    required RuntimeContext runtimeContext,
    required TokenRefreshMutex refreshMutex,
    required DataPool dataPool,
    MusifyFfiBindings? ffi,
    Future<String> Function()? cacheDirResolver,
  })  : _authSessionProvider = authSessionProvider,
        _tokenStore = tokenStore,
        _runtimeContext = runtimeContext,
        _refreshMutex = refreshMutex,
        _dataPool = dataPool,
        _ffi = ffi,
        _cacheDirResolver = cacheDirResolver;

  /// Broadcast stream of typed failures raised while servicing native auth
  /// refresh requests on `auth_refresh_port_`.
  Stream<NativeAuthRefreshFailure> get refreshFailures =>
      _refreshFailureController.stream;

  @visibleForTesting
  SendPort? get authRefreshSendPort {
    if (_authRefreshPort case final port?) {
      return port.sendPort;
    }
    return null;
  }

  Future<void> init() async {
    if (_lifecycle != _BridgeLifecycle.uninitialized) return;
    if (_ffi == null && !Platform.isAndroid) {
      return;
    }

    _lifecycle = _BridgeLifecycle.initializing;
    final ffi = switch (_ffi) {
      final providedFfi? => providedFfi,
      null => MusifyFfiBindings.instance,
    };
    _ffi = ffi;

    ffi.initDartApiDl(NativeApi.initializeApiDLData);

    final resolvedCacheDir = await _resolveNativeCacheDirectory();
    if (_lifecycle != _BridgeLifecycle.initializing) {
      return;
    }
    _resolvedCacheDir = resolvedCacheDir;
    _lifecycle = _BridgeLifecycle.active;

    final refreshPort = ReceivePort('musify_auth_refresh');
    _authRefreshPort = refreshPort;
    ffi.setAuthRefreshPort(refreshPort.sendPort.nativePort);
    _authRefreshSub = refreshPort.listen(_onNativeAuthRefreshRequested);

    _tokenStore.addChangeListener(_handleCredentialsChanged);
    _runtimeContext.addChangeListener(_handleCredentialsChanged);

    final pool = _dataPool;
    if (pool is DataPoolImpl) {
      pool.setRawPayloadObserver(_seedExtensionToNative);
    }

    await _ensureKodiakDiskWarmed();
    if (_lifecycle != _BridgeLifecycle.active) {
      return;
    }

    await syncSessionToNative();
  }

  Future<void> _ensureKodiakDiskWarmed() {
    if (_kodiakDiskWarmFuture case final existing?) {
      return existing;
    }
    final completer = Completer<void>();
    final future = completer.future;
    _kodiakDiskWarmFuture = future;

    _dataPool.ensureDiskLoaded().then(
      (_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_kodiakDiskWarmFuture, future)) {
          _kodiakDiskWarmFuture = null;
        }
        dev.log(
          '[PLAYBACK][CONNECT] NativePlaybackSessionBridge: Kodiak disk cache warm-up failed: $error',
          name: 'NativePlaybackSessionBridge',
          error: error,
          stackTrace: stackTrace,
        );
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    return future;
  }

  Future<String> _resolveNativeCacheDirectory() async {
    if (_cacheDirResolver case final customResolver?) {
      return customResolver();
    }
    final tempDir = await getTemporaryDirectory();
    final audioCacheDir = Directory(
      '${tempDir.path}${Platform.pathSeparator}musify_native_audio',
    );
    if (!await audioCacheDir.exists()) {
      await audioCacheDir.create(recursive: true);
    }
    return audioCacheDir.path;
  }

  void _handleCredentialsChanged() {
    if (_lifecycle != _BridgeLifecycle.active) return;
    unawaited(
      syncSessionToNative().then(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          dev.log(
            'NativePlaybackSessionBridge: credential-change sync failed: $error',
            name: 'NativePlaybackSessionBridge',
            error: error,
            stackTrace: stackTrace,
          );
        },
      ),
    );
  }

  /// Alias for [syncSessionToNative] for Wave 3 login/session lifecycle wiring.
  Future<void> syncAuthSession() => syncSessionToNative();

  /// Reads the active [AuthClientProfileConfig] and credentials from Dart
  /// storage and pushes them to native `AuthSessionStore` in deterministic
  /// FIFO order.
  Future<void> syncSessionToNative() {
    if (_lifecycle != _BridgeLifecycle.active) {
      return Future<void>.value();
    }
    return _enqueueSync(_executeSyncSessionToNative);
  }

  /// Deterministically clears credentials in native `AuthSessionStore` and
  /// resets the native client profile to [AuthClientProfileConfig.webPlayerDefault]
  /// (used during logout teardown).
  Future<void> clearNativeAuthSession() {
    if (_lifecycle != _BridgeLifecycle.active) {
      return Future<void>.value();
    }
    return _enqueueSync(_executeClearNativeAuthSession);
  }

  Future<void> _enqueueSync(Future<void> Function() task) {
    final previousTail = _syncTail;
    final tailCompleter = Completer<void>();
    final resultCompleter = Completer<void>();
    _syncTail = tailCompleter.future;

    () async {
      await previousTail;
      if (_lifecycle != _BridgeLifecycle.active) {
        if (!resultCompleter.isCompleted) {
          resultCompleter.complete();
        }
        return;
      }
      try {
        await task();
        if (!resultCompleter.isCompleted) {
          resultCompleter.complete();
        }
      } catch (error, stackTrace) {
        if (!resultCompleter.isCompleted) {
          resultCompleter.completeError(error, stackTrace);
        }
      }
    }()
        .whenComplete(() {
      if (!tailCompleter.isCompleted) {
        tailCompleter.complete();
      }
    });

    return resultCompleter.future;
  }

  Future<void> _executeSyncSessionToNative() async {
    if (_lifecycle != _BridgeLifecycle.active) return;
    final ffi = _ffi;
    if (ffi == null) return;

    await _ensureKodiakDiskWarmed();
    if (_lifecycle != _BridgeLifecycle.active) return;

    final profileConfig =
        await _authSessionProvider.getActiveClientProfileConfig();
    final rawAccessToken = await _tokenStore.getAccessToken();
    final rawClientToken = await _tokenStore.getClientToken();
    final rawSpDc = await _tokenStore.getSpDc();

    if (_lifecycle != _BridgeLifecycle.active) return;

    final accessToken = switch (rawAccessToken) {
      final token? => token,
      null => '',
    };
    final clientToken = switch (rawClientToken) {
      final token? => token,
      null => '',
    };
    final spDc = switch (rawSpDc) {
      final cookie? => cookie,
      null => '',
    };

    // Push client profile strictly BEFORE auth session so any native listener
    // woken by `musify_set_auth_session` observes the coherent client profile.
    _pushClientProfileToNative(ffi, profileConfig);
    _pushAuthSessionToNative(
      ffi: ffi,
      accessToken: accessToken,
      clientToken: clientToken,
      spDc: spDc,
    );
  }

  Future<void> _executeClearNativeAuthSession() async {
    if (_lifecycle != _BridgeLifecycle.active) return;
    final ffi = _ffi;
    if (ffi == null) return;

    _pushClientProfileToNative(ffi, AuthClientProfileConfig.webPlayerDefault);
    _pushAuthSessionToNative(
      ffi: ffi,
      accessToken: '',
      clientToken: '',
      spDc: '',
    );
  }

  void _pushClientProfileToNative(
    MusifyFfiBindings ffi,
    AuthClientProfileConfig profileConfig,
  ) {
    Pointer<Utf8> clientIdPtr = nullptr;
    Pointer<Utf8> appPlatformPtr = nullptr;
    Pointer<Utf8> appVersionPtr = nullptr;
    Pointer<Utf8> userAgentPtr = nullptr;

    try {
      clientIdPtr = profileConfig.clientId.toNativeUtf8();
      appPlatformPtr = profileConfig.appPlatform.toNativeUtf8();
      appVersionPtr = profileConfig.appVersion.toNativeUtf8();
      userAgentPtr = profileConfig.userAgent.toNativeUtf8();

      ffi.setClientProfile(
        clientId: clientIdPtr,
        appPlatform: appPlatformPtr,
        appVersion: appVersionPtr,
        userAgent: userAgentPtr,
        sendOriginHeaders: profileConfig.sendOriginHeaders ? 1 : 0,
      );
    } finally {
      if (userAgentPtr != nullptr) calloc.free(userAgentPtr);
      if (appVersionPtr != nullptr) calloc.free(appVersionPtr);
      if (appPlatformPtr != nullptr) calloc.free(appPlatformPtr);
      if (clientIdPtr != nullptr) calloc.free(clientIdPtr);
    }
  }

  void _pushAuthSessionToNative({
    required MusifyFfiBindings ffi,
    required String accessToken,
    required String clientToken,
    required String spDc,
  }) {
    Pointer<Utf8> accessPtr = nullptr;
    Pointer<Utf8> clientPtr = nullptr;
    Pointer<Utf8> spDcPtr = nullptr;
    Pointer<Utf8> countryPtr = nullptr;
    Pointer<Utf8> cataloguePtr = nullptr;
    Pointer<Utf8> langPtr = nullptr;
    Pointer<Utf8> cachePtr = nullptr;

    try {
      accessPtr = accessToken.toNativeUtf8();
      clientPtr = clientToken.toNativeUtf8();
      spDcPtr = spDc.toNativeUtf8();
      countryPtr = _runtimeContext.country.toNativeUtf8();
      cataloguePtr = _runtimeContext.catalogue.toNativeUtf8();
      langPtr = _runtimeContext.acceptLanguage.toNativeUtf8();
      cachePtr = _resolvedCacheDir.toNativeUtf8();

      ffi.setAuthSession(
        accessToken: accessPtr,
        clientToken: clientPtr,
        spDc: spDcPtr,
        country: countryPtr,
        catalogue: cataloguePtr,
        acceptLanguage: langPtr,
        cacheDir: cachePtr,
      );
    } finally {
      if (cachePtr != nullptr) calloc.free(cachePtr);
      if (langPtr != nullptr) calloc.free(langPtr);
      if (cataloguePtr != nullptr) calloc.free(cataloguePtr);
      if (countryPtr != nullptr) calloc.free(countryPtr);
      if (spDcPtr != nullptr) calloc.free(spDcPtr);
      if (clientPtr != nullptr) calloc.free(clientPtr);
      if (accessPtr != nullptr) calloc.free(accessPtr);
    }
  }

  void _onNativeAuthRefreshRequested(Object? message) {
    if (_lifecycle != _BridgeLifecycle.active) return;

    final NativeAuthRefreshReason? reason = switch (message) {
      final int code => NativeAuthRefreshReason.tryFromCode(code),
      _ => null,
    };

    if (reason == null) {
      dev.log(
        'NativePlaybackSessionBridge: unrecognized auth refresh reason payload: $message',
        name: 'NativePlaybackSessionBridge',
      );
      return;
    }

    unawaited(handleNativeAuthRefresh(reason));
  }

  /// Processes a structured native auth refresh signal (`1|2|3`) through a
  /// coalesced sequential queue so concurrent signals never stampede token
  /// endpoints or interleave native session writes.
  Future<void> handleNativeAuthRefresh(NativeAuthRefreshReason reason) {
    if (_lifecycle != _BridgeLifecycle.active) {
      return Future<void>.value();
    }

    switch (reason) {
      case NativeAuthRefreshReason.clientTokenError:
        if (_inFlightClientTokenRefresh case final inFlight?) {
          return inFlight;
        }
        final future = _enqueueRefresh(
          () => _executeClientTokenRefresh(reason),
        );
        _inFlightClientTokenRefresh = future;
        return future.whenComplete(() {
          if (identical(_inFlightClientTokenRefresh, future)) {
            _inFlightClientTokenRefresh = null;
          }
        });
      case NativeAuthRefreshReason.accessToken401:
      case NativeAuthRefreshReason.dealerWs401:
        if (_inFlightAccessTokenRefresh case final inFlight?) {
          return inFlight;
        }
        final future = _enqueueRefresh(
          () => _executeAccessTokenRefresh(reason),
        );
        _inFlightAccessTokenRefresh = future;
        return future.whenComplete(() {
          if (identical(_inFlightAccessTokenRefresh, future)) {
            _inFlightAccessTokenRefresh = null;
          }
        });
    }
  }

  Future<void> _enqueueRefresh(Future<void> Function() task) {
    final previousTail = _refreshTail;
    final tailCompleter = Completer<void>();
    _refreshTail = tailCompleter.future;

    () async {
      await previousTail;
      if (_lifecycle != _BridgeLifecycle.active) {
        return;
      }
      await task();
    }()
        .whenComplete(() {
      if (!tailCompleter.isCompleted) {
        tailCompleter.complete();
      }
    });

    return tailCompleter.future;
  }

  Future<void> _executeClientTokenRefresh(
    NativeAuthRefreshReason reason,
  ) async {
    try {
      final refreshedClientToken =
          await _authSessionProvider.forceRefreshClientToken();
      if (_lifecycle != _BridgeLifecycle.active) return;

      if (refreshedClientToken == null || refreshedClientToken.isEmpty) {
        _recordRefreshFailure(
          reason: reason,
          error: StateError(
            'forceRefreshClientToken returned an empty client token',
          ),
          stackTrace: StackTrace.current,
        );
        return;
      }

      await syncSessionToNative();
    } catch (error, stackTrace) {
      _recordRefreshFailure(
        reason: reason,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _executeAccessTokenRefresh(
    NativeAuthRefreshReason reason,
  ) async {
    try {
      final refreshedAccessToken = await _refreshMutex.lock(
        _authSessionProvider.refreshAccessToken,
      );
      if (_lifecycle != _BridgeLifecycle.active) return;

      if (refreshedAccessToken == null || refreshedAccessToken.isEmpty) {
        _recordRefreshFailure(
          reason: reason,
          error: StateError(
            'refreshAccessToken returned an empty access token (reason=${reason.name})',
          ),
          stackTrace: StackTrace.current,
        );
        return;
      }

      await _authSessionProvider.getClientToken();
      if (_lifecycle != _BridgeLifecycle.active) return;

      await syncSessionToNative();
    } catch (error, stackTrace) {
      _recordRefreshFailure(
        reason: reason,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _recordRefreshFailure({
    required NativeAuthRefreshReason reason,
    required Object error,
    required StackTrace stackTrace,
  }) {
    dev.log(
      'NativePlaybackSessionBridge: auth refresh failed '
      '(reason=${reason.name}, code=${reason.code}): $error',
      name: 'NativePlaybackSessionBridge',
      error: error,
      stackTrace: stackTrace,
    );
    if (!_refreshFailureController.isClosed) {
      _refreshFailureController.add(
        NativeAuthRefreshFailure(
          reason: reason,
          error: error,
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void _seedExtensionToNative(
    int extensionKind,
    String entityUri,
    Uint8List payload,
  ) {
    if (_lifecycle != _BridgeLifecycle.active ||
        entityUri.isEmpty ||
        payload.isEmpty) {
      return;
    }
    final ffi = _ffi;
    if (ffi == null) return;

    Pointer<Utf8> uriPtr = nullptr;
    Pointer<Uint8> payloadPtr = nullptr;
    try {
      uriPtr = entityUri.toNativeUtf8();
      payloadPtr = calloc<Uint8>(payload.length);
      payloadPtr.asTypedList(payload.length).setAll(0, payload);
      ffi.metadataSeedExtension(
        extensionKind,
        uriPtr,
        payloadPtr,
        payload.length,
      );
    } finally {
      if (payloadPtr != nullptr) calloc.free(payloadPtr);
      if (uriPtr != nullptr) calloc.free(uriPtr);
    }
  }

  void dispose() {
    if (_lifecycle == _BridgeLifecycle.disposed) return;
    final wasActive = _lifecycle == _BridgeLifecycle.active;
    _lifecycle = _BridgeLifecycle.disposed;
    _kodiakDiskWarmFuture = null;

    if (wasActive) {
      _tokenStore.removeChangeListener(_handleCredentialsChanged);
      _runtimeContext.removeChangeListener(_handleCredentialsChanged);

      final pool = _dataPool;
      if (pool is DataPoolImpl) {
        pool.setRawPayloadObserver(null);
      }

      if (_ffi case final ffi?) {
        ffi.setAuthRefreshPort(0);
      }
    }

    if (_authRefreshSub case final sub?) {
      _authRefreshSub = null;
      unawaited(sub.cancel());
    }
    if (_authRefreshPort case final port?) {
      _authRefreshPort = null;
      port.close();
    }
    if (!_refreshFailureController.isClosed) {
      unawaited(_refreshFailureController.close());
    }
  }
}
