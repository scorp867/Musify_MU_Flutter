import 'package:flutter/material.dart';

/// Delegate for a pinned sticky header in a [CustomScrollView].
///
/// Wraps any widget to make it stick at the top when scrolled past.
/// Used for filter chips (home) and search bar (browse).
class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final Color backgroundColor;

  StickyHeaderDelegate({
    required this.child,
    required this.height,
    this.backgroundColor = const Color(0xFF121212),
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: height,
      color: backgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant StickyHeaderDelegate oldDelegate) {
    return child != oldDelegate.child ||
        height != oldDelegate.height ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
