import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';

import '../config/runtime_context.dart';
import '../kodiak/dataloader/data_pool.dart';
import '../kodiak/dataloader/data_pool_impl.dart';
import '../network/auth/token_refresh_mutex.dart';
import '../network/spotify/auth/auth_session_provider.dart';
import '../network/spotify/auth/spotify_token_store.dart';
import 'musify_ffi_bindings.dart';

/// Bridges Dart authentication, market context, cache directory, and Kodiak
/// binary metadata extensions (`10`, `12`, `212`) into `libmusify_audio.so`.
///
/// Responsibilities:
/// 1. Pushes `(accessToken, clientToken, spDc, country, catalogue, acceptLanguage, cacheDir)`
///    into C++ `AuthSessionStore` and `DiskCache` via `musify_set_auth_session`.
/// 2. Listens on a Dart `ReceivePort` registered with `musify_set_auth_refresh_port`
///    to service C++ HTTP 401 token refresh signals via `TokenRefreshMutex`.
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
  bool _initialized = false;
  bool _disposed = false;

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

  Future<void> init() async {
    if (_initialized || _disposed) return;
    if (_ffi == null && !Platform.isAndroid) {
      return;
    }

    final ffi = switch (_ffi) {
      final providedFfi? => providedFfi,
      null => MusifyFfiBindings.instance,
    };
    _ffi = ffi;
    _initialized = true;

    ffi.initDartApiDl(NativeApi.initializeApiDLData);

    _resolvedCacheDir = await _resolveNativeCacheDirectory();

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

    await syncSessionToNative();
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
    if (_disposed || !_initialized) return;
    unawaited(syncSessionToNative());
  }

  Future<void> syncSessionToNative() async {
    if (_disposed || !_initialized) return;
    final ffi = _ffi;
    if (ffi == null) return;

    final rawAccessToken = await _tokenStore.getAccessToken();
    final rawClientToken = await _tokenStore.getClientToken();
    final rawSpDc = await _tokenStore.getSpDc();

    final accessToken = rawAccessToken != null ? rawAccessToken : '';
    final clientToken = rawClientToken != null ? rawClientToken : '';
    final spDc = rawSpDc != null ? rawSpDc : '';

    final accessPtr = accessToken.toNativeUtf8();
    final clientPtr = clientToken.toNativeUtf8();
    final spDcPtr = spDc.toNativeUtf8();
    final countryPtr = _runtimeContext.country.toNativeUtf8();
    final cataloguePtr = _runtimeContext.catalogue.toNativeUtf8();
    final langPtr = _runtimeContext.acceptLanguage.toNativeUtf8();
    final cachePtr = _resolvedCacheDir.toNativeUtf8();

    try {
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
      calloc.free(accessPtr);
      calloc.free(clientPtr);
      calloc.free(spDcPtr);
      calloc.free(countryPtr);
      calloc.free(cataloguePtr);
      calloc.free(langPtr);
      calloc.free(cachePtr);
    }
  }

  Future<void> _onNativeAuthRefreshRequested(Object? message) async {
    if (_disposed || !_initialized) return;
    try {
      final refreshedAccessToken = await _refreshMutex.lock(
        _authSessionProvider.refreshAccessToken,
      );
      if (refreshedAccessToken != null && refreshedAccessToken.isNotEmpty) {
        await _authSessionProvider.getClientToken();
        await syncSessionToNative();
      }
    } catch (e, st) {
      dev.log(
        'NativePlaybackSessionBridge: 401 refresh failed: $e',
        name: 'NativePlaybackSessionBridge',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _seedExtensionToNative(
    int extensionKind,
    String entityUri,
    Uint8List payload,
  ) {
    if (_disposed || !_initialized || entityUri.isEmpty || payload.isEmpty) {
      return;
    }
    final ffi = _ffi;
    if (ffi == null) return;

    final uriPtr = entityUri.toNativeUtf8();
    final payloadPtr = calloc<Uint8>(payload.length);
    try {
      payloadPtr.asTypedList(payload.length).setAll(0, payload);
      ffi.metadataSeedExtension(
        extensionKind,
        uriPtr,
        payloadPtr,
        payload.length,
      );
    } finally {
      calloc.free(uriPtr);
      calloc.free(payloadPtr);
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _tokenStore.removeChangeListener(_handleCredentialsChanged);
    _runtimeContext.removeChangeListener(_handleCredentialsChanged);

    final pool = _dataPool;
    if (pool is DataPoolImpl) {
      pool.setRawPayloadObserver(null);
    }

    if (_ffi case final ffi?) {
      ffi.setAuthRefreshPort(0);
    }

    _authRefreshSub?.cancel();
    _authRefreshPort?.close();
  }
}
