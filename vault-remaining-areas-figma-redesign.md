# Vault Remaining Areas Figma Redesign Plan

## Mobile Design Checkpoint (`mobile-developer` / `mobile-design`)
- **Platform**: Android + iOS (Flutter cross-platform, with focus on Android dark material surfaces & safe `800x600`+ viewport fit)
- **Framework**: Flutter (`flutter_bloc`, `VaultTheme` InheritedTheme)
- **Files Read**: `.agent/agents/mobile-developer.md`, `.agent/skills/mobile-design/SKILL.md`, `.agent/skills/mobile-design/mobile-design-thinking.md`
- **3 Core Principles Applied**:
  1. **Single Theme Authority + Composition**: Replace hardcoded legacy greens (`0xFF1DB954`, `0xFF1ED760`) and neutral grays (`0xFF282828`, `PlayerColors.*`) with `VaultThemeData` tokens (`warmEspresso` / `forestNoir`), explicitly forwarded across `useRootNavigator: true` modal routes.
  2. **Touch-First Geometry & Viewport Safety**: Maintain `>= 44-48dp` interactive hit targets, strict `8dp` (`VaultTheme.borderRadius8`) corners, `1px` `borderSubtle` hairlines, bounded keyboard/viewport scrolling, and thumb-zone primary CTAs.
  3. **Pure State & Explicit Lifecycle**: Dispose all sheet/form `TextEditingController`s and `ScrollController`s deterministically, keep `build()` side-effect-free, and preserve existing BLoC/Cubit/Navigator session-lock dismissal invariants.
- **Anti-Patterns Avoided**: No purple gradients (`HSV [260, 310]`), no pill (`StadiumBorder`) buttons, no emojis, no em dashes, no `!`/`??`/`.clamp()` value fallbacks, no duplicated keypad/sheet/dialog boilerplate.

---

## Scope Breakdown

### 1. Shared Vault Sheet, Dialog & PIN Primitives (`lib/features/vault/presentation/widgets/vault_settings_components.dart`)
- `resolveVaultTheme(BuildContext context, [VaultThemeData? explicitTheme])`: Resolves ancestor `VaultTheme.maybeOf(context)`, falling back to `SettingsMutationCubit` in `context` or `getIt` when sheets open above `VaultTheme` via `useRootNavigator: true` (including public routes like Player's `MoreOptionsBottomSheet`).
- `VaultSheetScaffold`: Unified Figma dark bottom sheet container (`vaultTheme.surface`, top `16dp` corners, `1px` `vaultTheme.borderSubtle` top frame, drag handle, header title/subtitle + trailing slot + accessible close icon button, hairline divider).
- `VaultSegmentedControl<T>`: Shared `44dp` geometric `8dp` recessed toggle bar (`vaultTheme.background`, `vaultTheme.accent` active segment with `vaultTheme.scaffold` ink) shared by `VaultLocalSongPickerSheet` and `VaultPortabilitySheet`.
- `showVaultCreatePlaylistSheet`: Replaces both `AlertDialog` playlist creators (`PrivateVaultDashboardScreen` & `PrivatePlaylistSelectionDialog`) with a keyboard-aware dark Figma modal bottom sheet (`VaultSheetScaffold`), self-contained `StatefulWidget` disposing controllers cleanly, preserving `TextFormField` structure (`first` = Name, optional `last` = Description) and `Create` CTA.
- `confirmVaultPlaylistDeletion`: Thin shared wrapper over `showVaultConfirmationSheet` used by both `PrivateVaultDashboardScreen` and `PrivatePlaylistDetailScreen` (`sheetKey: ValueKey('delete_playlist_confirmation_sheet')`).
- `VaultPinDotsRow` & `VaultPinKeypad` (`VaultKeypadActionTile`): Shared Figma `64x64` (`8dp`, spring press scale) keypad and crisp `14x14` geometric PIN dot strip shared by `VaultAuthScreen` and `VaultSetupScreen`, preserving test keys (`setup_pin_dot_slot_$index`, `pin_dot_filled`, `pin_dot_empty`).

### 2. Track Picker Sheet (`lib/features/vault/presentation/widgets/vault_local_song_picker_sheet.dart`)
- Capture active `VaultThemeData` in `.show(...)` and apply across header, segmented control, inline description card, `VaultInlineSearchField`, `Select All` / `Clear` toggle button, grouped inset track rows, checkboxes, and bottom commit bar.
- Clean human copy: remove `"Storage repository unavailable."` (`"Unable to save tracks right now."`), simplify descriptions (`copyToVault`: `"Keeps the original file in your library and links it privately."`; `moveToVault`: `"Moves the audio file into private storage and hides it from public apps."`), and refine empty states (`"No Songs Found"` / `"No Local Songs"`).
- Preserve existing interactive keys: `picker_track_${track.dataPath}`, `picker_commit_add_songs_button`.

### 3. Backup / Portability Sheet (`lib/features/vault/presentation/widgets/vault_portability_sheet.dart`)
- Capture active `VaultThemeData` and migrate entirely off `#1DB954` and `PlayerColors.*` onto `VaultSheetScaffold`, `VaultSegmentedControl`, inset `VaultSettingsGroup`-styled cards, `VaultSettingsSectionHeader`, and `showVaultSettingsSnackBar`.
- Clean human copy:
  - Header: `"Import & Export"`
  - Tabs: `"Import"` and `"Export"`
  - Device section: `"Device Music"`, `"${count} tracks found on this device"`, `"Copy to Vault"`, `"Move to Vault"`
  - Spotify section: `"Spotify Playlists (${count})"`, `"No Spotify playlists found in your library."`, geometric `40x40` badge, `"Import"` outlined `8dp` button
  - Export section: `"Restore to Device Storage"`, concise calm body (`"Moves hidden audio files back to Music/Musify_Exported so they appear in your regular library again."`), primary `"Export All ${count} Hidden Tracks"` / `"No Hidden Tracks to Export"`, `"Playlists (${count})"`, `"$sandboxedCount hidden ${sandboxedCount == 1 ? 'track' : 'tracks'}"`.
- Preserve keys: `portability_import_local_copy_btn`, `portability_import_local_move_btn`, `portability_sp_${item.uri}`, `portability_export_all_btn`, `portability_export_pl_${playlist.id}`.

### 4. Playlist Selection Sheet (`lib/features/vault/presentation/widgets/private_playlist_selection_dialog.dart`)
- Migrate off `#282828` / `#1ED760` / `#242424` to `resolveVaultTheme` + `VaultSheetScaffold`.
- Replace inner `AlertDialog` with `showVaultCreatePlaylistSheet(showDescription: false)` (fixes unreleased `TextEditingController` too!).
- Inset bordered playlist rows with `VaultArtworkImage.forPlaylist` (size `40`, `8dp` radius) + track count + chevron, preserving `ValueKey('picker_playlist_${playlist.id}')`.
- Clean human copy: `"Select Playlist"` (or clean header `"Choose Playlist"` -> update `stealth_ingestion_gate_test.dart`), `"New"`, `"No Playlists Yet"`, `"New Playlist"`.

### 5. Dashboard & Detail Delete/Create Modals
- `lib/features/vault/presentation/screens/private_vault_dashboard_screen.dart`: Switch `_showCreatePlaylistDialog` to `showVaultCreatePlaylistSheet` and `_confirmDeletePlaylist` to `confirmVaultPlaylistDeletion`.
- `lib/features/vault/presentation/screens/private_playlist_detail_screen.dart`: Switch `_confirmDeletePlaylist` to `confirmVaultPlaylistDeletion`.
- `lib/features/vault/presentation/screens/vault_auth_screen.dart`: Reuse shared `VaultPinKeypad` / spring keypad tile so `VaultAuthScreen` and `VaultSetupScreen` share one single keypad implementation cleanly.

### 6. Vault PIN Setup Screen (`lib/features/vault/presentation/screens/vault_setup_screen.dart`)
- Align header, `44x44` geometric icon badge, subtle `Step 1 of 2` / `Step 2 of 2` caption, `VaultPinDotsRow` (`setup_pin_dot_slot_$index`), inline danger feedback banner, and `VaultPinKeypad` (`64x64`, `8dp`) with `VaultAuthScreen` so `800x600` test and mobile viewports never clip.
- Clean human copy: `"Create PIN"`, `"Confirm PIN"`, `"Setting Up Vault"`, `"Securing your vault..."`, `"Vault Ready"`, `"PINs do not match. Start over."`

### 7. Gesture Enrollment Screen (`lib/features/vault/presentation/screens/gesture_enrollment_screen.dart`)
- Use `buildVaultSettingsAppBar` with title `"Set Unlock Gesture"` (keeping `gesture_enrollment_back_button` with `Icons.arrow_back`).
- Refine 3-segment progress bar (`gesture_step_indicator_$i`), clean step subtitle/title hierarchy, inset framed drawing surface (`gesture_enrollment_pad`) preserving `AspectRatio(1.0)` + `Listener`, refined telemetry inset card (`gesture_telemetry_card`) with `tabularFigures()`, and `48dp` geometric `8dp` bottom controls (`Clear Stroke`, `Start Over`, `Re-record`, `Save Gesture`).
- Clean human copy: `"Building Pattern"` / `"Combining your 3 samples..."` (no DTW Barycenter Averaging jargon in UI copy), `"Test Your Gesture"`, `"Gesture Saved"`, `"Pattern Mismatch"` / `"Try Again"`, step-up title `"Confirm It's You"` (or `"Confirm Gesture"`).

---

## Test & Verification Plan
1. Update affected widget/integration tests for modal bottom sheet conversions and calm human copy (`vault_local_song_picker_sheet_test.dart`, `vault_portability_sheet_test.dart`, `stealth_ingestion_gate_test.dart`, `private_vault_dashboard_screen_test.dart`, `m3_adversarial_challenge_test.dart`, `adversarial_session_lock_dialog_dismissal_test.dart`, `gesture_enrollment_screen_test.dart`, `gesture_enrollment_screen_adversarial_test.dart`), and add focused `VaultSetupScreen` + `PrivatePlaylistSelectionDialog` coverage if needed.
2. Run static AST check (`rg`) for banned tokens (`!`, `.clamp(`, `StadiumBorder`, em dashes, hardcoded legacy green `#1DB954`/`#1ED760` in vault UI).
3. Run `flutter analyze` across `lib/features/vault/`, `lib/features/player/`, and `test/features/`.
4. Run full `test/features/vault/` and `test/features/player/presentation/widgets/more_options_bottom_sheet_test.dart` suites.
5. Run `python3 .agent/scripts/checklist.py .` and `flutter build apk --debug`.
