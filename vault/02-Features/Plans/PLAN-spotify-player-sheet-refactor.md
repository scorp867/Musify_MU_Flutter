# Implementation Plan: Native Spotify Now Playing View & PeekScrollView

## Overview
Replicate the exact native Spotify Android Now Playing experience in Musify_MU:
1. Full-screen edge-to-edge window (`layoutInDisplayCutoutMode = SHORT_EDGES`, system bar contrast enforcement, transparent bars).
2. Single-top route guard (`FLAG_ACTIVITY_SINGLE_TOP` equivalent) preventing duplicate player sheets.
3. Spotify `Cubic(0.3, 0.0, 0.0, 1.0)` entrance/exit transition.
4. Two-tier `FullScreenLayout` + `PeekScrollView` layout architecture:
   - Viewport 1 (100% screen height): Header + Square Artwork + Metadata/Heart + SeekBar + Transport Controls + Device/Queue row + Peeking Lyrics Header (~56dp).
   - Viewport 2 (Scroll container): Expanded Lyrics Card + Track Details Card.
5. Interactive pull-down dismiss gesture with spring physics and velocity detection.
6. Touch safety & lifecycle guards (`cmj.java`/`jyi0.java` equivalent) ignoring touches once dismissal starts.

## User Rules & Anti-Patterns Avoided
- No purple gradients (strictly OLED black & deep neutral dark grays).
- No pill-shaped buttons.
- No AI clichés or fake metrics.
- Native 60-120fps Impeller rendering with zero re-layout jank.
