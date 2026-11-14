# Vault Settings Figma Redesign & Palette Refinement Plan

## 1. Objective & Design Direction

Elevate the Flutter Secure Vault presentation layer (`lib/features/vault/presentation/`) from boxy developer-styled cards to a clean, minimal, Figma-grade dark interface, prioritizing **Vault Settings (`VaultSettingsScreen`) and all 5 dedicated sub-screens** (`VaultAppearanceSettingsScreen`, `VaultSecuritySettingsScreen`, `VaultPrivacySettingsScreen`, `VaultGestureSettingsScreen`, `VaultDangerZoneScreen`) alongside **refining both vault color palettes** (`Warm Espresso` and `Forest Noir`).

Core principles:
- **True dark tonal hierarchy**: Deep near-black canvas (`scaffold`), calm +4% to +8% elevated card surfaces (`surfaceSubtle`, `surface`, `surfaceHighlight`), `1.0px` low-contrast hairline borders (`border`, `borderSubtle`), and crisp off-white typography (`>= 4.5:1` AA / `>= 7:1` AAA contrast without pure `#FFFFFF` OLED halation).
- **Inset-grouped Figma layout**: Replace fragmented, individually bordered cards with grouped vertical containers sharing internal `1.0px` inset dividers, generous `20.0px` screen gutters, crisp typographic hierarchy (`Poppins`), and uniform `>= 48dp` touch targets.
- **Plain, human-first UI copy**: Remove internal math/telemetry strings from user-facing cards while preserving every security warning invariant and existing test selector contract.
- **Strict workspace & architectural invariants**:
  - `8.0px` geometric corners (`VaultTheme.borderRadius8`, `VaultTheme.shape8`), zero `StadiumBorder`/pill shapes.
  - Zero purple/violet hues (`HSV hue` never in `[260, 310]`).
  - Zero emoji icons and zero em dashes in UI copy or code.
  - 100% functional parity across `SettingsMutationCubit`, `StepUpAuthGuard`, `ScreenPrivacyCubit`, `GestureEngineCubit`, and `VaultSessionBloc`.

---

## 2. Refined Palette Tokens (`Warm Espresso` & `Forest Noir`)

### 2.1 Token Comparison & Contrast Matrix

#### Palette 1: Warm Espresso

| Token | Legacy Hex | Refined Hex | Role & Usage |
| :--- | :--- | :--- | :--- |
| `scaffold` | `#1A120E` | `#120E0C` | Deep espresso obsidian screen backdrop |
| `surfaceSubtle` | `#2A1B14` | `#191411` | Primary inset-grouped settings & list cards |
| `background` | `#3A2418` | `#1E1814` | Secondary stage & sheet container fill |
| `surface` | `#6B4A2E` | `#231C18` | Elevated card, dialog, & reauth overlay card |
| `surfaceHighlight` | `#4A3022` | `#2C241E` | Selected row tint, icon badge fill, pressed state |
| `borderSubtle` | `#332215` | `#261F1A` | `1.0px` internal divider inside grouped cards |
| `border` | `#4A3320` | `#342B24` | `1.0px` outer hairline card & input stroke |
| `textHighSalience` | `#A88462` | `#ECE6E0` | Warm alabaster primary titles & values (`12.3:1` to `15.5:1`) |
| `textMediumSalience` | `#8D6C4F` | `#AFA59C` | Warm stone subtitles & section labels (`6.3:1` to `7.9:1`) |
| `textLowSalience` | `#4A3322` | `#827870` | Placeholders & disabled ink (`3.9:1` to `4.5:1`) |
| `accent` | `#D4B08C` | `#D6B48E` | Warm champagne accent for active states & CTA buttons (`7.8:1` to `9.9:1`) |
| `danger` | `#A84438` | `#B3463A` | Muted terracotta-crimson destructive fill (`4.4:1` with `textHighSalience`, `3.5:1` on `scaffold`) |

#### Palette 2: Forest Noir

| Token | Legacy Hex | Refined Hex | Role & Usage |
| :--- | :--- | :--- | :--- |
| `scaffold` | `#0F1F17` | `#0B120E` | Deep pine obsidian screen backdrop |
| `surfaceSubtle` | `#152A1F` | `#111B16` | Primary inset-grouped settings & list cards |
| `background` | `#1E3A2E` | `#15221B` | Secondary stage & sheet container fill |
| `surface` | `#3E5A3F` | `#1A2821` | Elevated card, dialog, & reauth overlay card |
| `surfaceHighlight` | `#284A39` | `#22332A` | Selected row tint, icon badge fill, pressed state |
| `borderSubtle` | `#193024` | `#1D2C24` | `1.0px` internal divider inside grouped cards |
| `border` | `#234233` | `#293D32` | `1.0px` outer hairline card & input stroke |
| `textHighSalience` | `#6B7F67` | `#E3EBE6` | Sage alabaster primary titles & values (`11.0:1` to `15.6:1`) |
| `textMediumSalience` | `#52664F` | `#9DB0A5` | Mineral sage subtitles & section labels (`5.8:1` to `8.3:1`) |
| `textLowSalience` | `#284235` | `#708479` | Placeholders & disabled ink (`3.9:1` to `4.6:1`) |
| `accent` | `#9EB29A` | `#9BC2AA` | Calm sage-jade accent for active states & CTA buttons (`6.8:1` to `9.7:1`) |
| `danger` | `#9C423B` | `#B1453A` | Muted rust-crimson destructive fill (`4.6:1` with `textHighSalience`, `3.4:1` on `scaffold`) |

Notes:
- **Derived High-Contrast Danger Text**: When small error/warning body text renders over dark `surfaceSubtle` or `danger`-tinted backgrounds (e.g., `decoy_validation_error`, Danger Zone impact items), derive ink via `Color.lerp(vaultTheme.danger, vaultTheme.textHighSalience, 0.35)` so body text exceeds `>= 5.0:1` contrast without hardcoding unthemed hexes or weakening filled `danger` button/snackbar contrast.
- **Cross-Screen Consistency**: Both palettes preserve semantic token roles across `VaultAuthScreen`, `VaultSetupScreen`, `PrivateVaultDashboardScreen`, `PrivatePlaylistDetailScreen`, and `ReauthBlurOverlay`. Removing `#6B4A2E` / `#3E5A3F` mid-tone cards directly improves readability on `ReauthBlurOverlay`, playlist tiles, and auth dialogs.

---

## 3. Figma-Style Settings Component Architecture

Refactor duplicated screen boilerplate and ad-hoc bordered containers in `lib/features/vault/presentation/screens/vault_settings_screen.dart` into clean reusable presentation primitives (either as dedicated helper widgets inside `lib/features/vault/presentation/widgets/vault_settings_components.dart` or scoped sections within the presentation layer):

1. **`VaultSettingsScaffold`**:
   - Encapsulates `ScreenPrivacyCubit` lifecycle registration (`engage()` on mount / `release()` on dispose), `StreamBuilder<VaultConfig>` reactivity wrapping `VaultTheme`, consistent AppBar styling (`toolbarHeight: 60.0`, `scrolledUnderElevation: 0.0`, clean `20.0px` horizontal gutters, `8.0px` focused ink highlights), and unified themed `SnackBar` helper (`showVaultSettingsSnackBar`).
   - Eliminates 6 duplicated copies of `_engageScreenPrivacy` / `_releaseScreenPrivacy` / `_resolveSettingsMutationCubit` boilerplate while honoring constructor injection fallbacks cleanly.
2. **`VaultSettingsSectionHeader`**:
   - Clean Figma section eyebrow (`11.5sp`, `w600`, `letterSpacing: 0.7`, `textMediumSalience`) with `EdgeInsets.only(left: 4.0, bottom: 8.0)` above every grouped card.
3. **`VaultSettingsGroup`**:
   - Single rounded (`8.0px`) container with `vaultTheme.surfaceSubtle` fill and `1.0px` `vaultTheme.border` stroke (`ClipRRect` with `VaultTheme.borderRadius8`), automatically inserting `1.0px` `vaultTheme.borderSubtle` dividers between child rows (`EdgeInsets.only(left: ...)` inset when paired with leading icons).
4. **Uniform Row Primitives (`minHeight >= 52.0px`, `>= 8dp` spacing)**:
   - **`VaultSettingsNavRow`**: `36x36` subtle `surfaceHighlight` (or muted `danger.withValues(alpha: 0.14)`) icon container (`8.0px` radius) + concise title (`14.5sp w500`) + single-sentence subtitle (`12.0sp w400 textMediumSalience`, `height: 1.35`) + `Icons.chevron_right` (`18px`). Zero nested outer-to-inner triple borders.
   - **`VaultSettingsToggleRow`**: Left icon optional + title + concise description + styled dark `Switch` (accent thumb/track when active, subtle `border` outline & `surfaceHighlight` track when off). Entire row taps toggle cleanly.
   - **`VaultSettingsOptionRow<T>`**: Used inside `VaultSettingsGroup` for Grace Timeout, Re-Auth Interval, Keypad Layout, Background Playback, and Gesture Sensitivity. Renders subtle `surfaceHighlight.withValues(alpha: 0.6)` row highlight on selection, concise title + 1-line description, and custom crisp `18px` circular radio indicator.
   - **`VaultSettingsInfoCallout`**: Quiet left-accented or subtle hairline footnote (`Icons.info_outline`, `12.0sp textMediumSalience`) replacing heavy alert boxes for neutral hints.

---

## 4. Screen-by-Screen UI Plan

1. **Settings Hub (`VaultSettingsScreen`)**:
   - Clean AppBar (`Vault Settings`), compact geometric (`8.0px`) status indicator (`vault_settings_status_badge` showing `Active Session` without cramped multi-border nesting) and crisp `vault_settings_quick_lock_button`.
   - Group 1 (`VAULT PREFERENCES`): `nav_tile_appearance`, `nav_tile_security`, `nav_tile_privacy`, `nav_tile_gestures`.
   - Group 2 (`DATA & RECOVERY`): `nav_tile_danger_zone` styled with muted crimson icon tint and clear subtitle.
2. **Appearance (`VaultAppearanceSettingsScreen`)**:
   - **Theme section**: Clean 2-column palette selector (`palette_warm_espresso`, `palette_forest_noir`) featuring a miniature app preview strip (mini scaffold + grouped card + accent dot) and 5 refined color swatches updated to the new hex values, plus crisp `accent` `1.5px` selection border and subtle check icon.
   - **Privacy Shield section**: Unified card placing the live frosted preview (`blur_preview_container` preserving `BackdropFilter` with `ImageFilter.blur(sigmaX: activeBlurSigma, sigmaY: activeBlurSigma)`) cleanly over an understated mini track mockup, directly connected below an inset `1px` divider to `blur_slider` and numeric `sigma` badge.
3. **Security & Authentication (`VaultSecuritySettingsScreen`)**:
   - **Access**: Grouped card containing `biometric_auth_switch` and `tile_pin_rotation` (`StepUpAuthGuard` flows unchanged).
   - **Session Lock Timing**: Grouped radio rows for `Background Grace Timeout` (`grace_timeout_immediate`, `grace_timeout_thirty_seconds`, `grace_timeout_one_minute`, `grace_timeout_five_minutes`) and `Active Re-Authentication` (`reauth_interval_5_min`, `reauth_interval_15_min`, `reauth_interval_30_min`, `reauth_interval_never`).
   - **PIN Pad**: Grouped radio rows (`keypad_layout_standard`, `keypad_layout_randomized`).
4. **Playback & Privacy (`VaultPrivacySettingsScreen`)**:
   - **Screen & Notification Privacy**: Grouped switches (`screen_privacy_switch`, `metadata_masking_switch`).
   - **When Vault Locks**: Grouped playback options (`lock_playback_stop`, `finish_track`, `continue_masked`).
   - **Decoy Now-Playing Persona**: Single structured card containing clean stacked fields (`decoy_title_field`, `decoy_artist_field`, `decoy_album_field`) with unified dark input decoration (`surface` fill, `border` default stroke, `accent` focus ring, `8.0px` radius), conditional `decoy_validation_error` alert row, and full-width `48dp` geometric (`8.0px`) `decoy_save_button`. Uses themed `SnackBar`.
5. **Gesture Controls (`VaultGestureSettingsScreen`)**:
   - **Stealth Gateway Card (`gesture_status_card`)**: Calm Figma status header showing `Active & Armed` with subtle status dot and two crisp key-value metadata rows without developer jargon:
     - `Recognition`: `Local Multi-Stage Engine` (replaces `$1-B + FastDTW + 7D Rubine`)
     - `Execution`: `Isolated Background Thread` (replaces `latency <= 35ms, 0 jank`)
   - **Match Sensitivity**: Grouped radio options (`gesture_sensitivity_strict`, `gesture_sensitivity_balanced`, `gesture_sensitivity_relaxed`) with clean human descriptions (removing raw `S_ensemble >= ...` equations).
   - **Drawing Feedback**: Grouped toggle row for `gesture_ink_visibility_switch`.
   - **Action**: Full-width `48dp` secondary-accent / bordered geometric (`8.0px`) button `re_enroll_gesture_button` routing through `StepUpAuthGuard`.
6. **Danger Zone (`VaultDangerZoneScreen`)**:
   - **Consequences Card (`danger_zone_warning_card`)**: Clean structured red-tinted card with concise header + 5 scannable icon-led consequence rows (replacing literal `'* '` ASCII bullets while keeping the verbatim substrings asserted by tests: `Cryptographic Shredding`, `Database Wipe`, `64KB Zero-Overwriting`, `RAM Zeroization`, `Irreversible Action`).
   - **Bottom Action Dock**: `SafeArea` footer containing the full-width `48dp` `purge_vault_button` (`8.0px` geometric shape, `danger` fill, `textHighSalience` ink) and themed `SnackBar` for failure feedback.

---

## 5. Planned Edits & Verification

### 5.1 Files to Update
- `lib/features/vault/domain/policies/vault_theme_palette_policy.dart` (refined ARGB/hex constants and doc comments matching Warm Espresso & Forest Noir)
- `lib/features/vault/presentation/theme/vault_theme.dart` (refined `VaultThemeData.fromPalette` tokens)
- `lib/features/vault/presentation/widgets/vault_settings_components.dart` (new cohesive Figma-style settings scaffold, section header, inset group container, nav/toggle/option rows, and themed snackbar helper)
- `lib/features/vault/presentation/screens/vault_settings_screen.dart` (full visual & structural refactor across Hub + all 5 sub-screens, updated Appearance preview swatches, clean telemetry-free copy)
- Test hex alignment (only where exact legacy hex literals are asserted):
  - `test/features/vault/domain/policies/policies_test.dart`
  - `test/features/vault/presentation/theme/vault_theme_test.dart`
  - `test/features/vault/presentation/widgets/reauth_blur_overlay_test.dart`
  - `test/features/vault/presentation/screens/private_vault_dashboard_screen_test.dart`

### 5.2 Verification Commands
1. `flutter analyze`
2. `flutter test test/features/vault/`
3. `python .agent/scripts/checklist.py .`
4. `flutter build apk --debug`
