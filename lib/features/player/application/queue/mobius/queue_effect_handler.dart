import '../../../data/esperanto/context_player_control_client.dart';
import '../../../data/esperanto/context_player_options_client.dart';
import '../../../data/esperanto/context_player_play_client.dart';
import '../../../data/esperanto/context_player_queue_client.dart';
import '../../../data/queue/queue_add_handler.dart';
import '../../../data/queue/queue_clear_handler.dart';
import '../../../data/queue/queue_helpers.dart';
import '../../../data/queue/queue_remove_handler.dart';
import '../../../data/queue/queue_reorder_handler.dart';
import '../../../domain/commands/add_to_queue_command.dart';
import '../../../domain/commands/options/command_options.dart';
import '../../../domain/commands/options/prepare_play_options.dart';
import '../../../domain/commands/pause_command.dart';
import '../../../domain/commands/play_command.dart';
import '../../../domain/commands/resume_command.dart';
import '../../../domain/commands/seek_to_command.dart';
import '../../../domain/commands/set_options_command.dart';
import '../../../domain/commands/set_queue_command.dart';
import '../../../domain/commands/skip_to_next_track_command.dart';
import '../../../domain/commands/skip_to_prev_track_command.dart';
import '../../../domain/commands/stop_command.dart';
import '../../../domain/commands/update_context_command.dart';
import '../../../domain/commands/update_track_command.dart';
import '../../../domain/models/context.dart';
import '../../../domain/models/context_page.dart';
import '../../../domain/models/play_origin.dart';
import '../../../domain/models/player_queue.dart';
import '../player_queue_event.dart';
import 'mobius_types.dart';
import 'queue_effects.dart';

/// 1:1 replica of Spotify Mobius Queue Effect Handler (p.mwp0, p.dwp0, p.hwp0).
/// Dispatches asynchronous commands to ContextPlayer clients and reports back events.
class QueueMobiusEffectHandler implements MobiusEffectHandler<QueueEffect, PlayerQueueEvent> {
  final ContextPlayerQueueClient? queueClient;
  final ContextPlayerControlClient? controlClient;
  final ContextPlayerOptionsClient? optionsClient;
  final ContextPlayerPlayClient? playClient;
  final PlayerQueue Function() getCurrentQueue;

  QueueMobiusEffectHandler({
    this.queueClient,
    this.controlClient,
    this.optionsClient,
    this.playClient,
    required this.getCurrentQueue,
  });

  @override
  Future<PlayerQueueEvent?> handleEffect(QueueEffect effect) async {
    try {
      if (effect is AddTracksEffect) {
        final qc = queueClient;
        if (qc == null) return null;

        // 1:1 with Spotify dwp0 lines 28-33:
        if (effect.tracks.length == 1 &&
            effect.mode == QueueInsertMode.addToEndOfQueue) {
          await qc.addToQueue(AddToQueueCommand.create(effect.tracks.first));
        } else {
          final updated = QueueAddHandler.addTracks(
            getCurrentQueue(),
            effect.tracks,
            mode: effect.mode,
          );
          final command = QueueHelpers.createSetQueueCommand(updated);
          await qc.setQueue(command);
        }
        return null;
      }

      if (effect is SetQueueTracksEffect) {
        final qc = queueClient;
        if (qc != null) {
          final current = getCurrentQueue();
          final updated = current.toBuilder()
              .nextTracks(effect.nextTracks)
              .prevTracks(effect.prevTracks ?? current.prevTracks)
              .build();
          final command = SetQueueCommand.builderFromQueue(updated)
              .options(CommandOptions.builder().overrideRestrictions(true).build())
              .build();
          await qc.setQueue(command);
        }
        return null;
      }

      if (effect is PlayContextEffect) {
        final pc = playClient;
        if (pc != null) {
          final playCommand = PlayCommand.builder(effect.context, effect.playOrigin)
              .options(effect.options ?? PreparePlayOptions.empty)
              .build();
          await pc.play(playCommand);
        }
        return null;
      }

      if (effect is RemoveTracksEffect) {
        final qc = queueClient;
        if (qc == null) return null;

        final updated = QueueRemoveHandler.removeTracks(
          getCurrentQueue(),
          effect.tracks,
        );
        final command = QueueHelpers.createSetQueueCommand(updated);
        await qc.setQueue(command);
        return null;
      }

      if (effect is ReorderTrackEffect) {
        final qc = queueClient;
        if (qc == null) return null;

        // 1:1 with Spotify gxl0 / lr5
        final updated = QueueReorderHandler.reorderTrack(
          playerQueue: getCurrentQueue(),
          trackToMove: effect.track,
          destinationVisibleIndex: effect.destinationIndex,
        );
        final command = QueueHelpers.createSetQueueCommand(updated);
        await qc.setQueue(command);
        return null;
      }

      if (effect is ClearQueueEffect) {
        final qc = queueClient;
        if (qc == null) return null;

        // 1:1 with Spotify hwp0 case 0 / pml0 case 2
        final updated = QueueClearHandler.clearUserQueue(getCurrentQueue());
        final command = QueueHelpers.createSetQueueCommand(updated);
        await qc.setQueue(command);
        return null;
      }

      if (effect is ToggleShuffleEffect) {
        final oc = optionsClient;
        if (oc != null) {
          await oc.setShuffle(effect.nextShuffle);
        }
        return null;
      }

      if (effect is ToggleRepeatEffect) {
        final oc = optionsClient;
        if (oc != null) {
          final command = SetOptionsCommand.builder()
              .repeatingContext(effect.nextRepeatContext)
              .repeatingTrack(effect.nextRepeatTrack)
              .build();
          await oc.setOptions(command);
        }
        return null;
      }

      if (effect is PlayPauseEffect) {
        final cc = controlClient;
        if (cc != null) {
          if (effect.currentlyPlaying) {
            await cc.pause(PauseCommand.builder().build());
          } else {
            await cc.resume(ResumeCommand.builder().build());
          }
        }
        return null;
      }

      if (effect is SkipNextEffect) {
        final cc = controlClient;
        if (cc != null) {
          await cc.skipToNext(SkipToNextTrackCommand.create());
        }
        return null;
      }

      if (effect is SkipPrevEffect) {
        final cc = controlClient;
        if (cc != null) {
          await cc.skipToPrev(SkipToPrevTrackCommand.create());
        }
        return null;
      }

      if (effect is PlayTrackEffect) {
        final cc = controlClient;
        final pc = playClient;
        final currentQueue = getCurrentQueue();

        final isInNextTracks = currentQueue.nextTracks.any(
          (t) => (t.uid.isNotEmpty && t.uid == effect.track.uid) ||
                 (t.uri.isNotEmpty && t.uri == effect.track.uri),
        );

        if (isInNextTracks && cc != null) {
          // 1:1 with Spotify x0j0 case 25: Skip to specific queued track
          await cc.skipToNext(SkipToNextTrackCommand.builder().track(effect.track).build());
        } else if (pc != null) {
          // Play standalone or context track with full metadata and pages
          final page = ContextPage.builder().tracks([effect.track]).build();
          final context = Context.builder(effect.track.uri)
              .url('context://${effect.track.uri}')
              .metadata(effect.track.metadata)
              .pages([page])
              .build();
          final playCommand = PlayCommand.create(
            context,
            const PlayOrigin(featureIdentifier: 'local_files'),
          );
          await pc.play(playCommand);
        }
        return null;
      }

      if (effect is SeekToEffect) {
        final cc = controlClient;
        if (cc != null) {
          await cc.seekTo(SeekToCommand.create(effect.positionMs));
        }
        return null;
      }

      if (effect is StopEffect) {
        final cc = controlClient;
        if (cc != null) {
          await cc.stop(StopCommand.create());
        }
        return null;
      }

      if (effect is SignalEffect) {
        final cc = controlClient;
        if (cc != null) {
          await cc.signal(effect.command);
        }
        return null;
      }

      if (effect is SetSleepTimerEffect) {
        final oc = optionsClient;
        if (oc != null) {
          await oc.setSleepTimer(effect.command);
        }
        return null;
      }

      if (effect is PlayAsNextInQueueEffect) {
        final updated = QueueAddHandler.addTracks(
          getCurrentQueue(),
          effect.tracks,
          mode: QueueInsertMode.playNext,
        );
        final command = QueueHelpers.createSetQueueCommand(updated);
        await queueClient?.setQueue(command);
        return null;
      }

      if (effect is UpdateContextEffect) {
        final pc = playClient;
        if (pc != null) {
          await pc.updateContext(UpdateContextCommand.create(effect.context));
        }
        return null;
      }

      if (effect is UpdateTrackEffect) {
        final pc = playClient;
        if (pc != null) {
          await pc.updateTrack(UpdateTrackCommand.create(effect.track));
        }
        return null;
      }
    } catch (e) {
      return QueueErrorOccurred(e.toString());
    }
    return null;
  }
}
