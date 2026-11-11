import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/states/gesture_engine_state.dart';

/// Sealed state hierarchy governing Region D: Stealth Gesture Engine and Enrollment Wizard.
@immutable
sealed class GestureEngineState extends Equatable {
  const GestureEngineState();

  /// Maps this state to the canonical [GestureEngineStateEnum].
  GestureEngineStateEnum get stateEnum;

  @override
  List<Object?> get props => [];
}

/// Idle state awaiting single-stroke drawing on StealthGesturePad.
@immutable
final class GestureEngineIdleState extends GestureEngineState {
  final GestureTemplate activeTemplate;
  final GestureSensitivityTierEnum sensitivityTier;

  const GestureEngineIdleState({
    required this.activeTemplate,
    required this.sensitivityTier,
  });

  @override
  GestureEngineStateEnum get stateEnum => GestureEngineStateEnum.idle;

  @override
  List<Object?> get props => [activeTemplate, sensitivityTier];
}

/// Executing multi-stage recognition pipeline in background isolate.
@immutable
final class GestureEngineEvaluatingStrokeState extends GestureEngineState {
  final GestureSample liveStroke;
  final GestureTemplate activeTemplate;
  final GestureSensitivityTierEnum sensitivityTier;

  const GestureEngineEvaluatingStrokeState({
    required this.liveStroke,
    required this.activeTemplate,
    required this.sensitivityTier,
  });

  @override
  GestureEngineStateEnum get stateEnum => GestureEngineStateEnum.evaluatingPipeline;

  @override
  List<Object?> get props => [liveStroke, activeTemplate, sensitivityTier];
}

/// Consensus score met or exceeded threshold; gateway trigger emitted.
@immutable
final class GestureEngineMatchConfirmedState extends GestureEngineState {
  final RecognitionScore score;
  final GestureTemplate activeTemplate;
  final GestureSensitivityTierEnum sensitivityTier;

  const GestureEngineMatchConfirmedState({
    required this.score,
    required this.activeTemplate,
    required this.sensitivityTier,
  });

  @override
  GestureEngineStateEnum get stateEnum => GestureEngineStateEnum.matchConfirmed;

  @override
  List<Object?> get props => [score, activeTemplate, sensitivityTier];
}

/// Score below threshold, anti-scribble tripped, or calculation failure; silent buffer wipe.
@immutable
final class GestureEngineRejectedSilentState extends GestureEngineState {
  final RecognitionScore? score;
  final GestureTemplate activeTemplate;
  final GestureSensitivityTierEnum sensitivityTier;

  const GestureEngineRejectedSilentState({
    this.score,
    required this.activeTemplate,
    required this.sensitivityTier,
  });

  @override
  GestureEngineStateEnum get stateEnum => GestureEngineStateEnum.rejectedSilent;

  @override
  List<Object?> get props => [score, activeTemplate, sensitivityTier];
}

/// Wizard enrollment: recording sample 1, 2, or 3 with live stroke capture.
@immutable
final class GestureEngineRecordingSampleState extends GestureEngineState {
  final int sampleIndex;
  final int totalRequiredSamples;
  final List<GestureSample> previousSamples;

  GestureEngineRecordingSampleState({
    required this.sampleIndex,
    this.totalRequiredSamples = 3,
    List<GestureSample> previousSamples = const [],
  })  : previousSamples = List.unmodifiable(previousSamples),
        assert(sampleIndex >= 1 && sampleIndex <= totalRequiredSamples,
            'sampleIndex must be between 1 and totalRequiredSamples'),
        assert(totalRequiredSamples >= 1, 'totalRequiredSamples must be at least 1'),
        assert(previousSamples.length == sampleIndex - 1,
            'previousSamples length must equal sampleIndex - 1');

  @override
  GestureEngineStateEnum get stateEnum => GestureEngineStateEnum.capturingStroke;

  @override
  List<Object?> get props => [
        sampleIndex,
        totalRequiredSamples,
        previousSamples,
      ];
}

/// Wizard enrollment: executing DTW Barycenter Averaging (DBA) on background isolate.
@immutable
final class GestureEngineSynthesizingTemplateState extends GestureEngineState {
  final List<GestureSample> samples;

  GestureEngineSynthesizingTemplateState({
    required List<GestureSample> samples,
  })  : samples = List.unmodifiable(samples),
        assert(samples.isNotEmpty, 'samples must not be empty');

  @override
  GestureEngineStateEnum get stateEnum => GestureEngineStateEnum.evaluatingPipeline;

  @override
  List<Object?> get props => [samples];
}

/// Wizard enrollment: interactive sandbox testing pad for practicing gesture.
@immutable
final class GestureEngineSandboxTestingState extends GestureEngineState {
  final GestureTemplate synthesizedTemplate;
  final int testAttemptsCount;
  final RecognitionScore? lastScore;

  const GestureEngineSandboxTestingState({
    required this.synthesizedTemplate,
    this.testAttemptsCount = 0,
    this.lastScore,
  }) : assert(testAttemptsCount >= 0, 'testAttemptsCount cannot be negative');

  @override
  GestureEngineStateEnum get stateEnum => GestureEngineStateEnum.idle;

  @override
  List<Object?> get props => [
        synthesizedTemplate,
        testAttemptsCount,
        lastScore,
      ];
}

/// Wizard enrollment: master template committed to encrypted storage.
@immutable
final class GestureEngineCommittedState extends GestureEngineState {
  final GestureTemplate finalTemplate;

  const GestureEngineCommittedState({
    required this.finalTemplate,
  });

  @override
  GestureEngineStateEnum get stateEnum => GestureEngineStateEnum.idle;

  @override
  List<Object?> get props => [finalTemplate];
}

/// Wizard enrollment: failure state (divergent samples or synthesis error).
@immutable
final class GestureEngineEnrollmentFailedState extends GestureEngineState {
  final String failureReason;
  final List<GestureSample> previousSamples;

  GestureEngineEnrollmentFailedState({
    required this.failureReason,
    List<GestureSample> previousSamples = const [],
  })  : previousSamples = List.unmodifiable(previousSamples),
        assert(failureReason.isNotEmpty, 'failureReason must not be empty');

  @override
  GestureEngineStateEnum get stateEnum => GestureEngineStateEnum.rejectedSilent;

  @override
  List<Object?> get props => [failureReason, previousSamples];
}

/// David Harel Statechart Region D Controller: Stealth Gesture Engine & Enrollment Wizard.
///
/// Encapsulates live stroke recognition, monotonic epoch superseding,
/// 3-sample DBA template enrollment, sandbox testing, and encrypted commitment.
class GestureEngineCubit extends Cubit<GestureEngineState> {
  final IGestureRecognizer _recognizer;
  final IVaultStorageRepository _storageRepository;
  final IVaultAuthService _vaultAuthService;

  final StreamController<RecognitionScore> _matchConfirmedController;

  GestureTemplate _activeTemplate;
  GestureSensitivityTierEnum _sensitivityTier;
  int _evaluationEpoch = 0;

  GestureEngineCubit({
    required IGestureRecognizer recognizer,
    required IVaultStorageRepository storageRepository,
    required IVaultAuthService vaultAuthService,
    GestureTemplate? initialTemplate,
    GestureSensitivityTierEnum initialSensitivityTier =
        GestureSensitivityTierEnum.balanced84Percent,
  })  : _recognizer = recognizer,
        _storageRepository = storageRepository,
        _vaultAuthService = vaultAuthService,
        _activeTemplate = initialTemplate ?? DefaultGestureTemplate.canonicalVShape,
        _sensitivityTier = initialSensitivityTier,
        _matchConfirmedController = StreamController<RecognitionScore>.broadcast(),
        super(
          GestureEngineIdleState(
            activeTemplate: initialTemplate ?? DefaultGestureTemplate.canonicalVShape,
            sensitivityTier: initialSensitivityTier,
          ),
        );

  /// Broadcast stream emitting verified match scores to the central coordinator.
  Stream<RecognitionScore> get matchConfirmedStream =>
      _matchConfirmedController.stream;

  /// Active reference template currently matched against on StealthGesturePad.
  GestureTemplate get activeTemplate => _activeTemplate;

  /// Active consensus sensitivity tier policy.
  GestureSensitivityTierEnum get sensitivityTier => _sensitivityTier;

  /// Initializes template and sensitivity configuration from persistent encrypted storage.
  Future<void> initialize() async {
    final templateResult = await _storageRepository.loadGestureTemplate();
    if (templateResult case VaultSuccess<GestureTemplate>(:final data)) {
      _activeTemplate = data;
    }

    final configResult = await _storageRepository.loadVaultConfig();
    if (configResult case VaultSuccess(:final data)) {
      _sensitivityTier = data.gestureSensitivity;
    }

    emit(
      GestureEngineIdleState(
        activeTemplate: _activeTemplate,
        sensitivityTier: _sensitivityTier,
      ),
    );
  }

  /// Cancels in-flight background isolate evaluation upon new pointer down.
  void onPointerDown() {
    _evaluationEpoch++;
    if (state is GestureEngineEvaluatingStrokeState) {
      emit(
        GestureEngineIdleState(
          activeTemplate: _activeTemplate,
          sensitivityTier: _sensitivityTier,
        ),
      );
    }
  }

  /// Evaluates a live stroke drawn on the StealthGesturePad in a background isolate.
  Future<void> evaluateStroke(GestureSample liveStroke) async {
    final int callEpoch = ++_evaluationEpoch;

    emit(
      GestureEngineEvaluatingStrokeState(
        liveStroke: liveStroke,
        activeTemplate: _activeTemplate,
        sensitivityTier: _sensitivityTier,
      ),
    );

    final result = await _recognizer.evaluateStroke(
      liveStroke: liveStroke,
      template: _activeTemplate,
      sensitivityTier: _sensitivityTier,
    );

    // Concurrency Gate: Discard dead-on-arrival isolate evaluation if superseded
    if (callEpoch != _evaluationEpoch) {
      return;
    }

    switch (result) {
      case VaultSuccess<RecognitionScore>(:final data):
        switch (data.decision) {
          case GestureMatchDecisionEnum.matched:
            emit(
              GestureEngineMatchConfirmedState(
                score: data,
                activeTemplate: _activeTemplate,
                sensitivityTier: _sensitivityTier,
              ),
            );
            _matchConfirmedController.add(data);
            emit(
              GestureEngineIdleState(
                activeTemplate: _activeTemplate,
                sensitivityTier: _sensitivityTier,
              ),
            );
          case GestureMatchDecisionEnum.rejectedAntiScribble:
          case GestureMatchDecisionEnum.rejectedStructuralGate:
          case GestureMatchDecisionEnum.rejectedClassifierFloor:
          case GestureMatchDecisionEnum.rejectedBelowSensitivityTier:
            emit(
              GestureEngineRejectedSilentState(
                score: data,
                activeTemplate: _activeTemplate,
                sensitivityTier: _sensitivityTier,
              ),
            );
            emit(
              GestureEngineIdleState(
                activeTemplate: _activeTemplate,
                sensitivityTier: _sensitivityTier,
              ),
            );
        }
      case VaultFailureResult<RecognitionScore>():
        emit(
          GestureEngineRejectedSilentState(
            score: null,
            activeTemplate: _activeTemplate,
            sensitivityTier: _sensitivityTier,
          ),
        );
        emit(
          GestureEngineIdleState(
            activeTemplate: _activeTemplate,
            sensitivityTier: _sensitivityTier,
          ),
        );
    }
  }

  /// Dynamically updates the active template (e.g., upon enrollment commitment).
  void updateActiveTemplate(GestureTemplate template) {
    _activeTemplate = template;
    if (state is GestureEngineIdleState) {
      emit(
        GestureEngineIdleState(
          activeTemplate: _activeTemplate,
          sensitivityTier: _sensitivityTier,
        ),
      );
    }
  }

  /// Dynamically updates the consensus sensitivity tier (e.g., from settings).
  void updateSensitivityTier(GestureSensitivityTierEnum tier) {
    _sensitivityTier = tier;
    if (state is GestureEngineIdleState) {
      emit(
        GestureEngineIdleState(
          activeTemplate: _activeTemplate,
          sensitivityTier: _sensitivityTier,
        ),
      );
    }
  }

  // --- Multi-Sample 3-Sample Enrollment Wizard Methods ---

  /// Begins guided 3-sample gesture enrollment wizard.
  void startEnrollment({int totalRequiredSamples = 3}) {
    emit(
      GestureEngineRecordingSampleState(
        sampleIndex: 1,
        totalRequiredSamples: totalRequiredSamples,
        previousSamples: const [],
      ),
    );
  }

  /// Submits a drawn gesture sample during the enrollment wizard.
  Future<void> recordSample(GestureSample sample) async {
    final currentState = state;
    if (currentState is! GestureEngineRecordingSampleState) {
      return;
    }

    final previous = currentState.previousSamples;

    // Validate pairwise consistency with previous samples
    if (previous.isNotEmpty) {
      final consistencyResult = await _recognizer.validateSampleConsistency(
        samples: [...previous, sample],
      );
      if (consistencyResult case VaultFailureResult(:final failure)) {
        emit(
          GestureEngineEnrollmentFailedState(
            failureReason:
                'Sample diverged from previous strokes: ${failure.message}',
            previousSamples: previous,
          ),
        );
        return;
      }
    }

    if (currentState.sampleIndex < currentState.totalRequiredSamples) {
      emit(
        GestureEngineRecordingSampleState(
          sampleIndex: currentState.sampleIndex + 1,
          totalRequiredSamples: currentState.totalRequiredSamples,
          previousSamples: [...previous, sample],
        ),
      );
    } else {
      final allSamples = [...previous, sample];
      emit(GestureEngineSynthesizingTemplateState(samples: allSamples));

      final synthesisResult = await _recognizer.synthesizeMasterTemplate(
        samples: allSamples,
      );

      switch (synthesisResult) {
        case VaultSuccess<GestureTemplate>(:final data):
          emit(
            GestureEngineSandboxTestingState(
              synthesizedTemplate: data,
              testAttemptsCount: 0,
            ),
          );
        case VaultFailureResult<GestureTemplate>(:final failure):
          emit(
            GestureEngineEnrollmentFailedState(
              failureReason: 'DBA Synthesis failed: ${failure.message}',
              previousSamples: allSamples,
            ),
          );
      }
    }
  }

  /// Evaluates a test stroke inside the sandbox testing pad.
  Future<void> testSandboxStroke(GestureSample testStroke) async {
    final currentState = state;
    if (currentState is! GestureEngineSandboxTestingState) {
      return;
    }

    final scoreResult = await _recognizer.evaluateStroke(
      liveStroke: testStroke,
      template: currentState.synthesizedTemplate,
      sensitivityTier: _sensitivityTier,
    );

    final score = switch (scoreResult) {
      VaultSuccess(:final data) => data,
      VaultFailureResult() => null,
    };

    emit(
      GestureEngineSandboxTestingState(
        synthesizedTemplate: currentState.synthesizedTemplate,
        testAttemptsCount: currentState.testAttemptsCount + 1,
        lastScore: score,
      ),
    );
  }

  /// Authorizes with PIN and commits the synthesized template to encrypted storage.
  Future<VaultResult<GestureTemplate>> commitEnrollment({
    required String authorizationPin,
  }) async {
    final currentState = state;
    if (currentState is! GestureEngineSandboxTestingState) {
      return const VaultResult.failure(
        VaultValidationFailure(
          'Cannot commit template outside of SandboxTesting state.',
        ),
      );
    }

    final pinResult = await _vaultAuthService.authenticateWithPin(
      pin: authorizationPin,
    );
    if (pinResult case VaultFailureResult(:final failure)) {
      return VaultResult.failure(
        VaultAuthFailure(
          'Step-up PIN authentication failed: ${failure.message}',
          cause: failure.cause,
        ),
      );
    }

    final template = currentState.synthesizedTemplate;
    final saveResult = await _storageRepository.saveGestureTemplate(template);
    if (saveResult case VaultFailureResult(:final failure)) {
      return VaultResult.failure(failure);
    }

    _activeTemplate = template;
    emit(GestureEngineCommittedState(finalTemplate: template));
    emit(
      GestureEngineIdleState(
        activeTemplate: _activeTemplate,
        sensitivityTier: _sensitivityTier,
      ),
    );

    return VaultResult.success(template);
  }

  /// Cancels active enrollment and restores idle live recognition state.
  void cancelEnrollment() {
    emit(
      GestureEngineIdleState(
        activeTemplate: _activeTemplate,
        sensitivityTier: _sensitivityTier,
      ),
    );
  }

  /// Retries the current sample recording step following a failure.
  void retryRecordingFromFailure() {
    final currentState = state;
    if (currentState is! GestureEngineEnrollmentFailedState) {
      return;
    }

    final previous = currentState.previousSamples;
    emit(
      GestureEngineRecordingSampleState(
        sampleIndex: previous.length + 1,
        totalRequiredSamples: 3,
        previousSamples: previous,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _matchConfirmedController.close();
    return super.close();
  }
}
