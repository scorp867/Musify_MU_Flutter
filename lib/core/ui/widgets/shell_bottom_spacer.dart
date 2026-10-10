import 'package:flutter/material.dart';

/// A dynamic shell spacer that provides bottom clearance for scrollable views
/// rendered inside an edge-to-edge [Scaffold] with [Scaffold.extendBody] set to true.
///
/// In Flutter, when [Scaffold.extendBody] is true, the scaffold automatically calculates
/// the combined height of all active bottom widgets (e.g., MiniPlayer, AppBottomNavigation,
/// and NetworkStatusBottomBar) plus system navigation insets, and exposes it in
/// [MediaQuery.paddingOf(context).bottom].
///
/// This spacer relies on Flutter's built-in calculation as the single source of truth,
/// adding [additionalHeight] (default: 16.0dp) for aesthetic breathing space.
class ShellBottomSpacer extends StatelessWidget {
  final bool hasBottomNav;
  final double additionalHeight;

  const ShellBottomSpacer({
    super.key,
    this.hasBottomNav = true,
    this.additionalHeight = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = hasBottomNav
        ? MediaQuery.paddingOf(context).bottom
        : MediaQuery.viewPaddingOf(context).bottom;

    final targetHeight = bottomPadding + additionalHeight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: targetHeight,
    );
  }
}

/// Sliver variant of [ShellBottomSpacer] for use inside [CustomScrollView.slivers].
class SliverShellBottomSpacer extends StatelessWidget {
  final bool hasBottomNav;
  final double additionalHeight;

  const SliverShellBottomSpacer({
    super.key,
    this.hasBottomNav = true,
    this.additionalHeight = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ShellBottomSpacer(
        hasBottomNav: hasBottomNav,
        additionalHeight: additionalHeight,
      ),
    );
  }
}
