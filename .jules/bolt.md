## 2024-05-24 - Missing memory limits on image decodes
**Learning:** Found several places where `Image.network` or `NetworkImage` are used instead of `AppNetworkImage` or `CachedNetworkImageProvider`. Unbounded image decodes cause massive memory pressure in Flutter lists.
**Action:** Replace `Image.network` with `AppNetworkImage` and set appropriate `memCacheWidth` and `memCacheHeight`. Replace `NetworkImage` with `CachedNetworkImageProvider` with `maxWidth` and `maxHeight`.
