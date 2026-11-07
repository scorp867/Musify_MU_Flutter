import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// A single item in a browse category (for example, a genre or page card).
@immutable
final class BrowseItem extends Equatable {
  final String uri;
  final String targetUri;
  final String title;
  final String imageUrl;
  final int? backgroundColor;

  const BrowseItem({
    required this.uri,
    this.targetUri = '',
    this.title = '',
    this.imageUrl = '',
    this.backgroundColor,
  });

  @override
  List<Object?> get props => [
    uri,
    targetUri,
    title,
    imageUrl,
    backgroundColor,
  ];

  BrowseItem copyWith({
    String? title,
    String? imageUrl,
    int? backgroundColor,
  }) {
    return BrowseItem(
      uri: uri,
      targetUri: targetUri,
      title: title != null ? title : this.title,
      imageUrl: imageUrl != null ? imageUrl : this.imageUrl,
      backgroundColor:
          backgroundColor != null ? backgroundColor : this.backgroundColor,
    );
  }
}
