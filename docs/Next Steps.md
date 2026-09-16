# Next Steps

The current foundation supports local playback and the player experience. The
next product work extends the online experience, library capabilities, and
platform coverage.

## Online music

- Define the online music API boundary and data contracts.
- Add `features/online_music/` with domain entities, repository contracts,
  data sources, and presentation state.
- Replace online home placeholder content with repository-backed data.
- Add artwork, stream URL, caching, loading, empty, and error states.

## Search and library

- Create dedicated search and library features under `features/`.
- Search local cached tracks and online results through separate data sources.
- Add playlists, favorites, recently played, and persistent user preferences.
- Connect library actions to the existing `PlaybackController` contract.

## Player capabilities

- Connect lyrics to a lyrics data source and expose loading/error states.
- Add artist and album details backed by media metadata or online services.
- Persist favorite, shuffle, repeat, and queue preferences where appropriate.
- Add queue and playback unit tests around boundary conditions in the sliding
  window.

## Platform hardening

- Verify Android permission behavior across supported Android versions.
- Verify MediaStore change observation and synchronization on real devices.
- Validate background playback, notification controls, artwork refresh, queue
  navigation, and process restart behavior.
- Confirm local music support expectations for iOS, desktop, and web targets.

## Testing and delivery

- Add repository, synchronization, queue-manager, media-mapper, and formatter
  unit tests.
- Add focused widget tests for the local library, mini player, player sheets,
  and navigation shell.
- Add integration coverage for local scanning and background playback on
  supported platforms.
