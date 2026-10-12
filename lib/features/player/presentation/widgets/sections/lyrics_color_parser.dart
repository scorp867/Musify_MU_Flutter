import 'dart:ui';

/// Parses signed 32-bit protobuf color integer into a Flutter [Color].
///
/// In Spotify Android's protobuf responses (`ColorData`), color values are stored
/// as signed 32-bit integers (e.g. -8686235 for 0xFF7B7565).
Color parseProtoColor(int rawValue, {Color defaultColor = const Color(0xFF242424)}) {
  if (rawValue == 0) return defaultColor;
  final argb = rawValue & 0xFFFFFFFF;
  final fullArgb = (argb & 0xFF000000) == 0 ? (0xFF000000 | argb) : argb;
  return Color(fullArgb);
}
