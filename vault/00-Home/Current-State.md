# Current State

Musify MU provides a feature-first Flutter application with local music
library support, background playback, a sliding-window queue, and a composed
player experience.

## Application shell

- `HiddenDrawerScaffold` presents the animated push drawer.
- `MainScreen` coordinates home, search, and library navigation tabs.
- `AppBottomNavigation` owns bottom-navigation presentation.
- `DrawerMenu` owns drawer profile and menu presentation.
- `ModeTransition` provides the circular spotlight transition between online
  and local modes.
- `HomeHeader` owns the home mode toggle and profile/menu entry points.

## Local music

- `DeviceMusicDataSource` owns device permissions, song queries, and MediaStore
  change observation.
- `LocalTracksStore` owns Drift database access for cached local tracks.
- `LocalMusicSyncService` compares device tracks with cached tracks and applies
  inserts, updates, and removals.
- `LocalMusicRepositoryImpl` combines the data sources and maps database rows
  to `DomainTrack` entities.
- `LocalMusicPlaybackSynchronizer` compares local entities with the active
  `MediaItem` and forwards relevant metadata changes through
  `PlaybackController`.
- `LocalMusicBloc` exposes local library loading, loaded, and error states to
  `LocalMusicScreen`.
- `LocalContextResolver` chunks offline device audio into discrete 50-track
  `ContextPage` instances with page URLs and pagination links, unifying offline
  playback with Spotify's Cosmos pagination architecture.
- Drift schema and generated code live together under
  `features/local_music/data/database/`.

## Playback and queue

- `AudioPlaybackService` owns the `just_audio` player and transport commands.
- `PlaybackQueueManager` owns the master linear track list (`_fullTracks`) and a
  2-slot gapless audio source pipeline in `just_audio` (Slot 0 active, Slot 1
  prefetched via `PrefetchLevel.media`), automatically auto-loading the next Cosmos
  page when approaching page boundaries.
- `PlayerQueue` and `ContextTrack` model Spotify's `com.spotify.player.model` 1:1,
  featuring a single linear `nextTracks` list as the single source of truth,
  dynamic `userQueue` / `contextTracks` partition getters, and delimiter detection.
- `QueueMutator` and `QueueFilterHelper` encapsulate all queue algebra
  (FIFO additions, play-next prepending, cross-partition drag-and-drop reordering,
  and page updates) with monotonic revision tracking.
- `QueueBloc` is registered as a lazy singleton in DI and provided at root in
  `app.dart`, eliminating split-brain state loss across `QueueSheetScreen` open/close cycles.
- `AudioNotificationHandler` bridges playback to `audio_service` notification
  and background playback controls, relaying queue changes via `onQueueChanged`.
- `AudioNotificationHandler` refreshes artwork into timestamped temporary files
  and publishes updated media items to notifications, the mini player, the full
  player, and the queue.
- `PlaybackController` is the contract consumed by presentation widgets and
  metadata synchronization, expanded with `setNextTracks` for atomic queue updates.
- `MediaItemMapper` centralizes media metadata, local path extras, modification
  timestamps, and artwork version metadata.

## Player presentation

The player presentation is composed from focused widgets:

- `MiniPlayer`  -  compact playback surface and progress indicator
- `PlayerScreen`  -  full-player orchestration and local UI state
- `PlayerArtwork`  -  artwork, backdrop, and fallback artwork
- `PlayerHeader`  -  player header and actions
- `PlayerMetadata`  -  title, artist, album, and favorite state
- `PlayerControls`  -  seek, transport, shuffle, repeat, queue, and lyrics
- `PlayerSections`  -  lyrics and track details sections
- `PlayerSheets`  -  queue, options, and track-details sheets
- `PlayerTheme`  -  player colors and shared player styling

## Quality baseline

- `flutter analyze` completes with no issues.
- `flutter test` covers the application-shell smoke test and active-media
  metadata synchronization.
- Drift generated code is maintained with `build_runner`.
- Presentation widgets receive playback contracts explicitly rather than
  resolving concrete services from the service locator.
