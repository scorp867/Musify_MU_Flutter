import 'dart:async';
import 'dart:typed_data';

/// Abstract transport interface for Spotify Esperanto RPC communication (from Spotify Transport.java & ClientBase.java).
abstract class EsperantoTransport {
  /// Calls an asynchronous single-response Esperanto RPC method.
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  );

  /// Subscribes to a streaming Esperanto RPC method returning continuous events.
  Stream<Uint8List> callStream(
    String service,
    String method,
    Uint8List payload,
  );

  /// Executes a synchronous Esperanto RPC method.
  Uint8List callSync(
    String service,
    String method,
    Uint8List payload,
  );
}

/// Base client for Esperanto services matching com.spotify.esperanto.esperanto.ClientBase.
class EsperantoClientBase {
  final EsperantoTransport transport;

  const EsperantoClientBase(this.transport);

  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) {
    return transport.callSingle(service, method, payload);
  }

  Stream<Uint8List> callStream(
    String service,
    String method,
    Uint8List payload,
  ) {
    return transport.callStream(service, method, payload);
  }

  Uint8List callSync(
    String service,
    String method,
    Uint8List payload,
  ) {
    return transport.callSync(service, method, payload);
  }
}

/// In-memory transport implementation for development, offline playback, and testing.
class InMemoryEsperantoTransport implements EsperantoTransport {
  final Map<String, StreamController<Uint8List>> _streamControllers = {};

  StreamController<Uint8List> _getOrCreateController(String key) {
    return _streamControllers.putIfAbsent(
      key,
      () => StreamController<Uint8List>.broadcast(),
    );
  }

  void pushEvent(String service, String method, Uint8List payload) {
    final key = '$service/$method';
    _getOrCreateController(key).add(payload);
  }

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    return Uint8List(0);
  }

  @override
  Stream<Uint8List> callStream(
    String service,
    String method,
    Uint8List payload,
  ) {
    final key = '$service/$method';
    return _getOrCreateController(key).stream;
  }

  @override
  Uint8List callSync(
    String service,
    String method,
    Uint8List payload,
  ) {
    return Uint8List(0);
  }

  void dispose() {
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }
}
