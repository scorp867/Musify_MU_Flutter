import 'package:flutter/material.dart';

/// Shared app header bar used across all main tabs.
///
/// Layout:
///   Row 1:  [leading] [title]                    [...trailing]
///   Row 2:  [bottom] (optional, e.g. filter chips)
///
/// Each screen customises via:
///   - `leading`: widget on the far left (app icon, avatar, etc.)
///   - `title`: the header text
///   - `trailing`: list of action widgets on the right
///   - `bottom`: optional widget below the title row (filter chips, etc.)
class AppHeader extends StatelessWidget {
  /// Widget on the far left (e.g. app icon, user avatar).
  final Widget? leading;

  /// Header title text.
  final String title;

  /// Style override for the title.
  final TextStyle? titleStyle;

  /// Action widgets on the right side.
  final List<Widget> trailing;

  /// Called when the leading widget is tapped.
  final VoidCallback? onLeadingTap;

  /// Optional widget below the title row (e.g. filter chips).
  final Widget? bottom;

  /// Horizontal padding for the title row.
  final EdgeInsetsGeometry padding;

  const AppHeader({
    super.key,
    this.leading,
    required this.title,
    this.titleStyle,
    this.trailing = const [],
    this.onLeadingTap,
    this.bottom,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: leading + title + trailing
        Padding(
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: leading + title
              Expanded(
                child: Row(
                  children: [
                    if (leading != null) ...[
                      GestureDetector(
                        onTap: onLeadingTap,
                        child: leading!,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        style: titleStyle ??
                            const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Right side: trailing actions
              if (trailing.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: trailing,
                ),
            ],
          ),
        ),

        // Row 2: optional bottom widget
        ?bottom,
      ],
    );
  }
}
