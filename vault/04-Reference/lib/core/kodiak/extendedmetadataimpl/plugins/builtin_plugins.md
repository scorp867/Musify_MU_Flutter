---
title: "builtin_plugins.dart"
path: "lib/core/kodiak/extendedmetadataimpl/plugins/builtin_plugins.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, kodiak]
lines: 70
incoming_dependencies: 6
outgoing_dependencies: 1
---

# builtin_plugins.dart

> Source File: `[lib/core/kodiak/extendedmetadataimpl/plugins/builtin_plugins.dart](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/extendedmetadataimpl/plugins/builtin_plugins.dart)`
> Layer: `lib/core/kodiak/extendedmetadataimpl/plugins`

## Executive Summary
`builtin_plugins.dart` is an essential file in `lib/core/kodiak/extendedmetadataimpl/plugins` providing definitions for Top-level functions/constants.

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `extended_metadata_plugin.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_plugin|extended_metadata_plugin.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `casita_parser.dart` | `lib/features/home_feed/data` | [[04-Reference/lib/features/home_feed/data/casita_parser|casita_parser.dart]] |
| `extended_metadata_service.dart` | `lib/core/media` | [[04-Reference/lib/core/media/extended_metadata_service|extended_metadata_service.dart]] |
| `data_pool_impl.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool_impl|data_pool_impl.dart]] |
| `extended_metadata_client.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_client|extended_metadata_client.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `kodiak_data_layer_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/kodiak_data_layer_test|kodiak_data_layer_test.dart]] |

## Declarations & API Breakdown

This file contains top-level functions or standalone variables.

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';

import 'simple_card_trait_plugin.dart';
import 'shortcuts_card_trait_plugin.dart';
import 'preview_card_trait_plugin.dart';
import 'identity_trait_plugin.dart';
import 'visual_identity_trait_plugin.dart';
import 'show_access_trait_plugin.dart';
import 'audiobook_specifics_plugin.dart';
import 'audiobook_price_plugin.dart';
import 'audio_preview_playback_trait_plugin.dart';
import 'preview_playback_trait_plugin.dart';
import 'promo_v1_trait_plugin.dart';
import 'promo_v3_trait_plugin.dart';
import 'concert_trait_plugin.dart';
import 'concert_location_trait_plugin.dart';
import 'concert_marketing_trait_plugin.dart';
import 'consumption_experience_trait_plugin.dart';
import 'track_v4_plugin.dart';
import 'episode_v4_plugin.dart';
import 'on_platform_reputation_trait_plugin.dart';
import 'credits_trait_plugin.dart';

export 'plugin_utils.dart';
export 'simple_card_trait_plugin.dart';
export 'shortcuts_card_trait_plugin.dart';
export 'preview_card_trait_plugin.dart';
export 'identity_trait_plugin.dart';
export 'visual_identity_trait_plugin.dart';
export 'show_access_trait_plugin.dart';
export 'audiobook_specifics_plugin.dart';
export 'audiobook_price_plugin.dart';
export 'audio_preview_playback_trait_plugin.dart';
export 'preview_playback_trait_plugin.dart';
export 'promo_v1_trait_plugin.dart';
export 'promo_v3_trait_plugin.dart';
export 'concert_trait_plugin.dart';
export 'concert_location_trait_plugin.dart';
export 'concert_marketing_trait_plugin.dart';
export 'consumption_experience_trait_plugin.dart';
export 'track_v4_plugin.dart';
export 'episode_v4_plugin.dart';
export 'on_platform_reputation_trait_plugin.dart';
export 'credits_trait_plugin.dart';

// ... [remaining code in source file] ...
```
