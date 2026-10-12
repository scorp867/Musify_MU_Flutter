import 'package:flutter/material.dart';

/// Item data model for Now Playing merch rows (`merch_row_now_playing.xml`).
class MerchItem {
  final String title;
  final String price;
  final String? imageUrl;
  final VoidCallback? onTap;

  const MerchItem({
    required this.title,
    required this.price,
    this.imageUrl,
    this.onTap,
  });
}

/// Spotify-identical Merch card
/// (`ScrollCardType.MERCH` / `merch_card_now_playing.xml`).
///
/// Features:
/// - 16dp rounded corners (`widgets_corner_radius`)
/// - Elevated base background (#242424)
/// - Header with "Merch" title and "Show all" action
/// - Clean item rows with 48x48 rounded thumbnail, title, price, and chevron
class PlayerMerchSection extends StatelessWidget {
  const PlayerMerchSection({
    super.key,
    required this.items,
    this.onShowAll,
  });

  final List<MerchItem> items;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Merch" + "Show all"
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Merch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (onShowAll != null)
                InkWell(
                  onTap: onShowAll,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      'Show all',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Merch Item Rows
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _MerchRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _MerchRow extends StatelessWidget {
  const _MerchRow({required this.item});

  final MerchItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // Thumbnail (merch_npv_image_round_rectangle = 48dp)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 48,
                height: 48,
                color: const Color(0xFF333333),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white38,
                          size: 22,
                        ),
                      )
                    : const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white38,
                        size: 22,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.price,
                    style: const TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
