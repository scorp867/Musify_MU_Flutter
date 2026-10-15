---
title: "update_page_command.dart"
path: "lib/features/player/domain/models/update_page_command.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player, command, pagination]
lines: 16
incoming_dependencies: 1
outgoing_dependencies: 1
---

# update_page_command.dart

> Source File: `[lib/features/player/domain/models/update_page_command.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/domain/models/update_page_command.dart)`
> Layer: `lib/features/player/domain/models`

## Executive Summary
`update_page_command.dart` defines `UpdatePageCommand`, matching Spotify's `com.spotify.player.model.command.UpdatePageCommand`. It communicates resolved `ContextPage` updates into the player engine to append new tracks dynamically as playback approaches page boundaries.

**Primary Architecture Role**: Domain Command / Value Object

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `context_page.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/context_page|context_page.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `queue_replication_test.dart` | `test/features/player` | [[04-Reference/test/features/player/queue_replication_test|queue_replication_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class UpdatePageCommand extends Equatable`
- **Archetype**: Domain Command
- **Extends**: `Equatable`

**Key Fields & Properties:**
| Field Name | Type | Description |
|------------|------|-------------|
| `page` | `ContextPage` | Resolved page payload to integrate |

**Methods & Handlers:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `create` | `UpdatePageCommand` | `ContextPage page` | Factory constructor |

## State & Data Flow Analysis
- Dispatched during Cosmos pagination when next page chunks are fetched and merged into the active queue.

## Implementation Highlight
```dart
import 'package:equatable/equatable.dart';
import 'context_page.dart';

/// 1:1 with Spotify's com.spotify.player.model.command.UpdatePageCommand
class UpdatePageCommand extends Equatable {
  final ContextPage page;

  const UpdatePageCommand({required this.page});

  factory UpdatePageCommand.create(ContextPage page) =>
      UpdatePageCommand(page: page);

  @override
  List<Object?> get props => [page];
}
```
