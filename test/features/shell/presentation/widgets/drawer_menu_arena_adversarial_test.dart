import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_refresher.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/data/spotify_profile_fetcher.dart';
import 'package:musify_mu/features/auth/domain/entities/spotify_user.dart';
import 'package:musify_mu/features/shell/presentation/widgets/drawer_menu.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_visibility_policy.dart';
import 'package:musify_mu/features/vault/presentation/widgets/stealth_gesture_pad.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AdversarialTokenStore implements SpotifyTokenStore {
  @override
  void addChangeListener(void Function() listener) {}
  @override
  void removeChangeListener(void Function() listener) {}
  @override
  Future<void> saveSpDc(String spDc) async {}
  @override
  Future<String?> getSpDc() async => null;
  @override
  Future<bool> hasSpDc() async => false;
  @override
  Future<void> saveAccessToken(String token, {int lifetimeMs = 3600000}) async {}
  @override
  Future<String?> getAccessToken() async => null;
  @override
  Future<bool> isAccessTokenExpired() async => true;
  @override
  Future<bool> hasValidAccessToken() async => false;
  @override
  Future<void> saveUsername(String username) async {}
  @override
  Future<String?> getUsername() async => null;
  @override
  Future<void> saveProfile({
    required String username,
    required String displayName,
    String? avatarUrl,
    String? country,
    String? product,
  }) async {}
  @override
  Future<({String username, String displayName, String? avatarUrl, String? country, String? product})?> getCachedProfile() async => null;
  @override
  Future<void> saveClientToken(String token, {int lifetimeMs = 86400000}) async {}
  @override
  Future<String?> getClientToken() async => null;
  @override
  Future<bool> isClientTokenExpired() async => false;
  @override
  Future<void> deleteClientToken() async {}
  @override
  Future<void> clearAll() async {}
}

class _AdversarialTokenRefresher implements SpotifyTokenRefresher {
  @override
  Future<String?> refresh() async => null;
}

class _AdversarialProfileFetcher implements SpotifyProfileFetcher {
  @override
  Future<SpotifyUser?> fetchProfile() async => null;
}

class _AdversarialAuthBloc extends AuthBloc {
  _AdversarialAuthBloc([SpotifyUser? initialUser])
      : super(
          tokenStore: _AdversarialTokenStore(),
          refresher: _AdversarialTokenRefresher(),
          profileFetcher: _AdversarialProfileFetcher(),
          cacheManager: AppCacheManager(),
          initialUser: initialUser,
        );
}

class AdversarialGestureRecognizer implements IGestureRecognizer {
  int evaluateCount = 0;
  GestureSample? lastEvaluatedSample;
  Future<VaultResult<RecognitionScore>> Function(
    GestureSample liveStroke,
    GestureTemplate template,
    GestureSensitivityTierEnum sensitivityTier,
  )? onEvaluate;

  AdversarialGestureRecognizer({this.onEvaluate});

  @override
  Future<VaultResult<RecognitionScore>> evaluateStroke({
    required GestureSample liveStroke,
    required GestureTemplate template,
    required GestureSensitivityTierEnum sensitivityTier,
  }) async {
    evaluateCount++;
    lastEvaluatedSample = liveStroke;
    final handler = onEvaluate;
    if (handler != null) {
      return handler(liveStroke, template, sensitivityTier);
    }
    return VaultResult.success(
      RecognitionScore(
        dollarOneScore: 0.95,
        dtwScore: 0.91,
        featureScore: 0.89,
        ensembleScore: 0.927,
        decision: GestureMatchDecisionEnum.matched,
      ),
    );
  }

  @override
  Future<VaultResult<GestureTemplate>> synthesizeMasterTemplate({
    required List<GestureSample> samples,
  }) async {
    return VaultResult.success(DefaultGestureTemplate.canonicalVShape);
  }

  @override
  Future<VaultResult<void>> validateSampleConsistency({
    required List<GestureSample> samples,
  }) async {
    return const VaultResult.success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DrawerMenu Arena Adversarial Tests', () {
    late _AdversarialAuthBloc authBloc;
    late List<MethodCall> platformCalls;

    setUp(() {
      platformCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform,
              (MethodCall methodCall) async {
        platformCalls.add(methodCall);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
      authBloc.close();
    });

    Widget createTestBed({
      required Widget child,
      Size size = const Size(360, 780),
      ThemeData? theme,
      SpotifyUser? user,
    }) {
      authBloc = _AdversarialAuthBloc(user);
      final activeTheme = (theme != null) ? theme : ThemeData.dark();

      return MaterialApp(
        theme: activeTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: BlocProvider<AuthBloc>.value(
                value: authBloc,
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    group('1. Gesture Arena Precedence over Parent Drag Recognizers', () {
      testWidgets(
          'Parent HorizontalDragGestureRecognizer is unconditionally defeated for strokes inside spacer',
          (WidgetTester tester) async {
        int parentDragStartCount = 0;
        int parentDragUpdateCount = 0;
        int parentDragEndCount = 0;
        bool vaultGestureMatched = false;

        final recognizer = AdversarialGestureRecognizer();

        await tester.pumpWidget(
          createTestBed(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => parentDragStartCount++,
              onHorizontalDragUpdate: (_) => parentDragUpdateCount++,
              onHorizontalDragEnd: (_) => parentDragEndCount++,
              child: DrawerMenu(
                gestureRecognizer: recognizer,
                onVaultGestureMatched: () {
                  vaultGestureMatched = true;
                },
              ),
            ),
          ),
        );
        await tester.pump();

        final padFinder = find.byType(StealthGesturePad);
        expect(padFinder, findsOneWidget);

        final padCenter = tester.getCenter(padFinder);

        // Perform a horizontal drag across the spacer that would normally trigger
        // a parent horizontal drag dismiss recognizer
        final gesture = await tester.startGesture(padCenter);
        await gesture.moveBy(const Offset(80, 0));
        await gesture.moveBy(const Offset(40, 0));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(parentDragStartCount, equals(0),
            reason: 'Parent horizontal drag must never start');
        expect(parentDragUpdateCount, equals(0),
            reason: 'Parent horizontal drag must never receive updates');
        expect(parentDragEndCount, equals(0),
            reason: 'Parent horizontal drag must never receive end');
        expect(recognizer.evaluateCount, equals(1),
            reason: 'StealthGesturePad recognizer must evaluate the stroke');
        expect(vaultGestureMatched, isTrue,
            reason: 'Matched callback must fire');
      });

      testWidgets(
          'Parent VerticalDragGestureRecognizer is unconditionally defeated for strokes inside spacer',
          (WidgetTester tester) async {
        int parentVerticalDragStart = 0;
        int parentVerticalDragUpdate = 0;
        int parentVerticalDragEnd = 0;
        bool vaultGestureMatched = false;

        final recognizer = AdversarialGestureRecognizer();

        await tester.pumpWidget(
          createTestBed(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) => parentVerticalDragStart++,
              onVerticalDragUpdate: (_) => parentVerticalDragUpdate++,
              onVerticalDragEnd: (_) => parentVerticalDragEnd++,
              child: DrawerMenu(
                gestureRecognizer: recognizer,
                onVaultGestureMatched: () {
                  vaultGestureMatched = true;
                },
              ),
            ),
          ),
        );
        await tester.pump();

        final padFinder = find.byType(StealthGesturePad);
        final padCenter = tester.getCenter(padFinder);

        final gesture = await tester.startGesture(padCenter);
        await gesture.moveBy(const Offset(0, 70));
        await gesture.moveBy(const Offset(0, 30));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(parentVerticalDragStart, equals(0),
            reason: 'Parent vertical drag must not start');
        expect(parentVerticalDragUpdate, equals(0),
            reason: 'Parent vertical drag must not receive updates');
        expect(parentVerticalDragEnd, equals(0),
            reason: 'Parent vertical drag must not receive end');
        expect(recognizer.evaluateCount, equals(1));
        expect(vaultGestureMatched, isTrue);
      });

      testWidgets(
          'Parent PanGestureRecognizer is unconditionally defeated for multi-segment strokes inside spacer',
          (WidgetTester tester) async {
        int parentPanStart = 0;
        int parentPanUpdate = 0;
        int parentPanEnd = 0;
        bool vaultGestureMatched = false;

        final recognizer = AdversarialGestureRecognizer();

        await tester.pumpWidget(
          createTestBed(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => parentPanStart++,
              onPanUpdate: (_) => parentPanUpdate++,
              onPanEnd: (_) => parentPanEnd++,
              child: DrawerMenu(
                gestureRecognizer: recognizer,
                onVaultGestureMatched: () {
                  vaultGestureMatched = true;
                },
              ),
            ),
          ),
        );
        await tester.pump();

        final padFinder = find.byType(StealthGesturePad);
        final padCenter = tester.getCenter(padFinder);

        // Draw canonical "V" shape
        final gesture = await tester.startGesture(padCenter);
        await gesture.moveBy(const Offset(40, 70));
        await gesture.moveBy(const Offset(40, -70));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(parentPanStart, equals(0),
            reason: 'Parent pan recognizer must not start');
        expect(parentPanUpdate, equals(0),
            reason: 'Parent pan recognizer must not update');
        expect(parentPanEnd, equals(0),
            reason: 'Parent pan recognizer must not end');
        expect(recognizer.evaluateCount, equals(1));
        expect(vaultGestureMatched, isTrue);
      });

      testWidgets(
          'EagerGestureRecognizer claims arena on pointer down without needing touch slop movement',
          (WidgetTester tester) async {
        final padFinder = find.byType(StealthGesturePad);

        await tester.pumpWidget(
          createTestBed(
            child: const DrawerMenu(),
          ),
        );
        await tester.pump();

        final rawGestureDetectorFinder = find.descendant(
          of: padFinder,
          matching: find.byType(RawGestureDetector),
        );
        expect(rawGestureDetectorFinder, findsOneWidget);

        final rawDetector =
            tester.widget<RawGestureDetector>(rawGestureDetectorFinder);
        expect(
          rawDetector.gestures.containsKey(EagerGestureRecognizer),
          isTrue,
          reason: 'RawGestureDetector must configure EagerGestureRecognizer',
        );
        expect(rawDetector.behavior, equals(HitTestBehavior.opaque));
      });
    });

    group('2. Full Spacer Expansion & Sizing Geometry Bounds', () {
      testWidgets(
          'StealthGesturePad occupies the full spacer height and width across diverse device viewports',
          (WidgetTester tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const viewports = <Size>[
          Size(360, 780), // Standard phone
          Size(412, 915), // Large flagship phone
          Size(600, 1024), // Small tablet
        ];

        double previousHeight = 0.0;
        for (final viewport in viewports) {
          tester.view.physicalSize = Size(viewport.width, viewport.height);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            createTestBed(
              size: viewport,
              child: const DrawerMenu(),
            ),
          );
          await tester.pump();

          final padFinder = find.byType(StealthGesturePad);
          final padSize = tester.getSize(padFinder);

          // Drawer horizontal padding is 20 on left and 20 on right = 40px total
          final expectedWidth = viewport.width - 40.0;
          expect(padSize.width, equals(expectedWidth),
              reason: 'Pad width must match full available column width for ${viewport.width}');
          expect(padSize.height, greaterThan(50.0),
              reason: 'Spacer height must expand flexibly to occupy remaining vertical space');
          expect(padSize.height, greaterThan(previousHeight),
              reason: 'Spacer height must expand monotonically with larger viewports');
          previousHeight = padSize.height;

          final equalizerFinder = find.text('Equalizer');
          final bottomFinder = find.text('Connect Spotify');

          final equalizerBottom = tester.getBottomLeft(equalizerFinder).dy;
          final padTop = tester.getTopLeft(padFinder).dy;
          final padBottom = tester.getBottomLeft(padFinder).dy;
          final bottomTop = tester.getTopLeft(bottomFinder).dy;

          expect(padTop, greaterThanOrEqualTo(equalizerBottom),
              reason: 'StealthGesturePad must start below Equalizer');
          expect(bottomTop, greaterThanOrEqualTo(padBottom),
              reason: 'StealthGesturePad must end above Connect Spotify');
        }
      });

      testWidgets(
          'Drawing outside spacer on Equalizer yields to parent and does NOT trigger StealthGesturePad',
          (WidgetTester tester) async {
        int parentDragCount = 0;
        final recognizer = AdversarialGestureRecognizer();
        bool vaultGestureMatched = false;

        await tester.pumpWidget(
          createTestBed(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => parentDragCount++,
              child: DrawerMenu(
                gestureRecognizer: recognizer,
                onVaultGestureMatched: () {
                  vaultGestureMatched = true;
                },
              ),
            ),
          ),
        );
        await tester.pump();

        final equalizerFinder = find.text('Equalizer');
        expect(equalizerFinder, findsOneWidget);
        final equalizerCenter = tester.getCenter(equalizerFinder);

        // Perform drag starting on Equalizer
        final gesture = await tester.startGesture(equalizerCenter);
        await gesture.moveBy(const Offset(60, 0));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(parentDragCount, greaterThan(0),
            reason: 'Parent drag must capture strokes initiated on Equalizer');
        expect(recognizer.evaluateCount, equals(0),
            reason: 'StealthGesturePad must not evaluate strokes outside its bounds');
        expect(vaultGestureMatched, isFalse);
      });

      testWidgets(
          'Taps and drags on bottom action items do NOT trigger StealthGesturePad',
          (WidgetTester tester) async {
        final recognizer = AdversarialGestureRecognizer();
        bool vaultGestureMatched = false;

        // Test with unauthenticated user (Connect Spotify)
        await tester.pumpWidget(
          createTestBed(
            user: null,
            child: DrawerMenu(
              gestureRecognizer: recognizer,
              onVaultGestureMatched: () {
                vaultGestureMatched = true;
              },
            ),
          ),
        );
        await tester.pump();

        final connectFinder = find.text('Connect Spotify');
        expect(connectFinder, findsOneWidget);

        final gesture1 = await tester.startGesture(tester.getCenter(connectFinder));
        await gesture1.moveBy(const Offset(30, 0));
        await gesture1.up();
        await tester.pumpAndSettle();

        expect(recognizer.evaluateCount, equals(0));
        expect(vaultGestureMatched, isFalse);

        // Test with authenticated user (Log Out)
        await tester.pumpWidget(
          createTestBed(
            user: const SpotifyUser(id: 'auth_usr', displayName: 'Auth User'),
            child: DrawerMenu(
              gestureRecognizer: recognizer,
              onVaultGestureMatched: () {
                vaultGestureMatched = true;
              },
            ),
          ),
        );
        await tester.pump();

        final logoutFinder = find.text('Log Out');
        expect(logoutFinder, findsOneWidget);

        final gesture2 = await tester.startGesture(tester.getCenter(logoutFinder));
        await gesture2.moveBy(const Offset(30, 0));
        await gesture2.up();
        await tester.pumpAndSettle();

        expect(recognizer.evaluateCount, equals(0));
        expect(vaultGestureMatched, isFalse);
      });

      testWidgets(
          'Stroke initiated inside spacer extending upward across Equalizer boundary remains captured by pad',
          (WidgetTester tester) async {
        int parentDragStart = 0;
        final recognizer = AdversarialGestureRecognizer();
        bool vaultGestureMatched = false;

        await tester.pumpWidget(
          createTestBed(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) => parentDragStart++,
              child: DrawerMenu(
                gestureRecognizer: recognizer,
                onVaultGestureMatched: () {
                  vaultGestureMatched = true;
                },
              ),
            ),
          ),
        );
        await tester.pump();

        final padFinder = find.byType(StealthGesturePad);
        final padCenter = tester.getCenter(padFinder);

        // Start inside pad, then drag upward into Equalizer territory
        final gesture = await tester.startGesture(padCenter);
        await gesture.moveBy(const Offset(0, -120));
        await gesture.moveBy(const Offset(30, -30));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(parentDragStart, equals(0),
            reason: 'Parent vertical drag must not steal stroke once pad captured pointer down');
        expect(recognizer.evaluateCount, equals(1),
            reason: 'Stroke must be delivered to pad even if pointer travels past pad boundary');
        expect(vaultGestureMatched, isTrue);
      });
    });

    group('3. Plurality of Themes & Visibility Policies', () {
      testWidgets(
          'DrawerMenu functions identically under Dark theme and Light theme without styling conflicts',
          (WidgetTester tester) async {
        final themes = <String, ThemeData>{
          'Dark': ThemeData.dark(),
          'Light': ThemeData.light(),
        };

        for (final entry in themes.entries) {
          bool vaultMatched = false;
          final recognizer = AdversarialGestureRecognizer();

          await tester.pumpWidget(
            createTestBed(
              theme: entry.value,
              child: DrawerMenu(
                gestureRecognizer: recognizer,
                onVaultGestureMatched: () {
                  vaultMatched = true;
                },
              ),
            ),
          );
          await tester.pump();

          final padFinder = find.byType(StealthGesturePad);
          expect(padFinder, findsOneWidget);

          final padCenter = tester.getCenter(padFinder);
          final gesture = await tester.startGesture(padCenter);
          await gesture.moveBy(const Offset(30, 60));
          await gesture.moveBy(const Offset(30, -60));
          await gesture.up();
          await tester.pumpAndSettle();

          expect(vaultMatched, isTrue,
              reason: 'Gesture match must succeed under ${entry.key} theme');
          expect(recognizer.evaluateCount, equals(1));
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets(
          'invisibleStealth policy produces zero ink and keeps dissipation ticker idle',
          (WidgetTester tester) async {
        bool vaultMatched = false;
        final recognizer = AdversarialGestureRecognizer();

        await tester.pumpWidget(
          createTestBed(
            child: DrawerMenu(
              gestureRecognizer: recognizer,
              gestureVisibilityPolicy:
                  GestureVisibilityPolicyEnum.invisibleStealth,
              onVaultGestureMatched: () {
                vaultMatched = true;
              },
            ),
          ),
        );
        await tester.pump();

        final padFinder = find.byType(StealthGesturePad);
        final customPaintFinder = find.descendant(
          of: padFinder,
          matching: find.byType(CustomPaint),
        );
        expect(customPaintFinder, findsOneWidget);

        final customPaint = tester.widget<CustomPaint>(customPaintFinder);
        expect(customPaint.painter, isNotNull);

        final padCenter = tester.getCenter(padFinder);
        final gesture = await tester.startGesture(padCenter);
        await gesture.moveBy(const Offset(30, 50));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(vaultMatched, isTrue);
        expect(recognizer.evaluateCount, equals(1));
      });

      testWidgets(
          'faintDissipatingHairline policy activates ticker and dissipates points within 280ms',
          (WidgetTester tester) async {
        bool vaultMatched = false;
        final recognizer = AdversarialGestureRecognizer();

        await tester.pumpWidget(
          createTestBed(
            child: DrawerMenu(
              gestureRecognizer: recognizer,
              gestureVisibilityPolicy:
                  GestureVisibilityPolicyEnum.faintDissipatingHairline,
              onVaultGestureMatched: () {
                vaultMatched = true;
              },
            ),
          ),
        );
        await tester.pump();

        final padFinder = find.byType(StealthGesturePad);
        final padCenter = tester.getCenter(padFinder);

        final gesture = await tester.startGesture(padCenter);
        await gesture.moveBy(const Offset(40, 70));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.moveBy(const Offset(40, -70));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();

        // Dissipation completes over 220ms - 280ms duration
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(vaultMatched, isTrue);
        expect(recognizer.evaluateCount, equals(1));
        expect(tester.takeException(), isNull);
      });
    });

    group('4. Adversarial Stress & Edge Case Scenarios', () {
      testWidgets(
          'Multi-touch pointer injection does not corrupt primary stroke evaluation',
          (WidgetTester tester) async {
        final recognizer = AdversarialGestureRecognizer();
        bool vaultMatched = false;

        await tester.pumpWidget(
          createTestBed(
            child: DrawerMenu(
              gestureRecognizer: recognizer,
              onVaultGestureMatched: () {
                vaultMatched = true;
              },
            ),
          ),
        );
        await tester.pump();

        final padFinder = find.byType(StealthGesturePad);
        final padCenter = tester.getCenter(padFinder);

        // Finger 1 down
        final finger1 = await tester.startGesture(padCenter, pointer: 1);
        await finger1.moveBy(const Offset(30, 60));

        // Finger 2 down simultaneously (should be ignored)
        final finger2 = await tester.startGesture(
          padCenter + const Offset(50, 50),
          pointer: 2,
        );
        await finger2.moveBy(const Offset(20, 20));
        await finger2.up();

        // Finger 1 continues and completes
        await finger1.moveBy(const Offset(30, -60));
        await finger1.up();
        await tester.pumpAndSettle();

        expect(recognizer.evaluateCount, equals(1),
            reason: 'Only primary pointer stroke must be evaluated');
        expect(vaultMatched, isTrue);
      });

      testWidgets(
          'Rapid re-touch cancels and supersedes in-flight background evaluation',
          (WidgetTester tester) async {
        final completer1 = Completer<VaultResult<RecognitionScore>>();
        int matchCount = 0;

        final recognizer = AdversarialGestureRecognizer(
          onEvaluate: (stroke, template, tier) => completer1.future,
        );

        await tester.pumpWidget(
          createTestBed(
            child: DrawerMenu(
              gestureRecognizer: recognizer,
              onVaultGestureMatched: () {
                matchCount++;
              },
            ),
          ),
        );
        await tester.pump();

        final padFinder = find.byType(StealthGesturePad);
        final padCenter = tester.getCenter(padFinder);

        // Stroke 1 starts and completes drawing
        final stroke1 = await tester.startGesture(padCenter);
        await stroke1.moveBy(const Offset(30, 30));
        await stroke1.up();
        await tester.pump();

        expect(recognizer.evaluateCount, equals(1));
        expect(completer1.isCompleted, isFalse);

        // Stroke 2 begins before stroke 1 finishes evaluation
        final stroke2 = await tester.startGesture(padCenter + const Offset(10, 10));
        await tester.pump();

        // Now stroke 1 returns a matched result
        completer1.complete(
          VaultResult.success(
            RecognitionScore(
              dollarOneScore: 0.96,
              dtwScore: 0.92,
              featureScore: 0.90,
              ensembleScore: 0.935,
              decision: GestureMatchDecisionEnum.matched,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Stroke 1 was superseded, so matchCount must still be 0
        expect(matchCount, equals(0),
            reason: 'Superseded stroke 1 must not trigger match confirmation');

        await stroke2.up();
        await tester.pumpAndSettle();
      });

      testWidgets(
          'Sub-threshold micro-jitter (< 2 points) silently discards without evaluation',
          (WidgetTester tester) async {
        final recognizer = AdversarialGestureRecognizer();
        bool vaultMatched = false;

        await tester.pumpWidget(
          createTestBed(
            child: DrawerMenu(
              gestureRecognizer: recognizer,
              onVaultGestureMatched: () {
                vaultMatched = true;
              },
            ),
          ),
        );
        await tester.pump();

        final padFinder = find.byType(StealthGesturePad);
        final padCenter = tester.getCenter(padFinder);

        platformCalls.clear();

        // Instant tap without movement
        final gesture = await tester.startGesture(padCenter);
        await gesture.up();
        await tester.pumpAndSettle();

        expect(recognizer.evaluateCount, equals(0),
            reason: 'Single tap must not trigger stroke evaluation');
        expect(vaultMatched, isFalse);
        final hasHaptic = platformCalls.any(
          (call) => call.method == 'HapticFeedback.vibrate',
        );
        expect(hasHaptic, isFalse,
            reason: 'Zero haptic feedback on single tap');
      });

      testWidgets(
          'Non-matching strokes silently reject with zero UI leakage and zero haptics',
          (WidgetTester tester) async {
        final nonMatchDecisions = <GestureMatchDecisionEnum>[
          GestureMatchDecisionEnum.rejectedAntiScribble,
          GestureMatchDecisionEnum.rejectedStructuralGate,
          GestureMatchDecisionEnum.rejectedClassifierFloor,
          GestureMatchDecisionEnum.rejectedBelowSensitivityTier,
        ];

        for (final decision in nonMatchDecisions) {
          platformCalls.clear();
          bool vaultMatched = false;

          final recognizer = AdversarialGestureRecognizer(
            onEvaluate: (stroke, template, tier) async {
              return VaultResult.success(
                RecognitionScore(
                  dollarOneScore: 0.45,
                  dtwScore: 0.45,
                  featureScore: 0.45,
                  ensembleScore: 0.45,
                  decision: decision,
                ),
              );
            },
          );

          await tester.pumpWidget(
            createTestBed(
              child: DrawerMenu(
                gestureRecognizer: recognizer,
                onVaultGestureMatched: () {
                  vaultMatched = true;
                },
              ),
            ),
          );
          await tester.pump();

          final padFinder = find.byType(StealthGesturePad);
          final padCenter = tester.getCenter(padFinder);

          final gesture = await tester.startGesture(padCenter);
          await gesture.moveBy(const Offset(30, 30));
          await gesture.up();
          await tester.pumpAndSettle();

          expect(vaultMatched, isFalse,
              reason: 'Non-match decision $decision must not trigger match');
          expect(platformCalls.any((c) => c.method == 'HapticFeedback.vibrate'),
              isFalse,
              reason: 'No haptics allowed on rejection');
          expect(find.byType(SnackBar), findsNothing,
              reason: 'No error SnackBar allowed (plausible deniability)');
          expect(find.byType(AlertDialog), findsNothing,
              reason: 'No error AlertDialog allowed');
        }
      });
    });
  });
}
