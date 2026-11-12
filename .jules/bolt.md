## 2024-11-12 - [Missing memCache Dimensions in AppNetworkImage]
**Learning:** Found missing memCache dimensions in `AppNetworkImage` for `FullBleedBannerSection`. When memCache dimensions are not specified, images are fully decoded into memory, which can lead to high memory usage. The dimensions should exactly match the layout bounds defined around the image, such as an `AspectRatio` widget.
**Action:** Constrain decoded image sizes using `memCacheWidth` and `memCacheHeight` matching explicit layout dimensions in the codebase to prevent full unconstrained image decoding.
