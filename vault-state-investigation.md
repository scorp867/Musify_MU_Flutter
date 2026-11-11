# Vault State Machine & Transition Investigation Plan

**Project Type:** MOBILE (Flutter / Dart)  
**Target Subsystem:** Private Vault (`lib/features/vault/`, `lib/app/routes/vault_routes.dart`, `lib/app/di/vault_injection.dart`)  
**Objective:** Exhaustively investigate all Vault state machines, screen transitions, and state lifecycles to ensure zero unexpected or illegal states can occur.

---

## State Engines in Scope

1. **VaultSessionBloc** (`VaultSessionState`): `uninitialized`, `locked`, `authenticating`, `unlocked`, `lockedOut`, `gracePeriodActive`
2. **GestureEngineCubit** (`GestureEngineState`): `idle`, `capturing`, `evaluating`, `enrolling`, `matched`, `failed`
3. **VaultPlaylistsCubit** (`VaultPlaylistsState`): `initial`, `loading`, `loaded`, `mutating`, `error`
4. **ScreenPrivacyCubit** (`ScreenPrivacyState`): `secure`, `obscured`, `exposed`
5. **PinPadCubit** (`PinPadState`): `entering`, `verifying`, `blocked`, `maxAttemptsReached`
6. **VaultSetupCubit** (`VaultSetupState`): `unconfigured`, `pinPrompt`, `gesturePrompt`, `configured`
7. **SettingsMutationCubit** (`SettingsMutationState`): `idle`, `mutating`, `success`, `failure`
8. **UI & Route Transitions**: `VaultRoutes` guard invariants, `ReauthBlurOverlay`, `StealthGesturePad`, AppLifecycleState transitions (`resumed`, `paused`, `inactive`, `detached`).

---

## Action Plan

- [ ] **Task 1: Baseline Test Execution & Flakiness Audit**
  - Run all 50+ existing vault test suites (`test/features/vault/`) and catalog failures or flakiness.
- [ ] **Task 2: Subagent 1 (Logic & State Invariant Audit)**
  - Audit all BLoC/Cubit event handlers, `mapEventToState`/`emit`, sealed class coverage, concurrency transformers (`sequential`, `restartable`, `droppable`), and banned AST fallbacks (`??`, `.clamp()`, silent returns).
- [ ] **Task 3: Subagent 2 (Presentation & Screen Transition Audit)**
  - Audit UI screen transitions, `BlocSelector`/`BlocListener` lifecycle, route guard redirects in `vault_routes.dart`, and app background/foreground transitions.
- [ ] **Task 4: State Transition Matrix Synthesis & Anomaly Reporting**
  - Synthesize state transition tables for every state machine, mapping valid inputs, forbidden transitions, and edge cases.
- [ ] **Task 5: Author Adversarial State Transition Tests**
  - Write new targeted tests in `test/features/vault/` exercising uncovered edge cases and invalid state transitions.
- [ ] **Task 6: Final Verification & Diagnostic Report Delivery**
  - Run `flutter test` across all vault suites to verify 100% test pass rate with new tests.
