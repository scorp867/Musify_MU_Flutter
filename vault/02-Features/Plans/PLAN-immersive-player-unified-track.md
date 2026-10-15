# Player, Media, and Queue Design

This document describes the current player architecture and the shared media
model used by local playback.

## Media model

`DomainTrack` is the local music domain entity located at:

```text
lib/features/local_music/domain/entities/domain_track.dart
```

The entity contains display metadata, duration, local file path, MediaStore
identifier, artwork metadata, modification time, and source information.

The local music repository maps Drift `LocalTrack` records to `DomainTrack`
objects at the data boundary. Presentation code remains independent from
generated database types.

`MediaItemMapper` translates domain track values into `audio_service`
`MediaItem` values and centralizes the `songId` and `dataPath` metadata keys.

## Player presentation

The player is a draggable bottom sheet opened from `MiniPlayer`:

```text
features/player/presentation/
├── screens/player_screen.dart
└── widgets/
    ├── mini_player.dart
    ├── player_artwork.dart
    ├── player_controls.dart
    ├── player_header.dart
    ├── player_metadata.dart
    ├── player_sections.dart
    ├── player_sheets.dart
    └── player_theme.dart
```

`PlayerScreen` coordinates playback state and local interaction state. Focused
widgets render artwork, metadata, controls, lyrics, track details, queue
sheets, and options sheets.

## Queue pipeline

The queue has separate UI and backend responsibilities.

### Queue UI

`PlayerQueueSheet` lives in `features/player/presentation/widgets/` and:

- Observes the queue exposed by `PlaybackController`
- Displays the current item and queue items
- Opens artwork and metadata for each queue item
- Dispatches queue selection through `skipToQueueItem`

The sheet does not know about `just_audio`, Drift, or queue-window pagination.

### Queue backend

`PlaybackQueueManager` lives in `core/audio/` and:

- Stores the complete `MediaItem` queue
- Loads a window around the selected track
- Loads up to ten previous tracks and fifty upcoming tracks
- Appends upcoming batches near the end of the loaded window
- Prepends previous batches near the beginning of the loaded window
- Converts media items into audio sources

`AudioPlaybackService` owns the `AudioPlayer` and delegates queue-window work
to `PlaybackQueueManager`. `AudioNotificationHandler` coordinates the queue
with notification and background playback state. During queue initialization,
the requested initial media item remains authoritative until the player emits
the corresponding settled queue index.

## Interaction flow

```text
LocalMusicScreen
      ↓ MediaItemMapper
PlaybackController
      ↓
AudioNotificationHandler
      ↓
AudioPlaybackService → PlaybackQueueManager → just_audio
      ↓
PlayerQueueSheet / MiniPlayer / PlayerScreen
```

## Extension points

- Online tracks can use the same `MediaItemMapper` contract after an online
  domain model supplies equivalent media values.
- Queue persistence can be added behind `PlaybackController` while queue sheet
  presentation remains independent from persistence details.
- Lyrics, artist details, and favorites can become independent application
  services consumed by the focused player widgets.
