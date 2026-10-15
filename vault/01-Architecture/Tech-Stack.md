---
title: "Tech Stack & Dependencies"
type: "tech-stack"
tags: [tech-stack, dependencies, pubspec, libraries]
---

# Tech Stack & Dependencies

Musify MU relies on an optimized, modern Flutter and Dart ecosystem (SDK `^3.11.4`).

## Core Framework & State Management
- **Flutter SDK**: Multi-platform rendering engine.
- **`flutter_bloc: ^9.1.1`**: Predictable, testable event-driven state machine.
- **`equatable: ^3.0.0`**: Value equality without boilerplate for BLoC states and events.
- **`get_it: ^9.2.1`**: Service locator for clean dependency injection at the app composition root.

## Local Storage & Persistence
- **`drift: ^2.34.4`**: Type-safe SQLite persistence for local music files and metadata.
- **`sqlite3_flutter_libs: ^0.6.0+eol`**: Native C SQLite binaries across Android, iOS, Windows, macOS, and Linux.
- **`shared_preferences: ^2.5.5`**: Lightweight key-value store for app settings and active playback mode.
- **`flutter_secure_storage: ^11.1.1`**: Platform-encrypted secure enclave for auth tokens, cookies, and secrets.

## Audio & Media Pipeline
- **`just_audio: ^0.10.6`**: Feature-rich hardware audio playback engine.
- **`audio_service: ^0.18.19`**: Background audio playback, lockscreen controls, and system media notification integration.
- **`on_audio_query: ^2.9.0`**: MediaStore and device storage music scanner.

## Network & Serialization
- **`dio: ^5.7.0`**: High-performance HTTP client with interceptors and connection pooling.
- **`native_dio_adapter: ^1.4.0`**: Native platform networking (Cronet on Android, NSURLSession on iOS) with HTTP/3 & QUIC support.
- **`protobuf: ^6.1.0`**: Google Protocol Buffers binary wire deserialization.
- **`crypto: ^3.0.7`**: Cryptographic hash functions for token signatures and TOTP.

## UI, Design Tokens & Animation
- **`material_color_utilities: ^0.13.0`**: Material 3 color algorithms, paired with Musify's custom Oklab palette generator.
- **`cached_network_image: ^4.0.4`**: Memory- and disk-cached album art image loading.
- **`lottie: ^3.6.1`**: Vector animation engine for seamless Spotify-style feedback animations.
