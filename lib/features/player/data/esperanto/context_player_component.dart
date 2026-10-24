import 'context_player_control_client.dart';
import 'context_player_options_client.dart';
import 'context_player_play_client.dart';
import 'context_player_queue_client.dart';
import 'context_player_state_client.dart';
import 'esperanto_transport.dart';

/// 1:1 replica of Spotify ContextPlayer Dagger Component / Factory (p.t0m).
/// Instantiates, wires, and provides all ContextPlayer client subcomponents.
class ContextPlayerComponent {
  final EsperantoTransport transport;

  late final ContextPlayerControlClient controlsClient;
  late final ContextPlayerOptionsClient optionsClient;
  late final ContextPlayerPlayClient playClient;
  late final ContextPlayerQueueClient queueClient;
  late final ContextPlayerStateClient stateClient;

  ContextPlayerComponent(this.transport) {
    controlsClient = ContextPlayerControlClient(transport);
    optionsClient = ContextPlayerOptionsClient(transport);
    playClient = ContextPlayerPlayClient(transport);
    queueClient = ContextPlayerQueueClient(transport);
    stateClient = ContextPlayerStateClient(transport);
  }

  /// 1:1 with t0m.a() -> ContextPlayerControlClient (p.j4v)
  ContextPlayerControlClient a() => controlsClient;

  /// 1:1 with t0m.c() -> ContextPlayerOptionsClient (p.k4v)
  ContextPlayerOptionsClient c() => optionsClient;

  /// 1:1 with t0m.d() -> ContextPlayerPlayClient (p.y3v)
  ContextPlayerPlayClient d() => playClient;

  /// 1:1 with t0m.e() -> ContextPlayerQueueClient (p.l4v)
  ContextPlayerQueueClient e() => queueClient;

  /// ContextPlayerStateClient (p.n4v)
  ContextPlayerStateClient state() => stateClient;
}
