import 'dart:async';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import '../../domain/models/error_type.dart';
import '../../domain/models/player_error.dart';
import '../../domain/models/player_state.dart';
import 'esperanto_transport.dart';
import 'player_state_proto_mappers.dart';
import 'proto/es_context_player_error.pb.dart' as proto_err;
import 'proto/es_get_error_request.pb.dart' as proto_ge;
import 'proto/es_get_state_request.pb.dart' as proto_gs;
import 'proto/es_optional.pb.dart' as proto_opt;

/// 1:1 replica of Spotify ContextPlayer State Client (p.rvy, implements urs0).
/// Communicates using 100% binary Protobuf payloads matching the Spotify Esperanto wire specification.
class ContextPlayerStateClient extends EsperantoClientBase {
  static const String serviceName =
      'spotify.player.esperanto.proto.ContextPlayer';

  ContextPlayerStateClient(super.transport);

  // 1:1 with hni1.java case 28: maps EsContextPlayerError -> PlayerError
  static PlayerError _parseContextPlayerError(
      proto_err.ContextPlayerError errorProto) {
    final errorType = switch (errorProto.code) {
      proto_err.ContextPlayerError_ErrorCode.SUCCESS => ErrorType.success,
      proto_err.ContextPlayerError_ErrorCode.PLAYBACK_STUCK =>
        ErrorType.playbackStuck,
      proto_err.ContextPlayerError_ErrorCode.PLAYBACK_ERROR =>
        ErrorType.playbackError,
      proto_err.ContextPlayerError_ErrorCode.LICENSE_CHANGE =>
        ErrorType.licenseChange,
      proto_err.ContextPlayerError_ErrorCode.PLAY_RESTRICTED =>
        ErrorType.playRestricted,
      proto_err.ContextPlayerError_ErrorCode.STOP_RESTRICTED =>
        ErrorType.stopRestricted,
      proto_err.ContextPlayerError_ErrorCode.UPDATE_RESTRICTED =>
        ErrorType.updateRestricted,
      proto_err.ContextPlayerError_ErrorCode.PAUSE_RESTRICTED =>
        ErrorType.pauseRestricted,
      proto_err.ContextPlayerError_ErrorCode.RESUME_RESTRICTED =>
        ErrorType.resumeRestricted,
      proto_err.ContextPlayerError_ErrorCode.SKIP_TO_PREV_RESTRICTED =>
        ErrorType.skipToPrevRestricted,
      proto_err.ContextPlayerError_ErrorCode.SKIP_TO_NEXT_RESTRICTED =>
        ErrorType.skipToNextRestricted,
      proto_err.ContextPlayerError_ErrorCode.SKIP_TO_NON_EXISTENT_TRACK =>
        ErrorType.skipToNonExistentTrack,
      proto_err.ContextPlayerError_ErrorCode.SEEK_TO_RESTRICTED =>
        ErrorType.seekToRestricted,
      proto_err.ContextPlayerError_ErrorCode.TOGGLE_REPEAT_CONTEXT_RESTRICTED =>
        ErrorType.toggleRepeatContextRestricted,
      proto_err.ContextPlayerError_ErrorCode.TOGGLE_REPEAT_TRACK_RESTRICTED =>
        ErrorType.toggleRepeatTrackRestricted,
      proto_err.ContextPlayerError_ErrorCode.SET_OPTIONS_RESTRICTED =>
        ErrorType.setOptionsRestricted,
      proto_err.ContextPlayerError_ErrorCode.TOGGLE_SHUFFLE_RESTRICTED =>
        ErrorType.toggleShuffleRestricted,
      proto_err.ContextPlayerError_ErrorCode.SET_QUEUE_RESTRICTED =>
        ErrorType.setQueueRestricted,
      proto_err.ContextPlayerError_ErrorCode.INTERRUPT_PLAYBACK_RESTRICTED =>
        ErrorType.interruptPlaybackRestricted,
      proto_err.ContextPlayerError_ErrorCode.ONE_TRACK_UNPLAYABLE =>
        ErrorType.oneTrackUnplayable,
      proto_err.ContextPlayerError_ErrorCode
            .ONE_TRACK_UNPLAYABLE_AUTO_STOPPED =>
        ErrorType.oneTrackUnplayableAutoStopped,
      proto_err.ContextPlayerError_ErrorCode
            .ALL_TRACKS_UNPLAYABLE_AUTO_STOPPED =>
        ErrorType.allTracksUnplayableAutoStopped,
      proto_err.ContextPlayerError_ErrorCode
            .SKIP_TO_NON_EXISTENT_TRACK_AUTO_STOPPED =>
        ErrorType.skipToNonExistentTrackAutoStopped,
      proto_err.ContextPlayerError_ErrorCode.QUEUE_REVISION_MISMATCH =>
        ErrorType.queueRevisionMismatch,
      proto_err.ContextPlayerError_ErrorCode.VIDEO_PLAYBACK_ERROR =>
        ErrorType.videoPlaybackError,
      proto_err.ContextPlayerError_ErrorCode.VIDEO_GEOGRAPHICALLY_RESTRICTED =>
        ErrorType.videoGeorestricted,
      proto_err.ContextPlayerError_ErrorCode
            .VIDEO_UNSUPPORTED_PLATFORM_VERSION =>
        ErrorType.videoUnsupportedPlatformVersion,
      proto_err.ContextPlayerError_ErrorCode
            .VIDEO_UNSUPPORTED_CLIENT_VERSION =>
        ErrorType.videoUnsupportedClientVersion,
      proto_err.ContextPlayerError_ErrorCode.VIDEO_UNSUPPORTED_KEY_SYSTEM =>
        ErrorType.videoUnsupportedKeyVersion,
      proto_err.ContextPlayerError_ErrorCode.VIDEO_MANIFEST_DELETED =>
        ErrorType.videoManifestDeleted,
      proto_err.ContextPlayerError_ErrorCode.VIDEO_COUNTRY_RESTRICTED =>
        ErrorType.videoCountryRestricted,
      proto_err.ContextPlayerError_ErrorCode.VIDEO_UNAVAILABLE =>
        ErrorType.videoUnavailable,
      proto_err.ContextPlayerError_ErrorCode.VIDEO_CATALOGUE_RESTRICTED =>
        ErrorType.videoCatalogueRestricted,
      proto_err.ContextPlayerError_ErrorCode.INVALID => ErrorType.invalid,
      proto_err.ContextPlayerError_ErrorCode.TIMEOUT => ErrorType.timeout,
      proto_err.ContextPlayerError_ErrorCode.PLAYBACK_REPORTING_ERROR =>
        ErrorType.playbackReportingError,
      proto_err.ContextPlayerError_ErrorCode.UNKNOWN => ErrorType.unknown,
      proto_err.ContextPlayerError_ErrorCode.ADD_TO_QUEUE_RESTRICTED =>
        ErrorType.addToQueueRestricted,
      proto_err.ContextPlayerError_ErrorCode.PICK_AND_SHUFFLE_CAPPED =>
        ErrorType.pickAndShuffleCapped,
      proto_err.ContextPlayerError_ErrorCode
            .PICK_AND_SHUFFLE_CONNECT_RESTRICTED =>
        ErrorType.pickAndShuffleConnectRestricted,
      proto_err.ContextPlayerError_ErrorCode.CONTEXT_LOADING_FAILED =>
        ErrorType.contextLoadingFailed,
      proto_err.ContextPlayerError_ErrorCode.AUDIOBOOK_NOT_PLAYABLE =>
        ErrorType.audiobookNotPlayable,
      proto_err.ContextPlayerError_ErrorCode.SIGNAL_NOT_AVAILABLE =>
        ErrorType.signalNotAvailable,
      _ => ErrorType.unknown,
    };

    final builder = PlayerError.builder(errorType);
    final dataMap = errorProto.data;
    if (dataMap['track_uri'] case final trackUri? when trackUri.isNotEmpty) {
      builder.trackUri(trackUri);
    }
    if (dataMap['context_uri'] case final contextUri?
        when contextUri.isNotEmpty) {
      builder.contextUri(contextUri);
    }
    final reasonsStr = switch (dataMap['reasons']) {
      final r? when r.isNotEmpty => r,
      _ => switch (dataMap['playback_error']) {
          final pe? when pe.isNotEmpty => pe,
          _ => null,
        },
    };
    if (reasonsStr case final r?) {
      builder.reasons(r);
    }
    return builder.build();
  }

  /// Subscribes to live PlayerState changes with track capping matching Spotify rvy.mo70507b.
  Stream<PlayerState> getStateStream({
    int targetPrevTracksCap = 2,
    int targetNextTracksCap = 2,
  }) {
    if (targetPrevTracksCap < 0 || targetNextTracksCap < 0) {
      throw ArgumentError('Cap under zero');
    }

    final req = proto_gs.GetStateRequest()
      ..prevTracksCap =
          (proto_opt.OptionalInt64()..value = Int64(targetPrevTracksCap))
      ..nextTracksCap =
          (proto_opt.OptionalInt64()..value = Int64(targetNextTracksCap));
    final payloadBytes = Uint8List.fromList(req.writeToBuffer());

    return callStream(serviceName, 'GetState', payloadBytes).map((bytes) {
      if (bytes.isEmpty) {
        throw const FormatException('Empty state payload received');
      }
      return PlayerStateProtoMappers.fromBuffer(bytes);
    });
  }

  /// Default PlayerState stream with (2, 2) cap matching Spotify rvy.mo70508q.
  Stream<PlayerState> get defaultStateStream =>
      getStateStream(targetPrevTracksCap: 2, targetNextTracksCap: 2);

  /// Subscribes to live stream of player errors matching Spotify rvy.mo70506a.
  Stream<PlayerError> getErrorStream() {
    final req = proto_ge.GetErrorRequest();
    final payloadBytes = Uint8List.fromList(req.writeToBuffer());

    return callStream(serviceName, 'GetError', payloadBytes).map((bytes) {
      if (bytes.isEmpty) {
        throw const FormatException('Empty error payload received');
      }
      final errorProto = proto_err.ContextPlayerError.fromBuffer(bytes);
      return _parseContextPlayerError(errorProto);
    });
  }
}
