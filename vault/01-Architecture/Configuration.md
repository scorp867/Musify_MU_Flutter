---
title: "Configuration & Build Tooling"
type: "configuration"
tags: [configuration, lints, analysis, build]
---

# Configuration & Build Tooling

## Dart Analysis Options (`analysis_options.yaml`)
Configured with `package:flutter_lints/flutter.yaml` with explicit excludes for generated files, native build outputs, and reverse-engineering scratch files:
- Excludes: `build/**`, `android/**`, `ios/**`, `windows/**`, `macos/**`, `linux/**`, `scratch/**`, and temporary test scripts.

## Code Generation (`build_runner`)
- Code generation toolchain (`drift_dev: ^2.34.0`, `build_runner: ^2.15.1`).
- Used to compile `app_database.g.dart` from the Drift schema in `lib/features/local_music/data/database/app_database.dart`.
- Command: `dart run build_runner build --delete-conflicting-outputs`

## Assets & Images
- Managed in `pubspec.yaml`:
  - `assets/images/app_icon.jpg`
  - `assets/animations/all_caught_up.json`
