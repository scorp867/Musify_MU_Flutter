// 1:1 replica of p199p/wcs.java (lines 277-309), p199p/y280.java (lines 74-82),
// p199p/tzs.java (lines 21-78), p199p/iq6.java (line 132),
// p199p/q9d.java (line 221), and p199p/oco.java (lines 16-17).

import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';

/// 1:1 4-stage Connect device sorting comparator matching `p199p/wcs.java`
/// (`m88644e` / `m88646g`), `p199p/tzs.java`, and `p199p/iq6.java`.
///
/// Precedence stages:
/// 1. Self device (`isSelf == true`) precedes all non-self devices
///    (`effectiveTimestamp == selfEffectiveTimestamp` (`0x7FFFFFFFFFFFFFFF`)).
/// 2. When neither device is self, local-network devices (`isLocal == true`)
///    precede non-local devices (`isLocal == false`).
/// 3. Effective last-connection timestamp descending (`tsB.compareTo(tsA)`),
///    where absent entries resolve to `unknownEffectiveTimestamp`
///    (`-0x8000000000000000`).
/// 4. Case-sensitive UTF-16 lexicographical `name` ascending (`a.name.compareTo(b.name)`).
@immutable
final class DeviceSortingComparator {
  /// Sentinel effective timestamp for self devices (`Long.MAX_VALUE`,
  /// `p199p/wcs.java:297`).
  static const int selfEffectiveTimestamp = 0x7FFFFFFFFFFFFFFF;

  /// Sentinel effective timestamp for remote devices with no stored history
  /// (`Long.MIN_VALUE`, `p199p/wcs.java:305`).
  static const int unknownEffectiveTimestamp = -0x8000000000000000;

  /// Unmodifiable map of SHA-256 hashed device identifiers to epoch-ms timestamps.
  final UnmodifiableMapView<String, int> lastConnectionTimestamps;

  /// Local device `connectStateIdentifier` prefix used to hash remote identifiers
  /// (`p199p/bzq.java:14-23`), or `''` when absent.
  final String localConnectStateIdentifier;

  DeviceSortingComparator({
    required Map<String, int> lastConnectionTimestamps,
    this.localConnectStateIdentifier = '',
  }) : lastConnectionTimestamps = UnmodifiableMapView<String, int>(
          Map<String, int>.of(lastConnectionTimestamps),
        );

  /// Computes the effective sorting timestamp for [device], matching
  /// `p199p/wcs.m88646g`.
  int effectiveTimestamp(ConnectDevice device) {
    if (device.isSelf) {
      return selfEffectiveTimestamp;
    }
    final hashedIdentifier = hashDeviceIdentifier(
      localConnectStateIdentifier: localConnectStateIdentifier,
      deviceIdentifier: device.connectStateIdentifier,
    );
    final timestamp = lastConnectionTimestamps[hashedIdentifier];
    if (timestamp != null) {
      return timestamp;
    }
    return unknownEffectiveTimestamp;
  }

  /// Compares [a] and [b] using Spotify's exact 4-stage `wcs.m88644e` order.
  int compare(ConnectDevice a, ConnectDevice b) {
    final tsA = effectiveTimestamp(a);
    final tsB = effectiveTimestamp(b);

    if (!a.isSelf && !b.isSelf && a.isLocal != b.isLocal) {
      return a.isLocal ? -1 : 1;
    }
    if (tsA == tsB) {
      return a.name.compareTo(b.name);
    }
    return tsB.compareTo(tsA);
  }

  /// Returns a new sorted [List<ConnectDevice>] without mutating [devices].
  List<ConnectDevice> sortDevices(Iterable<ConnectDevice> devices) {
    final copy = List<ConnectDevice>.of(devices);
    copy.sort(compare);
    return copy;
  }
}

/// Factory creating [DeviceSortingComparator] instances from timestamp snapshots,
/// matching `p199p/oco.java:16-17`.
@immutable
final class DeviceSortingComparatorFactory {
  const DeviceSortingComparatorFactory();

  /// Creates a [DeviceSortingComparator] with an explicit
  /// [localConnectStateIdentifier].
  DeviceSortingComparator create({
    required Map<String, int> lastConnectionTimestamps,
    String localConnectStateIdentifier = '',
  }) {
    return DeviceSortingComparator(
      lastConnectionTimestamps: lastConnectionTimestamps,
      localConnectStateIdentifier: localConnectStateIdentifier,
    );
  }

  /// Creates a [DeviceSortingComparator] resolving `localConnectStateIdentifier`
  /// from the first `isSelf == true` device in [devices] (or `''` if absent,
  /// matching `p199p/bbr.java` + `p199p/bzq.java:14-23`).
  DeviceSortingComparator createForDevices({
    required Map<String, int> lastConnectionTimestamps,
    required Iterable<ConnectDevice> devices,
  }) {
    var localId = '';
    for (final device in devices) {
      if (device.isSelf) {
        localId = device.connectStateIdentifier;
        break;
      }
    }
    return DeviceSortingComparator(
      lastConnectionTimestamps: lastConnectionTimestamps,
      localConnectStateIdentifier: localId,
    );
  }
}
