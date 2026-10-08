## 2024-10-08 - Don't downgrade dependencies for cached network image
**Learning:** When flutter test or analyze fails with a dependencies conflict involving the dart sdk and flutter sdk version, do NOT modify pubspec.yaml to hack around it and do NOT downgrade transitive packages unless explicitly instructed to. It will break the build for actual compilation targets.
**Action:** Verify actual source implementations only, use original pubspec as source of truth and revert temporary fixes before submitting.
