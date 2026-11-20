import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';

/// Immutable snapshot of the local Android `STREAM_MUSIC` volume state
/// (`#47 §4.3`).
@immutable
final class SystemVolumeSnapshot extends Equatable {
  /// Volume scaled to Connect wire range (`0..65535`).
  final int volume;

  /// Maximum discrete volume steps for `STREAM_MUSIC` (`>= 1`).
  final int steps;

  /// Current discrete volume step index (`0..steps`).
  final int currentStep;

  SystemVolumeSnapshot({
    required this.volume,
    required this.steps,
    required this.currentStep,
  }) {
    if (volume < 0 || volume > kMaxConnectVolumeWire) {
      throw RangeError.range(
        volume,
        0,
        kMaxConnectVolumeWire,
        'volume',
        'Must be within [0, $kMaxConnectVolumeWire]',
      );
    }
    if (steps < 0) {
      throw RangeError.value(steps, 'steps', 'Must be non-negative');
    }
    if (currentStep < 0) {
      throw RangeError.value(
        currentStep,
        'currentStep',
        'Must be non-negative',
      );
    }
  }

  /// Normalized volume in `[0.0, 1.0]`.
  double get normalizedVolume => volume / kMaxConnectVolumeWire;

  @override
  List<Object?> get props => [volume, steps, currentStep];
}

/// Sealed event stream emitted by `SystemVolumeBridge.kt` (`#47 §4.3`).
@immutable
sealed class SystemVolumeEvent extends Equatable {
  const SystemVolumeEvent();
}

/// Local Android `STREAM_MUSIC` volume changed via OS hardware keys or slider.
@immutable
final class LocalVolumeChanged extends SystemVolumeEvent {
  final int volume;
  final int steps;
  final int currentStep;

  LocalVolumeChanged({
    required this.volume,
    required this.steps,
    required this.currentStep,
  }) {
    if (volume < 0 || volume > kMaxConnectVolumeWire) {
      throw RangeError.range(
        volume,
        0,
        kMaxConnectVolumeWire,
        'volume',
        'Must be within [0, $kMaxConnectVolumeWire]',
      );
    }
    if (steps < 0) {
      throw RangeError.value(steps, 'steps', 'Must be non-negative');
    }
    if (currentStep < 0) {
      throw RangeError.value(
        currentStep,
        'currentStep',
        'Must be non-negative',
      );
    }
  }

  SystemVolumeSnapshot get snapshot => SystemVolumeSnapshot(
        volume: volume,
        steps: steps,
        currentStep: currentStep,
      );

  double get normalizedVolume => volume / kMaxConnectVolumeWire;

  @override
  List<Object?> get props => [volume, steps, currentStep];
}

/// Hardware volume key press intercepted by `VolumeProviderCompat.onAdjustVolume`
/// while remote playback is active (`direction` is strictly `-1` or `+1`;
/// `AudioManager.ADJUST_SAME (0)` is ignored).
@immutable
final class RemoteVolumeAdjust extends SystemVolumeEvent {
  final int direction;

  RemoteVolumeAdjust({required this.direction}) {
    if (direction != -1 && direction != 1) {
      throw ArgumentError.value(
        direction,
        'direction',
        'Must be -1 or +1 (ADJUST_SAME == 0 is forbidden)',
      );
    }
  }

  @override
  List<Object?> get props => [direction];
}

/// Absolute remote volume set via Android volume slider intercepted by
/// `VolumeProviderCompat.onSetVolumeTo` (`volume` in `0..65535`).
@immutable
final class RemoteVolumeSet extends SystemVolumeEvent {
  final int volume;

  RemoteVolumeSet({required this.volume}) {
    if (volume < 0 || volume > kMaxConnectVolumeWire) {
      throw RangeError.range(
        volume,
        0,
        kMaxConnectVolumeWire,
        'volume',
        'Must be within [0, $kMaxConnectVolumeWire]',
      );
    }
  }

  double get normalizedVolume => volume / kMaxConnectVolumeWire;

  @override
  List<Object?> get props => [volume];
}

/// Domain port for reading/setting Android `STREAM_MUSIC` volume and routing
/// hardware volume keys to active remote Connect devices via
/// `MediaSessionCompat` + `VolumeProviderCompat` (`#47 §4.3`, `#47 §5`).
abstract class SystemVolumePort {
  /// Returns the current local `STREAM_MUSIC` volume snapshot (`0..65535`).
  Future<SystemVolumeSnapshot> getLocalVolume();

  /// Sets the local `STREAM_MUSIC` volume (`0..65535`) with self-echo
  /// suppression.
  Future<bool> setLocalVolume({
    required int volume,
    bool showUi = false,
  });

  /// Enables or disables remote hardware volume button interception on Android
  /// `MediaSessionCompat` via `VolumeProviderCompat`.
  Future<bool> configureRemoteHardwareVolume({
    required bool enabled,
    required bool supportsVolume,
    required int volumeSteps,
    required int currentVolume,
  });

  /// Updates the current volume (`0..65535`) reported to Android's active
  /// `VolumeProviderCompat`.
  Future<bool> updateRemoteHardwareVolume({
    required int currentVolume,
  });

  /// Watches local volume changes and remote hardware volume button events.
  Stream<SystemVolumeEvent> watchEvents();
}
