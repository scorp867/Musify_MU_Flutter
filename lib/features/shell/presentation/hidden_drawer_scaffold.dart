import 'package:flutter/material.dart';
import 'package:musify_mu/app/di/mode_persistence.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/features/browse/application/browse_bloc.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/library/application/library_bloc.dart';
import 'package:musify_mu/features/shell/presentation/main_screen.dart';
import 'package:musify_mu/features/shell/presentation/widgets/drawer_menu.dart';

class HiddenDrawerScaffold extends StatefulWidget {
  final PlaybackController? playbackController;
  final ModePersistence modePersistence;
  final HomeFeedBloc Function() createHomeFeedBloc;
  final BrowseBloc Function() createBrowseBloc;
  final LibraryBloc Function(String userId) createLibraryBloc;

  const HiddenDrawerScaffold({
    super.key,
    this.playbackController,
    required this.modePersistence,
    required this.createHomeFeedBloc,
    required this.createBrowseBloc,
    required this.createLibraryBloc,
  });

  @override
  State<HiddenDrawerScaffold> createState() => _HiddenDrawerScaffoldState();
}

class _HiddenDrawerScaffoldState extends State<HiddenDrawerScaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _curvedAnimation;

  late Widget _mainScreen;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _initMainScreen();
  }

  void _initMainScreen() {
    _mainScreen = RepaintBoundary(
      key: const ValueKey('hidden_drawer_main_screen'),
      child: MainScreen(
        onMenuPressed: _toggleDrawer,
        isDrawerOpen: false,
        playbackController: widget.playbackController,
        modePersistence: widget.modePersistence,
        createHomeFeedBloc: widget.createHomeFeedBloc,
        createBrowseBloc: widget.createBrowseBloc,
        createLibraryBloc: widget.createLibraryBloc,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant HiddenDrawerScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playbackController != oldWidget.playbackController ||
        widget.modePersistence != oldWidget.modePersistence) {
      _initMainScreen();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    if (_animationController.status == AnimationStatus.forward ||
        _animationController.status == AnimationStatus.completed) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Push the screen 83% (in the 80% - 85% range requested)
    final drawerWidth = screenWidth * 0.83;

    final cachedDrawer = RepaintBoundary(
      child: SizedBox(
        width: drawerWidth,
        height: double.infinity,
        child: const DrawerMenu(),
      ),
    );

    return AnimatedBuilder(
      animation: _curvedAnimation,
      builder: (context, _) {
        final progress = _curvedAnimation.value;
        final isDrawerOpen = progress > 0.0;
        final drawerOffset = -drawerWidth * (1.0 - progress);
        final mainOffset = drawerWidth * progress;

        return PopScope(
          canPop: !isDrawerOpen,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && isDrawerOpen) {
              _toggleDrawer();
            }
          },
          child: Material(
            color: const Color(0xFF1E293B),
            child: Stack(
              children: [
                // 1. Drawer Menu sliding in from left, pushing the screen
                Transform.translate(
                  offset: Offset(drawerOffset, 0),
                  child: cachedDrawer,
                ),

                // 2. Foreground MainScreen pushed to the right with edge shadow
                Transform.translate(
                  offset: Offset(mainOffset, 0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Child 0 is ALWAYS _mainScreen: position never changes,
                      // ensuring Flutter NEVER deactivates or unmounts the element tree.
                      _mainScreen,

                      // Child 1 is ALWAYS the edge drop-shadow along the left border
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: -24,
                        width: 24,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: progress.clamp(0.0, 1.0),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [
                                    Color(0x66000000),
                                    Color(0x00000000),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Child 2 is ALWAYS the scrim overlay dims the main screen
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: progress == 0.0,
                          child: GestureDetector(
                            onTap: _toggleDrawer,
                            behavior: HitTestBehavior.opaque,
                            child: ColoredBox(
                              color: Colors.black.withValues(
                                alpha: 0.70 * progress,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
