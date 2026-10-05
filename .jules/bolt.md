## 2024-05-15 - [Avoid computing expensive getters during widget builds]
**Learning:** `LibraryViewData.sortedByRecents()` was called on every rebuild in `_LibraryContentState` which re-sorted items and was a CPU bottleneck. This occurs frequently because getter properties in the build loop do not hold state.
**Action:** Store expensive computed values in state in `initState` or `didUpdateWidget`, instead of recalculating them during every build via a getter.
