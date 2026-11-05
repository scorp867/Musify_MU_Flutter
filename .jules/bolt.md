## 2024-05-18 - [Flutter Image Memory Optimization]
**Learning:** Discovered that raw `Image.network` calls without `memCacheWidth`/`memCacheHeight` constraints decode high-resolution images fully into memory, leading to severe memory bloat and jank during fast scrolling in lists or grids.
**Action:** Always replace `Image.network` with the custom `AppNetworkImage` wrapper. Explicitly provide `memCacheWidth` and `memCacheHeight` (matching the widget constraints exactly) to restrict the decoded image buffer size and drastically reduce memory consumption.
