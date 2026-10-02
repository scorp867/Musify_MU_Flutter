## 2024-05-24 - Memoize Sorted List in Getter

**Learning:** Computed properties (getters) accessed during Flutter's `build` method run on every UI rebuild. If they contain expensive operations like $O(n \log n)$ sorting, it can cause frame drops during simple interactions like tapping a filter chip.

**Action:** Cache the result of expensive operations in state variables. Initialize them in `initState` and selectively update them in `didUpdateWidget` only when the underlying data changes.
