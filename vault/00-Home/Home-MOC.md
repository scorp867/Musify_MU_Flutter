---
title: "Musify MU Architecture Vault"
type: "moc"
tags: [moc, home, index, vault-root]
---

# Musify MU Architecture Vault

> Comprehensive, file-by-file knowledge base and architecture vault for the **Musify MU** codebase.

## 📊 Codebase Statistics

| Metric | Count | Details |
|--------|-------|---------|
| **Documented Source Files** | 290 | Hand-written Dart components in `lib/` |
| **Protobuf Schemas** | 24 | Wire schemas in `protos/spotify/` |
| **Unit & Widget Tests** | 25 | Test suites in `test/` |
| **Subsystem Domains** | 8 | Core features and architectural layers |
| **Platform Runners** | 6 | Android, iOS, Windows, macOS, Linux, Web |

---

## 🗺️ Master Navigation & Maps of Content

### 1. Architecture & Global Design
- [[01-Architecture/System-Architecture|System Architecture]] - Clean Architecture layers, BLoC pattern, and DI composition root
- [[01-Architecture/Dependency-Graph|Dependency Graph & Matrix]] - Cross-file inbound/outbound dependency mapping
- [[01-Architecture/Data-Flow|Data Flow & Sequences]] - Playback, Kodiak feed, and 401 token mutex diagrams
- [[01-Architecture/Project-Structure|Project Placement Rules]] - Directory organization and placement guide
- [[01-Architecture/Tech-Stack|Tech Stack & Dependencies]] - Runtime libraries and native network engines
- [[01-Architecture/Configuration|Configuration & Linter]] - Dart analysis options and build tools

### 2. Feature Subsystems
- [[02-Features/Auth-System|Authentication & Session Engine]] - Spotify webview login, tokens, TOTP
- [[02-Features/Player-Audio-Engine|Player & Audio Engine]] - JustAudio, queue manager, notification handler
- [[02-Features/Kodiak-Data-Engine|Kodiak Reactive Data Layer]] - DataPool, DataStatement, and trait plugins
- [[02-Features/Home-Feed-System|Home Feed & Casita Engine]] - Casita protobuf decoding, carousels, cards
- [[02-Features/Browse-Catalog|Browse Catalog]] - Browsita category discovery and search
- [[02-Features/Library-System|Library & Playlist Management]] - Rootlist, snapshot diffing, cover resolution
- [[02-Features/Local-Music-System|Local Music Engine]] - Device scanner, Drift SQLite, playback sync
- [[02-Features/UI-Design-System|UI Design System & Color Extraction]] - Encore icons, Oklab perceptual color

### 3. Wire Protocols
- [[03-Protocols/Protocol-Registry|Master Protocol Registry]] - Complete index of all 24 Spotify protobuf definitions

### 4. Interactive Visual Board
- Open `Musify-Architecture.canvas` in Obsidian to view the full interactive architecture map.

---

## 📚 Reading Paths
- **New Developer Onboarding**: Start with [[00-Home/Project-Overview|Project Overview]], then read [[01-Architecture/System-Architecture|System Architecture]] and [[01-Architecture/Project-Structure|Project Structure]].
- **Audio & Player Deep-Dive**: Explore [[02-Features/Player-Audio-Engine|Player Audio Engine]] and examine `lib/core/audio/` notes.
- **Network & Reverse-Engineering**: Read [[02-Features/Auth-System|Auth System]], [[03-Protocols/Protocol-Registry|Protocol Registry]], and `lib/core/network/` notes.
