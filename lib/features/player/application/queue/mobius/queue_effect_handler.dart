import '../../../data/esperanto/context_player_control_client.dart';
import '../../../data/esperanto/context_player_options_client.dart';
import '../../../data/esperanto/context_player_play_client.dart';
import '../../../data/esperanto/context_player_queue_client.dart';
import '../../../data/queue/queue_key_resolver.dart';
import '../../../data/queue/queue_uid_generator.dart';
import '../../../domain/commands/add_to_queue_command.dart';
import '../../../domain/commands/options/command_options.dart';
import '../../../domain/commands/pause_command.dart';
import '../../../domain/commands/play_as_next_in_queue_command.dart';
import '../../../domain/commands/resume_command.dart';
import '../../../domain/commands/seek_to_command.dart';
import '../../../domain/commands/set_options_command.dart';
import '../../../domain/commands/set_queue_command.dart';
import '../../../domain/commands/set_shuffling_context_command.dart';
import '../../../domain/commands/skip_to_next_track_command.dart';
import '../../../domain/commands/skip_to_prev_track_command.dart';
import '../../../domain/models/context_track.dart';
import '../../../domain/models/player_queue.dart';
import 'mobius_types.dart';
import 'queue_effect.dart';
import 'queue_event.dart';

/// 1:1 replica of Spotify Mobius Queue Effect Handler (`tbx0.java`, `sfo0.java`, `wos0.java`, `lgx0.java`).
///
/// Executes asynchronous side effects against Esperanto ContextPlayer clients,
/// maintaining native Orbit as the single source of truth.
class QueueMobiusEffectHandler implements MobiusEffectHandler<QueueEffect, QueueEvent> {
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
  Future<QueueEvent?> handleEffect(QueueEffect effect) async {
    try {
      switch (effect) {
        // 1:1 with Spotify sfo0.java case 27 & xos0.java m92227d
        case RemoveTracksEffect(:final tracks):
          final qc = queueClient;
          if (qc == null) return null;

          final keysToRemove = tracks.map(QueueKeyResolver.resolveKey).toList();

          final remaining = <ContextTrack>[];
          for (final t in currentQueueTracks()) {
            final key = QueueKeyResolver.resolveKey(t);
            final removeIdx = keysToRemove.indexOf(key);
            if (removeIdx != -1) {
              keysToRemove.removeAt(removeIdx);
            } else {
              remaining.add(t);
            }
          }

          final current = getCurrentQueue();
          final updatedQueue = current.toBuilder().nextTracks(remaining).build();
          final command = SetQueueCommand.builder(playerQueue: updatedQueue)
              .options(CommandOptions.builder().overrideRestrictions(true).build())
              .build();
          await qc.setQueue(command);
          return null;

        // 1:1 with Spotify wos0.java lines 40-87 & lr5.java lines 580-596
        case ReorderTrackEffect(:final track, :final destinationIndex):
          final qc = queueClient;
          if (qc == null) return null;

          final current = getCurrentQueue();
          final nextTracks = List<ContextTrack>.from(current.nextTracks);
          if (nextTracks.isEmpty) return null;

          final maxIdx = nextTracks.length - 1;
          final boundDest = destinationIndex < 0 ? 0 : (destinationIndex > maxIdx ? maxIdx : destinationIndex);

          final trackKey = QueueKeyResolver.resolveKey(track);
          int sourceIndex = -1;
          for (int i = 0; i < nextTracks.length; i++) {
            if (QueueKeyResolver.resolveKey(nextTracks[i]) == trackKey) {
              sourceIndex = i;
              break;
            }
          }
          if (sourceIndex == -1) {
            for (int i = 0; i < nextTracks.length; i++) {
              if (track.uid.isNotEmpty && nextTracks[i].uid == track.uid) {
                sourceIndex = i;
                break;
              }
            }
          }

          if (sourceIndex == -1) return null;

          int lastQueuedIdx = -1;
          for (int i = nextTracks.length - 1; i >= 0; i--) {
            if (i != sourceIndex && QueueKeyResolver.isQueued(nextTracks[i])) {
              lastQueuedIdx = i;
              break;
            }
          }

          final bool targetIsQueued;
          if (lastQueuedIdx == -1) {
            targetIsQueued = boundDest == 0 && QueueKeyResolver.isQueued(track);
          } else {
            targetIsQueued = boundDest <= (lastQueuedIdx + 1);
          }

          final movedItem = nextTracks.removeAt(sourceIndex);
          final updatedMetadata = Map<String, String>.from(movedItem.metadata);
          updatedMetadata[ContextTrackMetadata.keyIsQueued] = targetIsQueued ? 'true' : 'false';
          updatedMetadata['provider'] = targetIsQueued ? 'queue' : 'context';

          final effectiveUid = movedItem.uid.isNotEmpty
              ? movedItem.uid
              : QueueUidGenerator.generateTrackUid();

          final mutatedTrack = movedItem
              .toBuilder()
              .uid(effectiveUid)
              .provider(targetIsQueued ? 'queue' : 'context')
              .metadata(updatedMetadata)
              .build();

          final insertIdx = boundDest <= nextTracks.length ? boundDest : nextTracks.length;
          nextTracks.insert(insertIdx, mutatedTrack);

          final updatedQueue = current.toBuilder().nextTracks(nextTracks).build();
          final command = SetQueueCommand.builder(playerQueue: updatedQueue)
              .options(CommandOptions.builder().overrideRestrictions(true).build())
              .build();
          await qc.setQueue(command);
          return null;

        // 1:1 with Spotify p2k1 line 207 / dwp0 lines 28-33 / pvy.java line 36
        // Appends to user queue without mutating or removing context tracks
        case AddToQueueEffect(:final track, :final playNext, :final loggingParams):
          final ctrl = controlClient;
          final qc = queueClient;

          final effectiveUid = QueueUidGenerator.generateTrackUid();
          final meta = Map<String, String>.from(track.metadata);
          meta[ContextTrackMetadata.keyIsQueued] = 'true';
          meta['provider'] = 'queue';

          final queuedTrack = track
              .toBuilder()
              .uid(effectiveUid)
              .provider('queue')
              .metadata(meta)
              .build();

          if (playNext && ctrl != null) {
            final builder = PlayAsNextInQueueCommand.builder([queuedTrack]);
            if (loggingParams case final lp?) {
              builder.loggingParams(lp);
            }
            await ctrl.playAsNextInQueue(builder.build());
          } else if (qc != null) {
            final builder = AddToQueueCommand.builder(queuedTrack);
            if (loggingParams case final lp?) {
              builder.loggingParams(lp);
            }
            await qc.addToQueue(builder.build());
          }
          return null;

        // 1:1 with Spotify w9x0.java / fcx0
        case ClearQueueEffect():
          final qc = queueClient;
          if (qc == null) return null;

          final current = getCurrentQueue();
          final contextOnly = <ContextTrack>[];
          for (final t in current.nextTracks) {
            if (!QueueKeyResolver.isQueued(t)) {
              contextOnly.add(t);
            }
          }
          final updatedQueue = current.toBuilder().nextTracks(contextOnly).build();
          final command = SetQueueCommand.builder(playerQueue: updatedQueue)
              .options(CommandOptions.builder().overrideRestrictions(true).build())
              .build();
          await qc.setQueue(command);
          return null;

        // 1:1 with Spotify bpp.java line 767 / uyb0.java line 140
        case SkipToTrackEffect(:final track):
          final ctrl = controlClient;
          if (ctrl != null) {
            final command = SkipToNextTrackCommand.builder().track(track).build();
            await ctrl.skipToNext(command);
          }
          return null;

        case SetQueueEffect(:final queue):
          final qc = queueClient;
          if (qc != null) {
            final command = SetQueueCommand.builder(playerQueue: queue)
                .options(CommandOptions.builder().overrideRestrictions(true).build())
                .build();
            await qc.setQueue(command);
          }
          return null;

        case ToggleShuffleEffect(:final enableShuffle, :final loggingParams):
          final opt = optionsClient;
          if (opt != null) {
            final builder = SetShufflingContextCommand.builder(enableShuffle);
            if (loggingParams case final lp?) {
              builder.loggingParams(lp);
            }
            await opt.setShufflingContext(builder.build());
          }
          return null;

        case ToggleRepeatEffect(:final repeatingContext, :final repeatingTrack, :final loggingParams):
          final opt = optionsClient;
          if (opt != null) {
            final builder = SetOptionsCommand.builder()
                .repeatingContext(repeatingContext)
                .repeatingTrack(repeatingTrack);
            if (loggingParams case final lp?) {
              builder.loggingParams(lp);
            }
            await opt.setOptions(builder.build());
          }
          return null;

        case TogglePlayPauseEffect():
          final ctrl = controlClient;
          if (ctrl != null) {
            final current = getCurrentQueue();
            final isPlaying = current.track != null;
            if (isPlaying) {
              await ctrl.pause(PauseCommand.create());
            } else {
              await ctrl.resume(ResumeCommand.create());
            }
          }
          return null;

        case SkipToNextTrackEffect(:final loggingParams):
          final ctrl = controlClient;
          if (ctrl != null) {
            final builder = SkipToNextTrackCommand.builder();
            if (loggingParams case final lp?) {
              builder.loggingParams(lp);
            }
            await ctrl.skipToNext(builder.build());
          }
          return null;

        case SkipToPrevTrackEffect(:final loggingParams):
          final ctrl = controlClient;
          if (ctrl != null) {
            final builder = SkipToPrevTrackCommand.builder();
            if (loggingParams case final lp?) {
              builder.loggingParams(lp);
            }
            await ctrl.skipToPrev(builder.build());
          }
          return null;

        case SeekToPositionEffect(:final position, :final loggingParams):
          final ctrl = controlClient;
          if (ctrl != null) {
            final builder = SeekToCommand.builder(position.inMilliseconds);
            if (loggingParams case final lp?) {
              builder.loggingParams(lp);
            }
            await ctrl.seekTo(builder.build());
          }
          return null;
      }
    } catch (e) {
      return QueueErrorEvent(e.toString());
    }
  }

  List<ContextTrack> currentQueueTracks() => getCurrentQueue().nextTracks;
}
