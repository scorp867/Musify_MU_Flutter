# Project Overview

**Musify MU** is a Flutter music application for discovering, organizing, and
playing music from local device storage while providing a foundation for
online music experiences.

## Product experience

- **Online and local modes**  -  the home experience switches between online
  discovery content and the local device library.
- **Local music library**  -  device music is queried through `on_audio_query`,
  synchronized into a Drift database, and presented as a browsable library.
- **Background playback**  -  `just_audio` and `audio_service` provide playback,
  notification controls, and lock-screen integration.
- **Sliding-window queue**  -  large queues load around the current track and
  grow forward or backward as playback moves through the queue.
- **Immersive player**  -  the mini player opens a draggable full player with
  artwork, metadata, transport controls, seek controls, queue access, lyrics,
  and track details.
- **Application shell**  -  the hidden drawer, bottom navigation, and mode
  transition provide the main navigation experience.

## Design direction

Musify MU uses a vibrant dark visual language designed for music and
entertainment products:

- Dark surfaces with blue and green accents
- Poppins typography
- Album artwork as a visual focus
- Clear hierarchy, compact controls, and responsive touch targets
- Motion used to communicate mode changes and player transitions
- Circular spotlight animation for online/local mode switching

## Source organization

The codebase is organized by ownership and responsibility:

- `lib/app/` owns application startup, dependency registration, and theme
- `lib/core/` owns reusable audio, media, and UI infrastructure
- `lib/features/local_music/` owns local music domain, data, sync, and UI
- `lib/features/home/` owns home-mode presentation
- `lib/features/shell/` owns navigation and drawer presentation
- `lib/features/player/` owns player presentation and queue sheets

See [[01-Architecture/System-Architecture|Architecture]] and [[01-Architecture/Project-Structure|project-structure]] for dependency rules.
