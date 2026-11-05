library;

import 'mobius/player_queue_mobius_controller.dart';

export 'mobius/mobius_loop.dart';
export 'mobius/mobius_types.dart';
export 'mobius/player_queue_mobius_controller.dart';
export 'mobius/queue_effect.dart';
export 'mobius/queue_effect_handler.dart';
export 'mobius/queue_event.dart';
export 'mobius/queue_mobius_update.dart';
export 'mobius/queue_model.dart';

/// Legacy aliases for smooth migration across remaining consumer screens.
typedef PlayerQueueBloc = PlayerQueueMobiusController;
typedef PlayerQueueState = QueueModel;
typedef PlayerQueueEvent = QueueEvent;
