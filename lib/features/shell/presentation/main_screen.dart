import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/ui/animations/mode_transition.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/browse/application/browse_bloc.dart';
import 'package:musify_mu/features/browse/data/browse_repository.dart';
import 'package:musify_mu/features/browse/presentation/browse_view.dart';
import 'package:musify_mu/features/browse/presentation/offline_browse_view.dart';
import 'package:musify_mu/features/home/presentation/home_tab.dart';
import 'package:musify_mu/features/library/application/library_bloc.dart';
import 'package:musify_mu/features/library/data/library_repository.dart';
import 'package:musify_mu/features/library/presentation/library_view.dart';
import 'package:musify_mu/features/library/presentation/offline_library_view.dart';
import 'package:musify_mu/features/player/presentation/widgets/mini_player.dart';
import 'package:musify_mu/features/shell/presentation/widgets/bottom_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musify_mu/app/di/injection.dart';

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

  /// Tracks which tabs have been visited so we only build them on first visit.
  /// This prevents e.g. browsita from firing before casita.
  final Set<int> _visitedTabs = {0}; // Home tab is always "visited"

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

  bool _isTransitioning = false;

  void _toggleMode() {
    if (_isTransitioning) return;
    _isTransitioning = true;

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
        _isTransitioning = false;
        if (mounted) setState(() => _iconVisible = true);
      },
      onReady: () async {
        if (!mounted) return;
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
                if (_visitedTabs.contains(1))
                  _BrowseTab(
                    isOnlineMode: _isOnlineMode,
                    onMenuPressed: widget.onMenuPressed,
                    onToggleMode: _toggleMode,
                    playbackController: widget.playbackController,
                  )
                else
                  const SizedBox.shrink(),
                if (_visitedTabs.contains(2))
                  _LibraryTab(
                    isOnlineMode: _isOnlineMode,
                    onMenuPressed: widget.onMenuPressed,
                    onToggleMode: _toggleMode,
                    playbackController: widget.playbackController,
                  )
                else
                  const SizedBox.shrink(),
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
          onTap: (index) => setState(() {
            _currentIndex = index;
            _visitedTabs.add(index);
          }),
        ),
      ),
    );
  }
}

/// Browse tab -- online shows Spotify categories, offline shows local file search.
class _BrowseTab extends StatelessWidget {
  final bool isOnlineMode;
  final VoidCallback onMenuPressed;
  final VoidCallback onToggleMode;
  final PlaybackController? playbackController;

  const _BrowseTab({
    required this.isOnlineMode,
    required this.onMenuPressed,
    required this.onToggleMode,
    this.playbackController,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnlineMode) {
      return OfflineBrowseView(
        onMenuPressed: onMenuPressed,
        onToggleMode: onToggleMode,
        playbackController: playbackController,
      );
    }

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(
              child: Text(
                'Search',
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
            ),
          );
        }

        return BlocProvider(
          create: (_) => BrowseBloc(repository: getIt<BrowseRepository>())
            ..add(const BrowseLoadRequested()),
          child: Scaffold(
            backgroundColor: const Color(0xFF121212),
            body: SafeArea(
              bottom: false,
              child: BrowseView(
                onMenuPressed: onMenuPressed,
                onToggleMode: onToggleMode,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Library tab -- online shows Spotify playlists, offline shows local music library.
class _LibraryTab extends StatelessWidget {
  final bool isOnlineMode;
  final VoidCallback onMenuPressed;
  final VoidCallback onToggleMode;
  final PlaybackController? playbackController;

  const _LibraryTab({
    required this.isOnlineMode,
    required this.onMenuPressed,
    required this.onToggleMode,
    this.playbackController,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnlineMode) {
      return OfflineLibraryView(
        onMenuPressed: onMenuPressed,
        onToggleMode: onToggleMode,
        playbackController: playbackController,
      );
    }

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(
              child: Text(
                'Your Library',
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
            ),
          );
        }

        final userId = authState.user.id;

        return BlocProvider(
          create: (_) => LibraryBloc(
                repository: getIt<LibraryRepository>(param1: userId),
              )..add(const LibraryLoadRequested()),
          child: Scaffold(
            backgroundColor: const Color(0xFF121212),
            body: SafeArea(
              bottom: false,
              child: LibraryView(
                onMenuPressed: onMenuPressed,
                onToggleMode: onToggleMode,
              ),
            ),
          ),
        );
      },
    );
  }
}
