# Project structure

Musify MU uses a feature-first Flutter structure. Code is grouped by the
responsibility it owns rather than by the package or widget it happens to use.

```text
lib/
├── main.dart                         # Application entry point
├── app/
│   ├── app.dart                       # MaterialApp and root providers
│   ├── di/injection.dart              # Composition root / service locator
│   └── theme/app_theme.dart            # Application theme tokens
├── core/
│   ├── audio/                         # Audio, transport, and queue adapters
│   │   └── playback_queue_manager.dart # Sliding-window queue orchestration
│   ├── media/                         # Shared MediaItem metadata mapping
│   └── ui/
│       ├── animations/                # Reusable UI animations
│       └── formatters/                # Reusable display formatters
└── features/
    ├── home/presentation/             # Online/offline mode entry UI
    ├── shell/presentation/            # Drawer, navigation, and app shell
    ├── local_music/
    │   ├── domain/
    │   │   ├── entities/              # Local music domain models
    │   │   └── repositories/          # Domain contracts
    │   ├── application/               # Playback metadata synchronization
    │   ├── data/
    │   │   ├── database/              # Drift schema and generated code
    │   │   ├── datasources/            # Device and database access
    │   │   ├── repositories/           # Domain contract implementations
    │   │   └── services/               # Device-to-database synchronization
    │   └── presentation/               # Bloc, screens, and local-library UI
    └── player/
        └── presentation/
            ├── screens/                # Player screen orchestration
            └── widgets/                # Artwork, controls, queue, and sheets
```

## Dependency rules

- `main.dart` and `app/di` are the only composition-root locations. Feature
  widgets receive dependencies explicitly instead of resolving concrete
  services themselves.
- `core` contains reusable contracts/adapters and must not depend on feature
  presentation code.
- A feature's presentation layer depends on its domain contracts and shared
  core abstractions, not on database-generated types.
- Local music synchronization owns permissions, device querying, change
  observation, database writes, and mapping inside its data layer.
- Generated Drift output stays beside its source schema. Regenerate it with:

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

## Where new code belongs

| New code | Location |
| --- | --- |
| App-wide startup, theme, or dependency registration | `lib/app/` |
| Reusable audio, media, or UI infrastructure | `lib/core/` |
| Local device music behavior | `lib/features/local_music/` |
| Local metadata to active playback synchronization | `lib/features/local_music/application/` |
| Navigation/drawer/bottom navigation | `lib/features/shell/presentation/` |
| Online home experience | `lib/features/home/` |
| Playback/player experience | `lib/features/player/` |
| Sliding-window audio queue policy | `lib/core/audio/playback_queue_manager.dart` |
| Widget or unit tests | `test/`, mirroring the production area where practical |

Platform folders (`android/`, `ios/`, `web/`, `windows/`, `macos/`, and
`linux/`) remain at the project root because Flutter tooling expects them
there. Generated/build folders are not part of the application source layout.
