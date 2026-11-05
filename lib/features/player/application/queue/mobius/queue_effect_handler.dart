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
import '../../../domain/commands/options/player_option_overrides.dart';
import '../../../domain/commands/options/prepare_play_options.dart';
import '../../../domain/commands/options/skip_to_track.dart';
import '../../../domain/commands/pause_command.dart';
import '../../../domain/commands/play_command.dart';
import '../../../domain/commands/resume_command.dart';
import '../../../domain/commands/seek_to_command.dart';
import '../../../domain/commands/set_options_command.dart';
import '../../../domain/commands/set_queue_command.dart';
import '../../../domain/commands/set_shuffling_context_command.dart';
import '../../../domain/commands/skip_to_next_track_command.dart';
import '../../../domain/commands/skip_to_prev_track_command.dart';
import '../../../domain/commands/stop_command.dart';
import '../../../domain/commands/update_context_command.dart';
import '../../../domain/commands/update_track_command.dart';
import '../../../domain/models/context.dart';
import '../../../domain/models/context_page.dart';
import '../../../domain/models/context_track.dart';
import '../../../domain/models/play_origin.dart';
import '../../../domain/models/player_queue.dart';
import '../player_queue_event.dart';
import 'mobius_types.dart';
import 'queue_effects.dart';

/// 1:1 replica of Spotify Mobius Queue Effect Handler (p.mwp0, p.dwp0, p.hwp0, p.tbx0, p.ibx0).
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
      switch (effect) {
        case AddTracksEffect(:final tracks, :final mode):
          final qc = queueClient;
          if (qc == null) return null;

          // 1:1 with Spotify dwp0 lines 28-33 / hbx0 case 0:
          if (tracks.length == 1 && mode == QueueInsertMode.addToEndOfQueue) {
            await qc.addToQueue(AddToQueueCommand.create(tracks.first));
          } else {
            final updated = QueueAddHandler.addTracks(
              getCurrentQueue(),
              tracks,
              mode: mode,
            );
            final command = QueueHelpers.createSetQueueCommand(updated);
            await qc.setQueue(command);
          }
          return null;

        case SetQueueTracksEffect(:final nextTracks, :final prevTracks):
          final qc = queueClient;
          if (qc != null) {
            final current = getCurrentQueue();
            final updated = current.toBuilder()
                .nextTracks(nextTracks)
                .prevTracks(switch (prevTracks) {
                  final t? => t,
                  null => current.prevTracks,
                })
                .build();
            final command = SetQueueCommand.builder(playerQueue: updated)
                .options(CommandOptions.builder().overrideRestrictions(true).build())
                .build();
            await qc.setQueue(command);
          }
          return null;

        case PlayContextEffect(:final context, :final options, :final playOrigin):
          final pc = playClient;
          if (pc != null) {
            final resolvedOptions = switch (options) {
              final opts? => opts,
              null => PreparePlayOptions.empty,
            };
            final effectivePlayOrigin = playOrigin.featureIdentifier.isNotEmpty
                ? playOrigin
                : PlayOrigin.builder(
                    switch (context.metadata['play_origin_feature']) {
                      final f? when f.isNotEmpty => f,
                      _ => switch (context.uri) {
                          final cu when cu.startsWith('spotify:playlist:') => 'playlist',
                          final cu when cu.startsWith('spotify:album:') => 'album',
                          final cu when cu.startsWith('spotify:artist:') => 'artist',
                          final cu when cu.contains('local') => 'local_files',
                          _ => 'context-play-handler',
                        },
                    },
                  )
                  .viewUri(context.uri)
                  .build();

            final playCommand = PlayCommand.builder(context, effectivePlayOrigin)
                .options(resolvedOptions)
                .build();
            await pc.play(playCommand);
          }
          return null;

        case RemoveTracksEffect(:final tracks):
          final qc = queueClient;
          if (qc == null) return null;

          final updated = QueueRemoveHandler.removeTracks(
            getCurrentQueue(),
            tracks,
          );
          final command = QueueHelpers.createSetQueueCommand(updated);
          await qc.setQueue(command);
          return null;

        case ReorderTrackEffect(:final track, :final destinationIndex):
          final qc = queueClient;
          if (qc == null) return null;

          // 1:1 with Spotify gxl0 / lr5 / wos0
          final updated = QueueReorderHandler.reorderTrack(
            playerQueue: getCurrentQueue(),
            trackToMove: track,
            destinationVisibleIndex: destinationIndex,
          );
          final command = QueueHelpers.createSetQueueCommand(updated);
          await qc.setQueue(command);
          return null;

        case ClearQueueEffect():
          final qc = queueClient;
          if (qc == null) return null;

          // 1:1 with Spotify hwp0 case 0 / pml0 case 2 / w9x0 / kbx0 case 0
          final updated = QueueClearHandler.clearUserQueue(getCurrentQueue());
          final command = QueueHelpers.createSetQueueCommand(updated);
          await qc.setQueue(command);
          return null;

        case ToggleShuffleEffect(:final nextShuffle, :final loggingParams):
          final oc = optionsClient;
          if (oc != null) {
            final builder = SetShufflingContextCommand.builder(nextShuffle);
            if (loggingParams case final params?) {
              builder.loggingParams(params);
            }
            await oc.setShufflingContext(builder.build());
          }
          return null;

        case ToggleRepeatEffect(:final nextRepeatContext, :final nextRepeatTrack, :final loggingParams):
          final oc = optionsClient;
          if (oc != null) {
            final builder = SetOptionsCommand.builder()
                .repeatingContext(nextRepeatContext)
                .repeatingTrack(nextRepeatTrack);
            if (loggingParams case final params?) {
              builder.loggingParams(params);
            }
            await oc.setOptions(builder.build());
          }
          return null;

        case PlayPauseEffect(:final currentlyPlaying, :final loggingParams):
          final cc = controlClient;
          if (cc != null) {
            if (currentlyPlaying) {
              final builder = PauseCommand.builder();
              if (loggingParams case final params?) {
                builder.loggingParams(params);
              }
              await cc.pause(builder.build());
            } else {
              final builder = ResumeCommand.builder();
              if (loggingParams case final params?) {
                builder.loggingParams(params);
              }
              await cc.resume(builder.build());
            }
          }
          return null;

        case SkipNextEffect(:final loggingParams):
          final cc = controlClient;
          if (cc != null) {
            final builder = SkipToNextTrackCommand.builder();
            if (loggingParams case final params?) {
              builder.loggingParams(params);
            }
            await cc.skipToNext(builder.build());
          }
          return null;

        case SkipPrevEffect(:final loggingParams):
          final cc = controlClient;
          if (cc != null) {
            final builder = SkipToPrevTrackCommand.builder();
            if (loggingParams case final params?) {
              builder.loggingParams(params);
            }
            await cc.skipToPrev(builder.build());
          }
          return null;

        case PlayTrackEffect(:final track, :final playOrigin):
          final cc = controlClient;
          final pc = playClient;
          final currentQueue = getCurrentQueue();

          final isInNextTracks = currentQueue.nextTracks.any(
            (t) => (t.uid.isNotEmpty && t.uid == track.uid) ||
                   (t.uri.isNotEmpty && t.uri == track.uri),
          );

          if (isInNextTracks && cc != null) {
            // 1:1 with Spotify x0j0 case 25 / kax0 / jbx0 case 1: Skip to specific queued track
            await cc.skipToNext(SkipToNextTrackCommand.builder().track(track).build());
          } else if (pc != null) {
            // Play standalone or context track with full metadata and pages
            final page = ContextPage.builder()
                .pageUrl('context://${track.uri}')
                .tracks([track])
                .build();
            final context = Context.builder(track.uri)
                .url('context://${track.uri}')
                .metadata(track.metadata)
                .pages([page])
                .build();

            final effectivePlayOrigin = playOrigin.featureIdentifier.isNotEmpty
                ? playOrigin
                : PlayOrigin.builder(
                    switch (track.metadata['play_origin_feature']) {
                      final f? when f.isNotEmpty => f,
                      _ => switch (track.metadata['is_local']) {
                          'true' => 'local_files',
                          _ => switch (track.metadata[ContextTrackMetadata.keyContextUri]) {
                              final cu? when cu.startsWith('spotify:playlist:') => 'playlist',
                              final cu? when cu.startsWith('spotify:album:') => 'album',
                              final cu? when cu.startsWith('spotify:artist:') => 'artist',
                              _ => 'track_playback_manager',
                            },
                        },
                    },
                  )
                  .viewUri(
                    switch (track.metadata[ContextTrackMetadata.keyContextUri]) {
                      final cu? when cu.isNotEmpty => cu,
                      _ => track.uri,
                    },
                  )
                  .build();

            final playOptions = PreparePlayOptions.builder()
                .skipTo(SkipToTrack.fromUri(track.uri))
                .playerOptionsOverride(
                  PlayerOptionOverrides.builder()
                      .modes({'media': 'audio'})
                      .build(),
                )
                .build();

            final playCommand = PlayCommand.builder(context, effectivePlayOrigin)
                .options(playOptions)
                .build();
            await pc.play(playCommand);
          }
          return null;

        case SeekToEffect(:final positionMs, :final loggingParams):
          final cc = controlClient;
          if (cc != null) {
            final builder = SeekToCommand.builder(positionMs);
            if (loggingParams case final params?) {
              builder.loggingParams(params);
            }
            await cc.seekTo(builder.build());
          }
          return null;

        case StopEffect():
          final cc = controlClient;
          if (cc != null) {
            await cc.stop(StopCommand.create());
          }
          return null;

        case SignalEffect(:final command):
          final cc = controlClient;
          if (cc != null) {
            await cc.signal(command);
          }
          return null;

        case SetSleepTimerEffect(:final command):
          final oc = optionsClient;
          if (oc != null) {
            await oc.setSleepTimer(command);
          }
          return null;

        case PlayAsNextInQueueEffect(:final tracks):
          final updated = QueueAddHandler.addTracks(
            getCurrentQueue(),
            tracks,
            mode: QueueInsertMode.playNext,
          );
          final command = QueueHelpers.createSetQueueCommand(updated);
          final qc = queueClient;
          if (qc != null) {
            await qc.setQueue(command);
          }
          return null;

        case UpdateContextEffect(:final context):
          final pc = playClient;
          if (pc != null) {
            await pc.updateContext(UpdateContextCommand.create(context));
          }
          return null;

        case UpdateTrackEffect(:final track):
          final pc = playClient;
          if (pc != null) {
            await pc.updateTrack(UpdateTrackCommand.create(track));
          }
          return null;
      }
    } catch (e) {
      return QueueErrorOccurred(e.toString());
    }
  }
}
