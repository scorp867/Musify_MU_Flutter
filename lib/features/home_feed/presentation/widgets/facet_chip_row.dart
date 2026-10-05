import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';

/// Horizontal filter chip row for home feed facets.
/// Controlled widget: selectedFacet and onSelected are owned by the parent.
class FacetChipRow extends StatelessWidget {
  final HomeFacet selectedFacet;
  final ValueChanged<HomeFacet> onSelected;

  const FacetChipRow({
    super.key,
    required this.selectedFacet,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: HomeFacet.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final facet = HomeFacet.values[index];
          final isSelected = facet == selectedFacet;

          return GestureDetector(
            onTap: () => onSelected(facet),
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
                facet.label,
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
