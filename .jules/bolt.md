## 2024-05-18 - [Network Image Caching in Flutter]
**Learning:** [Flutter's `Image.network` only caches images in memory. This leads to redundant network requests when scrolling large lists or restarting the app. The `cached_network_image` package provides disk caching capabilities which significantly improves perceived performance and reduces bandwidth.]
**Action:** [Always use `CachedNetworkImage` and `CachedNetworkImageProvider` from the `cached_network_image` package instead of `Image.network` and `NetworkImage` for network images, especially in grid and list views.]
