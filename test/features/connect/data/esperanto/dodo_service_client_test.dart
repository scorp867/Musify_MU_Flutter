import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/data/esperanto/dodo_service_client.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_dodos_messages.pb.dart'
    as dodos_pb;
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:protobuf/protobuf.dart';

final class _RecordedCall {
  final String kind;
  final String service;
  final String method;
  final Uint8List payload;

  const _RecordedCall({
    required this.kind,
    required this.service,
    required this.method,
    required this.payload,
  });
}

final class _RecordingEsperantoTransport implements EsperantoTransport {
  final List<_RecordedCall> calls = <_RecordedCall>[];

  Future<Uint8List> Function(
    String service,
    String method,
    Uint8List payload,
  )? onCallSingle;

  Stream<Uint8List> Function(
    String service,
    String method,
    Uint8List payload,
  )? onCallStream;

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    calls.add(
      _RecordedCall(
        kind: 'single',
        service: service,
        method: method,
        payload: Uint8List.fromList(payload),
      ),
    );
    final handler = onCallSingle;
    if (handler != null) {
      return handler(service, method, payload);
    }
    return Uint8List(0);
  }

  @override
  Stream<Uint8List> callStream(
    String service,
    String method,
    Uint8List payload,
  ) {
    calls.add(
      _RecordedCall(
        kind: 'stream',
        service: service,
        method: method,
        payload: Uint8List.fromList(payload),
      ),
    );
    final handler = onCallStream;
    if (handler != null) {
      return handler(service, method, payload);
    }
    return const Stream<Uint8List>.empty();
  }

  @override
  Uint8List callSync(
    String service,
    String method,
    Uint8List payload,
  ) {
    calls.add(
      _RecordedCall(
        kind: 'sync',
        service: service,
        method: method,
        payload: Uint8List.fromList(payload),
      ),
    );
    return Uint8List(0);
  }
}

void main() {
  final malformedBytes = Uint8List.fromList(<int>[0xFF, 0xFF, 0xFF, 0x7F]);

  group('DodoServiceClient (Item 135 — all 4 RPCs)', () {
    test('uses exact DodoService Esperanto serviceName', () {
      expect(
        DodoServiceClient.serviceName,
        'spotify.connect.esperanto.proto.DodoService',
      );
    });

    test('DodoSub RPC streams 0-byte empty list and frozen populated DodoSubResponse updates', () async {
      final transport = _RecordingEsperantoTransport();
      final controller = StreamController<Uint8List>();
      addTearDown(controller.close);
      transport.onCallStream = (service, method, payload) => controller.stream;

      final client = DodoServiceClient(transport);
      final responses = <dodos_pb.DodoSubResponse>[];
      final errors = <Object>[];
      final sub = client.dodoSub().listen(responses.add, onError: errors.add);
      addTearDown(sub.cancel);

      expect(transport.calls, hasLength(1));
      expect(transport.calls.single.kind, 'stream');
      expect(transport.calls.single.service, DodoServiceClient.serviceName);
      expect(transport.calls.single.method, 'DodoSub');
      expect(transport.calls.single.payload, isEmpty);

      controller.add(Uint8List(0));
      controller.add(
        Uint8List.fromList(
          dodos_pb.DodoSubResponse(
            dodos: <dodos_pb.SingleDodo>[
              dodos_pb.SingleDodo(
                dodoId: 'dodo-1',
                csId: 'cs-1',
                isPrimary: true,
                isBeingObserved: false,
              ),
              dodos_pb.SingleDodo(
                dodoId: 'dodo-2',
                csId: 'cs-2',
                isPrimary: false,
                isBeingObserved: true,
              ),
            ],
          ).writeToBuffer(),
        ),
      );
      controller.add(malformedBytes);
      await pumpEventQueue();

      expect(responses, hasLength(2));
      expect(responses[0].dodos, isEmpty);
      expect(responses[0].isFrozen, isTrue);

      expect(responses[1].dodos, hasLength(2));
      expect(responses[1].dodos[0].dodoId, 'dodo-1');
      expect(responses[1].dodos[0].csId, 'cs-1');
      expect(responses[1].dodos[0].isPrimary, isTrue);
      expect(responses[1].dodos[0].isBeingObserved, isFalse);
      expect(responses[1].dodos[1].dodoId, 'dodo-2');
      expect(responses[1].dodos[1].isBeingObserved, isTrue);
      expect(responses[1].isFrozen, isTrue);
      expect(
        () => responses[1].dodos.add(dodos_pb.SingleDodo(dodoId: 'dodo-3')),
        throwsUnsupportedError,
      );

      expect(errors.single, isA<InvalidProtocolBufferException>());
    });

    test('SwitchToDodo RPC serializes csId (including empty for native NOT_FOUND) and decodes all Status variants', () async {
      final transport = _RecordingEsperantoTransport();
      final client = DodoServiceClient(transport);

      expect(await client.switchToDodo('cs-99'), common_pb.Status.OK);
      expect(transport.calls.last.kind, 'single');
      expect(transport.calls.last.service, DodoServiceClient.serviceName);
      expect(transport.calls.last.method, 'SwitchToDodo');
      expect(
        dodos_pb.SwitchToDodoRequest.fromBuffer(transport.calls.last.payload)
            .csId,
        'cs-99',
      );

      transport.onCallSingle = (service, method, payload) async {
        final req = dodos_pb.SwitchToDodoRequest.fromBuffer(payload);
        if (req.csId.isEmpty) {
          return Uint8List.fromList(
            common_pb.StatusResponse(status: common_pb.Status.NOT_FOUND)
                .writeToBuffer(),
          );
        }
        return Uint8List(0);
      };
      expect(await client.switchToDodo(''), common_pb.Status.NOT_FOUND);

      for (final status in common_pb.Status.values) {
        transport.onCallSingle = (service, method, payload) async =>
            Uint8List.fromList(
              common_pb.StatusResponse(status: status).writeToBuffer(),
            );
        expect(await client.switchToDodo('cs-1'), status);
      }
    });

    test('CreateNewDodo and EndDodo RPCs send empty requests and decode 0-byte OK and non-OK Status', () async {
      final transport = _RecordingEsperantoTransport();
      final client = DodoServiceClient(transport);

      expect(await client.createNewDodo(), common_pb.Status.OK);
      expect(transport.calls.last.kind, 'single');
      expect(transport.calls.last.service, DodoServiceClient.serviceName);
      expect(transport.calls.last.method, 'CreateNewDodo');
      expect(transport.calls.last.payload, isEmpty);

      expect(await client.endDodo(), common_pb.Status.OK);
      expect(transport.calls.last.kind, 'single');
      expect(transport.calls.last.service, DodoServiceClient.serviceName);
      expect(transport.calls.last.method, 'EndDodo');
      expect(transport.calls.last.payload, isEmpty);

      transport.onCallSingle = (service, method, payload) async =>
          Uint8List.fromList(
            common_pb.StatusResponse(status: common_pb.Status.UNIMPLEMENTED)
                .writeToBuffer(),
          );
      expect(await client.createNewDodo(), common_pb.Status.UNIMPLEMENTED);
      expect(await client.endDodo(), common_pb.Status.UNIMPLEMENTED);
    });

    test('propagates transport exceptions and malformed wire bytes untouched', () async {
      final transport = _RecordingEsperantoTransport();
      final client = DodoServiceClient(transport);

      transport.onCallStream = (service, method, payload) =>
          throw StateError('transport invalidated');
      expect(client.dodoSub, throwsStateError);

      transport.onCallSingle = (service, method, payload) async =>
          throw UnsupportedError('unknown method');
      await expectLater(client.createNewDodo, throwsUnsupportedError);

      transport.onCallSingle = (service, method, payload) async =>
          throw const FormatException('decode failed');
      await expectLater(() => client.switchToDodo('cs-1'), throwsFormatException);

      transport.onCallSingle = (service, method, payload) async =>
          throw ArgumentError('invalid args');
      await expectLater(client.endDodo, throwsArgumentError);

      transport.onCallSingle = (service, method, payload) async => malformedBytes;
      await expectLater(
        () => client.switchToDodo('cs-1'),
        throwsA(isA<InvalidProtocolBufferException>()),
      );
      await expectLater(
        client.createNewDodo,
        throwsA(isA<InvalidProtocolBufferException>()),
      );
      await expectLater(
        client.endDodo,
        throwsA(isA<InvalidProtocolBufferException>()),
      );
    });
  });
}
