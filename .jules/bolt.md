
## 2023-11-01 - Optimizing avatar loading performance
**Learning:** Found that some screens were using NetworkImage directly without utilizing the caching functionality provided by cached_network_image library, downloading and retaining full resolution images, increasing memory footprints and rendering times.
**Action:** Replace NetworkImage with CachedNetworkImageProvider and add maximum constraints for efficient memory usage.
