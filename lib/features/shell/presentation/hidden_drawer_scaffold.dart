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
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _radiusAnimation;

  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final curve = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(curve);
    _slideAnimation = Tween<double>(begin: 0.0, end: 250.0).animate(curve);
    _radiusAnimation = Tween<double>(begin: 0.0, end: 24.0).animate(curve);
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
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Stack(
        children: [
          const DrawerMenu(),
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_slideAnimation.value, 0),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      _radiusAnimation.value,
                    ),
                    child: child,
                  ),
                ),
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
        ],
      ),
    );
  }
}
