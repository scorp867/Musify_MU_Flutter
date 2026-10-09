import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// "You're all caught up" celebration banner section (p.f980 / p.en4 / p.s98).
///
/// Features Spotify's authentic `R.raw.all_caught_up` Lottie animation:
/// - Full hand, wrist, and thumb animation popping up and settling
/// - Dual celebration confetti explosions tinted via dynamic color delegates
///   `CONFETTI_1` and `CONFETTI_2` matching the section's `colorCode` (e.g. #83E6BD)
/// - Triggers strictly when the user scrolls the section into the viewport (>= 35% visible)
/// - Stays static on the final celebratory pose once the animation completes
/// - Optimized for 60/120 fps rendering via [RepaintBoundary] with zero UI jank
class CaughtUpBannerSection extends StatefulWidget {
  final HomeSection section;

  const CaughtUpBannerSection({
    super.key,
    required this.section,
  });

  @override
  State<CaughtUpBannerSection> createState() => _CaughtUpBannerSectionState();
}

class _CaughtUpBannerSectionState extends State<CaughtUpBannerSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasStartedAnimation = false;
  bool _compositionLoaded = false;

  static Color _parseColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final clean = hexString.replaceFirst('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_hasStartedAnimation) return;
    if (info.visibleFraction >= 0.35) {
      _hasStartedAnimation = true;
      if (_compositionLoaded) {
        _controller.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parseColor = _parseColor(
      widget.section.colorCode,
      const Color(0xFF83E6BD),
    );

    // Spotify's dynamic color calculation from p.f980:
    // CONFETTI_2 gets the exact received color (parseColor).
    // CONFETTI_1 gets adjusted HSV with boosted saturation and deeper value.
    final hsv = HSVColor.fromColor(parseColor);
    final confetti2 = parseColor;
    final confetti1 = HSVColor.fromAHSV(
      1.0,
      hsv.hue,
      (hsv.saturation * 1.5).clamp(0.0, 1.0),
      (hsv.value * 0.5).clamp(0.0, 1.0),
    ).toColor();

    final title = widget.section.title.isNotEmpty
        ? widget.section.title
        : "You’re all caught up";

    final subtitle = widget.section.subtitle.isNotEmpty
        ? widget.section.subtitle
        : "Come back next Friday for more recommendations.";

    return RepaintBoundary(
      child: VisibilityDetector(
        key: ValueKey('caught_up_banner_${widget.section.sectionUri ?? widget.section.sectionType}'),
        onVisibilityChanged: _onVisibilityChanged,
        child: Semantics(
          label: title,
          container: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 32, bottom: 32, left: 24, right: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Prominent celebration thumbs-up animation (28dp hand, burst confetti)
                SizedBox(
                  height: 64,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: -110,
                        child: SizedBox(
                          width: 582 * 1.25,
                          height: 278 * 1.25,
                          child: Lottie.asset(
                            'assets/animations/all_caught_up.json',
                            controller: _controller,
                            fit: BoxFit.fill,
                            delegates: LottieDelegates(
                              values: [
                                ValueDelegate.color(
                                  const ['**', 'CONFETTI_1', '**'],
                                  value: confetti1,
                                ),
                                ValueDelegate.color(
                                  const ['**', 'CONFETTI_2', '**'],
                                  value: confetti2,
                                ),
                              ],
                            ),
                            onLoaded: (composition) {
                              _controller.duration = composition.duration;
                              _compositionLoaded = true;
                              if (_hasStartedAnimation && !_controller.isAnimating && !_controller.isCompleted) {
                                _controller.forward();
                              }
                            },
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback for headless test environments
                              return const Center(
                                child: Icon(
                                  Icons.thumb_up,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Title: Spotify all_caught_up_title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle: Spotify all_caught_up_subtitle
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.1,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
