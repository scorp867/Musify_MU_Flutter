import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/network/status/bloc/network_status_bloc.dart';
import 'package:musify_mu/app/di/mode_persistence.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/ui/animations/mode_transition.dart';
import 'package:musify_mu/core/ui/widgets/app_header.dart';
import 'package:musify_mu/core/ui/widgets/auth_gated_bloc_provider.dart';
import 'package:musify_mu/core/ui/widgets/connect_spotify_prompt.dart';
import 'package:musify_mu/features/browse/application/browse_bloc.dart';
import 'package:musify_mu/features/browse/presentation/browse_view.dart';
import 'package:musify_mu/features/browse/presentation/offline_browse_view.dart';
import 'package:musify_mu/features/home/presentation/home_tab.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/library/application/library_bloc.dart';
import 'package:musify_mu/features/library/presentation/library_view.dart';
import 'package:musify_mu/features/library/presentation/offline_library_view.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_bloc.dart';
import 'package:musify_mu/features/player/data/queue/context_track_extensions.dart';
import 'package:musify_mu/features/player/presentation/widgets/mini_player.dart';
import 'package:musify_mu/features/shell/presentation/widgets/bottom_navigation.dart';
import 'package:musify_mu/features/shell/presentation/widgets/network_status_bottom_bar.dart';

/// InheritedWidget propagating active tab index and online mode state
/// to all nested tab Navigators without breaking stateful routes.
class _MainTabScope extends InheritedWidget {
  final int currentIndex;
  final bool isOnlineMode;
  final bool isDrawerOpen;
  final bool iconVisible;
  final GlobalKey iconKey;

  const _MainTabScope({
    required this.currentIndex,
    required this.isOnlineMode,
    required this.isDrawerOpen,
    required this.iconVisible,
    required this.iconKey,
    required super.child,
  });

  static _MainTabScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MainTabScope>();

  @override
  bool updateShouldNotify(_MainTabScope oldWidget) =>
      currentIndex != oldWidget.currentIndex ||
      isOnlineMode != oldWidget.isOnlineMode ||
      isDrawerOpen != oldWidget.isDrawerOpen ||
      iconVisible != oldWidget.iconVisible;
}

class MainScreen extends StatefulWidget {
  final VoidCallback onMenuPressed;
  final bool isDrawerOpen;
  final ModePersistence modePersistence;
  final HomeFeedBloc Function() createHomeFeedBloc;
  final BrowseBloc Function() createBrowseBloc;
  final LibraryBloc Function(String userId) createLibraryBloc;

  const MainScreen({
    super.key,
    required this.onMenuPressed,
    required this.isDrawerOpen,
    required this.modePersistence,
    required this.createHomeFeedBloc,
    required this.createBrowseBloc,
    required this.createLibraryBloc,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey _iconKey = GlobalKey();
  bool _isOnlineMode = false;
  bool _modeLoaded = false;
  bool _iconVisible = true;

  /// Dedicated navigator keys for nested tab routing (Option B).
  /// Enables playlist and detail screens to push within the active tab,
  /// extending behind the persistent MiniPlayer and bottom navigation bar.
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  /// Tracks which tabs have been visited so we only build them on first visit.
  /// This prevents e.g. browsita from firing before casita.
  final Set<int> _visitedTabs = {0}; // Home tab is always "visited"

  @override
  void initState() {
    super.initState();
    _loadSavedMode();
  }

  Future<void> _loadSavedMode() async {
    final savedMode = await widget.modePersistence.loadMode();
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
    await widget.modePersistence.saveMode(isOnline);
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
        for (final key in _navigatorKeys) {
          key.currentState?.popUntil((route) => route.isFirst);
        }
        setState(() {
          _isOnlineMode = !_isOnlineMode;
          _visitedTabs
            ..clear()
            ..add(_currentIndex);
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          if (widget.isDrawerOpen) {
            widget.onMenuPressed();
            return;
          }

          final currentNav = _navigatorKeys[_currentIndex].currentState;
          if (currentNav != null && currentNav.canPop()) {
            currentNav.pop();
            return;
          }

          if (_currentIndex != 0) {
            setState(() {
              _currentIndex = 0;
              _visitedTabs.add(0);
            });
          } else {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          extendBody: true,
          body: _MainTabScope(
            currentIndex: _currentIndex,
            isOnlineMode: _isOnlineMode,
            isDrawerOpen: widget.isDrawerOpen,
            iconVisible: _iconVisible,
            iconKey: _iconKey,
            child: Stack(
              children: [
                IndexedStack(
                  index: _currentIndex,
                  children: [
                    if (_visitedTabs.contains(0))
                      Navigator(
                        key: _navigatorKeys[0],
                        onGenerateRoute: (settings) => MaterialPageRoute<void>(
                          settings: settings,
                          builder: (context) => _HomeTabWrapper(
                            onMenuPressed: widget.onMenuPressed,
                            onToggleMode: _toggleMode,
                            createHomeFeedBloc: widget.createHomeFeedBloc,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (_visitedTabs.contains(1))
                      Navigator(
                        key: _navigatorKeys[1],
                        onGenerateRoute: (settings) => MaterialPageRoute<void>(
                          settings: settings,
                          builder: (context) => _BrowseTabWrapper(
                            onMenuPressed: widget.onMenuPressed,
                            onToggleMode: _toggleMode,
                            createBrowseBloc: widget.createBrowseBloc,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (_visitedTabs.contains(2))
                      Navigator(
                        key: _navigatorKeys[2],
                        onGenerateRoute: (settings) => MaterialPageRoute<void>(
                          settings: settings,
                          builder: (context) => _LibraryTabWrapper(
                            onMenuPressed: widget.onMenuPressed,
                            onToggleMode: _toggleMode,
                            createLibraryBloc: widget.createLibraryBloc,
                          ),
                        ),
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
              ],
            ),
          ),
          bottomNavigationBar: BlocBuilder<NetworkStatusBloc, NetworkStatusState>(
            builder: (context, networkState) {
              final isNetworkVisible = networkState.isVisible;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    child: BlocBuilder<PlayerQueueBloc, PlayerQueueState>(
                      builder: (context, queueState) {
                        final track = queueState.nowPlaying;
                        final bloc = context.read<PlayerQueueBloc>();
                        return MiniPlayer(
                          title: (track?.title.isNotEmpty == true)
                              ? track!.title
                              : 'Starboy',
                          artist: (track?.artist.isNotEmpty == true)
                              ? track!.artist
                              : 'The Weeknd, Daft Punk',
                          imageUrl: track?.imageUrl,
                          songId: track?.songId,
                          isPlaying: queueState.isPlaying,
                          queueBloc: bloc,
                          currentTrack: track,
                          colorService: context.read<ColorExtractionService>(),
                        );
                      },
                    ),
                  ),
                  RepaintBoundary(
                    child: AppBottomNavigation(
                      currentIndex: _currentIndex,
                      isNetworkBarVisible: isNetworkVisible,
                      onTap: (index) {
                        if (_currentIndex == index) {
                          _navigatorKeys[index]
                              .currentState
                              ?.popUntil((route) => route.isFirst);
                        } else {
                          setState(() {
                            _currentIndex = index;
                            _visitedTabs.add(index);
                          });
                        }
                      },
                    ),
                  ),
                  const NetworkStatusBottomBar(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeTabWrapper extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onToggleMode;
  final HomeFeedBloc Function() createHomeFeedBloc;

  const _HomeTabWrapper({
    required this.onMenuPressed,
    required this.onToggleMode,
    required this.createHomeFeedBloc,
  });

  @override
  Widget build(BuildContext context) {
    final scope = _MainTabScope.of(context);
    final isOnline = scope?.isOnlineMode ?? false;
    final isActive = scope?.currentIndex == 0;

    return HomeTab(
      isOnlineMode: isOnline,
      isActive: isActive,
      onMenuPressed: onMenuPressed,
      onToggleMode: onToggleMode,
      iconKey: scope?.iconKey ?? GlobalKey(),
      iconVisible: scope?.iconVisible ?? true,
      createHomeFeedBloc: createHomeFeedBloc,
    );
  }
}

class _BrowseTabWrapper extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onToggleMode;
  final BrowseBloc Function() createBrowseBloc;

  const _BrowseTabWrapper({
    required this.onMenuPressed,
    required this.onToggleMode,
    required this.createBrowseBloc,
  });

  @override
  Widget build(BuildContext context) {
    final scope = _MainTabScope.of(context);
    final isOnline = scope?.isOnlineMode ?? false;
    final isActive = scope?.currentIndex == 1;

    return _BrowseTab(
      isOnlineMode: isOnline,
      isActive: isActive,
      onMenuPressed: onMenuPressed,
      onToggleMode: onToggleMode,
      createBrowseBloc: createBrowseBloc,
    );
  }
}

class _LibraryTabWrapper extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onToggleMode;
  final LibraryBloc Function(String userId) createLibraryBloc;

  const _LibraryTabWrapper({
    required this.onMenuPressed,
    required this.onToggleMode,
    required this.createLibraryBloc,
  });

  @override
  Widget build(BuildContext context) {
    final scope = _MainTabScope.of(context);
    final isOnline = scope?.isOnlineMode ?? false;
    final isActive = scope?.currentIndex == 2;

    return _LibraryTab(
      isOnlineMode: isOnline,
      isActive: isActive,
      onMenuPressed: onMenuPressed,
      onToggleMode: onToggleMode,
      createLibraryBloc: createLibraryBloc,
    );
  }
}

/// Browse tab: online shows Spotify categories, offline shows local file search.
class _BrowseTab extends StatelessWidget {
  final bool isOnlineMode;
  final bool isActive;
  final VoidCallback onMenuPressed;
  final VoidCallback onToggleMode;
  final BrowseBloc Function() createBrowseBloc;

  const _BrowseTab({
    required this.isOnlineMode,
    this.isActive = true,
    required this.onMenuPressed,
    required this.onToggleMode,
    required this.createBrowseBloc,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnlineMode) {
      return OfflineBrowseView(
        onMenuPressed: onMenuPressed,
        onToggleMode: onToggleMode,
      );
    }

    return AuthGatedBlocProvider<BrowseBloc>(
      createBloc: (_) => createBrowseBloc()..add(const BrowseLoadRequested()),
      placeholder: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppHeader(
                leading: GestureDetector(
                  onTap: onMenuPressed,
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFF535353),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
                title: 'Search',
                trailing: [
                  GestureDetector(
                    onTap: onToggleMode,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/app_icon.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              const Expanded(
                child: ConnectSpotifyPrompt(
                  icon: Icons.search_rounded,
                  title: 'Search millions of songs',
                  subtitle:
                      'Connect your Spotify account to browse\ncategories and discover new music.',
                ),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        color: const Color(0xFF121212),
        child: SafeArea(
          bottom: false,
          child: BrowseView(
            onMenuPressed: onMenuPressed,
            onToggleMode: onToggleMode,
            isActive: isActive,
          ),
        ),
      ),
    );
  }
}

/// Library tab: online shows Spotify playlists, offline shows local music library.
class _LibraryTab extends StatelessWidget {
  final bool isOnlineMode;
  final bool isActive;
  final VoidCallback onMenuPressed;
  final VoidCallback onToggleMode;
  final LibraryBloc Function(String userId) createLibraryBloc;

  const _LibraryTab({
    required this.isOnlineMode,
    this.isActive = true,
    required this.onMenuPressed,
    required this.onToggleMode,
    required this.createLibraryBloc,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnlineMode) {
      return OfflineLibraryView(
        onMenuPressed: onMenuPressed,
        onToggleMode: onToggleMode,
      );
    }

    return AuthGatedBlocProvider<LibraryBloc>(
      createBloc: (userId) =>
          createLibraryBloc(userId)..add(const LibraryLoadRequested()),
      placeholder: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppHeader(
                leading: GestureDetector(
                  onTap: onMenuPressed,
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFF535353),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
                title: 'Your Library',
                trailing: [
                  GestureDetector(
                    onTap: onToggleMode,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/app_icon.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              const Expanded(
                child: ConnectSpotifyPrompt(
                  icon: Icons.library_music_rounded,
                  title: 'Your playlists, all in one place',
                  subtitle:
                      'Connect your Spotify account to access\nyour playlists, saved albums, and artists.',
                ),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        color: const Color(0xFF121212),
        child: SafeArea(
          bottom: false,
          child: LibraryView(
            onMenuPressed: onMenuPressed,
            onToggleMode: onToggleMode,
            isActive: isActive,
          ),
        ),
      ),
    );
  }
}
