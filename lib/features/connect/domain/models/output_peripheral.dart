// 1:1 replica of p199p/k7k.java (lines 4–83), p199p/n8d.java (lines 597–690),
// p199p/hkq.java (lines 350–455), p199p/udr0.java (lines 249–250), and
// com/spotify/connect/esperanto/proto/ConnectMessages$OutputPeripheral.java.

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Physical or logical audio output connection type for a peripheral.
///
/// Mirrors `OutputPeripheralConnectionType` (`es_connect_messages.pbenum.dart:115–163`).
/// When unset on the wire (`!hasConnectionType()`), [OutputPeripheral.connectionType]
/// is `null` rather than Java `k7k`'s `0` sentinel.
enum OutputPeripheralConnectionType {
  unknown, // proto 0, k7k code 1
  wired, // proto 1, k7k code 2
  carProjected, // proto 2, k7k code 3
  bluetooth, // proto 3, k7k code 4
  airplay, // proto 4, k7k code 5
  builtInSpeaker; // proto 5, k7k code 6

  /// Maps a proto `OutputPeripheralConnectionType` integer (0..5) to enum.
  static OutputPeripheralConnectionType fromProtoIndex(int value) {
    switch (value) {
      case 0:
        return OutputPeripheralConnectionType.unknown;
      case 1:
        return OutputPeripheralConnectionType.wired;
      case 2:
        return OutputPeripheralConnectionType.carProjected;
      case 3:
        return OutputPeripheralConnectionType.bluetooth;
      case 4:
        return OutputPeripheralConnectionType.airplay;
      case 5:
        return OutputPeripheralConnectionType.builtInSpeaker;
      default:
        throw RangeError.range(
          value,
          0,
          5,
          'value',
          'Invalid OutputPeripheralConnectionType proto index',
        );
    }
  }

  /// Maps `p199p/k7k.f123795d` (`0` = unset/`null`, `1..6` = enum values).
  static OutputPeripheralConnectionType? fromK7kCode(int code) {
    switch (code) {
      case 0:
        return null;
      case 1:
        return OutputPeripheralConnectionType.unknown;
      case 2:
        return OutputPeripheralConnectionType.wired;
      case 3:
        return OutputPeripheralConnectionType.carProjected;
      case 4:
        return OutputPeripheralConnectionType.bluetooth;
      case 5:
        return OutputPeripheralConnectionType.airplay;
      case 6:
        return OutputPeripheralConnectionType.builtInSpeaker;
      default:
        throw RangeError.range(
          code,
          0,
          6,
          'code',
          'Invalid k7k connectionType code',
        );
    }
  }
}

/// Output peripheral hardware category.
///
/// Mirrors `OutputPeripheralCategory` (`es_connect_messages.pbenum.dart:73–113`).
/// When unset on the wire (`!hasCategory()`), [OutputPeripheral.category] is
/// `null` rather than Java `k7k`'s `0` sentinel.
enum OutputPeripheralCategory {
  unknown, // proto 0, k7k code 1
  car, // proto 1, k7k code 2
  headphones, // proto 2, k7k code 3
  speaker, // proto 3, k7k code 4
  wearable, // proto 4, k7k code 5
  glasses, // proto 5, k7k code 6
  app; // proto 6, k7k code 7

  /// Maps a proto `OutputPeripheralCategory` integer (0..6) to enum.
  static OutputPeripheralCategory fromProtoIndex(int value) {
    switch (value) {
      case 0:
        return OutputPeripheralCategory.unknown;
      case 1:
        return OutputPeripheralCategory.car;
      case 2:
        return OutputPeripheralCategory.headphones;
      case 3:
        return OutputPeripheralCategory.speaker;
      case 4:
        return OutputPeripheralCategory.wearable;
      case 5:
        return OutputPeripheralCategory.glasses;
      case 6:
        return OutputPeripheralCategory.app;
      default:
        throw RangeError.range(
          value,
          0,
          6,
          'value',
          'Invalid OutputPeripheralCategory proto index',
        );
    }
  }

  /// Maps `p199p/k7k.f123796e` (`0` = unset/`null`, `1..7` = enum values).
  static OutputPeripheralCategory? fromK7kCode(int code) {
    switch (code) {
      case 0:
        return null;
      case 1:
        return OutputPeripheralCategory.unknown;
      case 2:
        return OutputPeripheralCategory.car;
      case 3:
        return OutputPeripheralCategory.headphones;
      case 4:
        return OutputPeripheralCategory.speaker;
      case 5:
        return OutputPeripheralCategory.wearable;
      case 6:
        return OutputPeripheralCategory.glasses;
      case 7:
        return OutputPeripheralCategory.app;
      default:
        throw RangeError.range(
          code,
          0,
          7,
          'code',
          'Invalid k7k category code',
        );
    }
  }
}

/// Connected audio output peripheral metadata matching `p199p/k7k.java`.
@immutable
final class OutputPeripheral extends Equatable {
  /// Peripheral display name (`k7k.f123792a`).
  final String? name;

  /// Peripheral manufacturer/brand (`k7k.f123793b`).
  final String? brand;

  /// Peripheral hardware model (`k7k.f123794c`).
  final String? model;

  /// Peripheral connection type (`k7k.f123795d`, `null` when unset).
  final OutputPeripheralConnectionType? connectionType;

  /// Peripheral category (`k7k.f123796e`, `null` when unset).
  final OutputPeripheralCategory? category;

  const OutputPeripheral({
    this.name,
    this.brand,
    this.model,
    this.connectionType,
    this.category,
  });

  bool get hasConnectionType => connectionType != null;

  bool get hasCategory => category != null;

  OutputPeripheral copyWith({
    String? name,
    bool clearName = false,
    String? brand,
    bool clearBrand = false,
    String? model,
    bool clearModel = false,
    OutputPeripheralConnectionType? connectionType,
    bool clearConnectionType = false,
    OutputPeripheralCategory? category,
    bool clearCategory = false,
  }) {
    return OutputPeripheral(
      name: clearName
          ? null
          : switch (name) {
              final value? => value,
              null => this.name,
            },
      brand: clearBrand
          ? null
          : switch (brand) {
              final value? => value,
              null => this.brand,
            },
      model: clearModel
          ? null
          : switch (model) {
              final value? => value,
              null => this.model,
            },
      connectionType: clearConnectionType
          ? null
          : switch (connectionType) {
              final value? => value,
              null => this.connectionType,
            },
      category: clearCategory
          ? null
          : switch (category) {
              final value? => value,
              null => this.category,
            },
    );
  }

  @override
  List<Object?> get props => [name, brand, model, connectionType, category];
}
