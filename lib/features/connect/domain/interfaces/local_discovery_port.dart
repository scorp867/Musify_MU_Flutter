import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Immutable descriptor of a local LAN `_spotify-connect._tcp.` service
/// discovered via Android `NsdManager` (`#47 §2.7`, `#47 §4.4`).
@immutable
final class DiscoveredNsdService extends Equatable {
  final String serviceName;
  final String host;
  final int port;
  final String cPath;
  final String version;
  final String stack;

  DiscoveredNsdService({
    required this.serviceName,
    required this.host,
    required this.port,
    required this.cPath,
    required this.version,
    required this.stack,
  }) {
    if (serviceName.trim().isEmpty) {
      throw ArgumentError.value(
        serviceName,
        'serviceName',
        'Must be non-empty',
      );
    }
    if (host.trim().isEmpty) {
      throw ArgumentError.value(host, 'host', 'Must be non-empty');
    }
    if (port <= 0 || port > 65535) {
      throw RangeError.range(
        port,
        1,
        65535,
        'port',
        'Must be within [1, 65535]',
      );
    }
    if (cPath.trim().isEmpty) {
      throw ArgumentError.value(cPath, 'cPath', 'Must be non-empty');
    }
  }

  /// Serializes this NSD service entry to the exact JSON map schema consumed
  /// by native `musify_connect_update_nsd_services` (`#47 §2.7`).
  Map<String, Object> toJson() {
    return <String, Object>{
      'serviceName': serviceName,
      'host': host,
      'port': port,
      'cPath': cPath,
      'version': version,
      'stack': stack,
    };
  }

  /// Serializes a list of [DiscoveredNsdService] items into the UTF-8 JSON
  /// array string expected by `musify_connect_update_nsd_services`.
  static String encodeListToJson(List<DiscoveredNsdService> services) {
    final payload = services
        .map((service) => service.toJson())
        .toList(growable: false);
    return jsonEncode(payload);
  }

  @override
  List<Object?> get props => [
        serviceName,
        host,
        port,
        cPath,
        version,
        stack,
      ];
}

/// Domain port for starting, stopping, and watching Android `NsdManager`
/// `_spotify-connect._tcp.` mDNS/Zeroconf discovery (`#47 §4.4`, `#47 §5`).
abstract class LocalDiscoveryPort {
  /// Acquires `WifiManager.MulticastLock` and starts `_spotify-connect._tcp.`
  /// NSD discovery.
  Future<void> startDiscovery();

  /// Stops active NSD discovery and releases the ref-counted `MulticastLock`.
  Future<void> stopDiscovery();

  /// Returns the current snapshot of discovered `_spotify-connect._tcp.`
  /// services.
  Future<List<DiscoveredNsdService>> getDiscoveredServices();

  /// Watches real-time snapshots of discovered `_spotify-connect._tcp.`
  /// services.
  Stream<List<DiscoveredNsdService>> watchDiscoveredServices();
}
