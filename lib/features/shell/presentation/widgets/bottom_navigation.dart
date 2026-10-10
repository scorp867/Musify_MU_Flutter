import 'package:flutter/material.dart';

/// A sleek Spotify-authentic navigation bar featuring a translucent gradient fade,
/// refined icons, and compact labels.
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isNetworkBarVisible;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isNetworkBarVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomPadding = isNetworkBarVisible ? 4.0 : (bottomInset + 4.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00000000), // Pure transparent top for smooth content bleed
            Color(0xCC000000), // 80% black mid
            Color(0xFF000000), // Solid black bottom
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.fromLTRB(16, 2, 16, bottomPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
              _buildNavItem(
                index: 0,
                label: 'Home',
                activeIcon: const Icon(Icons.home_filled, size: 24, color: Colors.white),
                inactiveIcon: const Icon(Icons.home_outlined, size: 24, color: Color(0xFFB3B3B3)),
              ),
              _buildNavItem(
                index: 1,
                label: 'Search',
                activeIcon: const Icon(Icons.search_rounded, size: 24, color: Colors.white),
                inactiveIcon: const Icon(Icons.search_rounded, size: 24, color: Color(0xFFB3B3B3)),
              ),
              _buildNavItem(
                index: 2,
                label: 'Your Library',
                activeIcon: const _SpotifyLibraryIcon(color: Colors.white, isFilled: true),
                inactiveIcon: const _SpotifyLibraryIcon(color: Color(0xFFB3B3B3), isFilled: false),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required Widget activeIcon,
    required Widget inactiveIcon,
  }) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Center(
                  child: isSelected ? activeIcon : inactiveIcon,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFFB3B3B3),
                  letterSpacing: 0.1,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for Spotify's signature 3-book Library icon.
class _SpotifyLibraryIcon extends StatelessWidget {
  final Color color;
  final bool isFilled;

  const _SpotifyLibraryIcon({
    required this.color,
    required this.isFilled,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _SpotifyLibraryPainter(color: color, isFilled: isFilled),
    );
  }
}

class _SpotifyLibraryPainter extends CustomPainter {
  final Color color;
  final bool isFilled;

  _SpotifyLibraryPainter({required this.color, required this.isFilled});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const barWidth = 3.2;
    const barHeight = 16.0;
    const top = 4.0;

    // First vertical book
    final r1 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3.5, top, barWidth, barHeight),
      const Radius.circular(1.4),
    );
    canvas.drawRRect(r1, paint);

    // Second vertical book
    final r2 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(9.5, top, barWidth, barHeight),
      const Radius.circular(1.4),
    );
    canvas.drawRRect(r2, paint);

    // Third tilted book (tilted ~14 degrees to the right)
    canvas.save();
    canvas.translate(17.5, top + (barHeight / 2));
    canvas.rotate(0.24);
    final r3 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-barWidth / 2, -barHeight / 2, barWidth, barHeight),
      const Radius.circular(1.4),
    );
    canvas.drawRRect(r3, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotifyLibraryPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isFilled != isFilled;
}
