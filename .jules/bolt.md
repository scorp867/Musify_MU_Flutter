## 2024-10-07 - CachedNetworkImage Error Widget Signature

**Learning:** When replacing `Image.network` with `CachedNetworkImage`, the property `errorBuilder: (context, error, stack)` must be changed to `errorWidget: (context, url, error)`. They have different signatures and property names.
**Action:** Always verify the parameter signatures of the replacement widget when optimizing or swapping out widgets.
