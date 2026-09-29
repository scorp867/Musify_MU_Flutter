import 'package:equatable/equatable.dart';

/// Complete browse tab data -- everything the UI needs.
class BrowseViewData extends Equatable {
  final List<BrowseSection> sections;

  const BrowseViewData({this.sections = const []});

  @override
  List<Object?> get props => [sections];

  Map<String, dynamic> toJson() => {
        'sections': sections.map((s) => s.toJson()).toList(),
      };

  factory BrowseViewData.fromJson(Map<String, dynamic> json) {
    return BrowseViewData(
      sections: (json['sections'] as List?)
              ?.map((s) => BrowseSection.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// A section in the browse page.
/// Browsita sections have a featureType oneof, but the main one
/// is ContentCategory (field 2) which shows category grids.
class BrowseSection extends Equatable {
  final String sectionId;
  final String sectionType;
  final String title;
  final String? iconName;
  final List<BrowseItem> items;
  final String? navigateUri;

  const BrowseSection({
    this.sectionId = '',
    this.sectionType = '',
    this.title = '',
    this.iconName,
    this.items = const [],
    this.navigateUri,
  });

  @override
  List<Object?> get props => [
        sectionId,
        sectionType,
        title,
        iconName,
        items,
        navigateUri,
      ];

  Map<String, dynamic> toJson() => {
        'sectionId': sectionId,
        'sectionType': sectionType,
        'title': title,
        if (iconName != null) 'iconName': iconName,
        'items': items.map((i) => i.toJson()).toList(),
        if (navigateUri != null) 'navigateUri': navigateUri,
      };

  factory BrowseSection.fromJson(Map<String, dynamic> json) {
    return BrowseSection(
      sectionId: json['sectionId'] as String? ?? '',
      sectionType: json['sectionType'] as String? ?? '',
      title: json['title'] as String? ?? '',
      iconName: json['iconName'] as String?,
      items: (json['items'] as List?)
              ?.map((i) => BrowseItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      navigateUri: json['navigateUri'] as String?,
    );
  }
}

/// A single item in a browse category (e.g. a genre card).
class BrowseItem extends Equatable {
  /// The Spotify URI (e.g. spotify:page:..., spotify:genre:...).
  final String uri;

  /// Target URI for navigation (where tapping takes you).
  final String targetUri;

  /// Resolved title (from extended metadata or inline).
  final String title;

  /// Resolved image URL (from extended metadata or inline).
  final String imageUrl;

  /// Background color (from extended metadata).
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
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'uri': uri,
        'targetUri': targetUri,
        'title': title,
        'imageUrl': imageUrl,
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
      };

  factory BrowseItem.fromJson(Map<String, dynamic> json) {
    return BrowseItem(
      uri: json['uri'] as String? ?? '',
      targetUri: json['targetUri'] as String? ?? '',
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      backgroundColor: json['backgroundColor'] as int?,
    );
  }
}
