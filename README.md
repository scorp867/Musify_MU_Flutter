# Musify MU

Your Music, Your Way.

Musify MU is a Flutter music application with local-device music discovery,
background playback, queue management, and online/offline home modes.

## Project structure

The application is organized by feature and responsibility:

- `lib/app/` — application bootstrap, dependency registration, and theme
- `lib/core/` — reusable audio, media, UI, and platform abstractions
- `lib/features/local_music/` — local music domain, Drift data layer, sync, and UI
- `lib/features/home/` — online/offline home presentation
- `lib/features/shell/` — drawer, navigation, and app shell
- `lib/features/player/` — mini player and full player presentation
- `test/` — automated tests
- `vault/docs/project-structure.md` — dependency rules and placement guide

See [docs/project-structure.md](vault/docs/project-structure.md) before adding a new
file so responsibilities stay in the right layer.

## Development

```bash
flutter pub get
flutter analyze
flutter test
```

If the Drift schema changes, regenerate the database code with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Flutter platform directories remain at the project root because Flutter
expects them there. Build and tool-generated directories are ignored and are
not application source.
