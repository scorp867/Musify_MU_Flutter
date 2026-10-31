library;

import 'package:equatable/equatable.dart';
import 'page_specification.dart';

/// 1:1 replica of Spotify `p199p.yzx0` (DynamicPageSpecification).
class DynamicPageSpecification extends Equatable implements PageSpecification {
  final String pageIdentifier;

  const DynamicPageSpecification(this.pageIdentifier);

  @override
  String pageId() {
    final parts = pageIdentifier.split('/');
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first;
    }
    return 'unknown';
  }

  @override
  String path() => pageIdentifier;

  @override
  List<Object?> get props => [pageIdentifier];

  @override
  String toString() => "{pageIdentifier='$pageIdentifier'}";
}
