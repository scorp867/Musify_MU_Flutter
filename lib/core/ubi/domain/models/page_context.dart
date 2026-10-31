library;

import 'package:equatable/equatable.dart';
import 'page_identifier.dart';
import 'page_instance_id.dart';
import 'page_specification.dart';

/// 1:1 replica of Spotify `p199p.du9` (PageContext).
class PageContext extends Equatable {
  final PageSpecification pageSpecification;
  final PageIdentifier? pageIdentifier;
  final PageInstanceId pageInstanceId;

  const PageContext({
    required this.pageSpecification,
    this.pageIdentifier,
    required this.pageInstanceId,
  });

  PageContext copyWith({
    PageSpecification? pageSpecification,
    PageIdentifier? pageIdentifier,
    PageInstanceId? pageInstanceId,
  }) {
    return PageContext(
      pageSpecification: pageSpecification ?? this.pageSpecification,
      pageIdentifier: pageIdentifier ?? this.pageIdentifier,
      pageInstanceId: pageInstanceId ?? this.pageInstanceId,
    );
  }

  @override
  List<Object?> get props =>
      [pageSpecification, pageIdentifier, pageInstanceId];
}
