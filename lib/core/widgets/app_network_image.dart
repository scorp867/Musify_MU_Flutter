import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/network/status/bloc/network_status_bloc.dart';
import 'package:musify_mu/core/network/status/network_status.dart';

/// Connectivity-aware image widget that automatically retries failed downloads
/// as soon as the device reconnects to the network, without requiring the user
/// to scroll the card out of and back into the viewport.
///
/// Follows pure Flutter BLoC architecture: receives connectivity state reactively
/// via [BuildContext] / [BlocListener] with zero service locator dependencies.
class AppNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final ImageWidgetBuilder? imageBuilder;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Alignment alignment;
  final Duration fadeInDuration;
  final NetworkStatusBloc? networkStatusBloc;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorWidget,
    this.imageBuilder,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.networkStatusBloc,
  });

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  int _retryKey = 0;
  bool _hasError = false;

  @override
  void didUpdateWidget(covariant AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _hasError = false;
      _retryKey = 0;
    }
  }

  void _onNetworkStatusChanged(BuildContext context, NetworkStatusState state) {
    if (state.status == NetworkStatus.restored || state.status == NetworkStatus.online) {
      if (_hasError) {
        setState(() {
          _hasError = false;
          _retryKey++;
        });
      }
    }
  }

  NetworkStatusBloc? _resolveBloc(BuildContext context) {
    if (widget.networkStatusBloc != null) {
      return widget.networkStatusBloc;
    }
    try {
      return context.read<NetworkStatusBloc>();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) {
      return widget.errorWidget?.call(
            context,
            widget.imageUrl,
            const FormatException('Empty image URL'),
          ) ??
          const SizedBox.shrink();
    }

    final imageWidget = CachedNetworkImage(
      key: ValueKey('${widget.imageUrl}_$_retryKey'),
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      alignment: widget.alignment,
      fadeInDuration: widget.fadeInDuration,
      placeholder: widget.placeholder,
      imageBuilder: widget.imageBuilder,
      errorWidget: (context, url, error) {
        if (!_hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _hasError = true;
            }
          });
        }
        return widget.errorWidget?.call(context, url, error) ??
            const SizedBox.shrink();
      },
    );

    final bloc = _resolveBloc(context);
    if (bloc != null) {
      return BlocListener<NetworkStatusBloc, NetworkStatusState>(
        bloc: bloc,
        listener: _onNetworkStatusChanged,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
