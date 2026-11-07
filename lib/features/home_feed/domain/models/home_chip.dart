import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Filter chip on the home feed (All, Music, Podcasts).
@immutable
final class HomeChip extends Equatable {
  final String id;
  final String label;

  const HomeChip({required this.id, required this.label});

  @override
  List<Object?> get props => [id, label];
}
