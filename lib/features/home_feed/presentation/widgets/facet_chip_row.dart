import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';

/// Horizontal filter chip row for home feed facets.
/// Controlled widget: selectedFacet and onSelected are owned by the parent.
class FacetChipRow extends StatelessWidget {
  final HomeFacet selectedFacet;
  final ValueChanged<HomeFacet> onSelected;
  final List<HomeChip>? chips;

  const FacetChipRow({
    super.key,
    required this.selectedFacet,
    required this.onSelected,
    this.chips,
  });

  @override
  Widget build(BuildContext context) {
    final hasDynamicChips = chips != null && chips!.isNotEmpty;
    final count = hasDynamicChips ? chips!.length : HomeFacet.values.length;

    return Container(
      height: 32,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final String label;
          final bool isSelected;
          final VoidCallback onTap;

          if (hasDynamicChips) {
            final chip = chips![index];
            label = chip.label;
            final lowerId = chip.id.toLowerCase();
            final lowerLabel = chip.label.toLowerCase();

            final isMusic = lowerId.contains('music') || lowerLabel.contains('music');
            final isPodcast = lowerId.contains('podcast') || lowerLabel.contains('podcast');

            isSelected = (selectedFacet == HomeFacet.music && isMusic) ||
                (selectedFacet == HomeFacet.podcasts && isPodcast) ||
                (selectedFacet == HomeFacet.all && !isMusic && !isPodcast);

            onTap = () {
              if (isMusic) {
                onSelected(HomeFacet.music);
              } else if (isPodcast) {
                onSelected(HomeFacet.podcasts);
              } else {
                onSelected(HomeFacet.all);
              }
            };
          } else {
            final facet = HomeFacet.values[index];
            label = facet.label;
            isSelected = facet == selectedFacet;
            onTap = () => onSelected(facet);
          }

          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1DB954)
                    : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.black : Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
