import 'package:flutter/material.dart';

/// Centralized SnackBar utility for consistent, unobtrusive in-app notifications.
///
/// Design attributes:
/// - Floats above the bottom navigation bar with balanced margin spacing.
/// - Sleek, compact height with subtle 8px border radius.
/// - Clean dark theme (#282828 background, pure white text).
/// - Strict 3-second auto-dismiss with horizontal swipe-to-dismiss.
/// - No retry action (content refreshes automatically upon reconnection).
/// - Clears any pending/queued notifications before displaying.
abstract final class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
          ),
        ),
        backgroundColor: const Color(0xFF282828),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 12,
        ),
      ),
    );
  }

  /// Clears all active and queued SnackBars immediately.
  static void clear(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}
