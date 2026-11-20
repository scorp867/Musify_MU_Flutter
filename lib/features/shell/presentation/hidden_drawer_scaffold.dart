import 'package:flutter/material.dart';
import 'package:musify_mu/app/di/mode_persistence.dart';
import 'package:musify_mu/core/ubi/domain/logging/ubi_logger.dart';
import 'package:musify_mu/features/browse/application/browse_bloc.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/library/application/library_bloc.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_bloc.dart';
import 'package:musify_mu/features/shell/presentation/main_screen.dart';
import 'package:musify_mu/features/shell/presentation/widgets/drawer_menu.dart';

/// Root drawer container forwarding composition-root dependencies (including
/// Spotify Connect `ConnectMobiusController`, `p199p/yrq.java`) to [MainScreen].
class HiddenDrawerScaffold extends StatefulWidget {
  final ModePersistence modePersistence;
  final HomeFeedBloc Function() createHomeFeedBloc;
  final BrowseBloc Function() createBrowseBloc;
  final LibraryBloc Function(String userId) createLibraryBloc;
  final ConnectMobiusController? connectController;
  final PlayerQueueMobiusController? queueBloc;
  final ConnectOutputStatusPolicy? outputStatusPolicy;
  final UbiLogger? ubiLogger;

  const HiddenDrawerScaffold({
    super.key,
    required this.modePersistence,
    required this.createHomeFeedBloc,
    required this.createBrowseBloc,
    required this.createLibraryBloc,
    this.connectController,
    this.queueBloc,
    this.outputStatusPolicy,
    this.ubiLogger,
  });

  @override
  State<HiddenDrawerScaffold> createState() => _HiddenDrawerScaffoldState();
}

class _HiddenDrawerScaffoldState extends State<HiddenDrawerScaffold>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _curvedAnimation;
  Widget? _mainScreen;

  AnimationController get _requireAnimationController {
    if (_animationController case final ctrl?) {
      return ctrl;
    }
    throw StateError('HiddenDrawerScaffold AnimationController not initialized');
  }

  Animation<double> get _requireCurvedAnimation {
    if (_curvedAnimation case final anim?) {
      return anim;
    }
    throw StateError('HiddenDrawerScaffold CurvedAnimation not initialized');
  }

  Widget get _requireMainScreen {
    if (_mainScreen case final screen?) {
      return screen;
    }
    throw StateError('HiddenDrawerScaffold MainScreen not initialized');
  }

  static double _boundUnitInterval(double value) {
    if (!value.isFinite || value <= 0.0) {
      return 0.0;
    }
    if (value >= 1.0) {
      return 1.0;
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _animationController = ctrl;

    _curvedAnimation = CurvedAnimation(
      parent: ctrl,
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
        modePersistence: widget.modePersistence,
        createHomeFeedBloc: widget.createHomeFeedBloc,
        createBrowseBloc: widget.createBrowseBloc,
        createLibraryBloc: widget.createLibraryBloc,
        connectController: widget.connectController,
        queueBloc: widget.queueBloc,
        outputStatusPolicy: widget.outputStatusPolicy,
        ubiLogger: widget.ubiLogger,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant HiddenDrawerScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.modePersistence != oldWidget.modePersistence ||
        widget.connectController != oldWidget.connectController ||
        widget.queueBloc != oldWidget.queueBloc ||
        widget.outputStatusPolicy != oldWidget.outputStatusPolicy ||
        widget.ubiLogger != oldWidget.ubiLogger) {
      _initMainScreen();
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _animationController = null;
    _curvedAnimation = null;
    super.dispose();
  }

  void _toggleDrawer() {
    final ctrl = _requireAnimationController;
    if (ctrl.status == AnimationStatus.forward ||
        ctrl.status == AnimationStatus.completed) {
      ctrl.reverse();
    } else {
      ctrl.forward();
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

    final curvedAnimation = _requireCurvedAnimation;
    final mainScreen = _requireMainScreen;

    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, _) {
        final progress = _boundUnitInterval(curvedAnimation.value);
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
                      // Child 0 is ALWAYS mainScreen: position never changes,
                      // ensuring Flutter NEVER deactivates or unmounts the element tree.
                      mainScreen,

                      // Child 1 is ALWAYS the edge drop-shadow along the left border
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: -24,
                        width: 24,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: progress,
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
