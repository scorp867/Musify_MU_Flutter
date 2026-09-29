import 'package:flutter/material.dart';

/// Sticky horizontal chip row for filtering home feed (All, Music, Podcasts…).
class FacetChipRow extends StatefulWidget {
  final List<String> labels;
  final ValueChanged<int>? onSelected;

  const FacetChipRow({
    super.key,
    this.labels = const ['All', 'Music', 'Podcasts & Shows'],
    this.onSelected,
  });

  @override
  State<FacetChipRow> createState() => _FacetChipRowState();
}

class _FacetChipRowState extends State<FacetChipRow> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isActive = index == _selected;
          return GestureDetector(
            onTap: () {
              setState(() => _selected = index);
              widget.onSelected?.call(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF1DB954)
                    : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.labels[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.black : Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
