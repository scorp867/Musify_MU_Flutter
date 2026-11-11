import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';

/// Operational lifecycle state enum for the stealth gesture recognizer
/// (Harel Region D: Stealth Gateway Pipeline).
enum GestureEngineStateEnum {
  /// Awaiting initial pointer down inside the stealth sensor pad.
  idle,

  /// Pointer is actively moving across the canvas; buffering timestamped coordinate stream.
  capturingStroke,

  /// Executing multi-stage recognition pipeline inside background isolate.
  evaluatingPipeline,

  /// Calibrated ensemble consensus score met or exceeded threshold; stealth trigger confirmed.
  matchConfirmed,

  /// Score below threshold, anti-scribble tripped, or feature divergence; silent buffer wipe.
  rejectedSilent;

  /// Whether the engine is actively processing touch or isolate execution.
  bool get isBusy => switch (this) {
        GestureEngineStateEnum.idle => false,
        GestureEngineStateEnum.capturingStroke => true,
        GestureEngineStateEnum.evaluatingPipeline => true,
        GestureEngineStateEnum.matchConfirmed => false,
        GestureEngineStateEnum.rejectedSilent => false,
      };
}

/// Root sealed state hierarchy governing the multi-sample gesture enrollment wizard.
///
/// Manages the process of capturing consistent single-stroke samples (typically 3),
/// synthesizing a golden master template via DTW Barycenter Averaging (DBA) on a
/// background isolate, live sandbox practice, and final encrypted commitment.
@immutable
sealed class GestureEnrollmentState extends Equatable {
  const GestureEnrollmentState();

  @override
  List<Object?> get props => [];
}

/// Active sample recording state in the enrollment wizard.
///
/// Invariant: [previousSamples.length] must equal [sampleIndex] - 1.
@immutable
final class GestureRecordingSampleState extends GestureEnrollmentState {
  /// 1-based index of the sample currently being recorded (e.g. 1, 2, or 3).
  final int sampleIndex;

  /// Total required consistent samples (default: 3).
  final int totalRequiredSamples;

  /// Immutable list of previously recorded valid samples in this enrollment session.
  final List<GestureSample> previousSamples;

  GestureRecordingSampleState({
    required this.sampleIndex,
    this.totalRequiredSamples = 3,
    List<GestureSample> previousSamples = const [],
  })  : previousSamples = List.unmodifiable(previousSamples),
        assert(sampleIndex >= 1 && sampleIndex <= totalRequiredSamples,
            'sampleIndex must be between 1 and totalRequiredSamples'),
        assert(totalRequiredSamples >= 1, 'totalRequiredSamples must be at least 1'),
        assert(previousSamples.length == sampleIndex - 1,
            'previousSamples length must equal sampleIndex - 1');

  /// Creates a copy of this state with updated parameters.
  GestureRecordingSampleState copyWith({
    int? sampleIndex,
    int? totalRequiredSamples,
    List<GestureSample>? previousSamples,
  }) {
    return GestureRecordingSampleState(
      sampleIndex: sampleIndex ?? this.sampleIndex,
      totalRequiredSamples: totalRequiredSamples ?? this.totalRequiredSamples,
      previousSamples: previousSamples ?? this.previousSamples,
    );
  }

  @override
  List<Object?> get props => [
        sampleIndex,
        totalRequiredSamples,
        previousSamples,
      ];
}

/// Template synthesis state.
///
/// Executing DTW Barycenter Averaging (DBA) on a background isolate to align all
/// recorded samples onto sample 1's trajectory and compute the master N=64 coordinate array.
@immutable
final class GestureSynthesizingTemplateState extends GestureEnrollmentState {
  /// The collection of verified consistent samples being synthesized.
  final List<GestureSample> samples;

  GestureSynthesizingTemplateState({
    required List<GestureSample> samples,
  })  : samples = List.unmodifiable(samples),
        assert(samples.isNotEmpty, 'samples must not be empty');

  @override
  List<Object?> get props => [samples];
}

/// Interactive sandbox testing state.
///
/// Allows the user to practice drawing against the freshly synthesized master template
/// before committing it to secure storage.
@immutable
final class GestureSandboxTestingState extends GestureEnrollmentState {
  /// The newly synthesized master template being tested.
  final GestureTemplate synthesizedTemplate;

  /// Number of test attempts made in this sandbox session.
  final int testAttemptsCount;

  /// Result of the most recent practice stroke evaluation, or null if no attempts yet.
  final RecognitionScore? lastScore;

  const GestureSandboxTestingState({
    required this.synthesizedTemplate,
    this.testAttemptsCount = 0,
    this.lastScore,
  }) : assert(testAttemptsCount >= 0, 'testAttemptsCount cannot be negative');

  /// Creates a copy of this state with updated parameters.
  GestureSandboxTestingState copyWith({
    GestureTemplate? synthesizedTemplate,
    int? testAttemptsCount,
    RecognitionScore? lastScore,
  }) {
    return GestureSandboxTestingState(
      synthesizedTemplate: synthesizedTemplate ?? this.synthesizedTemplate,
      testAttemptsCount: testAttemptsCount ?? this.testAttemptsCount,
      lastScore: lastScore ?? this.lastScore,
    );
  }

  @override
  List<Object?> get props => [
        synthesizedTemplate,
        testAttemptsCount,
        lastScore,
      ];
}

/// Final committed enrollment state.
///
/// Master template has been verified and securely persisted in the encrypted vault store.
@immutable
final class GestureCommittedState extends GestureEnrollmentState {
  /// The finalized master template committed to storage.
  final GestureTemplate finalTemplate;

  const GestureCommittedState({
    required this.finalTemplate,
  });

  @override
  List<Object?> get props => [finalTemplate];
}

/// Enrollment failure state.
///
/// Triggered when consecutive samples diverge beyond allowable DTW consistency bounds,
/// or when background synthesis encounters an unrecoverable mathematical error.
@immutable
final class GestureEnrollmentFailedState extends GestureEnrollmentState {
  /// Descriptive failure reason explaining why the enrollment could not proceed.
  final String failureReason;

  const GestureEnrollmentFailedState({
    required this.failureReason,
  }) : assert(failureReason.length > 0, 'failureReason must not be empty');

  @override
  List<Object?> get props => [failureReason];
}
