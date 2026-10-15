# Architecture

Musify MU uses a feature-first structure with BLoC for presentation state and
explicit dependency injection from the application composition root.

## Directory structure

```text
lib/
├── main.dart                         # Flutter entry point
├── app/
│   ├── app.dart                       # MaterialApp and root composition
│   ├── di/injection.dart              # get_it registrations
│   └── theme/app_theme.dart            # Shared theme tokens
├── core/
│   ├── audio/                         # Transport and queue infrastructure
│   │   └── playback_queue_manager.dart # 2-slot gapless prefetch queue policy
│   ├── media/                         # MediaItem metadata mapping
│   ├── network/spotify/               # Spotify HTTP infrastructure
│   │   ├── auth/                      # Token store, refresher, TOTP, session provider
│   │   └── transport/                 # Abstract transport, WebPlayer + Android impls
│   └── ui/                            # Shared animations and formatters
└── features/
    ├── auth/                          # Auth BLoC, profile fetcher, login WebView
    ├── home/presentation/             # Online home and mode entry point
    │   └── widgets/                   # Home header
    ├── shell/presentation/            # Drawer and bottom navigation
    │   └── widgets/                   # Drawer menu and bottom navigation
    ├── local_music/
    │   ├── domain/                    # Entities, repository contracts, and local_context_resolver
    │   ├── application/               # Active playback metadata sync
    │   ├── data/                      # Drift, device data, sync, repository
    │   └── presentation/              # BLoC and local-library screens
    └── player/
        ├── domain/                    # PlayerQueue, ContextTrack, QueueMutator, QueueFilterHelper
        ├── application/               # QueueBloc (singleton session queue state)
        └── presentation/              # Screens, artwork, controls, and sheets
```

The complete placement guide is in
[`ect-structure.md`](project-structure.md).

## Dependency direction

```text
app composition root
        ↓
feature presentation → feature domain contracts
        ↓                       ↑
feature data → core abstractions ┘
        ↓
core/network/spotify/transport (SpotifyTransport)
        ↓
core/network/spotify/auth (AuthSessionProvider)
```

- `main.dart` and `app/di/injection.dart` construct concrete services.
- Presentation widgets receive contracts explicitly; they do not resolve
  concrete services from `get_it`.
- Feature data layers depend on `SpotifyTransport` (abstract), never on
  auth internals like token stores, refreshers, or TOTP.
- `AuthSessionProvider` composes token store, refresher, and client token
  fetcher behind a single interface that transports consume.
- `WebPlayerTransport` and `AndroidTransport` implement `SpotifyTransport`
  with platform-specific identity headers. Callers needing both (e.g.
  library) receive both via constructor injection.
- The local music repository contract lives in `local_music/domain`; its
  implementation is in `local_music/data`.
- Device querying, permission handling, MediaStore observation, Drift access,
  and local-library synchronization are separate data responsibilities.
- `LocalMusicPlaybackSynchronizer` is the application boundary between local
  domain changes and active playback metadata; the BLoC never depends on the
  concrete audio notification handler.
- Generated Drift code stays next to `app_database.dart` and must be rebuilt
  through `build_runner` rather than edited manually.
- `core` must remain independent from feature presentation code.

## Tech stack

### State management

- `flutter_bloc` for predictable feature state.
- `equatable` for value-based BLoC event and state comparison.

### Dependency injection

- `get_it` is limited to the application composition root in
  `../../lib/app/di/injection.dart`.

### Database

- `drift` provides the type-safe SQLite schema and generated database access.
- `sqlite3_flutter_libs` provides native SQLite bindings.

### Audio and scanning

- `on_audio_query` handles device permissions and local music metadata.
- `just_audio` and `audio_service` provide playback and background notification
  integration.
- `PlaybackQueueManager` owns queue-window state and pagination; player UI
  queue sheets only render and dispatch queue actions through
  `PlaybackController`.
