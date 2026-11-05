import 'context_player_control_client.dart';
import 'context_player_options_client.dart';
import 'context_player_play_client.dart';
import 'context_player_queue_client.dart';
import 'context_player_state_client.dart';
import 'esperanto_transport.dart';

/// 1:1 replica of Spotify ContextPlayer Dagger Component & Factory (p.afs0).
/// Instantiates, wires, and provides all ContextPlayer client subcomponents.
class ContextPlayerComponent {
  final EsperantoTransport transport;
  final ContextPlayerControlClient controlsClient;
  final ContextPlayerOptionsClient optionsClient;
  final ContextPlayerPlayClient playClient;
  final ContextPlayerQueueClient queueClient;
  final ContextPlayerStateClient stateClient;

  ContextPlayerComponent(this.transport)
      : controlsClient = ContextPlayerControlClient(transport),
        optionsClient = ContextPlayerOptionsClient(transport),
        playClient = ContextPlayerPlayClient(transport),
        queueClient = ContextPlayerQueueClient(transport),
        stateClient = ContextPlayerStateClient(transport);

  /// 1:1 with afs0.m26810s -> ContextPlayerControlClient (p.nvy)
  ContextPlayerControlClient getControlsClient() => controlsClient;

  /// 1:1 with afs0.m26811t -> ContextPlayerOptionsClient (p.ovy)
  ContextPlayerOptionsClient getOptionsClient() => optionsClient;

  /// 1:1 with ContextPlayerPlayClient (p.avy)
  ContextPlayerPlayClient getPlayClient() => playClient;

  /// 1:1 with afs0.m26813v -> ContextPlayerQueueClient (p.pvy)
  ContextPlayerQueueClient getQueueClient() => queueClient;

  /// 1:1 with afs0.m26817z -> ContextPlayerStateClient (p.rvy / urs0)
  ContextPlayerStateClient getStateClient() => stateClient;
}
