import 'package:flutter/material.dart';

/// Shimmer loading placeholder for the home feed.
/// Shows skeleton cards while data is loading.
class HomeFeedShimmer extends StatefulWidget {
  const HomeFeedShimmer({super.key});

  @override
  State<HomeFeedShimmer> createState() => _HomeFeedShimmerState();
}

class _HomeFeedShimmerState extends State<HomeFeedShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shimmerColor = ColorTween(
          begin: const Color(0xFF1E1E1E),
          end: const Color(0xFF2A2A2A),
        ).evaluate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ))!;

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick grid skeleton (2x3)
              _shimmerQuickGrid(shimmerColor),
              const SizedBox(height: 32),
              // Carousel skeleton 1
              _shimmerCarousel(shimmerColor),
              const SizedBox(height: 32),
              // Carousel skeleton 2
              _shimmerCarousel(shimmerColor),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerQuickGrid(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(6, (_) {
          return SizedBox(
            width: (MediaQuery.of(context).size.width - 40) / 2,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _shimmerCarousel(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: 160,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            itemBuilder: (_, _) => Container(
              width: 140,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
