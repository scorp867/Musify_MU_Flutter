# Settings Mutation Audit & Verification Plan

## 1. Executive Summary
Thorough architectural investigation and automated test execution across all user-configurable settings in Musify's Secure Vault and app-level preferences. The investigation evaluates:
1. **Immediate Propagation**: Does every UI control immediately reflect changes across active screens and background services?
2. **Persistence Integrity**: Are mutated configurations safely encrypted and reloaded reliably across cold-boot app restarts?
3. **Engineering & Industry Standards**: Evaluating adherence to professional mobile engineering standards (reactive unidirectional data flow, fail-fast deserialization, zero race conditions, atomic SQLite transactions, and hardware Keystore isolation).

---

## 2. Setting Mutation Matrix (16 Vectors)

| # | Setting / Action | Category | Persistence Target | Step-Up Auth Guard | Immediate Effect Subsystem |
|---|-------------------|----------|-------------------|-------------------|----------------------------|
| 1 | `themePalette` (5 options) | Appearance | `vault_config` table (AES-256) | No | `VaultTheme`, `StreamBuilder`, `VaultRoutes` |
| 2 | `frostedGlassBlurSigma` (Slider) | Appearance | Ephemeral State / Local | No | `VaultAppearanceSettingsScreen` preview |
| 3 | `biometricAuth` (Toggle) | Security | `vault_config` table (AES-256) | **Yes** (`VaultAuthScreenMode.stepUp`) | Keystore Biometric prompt on unlock |
| 4 | `backgroundGraceTimeout` (4 options) | Security | `vault_config` table (AES-256) | No | `VaultSessionBloc` countdown timer |
| 5 | `activeReauthInterval` (4 options) | Security | `vault_config` table (AES-256) | No | `VaultSessionBloc` inactivity tracker |
| 6 | `keypadLayout` (2 options) | Security | `vault_config` table (AES-256) | No | `PinPadCubit` digit shuffle order |
| 7 | PIN Rotation (Old -> New -> Confirm) | Security | Android KeyStore / Verifier Hash | **Yes** (4-phase workflow) | Master key re-encryption |
| 8 | `screenSecurity` (FLAG_SECURE) | Privacy | `vault_config` table (AES-256) | No | `ScreenPrivacyCubit` window security flag |
| 9 | `metadataVisibility` (Mask/Show) | Privacy | `vault_config` table (AES-256) | No | `PlaybackPrivacyProxy` lockscreen projection |
| 10 | `decoyTitle` (Text field) | Privacy | `vault_config` table (AES-256) | No (Debounced 350ms / Flush on Blur) | `PlaybackPrivacyProxy` media metadata |
| 11 | `decoyArtist` (Text field) | Privacy | `vault_config` table (AES-256) | No (Debounced 350ms / Flush on Blur) | `PlaybackPrivacyProxy` media metadata |
| 12 | `decoyAlbum` (Text field) | Privacy | `vault_config` table (AES-256) | No (Debounced 350ms / Flush on Blur) | `PlaybackPrivacyProxy` media metadata |
| 13 | `lockPlaybackBehavior` (3 options) | Privacy | `vault_config` table (AES-256) | No | `PlaybackPrivacyProxy` audio pause / queue drop |
| 14 | `gestureSensitivity` (3 tiers) | Gestures | `vault_config` table (AES-256) | No | `GestureEngineCubit` $1-B classifier ensemble |
| 15 | `gestureVisibility` (Ink trail) | Gestures | `vault_config` table (AES-256) | No | `StealthGesturePad` visual canvas |
| 16 | Vault Purge (Danger Zone) | Danger | SQLite Database & Media Disk | **Yes** (Purge Confirmation PIN) | Complete file shred & session reset |

---

## 3. Sub-Agent Orchestration Topology

### Sub-Agent 1: `architectural-code-auditor`
- **Domain**: State machine lifecycle, concurrency contracts, step-up authentication boundaries.
- **Tasks**:
  - Audit `SettingsMutationCubit` queue mechanics (`_enqueueGeneralMutation`) against rapid concurrent mutations.
  - Audit step-up authentication flow (`StepUpAuthGuard`, `requestSensitiveMutation`, `confirmSensitiveMutation`, `cancelSensitiveMutation`).
  - Compare pattern against industry standard enterprise patterns (Clean Architecture, BLoC v8+, MVI).

### Sub-Agent 2: `persistence-lifecycle-auditor`
- **Domain**: Drift SQLite persistence, encrypted DTO boundaries, cold boot hydration sequence.
- **Tasks**:
  - Audit `VaultStorageRepository.saveVaultConfig` and `loadVaultConfig`.
  - Verify fail-fast deserialization in `VaultConfigDto.fromJson`.
  - Analyze app launch boot order in `main.dart` / `app.dart` to determine whether unawaited `initialize()` creates cold-boot race conditions.

### Sub-Agent 3: `ui-reactivity-auditor`
- **Domain**: Flutter widget tree responsiveness, controller lifecycle, text debouncing.
- **Tasks**:
  - Audit `VaultAppearanceSettingsScreen`, `VaultSecuritySettingsScreen`, `VaultPrivacySettingsScreen`, `VaultGestureSettingsScreen`, `VaultDangerZoneScreen`.
  - Investigate `_titleController`, `_artistController`, and `_albumController` initialization in `VaultPrivacySettingsScreen` to verify if cold-start delayed emissions cause text controller desynchronization.
  - Review use of `setState(() {})` inside `StreamBuilder` trees.

### Sub-Agent 4: `test-suite-executor`
- **Domain**: Comprehensive unit, widget, and restart-simulation test implementation.
- **Tasks**:
  - Construct automated end-to-end setting mutation test matrix covering all 16 mutation vectors.
  - Build cold-start persistence simulation tests (persist config -> recreate repository -> verify rehydrated entity matches bit-for-bit).
  - Execute test runner, verify 100% pass rate, and document telemetry.

---

## 4. Verification & Criteria of Success
- [ ] Every mutation vector verified via automated test suite.
- [ ] Cold-start persistence verified with non-default configuration permutations.
- [ ] Debounced text inputs tested under blur/focus-loss, whitespace rejection, and high-frequency keystrokes.
- [ ] Code reviewed against professional Android/Flutter engineering standards.
