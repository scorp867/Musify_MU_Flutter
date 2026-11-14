# Core Vault Screens Figma Redesign Plan

## Overview & Resolved Scope
Elevate the core Vault screens (`PrivateVaultDashboardScreen`, `PrivatePlaylistDetailScreen`, and `VaultAuthScreen`) to match the refined Figma dark surface, border, typography, and spacing language established in `VaultSettingsScreen` and its sub-screens.

Confirmed user decisions:
1. **Scope (`Option B`)**: Core Vault Media & Auth screens only (`PrivateVaultDashboardScreen`, `PrivatePlaylistDetailScreen`, `VaultAuthScreen`).
2. **Dashboard & Playlist Detail Layout (`Option B` + `A2`)**: Tall `220px+` Minimalist Editorial Header on `PrivatePlaylistDetailScreen` paired with clean inset-grouped playlist and track presentation, plus a sleek Figma Modal Bottom Sheet (`showModalBottomSheet`) for track removal confirmation.
3. **Copy & Chrome Cleanup (`Option A` + `A1`)**: Full rewrite of titles, status labels, and clinical engineering jargon into calm human copy across all three screens, with matching updates across widget and integration test assertions.

---

## Design & Architectural Guardrails
- **Palette & Contrast**: Consume `VaultThemeData` tokens (`scaffold`, `surface`, `surfaceSubtle`, `surfaceHighlight`, `border`, `borderSubtle`, `textHighSalience`, `textMediumSalience`, `textLowSalience`, `accent`, `danger`) and `vaultDangerInk(vaultTheme)` for WCAG-compliant danger text on dark surfaces. Zero purple HSV hues (`[260, 310]`).
- **Geometry & Touch Targets**: Strict `8dp` corners (`VaultTheme.borderRadius8`) with `1px` crisp borders (`borderSubtle`) and `>= 48dp` interactive targets (bottom sheet uses clean top corners matching modal sheet conventions). Zero pill (`StadiumBorder`) buttons, zero emoji icons, zero em dashes, zero vague AI marketing copy.
- **Type & BLoC Safety**: Zero `!`, zero `??`, zero `.clamp()`, zero empty `catch` blocks, pure synchronous `build()` methods, and preservation of core test keys (`ValueKey`s), `Icons.arrow_back`, session lock dismissal behavior, and `pin_dot_filled` color (`0xFFB3463A`).

---

## Screen-by-Screen Implementation Plan

### 1. Shared Vault UI Components (`lib/features/vault/presentation/widgets/vault_settings_components.dart`)
Reuse existing Figma primitives (`vaultDangerInk`, `showVaultSettingsSnackBar`, `buildVaultSettingsAppBar`, `VaultSettingsSectionHeader`, `VaultSettingsGroup`) and add shared minimalist Vault widgets to avoid duplication across Dashboard and Detail:
- `VaultInlineSearchField`: Inset `surfaceSubtle` search field (`height: 42dp`, `VaultTheme.borderRadius8`, `1px` `borderSubtle` outline, `Icons.search` leading icon, clean `Icons.close_rounded` clear button).
- `showVaultConfirmationSheet`: Reusable dark Figma Modal Bottom Sheet (`surface` background, `borderSubtle` top hairline, drag handle, Poppins title/message, `46dp` primary action + `46dp` cancel button, returning `Future<bool>` for `Dismissible` / destructive prompts).

### 2. `PrivateVaultDashboardScreen` (`lib/features/vault/presentation/screens/private_vault_dashboard_screen.dart`)
- **AppBar**: Match `VaultSettingsScreen` (`vaultTheme.scaffold`, `borderSubtle` `1px` bottom rule, `'Private Vault'` title), keeping `vault_dashboard_portability_button`, `vault_dashboard_quick_lock_button`, and `vault_dashboard_settings_button`.
- **Search & Playlists List**: Use `VaultInlineSearchField` (`'Search playlists...'`), crisp `PLAYLISTS` `VaultSettingsSectionHeader`, and sleek inset-grouped dark playlist rows (`surface`, `borderSubtle` outline, `VaultTheme.borderRadius8`, clean `48x48` frosted cover thumbnail without redundant lock icon clutter, tabular `track • duration` metadata), preserving `Dismissible(key: ValueKey(playlist.id))` and `ValueKey('vault_playlist_tile_${playlist.id}')`.
- **Empty & Dialog Copy (`A1`)**:
  - Empty Vault: `'No Playlists Yet'`, `'Create a playlist to keep tracks separate from your main library.'`, `'Create Playlist'` (`vault_dashboard_create_button`).
  - Search Empty: `'No Results'`, `'Nothing matches "$query".'`.
  - Load Error: `'Unable to Load Playlists'`.
  - Create Dialog: `'New Playlist'` title (`'Name'`, `'Description (optional)'`, `'Enter a playlist name'`).
  - Delete Dialog: `'Delete Playlist'`, `'Remove "${playlist.name}" from your private vault?'`, `'Delete'`.
  - Floating CTA (`create_private_playlist_fab`): Sleek `elevation: 0`, `borderRadius8` extended FAB (`'New Playlist'`).

### 3. `PrivatePlaylistDetailScreen` (`lib/features/vault/presentation/screens/private_playlist_detail_screen.dart`)
- **AppBar**: Restrained Figma header (`vaultTheme.scaffold`, `borderSubtle` hairline bottom rule), keeping `playlist_detail_add_songs_button` and quick-lock icon button.
- **Tall Minimalist Editorial Header (`playlist_detail_header`, `A2`)**:
  - Elevated `surface` hero card (`borderSubtle` outline, `borderRadius8`, zero gradients) featuring a **`220x220`** frosted-peek cover frame with crisp border, subtle bottom peek indicator (`Tap to reveal` / `visibility_off_outlined` when frosted), bold Poppins title (`20sp w700 -0.3`), optional concise description, tabular metadata (`'2 tracks \u2022 7 min'`), and integrated `44dp` geometric `Play All` (`accent` fill) & `Shuffle` (`surfaceSubtle` fill + `border` outline) buttons (`playlist_detail_play_all_button`, `playlist_detail_shuffle_button`).
  - Aligned `TRACKS` section header row with quiet `Delete Playlist` destructive action using `vaultDangerInk`, followed by `VaultInlineSearchField` (`playlist_detail_search_input`, `'Search tracks...'`).
- **Track Rows & Modal Bottom Sheet Confirmation (`A2` & `A1`)**:
  - Inset-styled `ReorderableListView.builder` track rows with balanced `40x40` framed artwork thumbnails, tabular `'1'`, `'2'` indices, `accent` playing highlight, crisp `borderSubtle` dividers, and `'No Tracks Yet'` empty state.
  - Replace the track removal `AlertDialog` with `showVaultConfirmationSheet` (`ValueKey('remove_track_confirmation_sheet')`): title `'Remove Track'`, message `'Remove "${track.title}" from this playlist?'`, destructive `'Remove'` & `'Cancel'` buttons; `VaultSessionBloc` lock continues dismissing the modal + detail screen cleanly via `popUntil((route) => route.isFirst)`.
  - Update step-up reauth title override to `'Confirm It\'s You'` and delete playlist confirmation copy to `'Delete "${loaded.playlist.name}" from your private vault?'`.

### 4. `VaultAuthScreen` (`lib/features/vault/presentation/screens/vault_auth_screen.dart` & `vault_settings_screen.dart`)
- **AppBar**: Keep transparent AppBar + `ValueKey('vault_auth_back_button')` with `Icons.arrow_back`.
- **Mode Titles & Copy (`A1`)**:
  - `unlock`: `'Unlock Vault'` / `'Enter your 6-digit PIN'`
  - `stepUp`: `'Confirm It\'s You'` / `'Enter your PIN to continue'`
  - `verifyOldPin`: `'Current PIN'` / `'Enter your current 6-digit PIN'`
  - `rotatePin`: `'New PIN'` / `'Choose a new 6-digit PIN'` (also align `titleOverride: 'New PIN'` in `vault_settings_screen.dart`)
  - `purgeConfirmation`: `'Erase Vault'` / `'Enter your PIN to permanently erase your vault'`
  - Biometric canceled copy: `'Biometrics unavailable. Use your PIN.'`
- **Geometric Icon Frame, PIN Track & Status Banner (`A1`)**:
  - Mode icon inside a restrained `48x48` `surfaceSubtle` `borderRadius8` frame (`1px` `borderSubtle` border).
  - Status copy updates: `'Checking PIN...'`, `'Unlocked'`, `'Incorrect PIN. 1 attempt left.'` / `'Incorrect PIN. N attempts left.'` inside a subtle bordered error chip (`vaultDangerInk` text), and bordered `surface` lockout card showing `'Temporarily Locked'`, tabular `MM:SS` countdown (`vaultDangerInk`), and `'Try again once the timer ends.'`.
  - Keypad tiles (`72x72`, `borderRadius8`, `surface`, `borderSubtle` border) using `VaultTheme.fontFamily` (`'Poppins'`).

---

## Verification Plan
1. Update widget and integration tests matching rewritten titles, status labels, hero header, and Modal Bottom Sheet removal confirmation.
2. Run AST & design rule grep verification (`!`, `??`, `.clamp`, em dashes, `StadiumBorder`, purple colors).
3. Run `flutter analyze lib/features/vault/ test/features/vault/`.
4. Run all affected vault unit, adversarial, and integration tests + full `test/features/vault/`.
5. Run `python .agent/scripts/checklist.py .` and `flutter build apk --debug`.
