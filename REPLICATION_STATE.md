# REPLICATION STATE

## 2. STRICT 1:1 FIDELITY RULES
- **Exact Replication:** Replicate Spotify's exact architecture, system design, logic, directory/file structure, domains, classes, objects, structs, enums, models, states, events, errors, getters, setters, methods, functions, and arguments.
- **Ditto Translation:** I don't want code "LIKE SPOTIFY" or "MATCHES WITH SPOTIFY", i STRICTLY want code and implementation of spotify, whatever or however they are doing it.
- **No Extra or Own Code:** Do NOT create your own logic or your own methods or any other methods or logics which are not in spotify.
- **Accurate Files:** Create as many files as there are in spotify, don't merge 2 or more files into one to create a monolithic file.
- **Existing code refactor:** if existing files are merged but in spotify they have separate files then break the file into their respective files with respective names (deobfuscated).
- **Zero Invention:** Do NOT invent custom logic, helper methods, wrapper classes, or abstractions that do not exist in Spotify. Strictly trace, translate, and replicate/refactor if current code doesn't follow Spotify.
- **Zero Placeholders:** No `TODO`s, mocks, stubs, simplified fallbacks, or hardcoded values anywhere.
- **Serialization:** Use **Protobufs ONLY**. Use JSON strictly and exclusively where Spotify itself uses JSON.

## 3. ARCHITECTURE MAPPING (DART vs. NATIVE)
## THIS IS MUST
- **Java -> Dart:** Anything Spotify implements in Java MUST be implemented in Dart.
- **Native (.so) -> Native:** Anything Spotify implements in the native `.so` library MUST be implemented in Native code.
- **Eliminate Duplication:** Do NOT duplicate logic across Dart and Native. Audit existing Dart code and strip out all logic that Spotify handles in Native.

## 4. SOURCES OF TRUTH & DECOMPILATION
- Cross-reference all three sources for 100% accuracy:
  1. Decompiled Java source: `/home/Downloads/Spotify_decompiled`
  2. The original native `.so` library
  3. The memory dump (`memdump`)
- **Strict Boundary:** Do NOT reference or deviate into any other external directories.
- **Re-decompilation Permitted:** If any decompiled file is ambiguous or incomplete, you are authorized to run the decompiler again on specific files with custom arguments/flags to get exact output.

## 5. ACTIVE SCOPE & SEQUENTIAL WORKFLOW
- **Current Focus Scope:** Player, Commands, Queue, and all directly related components.
- **Execution Order:**
  1. Audit all existing files in the current scope against the sources of truth.
  2. Work strictly **one file at a time, one class at a time**.
  3. Refactor the current class/file to match Spotify 1:1, strip redundant Dart/Native duplication, verify completeness, update `REPLICATION_STATE.md`, and immediately proceed to the next item in the queue.

## 6. COMMUNICATION POLICY
- **No Socratic or Design Questions:** Do NOT ask how something should be designed or how edge cases should be handled—Spotify's code already defines every edge case. Look it up in the Java source, `.so`, or `memdump`.
- Ask a question ONLY if blocked by a missing file or system permission error that you cannot resolve via terminal tools.
- Begin immediately by creating/reading `REPLICATION_STATE.md` and auditing the current scope.

---

## REPLICATION PROGRESS TRACKER

##### In Progress
- **Active Item:** None (Phase 12G Items 172–180 and full Phase 12A–12G ConnectState & DoDo replication Items 107–180 complete and verified).
- **Status:** Complete & Verified: All 74 Connect State, DoDo, and R2 modularity items (Items 107–180) are implemented 1:1 across the C++20 native engine (`android/app/src/main/cpp/connect/`), Esperanto FFI bridge, Dart domain/data/Mobius/UI layers (`lib/features/connect/`), and Player/Shell/DI/App wiring (`lib/features/player/`, `lib/features/shell/`, `lib/app/`). Item 180 cross-phase verification gate passed (C++20 NDK CMake build `[321/321]` with 0 errors/0 warnings and 12 exported `musify_connect_`/`musify_dodo_` symbols, scoped `flutter analyze` 0 issues, `flutter analyze lib/` 0 errors/0 warnings, `348/348` Item 180 tests + `68/68` core unit tests with 1 pre-existing skip).
- **Completed in Phase 11 (Native Architecture Parity — C++ ContextPlayerImpl):**
  1. `android/app/src/main/cpp/player/ContextPlayerImpl.h` (Item 99): C++ header matching `liborbit-jni-spotify.so` — PlayTrackCallback, StateChangedCallback, QueueChangedCallback, ErrorCallback, 26 command methods, thread-safe state.
  2. `android/app/src/main/cpp/player/ContextPlayerImpl.cpp` (Item 100): Full 1567-line C++ implementation — manual protobuf wire parsing, `handle_command` string dispatch, `advanceToNextTrack` EOS, `RoutingTrackPlayer` pause/stop during advancement, user queue interleaving, state protobuf emission (fields 1-31). NDK 28 Clang C++20: 0 errors.
  3. `android/app/src/main/cpp/player/RestrictionsEngine.h` (Item 101): 1:1 `RestrictionsSetupImpl` — 26 restriction fields matching `spotify.player.proto.Restrictions` (fields 1-26).
  4. `android/app/src/main/cpp/player/StateEmitter.h` (Item 102): `ContextPlayerState` & Queue protobuf wire encoder using `ProtobufWireHelper.h`.
  5. `android/app/src/main/cpp/ffi_bridge.cpp` (Item 103): 14 CPI FFI exports + `Dart_PostCObject_DL` NativePort callbacks + `musify_init_dart_api_dl`.
  6. `lib/core/audio/musify_ffi_bindings.dart` (Item 104): 13 CPI FFI lookups + late final function pointers + public API methods.
  7. `lib/features/player/data/esperanto/native_esperanto_transport.dart` (Item 105): Rewritten 983→321 lines, thin FFI bridge using `_engine.handle`. Fixed duplicate AudioEngine bug.
  8. `android/app/src/main/cpp/CMakeLists.txt` (Item 106): Updated for CPI + `dart_api_dl.c`.
  9. Zero analyzer issues (`flutter analyze`: No issues found).
  10. 100% test pass rate (211/211 passed, 1 skipped).
- **Completed in Phase 12A (Exhaustive Forensics & Master Inventory):**
  - Scanned `/home/Downloads/Spotify_decompiled/sources/com/spotify/connect`, `/home/Downloads/Spotify_decompiled/sources/p199p/`, `/home/Downloads/Spotify_decompiled/resources/lib/arm64-v8a/liborbit-jni-spotify.so`, and `/home/Downloads/Spotify_decompiled/memdump/liborbit-jni-spotify_memdump.so`.
  - Enumerated Items 107 through 180 covering Protobuf wire schemas, Native C++ Connect State engine, Esperanto RPC services & FFI bridge, Dart clients/models/mappers, Mobius loops, Room/SQLite device sorting comparator, R2 modularity extractions, and Output Switcher UI.

---

### Scope Queue

#### Phase 1: Player Commands (`com.spotify.player.model.command`) — [ALL COMPLETED 1:1]
1. [x] `lib/features/player/domain/commands/command.dart` (`Command.java`)
2. [x] `lib/features/player/domain/commands/add_to_queue_command.dart` (`AddToQueueCommand.java`, `AutoValue_AddToQueueCommand.java`)
3. [x] `lib/features/player/domain/commands/pause_command.dart` (`PauseCommand.java`, `AutoValue_PauseCommand.java`)
4. [x] `lib/features/player/domain/commands/play_as_next_in_queue_command.dart` (`PlayAsNextInQueueCommand.java`, `AutoValue_PlayAsNextInQueueCommand.java`)
5. [x] `lib/features/player/domain/commands/play_command.dart` (`PlayCommand.java`, `AutoValue_PlayCommand.java`)
6. [x] `lib/features/player/domain/commands/play_session_command.dart` (`PlaySessionCommand.java`, `AutoValue_PlaySessionCommand.java`)
7. [x] `lib/features/player/domain/commands/prepare_play_command.dart` (`PreparePlayCommand.java`, `AutoValue_PreparePlayCommand.java`)
8. [x] `lib/features/player/domain/commands/resume_command.dart` (`ResumeCommand.java`, `AutoValue_ResumeCommand.java`)
9. [x] `lib/features/player/domain/commands/seek_to_command.dart` (`SeekToCommand.java`, `AutoValue_SeekToCommand.java`)
10. [x] `lib/features/player/domain/commands/set_options_command.dart` (`SetOptionsCommand.java`, `AutoValue_SetOptionsCommand.java`)
11. [x] `lib/features/player/domain/commands/set_queue_command.dart` (`SetQueueCommand.java`, `AutoValue_SetQueueCommand.java`)
12. [x] `lib/features/player/domain/commands/set_repeating_context_command.dart` (`SetRepeatingContextCommand.java`, `AutoValue_SetRepeatingContextCommand.java`)
13. [x] `lib/features/player/domain/commands/set_repeating_track_command.dart` (`SetRepeatingTrackCommand.java`, `AutoValue_SetRepeatingTrackCommand.java`)
14. [x] `lib/features/player/domain/commands/set_shuffling_context_command.dart` (`SetShufflingContextCommand.java`, `AutoValue_SetShufflingContextCommand.java`)
15. [x] `lib/features/player/domain/commands/set_sleep_timer_command.dart` (`SetSleepTimerCommand.java`, `AutoValue_SetSleepTimerCommand.java`)
16. [x] `lib/features/player/domain/commands/signal_command.dart` (`SignalCommand.java`, `AutoValue_SignalCommand.java`)
17. [x] `lib/features/player/domain/commands/skip_to_next_track_command.dart` (`SkipToNextTrackCommand.java`, `AutoValue_SkipToNextTrackCommand.java`)
18. [x] `lib/features/player/domain/commands/skip_to_prev_track_command.dart` (`SkipToPrevTrackCommand.java`, `AutoValue_SkipToPrevTrackCommand.java`)
19. [x] `lib/features/player/domain/commands/stop_command.dart` (`StopCommand.java`, `AutoValue_StopCommand.java`)
20. [x] `lib/features/player/domain/commands/update_context_command.dart` (`UpdateContextCommand.java`, `AutoValue_UpdateContextCommand.java`)
21. [x] `lib/features/player/domain/commands/update_page_command.dart` (`UpdatePageCommand.java`, `AutoValue_UpdatePageCommand.java`)
22. [x] `lib/features/player/domain/commands/update_track_command.dart` (`UpdateTrackCommand.java`, `AutoValue_UpdateTrackCommand.java`)
23. [x] `lib/features/player/domain/commands/update_view_uri_command.dart` (`UpdateViewUriCommand.java`, `AutoValue_UpdateViewUriCommand.java`)

#### Phase 2: Player Command Options (`com.spotify.player.model.command.options`) — [ALL COMPLETED 1:1]
24. [x] `lib/features/player/domain/commands/options/command_options.dart` (`CommandOptions.java`, `AutoValue_CommandOptions.java`)
25. [x] `lib/features/player/domain/commands/options/logging_params.dart` (`LoggingParams.java`, `AutoValue_LoggingParams.java`)
26. [x] `lib/features/player/domain/commands/options/player_option_overrides.dart` (`PlayerOptionOverrides.java`, `AutoValue_PlayerOptionOverrides.java`)
27. [x] `lib/features/player/domain/commands/options/play_operation.dart` (`PlayOperation.java`)
28. [x] `lib/features/player/domain/commands/options/play_options.dart` (`PlayOptions.java`, `AutoValue_PlayOptions.java`)
29. [x] `lib/features/player/domain/commands/options/play_trigger.dart` (`PlayTrigger.java`)
30. [x] `lib/features/player/domain/commands/options/prefetch_level.dart` (`PrefetchLevel.java`)
31. [x] `lib/features/player/domain/commands/options/prepare_play_options.dart` (`PreparePlayOptions.java`, `AutoValue_PreparePlayOptions.java`)
32. [x] `lib/features/player/domain/commands/options/restore_paused.dart` (`RestorePaused.java`)
33. [x] `lib/features/player/domain/commands/options/skip_to_prev_track_options.dart` (`SkipToPrevTrackOptions.java`)
34. [x] `lib/features/player/domain/commands/options/skip_to_track.dart` (`SkipToTrack.java`, `AutoValue_SkipToTrack.java`)
35. [x] `lib/features/player/domain/commands/options/timer_type.dart` (`TimerType.java`, `AutoValue_TimerType_*.java`)

#### Phase 3: Player Models (`com.spotify.player.model`) — [ALL COMPLETED 1:1]
36. [x] `lib/features/player/domain/models/player_queue.dart` (`PlayerQueue.java`, `AutoValue_PlayerQueue.java`)
37. [x] `lib/features/player/domain/models/player_state.dart` (`PlayerState.java`, `AutoValue_PlayerState.java`) — Purged `playbackSpeed ?? 0.0`
38. [x] `lib/features/player/domain/models/context.dart` (`Context.java`, `AutoValue_Context.java`)
39. [x] `lib/features/player/domain/models/context_track.dart` (`ContextTrack.java`, `AutoValue_ContextTrack.java`)
40. [x] `lib/features/player/domain/models/context_page.dart` (`ContextPage.java`, `AutoValue_ContextPage.java`)
41. [x] `lib/features/player/domain/models/context_index.dart` (`ContextIndex.java`, `AutoValue_ContextIndex.java`)
42. [x] `lib/features/player/domain/models/player_options.dart` (`PlayerOptions.java`, `AutoValue_PlayerOptions.java`)
43. [x] `lib/features/player/domain/models/restrictions.dart` (`Restrictions.java`, `AutoValue_Restrictions.java`, `AutoValue_Restrictions_ModeRestrictions.java`, `AutoValue_Restrictions_RestrictionReasons.java`)
44. [x] `lib/features/player/domain/models/suppressions.dart` (`Suppressions.java`, `AutoValue_Suppressions.java`)
45. [x] `lib/features/player/domain/models/play_origin.dart` (`PlayOrigin.java`, `AutoValue_PlayOrigin.java`)
46. [x] `lib/features/player/domain/models/playback_quality.dart` (`PlaybackQuality.java`, `AutoValue_PlaybackQuality.java`)
47. [x] `lib/features/player/domain/models/pause_resume_origin.dart` (`PauseResumeOrigin.java`, `AutoValue_PauseResumeOrigin.java`)
48. [x] `lib/features/player/domain/models/player_error.dart` (`PlayerError.java`, `AutoValue_PlayerError.java`)
49. [x] `lib/features/player/domain/models/player_session.dart` (`PlayerSession.java`, `AutoValue_PlayerSession.java`)
50. [x] `lib/features/player/domain/models/sleep_timer.dart` (`SleepTimer.java`)
51. [x] `lib/features/player/domain/models/ad_break_context.dart` (`AdBreakContext.java`, `AutoValue_AdBreakContext.java`)
52. [x] `lib/features/player/domain/models/audio_stream.dart` (`AudioStream.java`)
53. [x] `lib/features/player/domain/models/bitrate_level.dart` (`BitrateLevel.java`)
54. [x] `lib/features/player/domain/models/bitrate_strategy.dart` (`BitrateStrategy.java`)
55. [x] `lib/features/player/domain/models/error_type.dart` (`ErrorType.java`)
56. [x] `lib/features/player/domain/models/file_origin.dart` (`FileOrigin.java`)
57. [x] `lib/features/player/domain/models/format.dart` (`Format.java`)
58. [x] `lib/features/player/domain/models/hifi_status.dart` (`HiFiStatus.java`)

#### Phase 4: Esperanto Clients & Wire Mappers — [ALL COMPLETED 1:1]
59. [x] `lib/features/player/data/esperanto/context_player_queue_client.dart` (`p199p/pvy.java`) — Purged `late` field, enforced 1:1 `queueStream`
60. [x] `lib/features/player/data/esperanto/context_player_control_client.dart` (`p199p/nvy.java`, `p199p/hvy.java`, `p199p/ivy.java`, `p199p/jvy.java`, `p199p/dvy.java`, `p199p/evy.java`, `p199p/fvy.java`, `p199p/gvy.java`)
61. [x] `lib/features/player/data/esperanto/context_player_options_client.dart` (`p199p/ovy.java`) — Purged `??` and `!` operators
62. [x] `lib/features/player/data/esperanto/context_player_play_client.dart` (`p199p/avy.java`)
63. [x] `lib/features/player/data/esperanto/context_player_state_client.dart` (`p199p/rvy.java`) — Purged swallowed exceptions and non-exhaustive switch
64. [x] `lib/features/player/data/esperanto/context_player_play_prepared_client.dart` (`p199p/svy.java`) — Purged `??` operator
65. [x] `lib/features/player/data/esperanto/queue_proto_mappers.dart` (`p199p/dal0.java`, `p199p/frl.java`, `p199p/qrl1.java`, `p199p/ltl1.java`, `p199p/n8y.java`) — Safely parses queueRevision via pattern-matched `Int64.tryParseInt` with zero-default parity.
66. [x] `lib/features/player/data/esperanto/player_state_proto_mappers.dart` (`p199p/n8y.java`, `p199p/m250.java`, `p199p/f111.java`, `p199p/lrs0.java`)
67. [x] `lib/features/player/data/esperanto/context_player_component.dart` (`p199p/afs0.java` lines 160-205)
68. [x] `lib/features/player/data/esperanto/esperanto_transport.dart` (`com/spotify/esperanto/esperanto/Transport.java`, `ClientBase.java`)
69. [x] `lib/features/player/data/esperanto/native_esperanto_transport.dart` (`com/spotify/esperanto/esperantoimpl/NativeTransport.java`) — Purged `??`, `!`, `late`, and empty catch blocks.

#### Phase 5: Queue Application & Mobius Loop — [ALL COMPLETED 1:1]
70. [x] `lib/features/player/application/queue/player_queue_bloc.dart` (`p199p/mgx0.java` / `p199p/lgx0.java`) — Refactored to pure `PlayerQueueMobiusController` running `MobiusLoop`, implementing `ValueListenable<PlayerQueueState>`, zero BLoC internals, zero `late` fields.
71. [x] `lib/features/player/application/queue/player_queue_event.dart` (`p199p/xdx0.java`) — Sealed event root with final subclasses matching Spotify's `xdx0` event hierarchy.
72. [x] `lib/features/player/application/queue/player_queue_state.dart` (`p199p/ehx0.java`) — Full AutoValue copy semantics, zero `??`, zero `!`.
73. [x] `lib/features/player/application/queue/mobius/queue_effect_handler.dart` (`p199p/tbx0.java`, `p199p/ibx0.java`) — Exhaustive pattern matching routing effects to ContextPlayer clients.
74. [x] `lib/features/player/application/queue/mobius/queue_effects.dart` (`p199p/u9x0.java`) — Sealed effect root with final subclasses.
75. [x] `lib/features/player/application/queue/mobius/queue_mobius_update.dart` (`p199p/svd0.java`, `p199p/jcv0.java` `m54765n`) — Purged local shuffling, exhaustive switch expression.

#### Phase 6: Native Engine (ContextProcessor / AudioEngine in Native C++) — [ALL COMPLETED 1:1]
76. [x] `android/app/src/main/cpp/ContextProcessor.cpp` & `ContextProcessor.h` (1:1 with `liborbit.so` assembly 0x3cea34, 0x16b81d4, 0xf564d6, 0xfb85bc, 0x16a7530, 0xf5529c)
77. [x] `android/app/src/main/cpp/AudioEngine.cpp` & `AudioEngine.h` (dual-source Vorbis/AAC handover, Oboe real-time audio)
78. [x] `android/app/src/main/cpp/ffi_bridge.cpp` & `lib/core/audio/musify_ffi_bindings.dart` (leaf optimizations, safe C-ABI memory deallocation)

#### Phase 7: Queue Handlers & Filtering (`data/queue`) — [ALL COMPLETED 1:1]
79. [x] `lib/features/player/data/queue/context_track_extensions.dart` (`p199p/ock1.java`, `p199p/ybb1.java`, `p199p/s5j.java`)
80. [x] `lib/features/player/data/queue/queue_helpers.dart` (`p199p/xos0.java`, `p199p/hxl0.java`)
81. [x] `lib/features/player/data/queue/queue_clear_handler.dart` (`p199p/bjm0.java` case 21, `p199p/kbx0.java`)
82. [x] `lib/features/player/data/queue/queue_remove_handler.dart` (`p199p/sfo0.java` case 27, `p199p/ock1.m68168i0`)
83. [x] `lib/features/player/data/queue/queue_add_handler.dart` (`p199p/tm1.java` case 26, `p199p/hbx0.java` case 0)
84. [x] `lib/features/player/data/queue/queue_reorder_handler.dart` (`p199p/sbx0.java`, `p199p/lr5.java`)
85. [x] `lib/features/player/data/queue/queue_track_filter.dart` (`p199p/s5j.java`, `p199p/ock1.java`)
86. [x] `lib/features/player/data/queue/queue_membership_checker.dart` (`p199p/vnl0.java`)

#### Phase 8: Audio Stream Resolvers & Coordinators (`data/services`) — [ALL COMPLETED 1:1]
87. [x] `lib/features/player/data/services/spotify_hex_utils.dart`
88. [x] `lib/features/player/data/services/spotify_head_resolver.dart`
89. [x] `lib/features/player/data/services/spotify_storage_resolver.dart`
90. [x] `lib/features/player/data/services/spotify_license_resolver.dart` — Purged `!` and `??` operators.
91. [x] `lib/features/player/data/services/spotify_audio_stream_coordinator.dart` — Preserving head playing, secondary stream attaching, Widevine DRM licensing, and handover.

#### Phase 9: Now Playing Scroll & Cards Pipeline (`application/scroll`) — [ALL COMPLETED 1:1]
92. [x] `lib/features/player/application/scroll/now_playing_scroll_state.dart` — Purged banned `!` assertion.
93. [x] `lib/features/player/application/scroll/now_playing_scroll_event.dart`
94. [x] `lib/features/player/application/scroll/now_playing_scroll_bloc.dart` (`NowPlayingScrollController`) — Purged BLoC base class and banned `??` operators.

#### Phase 10: Presentation Layer (Queue & Player Screens/Widgets) — [ALL COMPLETED 1:1]
95. [x] `lib/features/player/presentation/widgets/queue_controls_layout.dart` (`com/spotify/nowplayingqueue/bottomsheet/view/QueueControlsLayout.java`)
96. [x] `lib/features/player/presentation/screens/queue_sheet_screen.dart` (`com/spotify/nowplayingqueue/`)
97. [x] `lib/features/player/presentation/widgets/mini_player.dart` (`com/spotify/nowplayingmini/`)
98. [x] `lib/features/player/presentation/screens/player_screen.dart` (`com/spotify/nowplaying/`)

#### Phase 11: Native Architecture Parity (C++ ContextPlayerImpl) — [ALL COMPLETED 1:1]
99. [x] `android/app/src/main/cpp/player/ContextPlayerImpl.h` — C++ header matching `liborbit-jni-spotify.so` ContextPlayerImpl
100. [x] `android/app/src/main/cpp/player/ContextPlayerImpl.cpp` — Full 1567-line C++ implementation (command dispatch, EOS advance, state/queue protobuf emission, restrictions)
101. [x] `android/app/src/main/cpp/player/RestrictionsEngine.h` — 1:1 `RestrictionsSetupImpl` with 26 restriction fields
102. [x] `android/app/src/main/cpp/player/StateEmitter.h` — ContextPlayerState & Queue protobuf wire encoder
103. [x] `android/app/src/main/cpp/ffi_bridge.cpp` — 14 CPI FFI exports + `Dart_PostCObject_DL` NativePort callbacks
104. [x] `lib/core/audio/musify_ffi_bindings.dart` — 13 CPI FFI lookups + public API methods
105. [x] `lib/features/player/data/esperanto/native_esperanto_transport.dart` — Rewritten 983→321 lines, thin FFI bridge using `_engine.handle`
106. [x] `android/app/src/main/cpp/CMakeLists.txt` — Updated build config for CPI + dart_api_dl

#### Phase 12A: Forensics & Master Inventory — [COMPLETED]
- Items scanned, verified, and mapped to exact source files, binary offsets, and target paths.

#### Phase 12B: Protobuf Schemas & Wire Descriptors (`protos/spotify/connect/` & `protos/esperanto/`) — [ALL COMPLETED 1:1]
107. [x] `protos/spotify/connect/cluster.proto` (`ClusterUpdate`, `Cluster`) — Sources: `liborbit-jni-spotify_memdump.so` offset `0x3fa5c2` (`connect.proto`), `0x3fdc96` (`connect-service.proto`).
108. [x] `protos/spotify/connect/devices.proto` (`DeviceInfo`, `Capabilities`, `AudioOutputDeviceInfo`, `DodoDeviceInfo`, `DeviceAliases`) — Sources: `liborbit-jni-spotify_memdump.so` offset `0x3fe006` (`devices.proto`).
109. [x] `protos/spotify/connect/player.proto` (`PlayerState`, `PlaybackQuality`, `ContextIndex`) — Sources: `liborbit-jni-spotify_memdump.so` offset `0x3fe6e6` (`player.proto`).
110. [x] `protos/spotify/connect/connect.proto` (`PutStateRequest`, `PutStateRequestWrapper`, `PutStateReason`, `ConnectCommand`) — Sources: `liborbit-jni-spotify_memdump.so` offset `0x3fa5c2`.
111. [x] `protos/spotify/connect/group.proto` (`GroupData`, `GroupDevice`, `GroupCapabilities`, `GroupDeviceIdentifiers`, `GroupDeviceCapabilities`, `GroupDeviceVolume`) — Sources: `ConnectMessages$GroupData.java`.
112. [x] `protos/esperanto/connect_messages.proto` & `lib/features/connect/data/proto/es_connect_messages.pb.dart` (`ConnectMessages$StateRequest`, `StateResponse`, `Device`, `Hifi`, `Incarnation`, `OutputPeripheral`, `TransferRequest`, `PullRequest`, `LogoutRequest`, `NotifyAudioRouteChangedRequest`, `SetPreferredIncarnationRequest`, `AddDeviceToGroupRequest`/`Response`, `RemoveDeviceFromGroupRequest`/`Response`, `ClusterUpdateAfterBackendConnectionResponse`, `InstallSpotifyRequest`/`StatusUpdate`) — Sources: `com/spotify/connect/esperanto/proto/ConnectMessages.java`.
113. [x] `protos/esperanto/volume_messages.proto` & `lib/features/connect/data/proto/es_volume_messages.pb.dart` (`VolumeResponse`, `VolumeSetRequest`, `VolumeUpRequest`, `VolumeDownRequest`) — Sources: `com/spotify/connect/esperanto/proto/VolumeMessages.java`.
114. [x] `protos/esperanto/common_messages.proto` & `lib/features/connect/data/proto/es_common_messages.pb.dart` (`LoggingParams`, `StatusResponse`) — Sources: `com/spotify/connect/esperanto/proto/CommonMessages.java`.
115. [x] `protos/esperanto/cast_messages.proto` & `lib/features/connect/data/proto/es_cast_messages.pb.dart` (`DeviceId`, `PutDeviceRequest`, `ConnectionErrorRequest`, `ConnectRequest`, `Response`) — Sources: `com/spotify/connect/discovery/cast/esperanto/proto/CastMessages.java`.

#### Phase 12C: Native C++ Connect State Engine (`android/app/src/main/cpp/connect/`) — [ALL COMPLETED 1:1]
116. [x] `android/app/src/main/cpp/connect/ConnectStateProtos.h` — Protobuf wire encoders/decoders for `spotify.connectstate.*` using `ProtobufWireHelper.h` (Sources: `liborbit-jni-spotify_memdump.so` string tables).
117. [x] `android/app/src/main/cpp/connect/DealerWebSocketClient.h` & `.cpp` — Native WebSocket client to `wss://dealer.g2.spotify.com:443`, ping/pong (`hm://connect-state/v1/ping`), `X-Spotify-Connection-Id`, topic distribution for `hm://connect-state/v1/*` (Sources: `liborbit` strings `0x184e99`, `0x19cb5c`, `0x19ecd0`).
118. [x] `android/app/src/main/cpp/connect/PutStateBackoff.h` & `.cpp` — Exponential backoff for WebGate PutState synchronization (Sources: `liborbit` `0x1522e9`, `ConnectStateClientImpl PutStateBackoff`).
119. [x] `android/app/src/main/cpp/connect/VolumeThrottler.h` & `.cpp` — Rate-limits `VOLUME_CHANGED` PutState calls (Sources: `liborbit` `0x1a2c19` `"Not sending VOLUME_CHANGED PutState now..."` & `0x18a597` `"player_state_changed_putstate_throttling_window"`).
120. [x] `android/app/src/main/cpp/connect/ConnectStateClientImpl.h` & `.cpp` — REST sync with WebGate (`PUT /connect-state/v1/devices/{id}`, `POST /connect-state/v1/connect/*`), gzip compression via zlib, PutStateRequest builder (Sources: `liborbit` `0x17c281`, `0x37bf6e`).
121. [x] `android/app/src/main/cpp/connect/ConnectDevicesImpl.h` & `.cpp` — Cluster state holder, `acquireClusterUpdatePostponementBlock` / `releaseClusterUpdatePostponementBlock`, capability application, local discovery (Sources: `liborbit` `0x18e180`, `0x159fd8`, `0x13f62d`, `0x178393`).
122. [x] `android/app/src/main/cpp/connect/TransferIntention.h` & `.cpp` — Transfer intention state machine, intention ID lifecycle, timeout handling (Sources: `liborbit` `0x14e9a1`, `0x171d08`).
123. [x] `android/app/src/main/cpp/connect/TransferManager.h` & `.cpp` — 1:1 replication of `spotify::connect::TransferManager` (`transferToDevice`, `transferToConnectStateDevice`, `onClusterUpdate`, `onBecomeActiveTimeout`, `shouldIgnoreRepeatedTransferRequest`) (Sources: `liborbit` `0x1951e5`, `0x19f03d`, `0x15a30c`, `0x1a2f14`, `0x14abef`).
124. [x] `android/app/src/main/cpp/connect/ConnectSubsystem.h` & `.cpp` — Coordinator integrating `ContextPlayerImpl` (state notification, remote command injection, playback handoff), `DealerWebSocketClient`, `ConnectStateClientImpl`, `ConnectDevicesImpl`, and `TransferManager`.
125. [x] `android/app/src/main/cpp/network/NativeHttpClient.h` & `.cpp` — Refactor `executeOnce` to attach `CURLOPT_POSTFIELDS` on `PUT` and expose public `put()` method for WebGate `PUT connect-state/v1/devices/{device_id}`.

#### Phase 12D: Native Esperanto Services & FFI Bridge — [ALL COMPLETED 1:1]
126. [x] `android/app/src/main/cpp/connect/ConnectServiceImpl.h` & `.cpp` — Native C++ Esperanto RPC implementation for `spotify.connect.esperanto.proto.ConnectService` (12 RPC methods) (Sources: `liborbit` `0x1a2b68`, `p199p/s77.java`, `p199p/C2086nd.java`).
127. [x] `android/app/src/main/cpp/connect/ConnectVolumeServiceImpl.h` & `.cpp` — Native C++ Esperanto RPC implementation for `spotify.connect.esperanto.proto.ConnectVolumeService` (5 RPC methods) (Sources: `liborbit` `0x1434d6`, `p199p/a0f1.java`, `p199p/lw51.java`).
128. [x] `android/app/src/main/cpp/connect/DodoServiceImpl.h` & `.cpp` — Native C++ Esperanto RPC implementation for `spotify.connect.esperanto.proto.DodoService` (4 RPC methods) (Sources: `liborbit` `0x16a9c9`).
129. [x] `android/app/src/main/cpp/ffi_bridge.cpp` — Export C-ABI FFI functions for Connect Subsystem (`musify_connect_create`, `musify_connect_destroy`, `musify_connect_service_call`, `musify_connect_volume_service_call`, `musify_connect_set_state_port`, `musify_connect_set_volume_port`, plus `musify_connect_set_local_volume_port`, `musify_connect_set_dodo_port`, `musify_connect_set_install_spotify_port`, `musify_connect_start`, `musify_connect_stop`, `musify_dodo_service_call`).
130. [x] `android/app/src/main/cpp/CMakeLists.txt` — Append all `connect/*.cpp` files to `musify_audio` build target with C++20 flags.
131. [x] `lib/core/audio/musify_ffi_bindings.dart` — Add Connect Subsystem FFI lookup bindings and public API methods.
132. [x] `lib/features/player/data/esperanto/native_esperanto_transport.dart` — Implement service-based routing in `callSingle`, `callStream`, and `callSync` for `spotify.connect.esperanto.proto.*` services.

#### Phase 12E: Dart Esperanto Clients, Domain Models & Proto Mappers (`lib/features/connect/data/` & `domain/`) — [ALL COMPLETED 1:1]
133. [x] `lib/features/connect/data/esperanto/connect_service_client.dart` — Dart client for `spotify.connect.esperanto.proto.ConnectService` across `NativeEsperantoTransport` (Sources: `p199p/s77.java`, `p199p/C2086nd.java`).
134. [x] `lib/features/connect/data/esperanto/connect_volume_service_client.dart` — Dart client for `spotify.connect.esperanto.proto.ConnectVolumeService` across `NativeEsperantoTransport` (Sources: `p199p/C2086nd.java`, `p199p/a0f1.java`, `p199p/lw51.java`).
135. [x] `lib/features/connect/data/esperanto/dodo_service_client.dart` — Dart client for `spotify.connect.esperanto.proto.DodoService` across `NativeEsperantoTransport` (Sources: `liborbit` `0x16a9c9`).
136. [x] `lib/features/connect/data/mappers/connect_proto_mappers.dart` — Master wire mapper converting Esperanto proto responses into immutable domain models (Sources: `p199p/n8d.java` lines 514–1050).
137. [x] `lib/features/connect/data/mappers/cluster_mapper.dart` — 1:1 mapper for `ConnectMessages$StateResponse` to `ConnectCluster` (Sources: `p199p/n8d.java`).
138. [x] `lib/features/connect/data/mappers/device_info_mapper.dart` — 1:1 mapper for `ConnectMessages$StateResponse$Device` to `ConnectDevice` (Sources: `p199p/n8d.java`).
139. [x] `lib/features/connect/data/mappers/volume_mapper.dart` — 1:1 mapper for `VolumeMessages$VolumeState` to `ConnectVolumeState` (Sources: `p199p/a0f1.java`).
140. [x] `lib/features/connect/data/mappers/group_mapper.dart` — 1:1 mapper for `ConnectMessages$GroupData` to `ConnectGroupData` (Sources: `p199p/n8d.java`).
141. [x] `lib/features/connect/domain/models/connect_device.dart` — 1:1 domain entity (`p199p/w7k.java`) with 39 immutable fields, zero non-null assertions, zero fallbacks.
142. [x] `lib/features/connect/domain/models/connect_cluster.dart` — 1:1 domain entity (`p199p/tck.java`) holding active device ID, cluster devices map, state flags.
143. [x] `lib/features/connect/domain/models/connect_capabilities.dart` — 1:1 domain entity for device capabilities (volume steps, transfer support, group support, voice support).
144. [x] `lib/features/connect/domain/models/connect_volume_state.dart` — 1:1 domain entity for volume (0.0 to 1.0, step size, is_muted).
145. [x] `lib/features/connect/domain/models/connect_group_data.dart` — 1:1 domain entity (`p199p/of40.java`) for group audio session data.
146. [x] `lib/features/connect/domain/models/connect_group_device.dart` — 1:1 domain entity (`p199p/ug40.java`) for speaker group member.
147. [x] `lib/features/connect/domain/models/output_peripheral.dart` — 1:1 domain entity (`p199p/k7k.java`) for Bluetooth/AirPlay/Cast peripheral status.
148. [x] `lib/features/connect/domain/models/incarnation.dart` — 1:1 domain entity (`p199p/r370.java`) for device incarnation.
149. [x] `lib/features/connect/domain/models/hifi_status.dart` — 1:1 domain entity (`p199p/u450.java`) for HiFi eligibility and support.
150. [x] `lib/features/connect/domain/models/device_type.dart` — 1:1 domain enum (`p199p/t3t.java`) with 17 variants.
151. [x] `lib/features/connect/domain/models/grouping_status.dart` — 1:1 domain enum (`p199p/im40.java`) with 4 variants.
152. [x] `lib/features/connect/domain/models/transfer_state.dart` — Sealed hierarchy for transfer intention state.

#### Phase 12F: Connect Application Layer, Mobius Loops & Device Sorting (`lib/features/connect/application/`) — [ALL COMPLETED 1:1]
153. [x] `lib/features/connect/application/mobius/connect_mobius_controller.dart` — Mobius loop controller managing subscriptions and state emissions (`p199p/yrq.java`).
154. [x] `lib/features/connect/application/mobius/connect_event.dart` — Sealed event root with `DeviceSelected`, `VolumeChanged`, `RefreshRequested`, `ClusterUpdated` (`p199p/i6k.java`, `f6k`, `g6k`, `h6k`).
155. [x] `lib/features/connect/application/mobius/connect_state.dart` — Immutable Mobius state holding available devices, cluster state, and active transfer (`p199p/v6k.java`, `w6k.java`).
156. [x] `lib/features/connect/application/mobius/connect_effect.dart` — Sealed effect root (`TransferToDeviceEffect`, `SetVolumeEffect`, `RefreshClusterEffect`, `WakeSleepingDevicesEffect`).
157. [x] `lib/features/connect/application/mobius/connect_effect_handler.dart` — Effect handler executing against ConnectServiceClient & ConnectVolumeServiceClient (`p199p/d6k.java`).
158. [x] `lib/features/connect/application/mobius/connect_mobius_update.dart` — Pure deterministic state transition function (`p199p/vrq.java` & `p199p/lbv.java` `m59792d`).
159. [x] `lib/features/connect/application/sorting/device_picker_sorting_database.dart` — 1:1 replication of `DevicePickerSortingDatabase` (Room SQLite table `DeviceLastConnection` with `deviceIdentifier` and `timestamp`) (`qr0.java`, `or0.java`, `wwj.java`, `p199p/azq.java`).
160. [x] `lib/features/connect/application/sorting/device_sorting_comparator.dart` — 1:1 4-stage comparator (`p199p/wcs.java` lines 3–57 `m88644e`/`m88646g`, `p199p/iq6.java`, `p199p/tzs.java`, `p199p/oco.java`).
161. [x] `lib/features/connect/application/volume/remote_volume_controller.dart` — Remote volume controller with step quantization and debounce (`p199p/a0f1.java`, `p199p/lw51.java`).

#### Requirement R2: Code Modularity & Extraction of Existing Merged Files — [ALL COMPLETED 1:1]
162. [x] `lib/features/player/presentation/widgets/player_seek_bar.dart` — Extracted `PlayerSeekBar` and `_SilverFlowingSliderTrackShape` from `player_controls.dart`.
163. [x] `lib/features/player/presentation/widgets/player_playback_controls.dart` — Extracted `PlayerPlaybackControls` from `player_controls.dart`.
164. [x] `lib/features/player/presentation/widgets/player_utility_row.dart` — Extracted `PlayerUtilityRow` (Connect Devices trigger) from `player_controls.dart`.
165. [x] `lib/features/player/presentation/widgets/player_secondary_controls.dart` — Extracted `PlayerSecondaryControls` from `player_controls.dart`.
166. [x] `lib/features/player/presentation/widgets/player_controls.dart` — Refactored to clean barrel export.
167. [x] `lib/features/player/presentation/widgets/player_options_sheet.dart` — Extracted `PlayerOptionsSheet` from `player_sheets.dart`.
168. [x] `lib/features/player/presentation/widgets/player_track_details_sheet.dart` — Extracted `PlayerTrackDetailsSheet` from `player_sheets.dart` (remediated `duration!` AST violation via pattern-matched `if (duration case final trackDuration?)`).
169. [x] `lib/features/player/presentation/widgets/player_sheet_header.dart` — Extracted `PlayerSheetHeader` from `player_sheets.dart`.
170. [x] `lib/features/player/presentation/widgets/player_sheet_detail_row.dart` — Extracted `PlayerSheetDetailRow` from `player_sheets.dart`.
171. [x] `lib/features/player/presentation/widgets/player_sheets.dart` — Refactored to clean barrel export.

#### Phase 12G: Presentation Layer & Output Switcher UI (`lib/features/connect/presentation/`) — [ALL COMPLETED 1:1]
172. [x] `lib/features/connect/presentation/screens/device_picker_sheet.dart` — Output Switcher modal bottom sheet with device list, active device indicator, and volume slider (`com/spotify/connect/`).
173. [x] `lib/features/connect/presentation/widgets/device_list_tile.dart` — Device entry tile with type icon, name, connection status (`p199p/bsq.java`, `p199p/dsq.java`).
174. [x] `lib/features/connect/presentation/widgets/device_picker_header.dart` — Title bar with current listening device status and close button.
175. [x] `lib/features/connect/presentation/widgets/active_device_banner.dart` — Green "Listening on <Device>" banner for `MiniPlayer` and `PlayerScreen`.
176. [x] `lib/features/connect/presentation/widgets/connect_volume_slider.dart` — Remote volume slider widget.
177. [x] `lib/features/connect/presentation/widgets/group_device_tile.dart` — Multi-speaker group sub-item with individual volume control.
178. [x] Wire `ActiveDeviceBanner` into `lib/features/player/presentation/widgets/mini_player.dart` and `lib/features/player/presentation/screens/player_screen.dart`.
179. [x] Wire Connect device trigger in `PlayerUtilityRow` (`onDevice`) to launch `DevicePickerSheet`.
180. [x] Verification & Quality Gate: `flutter analyze` 0 errors/0 warnings, C++20 Clang compilation 0 errors/0 warnings, 100% test pass rate with zero regressions.

---

### Completed & Verified
- [x] Items 1–23: All Player Commands (`com.spotify.player.model.command.*`)
- [x] Items 24–35: All Command Options (`com.spotify.player.model.command.options.*`)
- [x] Items 36–58: All Player Models (`com.spotify.player.model.*`)
- [x] Items 59–69: Esperanto Clients & Wire Mappers (`ContextPlayerQueueClient`, `ContextPlayerControlClient`, `ContextPlayerOptionsClient`, `ContextPlayerPlayClient`, `ContextPlayerStateClient`, `ContextPlayerPlayPreparedClient`, `QueueProtoMappers`, `PlayerStateProtoMappers`, `ContextPlayerComponent`, `EsperantoTransport`, `NativeEsperantoTransport`)
- [x] Items 70–75: Queue Application & Mobius Loop (`PlayerQueueMobiusController`, `PlayerQueueEvent`, `PlayerQueueState`, `QueueMobiusEffectHandler`, `QueueEffect`, `queueMobiusUpdate`)
- [x] Items 76–78: Native C++ Engine & FFI Bridge
- [x] Items 79–86: Queue Handlers & Filtering (`data/queue/*`)
- [x] Items 87–91: Audio Stream Resolvers & Coordinators (`data/services/*`)
- [x] Items 92–94: Now Playing Scroll Controller & Pipeline (`application/scroll/*`)
- [x] Items 95–98: Presentation Layer (Queue & Player Screens/Widgets)
- [x] Items 99–106: Native Architecture Parity — C++ ContextPlayerImpl, RestrictionsEngine, StateEmitter, FFI Bridge, Dart Bindings, thin NativeEsperantoTransport
- [x] Phase 12A: Exhaustive Master Inventory & Forensics Complete (Items 107–180 enumerated with exact source citations)
- [x] Items 107–115: Phase 12B Protobuf Schemas & Wire Descriptors (`protos/spotify/connect/*`, `protos/esperanto/*`, `lib/features/connect/data/proto/*`)
- [x] Items 162–171: Requirement R2 Code Modularity & Extraction (`player_controls.dart` and `player_sheets.dart` split into 8 dedicated files + 2 barrel exports with `duration!` AST fix)
- [x] Items 116–125: Phase 12C Native C++ Connect State Engine (`android/app/src/main/cpp/connect/*`, `ContextPlayerImpl` hooks, and `NativeHttpClient` PUT support)
- [x] Items 126–132: Phase 12D Native Esperanto Services & FFI Bridge (`ConnectServiceImpl`, `ConnectVolumeServiceImpl`, `DodoServiceImpl`, `ffi_bridge.cpp` C-ABI exports & atomic NativePorts, `CMakeLists.txt` C++20 NDK build, `musify_ffi_bindings.dart`, and `native_esperanto_transport.dart` service routing)
- [x] Items 133–152: Phase 12E Dart Esperanto Clients, Domain Models & Proto Mappers (`ConnectServiceClient`, `ConnectVolumeServiceClient`, `DodoServiceClient`, `ConnectProtoMappers`, `ClusterMapper`, `DeviceInfoMapper`, `VolumeMapper`, `GroupMapper`, and 12 immutable domain models under `lib/features/connect/`)
- [x] Items 153–161: Phase 12F Connect Application Layer, Mobius Loops & Device Sorting (`ConnectMobiusController`, `ConnectEvent`, `ConnectState`, `ConnectEffect`, `ConnectEffectHandler`, `connectMobiusUpdate`, `DevicePickerSortingDatabase`, `DeviceSortingComparator`, and `RemoteVolumeController`)
- [x] Items 172–180: Phase 12G Presentation Layer, Output Switcher UI, Player/DI Wiring & Final Verification Gate (DevicePickerSheet, DeviceListTile, DevicePickerHeader, ActiveDeviceBanner, ConnectVolumeSlider, GroupDeviceTile, MiniPlayer/PlayerScreen/PlayerUtilityRow + DI/App wiring; C++20 NDK 0 errors/0 warnings, scoped Flutter analyze 0 issues, 348/348 Item 180 tests + 68/68 core unit tests pass)
