import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/caught_up_banner_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/full_bleed_banner_section.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  group('FullBleedBannerSection Widget Tests', () {
    testWidgets('renders edge-to-edge aspect ratio and AppNetworkImage with srcIn tinting', (tester) async {
      const section = HomeSection(
        title: 'New Music Friday',
        subtitle: 'New music from Drake, Mac Miller, Quavo and more!',
        sectionType: 'fullBleedBanner',
        colorCode: '#83E6BD',
        imageUrl: 'https://i.scdn.co/image/ab6715f30000b0b0da9bc851b0267ae148b29d2e',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullBleedBannerSection(section: section),
          ),
        ),
      );

      // Verify AspectRatio widget with 2226 / 294
      final aspectRatioFinder = find.byType(AspectRatio);
      expect(aspectRatioFinder, findsOneWidget);
      final AspectRatio aspectRatioWidget = tester.widget(aspectRatioFinder);
      expect(aspectRatioWidget.aspectRatio, closeTo(2226 / 294, 0.001));

      // Verify AppNetworkImage is used
      final appImageFinder = find.byType(AppNetworkImage);
      expect(appImageFinder, findsOneWidget);
      final AppNetworkImage appImage = tester.widget(appImageFinder);
      expect(appImage.imageUrl, 'https://i.scdn.co/image/ab6715f30000b0b0da9bc851b0267ae148b29d2e');
      expect(appImage.color, const Color(0xFF83E6BD));
      expect(appImage.colorBlendMode, BlendMode.srcIn);

      // Verify subtitle description
      expect(find.text('New music from Drake, Mac Miller, Quavo and more!'), findsOneWidget);
    });
  });

  group('CaughtUpBannerSection Widget Tests', () {
    testWidgets('renders Lottie animation container, title, and subtitle', (tester) async {
      const section = HomeSection(
        title: 'You’re all caught up',
        subtitle: 'Come back next Friday for more recommendations.',
        sectionType: 'banner',
        colorCode: '#83E6BD',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CaughtUpBannerSection(section: section),
            ),
          ),
        ),
      );

      // Verify title and subtitle
      expect(find.text('You’re all caught up'), findsOneWidget);
      expect(find.text('Come back next Friday for more recommendations.'), findsOneWidget);

      // Verify Lottie asset or fallback icon is rendered inside 140x140 box
      final lottieOrIcon = find.byType(Lottie);
      expect(lottieOrIcon, findsOneWidget);

      final Lottie lottieWidget = tester.widget(lottieOrIcon);
      expect(lottieWidget.delegates, isNotNull);

      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
