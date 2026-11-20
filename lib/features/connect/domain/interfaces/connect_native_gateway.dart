import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Wake/reconnect reason code passed to `musify_connect_reconnect(handle, reason_code)`
/// (`#47 §2.5`).
enum ConnectReconnectReason {
  /// App returned to foreground (`1`).
  foreground(1),

  /// Network connectivity was restored (`2`).
  networkRestored(2),

  /// Auth credentials or session were updated (`3`).
  authUpdated(3),

  /// Explicit user-triggered refresh/reconnect (`4`).
  manual(4);

  final int code;

  const ConnectReconnectReason(this.code);

  int get wireCode => code;

  static ConnectReconnectReason fromCode(int code) {
    switch (code) {
      case 1:
        return ConnectReconnectReason.foreground;
      case 2:
        return ConnectReconnectReason.networkRestored;
      case 3:
        return ConnectReconnectReason.authUpdated;
      case 4:
        return ConnectReconnectReason.manual;
      default:
        throw RangeError.range(
          code,
          1,
          4,
          'code',
          'Invalid ConnectReconnectReason code',
        );
    }
  }
}

/// Origin reason code passed to `musify_connect_set_local_volume(..., reason_code)`
/// (`#47 §2.8`).
enum ConnectLocalVolumeReason {
  /// User changed hardware volume (`0 = kUser -> PutState`).
  user(0),

  /// System/initial sync (`1 = kSystem -> sync only`).
  system(1);

  final int code;

  const ConnectLocalVolumeReason(this.code);

  int get wireCode => code;

  static ConnectLocalVolumeReason fromCode(int code) {
    switch (code) {
      case 0:
        return ConnectLocalVolumeReason.user;
      case 1:
        return ConnectLocalVolumeReason.system;
      default:
        throw RangeError.range(
          code,
          0,
          1,
          'code',
          'Invalid ConnectLocalVolumeReason code',
        );
    }
  }
}

/// Esperanto service identifier for non-blocking `musify_connect_call_async`
/// (`#47 §2.3`).
enum ConnectEsperantoServiceId {
  connectService(
    1,
    'spotify.connect.esperanto.proto.ConnectService',
  ),
  connectVolumeService(
    2,
    'spotify.connect.esperanto.proto.ConnectVolumeService',
  ),
  dodoService(
    3,
    'spotify.connect.esperanto.proto.DodoService',
  );

  final int id;
  final String serviceName;

  const ConnectEsperantoServiceId(this.id, this.serviceName);

  int get code => id;

  static ConnectEsperantoServiceId fromId(int id) {
    switch (id) {
      case 1:
        return ConnectEsperantoServiceId.connectService;
      case 2:
        return ConnectEsperantoServiceId.connectVolumeService;
      case 3:
        return ConnectEsperantoServiceId.dodoService;
      default:
        throw RangeError.range(
          id,
          1,
          3,
          'id',
          'Invalid ConnectEsperantoServiceId',
        );
    }
  }

  static ConnectEsperantoServiceId? tryFromServiceName(String serviceName) {
    switch (serviceName) {
      case 'spotify.connect.esperanto.proto.ConnectService':
      case 'ConnectService':
        return ConnectEsperantoServiceId.connectService;
      case 'spotify.connect.esperanto.proto.ConnectVolumeService':
      case 'ConnectVolumeService':
        return ConnectEsperantoServiceId.connectVolumeService;
      case 'spotify.connect.esperanto.proto.DodoService':
      case 'DodoService':
        return ConnectEsperantoServiceId.dodoService;
      default:
        return null;
    }
  }
}

/// Asynchronous reply posted by `musify_connect_call_async` (`#47 §2.3`).
@immutable
final class ConnectAsyncCallResult extends Equatable {
  /// Native `EsperantoCallStatus` code (`0 = kOk`).
  final int statusCode;

  /// Serialized protobuf response payload.
  final Uint8List payloadBytes;

  const ConnectAsyncCallResult({
    required this.statusCode,
    required this.payloadBytes,
  });

  bool get isOk => statusCode == 0;

  @override
  List<Object?> get props => [statusCode, payloadBytes];
}

/// Domain port abstracting the native C++ `ConnectSubsystem` FFI lifecycle,
/// endpoint routing, NSD local device reporting, OS volume sync, and
/// non-blocking Esperanto RPC execution (`#47 §2`, `#47 §5`).
abstract class ConnectNativeGateway {
  /// Starts the native `ConnectSubsystem` with serialized `DeviceInfo` wire
  /// bytes (`musify_connect_start`).
  ///
  /// Return codes:
  /// - `0`: started
  /// - `-1`: invalid args / empty payload
  /// - `-2`: protobuf decode error
  /// - `-3`: missing mandatory `DeviceInfo` fields (`device_id`, `name`, or `client_id`)
  int start(Uint8List deviceInfoBytes);

  /// Idempotently stops the native `ConnectSubsystem` (`musify_connect_stop`).
  void stop();

  /// Updates dynamic APResolve `spclient` and `dealer` endpoints
  /// (`musify_connect_set_endpoints`).
  int setEndpoints({
    required String spclientBaseUrl,
    required String dealerWsUrl,
  });

  /// Forces Dealer/Connect wakeup and cluster refresh (`musify_connect_reconnect`).
  int reconnect(ConnectReconnectReason reason);

  /// Notifies native Connect of OS network availability (`musify_connect_set_network_available`).
  void setNetworkAvailable(bool isAvailable);

  /// Feeds Android NSD `_spotify-connect._tcp.` services snapshot as a UTF-8
  /// JSON array into native `LocalDeviceReporter` (`musify_connect_update_nsd_services`).
  int updateNsdServices(String servicesJsonUtf8);

  /// Pushes OS `STREAM_MUSIC` volume (`0..65535`) and discrete step count into
  /// native `ConnectSubsystem` (`musify_connect_set_local_volume`).
  int setLocalVolume({
    required int volume0To65535,
    required int volumeSteps,
    required ConnectLocalVolumeReason reason,
  });

  /// Executes a non-blocking Connect Esperanto RPC on the native worker pool
  /// (`musify_connect_call_async`).
  Future<ConnectAsyncCallResult> callServiceAsync({
    required ConnectEsperantoServiceId serviceId,
    required String method,
    required Uint8List payload,
  });

  /// Stream of raw `LocalVolumeResponse` protobuf payloads emitted by native
  /// `ConnectSubsystem` when a remote peer changes this device's volume.
  Stream<Uint8List> get localVolumeStream;

  /// Stream of UTF-8 JSON diagnostic events emitted by native Connect
  /// (`musify_connect_set_diagnostic_port`).
  Stream<String> get diagnosticStream;

  /// Releases any resources held by this gateway.
  void dispose();
}
