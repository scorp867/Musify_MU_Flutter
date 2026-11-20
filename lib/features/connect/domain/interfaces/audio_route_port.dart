import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';

export 'package:musify_mu/features/connect/application/mobius/connect_state.dart'
    show LocalAudioPeripheral, kBuiltInSpeakerPeripheralId;
export 'package:musify_mu/features/connect/domain/models/output_peripheral.dart'
    show
        OutputPeripheral,
        OutputPeripheralCategory,
        OutputPeripheralConnectionType;

/// Domain port for monitoring Android local audio output peripherals
/// (Bluetooth A2DP/BLE, wired headset/USB, built-in speaker) and launching
/// the Android system media output switcher dialog (`#47 §4.2`, `#47 §5`).
abstract class AudioRoutePort {
  /// Queries the current snapshot of connected local audio output peripherals.
  Future<List<LocalAudioPeripheral>> getPeripherals();

  /// Watches real-time changes to connected local audio output peripherals.
  Stream<List<LocalAudioPeripheral>> watchPeripherals();

  /// Launches the Android system media output switcher dialog (falling back to
  /// Bluetooth settings on OEM ROMs or API < 30).
  Future<bool> openSystemOutputSwitcher();
}
