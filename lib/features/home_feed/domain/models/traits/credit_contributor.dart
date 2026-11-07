import 'package:flutter/foundation.dart';

/// A single contributor on a track (artist, writer, producer, etc.).
@immutable
final class CreditContributor {
  final String name;
  final String role;
  final String uri;
  final String url;
  final String roleGroupName;

  const CreditContributor({
    required this.name,
    this.role = '',
    this.uri = '',
    this.url = '',
    this.roleGroupName = '',
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditContributor &&
        other.name == name &&
        other.role == role &&
        other.uri == uri &&
        other.url == url &&
        other.roleGroupName == roleGroupName;
  }

  @override
  int get hashCode => Object.hash(name, role, uri, url, roleGroupName);
}
