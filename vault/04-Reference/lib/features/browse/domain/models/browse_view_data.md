---
title: "browse_view_data.dart"
path: "lib/features/browse/domain/models/browse_view_data.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, browse]
lines: 145
incoming_dependencies: 5
outgoing_dependencies: 0
---

# browse_view_data.dart

> Source File: `[lib/features/browse/domain/models/browse_view_data.dart](file:///c:/Users/Admin/Musify_MU/lib/features/browse/domain/models/browse_view_data.dart)`
> Layer: `lib/features/browse/domain/models`

## Executive Summary
`browse_view_data.dart` is an essential file in `lib/features/browse/domain/models` providing definitions for `BrowseViewData`, `BrowseSection`, `BrowseItem`.
**Primary Architecture Role**: Domain Model / Entity

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `browse_repository.dart` | `lib/features/browse/data` | [[04-Reference/lib/features/browse/data/browse_repository|browse_repository.dart]] |
| `browsita_parser.dart` | `lib/features/browse/data` | [[04-Reference/lib/features/browse/data/browsita_parser|browsita_parser.dart]] |
| `browse_view.dart` | `lib/features/browse/presentation` | [[04-Reference/lib/features/browse/presentation/browse_view|browse_view.dart]] |
| `browse_repository.dart` | `lib/features/browse/domain/repositories` | [[04-Reference/lib/features/browse/domain/repositories/browse_repository|browse_repository.dart]] |
| `load_browse.dart` | `lib/features/browse/domain/usecases` | [[04-Reference/lib/features/browse/domain/usecases/load_browse|load_browse.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class BrowseViewData`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `sections` | `List<BrowseSection>` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toJson` | `dynamic>` | `(none)` |
| `map` | `dynamic` | `(s` |
| `fromJson` | `dynamic` | `Map<String, dynamic> json` |
| `map` | `dynamic` | `(s` |

#### `class BrowseSection`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `sectionId` | `String` |
| `sectionType` | `String` |
| `title` | `String` |
| `iconName` | `String?` |
| `items` | `List<BrowseItem>` |
| `navigateUri` | `String?` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toJson` | `dynamic>` | `(none)` |
| `map` | `dynamic` | `(i` |
| `fromJson` | `dynamic` | `Map<String, dynamic> json` |
| `map` | `dynamic` | `(i` |

#### `class BrowseItem`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `uri` | `String` |
| `targetUri` | `String` |
| `title` | `String` |
| `imageUrl` | `String` |
| `backgroundColor` | `int?` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `copyWith` | `BrowseItem` | `{ String? title, String? imageUrl, int? backgro...` |
| `toJson` | `dynamic>` | `(none)` |
| `fromJson` | `dynamic` | `Map<String, dynamic> json` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
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

// ... [remaining code in source file] ...
```
