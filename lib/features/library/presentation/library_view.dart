import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:musify_mu/core/ui/widgets/app_header.dart';
import 'package:musify_mu/core/ui/widgets/sticky_header_delegate.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/library/application/library_bloc.dart';
import 'package:musify_mu/features/library/domain/models/library_view_data.dart';
import 'package:musify_mu/features/playlist_detail/application/playlist_detail_bloc.dart';
import 'package:musify_mu/features/playlist_detail/presentation/playlist_detail_screen.dart';

/// The Library tab view.
class LibraryView extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onToggleMode;

  const LibraryView({super.key, this.onMenuPressed, this.onToggleMode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        return switch (state) {
          LibraryLoading() => const _LibraryShimmer(),
          LibraryLoaded(:final data, :final isRefreshing) =>
            _LibraryContent(
              data: data,
              isRefreshing: isRefreshing,
              onMenuPressed: onMenuPressed,
              onToggleMode: onToggleMode,
            ),
          LibraryError(:final message, :final staleData) =>
            staleData != null
                ? _LibraryContent(
                    data: staleData,
                    isRefreshing: false,
                    onMenuPressed: onMenuPressed,
                    onToggleMode: onToggleMode,
                  )
                : _ErrorView(message: message),
        };
      },
    );
  }
}

// ─── Filter chip state ───────────────────────────────────────────────

enum LibraryFilter { all, playlists, podcasts, artists }

// ─── Content ─────────────────────────────────────────────────────────

class _LibraryContent extends StatefulWidget {
  final LibraryViewData data;
  final bool isRefreshing;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onToggleMode;

  const _LibraryContent({
    required this.data,
    required this.isRefreshing,
    this.onMenuPressed,
    this.onToggleMode,
  });

  @override
  State<_LibraryContent> createState() => _LibraryContentState();
}

class _LibraryContentState extends State<_LibraryContent> {
  LibraryFilter _activeFilter = LibraryFilter.all;

  List<LibraryItem> get _filteredItems {
    final sorted = widget.data.sortedByRecents();
    return switch (_activeFilter) {
      LibraryFilter.all => sorted,
      LibraryFilter.playlists =>
        sorted.where((i) => i.type == 'playlist').toList(),
      LibraryFilter.podcasts =>
        sorted.where((i) => i.type == 'show').toList(),
      LibraryFilter.artists =>
        sorted.where((i) => i.type == 'artist').toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return RefreshIndicator(
      color: const Color(0xFF1DB954),
      backgroundColor: const Color(0xFF282828),
      onRefresh: () async {
        context.read<LibraryBloc>().add(const LibraryRefreshRequested());
        await context.read<LibraryBloc>().stream.firstWhere(
              (s) => (s is LibraryLoaded && !s.isRefreshing) || s is LibraryError,
            );
      },
      child: CustomScrollView(
        slivers: [
          // Header (floating)
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: const Color(0xFF121212),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 72,
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            title: _LibraryHeader(
              onMenuPressed: widget.onMenuPressed,
              onToggleMode: widget.onToggleMode,
            ),
          ),

          // Filter chips (pinned)
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyHeaderDelegate(
              height: 48,
              child: _FilterChipRow(
                active: _activeFilter,
                onChanged: (filter) =>
                    setState(() => _activeFilter = filter),
              ),
            ),
          ),

          // Sort bar
          SliverToBoxAdapter(
            child: _SortBar(itemCount: items.length),
          ),

          // Library items
          SliverList.builder(
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return const SizedBox(height: 120);
              }
              return _LibraryItemTile(item: items[index]);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────

class _LibraryHeader extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onToggleMode;

  const _LibraryHeader({this.onMenuPressed, this.onToggleMode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      builder: (context, authState) {
        final user =
            authState is Authenticated ? authState.user : null;

        Widget avatar;
        if (user?.avatarUrl != null) {
          avatar = CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF1E293B),
            // ⚡ Bolt: Replaced NetworkImage with CachedNetworkImageProvider to prevent
            // redundant network requests and improve rendering performance by using disk cache.
            backgroundImage: CachedNetworkImageProvider(user!.avatarUrl!),
          );
        } else if (user?.displayName != null) {
          avatar = CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF1DB954),
            child: Text(
              user!.displayName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          );
        } else {
          avatar = const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFF535353),
            child: Icon(Icons.person, color: Colors.white),
          );
        }

        return AppHeader(
          leading: GestureDetector(
            onTap: onMenuPressed,
            child: avatar,
          ),
          title: 'Your Library',
          trailing: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {},
            ),
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
        );
      },
    );
  }
}

// ─── Filter chips ────────────────────────────────────────────────────

class _FilterChipRow extends StatelessWidget {
  final LibraryFilter active;
  final ValueChanged<LibraryFilter> onChanged;

  const _FilterChipRow({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (active != LibraryFilter.all)
            _buildClearButton(),
          for (final filter in LibraryFilter.values)
            if (filter != LibraryFilter.all)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildChip(filter),
              ),
        ],
      ),
    );
  }

  Widget _buildClearButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onChanged(LibraryFilter.all),
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF333333),
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  Widget _buildChip(LibraryFilter filter) {
    final isActive = active == filter;
    final label = switch (filter) {
      LibraryFilter.all => 'All',
      LibraryFilter.playlists => 'Playlists',
      LibraryFilter.podcasts => 'Podcasts',
      LibraryFilter.artists => 'Artists',
    };

    return GestureDetector(
      onTap: () => onChanged(isActive ? LibraryFilter.all : filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1DB954)
              : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Sort bar ────────────────────────────────────────────────────────

class _SortBar extends StatelessWidget {
  final int itemCount;

  const _SortBar({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.swap_vert, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          const Text(
            'Recents',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Icon(Icons.grid_view_rounded,
              color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }
}

// ─── Item tile ───────────────────────────────────────────────────────

class _LibraryItemTile extends StatelessWidget {
  final LibraryItem item;

  const _LibraryItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isLikedSongs = item.uri == 'spotify:collection:tracks';
    final isArtist = item.type == 'artist';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SizedBox(
        width: 56,
        height: 56,
        child: isLikedSongs
            ? _buildLikedSongsIcon()
            : _buildItemImage(isArtist: isArtist),
      ),
      title: Text(
        item.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _buildSubtitle(),
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        if (item.type != 'playlist') return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) {
              final bloc = GetIt.instance<PlaylistDetailBloc>()
                ..add(PlaylistDetailLoadRequested(item));
              return MultiBlocProvider(
                providers: [
                  BlocProvider<PlaylistDetailBloc>.value(value: bloc),
                  BlocProvider<LibraryBloc>.value(
                    value: context.read<LibraryBloc>(),
                  ),
                  BlocProvider<AuthBloc>.value(
                    value: context.read<AuthBloc>(),
                  ),
                ],
                child: PlaylistDetailScreen(item: item),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLikedSongsIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Icon(Icons.favorite, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildItemImage({required bool isArtist}) {
    // Mosaic: 2x2 grid of album arts for playlists without custom covers.
    if (item.mosaicImageUrls.length >= 4) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: _MosaicGrid(urls: item.mosaicImageUrls.take(4).toList()),
      );
    }

    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(isArtist ? 28 : 4),
        child: CachedNetworkImage(
          imageUrl: item.imageUrl!,
          fit: BoxFit.cover,
          memCacheWidth: 140,
          memCacheHeight: 140,
          errorWidget: (_, _, _) => _placeholderIcon(),
        ),
      );
    }
    return _placeholderIcon(isCircle: isArtist);
  }

  Widget _placeholderIcon({bool isCircle = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius:
            BorderRadius.circular(isCircle ? 28 : 4),
      ),
      child: Center(
        child: Icon(
          item.type == 'artist'
              ? Icons.person
              : item.type == 'show'
                  ? Icons.podcasts
                  : Icons.music_note,
          color: Colors.grey.shade600,
          size: 24,
        ),
      ),
    );
  }

  String _buildSubtitle() {
    if (item.uri == 'spotify:collection:tracks') {
      final count = item.trackCount ?? 0;
      return 'Playlist \u2022 $count songs';
    }
    if (item.type == 'artist') return 'Artist';
    if (item.type == 'show') return 'Podcast';
    if (item.ownerName != null) return 'Playlist \u2022 ${item.ownerName}';
    return 'Playlist';
  }
}

// ─── Shimmer ─────────────────────────────────────────────────────────

class _LibraryShimmer extends StatelessWidget {
  const _LibraryShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFF282828),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 12,
                        width: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                color: Colors.grey.shade600, size: 48),
            const SizedBox(height: 16),
            Text(
              'Couldn\'t load your library',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context
                  .read<LibraryBloc>()
                  .add(const LibraryLoadRequested()),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Color(0xFF1DB954),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2x2 grid of album art images, matching the Spotify playlist mosaic style.
class _MosaicGrid extends StatelessWidget {
  final List<String> urls;

  const _MosaicGrid({required this.urls});

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
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      memCacheWidth: 80,
      memCacheHeight: 80,
      errorWidget: (_, _, _) => Container(color: const Color(0xFF282828)),
    );
  }
}
