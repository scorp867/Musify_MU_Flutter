import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/di/mode_persistence.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/network/status/bloc/network_status_bloc.dart';
import 'package:musify_mu/core/ubi/domain/logging/ubi_logger.dart';
import 'package:musify_mu/core/ubi/domain/models/bottom_tab_ubi_elements.dart';
import 'package:musify_mu/core/ui/animations/mode_transition.dart';
import 'package:musify_mu/core/ui/widgets/app_header.dart';
import 'package:musify_mu/core/ui/widgets/auth_gated_bloc_provider.dart';
import 'package:musify_mu/core/ui/widgets/connect_spotify_prompt.dart';
import 'package:musify_mu/features/browse/application/browse_bloc.dart';
import 'package:musify_mu/features/browse/presentation/browse_view.dart';
import 'package:musify_mu/features/browse/presentation/offline_browse_view.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/connect/presentation/screens/device_picker_sheet.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_device_label.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_state_icon.dart';
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

  static _MainTabScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_MainTabScope>();
    if (scope == null) {
      throw StateError('No _MainTabScope found in widget tree context');
    }
    return scope;
  }

  @override
  bool updateShouldNotify(_MainTabScope oldWidget) =>
      currentIndex != oldWidget.currentIndex ||
      isOnlineMode != oldWidget.isOnlineMode ||
      isDrawerOpen != oldWidget.isDrawerOpen ||
      iconVisible != oldWidget.iconVisible;
}

/// Main tab shell forwarding composition-root Connect state
/// ([ConnectMobiusController], `p199p/yrq.java`) to [MiniPlayer] and rendering
/// the remote-active fallback Connect bar when remote playback is active while
/// local `nowPlaying` is empty (`#47 §5`).
class MainScreen extends StatefulWidget {
  final VoidCallback onMenuPressed;
  final bool isDrawerOpen;
  final ModePersistence modePersistence;
  final HomeFeedBloc Function() createHomeFeedBloc;
  final BrowseBloc Function() createBrowseBloc;
  final LibraryBloc Function(String userId) createLibraryBloc;
  final ConnectMobiusController? connectController;
  final PlayerQueueMobiusController? queueBloc;
  final ConnectOutputStatusPolicy? outputStatusPolicy;
  final UbiLogger? ubiLogger;

  const MainScreen({
    super.key,
    required this.onMenuPressed,
    required this.isDrawerOpen,
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
  final Set<int> _visitedTabs = {0};

  PlayerQueueMobiusController? _resolveQueueBloc() {
    if (widget.queueBloc case final explicit?) {
      return explicit;
    }
    return context.read<PlayerQueueBloc?>();
  }

  ConnectMobiusController? _resolveConnectController() {
    if (widget.connectController case final explicit?) {
      return explicit;
    }
    return context.read<ConnectMobiusController?>();
  }

  ConnectOutputStatusPolicy _resolveOutputStatusPolicy() {
    if (widget.outputStatusPolicy case final explicit?) {
      return explicit;
    }
    if (context.read<ConnectOutputStatusPolicy?>() case final provided?) {
      return provided;
    }
    return ConnectOutputStatusPolicy.instance;
  }

  UbiLogger? _resolveUbiLogger() {
    if (widget.ubiLogger case final explicit?) {
      return explicit;
    }
    return context.read<UbiLogger?>();
  }

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

  void _toggleMode() {
    if (!_iconVisible) return;

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
      },
    );
  }

  Widget _buildBottomPlayerOrRemoteFallback(BuildContext context) {
    final queueController = _resolveQueueBloc();
    final connectController = _resolveConnectController();
    final policy = _resolveOutputStatusPolicy();
    final colorService = context.read<ColorExtractionService?>();

    if (queueController != null) {
      return ValueListenableBuilder<QueueModel>(
        valueListenable: queueController,
        builder: (context, queueState, _) {
          final track = queueState.nowPlaying;
          if (track != null) {
            return MiniPlayer(
              title: track.title,
              artist: track.artist,
              imageUrl: track.imageUrl,
              isPlaying: queueState.isPlaying,
              queueBloc: queueController,
              currentTrack: track,
              colorService: colorService,
              connectController: connectController,
              outputStatusPolicy: policy,
            );
          }
          return _buildRemoteActiveFallbackIfNeeded(
            connectController: connectController,
            policy: policy,
          );
        },
      );
    }

    return _buildRemoteActiveFallbackIfNeeded(
      connectController: connectController,
      policy: policy,
    );
  }

  Widget _buildRemoteActiveFallbackIfNeeded({
    required ConnectMobiusController? connectController,
    required ConnectOutputStatusPolicy policy,
  }) {
    if (connectController == null) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<ConnectState>(
      valueListenable: connectController,
      builder: (context, connectState, _) {
        if (!policy.isRemoteOutputActive(connectState)) {
          return const SizedBox.shrink();
        }
        return _RemoteActiveConnectFallbackBar(
          connectState: connectState,
          controller: connectController,
          policy: policy,
        );
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
                    child: _buildBottomPlayerOrRemoteFallback(context),
                  ),
                  RepaintBoundary(
                    child: AppBottomNavigation(
                      currentIndex: _currentIndex,
                      isNetworkBarVisible: isNetworkVisible,
                      onTap: (index) {
                        final ubiLogger = _resolveUbiLogger();
                        if (_currentIndex == index) {
                          if (ubiLogger != null) {
                            final element = switch (index) {
                              0 => const HomeTabUbiElement.quickScroll(),
                              1 => const SearchTabUbiElement.quickScroll(),
                              2 => const YourLibraryTabUbiElement.quickScroll(),
                              _ => const TabBarUbiElement(actionName: 'quick_scroll'),
                            };
                            ubiLogger.logInteraction(element);
                          }
                          _navigatorKeys[index]
                              .currentState
                              ?.popUntil((route) => route.isFirst);
                        } else {
                          if (ubiLogger != null) {
                            final element = switch (index) {
                              0 => const HomeTabUbiElement.navigate(),
                              1 => const SearchTabUbiElement.navigate(),
                              2 => const YourLibraryTabUbiElement.navigate(),
                              _ => const TabBarUbiElement(actionName: 'ui_navigate'),
                            };
                            ubiLogger.logInteraction(element);
                          }
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

class _RemoteActiveConnectFallbackBar extends StatelessWidget {
  const _RemoteActiveConnectFallbackBar({
    required this.connectState,
    required this.controller,
    required this.policy,
  });

  final ConnectState connectState;
  final ConnectMobiusController controller;
  final ConnectOutputStatusPolicy policy;

  @override
  Widget build(BuildContext context) {
    final ConnectIconState iconState = resolveConnectIconState(
      connectState,
      policy: policy,
    );
    final ConnectLabelState labelState = resolveConnectLabelState(
      connectState,
      policy: policy,
    );
    final String statusText = policy.resolveBannerStatusText(connectState);

    void openPicker() {
      DevicePickerSheet.show(
        context,
        controller: controller,
      );
    }

    return Container(
      key: const ValueKey<String>('remote_active_connect_fallback_bar'),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      height: ConnectEncoreTheme.miniPlayerDefaultHeight,
      decoration: BoxDecoration(
        color: ConnectEncoreTheme.miniPlayerDefaultBackground,
        borderRadius: BorderRadius.circular(
          ConnectEncoreTheme.miniPlayerDefaultRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12.0,
            offset: const Offset(0.0, 4.0),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: openPicker,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ConnectStateIcon(
                  iconState: iconState,
                  size: 24.0,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ConnectEncoreTheme.bodySmall13Bold.copyWith(
                          color: ConnectEncoreTheme.textBase,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      ConnectDeviceLabel(
                        labelState: labelState,
                        textStyle: ConnectEncoreTheme.caption11Regular.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        showBadgeIcon: true,
                      ),
                    ],
                  ),
                ),
                SizedBox.square(
                  dimension: ConnectEncoreTheme.miniPlayerActionButtonSize,
                  child: IconButton(
                    key: const ValueKey<String>(
                      'remote_fallback_open_picker_button',
                    ),
                    padding: const EdgeInsets.all(8.0),
                    tooltip: 'Devices',
                    icon: ConnectStateIcon(
                      iconState: iconState,
                      size: 24.0,
                    ),
                    onPressed: openPicker,
                  ),
                ),
              ],
            ),
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
    final isOnline = scope.isOnlineMode;
    final isActive = scope.currentIndex == 0;

    return HomeTab(
      isOnlineMode: isOnline,
      isActive: isActive,
      onMenuPressed: onMenuPressed,
      onToggleMode: onToggleMode,
      iconKey: scope.iconKey,
      iconVisible: scope.iconVisible,
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
    final isOnline = scope.isOnlineMode;
    final isActive = scope.currentIndex == 1;

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
    final isOnline = scope.isOnlineMode;
    final isActive = scope.currentIndex == 2;

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
