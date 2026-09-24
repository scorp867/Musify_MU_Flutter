import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/ui/animations/mode_transition.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/data/spotify_client_token.dart';
import 'package:musify_mu/features/auth/data/spotify_token_refresher.dart';
import 'package:musify_mu/features/auth/data/spotify_token_store.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/browse/application/browse_bloc.dart';
import 'package:musify_mu/features/browse/data/browse_repository.dart';
import 'package:musify_mu/features/browse/presentation/browse_view.dart';
import 'package:musify_mu/features/home/presentation/home_tab.dart';
import 'package:musify_mu/features/player/presentation/widgets/mini_player.dart';
import 'package:musify_mu/features/shell/presentation/widgets/bottom_navigation.dart';
import 'package:musify_mu/features/spotify_client/spotify_client.dart';
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
                // Lazy: only build when first visited
                if (_visitedTabs.contains(1))
                  _BrowseTab()
                else
                  const SizedBox.shrink(),
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
          onTap: (index) => setState(() {
            _currentIndex = index;
            _visitedTabs.add(index);
          }),
        ),
      ),
    );
  }
}

/// Browse tab that wires up the BrowseBloc when authenticated.
class _BrowseTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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

        final tokenStore = SpotifyTokenStore();
        final tokenRefresher = SpotifyTokenRefresher(tokenStore: tokenStore);
        final clientTokenFetcher = SpotifyClientTokenFetcher(tokenStore);

        final spotifyClient = SpotifyClient(
          tokenStore: tokenStore,
          tokenRefresher: tokenRefresher,
          clientTokenFetcher: clientTokenFetcher,
        );

        final browseRepository = BrowseRepository(client: spotifyClient);

        return BlocProvider(
          create: (_) => BrowseBloc(repository: browseRepository)
            ..add(const BrowseLoadRequested()),
          child: const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: SafeArea(
              bottom: false,
              child: BrowseView(),
            ),
          ),
        );
      },
    );
  }
}
