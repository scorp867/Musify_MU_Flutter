// 1:1 replica of DodoServiceImpl.cpp (lines 12–120), DodoServiceImpl.h,
// dodos_messages.proto, and liborbit-jni-spotify.so / liborbit-jni-spotify_memdump.so
// (0x16a9c9 `spotify.connect.esperanto.proto.DodoService`, 0xe3fdb4 dispatcher,
// 0x5a1dd0 / 0x36a536 `dodos_messages.proto`).

import 'dart:async';
import 'dart:typed_data';

import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_dodos_messages.pb.dart'
    as dodos_pb;
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    as empty_pb;

/// Pure Esperanto RPC and stream adapter for
/// `spotify.connect.esperanto.proto.DodoService` (4 RPCs).
///
/// Accepts valid 0-byte proto3 payloads (`DodoSubResponse(dodos: [])` and
/// `StatusResponse(status: Status.OK)`) and returns frozen protobuf responses
/// with zero cached Dodo state.
final class DodoServiceClient extends EsperantoClientBase {
  static const String serviceName =
      'spotify.connect.esperanto.proto.DodoService';

  const DodoServiceClient(super.transport);

  /// 1:1 with `DodoServiceImpl.cpp:51–64` (`DodoService.DodoSub` `callStream`).
  ///
  /// Returns deeply immutable (`..freeze()`) [dodos_pb.DodoSubResponse] events.
  Stream<dodos_pb.DodoSubResponse> dodoSub() {
    final payload = Uint8List.fromList(empty_pb.Empty().writeToBuffer());
    return callStream(serviceName, 'DodoSub', payload)
        .map((bytes) => dodos_pb.DodoSubResponse.fromBuffer(bytes)..freeze());
  }

  /// 1:1 with `DodoServiceImpl.cpp:66–87` (`DodoService.SwitchToDodo`
  /// `callSingle`).
  ///
  /// Passes [csId] directly on the wire to match native `DodoServiceImpl`
  /// semantics (empty `csId` returns `common_pb.Status.NOT_FOUND`).
  Future<common_pb.Status> switchToDodo(String csId) async {
    final request = dodos_pb.SwitchToDodoRequest(csId: csId);
    final payload = Uint8List.fromList(request.writeToBuffer());
    final responseBytes = await callSingle(serviceName, 'SwitchToDodo', payload);
    return common_pb.StatusResponse.fromBuffer(responseBytes).status;
  }

  /// 1:1 with `DodoServiceImpl.cpp:89–103` (`DodoService.CreateNewDodo`
  /// `callSingle`).
  Future<common_pb.Status> createNewDodo() async {
    final payload = Uint8List.fromList(
      dodos_pb.CreateNewDodoRequest().writeToBuffer(),
    );
    final responseBytes = await callSingle(
      serviceName,
      'CreateNewDodo',
      payload,
    );
    return common_pb.StatusResponse.fromBuffer(responseBytes).status;
  }

  /// 1:1 with `DodoServiceImpl.cpp:105–119` (`DodoService.EndDodo`
  /// `callSingle`).
  Future<common_pb.Status> endDodo() async {
    final payload = Uint8List.fromList(
      dodos_pb.EndDodoRequest().writeToBuffer(),
    );
    final responseBytes = await callSingle(serviceName, 'EndDodo', payload);
    return common_pb.StatusResponse.fromBuffer(responseBytes).status;
  }
}
