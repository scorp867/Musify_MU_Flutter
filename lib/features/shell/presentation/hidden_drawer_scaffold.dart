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

  bool _isDrawerOpen = false;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    if (_isDrawerOpen) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() => _isDrawerOpen = !_isDrawerOpen);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Push the screen 83% (in the 80% - 85% range requested)
    final drawerWidth = screenWidth * 0.83;

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: AnimatedBuilder(
        animation: _curvedAnimation,
        builder: (context, child) {
          final progress = _curvedAnimation.value;
          final drawerOffset = -drawerWidth * (1.0 - progress);
          final mainOffset = drawerWidth * progress;
          final isOpen = progress > 0;

          return Stack(
            children: [
              // 1. Drawer Menu sliding in from left, pushing the screen
              Transform.translate(
                offset: Offset(drawerOffset, 0),
                child: SizedBox(
                  width: drawerWidth,
                  height: double.infinity,
                  child: const DrawerMenu(),
                ),
              ),

              // 2. Foreground MainScreen pushed to the right with edge shadow
              Transform.translate(
                offset: Offset(mainOffset, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: isOpen
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.5 * progress,
                              ),
                              blurRadius: 28,
                              offset: const Offset(-8, 0),
                            ),
                          ]
                        : const [],
                  ),
                  child: Stack(
                    children: [
                      child!,
                      // Scrim overlay: dims the remaining sliver of the main screen
                      IgnorePointer(
                        ignoring: !_isDrawerOpen,
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
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        child: RepaintBoundary(
          child: MainScreen(
            onMenuPressed: _toggleDrawer,
            isDrawerOpen: _isDrawerOpen,
            playbackController: widget.playbackController,
            modePersistence: widget.modePersistence,
            createHomeFeedBloc: widget.createHomeFeedBloc,
            createBrowseBloc: widget.createBrowseBloc,
            createLibraryBloc: widget.createLibraryBloc,
          ),
        ),
      ),
    );
  }
}
