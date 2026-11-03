## 2024-03-24 - Network Image Replacement
**Learning:** The project uses `AppNetworkImage` which is preferred over `Image.network` and `NetworkImage`.
**Action:** Replace direct uses of `Image.network` and `NetworkImage` with `AppNetworkImage` or `CachedNetworkImageProvider` to ensure images are cached properly and performance is improved.
