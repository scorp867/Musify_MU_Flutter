// 1:1 replica of p199p/imd1.java, p199p/hmd1.java, p199p/gmd1.java, p199p/yld1.java,
// p199p/zld1.java, p199p/qtq.java (lines 22–76, 189–193), p199p/bdk.java,
// p199p/zck.java, p199p/adk.java, p199p/cdk.java,
// and native TransferIntention.h (lines 25–47) / TransferManager.h (lines 33–41).

import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Origin that initiated a playback transfer command (`p199p/cdk.java`).
enum TransferSource {
  inApp, // IN_APP
  googleOutputSwitcher, // GOOGLE_OUTPUT_SWITCHER
}

/// Non-terminal phase of an active playback transfer (`TransferIntention.h:41–47`).
enum TransferPhase {
  created, // kCreated (0)
  discovering, // kDiscovering (1)
  transferring, // kTransferring (2)
  becomingActive, // kBecomingActive (3)
}

/// Unified transfer failure classification combining `p199p/yld1.java`,
/// `p199p/zld1.java`, and `TransferIntention::FinishReason` (`TransferIntention.h:25–31`).
enum TransferFailureReason {
  notFound, // yld1.NOT_FOUND / Status.NOT_FOUND
  invalidArguments, // yld1.INVALID_ARGUMENTS / Status.INVALID_ARGUMENTS
  backendFailure, // yld1.BACKEND_FAILURE / Status.BACKEND_FAILURE
  aborted, // FinishReason.kAborted (2)
  noResponse, // FinishReason.kNoResponse (3)
  loginFailed, // FinishReason.kLoginFailed (4)
  transportError, // zld1(Exception)
  unknown, // yld1.UNKNOWN / FinishReason.kFailed (1) / UNIMPLEMENTED
}

/// Playback transfer command dispatched by ConnectTransferer
/// (`p199p/bdk.java`, `p199p/zck.java`, `p199p/adk.java`).
@immutable
sealed class TransferCommand extends Equatable {
  final TransferSource source;

  const TransferCommand({required this.source});
}

/// Transfers playback back to the local device (`p199p/zck.java`).
@immutable
final class TransferToLocal extends TransferCommand {
  const TransferToLocal({required super.source});

  @override
  List<Object?> get props => [source];
}

/// Transfers playback to a remote Connect/Cast device (`p199p/adk.java`).
@immutable
final class TransferToRemote extends TransferCommand {
  final String targetDeviceId;

  TransferToRemote({
    required this.targetDeviceId,
    required super.source,
  }) {
    if (targetDeviceId.isEmpty) {
      throw ArgumentError.value(
        targetDeviceId,
        'targetDeviceId',
        'Must be non-empty',
      );
    }
  }

  @override
  List<Object?> get props => [targetDeviceId, source];
}

/// Exhaustive transfer intention lifecycle state making illegal state
/// combinations unrepresentable at compile time.
@immutable
sealed class TransferState extends Equatable {
  const TransferState();
}

/// No transfer is currently active (`p199p/qtq.java` absent optional).
@immutable
final class TransferIdle extends TransferState {
  const TransferIdle();

  @override
  List<Object?> get props => const <Object?>[];
}

/// A playback transfer to [targetDeviceId] is currently in flight.
@immutable
final class TransferInProgress extends TransferState {
  final String targetDeviceId;
  final TransferPhase phase;
  final TransferSource source;
  final String? intentionId;

  TransferInProgress({
    required this.targetDeviceId,
    required this.phase,
    this.source = TransferSource.inApp,
    this.intentionId,
  }) {
    if (targetDeviceId.isEmpty) {
      throw ArgumentError.value(
        targetDeviceId,
        'targetDeviceId',
        'Must be non-empty',
      );
    }
  }

  TransferInProgress copyWith({
    String? targetDeviceId,
    TransferPhase? phase,
    TransferSource? source,
    String? intentionId,
    bool clearIntentionId = false,
  }) {
    return TransferInProgress(
      targetDeviceId: switch (targetDeviceId) {
        final value? => value,
        null => this.targetDeviceId,
      },
      phase: switch (phase) {
        final value? => value,
        null => this.phase,
      },
      source: switch (source) {
        final value? => value,
        null => this.source,
      },
      intentionId: clearIntentionId
          ? null
          : switch (intentionId) {
              final value? => value,
              null => this.intentionId,
            },
    );
  }

  @override
  List<Object?> get props => [targetDeviceId, phase, source, intentionId];
}

/// Playback transfer to [targetDeviceId] completed successfully (`p199p/hmd1.java`).
@immutable
final class TransferSucceeded extends TransferState {
  final String targetDeviceId;
  final String? intentionId;
  final String? ackId;

  TransferSucceeded({
    required this.targetDeviceId,
    this.intentionId,
    this.ackId,
  }) {
    if (targetDeviceId.isEmpty) {
      throw ArgumentError.value(
        targetDeviceId,
        'targetDeviceId',
        'Must be non-empty',
      );
    }
  }

  TransferSucceeded copyWith({
    String? targetDeviceId,
    String? intentionId,
    bool clearIntentionId = false,
    String? ackId,
    bool clearAckId = false,
  }) {
    return TransferSucceeded(
      targetDeviceId: switch (targetDeviceId) {
        final value? => value,
        null => this.targetDeviceId,
      },
      intentionId: clearIntentionId
          ? null
          : switch (intentionId) {
              final value? => value,
              null => this.intentionId,
            },
      ackId: clearAckId
          ? null
          : switch (ackId) {
              final value? => value,
              null => this.ackId,
            },
    );
  }

  @override
  List<Object?> get props => [targetDeviceId, intentionId, ackId];
}

/// Playback transfer to [targetDeviceId] failed (`p199p/gmd1.java`).
@immutable
final class TransferFailed extends TransferState {
  final String targetDeviceId;
  final TransferFailureReason reason;
  final String? errorDescription;
  final UnmodifiableListView<String> reasons;
  final String? intentionId;
  final Object? exception;

  TransferFailed({
    required this.targetDeviceId,
    required this.reason,
    this.errorDescription,
    List<String> reasons = const <String>[],
    this.intentionId,
    this.exception,
  }) : reasons = UnmodifiableListView<String>(List<String>.of(reasons)) {
    if (targetDeviceId.isEmpty) {
      throw ArgumentError.value(
        targetDeviceId,
        'targetDeviceId',
        'Must be non-empty',
      );
    }
  }

  TransferFailed copyWith({
    String? targetDeviceId,
    TransferFailureReason? reason,
    String? errorDescription,
    bool clearErrorDescription = false,
    List<String>? reasons,
    String? intentionId,
    bool clearIntentionId = false,
    Object? exception,
    bool clearException = false,
  }) {
    return TransferFailed(
      targetDeviceId: switch (targetDeviceId) {
        final value? => value,
        null => this.targetDeviceId,
      },
      reason: switch (reason) {
        final value? => value,
        null => this.reason,
      },
      errorDescription: clearErrorDescription
          ? null
          : switch (errorDescription) {
              final value? => value,
              null => this.errorDescription,
            },
      reasons: switch (reasons) {
        final value? => value,
        null => this.reasons,
      },
      intentionId: clearIntentionId
          ? null
          : switch (intentionId) {
              final value? => value,
              null => this.intentionId,
            },
      exception: clearException
          ? null
          : switch (exception) {
              final value? => value,
              null => this.exception,
            },
    );
  }

  @override
  List<Object?> get props => [
        targetDeviceId,
        reason,
        errorDescription,
        reasons,
        intentionId,
        exception,
      ];
}
