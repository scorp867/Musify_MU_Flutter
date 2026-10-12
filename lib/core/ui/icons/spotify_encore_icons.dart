import 'package:flutter/material.dart';

/// Exact 1:1 Vector paths extracted from Spotify APK drawable resources:
/// - encore_icon_sort_24.xml
/// - encore_icon_delete_24.xml
/// - encore_icon_add_to_queue_24.xml
/// - encore_icon_shuffle_24.xml
/// - encore_icon_repeat_24.xml
/// - encore_icon_repeat_once_24.xml
/// - encore_icon_time_24.xml
/// - encore_icon_queue_badge_24.xml
/// - encore_icon_pause_24.xml
/// - encore_icon_play_24.xml
class SpotifyEncoreIcons {
  SpotifyEncoreIcons._();

  static const String sortPath =
      'M21,8L3,8L3,6h18zM21,18L3,18v-2h18zM3,13h18v-2L3,11z';

  static const String deletePath =
      'M8,4L8,3a3,3 0,0 1,3 -3h2a3,3 0,0 1,3 3v1h6v2h-0.956l-1.878,14.261'
      'A2,2 0,0 1,17.183 22L6.817,22a2,2 0,0 1,-1.983 -1.739L2.956,6L2,6L2,4z'
      'M10,3v1h4L14,3a1,1 0,0 0,-1 -1h-2a1,1 0,0 0,-1 1'
      'M4.974,6l1.843,14h10.366l1.843,-14z';

  static const String addToQueuePath1 =
      'M10.929,5C10.976,4.673 11,4.34 11,4C11,3.66 10.976,3.327 10.929,3H18.55'
      'C20.483,3 22.05,4.567 22.05,6.5C22.05,8.433 20.483,10 18.55,10H7.607'
      'C8.453,9.491 9.182,8.807 9.745,8H18.55C19.378,8 20.05,7.328 20.05,6.5'
      'C20.05,5.672 19.378,5 18.55,5H10.929Z';
  static const String addToQueuePath2 = 'M3,16H21V14H3V16Z';
  static const String addToQueuePath3 = 'M3,22H21V20H3V22Z';
  static const String addToQueuePath4 = 'M5,3H8V5H5V8H3V5H0L0,3H3V0L5,0V3Z';

  static const String shufflePath1 =
      'M18.788,3.702a1,1 0,0 1,1.414 -1.414L23.914,6l-3.712,3.712'
      'a1,1 0,1 1,-1.414 -1.414L20.086,7h-1.518a5,5 0,0 0,-3.826 1.78'
      'l-7.346,8.73a7,7 0,0 1,-5.356 2.494H1v-2h1.04a5,5 0,0 0,3.826 -1.781'
      'l7.345,-8.73A7,7 0,0 1,18.569 5h1.518l-1.298,-1.298z';
  static const String shufflePath2 =
      'M18.788,14.289a1,1 0,0 0,0 1.414L20.086,17h-1.518'
      'a5,5 0,0 1,-3.826 -1.78l-1.403,-1.668 -1.306,1.554 1.178,1.4'
      'A7,7 0,0 0,18.568 19h1.518l-1.298,1.298a1,1 0,1 0,1.414 1.414'
      'L23.914,18l-3.712,-3.713a1,1 0,0 0,-1.414 0z'
      'M7.396,6.49l2.023,2.404 -1.307,1.553 -2.246,-2.67'
      'a5,5 0,0 0,-3.826 -1.78H1v-2h1.04A7,7 0,0 1,7.396 6.49';

  static const String repeatPath =
      'M6,2a5,5 0,0 0,-5 5v8a5,5 0,0 0,5 5h1v-2H6a3,3 0,0 1,-3 -3V7'
      'a3,3 0,0 1,3 -3h12a3,3 0,0 1,3 3v8a3,3 0,0 1,-3 3h-4.798'
      'l1.298,-1.298a1,1 0,1 0,-1.414 -1.414L9.373,19l3.713,3.712'
      'a1,1 0,0 0,1.414 -1.414L13.202,20H18a5,5 0,0 0,5 -5V7a5,5 0,0 0,-5 -5z';

  static const String repeatOncePath1 =
      'M1,7a5,5 0,0 1,5 -5h1v2L6,4a3,3 0,0 0,-3 3v8a3,3 0,0 0,3 3h1v2'
      'L6,20a5,5 0,0 1,-5 -5zM18,4h-1L17,2h1a5,5 0,0 1,5 5v8a5,5 0,0 1,-5 5'
      'h-7.202v-2L18,18a3,3 0,0 0,3 -3L21,7a3,3 0,0 0,-3 -3';
  static const String repeatOncePath2 =
      'M14.5,15.288a1,1 0,0 1,0 1.414L12.202,19l2.298,2.298'
      'a1,1 0,0 1,-1.414 1.415L9.373,19l3.713,-3.712a1,1 0,0 1,1.414 0'
      'M11.967,3.202l1.008,0.91H9.559v-1.4q1.316,-0.098 1.918,-0.49'
      'c0.602,-0.392 0.649,-0.649 0.742,-1.162h1.75V11h-2.002z';

  // Sleep Timer stopwatch icon (matching Spotify queue controls dock)
  static const String timePath1 =
      'M9,1a1,1 0,0 0,0 2h6a1,1 0,1 0,0 -2z'
      'M12,4.5a9.25,9.25 0,1 0,0 18.5a9.25,9.25 0,1 0,0 -18.5z'
      'M12,6.5a7.25,7.25 0,1 1,0 14.5a7.25,7.25 0,1 1,0 -14.5z';
  static const String timePath2 =
      'M12,8.5a1,1 0,0 1,1 1v4.25a1,1 0,1 1,-2 0V9.5a1,1 0,0 1,1 -1';

  // Extracted from encore_icon_queue_badge_24.xml
  static const String queueBadgePath1 =
      'M5,6.5A1.5,1.5 0,0 1,6.5 5h11a1.5,1.5 0,0 1,0 3h-11A1.5,1.5 0,0 1,5 6.5';
  static const String queueBadgePath2 =
      'M3,1a2,2 0,0 0,-2 2v18a2,2 0,0 0,2 2h18a2,2 0,0 0,2 -2L23,3a2,2 0,0 0,-2 -2z'
      'M20,15L4,15v-2h16z'
      'M20,20L4,20v-2h16z'
      'M6.5,3h11a3.5,3.5 0,1 1,0 7h-11a3.5,3.5 0,1 1,0 -7'
      'm0,2a1.5,1.5 0,1 0,0 3h11a1.5,1.5 0,0 0,0 -3z';

  // Extracted from encore_icon_pause_24.xml
  static const String pausePath =
      'M5.7,3a0.7,0.7 0,0 0,-0.7 0.7v16.6a0.7,0.7 0,0 0,0.7 0.7h2.6'
      'a0.7,0.7 0,0 0,0.7 -0.7L9,3.7a0.7,0.7 0,0 0,-0.7 -0.7z'
      'M15.7,3a0.7,0.7 0,0 0,-0.7 0.7v16.6a0.7,0.7 0,0 0,0.7 0.7h2.6'
      'a0.7,0.7 0,0 0,0.7 -0.7L19,3.7a0.7,0.7 0,0 0,-0.7 -0.7z';

  // Extracted from encore_icon_play_24.xml
  static const String playPath =
      'm7.05,3.606 l13.49,7.788a0.7,0.7 0,0 1,0 1.212L7.05,20.394'
      'A0.7,0.7 0,0 1,6 19.788V4.212a0.7,0.7 0,0 1,1.05 -0.606';

  static const String checkPath =
      'M1,12.5l7,7L23,4.5l-1.5,-1.5L8,16.5L2.5,11z';

  static const String crossPath =
      'M3.293,3.293a1,1 0,0 1,1.414 0L12,10.586l7.293,-7.293a1,1 0,1 1,1.414 1.414L13.414,12l7.293,7.293a1,1 0,0 1,-1.414 1.414L12,13.414l-7.293,7.293a1,1 0,0 1,-1.414 -1.414L10.586,12 3.293,4.707a1,1 0,0 1,0 -1.414';

  static const String chevronDownPath =
      'M2.793,8.043a1,1 0,0 1,1.414 0L12,15.836l7.793,-7.793a1,1 0,1 1,1.414 1.414L12,18.664 2.793,9.457a1,1 0,0 1,0 -1.414';
}

/// Widget that renders any extracted Spotify Encore SVG Path accurately.
class SpotifyIcon extends StatelessWidget {
  final List<String> paths;
  final Color color;
  final double size;

  const SpotifyIcon({
    super.key,
    required this.paths,
    this.color = Colors.white,
    this.size = 24.0,
  });

  factory SpotifyIcon.sort({Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(paths: const [SpotifyEncoreIcons.sortPath], color: color, size: size);

  factory SpotifyIcon.delete({Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(paths: const [SpotifyEncoreIcons.deletePath], color: color, size: size);

  factory SpotifyIcon.addToQueue({Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(
        paths: const [
          SpotifyEncoreIcons.addToQueuePath1,
          SpotifyEncoreIcons.addToQueuePath2,
          SpotifyEncoreIcons.addToQueuePath3,
          SpotifyEncoreIcons.addToQueuePath4,
        ],
        color: color,
        size: size,
      );

  factory SpotifyIcon.shuffle({Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(
        paths: const [
          SpotifyEncoreIcons.shufflePath1,
          SpotifyEncoreIcons.shufflePath2,
        ],
        color: color,
        size: size,
      );

  factory SpotifyIcon.repeat({Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(paths: const [SpotifyEncoreIcons.repeatPath], color: color, size: size);

  factory SpotifyIcon.repeatOnce({Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(
        paths: const [
          SpotifyEncoreIcons.repeatOncePath1,
          SpotifyEncoreIcons.repeatOncePath2,
        ],
        color: color,
        size: size,
      );

  factory SpotifyIcon.timer({Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(
        paths: const [
          SpotifyEncoreIcons.timePath1,
          SpotifyEncoreIcons.timePath2,
        ],
        color: color,
        size: size,
      );

  factory SpotifyIcon.queueBadge({Color color = Colors.white, double size = 14}) =>
      SpotifyIcon(
        paths: const [
          SpotifyEncoreIcons.queueBadgePath1,
          SpotifyEncoreIcons.queueBadgePath2,
        ],
        color: color,
        size: size,
      );

  factory SpotifyIcon.pause({
    Key? key,
    Color color = Colors.black,
    double size = 16,
  }) =>
      SpotifyIcon(
        key: key,
        paths: const [SpotifyEncoreIcons.pausePath],
        color: color,
        size: size,
      );

  factory SpotifyIcon.play({
    Key? key,
    Color color = Colors.black,
    double size = 16,
  }) =>
      SpotifyIcon(
        key: key,
        paths: const [SpotifyEncoreIcons.playPath],
        color: color,
        size: size,
      );

  factory SpotifyIcon.check({Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(paths: const [SpotifyEncoreIcons.checkPath], color: color, size: size);

  factory SpotifyIcon.cross({Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(paths: const [SpotifyEncoreIcons.crossPath], color: color, size: size);

  factory SpotifyIcon.chevronDown({Color color = Colors.white, double size = 24}) =>
      SpotifyIcon(paths: const [SpotifyEncoreIcons.chevronDownPath], color: color, size: size);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SvgPathPainter(paths: paths, color: color),
      ),
    );
  }
}

class _SvgPathPainter extends CustomPainter {
  final List<String> paths;
  final Color color;

  const _SvgPathPainter({required this.paths, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final pathData in paths) {
      final path = _parseSvgPath(pathData);
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SvgPathPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.paths != paths;
  }

  static final Map<String, Path> _cache = {};

  Path _parseSvgPath(String d) {
    if (_cache.containsKey(d)) return _cache[d]!;
    final path = _SvgPathParser(d).parse();
    _cache[d] = path;
    return path;
  }
}

/// Complete parser for Android Vector Drawable pathData format
class _SvgPathParser {
  final String d;
  int _index = 0;

  _SvgPathParser(this.d);

  Path parse() {
    final path = Path()..fillType = PathFillType.evenOdd;
    double currentX = 0;
    double currentY = 0;
    double startX = 0;
    double startY = 0;
    double lastControlX = 0;
    double lastControlY = 0;
    String lastCmd = '';
    String prevCmd = '';

    while (_index < d.length) {
      _skipWhitespaceAndCommas();
      if (_index >= d.length) break;

      final char = d[_index];
      if (_isCommand(char)) {
        lastCmd = char;
        _index++;
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
          lastCmd = 'L';
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
          lastCmd = 'l';
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
          lastControlX = x;
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
          lastControlY = y;
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
          final x2 = currentX + dx2;
          final y2 = currentY + dy2;
          path.cubicTo(
            currentX + dx1,
            currentY + dy1,
            x2,
            y2,
            currentX + dx,
            currentY + dy,
          );
          lastControlX = x2;
          lastControlY = y2;
          currentX += dx;
          currentY += dy;
          prevCmd = 'c';
          break;
        case 'S':
          final x1 = ('CcSs'.contains(prevCmd))
              ? 2 * currentX - lastControlX
              : currentX;
          final y1 = ('CcSs'.contains(prevCmd))
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
          final x1 = ('CcSs'.contains(prevCmd))
              ? 2 * currentX - lastControlX
              : currentX;
          final y1 = ('CcSs'.contains(prevCmd))
              ? 2 * currentY - lastControlY
              : currentY;
          final dx2 = _readDouble();
          final dy2 = _readDouble();
          final dx = _readDouble();
          final dy = _readDouble();
          final x2 = currentX + dx2;
          final y2 = currentY + dy2;
          path.cubicTo(x1, y1, x2, y2, currentX + dx, currentY + dy);
          lastControlX = x2;
          lastControlY = y2;
          currentX += dx;
          currentY += dy;
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
          path.quadraticBezierTo(x1, y1, currentX + dx, currentY + dy);
          lastControlX = x1;
          lastControlY = y1;
          currentX += dx;
          currentY += dy;
          prevCmd = 'q';
          break;
        case 'A':
        case 'a':
          final rx = _readDouble();
          final ry = _readDouble();
          final angle = _readDouble();
          final largeArc = _readDouble() != 0;
          final sweep = _readDouble() != 0;
          var x = _readDouble();
          var y = _readDouble();
          if (lastCmd == 'a') {
            x += currentX;
            y += currentY;
          }
          path.arcToPoint(
            Offset(x, y),
            radius: Radius.elliptical(rx, ry),
            rotation: angle,
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
          _index++;
          break;
      }
    }
    return path;
  }

  void _skipWhitespaceAndCommas() {
    while (_index < d.length &&
        (d[_index] == ' ' ||
            d[_index] == ',' ||
            d[_index] == '\n' ||
            d[_index] == '\r' ||
            d[_index] == '\t')) {
      _index++;
    }
  }

  bool _isCommand(String char) {
    return 'MLHVCSQTAZmlhvcsqtaz'.contains(char);
  }

  double _readDouble() {
    _skipWhitespaceAndCommas();
    if (_index >= d.length) return 0;
    final start = _index;
    if (d[_index] == '-' || d[_index] == '+') {
      _index++;
    }
    var hasDot = false;
    while (_index < d.length) {
      final c = d[_index];
      if (c == '.') {
        if (hasDot) break;
        hasDot = true;
        _index++;
      } else if (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) {
        _index++;
      } else {
        break;
      }
    }
    final str = d.substring(start, _index);
    return double.tryParse(str) ?? 0;
  }
}
