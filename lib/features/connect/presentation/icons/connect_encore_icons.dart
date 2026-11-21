// Exact 1:1 Spotify 9.1.92.3058 Encore vector paths (16dp & 24dp) with
// zero-dependency CustomPainter SVG path parsing and PathFillType fidelity.
//
// Extracted directly from:
// - `res/drawable/encore_icon_*.xml`
// - `p199p/hnw.java`, `gnw.java`, `iuw.java`, `lmw.java`, `plw.java`,
//   `ovw.java`, `tqw.java`, `juw.java`, `byl1.java` (`m32480o` / `m32482q`)

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';

/// Single SVG sub-path specification inside an [EncoreVectorIconData].
@immutable
final class EncoreVectorPath {
  const EncoreVectorPath({
    required this.pathData,
    this.fillType = PathFillType.nonZero,
  });

  final String pathData;
  final PathFillType fillType;
}

/// Immutable Encore vector icon descriptor with exact viewport dimensions.
@immutable
final class EncoreVectorIconData {
  const EncoreVectorIconData({
    required this.id,
    required this.viewportSize,
    required this.paths,
  });

  final String id;
  final double viewportSize;
  final List<EncoreVectorPath> paths;
}

/// Semantic icon family that selects the optically tuned 16dp or 24dp Encore
/// vector asset automatically based on rendered [size] (matching Spotify's
/// `qtw(vector16, vector24)` optical size switching).
@immutable
final class EncoreIconPair {
  const EncoreIconPair({
    required this.small16,
    required this.medium24,
  });

  final EncoreVectorIconData small16;
  final EncoreVectorIconData medium24;

  EncoreVectorIconData resolveForSize(double size) {
    return size <= 18.0 ? small16 : medium24;
  }
}

/// All exact Spotify 9.1.92.3058 Encore icons used by Connect & MiniPlayer.
abstract final class ConnectEncoreIcons {
  /// `encore_icon_devices_16.xml`
  static const EncoreVectorIconData devices16 = EncoreVectorIconData(
    id: 'devices16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M6,2.75C6,1.784 6.784,1 7.75,1h6.5c0.966,0 1.75,0.784 1.75,1.75v10.5A1.75,1.75 0,0 1,14.25 15h-6.5A1.75,1.75 0,0 1,6 13.25zM7.75,2.5a0.25,0.25 0,0 0,-0.25 0.25v10.5c0,0.138 0.112,0.25 0.25,0.25h6.5a0.25,0.25 0,0 0,0.25 -0.25L14.5,2.75a0.25,0.25 0,0 0,-0.25 -0.25zM1.75,2.5a0.25,0.25 0,0 0,-0.25 0.25v6.5c0,0.138 0.112,0.25 0.25,0.25L4,9.5L4,11L1.75,11A1.75,1.75 0,0 1,0 9.25v-6.5C0,1.784 0.784,1 1.75,1L4,1v1.5zM4,15L2,15v-1.5h2z',
      ),
      EncoreVectorPath(
        pathData: 'M13,10a2,2 0,1 1,-4 0,2 2,0 0,1 4,0m-1,-5a1,1 0,1 1,-2 0,1 1,0 0,1 2,0',
      ),
    ],
  );

  /// `encore_icon_devices_24.xml`
  static const EncoreVectorIconData devices24 = EncoreVectorIconData(
    id: 'devices24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M10,19a3,3 0,0 0,3 3h8a3,3 0,0 0,3 -3L24,5a3,3 0,0 0,-3 -3h-8a3,3 0,0 0,-3 3zM13,20a1,1 0,0 1,-1 -1L12,5a1,1 0,0 1,1 -1h8a1,1 0,0 1,1 1v14a1,1 0,0 1,-1 1z',
      ),
      EncoreVectorPath(
        pathData: 'M18.25,7.25a1.25,1.25 0,1 0,-2.5 0,1.25 1.25,0 0,0 2.5,0M17,16a1.5,1.5 0,1 1,0 -3,1.5 1.5,0 0,1 0,3m-3.5,-1.5a3.5,3.5 0,1 0,7 0,3.5 3.5,0 0,0 -7,0M0,4a2,2 0,0 1,2 -2h5v2L2,4v11h5v2L2,17a2,2 0,0 1,-2 -2zM7,22L4,22v-2h3z',
      ),
    ],
  );

  /// `encore_icon_device_mobile_16.xml (xnw)`
  static const EncoreVectorIconData deviceMobile16 = EncoreVectorIconData(
    id: 'deviceMobile16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M8,13a1,1 0,1 0,0 -2,1 1,0 0,0 0,2',
      ),
      EncoreVectorPath(
        pathData: 'M4.75,0A1.75,1.75 0,0 0,3 1.75v12.5c0,0.966 0.784,1.75 1.75,1.75h6.5A1.75,1.75 0,0 0,13 14.25V1.75A1.75,1.75 0,0 0,11.25 0zM4.5,1.75a0.25,0.25 0,0 1,0.25 -0.25h6.5a0.25,0.25 0,0 1,0.25 0.25v12.5a0.25,0.25 0,0 1,-0.25 0.25h-6.5a0.25,0.25 0,0 1,-0.25 -0.25z',
      ),
    ],
  );

  /// `encore_icon_device_mobile_24.xml`
  static const EncoreVectorIconData deviceMobile24 = EncoreVectorIconData(
    id: 'deviceMobile24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M5,5a3,3 0,0 1,3 -3h8a3,3 0,0 1,3 3v14a3,3 0,0 1,-3 3L8,22a3,3 0,0 1,-3 -3zM8,4a1,1 0,0 0,-1 1v14a1,1 0,0 0,1 1h8a1,1 0,0 0,1 -1L17,5a1,1 0,0 0,-1 -1z',
      ),
      EncoreVectorPath(
        pathData: 'M13.25,16.75a1.25,1.25 0,1 1,-2.5 0,1.25 1.25,0 0,1 2.5,0',
      ),
    ],
  );

  /// `encore_icon_device_computer_16.xml (wnw)`
  static const EncoreVectorIconData deviceComputer16 = EncoreVectorIconData(
    id: 'deviceComputer16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M2,3.75C2,2.784 2.784,2 3.75,2h8.5c0.966,0 1.75,0.784 1.75,1.75v6.5A1.75,1.75 0,0 1,12.25 12h-8.5A1.75,1.75 0,0 1,2 10.25zM3.75,3.5a0.25,0.25 0,0 0,-0.25 0.25v6.5c0,0.138 0.112,0.25 0.25,0.25h8.5a0.25,0.25 0,0 0,0.25 -0.25v-6.5a0.25,0.25 0,0 0,-0.25 -0.25zM0.25,15.25A0.75,0.75 0,0 1,1 14.5h14a0.75,0.75 0,0 1,0 1.5L1,16a0.75,0.75 0,0 1,-0.75 -0.75',
      ),
    ],
  );

  /// `encore_icon_device_computer_24.xml`
  static const EncoreVectorIconData deviceComputer24 = EncoreVectorIconData(
    id: 'deviceComputer24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M0,21a1,1 0,0 1,1 -1h22a1,1 0,1 1,0 2L1,22a1,1 0,0 1,-1 -1M3,5a3,3 0,0 1,3 -3h12a3,3 0,0 1,3 3v9a3,3 0,0 1,-3 3L6,17a3,3 0,0 1,-3 -3zM6,4a1,1 0,0 0,-1 1v9a1,1 0,0 0,1 1h12a1,1 0,0 0,1 -1L19,5a1,1 0,0 0,-1 -1z',
      ),
    ],
  );

  /// `encore_icon_device_tablet_16.xml (cow)`
  static const EncoreVectorIconData deviceTablet16 = EncoreVectorIconData(
    id: 'deviceTablet16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M1,1.75C1,0.784 1.784,0 2.75,0h10.5C14.216,0 15,0.784 15,1.75v12.5A1.75,1.75 0,0 1,13.25 16L2.75,16A1.75,1.75 0,0 1,1 14.25zM2.75,1.5a0.25,0.25 0,0 0,-0.25 0.25v12.5c0,0.138 0.112,0.25 0.25,0.25h10.5a0.25,0.25 0,0 0,0.25 -0.25L13.5,1.75a0.25,0.25 0,0 0,-0.25 -0.25z',
      ),
      EncoreVectorPath(
        pathData: 'M9,12a1,1 0,1 1,-2 0,1 1,0 0,1 2,0',
      ),
    ],
  );

  /// `encore_icon_device_tablet_24.xml`
  static const EncoreVectorIconData deviceTablet24 = EncoreVectorIconData(
    id: 'deviceTablet24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M3,5a3,3 0,0 1,3 -3h12a3,3 0,0 1,3 3v14a3,3 0,0 1,-3 3L6,22a3,3 0,0 1,-3 -3zM6,4a1,1 0,0 0,-1 1v14a1,1 0,0 0,1 1h12a1,1 0,0 0,1 -1L19,5a1,1 0,0 0,-1 -1z',
      ),
      EncoreVectorPath(
        pathData: 'M13.25,16.75a1.25,1.25 0,1 1,-2.5 0,1.25 1.25,0 0,1 2.5,0',
      ),
    ],
  );

  /// `encore_icon_device_speaker_16.xml (bow)`
  static const EncoreVectorIconData deviceSpeaker16 = EncoreVectorIconData(
    id: 'deviceSpeaker16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M8,6.438c0.552,0 1,-0.434 1,-0.969S8.552,4.5 8,4.5s-1,0.434 -1,0.969 0.448,0.969 1,0.969m0,6.312a2.25,2.25 0,1 0,0 -4.5,2.25 2.25,0 0,0 0,4.5',
      ),
      EncoreVectorPath(
        pathData: 'M2.002,2.75c0,-0.966 0.784,-1.75 1.75,-1.75h8.5c0.966,0 1.75,0.784 1.75,1.75v11.5a1.75,1.75 0,0 1,-1.75 1.75h-8.5a1.75,1.75 0,0 1,-1.75 -1.75zM3.752,2.5a0.25,0.25 0,0 0,-0.25 0.25v11.5c0,0.138 0.112,0.25 0.25,0.25h8.5a0.25,0.25 0,0 0,0.25 -0.25L12.502,2.75a0.25,0.25 0,0 0,-0.25 -0.25z',
      ),
    ],
  );

  /// `encore_icon_device_speaker_24.xml`
  static const EncoreVectorIconData deviceSpeaker24 = EncoreVectorIconData(
    id: 'deviceSpeaker24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M5,19a3,3 0,0 0,3 3h8a3,3 0,0 0,3 -3L19,5a3,3 0,0 0,-3 -3L8,2a3,3 0,0 0,-3 3zM8,20a1,1 0,0 1,-1 -1L7,5a1,1 0,0 1,1 -1h8a1,1 0,0 1,1 1v14a1,1 0,0 1,-1 1z',
      ),
      EncoreVectorPath(
        pathData: 'M13.25,7.25a1.25,1.25 0,1 0,-2.5 0,1.25 1.25,0 0,0 2.5,0M12,16a1.5,1.5 0,1 1,0 -3,1.5 1.5,0 0,1 0,3m-3.5,-1.5a3.5,3.5 0,1 0,7 0,3.5 3.5,0 0,0 -7,0',
      ),
    ],
  );

  /// `encore_icon_device_tv_16.xml (dow)`
  static const EncoreVectorIconData deviceTv16 = EncoreVectorIconData(
    id: 'deviceTv16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M0,2.75C0,1.784 0.784,1 1.75,1h12.5c0.966,0 1.75,0.784 1.75,1.75v7.5A1.75,1.75 0,0 1,14.25 12L1.75,12A1.75,1.75 0,0 1,0 10.25zM1.75,2.5a0.25,0.25 0,0 0,-0.25 0.25v7.5c0,0.138 0.112,0.25 0.25,0.25h12.5a0.25,0.25 0,0 0,0.25 -0.25v-7.5a0.25,0.25 0,0 0,-0.25 -0.25zM4.25,15.25A0.75,0.75 0,0 1,5 14.5h6a0.75,0.75 0,0 1,0 1.5L5,16a0.75,0.75 0,0 1,-0.75 -0.75',
      ),
    ],
  );

  /// `encore_icon_device_tv_24.xml`
  static const EncoreVectorIconData deviceTv24 = EncoreVectorIconData(
    id: 'deviceTv24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M4,2a3,3 0,0 0,-3 3v9a3,3 0,0 0,3 3h16a3,3 0,0 0,3 -3L23,5a3,3 0,0 0,-3 -3zM3,5a1,1 0,0 1,1 -1h16a1,1 0,0 1,1 1v9a1,1 0,0 1,-1 1L4,15a1,1 0,0 1,-1 -1zM7,21a1,1 0,0 1,1 -1h8a1,1 0,1 1,0 2L8,22a1,1 0,0 1,-1 -1',
      ),
    ],
  );

  /// `encore_icon_device_arm_16.xml (unw)`
  static const EncoreVectorIconData deviceArm16 = EncoreVectorIconData(
    id: 'deviceArm16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M11.5,9.5a1.5,1.5 0,1 0,0 -3,1.5 1.5,0 0,0 0,3',
      ),
      EncoreVectorPath(
        pathData: 'M1.75,3A1.75,1.75 0,0 0,0 4.75v6.5C0,12.216 0.784,13 1.75,13H2v1.25a0.75,0.75 0,0 0,1.5 0V13h9v1.25a0.75,0.75 0,0 0,1.5 0V13h0.25A1.75,1.75 0,0 0,16 11.25v-6.5A1.75,1.75 0,0 0,14.25 3zM1.5,4.75a0.25,0.25 0,0 1,0.25 -0.25h12.5a0.25,0.25 0,0 1,0.25 0.25v6.5a0.25,0.25 0,0 1,-0.25 0.25H1.75a0.25,0.25 0,0 1,-0.25 -0.25z',
      ),
    ],
  );

  /// `encore_icon_device_arm_24.xml`
  static const EncoreVectorIconData deviceArm24 = EncoreVectorIconData(
    id: 'deviceArm24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M16.5,7a3.5,3.5 0,1 0,0 7,3.5 3.5,0 0,0 0,-7M15,10.5a1.5,1.5 0,1 1,3 0,1.5 1.5,0 0,1 -3,0',
      ),
      EncoreVectorPath(
        pathData: 'M3,3a3,3 0,0 0,-3 3v9a3,3 0,0 0,3 3v2a1,1 0,1 0,2 0v-2h14v2a1,1 0,1 0,2 0v-2a3,3 0,0 0,3 -3L24,6a3,3 0,0 0,-3 -3zM21,16L3,16a1,1 0,0 1,-1 -1L2,6a1,1 0,0 1,1 -1h18a1,1 0,0 1,1 1v9a1,1 0,0 1,-1 1',
      ),
    ],
  );

  /// `encore_icon_device_car_16.xml (vnw)`
  static const EncoreVectorIconData deviceCar16 = EncoreVectorIconData(
    id: 'deviceCar16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M2.92,2.375A2.75,2.75 0,0 1,5.303 1h5.395c0.983,0 1.89,0.524 2.382,1.375L14.017,4h1.233a0.75,0.75 0,0 1,0 1.5h-0.237c0.989,0.9 0.988,2.117 0.987,2.707v7.043a0.75,0.75 0,0 1,-0.75 0.75h-1.5a0.75,0.75 0,0 1,-0.75 -0.75L13,14L3,14v1.25a0.75,0.75 0,0 1,-0.75 0.75L0.75,16a0.75,0.75 0,0 1,-0.75 -0.75L0,8.207C0,7.617 -0.002,6.4 0.987,5.5L0.75,5.5a0.75,0.75 0,0 1,0 -1.5h1.233l0.938,-1.625zM5.302,2.5c-0.446,0 -0.859,0.238 -1.082,0.625L3.137,5h9.726L11.78,3.125a1.25,1.25 0,0 0,-1.083 -0.625zM13.872,6.5L2.128,6.5l-0.055,0.046c-0.473,0.377 -0.556,0.894 -0.57,1.454h2.429a1,1 0,0 1,1 1v0.5L1.5,9.5v3h13v-3h-3.43L11.07,9a1,1 0,0 1,1 -1h2.427c-0.013,-0.56 -0.096,-1.077 -0.569,-1.454l-0.055,-0.046z',
      ),
    ],
  );

  /// `encore_icon_device_car_24.xml`
  static const EncoreVectorIconData deviceCar24 = EncoreVectorIconData(
    id: 'deviceCar24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M12,19c2.036,0 4.039,-0.142 6,-0.415L18,20.5a1.5,1.5 0,0 0,1.5 1.5h3a1.5,1.5 0,0 0,1.5 -1.5L24,10.45c0,-1.49 -0.83,-2.785 -2.05,-3.45L23,7a1,1 0,1 0,0 -2h-2.405l-0.866,-1.5A5,5 0,0 0,15.4 1L8.601,1a5,5 0,0 0,-4.33 2.5L3.405,5L1,5a1,1 0,0 0,0 2h1.05A3.93,3.93 0,0 0,0 10.45L0,20.5A1.5,1.5 0,0 0,1.5 22h3A1.5,1.5 0,0 0,6 20.5v-1.915c1.961,0.273 3.964,0.415 6,0.415M6.003,4.5A3,3 0,0 1,8.6 3h6.798a3,3 0,0 1,2.598 1.5l1.346,2.331A40,40 0,0 1,12 7.504c-2.51,0 -4.963,-0.231 -7.343,-0.673zM12,9.504a42,42 0,0 0,8.652 -0.893l0.018,0.006a1.93,1.93 0,0 1,1.317 1.605c-0.045,0.049 -0.12,0.115 -0.241,0.196 -0.249,0.163 -0.604,0.324 -1.048,0.47 -0.885,0.293 -1.955,0.474 -2.797,0.558a1,1 0,1 0,0.198 1.99c0.93,-0.092 2.155,-0.294 3.226,-0.648q0.342,-0.113 0.675,-0.254v3.238A41.3,41.3 0,0 1,12 17a41.3,41.3 0,0 1,-10 -1.228v-3.238q0.333,0.142 0.675,0.254c1.07,0.354 2.297,0.556 3.226,0.649a1,1 0,0 0,0.198 -1.99c-0.842,-0.085 -1.912,-0.266 -2.797,-0.558 -0.443,-0.147 -0.8,-0.308 -1.048,-0.471a1.3,1.3 0,0 1,-0.24 -0.195A1.93,1.93 0,0 1,3.33 8.617l0.018,-0.006A42,42 0,0 0,12 9.504m8,8.753a44,44 0,0 0,2 -0.426L22,20h-2zM2,17.831q0.991,0.236 2,0.426L4,20L2,20v-2.17z',
      ),
    ],
  );

  /// `encore_icon_device_other_16.xml (znw)`
  static const EncoreVectorIconData deviceOther16 = EncoreVectorIconData(
    id: 'deviceOther16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M6,2.75C6,1.784 6.784,1 7.75,1h6.5c0.966,0 1.75,0.784 1.75,1.75v10.5A1.75,1.75 0,0 1,14.25 15h-6.5A1.75,1.75 0,0 1,6 13.25zM7.75,2.5a0.25,0.25 0,0 0,-0.25 0.25v10.5c0,0.138 0.112,0.25 0.25,0.25h6.5a0.25,0.25 0,0 0,0.25 -0.25L14.5,2.75a0.25,0.25 0,0 0,-0.25 -0.25zM1.75,2.5a0.25,0.25 0,0 0,-0.25 0.25v6.5c0,0.138 0.112,0.25 0.25,0.25L4,9.5L4,11L1.75,11A1.75,1.75 0,0 1,0 9.25v-6.5C0,1.784 0.784,1 1.75,1L4,1v1.5zM4,15L2,15v-1.5h2z',
      ),
      EncoreVectorPath(
        pathData: 'M13,10a2,2 0,1 1,-4 0,2 2,0 0,1 4,0m-1,-5a1,1 0,1 1,-2 0,1 1,0 0,1 2,0',
      ),
    ],
  );

  /// `encore_icon_device_other_24.xml`
  static const EncoreVectorIconData deviceOther24 = EncoreVectorIconData(
    id: 'deviceOther24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M10,19a3,3 0,0 0,3 3h8a3,3 0,0 0,3 -3L24,5a3,3 0,0 0,-3 -3h-8a3,3 0,0 0,-3 3zM13,20a1,1 0,0 1,-1 -1L12,5a1,1 0,0 1,1 -1h8a1,1 0,0 1,1 1v14a1,1 0,0 1,-1 1z',
      ),
      EncoreVectorPath(
        pathData: 'M18.25,7.25a1.25,1.25 0,1 0,-2.5 0,1.25 1.25,0 0,0 2.5,0M17,16a1.5,1.5 0,1 1,0 -3,1.5 1.5,0 0,1 0,3m-3.5,-1.5a3.5,3.5 0,1 0,7 0,3.5 3.5,0 0,0 -7,0M0,4a2,2 0,0 1,2 -2h5v2L2,4v11h5v2L2,17a2,2 0,0 1,-2 -2zM7,22L4,22v-2h3z',
      ),
    ],
  );

  /// `encore_icon_device_multispeaker_16.xml (ynw)`
  static const EncoreVectorIconData deviceMultispeaker16 = EncoreVectorIconData(
    id: 'deviceMultispeaker16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M11,12.75a2,2 0,1 0,0 -4,2 2,0 0,0 0,4',
      ),
      EncoreVectorPath(
        pathData: 'M6,2.75C6,1.784 6.783,1 7.75,1h6.5c0.966,0 1.75,0.784 1.75,1.75v11.5A1.75,1.75 0,0 1,14.25 16h-6.5A1.75,1.75 0,0 1,6 14.25zM7.75,2.5a0.25,0.25 0,0 0,-0.25 0.25v11.5c0,0.138 0.112,0.25 0.25,0.25h6.5a0.25,0.25 0,0 0,0.25 -0.25L14.5,2.75a0.25,0.25 0,0 0,-0.25 -0.25zM1.75,2.5a0.25,0.25 0,0 0,-0.25 0.25v11.5c0,0.138 0.112,0.25 0.25,0.25h2.375L4.125,16L1.75,16A1.75,1.75 0,0 1,0 14.25L0,2.75C0,1.784 0.784,1 1.75,1h2.375v1.5z',
      ),
      EncoreVectorPath(
        pathData: 'M12,5.5a1,1 0,1 1,-2 0,1 1,0 0,1 2,0',
      ),
    ],
  );

  /// `encore_icon_device_multispeaker_24.xml`
  static const EncoreVectorIconData deviceMultispeaker24 = EncoreVectorIconData(
    id: 'deviceMultispeaker24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M10,19a3,3 0,0 0,3 3h8a3,3 0,0 0,3 -3L24,5a3,3 0,0 0,-3 -3h-8a3,3 0,0 0,-3 3zM13,20a1,1 0,0 1,-1 -1L12,5a1,1 0,0 1,1 -1h8a1,1 0,0 1,1 1v14a1,1 0,0 1,-1 1z',
      ),
      EncoreVectorPath(
        pathData: 'M18.25,7.25a1.25,1.25 0,1 0,-2.5 0,1.25 1.25,0 0,0 2.5,0M17,16a1.5,1.5 0,1 1,0 -3,1.5 1.5,0 0,1 0,3m-3.5,-1.5a3.5,3.5 0,1 0,7 0,3.5 3.5,0 0,0 -7,0M0,5a3,3 0,0 1,3 -3h4v2H3a1,1 0,0 0,-1 1v14a1,1 0,0 0,1 1h4v2H3a3,3 0,0 1,-3 -3z',
      ),
      EncoreVectorPath(
        pathData: 'M5.75,7.25C5.75,6.56 6.31,6 7,6v2.5c-0.69,0 -1.25,-0.56 -1.25,-1.25M7,16a1.5,1.5 0,0 1,0 -3v-2a3.5,3.5 0,1 0,0 7z',
      ),
    ],
  );

  /// `encore_icon_device_smart_glasses_16.xml (aow)`
  static const EncoreVectorIconData deviceSmartGlasses16 = EncoreVectorIconData(
    id: 'deviceSmartGlasses16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'm7.136,9.007 l0.042,-0.13 0.063,-0.208a55,55 0,0 0,0.37 -1.336h0.78a55,55 0,0 0,0.434 1.544,5 5,0 0,0 0.115,0.323c0.065,0.153 0.166,0.363 0.314,0.578 0.285,0.416 0.834,0.972 1.707,0.972a108,108 0,0 0,1.536 -0.016l0.207,-0.003 0.1,-0.004a2.2,2.2 0,0 0,0.907 -0.263,1.9 1.9,0 0,0 0.73,-0.701c0.201,-0.338 0.31,-0.75 0.31,-1.23L14.751,7.328c0.328,-0.047 0.582,-0.362 0.582,-0.745 0,-0.414 -0.298,-0.75 -0.667,-0.75h-0.088a1,1 0,0 0,-0.15 -0.209c-0.246,-0.265 -0.56,-0.329 -0.754,-0.352a6,6 0,0 0,-0.625 -0.022h-3.014a6,6 0,0 0,-0.723 0.03c-0.22,0.03 -0.596,0.112 -0.848,0.458a1,1 0,0 0,-0.062 0.095L7.6,5.833a1,1 0,0 0,-0.062 -0.095c-0.252,-0.346 -0.628,-0.429 -0.848,-0.459a6,6 0,0 0,-0.723 -0.029L2.953,5.25c-0.216,0 -0.44,0 -0.625,0.022 -0.194,0.023 -0.508,0.087 -0.754,0.352q-0.09,0.101 -0.15,0.21h-0.09c-0.369,0 -0.667,0.335 -0.667,0.75 0,0.383 0.255,0.699 0.585,0.744v1.205c0,0.48 0.108,0.892 0.31,1.23 0.2,0.337 0.47,0.559 0.73,0.701a2.2,2.2 0,0 0,1.007 0.267l0.206,0.003 1.536,0.016c0.873,0 1.422,-0.556 1.708,-0.972a3.3,3.3 0,0 0,0.387 -0.771M5.93,6.75l0.277,0.001a9,9 0,0 1,-0.123 0.485v0.001a54,54 0,0 1,-0.35 1.226l-0.018,0.056a1.8,1.8 0,0 1,-0.205 0.41c-0.158,0.23 -0.31,0.321 -0.47,0.321a106,106 0,0 1,-1.516 -0.016l-0.211,-0.003c-0.014,-0.001 -0.056,-0.004 -0.087,-0.01a0.7,0.7 0,0 1,-0.214 -0.072,0.4 0.4,0 0,1 -0.165,-0.155c-0.042,-0.071 -0.097,-0.208 -0.097,-0.46L2.751,7.065l0.001,-0.315 0.234,-0.001L5.93,6.749ZM9.794,6.751 L10.07,6.75h3.178l0.001,0.316v1.467c0,0.253 -0.055,0.39 -0.097,0.46a0.4,0.4 0,0 1,-0.165 0.156,0.7 0.7,0 0,1 -0.214,0.073c-0.03,0.005 -0.072,0.008 -0.086,0.009l-0.212,0.003 -1.515,0.016c-0.16,0 -0.313,-0.09 -0.47,-0.32a1.8,1.8 0,0 1,-0.224 -0.467c-0.01,-0.034 -0.04,-0.127 -0.067,-0.219a53,53 0,0 1,-0.283 -1.007v-0.001a9,9 0,0 1,-0.122 -0.485',
      ),
    ],
  );

  /// `encore_icon_device_smart_glasses_24.xml`
  static const EncoreVectorIconData deviceSmartGlasses24 = EncoreVectorIconData(
    id: 'deviceSmartGlasses24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M8.944,8L4.43,8c-0.328,0 -0.657,0 -0.926,0.032 -0.282,0.034 -0.717,0.124 -1.054,0.49 -0.14,0.15 -0.232,0.316 -0.294,0.478L2,9a1,1 0,0 0,0 2v1.8c0,0.702 0.157,1.295 0.446,1.78a2.75,2.75 0,0 0,1.05 1.007,3.2 3.2,0 0,0 1.447,0.384h0.003l0.31,0.004 0.748,0.01c0.57,0.008 1.229,0.015 1.555,0.015 1.25,0 2.04,-0.794 2.458,-1.404a4.8,4.8 0,0 0,0.594 -1.214l0.006,-0.019 0.003,-0.011 0.024,-0.074 0.094,-0.31A82,82 0,0 0,11.285 11h1.43q0.052,0.201 0.11,0.416a83,83 0,0 0,0.531 1.862l0.023,0.074 0.004,0.011 0.006,0.019 0.029,0.088a4.8,4.8 0,0 0,0.566 1.127C14.4,15.205 15.19,16 16.44,16c0.326,0 0.985,-0.007 1.555,-0.015l0.748,-0.01 0.31,-0.004h0.003a2,2 0,0 0,0.14 -0.005,3.2 3.2,0 0,0 1.308,-0.379 2.75,2.75 0,0 0,1.049 -1.007c0.289,-0.485 0.446,-1.078 0.446,-1.78L21.999,11a1,1 0,1 0,0 -2h-0.156a1.5,1.5 0,0 0,-0.294 -0.479c-0.338,-0.365 -0.772,-0.455 -1.054,-0.489A8,8 0,0 0,19.57 8h-4.514c-0.37,0 -0.756,0 -1.072,0.043 -0.32,0.043 -0.84,0.162 -1.187,0.637a1.5,1.5 0,0 0,-0.176 0.32h-1.242a1.5,1.5 0,0 0,-0.176 -0.32c-0.347,-0.475 -0.867,-0.594 -1.187,-0.637C9.7,8 9.314,8 8.944,8m-0.242,4.785 l-0.011,0.035a2.8,2.8 0,0 1,-0.323 0.645c-0.248,0.36 -0.51,0.535 -0.81,0.535a159,159 0,0 1,-2.274 -0.024l-0.317,-0.005h-0.013l-0.02,-0.001a1.2,1.2 0,0 1,-0.477 -0.136,0.75 0.75,0 0,1 -0.293,-0.28C4.087,13.427 4,13.199 4,12.8v-2.2c0,-0.26 0,-0.451 0.005,-0.597 0.118,-0.002 0.27,-0.003 0.473,-0.003h4.415c0.241,0 0.424,0 0.567,0.005 -0.039,0.209 -0.108,0.494 -0.215,0.883a81,81 0,0 1,-0.51 1.793l-0.017,0.053 -0.002,0.008v-0.002zM15.339,12.876s-0.118,-0.336 -0.159,-0.474a82,82 0,0 1,-0.425 -1.514c-0.107,-0.39 -0.176,-0.674 -0.215,-0.883 0.143,-0.004 0.326,-0.005 0.567,-0.005h4.415c0.202,0 0.355,0 0.473,0.003 0.005,0.146 0.005,0.336 0.005,0.596v2.2c0,0.399 -0.087,0.627 -0.164,0.756a0.75,0.75 0,0 1,-0.293 0.279,1.1 1.1,0 0,1 -0.492,0.142h-0.335l-0.746,0.01c-0.574,0.007 -1.218,0.014 -1.529,0.014 -0.3,0 -0.561,-0.175 -0.808,-0.535a4,4 0,0 1,-0.294 -0.589',
      ),
    ],
  );

  /// `encore_icon_games_console_16.xml (zow)`
  static const EncoreVectorIconData gamesConsole16 = EncoreVectorIconData(
    id: 'gamesConsole16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M4.423,2.5a1.25,1.25 0,0 0,-1.224 0.995l-1.652,7.923a1.313,1.313 0,0 0,2.423 0.925l1.57,-2.718A1.25,1.25 0,0 1,6.622 9h2.756c0.447,0 0.86,0.238 1.083,0.625l1.57,2.718a1.313,1.313 0,0 0,2.422 -0.924l-1.652,-7.924a1.25,1.25 0,0 0,-1.224 -0.995zM1.731,3.189A2.75,2.75 0,0 1,4.423 1h7.154a2.75,2.75 0,0 1,2.692 2.189l1.653,7.923a2.813,2.813 0,0 1,-5.19 1.981L9.233,10.5L6.766,10.5L5.27,13.093a2.813,2.813 0,0 1,-5.19 -1.98l1.65,-7.925z',
      ),
      EncoreVectorPath(
        pathData: 'M7,5.5a1.25,1.25 0,1 1,-2.5 0,1.25 1.25,0 0,1 2.5,0m2,0a1.25,1.25 0,1 0,2.5 0,1.25 1.25,0 0,0 -2.5,0',
      ),
    ],
  );

  /// `encore_icon_games_console_24.xml`
  static const EncoreVectorIconData gamesConsole24 = EncoreVectorIconData(
    id: 'gamesConsole24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M7.041,4a2.5,2.5 0,0 0,-2.447 1.99L2.22,17.372a2.183,2.183 0,0 0,4.274 0.89l0.474,-2.272A2.5,2.5 0,0 1,9.415 14h5.17a2.5,2.5 0,0 1,2.447 1.99l0.474,2.273a2.183,2.183 0,0 0,4.274 -0.892L19.406,5.99A2.5,2.5 0,0 0,16.96 4H7.04zM2.636,5.581A4.5,4.5 0,0 1,7.04 2h9.918a4.5,4.5 0,0 1,4.405 3.581l2.374,11.382a4.183,4.183 0,1 1,-8.19 1.708l-0.474,-2.273a0.5,0.5 0,0 0,-0.49 -0.398H9.416a0.5,0.5 0,0 0,-0.49 0.398l-0.473,2.273a4.183,4.183 0,1 1,-8.19 -1.708z',
      ),
      EncoreVectorPath(
        pathData: 'M10,8.75a1.75,1.75 0,1 1,-3.5 0,1.75 1.75,0 0,1 3.5,0m4,0a1.75,1.75 0,1 0,3.5 0,1.75 1.75,0 0,0 -3.5,0',
      ),
    ],
  );

  /// `encore_icon_watch_16.xml (pvw)`
  static const EncoreVectorIconData watch16 = EncoreVectorIconData(
    id: 'watch16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'm4.347,1.122 l-0.403,1.899A2.25,2.25 0,0 0,2 5.25v5.5a2.25,2.25 0,0 0,1.944 2.23l0.403,1.898c0.14,0.654 0.717,1.122 1.386,1.122h4.535c0.668,0 1.246,-0.468 1.385,-1.122l0.404,-1.899A2.25,2.25 0,0 0,14 10.75v-5.5a2.25,2.25 0,0 0,-1.943 -2.23l-0.404,-1.898A1.42,1.42 0,0 0,10.267 0H5.734c-0.67,0 -1.247,0.468 -1.386,1.122zM5.8,1.5h4.4l0.319,1.5H5.48zM10.52,13l-0.319,1.5H5.8L5.481,13zM4.25,4.5h7.5a0.75,0.75 0,0 1,0.75 0.75v5.5a0.75,0.75 0,0 1,-0.75 0.75h-7.5a0.75,0.75 0,0 1,-0.75 -0.75v-5.5a0.75,0.75 0,0 1,0.75 -0.75',
      ),
    ],
  );

  /// `encore_icon_watch_24.xml`
  static const EncoreVectorIconData watch24 = EncoreVectorIconData(
    id: 'watch24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M6.916,1.584A2,2 0,0 1,8.873 0h6.4a2,2 0,0 1,1.957 1.584l0.761,3.584A3,3 0,0 1,20 8v8a3,3 0,0 1,-2.009 2.832l-0.761,3.584A2,2 0,0 1,15.273 24h-6.4a2,2 0,0 1,-1.957 -1.584l-0.75,-3.534A3,3 0,0 1,4 16L4,8c0,-1.367 0.915,-2.52 2.165,-2.882zM8.235,5h7.676l-0.637,-3L8.873,2zM8.235,19 L8.873,22h6.4l0.638,-3zM7,7a1,1 0,0 0,-1 1v8a1,1 0,0 0,1 1h10a1,1 0,0 0,1 -1L18,8a1,1 0,0 0,-1 -1z',
      ),
    ],
  );

  /// `encore_icon_headphones_16.xml (jpw)`
  static const EncoreVectorIconData headphones16 = EncoreVectorIconData(
    id: 'headphones16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M0,8.289a8,8 0,1 1,14.77 4.263l-0.913,1.583A2.291,2.291 0,1 1,9.89 11.84l1.212,-2.09A2.31,2.31 0,0 1,13.1 8.6h1.392a6.5,6.5 0,1 0,-12.985 0h1.39a2.31,2.31 0,0 1,1.999 1.15l1.212,2.09a2.291,2.291 0,1 1,-3.966 2.295l-0.915,-1.585A7.96,7.96 0,0 1,0 8.289m1.755,1.81c0.172,0.594 0.426,1.151 0.749,1.662l0.008,0.013 0.93,1.611a0.791,0.791 0,1 0,1.37 -0.792L3.6,10.503a0.81,0.81 0,0 0,-0.702 -0.403zM14.245,10.099L13.1,10.099a0.81,0.81 0,0 0,-0.7 0.405l-1.213,2.089a0.791,0.791 0,1 0,1.37 0.792l0.929,-1.61 0.008,-0.012c0.324,-0.511 0.578,-1.07 0.75,-1.663z',
      ),
    ],
  );

  /// `encore_icon_headphones_24.xml`
  static const EncoreVectorIconData headphones24 = EncoreVectorIconData(
    id: 'headphones24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M0.5,12.5C0.5,6.149 5.649,1 12,1s11.5,5.149 11.5,11.5a11.43,11.43 0,0 1,-1.768 6.13l-1.325,2.294a3.232,3.232 0,1 1,-5.594 -3.238l1.83,-3.155a3,3 0,0 1,2.595 -1.494h2.247a9.5,9.5 0,1 0,-18.97 0L4.76,13.037a3,3 0,0 1,2.595 1.494l1.831,3.155a3.232,3.232 0,1 1,-5.594 3.238l-1.327,-2.298A11.44,11.44 0,0 1,0.5 12.5m2.342,2.537c0.25,0.907 0.633,1.76 1.125,2.537l0.01,0.017 1.348,2.333a1.232,1.232 0,1 0,2.132 -1.234l-1.83,-3.155a1,1 0,0 0,-0.866 -0.498zM21.158,15.037h-1.92a1,1 0,0 0,-0.864 0.498l-1.831,3.155a1.232,1.232 0,1 0,2.132 1.234l1.345,-2.33 0.011,-0.017a9.5,9.5 0,0 0,1.127 -2.54',
      ),
    ],
  );

  /// `encore_icon_headphones_optimize_16.xml (kpw)`
  static const EncoreVectorIconData headphonesOptimize16 = EncoreVectorIconData(
    id: 'headphonesOptimize16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M6.553,0.421a8,8 0,0 1,2.26 -0.09,2.75 2.75,0 0,0 -0.967,1.46 6.5,6.5 0,0 0,-5.938 4.227A6.5,6.5 0,0 0,1.507 8.6h1.39a2.31,2.31 0,0 1,2 1.15l1.211,2.09a2.292,2.292 0,1 1,-3.966 2.295l-0.914,-1.585A8.004,8.004 0,0 1,6.553 0.421M1.755,10.1c0.172,0.594 0.426,1.151 0.749,1.662l0.008,0.013 0.93,1.611a0.792,0.792 0,0 0,1.37 -0.792L3.6,10.503a0.81,0.81 0,0 0,-0.702 -0.403zM15.872,6.88c0.13,0.724 0.162,1.464 0.089,2.2a8,8 0,0 1,-1.19 3.472l-0.914,1.583a2.295,2.295 0,0 1,-3.131 0.836,2.293 2.293,0 0,1 -0.836,-3.13l1.213,-2.09A2.31,2.31 0,0 1,13.1 8.6h1.392q0.027,-0.582 -0.05,-1.155 0.097,-0.097 0.184,-0.202a2.7,2.7 0,0 0,1.246 -0.364M13.1,10.1a0.81,0.81 0,0 0,-0.7 0.404l-1.213,2.09a0.792,0.792 0,1 0,1.37 0.791l0.93,-1.61 0.007,-0.012c0.324,-0.51 0.578,-1.07 0.75,-1.663h0.001zM12.5,0.75a0.75,0.75 0,0 1,0.75 0.75v4a0.75,0.75 0,0 1,-1.5 0v-4a0.75,0.75 0,0 1,0.75 -0.75m-2,1a0.75,0.75 0,0 1,0.75 0.75v2a0.75,0.75 0,0 1,-1.5 0v-2a0.75,0.75 0,0 1,0.75 -0.75m4,0a0.75,0.75 0,0 1,0.75 0.75v2a0.75,0.75 0,0 1,-1.5 0v-2a0.75,0.75 0,0 1,0.75 -0.75',
      ),
    ],
  );

  /// `Encore.Vector.Bluetooth16 (lmw)`
  static const EncoreVectorIconData bluetooth16 = EncoreVectorIconData(
    id: 'bluetooth16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M7.809,1.538a0.5,0.5 0 0 1 0.545,0.108l3.0,3.0a0.5,0.5 0 0 1 0.0,0.708L8.707,8.0l2.647,2.646a0.5,0.5 0 0 1 0.0,0.708l-3.0,3.0A0.5,0.5 0 0 1 7.5,14.0L7.5,9.207l-2.146,2.147a0.5,0.5 0 0 1 -0.708,-0.707L7.293,8.0L4.646,5.354a0.5,0.5 0 1 1 0.708,-0.708L7.5,6.793L7.5,2.0a0.5,0.5 0 0 1 0.309,-0.462m0.691,7.67v3.585L10.293,11.0ZM8.5,6.793L10.293,5.0L8.5,3.207Z',
      ),
    ],
  );

  /// `encore_icon_bluetooth_24.xml`
  static const EncoreVectorIconData bluetooth24 = EncoreVectorIconData(
    id: 'bluetooth24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M11.713,2.307a0.75,0.75 0,0 1,0.817 0.163l4.5,4.5a0.75,0.75 0,0 1,0 1.06L13.06,12l3.97,3.97a0.75,0.75 0,0 1,0 1.06l-4.5,4.5a0.75,0.75 0,0 1,-1.28 -0.53v-7.19l-3.22,3.22a0.75,0.75 0,0 1,-1.06 -1.06L10.94,12 6.97,8.03a0.75,0.75 0,0 1,1.06 -1.06l3.22,3.22L11.25,3a0.75,0.75 0,0 1,0.463 -0.693m1.037,11.504v5.378l2.69,-2.689zM12.75,10.189L15.44,7.5l-2.69,-2.69v5.38z',
      ),
    ],
  );

  /// `Encore.Vector.AirPlay16 (plw)`
  static const EncoreVectorIconData airPlay16 = EncoreVectorIconData(
    id: 'airPlay16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M11.976,14.0L8.0,8.0l-4.0,6.0ZM0.0,2.0v10.0h2.929l0.666,-1.0H1.0V3.0h14.0v8.0h-2.611l0.659,1.0H16.0V2.0Z',
      ),
    ],
  );

  /// `Encore.Vector.AirPlay24 (plw)`
  static const EncoreVectorIconData airPlay24 = EncoreVectorIconData(
    id: 'airPlay24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M17.964,21.0L12.0,12.0l-6.0,9.0ZM0.0,3.0v15.0h4.393l1.0,-1.5H1.5v-12.0h21.0v12.0h-3.916l0.987,1.5H24.0V3.0Z',
      ),
    ],
  );

  /// `Encore.Vector.ChromecastDisconnected16 (hnw)`
  static const EncoreVectorIconData chromecastDisconnected16 = EncoreVectorIconData(
    id: 'chromecastDisconnected16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M0.667,12.0v2.0h2.0q0.0,-0.825 -0.588,-1.413A1.93,1.93 0 0 0 0.667,12.0m0.0,-2.667v1.334q1.38,0.0 2.357,0.976Q4.0,12.618 4.0,14.0h1.333q0.0,-0.952 -0.369,-1.817a4.7,4.7 0 0 0 -0.992,-1.489a4.7,4.7 0 0 0 -1.488,-0.992a4.6,4.6 0 0 0 -1.817,-0.369m0.0,-2.666V8.0q1.627,0.0 3.008,0.806a6.0,6.0 0 0 1 2.186,2.186q0.806,1.38 0.806,3.008H8.0a7.4,7.4 0 0 0 -0.369,-2.317a7.0,7.0 0 0 0 -1.048,-2.02A8.0,8.0 0 0 0 5.0,8.083a7.0,7.0 0 0 0 -2.024,-1.047a7.3,7.3 0 0 0 -2.31,-0.37ZM14.0,2.0H2.0a1.28,1.28 0 0 0 -0.94,0.393a1.28,1.28 0 0 0 -0.393,0.94v2.0H2.0v-2.0h12.0v9.334H9.333V14.0H14.0q0.548,0.0 0.94,-0.393q0.393,-0.393 0.393,-0.94V3.333q0.0,-0.547 -0.393,-0.94A1.28,1.28 0 0 0 14.0,2.0',
      ),
    ],
  );

  /// `Encore.Vector.ChromecastDisconnected24 (hnw)`
  static const EncoreVectorIconData chromecastDisconnected24 = EncoreVectorIconData(
    id: 'chromecastDisconnected24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M1.0,18.0v3.0h3.0a2.9,2.9 0 0 0 -0.88,-2.119A2.9,2.9 0 0 0 1.0,18.0m0.0,-4.0v2.0q2.071,0.0 3.536,1.465Q6.0,18.928 6.0,21.0h2.0q0.0,-1.429 -0.553,-2.726a7.0,7.0 0 0 0 -1.489,-2.232a7.0,7.0 0 0 0 -2.232,-1.488A6.9,6.9 0 0 0 1.0,14.0m0.0,-4.0v2.0q2.44,0.0 4.512,1.208a8.96,8.96 0 0 1 3.28,3.28A8.8,8.8 0 0 1 10.0,21.0h2.0q0.0,-1.797 -0.553,-3.476a10.4,10.4 0 0 0 -1.572,-3.03A12.0,12.0 0 0 0 7.5,12.125a10.5,10.5 0 0 0 -3.036,-1.572A11.0,11.0 0 0 0 1.0,9.998ZM21.0,3.0L3.0,3.0q-0.821,0.0 -1.41,0.59Q0.999,4.178 1.0,5.0v3.0h2.0L3.0,5.0h18.0v14.0h-7.0v2.0h7.0q0.821,0.0 1.41,-0.59q0.59,-0.588 0.59,-1.41L23.0,5.0a1.92,1.92 0 0 0 -0.59,-1.411A1.93,1.93 0 0 0 21.0,3.0',
      ),
    ],
  );

  /// `Encore.Vector.ChromecastConnected16 (gnw)`
  static const EncoreVectorIconData chromecastConnected16 = EncoreVectorIconData(
    id: 'chromecastConnected16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M0.667,12.0v2.0h2.0q0.0,-0.825 -0.588,-1.413A1.93,1.93 0 0 0 0.667,12.0m0.0,-2.667v1.334q1.38,0.0 2.357,0.976Q4.0,12.618 4.0,14.0h1.333q0.0,-0.952 -0.369,-1.817a4.7,4.7 0 0 0 -0.992,-1.489a4.7,4.7 0 0 0 -1.488,-0.992a4.6,4.6 0 0 0 -1.817,-0.369m12.0,-4.666L3.333,4.667v1.087a8.5,8.5 0 0 1 3.465,2.115a8.5,8.5 0 0 1 2.115,3.464h3.754ZM0.667,6.667L0.667,8.0q1.627,0.0 3.008,0.806a6.0,6.0 0 0 1 2.186,2.186q0.806,1.38 0.806,3.008L8.0,14.0a7.4,7.4 0 0 0 -0.369,-2.317a7.0,7.0 0 0 0 -1.048,-2.02A8.0,8.0 0 0 0 5.0,8.083a7.0,7.0 0 0 0 -2.024,-1.047a7.3,7.3 0 0 0 -2.31,-0.37ZM14.0,2.0L2.0,2.0a1.28,1.28 0 0 0 -0.94,0.393a1.28,1.28 0 0 0 -0.393,0.94v2.0L2.0,5.333v-2.0h12.0v9.334L9.333,12.667L9.333,14.0L14.0,14.0q0.548,0.0 0.94,-0.393q0.393,-0.393 0.393,-0.94L15.333,3.333q0.0,-0.547 -0.393,-0.94A1.28,1.28 0 0 0 14.0,2.0',
      ),
    ],
  );

  /// `Encore.Vector.ChromecastConnected24 (gnw)`
  static const EncoreVectorIconData chromecastConnected24 = EncoreVectorIconData(
    id: 'chromecastConnected24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M1.0,18.0v3.0h3.0a2.9,2.9 0 0 0 -0.88,-2.119A2.9,2.9 0 0 0 1.0,18.0m0.0,-4.0v2.0q2.071,0.0 3.536,1.465Q6.0,18.928 6.0,21.0h2.0q0.0,-1.429 -0.553,-2.726a7.0,7.0 0 0 0 -1.489,-2.232a7.0,7.0 0 0 0 -2.232,-1.488A6.9,6.9 0 0 0 1.0,14.0m18.0,-7.0L5.0,7.0v1.63a12.74,12.74 0 0 1 5.196,3.172A12.74,12.74 0 0 1 13.37,17.0L19.0,17.0ZM1.0,10.0v2.0q2.44,0.0 4.512,1.208a8.96,8.96 0 0 1 3.28,3.28A8.8,8.8 0 0 1 10.0,21.0h2.0q0.0,-1.797 -0.553,-3.476a10.4,10.4 0 0 0 -1.572,-3.03A12.0,12.0 0 0 0 7.5,12.125a10.5,10.5 0 0 0 -3.036,-1.572A11.0,11.0 0 0 0 1.0,9.998ZM21.0,3.0L3.0,3.0q-0.821,0.0 -1.41,0.59Q0.999,4.178 1.0,5.0v3.0h2.0L3.0,5.0h18.0v14.0h-7.0v2.0h7.0q0.821,0.0 1.41,-0.59q0.59,-0.588 0.59,-1.41L23.0,5.0a1.92,1.92 0 0 0 -0.59,-1.411A1.93,1.93 0 0 0 21.0,3.0',
      ),
    ],
  );

  /// `Encore.Vector.SpotifyConnect16 (iuw)`
  static const EncoreVectorIconData spotifyConnect16 = EncoreVectorIconData(
    id: 'spotifyConnect16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M14.5,8.0a6.47,6.47 0 0 0 -1.3,-3.9l1.2,-0.9C15.405,4.537 16.0,6.2 16.0,8.0s-0.595,3.463 -1.6,4.8l-1.2,-0.9A6.47,6.47 0 0 0 14.5,8.0M8.0,1.5a6.5,6.5 0 1 0 3.25,12.13a0.75,0.75 0 1 1 0.75,1.3a8.0,8.0 0 1 1 0.0,-13.86a0.75,0.75 0 1 1 -0.75,1.298A6.47,6.47 0 0 0 8.0,1.5',
      ),
      EncoreVectorPath(
        pathData: 'M11.259,8.0c0.0,-0.676 -0.228,-1.296 -0.611,-1.791l1.187,-0.918c0.579,0.749 0.924,1.69 0.924,2.709a4.4,4.4 0 0 1 -0.925,2.709l-1.186,-0.918c0.383,-0.495 0.61,-1.115 0.61,-1.791ZM8.75,4.115l-4.139,2.39a1.727,1.727 0 0 0 0.0,2.99l4.139,2.39Z',
      ),
    ],
  );

  /// `Encore.Vector.SpotifyConnect24 (iuw)`
  static const EncoreVectorIconData spotifyConnect24 = EncoreVectorIconData(
    id: 'spotifyConnect24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M21.0,12.0c0.0,-2.027 -0.67,-3.895 -1.799,-5.4l1.6,-1.2A10.96,10.96 0 0 1 23.0,12.0c0.0,2.475 -0.819,4.762 -2.2,6.6l-1.599,-1.2A8.96,8.96 0 0 0 21.0,12.0m-9.0,-9.0a9.0,9.0 0 0 0 0.0,18.0a8.96,8.96 0 0 0 4.5,-1.203a1.0,1.0 0 1 1 1.0,1.73A10.95,10.95 0 0 1 12.0,23.0C5.925,23.0 1.0,18.075 1.0,12.0S5.925,1.0 12.0,1.0c2.002,0.0 3.882,0.536 5.5,1.472a1.0,1.0 0 0 1 -1.0,1.731A8.95,8.95 0 0 0 12.0,3.0',
      ),
      EncoreVectorPath(
        pathData: 'M17.0,12.0a4.98,4.98 0 0 0 -1.042,-3.056L17.54,7.72A6.97,6.97 0 0 1 19.0,12.0c0.0,1.61 -0.545,3.096 -1.46,4.28l-1.582,-1.224A4.97,4.97 0 0 0 17.0,12.0m-4.0,-5.0l-5.327,3.077a2.223,2.223 0 0 0 0.0,3.846L13.0,17.0Z',
      ),
    ],
  );

  /// `Encore.Vector.VolumeOneWave16 (ovw)`
  static const EncoreVectorIconData volumeOneWave16 = EncoreVectorIconData(
    id: 'volumeOneWave16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M9.741,0.85a0.75,0.75 0 0 1 0.375,0.65v13.0a0.75,0.75 0 0 1 -1.125,0.65l-6.925,-4.0a3.64,3.64 0 0 1 -1.33,-4.967a3.64,3.64 0 0 1 1.33,-1.332l6.925,-4.0a0.75,0.75 0 0 1 0.75,0.0ZM2.817,6.15a2.14,2.14 0 0 0 0.0,3.7l5.8,3.35L8.617,2.8ZM11.5,10.44L11.5,5.56a2.75,2.75 0 0 1 0.0,4.88',
      ),
    ],
  );

  /// `Encore.Vector.VolumeOneWave24 (ovw)`
  static const EncoreVectorIconData volumeOneWave24 = EncoreVectorIconData(
    id: 'volumeOneWave24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M14.5,1.134A1.0,1.0 0 0 1 15.0,2.0v20.0a1.0,1.0 0 0 1 -1.5,0.866L2.846,16.712a5.445,5.445 0 0 1 0.0,-9.424L13.5,1.135a1.0,1.0 0 0 1 1.0,0.0ZM3.847,9.02a3.444,3.444 0 0 0 0.0,5.96L13.0,20.268V3.732ZM17.0,16.032V7.968a4.5,4.5 0 0 1 0.0,8.064',
      ),
    ],
  );

  /// `encore_icon_volume_16.xml (mvw)`
  static const EncoreVectorIconData volume16 = EncoreVectorIconData(
    id: 'volume16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M9.741,0.85a0.75,0.75 0,0 1,0.375 0.65v13a0.75,0.75 0,0 1,-1.125 0.65l-6.925,-4a3.64,3.64 0,0 1,-1.33 -4.967,3.64 3.64,0 0,1 1.33,-1.332l6.925,-4a0.75,0.75 0,0 1,0.75 0zM2.817,6.15a2.14,2.14 0,0 0,0 3.7l5.8,3.35L8.617,2.8zM11.5,10.44L11.5,5.56a2.75,2.75 0,0 1,0 4.88',
      ),
      EncoreVectorPath(
        pathData: 'M11.5,13.614a5.752,5.752 0,0 0,0 -11.228v1.55a4.252,4.252 0,0 1,0 8.127z',
      ),
    ],
  );

  /// `encore_icon_volume_24.xml`
  static const EncoreVectorIconData volume24 = EncoreVectorIconData(
    id: 'volume24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M14.5,1.134A1,1 0,0 1,15 2v20a1,1 0,0 1,-1.5 0.866L2.846,16.712a5.445,5.445 0,0 1,0 -9.424L13.5,1.135a1,1 0,0 1,1 0zM3.847,9.02a3.444,3.444 0,0 0,0 5.96L13,20.268V3.732zM17,20.127a8.504,8.504 0,0 0,0 -16.253v2.125a6.502,6.502 0,0 1,0 12.003z',
      ),
      EncoreVectorPath(
        pathData: 'M17,16.032V7.968a4.5,4.5 0,0 1,0 8.064',
      ),
    ],
  );

  /// `encore_icon_volume_off_16.xml`
  static const EncoreVectorIconData volumeOff16 = EncoreVectorIconData(
    id: 'volumeOff16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M13.86,5.47a0.75,0.75 0,0 0,-1.061 0l-1.47,1.47 -1.47,-1.47A0.75,0.75 0,0 0,8.8 6.53L10.269,8l-1.47,1.47a0.75,0.75 0,1 0,1.06 1.06l1.47,-1.47 1.47,1.47a0.75,0.75 0,0 0,1.06 -1.06L12.39,8l1.47,-1.47a0.75,0.75 0,0 0,0 -1.06',
      ),
      EncoreVectorPath(
        pathData: 'M10.116,1.5A0.75,0.75 0,0 0,8.991 0.85l-6.925,4a3.64,3.64 0,0 0,-1.33 4.967,3.64 3.64,0 0,0 1.33,1.332l6.925,4a0.75,0.75 0,0 0,1.125 -0.649v-1.906a4.7,4.7 0,0 1,-1.5 -0.694v1.3L2.817,9.852a2.14,2.14 0,0 1,-0.781 -2.92c0.187,-0.324 0.456,-0.594 0.78,-0.782l5.8,-3.35v1.3c0.45,-0.313 0.956,-0.55 1.5,-0.694z',
      ),
    ],
  );

  /// `encore_icon_volume_off_24.xml`
  static const EncoreVectorIconData volumeOff24 = EncoreVectorIconData(
    id: 'volumeOff24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M17.293,15.207a1,1 0,0 0,1.414 0l1.793,-1.793 1.793,1.793a1,1 0,0 0,1.414 -1.414L21.914,12l1.793,-1.793a1,1 0,0 0,-1.414 -1.414L20.5,10.586l-1.793,-1.793a1,1 0,1 0,-1.414 1.414L19.086,12l-1.793,1.793a1,1 0,0 0,0 1.414M14.5,1.134A1,1 0,0 1,15 2v20a1,1 0,0 1,-1.5 0.866L2.846,16.712a5.445,5.445 0,0 1,0 -9.424L13.5,1.135a1,1 0,0 1,1 0zM3.847,9.02a3.444,3.444 0,0 0,0 5.96L13,20.268V3.732z',
      ),
    ],
  );

  /// `Encore.Vector.More16 (tqw)`
  static const EncoreVectorIconData more16 = EncoreVectorIconData(
    id: 'more16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M3.0,8.0a1.5,1.5 0 1 1 -3.0,0.0a1.5,1.5 0 0 1 3.0,0.0m6.5,0.0a1.5,1.5 0 1 1 -3.0,0.0a1.5,1.5 0 0 1 3.0,0.0M16.0,8.0a1.5,1.5 0 1 1 -3.0,0.0a1.5,1.5 0 0 1 3.0,0.0',
      ),
    ],
  );

  /// `Encore.Vector.More24 (tqw)`
  static const EncoreVectorIconData more24 = EncoreVectorIconData(
    id: 'more24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M4.5,13.5a1.5,1.5 0 1 0 0.0,-3.0a1.5,1.5 0 0 0 0.0,3.0m15.0,0.0a1.5,1.5 0 1 0 0.0,-3.0a1.5,1.5 0 0 0 0.0,3.0m-7.5,0.0a1.5,1.5 0 1 0 0.0,-3.0a1.5,1.5 0 0 0 0.0,3.0',
      ),
    ],
  );

  /// `encore_icon_more_android_16.xml`
  static const EncoreVectorIconData moreAndroid16 = EncoreVectorIconData(
    id: 'moreAndroid16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M8,3a1.5,1.5 0,1 1,0 -3,1.5 1.5,0 0,1 0,3m0,6.5a1.5,1.5 0,1 1,0 -3,1.5 1.5,0 0,1 0,3M8,16a1.5,1.5 0,1 1,0 -3,1.5 1.5,0 0,1 0,3',
      ),
    ],
  );

  /// `encore_icon_more_android_24.xml`
  static const EncoreVectorIconData moreAndroid24 = EncoreVectorIconData(
    id: 'moreAndroid24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M10.5,4.5a1.5,1.5 0,1 0,3 0,1.5 1.5,0 0,0 -3,0m0,15a1.5,1.5 0,1 0,3 0,1.5 1.5,0 0,0 -3,0m0,-7.5a1.5,1.5 0,1 0,3 0,1.5 1.5,0 0,0 -3,0',
      ),
    ],
  );

  /// `encore_icon_chevron_down_16.xml`
  static const EncoreVectorIconData chevronDown16 = EncoreVectorIconData(
    id: 'chevronDown16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M0.47,4.97a0.75,0.75 0,0 1,1.06 0L8,11.44l6.47,-6.47a0.75,0.75 0,1 1,1.06 1.06L8,13.56 0.47,6.03a0.75,0.75 0,0 1,0 -1.06',
      ),
    ],
  );

  /// `encore_icon_chevron_up_16.xml`
  static const EncoreVectorIconData chevronUp16 = EncoreVectorIconData(
    id: 'chevronUp16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M0.47,11.03a0.75,0.75 0,0 0,1.06 0L8,4.56l6.47,6.47a0.75,0.75 0,1 0,1.06 -1.06L8,2.44 0.47,9.97a0.75,0.75 0,0 0,0 1.06',
      ),
    ],
  );

  /// `encore_icon_chevron_right_16.xml`
  static const EncoreVectorIconData chevronRight16 = EncoreVectorIconData(
    id: 'chevronRight16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M4.97,0.47a0.75,0.75 0,0 0,0 1.06L11.44,8l-6.47,6.47a0.75,0.75 0,1 0,1.06 1.06L13.56,8 6.03,0.47a0.75,0.75 0,0 0,-1.06 0',
      ),
    ],
  );

  /// `encore_icon_check_alt_16.xml`
  static const EncoreVectorIconData checkAlt16 = EncoreVectorIconData(
    id: 'checkAlt16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M8,1.5a6.5,6.5 0,1 0,0 13,6.5 6.5,0 0,0 0,-13M0,8a8,8 0,1 1,16 0A8,8 0,0 1,0 8',
      ),
      EncoreVectorPath(
        pathData: 'M11.079,5.47a0.75,0.75 0,0 1,0 1.06l-4.53,4.53 -2.08,-2.078a0.75,0.75 0,1 1,1.061 -1.06l1.02,1.016 3.47,-3.47a0.75,0.75 0,0 1,1.06 0z',
      ),
    ],
  );

  /// `encore_icon_check_alt_24.xml`
  static const EncoreVectorIconData checkAlt24 = EncoreVectorIconData(
    id: 'checkAlt24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M12,3a9,9 0,1 0,0 18,9 9,0 0,0 0,-18M1,12C1,5.925 5.925,1 12,1s11,4.925 11,11 -4.925,11 -11,11S1,18.075 1,12',
      ),
      EncoreVectorPath(
        pathData: 'M17.398,8.207a1,1 0,0 1,0 1.414l-7.425,7.425 -3.308,-3.308a1,1 0,0 1,1.414 -1.414l1.894,1.894 6.011,-6.011a1,1 0,0 1,1.414 0',
      ),
    ],
  );

  /// `encore_icon_check_alt_fill_16.xml`
  static const EncoreVectorIconData checkAltFill16 = EncoreVectorIconData(
    id: 'checkAltFill16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M0,8a8,8 0,1 1,16 0A8,8 0,0 1,0 8m11.748,-1.97a0.75,0.75 0,0 0,-1.06 -1.06l-4.47,4.47 -1.405,-1.406a0.75,0.75 0,1 0,-1.061 1.06l2.466,2.467 5.53,-5.53z',
      ),
    ],
  );

  /// `encore_icon_check_alt_fill_24.xml`
  static const EncoreVectorIconData checkAltFill24 = EncoreVectorIconData(
    id: 'checkAltFill24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M1,12C1,5.925 5.925,1 12,1s11,4.925 11,11 -4.925,11 -11,11S1,18.075 1,12m16.398,-2.38a1,1 0,0 0,-1.414 -1.413l-6.011,6.01 -1.894,-1.893a1,1 0,0 0,-1.414 1.414l3.308,3.308z',
      ),
    ],
  );

  /// `encore_icon_plus_alt_16.xml`
  static const EncoreVectorIconData plusAlt16 = EncoreVectorIconData(
    id: 'plusAlt16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M8,1.5a6.5,6.5 0,1 0,0 13,6.5 6.5,0 0,0 0,-13M0,8a8,8 0,1 1,16 0A8,8 0,0 1,0 8',
      ),
      EncoreVectorPath(
        pathData: 'M11.75,8a0.75,0.75 0,0 1,-0.75 0.75H8.75V11a0.75,0.75 0,0 1,-1.5 0V8.75H5a0.75,0.75 0,0 1,0 -1.5h2.25V5a0.75,0.75 0,0 1,1.5 0v2.25H11a0.75,0.75 0,0 1,0.75 0.75',
      ),
    ],
  );

  /// `encore_icon_plus_alt_24.xml`
  static const EncoreVectorIconData plusAlt24 = EncoreVectorIconData(
    id: 'plusAlt24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M11.999,3a9,9 0,1 0,0 18,9 9,0 0,0 0,-18m-11,9c0,-6.075 4.925,-11 11,-11s11,4.925 11,11 -4.925,11 -11,11 -11,-4.925 -11,-11',
      ),
      EncoreVectorPath(
        pathData: 'M17.999,12a1,1 0,0 1,-1 1h-4v4a1,1 0,1 1,-2 0v-4h-4a1,1 0,1 1,0 -2h4V7a1,1 0,1 1,2 0v4h4a1,1 0,0 1,1 1',
      ),
    ],
  );

  /// `encore_icon_play_24.xml`
  static const EncoreVectorIconData play24 = EncoreVectorIconData(
    id: 'play24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'm7.05,3.606 l13.49,7.788a0.7,0.7 0,0 1,0 1.212L7.05,20.394A0.7,0.7 0,0 1,6 19.788V4.212a0.7,0.7 0,0 1,1.05 -0.606',
      ),
    ],
  );

  /// `encore_icon_pause_24.xml`
  static const EncoreVectorIconData pause24 = EncoreVectorIconData(
    id: 'pause24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M5.7,3a0.7,0.7 0,0 0,-0.7 0.7v16.6a0.7,0.7 0,0 0,0.7 0.7h2.6a0.7,0.7 0,0 0,0.7 -0.7L9,3.7a0.7,0.7 0,0 0,-0.7 -0.7zM15.7,3a0.7,0.7 0,0 0,-0.7 0.7v16.6a0.7,0.7 0,0 0,0.7 0.7h2.6a0.7,0.7 0,0 0,0.7 -0.7L19,3.7a0.7,0.7 0,0 0,-0.7 -0.7z',
      ),
    ],
  );

  /// `encore_icon_queue_24.xml`
  static const EncoreVectorIconData queue24 = EncoreVectorIconData(
    id: 'queue24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M21,22L3,22v-2h18zM21,16L3,16v-2h18zM2.05,6.546a3.5,3.5 0,0 1,3.5 -3.5h13a3.5,3.5 0,0 1,0 7h-13a3.5,3.5 0,0 1,-3.5 -3.5m3.5,-1.5a1.5,1.5 0,0 0,0 3h13a1.5,1.5 0,0 0,0 -3z',
      ),
    ],
  );

  /// `encore_icon_queue_badge_16.xml`
  static const EncoreVectorIconData queueBadge16 = EncoreVectorIconData(
    id: 'queueBadge16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M3,4.5a1,1 0,0 1,1 -1h8a1,1 0,1 1,0 2H4a1,1 0,0 1,-1 -1',
      ),
      EncoreVectorPath(
        pathData: 'M1,0a1,1 0,0 0,-1 1v14a1,1 0,0 0,1 1h14a1,1 0,0 0,1 -1L16,1a1,1 0,0 0,-1 -1zM2,14v-1.5h12L14,14zM14,10.5L2,10.5L2,9h12zM4,2h8a2.5,2.5 0,0 1,0 5L4,7a2.5,2.5 0,0 1,0 -5',
      ),
    ],
  );

  /// `encore_icon_queue_badge_24.xml`
  static const EncoreVectorIconData queueBadge24 = EncoreVectorIconData(
    id: 'queueBadge24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M5,6.5A1.5,1.5 0,0 1,6.5 5h11a1.5,1.5 0,0 1,0 3h-11A1.5,1.5 0,0 1,5 6.5',
      ),
      EncoreVectorPath(
        pathData: 'M3,1a2,2 0,0 0,-2 2v18a2,2 0,0 0,2 2h18a2,2 0,0 0,2 -2L23,3a2,2 0,0 0,-2 -2zM20,15L4,15v-2h16zM20,20L4,20v-2h16zM6.5,3h11a3.5,3.5 0,1 1,0 7h-11a3.5,3.5 0,1 1,0 -7m0,2a1.5,1.5 0,1 0,0 3h11a1.5,1.5 0,0 0,0 -3z',
      ),
    ],
  );

  /// `encore_icon_enhance_badge_16.xml`
  static const EncoreVectorIconData enhanceBadge16 = EncoreVectorIconData(
    id: 'enhanceBadge16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M1,0a1,1 0,0 0,-1 1v14a1,1 0,0 0,1 1h14a1,1 0,0 0,1 -1L16,1a1,1 0,0 0,-1 -1zM8.975,4.287c1.268,-0.448 1.959,-1.448 2.288,-2.318 0.042,-0.113 0.432,-0.113 0.474,0 0.33,0.87 1.02,1.87 2.288,2.318 0.113,0.04 0.113,0.386 0,0.426 -1.268,0.448 -1.959,1.448 -2.288,2.319 -0.042,0.112 -0.432,0.112 -0.474,0 -0.33,-0.87 -1.02,-1.871 -2.288,-2.319 -0.113,-0.04 -0.113,-0.386 0,-0.426M1.893,9.33c2.347,-0.647 3.474,-2.68 3.904,-4.25 0.033,-0.118 0.373,-0.118 0.406,0 0.43,1.57 1.557,3.603 3.904,4.25 0.115,0.032 0.115,0.308 0,0.34 -2.347,0.648 -3.474,2.68 -3.904,4.25 -0.033,0.118 -0.373,0.118 -0.406,0 -0.43,-1.57 -1.557,-3.602 -3.904,-4.25 -0.115,-0.032 -0.115,-0.308 0,-0.34',
      ),
    ],
  );

  /// `encore_icon_enhance_badge_24.xml`
  static const EncoreVectorIconData enhanceBadge24 = EncoreVectorIconData(
    id: 'enhanceBadge24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M3,1a2,2 0,0 0,-2 2v18a2,2 0,0 0,2 2h18a2,2 0,0 0,2 -2L23,3a2,2 0,0 0,-2 -2zM14.975,6.302c1.268,-0.447 1.959,-1.448 2.288,-2.318 0.042,-0.113 0.432,-0.113 0.474,0 0.33,0.87 1.02,1.871 2.288,2.318 0.113,0.04 0.113,0.387 0,0.427 -1.268,0.447 -1.959,1.448 -2.288,2.318 -0.042,0.113 -0.432,0.113 -0.474,0 -0.33,-0.87 -1.02,-1.87 -2.288,-2.318 -0.113,-0.04 -0.113,-0.386 0,-0.427M19.5,18a1.5,1.5 0,1 1,-3 0,1.5 1.5,0 0,1 3,0M2.99,12.352C7.389,11.47 9.27,7.9 9.833,5.485c0.027,-0.118 0.307,-0.118 0.334,0 0.563,2.414 2.444,5.984 6.843,6.867 0.119,0.024 0.119,0.272 0,0.296 -4.4,0.883 -6.28,4.454 -6.843,6.867 -0.027,0.118 -0.307,0.118 -0.334,0 -0.563,-2.413 -2.444,-5.984 -6.843,-6.867 -0.119,-0.024 -0.119,-0.272 0,-0.296',
      ),
    ],
  );

  /// `encore_icon_exclamation_circle_16.xml`
  static const EncoreVectorIconData exclamationCircle16 = EncoreVectorIconData(
    id: 'exclamationCircle16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M8,1.5a6.5,6.5 0,1 0,0 13,6.5 6.5,0 0,0 0,-13M0,8a8,8 0,1 1,16 0A8,8 0,0 1,0 8',
      ),
      EncoreVectorPath(
        pathData: 'M7.25,9L7.25,4h1.5v5zM7.25,12.026v-1.5h1.5v1.5z',
      ),
    ],
  );

  /// `encore_icon_exclamation_circle_24.xml`
  static const EncoreVectorIconData exclamationCircle24 = EncoreVectorIconData(
    id: 'exclamationCircle24',
    viewportSize: 24.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M11,18v-2h2v2zM11,14L11,6h2v8z',
      ),
      EncoreVectorPath(
        pathData: 'M12,3a9,9 0,1 0,0 18,9 9,0 0,0 0,-18M1,12C1,5.925 5.925,1 12,1s11,4.925 11,11 -4.925,11 -11,11S1,18.075 1,12',
      ),
    ],
  );

  /// `Encore.Vector.SpotifyLogo16 (juw)`
  static const EncoreVectorIconData spotifyLogo16 = EncoreVectorIconData(
    id: 'spotifyLogo16',
    viewportSize: 16.0,
    paths: <EncoreVectorPath>[
      EncoreVectorPath(
        pathData: 'M8.319,0.006A8.003,8.003 0 0 0 0.006,7.683a8.0,8.0 0 0 0 7.677,8.31A8.0,8.0 0 0 0 8.319,0.006m3.377,11.72a0.48,0.48 0 0 1 -0.652,0.179a9.6,9.6 0 0 0 -3.426,-1.165a9.6,9.6 0 0 0 -3.613,0.176a0.479,0.479 0 0 1 -0.226,-0.93c1.3,-0.316 2.637,-0.38 3.972,-0.193c1.336,0.188 2.602,0.62 3.765,1.28c0.228,0.13 0.309,0.422 0.178,0.652ZM12.746,9.626a0.62,0.62 0 0 1 -0.841,0.25A11.8,11.8 0 0 0 7.923,8.57a11.8,11.8 0 0 0 -4.188,0.158a0.62,0.62 0 0 1 -0.74,-0.473a0.62,0.62 0 0 1 0.473,-0.739a13.0,13.0 0 0 1 4.626,-0.176c1.552,0.217 3.031,0.704 4.4,1.444a0.62,0.62 0 0 1 0.25,0.842h0.003ZM13.912,7.259a0.765,0.765 0 0 1 -1.031,0.326a14.3,14.3 0 0 0 -4.612,-1.473a14.3,14.3 0 0 0 -4.84,0.145a0.764,0.764 0 1 1 -0.303,-1.499a15.8,15.8 0 0 1 5.356,-0.16c1.791,0.252 3.51,0.8 5.104,1.63c0.374,0.194 0.52,0.656 0.326,1.03Z',
      ),
    ],
  );

  static const EncoreIconPair devices = EncoreIconPair(
    small16: devices16,
    medium24: devices24,
  );
  static const EncoreIconPair deviceMobile = EncoreIconPair(
    small16: deviceMobile16,
    medium24: deviceMobile24,
  );
  static const EncoreIconPair deviceComputer = EncoreIconPair(
    small16: deviceComputer16,
    medium24: deviceComputer24,
  );
  static const EncoreIconPair deviceTablet = EncoreIconPair(
    small16: deviceTablet16,
    medium24: deviceTablet24,
  );
  static const EncoreIconPair deviceSpeaker = EncoreIconPair(
    small16: deviceSpeaker16,
    medium24: deviceSpeaker24,
  );
  static const EncoreIconPair deviceTv = EncoreIconPair(
    small16: deviceTv16,
    medium24: deviceTv24,
  );
  static const EncoreIconPair deviceArm = EncoreIconPair(
    small16: deviceArm16,
    medium24: deviceArm24,
  );
  static const EncoreIconPair deviceCar = EncoreIconPair(
    small16: deviceCar16,
    medium24: deviceCar24,
  );
  static const EncoreIconPair deviceOther = EncoreIconPair(
    small16: deviceOther16,
    medium24: deviceOther24,
  );
  static const EncoreIconPair deviceMultispeaker = EncoreIconPair(
    small16: deviceMultispeaker16,
    medium24: deviceMultispeaker24,
  );
  static const EncoreIconPair deviceSmartGlasses = EncoreIconPair(
    small16: deviceSmartGlasses16,
    medium24: deviceSmartGlasses24,
  );
  static const EncoreIconPair gamesConsole = EncoreIconPair(
    small16: gamesConsole16,
    medium24: gamesConsole24,
  );
  static const EncoreIconPair watch = EncoreIconPair(
    small16: watch16,
    medium24: watch24,
  );
  static const EncoreIconPair headphones = EncoreIconPair(
    small16: headphones16,
    medium24: headphones24,
  );
  static const EncoreIconPair headphonesOptimize = EncoreIconPair(
    small16: headphonesOptimize16,
    medium24: headphones24,
  );
  static const EncoreIconPair bluetooth = EncoreIconPair(
    small16: bluetooth16,
    medium24: bluetooth24,
  );
  static const EncoreIconPair airPlay = EncoreIconPair(
    small16: airPlay16,
    medium24: airPlay24,
  );
  static const EncoreIconPair chromecastDisconnected = EncoreIconPair(
    small16: chromecastDisconnected16,
    medium24: chromecastDisconnected24,
  );
  static const EncoreIconPair chromecastConnected = EncoreIconPair(
    small16: chromecastConnected16,
    medium24: chromecastConnected24,
  );
  static const EncoreIconPair spotifyConnect = EncoreIconPair(
    small16: spotifyConnect16,
    medium24: spotifyConnect24,
  );
  static const EncoreIconPair volumeOneWave = EncoreIconPair(
    small16: volumeOneWave16,
    medium24: volumeOneWave24,
  );
  static const EncoreIconPair volume = EncoreIconPair(
    small16: volume16,
    medium24: volume24,
  );
  static const EncoreIconPair volumeOff = EncoreIconPair(
    small16: volumeOff16,
    medium24: volumeOff24,
  );
  static const EncoreIconPair more = EncoreIconPair(
    small16: more16,
    medium24: more24,
  );
  static const EncoreIconPair moreAndroid = EncoreIconPair(
    small16: moreAndroid16,
    medium24: moreAndroid24,
  );
  static const EncoreIconPair checkAlt = EncoreIconPair(
    small16: checkAlt16,
    medium24: checkAlt24,
  );
  static const EncoreIconPair checkAltFill = EncoreIconPair(
    small16: checkAltFill16,
    medium24: checkAltFill24,
  );
  static const EncoreIconPair plusAlt = EncoreIconPair(
    small16: plusAlt16,
    medium24: plusAlt24,
  );
  static const EncoreIconPair queueBadge = EncoreIconPair(
    small16: queueBadge16,
    medium24: queueBadge24,
  );
  static const EncoreIconPair enhanceBadge = EncoreIconPair(
    small16: enhanceBadge16,
    medium24: enhanceBadge24,
  );
  static const EncoreIconPair exclamationCircle = EncoreIconPair(
    small16: exclamationCircle16,
    medium24: exclamationCircle24,
  );
}

/// Returns `true` when [device] is a Google Cast target (`CAST_VIDEO`,
/// `CAST_AUDIO`, or carries a Cast incarnation).
bool isCastConnectDevice(ConnectDevice device) {
  if (device.type == DeviceType.castVideo ||
      device.type == DeviceType.castAudio) {
    return true;
  }
  for (final incarnation in device.incarnations) {
    final parsed = incarnation.parsedLoginType;
    if (parsed == IncarnationLoginType.cast ||
        parsed == IncarnationLoginType.castJs) {
      return true;
    }
  }
  return false;
}

/// Maps [DeviceType] to Spotify's exact Encore vector icon pair (`p199p/byl1.java`
/// `m32480o` & `m32482q`). Exhaustive over all [DeviceType] values.
EncoreIconPair resolveDeviceTypeEncoreIcon(
  DeviceType type, {
  bool isGroup = false,
  bool isCastConnected = false,
}) {
  if (isGroup) {
    return ConnectEncoreIcons.deviceMultispeaker;
  }
  switch (type) {
    case DeviceType.computer:
    case DeviceType.chromebook:
      return ConnectEncoreIcons.deviceComputer;
    case DeviceType.tablet:
      return ConnectEncoreIcons.deviceTablet;
    case DeviceType.smartphone:
      return ConnectEncoreIcons.deviceMobile;
    case DeviceType.speaker:
    case DeviceType.homeThing:
    case DeviceType.unknownSpotifyHw:
      return ConnectEncoreIcons.deviceSpeaker;
    case DeviceType.tv:
    case DeviceType.stb:
      return ConnectEncoreIcons.deviceTv;
    case DeviceType.avr:
    case DeviceType.audioDongle:
      return ConnectEncoreIcons.deviceArm;
    case DeviceType.gameConsole:
      return ConnectEncoreIcons.gamesConsole;
    case DeviceType.castVideo:
    case DeviceType.castAudio:
      return isCastConnected
          ? ConnectEncoreIcons.chromecastConnected
          : ConnectEncoreIcons.chromecastDisconnected;
    case DeviceType.automobile:
      return ConnectEncoreIcons.deviceCar;
    case DeviceType.smartwatch:
      return ConnectEncoreIcons.watch;
    case DeviceType.unknown:
      return ConnectEncoreIcons.deviceSpeaker;
  }
}

/// Maps a local or device [OutputPeripheral] to Spotify's exact Encore vector
/// icon pair (`p199p/na7.java` + `p199p/byl1.java`).
EncoreIconPair resolvePeripheralEncoreIcon({
  required OutputPeripheralCategory? category,
  required OutputPeripheralConnectionType? connectionType,
  DeviceType? fallbackDeviceType,
}) {
  switch (category) {
    case OutputPeripheralCategory.headphones:
      return ConnectEncoreIcons.headphones;
    case OutputPeripheralCategory.speaker:
      return ConnectEncoreIcons.deviceSpeaker;
    case OutputPeripheralCategory.car:
      return ConnectEncoreIcons.deviceCar;
    case OutputPeripheralCategory.wearable:
      return ConnectEncoreIcons.watch;
    case OutputPeripheralCategory.glasses:
      return ConnectEncoreIcons.deviceSmartGlasses;
    case OutputPeripheralCategory.app:
      return ConnectEncoreIcons.deviceOther;
    case OutputPeripheralCategory.unknown:
    case null:
      break;
  }

  switch (connectionType) {
    case OutputPeripheralConnectionType.carProjected:
      return ConnectEncoreIcons.deviceCar;
    case OutputPeripheralConnectionType.bluetooth:
      return ConnectEncoreIcons.headphones;
    case OutputPeripheralConnectionType.wired:
      return ConnectEncoreIcons.headphones;
    case OutputPeripheralConnectionType.airplay:
      return ConnectEncoreIcons.airPlay;
    case OutputPeripheralConnectionType.builtInSpeaker:
      return switch (fallbackDeviceType) {
        final type? => resolveDeviceTypeEncoreIcon(type),
        null => ConnectEncoreIcons.deviceMobile,
      };
    case OutputPeripheralConnectionType.unknown:
    case null:
      return switch (fallbackDeviceType) {
        final type? => resolveDeviceTypeEncoreIcon(type),
        null => ConnectEncoreIcons.deviceOther,
      };
  }
}

/// Resolves the exact Encore vector icon pair for a [ConnectDevice],
/// accounting for speaker groups, Cast connection state, and active peripherals.
EncoreIconPair resolveConnectDeviceEncoreIcon(
  ConnectDevice device, {
  bool isConnected = false,
  bool preferDeviceIconOverPeripheral = false,
}) {
  if (device.isGroup) {
    return ConnectEncoreIcons.deviceMultispeaker;
  }
  if (isCastConnectDevice(device)) {
    return isConnected
        ? ConnectEncoreIcons.chromecastConnected
        : ConnectEncoreIcons.chromecastDisconnected;
  }
  if (!preferDeviceIconOverPeripheral) {
    if (device.outputPeripheral case final peripheral?) {
      if (peripheral.connectionType !=
          OutputPeripheralConnectionType.builtInSpeaker) {
        return resolvePeripheralEncoreIcon(
          category: peripheral.category,
          connectionType: peripheral.connectionType,
          fallbackDeviceType: device.type,
        );
      }
    }
  }
  return resolveDeviceTypeEncoreIcon(
    device.type,
    isGroup: device.isGroup,
    isCastConnected: isConnected,
  );
}

/// Zero-dependency CustomPainter widget rendering an [EncoreVectorIconData]
/// or [EncoreIconPair] with cached [Path] geometry and exact [PathFillType].
class ConnectEncoreIcon extends StatelessWidget {
  const ConnectEncoreIcon({
    super.key,
    required this.icon,
    required this.size,
    required this.color,
    this.semanticLabel,
  }) : iconPair = null;

  const ConnectEncoreIcon.pair({
    super.key,
    required this.iconPair,
    required this.size,
    required this.color,
    this.semanticLabel,
  }) : icon = null;

  final EncoreVectorIconData? icon;
  final EncoreIconPair? iconPair;
  final double size;
  final Color color;
  final String? semanticLabel;

  EncoreVectorIconData _resolveVectorData() {
    if (icon case final explicit?) {
      return explicit;
    }
    if (iconPair case final pair?) {
      return pair.resolveForSize(size);
    }
    throw StateError(
      'ConnectEncoreIcon requires either icon or iconPair to be non-null.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final vectorData = _resolveVectorData();
    final painted = RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: _EncoreVectorPainter(
          vectorData: vectorData,
          color: color,
        ),
      ),
    );
    if (semanticLabel case final label? when label.isNotEmpty) {
      return Semantics(
        label: label,
        child: painted,
      );
    }
    return painted;
  }
}

final class _EncoreVectorPainter extends CustomPainter {
  _EncoreVectorPainter({
    required this.vectorData,
    required this.color,
  });

  final EncoreVectorIconData vectorData;
  final Color color;

  static final Map<String, List<Path>> _parsedPathCache = <String, List<Path>>{};

  static List<Path> _resolveCachedPaths(EncoreVectorIconData data) {
    final existing = _parsedPathCache[data.id];
    if (existing != null) {
      return existing;
    }
    final built = <Path>[
      for (final spec in data.paths)
        _EncoreSvgPathParser(spec.pathData).parse(fillType: spec.fillType),
    ];
    final unmodifiable = UnmodifiableListView<Path>(built);
    _parsedPathCache[data.id] = unmodifiable;
    return unmodifiable;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || vectorData.viewportSize <= 0) {
      return;
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.save();
    canvas.scale(
      size.width / vectorData.viewportSize,
      size.height / vectorData.viewportSize,
    );
    final paths = _resolveCachedPaths(vectorData);
    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EncoreVectorPainter oldDelegate) {
    return oldDelegate.vectorData.id != vectorData.id ||
        oldDelegate.color != color;
  }
}

/// Complete zero-dependency SVG `pathData` parser supporting all Android
/// VectorDrawable / Compose PathBuilder commands (`M/L/H/V/C/S/Q/T/A/Z`,
/// upper & lower case, implicit command repetition, scientific notation,
/// compact arc flags, and [PathFillType]).
final class _EncoreSvgPathParser {
  _EncoreSvgPathParser(this.d);

  final String d;
  int _index = 0;

  Path parse({PathFillType fillType = PathFillType.nonZero}) {
    final path = Path()..fillType = fillType;
    var currentX = 0.0;
    var currentY = 0.0;
    var startX = 0.0;
    var startY = 0.0;
    var lastControlX = 0.0;
    var lastControlY = 0.0;
    var lastCmd = '';
    var prevCmd = '';

    while (_index < d.length) {
      _skipSeparators();
      if (_index >= d.length) {
        break;
      }

      final ch = d[_index];
      if (_isCommand(ch)) {
        lastCmd = ch;
        _index++;
      } else if (lastCmd == 'M') {
        lastCmd = 'L';
      } else if (lastCmd == 'm') {
        lastCmd = 'l';
      } else if (lastCmd.isEmpty) {
        throw FormatException('Unexpected token at index $_index in SVG path', d, _index);
      }

      switch (lastCmd) {
        case 'M':
          final x = _readDouble();
          final y = _readDouble();
          path.moveTo(x, y);
          currentX = x;
          currentY = y;
          startX = x;
          startY = y;
          lastControlX = x;
          lastControlY = y;
          prevCmd = 'M';
          break;
        case 'm':
          final dx = _readDouble();
          final dy = _readDouble();
          currentX += dx;
          currentY += dy;
          path.moveTo(currentX, currentY);
          startX = currentX;
          startY = currentY;
          lastControlX = currentX;
          lastControlY = currentY;
          prevCmd = 'm';
          break;
        case 'L':
          final x = _readDouble();
          final y = _readDouble();
          path.lineTo(x, y);
          currentX = x;
          currentY = y;
          lastControlX = x;
          lastControlY = y;
          prevCmd = 'L';
          break;
        case 'l':
          final dx = _readDouble();
          final dy = _readDouble();
          currentX += dx;
          currentY += dy;
          path.lineTo(currentX, currentY);
          lastControlX = currentX;
          lastControlY = currentY;
          prevCmd = 'l';
          break;
        case 'H':
          final x = _readDouble();
          path.lineTo(x, currentY);
          currentX = x;
          lastControlX = currentX;
          lastControlY = currentY;
          prevCmd = 'H';
          break;
        case 'h':
          final dx = _readDouble();
          currentX += dx;
          path.lineTo(currentX, currentY);
          lastControlX = currentX;
          lastControlY = currentY;
          prevCmd = 'h';
          break;
        case 'V':
          final y = _readDouble();
          path.lineTo(currentX, y);
          currentY = y;
          lastControlX = currentX;
          lastControlY = currentY;
          prevCmd = 'V';
          break;
        case 'v':
          final dy = _readDouble();
          currentY += dy;
          path.lineTo(currentX, currentY);
          lastControlX = currentX;
          lastControlY = currentY;
          prevCmd = 'v';
          break;
        case 'C':
          final x1 = _readDouble();
          final y1 = _readDouble();
          final x2 = _readDouble();
          final y2 = _readDouble();
          final x = _readDouble();
          final y = _readDouble();
          path.cubicTo(x1, y1, x2, y2, x, y);
          lastControlX = x2;
          lastControlY = y2;
          currentX = x;
          currentY = y;
          prevCmd = 'C';
          break;
        case 'c':
          final dx1 = _readDouble();
          final dy1 = _readDouble();
          final dx2 = _readDouble();
          final dy2 = _readDouble();
          final dx = _readDouble();
          final dy = _readDouble();
          final x1 = currentX + dx1;
          final y1 = currentY + dy1;
          final x2 = currentX + dx2;
          final y2 = currentY + dy2;
          final x = currentX + dx;
          final y = currentY + dy;
          path.cubicTo(x1, y1, x2, y2, x, y);
          lastControlX = x2;
          lastControlY = y2;
          currentX = x;
          currentY = y;
          prevCmd = 'c';
          break;
        case 'S':
          final x1 = 'CcSs'.contains(prevCmd)
              ? 2 * currentX - lastControlX
              : currentX;
          final y1 = 'CcSs'.contains(prevCmd)
              ? 2 * currentY - lastControlY
              : currentY;
          final x2 = _readDouble();
          final y2 = _readDouble();
          final x = _readDouble();
          final y = _readDouble();
          path.cubicTo(x1, y1, x2, y2, x, y);
          lastControlX = x2;
          lastControlY = y2;
          currentX = x;
          currentY = y;
          prevCmd = 'S';
          break;
        case 's':
          final x1 = 'CcSs'.contains(prevCmd)
              ? 2 * currentX - lastControlX
              : currentX;
          final y1 = 'CcSs'.contains(prevCmd)
              ? 2 * currentY - lastControlY
              : currentY;
          final dx2 = _readDouble();
          final dy2 = _readDouble();
          final dx = _readDouble();
          final dy = _readDouble();
          final x2 = currentX + dx2;
          final y2 = currentY + dy2;
          final x = currentX + dx;
          final y = currentY + dy;
          path.cubicTo(x1, y1, x2, y2, x, y);
          lastControlX = x2;
          lastControlY = y2;
          currentX = x;
          currentY = y;
          prevCmd = 's';
          break;
        case 'Q':
          final x1 = _readDouble();
          final y1 = _readDouble();
          final x = _readDouble();
          final y = _readDouble();
          path.quadraticBezierTo(x1, y1, x, y);
          lastControlX = x1;
          lastControlY = y1;
          currentX = x;
          currentY = y;
          prevCmd = 'Q';
          break;
        case 'q':
          final dx1 = _readDouble();
          final dy1 = _readDouble();
          final dx = _readDouble();
          final dy = _readDouble();
          final x1 = currentX + dx1;
          final y1 = currentY + dy1;
          final x = currentX + dx;
          final y = currentY + dy;
          path.quadraticBezierTo(x1, y1, x, y);
          lastControlX = x1;
          lastControlY = y1;
          currentX = x;
          currentY = y;
          prevCmd = 'q';
          break;
        case 'T':
          final x1 = 'QqTt'.contains(prevCmd)
              ? 2 * currentX - lastControlX
              : currentX;
          final y1 = 'QqTt'.contains(prevCmd)
              ? 2 * currentY - lastControlY
              : currentY;
          final x = _readDouble();
          final y = _readDouble();
          path.quadraticBezierTo(x1, y1, x, y);
          lastControlX = x1;
          lastControlY = y1;
          currentX = x;
          currentY = y;
          prevCmd = 'T';
          break;
        case 't':
          final x1 = 'QqTt'.contains(prevCmd)
              ? 2 * currentX - lastControlX
              : currentX;
          final y1 = 'QqTt'.contains(prevCmd)
              ? 2 * currentY - lastControlY
              : currentY;
          final dx = _readDouble();
          final dy = _readDouble();
          final x = currentX + dx;
          final y = currentY + dy;
          path.quadraticBezierTo(x1, y1, x, y);
          lastControlX = x1;
          lastControlY = y1;
          currentX = x;
          currentY = y;
          prevCmd = 't';
          break;
        case 'A':
        case 'a':
          final rx = _readDouble();
          final ry = _readDouble();
          final rotation = _readDouble();
          final largeArc = _readArcFlag();
          final sweep = _readArcFlag();
          var x = _readDouble();
          var y = _readDouble();
          if (lastCmd == 'a') {
            x += currentX;
            y += currentY;
          }
          path.arcToPoint(
            Offset(x, y),
            radius: Radius.elliptical(rx, ry),
            rotation: rotation,
            largeArc: largeArc,
            clockwise: sweep,
          );
          currentX = x;
          currentY = y;
          lastControlX = x;
          lastControlY = y;
          prevCmd = lastCmd;
          break;
        case 'Z':
        case 'z':
          path.close();
          currentX = startX;
          currentY = startY;
          lastControlX = startX;
          lastControlY = startY;
          prevCmd = 'z';
          break;
        default:
          throw FormatException(
            'Unsupported SVG path command "$lastCmd"',
            d,
            _index,
          );
      }
    }
    return path;
  }

  void _skipSeparators() {
    while (_index < d.length) {
      final c = d.codeUnitAt(_index);
      if (c == 32 || c == 44 || c == 10 || c == 13 || c == 9) {
        _index++;
      } else {
        break;
      }
    }
  }

  bool _isCommand(String ch) {
    return 'MLHVCSQTAZmlhvcsqtaz'.contains(ch);
  }

  bool _readArcFlag() {
    _skipSeparators();
    if (_index >= d.length) {
      throw FormatException('Unexpected end of SVG path reading arc flag', d, _index);
    }
    final ch = d[_index];
    if (ch == '0') {
      _index++;
      return false;
    }
    if (ch == '1') {
      _index++;
      return true;
    }
    throw FormatException('Invalid SVG arc flag "$ch"', d, _index);
  }

  double _readDouble() {
    _skipSeparators();
    if (_index >= d.length) {
      throw FormatException('Unexpected end of SVG path reading number', d, _index);
    }
    final start = _index;
    if (d[_index] == '-' || d[_index] == '+') {
      _index++;
    }
    var hasDot = false;
    var hasExponent = false;
    while (_index < d.length) {
      final c = d.codeUnitAt(_index);
      if (c >= 48 && c <= 57) {
        _index++;
      } else if (c == 46 && !hasDot && !hasExponent) {
        hasDot = true;
        _index++;
      } else if ((c == 101 || c == 69) && !hasExponent) {
        hasExponent = true;
        _index++;
        if (_index < d.length && (d[_index] == '-' || d[_index] == '+')) {
          _index++;
        }
      } else {
        break;
      }
    }
    final token = d.substring(start, _index);
    final parsed = double.tryParse(token);
    if (parsed == null) {
      throw FormatException('Invalid numeric token "$token" in SVG path', d, start);
    }
    return parsed;
  }
}
