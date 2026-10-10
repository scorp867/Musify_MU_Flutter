import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/ui/widgets/app_snack_bar.dart';
import 'package:musify_mu/core/ui/widgets/sticky_header_delegate.dart';
import 'package:musify_mu/core/ui/widgets/shell_bottom_spacer.dart';
import 'package:musify_mu/features/home/presentation/widgets/home_header.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/home_feed/presentation/section_registry.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/home_feed_shimmer.dart';

/// The authenticated home feed -- renders sections from Casita data.
///
/// When [headerTitleRow] is provided, it's included as a scrollable
/// sliver at the top (scrolls away), with filter chips pinned below.
class HomeFeedView extends StatefulWidget {
  final Widget? headerTitleRow;
  final bool isActive;

  const HomeFeedView({
    super.key,
    this.headerTitleRow,
    this.isActive = true,
  });

  @override
  State<HomeFeedView> createState() => _HomeFeedViewState();
}

class _HomeFeedViewState extends State<HomeFeedView> {
  static const _defaultChips = [
    HomeChip(id: 'all', label: 'All'),
    HomeChip(id: 'music', label: 'Music'),
    HomeChip(id: 'podcasts', label: 'Podcasts'),
  ];

  @override
  void didUpdateWidget(HomeFeedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      AppSnackBar.clear(context);
      context.read<HomeFeedBloc>().add(const HomeFeedCancelRequested());
    } else if (!oldWidget.isActive && widget.isActive) {
      final bloc = context.read<HomeFeedBloc>();
      if (bloc.state is HomeFeedLoading) {
        bloc.add(const HomeFeedLoadRequested());
      } else {
        bloc.add(const HomeFeedActivated());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeFeedBloc, HomeFeedState>(
      listenWhen: (prev, curr) {
        if (curr is! HomeFeedError) return false;
        if (prev is HomeFeedError) {
          return prev.message != curr.message;
        }
        return true;
      },
      listener: (context, state) {
        if (state is HomeFeedError) {
          AppSnackBar.show(context, message: state.message);
        }
      },
      child: BlocBuilder<HomeFeedBloc, HomeFeedState>(
        builder: (context, state) {
          final List<HomeChip> chips = switch (state) {
          HomeFeedLoaded(:final data) =>
            data.chips.isNotEmpty ? data.chips : _defaultChips,
          _ => _defaultChips,
        };

        return RefreshIndicator(
          color: const Color(0xFF1DB954),
          backgroundColor: const Color(0xFF282828),
          onRefresh: () async {
            final bloc = context.read<HomeFeedBloc>();
            bloc.add(const HomeFeedRefreshRequested());
            try {
              await bloc.stream
                  .firstWhere(
                    (s) =>
                        (s is HomeFeedLoaded && !s.isRefreshing) ||
                        s is HomeFeedError,
                  )
                  .timeout(const Duration(seconds: 8));
            } catch (_) {}
          },
          child: CustomScrollView(
            slivers: [
              // Title row (floating -- reappears on any downward scroll)
              if (widget.headerTitleRow != null)
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
                  title: widget.headerTitleRow,
                ),

              // Filter chips (pinned -- stays visible when scrolling)
              if (widget.headerTitleRow != null)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyHeaderDelegate(
                    height: 40,
                    child: HomeFilterChips(chips: chips),
                  ),
                ),

              // Body content
              ..._buildBodySlivers(context, state),
            ],
          ),
        );
      },
    ),
  );
}

  List<Widget> _buildBodySlivers(BuildContext context, HomeFeedState state) {
    return switch (state) {
      HomeFeedLoading() => const [
          SliverToBoxAdapter(child: HomeFeedShimmer()),
        ],
      HomeFeedLoaded(:final data) => [
          SliverList.builder(
            itemCount: data.sections.length + 1,
            itemBuilder: (context, index) {
              if (index >= data.sections.length) {
                return const ShellBottomSpacer();
              }
              return _buildSection(data.sections[index]);
            },
          ),
        ],
      HomeFeedError(:final message, :final staleData) => staleData != null
          ? [
              SliverList.builder(
                itemCount: staleData.sections.length + 1,
                itemBuilder: (context, index) {
                  if (index >= staleData.sections.length) {
                    return const ShellBottomSpacer();
                  }
                  return _buildSection(staleData.sections[index]);
                },
              ),
            ]
          : [
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorView(message: message),
              ),
            ],
    };
  }

  Widget _buildSection(HomeSection section) {
    return _KeepAliveSection(
      key: ValueKey('section_${section.sectionUri}_${section.sectionType}'),
      child: const SectionRegistry().buildSection(section),
    );
  }
}

class _KeepAliveSection extends StatefulWidget {
  final Widget child;
  const _KeepAliveSection({super.key, required this.child});

  @override
  State<_KeepAliveSection> createState() => _KeepAliveSectionState();
}

class _KeepAliveSectionState extends State<_KeepAliveSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// ─── Error fallback ──────────────────────────────────────────────────

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
              'Couldn\'t load your feed',
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
                  .read<HomeFeedBloc>()
                  .add(const HomeFeedLoadRequested()),
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
