---
title: "banner_sections_widget_test.dart"
path: "test/features/home_feed/banner_sections_widget_test.dart"
type: "unit-test"
tags: [test, unit-test, flutter-test, verification]
lines: 85
---

# banner_sections_widget_test.dart

> Test File: `[test/features/home_feed/banner_sections_widget_test.dart](file:///c:/Users/Admin/Musify_MU/test/features/home_feed/banner_sections_widget_test.dart)`

## Test Suite Overview
This test suite verifies the functionality and regression resistance of components in Musify MU.

## Target Components Verified
- [[04-Reference/lib/core/widgets/app_network_image|app_network_image.dart]] (`lib/core/widgets/app_network_image.dart`)
- [[04-Reference/lib/features/home_feed/domain/models/home_view_data|home_view_data.dart]] (`lib/features/home_feed/domain/models/home_view_data.dart`)
- [[04-Reference/lib/features/home_feed/presentation/widgets/sections/caught_up_banner_section|caught_up_banner_section.dart]] (`lib/features/home_feed/presentation/widgets/sections/caught_up_banner_section.dart`)
- [[04-Reference/lib/features/home_feed/presentation/widgets/sections/full_bleed_banner_section|full_bleed_banner_section.dart]] (`lib/features/home_feed/presentation/widgets/sections/full_bleed_banner_section.dart`)

## Test Cases & Groups
**Test Groups:**
- `group('FullBleedBannerSection Widget Tests')`
- `group('CaughtUpBannerSection Widget Tests')`

**Individual Test Cases:**
- `test('renders edge-to-edge aspect ratio and AppNetworkImage with srcIn tinting')`
- `test('renders Lottie animation container, title, and subtitle')`

## Verification Strategy
- Follows the **AAA (Arrange, Act, Assert)** testing pattern.
- Uses `flutter_test` test harness with simulated events and streams.
