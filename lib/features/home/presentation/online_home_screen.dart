import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/application/auth_event.dart';
import 'package:musify_mu/features/auth/data/spotify_client_token.dart';
import 'package:musify_mu/features/auth/data/spotify_token_refresher.dart';
import 'package:musify_mu/features/auth/data/spotify_token_store.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/auth/presentation/widgets/spotify_login_webview.dart';
import 'package:musify_mu/features/auth/presentation/widgets/spotify_welcome_landing.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/home_feed/data/home_repository.dart';
import 'package:musify_mu/features/home_feed/presentation/home_feed_view.dart';
import 'package:musify_mu/features/spotify_client/spotify_client.dart';

class OnlineHomeScreen extends StatefulWidget {
  final Widget? headerTitleRow;

  const OnlineHomeScreen({super.key, this.headerTitleRow});

  @override
  State<OnlineHomeScreen> createState() => _OnlineHomeScreenState();
}

class _OnlineHomeScreenState extends State<OnlineHomeScreen> {
  bool _showWebView = false;

  void _onConnectTapped() {
    setState(() => _showWebView = true);
  }

  void _onWebViewCancel() {
    setState(() => _showWebView = false);
  }

  void _onLoginSuccess(String spDcCookie, String bearerToken) {
    setState(() => _showWebView = false);
    context.read<AuthBloc>().add(AuthTokensCaptured(
          spDcCookie: spDcCookie,
          accessToken: bearerToken,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return switch (state) {
          Unauthenticated() => _buildUnauthenticatedView(),
          Authenticating() => SpotifyWelcomeLanding(
              isLoading: true,
              onConnect: () {},
            ),
          AuthError(:final message) => _AuthErrorView(
              message: message,
              onRetry: () {
                context.read<AuthBloc>().add(const AuthLoginRequested());
              },
            ),
          Authenticated() => _buildAuthenticatedFeed(),
        };
      },
    );
  }

  Widget _buildUnauthenticatedView() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _showWebView
          ? SpotifyLoginWebView(
              key: const ValueKey('webview'),
              onLoginSuccess: _onLoginSuccess,
              onCancel: _onWebViewCancel,
            )
          : SpotifyWelcomeLanding(
              key: const ValueKey('welcome'),
              onConnect: _onConnectTapped,
            ),
    );
  }

  /// Builds the authenticated home feed with all dependencies wired up.
  Widget _buildAuthenticatedFeed() {
    final tokenStore = SpotifyTokenStore();
    final tokenRefresher = SpotifyTokenRefresher(tokenStore: tokenStore);
    final clientTokenFetcher = SpotifyClientTokenFetcher(tokenStore);

    final spotifyClient = SpotifyClient(
      tokenStore: tokenStore,
      tokenRefresher: tokenRefresher,
      clientTokenFetcher: clientTokenFetcher,
    );

    final homeRepository = HomeRepository(client: spotifyClient);

    return BlocProvider(
      create: (_) => HomeFeedBloc(repository: homeRepository)
        ..add(const HomeFeedLoadRequested()),
      child: Container(
        color: const Color(0xFF121212),
        child: HomeFeedView(
          headerTitleRow: widget.headerTitleRow,
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Error view
// ---------------------------------------------------------------------------

class _AuthErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AuthErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: onRetry,
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    color: Color(0xFF1DB954),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
