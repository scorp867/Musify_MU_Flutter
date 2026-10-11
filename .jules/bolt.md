## 2024-05-18 - Avoid NetworkImage for caching and memory performance
**Learning:** Found usage of `NetworkImage` in `BrowseView` and `LibraryView`. `NetworkImage` doesn't provide fine-grained memory control like setting `maxWidth`/`maxHeight` and lacks robust caching, which leads to bloated memory footprints in list-heavy views.
**Action:** Always prefer `CachedNetworkImageProvider` with `maxWidth` and `maxHeight` properties defined for images loaded over the network to limit memory usage and enable robust disk caching.
