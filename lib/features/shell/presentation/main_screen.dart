import 'package:flutter/material.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/ui/animations/mode_transition.dart';
import 'package:musify_mu/features/home/presentation/home_tab.dart';
import 'package:musify_mu/features/player/presentation/widgets/mini_player.dart';
import 'package:musify_mu/features/shell/presentation/widgets/bottom_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback onMenuPressed;
  final bool isDrawerOpen;
  final PlaybackController? playbackController;

  const MainScreen({
    super.key,
    required this.onMenuPressed,
    required this.isDrawerOpen,
    this.playbackController,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _kModeKey = 'app_mode_online';

  int _currentIndex = 0;
  final GlobalKey _iconKey = GlobalKey();
  bool _isOnlineMode = false;
  bool _modeLoaded = false;
  bool _iconVisible = true;

  @override
  void initState() {
    super.initState();
    _loadSavedMode();
  }

  Future<void> _loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getBool(_kModeKey);
    if (savedMode != null && mounted) {
      setState(() {
        _isOnlineMode = savedMode;
      });
    }
    if (mounted) {
      setState(() => _modeLoaded = true);
    }
  }

  Future<void> _saveMode(bool isOnline) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kModeKey, isOnline);
  }

  void _toggleMode() {
    final targetMode = _isOnlineMode ? 'Offline' : 'Online';

    ModeTransition.start(
      context,
      iconKey: _iconKey,
      targetModeName: targetMode,
      isCurrentlyFlipped: !_isOnlineMode,
      onHideOriginal: () {
        setState(() => _iconVisible = false);
      },
      onShowOriginal: () {
        if (mounted) setState(() => _iconVisible = true);
      },
      onReady: () async {
        setState(() {
          _isOnlineMode = !_isOnlineMode;
        });
        await _saveMode(_isOnlineMode);
        await Future.delayed(const Duration(milliseconds: 100));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show nothing until the saved mode preference is loaded.
    if (!_modeLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: SizedBox.shrink(),
      );
    }

    return PopScope(
      canPop: _currentIndex == 0 && !widget.isDrawerOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (widget.isDrawerOpen) {
          widget.onMenuPressed();
        } else if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                HomeTab(
                  isOnlineMode: _isOnlineMode,
                  onMenuPressed: widget.onMenuPressed,
                  onToggleMode: _toggleMode,
                  iconKey: _iconKey,
                  iconVisible: _iconVisible,
                  playbackController: widget.playbackController,
                ),
                const Center(
                  child: Text(
                    'Search',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
                const Center(
                  child: Text(
                    'Library',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
              ],
            ),
            if (widget.isDrawerOpen)
              GestureDetector(
                onTap: widget.onMenuPressed,
                child: Container(color: Colors.transparent),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(controller: widget.playbackController),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}
