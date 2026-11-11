// ignore_for_file: prefer_conditional_assignment

import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/data/gesture/raw_touch_filter.dart';
import 'package:musify_mu/features/vault/data/services/gesture_recognizer_service.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/enroll_gesture_use_case.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_session_scaffold_guard.dart';

/// Exhaustive sealed state hierarchy governing the gesture enrollment wizard and sandbox testing.
@immutable
sealed class GestureEnrollmentState extends Equatable {
  const GestureEnrollmentState();

  @override
  List<Object?> get props => [];
}

/// State 1: Active single-stroke sample recording (Sample 1, 2, or 3).
@immutable
final class GestureRecordingSampleState extends GestureEnrollmentState {
  final int sampleIndex;
  final int totalRequiredSamples;
  final List<GestureSample> previousSamples;

  GestureRecordingSampleState({
    required this.sampleIndex,
    this.totalRequiredSamples = 3,
    List<GestureSample> previousSamples = const [],
  })  : previousSamples = List.unmodifiable(previousSamples),
        assert(
          sampleIndex >= 1 && sampleIndex <= totalRequiredSamples,
          'sampleIndex must be between 1 and totalRequiredSamples',
        ),
        assert(
          totalRequiredSamples >= 1,
          'totalRequiredSamples must be at least 1',
        ),
        assert(
          previousSamples.length == sampleIndex - 1,
          'previousSamples length must equal sampleIndex - 1',
        );

  @override
  List<Object?> get props => [
        sampleIndex,
        totalRequiredSamples,
        previousSamples,
      ];
}

/// State 2: Validating consistency or synthesizing DBA template on background isolate.
@immutable
final class GestureSynthesizingTemplateState extends GestureEnrollmentState {
  final List<GestureSample> samples;

  GestureSynthesizingTemplateState({
    required List<GestureSample> samples,
  })  : samples = List.unmodifiable(samples),
        assert(samples.isNotEmpty, 'samples must not be empty');

  @override
  List<Object?> get props => [samples];
}

/// State 3: Interactive sandbox practice pad before final persistence.
@immutable
final class GestureSandboxTestingState extends GestureEnrollmentState {
  final GestureTemplate synthesizedTemplate;
  final int testAttemptsCount;
  final int successfulMatchesCount;
  final RecognitionScore? lastScore;

  const GestureSandboxTestingState({
    required this.synthesizedTemplate,
    this.testAttemptsCount = 0,
    this.successfulMatchesCount = 0,
    this.lastScore,
  })  : assert(testAttemptsCount >= 0, 'testAttemptsCount cannot be negative'),
        assert(
          successfulMatchesCount >= 0,
          'successfulMatchesCount cannot be negative',
        ),
        assert(
          successfulMatchesCount <= testAttemptsCount,
          'successfulMatchesCount cannot exceed testAttemptsCount',
        );

  GestureSandboxTestingState copyWith({
    GestureTemplate? synthesizedTemplate,
    int? testAttemptsCount,
    int? successfulMatchesCount,
    RecognitionScore? lastScore,
  }) {
    return GestureSandboxTestingState(
      synthesizedTemplate: switch (synthesizedTemplate) {
        final t? => t,
        null => this.synthesizedTemplate,
      },
      testAttemptsCount: switch (testAttemptsCount) {
        final c? => c,
        null => this.testAttemptsCount,
      },
      successfulMatchesCount: switch (successfulMatchesCount) {
        final m? => m,
        null => this.successfulMatchesCount,
      },
      lastScore: switch (lastScore) {
        final s? => s,
        null => this.lastScore,
      },
    );
  }

  @override
  List<Object?> get props => [
        synthesizedTemplate,
        testAttemptsCount,
        successfulMatchesCount,
        lastScore,
      ];
}

/// State 4: Master template committed to encrypted storage.
@immutable
final class GestureCommittedState extends GestureEnrollmentState {
  final GestureTemplate finalTemplate;

  const GestureCommittedState({
    required this.finalTemplate,
  });

  @override
  List<Object?> get props => [finalTemplate];
}

/// State 5: Sample inconsistency or synthesis failure with recovery context.
@immutable
final class GestureEnrollmentFailedState extends GestureEnrollmentState {
  final String failureReason;
  final List<GestureSample> preservedSamples;

  GestureEnrollmentFailedState({
    required this.failureReason,
    List<GestureSample> preservedSamples = const [],
  })  : preservedSamples = List.unmodifiable(preservedSamples),
        assert(failureReason.isNotEmpty, 'failureReason must not be empty');

  @override
  List<Object?> get props => [failureReason, preservedSamples];
}

/// Full-screen guided enrollment wizard for secret stealth gesture template creation.
///
/// Implements:
/// - Guided 3-sample capture tracking sample 1, 2, 3 with live stroke validation.
/// - Live high-performance ink rendering with quadratic Bezier midpoint smoothing.
/// - Pairwise FastDTW consistency evaluation across samples with per-sample retry recovery.
/// - Background isolate template synthesis via DTW Barycenter Averaging (DBA).
/// - Interactive sandbox test pad allowing practice strokes against the candidate template.
/// - Step-up PIN authentication via [VaultAuthScreen] before encrypted storage persistence.
/// - Strict zero loose booleans and design system compliance (zero purple, zero pill buttons,
///   zero emojis, zero em dashes).
class GestureEnrollmentScreen extends StatefulWidget {
  /// Optional injected Cubit for Region D integration.
  final GestureEngineCubit? gestureEngineCubit;

  /// Optional underlying gesture recognition pipeline service.
  final IGestureRecognizer? recognizer;

  /// Optional storage repository for persistence.
  final IVaultStorageRepository? storageRepository;

  /// Optional auth service for step-up PIN verification.
  final IVaultAuthService? authService;

  /// Optional domain interactor use case.
  final EnrollGestureUseCase? enrollGestureUseCase;

  /// Optional screen privacy cubit for FLAG_SECURE management.
  final ScreenPrivacyCubit? screenPrivacyCubit;

  /// Optional vault session bloc for security state observation.
  final VaultSessionBloc? sessionBloc;

  /// Optional PIN pad cubit for step-up authentication.
  final PinPadCubit? pinPadCubit;

  /// Optional completion callback.
  final VoidCallback? onEnrollmentComplete;

  /// Optional pre-verified step-up authorization PIN.
  final String? initialAuthorizationPin;

  const GestureEnrollmentScreen({
    this.gestureEngineCubit,
    this.recognizer,
    this.storageRepository,
    this.authService,
    this.enrollGestureUseCase,
    this.screenPrivacyCubit,
    this.sessionBloc,
    this.pinPadCubit,
    this.onEnrollmentComplete,
    this.initialAuthorizationPin,
    super.key,
  });

  @override
  State<GestureEnrollmentScreen> createState() =>
      _GestureEnrollmentScreenState();
}

class _GestureEnrollmentScreenState extends State<GestureEnrollmentScreen> {
  late GestureEnrollmentState _enrollmentState;
  final List<GestureSample> _collectedSamples = <GestureSample>[];
  final List<GesturePoint> _rawPoints = <GesturePoint>[];
  final List<Offset> _liveDisplayPoints = <Offset>[];

  int _strokeStartMs = 0;
  bool _isPointerDown = false;
  String? _temporaryWarningMessage;

  ScreenPrivacyCubit? _screenPrivacyCubit;

  @override
  void initState() {
    super.initState();
    _enrollmentState = GestureRecordingSampleState(sampleIndex: 1);
    _engageScreenPrivacy();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_screenPrivacyCubit == null) {
      _screenPrivacyCubit = _resolveScreenPrivacyCubit();
    }
  }

  void _engageScreenPrivacy() {
    if (_screenPrivacyCubit == null) {
      _screenPrivacyCubit = _resolveScreenPrivacyCubit();
    }
    _screenPrivacyCubit?.engageSecureFlag(
      reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
    );
  }

  VaultSessionBloc? _resolveSessionBloc() {
    if (widget.sessionBloc case final bloc?) {
      return bloc;
    }
    if (!mounted) return null;
    try {
      return context.read<VaultSessionBloc>();
    } catch (_) {
      return null;
    }
  }

  void _releaseScreenPrivacy() {
    final cubit = _screenPrivacyCubit;
    if (cubit != null && !cubit.isClosed) {
      cubit.releaseSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );
    }
  }

  PinPadCubit? _resolvePinPadCubit() {
    if (widget.pinPadCubit case final cubit?) {
      return cubit;
    }
    if (!mounted) return null;
    try {
      return context.read<PinPadCubit>();
    } catch (_) {
      return null;
    }
  }

  ScreenPrivacyCubit? _resolveScreenPrivacyCubit() {
    if (widget.screenPrivacyCubit case final cubit?) {
      return cubit;
    }
    if (!mounted) return _screenPrivacyCubit;
    try {
      return context.read<ScreenPrivacyCubit>();
    } catch (_) {
      return _screenPrivacyCubit;
    }
  }

  GestureEngineCubit? _resolveGestureEngineCubit() {
    if (widget.gestureEngineCubit case final cubit?) {
      return cubit;
    }
    if (!mounted) return null;
    try {
      return context.read<GestureEngineCubit>();
    } catch (_) {
      return null;
    }
  }

  IGestureRecognizer _resolveRecognizer() {
    if (widget.recognizer case final rec?) {
      return rec;
    }
    if (!mounted) return GestureRecognizerService();
    try {
      final fromContext = context.read<IGestureRecognizer>();
      return fromContext;
    } catch (_) {
      return GestureRecognizerService();
    }
  }

  IVaultStorageRepository? _resolveStorageRepository() {
    if (widget.storageRepository case final repo?) {
      return repo;
    }
    if (!mounted) return null;
    try {
      return context.read<IVaultStorageRepository>();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _releaseScreenPrivacy();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_isPointerDown) return;
    _isPointerDown = true;
    _rawPoints.clear();
    _liveDisplayPoints.clear();
    _strokeStartMs = DateTime.now().millisecondsSinceEpoch;

    final pt = GesturePoint(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      timestampMs: 0,
    );
    _rawPoints.add(pt);
    _liveDisplayPoints.add(event.localPosition);

    setState(() {
      _temporaryWarningMessage = null;
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isPointerDown) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - _strokeStartMs;

    final pt = GesturePoint(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      timestampMs: (elapsed < 0) ? 0 : elapsed,
    );
    _rawPoints.add(pt);
    _liveDisplayPoints.add(event.localPosition);
    setState(() {});
  }

  Future<void> _onPointerUp(PointerUpEvent event) async {
    if (!_isPointerDown) return;
    _isPointerDown = false;

    if (_rawPoints.isEmpty) {
      _liveDisplayPoints.clear();
      setState(() {});
      return;
    }

    // 1. Calculate trajectory arc length
    double totalLength = 0.0;
    for (int i = 0; i < _rawPoints.length - 1; i++) {
      final dx = _rawPoints[i + 1].x - _rawPoints[i].x;
      final dy = _rawPoints[i + 1].y - _rawPoints[i].y;
      totalLength += math.sqrt(dx * dx + dy * dy);
    }

    // 2. Deadband pre-filtering check (< 2.5px)
    if (totalLength < RawTouchFilter.defaultDeadbandThreshold) {
      _rawPoints.clear();
      _liveDisplayPoints.clear();
      setState(() {
        _temporaryWarningMessage =
            'Stroke too brief. Draw a continuous gesture.';
      });
      return;
    }

    final int sampledAt = (_strokeStartMs > 0)
        ? _strokeStartMs
        : DateTime.now().millisecondsSinceEpoch;

    final GestureSample sample;
    try {
      sample = GestureSample(
        points: List.unmodifiable(_rawPoints),
        sampledAtEpochMs: sampledAt,
        totalLength: totalLength,
      );
    } on FormatException catch (e) {
      _rawPoints.clear();
      _liveDisplayPoints.clear();
      setState(() {
        _temporaryWarningMessage = e.message;
      });
      return;
    }

    _rawPoints.clear();

    final currentState = _enrollmentState;
    switch (currentState) {
      case GestureRecordingSampleState():
        await _handleWizardSample(sample, currentState);
      case GestureSandboxTestingState():
        await _handleSandboxStroke(sample, currentState);
      case GestureSynthesizingTemplateState():
      case GestureCommittedState():
      case GestureEnrollmentFailedState():
        _liveDisplayPoints.clear();
        setState(() {});
    }
  }

  Future<void> _handleWizardSample(
    GestureSample sample,
    GestureRecordingSampleState state,
  ) async {
    final recognizer = _resolveRecognizer();
    final previous = _collectedSamples;

    // Validate pairwise DTW consistency if this is sample 2 or 3
    if (previous.isNotEmpty) {
      final consistencyResult = await recognizer.validateSampleConsistency(
        samples: [...previous, sample],
      );
      if (consistencyResult case VaultFailureResult(:final failure)) {
        HapticFeedback.mediumImpact();
        setState(() {
          _liveDisplayPoints.clear();
          _temporaryWarningMessage =
              'Stroke differed from previous sample: ${failure.message}';
        });
        return;
      }
    }

    _collectedSamples.add(sample);
    _liveDisplayPoints.clear();

    if (_collectedSamples.length < 3) {
      HapticFeedback.lightImpact();
      setState(() {
        _enrollmentState = GestureRecordingSampleState(
          sampleIndex: _collectedSamples.length + 1,
          previousSamples: List.unmodifiable(_collectedSamples),
        );
      });
    } else {
      // Trigger background isolate DBA synthesis
      setState(() {
        _enrollmentState = GestureSynthesizingTemplateState(
          samples: List.unmodifiable(_collectedSamples),
        );
      });

      final synthesisResult = await recognizer.synthesizeMasterTemplate(
        samples: _collectedSamples,
      );

      switch (synthesisResult) {
        case VaultSuccess<GestureTemplate>(:final data):
          HapticFeedback.mediumImpact();
          setState(() {
            _enrollmentState = GestureSandboxTestingState(
              synthesizedTemplate: data,
              testAttemptsCount: 0,
              successfulMatchesCount: 0,
            );
          });
        case VaultFailureResult<GestureTemplate>(:final failure):
          setState(() {
            _enrollmentState = GestureEnrollmentFailedState(
              failureReason: 'Synthesis error: ${failure.message}',
              preservedSamples: List.unmodifiable(_collectedSamples),
            );
          });
      }
    }
  }

  Future<void> _handleSandboxStroke(
    GestureSample sample,
    GestureSandboxTestingState state,
  ) async {
    final recognizer = _resolveRecognizer();
    final scoreResult = await recognizer.evaluateStroke(
      liveStroke: sample,
      template: state.synthesizedTemplate,
      sensitivityTier: GestureSensitivityTierEnum.balanced84Percent,
    );

    _liveDisplayPoints.clear();

    final score = switch (scoreResult) {
      VaultSuccess(:final data) => data,
      VaultFailureResult() => null,
    };

    final isMatch = score?.decision == GestureMatchDecisionEnum.matched;
    if (isMatch) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _enrollmentState = state.copyWith(
        testAttemptsCount: state.testAttemptsCount + 1,
        successfulMatchesCount:
            state.successfulMatchesCount + (isMatch ? 1 : 0),
        lastScore: score,
      );
    });
  }

  Future<void> _commitEnrollment(GestureTemplate template) async {
    String? pin = widget.initialAuthorizationPin;

    if (pin == null) {
      final authResult = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => VaultAuthScreen(
            mode: VaultAuthScreenMode.stepUp,
            titleOverride: 'Authorize Gesture Enrollment',
            pinPadCubit: switch (widget.pinPadCubit) {
              final c? => c,
              null => _resolvePinPadCubit(),
            },
            sessionBloc: _resolveSessionBloc(),
            screenPrivacyCubit: _resolveScreenPrivacyCubit(),
          ),
        ),
      );

      if (authResult != true) {
        return;
      }
    }

    final storage = _resolveStorageRepository();
    if (storage != null) {
      final saveResult = await storage.saveGestureTemplate(template);
      switch (saveResult) {
        case VaultSuccess<void>():
          break;
        case VaultFailureResult<void>(:final failure):
          setState(() {
            _temporaryWarningMessage =
                'Failed to persist template: ${failure.message}';
          });
          return;
      }
    }

    final cubit = _resolveGestureEngineCubit();
    cubit?.updateActiveTemplate(template);

    setState(() {
      _enrollmentState = GestureCommittedState(finalTemplate: template);
    });

    widget.onEnrollmentComplete?.call();

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  void _resetToSampleOne() {
    _collectedSamples.clear();
    _rawPoints.clear();
    _liveDisplayPoints.clear();
    setState(() {
      _temporaryWarningMessage = null;
      _enrollmentState = GestureRecordingSampleState(sampleIndex: 1);
    });
  }

  void _clearCurrentStroke() {
    _rawPoints.clear();
    _liveDisplayPoints.clear();
    setState(() {
      _temporaryWarningMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vaultTheme = VaultTheme.of(context);

    return VaultSessionScaffoldGuard(
      sessionBlocOverride: _resolveSessionBloc(),
      child: Scaffold(
        key: const ValueKey('gesture_enrollment_scaffold'),
      backgroundColor: vaultTheme.scaffold,
      appBar: AppBar(
        backgroundColor: vaultTheme.scaffold,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          key: const ValueKey('gesture_enrollment_back_button'),
          icon: Icon(
            Icons.arrow_back,
            color: vaultTheme.textHighSalience,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(false);
            }
          },
        ),
        title: Text(
          'Enroll Secret Gesture',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: vaultTheme.textHighSalience,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStepIndicator(vaultTheme),
              const SizedBox(height: 16.0),
              _buildHeaderSection(vaultTheme),
              if (_temporaryWarningMessage case final warning?) ...[
                const SizedBox(height: 12.0),
                _buildWarningBanner(warning, vaultTheme),
              ],
              const SizedBox(height: 16.0),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      key: const ValueKey('gesture_enrollment_pad'),
                      decoration: BoxDecoration(
                        color: vaultTheme.surfaceSubtle,
                        borderRadius: VaultTheme.borderRadius8,
                        border: Border.all(
                          color: vaultTheme.border,
                          width: VaultTheme.borderWidth,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: VaultTheme.borderRadius8,
                        child: Stack(
                          children: [
                            _buildWatermarkGrid(vaultTheme),
                            Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: _onPointerDown,
                              onPointerMove: _onPointerMove,
                              onPointerUp: _onPointerUp,
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: GestureInkPainter(
                                    points: _liveDisplayPoints,
                                    strokeColor: vaultTheme.accent,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              _buildBottomControls(vaultTheme),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildStepIndicator(VaultThemeData vaultTheme) {
    final activeIndex = switch (_enrollmentState) {
      GestureRecordingSampleState(:final sampleIndex) => sampleIndex,
      GestureSynthesizingTemplateState() => 3,
      GestureSandboxTestingState() => 4,
      GestureCommittedState() => 4,
      GestureEnrollmentFailedState() => 1,
    };

    return Row(
      children: [
        for (int i = 1; i <= 3; i++) ...[
          Expanded(
            child: Container(
              key: ValueKey('gesture_step_indicator_$i'),
              height: 6.0,
              decoration: BoxDecoration(
                color: i < activeIndex
                    ? vaultTheme.accent
                    : (i == activeIndex
                        ? vaultTheme.accent.withValues(alpha: 0.60)
                        : vaultTheme.surfaceSubtle),
                borderRadius: BorderRadius.circular(3.0),
                border: Border.all(
                  color: i <= activeIndex
                      ? vaultTheme.accent
                      : vaultTheme.borderSubtle,
                  width: 1.0,
                ),
              ),
            ),
          ),
          if (i < 3) const SizedBox(width: 8.0),
        ],
      ],
    );
  }

  Widget _buildHeaderSection(VaultThemeData vaultTheme) {
    final (title, subtitle) = switch (_enrollmentState) {
      GestureRecordingSampleState(:final sampleIndex) => (
          'Sample $sampleIndex of 3',
          sampleIndex == 1
              ? 'Draw your secret single-stroke gesture on the canvas.'
              : 'Draw the same gesture again to verify consistency.',
        ),
      GestureSynthesizingTemplateState() => (
          'Synthesizing Template',
          'Executing DTW Barycenter Averaging on background isolate...',
        ),
      GestureSandboxTestingState() => (
          'Practice & Verify',
          'Draw on the test pad to test recognition confidence before saving.',
        ),
      GestureCommittedState() => (
          'Gesture Enrolled',
          'Your secret stealth gesture has been encrypted and saved.',
        ),
      GestureEnrollmentFailedState(:final failureReason) => (
          'Sample Inconsistency',
          failureReason,
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 20.0,
            fontWeight: FontWeight.w600,
            color: vaultTheme.textHighSalience,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 13.0,
            fontWeight: FontWeight.w400,
            color: vaultTheme.textMediumSalience,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningBanner(String message, VaultThemeData vaultTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: vaultTheme.danger.withValues(alpha: 0.12),
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: vaultTheme.danger,
          width: VaultTheme.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 18.0,
            color: vaultTheme.danger,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 12.0,
                color: vaultTheme.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatermarkGrid(VaultThemeData vaultTheme) {
    return CustomPaint(
      painter: _CanvasGridPainter(gridColor: vaultTheme.borderSubtle),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildBottomControls(VaultThemeData vaultTheme) {
    final currentState = _enrollmentState;
    switch (currentState) {
      case GestureRecordingSampleState():
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('gesture_clear_stroke_button'),
                onPressed: _clearCurrentStroke,
                style: OutlinedButton.styleFrom(
                  shape: VaultTheme.shape8,
                  side: BorderSide(
                    color: vaultTheme.border,
                    width: VaultTheme.borderWidth,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                ),
                child: Text(
                  'Clear Stroke',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: vaultTheme.textMediumSalience,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('gesture_start_over_button'),
                onPressed: _resetToSampleOne,
                style: OutlinedButton.styleFrom(
                  shape: VaultTheme.shape8,
                  side: BorderSide(
                    color: vaultTheme.border,
                    width: VaultTheme.borderWidth,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                ),
                child: Text(
                  'Start Over',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: vaultTheme.textMediumSalience,
                  ),
                ),
              ),
            ),
          ],
        );

      case GestureSynthesizingTemplateState():
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: vaultTheme.accent,
            ),
          ),
        );

      case GestureSandboxTestingState(:final synthesizedTemplate):
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTelemetryCard(currentState, vaultTheme),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('gesture_rerecord_button'),
                    onPressed: _resetToSampleOne,
                    style: OutlinedButton.styleFrom(
                      shape: VaultTheme.shape8,
                      side: BorderSide(
                        color: vaultTheme.border,
                        width: VaultTheme.borderWidth,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                    ),
                    child: Text(
                      'Re-record Gesture',
                      style: TextStyle(
                        fontFamily: VaultTheme.fontFamily,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                        color: vaultTheme.textMediumSalience,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('gesture_save_button'),
                    onPressed: () => _commitEnrollment(synthesizedTemplate),
                    style: FilledButton.styleFrom(
                      backgroundColor: vaultTheme.accent,
                      foregroundColor: vaultTheme.scaffold,
                      shape: VaultTheme.shape8,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                    ),
                    child: const Text(
                      'Save Gesture',
                      style: TextStyle(
                        fontFamily: VaultTheme.fontFamily,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case GestureCommittedState():
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: vaultTheme.surfaceSubtle,
            borderRadius: VaultTheme.borderRadius8,
            border: Border.all(
              color: vaultTheme.accent,
              width: VaultTheme.borderWidth,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: vaultTheme.accent,
                size: 20.0,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Gesture Enrolled Successfully',
                style: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: vaultTheme.textHighSalience,
                ),
              ),
            ],
          ),
        );

      case GestureEnrollmentFailedState():
        return ElevatedButton(
          key: const ValueKey('gesture_retry_failed_button'),
          onPressed: _resetToSampleOne,
          style: ElevatedButton.styleFrom(
            backgroundColor: vaultTheme.surface,
            shape: VaultTheme.shape8,
            padding: const EdgeInsets.symmetric(vertical: 14.0),
          ),
          child: Text(
            'Try Again From Sample 1',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              color: vaultTheme.textHighSalience,
            ),
          ),
        );
    }
  }

  Widget _buildTelemetryCard(
    GestureSandboxTestingState state,
    VaultThemeData vaultTheme,
  ) {
    final lastScore = state.lastScore;

    if (lastScore == null) {
      return Container(
        key: const ValueKey('gesture_telemetry_card'),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: vaultTheme.surfaceSubtle,
          borderRadius: VaultTheme.borderRadius8,
          border: Border.all(
            color: vaultTheme.border,
            width: VaultTheme.borderWidth,
          ),
        ),
        child: Center(
          child: Text(
            'Draw on the pad to test match recognition',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontSize: 12.0,
              color: vaultTheme.textMediumSalience,
            ),
          ),
        ),
      );
    }

    final isMatch = lastScore.decision == GestureMatchDecisionEnum.matched;
    final matchPercentage = (lastScore.ensembleScore * 100.0).toStringAsFixed(1);

    return Container(
      key: const ValueKey('gesture_telemetry_card'),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: vaultTheme.surfaceSubtle,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: isMatch ? vaultTheme.accent : vaultTheme.danger,
          width: VaultTheme.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMatch ? Icons.check_circle_outline : Icons.error_outline,
                size: 18.0,
                color: isMatch ? vaultTheme.accent : vaultTheme.danger,
              ),
              const SizedBox(width: 8.0),
              Text(
                isMatch
                    ? 'Match Confirmed ($matchPercentage%)'
                    : 'No Match ($matchPercentage%)',
                style: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: isMatch ? vaultTheme.accent : vaultTheme.danger,
                ),
              ),
              const Spacer(),
              Text(
                'Tests: ${state.testAttemptsCount} (${state.successfulMatchesCount} matched)',
                style: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  fontSize: 11.0,
                  color: vaultTheme.textMediumSalience,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            '\$1: ${lastScore.dollarOneScore.toStringAsFixed(2)} | DTW: ${lastScore.dtwScore.toStringAsFixed(2)} | Rubine: ${lastScore.featureScore.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontSize: 11.0,
              color: vaultTheme.textMediumSalience,
            ),
          ),
        ],
      ),
    );
  }
}

/// Canvas grid watermark painter.
class _CanvasGridPainter extends CustomPainter {
  final Color gridColor;

  const _CanvasGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withValues(alpha: 0.35)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Crosshairs through the center
    final midX = size.width / 2.0;
    final midY = size.height / 2.0;

    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), paint);
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
  }

  @override
  bool shouldRepaint(covariant _CanvasGridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor;
}

/// Custom painter rendering smooth live ink with quadratic Bezier midpoint smoothing.
class GestureInkPainter extends CustomPainter {
  final List<Offset> points;
  final Color strokeColor;
  final double strokeWidth;

  const GestureInkPainter({
    required this.points,
    required this.strokeColor,
    this.strokeWidth = 3.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (points.length == 1) {
      canvas.drawCircle(
        points.first,
        strokeWidth / 2.0,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2.0, (p0.dy + p1.dy) / 2.0);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }

    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant GestureInkPainter oldDelegate) {
    return oldDelegate.points.length != points.length ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
