import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/library/application/library_bloc.dart';
import 'package:musify_mu/features/library/domain/models/library_item.dart';
import 'package:musify_mu/features/playlist_detail/application/playlist_detail_bloc.dart';

/// Screen for displaying playlist detail with Spotify-accurate color extraction
/// and 21-stop eased atmospheric gradient background.
///
/// Supports pull-to-refresh which dispatches a library refresh and reactively
/// re-extracts color when artwork changes.
class PlaylistDetailScreen extends StatefulWidget {
  final LibraryItem item;

  const PlaylistDetailScreen({super.key, required this.item});

  /// Opens the playlist detail screen via standard navigation.
  static void open(BuildContext context, LibraryItem item) {
    final libraryBloc = context.read<LibraryBloc>();
    final authBloc = context.read<AuthBloc>();
    final colorService = context.read<ColorExtractionService>();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<PlaylistDetailBloc>(
                create: (_) => PlaylistDetailBloc(
                  colorService: colorService,
                )..add(PlaylistDetailLoadRequested(item)),
              ),
              BlocProvider.value(value: libraryBloc),
              BlocProvider.value(value: authBloc),
            ],
            child: PlaylistDetailScreen(item: item),
          );
        },
      ),
    );
  }

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  LibraryItem? _findCurrentItem(LibraryState libraryState) {
    if (libraryState is! LibraryLoaded) return null;
    final items = libraryState.data.sortedByRecents();
    try {
      return items.firstWhere((i) => i.uri == widget.item.uri);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LibraryBloc, LibraryState>(
      listenWhen: (prev, curr) {
        return curr is LibraryLoaded && !curr.isRefreshing;
      },
      listener: (context, libraryState) {
        final updatedItem = _findCurrentItem(libraryState);
        if (updatedItem != null) {
          context
              .read<PlaylistDetailBloc>()
              .add(PlaylistDetailArtworkChanged(updatedItem));
        }
      },
      child: BlocBuilder<PlaylistDetailBloc, PlaylistDetailState>(
        builder: (context, state) {
          return switch (state) {
            PlaylistDetailLoading() => const _LoadingView(),
            PlaylistDetailLoaded() => _DetailView(state: state),
            PlaylistDetailError(:final message) =>
              _ErrorView(message: message),
          };
        },
      ),
    );
  }
}

// ─── Detail view ─────────────────────────────────────────────────────

class _DetailView extends StatelessWidget {
  final PlaylistDetailLoaded state;

  const _DetailView({required this.state});

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    // Ambient gradient blankets the upper ~68% of the viewport (reaching down
    // past the action buttons and into the track list, matching Spotify's diffuse matte falloff).
    final gradientHeight = (screenHeight * 0.68).clamp(560.0, 750.0);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Background: atmospheric matte gradient fading seamlessly into #121212
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: gradientHeight,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              decoration: BoxDecoration(gradient: state.gradient),
            ),
          ),

          // Top status bar scrim to eliminate edge-lit glare (matching Spotify's statusBarPlaceholder)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: statusBarHeight + 16,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Scrollable foreground with pull-to-refresh
          RefreshIndicator(
            color: const Color(0xFF1DB954),
            backgroundColor: const Color(0xFF282828),
            onRefresh: () async {
              context
                  .read<LibraryBloc>()
                  .add(const LibraryRefreshRequested());
              await context.read<LibraryBloc>().stream.firstWhere(
                    (s) =>
                        (s is LibraryLoaded && !s.isRefreshing) ||
                        s is LibraryError,
                  );
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // Top App Bar / Back button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: statusBarHeight + 4, left: 8, right: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        if (state.isExtracting)
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Artwork (Centered, high-quality)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 20),
                    child: Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 24,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: state.item.mosaicImageUrls.length >= 4
                            ? _MosaicArtwork(urls: state.item.mosaicImageUrls.take(4).toList())
                            : _SingleArtwork(url: state.item.imageUrl),
                      ),
                    ),
                  ),
                ),

                // Metadata: title, owner, count, Spotify-style controls
                SliverToBoxAdapter(
                  child: _PlaylistMetadata(state: state),
                ),

                // Extra scroll space for pull-to-refresh
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Artwork widgets ─────────────────────────────────────────────────

class _SingleArtwork extends StatelessWidget {
  final String? url;

  const _SingleArtwork({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _artworkPlaceholder();
    }

    return AppNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      memCacheWidth: 440,
      memCacheHeight: 440,
      placeholder: (_, _) => _artworkPlaceholder(),
      errorWidget: (_, _, _) => _artworkPlaceholder(),
    );
  }
}

class _MosaicArtwork extends StatelessWidget {
  final List<String> urls;

  const _MosaicArtwork({required this.urls});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _tile(urls[0])),
              const SizedBox(width: 1),
              Expanded(child: _tile(urls[1])),
            ],
          ),
        ),
        const SizedBox(height: 1),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _tile(urls[2])),
              const SizedBox(width: 1),
              Expanded(child: _tile(urls[3])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(String url) {
    return AppNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      memCacheWidth: 220,
      memCacheHeight: 220,
      placeholder: (_, _) => Container(color: const Color(0xFF282828)),
      errorWidget: (_, _, _) => Container(color: const Color(0xFF282828)),
    );
  }
}

Widget _artworkPlaceholder() {
  return Container(
    color: const Color(0xFF282828),
    child: const Center(
      child: Icon(Icons.music_note, color: Color(0xFF535353), size: 48),
    ),
  );
}

// ─── Playlist metadata & debug panel ─────────────────────────────────

class _PlaylistMetadata extends StatelessWidget {
  final PlaylistDetailLoaded state;

  const _PlaylistMetadata({required this.state});

  @override
  Widget build(BuildContext context) {
    final item = state.item;
    final colorHex =
        '#${state.extractedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Playlist title
          Text(
            item.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          // Owner & Song count
          Row(
            children: [
              if (item.ownerName != null) ...[
                Text(
                  item.ownerName!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '\u2022',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '${item.trackCount ?? 0} songs',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action row matching Spotify style (Add, Download, Share, Play)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white70, size: 26),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.arrow_circle_down_outlined, color: Colors.white70, size: 26),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white70, size: 24),
                onPressed: () {},
              ),
              const Spacer(),
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1ED760),
                ),
                child: const Center(
                  child: Icon(Icons.play_arrow, color: Colors.black, size: 32),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Color debug panel requested by the user
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Extracted Color',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.mosaicImageUrls.length >= 4 ? '2x2 Mosaic' : 'Single Cover',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: state.extractedColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          colorHex,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'RGB(${state.extractedColor.r * 255 ~/ 1}, ${state.extractedColor.g * 255 ~/ 1}, ${state.extractedColor.b * 255 ~/ 1})',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading view ────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1DB954),
        ),
      ),
    );
  }
}

// ─── Error view ──────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: Colors.grey.shade600, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
