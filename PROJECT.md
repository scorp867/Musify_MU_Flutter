# Project: Musify "Private Playlists" Secure Vault Module (Phase 4)

## Architecture
- Clean Architecture (Feature-First) with David Harel's Statechart concurrent orthogonal regions:
  - **Region A: `VaultSessionBloc`**: Root security authority managing session lifecycle (`uninitialized`, `locked`, `authenticating`, `activeSession.unlocked`, `activeSession.backgroundGrace`, `activeSession.pendingReauth`, `lockoutCooldown` with persistent timer).
  - **Region B: `PlaybackPrivacyProxy`**: Intercepts `PlayerQueueMobiusController` playback, applies `DecoyMediaMaskingStrategy` / `PassthroughMediaMaskingStrategy`, and executes `StopImmediatelyLockStrategy`, `FinishCurrentTrackLockStrategy`, or `ContinueMaskedLockStrategy`.
  - **Region C: `ScreenPrivacyCubit`**: Governs native Android `FLAG_SECURE` via platform channels and route/lifecycle observers.
  - **Region D: `GestureEngineCubit`**: Interfaces with `StealthGesturePad`, handles live stroke evaluation and 3-sample DBA template enrollment.
  - **Sub-Service 5: `SettingsMutationCubit`**: State machine adhering to `SettingsMutationStateEnum` (`syncedIdle`, `awaitingStepUpAuth`, `persistingConfig`, `mutationRejected`), auto-saves immediately via atomic Drift transactions, debounces decoy persona text, and resets immediately to `syncedIdle` on rejection.
  - **Sub-Service 6: `PinPadCubit`**: Manages 6-digit PIN input lifecycle (`idleInput`, `evaluatingAndDeriving`, `authSuccess`, `authFailureShake`, `lockedOut`), supporting standard and randomized keypad layout policies.
  - **Central Coordinator: `VaultCoordinator`**: Coordinates events, timers, and transitions across all BLoCs, player controllers, and UI routes.
- Presentation Layer Architecture:
  - **Strict Full-Screen Authentication (`VaultAuthScreen`)**: Dedicated full screen (`Scaffold`) for all vault authentication entry points (NO bottom sheets, NO alert dialogs). Reused across `unlock`, `stepUp`, `verifyOldPin`, and `purgeConfirmation` modes.
  - **`ReauthBlurOverlay`**: Frosted glass non-destructive re-auth overlay over active vault views on `pendingReauth` cool-off expiration without interrupting playback or losing scroll state.
  - **Dedicated Vault Screens**:
    - `PrivateVaultDashboardScreen`: Dense vertical list of private playlists, 48px square thumbnails with frosted artwork peek, quick inline search filter, quick-lock action icon.
    - `PrivatePlaylistDetailScreen`: Header, cover art peek/unblur, in-playlist search filter, reorderable tracks with swipe-to-remove, playback via `VaultAudioPlaybackService` and Mobius.
    - `GestureEnrollmentScreen`: Guided 3-sample wizard with live ink trails, real-time DTW feedback, isolate DBA synthesis, and sandbox testing pad.
    - `VaultSettingsScreen`: Multi-page/tabbed settings (Appearance, Security & Authentication, Playback & Privacy, Gesture Controls, Danger Zone).
  - **Public Ingestion Stealth Gate**: "Clone to Private Vault" and "Add to Private Playlists" in `PlaylistScreen` rendered ONLY when `VaultSessionBloc.state is VaultActiveSessionState` (zero public UI leakage).
  - **Design System Invariants**: `warmEspresso` vs `forestNoir` palettes, `BorderRadius.circular(8)` geometric curves, 1px tone-on-tone borders, Poppins typography, zero purple gradients, zero pill buttons, zero emojis, zero em dashes.

---

## Feature Inventory

Every Phase 4 feature mapped to an assigned milestone:

| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | `SettingsMutationCubit` State Machine | Adheres to `SettingsMutationStateEnum` (`syncedIdle`, `awaitingStepUpAuth`, `persistingConfig`, `mutationRejected`) | M1 | STRICT_PROMPT §6.F, R1 |
| 2 | Immediate Encrypted Auto-Save | Persists general setting changes immediately to Drift `vault_config` table via atomic transactions | M1 | STRICT_PROMPT §6.F, R1 |
| 3 | Non-Blocking Mutation Rejection Recovery | On failure/rejection, reverts to last known good config, emits `mutationRejected`, and immediately transitions back to `syncedIdle` | M1 | STRICT_PROMPT §6.F, R1 |
| 4 | Decoy Persona Debouncing | Text edits for `decoyTitle`, `decoyArtist`, `decoyAlbum` debounced (350ms) or saved on focus loss without UI lag | M1 | STRICT_PROMPT §5.H, R1 |
| 5 | `PinPadCubit` State Machine | 6-digit keypad lifecycle adhering to `PinPadStateEnum` (`idleInput`, `evaluatingAndDeriving`, `authSuccess`, `authFailureShake`, `lockedOut`) | M1 | STRICT_PROMPT §5.H, R1 |
| 6 | Keypad Layout Policy | Supports `standardOrdered` ([1..9, 0]) and `randomizedPerAttempt` to defeat smudge attacks | M1 | STRICT_PROMPT §5.H, R4 |
| 7 | Auto-Submit & Inline Derivation | Auto-submits on 6th digit, derives PBKDF2 on background isolate, emits shake or lockout timer | M1 | STRICT_PROMPT §5.H, R1 |
| 8 | Region A `VaultSessionBloc` FSM | Root session authority: `uninitialized`, `locked`, `authenticating`, `unlocked`, `backgroundGrace`, `pendingReauth`, `lockoutCooldown` | M1 | STRICT_PROMPT §4, R7 |
| 9 | Region B `PlaybackPrivacyProxy` Updates | Reactively subscribes to config changes, applies media masking and executes lock playback behavior | M1 | STRICT_PROMPT §5, R7 |
| 10 | Region C `ScreenPrivacyCubit` FSM | Manages native `FLAG_SECURE` window security states (`publicUnrestricted`, `secureFlagEngaged`, `platformSyncPending`) | M1 | STRICT_PROMPT §5, R7 |
| 11 | Region D `GestureEngineCubit` FSM | Coordinates live stroke matching with `StealthGesturePad` and 3-sample DBA enrollment | M1 | STRICT_PROMPT §7, R7 |
| 12 | Central `VaultCoordinator` | Orchestrates cross-BLoC communication, timers, app lifecycle events, and route transitions | M1 | STRICT_PROMPT §9, R7 |
| 13 | Strict Full-Screen `VaultAuthScreen` | Dedicated full-screen route (`Scaffold`) for authentication (NO bottom sheets, NO popup alert dialogs) | M2 | USER DIRECTIVE, R2 |
| 14 | Canonical `VaultAuthScreenMode` Reuse | Reused for `unlock`, `stepUp`, `verifyOldPin`, and `purgeConfirmation` without code duplication | M2 | STRICT_PROMPT §8.2, R2 |
| 15 | Keypad Visual Styling & Animations | 8px geometric radius, 1px tone-on-tone borders, Poppins font, inline progress, shake animation, lockout timer | M2 | STRICT_PROMPT §1 & §8, R3 |
| 16 | `ReauthBlurOverlay` Widget | Frosted glass cool-off overlay (sigma 12) over active vault views on `pendingReauth` without playback interruption | M2 | STRICT_PROMPT §8.3, R7 |
| 17 | `VaultTheme` Dual Palette Engine | Tokenized reactive theme support for `warmEspresso` and `forestNoir` with dynamic runtime switching | M2 | STRICT_PROMPT §1.2, R4 |
| 18 | `PrivateVaultDashboardScreen` | Dense playlist list, 48px square thumbnails, frosted artwork peek, quick inline search filter, app bar quick-lock action | M3 | STRICT_PROMPT §8.4, R7 |
| 19 | `PrivatePlaylistDetailScreen` | Header, cover art peek/unblur, in-playlist search, reorderable track list with swipe-to-remove, Mobius playback | M3 | STRICT_PROMPT §8.5, R7 |
| 20 | Public Menu Ingestion Stealth Gating | "Clone to Private Vault" and "Add to Private Playlists" in `PlaylistScreen` rendered ONLY when vault session is active | M3 | STRICT_PROMPT §8.6, R7 |
| 21 | `GestureEnrollmentScreen` | Guided 3-sample wizard with live ink trails, real-time DTW feedback, background DBA synthesis, sandbox testing pad | M4 | STRICT_PROMPT §8.8, R4 |
| 22 | `VaultSettingsScreen` Multi-Tabbed UI | 5 sub-screens: Appearance, Security & Authentication, Playback & Privacy, Gesture Controls, Danger Zone | M4 | STRICT_PROMPT §8.7, R3 |
| 23 | Step-Up Authentication Guard | Intercepts sensitive mutations (`pinRotation`, `biometricPolicyChange`, `gestureReEnrollment`, `vaultDataPurge`) via `VaultAuthScreen` | M4 | STRICT_PROMPT §6.F, R2 |
| 24 | PIN Rotation Flow | Verifies old PIN, inputs/confirms new PIN, re-derives PBKDF2 salt/token, updates Slot 1 & 2 without altering audio files | M4 | STRICT_PROMPT §3.2, R5 |
| 25 | Destructive Vault Purge Flow | Two-step confirmation with severe warning, master PIN verification, DB purge, KeyStore/RAM key shred, 64KB zero-overwriting in isolate, state to `uninitialized` | M4 | STRICT_PROMPT §8.7, R6 |
| 26 | GetIt Composition Root Wiring | Registers all vault databases, repositories, services, use cases, BLoCs, and `VaultCoordinator` in `lib/app/di/injection.dart` | M5 | STRICT_PROMPT §9, R7 |
| 27 | Android Native `FLAG_SECURE` Channel | Implements window flag mutation method channel in `MainActivity.kt` | M5 | STRICT_PROMPT §5, R7 |
| 28 | App Widget Tree Integration | Wires `VaultSessionBloc`, `SettingsMutationCubit`, `ScreenPrivacyCubit`, `VaultRouteObserver`, and lifecycle listeners in `lib/app/app.dart` | M5 | STRICT_PROMPT §9, R7 |
| 29 | `DrawerMenu` Stealth Pad Connection | Wires `StealthGesturePad.onVaultGestureMatched` in `DrawerMenu` to navigate to `VaultAuthScreen(mode: unlock)` | M5 | STRICT_PROMPT §8.1, R7 |
| 30 | Comprehensive Verification & Audit | Full test suite, 0 regressions on 930 baseline tests, 0 analyzer issues, Dual Reviews, Dual Challenges, Clean Forensic Audit | M6 | STRICT_PROMPT §10, Acceptance |

---

## Milestones

| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Harel FSM State Machines & Controllers | `SettingsMutationCubit`, `PinPadCubit`, `VaultSessionBloc`, `ScreenPrivacyCubit`, `GestureEngineCubit`, `VaultCoordinator` | Survey Complete | DONE |
| M2 | Full-Screen Authentication (`VaultAuthScreen`) & Reauth Overlay | `VaultAuthScreen` (NO bottom sheets), `ReauthBlurOverlay`, `VaultTheme` (`warmEspresso`/`forestNoir`) | M1 | DONE |
| M3 | Dedicated Vault Screens & Ingestion Flows | `PrivateVaultDashboardScreen`, `PrivatePlaylistDetailScreen`, `PlaylistScreen` stealth-gated ingestion | M1, M2 | DONE |
| M4 | Gesture Enrollment & Vault Settings UI (Step-Up, PIN Rotation, Purge) | `GestureEnrollmentScreen`, `VaultSettingsScreen` (5 sub-screens), step-up auth guard, PIN rotation, destructive purge | M1, M2, M3 | DONE |
| M5 | Global System Integration & Dependency Wiring | `lib/app/di/injection.dart`, `lib/app/app.dart`, `MainActivity.kt`, `DrawerMenu` routing | M1, M2, M3, M4 | DONE |
| M6 | Comprehensive Testing, Adversarial Verification & Forensic Audit | Comprehensive test suite, 930 baseline regression check, Dual Reviewers, Dual Challengers, Forensic Auditor | M1, M2, M3, M4, M5 | DONE |



---

## Interface Contracts

### M1: Harel FSM State Machines & Controllers
- `SettingsMutationCubit`:
  ```dart
  class SettingsMutationCubit extends Cubit<SettingsMutationState> {
    Future<void> updateGeneralPolicy(VaultConfig updatedConfig);
    Future<void> requestSensitiveMutation({required SensitiveSettingMutationEnum mutationType});
    Future<void> confirmSensitiveMutation({required SensitiveSettingMutationEnum mutationType, required Future<void> Function() onExecute});
    void cancelSensitiveMutation({required SensitiveSettingMutationEnum mutationType});
  }
  ```
- `PinPadCubit`:
  ```dart
  class PinPadCubit extends Cubit<PinPadState> {
    void onDigitEntered(int digit);
    void onBackspace();
    void clear();
    void resetToIdle();
  }
  ```
- `VaultSessionBloc`:
  ```dart
  class VaultSessionBloc extends Bloc<VaultSessionEvent, VaultSessionState> { ... }
  ```
- `ScreenPrivacyCubit`:
  ```dart
  class ScreenPrivacyCubit extends Cubit<ScreenPrivacyState> {
    Future<void> engageSecureFlag({required String reason});
    Future<void> releaseSecureFlag({required String reason});
  }
  ```
- `VaultCoordinator`:
  ```dart
  class VaultCoordinator {
    void onStealthGestureTriggered(BuildContext context);
    void onAppLifecycleStateChanged(AppLifecycleState state);
    void dispose();
  }
  ```

### M2: Full-Screen Authentication & Re-Auth Overlay
- `VaultAuthScreen`:
  ```dart
  enum VaultAuthScreenMode { unlock, stepUp, verifyOldPin, purgeConfirmation }
  class VaultAuthScreen extends StatelessWidget {
    final VaultAuthScreenMode mode;
    final String? titleOverride;
    final ValueChanged<bool>? onAuthComplete;
    const VaultAuthScreen({required this.mode, this.titleOverride, this.onAuthComplete, super.key});
  }
  ```
- `ReauthBlurOverlay`:
  ```dart
  class ReauthBlurOverlay extends StatelessWidget {
    final Widget child;
    final VoidCallback onReauthRequested;
    const ReauthBlurOverlay({required this.child, required this.onReauthRequested, super.key});
  }
  ```

### M3: Dedicated Vault Management Screens
- `PrivateVaultDashboardScreen`:
  ```dart
  class PrivateVaultDashboardScreen extends StatelessWidget { const PrivateVaultDashboardScreen({super.key}); }
  ```
- `PrivatePlaylistDetailScreen`:
  ```dart
  class PrivatePlaylistDetailScreen extends StatelessWidget {
    final String playlistId;
    const PrivatePlaylistDetailScreen({required this.playlistId, super.key});
  }
  ```

### M4: Gesture Enrollment & Vault Settings UI
- `GestureEnrollmentScreen`:
  ```dart
  class GestureEnrollmentScreen extends StatefulWidget { const GestureEnrollmentScreen({super.key}); }
  ```
- `VaultSettingsScreen` (Hub & Dedicated Section Screens):
  ```dart
  class VaultSettingsScreen extends StatefulWidget { const VaultSettingsScreen({super.key}); }
  class VaultAppearanceSettingsScreen extends StatelessWidget { const VaultAppearanceSettingsScreen({super.key}); }
  class VaultSecuritySettingsScreen extends StatelessWidget { const VaultSecuritySettingsScreen({super.key}); }
  class VaultPrivacySettingsScreen extends StatelessWidget { const VaultPrivacySettingsScreen({super.key}); }
  class VaultGestureSettingsScreen extends StatelessWidget { const VaultGestureSettingsScreen({super.key}); }
  class VaultDangerZoneScreen extends StatelessWidget { const VaultDangerZoneScreen({super.key}); }
  ```

### M5: Global Integration
- `lib/app/di/injection.dart`: `setupVaultInjection()` registered inside `setupInjection()`.
- `lib/features/shell/presentation/widgets/drawer_menu.dart`:
  `StealthGesturePad(onVaultGestureMatched: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultAuthScreen(mode: VaultAuthScreenMode.unlock))))`

---

## Code Layout

```
lib/features/vault/
├── application/
│   ├── coordinator/
│   │   └── vault_coordinator.dart                          # M1
│   ├── gesture/
│   │   └── gesture_engine_cubit.dart                       # M1
│   ├── pin_pad/
│   │   └── pin_pad_cubit.dart                              # M1
│   ├── screen_privacy/
│   │   └── screen_privacy_cubit.dart                       # M1
│   ├── session/
│   │   └── vault_session_bloc.dart                         # M1
│   └── settings/
│       └── settings_mutation_cubit.dart                    # M1
├── domain/
│   ├── entities/                                           # Phase 1: DONE
│   ├── policies/                                           # Phase 1: DONE
│   ├── repositories/                                       # Phase 1: DONE
│   ├── states/                                             # Phase 1: DONE
│   └── usecases/                                           # Phase 1/2: DONE
├── data/
│   ├── datasources/                                        # Phase 2: DONE
│   ├── gesture/                                            # Phase 3: DONE
│   ├── models/                                             # Phase 1: DONE
│   ├── repositories/                                       # Phase 2: DONE
│   └── services/                                           # Phase 2/3: DONE
└── presentation/
    ├── screens/
    │   ├── gesture_enrollment_screen.dart                  # M4
    │   ├── private_playlist_detail_screen.dart             # M3
    │   ├── private_vault_dashboard_screen.dart             # M3
    │   ├── vault_auth_screen.dart                          # M2
    │   └── vault_settings_screen.dart                      # M4
    ├── theme/
    │   └── vault_theme.dart                                # M2
    └── widgets/
        ├── reauth_blur_overlay.dart                        # M2
        └── stealth_gesture_pad.dart                        # Phase 3: DONE

lib/features/playlist/presentation/
└── playlist_screen.dart                                    # M3 (Stealth Ingestion)

lib/app/
├── app.dart                                                # M5
└── di/
    └── injection.dart                                      # M5

android/app/src/main/kotlin/um/musify/mu/musify_mu/
└── MainActivity.kt                                         # M5 (FLAG_SECURE channel)

test/features/vault/
├── application/                                            # M1/M6
├── presentation/                                           # M2/M3/M4/M6
└── integration/                                            # M5/M6
```
