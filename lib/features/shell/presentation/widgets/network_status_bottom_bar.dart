import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/network/status/bloc/network_status_bloc.dart';
import 'package:musify_mu/core/network/status/network_status.dart';

/// An ultra-sleek, full-width ambient status bar displayed at the bottom-most
/// boundary of the shell. Lifts the screen content when active, accounts for
/// system navigation insets, and collapses to 0 when online.
class NetworkStatusBottomBar extends StatelessWidget {
  const NetworkStatusBottomBar({super.key});

  /// The visible content strip height above system navigation bars.
  static const double contentHeight = 16.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkStatusBloc, NetworkStatusState>(
      builder: (context, state) {
        final isVisible = state.isVisible;
        final color = isVisible ? _getStatusColor(state.status) : Colors.transparent;
        final message = state.message ?? '';
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        final targetHeight = isVisible ? (contentHeight + bottomInset) : 0.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: targetHeight,
          color: color,
          clipBehavior: Clip.hardEdge,
          child: isVisible
              ? Container(
                  height: contentHeight,
                  margin: EdgeInsets.only(bottom: bottomInset),
                  alignment: Alignment.center,
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: Colors.white,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Color _getStatusColor(NetworkStatus status) {
    return switch (status) {
      NetworkStatus.offline => const Color(0xFFE22134),
      NetworkStatus.slow => const Color(0xFFFFA000),
      NetworkStatus.restored => const Color(0xFF1DB954),
      NetworkStatus.online => const Color(0xFF121212),
    };
  }
}
