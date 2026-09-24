import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Compact tile for the shortcuts quick grid.
/// Shows: small artwork + title side-by-side.
class QuickGridTile extends StatelessWidget {
  final SpotifyEntity item;

  const QuickGridTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 40) / 2;
    final title = item.fallbackTitle;
    final imageUrl = item.fallbackImageUrl;

    return SizedBox(
      width: width,
      height: 56,
      child: Material(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF383838),
      child: Icon(Icons.music_note, color: Colors.grey.shade600, size: 20),
    );
  }
}
