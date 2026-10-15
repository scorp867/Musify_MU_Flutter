---
title: "command_options.dart"
path: "lib/features/player/domain/models/command_options.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player, command, options]
lines: 47
incoming_dependencies: 2
outgoing_dependencies: 0
---

# command_options.dart

> Source File: `[lib/features/player/domain/models/command_options.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/domain/models/command_options.dart)`
> Layer: `lib/features/player/domain/models`

## Executive Summary
`command_options.dart` provides `CommandOptions`, replicating `com.spotify.player.model.command.options.CommandOptions`. It encapsulates metadata parameters accompanying commands sent to the player engine (such as restriction overrides, local-device constraints, playback IDs, and system-initiated flags).

**Primary Architecture Role**: Domain Model / Command Options

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- Leaf component: No internal project dependencies.

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `set_queue_command.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/set_queue_command|set_queue_command.dart]] |
| `queue_replication_test.dart` | `test/features/player` | [[04-Reference/test/features/player/queue_replication_test|queue_replication_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class CommandOptions`
- **Archetype**: Domain Model / Command Options

**Key Fields & Properties:**
| Field Name | Type | Description |
|------------|------|-------------|
| `overrideRestrictions` | `bool` | Whether to ignore catalog restriction rules |
| `onlyForLocalDevice` | `bool` | Restricts action strictly to current device |
| `onlyForPlaybackId` | `String?` | Guards against stale asynchronous commands |
| `systemInitiated` | `bool` | True if triggered by automated system event |
| `empty` | `CommandOptions` | Default configuration constant |

**Methods & Handlers:**
| Method | Return Type | Parameters | Description |
|--------|-------------|------------|-------------|
| `copyWith` | `CommandOptions` | Parameter overrides | Immutability copy helper |
| `toJson` | `Map<String, dynamic>` | None | Serialization to JSON map |
| `fromJson` | `CommandOptions` | `Map<String, dynamic> json` | Factory deserializer |

## State & Data Flow Analysis
- Carried within `SetQueueCommand` and other player command payloads to validate and coordinate engine instructions.

## Implementation Highlight
```dart
/// 1:1 with com.spotify.player.model.command.options.CommandOptions
class CommandOptions {
  const CommandOptions({
    this.overrideRestrictions = false,
    this.onlyForLocalDevice = false,
    this.onlyForPlaybackId,
    this.systemInitiated = false,
  });

  static const CommandOptions empty = CommandOptions();
// ...
```
