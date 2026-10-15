---
title: "credits_trait_plugin.dart"
path: "lib/core/kodiak/extendedmetadataimpl/plugins/credits_trait_plugin.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, kodiak]
lines: 38
incoming_dependencies: 0
outgoing_dependencies: 2
---

# credits_trait_plugin.dart

> Source File: `[lib/core/kodiak/extendedmetadataimpl/plugins/credits_trait_plugin.dart](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/extendedmetadataimpl/plugins/credits_trait_plugin.dart)`
> Layer: `lib/core/kodiak/extendedmetadataimpl/plugins`

## Executive Summary
`credits_trait_plugin.dart` is an essential file in `lib/core/kodiak/extendedmetadataimpl/plugins` providing definitions for `CreditsTraitPlugin`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `extended_metadata_plugin.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_plugin|extended_metadata_plugin.dart]] |
| `traits.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/traits|traits.dart]] |

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class CreditsTraitPlugin`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Implements**: `ExtendedMetadataPlugin<CreditsTrait>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `trait` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `parse` | `CreditsTrait` | `Uint8List payload` |
| `CreditsTrait` | `return` | `contributors: trait.contributors.map((c` |
| `map` | `dynamic` | `(s` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/credits_trait.pb.dart'
    as ct;
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 186 (CREDITS_V2_TRAIT).
/// Equivalent to Spotify Android's `bmk` decoder plugin.
class CreditsTraitPlugin implements ExtendedMetadataPlugin<CreditsTrait> {
  const CreditsTraitPlugin();

  @override
  Type get traitType => CreditsTrait;

  @override
  int get extensionKindValue => 186;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.CREDITS_V2_TRAIT;

  @override
  CreditsTrait parse(Uint8List payload) {
    final trait = ct.CreditsTrait.fromBuffer(payload);
    return CreditsTrait(
      contributors: trait.contributors.map((c) {
        return CreditContributor(
          name: c.name,
          role: c.role,
          uri: c.uri,
          url: c.url,
          roleGroupName: c.hasRoleGroup() ? c.roleGroup.name : '',
        );
      }).toList(),
      sourceNames: trait.sources.map((s) => s.name).toList(),
    );
  }
}
```
