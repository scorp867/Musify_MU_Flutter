# PLAN: Fix Visited Tabs Rebuilding on Online/Offline Mode Toggle

## 1. Problem Statement & Context
In `MainScreen` (`lib/features/shell/presentation/main_screen.dart`), the application manages tabs using an `IndexedStack` and a `_visitedTabs` set (`Set<int> _visitedTabs = {0};`).
When toggling between Offline and Online modes:
- If only the Home tab has been visited, only Home rebuilds.
- If Browse or Library have also been visited, all visited tabs rebuild simultaneously, regardless of which tab is currently active.
- Each visited tab instantiates a brand new BLoC and triggers network requests or local database fetches at the exact same moment.

## 2. Root Cause Analysis (Evidence from Code)
1. **Persistent Set Accumulation (`_visitedTabs`)**:
   - In `MainScreenState`, `_visitedTabs` tracks which tabs were opened (`onTap: (index) => _visitedTabs.add(index)`).
   - Once added, tabs are never pruned from `_visitedTabs`.
2. **`IndexedStack` Retains All Visited Children**:
   - `IndexedStack` keeps all elements in `_visitedTabs` alive in the element tree.
   - When `_toggleMode()` executes, `setState()` updates `_isOnlineMode` in `_MainScreenState`.
   - `IndexedStack` rebuilds every child present in its `children` list with the new `isOnlineMode` value.
3. **Hard Root-Widget Swapping in Tab `build()` Methods**:
   - `_BrowseTab`: Switches between `OfflineBrowseView` and `AuthGatedBlocProvider<BrowseBloc>` (triggers `BrowseLoadRequested()`).
   - `_LibraryTab`: Switches between `OfflineLibraryView` and `AuthGatedBlocProvider<LibraryBloc>` (triggers `LibraryLoadRequested()`).
   - `HomeTab`: Switches between `LocalMusicScreen` and `OnlineHomeScreen` (triggers `HomeFeedLoadRequested()`).
   - Because the widget runtime types change completely, Flutter unmounts and remounts each visited tab tree, firing background requests across all visited tabs at once.

---

## 3. Solution Strategies & Trade-offs

### Option A: Reset Visited Tabs on Mode Switch (Prune Inactive Tabs)
- **Concept**: When switching modes, clear `_visitedTabs` and add only `_currentIndex`. Guard `HomeTab` with `_visitedTabs.contains(0)`.
- **Pros**:
  - Minimal code change, zero risk of regressing existing behavior.
  - Inactive tabs are not built in the new mode until tapped.
  - Eliminates all background network and database requests on mode toggle.
- **Cons**:
  - Switching back to an inactive tab starts from an uninitialized state in the new mode (expected, since mode changed).

### Option B: Dual `IndexedStack` (Online Stack & Offline Stack)
- **Concept**: Maintain two independent `IndexedStack`s (one for Online tabs, one for Offline tabs).
- **Pros**:
  - Full state & scroll position preservation: switching from Spotify Online to Local Offline and back to Online restores exact state without reload.
- **Cons**:
  - Slightly higher memory footprint when both stacks are loaded.

### Option C: Deferred Mode Synchronization per Tab
- **Concept**: Each tab tracks the mode it was built in. If the global mode changes while the tab is inactive, the tab defers rebuilding until it becomes the active index.
- **Pros**:
  - Keeps widget trees alive in their previous mode until focused.
- **Cons**:
  - Leaves stale mode widgets in background memory.

---

## 4. Implementation Plan (Phase Breakdown)

### Phase 1: Context & Decision Finalization
- Confirm preferred strategy with user via Socratic Gate.

### Phase 2: Refactoring `MainScreen`
- Update tab instantiation and visited tab lifecycle in `lib/features/shell/presentation/main_screen.dart`.
- Ensure `HomeTab` follows consistent lazy-mount semantics when appropriate.
- Verify smooth transition with `ModeTransition`.

### Phase 3: Verification & Edge Cases
- Test switching mode from Tab 0, Tab 1, and Tab 2.
- Verify only active tab rebuilds/fetches on mode switch.
- Verify inactive tabs load correctly upon subsequent navigation.
- Run Flutter analyzer / unit tests.
